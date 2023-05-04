//
//  Publisher.swift
//  Cobrowse
//

import Combine

extension Publisher where Self == Published<String>.Publisher {
    
    static func isNotEmpty(_ publisher: Self) -> AnyPublisher<Bool, Never> {
        publisher
            .map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
}
