import Foundation

// MARK: - Plex Models

struct PlexMediaItem: Identifiable {
    let id: String
    let title: String
    let year: Int?
    let type: MediaType
    let thumbURL: URL?
    let addedAt: Date
    let summary: String?

    enum MediaType: String {
        case movie, show, episode
    }
}

// MARK: - Sonarr Models

struct SonarrEpisode: Identifiable {
    let id: Int
    let seriesTitle: String
    let episodeTitle: String
    let seasonNumber: Int
    let episodeNumber: Int
    let airDate: Date
    let overview: String?
    let posterURL: URL?
    let hasFile: Bool
}

struct SonarrQueueItem: Identifiable {
    let id: Int
    let seriesTitle: String
    let episodeTitle: String
    let status: String
    let progress: Double
}

// MARK: - Radarr Models

struct RadarrMovie: Identifiable {
    let id: Int
    let title: String
    let year: Int
    let posterURL: URL?
    let status: String
    let hasFile: Bool
    let addedDate: Date?
    let physicalRelease: Date?
}

// MARK: - SABnzbd Models

struct SABDownload: Identifiable {
    let id: String
    let name: String
    let status: String
    let progress: Double
    let sizeLeft: String
    let eta: String
}

struct SABStatus {
    let speed: String
    let sizeLeft: String
    let eta: String
    let paused: Bool
    let queueCount: Int
    let queue: [SABDownload]
}
