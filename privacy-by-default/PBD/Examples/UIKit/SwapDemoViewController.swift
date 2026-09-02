//
//  SwapDemoViewController.swift
//  PBD
//

import UIKit
import SwiftUI

/// One hosting controller, holding either an approved or an unapproved view.
///
/// The controller never changes. Its `Content` is `AnyView` throughout, and the
/// SDK is asked about the same object each pass. Only the value inside changes.
/// So this is the test of whether approval follows what is *on screen* rather
/// than what the controller was when it first appeared: tap Swap and the agent's
/// view should reveal or redact in step, while the device shows both normally.
final class SwapDemoViewController: UIHostingController<AnyView> {

    private var showsApproved = true

    init() {
        // A placeholder, because the real root view needs `self` for its button
        // and `self` does not exist until `super.init` has run.
        super.init(rootView: AnyView(EmptyView()))

        rootView = currentRootView
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Swapping root"
        view.backgroundColor = .systemBackground
    }

    private var currentRootView: AnyView {
        showsApproved
            ? AnyView(ApprovedSwapView(swap: swapRootView))
            : AnyView(UnapprovedSwapView(swap: swapRootView))
    }

    private func swapRootView() {
        showsApproved.toggle()

        rootView = currentRootView
    }
}
