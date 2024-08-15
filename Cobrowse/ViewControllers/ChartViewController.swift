//
//  ViewController.swift
//  Cobrowse
//

import UIKit
import Combine

import DGCharts
import CobrowseIO

class ChartViewController: UIViewController {

    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var profileButton: UIBarButtonItem!
    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var chartView: PieChartView!
    @IBOutlet weak var spentLabel: UILabel!
    
    private var bag = Set<AnyCancellable>()
    
    var recentTransactions: [Transaction] = [] {
        didSet {
            spentLabel.text = recentTransactions.totalSpent.currencyString
            chartView.data = Dictionary(grouping: recentTransactions, by: { $0.category }).chartData
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        balanceLabel.text = account.balance.currencyString
        profileButton.isHidden = true
        stackView.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard bag.isEmpty
            else { return }
        
        subscribeToSession()
        subscribeToTransactions()
        subscribeToSignedInState()
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

// MARK: - CobrowseIOUredacted

extension ChartViewController: CobrowseIOUnredacted {
    
    func unredactedViews() -> [Any] {
        
        guard session.isRedactionByDefaultEnabled
            else { return [] }
        
        return [
            spentLabel!,
            chartView!
        ]
    }
}

// MARK: - Subscriptions

extension ChartViewController {
    
    private func subscribeToSession() {
        session.$current
            .sink { [weak self] session in
                guard let self = self else { return }
                
                let isActive = session?.isActive() ?? false
                sessionButton.isHidden = !isActive
            }
            .store(in: &bag)
    }
    
    private func subscribeToTransactions() {
        account.$transactions
            .sink { [weak self] transactions in
                guard let self = self else { return }
                
                recentTransactions = transactions.recentTransactions
            }
            .store(in: &bag)
    }
    
    private func subscribeToSignedInState() {
        account.$isSignedIn
            .sink { [weak self] isSignedIn in
                guard let self = self else { return }
                
                if isSignedIn {
                    
                    profileButton.isHidden = false
                    
                    dismiss(animated: true) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UIView.animate(withDuration: 0.25) { [weak self] in
                                guard let self = self else { return }
                                
                                stackView.alpha = 1.0
                            }
                        }
                        
                        self.performSegue(to: .transactions)
                    }
                } else {
                    dismiss(animated: false) { [weak self] in
                        guard let self = self else { return }
                        
                        performSegue(to: .signIn)
                        stackView.alpha = 0.0
                        profileButton.isHidden = true
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
