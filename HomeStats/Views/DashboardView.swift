import SwiftUI

struct DashboardView: View {
    @StateObject private var service = HAService()
    @State private var selectedDomain: String?

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                if service.isLoading && service.entities.isEmpty {
                    loadingView
                } else if let error = service.error, service.entities.isEmpty {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .onAppear {
                service.startAutoRefresh()
            }
            .onDisappear {
                service.stopAutoRefresh()
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Domain filter
            domainFilterView

            // Entity grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredEntities) { entity in
                        if entity.domain == "camera" {
                            CameraCard(entity: entity)
                        } else {
                            EntityCard(entity: entity) {
                                Task {
                                    await service.toggle(entity)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 24)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("HomeStats")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            if service.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }

            if let lastUpdated = service.lastUpdated {
                Text("Updated: \(lastUpdated, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 48)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var domainFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                DomainButton(title: "All", isSelected: selectedDomain == nil) {
                    selectedDomain = nil
                }

                ForEach(service.domains(), id: \.self) { domain in
                    DomainButton(
                        title: domain.capitalized,
                        isSelected: selectedDomain == domain
                    ) {
                        selectedDomain = domain
                    }
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.vertical, 12)
    }

    private var filteredEntities: [HAEntity] {
        if let domain = selectedDomain {
            return service.entities.filter { $0.domain == domain }
        }
        return service.entities
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
            Text("Connecting to Home Assistant...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Connection Error")
                .font(.title)
                .fontWeight(.bold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Button("Retry") {
                Task {
                    await service.fetchStates()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

struct DomainButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(white: 0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(DomainButtonStyle())
    }
}

struct DomainButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isFocused ? Color.white : Color.clear, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.1 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    DashboardView()
}
