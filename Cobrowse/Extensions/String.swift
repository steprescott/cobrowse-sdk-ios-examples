
import Foundation

extension String {
    
    static func == (lhs: String, rhs: Segue) -> Bool {
        return lhs == rhs.rawValue as String
    }
}
