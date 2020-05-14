import Foundation
import DeepDiff
import CurrencyKit

protocol ITransactionsView: class {
    func set(status: TransactionViewStatus)
    func show(filters: [Wallet?])
    func show(transactions: [TransactionViewItem], animated: Bool)
    func showNoTransactions()
    func reloadTransactions()
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
    func onFilterSelect(wallet: Wallet?)

    func onBottomReached()

    func onTransactionClick(item: TransactionViewItem)
    func willShow(item: TransactionViewItem)
}

protocol ITransactionsInteractor {
    func initialFetch()
    func fetchLastBlockHeights()

    func fetchRecords(fetchDataList: [FetchData], initial: Bool)
    func set(selectedWallets: [Wallet])

    func fetchRate(coin: Coin, date: Date)
}

protocol ITransactionsInteractorDelegate: class {
    func onUpdate(selectedCoins: [Wallet])
    func onUpdate(walletsData: [(Wallet, Int, LastBlockInfo?)])
    func onUpdateBaseCurrency()
    func onConnectionRestore()

    func onUpdate(lastBlockInfo: LastBlockInfo, wallet: Wallet)

    func didUpdate(records: [TransactionRecord], wallet: Wallet)

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date)
    func didFetch(recordsData: [Wallet: [TransactionRecord]], initial: Bool)
    func onUpdate(states: [Coin: AdapterState])
    func didUpdate(state: AdapterState, wallet: Wallet)
}

protocol ITransactionsRouter {
    func openTransactionInfo(viewItem: TransactionViewItem)
}

protocol ITransactionViewItemFactory {
    func viewItem(fromRecord: TransactionRecord, wallet: Wallet, lastBlockInfo: LastBlockInfo?, threshold: Int?, rate: CurrencyValue?) -> TransactionViewItem
    func viewStatus(adapterStates: [Coin: AdapterState], transactionsCount: Int) -> TransactionViewStatus
}

protocol IDiffer {
    func changes<T: DiffAware>(old: [T], new: [T], section: Int) -> ChangeWithIndexPath
}

struct FetchData {
    let wallet: Wallet
    let from: TransactionRecord?
    let limit: Int
}
