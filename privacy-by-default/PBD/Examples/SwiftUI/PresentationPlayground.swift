//
//  PresentationPlayground.swift
//  PBD
//

import SwiftUI

// Two view types with identical bodies, because approval is per type: one is in
// `Approvals.swift` and the other is not. Each can present either at the next
// depth, in any style, so any stack of approved and unapproved screens can be
// built by tapping.

/// The approved half of the pair, identical to `UnapprovedPresentationView` in
/// everything but its type, which is all approval keys on.
struct ApprovedPresentationView: View {

    let depth: Int

    var body: some View {
        PresentationPlayground(depth: depth, isApproved: isApproved)
            .cobrowseUnredactedIfNeeded()
    }
}

/// The other half. See `ApprovedPresentationView`.
struct UnapprovedPresentationView: View {

    let depth: Int

    var body: some View {
        PresentationPlayground(depth: depth, isApproved: isApproved)
    }
}

/// The body both halves share.
///
/// Presents either type at the next depth in any style, so a stack of approved
/// and unapproved screens can be built by tapping.
private struct PresentationPlayground: View {

    let depth: Int
    let isApproved: Bool

    @Environment(\.dismiss) private var dismiss

    // One binding per style *and* per approval, because each presentation
    // closure has to return a single concrete view.
    //
    // A `@ViewBuilder` choosing between the two has the type
    // `_ConditionalContent<ApprovedPresentationView, UnapprovedPresentationView>`,
    // which names both, so nothing can say which is on screen and everything
    // presented that way stays hidden. The same rule as `navigationDestination`:
    // declare one per view type.
    @State private var approvedSheet: Int?
    @State private var unapprovedSheet: Int?
    @State private var approvedCover: Int?
    @State private var unapprovedCover: Int?
    @State private var approvedPopover: Int?
    @State private var unapprovedPopover: Int?

    /// A popover is sized by its content, and the grid inside is cramped below
    /// this. The UIKit twin says the same thing through `preferredContentSize`.
    private static let popoverMinimumWidth: CGFloat = 380

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("\(isApproved ? "Approved" : "Unapproved") · depth \(depth)")
                .font(.title2).bold()

            grid

            Spacer()
        }
        .padding()
        .closableOverContent()
        .viewDetails(isApproved: isApproved)
        .sheet(item: $approvedSheet) { ApprovedPresentationView(depth: $0) }
        .sheet(item: $unapprovedSheet) { UnapprovedPresentationView(depth: $0) }
        .fullScreenCover(item: $approvedCover) { ApprovedPresentationView(depth: $0) }
        .fullScreenCover(item: $unapprovedCover) { UnapprovedPresentationView(depth: $0) }
    }

    /// One grid rather than three rows, so every cell is the same size whatever
    /// its label. The popovers are declared on their own buttons, because a
    /// popover points at the view it is attached to, so declare it on the screen
    /// and it points at the screen.
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            header("Approved", tint: .green)
            header("Unapproved", tint: .red)

            button("Sheet", tint: .green, presents: $approvedSheet)
            button("Sheet", tint: .red, presents: $unapprovedSheet)

            button("Cover", tint: .green, presents: $approvedCover)
            button("Cover", tint: .red, presents: $unapprovedCover)

            button("Popover", tint: .green, presents: $approvedPopover)
                .popover(item: $approvedPopover) {
                    ApprovedPresentationView(depth: $0)
                        .frame(minWidth: Self.popoverMinimumWidth)
                        .presentationCompactAdaptation(.popover)
                }

            button("Popover", tint: .red, presents: $unapprovedPopover)
                .popover(item: $unapprovedPopover) {
                    UnapprovedPresentationView(depth: $0)
                        .frame(minWidth: Self.popoverMinimumWidth)
                        .presentationCompactAdaptation(.popover)
                }
        }
    }

    private func header(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
    }

    /// The width goes on the *label*: a button style sizes its background to what
    /// it is given, so a frame outside the button only centres a self-sized one.
    private func button(_ title: String, tint: Color, presents depth: Binding<Int?>) -> some View {
        Button {
            depth.wrappedValue = self.depth + 1
        } label: {
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(tint)
    }
}

/// So a depth can drive `sheet(item:)` directly.
extension Int: @retroactive Identifiable {

    public var id: Int { self }
}
