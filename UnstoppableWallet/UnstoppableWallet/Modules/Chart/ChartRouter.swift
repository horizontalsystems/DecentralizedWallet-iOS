import UIKit
import ThemeKit
import LanguageKit
import Chart
import SafariServices

class ChartRouter {
    weak var viewController: UIViewController?
}

extension ChartRouter: IChartRouter {

    func open(link: String?) {
        if let link = link, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    func openAlertSettings(coin: Coin) {
        viewController?.present(ChartNotificationRouter.module(coin: coin, mode: .all), animated: true)
    }

}

extension ChartRouter {

    static func module(coinCode: String, coinTitle: String) -> UIViewController {
        let router = ChartRouter()
        let chartRateFactory = ChartRateFactory(timelineHelper: TimelineHelper(), indicatorFactory: IndicatorFactory(), currentLocale: LanguageManager.shared.currentLocale)
        let interactor = ChartInteractor(rateManager: App.shared.rateManager, chartTypeStorage: App.shared.localStorage, currentDateProvider: CurrentDateProvider(), priceAlertManager: App.shared.priceAlertManager, coinManager: App.shared.coinManager)
        let presenter = ChartPresenter(router: router, interactor: interactor, factory: chartRateFactory, coinCode: coinCode, coinTitle: coinTitle, currency: App.shared.currencyKit.baseCurrency)
        let viewController = ChartViewController(delegate: presenter, configuration: ChartConfiguration.fullChart)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
