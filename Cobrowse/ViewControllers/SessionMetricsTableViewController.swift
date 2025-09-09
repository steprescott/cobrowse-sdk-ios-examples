
import UIKit
import Combine

import CobrowseSDK

class SessionMetricsTableViewController: UITableViewController {
    
    @IBOutlet var noActiveSessionView: UIView!
    
    private var sessionIsActive = false {
        didSet {
            tableView.backgroundView = sessionIsActive ? nil : noActiveSessionView
            tableView.reloadData()
        }
    }

    private var metrics: CBIOSessionMetrics? {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        subscribeToSession()
        subscribeToSessionMetrics()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sessionIsActive ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(.rightDetail, for: indexPath)!

        cell.textLabel?.text = title(for: indexPath)
        cell.detailTextLabel?.text = valueFor(indexPath: indexPath)
        
        return cell
    }
    
    func title(for indexPath: IndexPath) -> String {
        switch indexPath.row {
            case 0: return "Latency"
            case 1: return "Last updated"
            default: return "N/A"
        }
    }
    
    func valueFor(indexPath: IndexPath) -> String {

        switch indexPath.row {
            case 0:
                guard let latency = metrics?.latency()
                    else { return "..." }
                
                return "\(latency.formatted) s"
            
            case 1:
                guard let lastAlive = metrics?.lastAlive()
                    else { return "..." }

                return lastAlive.formatted
            
            default:
                return "N/A"
        }
    }
}

// MARK: - Subscriptions

extension SessionMetricsTableViewController {
    
    private func subscribeToSession() {
        
        tableView.backgroundView = noActiveSessionView
        
        cobrowseSession.$current.sink { [weak self] session in
            
            guard let self, let session, self.sessionIsActive != session.isActive()
                else { return }
            
            self.sessionIsActive = session.isActive()
        }
        .store(in: &bag)
    }
    
    private func subscribeToSessionMetrics() {
        
        cobrowseSession.$metrics.sink { [weak self] metrics in
            self?.metrics = metrics
        }
        .store(in: &bag)
    }
}
