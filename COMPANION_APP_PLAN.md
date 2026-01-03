# HomeStats Companion iOS App Plan

## Shared Data Model

```swift
// Shared/Models/HomeStatsConfig.swift

import Foundation

struct HomeStatsConfig: Codable {
    var homeAssistant: HomeAssistantConfig?
    var plex: PlexConfig?
    var sonarr: ServiceConfig?
    var radarr: ServiceConfig?
    var sabnzbd: ServiceConfig?
    var proxmox: ProxmoxConfig?
    var pihole: PiholeConfig?
    var printers: [PrinterConfig]

    static let cloudKey = "HomeStatsConfig"
}

struct HomeAssistantConfig: Codable {
    var url: String          // "http://192.168.1.100:8123"
    var token: String        // Long-lived access token
}

struct PlexConfig: Codable {
    var url: String          // "http://192.168.1.100:32400"
    var token: String        // X-Plex-Token
}

struct ServiceConfig: Codable {
    var url: String
    var apiKey: String
}

struct ProxmoxConfig: Codable {
    var url: String          // "https://192.168.1.100:8006"
    var username: String     // "user@pam"
    var password: String     // Or token
    var nodes: [String]      // ["pve", "pve2"]
}

struct PiholeConfig: Codable {
    var url: String
    var apiToken: String?    // Optional for stats-only
}

struct PrinterConfig: Codable, Identifiable {
    var id: String           // UUID
    var name: String         // "DB Galore"
    var printerId: String    // Bambu device ID
    var accessCode: String
    var amsId: String?
}
```

## iCloud Sync Manager

```swift
// Shared/Services/ConfigSyncManager.swift

import Foundation

class ConfigSyncManager: ObservableObject {
    static let shared = ConfigSyncManager()

    @Published var config: HomeStatsConfig

    private let store = NSUbiquitousKeyValueStore.default

    init() {
        config = Self.load() ?? HomeStatsConfig(printers: [])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        store.synchronize()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        store.set(data, forKey: HomeStatsConfig.cloudKey)
        store.synchronize()
    }

    static func load() -> HomeStatsConfig? {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: HomeStatsConfig.cloudKey),
              let config = try? JSONDecoder().decode(HomeStatsConfig.self, from: data) else {
            return nil
        }
        return config
    }

    @objc private func storeDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if let loaded = Self.load() {
                self.config = loaded
            }
        }
    }
}
```

## iOS App Structure

```
HomeStatsCompanion/
├── App/
│   └── HomeStatsCompanionApp.swift
├── Views/
│   ├── ContentView.swift           # Main navigation
│   ├── ServiceListView.swift       # List of all services
│   ├── Forms/
│   │   ├── HomeAssistantFormView.swift
│   │   ├── PlexFormView.swift
│   │   ├── SonarrFormView.swift
│   │   ├── RadarrFormView.swift
│   │   ├── SABnzbdFormView.swift
│   │   ├── ProxmoxFormView.swift
│   │   ├── PiholeFormView.swift
│   │   └── PrinterFormView.swift
│   └── Components/
│       ├── ServiceRow.swift
│       ├── ConnectionStatusBadge.swift
│       └── TestConnectionButton.swift
├── Services/
│   └── ConnectionTester.swift      # Verify configs work
└── Shared/                         # Shared with tvOS target
    ├── Models/
    │   └── HomeStatsConfig.swift
    └── Services/
        └── ConfigSyncManager.swift
```

## iOS Views

### ServiceListView
```swift
struct ServiceListView: View {
    @ObservedObject var syncManager = ConfigSyncManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Smart Home") {
                    NavigationLink {
                        HomeAssistantFormView()
                    } label: {
                        ServiceRow(
                            icon: "house.fill",
                            name: "Home Assistant",
                            isConfigured: syncManager.config.homeAssistant != nil
                        )
                    }
                }

                Section("Media") {
                    NavigationLink {
                        PlexFormView()
                    } label: {
                        ServiceRow(icon: "play.tv.fill", name: "Plex",
                                   isConfigured: syncManager.config.plex != nil)
                    }

                    NavigationLink {
                        SonarrFormView()
                    } label: {
                        ServiceRow(icon: "tv", name: "Sonarr",
                                   isConfigured: syncManager.config.sonarr != nil)
                    }

                    NavigationLink {
                        RadarrFormView()
                    } label: {
                        ServiceRow(icon: "film", name: "Radarr",
                                   isConfigured: syncManager.config.radarr != nil)
                    }

                    NavigationLink {
                        SABnzbdFormView()
                    } label: {
                        ServiceRow(icon: "arrow.down.circle", name: "SABnzbd",
                                   isConfigured: syncManager.config.sabnzbd != nil)
                    }
                }

                Section("Infrastructure") {
                    NavigationLink {
                        ProxmoxFormView()
                    } label: {
                        ServiceRow(icon: "server.rack", name: "Proxmox",
                                   isConfigured: syncManager.config.proxmox != nil)
                    }

                    NavigationLink {
                        PiholeFormView()
                    } label: {
                        ServiceRow(icon: "shield.checkered", name: "Pi-hole",
                                   isConfigured: syncManager.config.pihole != nil)
                    }
                }

                Section("3D Printers") {
                    ForEach(syncManager.config.printers) { printer in
                        NavigationLink {
                            PrinterFormView(printer: printer)
                        } label: {
                            ServiceRow(icon: "printer.fill", name: printer.name,
                                       isConfigured: true)
                        }
                    }

                    Button {
                        // Add new printer
                    } label: {
                        Label("Add Printer", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("HomeStats Setup")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SyncStatusIndicator()
                }
            }
        }
    }
}
```

### Example Form View
```swift
struct HomeAssistantFormView: View {
    @ObservedObject var syncManager = ConfigSyncManager.shared
    @State private var url = ""
    @State private var token = ""
    @State private var testStatus: TestStatus = .idle

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $url)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .placeholder("http://192.168.1.100:8123")

                SecureField("Long-Lived Access Token", text: $token)
                    .autocapitalization(.none)
            } header: {
                Text("Connection")
            } footer: {
                Text("Create a token in Home Assistant: Profile → Long-Lived Access Tokens")
            }

            Section {
                TestConnectionButton(status: $testStatus) {
                    await testConnection()
                }
            }

            Section {
                Button("Save") {
                    syncManager.config.homeAssistant = HomeAssistantConfig(
                        url: url,
                        token: token
                    )
                    syncManager.save()
                }
                .disabled(url.isEmpty || token.isEmpty)
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

    private func testConnection() async {
        // Test the HA API connection
    }
}
```

## tvOS Integration

Update existing config files to use sync manager:

```swift
// HomeStats/Config/AppConfig.swift (tvOS)

import Foundation

enum AppConfig {
    static var shared: HomeStatsConfig {
        ConfigSyncManager.shared.config
    }

    // Convenience accessors
    static var homeAssistant: HomeAssistantConfig? { shared.homeAssistant }
    static var printers: [PrinterConfig] { shared.printers }
    // etc.
}
```

## Project Setup

1. Create new Xcode project: "HomeStats" with both tvOS and iOS targets
2. Move shared code to Shared folder, add to both targets
3. Enable iCloud capability on both targets:
   - iCloud → Key-value storage
4. Use same bundle ID prefix: `com.knophy.HomeStats` (tvOS) and `com.knophy.HomeStats.Companion` (iOS)

## Future Enhancements

- **Auto-discovery**: Use Bonjour to find Home Assistant, Plex on local network
- **QR scan**: Scan Home Assistant mobile app QR for quick setup
- **Backup/Restore**: Export config to file
- **Multiple homes**: Support different configs for different locations
