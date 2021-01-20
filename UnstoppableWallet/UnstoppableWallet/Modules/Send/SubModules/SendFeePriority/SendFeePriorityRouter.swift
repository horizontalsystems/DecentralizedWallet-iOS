import UIKit
import ThemeKit

class SendFeePriorityRouter {
    weak var viewController: UIViewController?
}

extension SendFeePriorityRouter {

    static func module(coin: Coin, customPriorityUnit: CustomPriorityUnit? = nil) -> (UIView?, ISendFeePriorityModule, ISendSubRouter)? {
        let feeCoin = App.shared.feeCoinProvider.feeCoin(coin: coin) ?? coin

        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: feeCoin.type) else {
            return nil
        }

        let router = SendFeePriorityRouter()
        let interactor = SendFeePriorityInteractor(provider: feeRateProvider)
        let presenter = SendFeePriorityPresenter(interactor: interactor, router: router, coin: coin)
        interactor.delegate = presenter

        var view: SendFeePriorityView? = nil
        if !feeRateProvider.feeRatePriorityList.isEmpty {
            view = SendFeePriorityView(delegate: presenter, customPriorityUnit: customPriorityUnit)
            presenter.view = view
        }

        return (view, presenter, router)
    }

}

extension SendFeePriorityRouter: ISendFeePriorityRouter {

    func openPriorities(items: [PriorityItem], onSelect: @escaping (PriorityItem) -> ()) {
        let alertController = AlertRouter.module(
                title: "send.tx_speed".localized,
                viewItems: items.map { item in
                    AlertViewItem(text: "\(item.priority.title)", selected: item.selected)
                }
        ) { index in
            onSelect(items[index])
        }

        viewController?.present(alertController, animated: true)
    }

    func openFeeInfo() {
        let controller = InfoModule.viewController(dataSource: FeeInfoDataSource())
        viewController?.present(ThemeNavigationController(rootViewController: controller), animated: true)
    }

}

extension SendFeePriorityRouter: ISendSubRouter {
}
