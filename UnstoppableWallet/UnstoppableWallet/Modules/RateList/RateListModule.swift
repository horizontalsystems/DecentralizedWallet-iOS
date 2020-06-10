import Foundation
import XRatesKit
import CurrencyKit

protocol IRateListView: AnyObject {
    func set(coinViewItems: [RateListModule.CoinViewItem])
    func set(postViewItems: [RateListModule.PostViewItem])
    func set(lastUpdated: Date)
    func setPostSpinner(visible: Bool)
    func refresh()
}

protocol IRateListViewDelegate {
    func onLoad()
    func onSelectCoin(index: Int)
    func onSelectPost(index: Int)
}

protocol IRateListInteractor {
    var wallets: [Wallet] { get }
    var featuredCoins: [Coin] { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfos(currencyCode: String)

    func posts(coinCode: CoinCode, timestamp: TimeInterval) -> [CryptoNewsPost]?
    func subscribeToPosts(coinCode: CoinCode)
}

protocol IRateListInteractorDelegate: AnyObject {
    func didReceive(marketInfos: [String: MarketInfo])
    func didReceive(posts: [CryptoNewsPost])
}

protocol IRateListRouter {
    func showChart(coinCode: String, coinTitle: String)
    func open(link: String)
}

class RateListModule {

    struct CoinViewItem {
        let coinCode: String
        let coinTitle: String
        let blockchainType: String?
        let rate: RateViewItem?
    }

    struct PostViewItem {
        let title: String
        let date: Date
    }

}
