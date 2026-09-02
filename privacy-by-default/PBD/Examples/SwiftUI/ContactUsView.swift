//
//  ContactUsView.swift
//  PBD
//

import SwiftUI

/// Support contact numbers. Nothing private on it, and deliberately **not**
/// in `Approvals.swift`.
///
/// It is the demo's argument for redaction by default: a screen whose content
/// nobody would mind an agent seeing is still hidden, because hidden is what a
/// screen is until someone says otherwise. Approving it is one line; forgetting
/// to costs nothing but a black rectangle.
struct ContactUsView: View {

    @Environment(\.dismiss) private var dismiss

    private let numbers = [
        ("General enquiries", "0800 123 4567"),
        ("Billing", "0800 123 4568"),
        ("Report a lost card", "0800 123 4569"),
        ("From abroad", "+44 20 7946 0000")
    ]

    var body: some View {
        List {
            Section("Call us") {
                ForEach(numbers, id: \.0) { name, number in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(number)
                            .font(.title3.monospacedDigit())
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Text("Lines are open 8am to 8pm, seven days a week.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.inline)
        .closable()
        .viewDetails(isApproved: isApproved)
        .cobrowseUnredactedIfNeeded()
    }
}
