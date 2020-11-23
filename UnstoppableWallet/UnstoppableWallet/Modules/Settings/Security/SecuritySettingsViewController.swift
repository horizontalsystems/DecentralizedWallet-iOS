import UIKit
import UIExtensions
import SectionsTableView
import RxSwift
import ThemeKit
import PinKit

class SecuritySettingsViewController: ThemeViewController {
    private let delegate: ISecuritySettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var backupAlertVisible = false
    private var pinSet = false
    private var editPinVisible = false
    private var biometryVisible = false
    private var biometryType: BiometryType?
    private var biometryEnabled = false

    init(delegate: ISecuritySettingsViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_security.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tableView.registerCell(forClass: TitleCell.self)
        tableView.registerCell(forClass: RightImageCell.self)
        tableView.registerCell(forClass: ToggleCell.self)

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()

        tableView.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private var privacyRows: [RowProtocol] {
        [
            Row<TitleCell>(id: "privacy", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "privacy_20"), title: "settings_security.privacy".localized, showDisclosure: true, last: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapPrivacy()
            })
        ]
    }

    private var pinRows: [RowProtocol] {
        let attentionIcon = pinSet ? nil : UIImage(named: "attention_20")

        var rows: [RowProtocol] = [
            Row<ToggleCell>(id: "pin", height: .heightSingleLineCell, bind: { [unowned self] cell, _ in
                cell.bind(
                        titleIcon: UIImage(named: "passcode_20"),
                        title: "settings_security.passcode".localized,
                        rightImage: attentionIcon?.tinted(with: .themeLucian),
                        isOn: pinSet, last: !editPinVisible,
                        onToggle: { [weak self] isOn in
                            self?.delegate.didSwitch(pinSet: isOn)
                        })
            })
        ]

        if editPinVisible {
            rows.append(Row<TitleCell>(id: "edit_pin", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: nil, title: "settings_security.change_pin".localized, showDisclosure: true, last: true)
            }, action: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.delegate.didTapEditPin()
                }
            }))
        }

        return rows
    }

    private var biometryRow: RowProtocol? {
        biometryType.flatMap {
            switch $0 {
            case .touchId: return createBiometryRow(title: "settings_security.touch_id".localized, icon: "touch_id_20")
            case .faceId: return createBiometryRow(title: "settings_security.face_id".localized, icon: "face_id_20")
            default: return nil
            }
        }
    }

    private func createBiometryRow(title: String, icon: String) -> RowProtocol {
        Row<ToggleCell>(id: "biometry", height: .heightSingleLineCell, bind: { [unowned self] cell, _ in
            cell.bind(titleIcon: UIImage(named: icon), title: title, isOn: self.biometryEnabled, last: true, onToggle: { [weak self] isOn in
                self?.delegate.didSwitch(biometryEnabled: isOn)
            })
        })
    }

}

extension SecuritySettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "privacy", headerState: .margin(height: .margin3x), rows: privacyRows),
            Section(id: "pin", headerState: .margin(height: .margin8x), rows: pinRows)
        ]

        if biometryVisible, let biometryRow = biometryRow {
            sections.append(Section(id: "biometry", headerState: .margin(height: .margin8x), rows: [biometryRow]))
        }

        return sections
    }

}

extension SecuritySettingsViewController: ISecuritySettingsView {

    func refresh() {
        tableView.reload()
    }

    func set(backupAlertVisible: Bool) {
        self.backupAlertVisible = backupAlertVisible
    }

    func toggle(pinSet: Bool) {
        self.pinSet = pinSet
    }

    func set(editPinVisible: Bool) {
        self.editPinVisible = editPinVisible
    }

    func set(biometryVisible: Bool) {
        self.biometryVisible = biometryVisible
    }

    func set(biometryType: BiometryType?) {
        self.biometryType = biometryType
    }

    func toggle(biometryEnabled: Bool) {
        self.biometryEnabled = biometryEnabled
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

}
