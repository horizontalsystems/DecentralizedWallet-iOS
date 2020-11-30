import RxSwift
import RxRelay
import HsToolKit

protocol IAddTokenBlockchainService {
    func validate(reference: String) throws
    func existingCoin(reference: String, coins: [Coin]) -> Coin?
    func coinSingle(reference: String) -> Single<Coin>
}

class AddTokenService {
    private let blockchainService: IAddTokenBlockchainService
    private let coinManager: ICoinManager

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(blockchainService: IAddTokenBlockchainService, coinManager: ICoinManager) {
        self.blockchainService = blockchainService
        self.coinManager = coinManager
    }

}

extension AddTokenService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func set(reference: String?) {
        disposeBag = DisposeBag()

        guard let reference = reference, !reference.isEmpty else {
            state = .idle
            return
        }

        do {
            try blockchainService.validate(reference: reference)
        } catch {
            state = .failed(error: error)
            return
        }

        if let existingCoin = blockchainService.existingCoin(reference: reference, coins: coinManager.coins) {
            state = .alreadyExists(coin: existingCoin)
            return
        }

        state = .loading

        blockchainService.coinSingle(reference: reference)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] coin in
                    self?.state = .fetched(coin: coin)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

    func save() {
        guard case .fetched(let coin) = state else {
            return
        }

        coinManager.save(coin: coin)
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case alreadyExists(coin: Coin)
        case fetched(coin: Coin)
        case failed(error: Error)
    }

}
