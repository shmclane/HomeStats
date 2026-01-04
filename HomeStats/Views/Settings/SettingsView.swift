import SwiftUI

struct SettingsView: View {
    @ObservedObject private var syncManager = ConfigSyncManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                headerView

                VStack(alignment: .leading, spacing: 24) {
                    ServiceStatusSection(title: "Smart Home", services: [
                        (.homeAssistant, syncManager.config.homeAssistant != nil)
                    ])

                    ServiceStatusSection(title: "Media", services: [
                        (.plex, syncManager.config.plex != nil),
                        (.sonarr, syncManager.config.sonarr != nil),
                        (.radarr, syncManager.config.radarr != nil),
                        (.sabnzbd, syncManager.config.sabnzbd != nil)
                    ])

                    ServiceStatusSection(title: "Infrastructure", services: [
                        (.proxmox, syncManager.config.proxmox != nil),
                        (.pihole, syncManager.config.pihole != nil)
                    ])

                    printersSection
                }
                .padding(.horizontal, 48)

                Spacer(minLength: 50)
            }
            .padding(.vertical, 40)
        }
        .background(Color.black)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                Text("Settings")
                    .font(.title2.bold())

                Spacer()

                syncStatusView
            }

            Text("Configure services using the HomeStats Companion app on your iPhone")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 48)
    }

    private var syncStatusView: some View {
        HStack(spacing: 8) {
            switch syncManager.syncStatus {
            case .idle:
                Image(systemName: "icloud")
                    .foregroundColor(.secondary)
                Text("iCloud")
                    .foregroundColor(.secondary)
            case .syncing:
                ProgressView()
                Text("Syncing...")
                    .foregroundColor(.secondary)
            case .synced:
                Image(systemName: "icloud.fill")
                    .foregroundColor(.green)
                Text("Synced")
                    .foregroundColor(.green)
            case .error(let message):
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
            }

            if let lastSync = syncManager.lastSyncDate {
                Text("(\(lastSync, style: .relative) ago)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .font(.callout)
    }

    private var printersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "printer.fill")
                    .foregroundColor(.blue)
                Text("3D Printers")
                    .font(.headline)
            }

            if syncManager.config.printers.isEmpty {
                HStack {
                    Image(systemName: "circle.dashed")
                        .foregroundColor(.secondary)
                    Text("No printers configured")
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 32)
            } else {
                ForEach(syncManager.config.printers) { printer in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(printer.name)
                        Spacer()
                        Text(printer.printerId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 32)
                }
            }
        }
    }
}

// MARK: - Service Status Section

struct ServiceStatusSection: View {
    let title: String
    let services: [(ServiceType, Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }

            ForEach(services, id: \.0) { service, isConfigured in
                HStack {
                    Image(systemName: isConfigured ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundColor(isConfigured ? .green : .secondary)
                    Text(service.rawValue)
                        .foregroundColor(isConfigured ? .primary : .secondary)

                    Spacer()

                    if isConfigured {
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Not configured")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 32)
            }
        }
    }

    private var categoryIcon: String {
        switch title {
        case "Smart Home": return "house.fill"
        case "Media": return "play.tv.fill"
        case "Infrastructure": return "server.rack"
        default: return "circle"
        }
    }
}

#Preview {
    SettingsView()
}
