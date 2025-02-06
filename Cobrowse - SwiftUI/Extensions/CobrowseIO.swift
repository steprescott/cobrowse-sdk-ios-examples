//
//  CobrowseIO.swift
//  CobrowseIO
//

import CobrowseSDK

@available(iOS 13.0, macOS 10.15, *)
public extension CobrowseIO {

    func createSession() async throws -> CBIOSession {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.createSession { error, session in
                    CBErrorSessionBlock.process(error, with: session, for: continuation)
                }
            }
        }
    }
    
    func getSession(_ codeOrID: String) async throws -> CBIOSession {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.getSession(codeOrID) { error, session in
                    CBErrorSessionBlock.process(error, with: session, for: continuation)
                }
            }
        }
    }
}
