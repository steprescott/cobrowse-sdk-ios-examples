
import Foundation

extension String {

    var accessibilityIdentifier: String {
        replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
    }
}
