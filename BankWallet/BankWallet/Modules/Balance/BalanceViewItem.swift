import Foundation

struct BalanceViewItem {
    let coin: Coin
    let coinValue: CoinValue
    let exchangeValue: CurrencyValue?
    let currencyValue: CurrencyValue?
    let state: AdapterState
    let rateExpired: Bool
    let percentDelta: Decimal
    let chartData: [ChartPoint]
}
