import Foundation
import Combine

@MainActor
class HAService: ObservableObject {
    @Published var entities: [HAEntity] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?

    private var refreshTimer: Timer?
    private let decoder: JSONDecoder
    private let applyFilters: Bool

    init(applyFilters: Bool = true) {
        self.applyFilters = applyFilters
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func fetchStates() async {
        isLoading = true
        error = nil

        let url = AppConfig.haURL.appendingPathComponent("api/states")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(AppConfig.haToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HAServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw HAServiceError.httpError(httpResponse.statusCode)
            }

            let allEntities = try decoder.decode([HAEntity].self, from: data)

            var filtered = allEntities

            if applyFilters {
                // Apply configured filters
                // Domain filter
                if let allowedDomains = AppConfig.allowedDomains {
                    filtered = filtered.filter { allowedDomains.contains($0.domain) }
                } else {
                    // Default displayable domains if no filter configured
                    let displayableDomains = Set([
                        "light", "switch", "sensor", "binary_sensor", "climate",
                        "fan", "cover", "lock", "media_player", "person",
                        "device_tracker", "weather", "input_boolean"
                    ])
                    filtered = filtered.filter { displayableDomains.contains($0.domain) }
                }

                // Name filters (case-insensitive contains, matches ANY)
                if let nameFilters = AppConfig.nameFilters?.map({ $0.lowercased() }), !nameFilters.isEmpty {
                    filtered = filtered.filter { entity in
                        let name = entity.name.lowercased()
                        return nameFilters.contains { name.contains($0) }
                    }
                }
            }

            entities = filtered.sorted { $0.domain < $1.domain || ($0.domain == $1.domain && $0.name < $1.name) }

            lastUpdated = Date()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchStates()
            }
        }
        // Initial fetch
        Task {
            await fetchStates()
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func entitiesByDomain() -> [String: [HAEntity]] {
        Dictionary(grouping: entities, by: { $0.domain })
    }

    func domains() -> [String] {
        Array(Set(entities.map { $0.domain })).sorted()
    }

    // MARK: - Entity Control

    func toggle(_ entity: HAEntity) async {
        let service = toggleService(for: entity)
        await callService(domain: entity.domain, service: service, entityId: entity.entityId)
    }

    private func toggleService(for entity: HAEntity) -> String {
        switch entity.domain {
        case "light":
            return "toggle"
        case "switch", "input_boolean":
            return "toggle"
        case "cover":
            // For covers: open if closed, close if open
            return entity.state == "closed" ? "open_cover" : "close_cover"
        case "lock":
            return entity.state == "locked" ? "unlock" : "lock"
        case "fan":
            return "toggle"
        default:
            return "toggle"
        }
    }

    func callService(domain: String, service: String, entityId: String) async {
        let url = AppConfig.haURL.appendingPathComponent("api/services/\(domain)/\(service)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.haToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["entity_id": entityId]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Refresh states after successful toggle
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay for HA to update
                await fetchStates()
            }
        } catch {
            print("Toggle error: \(error)")
        }
    }

    func callButton(entityId: String) async {
        await callService(domain: "button", service: "press", entityId: entityId)
    }
}

enum HAServiceError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Home Assistant"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
