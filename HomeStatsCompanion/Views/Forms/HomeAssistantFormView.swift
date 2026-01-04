import SwiftUI

struct HomeAssistantFormView: View {
    @ObservedObject private var syncManager = ConfigSyncManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var token = ""

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Long-Lived Access Token", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Connection")
            } footer: {
                Text(ServiceType.homeAssistant.helpText)
            }

            Section {
                TestConnectionButton(service: .homeAssistant)
            }

            Section {
                Button("Save") {
                    save()
                }
                .disabled(url.isEmpty || token.isEmpty)

                if syncManager.config.homeAssistant != nil {
                    Button("Remove Configuration", role: .destructive) {
                        syncManager.config.homeAssistant = nil
                        syncManager.save()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Home Assistant")
        .onAppear {
            if let ha = syncManager.config.homeAssistant {
                url = ha.url
                token = ha.token
            }
        }
    }

    private func save() {
        syncManager.config.homeAssistant = HomeAssistantConfig(
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            token: token.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        syncManager.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        HomeAssistantFormView()
    }
}
