import SwiftUI

struct ServiceFormView: View {
    let service: ServiceType

    @ObservedObject private var syncManager = ConfigSyncManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var apiKey = ""

    private var currentConfig: ServiceConfig? {
        switch service {
        case .sonarr: return syncManager.config.sonarr
        case .radarr: return syncManager.config.radarr
        case .sabnzbd: return syncManager.config.sabnzbd
        default: return nil
        }
    }

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("API Key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Connection")
            } footer: {
                Text(service.helpText)
            }

            Section {
                TestConnectionButton(service: service)
            }

            Section {
                Button("Save") {
                    save()
                }
                .disabled(url.isEmpty || apiKey.isEmpty)

                if currentConfig != nil {
                    Button("Remove Configuration", role: .destructive) {
                        remove()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(service.rawValue)
        .onAppear {
            if let config = currentConfig {
                url = config.url
                apiKey = config.apiKey
            }
        }
    }

    private func save() {
        let config = ServiceConfig(
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        switch service {
        case .sonarr: syncManager.config.sonarr = config
        case .radarr: syncManager.config.radarr = config
        case .sabnzbd: syncManager.config.sabnzbd = config
        default: break
        }

        syncManager.save()
        dismiss()
    }

    private func remove() {
        switch service {
        case .sonarr: syncManager.config.sonarr = nil
        case .radarr: syncManager.config.radarr = nil
        case .sabnzbd: syncManager.config.sabnzbd = nil
        default: break
        }
        syncManager.save()
    }
}

#Preview {
    NavigationStack {
        ServiceFormView(service: .sonarr)
    }
}
