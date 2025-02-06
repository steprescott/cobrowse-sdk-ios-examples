//
//  CBIOSession.swift
//  CobrowseIO
//

import CobrowseSDK

@available(iOS 13.0, macOS 10.15, *)
public extension CBIOSession {
    @discardableResult
    func setFullDevice(state: CBIOFullDeviceState) async throws -> CBIOSession {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.setFullDevice(state) { error, session in
                    CBErrorSessionBlock.process(error, with: session, for: continuation)
                }
            }
        }
    }
    
    @discardableResult
    func setRemoteControl(state: CBIORemoteControlState) async throws -> CBIOSession {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.setRemoteControl(state) { error, session in
                    CBErrorSessionBlock.process(error, with: session, for: continuation)
                }
            }
        }
    }
    
    @discardableResult
    func set(capabilities: [String]) async throws -> CBIOSession {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.setCapabilities(capabilities) { error, session in
                    CBErrorSessionBlock.process(error, with: session, for: continuation)
                }
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
enum CBErrorSessionBlock {
    static func process(_ error: Error?, with session: CBIOSession?, for continuation: CheckedContinuation<CBIOSession, any Error>) {
        switch (session, error) {
            case (_, nil): continuation.resume(with: .success(session!))
            case (nil, _): continuation.resume(throwing: error!)
            default: continuation.resume(throwing: NSError(domain: "Unknown Error", code: 0, userInfo: nil))
        }
    }
}
