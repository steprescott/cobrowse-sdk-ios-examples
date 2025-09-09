
import SwiftUI

struct SessionLatencyView: View {
    
    @EnvironmentObject private var cobrowseSession: CobrowseSession
    
    @State private var isPresented = false
    
    var statusColor: Color {
        guard let session = cobrowseSession.current, session.isActive()
            else { return .gray }
        
        return cobrowseSession.latency.color
    }
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Circle()
                .fill(statusColor)
                .frame(width: 24, height: 24)
        }
        .popover(isPresented: $isPresented) {
            SessionMetricsView()
            .frame(minWidth: 300, minHeight: 140)
            .presentationCompactAdaptation(.popover)
            .presentationBackground { Color.background }
        }
        
    }
}
