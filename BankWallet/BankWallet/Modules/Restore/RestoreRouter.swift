import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?

    private let delegate: IRestoreDelegate

    init(delegate: IRestoreDelegate) {
        self.delegate = delegate
    }

}

extension RestoreRouter: IRestoreRouter {

    func showRestore(defaultAccountType: DefaultAccountType, delegate: IRestoreAccountTypeDelegate) {
        guard let module = RestoreRouter.module(defaultAccountType: defaultAccountType, mode: .pushed, delegate: delegate) else {
            return
        }

        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func notifyRestored(account: Account) {
        delegate.didRestore(account: account)
    }

}

extension RestoreRouter {

    static func module(delegate: IRestoreDelegate) -> UIViewController {
        let router = RestoreRouter(delegate: delegate)
        let presenter = RestorePresenter(router: router, accountCreator: App.shared.accountCreator, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let viewController = RestoreViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func module(defaultAccountType: DefaultAccountType, mode: PresentationMode, delegate: IRestoreAccountTypeDelegate) -> UIViewController? {
        switch defaultAccountType {
        case .mnemonic(let wordsCount):
            let showSyncMode = wordsCount == 12
            return RestoreWordsRouter.module(mode: mode, wordsCount: wordsCount, showSyncMode: showSyncMode, delegate: delegate)
        case .eos: return RestoreEosRouter.module(mode: mode, delegate: delegate)
        }
    }

    enum PresentationMode {
        case pushed
        case presented
    }

}
