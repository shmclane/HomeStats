import Foundation

enum MediaConfig {
    // Radarr
    static let radarrURL = URL(string: "http://10.0.0.156:7878")!
    static let radarrAPIKey = "08f8505fdf7b4bd393e95e0691c102ed"

    // Sonarr
    static let sonarrURL = URL(string: "http://10.0.0.156:8989")!
    static let sonarrAPIKey = "bd86ffe8538549989083e7f014782bdd"

    // Plex
    static let plexURL = URL(string: "http://10.0.0.156:32400")!
    static let plexToken = "h15BaG-SM4Ad78BLJQSc"

    // SABnzbd
    static let sabnzbdURL = URL(string: "http://10.0.0.156:8080")!
    static let sabnzbdAPIKey = "d724788bfdb74d9fa97f8828e48feb0f"
}
