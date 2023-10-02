//
//  SheetPresentationDelegate.swift
//  Cobrowse
//

import UIKit

import Combine

let sheetPresentationDelegate = SheetPresentationDelegate()

class SheetPresentationDelegate: NSObject {
    
    @Published var identifier: String?
    
    static func subscribe(for item: UIBarButtonItem, store bag: inout Set<AnyCancellable>) {

        sheetPresentationDelegate.$identifier.sink { identifier in
            guard identifier != Detent.small,
                  let session = session.current,
                  session.isActive()
            else { item.isHidden = true; return }

            item.isHidden = false;
        }
        .store(in: &bag)
        
        session.$current.sink { session in
            guard let session = session,
                  session.isActive(),
                  let identifier = sheetPresentationDelegate.identifier,
                  identifier != Detent.small
                else { item.isHidden = true; return }
            
            item.isHidden = false
        }
        .store(in: &bag)
    }
}

// MARK: - UISheetPresentationControllerDelegate

extension SheetPresentationDelegate: UISheetPresentationControllerDelegate {
    
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        identifier = sheetPresentationController.selectedDetentIdentifier?.rawValue
    }
}
