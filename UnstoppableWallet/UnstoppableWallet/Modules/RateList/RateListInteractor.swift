import RxSwift
import XRatesKit

class RateListInteractor {
    weak var delegate: IRateListInteractorDelegate?

    private let rateManager: IRateManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider

    private let disposeBag = DisposeBag()

    init(rateManager: IRateManager, walletManager: IWalletManager, appConfigProvider: IAppConfigProvider) {
        self.rateManager = rateManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
    }

}

extension RateListInteractor: IRateListInteractor {

    var wallets: [Wallet] {
        walletManager.wallets
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo? {
        rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
    }

    func subscribeToMarketInfos(currencyCode: String) {
        rateManager.marketInfosObservable(currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfos in
                    self?.delegate?.didReceive(marketInfos: marketInfos)
                })
                .disposed(by: disposeBag)
    }

}
