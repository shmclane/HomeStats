import SwiftUI

struct TestDashboardView: View {
    @StateObject private var service = HAService(applyFilters: false)
    @State private var selectedView = 0

    private let viewNames = ["Home", "Pool", "Fans", "Covers", "Climate", "Cameras"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with view selector
                headerView

                // Content based on selected view
                ScrollView {
                    switch selectedView {
                    case 0: homeView
                    case 1: poolView
                    case 2: fansView
                    case 3: coversView
                    case 4: climateView
                    case 5: camerasView
                    default: homeView
                    }
                }
            }
        }
        .onAppear {
            service.startAutoRefresh()
        }
        .onDisappear {
            service.stopAutoRefresh()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Test Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                if let lastUpdated = service.lastUpdated {
                    Text("Updated: \(lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 48)
            .padding(.top, 24)

            // View selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewNames.enumerated()), id: \.offset) { index, name in
                        Button(action: { selectedView = index }) {
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(selectedView == index ? .semibold : .regular)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedView == index ? Color.blue : Color(white: 0.2))
                                .foregroundColor(selectedView == index ? .white : .primary)
                                .cornerRadius(20)
                        }
                        .buttonStyle(DomainButtonStyle())
                    }
                }
                .padding(.horizontal, 48)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Home View

    private var homeView: some View {
        VStack(spacing: 24) {
            // Weather
            if let weather = getEntity("weather.farting_buddha_farms") {
                WeatherCard(entity: weather)
            }

            // Quick controls grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                // Lights
                ForEach(getLights(), id: \.entityId) { light in
                    EntityCard(entity: light) {
                        Task { await service.toggle(light) }
                    }
                }

                // Media players
                ForEach(getMediaPlayers(), id: \.entityId) { player in
                    MediaPlayerCard(entity: player)
                }

                // Vacuum
                if let vacuum = getEntity("vacuum.not_quite_gg") {
                    VacuumCard(entity: vacuum) {
                        Task { await service.callService(domain: "vacuum", service: "start", entityId: vacuum.entityId) }
                    }
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Pool View

    private var poolView: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                // Pool controls
                VStack(spacing: 16) {
                    SectionHeader(title: "Pool Controls", icon: "flame.fill")

                    if let fireplace = getEntity("switch.pool_fireplace") {
                        ToggleCard(entity: fireplace) {
                            Task { await service.toggle(fireplace) }
                        }
                    }

                    if let bocce = getEntity("light.bocce_court") {
                        ToggleCard(entity: bocce) {
                            Task { await service.toggle(bocce) }
                        }
                    }
                }
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(16)

                // Pool heat
                VStack(spacing: 16) {
                    SectionHeader(title: "Pool Heat", icon: "thermometer")

                    if let poolHeat = getEntity("climate.pentair_f7_9f_bc_pool_heat") {
                        ClimateCard(entity: poolHeat)
                    }
                }
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(16)

                // Weather
                VStack(spacing: 16) {
                    SectionHeader(title: "Weather", icon: "cloud.sun.fill")

                    if let weather = getEntity("weather.forecast_candace_mclane_studios") {
                        WeatherCard(entity: weather)
                    }
                }
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(16)
            }
            .padding(.horizontal, 48)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Fans View

    private var fansView: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "All Fans", icon: "fan.fill")
                .padding(.horizontal, 48)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                ForEach(getFans(), id: \.entityId) { fan in
                    FanControlCard(entity: fan, service: service)
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Covers View

    private var coversView: some View {
        VStack(spacing: 24) {
            // Group covers by area
            let coverGroups = groupCovers()

            ForEach(Array(coverGroups.keys.sorted()), id: \.self) { area in
                VStack(alignment: .leading, spacing: 12) {
                    Text(area)
                        .font(.headline)
                        .padding(.horizontal, 48)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        ForEach(coverGroups[area] ?? [], id: \.entityId) { cover in
                            CoverCard(entity: cover) {
                                Task { await service.toggle(cover) }
                            }
                        }
                    }
                    .padding(.horizontal, 48)
                }
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - Climate View

    private var climateView: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Climate Controls", icon: "thermometer")
                .padding(.horizontal, 48)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                ForEach(getClimateEntities(), id: \.entityId) { climate in
                    ClimateCard(entity: climate)
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Cameras View

    private var camerasView: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Cameras", icon: "video.fill")
                .padding(.horizontal, 48)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 380))], spacing: 16) {
                ForEach(getCameras(), id: \.entityId) { camera in
                    CameraCard(entity: camera)
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Helper Functions

    private func getEntity(_ entityId: String) -> HAEntity? {
        service.entities.first { $0.entityId == entityId }
    }

    private func getLights() -> [HAEntity] {
        service.entities.filter { $0.domain == "light" }.prefix(6).map { $0 }
    }

    private func getMediaPlayers() -> [HAEntity] {
        service.entities.filter { $0.domain == "media_player" }.prefix(4).map { $0 }
    }

    private func getFans() -> [HAEntity] {
        service.entities.filter { $0.domain == "fan" }
    }

    private func getCovers() -> [HAEntity] {
        service.entities.filter { $0.domain == "cover" }
    }

    private func getClimateEntities() -> [HAEntity] {
        service.entities.filter { $0.domain == "climate" }
    }

    private func getCameras() -> [HAEntity] {
        service.entities.filter { $0.domain == "camera" }.prefix(9).map { $0 }
    }

    private func groupCovers() -> [String: [HAEntity]] {
        let covers = getCovers()
        var groups: [String: [HAEntity]] = [:]

        for cover in covers {
            let name = cover.entityId.replacingOccurrences(of: "cover.", with: "")
            let area: String
            if name.contains("shop") { area = "Shop" }
            else if name.contains("boat") { area = "Boat Barn" }
            else if name.contains("billiards") || name.contains("bar") || name.contains("hall") { area = "Billiards/Bar" }
            else if name.contains("office") { area = "Office" }
            else { area = "Other" }

            groups[area, default: []].append(cover)
        }
        return groups
    }
}

// MARK: - Supporting Views

struct WeatherCard: View {
    let entity: HAEntity

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: weatherIcon)
                .font(.system(size: 48))
                .foregroundColor(.blue)

            VStack(alignment: .leading) {
                Text(entity.name)
                    .font(.headline)
                Text(entity.state.capitalized)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }

    private var weatherIcon: String {
        switch entity.state.lowercased() {
        case "sunny", "clear": return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "partlycloudy": return "cloud.sun.fill"
        case "rainy": return "cloud.rain.fill"
        case "snowy": return "cloud.snow.fill"
        default: return "cloud.fill"
        }
    }
}

struct MediaPlayerCard: View {
    let entity: HAEntity

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tv")
                .font(.system(size: 32))
                .foregroundColor(entity.isOn ? .purple : .gray)

            Text(entity.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(entity.state.capitalized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 180, height: 120)
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

struct VacuumCard: View {
    let entity: HAEntity
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(spacing: 8) {
                Image(systemName: "camera.metering.center.weighted")
                    .font(.system(size: 32))
                    .foregroundColor(entity.state == "cleaning" ? .green : .gray)

                Text(entity.name)
                    .font(.caption)
                    .lineLimit(2)

                Text(entity.state.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 180, height: 120)
            .padding()
            .background(Color(white: 0.15))
            .cornerRadius(12)
        }
        .buttonStyle(CardButtonStyle())
    }
}

struct ToggleCard: View {
    let entity: HAEntity
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: entity.isOn ? "power.circle.fill" : "power.circle")
                    .foregroundColor(entity.isOn ? .green : .gray)
                Text(entity.name)
                Spacer()
                Text(entity.isOn ? "On" : "Off")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(white: 0.15))
            .cornerRadius(8)
        }
        .buttonStyle(CardButtonStyle())
    }
}

struct ClimateCard: View {
    let entity: HAEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: climateIcon)
                    .foregroundColor(climateColor)
                Text(entity.name)
                    .font(.headline)
            }

            Text(entity.state.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let temp = entity.attributes.temperature {
                Text("Target: \(Int(temp))°")
                    .font(.title2)
            }

            if let currentTemp = entity.attributes.currentTemperature {
                Text("Current: \(Int(currentTemp))°")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }

    private var climateIcon: String {
        switch entity.state {
        case "heat": return "flame.fill"
        case "cool": return "snowflake"
        case "heat_cool": return "thermometer"
        default: return "power"
        }
    }

    private var climateColor: Color {
        switch entity.state {
        case "heat": return .orange
        case "cool": return .blue
        case "heat_cool": return .green
        default: return .gray
        }
    }
}

struct FanControlCard: View {
    let entity: HAEntity
    let service: HAService

    var body: some View {
        Button(action: {
            Task { await service.toggle(entity) }
        }) {
            VStack(spacing: 8) {
                Image(systemName: "fan.fill")
                    .font(.system(size: 28))
                    .foregroundColor(entity.isOn ? .cyan : .gray)
                    .rotationEffect(.degrees(entity.isOn ? 360 : 0))
                    .animation(entity.isOn ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: entity.isOn)

                Text(entity.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(entity.isOn ? "On" : "Off")
                    .font(.caption2)
                    .foregroundColor(entity.isOn ? .green : .secondary)
            }
            .frame(width: 160, height: 100)
            .padding()
            .background(Color(white: 0.15))
            .cornerRadius(12)
        }
        .buttonStyle(CardButtonStyle())
    }
}

struct CoverCard: View {
    let entity: HAEntity
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 4) {
                Image(systemName: coverIcon)
                    .font(.system(size: 24))
                    .foregroundColor(coverColor)

                Text(entity.name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(entity.state.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 130, height: 80)
            .padding(8)
            .background(Color(white: 0.15))
            .cornerRadius(8)
        }
        .buttonStyle(CardButtonStyle())
    }

    private var coverIcon: String {
        switch entity.state {
        case "open": return "door.left.hand.open"
        case "closed": return "door.left.hand.closed"
        default: return "door.sliding.left.hand.open"
        }
    }

    private var coverColor: Color {
        entity.state == "open" ? .orange : .gray
    }
}

// Add temperature and currentTemperature to HAAttributes
extension HAAttributes {
    var temperature: Double? {
        nil // Would need to parse from raw attributes
    }

    var currentTemperature: Double? {
        nil // Would need to parse from raw attributes
    }
}

