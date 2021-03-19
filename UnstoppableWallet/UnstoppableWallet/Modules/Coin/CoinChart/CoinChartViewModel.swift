import Foundation
import RxSwift
import RxRelay
import RxCocoa
import XRatesKit
import Chart

class CoinChartViewModel {
    private let service: CoinChartService
    private let factory: CoinChartFactory
    private let disposeBag = DisposeBag()

    //todo: refactor!
    private let pointSelectModeEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let pointSelectedItemRelay = BehaviorRelay<SelectedPointViewItem?>(value: nil)

    private let chartTypeIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let rateRelay = BehaviorRelay<String?>(value: nil)
    private let rateDiffRelay = BehaviorRelay<Decimal?>(value: nil)
    private let chartInfoRelay = BehaviorRelay<CoinChartViewModel.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    let chartTypes = ChartType.allCases.map { $0.title.uppercased() }

    init(service: CoinChartService, factory: CoinChartFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.chartTypeObservable) { [weak self] in self?.sync(chartType: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(chartType: service.chartType)
        sync(state: service.state)
    }

    private func sync(chartType: ChartType) {
        chartTypeIndexRelay.accept(ChartType.allCases.firstIndex(of: chartType) ?? 0)
    }

    private func sync(state: DataStatus<CoinChartService.Item>) {
        loadingRelay.accept(state.isLoading)
        errorRelay.accept(state.error?.smartDescription)
        if state.error != nil {
            rateRelay.accept(nil)
            rateDiffRelay.accept(nil)
            chartInfoRelay.accept(nil)

            return
        }

        rateRelay.accept(state.data?.rate?.description ?? "") //todo: Convert!
        rateDiffRelay.accept(state.data?.rateDiff24h)

        guard let item = state.data else {
            chartInfoRelay.accept(nil)
            return
        }

        chartInfoRelay.accept(factory.convert(item: item, chartType: service.chartType, currency: service.currency, selectedIndicator: service.selectedIndicator))
    }

}

extension CoinChartViewModel {

    var pointSelectModeEnabledDriver: Driver<Bool> {
        pointSelectModeEnabledRelay.asDriver()
    }

    var pointSelectedItemDriver: Driver<SelectedPointViewItem?> {
        pointSelectedItemRelay.asDriver()
    }

    var chartTypeIndexDriver: Driver<Int> {
        chartTypeIndexRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var rateDriver: Driver<String?> {
        rateRelay.asDriver()
    }

    var rateDiffDriver: Driver<Decimal?> {
        rateDiffRelay.asDriver()
    }

    var chartInfoDriver: Driver<CoinChartViewModel.ViewItem?> {
        chartInfoRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func onSelectType(at index: Int) {
        let chartTypes = ChartType.allCases
        guard chartTypes.count > index else {
            return
        }

        service.chartType = chartTypes[index]
    }

    func onTap(indicator: ChartIndicatorSet) {
        service.selectedIndicator = service.selectedIndicator.toggle(indicator: indicator)
    }

}

extension CoinChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
        pointSelectModeEnabledRelay.accept(true)
    }

    public func select(item: ChartItem) {
        pointSelectedItemRelay.accept(factory.selectedPointViewItem(chartItem: item, type: service.chartType, currency: service.currency, macdSelected: service.selectedIndicator.contains(.macd)))
    }

    public func touchUp() {
        pointSelectModeEnabledRelay.accept(false)
    }

}

extension CoinChartViewModel {

    struct ViewItem {
        let chartData: ChartData

        let chartTrend: MovementTrend
        let chartDiff: Decimal?

        let trends: [ChartIndicatorSet: MovementTrend]

        let minValue: String?
        let maxValue: String?

        let timeline: [ChartTimelineItem]

        let selectedIndicator: ChartIndicatorSet
    }

}