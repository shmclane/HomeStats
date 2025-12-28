import SwiftUI

struct CameraCard: View {
    let entity: HAEntity
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var refreshTimer: Timer?

    var body: some View {
        VStack(spacing: 8) {
            // Camera image
            ZStack {
                Color(white: 0.1)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "video.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 400, height: 225)
            .clipped()
            .cornerRadius(12)

            // Name
            Text(entity.name)
                .font(.headline)
                .lineLimit(1)
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(16)
        .onAppear {
            loadImage()
            startRefresh()
        }
        .onDisappear {
            stopRefresh()
        }
    }

    private func loadImage() {
        let urlString = "\(AppConfig.haURL)/api/camera_proxy/\(entity.entityId)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(AppConfig.haToken)", forHTTPHeaderField: "Authorization")

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func startRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            loadImage()
        }
    }

    private func stopRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
