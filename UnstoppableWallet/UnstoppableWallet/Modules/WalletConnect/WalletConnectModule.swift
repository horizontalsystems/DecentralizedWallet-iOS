import UIKit

struct WalletConnectModule {

    static func start(sourceViewController: UIViewController?) {
        let service = WalletConnectService(
                ethereumKitManager: App.shared.ethereumKitManager,
                appConfigProvider: App.shared.appConfigProvider,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager,
                sessionStore: App.shared.walletConnectSessionStore
        )
        let viewModel = WalletConnectViewModel(service: service)
        let view = WalletConnectView(viewModel: viewModel, sourceViewController: sourceViewController)

        sourceViewController?.present(view.initialViewController, animated: true)
    }

}
