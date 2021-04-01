import RxSwift
import RxCocoa
import CoinKit

class RestoreSelectViewModel {
    private let service: RestoreSelectService
    private let disposeBag = DisposeBag()

    private let viewStateRelay = BehaviorRelay<CoinToggleViewModel.ViewState>(value: .empty)
    private let disableCoinRelay = PublishRelay<Coin>()
    private let enabledCoinsRelay = PublishRelay<[Coin]>()

    init(service: RestoreSelectService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.syncViewState(state: $0) }
        subscribe(disposeBag, service.cancelEnableCoinObservable) { [weak self] in self?.disableCoinRelay.accept($0) }

        syncViewState()
    }

    private func viewItem(item: RestoreSelectService.Item) -> CoinToggleViewModel.ViewItem {
        CoinToggleViewModel.ViewItem(
                coin: item.coin,
                state: .toggleVisible(enabled: item.enabled)
        )
    }

    private func syncViewState(state: RestoreSelectService.State? = nil) {
        let state = state ?? service.state

        let viewState = CoinToggleViewModel.ViewState(
                featuredViewItems: state.featuredItems.map { viewItem(item: $0) },
                viewItems: state.items.map { viewItem(item: $0) }
        )

        viewStateRelay.accept(viewState)
    }

}

extension RestoreSelectViewModel: ICoinToggleViewModel {

    var viewStateDriver: Driver<CoinToggleViewModel.ViewState> {
        viewStateRelay.asDriver()
    }

    func onEnable(coin: Coin) {
        service.enable(coin: coin)
    }

    func onDisable(coin: Coin) {
        service.disable(coin: coin)
    }

    func onUpdate(filter: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter)
        }
    }

}

extension RestoreSelectViewModel {

    var disableCoinSignal: Signal<Coin> {
        disableCoinRelay.asSignal()
    }

    var restoreEnabledDriver: Driver<Bool> {
        service.canRestoreObservable.asDriver(onErrorJustReturn: false)
    }

    var enabledCoinsSignal: Signal<[Coin]> {
        enabledCoinsRelay.asSignal()
    }

    func onRestore() {
        enabledCoinsRelay.accept(Array(service.enabledCoins))
    }

}