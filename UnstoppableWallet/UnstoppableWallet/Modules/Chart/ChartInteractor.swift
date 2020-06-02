import UIKit
import RxSwift
import XRatesKit

class ChartInteractor {
    weak var delegate: IChartInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var chartsDisposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let chartTypeStorage: IChartTypeStorage
    private let currentDateProvider: ICurrentDateProvider

    init(rateManager: IRateManager, chartTypeStorage: IChartTypeStorage, currentDateProvider: ICurrentDateProvider) {
        self.rateManager = rateManager
        self.chartTypeStorage = chartTypeStorage
        self.currentDateProvider = currentDateProvider
    }

}

extension ChartInteractor: IChartInteractor {

    var defaultChartType: ChartType? {
        get {
            chartTypeStorage.chartType
        }
        set {
            chartTypeStorage.chartType = newValue
        }
    }

    func chartInfo(coinCode: CoinCode, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        rateManager.chartInfo(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
    }

    func subscribeToChartInfo(coinCode: CoinCode, currencyCode: String, chartType: ChartType) {
        chartsDisposeBag = DisposeBag()

        rateManager.chartInfoObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chartInfo in
                    self?.delegate?.didReceive(chartInfo: chartInfo, coinCode: coinCode)
                }, onError: { [weak self] error in
                    self?.delegate?.onChartInfoError()
                })
                .disposed(by: chartsDisposeBag)
    }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo? {
        rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
    }

    func subscribeToMarketInfo(coinCode: CoinCode, currencyCode: String) {
        rateManager.marketInfoObservable(coinCode: coinCode, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfo in
                    self?.delegate?.didReceive(marketInfo: marketInfo)
                })
                .disposed(by: disposeBag)
    }

}
