import RxSwift
import RxRelay
import RxCocoa
import XRatesKit
import CoinKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let returnOfInvestmentsViewItemsFactory = ReturnOfInvestmentsViewItemsFactory()
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)

    init(service: CoinPageService) {
        self.service = service

//        CoinPageService.stateObservable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//                .subscribe(onNext: { [weak self] state in
//                    self?.sync(state: state)
//                })
//                .disposed(by: disposeBag)

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinMarketInfo>) {
        loadingRelay.accept(state.isLoading)

        let viewItem = state.data.map { info in
            ViewItem(
                    fundCategories: info.meta.fundCategories,
                    links: links(linkMap: info.meta.links),
                    returnOfInvestmentsViewItems: returnOfInvestmentsViewItemsFactory.viewItems(info: info, diffCoinCodes: service.diffCoinCodes, currentCoinCode: service.coinCode, timePeriods: CoinPageService.timePeriods)
            )
        }

        viewItemRelay.accept(viewItem)
    }

    private func links(linkMap: [LinkType: String]) -> [Link] {
        let linkTypes: [LinkType] = [.guide, .website, .whitepaper, .reddit, .twitter, .telegram, .github]

        return linkTypes.compactMap { linkType in
            guard let url = linkMap[linkType], !url.isEmpty else {
                return nil
            }

            return Link(type: linkType, url: url)
        }
    }

}

extension CoinPageViewModel {

    var title: String {
        service.coinCode
    }

    var subtitle: String {
        service.coinTitle
    }

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var coinCode: String {
        service.coinCode
    }

}

extension CoinPageViewModel {

    struct ViewItem {
        let fundCategories: [CoinFundCategory]
        let links: [Link]

        let returnOfInvestmentsViewItems: [[ReturnOfInvestmentsViewItem]]
    }

    enum ReturnOfInvestmentsViewItem {
        case title(String)
        case subtitle(String)
        case content(String)
        case value(Decimal?)

        var font: UIFont? {
            switch self {
            case .title: return .subhead1
            case .subtitle: return .caption
            case .content: return .caption
            case .value: return nil
            }
        }

        var color: UIColor? {
            switch self {
            case .title: return .themeOz
            case .subtitle: return .themeBran
            case .content: return .themeGray
            case .value: return nil
            }
        }

        var backgroundColor: UIColor? {
            switch self {
            case .title, .subtitle: return .themeLawrence
            case .content, .value: return .themeBlake
            }
        }

    }

    struct Link {
        let type: LinkType
        let url: String

        var icon: UIImage? {
            switch type {
            case .guide: return UIImage(named: "academy_1_20")
            case .website: return UIImage(named: "globe_20")
            case .whitepaper: return UIImage(named: "academy_1_20")
            case .reddit: return UIImage(named: "reddit_20")
            case .twitter: return UIImage(named: "twitter_20")
            case .telegram: return UIImage(named: "telegram_20")
            case .github: return UIImage(named: "github_20")
            }
        }

        var title: String {
            switch type {
            case .guide: return "coin_page.guide".localized
            case .website: return "coin_page.website".localized
            case .whitepaper: return "coin_page.whitepaper".localized
            case .reddit: return "Reddit"
            case .twitter: return "Twitter"
            case .telegram: return "Telegram"
            case .github: return "Github"
            }
        }
    }

}
