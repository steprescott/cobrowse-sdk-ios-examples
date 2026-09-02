import SwiftUI

// SwiftUI's own types, marked so they can be recognised without naming them.
//
// Each is generic, so it cannot be matched with `is` against a concrete type.
// A marker protocol on the generic type gives the walk something to test, and
// a place to reach the value through public API.

/// Which module declared a type.
enum Module {

    /// Whether SwiftUI or the standard library declared this type, rather than
    /// the App or a third party.
    ///
    /// Read from the qualified names of types we know are theirs, so there is
    /// no list to keep current. Spelling a name costs microseconds, so the
    /// answer is kept per type.
    static func isSystem(_ type: Any.Type) -> Bool {
        systemTypes.value(for: type) { systemModules.contains(name(of: type)) }
    }

    private static let systemTypes = PerType<Bool>()

    private static let systemModules: Set<String> = [name(of: AnyView.self), name(of: Optional<AnyView>.self)]

    private static func name(of type: Any.Type) -> String {
        name(from: String(reflecting: type))
    }

    /// The module a qualified type name belongs to.
    ///
    /// Taken from a name rather than a type so the rule can be tested: the
    /// shape that needed it, `Tab<…>.TabIdentifiedView`, is private to SwiftUI
    /// and cannot be spelled in source.
    ///
    /// A type declared inside an extension is spelled
    /// `(extension in SwiftUI):SwiftUI.Tab<…>.TabIdentifiedView`, so the
    /// module comes after the colon rather than before the first dot.
    static func name(from typeName: String) -> String {

        var typeName = typeName

        // `(extension in SwiftUI):SwiftUI.Tab<…>.TabIdentifiedView`
        //                        ↑ the real name starts here
        if let colon = typeName.firstIndex(of: ":") {
            typeName = String(typeName[typeName.index(after: colon)...])
        }

        return String(typeName.prefix { $0 != "." })
    }
}

/// A SwiftUI wrapper that holds the view it wraps behind public API.
///
/// Only `ModifiedContent` needs this. It is the one wrapper on the path with
/// two views' worth of stored properties, so "the one view held" cannot
/// separate the view from a modifier that is itself a view.
protocol AnyModifiedContent {

    /// The view it wraps, never the modifier.
    var anyContent: Any { get }
}

extension ModifiedContent: AnyModifiedContent {

    var anyContent: Any { content }
}

/// `TupleView`, whose `value` is the tuple of the views it lays out.
protocol AnyTupleView {

    var anyValue: Any { get }
}

extension TupleView: AnyTupleView {

    var anyValue: Any { value }
}

/// A choice between views, where the type names every branch and the value
/// holds only the live one.
protocol AnyConditionalContent {}
extension _ConditionalContent: AnyConditionalContent {}

/// `TabView`, whose content declares the tabs.
protocol AnyTabView {}
extension TabView: AnyTabView {}

extension View {

    /// This view's `body`, evaluated outside SwiftUI's render graph, or `nil`
    /// for a primitive view that has none.
    ///
    /// SwiftUI's primitive views declare `Body == Never` and trap in `body`;
    /// the check is on the type, before the call, so nothing is ever asked
    /// that cannot answer. Anything else is an ordinary computed property.
    ///
    /// Outside the graph a `@State` reads as its initial value and SwiftUI
    /// logs a warning, which is why callers evaluate a container's body once
    /// per type and remember the answer.
    var evaluatedBody: Any? {
        Body.self == Never.self ? nil : body
    }
}
