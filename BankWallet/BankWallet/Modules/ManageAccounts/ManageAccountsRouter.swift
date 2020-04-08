import UIKit
import ThemeKit

class ManageAccountsRouter {
    weak var viewController: UIViewController?
}

extension ManageAccountsRouter: IManageAccountsRouter {

    func showUnlink(account: Account, predefinedAccountType: PredefinedAccountType) {
        viewController?.present(UnlinkRouter.module(account: account, predefinedAccountType: predefinedAccountType), animated: true)
    }

    func showBackup(account: Account, predefinedAccountType: PredefinedAccountType) {
        let module = BackupRouter.module(account: account, predefinedAccountType: predefinedAccountType)
        viewController?.present(module, animated: true)
    }

    func showCreateWallet(predefinedAccountType: PredefinedAccountType) {
        let module = CreateWalletRouter.module(presentationMode: .inApp, predefinedAccountType: predefinedAccountType)
        viewController?.present(module, animated: true)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType) {
        let module = RestoreRouter.module(predefinedAccountType: predefinedAccountType)
        viewController?.present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    func showSettings() {
        let module = DerivationSettingsRouter.module()
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageAccountsRouter {

    static func module() -> UIViewController {
        let router = ManageAccountsRouter()
        let interactor = ManageAccountsInteractor(predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager, accountManager: App.shared.accountManager, derivationSettingsManager: App.shared.derivationSettingsManager)
        let presenter = ManageAccountsPresenter(interactor: interactor, router: router)
        let viewController = ManageAccountsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
