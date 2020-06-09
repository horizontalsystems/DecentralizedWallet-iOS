import Foundation
import XRatesKit
import CurrencyKit

protocol IRateListView: AnyObject {
    func set(viewItems: [RateListModule.CoinViewItem])
    func set(lastUpdated: Date)
    func refresh()
}

protocol IRateListViewDelegate {
    func onLoad()
    func onSelectCoin(index: Int)
}

protocol IRateListInteractor {
    var wallets: [Wallet] { get }
    var featuredCoins: [Coin] { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfos(currencyCode: String)
}

protocol IRateListInteractorDelegate: AnyObject {
    func didReceive(marketInfos: [String: MarketInfo])
}

protocol IRateListRouter {
    func showChart(coinCode: String, coinTitle: String)
}

class RateListModule {

    struct CoinViewItem {
        let coinCode: String
        let coinTitle: String
        let blockchainType: String?
        let rate: RateViewItem?
    }

}
