import LitecoinKit
import BitcoinCore
import RxSwift

class LitecoinAdapter: BitcoinBaseAdapter {
    private let litecoinKit: LitecoinKit

    init(wallet: Wallet, testMode: Bool) throws {
        guard case let .mnemonic(words, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        guard let walletDerivation = wallet.coinSettings[.derivation] as? MnemonicDerivation else {
            throw AdapterError.wrongParameters
        }

        guard let walletSyncMode = wallet.coinSettings[.syncMode] as? SyncMode else {
            throw AdapterError.wrongParameters
        }

        let networkType: LitecoinKit.NetworkType = testMode ? .testNet : .mainNet
        let bip = BitcoinBaseAdapter.bip(from: walletDerivation)
        let syncMode = BitcoinBaseAdapter.kitMode(from: walletSyncMode)

        litecoinKit = try LitecoinKit(withWords: words, bip: bip, walletId: wallet.account.id, syncMode: syncMode, networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.defaultConfirmationsThreshold, minLogLevel: .error)

        super.init(abstractKit: litecoinKit)

        litecoinKit.delegate = self
    }

}

extension LitecoinAdapter: ISendBitcoinAdapter {
}

extension LitecoinAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try LitecoinKit.clear(exceptFor: excludedWalletIds)
    }

}
