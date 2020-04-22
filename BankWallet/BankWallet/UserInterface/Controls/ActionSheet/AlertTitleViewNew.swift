import UIKit
import SnapKit
import ThemeKit

class AlertTitleViewNew: UIView {
    private static let height: CGFloat = 64

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton()
    private let separatorView = UIView()

    var onTapClose: (() -> ())?

    init() {
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(AlertTitleViewNew.height)
        }

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentHuggingPriority(.required, for: .vertical)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        titleLabel.font = .headline2
        titleLabel.textColor = .themeOz

        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin1x)
        }

        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeGray

        addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.size.equalTo(24 + 2 * CGFloat.margin2x)
        }

        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        closeButton.setImage(UIImage(named: "Close Icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .themeGray
        closeButton.addTarget(self, action: #selector(_onTapClose), for: .touchUpInside)

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapClose() {
        onTapClose?()
    }

    func bind(title: String?, subtitle: String?, image: UIImage?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconImageView.image = image
    }

}
