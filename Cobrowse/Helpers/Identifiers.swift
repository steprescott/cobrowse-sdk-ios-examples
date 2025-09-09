//
//  Identifiers.swift
//  Cobrowse
//

import Foundation

enum Segue: String {
    
    case account = "Account"
    case transaction = "Transaction"
    case transactions = "Transactions"
    case signIn = "SignIn"
    case sessionMetrics = "SessionMetrics"
}

enum Cells: String {
    
    case transaction = "TransactionTableViewCell"
    case rightDetail = "RightDetailTableViewCell"
}

enum VC: String {
    
    case webViewController = "WebViewController"
    case consentPrompt = "ConsentPrompt"
    case fullDevicePrompt = "FullDevicePrompt"
}

enum Detent: String {
    
    case small
}
