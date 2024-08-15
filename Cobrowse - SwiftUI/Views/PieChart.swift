//
//  PieChart.swift
//  Cobrowse - SwiftUI
//

import SwiftUI
import Charts

struct PieChart: View {
    
    let recentTransactions: [Transaction]
    
    private var recentTransactionsByCategory: [Dictionary<Transaction.Category, [Transaction]>.Element] {
        Dictionary(grouping: recentTransactions, by: { $0.category })
            .sorted { $0.key.rawValue < $1.key.rawValue }
    }
    
    @State private var angleSelection: Double?
    @State private var selectedCategory: Transaction.Category?
    
    var body: some View {
        Chart {
            ForEach(recentTransactionsByCategory, id: \.key) { (category, transactions) in
                let total = transactions.reduce(0.0) { $0 + $1.amount }
                
                SectorMark(angle: .value(category.rawValue, total),
                           innerRadius: .ratio(0.5),
                           outerRadius: selectedCategory == category ? .ratio(1.0) : .ratio(0.88),
                           angularInset: 2)
                .foregroundStyle(by: .value(category.rawValue, category.rawValue))
                .annotation(position: .overlay, alignment: .center) {
                    category.icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                        .foregroundStyle(Color.white)
                }
            }
        }
        .chartBackground(content: { proxy in
            VStack {
                Text("Spent")
                    .font(.subheadline)
                    .foregroundStyle(Color.Cobrowse.text)
                
                if let totalSpent = recentTransactions.totalSpent.currencyString {
                    Text(totalSpent)
                        .font(.title)
                        .foregroundStyle(Color.Cobrowse.primary)
                        .redacted()
                }
                
                Text("This month")
                    .font(.subheadline)
                    .foregroundStyle(Color.Cobrowse.text)
            }
        })
        .chartLegend(.hidden)
        .chartForegroundStyleScale(domain: .automatic, range: recentTransactionsByCategory.map { $0.key.color })
        .chartAngleSelection(value: $angleSelection)
        .onChange(of: angleSelection) { _, newValue in
            guard let newValue
                else { return }
            
            selectedCategory = category(for: newValue)
        }
    }
    
    private func category(for value: Double) -> Transaction.Category? {
        var accumulatedCount = 0.0
        
        let category = Array(recentTransactionsByCategory).first { (category, transactions) in
            let total = transactions.reduce(0.0) { $0 + $1.amount }
            accumulatedCount += total
            return value <= accumulatedCount
        }
        
        return category?.key
    }
}
