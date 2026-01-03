import Foundation

@MainActor
class HomeDashboardService: ObservableObject {
    @Published var garageDoorState: String = "unknown"
    @Published var garageCameraURL: URL?
    @Published var familyRoomTemp: Double?
    @Published var masterBedroomTemp: Double?
    @Published var greenhouseWeather: WeatherData?
    @Published var heberWeather: WeatherData?
    @Published var bigforkWeather: WeatherData?
    @Published var mainHouseLights: [LightGroup] = []
    @Published var barnLights: [LightGroup] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?

    private var refreshTimer: Timer?
    private var allStates: [[String: Any]] = []

    init() {
        initializeLightGroups()
    }

    private func initializeLightGroups() {
        mainHouseLights = LightGroups.mainHouse.map {
            LightGroup(id: $0.id, name: $0.name, icon: $0.icon, entityIds: $0.entityIds)
        }
        barnLights = LightGroups.barn.map {
            LightGroup(id: $0.id, name: $0.name, icon: $0.icon, entityIds: $0.entityIds)
        }
    }

    func fetchAll() async {
        isLoading = true
        error = nil

        let url = AppConfig.haURL.appendingPathComponent("api/states")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(AppConfig.haToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            allStates = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []

            parseGarageDoor()
            parseGarageCamera()
            parseTemperatures()
            parseWeather()
            parseLights()

            lastUpdated = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func getState(for entityId: String) -> [String: Any]? {
        allStates.first { ($0["entity_id"] as? String) == entityId }
    }

    private func parseGarageDoor() {
        if let entity = getState(for: DashboardEntities.garageDoor) {
            garageDoorState = (entity["state"] as? String) ?? "unknown"
        }
    }

    private func parseGarageCamera() {
        // Get camera entity_picture which includes access token
        if let entity = getState(for: DashboardEntities.garageCamera),
           let attrs = entity["attributes"] as? [String: Any],
           let entityPicture = attrs["entity_picture"] as? String {
            garageCameraURL = URL(string: AppConfig.haURL.absoluteString + entityPicture)
        }
    }

    private func parseTemperatures() {
        if let entity = getState(for: DashboardEntities.familyRoomClimate),
           let attrs = entity["attributes"] as? [String: Any] {
            familyRoomTemp = attrs["current_temperature"] as? Double
        }
        if let entity = getState(for: DashboardEntities.masterBedroomClimate),
           let attrs = entity["attributes"] as? [String: Any] {
            masterBedroomTemp = attrs["current_temperature"] as? Double
        }
    }

    private func parseWeather() {
        if let entity = getState(for: DashboardEntities.greenhouseWeather),
           let state = entity["state"] as? String,
           let attrs = entity["attributes"] as? [String: Any] {
            greenhouseWeather = WeatherData.from(state: state, attributes: attrs, location: "Greenhouse")
        }
        if let entity = getState(for: DashboardEntities.heberWeather),
           let state = entity["state"] as? String,
           let attrs = entity["attributes"] as? [String: Any] {
            heberWeather = WeatherData.from(state: state, attributes: attrs, location: "Heber City")
        }
        if let entity = getState(for: DashboardEntities.bigforkWeather),
           let state = entity["state"] as? String,
           let attrs = entity["attributes"] as? [String: Any] {
            bigforkWeather = WeatherData.from(state: state, attributes: attrs, location: "Bigfork")
        }
    }

    private func parseLights() {
        mainHouseLights = LightGroups.mainHouse.map { group in
            let onCount = group.entityIds.filter { entityId in
                if let entity = getState(for: entityId),
                   let state = entity["state"] as? String {
                    return state == "on"
                }
                return false
            }.count
            return LightGroup(
                id: group.id,
                name: group.name,
                icon: group.icon,
                entityIds: group.entityIds,
                isOn: onCount > 0,
                onCount: onCount
            )
        }

        barnLights = LightGroups.barn.map { group in
            let onCount = group.entityIds.filter { entityId in
                if let entity = getState(for: entityId),
                   let state = entity["state"] as? String {
                    return state == "on"
                }
                return false
            }.count
            return LightGroup(
                id: group.id,
                name: group.name,
                icon: group.icon,
                entityIds: group.entityIds,
                isOn: onCount > 0,
                onCount: onCount
            )
        }
    }

    // MARK: - Actions

    func closeGarageDoor() async {
        await callService(domain: "cover", service: "close_cover", entityId: DashboardEntities.garageDoor)
    }

    func openGarageDoor() async {
        await callService(domain: "cover", service: "open_cover", entityId: DashboardEntities.garageDoor)
    }

    func toggleGarageDoor() async {
        if garageDoorState == "open" {
            await closeGarageDoor()
        } else {
            await openGarageDoor()
        }
    }

    func turnOffLightGroup(_ group: LightGroup) async {
        for entityId in group.entityIds {
            await callService(domain: "light", service: "turn_off", entityId: entityId)
        }
        await fetchAll()
    }

    func turnOnLightGroup(_ group: LightGroup) async {
        for entityId in group.entityIds {
            await callService(domain: "light", service: "turn_on", entityId: entityId)
        }
        await fetchAll()
    }

    func toggleLightGroup(_ group: LightGroup) async {
        if group.isOn {
            await turnOffLightGroup(group)
        } else {
            await turnOnLightGroup(group)
        }
    }

    func turnOffAllLights() async {
        let allGroups = mainHouseLights + barnLights
        for group in allGroups where group.isOn {
            for entityId in group.entityIds {
                await callService(domain: "light", service: "turn_off", entityId: entityId)
            }
        }
        await fetchAll()
    }

    private func callService(domain: String, service: String, entityId: String) async {
        let url = AppConfig.haURL.appendingPathComponent("api/services/\(domain)/\(service)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.haToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["entity_id": entityId])

        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Auto Refresh

    func startAutoRefresh(interval: TimeInterval = 10) {
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
