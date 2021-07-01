import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import CurrencyKit
import ComponentKit
import RxSwift
import SafariServices

class TransactionInfoViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: TransactionInfoViewModel
    private let pageTitle: String
    private var viewItems = [[TransactionInfoModule.ViewItem]]()

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: TransactionInfoViewModel, pageTitle: String) {
        self.viewModel = viewModel
        self.pageTitle = pageTitle
        viewItems = viewModel.viewItems

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = pageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: B7Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: A1Cell.self)

        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: D6Cell.self)
        tableView.registerCell(forClass: C6Cell.self)
        tableView.registerCell(forClass: TransactionInfoPendingStatusCell.self)
        tableView.registerCell(forClass: TransactionInfoTransactionIdCell.self)
        tableView.registerCell(forClass: TransactionInfoWarningCell.self)
        tableView.registerCell(forClass: TransactionInfoNoteCell.self)
        tableView.registerCell(forClass: TransactionInfoShareCell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems
            self?.tableView.reload()
        }

        tableView.reload()
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    private func openStatusInfo() {
        let viewController = TransactionStatusInfoViewController()
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func pendingStatusCell(rowInfo: RowInfo, progress: Double, label: String) -> RowProtocol {
        Row<TransactionInfoPendingStatusCell>(
                id: "status",
                hash: "pending-\(progress)-\(label)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.bind(progress: progress, label: label) { [weak self] in
                        self?.openStatusInfo()
                    }
                }
        )
    }

    private func statusRow(rowInfo: RowInfo, status: TransactionStatus, completed: String, pending: String) -> RowProtocol {
        switch status {
        case .completed:
            return Row<D6Cell>(
                    id: "status",
                    hash: "completed",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                        cell.title = "status".localized
                        cell.value = completed
                        cell.valueImage = UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate)
                        cell.valueImageTintColor = .themeRemus
                        cell.selectionStyle = .none
                    }
            )
        case .failed:
            return Row<C6Cell>(
                    id: "status",
                    hash: "failed",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                        cell.title = "status".localized
                        cell.titleImage = UIImage(named: "circle_information_20")?.withRenderingMode(.alwaysTemplate)
                        cell.titleImageTintColor = .themeJacob
                        cell.value = "tx_info.status.failed".localized
                        cell.valueImage = UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate)
                        cell.valueImageTintColor = .themeLucian
                        cell.titleImageAction = { [weak self] in
                            self?.openStatusInfo()
                        }
                    }
            )

        case .pending:
            return pendingStatusCell(rowInfo: rowInfo, progress: 0, label: pending)
        case .processing(let progress):
            return pendingStatusCell(rowInfo: rowInfo, progress: progress, label: pending)
        }
    }

    private func fromToRow(rowInfo: RowInfo, title: String, value: String) -> RowProtocol {
        Row<D9Cell>(
                id: title,
                hash: value,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.viewItem = .init(title: TransactionInfoAddressMapper.title(value: value), value: value)
                }
        )
    }

    private func fromRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, title: "tx_info.from_hash".localized, value: value)
    }

    private func toRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, title: "tx_info.to_hash".localized, value: value)
    }

    private func recipientRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, title: "tx_info.recipient_hash".localized, value: value)
    }

    private func idRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        Row<TransactionInfoTransactionIdCell>(
                id: "transaction_id",
                hash: value,
                height: .heightCell48,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.bind(
                            value: value,
                            onTapId: {
                                self?.viewModel.onTapTransactionId()
                                HudHelper.instance.showSuccess(title: "alert.copied".localized)
                            },
                            onTapShare: {
                                let activityViewController = UIActivityViewController(activityItems: [value], applicationActivities: [])
                                self?.present(activityViewController, animated: true)
                            }
                    )
                }
        )
    }

    private func valueRow(rowInfo: RowInfo, title: String, value: String?, valueItalic: Bool = false) -> RowProtocol {
        Row<D7Cell>(
                id: title,
                hash: value ?? "",
                dynamicHeight: { width in
                    D7Cell.height(containerWidth: width, backgroundStyle: .transparent, title: title, value: value, valueItalic: valueItalic)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueItalic = valueItalic
                }
        )
    }

    private func rateRow(rowInfo: RowInfo, currencyValue: CurrencyValue, coinCode: String) -> RowProtocol {
        let formattedValue = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)

        return valueRow(
                rowInfo: rowInfo,
                title: "tx_info.rate".localized,
                value: formattedValue.map { "balance.rate_per_coin".localized($0, coinCode) }
        )
    }

    private func feeRow(rowInfo: RowInfo, coinValue: CoinValue, currencyValue: CurrencyValue?) -> RowProtocol {
        var parts = [String]()

        if let formattedCoinValue = ValueFormatter.instance.format(coinValue: coinValue) {
            parts.append(formattedCoinValue)
        }

        if let currencyValue = currencyValue, let formattedCurrencyValue = ValueFormatter.instance.format(currencyValue: currencyValue) {
            parts.append(formattedCurrencyValue)
        }

        return valueRow(
                rowInfo: rowInfo,
                title: "tx_info.fee".localized,
                value: parts.joined(separator: " | ")
        )
    }

    private func warningRow(rowInfo: RowInfo, id: String, image: UIImage?, text: String, onTapButton: @escaping () -> ()) -> RowProtocol {
        Row<TransactionInfoWarningCell>(
                id: id,
                hash: text,
                dynamicHeight: { containerWidth in
                    TransactionInfoWarningCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.bind(image: image, text: text, onTapButton: onTapButton)
                }
        )
    }

    private func doubleSpendRow(rowInfo: RowInfo) -> RowProtocol {
        warningRow(
                rowInfo: rowInfo,
                id: "double_spend",
                image: UIImage(named: "double_send_20"),
                text: "tx_info.double_spent_note".localized
        ) { [weak self] in
//            self?.delegate.onTapDoubleSpendInfo()
        }
    }

    private func lockInfoRow(rowInfo: RowInfo, lockState: TransactionLockState) -> RowProtocol {
        let id = "lock_info"
        let image = UIImage(named: lockState.locked ? "lock_20" : "unlock_20")
        let formattedDate = DateHelper.instance.formatFullTime(from: lockState.date)

        if lockState.locked {
            return warningRow(rowInfo: rowInfo, id: id, image: image, text: "tx_info.locked_until".localized(formattedDate)) { [weak self] in
//                self?.delegate.onTapLockInfo()
            }
        } else {
            return noteRow(rowInfo: rowInfo, id: id, image: image, imageTintColor: .themeGray, text: "tx_info.unlocked_at".localized(formattedDate))
        }
    }

    private func noteRow(rowInfo: RowInfo, id: String, image: UIImage?, imageTintColor: UIColor?, text: String) -> RowProtocol {
        Row<TransactionInfoNoteCell>(
                id: id,
                hash: text,
                dynamicHeight: { containerWidth in
                    TransactionInfoNoteCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.bind(image: image, imageTintColor: imageTintColor, text: text)
                }
        )
    }

    private func sentToSelfRow(rowInfo: RowInfo) -> RowProtocol {
        noteRow(
                rowInfo: rowInfo,
                id: "sent_to_self",
                image: UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate),
                imageTintColor: .themeRemus,
                text: "tx_info.to_self_note".localized
        )
    }

    private func rawTransactionRow(rowInfo: RowInfo) -> RowProtocol {
        Row<TransactionInfoShareCell>(
                id: "raw_transaction",
                height: .heightCell48,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.bind(
                            title: "tx_info.raw_transaction".localized,
                            onTapShare: {
//                                self?.delegate.onTapShareRawTransaction()
                            }
                    )
                }
        )
    }

    private func explorerRow(rowInfo: RowInfo, title: String, url: String?) -> RowProtocol {
        Row<A1Cell>(
                id: "explorer_row",
                hash: "explorer_row",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.titleImage = UIImage(named: "globe_20")
                },
                action: { [weak self] _ in
                    guard let urlString = url, let url = URL(string: urlString) else {
                        return
                    }

                    let controller = SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
                    self?.present(controller, animated: true)
                }
        )
    }

    private func actionTitleRow(rowInfo: RowInfo, title: String, value: String?) -> RowProtocol {
        Row<B7Cell>(
                id: "action_\(rowInfo.index)",
                hash: "action_\(value)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.value = value
                }
        )
    }

    private func amountRow(rowInfo: RowInfo, coinValue: CoinValue, currencyValue: CurrencyValue?, incoming: Bool?) -> RowProtocol {
        Row<D7Cell>(
                id: "amount_\(rowInfo.index)",
                hash: "amount_\(coinValue.value.description)",
                height: .heightCell48,
                bind: { cell, _ in
                    let isMaxValue = coinValue.isMaxValue
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = isMaxValue ? "transactions.value.unlimited".localized : currencyValue?.formattedString
                    cell.value = isMaxValue ? "∞" : coinValue.formattedString
                    incoming.flatMap {
                        cell.valueColor = $0 ? .themeGreenD : .themeYellowD
                    }
                }
        )
    }

    private func dateRow(rowInfo: RowInfo, date: Date) -> RowProtocol {
        Row<D7Cell>(
                id: "date",
                hash: "date_\(date.description)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.date".localized
                    cell.value = DateHelper.instance.formatFullTime(from: date)
                }
        )
    }

    private func priceRow(rowInfo: RowInfo, coinValue1: CoinValue, coinValue2: CoinValue) -> RowProtocol {
        Row<D7Cell>(
                id: "price",
                hash: "\(coinValue1.value.description)_\(coinValue2.value.description)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.price".localized

                    let price = coinValue1.value.magnitude / coinValue2.value.magnitude
                    cell.value = "\(coinValue2.coin.code) = \(price) \(coinValue1.coin.code)"
                }
        )
    }
    private func row(viewItem: TransactionInfoModule.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
        case let .actionTitle(title, subTitle): return actionTitleRow(rowInfo: rowInfo, title: title, value: subTitle)
        case let .amount(coinValue, currencyValue, incoming): return amountRow(rowInfo: rowInfo, coinValue: coinValue, currencyValue: currencyValue, incoming: incoming)
        case let .status(status, completed, pending): return statusRow(rowInfo: rowInfo, status: status, completed: completed, pending: pending)
        case let .date(date): return dateRow(rowInfo: rowInfo, date: date)
        case let .from(value): return fromRow(rowInfo: rowInfo, value: value)
        case let .to(value): return toRow(rowInfo: rowInfo, value: value)
        case let .recipient(value): return recipientRow(rowInfo: rowInfo, value: value)
        case let .id(value): return idRow(rowInfo: rowInfo, value: value)
        case let .rate(currencyValue, coinCode): return rateRow(rowInfo: rowInfo, currencyValue: currencyValue, coinCode: coinCode)
        case let .fee(coinValue, currencyValue): return feeRow(rowInfo: rowInfo, coinValue: coinValue, currencyValue: currencyValue)
        case let .price(coinValue1, coinValue2): return priceRow(rowInfo: rowInfo, coinValue1: coinValue1, coinValue2: coinValue2)
        case .doubleSpend: return doubleSpendRow(rowInfo: rowInfo)
        case let .lockInfo(lockState): return lockInfoRow(rowInfo: rowInfo, lockState: lockState)
        case .sentToSelf: return sentToSelfRow(rowInfo: rowInfo)
        case .rawTransaction: return rawTransactionRow(rowInfo: rowInfo)
        case let .memo(text): return valueRow(rowInfo: rowInfo, title: "tx_info.memo".localized, value: text, valueItalic: true)
        case let .explorer(title, url): return explorerRow(rowInfo: rowInfo, title: title, url: url)
        }
    }

}

extension TransactionInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems.enumerated().map { (index: Int, sectionViewItems: [TransactionInfoModule.ViewItem]) -> SectionProtocol in
            Section(
                    id: "section_\(index)",
                    headerState: .margin(height: .margin12),
                    rows: sectionViewItems.enumerated().map { (index, viewItem) in
                        row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == sectionViewItems.count - 1))
                    }
            )
        }
    }

}

fileprivate struct RowInfo {
    let index: Int
    let isFirst: Bool
    let isLast: Bool
}
