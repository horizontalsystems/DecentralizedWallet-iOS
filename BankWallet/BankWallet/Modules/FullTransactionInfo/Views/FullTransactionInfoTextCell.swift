import UIKit
import SnapKit
import ThemeKit

class FullTransactionInfoTextCell: TitleCell {
    private let label = UILabel()
    private let button = ThemeButton()

    private var onTap: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = .subhead2
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        iconImageView.tintColor = .themeGray

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(disclosureImageView.snp.leading)
        }

        label.textAlignment = .right
        label.font = .subhead1
        label.textColor = .themeLeah

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(disclosureImageView.snp.leading)
        }

        button.apply(style: .secondaryDefault)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

    func bind(item: FullTransactionItem, selectionStyle: SelectionStyle = .none, showDisclosure: Bool = false, last: Bool = false, onTap: (() -> ())? = nil) {
        super.bind(titleIcon: item.icon.flatMap { UIImage(named: $0) }, title: item.title, titleColor: .themeGray, showDisclosure: showDisclosure, last: last)
        self.selectionStyle = selectionStyle

        if let onTap = onTap {
            label.isHidden = true
            label.text = nil

            button.isHidden = false
            button.setTitle(item.value, for: .normal)

            button.snp.remakeConstraints { maker in
                maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin4x)
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(disclosureImageView.snp.leading).offset(showDisclosure ? -CGFloat.margin2x : 0)
            }
        } else {
            button.isHidden = true
            button.setTitle(nil, for: .normal)

            label.isHidden = false
            label.text = item.value

            label.snp.remakeConstraints { maker in
                maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin4x)
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(disclosureImageView.snp.leading).offset(showDisclosure ? -CGFloat.margin2x : 0)
            }
        }

        self.onTap = onTap
    }

}
