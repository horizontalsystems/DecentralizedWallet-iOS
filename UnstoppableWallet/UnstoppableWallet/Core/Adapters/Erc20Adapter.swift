import EthereumKit
import Erc20Kit
import RxSwift
import BigInt
import class Erc20Kit.Transaction

class Erc20Adapter: EthereumBaseAdapter {
    private let erc20Kit: Erc20Kit.Kit
    private let contractAddress: Address
    private let fee: Decimal
    private(set) var minimumRequiredBalance: Decimal
    private(set) var minimumSpendableAmount: Decimal?

    init(ethereumKit: EthereumKit.Kit, contractAddress: String, decimal: Int, fee: Decimal, minimumRequiredBalance: Decimal, minimumSpendableAmount: Decimal?) throws {
        let address = try Address(hex: contractAddress)
        self.erc20Kit = try Erc20Kit.Kit.instance(ethereumKit: ethereumKit, contractAddress: address)
        self.contractAddress = address
        self.fee = fee
        self.minimumRequiredBalance = minimumRequiredBalance
        self.minimumSpendableAmount = minimumSpendableAmount

        super.init(ethereumKit: ethereumKit, decimal: decimal)
    }

    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
        let mineAddress = ethereumKit.receiveAddress

        var type: TransactionType = .sentToSelf
        var amount: Decimal = 0

        if let significand = Decimal(string: transaction.value.description) {
            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)

            let fromMine = transaction.from == mineAddress
            let toMine = transaction.to == mineAddress

            if fromMine && !toMine {
                type = .outgoing
            } else if !fromMine && toMine {
                type = .incoming
            }
        }

        return TransactionRecord(
                uid: transaction.transactionHash.hex + String(transaction.interTransactionIndex),
                transactionHash: transaction.transactionHash.hex,
                transactionIndex: transaction.transactionIndex ?? 0,
                interTransactionIndex: transaction.interTransactionIndex,
                type: type,
                blockHeight: transaction.blockNumber,
                amount: abs(amount),
                fee: nil,
                date: Date(timeIntervalSince1970: transaction.timestamp),
                failed: transaction.isError,
                from: transaction.from.hex,
                to: transaction.to.hex,
                lockInfo: nil,
                conflictingHash: nil,
                showRawTransaction: false
        )
    }

    override func sendSingle(to address: String, value: Decimal, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)) else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        do {
            return try erc20Kit.sendSingle(to: Address(hex: address), value: amount, gasPrice: gasPrice, gasLimit: gasLimit)
                    .map { _ in ()}
                    .catchError { [weak self] error in
                        Single.error(self?.createSendError(from: error) ?? error)
                    }
        } catch {
            return Single.error(error)
        }
    }

}

extension Erc20Adapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Erc20Kit.Kit.clear(exceptFor: excludedWalletIds)
    }

}

// IAdapter
extension Erc20Adapter: IAdapter {

    func start() {
        erc20Kit.refresh()
    }

    func stop() {
    }

    func refresh() {
        erc20Kit.refresh()
    }

    var debugInfo: String {
        ethereumKit.debugInfo
    }

}

extension Erc20Adapter: IBalanceAdapter {

    var state: AdapterState {
        switch erc20Kit.syncState {
        case .synced: return .synced
        case .notSynced(let error): return .notSynced(error: error.convertedError)
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        erc20Kit.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        guard let balanceString = erc20Kit.balance else {
            return 0
        }

        return balanceDecimal(balanceString: balanceString.description, decimal: decimal)
    }

    var balanceUpdatedObservable: Observable<Void> {
        erc20Kit.balanceObservable.map { _ in () }
    }

}

extension Erc20Adapter: ISendEthereumAdapter {

    func availableBalance(gasPrice: Int, gasLimit: Int) -> Decimal {
        max(0, balance - fee)
    }

    var ethereumBalance: Decimal {
        balanceDecimal(balanceString: ethereumKit.balance?.description, decimal: EthereumAdapter.decimal)
    }

    func fee(gasPrice: Int, gasLimit: Int) -> Decimal {
        let value = Decimal(gasPrice) * Decimal(gasLimit)
        return value / pow(10, EthereumAdapter.decimal)
    }

    func estimateGasLimit(to address: String?, value: Decimal, gasPrice: Int?) -> Single<Int> {
        guard let amount = BigUInt(value.roundedString(decimal: decimal)) else {
            return Single.error(SendTransactionError.wrongAmount)
        }


        var tokenAddress: Address?
        if let address = address {
            tokenAddress = try? Address(hex: address)
        }


        return erc20Kit.estimateGas(to: tokenAddress, contractAddress: contractAddress, value: amount, gasPrice: gasPrice)
    }

}

extension Erc20Adapter: ITransactionsAdapter {

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        erc20Kit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        do {
            let fromData = from.flatMap { record in
                Data(hex: record.transactionHash).map {
                    (hash: $0, interTransactionIndex: record.interTransactionIndex)
                }
            }
            return try erc20Kit.transactionsSingle(from: fromData, limit: limit)
                    .map { [weak self] transactions -> [TransactionRecord] in
                        transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                    }
        } catch {
            return Single.error(error)
        }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
