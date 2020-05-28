import UIKit
import SnapKit

extension FilterHeaderView {
    enum ViewItem {
        case all
        case item(title: String)
    }
}

class FilterHeaderView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    private var filters = [ViewItem]()
    private let collectionView: UICollectionView

    var onSelect: ((Int) -> ())?

    public var headerHeight: CGFloat {
        filters.isEmpty ? 0 : 40
    }

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)

        backgroundColor = .themeNavigationBarBackground

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 6, left: layoutMargins.left * 2, bottom: 6, right: layoutMargins.right * 2)
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: FilterHeaderCell.self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FilterHeaderCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? FilterHeaderCell {
            cell.bind(title: title(index: indexPath.item), selected: collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        FilterHeaderCell.size(for: title(index: indexPath.item))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .margin2x
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first, selectedIndexPath == indexPath {
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath.item)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func reload(filters: [ViewItem]) {
        self.filters = filters
        collectionView.reloadData()

        if filters.count > 0 {
            collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        }
    }

    private func title(index: Int) -> String {
        switch filters[index] {
        case .all: return "transactions.filter_all".localized
        case .item(let title): return title
        }
    }

}
