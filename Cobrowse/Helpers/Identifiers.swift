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
}

enum Cells: String {
    
    case transaction = "TransactionTableViewCell"
}

enum VC: String {
    
    case webViewController = "WebViewController"
    case consentPrompt = "ConsentPrompt"
    case fullDevicePrompt = "FullDevicePrompt"
}

enum Detent: String {
    
    case small
}
