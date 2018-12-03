import UIKit

extension UIColor {
    static var crypto_Dark_LightBackground: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightBackground : .cryptoDark }
    static var crypto_Dark_Bars: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars: .cryptoDark }
    static var crypto_Steel20_White: UIColor { return App.shared.localStorage.lightMode ? .white : .cryptoSteel20 }
    static var crypto_White_Black: UIColor { return App.shared.localStorage.lightMode ? .black : white }
    static var crypto_Clear_White: UIColor { return App.shared.localStorage.lightMode ? .white : .clear }
    static var crypto_Silver_Black: UIColor { return App.shared.localStorage.lightMode ? .black : .cryptoSilver }

    static var crypto_Silver_Dark50: UIColor { return App.shared.localStorage.lightMode ? .cryptoDark50 : .cryptoSilver50 }

    static var cryptoBars: UIColor = UIColor(named: "Bars") ?? .black
    static var cryptoDark: UIColor = UIColor(named: "Dark") ?? .black
    static var cryptoDark50: UIColor = UIColor(named: "Dark50") ?? .black
    static var cryptoGray: UIColor = UIColor(named: "Gray") ?? .black
    static var cryptoGray50: UIColor = UIColor(named: "Gray50") ?? .black
    static var cryptoGreen: UIColor = UIColor(named: "Green") ?? .black
    static var cryptoGreen50: UIColor = UIColor(named: "Green50") ?? .black
    static var cryptoGreenPressed: UIColor = UIColor(named: "GreenPressed") ?? .black
    static var cryptoGreen20: UIColor = UIColor(named: "Green20") ?? .black
    static var cryptoLightBackground: UIColor = UIColor(named: "LightBackground") ?? .black
    static var cryptoLightGray: UIColor = UIColor(named: "LightGray") ?? .black
    static var cryptoRed: UIColor = UIColor(named: "Red") ?? .black
    static var cryptoRedPressed: UIColor = UIColor(named: "RedPressed") ?? .black
    static var cryptoSilver: UIColor = UIColor(named: "Silver") ?? .black
    static var cryptoSilver50: UIColor = UIColor(named: "Silver50") ?? .black
    static var cryptoSteel20: UIColor = UIColor(named: "Steel20") ?? .black
    static var cryptoWhite50: UIColor = UIColor(named: "White50") ?? .black
    static var cryptoYellow: UIColor = UIColor(named: "Yellow") ?? .black
    static var cryptoYellow50: UIColor = UIColor(named: "Yellow50") ?? .black
    static var cryptoYellow40: UIColor = UIColor(named: "Yellow40") ?? .black
    static var cryptoYellowPressed: UIColor = UIColor(named: "YellowPressed") ?? .black
}
