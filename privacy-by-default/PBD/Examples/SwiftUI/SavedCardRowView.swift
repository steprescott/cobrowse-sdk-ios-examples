//
//  SavedCardRowView.swift
//  PBD
//

import SwiftUI
import CobrowseSDK

/// A saved card: icon, brand, nickname, and the digits off on their own.
///
/// The separation is the point. `RedactedByRegexDelegate` reads one label at a
/// time, so putting the digits in their own label is what lets an agent see
/// which card is which while the number itself stays hidden. Written as a single
/// "Visa •••• 4242" string, matching it would black out the whole row.
///
/// `SavedCardRow` is the UIKit twin, drawn the same way.
struct SavedCardRowView: View {

    let card: SavedCard

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: card.symbolName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.nickname)
                    .font(.body)
                Text(card.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(card.maskedNumber)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .cobrowseRedacted()
        }
        .padding(.vertical, 4)
    }
}
