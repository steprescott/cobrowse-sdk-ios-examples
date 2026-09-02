//
//  View+Closable.swift
//  PBD
//

import SwiftUI

// The close affordance every presented example shows: an X, top right.
//
// Two placements, because a popover is sized by its content and a navigation bar
// would make it fill the screen.
//
// The X closes the whole presentation, not one screen of it. SwiftUI's `dismiss`
// pops when it is called from a pushed view, so the root of a presentation
// publishes its own dismiss for everything below it to use.

extension View {

    /// An X in the navigation bar. For a screen that has one.
    func closable() -> some View {
        modifier(ClosableBar())
    }

    /// An X drawn over the content. For a screen with no navigation bar, such as a
    /// popover, or anything else sized by what it contains.
    func closableOverContent() -> some View {
        modifier(ClosableOverlay())
    }

    /// Marks the root of a presentation, so an X pushed deeper inside it closes
    /// all of it rather than popping one screen.
    func closesModal() -> some View {
        modifier(ModalRoot())
    }
}

/// Publishes a presentation's own dismiss to everything inside it.
private struct ModalRoot: ViewModifier {

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.environment(\.closeModal, CloseModalAction { dismiss() })
    }
}

/// The X as a navigation bar item.
private struct ClosableBar: ViewModifier {

    @Environment(\.closeModal) private var closeModal
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CloseLabel(close: closeModal ?? CloseModalAction { dismiss() })
            }
        }
    }
}

/// The X for a screen with no bar to put it in.
private struct ClosableOverlay: ViewModifier {

    @Environment(\.closeModal) private var closeModal
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        // An inset rather than an overlay, so the button reserves its own space
        // and the content starts below it, the way a navigation bar behaves.
        content.safeAreaInset(edge: .top) {
            HStack {
                Spacer()

                Button {
                    (closeModal ?? CloseModalAction { dismiss() })()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(.background, in: .circle)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
                }
                // Plain, so the X stays the label's own colour rather than
                // taking the accent tint.
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

/// The X itself, so both placements draw the same thing.
private struct CloseLabel: View {

    let close: CloseModalAction

    var body: some View {
        Button {
            close()
        } label: {
            Image(systemName: "xmark")
        }
    }
}

/// Closes the presentation this view is inside, from any depth within it.
///
/// Falls back to the nearest `dismiss` where no root has claimed it, so a screen
/// presented on its own still closes.
struct CloseModalAction {

    fileprivate let close: () -> Void

    fileprivate init(close: @escaping () -> Void) {
        self.close = close
    }

    func callAsFunction() {
        close()
    }
}

/// Carries a presentation root's dismiss down to its pushed screens.
private struct CloseModalKey: EnvironmentKey {

    /// Nothing by default, so a screen with no presentation root above it falls
    /// back to its own `dismiss` rather than to a button that does nothing.
    static let defaultValue: CloseModalAction? = nil
}

extension EnvironmentValues {

    var closeModal: CloseModalAction? {
        get { self[CloseModalKey.self] }
        set { self[CloseModalKey.self] = newValue }
    }
}
