import UIKit
import SnapKit

@IBDesignable
class IndexedInputField: UIView, UITextFieldDelegate {

    var textField: UITextField
    var indexLabel: UILabel

    var clearWrapperView: UIView
    var clearTextButton: UIButton
    var clearTextImageView: UIImageView

    var _clearButtonIsHidden = false
    var clearButtonIsHidden: Bool {
        set {
            _clearButtonIsHidden = newValue
            clearWrapperView.isHidden = newValue
            clearWrapperView.snp.updateConstraints { maker in
                maker.width.equalTo(newValue ? InputFieldTheme.cancelableRightMargin : InputFieldTheme.nonCancelableRightMargin)
            }
        }
        get {
            return _clearButtonIsHidden
        }
    }

//    @IBInspectable var contentBackgroundColor: UIColor? {
//        get {
//            return backgroundColor
//        }
//        set {
//            backgroundColor = newValue
//        }
//    }
//
//    @IBInspectable var cornerRadius: CGFloat {
//        get {
//            return layer.cornerRadius
//        }
//        set {
//            layer.cornerRadius = newValue
//            layer.masksToBounds = newValue != 0
//        }
//    }
//    @IBInspectable var borderWidth: CGFloat {
//        get {
//            return layer.borderWidth
//        }
//        set {
//            layer.borderWidth = newValue
//        }
//    }
//    @IBInspectable var borderColor: UIColor? {
//        get {
//            guard let color = layer.borderColor else { return nil }
//            return UIColor(cgColor: color)
//        }
//        set {
//            layer.borderColor = newValue?.cgColor
//        }
//    }

    var onReturn: (() -> ())?
    var onSpaceKey: (() -> Bool)?
    var onTextChange: ((String?) -> ())?

    override init(frame: CGRect) {
        indexLabel = UILabel()
        textField = UITextField()

        clearWrapperView = UIView()
        clearTextButton = UIButton()
        clearTextImageView = UIImageView(image: UIImage(named: "Cancel Input Icon"))
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        indexLabel = UILabel()
        textField = UITextField()

        clearWrapperView = UIView()
        clearTextButton = UIButton()
        clearTextImageView = UIImageView(image: UIImage(named: "Cancel Input Icon"))
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        backgroundColor = .appLawrence

        clearTextButton.addTarget(self, action: #selector(onClearText), for: .touchUpInside)

        clearWrapperView.isHidden = true
        clearWrapperView.addSubview(clearTextImageView)
        clearWrapperView.addSubview(clearTextButton)
        clearTextButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        clearTextImageView.snp.makeConstraints { maker in
            maker.width.height.equalTo(InputFieldTheme.clearTextIconSideSize)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-InputFieldTheme.clearTextIconRightMargin)
        }
        addSubview(clearWrapperView)
        clearWrapperView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(InputFieldTheme.nonCancelableRightMargin)
        }

        addSubview(indexLabel)
        indexLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(InputFieldTheme.indexMargin)
            maker.centerY.equalToSuperview()
            maker.width.equalTo(InputFieldTheme.indexWidth)
        }
        indexLabel.textColor = InputFieldTheme.indexColor
        indexLabel.font = InputFieldTheme.indexFont

        textField.keyboardAppearance = App.theme.keyboardAppearance
        textField.autocorrectionType = .yes
        textField.autocapitalizationType = .none
        textField.tintColor = AppTheme.textFieldTintColor
        textField.font = InputFieldTheme.indexFont

        textField.addTarget(self, action: #selector(textChange), for: .editingChanged)
        textField.textColor = InputFieldTheme.textColor
        textField.delegate = self
        addSubview(textField)
        textField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(InputFieldTheme.inputFieldRightMargin)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.trailing.equalTo(self.clearWrapperView.snp.leading)
            maker.height.equalTo(InputFieldTheme.indexFont.lineHeight)
        }
    }

    @objc func onClearText() {
        textField.text = nil
        clearWrapperView.isHidden = true
    }

    @objc func textChange(textField: UITextField) {
        clearWrapperView.isHidden = _clearButtonIsHidden || (textField.text?.isEmpty ?? true)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        clearWrapperView.isHidden = _clearButtonIsHidden || (textField.text?.isEmpty ?? true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        onTextChange?(textField.text)
        clearWrapperView.isHidden = true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch string {
        case " ":
            return onSpaceKey?() ?? true
        default:
            return true
        }
    }
}
