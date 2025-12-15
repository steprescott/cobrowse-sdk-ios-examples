import Foundation

extension String {
    
    static func == (lhs: String, rhs: Segue) -> Bool {
        lhs == rhs.rawValue as String
    }
}
