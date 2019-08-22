import UIKit
import ActionSheet

class TransactionInfoViewController: ActionSheetController {
    private let delegate: ITransactionInfoViewDelegate

    init(delegate: ITransactionInfoViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        let item = delegate.viewItem

        let titleItem = TransactionTitleItem(item: item, tag: 0, onIdTap: { [weak self] in
            self?.delegate.onCopy(value: item.transactionHash)
        })
        model.addItemView(titleItem)

        let amountItem = TransactionAmountItem(item: item, tag: 1)
        model.addItemView(amountItem)

        if let value = item.rate, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) {
            let rateItem = TransactionValueItem(title: "tx_info.rate".localized, value: "balance.rate_per_coin".localized(formattedValue, item.coinValue.coin.code), tag: 2)
            model.addItemView(rateItem)
        }

        if let feeCoinValue = item.feeCoinValue, let formattedValue = ValueFormatter.instance.format(coinValue: feeCoinValue) {
            let feeItem = TransactionValueItem(title: "tx_info.fee".localized, value: formattedValue, tag: 3)
            model.addItemView(feeItem)
        }

        let timeItem = TransactionValueItem(title: "tx_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: item.date), tag: 4)
        model.addItemView(timeItem)

        let statusItem = TransactionStatusItem(item: item, tag: 5)
        model.addItemView(statusItem)

        if let from = item.from {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.from_hash".localized, value: from, tag: 6, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: from)
            }))
        }

        if let to = item.to {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.to_hash".localized, value: to, tag: 7, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: to)
            }))
        }

        if item.sentToSelf {
            let infoItem = TransactionNoteItem(note: "tx_info.note".localized, tag: 8)
            model.addItemView(infoItem)
        }

        let openFullInfoItem = TransactionOpenFullInfoItem(tag: 9, required: true, onTap: { [weak self] in
            self?.delegate.openFullInfo()
        })
        model.addItemView(openFullInfoItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .crypto_Dark_Bars
        model.hideInBackground = false
    }

}

extension TransactionInfoViewController: ITransactionInfoView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
