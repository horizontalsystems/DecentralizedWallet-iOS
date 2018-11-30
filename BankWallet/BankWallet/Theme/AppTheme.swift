import UIKit
import GrouviActionSheet

class AppTheme {
    static var blurStyle: UIBlurEffectStyle { return App.shared.localStorage.lightMode ? .prominent : .dark }

    static var keyboardAppearance: UIKeyboardAppearance { return App.shared.localStorage.lightMode ? .default : .dark }
    static var textFieldTintColor: UIColor { return .crypto_White_Black }

    public static let defaultAnimationDuration = 0.3

    static let actionSheetBackgroundColor = UIColor.cryptoBars
    static var controllerBackground: UIColor { return .crypto_Dark_LightBackground }
    static var tabBarStyle: UIBarStyle { return App.shared.localStorage.lightMode ? .default : .black }
    static var navigationBarStyle: UIBarStyle { return App.shared.localStorage.lightMode ? .default : .blackTranslucent}
    static var navigationBarTintColor = UIColor.cryptoYellow
    static var statusBarStyle: UIStatusBarStyle { return App.shared.localStorage.lightMode ? .default : .lightContent}

    static let actionSheetConfig = ActionSheetThemeConfig(actionStyle: .sheet(showDismiss: false), cornerRadius: 16)
    static let actionAlertConfig = ActionSheetThemeConfig(actionStyle: .alert, cornerRadius: 16)
}
