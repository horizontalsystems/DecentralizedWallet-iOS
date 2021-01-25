import Foundation

struct MarketOverviewModule {

    static func view() -> MarketOverviewViewController {
        let dataSource = MarketTopDataSource(rateManager: App.shared.rateManager)
        let service = MarketListService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, dataSource: dataSource)
        let viewModel = MarketOverviewViewModel(service: service)

        return MarketOverviewViewController(viewModel: viewModel)
    }

}