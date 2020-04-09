class PrivacyViewItemFactory {

    func syncViewItems(items: [PrivacySyncItem]) -> [PrivacyViewItem] {
        items.map { item in
            PrivacyViewItem(iconName: item.coin.code, title: item.coin.title, value: item.setting.syncMode.title, changable: true)
        }
    }

}
