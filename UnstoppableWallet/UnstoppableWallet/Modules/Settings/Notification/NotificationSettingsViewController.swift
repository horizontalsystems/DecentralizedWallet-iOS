import UIKit
import SectionsTableView
import ThemeKit

class NotificationSettingsViewController: ThemeViewController {
    private let delegate: INotificationSettingsViewDelegate

    private var viewItems = [NotificationSettingSectionViewItem]()
    private var pushNotificationsOn = false

    private let tableView = SectionsTableView(style: .grouped)
    private let warningView = UIView()

    init(delegate: INotificationSettingsViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_notifications.title".localized

        tableView.registerCell(forClass: ToggleCell.self)
        tableView.registerCell(forClass: SingleLineValueDropdownCell.self)
        tableView.registerCell(forClass: TitleCell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        warningView.isHidden = true

        view.addSubview(warningView)
        warningView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
        }

        let warningLabel = UILabel()
        warningLabel.numberOfLines = 0
        warningLabel.font = .subhead2
        warningLabel.textColor = .themeGray
        warningLabel.text = "settings.notifications.disabled_text".localized

        warningView.addSubview(warningLabel)
        warningLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        let settingsButton = ThemeButton().apply(style: .secondaryDefault)
        settingsButton.setTitle("settings.notifications.settings_button".localized, for: .normal)
        settingsButton.addTarget(self, action: #selector(onTapSettingsButton), for: .touchUpInside)

        warningView.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(warningLabel.snp.bottom).offset(CGFloat.margin8x)
        }

        delegate.viewDidLoad()
        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc func onTapSettingsButton() {
        delegate.didTapSettingsButton()
    }

}

extension NotificationSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [toggleNotificationsSection()]

        sections.append(contentsOf: itemSections(viewItems: viewItems))

        if !viewItems.isEmpty {
            sections.append(resetAllSection())
        }

        return sections
    }

    private func toggleNotificationsSection() -> SectionProtocol {
        let description = "settings_notifications.description".localized
        var footerState: ViewState<BottomDescriptionHeaderFooterView> = .cellType(hash: "toggle_description", binder: { view in
            view.bind(text: description)
        }, dynamicHeight: { [unowned self] containerWidth in
            BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: description)
        })

        return Section(
                id: "toggle_section",
                headerState: .margin(height: .margin3x),
                footerState: footerState,
                rows: [
                    Row<ToggleCell>(
                            id: "toggle_cell",
                            hash: "\(pushNotificationsOn)",
                            height: CGFloat.heightSingleLineCell,
                            bind: { [weak self] cell, _ in
                                cell.bind(title: "settings_notifications.toggle_title".localized, isOn: self?.pushNotificationsOn ?? false, last: true, onToggle: { on in
                                    self?.delegate.didToggleNotifications(on: on)
                                })
                            }
                    )
                ]
        )
    }

    private func itemSections(viewItems: [NotificationSettingSectionViewItem]) -> [SectionProtocol] {
        viewItems.enumerated().map { index, viewItem in
            itemSection(sectionIndex: index, viewItem: viewItem)
        }
    }

    private func itemSection(sectionIndex: Int, viewItem: NotificationSettingSectionViewItem) -> SectionProtocol {
        var headerState: ViewState<SubtitleHeaderFooterView> = .cellType(hash: "item_section_header_\(sectionIndex)", binder: { view in
            view.bind(text: viewItem.title)
        }, dynamicHeight: { containerWidth in
            SubtitleHeaderFooterView.height
        })

        let itemsCount = viewItem.rowItems.count

        return Section(
                id: "item_section_\(sectionIndex)",
                headerState: headerState,
                footerState: .margin(height: 20),
                rows: viewItem.rowItems.enumerated().compactMap { [weak self] index, item in
                    self?.itemRow(index: index, viewItem: item, last: index == itemsCount - 1)
                }
        )
    }

    private func itemRow(index: Int, viewItem: NotificationSettingRowViewItem, last: Bool) -> RowProtocol {
        Row<SingleLineValueDropdownCell>(
                id: "item_row_\(index)",
                hash: "\(viewItem.value)",
                height: .heightSingleLineCell,
                autoDeselect: true,
                bind: { [weak self] cell, _ in
                    cell.bind(title: viewItem.title.localized, value: viewItem.value, last: true)
                },
                action: { _ in
                    viewItem.onTap()
                }
        )
    }

    private func resetAllSection() -> SectionProtocol {
        Section(
                id: "reset_all_section",
                headerState: .margin(height: .margin3x),
                footerState: .margin(height: .margin8x),
                rows: [
                    Row<TitleCell>(
                            id: "reset_all_cell",
                            height: CGFloat.heightSingleLineCell,
                            autoDeselect: true,
                            bind: { [weak self] cell, _ in
                                cell.bind(title: "settings_notifications.reset_all_title".localized, titleColor: .themeLucian, last: true)
                            },
                            action: { [weak self] _ in
                                self?.delegate.didTapDeactivateAll()
                            }
                    )
                ]
        )
    }

}

extension NotificationSettingsViewController: INotificationSettingsView {

    func set(pushNotificationsOn: Bool) {
        self.pushNotificationsOn = pushNotificationsOn

        tableView.reload()
    }

    func set(viewItems: [NotificationSettingSectionViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

    func showWarning() {
        warningView.isHidden = false
        tableView.isHidden = true
    }

    func hideWarning() {
        warningView.isHidden = true
        tableView.isHidden = false
    }

    func showError(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

}
