//
//  Dictionary.swift
//  Cobrowse
//

extension Dictionary where Key == Date, Value == [Transaction] {
    
    func sectionTitle(for section: Int) -> String? {
        keys.sorted(by: >)[section].string
    }
    
    func `for`(_ section: Int) -> [Transaction] {
        let month = keys.sorted(by: >)[section]
        
        return self[month] ?? []
    }
    
    func transaction(for indexPath: IndexPath) -> Transaction? {
        let month = keys.sorted(by: >)[indexPath.section]
        
        guard let transactionsForMonth = self[month]
            else { return nil }
        
        return transactionsForMonth[indexPath.row]
    }
}

#if canImport(UIKit)
import UIKit
import DGCharts

extension Dictionary where Key == Transaction.Category, Value == [Transaction] {
    
    var chartData: PieChartData {
        PieChartData(dataSet: dataSet)
    }
    
    var dataSet: PieChartDataSet {
        let set = PieChartDataSet(entries: dataEntries)
        
        set.colors = keys.map { $0.color }
        set.drawValuesEnabled = false
        set.sliceSpace = 4
        
        return set
    }
    
    var dataEntries: [PieChartDataEntry] {
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        
        return reduce(into: []) { result, entry in
            let category = entry.key
            let transactions = entry.value
            let total = transactions.reduce(0.0) { $0 + $1.amount }
            let icon = category.icon.withConfiguration(configuration).withTintColor(.white)
            let entry = PieChartDataEntry(value: total, icon: icon)
            
            result.append(entry)
        }
    }
}

#endif
