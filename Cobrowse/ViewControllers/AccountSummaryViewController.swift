import UIKit
import QuickLook

class AccountSummaryViewController: UIViewController {
    
    private let dataSource = AccountSummaryDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let controller = QLPreviewController()
        let controller = PDFPreviewController()
        controller.dataSource = dataSource
        
        addChild(controller)
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
