import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class GuidesViewController: ThemeViewController {
    private let delegate: IGuidesViewDelegate

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let filterHeaderView = FilterHeaderView()

    private var viewItems = [GuideViewItem]()

    init(delegate: IGuidesViewDelegate) {
        self.delegate = delegate

        super.init()

        tabBarItem = UITabBarItem(title: "guides.tab_bar_item".localized, image: UIImage(named: "Guides Tab Bar"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "guides.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: GuideCell.self)
        tableView.dataSource = self
        tableView.delegate = self

        filterHeaderView.onSelect = { [weak self] index in
        }

        delegate.onLoad()

    }

}

extension GuidesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: GuideCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? GuideCell {
            let index = indexPath.row

            cell.bind(
                    viewItem: viewItems[index],
                    first: index == 0,
                    last: index == viewItems.count - 1
            )
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.onTapGuide(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row

        return GuideCell.height(
                containerWidth: tableView.width,
                viewItem: viewItems[index],
                first: index == 0,
                last: index == viewItems.count - 1
        )
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        filterHeaderView.headerHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        filterHeaderView
    }

}

extension GuidesViewController: IGuidesView {

    func set(viewItems: [GuideViewItem]) {
        self.viewItems = viewItems

        filterHeaderView.reload(filters: [
            FilterHeaderView.ViewItem.item(title: "Basics"),
            FilterHeaderView.ViewItem.item(title: "Coins"),
        ])
    }

}
