//
//  TransactionTableViewCell.swift
//  Cobrowse
//

import UIKit

import CobrowseSDK

class TransactionTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
}

// MARK: - CobrowseIORedacted

extension TransactionTableViewCell: CobrowseIORedacted {
    
    func redactedViews() -> [Any] {
        [
            titleLabel,
            subtitleLabel,
            amountLabel
        ].compactMap { $0 }
    }
}
