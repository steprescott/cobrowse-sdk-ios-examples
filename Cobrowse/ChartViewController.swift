//
//  ViewController.swift
//  Cobrowse
//

import UIKit

import Charts
import CobrowseIO

class ChartViewController: UIViewController {
    
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var chartView: PieChartView!
    @IBOutlet weak var spentLabel: UILabel!
    
    var recentTransactions: [Transaction] = [] {
        didSet {
            spentLabel.text = recentTransactions.totalSpent.currencyString
            chartView.data = Dictionary(grouping: recentTransactions, by: { $0.category }).chartData
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        balanceLabel.text = account.total.currencyString
        
        subscribeToSession()
        subscribeToTransactions()
        subscribeToSignedInState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !account.isSignedIn {
            performSegue(to: .signIn)
        }
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        session.current?.end()
    }
}

// MARK: - CobrowseIORedacted

extension ChartViewController: CobrowseIORedacted {
    
    func redactedViews() -> [Any] {
        [
            balanceLabel!,
            spentLabel!
        ]
    }
}

// MARK: - Subscriptions

extension ChartViewController {
    
    private func subscribeToSession() {
        session.$current
            .sink { [self] session in
                let isActive = session?.isActive() ?? false
                sessionButton.isHidden = !isActive
            }
            .store(in: &bag)
    }
    
    private func subscribeToTransactions() {
        account.$transactions
            .sink { [self] transactions in
                recentTransactions = transactions.recentTrnsactions
            }
            .store(in: &bag)
    }
    
    private func subscribeToSignedInState() {
        account.$isSignedIn
            .dropFirst(1)
            .sink { [self] isSignedIn in
                if isSignedIn {
                    dismiss(animated: true) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UIView.animate(withDuration: 0.25) { [self] in
                                chartView.alpha = 1.0
                            }
                        }
                        
                        self.performSegue(to: .transactions)
                    }
                } else {
                    dismiss(animated: false) {
                        self.performSegue(to: .signIn)
                        self.chartView.alpha = 0.0
                    }
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Segue

extension ChartViewController {
    
    @IBAction func unwindSegue(unwindSegue: UIStoryboardSegue) { }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segue.transactions {
            
            guard let sheetPresentationController = segue.destination.sheetPresentationController
                else { return }
            
            segue.destination.isModalInPresentation = true
            
            sheetPresentationController.delegate = sheetPresentationDelegate
            sheetPresentationController.detents = [.small(), .large()]
            sheetPresentationController.largestUndimmedDetentIdentifier = .small
            sheetPresentationController.prefersGrabberVisible = true
        }
    }
}
