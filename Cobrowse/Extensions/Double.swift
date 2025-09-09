
import Foundation

extension Double {
    
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var formatted: String {
        Double.formatter.string(from: NSNumber(value: self)) ?? "Unknown"
    }
}
