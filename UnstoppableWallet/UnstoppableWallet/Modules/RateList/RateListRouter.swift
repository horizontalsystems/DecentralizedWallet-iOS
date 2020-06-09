import UIKit

class RateListRouter {
    private weak var chartOpener: IChartOpener?

    init(chartOpener: IChartOpener?) {
        self.chartOpener = chartOpener
    }

}

extension RateListRouter: IRateListRouter {

    func showChart(coinCode: String, coinTitle: String) {
        chartOpener?.showChart(coinCode: coinCode, coinTitle: coinTitle)
    }

}

extension RateListRouter {

    static func module(chartOpener: IChartOpener, additionalSafeAreaInsets: UIEdgeInsets = .zero) -> UIViewController {
        let currency = App.shared.currencyKit.baseCurrency

        let router = RateListRouter(chartOpener: chartOpener)
        let interactor = RateListInteractor(rateManager: App.shared.rateManager, walletManager: App.shared.walletManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RateListPresenter(currency: currency, interactor: interactor, router: router)

        let viewController = RateListViewController(delegate: presenter)
        viewController.additionalSafeAreaInsets = additionalSafeAreaInsets

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
