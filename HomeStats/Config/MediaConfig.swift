import Foundation

enum MediaConfig {
    // MARK: - Synced Config (from iOS companion app)

    private static var syncedConfig: HomeStatsConfig {
        ConfigSyncManager.currentConfig
    }

    // MARK: - Radarr

    static var radarrURL: URL {
        syncedConfig.radarr?.baseURL ?? defaultRadarrURL
    }

    static var radarrAPIKey: String {
        syncedConfig.radarr?.apiKey ?? defaultRadarrAPIKey
    }

    // MARK: - Sonarr

    static var sonarrURL: URL {
        syncedConfig.sonarr?.baseURL ?? defaultSonarrURL
    }

    static var sonarrAPIKey: String {
        syncedConfig.sonarr?.apiKey ?? defaultSonarrAPIKey
    }

    // MARK: - Plex

    static var plexURL: URL {
        syncedConfig.plex?.baseURL ?? defaultPlexURL
    }

    static var plexToken: String {
        syncedConfig.plex?.token ?? defaultPlexToken
    }

    // MARK: - SABnzbd

    static var sabnzbdURL: URL {
        syncedConfig.sabnzbd?.baseURL ?? defaultSABnzbdURL
    }

    static var sabnzbdAPIKey: String {
        syncedConfig.sabnzbd?.apiKey ?? defaultSABnzbdAPIKey
    }

    // MARK: - Default Values (fallbacks)

    private static let defaultRadarrURL = URL(string: "http://10.0.0.156:7878")!
    private static let defaultRadarrAPIKey = "08f8505fdf7b4bd393e95e0691c102ed"

    private static let defaultSonarrURL = URL(string: "http://10.0.0.156:8989")!
    private static let defaultSonarrAPIKey = "bd86ffe8538549989083e7f014782bdd"

    private static let defaultPlexURL = URL(string: "http://10.0.0.156:32400")!
    private static let defaultPlexToken = "h15BaG-SM4Ad78BLJQSc"

    private static let defaultSABnzbdURL = URL(string: "http://10.0.0.156:8080")!
    private static let defaultSABnzbdAPIKey = "d724788bfdb74d9fa97f8828e48feb0f"
}
