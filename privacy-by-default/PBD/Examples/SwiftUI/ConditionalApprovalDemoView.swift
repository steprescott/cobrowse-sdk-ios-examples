//
//  ConditionalApprovalDemoView.swift
//  PBD
//

import SwiftUI

/// **A conditional where only ONE side is approved — shown in the two places
/// it WORKS.**
///
/// The shape is ordinary: one screen or the other depending on state, where
/// only one of them is approved because only one shows no PII. What the agent
/// should see is the approved side, and black in place of the other.
///
/// - **Pushed** — a `navigationDestination` that switches between an approved
///   and an unapproved screen.
/// - **Presented** — a sheet whose content is an `if/else` between the two.
///
/// Both are judged by the branch on DISPLAY, because SwiftUI hands us that
/// value from its render graph and a `_ConditionalContent` holds only its live
/// branch.
///
/// ⚠ **A conditional TAB is deliberately not demonstrated here, because it
/// does not work and cannot.** A tab's identity is not in any live value: it
/// is read by evaluating the container's `body` off-graph, where a `@State`
/// read returns its INITIAL value, so the declaration is frozen at launch. A
/// conditional tab therefore stays hidden in every state — it fails closed.
/// The reason a tab is the one container like this, and the six other routes
/// that were measured and rejected, are in `README.md` under Limitations. The
/// refusal is asserted in `DeclarationStalenessTests`, and the pattern to use
/// instead — a stable tab with the sensitive screen pushed — in
/// `StableTabPatternTests`.
struct ConditionalApprovalDemoView: View {

    var body: some View {
        TabView {
            PushesAChoiceView()
                .tabItem { Label("Pushed", systemImage: "arrow.turn.down.right") }

            PresentsAChoiceView()
                .tabItem { Label("Presented", systemImage: "rectangle.portrait.bottomhalf.filled") }
        }
        .closesModal()
    }
}

/// A screen that PRESENTS one side of a choice. The sheet's content closure is
/// an `if/else`, so SwiftUI wraps the live branch and the policy reaches it.
struct PresentsAChoiceView: View {

    @State private var showingApproved: Bool?

    var body: some View {
        NavigationStack {
            Form {
                Section("Present one side of a choice") {
                    Button("Present the approved screen") { showingApproved = true }
                    Button("Present the unapproved screen") { showingApproved = false }
                }

                Section {
                    Text("The sheet's content names both screens. The agent sees the approved "
                         + "one and black in place of the other.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Presented choice")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(get: { showingApproved != nil },
                                        set: { if $0 == false { showingApproved = nil } })) {
                if showingApproved == true {
                    ContactUsView()
                } else {
                    JourneyAView()
                }
            }
            .closable()
            .viewDetails(isApproved: isApproved)
        }
    }
}

/// A mixed choice as a PUSHED destination, where it works: the destination
/// closure switches between an approved and an unapproved screen, and the
/// agent sees only the approved one.
struct PushesAChoiceView: View {

    /// One type per route, so the switch is deliberate rather than an accident
    /// of routing.
    enum Route: Hashable, CaseIterable {
        case approved
        case unapproved
    }

    @State private var route: Route?

    var body: some View {
        NavigationStack {
            Form {
                Section("Push one side of a choice") {
                    ForEach(Route.allCases, id: \.self) { route in
                        Button(title(of: route)) { self.route = route }
                    }
                }

                Section {
                    Text("The destination's type names both screens. The agent sees the "
                         + "approved one and not the other, because a pushed choice is "
                         + "judged by the branch on display.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Pushed choice")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $route) { destination(for: $0) }
            .closable()
            .viewDetails(isApproved: isApproved)
        }
    }

    /// The switch. Its static type is `_ConditionalContent<ContactUsView,
    /// JourneyAView>` — one approved, one not — and the value holds only the
    /// branch on display.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
            case .approved: ContactUsView()
            case .unapproved: JourneyAView()
        }
    }

    private func title(of route: Route) -> String {
        switch route {
            case .approved: "Push the approved screen"
            case .unapproved: "Push the unapproved screen"
        }
    }
}

/// A screen that declares the next screen's destination on itself, so its type
/// carries a name that is not the screen on display. Kept because it is the
/// shape a real app writes and a synthetic fixture once passed while this
/// broke.
struct CarriedDestinationView: View {

    @State private var reviewing: SavedCard?

    var body: some View {
        NavigationStack {
            Form {
                Section("A destination carried on this screen") {
                    Button("Review a payment") { reviewing = SavedCard.onFile.first }
                    Text("This screen's type also names PaymentReviewView. Only this one is on screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Carried destination")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $reviewing) { card in
                PaymentReviewView(amount: "10.00", card: card) { reviewing = nil }
            }
            .closable()
            .viewDetails(isApproved: isApproved)
        }
    }
}
