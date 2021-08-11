//
//  ViewController.swift
//  GroupingSeparatorTextField
//
//  Created by Ting Yen Kuo on 2021/8/11.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textField2: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        [textField, textField2].forEach {
            $0?.font = .systemFont(ofSize: 20)
            $0?.keyboardType = .decimalPad
        }

        // solution 1
        textField.delegate = self
        textField.addTarget(self, action: #selector(handleChanged), for: .editingChanged)

        // solution 2
        textField2.addTarget(self, action: #selector(handleBeginEdit), for: .editingDidBegin)
        textField2.addTarget(self, action: #selector(handleEndEdit), for: .editingDidEnd)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapBackground))
        view.addGestureRecognizer(tapRecognizer)
    }

    @objc func handleTapBackground() {
        view.endEditing(true)
    }

    @objc func handleChanged(textField: UITextField) {
        guard let text = textField.text?.removeGroupingSeparator(),
              let value = Double(text) else { return }
        textField.text = Constant.NumberFormatter.string(from: value as NSNumber)
    }

    @objc func handleBeginEdit(textField: UITextField) {
        guard let value = textField.text?.removeGroupingSeparator().value() else { return }
        textField.text = String(value)
    }

    @objc func handleEndEdit(textField: UITextField) {
        guard let value = textField.text?.removeGroupingSeparator().value() else { return }
        textField.text = Constant.NumberFormatter.string(from: value as NSNumber)
    }

    private enum Constant {
        static let NumberFormatter: Foundation.NumberFormatter = {
            let numberFormatter = Foundation.NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.usesGroupingSeparator = true
            return numberFormatter
        }()
    }
}

extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard var text = textField.text else { return false }
        print("#### text: \(text), range: \(range), replacementString: \(string)")
        let isRemovingCharacter = string.isEmpty

        if isRemovingCharacter {
            // remove character
            let isRemovingLast = range.location + range.length == text.count
            if isRemovingLast {
                return true
            } else {
                let isRemovingSeparator = Array(text)[range.location] == ","
                let oldTextSeparatorCount = text.groupingSeparatorCount()
                if isRemovingSeparator {
                    let index = text.index(text.startIndex, offsetBy: range.location - 1)
                    text.remove(at: index)
                } else {
                    text.deleteCharactersInRange(range: range)
                }

                guard let newValue = text.removeGroupingSeparator().value(), let newText = Constant.NumberFormatter.string(from: newValue as NSNumber) else { return false }
                textField.text = newText
                let newTextSeparatorCount = newText.groupingSeparatorCount()

                // Setup cursor position

                let diffCount = newTextSeparatorCount - oldTextSeparatorCount
                if diffCount == .zero {
                    // append to number next index
                    if let newPosition = textField.position(from: textField.beginningOfDocument, offset: range.location) {
                        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    }
                } else if diffCount < .zero {
                    // since the separator count increased, so append to number next next index (count one separator)
                    if let newPosition = textField.position(from: textField.beginningOfDocument, offset: max(range.location - 1, 0)) {
                        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    }
                }
                return false
            }
        } else {
            // add character
            let isAddingLast = range.location == text.count
            if isAddingLast {
                return true
            } else {
                let oldTextSeparatorCount = text.groupingSeparatorCount()
                let index = text.index(text.startIndex, offsetBy: range.location)
                text.insert(contentsOf: string, at: index)
                guard let newValue = text.removeGroupingSeparator().value(), let newText = Constant.NumberFormatter.string(from: newValue as NSNumber) else { return false }
                textField.text = newText
                let newTextSeparatorCount = newText.groupingSeparatorCount()

                // Setup cursor position

                let diffCount = newTextSeparatorCount - oldTextSeparatorCount
                if diffCount == .zero {
                    // append to number next index
                    if let newPosition = textField.position(from: textField.beginningOfDocument, offset: range.location + 1) {
                        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    }
                } else if diffCount > .zero {
                    // since the separator count increased, so append to number next next index (count one separator)
                    if let newPosition = textField.position(from: textField.beginningOfDocument, offset: range.location + 2) {
                        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    }
                }
                return false
            }
        }
    }
}

extension String {
    func groupingSeparatorCount() -> Int {
        self.components(separatedBy: ",").count - 1
    }

    func removeGroupingSeparator() -> String {
        self.replacingOccurrences(of: ",", with: "")
    }

    func value() -> Double? { Double(self) }

    mutating func deleteCharactersInRange(range: NSRange) {
        let mutableSelf = NSMutableString(string: self)
        mutableSelf.deleteCharacters(in: range)
        self = mutableSelf as String
    }
}
