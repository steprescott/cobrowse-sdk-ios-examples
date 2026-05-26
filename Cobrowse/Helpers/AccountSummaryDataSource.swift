import QuickLook

class AccountSummaryDataSource: NSObject, QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        PreviewItem(
            url: Bundle.main.url(forResource: "account_summary", withExtension: "pdf"),
            title: "My Summary"
        )
    }
}

private class PreviewItem: NSObject, QLPreviewItem {
    
    let previewItemURL: URL?
    let previewItemTitle: String?

    init(url: URL?, title: String? = nil) {
        self.previewItemURL = url
        self.previewItemTitle = title
    }
}
