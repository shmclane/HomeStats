import SwiftUI

struct ServiceRow: View {
    let service: ServiceType
    let isConfigured: Bool

    var body: some View {
        HStack {
            Image(systemName: service.icon)
                .font(.title3)
                .foregroundStyle(isConfigured ? .blue : .secondary)
                .frame(width: 30)

            Text(service.rawValue)

            Spacer()

            if isConfigured {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    List {
        ServiceRow(service: .homeAssistant, isConfigured: true)
        ServiceRow(service: .plex, isConfigured: false)
    }
}
