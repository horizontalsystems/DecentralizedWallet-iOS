import EthereumKit
import Erc20Kit
import RxSwift
import BigInt
import HsToolKit

class Evm20Adapter: BaseEvmAdapter {
    private static let approveConfirmationsThreshold: Int? = nil
    let evm20Kit: Erc20Kit.Kit
    private let contractAddress: EthereumKit.Address

    init(evmKit: EthereumKit.Kit, contractAddress: String, decimal: Int, coinManager: ICoinManager) throws {
        let address = try EthereumKit.Address(hex: contractAddress)
        evm20Kit = try Erc20Kit.Kit.instance(ethereumKit: evmKit, contractAddress: address)
        self.contractAddress = address

        super.init(evmKit: evmKit, decimal: decimal, coinManager: coinManager)
    }

}

// IAdapter

extension Evm20Adapter: IAdapter {

    func start() {
        evm20Kit.start()
    }

    func stop() {
        evm20Kit.stop()
    }

    func refresh() {
        evmKit.refresh()
        evm20Kit.refresh()
    }

}

extension Evm20Adapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(evmSyncState: evm20Kit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        evm20Kit.syncStateObservable.map { [unowned self] in self.convertToAdapterState(evmSyncState: $0) }
    }

    var balanceData: BalanceData {
        balanceData(balance: evm20Kit.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        evm20Kit.balanceObservable.map { [unowned self] in self.balanceData(balance: $0) }
    }

}

extension Evm20Adapter: ISendEthereumAdapter {

    func transactionData(amount: BigUInt, address: EthereumKit.Address) -> TransactionData {
        evm20Kit.transferTransactionData(to: address, value: amount)
    }

}

extension Evm20Adapter: IErc20Adapter {

    var pendingTransactions: [TransactionRecord] {
        evm20Kit.pendingTransactions().map { transactionConverter.transactionRecord(fromTransaction: $0) }
    }

    func allowanceSingle(spenderAddress: EthereumKit.Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Decimal> {
        evm20Kit.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                .map { [unowned self] allowanceString in
                    if let significand = Decimal(string: allowanceString) {
                        return Decimal(sign: .plus, exponent: -decimal, significand: significand)
                    }

                    return 0
                }
    }

}

extension Evm20Adapter: ITransactionsAdapter {

    var transactionState: AdapterState {
        convertToAdapterState(evmSyncState: evm20Kit.transactionsSyncState)
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        evm20Kit.transactionsSyncStateObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        evm20Kit.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        do {
            let fromHash = from.flatMap { Data(hex: $0.transactionHash) }
            return try evm20Kit.transactionsSingle(from: fromHash, limit: limit)
                    .map { [weak self] transactions -> [TransactionRecord] in
                        transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
                    }
        } catch {
            return Single.error(error)
        }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
