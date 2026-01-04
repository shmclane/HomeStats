import Foundation

enum AppConfig {
    // MARK: - Synced Config (from iOS companion app)

    private static var syncedConfig: HomeStatsConfig {
        ConfigSyncManager.currentConfig
    }

    // MARK: - Home Assistant

    static var haURL: URL {
        syncedConfig.homeAssistant?.baseURL ?? defaultHAURL
    }

    static var haToken: String {
        syncedConfig.homeAssistant?.token ?? defaultHAToken
    }

    static let refreshInterval: TimeInterval = 10

    // Entity filters for main dashboard - set to nil to show all
    static let allowedDomains: Set<String>? = ["cover", "light", "camera", "sensor"]
    static let nameFilters: [String]? = ["big door", "kitchen", "boatsy"]  // Case-insensitive, matches ANY

    // MARK: - Printers

    static var printers: [(name: String, id: String, amsId: String?)] {
        let syncedPrinters = syncedConfig.printers
        if !syncedPrinters.isEmpty {
            return syncedPrinters.map { ($0.name, $0.printerId, $0.amsId) }
        }
        return defaultPrinters
    }

    // MARK: - Proxmox

    static var proxmoxURL: URL {
        syncedConfig.proxmox?.baseURL ?? defaultProxmoxURL
    }

    static var proxmoxUsername: String {
        syncedConfig.proxmox?.username ?? defaultProxmoxTokenId
    }

    static var proxmoxPassword: String {
        syncedConfig.proxmox?.password ?? defaultProxmoxToken
    }

    static var proxmoxNode: String {
        syncedConfig.proxmox?.nodes.first ?? defaultProxmoxNode
    }

    // Legacy accessors for existing code
    static var proxmoxTokenId: String { proxmoxUsername }
    static var proxmoxToken: String { proxmoxPassword }

    // MARK: - Pi-hole

    static var piholeURL: URL {
        syncedConfig.pihole?.baseURL ?? defaultPiholeURL
    }

    static var piholePassword: String {
        syncedConfig.pihole?.apiToken ?? defaultPiholePassword
    }

    // MARK: - Default Values (fallbacks)

    private static let defaultHAURL = URL(string: "http://172.16.1.9:8123")!
    private static let defaultHAToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJiMGUxNTQwYTczZGM0MGU2YTY5YjY3ZDI3Zjg3NzhlYiIsImlhdCI6MTc2NzQ2Njg0MSwiZXhwIjoyMDgyODI2ODQxfQ.DLk1CNzqLY3aT2xNgbstUqYShpRuj_gWd-A_cMnsUQ4"

    private static let defaultPrinters: [(name: String, id: String, amsId: String?)] = [
        ("DB Galore", "p1s_01p00a3c0500019", "p1s_01p00a3c0500019"),
        ("Boatsy", "boatsy", "p1s_01p09c532500949")
    ]

    private static let defaultProxmoxURL = URL(string: "https://172.16.1.10:8006")!
    private static let defaultProxmoxTokenId = "root@pam!homestats"
    private static let defaultProxmoxToken = "e51da962-628b-42a3-b117-dc34b3faf3ad"
    private static let defaultProxmoxNode = "pm3"

    private static let defaultPiholeURL = URL(string: "http://172.16.1.2")!
    private static let defaultPiholePassword = "9CTIgmxpf3cOXkayTg3GHFkuFcc8mY7iuKFabyYK9ZU="
}
