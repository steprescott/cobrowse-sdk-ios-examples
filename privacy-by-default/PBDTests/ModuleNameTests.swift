import XCTest
import SwiftUI
@testable import PBD

/// **Reading a type's module from its qualified name, including the shape that
/// broke every iOS 18 `Tab { }` container.** Measured 2026-09-02, iOS 26.5.
///
/// Tested on names rather than types because the type that exposed the bug —
/// `Tab<…>.TabIdentifiedView` — is private to SwiftUI and cannot be spelled in
/// source, and the hazardous case below cannot be constructed at all.
final class ModuleNameTests: XCTestCase {

    /// The ordinary shapes, unaffected.
    func testAPlainQualifiedNameReadsItsModule() {
        XCTAssertEqual(Module.name(from: "SwiftUI.AnyView"), "SwiftUI")
        XCTAssertEqual(Module.name(from: "Swift.Optional<SwiftUI.AnyView>"), "Swift")
        XCTAssertEqual(Module.name(from: "PBD.ContactUsView"), "PBD")
        XCTAssertEqual(
            Module.name(from: "SwiftUI.TupleView<(SwiftUI.Text, PBD.ContactUsView)>"),
            "SwiftUI",
            "a framework container whose ARGUMENT is the app's view is still SwiftUI's"
        )
    }

    /// **The bug: a type declared inside an extension.** Reading up to the
    /// first `.` gives `(extension in SwiftUI):SwiftUI`, which is in no
    /// allowlist, so SwiftUI's own type was treated as one the developer wrote
    /// — the walk stopped there and refused it, and no tab of an iOS 18
    /// `Tab { }` container was ever identified.
    func testATypeDeclaredInAnExtensionReadsTheRealModule() {
        let name = "(extension in SwiftUI):SwiftUI.Tab<Swift.Never, PBD.ContactUsView, "
            + "SwiftUI.DefaultTabLabel>.TabIdentifiedView"

        XCTAssertEqual(Module.name(from: name), "SwiftUI")
    }

    /// **The one shape this reads as SwiftUI's when it is the developer's, and
    /// the trade Ste took knowingly.**
    ///
    /// The split is on the first colon, with no prefix anchor. A developer's
    /// own generic type carrying an extension-declared type as an argument has
    /// its first colon *inside* that argument, so everything after it is taken
    /// and the module reads `SwiftUI`.
    ///
    /// It is recorded rather than guarded because the shape is
    /// **hand-constructed and has never been observed**: the type it needs,
    /// `Tab<…>.TabIdentifiedView`, is private to SwiftUI and cannot be named
    /// in source, so a developer cannot write this. If it is ever seen in the
    /// wild, the consequence is that the walk enters a view the developer
    /// wrote — so this is the test to come back to, and an anchor on
    /// `"(extension in "` is the one-line repair.
    func testADeveloperTypeCarryingAnExtensionDeclaredArgumentReadsAsSwiftUI() {
        let name = "PBD.MyWrapper<(extension in SwiftUI):SwiftUI.Tab<Swift.Never, "
            + "PBD.ContactUsView, SwiftUI.DefaultTabLabel>.TabIdentifiedView>"

        // The ordering is the whole argument: here the first `.` comes BEFORE
        // the first `:`, because the marker is inside the generic argument
        // rather than at the front.
        //
        //     PBD.MyWrapper<(extension in SwiftUI):SwiftUI.Tab<…>…
        //        ^ first '.' at 3            first ':' at 36 ^
        XCTAssertEqual(offset(of: ".", in: name), 3)
        XCTAssertEqual(offset(of: ":", in: name), 36)

        XCTAssertEqual(
            Module.name(from: name), "SwiftUI",
            "this now reads as PBD, so an anchor has been added back — good, and delete this test"
        )
    }

    /// A name with no module at all must not crash or invent one.
    func testAnUnqualifiedNameIsItsOwnModule() {
        XCTAssertEqual(Module.name(from: "Int"), "Int")
        XCTAssertEqual(Module.name(from: ""), "")
    }

    /// Character offset of the first occurrence, or nil.
    private func offset(of character: Character, in name: String) -> Int? {
        name.firstIndex(of: character).map { name.distance(from: name.startIndex, to: $0) }
    }
}
