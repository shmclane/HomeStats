import SwiftUI

struct PlexFormView: View {
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

                SecureField("X-Plex-Token", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Connection")
            } footer: {
                Text(ServiceType.plex.helpText)
            }

            Section {
                TestConnectionButton(service: .plex)
            }

            Section {
                Button("Save") {
                    save()
                }
                .disabled(url.isEmpty || token.isEmpty)

                if syncManager.config.plex != nil {
                    Button("Remove Configuration", role: .destructive) {
                        syncManager.config.plex = nil
                        syncManager.save()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Plex")
        .onAppear {
            if let plex = syncManager.config.plex {
                url = plex.url
                token = plex.token
            }
        }
    }

    private func save() {
        syncManager.config.plex = PlexConfig(
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            token: token.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        syncManager.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PlexFormView()
    }
}
