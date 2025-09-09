
import SwiftUI

struct SessionMetricsView: View {
    
    @EnvironmentObject private var cobrowseSession: CobrowseSession
    
    var isActive: Bool {
        cobrowseSession.current?.isActive() ?? false
    }
    
    var latency: String {
        guard let latency = cobrowseSession.metrics?.latency()
            else { return "..." }
        
        return "\(latency.formatted) s"
    }
    
    var lastUpdated: String {
        guard let lastUpdated = cobrowseSession.metrics?.lastAlive()
            else { return "..." }
        
        return lastUpdated.formatted
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Text("No active session")
                    .opacity(isActive ? 0 : 1)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Latency")
                            .font(.headline)
                        Spacer()
                        Text(latency)
                    }
                    
                    HStack(alignment: .top) {
                        Text("Last updated")
                            .font(.headline)
                        Spacer()
                        Text(lastUpdated)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .opacity(isActive ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .navigationTitle("Session Metrics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
