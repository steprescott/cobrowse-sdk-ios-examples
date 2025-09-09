
import SwiftUI

extension CobrowseSession.Latency {
    
    var color: Color {
        switch self {
            case .unknown: return .gray
            case .low: return .green
            case .medium: return .yellow
            case .high: return .red
        }
    }
}
