import UIKit
import ThemeKit

struct SwapConfirmationModule {

    static func viewController(tradeService: SwapTradeService, transactionService: EthereumTransactionService) -> UIViewController {
        let ethereumCoinService = CoinService(
                coin: App.shared.appConfigProvider.ethereumCoin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let viewModel = SwapConfirmationViewModel(tradeService: tradeService, transactionService: transactionService, ethereumCoinService: ethereumCoinService, viewItemHelper: SwapViewItemHelper())
        let viewController = SwapConfirmationView(viewModel: viewModel)

        return viewController
    }

}
