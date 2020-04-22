import UIKit
import ThemeKit
import SnapKit

class BackupRequiredViewController: ThemeActionSheetController {
    private let router: BackupRequiredRouter

    private let titleView = AlertTitleViewNew()
    private let descriptionView = HighlightedDescriptionView()
    private let backupButton = UIButton.appYellow

    init(router: BackupRequiredRouter, subtitle: String, text: String) {
        self.router = router

        super.init()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "backup.backup_required".localized,
                subtitle: subtitle,
                image: UIImage(named: "Attention Icon")?.tinted(with: .themeLucian)
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        descriptionView.bind(text: text)

        view.addSubview(backupButton)
        backupButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        backupButton.setTitle("settings_manage_keys.backup".localized, for: .normal)
        backupButton.addTarget(self, action: #selector(_onTapBackup), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapBackup() {
        dismiss(animated: true) { [weak self] in
            self?.router.showBackup()
        }
    }

}
