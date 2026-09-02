import UIKit
import SwiftUI

/// A controller that hosts a SwiftUI view, whatever it hosts.
///
/// `UIHostingController` is generic over its content, so it can only be seen
/// through a protocol. What the policy needs from it is the VALUE, which
/// answers directly and reads `AnyView`where the view is erased.
protocol AnyHostingController {

    /// The type this controller hosts.
    var viewType: Any.Type { get }

    /// The view it hosts, as a value.
    var anyRootView: Any { get }
}

extension UIHostingController: AnyHostingController {

    var viewType: Any.Type { Content.self }

    var anyRootView: Any { rootView }
}

extension UIViewController {

    /// The verdict on if this controller's rootView is shown to the agent.
    ///
    /// Most controllers answer for themselves. A navigation stack's root
    /// cannot: what it hosts is SwiftUI's navigation plumbing, which names no
    /// view. So it borrows a verdict from its ancestors, and it is the only
    /// controller that does. Anything pushed after the root answers as itself.
    ///
    /// The borrow asks every ancestor, unless the stack sits inside a tab. Then
    /// it stops at that tab's own controller.
    var cobrowseVerdict: Find.Verdict {

        // Ask this controller which view it hosts.
        let verdict = hostedVerdict

        // Return that verdict unless all three hold:
        // 1. it found no view, so `.unknown`
        // 2. this controller is a Hosting Controller
        // 3. this controller is a navigation stack's root
        guard verdict.isUnknown, self is AnyHostingController, isNavigationRoot
            else { return verdict }

        // We didn't find it via the hosted so we ask each ancestor and take the first
        // that found a view.
        return borrowChain.lazy
            .map(\.hostedVerdict)
            .first { $0.isUnknown == false }
            ?? .unknown("a navigation root, and no ancestor names a view either")
    }

    /// The ancestors a navigation root may borrow a verdict from, nearest
    /// first.
    ///
    /// The list ends with the first ancestor that a container holds alongside
    /// others, since anything beyond it covers more than this view.
    private var borrowChain: [UIViewController] {

        var chain: [UIViewController] = []

        for ancestor in ancestors {
            chain.append(ancestor)

            // Does a tab bar hold this ancestor? Then it is the last to ask.
            if ancestor.isTab { break }
        }

        return chain
    }

    /// Whether this controller is the child of a tab bar controller, and so a tab.
    fileprivate var isTab: Bool { parent is UITabBarController }

    /// The verdict this controller reaches on its own, without borrowing.
    ///
    /// A tab is asked first. Its own root view names nothing, so its container's
    /// declaration is the only place to look.
    private var hostedVerdict: Find.Verdict {

        if let declared = declaredTab {
            return declared
        }

        guard let hosting = self as? AnyHostingController
            else { return .unknown("hosts no SwiftUI view") }

        return Find.Verdict.for(hosting.anyRootView)
    }

    /// The verdict this tab is declared with, or `nil` if this is not a tab or
    /// the declaration cannot be read. If `nil` the tab hidden.
    ///
    /// A verdict rather than a type. The `Tab { }` API gives every tab the same
    /// type, so only the values can tell them apart, and `Tabs` judges them as
    /// it reads the declaration.
    var declaredTab: Find.Verdict? {

        // Is a tab bar holding this? `children` rather than `viewControllers`,
        // which SwiftUI leaves nil on iOS 27.
        guard let tabs = parent as? UITabBarController
            else { return nil }

        let controllers = tabs.children

        // Which tab is this one?
        guard let index = controllers.firstIndex(of: self)
            else { return nil }

        // Read the declaration and take this tab's verdict from it.
        guard let declared = tabs.declaredTabs(count: controllers.count),
              declared.indices.contains(index)
        else { return nil }

        return declared[index]
    }

    fileprivate var ancestors: [UIViewController] {
        parent.map { [$0] + $0.ancestors } ?? []
    }

    fileprivate var isNavigationRoot: Bool {
        navigationController?.viewControllers.first === self
    }
}

extension UITabBarController {

    /// One verdict per tab, from the nearest ancestor that declares a
    /// `TabView`.
    ///
    /// In declaration order, so a caller matches a tab by its position.
    ///
    /// A declaration can list tabs that are not on screen. The `count` decides
    /// which of them are: it either matches every declared tab, or only the
    /// ones that are always there. Matching neither returns `nil`.
    fileprivate func declaredTabs(count: Int) -> [Find.Verdict]? {

        ([self] + ancestors).lazy
            .compactMap { $0 as? AnyHostingController }
            .compactMap { Tabs.declared(in: $0.anyRootView)?.aligned(to: count) }
            .first
    }
}
