import Foundation

struct HAEntity: Identifiable, Codable {
    let entityId: String
    let state: String
    let attributes: HAAttributes
    let lastChanged: Date
    let lastUpdated: Date

    var id: String { entityId }

    var domain: String {
        entityId.split(separator: ".").first.map(String.init) ?? "unknown"
    }

    var name: String {
        attributes.friendlyName ?? entityId.split(separator: ".").last.map(String.init) ?? entityId
    }

    var icon: String {
        if let customIcon = attributes.icon {
            return mapMdiToSFSymbol(customIcon)
        }
        return defaultIconForDomain(domain)
    }

    var unitOfMeasurement: String? {
        attributes.unitOfMeasurement
    }

    var isOn: Bool {
        state.lowercased() == "on" || state.lowercased() == "home" || state.lowercased() == "playing"
    }

    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
    }

    private func mapMdiToSFSymbol(_ mdi: String) -> String {
        let mdiName = mdi.replacingOccurrences(of: "mdi:", with: "")
        let mapping: [String: String] = [
            "lightbulb": "lightbulb.fill",
            "lightbulb-outline": "lightbulb",
            "thermometer": "thermometer",
            "temperature-celsius": "thermometer",
            "water-percent": "humidity.fill",
            "motion-sensor": "figure.walk",
            "door": "door.left.hand.closed",
            "door-open": "door.left.hand.open",
            "window-closed": "window.vertical.closed",
            "window-open": "window.vertical.open",
            "power-plug": "powerplug.fill",
            "flash": "bolt.fill",
            "battery": "battery.100",
            "wifi": "wifi",
            "television": "tv.fill",
            "speaker": "speaker.wave.2.fill",
            "fan": "fan.fill",
            "air-conditioner": "air.conditioner.horizontal.fill",
            "home": "house.fill",
            "lock": "lock.fill",
            "lock-open": "lock.open.fill",
            "garage": "car.garage.fill",
            "camera": "camera.fill",
            "sun": "sun.max.fill",
            "moon": "moon.fill",
            "cloud": "cloud.fill",
            "weather-cloudy": "cloud.fill",
            "weather-sunny": "sun.max.fill",
            "weather-rainy": "cloud.rain.fill"
        ]
        return mapping[mdiName] ?? defaultIconForDomain(domain)
    }

    private func defaultIconForDomain(_ domain: String) -> String {
        switch domain {
        case "light": return "lightbulb.fill"
        case "switch": return "power"
        case "sensor": return "gauge"
        case "binary_sensor": return "sensor.fill"
        case "climate": return "thermometer"
        case "fan": return "fan.fill"
        case "cover": return "blinds.vertical.closed"
        case "lock": return "lock.fill"
        case "camera": return "camera.fill"
        case "media_player": return "tv.fill"
        case "person": return "person.fill"
        case "device_tracker": return "location.fill"
        case "automation": return "gearshape.2.fill"
        case "script": return "scroll.fill"
        case "scene": return "sparkles"
        case "input_boolean": return "togglepower"
        case "input_number": return "number"
        case "input_select": return "list.bullet"
        case "weather": return "cloud.sun.fill"
        case "sun": return "sun.max.fill"
        case "zone": return "mappin.circle.fill"
        default: return "questionmark.circle"
        }
    }
}

struct HAAttributes: Codable {
    let friendlyName: String?
    let icon: String?
    let unitOfMeasurement: String?
    let brightness: Int?
    let colorTemp: Int?
    let rgbColor: [Int]?
    let deviceClass: String?

    enum CodingKeys: String, CodingKey {
        case friendlyName = "friendly_name"
        case icon
        case unitOfMeasurement = "unit_of_measurement"
        case brightness
        case colorTemp = "color_temp"
        case rgbColor = "rgb_color"
        case deviceClass = "device_class"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        friendlyName = try container.decodeIfPresent(String.self, forKey: .friendlyName)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        unitOfMeasurement = try container.decodeIfPresent(String.self, forKey: .unitOfMeasurement)
        brightness = try container.decodeIfPresent(Int.self, forKey: .brightness)
        colorTemp = try container.decodeIfPresent(Int.self, forKey: .colorTemp)
        rgbColor = try container.decodeIfPresent([Int].self, forKey: .rgbColor)
        deviceClass = try container.decodeIfPresent(String.self, forKey: .deviceClass)
    }
}
