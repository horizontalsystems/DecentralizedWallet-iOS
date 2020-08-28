import RxSwift
import RxCocoa
import UniswapKit
import UIExtensions

class BaseSwapInputPresenter {
    static let maxValidDecimals = 8
    let disposeBag = DisposeBag()

    let service: SwapService
    private let decimalParser: ISendAmountDecimalParser
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private var descriptionRelay = BehaviorRelay<String?>(value: nil)
    private var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    private var amountRelay = BehaviorRelay<String?>(value: nil)
    private var tokenCodeRelay = BehaviorRelay<String?>(value: nil)

    private var validDecimals = BaseSwapInputPresenter.maxValidDecimals

    var type: TradeType {
        fatalError("Must be implemented by Concrete subclass.")
    }

    var _description: String {
        fatalError("Must be implemented by Concrete subclass.")
    }

    init(service: SwapService, decimalParser: ISendAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        descriptionRelay.accept(_description)

        subscribeToService()
    }

    func subscribeToService() {
        handle(estimated: service.estimated)
        subscribe(disposeBag, service.estimatedObservable) { [weak self] in self?.handle(estimated: $0) }
    }

    private func handle(estimated: TradeType) {
        isEstimatedRelay.accept(estimated != type)
    }

    func update(amount: Decimal?) {
        guard self.type != service.estimated else {
            return
        }

        decimalFormatter.maximumFractionDigits = validDecimals
        let amountString = amount.flatMap { decimalFormatter.string(from: $0 as NSNumber) }

        amountRelay.accept(amountString)
    }

    func handle(coin: Coin?) {
        let max = SwapToInputPresenter.maxValidDecimals
        validDecimals = min(max, (coin?.decimal ?? max))

        tokenCodeRelay.accept(coin?.code)
    }

}

extension BaseSwapInputPresenter {

    var isEstimated: Driver<Bool> {
        isEstimatedRelay.asDriver()
    }

    func isValid(amount: String?) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
            return false
        }

        return amount.decimalCount <= validDecimals
    }

    var description: Driver<String?> {
        descriptionRelay.asDriver()
    }

    var amount: Driver<String?> {
        amountRelay.asDriver()
    }

    var tokenCode: Driver<String?> {
        tokenCodeRelay.asDriver()
    }

    func onChange(amount: String?) {
        service.onChange(type: type, amount: decimalParser.parseAnyDecimal(from: amount))
    }

    var tokensForSelection: [SwapModule.CoinBalanceItem] {
        service.tokensForSelection(type: type)
    }

    func onSelect(coin: SwapModule.CoinBalanceItem) {
        service.onSelect(type: type, coin: coin.coin)
    }

}
