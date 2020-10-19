import RxCocoa
import CurrencyKit
import EthereumKit
import BigInt

protocol IWalletConnectRequestViewModel {
    var amountData: AmountData { get }
    var viewItems: [WalletConnectRequestViewItem] { get }
    var approveSignal: Signal<Data> { get }
    func approve()
}

struct WalletConnectTransaction {
    let from: Address
    let to: Address?
    let nonce: Int?
    let gasPrice: Int?
    let gasLimit: Int?
    let value: BigUInt?
    let data: Data
}

enum WalletConnectRequestViewItem {
    case from(value: String)
    case to(value: String)
    case input(value: String)
}
