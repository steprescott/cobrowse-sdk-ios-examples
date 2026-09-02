import SwiftUI


/// A tab's own controller hosts nothing that names its view, so the container's
/// declaration is the only place a tab's identity is written.
///
/// Each tab is judged by its value rather than its type. The `Tab { }` API gives
/// every tab the same type, so only the values differ.
struct Tabs {

    /// One entry per declared tab, in the order written. `isOptional` for a tab
    /// written `if flag { … }`, whose presence only the runtime knows.
    /// `isOptional is used to detect if there are any tabs
    /// wrapped in `_ConditionalContent`. Optional tabs are not supported.
    let all: [(verdict: Find.Verdict, isOptional: Bool)]

    /// What the `TabView` in this view declares, or `nil` if it declares no
    /// tabs.
    ///
    /// Kept per type. Reading a declaration can cost milliseconds the first
    /// time, and the answer never changes for that type.
    static func declared(in value: Any) -> Tabs? {
        known.value(for: type(of: value)) { read(from: value) }
    }

    private static let known = PerType<Tabs?>()

    private static func read(from value: Any) -> Tabs? {

        // The `TabView` sits in one of three places. It is hosted on its own,
        // or wrapped, or declared in the body of a view the App wrote.
        // `tabView` finds it in all three, and asks for a body only when it
        // has to.
        guard let tabView = Find.tabView(in: value),
              let content = Mirror(reflecting: tabView).children.first(where: { $0.value is any View })?.value
        else { return nil }

        // Several tabs are a tuple; one tab is the view itself.
        let elements = tuple(in: content)
            .map { Mirror(reflecting: $0.anyValue).children.map(\.value) } ?? [content]

        guard elements.isEmpty == false
            else { return nil }

        return Tabs(all: elements.map { (verdict(of: $0), isOptional($0)) })
    }

    /// The `TupleView` holding the tabs, wherever the API keeps it.
    ///
    /// The old `.tabItem` API makes the content a `TupleView` itself.
    /// This looks for it by conformance.
    private static func tuple(in value: Any, depth: Int = 0) -> (any AnyTupleView)? {

        // Is this the tuple? Return it.
        if let tuple = value as? any AnyTupleView { return tuple }

        // Is it one of SwiftUI's own types, and not too deep? If not, stop.
        // A view the App wrote may store a tuple of its own and it is not the
        // declaration.
        guard depth < depthLimit, Module.isSystem(type(of: value))
            else { return nil }

        // Ask the same of each value it holds, and return the first tuple.
        for child in Mirror(reflecting: value).children {
            if let found = tuple(in: child.value, depth: depth + 1) { return found }
        }

        // Nothing held a tuple.
        return nil
    }

    /// How far in to look for the tuple. Two levels covers both tab APIs, and
    /// stopping early keeps the search away from anything further in.
    private static let depthLimit = 4

    /// Whether this tab is wrapped in an `Optional`, which is what an `if`
    /// with no `else` leaves in the declaration. Only the runtime knows
    /// whether such a tab is there.
    private static func isOptional(_ element: Any) -> Bool {
        Mirror(reflecting: element).displayStyle == .optional
    }

    /// The verdict on the view this tab shows.
    ///
    /// A tab written `if flag { … }` holds no view when it is not there. There
    /// is nothing to judge, so the answer is `.unknown`. Walking it would draw
    /// a conclusion from an empty value. `aligned(to:)` decides whether such a
    /// tab is on screen.
    private static func verdict(of element: Any) -> Find.Verdict {

        if isOptional(element), Mirror(reflecting: element).children.isEmpty {
            return .unknown("a conditional tab that is not present")
        }

        return Find.Verdict.for(element)
    }

    /// The declared tabs that line up with the `count` on screen, or `nil` if
    /// they cannot be lined up.
    ///
    /// The declaration lists every tab that could exist. The count is the only
    /// thing that comes from the runtime, so it is the only thing that can say
    /// which conditional tabs are actually there. Two readings are possible:
    /// every declared tab, or only the ones that are always present.
    ///
    /// If the count fits neither, nothing is returned and every tab in the
    /// container stays hidden. Guessing would put a tab against the wrong
    /// view.
    func aligned(to count: Int) -> [Find.Verdict]? {

        let nonOptional = all.filter { $0.isOptional == false }

        if count == all.count         { return all.map(\.verdict) }
        if count == nonOptional.count { return nonOptional.map(\.verdict) }

        return nil
    }
}

