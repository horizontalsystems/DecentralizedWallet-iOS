import RxSwift
import RxRelay
import EthereumKit
import BinanceChainKit
import CoinKit

class EnableCoinsService {
    private let appConfigProvider: IAppConfigProvider
    private let erc20Provider: EnableCoinsErc20Provider
    private let bep20Provider: EnableCoinsBep20Provider
    private let bep2Provider: EnableCoinsBep2Provider
    private let coinManager: ICoinManager
    private let disposeBag = DisposeBag()

    private let enableCoinsRelay = PublishRelay<[Coin]>()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(appConfigProvider: IAppConfigProvider, erc20Provider: EnableCoinsErc20Provider, bep20Provider: EnableCoinsBep20Provider, bep2Provider: EnableCoinsBep2Provider, coinManager: ICoinManager) {
        self.appConfigProvider = appConfigProvider
        self.erc20Provider = erc20Provider
        self.bep20Provider = bep20Provider
        self.bep2Provider = bep2Provider
        self.coinManager = coinManager
    }

    private func resolveTokenType(coinType: CoinType, accountType: AccountType) -> TokenType? {
        switch (coinType, accountType) {
        case (.ethereum, .mnemonic(let words, _)):
            if words.count == 12 {
                return .erc20(words: words)
            }
        case (.binanceSmartChain, .mnemonic(let words, _)):
            if words.count == 24 {
                return .bep20(words: words)
            }
        case (.bep2(let symbol), .mnemonic(let words, _)):
            if symbol == "BNB", words.count == 24 {
                return .bep2(words: words)
            }
        default:
            ()
        }

        return nil
    }

    private func fetchErc20Tokens(words: [String]) {
        do {
            let address = try Kit.address(words: words, networkType: appConfigProvider.testMode ? .ropsten : .ethMainNet)

            state = .loading

            erc20Provider.contractAddressesSingle(address: address.hex)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] addresses in
                        self?.handleFetchErc20(addresses: addresses)
                    }, onError: { [weak self] error in
                        self?.state = .failure(error: error)
                    })
                    .disposed(by: disposeBag)
        } catch {
            state = .failure(error: error)
        }
    }

    private func handleFetchErc20(addresses: [String]) {
        let allCoins = coinManager.coins

        let coins = addresses.compactMap { address in
            allCoins.first { coin in
                coin.type == .erc20(address: address)
            }
        }

        state = .success(coins: coins)
        enableCoinsRelay.accept(coins)
    }

    private func fetchBep20Tokens(words: [String]) {
        do {
            let address = try Kit.address(words: words, networkType: .bscMainNet)

            state = .loading

            bep20Provider.contractAddressesSingle(address: address.hex)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] addresses in
                        self?.handleFetchBep20(addresses: addresses)
                    }, onError: { [weak self] error in
                        self?.state = .failure(error: error)
                    })
                    .disposed(by: disposeBag)
        } catch {
            state = .failure(error: error)
        }
    }

    private func handleFetchBep20(addresses: [String]) {
        let allCoins = coinManager.coins

        let coins = addresses.compactMap { address in
            allCoins.first { coin in
                coin.type == .bep20(address: address)
            }
        }

        state = .success(coins: coins)
        enableCoinsRelay.accept(coins)
    }

    private func fetchBep2Tokens(words: [String]) {
        do {
            let single = try bep2Provider.tokenSymbolsSingle(words: words)

            state = .loading

            single
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] tokenSymbols in
                        self?.handleFetchBep2(tokenSymbols: tokenSymbols)
                    }, onError: { [weak self] error in
                        self?.state = .failure(error: error)
                    })
                    .disposed(by: disposeBag)
        } catch {
            state = .failure(error: error)
        }
    }

    private func handleFetchBep2(tokenSymbols: [String]) {
        let allCoins = coinManager.coins

        let coins = tokenSymbols.compactMap { tokenSymbol -> Coin? in
            if tokenSymbol == "BNB" {
                return nil
            }

            return allCoins.first { coin in
                coin.type == .bep2(symbol: tokenSymbol)
            }
        }

        state = .success(coins: coins)
        enableCoinsRelay.accept(coins)
    }

}

extension EnableCoinsService {

    var enableCoinsObservable: Observable<[Coin]> {
        enableCoinsRelay.asObservable()
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func handle(coinType: CoinType, accountType: AccountType) {
        guard let tokenType = resolveTokenType(coinType: coinType, accountType: accountType) else {
            return
        }

        state = .waitingForApprove(tokenType: tokenType)
    }

    func approveEnable() {
        guard case .waitingForApprove(let tokenType) = state else {
            return
        }

        switch tokenType {
        case .erc20(let words):
            fetchErc20Tokens(words: words)
        case .bep20(let words):
            fetchBep20Tokens(words: words)
        case .bep2(let words):
            fetchBep2Tokens(words: words)
        }
    }

}

extension EnableCoinsService {

    enum State {
        case idle
        case waitingForApprove(tokenType: TokenType)
        case loading
        case success(coins: [Coin])
        case failure(error: Error)
    }

    enum TokenType {
        case erc20(words: [String])
        case bep20(words: [String])
        case bep2(words: [String])

        var title: String {
            switch self {
            case .erc20: return "ERC20"
            case .bep20: return "BEP20"
            case .bep2: return "BEP2"
            }
        }
    }

}
