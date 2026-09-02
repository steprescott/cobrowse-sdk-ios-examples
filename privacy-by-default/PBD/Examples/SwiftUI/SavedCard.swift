//
//  SavedCard.swift
//  PBD
//

import Foundation

/// A card already on file.
///
/// Split deliberately. The brand, the nickname and the icon are not personal
/// data and an agent helping with a payment needs to see them. "The Visa, the
/// one you call Household bills" is the whole of a useful conversation. Only
/// the digits identify the card, and only they are hidden.
///
/// A row built from one string could not do that, which is what makes this
/// worth showing: the same row is partly redacted and partly not.
struct SavedCard: Hashable, Identifiable {

    /// Visible: the card scheme.
    let brand: String

    /// Visible: what the customer calls this card.
    let nickname: String

    /// Redacted: the only part that identifies the card.
    let lastFour: String

    let symbolName: String

    var id: String { brand + lastFour }

    /// The digits as they read on screen, and what the pattern matches.
    var maskedNumber: String { "•••• \(lastFour)" }

    static let onFile: [SavedCard] = [
        SavedCard(brand: "Visa", nickname: "Everyday spending", lastFour: "4242", symbolName: "creditcard.fill"),
        SavedCard(brand: "Mastercard", nickname: "Household bills", lastFour: "8210", symbolName: "creditcard.circle.fill"),
        SavedCard(brand: "Amex", nickname: "Travel", lastFour: "0005", symbolName: "airplane.circle.fill")
    ]

    /// A card just typed in, named for its last four digits.
    static func entered(number: String) -> SavedCard {
        SavedCard(
            brand: "New payment method",
            nickname: "Added just now",
            lastFour: String(number.suffix(4)),
            symbolName: "creditcard.and.123")
    }
}
