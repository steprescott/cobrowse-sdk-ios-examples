//
//  CodeTextField.swift
//  Cobrowse
//

import UIKit

class CodeTextField: UITextField {
    
    var onDigitInput: ((CodeTextField) -> Void)?
    var onBackspace: ((CodeTextField) -> Void)?

    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc private func textChanged() {
        
        guard let input = text?.last
            else { return }
        
        if input.isDigit {
            text = String(input)
            onDigitInput?(self)
        } else {
            text = nil
        }
    }


    override func deleteBackward() {
        
        onBackspace?(self)
        super.deleteBackward()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }
}

extension Array where Element == CodeTextField {
    
    var code: String {
        compactMap { $0.text }.joined()
    }
    
    var hasCompleteCode: Bool {
        first { $0.text?.isEmpty ?? false } == nil
    }
    
    func reset() {
        
        clear()
        enable()
    }
    
    func clear() {
        forEach { $0.text = nil }
    }
    
    func enable() {
        forEach { $0.isEnabled = true }
    }
    
    func disable() {
        
        forEach {
            $0.resignFirstResponder()
            $0.isEnabled = false
        }
    }
}
