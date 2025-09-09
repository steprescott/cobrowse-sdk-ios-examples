
import UIKit
import Combine

import CobrowseSDK

class SessionMetricsButton: UIButton {

    private var bag = Set<AnyCancellable>()
    
    var latency: CobrowseSession.Latency = .unknown {
        didSet { tintColor = latency.color }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:  coder)
        
        layer.masksToBounds = true
        
        subscribeToSession()
        subscribeToSessionLatency()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height / 2
    }
}

// MARK: - Subscriptions

extension SessionMetricsButton {
    
    private func subscribeToSession() {
        
        cobrowseSession.$current.sink { [weak self] session in
            
            guard let self, let session, !session.isActive()
                else { return }
            
            self.latency = .unknown
        }
        .store(in: &bag)
    }
    
    private func subscribeToSessionLatency() {
        
        cobrowseSession.$latency.sink { [weak self] latency in
            self?.latency = latency
        }
        .store(in: &bag)
    }
}
