import Foundation

@MainActor
class MediaDashboardService: ObservableObject {
    @Published var recentPlexTV: [PlexMediaItem] = []
    @Published var recentPlexMovies: [PlexMediaItem] = []
    @Published var upcomingEpisodes: [SonarrEpisode] = []
    @Published var recentMovies: [RadarrMovie] = []
    @Published var downloads: SABStatus?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?

    private var refreshTimer: Timer?

    func fetchAll() async {
        isLoading = true
        error = nil

        async let plex = fetchPlexRecent()
        async let sonarr = fetchSonarrUpcoming()
        async let radarr = fetchRadarrRecent()
        async let sab = fetchSABnzbd()

        let (plexResult, sonarrResult, radarrResult, sabResult) = await (plex, sonarr, radarr, sab)

        // Split Plex results into TV and Movies (5 each)
        recentPlexTV = Array(plexResult.filter { $0.type != .movie }.prefix(5))
        recentPlexMovies = Array(plexResult.filter { $0.type == .movie }.prefix(5))
        upcomingEpisodes = sonarrResult
        recentMovies = radarrResult
        downloads = sabResult

        lastUpdated = Date()
        isLoading = false
    }

    // MARK: - Plex

    private func fetchPlexRecent() async -> [PlexMediaItem] {
        let url = MediaConfig.plexURL
            .appendingPathComponent("library/recentlyAdded")
        var request = URLRequest(url: url)
        request.setValue(MediaConfig.plexToken, forHTTPHeaderField: "X-Plex-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parsePlexResponse(data)
        } catch {
            print("Plex error: \(error)")
            return []
        }
    }

    private func parsePlexResponse(_ data: Data) -> [PlexMediaItem] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any],
              let metadata = container["Metadata"] as? [[String: Any]] else {
            return []
        }

        return metadata.prefix(20).compactMap { item -> PlexMediaItem? in
            guard let ratingKey = item["ratingKey"] as? String,
                  let rawTitle = item["title"] as? String,
                  let type = item["type"] as? String,
                  let addedAt = item["addedAt"] as? Int else {
                return nil
            }

            // For seasons/episodes, use parentTitle (show name) instead of "Season 1"
            let title: String
            if type == "season" || type == "episode" {
                title = (item["parentTitle"] as? String) ?? (item["grandparentTitle"] as? String) ?? rawTitle
            } else {
                title = rawTitle
            }

            var thumbURL: URL?
            // Try thumb, then parentThumb for seasons
            if let thumb = item["thumb"] as? String {
                thumbURL = URL(string: "\(MediaConfig.plexURL.absoluteString)\(thumb)?X-Plex-Token=\(MediaConfig.plexToken)")
            } else if let parentThumb = item["parentThumb"] as? String {
                thumbURL = URL(string: "\(MediaConfig.plexURL.absoluteString)\(parentThumb)?X-Plex-Token=\(MediaConfig.plexToken)")
            }

            let mediaType: PlexMediaItem.MediaType
            switch type {
            case "movie": mediaType = .movie
            case "show", "season", "episode": mediaType = .show
            default: mediaType = .show
            }

            return PlexMediaItem(
                id: ratingKey,
                title: title,
                year: item["year"] as? Int,
                type: mediaType,
                thumbURL: thumbURL,
                addedAt: Date(timeIntervalSince1970: TimeInterval(addedAt)),
                summary: item["summary"] as? String
            )
        }
    }

    // MARK: - Sonarr

    private func fetchSonarrUpcoming() async -> [SonarrEpisode] {
        let calendar = Calendar.current
        let start = Date()
        let end = calendar.date(byAdding: .day, value: 2, to: start)!

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var components = URLComponents(url: MediaConfig.sonarrURL.appendingPathComponent("api/v3/calendar"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "start", value: formatter.string(from: start)),
            URLQueryItem(name: "end", value: formatter.string(from: end)),
            URLQueryItem(name: "includeSeries", value: "true"),
            URLQueryItem(name: "includeEpisodeFile", value: "true")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(MediaConfig.sonarrAPIKey, forHTTPHeaderField: "X-Api-Key")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parseSonarrResponse(data)
        } catch {
            print("Sonarr error: \(error)")
            return []
        }
    }

    private func parseSonarrResponse(_ data: Data) -> [SonarrEpisode] {
        guard let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return items.compactMap { item -> SonarrEpisode? in
            guard let id = item["id"] as? Int,
                  let title = item["title"] as? String,
                  let seasonNumber = item["seasonNumber"] as? Int,
                  let episodeNumber = item["episodeNumber"] as? Int else {
                return nil
            }

            let series = item["series"] as? [String: Any]
            let seriesTitle = series?["title"] as? String ?? "Unknown"

            var airDate = Date()
            if let airDateStr = item["airDateUtc"] as? String {
                airDate = dateFormatter.date(from: airDateStr) ?? Date()
            }

            var posterURL: URL?
            if let images = series?["images"] as? [[String: Any]] {
                if let poster = images.first(where: { ($0["coverType"] as? String) == "poster" }),
                   let remotePath = poster["remoteUrl"] as? String {
                    posterURL = URL(string: remotePath)
                }
            }

            return SonarrEpisode(
                id: id,
                seriesTitle: seriesTitle,
                episodeTitle: title,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                airDate: airDate,
                overview: item["overview"] as? String,
                posterURL: posterURL,
                hasFile: item["hasFile"] as? Bool ?? false
            )
        }
    }

    // MARK: - Radarr

    private func fetchRadarrRecent() async -> [RadarrMovie] {
        var components = URLComponents(url: MediaConfig.radarrURL.appendingPathComponent("api/v3/movie"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "apikey", value: MediaConfig.radarrAPIKey)]

        var request = URLRequest(url: components.url!)
        request.setValue(MediaConfig.radarrAPIKey, forHTTPHeaderField: "X-Api-Key")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parseRadarrResponse(data)
        } catch {
            print("Radarr error: \(error)")
            return []
        }
    }

    private func parseRadarrResponse(_ data: Data) -> [RadarrMovie] {
        guard let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()

        // Get movies with files, sorted by added date
        let moviesWithFiles = items
            .filter { ($0["hasFile"] as? Bool) == true }
            .compactMap { item -> RadarrMovie? in
                guard let id = item["id"] as? Int,
                      let title = item["title"] as? String,
                      let year = item["year"] as? Int else {
                    return nil
                }

                var posterURL: URL?
                if let images = item["images"] as? [[String: Any]] {
                    if let poster = images.first(where: { ($0["coverType"] as? String) == "poster" }),
                       let remotePath = poster["remoteUrl"] as? String {
                        posterURL = URL(string: remotePath)
                    }
                }

                var addedDate: Date?
                if let added = item["added"] as? String {
                    addedDate = dateFormatter.date(from: added)
                }

                return RadarrMovie(
                    id: id,
                    title: title,
                    year: year,
                    posterURL: posterURL,
                    status: item["status"] as? String ?? "",
                    hasFile: true,
                    addedDate: addedDate,
                    physicalRelease: nil
                )
            }
            .sorted { ($0.addedDate ?? .distantPast) > ($1.addedDate ?? .distantPast) }

        return Array(moviesWithFiles.prefix(10))
    }

    // MARK: - SABnzbd

    private func fetchSABnzbd() async -> SABStatus? {
        var components = URLComponents(url: MediaConfig.sabnzbdURL.appendingPathComponent("api"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "mode", value: "queue"),
            URLQueryItem(name: "output", value: "json"),
            URLQueryItem(name: "apikey", value: MediaConfig.sabnzbdAPIKey)
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return parseSABnzbdResponse(data)
        } catch {
            print("SABnzbd error: \(error)")
            return nil
        }
    }

    private func parseSABnzbdResponse(_ data: Data) -> SABStatus? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let queue = json["queue"] as? [String: Any] else {
            return nil
        }

        let speed = queue["speed"] as? String ?? "0"
        let sizeLeft = queue["sizeleft"] as? String ?? "0 B"
        let eta = queue["eta"] as? String ?? ""
        let paused = (queue["paused"] as? Bool) ?? false
        let queueCount = (queue["noofslots_total"] as? Int) ?? 0

        var downloads: [SABDownload] = []
        if let slots = queue["slots"] as? [[String: Any]] {
            downloads = slots.prefix(5).compactMap { slot -> SABDownload? in
                guard let id = slot["nzo_id"] as? String,
                      let name = slot["filename"] as? String else {
                    return nil
                }
                let status = slot["status"] as? String ?? ""
                let percentage = Double(slot["percentage"] as? String ?? "0") ?? 0
                let slotSizeLeft = slot["sizeleft"] as? String ?? ""
                let slotEta = slot["timeleft"] as? String ?? ""

                return SABDownload(
                    id: id,
                    name: name,
                    status: status,
                    progress: percentage / 100.0,
                    sizeLeft: slotSizeLeft,
                    eta: slotEta
                )
            }
        }

        return SABStatus(
            speed: speed,
            sizeLeft: sizeLeft,
            eta: eta,
            paused: paused,
            queueCount: queueCount,
            queue: downloads
        )
    }

    // MARK: - Auto Refresh

    func startAutoRefresh(interval: TimeInterval = 60) {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchAll()
            }
        }
        Task { await fetchAll() }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
