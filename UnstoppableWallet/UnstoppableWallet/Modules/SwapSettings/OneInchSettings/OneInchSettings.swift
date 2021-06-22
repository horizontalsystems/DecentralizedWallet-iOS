import Foundation
import UniswapKit
import EthereumKit

struct OneInchSettings {
    var allowedSlippage: Decimal
    var recipient: Address?

    init(allowedSlippage: Decimal = 0.5, recipient: Address? = nil) {
        self.allowedSlippage = allowedSlippage
        self.recipient = recipient
    }

}
