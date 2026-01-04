import Foundation

// MARK: - Main Config

enum AppMode: String, Codable, CaseIterable {
    case wife = "Simple"
    case geek = "Advanced"
}

struct HomeStatsConfig: Codable, Equatable {
    var appMode: AppMode = .wife
    var homeAssistant: HomeAssistantConfig?
    var plex: PlexConfig?
    var sonarr: ServiceConfig?
    var radarr: ServiceConfig?
    var sabnzbd: ServiceConfig?
    var proxmox: ProxmoxConfig?
    var pihole: PiholeConfig?
    var printers: [PrinterConfig]

    init(
        appMode: AppMode = .wife,
        homeAssistant: HomeAssistantConfig? = nil,
        plex: PlexConfig? = nil,
        sonarr: ServiceConfig? = nil,
        radarr: ServiceConfig? = nil,
        sabnzbd: ServiceConfig? = nil,
        proxmox: ProxmoxConfig? = nil,
        pihole: PiholeConfig? = nil,
        printers: [PrinterConfig] = []
    ) {
        self.appMode = appMode
        self.homeAssistant = homeAssistant
        self.plex = plex
        self.sonarr = sonarr
        self.radarr = radarr
        self.sabnzbd = sabnzbd
        self.proxmox = proxmox
        self.pihole = pihole
        self.printers = printers
    }

    static let cloudKey = "HomeStatsConfig"
}

// MARK: - Service Configs

struct HomeAssistantConfig: Codable, Equatable {
    var url: String
    var token: String

    var baseURL: URL? { URL(string: url) }
}

struct PlexConfig: Codable, Equatable {
    var url: String
    var token: String

    var baseURL: URL? { URL(string: url) }
}

struct ServiceConfig: Codable, Equatable {
    var url: String
    var apiKey: String

    var baseURL: URL? { URL(string: url) }
}

struct ProxmoxConfig: Codable, Equatable {
    var url: String
    var username: String
    var password: String
    var nodes: [String]

    var baseURL: URL? { URL(string: url) }

    init(url: String = "", username: String = "", password: String = "", nodes: [String] = []) {
        self.url = url
        self.username = username
        self.password = password
        self.nodes = nodes
    }
}

struct PiholeConfig: Codable, Equatable {
    var url: String
    var apiToken: String?

    var baseURL: URL? { URL(string: url) }
}

struct PrinterConfig: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var printerId: String
    var accessCode: String
    var amsId: String?

    init(id: String = UUID().uuidString, name: String = "", printerId: String = "", accessCode: String = "", amsId: String? = nil) {
        self.id = id
        self.name = name
        self.printerId = printerId
        self.accessCode = accessCode
        self.amsId = amsId
    }
}

// MARK: - Service Type Enum

enum ServiceType: String, CaseIterable, Identifiable {
    case homeAssistant = "Home Assistant"
    case plex = "Plex"
    case sonarr = "Sonarr"
    case radarr = "Radarr"
    case sabnzbd = "SABnzbd"
    case proxmox = "Proxmox"
    case pihole = "Pi-hole"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .homeAssistant: return "house.fill"
        case .plex: return "play.tv.fill"
        case .sonarr: return "tv"
        case .radarr: return "film"
        case .sabnzbd: return "arrow.down.circle"
        case .proxmox: return "server.rack"
        case .pihole: return "shield.checkered"
        }
    }

    var category: ServiceCategory {
        switch self {
        case .homeAssistant: return .smartHome
        case .plex, .sonarr, .radarr, .sabnzbd: return .media
        case .proxmox, .pihole: return .infrastructure
        }
    }

    var helpText: String {
        switch self {
        case .homeAssistant:
            return "Create a Long-Lived Access Token in Home Assistant: Profile → Security → Long-Lived Access Tokens"
        case .plex:
            return "Find your Plex token at plex.tv/claim or in Plex app XML responses"
        case .sonarr, .radarr:
            return "Find the API key in Settings → General → Security"
        case .sabnzbd:
            return "Find the API key in Config → General → Security"
        case .proxmox:
            return "Use your Proxmox VE login credentials (user@pam format)"
        case .pihole:
            return "Find the API token in Settings → API → Show API token"
        }
    }
}

enum ServiceCategory: String, CaseIterable {
    case smartHome = "Smart Home"
    case media = "Media"
    case infrastructure = "Infrastructure"
}
