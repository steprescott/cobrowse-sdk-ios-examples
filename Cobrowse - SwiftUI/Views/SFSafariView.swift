import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: String

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = SFSafariViewController(url: URL(string: url)!)
        vc.preferredControlTintColor = UIColor.cbPrimary
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
