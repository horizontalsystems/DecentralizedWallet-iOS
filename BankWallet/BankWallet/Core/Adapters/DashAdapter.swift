import DashKit
import RxSwift

class DashAdapter: BitcoinBaseAdapter {
    private let feeRate = 1

    private let dashKit: DashKit

    init(wallet: Wallet, testMode: Bool) throws {
        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }


        let networkType: DashKit.NetworkType = testMode ? .testNet : .mainNet
        dashKit = try DashKit(withWords: words, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: wallet.syncMode ?? .fast), networkType: networkType, minLogLevel: .error)

        super.init(abstractKit: dashKit)

        dashKit.delegate = self
    }

}

extension DashAdapter: DashKitDelegate {

    public func transactionsUpdated(inserted: [DashTransactionInfo], updated: [DashTransactionInfo]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

}

extension DashAdapter: ISendDashAdapter {

    func availableBalance(address: String?) -> Decimal {
        return availableBalance(feeRate: feeRate, address: address)
    }

    func fee(amount: Decimal, address: String?) -> Decimal {
        return fee(amount: amount, feeRate: feeRate, address: address)
    }

    func sendSingle(amount: Decimal, address: String) -> Single<Void> {
        return sendSingle(amount: amount, address: address, feeRate: feeRate)
    }

}

extension DashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try DashKit.clear(exceptFor: excludedWalletIds)
    }

}
