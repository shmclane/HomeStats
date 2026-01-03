import SwiftUI

// MARK: - Focused Item Type

enum FocusedMediaItem: Equatable {
    case episode(SonarrEpisode)
    case plex(PlexMediaItem)
    case radarr(RadarrMovie)

    static func == (lhs: FocusedMediaItem, rhs: FocusedMediaItem) -> Bool {
        switch (lhs, rhs) {
        case (.episode(let a), .episode(let b)): return a.id == b.id
        case (.plex(let a), .plex(let b)): return a.id == b.id
        case (.radarr(let a), .radarr(let b)): return a.id == b.id
        default: return false
        }
    }
}

struct MediaDashboardView: View {
    @StateObject private var service = MediaDashboardService()
    @State private var focusedItem: FocusedMediaItem?

    var body: some View {
        HStack(spacing: 0) {
            // Main content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView

                    // Upcoming Episodes
                    if !service.upcomingEpisodes.isEmpty {
                        MediaSection(title: "Coming Soon", icon: "tv.fill") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(service.upcomingEpisodes) { episode in
                                        EpisodeCard(episode: episode, onFocus: { focused in
                                            if focused {
                                                focusedItem = .episode(episode)
                                            }
                                        })
                                    }
                                }
                                .padding(.horizontal, 48)
                            }
                        }
                    }

                    // Recently Added to Plex (TV + Movies)
                    if !service.recentPlexTV.isEmpty || !service.recentPlexMovies.isEmpty {
                        MediaSection(title: "Recently Added", icon: "play.rectangle.fill") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(service.recentPlexTV) { item in
                                        PlexCard(item: item, onFocus: { focused in
                                            if focused {
                                                focusedItem = .plex(item)
                                            }
                                        })
                                    }
                                    ForEach(service.recentPlexMovies) { item in
                                        PlexCard(item: item, onFocus: { focused in
                                            if focused {
                                                focusedItem = .plex(item)
                                            }
                                        })
                                    }
                                }
                                .padding(.horizontal, 48)
                            }
                        }
                    }

                    // Recent Movies
                    if !service.recentMovies.isEmpty {
                        MediaSection(title: "Movie Library", icon: "film.fill") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(service.recentMovies) { movie in
                                        MovieCard(movie: movie, onFocus: { focused in
                                            if focused {
                                                focusedItem = .radarr(movie)
                                            }
                                        })
                                    }
                                }
                                .padding(.horizontal, 48)
                            }
                        }
                    }

                    if service.recentPlexTV.isEmpty && service.recentPlexMovies.isEmpty && service.upcomingEpisodes.isEmpty && service.recentMovies.isEmpty && !service.isLoading {
                        Text("No media data available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(100)
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(maxWidth: focusedItem != nil ? .infinity : .infinity)

            // Slide-out detail panel (1/3 width)
            if let item = focusedItem {
                MediaDetailPanel(item: item)
                    .frame(width: 500)
                    .transition(.move(edge: .trailing))
            }
        }
        .background(Color.black)
        .animation(.easeInOut(duration: 0.25), value: focusedItem != nil)
        .onExitCommand {
            if focusedItem != nil {
                focusedItem = nil
            }
        }
        .onAppear {
            service.startAutoRefresh(interval: 60)
        }
        .onDisappear {
            service.stopAutoRefresh()
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 12) {
                    if let sab = service.downloads {
                        // Status pill
                        SABStatusPill(
                            icon: sab.paused ? "pause.circle.fill" : "arrow.down.circle.fill",
                            text: sab.paused ? "Paused" : "Active",
                            color: sab.paused ? .yellow : .green
                        )

                        // Speed pill
                        SABStatusPill(
                            icon: "speedometer",
                            text: "\(sab.speed)/s",
                            color: .blue
                        )

                        // Queue depth pill
                        SABStatusPill(
                            icon: "tray.full.fill",
                            text: "\(sab.queueCount)",
                            color: sab.queueCount > 0 ? .orange : .gray
                        )
                    }

                    if service.isLoading {
                        ProgressView()
                    }
                }

                if let lastUpdated = service.lastUpdated {
                    Text("Updated \(lastUpdated, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.trailing, 48)
        }
    }
}

// MARK: - SABnzbd Status Pill

struct SABStatusPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(16)
    }
}

// MARK: - Section Container

struct MediaSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.title3.bold())
            }
            .padding(.horizontal, 48)

            content
        }
    }
}

// MARK: - Episode Card

struct EpisodeCard: View {
    let episode: SonarrEpisode
    var onFocus: ((Bool) -> Void)?
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster
                AsyncImage(url: episode.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(Color(white: 0.2))
                            .aspectRatio(2/3, contentMode: .fill)
                            .overlay(
                                Image(systemName: "tv")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle().fill(Color(white: 0.2))
                    }
                }
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(episode.seriesTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("S\(episode.seasonNumber)E\(episode.episodeNumber)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .frame(width: 120, alignment: .leading)
                .padding(.top, 6)
            }
        }
        .buttonStyle(MediaCardButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            onFocus?(newValue)
        }
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .zIndex(isFocused ? 100 : 0)
    }
}

// MARK: - Plex Card

struct PlexCard: View {
    let item: PlexMediaItem
    var onFocus: ((Bool) -> Void)?
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster
                AsyncImage(url: item.thumbURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(Color(white: 0.2))
                            .aspectRatio(2/3, contentMode: .fill)
                            .overlay(
                                Image(systemName: item.type == .movie ? "film" : "tv")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle().fill(Color(white: 0.2))
                    }
                }
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(item.type == .movie ? "Movie" : "TV")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(item.type == .movie ? Color.purple : Color.blue)
                        .cornerRadius(3)
                }
                .frame(width: 120, alignment: .leading)
                .padding(.top, 6)
            }
        }
        .buttonStyle(MediaCardButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            onFocus?(newValue)
        }
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .zIndex(isFocused ? 100 : 0)
    }
}

// MARK: - Movie Card

struct MovieCard: View {
    let movie: RadarrMovie
    var onFocus: ((Bool) -> Void)?
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster
                AsyncImage(url: movie.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(Color(white: 0.2))
                            .aspectRatio(2/3, contentMode: .fill)
                            .overlay(
                                Image(systemName: "film")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle().fill(Color(white: 0.2))
                    }
                }
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(movie.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(String(movie.year))
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if movie.hasFile {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Available")
                                .foregroundColor(.green)
                        }
                        .font(.caption2)
                    }
                }
                .frame(width: 120, alignment: .leading)
                .padding(.top, 6)
            }
        }
        .buttonStyle(MediaCardButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            onFocus?(newValue)
        }
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .zIndex(isFocused ? 100 : 0)
    }
}

// MARK: - Media Detail Panel

struct MediaDetailPanel: View {
    let item: FocusedMediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Poster
            posterView
                .frame(height: 300)
                .cornerRadius(12)
                .clipped()

            // Title and metadata
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .lineLimit(2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.blue)

                if let year = year {
                    Text(String(year))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let summary = summary {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(8)
                        .padding(.top, 8)
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color(white: 0.1))
    }

    private var title: String {
        switch item {
        case .episode(let ep): return ep.seriesTitle
        case .plex(let p): return p.title
        case .radarr(let m): return m.title
        }
    }

    private var subtitle: String {
        switch item {
        case .episode(let ep): return "S\(ep.seasonNumber)E\(ep.episodeNumber) - \(ep.episodeTitle)"
        case .plex(let p): return p.type == .movie ? "Movie" : "TV Series"
        case .radarr(let m): return m.hasFile ? "Available" : m.status
        }
    }

    private var year: Int? {
        switch item {
        case .episode: return nil
        case .plex(let p): return p.year
        case .radarr(let m): return m.year
        }
    }

    private var summary: String? {
        switch item {
        case .episode(let ep): return ep.overview
        case .plex(let p): return p.summary
        case .radarr: return nil
        }
    }

    @ViewBuilder
    private var posterView: some View {
        switch item {
        case .episode(let ep):
            AsyncImage(url: ep.posterURL) { phase in
                posterPhaseView(phase, icon: "tv")
            }
        case .plex(let p):
            AsyncImage(url: p.thumbURL) { phase in
                posterPhaseView(phase, icon: p.type == .movie ? "film" : "tv")
            }
        case .radarr(let m):
            AsyncImage(url: m.posterURL) { phase in
                posterPhaseView(phase, icon: "film")
            }
        }
    }

    @ViewBuilder
    private func posterPhaseView(_ phase: AsyncImagePhase, icon: String) -> some View {
        switch phase {
        case .success(let image):
            image
                .resizable()
                .aspectRatio(2/3, contentMode: .fit)
        case .failure, .empty:
            Rectangle()
                .fill(Color(white: 0.2))
                .aspectRatio(2/3, contentMode: .fit)
                .overlay(
                    Image(systemName: icon)
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
        @unknown default:
            Rectangle().fill(Color(white: 0.2))
        }
    }
}

// MARK: - Media Card Button Style

struct MediaCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    MediaDashboardView()
}
