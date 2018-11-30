/**
 Copyright (c) 2017 Milad Nozari
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

public enum DigitInputViewAnimationType: Int {
    case none, dissolve, spring
}

// MARK: -

public protocol DigitInputViewDelegate: class {
    func digitsDidChange(digitInputView: DigitInputView)
}

// MARK: -

open class DigitInputView: UIView {
    
    // MARK: - Properties
    
    /// The number of digits to show, which will be the maximum length of the final string.
    open var numberOfDigits: Int = 4 {
        didSet {
            setUp()
        }
    }
    
    /// The color of the line under each digit.
    open var bottomBorderColor = UIColor.lightGray {
        didSet {
            setUp()
        }
    }
    
    /// The color of the line under next digit.
    open var nextDigitBottomBorderColor = UIColor.gray {
        didSet {
            setUp()
        }
    }
    
    /// The color of the digits.
    open var textColor: UIColor = .black {
        didSet {
            setUp()
        }
    }
    
    /// The keyboard type that shows up when entering characters
    open var keyboardType: UIKeyboardType = .default {
        didSet {
            setUp()
        }
    }
    
    /// The keyboard appearance style.
    open var keyboardAppearance: UIKeyboardAppearance = .default {
        didSet {
            setUp()
        }
    }
    
    /// Only the characters in this string are acceptable.
    /// The rest will be ignored.
    open var acceptableCharacters = CharacterSet.decimalDigits
    
    /// The animation to use to show new digits.
    open var animationType: DigitInputViewAnimationType = .spring
    
    /// The font of the digits (although font size will be calculated automatically).
    open var font: UIFont?
    
    /// The string that the user has entered.
    open var text: String {
        get {
            guard let textField = textField else { return "" }
            return textField.text ?? ""
        }
        
    }

    open weak var delegate: DigitInputViewDelegate?
    
    fileprivate var labels = [UILabel]()
    fileprivate var underlines = [UIView]()
    fileprivate var textField: UITextField?
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?
    
    private let underlineHeight: CGFloat = 4
    private let spacing: CGFloat = 8
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    /// Sets up the required views.
    private func setUp() {
        clipsToBounds = true
        isUserInteractionEnabled = true
        
        if textField.superview == nil {
            textField.frame = CGRect(x: 0, y: -40, width: 100, height: 30) // Hidden field.
            addSubview(textField)
        }
        textField.delegate = self
        textField.keyboardType = keyboardType
        textField.keyboardAppearance = keyboardAppearance
        textField.addTarget(
            self,
            action: #selector(textFieldEditingChanged),
            for: .editingChanged
        )

        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(viewTapped(_:))
            )
            addGestureRecognizer(tapGestureRecognizer!)
        }

        setUpLabelsAndUnderlines()
    }
    
    /// Since this function isn't called frequently, we just
    /// remove everything and recreate them. Don't need to optimize it.
    private func setUpLabelsAndUnderlines() {
        for label in labels {
            label.removeFromSuperview()
        }
        for underline in underlines {
            underline.removeFromSuperview()
        }
        labels.removeAll()
        underlines.removeAll()
        
        for i in 0..<numberOfDigits {
            let label = UILabel()
            label.textAlignment = .center
            label.isUserInteractionEnabled = false
            label.textColor = textColor
            
            let underline = UIView()
            if i == 0 {
                underline.backgroundColor = nextDigitBottomBorderColor
            } else {
                underline.backgroundColor = bottomBorderColor
            }
            
            addSubview(label)
            addSubview(underline)
            labels.append(label)
            underlines.append(underline)
        }
    }
    
    // MARK: - First Responder
    
    override open var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override open func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    override open func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        /// Maximun number of digits as CGFloat.
        let numberOfDigits = CGFloat(self.numberOfDigits)
        
        // Width to height ratio.
        let ratio: CGFloat = 0.75
        
        // Now we find the optimal font size based on the view size
        // and set the frame for the labels.
        var characterWidth = frame.height * ratio
        var characterHeight = frame.height
        
        // If using the current width, the digits go off the view, recalculate
        // based on width instead of height.
        if (characterWidth + spacing) * numberOfDigits + spacing > frame.width {
            characterWidth = (frame.width - spacing * (numberOfDigits + 1)) / numberOfDigits
            characterHeight = characterWidth / ratio
        }
        
        let extraSpace = frame.width - (numberOfDigits - 1) * spacing -
                         numberOfDigits * characterWidth
        
        // Font size should be less than the available vertical space.
        let fontSize = characterHeight * 0.8
        
        let y = (frame.height - characterHeight) / 2
        for (index, label) in labels.enumerated() {
            let x = extraSpace / 2 + (characterWidth + spacing) * CGFloat(index)
            label.frame = CGRect(x: x, y: y, width: characterWidth, height: characterHeight)
            
            underlines[index].frame = CGRect(x: x, y: frame.height - underlineHeight,
                                             width: characterWidth, height: underlineHeight)
            
            if let font = font {
                label.font = font.withSize(fontSize)
            }
            else {
                label.font = label.font.withSize(fontSize)
            }
        }
    }
    
    /// Handles tap gesture on the view.
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        textField.becomeFirstResponder()
    }
    
    @objc private func textFieldEditingChanged() {
        textDidChange()
    }
    
    /**
     Called when the text changes so that the labels get updated
    */
    fileprivate func didChange(_ backspaced: Bool = false) {
        
        guard let textField = textField, let text = textField.text else { return }
        
        for item in labels {
            item.text = ""
        }
        
        for (index, item) in text.enumerated() {
            if labels.count > index {
                let animate = index == text.count - 1 && !backspaced
                changeText(of: labels[index], newText: String(item), animate)
            }
        }
        
        // Set all the bottom borders color to default.
        for underline in underlines {
            underline.backgroundColor = bottomBorderColor
        }
        
        let nextIndex = text.count
        if labels.count > 0 && nextIndex < labels.count {
            // Set the next digit bottom border color.
            underlines[nextIndex].backgroundColor = nextDigitBottomBorderColor
        }
        
        delegate?.digitsDidChange(digitInputView: self)
    }
    
    /// Changes the text of a UILabel with animation
    ///
    /// - parameter label: The label to change text of
    /// - parameter newText: The new string for the label
    private func changeText(of label: UILabel, newText: String, _ animated: Bool = false) {
        guard animated && animationType != .none else {
            label.text = newText
            return
        }
        
        if animationType == .spring {
            label.frame.origin.y = frame.height
            label.text = newText
            
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: { 
                label.frame.origin.y = self.frame.height - label.frame.height
            }, completion: nil)
        }
        else if animationType == .dissolve {
            UIView.transition(with: label,
                              duration: 0.4,
                              options: .transitionCrossDissolve,
                              animations: {
                                label.text = newText
            }, completion: nil)
        }
    }
    
}


// MARK: TextField Delegate
extension DigitInputView: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let char = string.cString(using: .utf8)
        let isBackSpace = strcmp(char, "\\b")
        if isBackSpace == -92 {
            textField.text!.removeLast()
            didChange(true)
            return false
        }
        
        if textField.text?.count ?? 0 >= numberOfDigits {
            return false
        }
        
        guard let acceptableCharacters = acceptableCharacters else {
            textField.text = (textField.text ?? "") + string
            didChange()
            return false
        }
        
        if acceptableCharacters.contains(string) {
            textField.text = (textField.text ?? "") + string
            didChange()
            return false
        }
        
        return false
        
    }
    
}
