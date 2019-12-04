import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionAmountItemView: BaseActionItemView {
    private let amountInfoView = AmountInfoView()

    override var item: TransactionAmountItem? { _item as? TransactionAmountItem }

    override func initView() {
        super.initView()

        backgroundColor = .appLawrence

        addSubview(amountInfoView)
        amountInfoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    override func updateView() {
        super.updateView()

        guard let item = item else {
            return
        }
        if let customPrimaryFractionPolicy = item.customPrimaryFractionPolicy {
            amountInfoView.customPrimaryFractionPolicy = customPrimaryFractionPolicy
            amountInfoView.primaryFormatTrimmable = false
        }

        amountInfoView.bind(primaryAmountInfo: item.primaryAmountInfo,
                secondaryAmountInfo: item.secondaryAmountInfo,
                incoming: item.incoming,
                sentToSelf: item.sentToSelf,
                locked: item.locked)
    }

}
