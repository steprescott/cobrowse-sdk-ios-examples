//
//  CodeTextField.swift
//  Cobrowse
//

import UIKit

class CodeTextField: UITextField {
    
    var onDigitInput: ((CodeTextField) -> Void)?
    var onFocus: ((CodeTextField) -> Void)?
    var onBackspace: ((CodeTextField) -> Void)?

    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        borderStyle = .roundedRect
        keyboardType = .numberPad
        textAlignment = .center
        font = UIFont.preferredFont(forTextStyle: .largeTitle)
        
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
        addTarget(self, action: #selector(textEditingDidBegin), for: .editingDidBegin)
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

    @objc private func textEditingDidBegin() {
        onFocus?(self)
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
