//
//  CodeInput.swift
//  Cobrowse - SwiftUI
//

import SwiftUI

struct CodeInput: View {
    
    @Binding var code: String?
    @State private var codeValues = Array(repeating: "", count: 6)
    @State private var isDisabled = false
    @FocusState private var focusedInput: Int?
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<6, id: \.self) { index in
                Input(index: index, value: $codeValues[index]) { textField in
                    codeValues[index] = textField.text ?? ""
                    focusedInput = index + 1
                }
                onFocus: { textField in
                    let codeIndex = codeValues.count - 1
                    let nextIndex = min(index + 1, codeIndex)

                    guard !codeValues[index].isEmpty, codeValues[nextIndex].isEmpty
                        else { return }
                    
                    textField.text = nil
                    codeValues[index] = ""
                }
                onBackspace: { textField in
                    let nextIndex = min(index + 1, codeValues.count - 1)

                    guard !codeValues[index].isEmpty else {
                        focusedInput = index - 1
                        return
                    }

                    let isNextIndexNotEmpty = !codeValues[nextIndex].isEmpty
                    let isLastCodeNotEmpty = (codeValues.last != nil && !codeValues.last!.isEmpty)

                    if isNextIndexNotEmpty || isLastCodeNotEmpty {
                        textField.text = nil
                        codeValues[index] = ""
                    } else {
                        codeValues[index] = ""
                        focusedInput = index - 1
                    }
                }
                .disabled(isDisabled)
                .focused($focusedInput, equals: index)
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .onAppear {
            focusedInput = 0
        }
        .onChange(of: code, { _, _ in
            if code == nil {
                codeValues = Array(repeating: "", count: 6)
                isDisabled = false
                focusedInput = 0
            }
        })
        .onChange(of: codeValues, { _, _ in
            if codeValues.allSatisfy({ !$0.isEmpty }) {
                isDisabled = true
                code = codeValues.joined()
            }
        })
    }
}

struct Input: UIViewRepresentable {
    
    let index: Int
    
    @Binding var value: String

    var onDigitInput: ((CodeTextField) -> Void)?
    var onFocus: ((CodeTextField) -> Void)?
    var onBackspace: ((CodeTextField) -> Void)?
    
    func makeUIView(context: Context) -> CodeTextField {
        let textField = CodeTextField()
        
        textField.text = value
        textField.tag = index
        textField.placeholder = "\(index + 1)"
        textField.onDigitInput = { _ in self.onDigitInput?(textField) }
        textField.onFocus = { _ in self.onFocus?(textField) }
        textField.onBackspace = { _ in self.onBackspace?(textField) }
            
        return textField
    }
    
    func updateUIView(_ textField: CodeTextField, context: Context) {
        textField.text = value
    }
}
