//
//  Formatters.swift
//  Cobrowse
//

import Foundation

var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    
    return formatter
}()

var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    
    return formatter
}()

let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter
}()

var ordinalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter
}()

extension Date {
    
    var string: String? {
        dateFormatter.string(from: self)
    }
    
    var timeString: String? {
        timeFormatter.string(from: self)
    }
}

extension Double {
    
    var currencyString: String? {
        currencyFormatter.string(from: NSNumber(value: self))
    }
}

extension Int {
    
    var ordinalString: String? {
        ordinalFormatter.string(from: NSNumber(value: self))
    }
}
