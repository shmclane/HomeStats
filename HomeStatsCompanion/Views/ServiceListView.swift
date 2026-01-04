import SwiftUI

struct ServiceListView: View {
    @ObservedObject private var syncManager = ConfigSyncManager.shared

    var body: some View {
        List {
            Section("Smart Home") {
                NavigationLink {
                    HomeAssistantFormView()
                } label: {
                    ServiceRow(
                        service: .homeAssistant,
                        isConfigured: syncManager.isConfigured(.homeAssistant)
                    )
                }
            }

            Section("Media") {
                NavigationLink {
                    PlexFormView()
                } label: {
                    ServiceRow(
                        service: .plex,
                        isConfigured: syncManager.isConfigured(.plex)
                    )
                }

                NavigationLink {
                    ServiceFormView(service: .sonarr)
                } label: {
                    ServiceRow(
                        service: .sonarr,
                        isConfigured: syncManager.isConfigured(.sonarr)
                    )
                }

                NavigationLink {
                    ServiceFormView(service: .radarr)
                } label: {
                    ServiceRow(
                        service: .radarr,
                        isConfigured: syncManager.isConfigured(.radarr)
                    )
                }

                NavigationLink {
                    ServiceFormView(service: .sabnzbd)
                } label: {
                    ServiceRow(
                        service: .sabnzbd,
                        isConfigured: syncManager.isConfigured(.sabnzbd)
                    )
                }
            }

            Section("Infrastructure") {
                NavigationLink {
                    ProxmoxFormView()
                } label: {
                    ServiceRow(
                        service: .proxmox,
                        isConfigured: syncManager.isConfigured(.proxmox)
                    )
                }

                NavigationLink {
                    PiholeFormView()
                } label: {
                    ServiceRow(
                        service: .pihole,
                        isConfigured: syncManager.isConfigured(.pihole)
                    )
                }
            }

            Section("3D Printers") {
                ForEach(syncManager.config.printers) { printer in
                    NavigationLink {
                        PrinterFormView(printerId: printer.id)
                    } label: {
                        Label(printer.name.isEmpty ? "New Printer" : printer.name, systemImage: "printer.fill")
                    }
                }
                .onDelete(perform: deletePrinters)

                Button {
                    addPrinter()
                } label: {
                    Label("Add Printer", systemImage: "plus.circle")
                }
            }

            Section {
                Toggle("Allow Self-Signed Certificates", isOn: $syncManager.config.allowInsecureCerts)
            } header: {
                Text("Security")
            } footer: {
                Text("Enable this for local servers with self-signed SSL certificates (e.g., Proxmox)")
            }
        }
        .navigationTitle("HomeStats Setup")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncStatusView()
            }
        }
    }

    private func addPrinter() {
        syncManager.config.printers.append(PrinterConfig())
    }

    private func deletePrinters(at offsets: IndexSet) {
        syncManager.config.printers.remove(atOffsets: offsets)
        syncManager.save()
    }
}

#Preview {
    NavigationStack {
        ServiceListView()
    }
}
