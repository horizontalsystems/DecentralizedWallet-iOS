import Foundation
import RxSwift
import RxCocoa
import EthereumKit
import BigInt

class SendEvmTransactionService {
    private let disposeBag = DisposeBag()

    private let sendData: SendEvmData
    private let evmKit: EthereumKit.Kit
    private let transactionService: EvmTransactionService

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let sendStateRelay = PublishRelay<SendState>()
    private(set) var sendState: SendState = .idle {
        didSet {
            sendStateRelay.accept(sendState)
        }
    }

    init(sendData: SendEvmData, gasPrice: Int? = nil, evmKit: EthereumKit.Kit, transactionService: EvmTransactionService) {
        self.sendData = sendData
        self.evmKit = evmKit
        self.transactionService = transactionService

        subscribe(disposeBag, transactionService.transactionStatusObservable) { [weak self] _ in self?.syncState() }

        transactionService.set(transactionData: sendData.transactionData)

        if let gasPrice = gasPrice {
            transactionService.set(gasPriceType: .custom(gasPrice: gasPrice))
        }
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func syncState() {
        switch transactionService.transactionStatus {
        case .loading:
            state = .notReady(errors: [])
        case .failed(let error):
            state = .notReady(errors: [error])
        case .completed(let transaction):
            if transaction.totalAmount > evmBalance {
                state = .notReady(errors: [TransactionError.insufficientBalance(requiredBalance: transaction.totalAmount)])
            } else {
                state = .ready
            }
        }
    }

}

extension SendEvmTransactionService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var sendStateObservable: Observable<SendState> {
        sendStateRelay.asObservable()
    }

    var transactionData: TransactionData {
        sendData.transactionData
    }

    var additionalItems: [SendEvmData.AdditionalItem] {
        sendData.additionalItems
    }

    var ownAddress: EthereumKit.Address {
        evmKit.receiveAddress
    }

    var decoration: TransactionDecoration? {
        evmKit.decorate(transactionData: sendData.transactionData)
    }

    func send() {
        guard case .ready = state, case .completed(let transaction) = transactionService.transactionStatus else {
            return
        }

        sendState = .sending

        evmKit.sendSingle(
                        transactionData: sendData.transactionData,
                        gasPrice: transaction.gasData.gasPrice,
                        gasLimit: transaction.gasData.gasLimit
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] fullTransaction in
                    self?.sendState = .sent(transactionHash: fullTransaction.transaction.hash)
                }, onError: { error in
                    self.sendState = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

}

extension SendEvmTransactionService {

    enum State {
        case ready
        case notReady(errors: [Error])
    }

    enum SendState {
        case idle
        case sending
        case sent(transactionHash: Data)
        case failed(error: Error)
    }

    enum TransactionError: Error {
        case insufficientBalance(requiredBalance: BigUInt)
    }

}
