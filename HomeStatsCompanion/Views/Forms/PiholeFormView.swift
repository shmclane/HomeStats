import SwiftUI

struct PiholeFormView: View {
    @ObservedObject private var syncManager = ConfigSyncManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var apiToken = ""

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("API Token (optional)", text: $apiToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Connection")
            } footer: {
                Text(ServiceType.pihole.helpText)
            }

            Section {
                TestConnectionButton(service: .pihole)
            }

            Section {
                Button("Save") {
                    save()
                }
                .disabled(url.isEmpty)

                if syncManager.config.pihole != nil {
                    Button("Remove Configuration", role: .destructive) {
                        syncManager.config.pihole = nil
                        syncManager.save()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Pi-hole")
        .onAppear {
            if let pihole = syncManager.config.pihole {
                url = pihole.url
                apiToken = pihole.apiToken ?? ""
            }
        }
    }

    private func save() {
        syncManager.config.pihole = PiholeConfig(
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            apiToken: apiToken.isEmpty ? nil : apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        syncManager.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PiholeFormView()
    }
}
