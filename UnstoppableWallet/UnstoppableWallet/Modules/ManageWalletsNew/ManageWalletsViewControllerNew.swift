import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class ManageWalletsViewControllerNew: CoinToggleViewControllerNew {
    private let viewModel: ManageWalletsViewModelNew
    private let restoreSettingsView: RestoreSettingsView
    private let coinSettingsView: CoinSettingsView

    init(viewModel: ManageWalletsViewModelNew, restoreSettingsView: RestoreSettingsView, coinSettingsView: CoinSettingsView) {
        self.viewModel = viewModel
        self.restoreSettingsView = restoreSettingsView
        self.coinSettingsView = coinSettingsView

        super.init(viewModel: viewModel)

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "manage_coins.title".localized
        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "manage_coins.add_token".localized, style: .plain, target: self, action: #selector(onTapAddTokenButton))

        restoreSettingsView.onOpenController = { [weak self] controller in
            self?.present(controller, animated: true)
        }
        coinSettingsView.onOpenController = { [weak self] controller in
            self?.present(controller, animated: true)
        }

        subscribe(disposeBag, viewModel.disableCoinSignal) { [weak self] coin in
            self?.setToggle(on: false, coin: coin)
        }
    }

    @objc func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc func onTapAddTokenButton() {
        let module = AddTokenSelectorRouter.module(sourceViewController: self)
        present(module, animated: true)
    }

}
