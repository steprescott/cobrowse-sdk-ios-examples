import UIKit
import QuickLook

class AccountSummaryViewController: UIViewController {

    private let previewController = QLPreviewController()
    private let dataSource = AccountSummaryDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        previewController.dataSource = dataSource
        
        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.didMove(toParent: self)
        
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            previewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
