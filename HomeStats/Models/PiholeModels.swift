import Foundation

struct PiholeAuthResponse: Codable {
    let session: PiholeSession
}

struct PiholeSession: Codable {
    let valid: Bool
    let sid: String
    let validity: Int
}

struct PiholeSummary: Codable {
    let queries: PiholeQueries
    let clients: PiholeClients
    let gravity: PiholeGravity
}

struct PiholeQueries: Codable {
    let total: Int
    let blocked: Int
    let percentBlocked: Double
    let uniqueDomains: Int
    let forwarded: Int
    let cached: Int

    enum CodingKeys: String, CodingKey {
        case total, blocked, forwarded, cached
        case percentBlocked = "percent_blocked"
        case uniqueDomains = "unique_domains"
    }
}

struct PiholeClients: Codable {
    let active: Int
    let total: Int
}

struct PiholeGravity: Codable {
    let domainsBeingBlocked: Int
    let lastUpdate: Int

    enum CodingKeys: String, CodingKey {
        case domainsBeingBlocked = "domains_being_blocked"
        case lastUpdate = "last_update"
    }
}

struct PiholeSummaryResponse: Codable {
    let queries: PiholeQueries
    let clients: PiholeClients
    let gravity: PiholeGravity
}

struct PiholeHistoryResponse: Codable {
    let history: [PiholeHistoryPoint]
}

struct PiholeHistoryPoint: Codable, Identifiable {
    var id: Int { timestamp }
    let timestamp: Int
    let total: Int
    let cached: Int
    let blocked: Int
    let forwarded: Int

    var date: Date {
        Date(timeIntervalSince1970: Double(timestamp))
    }
}
