import SwiftUI

struct SyncStatusView: View {
    @ObservedObject private var syncManager = ConfigSyncManager.shared

    var body: some View {
        HStack(spacing: 4) {
            switch syncManager.syncStatus {
            case .idle:
                Image(systemName: "icloud")
                    .foregroundStyle(.secondary)
            case .syncing:
                ProgressView()
                    .scaleEffect(0.8)
            case .synced:
                Image(systemName: "icloud.fill")
                    .foregroundStyle(.green)
            case .error:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    SyncStatusView()
}
