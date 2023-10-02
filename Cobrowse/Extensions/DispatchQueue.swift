//
//  DispatchQueue.swift
//  Cobrowse
//

import Foundation

func async(after seconds: Double, execute work: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
}
