import Foundation

@MainActor
class PiholeService: ObservableObject {
    @Published var summary: PiholeSummary?
    @Published var history: [PiholeHistoryPoint] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var refreshTimer: Timer?
    private var sessionId: String?
    private var sessionExpiry: Date?

    func fetchAll() async {
        isLoading = true
        error = nil

        do {
            try await ensureAuthenticated()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.fetchSummary() }
                group.addTask { await self.fetchHistory() }
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func ensureAuthenticated() async throws {
        if let expiry = sessionExpiry, Date() < expiry, sessionId != nil {
            return
        }

        let url = AppConfig.piholeURL.appendingPathComponent("api/auth")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["password": AppConfig.piholePassword]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(PiholeAuthResponse.self, from: data)

        if response.session.valid {
            sessionId = response.session.sid
            sessionExpiry = Date().addingTimeInterval(Double(response.session.validity - 60))
        } else {
            throw PiholeError.authenticationFailed
        }
    }

    private func fetchSummary() async {
        guard let sid = sessionId else { return }

        let url = AppConfig.piholeURL.appendingPathComponent("api/stats/summary")
        var request = URLRequest(url: url)
        request.setValue(sid, forHTTPHeaderField: "sid")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(PiholeSummaryResponse.self, from: data)
            summary = PiholeSummary(
                queries: response.queries,
                clients: response.clients,
                gravity: response.gravity
            )
        } catch {
            print("Summary error: \(error)")
        }
    }

    private func fetchHistory() async {
        guard let sid = sessionId else { return }

        let url = AppConfig.piholeURL.appendingPathComponent("api/history")
        var request = URLRequest(url: url)
        request.setValue(sid, forHTTPHeaderField: "sid")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(PiholeHistoryResponse.self, from: data)
            history = response.history
        } catch {
            print("History error: \(error)")
        }
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
}

enum PiholeError: LocalizedError {
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Pi-hole authentication failed"
        }
    }
}
