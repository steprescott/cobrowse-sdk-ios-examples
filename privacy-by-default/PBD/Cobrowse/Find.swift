import SwiftUI

enum Find {

    enum Verdict: Equatable, CustomStringConvertible {

        /// The view is found and does conform to `ApprovedForCobrowse`
        case approved

        /// The view is found but doe not conform to `ApprovedForCobrowse` so defaults to `.refused`
        case refused(String)

        /// There was no view found so report that so the caller can look elsewhere, such as in UIKit, for the verdict.
        case unknown(String)

        var isApproved: Bool { if case .approved = self { true } else { false } }
        var isRefused: Bool { if case .refused = self { true } else { false } }
        var isUnknown: Bool { if case .unknown = self { true } else { false } }

        var description: String {
            switch self {
                case .approved: "APPROVED"
                case .refused(let why): "REFUSED: \(why)"
                case .unknown(let why): "UNKNOWN: \(why)"
            }
        }

        /// Find out if this view is approved. Depending on the type of view,
        /// the answer is found at a different depth.
        ///
        /// A wrapper that carries the conformance, such as `ModifiedContent`,
        /// answers as it is. One that cannot, such as `AnyView`, is unwrapped
        /// and asked again, until a view outside SwiftUI is reached or nothing
        /// is held and its body is asked instead.
        static func `for`(_ view: Any) -> Verdict {

            switch Find.unwrap(view, until: { CobrowseApproval.approves(type(of: $0)) }) {

                // This view carries the conformance, either itself or through a
                // conforming wrapper around it.
                case .arrived:
                    return .approved

                // This IS the screen the Controller shows, and as it does not
                // conform to `ApprovedForCobrowse` by default we reject it.
                case .notASystemView(let view):
                    return .refused("\(type(of: view)) is not approved")

                // The wrappers didn't hold a view so we look to the body for
                // a verdict.
                case .nothingHeld(let wrapper):
                    return .for(body: wrapper)

                // Safety stop to ensure we don't loop too far.
                case .tooDeep:
                    return .unknown("\(Find.depthLimit) levels down and still among SwiftUI's wrappers")
            }
        }

        /// The verdict from this wrapper's `body`, asked once per type.
        ///
        /// Evaluating a body is more expensive. Only SwiftUI's own wrappers
        /// reach here, and they carry their content in their type, so the
        /// verdict is the same for every instance of that type and is kept.
        ///
        /// The key is the specialised type: `LazyView<Approved>` and
        /// `LazyView<Unapproved>` are different types and cache separately.
        ///
        /// Body is asked only when a wrapper holds no view one level down.
        /// An example is a `LazyView`. It holds a closure, not a view, so its
        /// body is the only place left to look. That is how a popover's
        /// content arrives.
        private static func `for`(body wrapper: Any) -> Verdict {
            Find.bodyVerdicts.value(for: type(of: wrapper)) {
                Find.body(of: wrapper).map { Verdict.for($0) }
                    ?? .unknown("\(type(of: wrapper)) is SwiftUI's own and shows no view")
            }
        }
    }

    /// Detect if the view was declared outside SwiftUI and the standard
    /// library: the App's own module, or a third-party one.
    fileprivate static func isNotSystemView(_ value: Any) -> Bool {
        value is any View && Module.isSystem(type(of: value)) == false
    }

    /// Cache for already answered view bodies
    fileprivate static let bodyVerdicts = PerType<Verdict>()

    /// This views `body`, evaluated off the graph, or `nil` where the value
    /// is not a view or is a primitive with no body. See `View.evaluatedBody`.
    fileprivate static func body(of wrapper: Any) -> Any? {
        (wrapper as? any View)?.evaluatedBody
    }
    
    // MARK: - finding a TabView, which is a different question from the verdict

    /// The `TabView` this view shows, or `nil` if there isn't one found.
    ///
    /// A `TabView`'s content lists its tabs in the order they were written, which
    /// is the only place a tab's identity is recorded.
    static func tabView(in view: Any) -> Any? {

        switch unwrap(view, until: { $0 is any AnyTabView }) {

            // This view is the `TabView` itself and its content is
            // where the tabs are declared.
            case .arrived(let view):
                return view

            // Either a view the App wrote, which we never look below, or a
            // wrapper holding no single view. Both ways its body is the last
            // place a declaration could be, and a container the App wrote
            // declares its tabs there.
            case .notASystemView(let view), .nothingHeld(let view):
                return tabView(inBodyOf: view)

            case .tooDeep:
                return nil
        }
    }

    /// The `TabView` in what this wrapper's `body` returns.
    private static func tabView(inBodyOf wrapper: Any) -> Any? {
        body(of: wrapper).flatMap { tabView(in: $0) }
    }

    // MARK: - the walk both questions share

    /// Where the unwrap stopped.
    fileprivate enum Unwrapped {

        /// The view the caller was looking for.
        case arrived(Any)

        /// A view declared outside SwiftUI and the standard library.
        case notASystemView(Any)

        /// A wrapper holding no view one level down, such as a `LazyView`
        /// holding a closure.
        case nothingHeld(Any)

        /// `depthLimit` levels down without reaching any of the above.
        case tooDeep
    }

    /// A `NavigationStack` root nests SwiftUI's own containers several deep
    /// before anything of the app's appears, and a popover is seven deep.
    /// Twelve is past every shape that occurs, and the point is to stop rather
    /// than to reach.
    fileprivate static let depthLimit = 12
    
    /// Unwrap SwiftUI's wrappers a level at a time until `arrived` says this is
    /// the view being looked for, or until something stops the walk.
    ///
    /// `verdict(for:)` and `tabView(in:)` ask different questions of the same walk
    /// and treat its stops differently, so the walk lives here once and each
    /// decides what its stops mean.
    fileprivate static func unwrap(_ start: Any, until arrived: (Any) -> Bool) -> Unwrapped {

        var view = start

        for _ in 0 ..< depthLimit {

            // Check if this is the view being looked for.
            if arrived(view) {
                return .arrived(view)
            }

            // Check if this view was declared outside SwiftUI — the App's own
            // module, or a third-party one.
            if isNotSystemView(view) {
                return .notASystemView(view)
            }

            // Check what this SwiftUI wrapper holds one level down.
            guard let next = look(in: view) else {
                return .nothingHeld(view)
            }

            // Ask the same questions to the next view.
            view = next
        }

        return .tooDeep
    }

    // MARK: - The ways SwiftUI holds the view it is showing

    /// The view stored inside this wrapper, or `nil` if not found.
    ///
    /// Each route handles one kind of wrapper and returns `nil` for the
    /// others, so the first view returned is the answer.
    ///
    /// The named types come first because `in(properties:)` recognises
    /// nothing, it counts stored views and returns it if there is only one found.
    private static func look(in value: Any) -> Any? {

        view.in(modifiedContent: value)
            ?? view.in(anyView: value)
            ?? view.in(conditionalContent: value)
            ?? view.in(optional: value)
            ?? view.in(properties: value)
    }
    
    enum view {

        /// Returns the view `ModifiedContent` wraps.
        ///
        /// It holds two things and they are public, so its content is taken through
        /// the API rather than by reflection.
        static func `in`(modifiedContent wrapper: Any) -> Any? {
            (wrapper as? any AnyModifiedContent)?.anyContent
        }

        /// Returns the view found in`AnyView`.
        ///
        /// `AnyView` publishes nothing about what it holds. Its one stored
        /// property is a box, and the box holds the view.
        static func `in`(anyView wrapper: Any) -> Any? {

            guard wrapper is AnyView
                else { return nil }

            return theViewBehindStorage(of: wrapper)
        }

        /// The view from the live branch of a`_ConditionalContent`.
        ///
        /// A choice holds only its LIVE branch, behind one level of storage
        /// that is not itself a view, so both levels are taken here. A `switch`
        /// is thereby judged by the view it is actually showing. The live
        /// branch the view holds is never ahead of what is rendered, so the
        /// unapproved branch never reaches the agent.
        static func `in`(conditionalContent wrapper: Any) -> Any? {

            guard wrapper is any AnyConditionalContent
                else { return nil }

            return theViewBehindStorage(of: wrapper)
        }

        /// The view that is wrapped in the`Optional` or `nil` where it wraps none.
        static func `in`(optional wrapper: Any) -> Any? {

            guard Mirror(reflecting: wrapper).displayStyle == .optional
                else { return nil }

            return theOnlyView(storedIn: wrapper)
        }

        /// The view for a wrapper with no type that we can name. It must only
        /// declare / store one `View` property otherwise `nil` for none and for more than
        /// one found.
        ///
        /// `SheetContent` and `PopoverContent` come through here, and a
        /// `PopoverContent` keeps its minimum size and mode next to its view,
        /// so counting the views rather than the properties is what reaches it.
        ///
        /// Holding two views, nothing static says which is on display, and
        /// so the default is to refuse the verdict. A closure is not a view, so a
        /// `LazyView` returns `nil` here and its `body` is asked instead.
        static func `in`(properties wrapper: Any) -> Any? {
            theOnlyView(storedIn: wrapper)
        }

        /// The view held behind one level of opaque storage.
        ///
        /// `AnyView` and `_ConditionalContent` each keep the view behind a
        /// single stored property that is not itself a view. Both facts are
        /// required: a second property, or storage that IS a view, means the
        /// layout is not the one this expects, and reflecting on into it would
        /// reach inside a view instead of stopping at it. Either way `nil`.
        static func theViewBehindStorage(of wrapper: Any) -> Any? {

            guard let storage = theOnlyValue(storedIn: wrapper),
                  storage is any View == false
            else { return nil }

            return theOnlyView(storedIn: storage)
        }

        /// The one view stored in this value, or `nil` for none and for more
        /// than one. Order-independent: it counts, it does not take the first.
        /// It asserts that there must only be one `View` found so we are safe.
        /// If anything changes or fails we `.reject` the verdict.
        private static func theOnlyView(storedIn value: Any) -> Any? {

            let views = Mirror(reflecting: value).children.filter { $0.value is any View }

            guard views.count == 1
                else { return nil }

            return views[0].value
        }

        /// The one value stored in this wrapper, whether or not it is a view.
        ///
        /// For the two wrappers whose single property is opaque storage. A
        /// second property means SwiftUI has changed the layout, and picking
        /// one of them would be a guess, so `nil` is returned instead to stay safe.
        private static func theOnlyValue(storedIn wrapper: Any) -> Any? {

            let stored = Mirror(reflecting: wrapper).children

            guard stored.count == 1
                else { return nil }

            return stored.first?.value
        }
    }

}
