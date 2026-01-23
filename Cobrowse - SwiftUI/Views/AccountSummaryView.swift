
import SwiftUI
import QuickLook

struct AccountSummaryView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> QLPreviewController {
        
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> AccountSummaryDataSource {
        AccountSummaryDataSource()
    }
}
