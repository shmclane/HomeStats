import Foundation
import Combine

@MainActor
class ProxmoxService: NSObject, ObservableObject, URLSessionDelegate {
    @Published var resources: [ProxmoxResource] = []
    @Published var nodeStatus: ProxmoxNodeStatus?
    @Published var rrdData: [ProxmoxRRDData] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var refreshTimer: Timer?
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var authHeader: String {
        "PVEAPIToken=\(AppConfig.proxmoxTokenId)=\(AppConfig.proxmoxToken)"
    }

    func fetchAll() async {
        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchResources() }
            group.addTask { await self.fetchNodeStatus() }
            group.addTask { await self.fetchRRDData() }
        }

        isLoading = false
    }

    func fetchResources() async {
        let url = AppConfig.proxmoxURL
            .appendingPathComponent("api2/json/cluster/resources")

        do {
            let data = try await fetchData(from: url)
            let response = try JSONDecoder().decode(ProxmoxResourcesResponse.self, from: data)
            resources = response.data.filter { !$0.isNode && !$0.isTemplate }
                .sorted { ($0.vmid ?? 0) < ($1.vmid ?? 0) }
        } catch {
            self.error = error
        }
    }

    func fetchNodeStatus() async {
        let url = AppConfig.proxmoxURL
            .appendingPathComponent("api2/json/nodes/\(AppConfig.proxmoxNode)/status")

        do {
            let data = try await fetchData(from: url)
            let response = try JSONDecoder().decode(ProxmoxNodeStatusResponse.self, from: data)
            nodeStatus = response.data
        } catch {
            print("Node status error: \(error)")
        }
    }

    func fetchRRDData() async {
        var components = URLComponents(url: AppConfig.proxmoxURL
            .appendingPathComponent("api2/json/nodes/\(AppConfig.proxmoxNode)/rrddata"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "timeframe", value: "day")]

        do {
            let data = try await fetchData(from: components.url!)
            let response = try JSONDecoder().decode(ProxmoxRRDResponse.self, from: data)
            rrdData = response.data ?? []
        } catch {
            print("RRD data error: \(error)")
        }
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxmoxError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ProxmoxError.httpError(httpResponse.statusCode)
        }

        return data
    }

    func startAutoRefresh(interval: TimeInterval = 30) {
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

    var runningVMs: [ProxmoxResource] {
        resources.filter { $0.isVM && $0.isRunning }
    }

    var stoppedVMs: [ProxmoxResource] {
        resources.filter { $0.isVM && !$0.isRunning }
    }

    var runningContainers: [ProxmoxResource] {
        resources.filter { $0.isContainer && $0.isRunning }
    }

    var stoppedContainers: [ProxmoxResource] {
        resources.filter { $0.isContainer && !$0.isRunning }
    }

    // MARK: - URLSessionDelegate (allow self-signed certs)

    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

enum ProxmoxError: LocalizedError {
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Proxmox"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
