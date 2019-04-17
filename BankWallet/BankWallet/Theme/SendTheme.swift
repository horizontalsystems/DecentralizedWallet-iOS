import UIKit
import ActionSheet

class SendTheme {
    static let margin: CGFloat = 16
    static let mediumMargin: CGFloat = 12
    static let smallMargin: CGFloat = 8
    static let tinyMargin: CGFloat = 5

    static var itemBackground: UIColor { return .crypto_Steel20_White }

    static let holderTopMargin: CGFloat = 12
    static let holderCornerRadius: CGFloat = 8
    static let holderBorderWidth: CGFloat = 1 / UIScreen.main.scale
    static let holderBorderColor: UIColor = .cryptoSteel20
    static var holderBackground: UIColor { return .crypto_SteelDark_White }
    static let holderLeadingPadding: CGFloat = 12
    static let holderTopPadding: CGFloat = 9

    static var buttonBackground: RespondButton.Style { return [.active: .crypto_Steel20_LightBackground, .selected: .crypto_Steel40_LightGray, .disabled: UIColor.crypto_Steel20_LightBackground] }
    static let confirmationValueTitleTopMargin: CGFloat = 11
    static let buttonBorderColor = UIColor.cryptoSteel20
    static let buttonCornerRadius: CGFloat = 4
    static var buttonIconColor: UIColor { return .crypto_White_Black }
    static let buttonIconColorDisabled: UIColor = .cryptoSteel20
    static let buttonTitleHorizontalMargin: CGFloat = 12
    static let buttonSize: CGFloat = 32
    static let scanButtonWidth: CGFloat = 36
    static let buttonFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)
    static let errorFont: UIFont = .systemFont(ofSize: 12, weight: .medium)
    static let errorColor: UIColor = .cryptoRed

    static let titleHeight: CGFloat = 48
    static let titleFont = UIFont.cryptoHeadline
    static var titleColor: UIColor { return .crypto_White_Black }

    static let amountHeight: CGFloat = 72
    static let amountFont: UIFont = .cryptoBody2
    static var amountColor: UIColor { return .crypto_Bars_Dark }
    static let amountPlaceholderColor: UIColor = .cryptoSteel40
    static let amountLineColor: UIColor = .cryptoSteel20
    static let amountLineTopMargin: CGFloat = 5
    static let amountLineHeight: CGFloat = 1
    static let amountInputTintColor: UIColor = .cryptoYellow
    static let amountHintFont: UIFont = .cryptoCaption3
    static let amountHintColor: UIColor = .cryptoGray
    static let amountTopMargin: CGFloat = 5
    static let amountErrorLabelTopMargin: CGFloat = 4

    static let addressHeight: CGFloat = 56
    static let addressFont: UIFont = .cryptoBody2
    static var addressColor: UIColor { return .crypto_Bars_Dark }
    static let addressHintColor: UIColor = .cryptoSteel40
    static let addressErrorTopMargin: CGFloat = 2
    static let addressToLabelTextColor: UIColor = .cryptoGray

    static let constantFeeTitleTopMargin: CGFloat = 18
    static let constantFeeHeight: CGFloat = 56
    static let feeTitleTopMargin: CGFloat = 11
    static let feeHeight: CGFloat = 80
    static let feeFont: UIFont = .systemFont(ofSize: 14)
    static let feeColor: UIColor = .cryptoGray
    static var feeSliderTintColor: UIColor { return .crypto_LightGray_SteelDark }
    static let feeSliderThumbColor: UIColor = .cryptoGray
    static let stepViewSideSize: CGFloat = 7
    static let slideBarHeight: CGFloat = 2
    static let feeSliderTopMargin: CGFloat = -6
    static let feeSliderLeftMargin: CGFloat = 19
    static let feeSliderRightMargin: CGFloat = 17
    static let feeSliderHeight: CGFloat = 50

    static let switchRightMargin: CGFloat = 6
    static let pasteRightMargin: CGFloat = 6

    static let sendHeight: CGFloat = 81
    static let sendButtonHeight: CGFloat = 50
    static let sendButtonCornerRadius: CGFloat = 8

    static let keyboardHeight: CGFloat = 209
    static let keyboardTopMargin: CGFloat = 0
    static let keyboardSideMargin: CGFloat = 17
    static let keyboardBottomMargin: CGFloat = 8

    static let confirmationAmountHeight: CGFloat = 80
    static let confirmationCurrencyAmountFont: UIFont = .cryptoTitle4
    static let confirmationCurrencyAmountColor: UIColor = .cryptoYellow
    static let confirmationCurrencyAmountTopMargin: CGFloat = 20
    static let confirmationAmountFont: UIFont = .cryptoSectionCaption
    static let confirmationAmountColor: UIColor = .cryptoGray
    static let confirmationAmountTopMargin: CGFloat = 4

    static let confirmationAddressHeight: CGFloat = 44

    static var hashBackground: UIColor { return .crypto_Steel20_LightBackground }
    static var hashBackgroundSelected: UIColor { return .crypto_Steel40_LightGray }
    static let hashWrapperBorderColor: UIColor = .cryptoSteel20
    static let hashBackgroundHeight: CGFloat = 28
    static let hashCornerRadius: CGFloat = 4
    static var hashColor: UIColor { return .crypto_Bars_Dark }

    static let confirmationFeeValueHeight: CGFloat = 28
    static let confirmationTotalValueHeight: CGFloat = 21
    static let valueFont: UIFont = .cryptoCaption1
    static let valueColor: UIColor = .cryptoGray

    static var confirmationSheetConfig: ActionSheetThemeConfig {
        return ActionSheetThemeConfig(
                actionStyle: .alert,
                sideMargin: 30,
                cornerRadius: 16,
                separatorColor: UIColor.cryptoSteel20,
                backgroundStyle: .blur(intensity: 0.55, style: AppTheme.actionSheetBlurStyle)
        )
    }
}
