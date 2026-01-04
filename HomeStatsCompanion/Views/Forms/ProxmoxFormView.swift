import SwiftUI

struct ProxmoxFormView: View {
    @ObservedObject private var syncManager = ConfigSyncManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var nodesText = ""

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Connection")
            } footer: {
                Text("Example: https://192.168.1.100:8006")
            }

            Section {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
            } header: {
                Text("Authentication")
            } footer: {
                Text(ServiceType.proxmox.helpText)
            }

            Section {
                TextField("Node Names", text: $nodesText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Nodes")
            } footer: {
                Text("Comma-separated list of node names (e.g., pve, pve2)")
            }

            Section {
                TestConnectionButton(service: .proxmox)
            }

            Section {
                Button("Save") {
                    save()
                }
                .disabled(url.isEmpty || username.isEmpty || password.isEmpty)

                if syncManager.config.proxmox != nil {
                    Button("Remove Configuration", role: .destructive) {
                        syncManager.config.proxmox = nil
                        syncManager.save()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Proxmox")
        .onAppear {
            if let proxmox = syncManager.config.proxmox {
                url = proxmox.url
                username = proxmox.username
                password = proxmox.password
                nodesText = proxmox.nodes.joined(separator: ", ")
            }
        }
    }

    private func save() {
        let nodes = nodesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        syncManager.config.proxmox = ProxmoxConfig(
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            nodes: nodes
        )
        syncManager.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ProxmoxFormView()
    }
}
