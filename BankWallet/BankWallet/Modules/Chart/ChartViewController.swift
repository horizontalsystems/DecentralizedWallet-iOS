import UIKit
import ActionSheet
import XRatesKit

class ChartViewController: WalletActionSheetController {
    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private let delegate: IChartViewDelegate

    private let titleItem: AlertTitleItem
    private let currentRateItem = ChartCurrentRateItem(tag: 1)
    private let chartRateTypeItem = ChartRateTypeItem(tag: 2)
    private var chartRateItem: ChartRateItem?
    private var marketCapItem = ChartMarketCapItem(tag: 4)

    init(delegate: IChartViewDelegate) {
        self.delegate = delegate

        let coin = delegate.coin
        titleItem = AlertTitleItem(
                title: "chart.title".localized(coin.title),
                icon: UIImage(coin: coin),
                iconTintColor: AppTheme.coinIconColor,
                tag: 0
        )

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        titleItem.onClose = { [weak self] in
            self?.dismiss(byFade: false)
        }

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        model.addItemView(titleItem)
        model.addItemView(currentRateItem)
        model.addItemView(chartRateTypeItem)

        let chartRateItem = ChartRateItem(tag: 3, chartConfiguration: ChartConfiguration(), indicatorDelegate: self)
        self.chartRateItem = chartRateItem

        model.addItemView(chartRateItem)
        model.addItemView(marketCapItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .crypto_Dark_Bars
        model.hideInBackground = false

        delegate.viewDidLoad()
    }

    private func showSubtitle(for timestamp: TimeInterval?) {
        guard let timestamp = timestamp else {
            titleItem.bindSubtitle?(nil)
            return
        }
        titleItem.bindSubtitle?(DateHelper.instance.formatFullTime(from: Date(timeIntervalSince1970: timestamp)))
    }

    private func show(currentRateValue: CurrencyValue?) {
        guard let currentRateValue = currentRateValue else {
            currentRateItem.bindRate?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: currentRateValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        currentRateItem.bindRate?(formattedValue)
    }

    private func show(diff: Decimal?) {
        currentRateItem.bindDiff?(diff)
    }

    private func show(marketCapValue: CurrencyValue?) {
        marketCapItem.setMarketCap?(CurrencyCompactFormatter.instance.format(currencyValue: marketCapValue))
    }

    private func show(volumeValue: CurrencyValue?) {
        marketCapItem.setVolume?(CurrencyCompactFormatter.instance.format(currencyValue: volumeValue))
    }

    private func show(supplyValue: CoinValue?) {
        marketCapItem.setCirculation?(roundedFormat(coinValue: supplyValue))
    }

    private func show(maxSupply: CoinValue?) {
        marketCapItem.setTotal?(roundedFormat(coinValue: maxSupply) ?? "n/a".localized)
    }

    private func roundedFormat(coinValue: CoinValue?) -> String? {
        guard let coinValue = coinValue, let formattedValue = coinFormatter.string(from: coinValue.value as NSNumber) else {
            return nil
        }

        return "\(formattedValue) \(coinValue.coin.code)"
    }

    private func title(for chartType: ChartType) -> String {
        switch chartType {
        case .day: return "chart.time_duration.day".localized
        case .week: return "chart.time_duration.week".localized
        case .month: return "chart.time_duration.month".localized
        case .halfYear: return "chart.time_duration.halyear".localized
        case .year: return "chart.time_duration.year".localized
        }
    }

}

extension ChartViewController: IChartView {

    func show(chartViewItem viewItem: ChartInfoViewItem) {
        show(diff: viewItem.diff)
        chartRateItem?.bind?(viewItem.gridIntervalType, viewItem.points, viewItem.startTimestamp, viewItem.endTimestamp, true)
    }

    func show(marketInfoViewItem viewItem: MarketInfoViewItem) {
        showSubtitle(for: viewItem.timestamp)
        show(currentRateValue: viewItem.rateValue)

        show(marketCapValue: viewItem.marketCapValue)
        show(volumeValue: viewItem.volumeValue)
        show(supplyValue: viewItem.supplyValue)
        show(maxSupply: viewItem.maxSupplyValue)
    }

    func addTypeButtons(types: [ChartType]) {
        for type in types {
            let typeTitle = title(for: type)
            chartRateTypeItem.bindButton?(typeTitle, type.rawValue) { [weak self] in
                self?.delegate.onSelect(type: type)
            }
        }
    }

    func setChartTypeEnabled(tag: Int) {
        chartRateTypeItem.setEnabled?(tag)
    }

    func set(chartType: ChartType) {
        chartRateTypeItem.setSelected?(chartType.rawValue)
    }

    func showSelectedPoint(chartType: ChartType, timestamp: TimeInterval, value: CurrencyValue) {
        let date = Date(timeIntervalSince1970: timestamp)
        let formattedDate = [ChartType.month, ChartType.halfYear, ChartType.year].contains(chartType) ? DateHelper.instance.formatFullDateOnly(from: date) : DateHelper.instance.formatFullTime(from: date)
        let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)

        chartRateTypeItem.showPoint?(formattedDate, formattedValue)
    }

    func reloadAllModels() {
        model.reload?()
    }

    func showSpinner() {
        chartRateItem?.showSpinner?()
    }

    func hideSpinner() {
        chartRateItem?.hideSpinner?()
    }

    func showError() {
        chartRateItem?.showError?("chart.error.not_available".localized)
    }

}

extension ChartViewController: IChartIndicatorDelegate {

    func didTap(chartPoint: ChartPointPosition) {
        delegate.chartTouchSelect(timestamp: chartPoint.timestamp, value: chartPoint.value)
    }

    func didFinishTap() {
        chartRateTypeItem.showPoint?(nil, nil)
    }

}
