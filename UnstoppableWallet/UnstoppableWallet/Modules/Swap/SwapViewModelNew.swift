import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit

class SwapViewModelNew {
    private let disposeBag = DisposeBag()

    public let service: SwapServiceNew
    public let tradeService: SwapTradeService
    public let transactionService: EthereumTransactionService

    public let viewItemHelper: SwapViewItemHelper

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var swapErrorRelay = BehaviorRelay<String?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<TradeViewItem?>(value: nil)
    private var tradeOptionsViewItemRelay = BehaviorRelay<TradeOptionsViewItem?>(value: nil)
    private var proceedAllowedRelay = BehaviorRelay<Bool>(value: false)
    private var approveActionRelay = BehaviorRelay<ApproveActionState>(value: .hidden)

    private var openApproveRelay = PublishRelay<SwapAllowanceService.ApproveData>()

    init(service: SwapServiceNew, tradeService: SwapTradeService, transactionService: EthereumTransactionService, viewItemHelper: SwapViewItemHelper) {
        self.service = service
        self.tradeService = tradeService
        self.transactionService = transactionService
        self.viewItemHelper = viewItemHelper

        subscribeToService()

        sync(state: service.state)
        sync(errors: service.errors)
        sync(tradeState: tradeService.state)
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.sync(errors: $0) }
        subscribe(disposeBag, tradeService.stateObservable) { [weak self] in self?.sync(tradeState: $0) }
        subscribe(disposeBag, tradeService.tradeOptionsObservable) { [weak self] in self?.sync(tradeOptions: $0) }
    }

    private func sync(state: SwapServiceNew.State? = nil) {
        let state = state ?? service.state

        isLoadingRelay.accept(state == .loading)
        proceedAllowedRelay.accept(state == .ready)
    }

    private func sync(errors: [Error]? = nil) {
        let errors = errors ?? service.errors

        swapErrorRelay.accept(errors.first.map { $0.convertedError.smartDescription })

        let isInsufficientAllowance = errors.contains(where: { .insufficientAllowance == $0 as? SwapServiceNew.SwapError })
        approveActionRelay.accept(isInsufficientAllowance ? .visible : .hidden)
    }

    private func sync(tradeState: SwapTradeService.State? = nil) {
        let state = tradeState ?? tradeService.state

        switch state {
        case .ready(let trade):
            tradeViewItemRelay.accept(tradeViewItem(trade: trade))
        default:
            tradeViewItemRelay.accept(nil)
        }
    }

    private func sync(tradeOptions: TradeOptions) {
        tradeOptionsViewItemRelay.accept(tradeOptionsViewItem(tradeOptions: tradeOptions))
    }

    private func tradeViewItem(trade: SwapTradeService.Trade) -> TradeViewItem {
        TradeViewItem(
                executionPrice: viewItemHelper.priceValue(executionPrice: trade.minMaxAmount, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut)?.formattedString,
                priceImpact: viewItemHelper.impactPrice(trade.tradeData.priceImpact),
                priceImpactLevel: trade.impactLevel,
                minMaxTitle: viewItemHelper.minMaxTitle(type: trade.tradeData.type).localized,
                minMaxAmount: viewItemHelper.minMaxValue(amount: trade.minMaxAmount, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut, type: trade.tradeData.type)?.formattedString
        )
    }

    private func tradeOptionsViewItem(tradeOptions: TradeOptions) -> TradeOptionsViewItem {
        TradeOptionsViewItem(slippage: viewItemHelper.slippage(tradeOptions.allowedSlippage),
            deadline: viewItemHelper.deadline(tradeOptions.ttl),
            recipient: tradeOptions.recipient?.hex)
    }

}

extension SwapViewModelNew {

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var swapErrorDriver: Driver<String?> {
        swapErrorRelay.asDriver()
    }

    var tradeViewItemDriver: Driver<TradeViewItem?> {
        tradeViewItemRelay.asDriver()
    }

    var tradeOptionsViewItemDriver: Driver<TradeOptionsViewItem?> {
        tradeOptionsViewItemRelay.asDriver()
    }

    var proceedAllowedDriver: Driver<Bool> {
        proceedAllowedRelay.asDriver()
    }

    var approveActionDriver: Driver<ApproveActionState> {
        approveActionRelay.asDriver()
    }

    var openApproveSignal: Signal<SwapAllowanceService.ApproveData> {
        openApproveRelay.asSignal()
    }

    func onTapSwitch() {
        tradeService.switchCoins()
    }

    func onTapApprove() {
        guard let approveData = service.approveData else {
            return
        }

        openApproveRelay.accept(approveData)
    }

    func didApprove() {
//        service.didApprove()
    }

}

extension SwapViewModelNew {

    struct TradeViewItem {
        let executionPrice: String?
        let priceImpact: String?
        let priceImpactLevel: SwapTradeService.PriceImpactLevel
        let minMaxTitle: String?
        let minMaxAmount: String?
    }

    struct TradeOptionsViewItem {
        let slippage: String?
        let deadline: String?
        let recipient: String?
    }

    enum ApproveActionState {
        case hidden
        case visible
        case pending
    }

}
