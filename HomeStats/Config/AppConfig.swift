import Foundation

enum AppConfig {
    static let haURL = URL(string: "http://172.16.1.9:8123")!
    static let haToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIxYWFhMGFiYjZkMmQ0OTdlYmI5N2NjYWZlZDdkZDI3MSIsImlhdCI6MTc2Njg4NzA5NSwiZXhwIjoyMDgyMjQ3MDk1fQ.QU1dBDeU7M_JM5pwAa1u-zMhWkPkCamtcCimDT1F65c"
    static let refreshInterval: TimeInterval = 10

    // Entity filters for main dashboard - set to nil to show all
    static let allowedDomains: Set<String>? = ["cover", "light", "camera", "sensor"]
    static let nameFilters: [String]? = ["big door", "kitchen", "boatsy"]  // Case-insensitive, matches ANY

    // Printer configurations
    static let printers: [(name: String, id: String, amsId: String?)] = [
        ("DB Galore", "p1s_01p00a3c0500019", "p1s_01p00a3c0500019"),
        ("Boatsy", "boatsy", "p1s_01p09c532500949")  // Boatsy uses different AMS
    ]

    // Proxmox configuration
    static let proxmoxURL = URL(string: "https://172.16.1.10:8006")!
    static let proxmoxTokenId = "root@pam!homestats"
    static let proxmoxToken = "e51da962-628b-42a3-b117-dc34b3faf3ad"
    static let proxmoxNode = "pm3"

    // Pi-hole configuration
    static let piholeURL = URL(string: "http://172.16.1.2")!
    static let piholePassword = "9CTIgmxpf3cOXkayTg3GHFkuFcc8mY7iuKFabyYK9ZU="
}
