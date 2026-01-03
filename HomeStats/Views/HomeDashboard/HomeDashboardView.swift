import SwiftUI

struct HomeDashboardView: View {
    @StateObject private var service = HomeDashboardService()

    var body: some View {
        HomeDashboardOptionA(service: service)
            .onAppear {
                service.startAutoRefresh(interval: 10)
            }
            .onDisappear {
                service.stopAutoRefresh()
            }
    }
}

#Preview {
    HomeDashboardView()
}
