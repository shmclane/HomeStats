import Foundation
import Combine

@MainActor
class ConfigSyncManager: ObservableObject {
    static let shared = ConfigSyncManager()

    // Thread-safe accessor for config values (for use in non-MainActor contexts)
    nonisolated static var currentConfig: HomeStatsConfig {
        if let data = UserDefaults.standard.data(forKey: "HomeStatsConfig_Local"),
           let config = try? JSONDecoder().decode(HomeStatsConfig.self, from: data) {
            return config
        }
        return HomeStatsConfig()
    }

    @Published var config: HomeStatsConfig {
        didSet {
            if config != oldValue {
                saveToCloud()
            }
        }
    }

    @Published var lastSyncDate: Date?
    @Published var syncStatus: SyncStatus = .idle

    private let store = NSUbiquitousKeyValueStore.default
    private let localDefaults = UserDefaults.standard
    private let localKey = "HomeStatsConfig_Local"

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case error(String)
    }

    private init() {
        // Load from local first, then cloud
        config = Self.loadLocal() ?? Self.loadFromCloud() ?? HomeStatsConfig()

        // Listen for cloud changes
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleCloudChange(notification)
            }
        }

        // Trigger initial sync
        store.synchronize()
    }

    // MARK: - Public Methods

    func save() {
        saveToLocal()
        saveToCloud()
    }

    func refresh() {
        syncStatus = .syncing
        store.synchronize()

        if let cloudConfig = Self.loadFromCloud() {
            config = cloudConfig
            saveToLocal()
            lastSyncDate = Date()
            syncStatus = .synced
        } else {
            syncStatus = .idle
        }
    }

    // MARK: - Service Convenience Methods

    func isConfigured(_ service: ServiceType) -> Bool {
        switch service {
        case .homeAssistant: return config.homeAssistant != nil
        case .plex: return config.plex != nil
        case .sonarr: return config.sonarr != nil
        case .radarr: return config.radarr != nil
        case .sabnzbd: return config.sabnzbd != nil
        case .proxmox: return config.proxmox != nil
        case .pihole: return config.pihole != nil
        }
    }

    // MARK: - Private Methods

    private func saveToLocal() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        localDefaults.set(data, forKey: localKey)
    }

    private func saveToCloud() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        syncStatus = .syncing
        store.set(data, forKey: HomeStatsConfig.cloudKey)
        store.synchronize()
        lastSyncDate = Date()
        syncStatus = .synced
    }

    private static func loadLocal() -> HomeStatsConfig? {
        guard let data = UserDefaults.standard.data(forKey: "HomeStatsConfig_Local"),
              let config = try? JSONDecoder().decode(HomeStatsConfig.self, from: data) else {
            return nil
        }
        return config
    }

    private static func loadFromCloud() -> HomeStatsConfig? {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: HomeStatsConfig.cloudKey),
              let config = try? JSONDecoder().decode(HomeStatsConfig.self, from: data) else {
            return nil
        }
        return config
    }

    private func handleCloudChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // Data changed on server or initial sync
            if let cloudConfig = Self.loadFromCloud() {
                config = cloudConfig
                saveToLocal()
                lastSyncDate = Date()
                syncStatus = .synced
            }

        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            syncStatus = .error("iCloud storage quota exceeded")

        case NSUbiquitousKeyValueStoreAccountChange:
            // iCloud account changed, reload
            refresh()

        default:
            break
        }
    }
}

// MARK: - Insecure URLSession for Self-Signed Certs

class InsecureURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Connection Testing

extension ConfigSyncManager {
    private var urlSession: URLSession {
        if config.allowInsecureCerts {
            let delegate = InsecureURLSessionDelegate()
            return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        }
        return URLSession.shared
    }

    func testConnection(for service: ServiceType) async -> Result<String, Error> {
        switch service {
        case .homeAssistant:
            return await testHomeAssistant()
        case .plex:
            return await testPlex()
        case .sonarr:
            return await testSonarr()
        case .radarr:
            return await testRadarr()
        case .sabnzbd:
            return await testSABnzbd()
        case .proxmox:
            return await testProxmox()
        case .pihole:
            return await testPihole()
        }
    }

    private func testHomeAssistant() async -> Result<String, Error> {
        guard let ha = config.homeAssistant, let url = ha.baseURL else {
            return .failure(ConfigError.notConfigured)
        }

        var request = URLRequest(url: url.appendingPathComponent("api/"))
        request.setValue("Bearer \(ha.token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .success("Connected to Home Assistant")
            }
            return .failure(ConfigError.invalidResponse)
        } catch {
            return .failure(error)
        }
    }

    private func testPlex() async -> Result<String, Error> {
        guard let plex = config.plex, let url = plex.baseURL else {
            return .failure(ConfigError.notConfigured)
        }

        var request = URLRequest(url: url)
        request.setValue(plex.token, forHTTPHeaderField: "X-Plex-Token")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .success("Connected to Plex")
            }
            return .failure(ConfigError.invalidResponse)
        } catch {
            return .failure(error)
        }
    }

    private func testSonarr() async -> Result<String, Error> {
        guard let sonarr = config.sonarr, let url = sonarr.baseURL else {
            return .failure(ConfigError.notConfigured)
        }

        var request = URLRequest(url: url.appendingPathComponent("api/v3/system/status"))
        request.setValue(sonarr.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .success("Connected to Sonarr")
            }
            return .failure(ConfigError.invalidResponse)
        } catch {
            return .failure(error)
        }
    }

    private func testRadarr() async -> Result<String, Error> {
        guard let radarr = config.radarr, let url = radarr.baseURL else {
            return .failure(ConfigError.notConfigured)
        }

        var request = URLRequest(url: url.appendingPathComponent("api/v3/system/status"))
        request.setValue(radarr.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .success("Connected to Radarr")
            }
            return .failure(ConfigError.invalidResponse)
        } catch {
            return .failure(error)
        }
    }

    private func testSABnzbd() async -> Result<String, Error> {
        guard let sab = config.sabnzbd, let url = sab.baseURL else {
            return .failure(ConfigError.notConfigured)
        }

        var components = URLComponents(url: url.appendingPathComponent("api"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "mode", value: "version"),
            URLQueryItem(name: "output", value: "json"),
            URLQueryItem(name: "apikey", value: sab.apiKey)
        ]

        do {
            let (_, response) = try await urlSession.data(from: components.url!)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .success("Connected to SABnzbd")
            }
            return .failure(ConfigError.invalidResponse)
        } catch {
            return .failure(error)
        }
    }

    private func testProxmox() async -> Result<String, Error> {
        guard let proxmox = config.proxmox, let url = proxmox.baseURL else {
            return .failure(ConfigError.notConfigured)
        }

        // Proxmox needs auth first, just test reachability
        var request = URLRequest(url: url.appendingPathComponent("api2/json/version"))
        request.timeoutInterval = 10

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...401).contains(httpResponse.statusCode) {
                return .success("Proxmox server reachable")
            }
            return .failure(ConfigError.invalidResponse)
        } catch {
            return .failure(error)
        }
    }

    private func testPihole() async -> Result<String, Error> {
        guard let pihole = config.pihole, let url = pihole.baseURL else {
            return .failure(ConfigError.notConfigured)
        }

        var request = URLRequest(url: url.appendingPathComponent("admin/api.php"))
        request.timeoutInterval = 10

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .success("Connected to Pi-hole")
            }
            return .failure(ConfigError.invalidResponse)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Errors

enum ConfigError: LocalizedError {
    case notConfigured
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Service not configured"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}
