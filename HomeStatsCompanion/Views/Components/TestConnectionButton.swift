import SwiftUI

struct TestConnectionButton: View {
    let service: ServiceType
    @State private var testResult: TestResult = .idle

    enum TestResult: Equatable {
        case idle
        case testing
        case success(String)
        case failure(String)
    }

    var body: some View {
        Button {
            Task {
                await testConnection()
            }
        } label: {
            HStack {
                switch testResult {
                case .idle:
                    Label("Test Connection", systemImage: "network")
                case .testing:
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Testing...")
                case .success(let message):
                    Label(message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failure(let message):
                    Label(message, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .disabled(testResult == .testing)
    }

    @MainActor
    private func testConnection() async {
        testResult = .testing

        let result = await ConfigSyncManager.shared.testConnection(for: service)

        switch result {
        case .success(let message):
            testResult = .success(message)
        case .failure(let error):
            testResult = .failure(error.localizedDescription)
        }

        // Reset after delay
        try? await Task.sleep(for: .seconds(3))
        testResult = .idle
    }
}

#Preview {
    TestConnectionButton(service: .homeAssistant)
}
