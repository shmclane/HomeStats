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
}
