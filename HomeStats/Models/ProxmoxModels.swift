import Foundation

struct ProxmoxResource: Codable, Identifiable {
    let id: String
    let type: String
    let node: String
    let status: String
    let name: String?
    let vmid: Int?
    let cpu: Double?
    let mem: Int?
    let maxmem: Int?
    let maxcpu: Int?
    let uptime: Int?
    let template: Int?

    var isRunning: Bool { status == "running" || status == "online" }
    var isVM: Bool { type == "qemu" }
    var isContainer: Bool { type == "lxc" }
    var isNode: Bool { type == "node" }
    var isTemplate: Bool { (template ?? 0) == 1 }

    var displayName: String {
        name ?? "Unknown"
    }

    var memoryUsagePercent: Double {
        guard let mem = mem, let maxmem = maxmem, maxmem > 0 else { return 0 }
        return Double(mem) / Double(maxmem) * 100
    }

    var cpuUsagePercent: Double {
        (cpu ?? 0) * 100
    }
}

struct ProxmoxResourcesResponse: Codable {
    let data: [ProxmoxResource]
}

struct ProxmoxRRDData: Codable, Identifiable {
    var id: Int { Int(time) }
    let time: Double
    let cpu: Double?
    let memused: Double?
    let memtotal: Double?
    let netin: Double?
    let netout: Double?
    let loadavg: Double?
    let rootused: Double?
    let roottotal: Double?
    let iowait: Double?

    var date: Date {
        Date(timeIntervalSince1970: time)
    }

    var cpuPercent: Double {
        (cpu ?? 0) * 100
    }

    var memoryPercent: Double {
        guard let used = memused, let total = memtotal, total > 0 else { return 0 }
        return used / total * 100
    }

    var netinMbps: Double {
        ((netin ?? 0) * 8) / 1_000_000
    }

    var netoutMbps: Double {
        ((netout ?? 0) * 8) / 1_000_000
    }
}

struct ProxmoxRRDResponse: Codable {
    let data: [ProxmoxRRDData]?
}

struct ProxmoxNodeStatus: Codable {
    let cpu: Double
    let memory: MemoryInfo
    let uptime: Int
    let cpuinfo: CPUInfo
    let loadavg: [String]
    let kversion: String
    let pveversion: String

    struct MemoryInfo: Codable {
        let used: Int
        let total: Int
        let free: Int
    }

    struct CPUInfo: Codable {
        let model: String
        let cpus: Int
        let cores: Int
        let sockets: Int
    }
}

struct ProxmoxNodeStatusResponse: Codable {
    let data: ProxmoxNodeStatus
}
