import QuickLook

class AccountSummaryDataSource: NSObject, QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        Bundle.main.url(forResource: "account_summary", withExtension: "pdf")! as QLPreviewItem
    }
}
