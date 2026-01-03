import Foundation

// MARK: - Light Room Groups

struct LightGroup: Identifiable {
    let id: String
    let name: String
    let icon: String
    let entityIds: [String]
    var isOn: Bool = false
    var onCount: Int = 0

    var statusText: String {
        if onCount == 0 { return "All Off" }
        if onCount == entityIds.count { return "All On" }
        return "\(onCount) On"
    }
}

enum LightGroups {
    static let mainHouse: [(id: String, name: String, icon: String, entityIds: [String])] = [
        ("kitchen", "Kitchen", "fork.knife", [
            "light.kitchen", "light.kitchen_strip_1", "light.kitchen_strip_2",
            "light.kitchen_desk", "light.kitchen_bar_1", "light.kitchen_bar_2",
            "light.kitchen_bar_3", "light.kitchen_blender", "light.kitchen_oven",
            "light.kitchen_bay_window", "light.kitchen_sink_overhead",
            "light.kitchen_toaster", "light.kitchen_table", "light.kitchen_micro_middle"
        ]),
        ("mbr", "Master Bedroom", "bed.double.fill", [
            "light.mbr", "light.master_bathroom", "light.master_hall",
            "light.mbr_closets", "light.master_bedroom_couch"
        ]),
        ("living", "Living Room", "sofa.fill", ["light.living_rom"]),
        ("dining", "Dining Room", "chandelier.fill", ["light.dinig_room"]),
        ("office", "Dad's Office", "desktopcomputer", ["light.dads_office", "light.dads_light"]),
        ("bar", "Bar", "wineglass.fill", ["light.bar"]),
        ("jen", "Jen's Room", "person.fill", ["light.ollie"]),
        ("gg", "GG Room", "star.fill", ["light.gg_room", "light.gg_window"])
    ]

    static let barn: [(id: String, name: String, icon: String, entityIds: [String])] = []
}

// MARK: - Weather Data

struct WeatherData {
    let location: String
    let condition: String
    let temperature: Double?
    let humidity: Int?
    let icon: String

    static func from(state: String, attributes: [String: Any], location: String) -> WeatherData {
        WeatherData(
            location: location,
            condition: state.replacingOccurrences(of: "-", with: " ").capitalized,
            temperature: attributes["temperature"] as? Double,
            humidity: attributes["humidity"] as? Int,
            icon: weatherIcon(for: state)
        )
    }

    private static func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "sunny", "clear": return "sun.max.fill"
        case "partlycloudy", "partly-cloudy": return "cloud.sun.fill"
        case "cloudy": return "cloud.fill"
        case "rainy", "rain": return "cloud.rain.fill"
        case "snowy", "snow": return "cloud.snow.fill"
        case "fog", "foggy": return "cloud.fog.fill"
        case "windy": return "wind"
        case "lightning", "thunderstorm": return "cloud.bolt.fill"
        default: return "cloud.fill"
        }
    }
}

// MARK: - Dashboard Entity IDs

enum DashboardEntities {
    static let garageDoor = "cover.ratgdov25i_fada1e_door"
    static let garageCamera = "camera.garage_high"
    static let familyRoomClimate = "climate.family_room"
    static let masterBedroomClimate = "climate.master_bedroom"
    static let greenhouseWeather = "weather.forecast_fbf_greenhouse"
    static let heberWeather = "weather.40_52965322226225_111_38917508069427"
    static let bigforkWeather = "weather.forecast_lorang_ln"
    static let speedtestPing = "sensor.speedtest_ping"
}
