//
//  Date.swift
//  Cobrowse
//

import Foundation

extension Date {

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    var formatted: String {
        return Date.formatter.string(from: self)
    }
    
    var startOfMonth: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    var endOfMonth: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: self.startOfMonth)!
        let endOfMonth = calendar.date(byAdding: DateComponents(second: -1), to: startOfNextMonth)!
        return endOfMonth
    }
    
    var day: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.component(.day, from: self)
    }
    
    static func random(between range: ClosedRange<Date>) -> Date {
        let timeInterval = range.upperBound.timeIntervalSince(range.lowerBound)
        let randomTimeInterval = Double.random(in: 0...timeInterval)
        return range.lowerBound.addingTimeInterval(randomTimeInterval)
    }
    
    func isAfterDate(_ date: Date) -> Bool {
        return self > date
    }
    
    func months(ago months: Int) -> Date? {
        var components = DateComponents()
        components.month = -months
        
        return Calendar.current.date(byAdding: components, to: Date())
    }
}
