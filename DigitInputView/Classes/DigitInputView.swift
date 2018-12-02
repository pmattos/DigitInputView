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
            configureLabelsAndUnderlines()
        }
    }
    
    /// The color of the line under each digit.
    open var bottomBorderColor = UIColor.lightGray {
        didSet {
            configureLabelsAndUnderlines()
        }
    }
    
    /// The color of the line under next digit.
    open var nextDigitBottomBorderColor = UIColor.gray {
        didSet {
            configureLabelsAndUnderlines()
        }
    }
    
    /// The color of the digits.
    open var textColor: UIColor = .black {
        didSet {
            configureLabelsAndUnderlines()
        }
    }
    
    /// The keyboard type that shows up when entering characters
    open var keyboardType: UIKeyboardType = .default {
        didSet {
            configureTextField()
        }
    }
    
    /// The keyboard appearance style.
    open var keyboardAppearance: UIKeyboardAppearance = .default {
        didSet {
            configureTextField()
        }
    }
    
    /// Provides the keyboard with extra information
    /// about the semantic intent of the text document.
    open var textContentType: UITextContentType! = nil {
        didSet {
            configureTextField()
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
            return textField.text ?? ""
        }
        set {
            textField.text = newValue
            textDidChange()
        }
    }

    /// The view's delegate.
    open weak var delegate: DigitInputViewDelegate?
    
    // MARK: - Private Properties

    private var textField: UITextField!
    private var labels = [UILabel]()
    private var underlines = [UIView]()

    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    private let underlineHeight: CGFloat = 4
    private let spacing: CGFloat = 8
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }
    
    /// Configures the required views.
    private func configureViews() {
        clipsToBounds = true
        isUserInteractionEnabled = true

        tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(viewTapped(_:))
        )
        addGestureRecognizer(tapGestureRecognizer)

        configureTextField()
        configureLabelsAndUnderlines()
    }
    
    /// Configures Sets up the text field?
    private func configureTextField() {
        // First time initialization.
        if textField == nil {
            textField = UITextField()
            textField.frame = CGRect(x: 0, y: -40, width: 100, height: 30) // Hidden field.
            textField.addTarget(
                self,
                action: #selector(textFieldEditingChanged),
                for: .editingChanged
            )
            addSubview(textField)
        }
        textField.delegate = self
        textField.keyboardType = keyboardType
        textField.keyboardAppearance = keyboardAppearance
        if #available(iOS 10.0, *) { textField.textContentType = textContentType }
    }
    
    /// Since this function isn't called frequently, we just
    /// remove everything and recreate them. Don't need to optimize it.
    private func configureLabelsAndUnderlines() {
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
        return true
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
    
    /// Called when the text changes so that the labels get updated.
    fileprivate func textDidChange() {
        for item in labels {
            item.text = ""
        }
        
        for (index, item) in text.enumerated() {
            if labels.count > index {
                let animate = index == text.count - 1
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
            
            UIView.animate(
                withDuration: 0.2, delay: 0,
                usingSpringWithDamping: 0.1, initialSpringVelocity: 1,
                options: .curveEaseInOut, animations: {
                    label.frame.origin.y = self.frame.height - label.frame.height
                },
                completion: nil
            )
        }
        else if animationType == .dissolve {
            UIView.transition(
                with: label,
                duration: 0.4,
                options: .transitionCrossDissolve,
                animations: {
                    label.text = newText
                },
                completion: nil
            )
        }
    }
    
}

// MARK: - TextField Delegate

extension DigitInputView: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString: String) -> Bool {
        
        let oldText = textField.text ?? ""
        let newText = oldText.replacingCharacters(in: Range(range, in: oldText)!,
                                                  with: replacementString)
        
        guard newText.count <= numberOfDigits else { return false }
        guard acceptableCharacters.contains(charactersIn: newText) else { return false }
        
        return true
    }
}

// MARK: - Helpers

fileprivate extension CharacterSet {
    
    /// Returns `true` if all characters in the
    /// specified string are contained in this set.
    func contains(charactersIn string: String) -> Bool {
        let stringCharsSet = CharacterSet(charactersIn: string)
        return self.isSuperset(of: stringCharsSet)
    }
}
