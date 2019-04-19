import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T

class SendInteractorTests: XCTestCase {
    enum StubError: Error { case some }

    private var mockDelegate: MockISendInteractorDelegate!
    private var mockCurrencyManager: MockICurrencyManager!
    private var mockRateStorage: MockIRateStorage!
    private var mockLocalStorage: MockILocalStorage!
    private var mockPasteboardManager: MockIPasteboardManager!
    private var mockAppConfigProvider: MockIAppConfigProvider!
    private var mockBackgroundManager: BackgroundManager!

    private let coinCode = "BTC"
    private let baseCurrency = Currency(code: "USD", symbol: "$")
    private let balance: Decimal = 123.45

    private let fiatDecimal = 2
    private let maxDecimal = 8

    private var mockAdapter: MockIAdapter!
    private var interactorState: SendInteractorState!
    private var input: SendUserInput!

    private var interactor: SendInteractor!

    override func setUp() {
        super.setUp()

        mockAdapter = MockIAdapter()
        interactorState = SendInteractorState(adapter: mockAdapter)

        mockDelegate = MockISendInteractorDelegate()
        mockCurrencyManager = MockICurrencyManager()
        mockRateStorage = MockIRateStorage()
        mockLocalStorage = MockILocalStorage()
        mockPasteboardManager = MockIPasteboardManager()
        mockAppConfigProvider = MockIAppConfigProvider()
        mockBackgroundManager = BackgroundManager()

        stub(mockDelegate) { mock in
            when(mock.didUpdateRate()).thenDoNothing()
            when(mock.didSend()).thenDoNothing()
            when(mock.didFailToSend(error: any())).thenDoNothing()
            when(mock.onBecomeActive()).thenDoNothing()
        }
        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrency.get).thenReturn(baseCurrency)
        }
        stub(mockAdapter) { mock in
            when(mock.feeCoinCode.get).thenReturn(nil)
            when(mock.coin.get).thenReturn(Coin(title: "some", code: coinCode, type: .bitcoin))
            when(mock.decimal.get).thenReturn(0)
            when(mock.balance.get).thenReturn(balance)
            when(mock.validate(address: any())).thenDoNothing()
            when(mock.fee(for: any(), address: any(), feeRatePriority: any())).thenReturn(0)
            when(mock.validate(amount: any(), address: any(), feeRatePriority: any())).thenReturn([])
            when(mock.availableBalance(for: any(), feeRatePriority: any())).thenReturn(0)
        }
        stub(mockPasteboardManager) { mock in
            when(mock.set(value: any())).thenDoNothing()
        }
        stub(mockAppConfigProvider) { mock in
            when(mock.fiatDecimal.get).thenReturn(fiatDecimal)
            when(mock.maxDecimal.get).thenReturn(maxDecimal)
        }
        input = SendUserInput()
        input.feeRatePriority = .medium

        interactor = SendInteractor(currencyManager: mockCurrencyManager, rateStorage: mockRateStorage, localStorage: mockLocalStorage, pasteboardManager: mockPasteboardManager, state: interactorState, appConfigProvider: mockAppConfigProvider, backgroundManager: mockBackgroundManager, async: false)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockCurrencyManager = nil
        mockRateStorage = nil
        mockLocalStorage = nil
        mockPasteboardManager = nil
        mockAppConfigProvider = nil
        mockBackgroundManager = nil

        mockAdapter = nil
        interactorState = nil

        input = nil

        interactor = nil

        super.tearDown()
    }

    func testValueFromPasteboard() {
        let address = "address"

        stub(mockPasteboardManager) { mock in
            when(mock.value.get).thenReturn(address)
        }

        XCTAssertEqual(interactor.valueFromPasteboard, address)
    }

    func testConvertedAmount_FromCoinToCurrency() {
        let rateValue: Decimal = 987.65
        let amount: Decimal = 123.45

        interactorState.exchangeRate = rateValue

        XCTAssertEqual(interactor.convertedAmount(forInputType: .coin, amount: amount), amount * rateValue)
    }

    func testConvertedAmount_FromCurrencyToCoin() {
        let rateValue: Decimal = 987.65
        let amount: Decimal = 123.45

        interactorState.exchangeRate = rateValue

        XCTAssertEqual(interactor.convertedAmount(forInputType: .currency, amount: amount), amount / rateValue)
    }

    func testConvertedAmount_NoRate() {
        XCTAssertEqual(interactor.convertedAmount(forInputType: .coin, amount: 123.45), nil)
    }

    func testState_numberOfDecimals_coin() {
        let decimal = 8
        stub(mockAdapter) { mock in
            when(mock.decimal.get).thenReturn(decimal)
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.decimal, decimal)
    }

    func testState_numberOfDecimals_fiat() {
        interactorState.exchangeRate = 2
        input.inputType = .currency

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.decimal, fiatDecimal)
    }

    func testState_numberOfDecimals_maxDecimal() {
        let expectedDecimal = 8

        stub(mockAdapter) { mock in
            when(mock.decimal.get).thenReturn(18)
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.decimal, expectedDecimal)
    }

    func testState_InputType_Coin() {
        input.inputType = .coin

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.inputType, SendInputType.coin)
    }

    func testState_InputType_Currency() {
        interactorState.exchangeRate = 2
        input.inputType = .currency

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.inputType, SendInputType.currency)
    }

    func testState_forceCoinInputType_noRate() {
        interactorState.exchangeRate = nil
        input.inputType = .currency
        input.amount = 6

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.inputType, SendInputType.coin)
    }

    func testState_dropValues_noRate() {
        interactorState.exchangeRate = nil
        input.inputType = .currency
        input.amount = 6

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.currencyValue)
        XCTAssertEqual(state.coinValue?.value, 0)
        XCTAssertNil(state.feeCurrencyValue)
        XCTAssertEqual(state.feeCoinValue?.value, 0)
    }

    func testState_CoinValue_CoinType() {
        let amount: Decimal = 123.45

        input.inputType = .coin
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.coinValue, CoinValue(coinCode: coinCode, value: amount))
    }

    func testState_CoinValue_CurrencyType() {
        let rateValue: Decimal = 987.65
        let amount: Decimal = 123.45

        interactorState.exchangeRate = rateValue
        input.inputType = .currency
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.coinValue, CoinValue(coinCode: coinCode, value: amount / rateValue))
    }

    func testState_CurrencyValue_CoinType() {
        let rateValue: Decimal = 987.65
        let amount: Decimal = 123.45

        interactorState.exchangeRate = rateValue
        input.inputType = .coin
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.currencyValue, CurrencyValue(currency: baseCurrency, value: amount * rateValue))
    }

    func testState_CurrencyValue_CurrencyType() {
        let amount: Decimal = 6

        interactorState.exchangeRate = 2
        input.inputType = .currency
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.currencyValue, CurrencyValue(currency: baseCurrency, value: amount))
    }

    func testState_CurrencyValue_CoinType_NoRate() {
        interactorState.exchangeRate = nil
        input.inputType = .coin

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.currencyValue)
    }

    func testState_AmountError_CoinType_EnoughBalance() {
        input.inputType = .coin
        input.amount = balance - 1

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.amountError)
    }

    func testState_AmountError_CoinType_InsufficientBalance() {
        let amount: Decimal = 140
        let address = "address"
        input.amount = amount
        input.address = address

        let expectedAvailableBalance: Decimal = 123
        let expectedAmountError = AmountInfo.coinValue(coinValue: CoinValue(coinCode: coinCode, value: expectedAvailableBalance))

        stub(mockAdapter) { mock in
            when(mock.validate(amount: equal(to: amount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn([SendStateError.insufficientAmount])
            when(mock.availableBalance(for: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(expectedAvailableBalance)
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(expectedAmountError, state.amountError)
    }

    func testState_AmountError_CurrencyType_EnoughBalance() {
        let rateValue: Decimal = 987.65
        let currencyBalance = balance * rateValue

        interactorState.exchangeRate = rateValue
        input.inputType = .currency
        input.amount = currencyBalance - 1

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.amountError)
    }

    func testState_AmountError_CurrencyType_InsufficientBalance() {
        let fiatAmount: Decimal = 40
        let address = "address"
        input.amount = fiatAmount
        input.address = address
        input.inputType = .currency

        let rateValue: Decimal = 2
        interactorState.exchangeRate = rateValue
        let coinAmount = fiatAmount / rateValue

        let coinAvailableBalance: Decimal = 3
        let expectedAvailableBalance: Decimal = coinAvailableBalance * rateValue
        let expectedAmountError = AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: baseCurrency, value: expectedAvailableBalance))

        stub(mockAdapter) { mock in
            when(mock.validate(amount: equal(to: coinAmount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn([SendStateError.insufficientAmount])
            when(mock.availableBalance(for: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(coinAvailableBalance)
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(expectedAmountError, state.amountError)
    }

    func testState_FeeError_CoinType_InsufficientFeeBalance() {
        let amount: Decimal = 123.45
        let address = "address"

        input.amount = amount
        input.address = address

        let feeCoinCode = "ETH"
        let erc20CoinCode = "TNT"
        let erc20Coin = Coin(title: "trinitrotoluene", code: erc20CoinCode, type: .erc20(address: "some_address", decimal: 3))
        let fee = Decimal(string: "0.00004")!
        let expectedFeeError = FeeError.erc20error(erc20CoinCode: erc20CoinCode, fee: CoinValue(coinCode: feeCoinCode, value: fee))

        stub(mockAdapter) { mock in
            when(mock.fee(for: equal(to: amount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(fee)
            when(mock.coin.get).thenReturn(erc20Coin)
            when(mock.feeCoinCode.get).thenReturn(feeCoinCode)
            when(mock.validate(amount: equal(to: amount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn([SendStateError.insufficientFeeBalance])
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(expectedFeeError, state.feeError)
    }

    func testState_Address() {
        let address = "address"
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.address, address)
    }

    func testState_AddressError_Valid() {
        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.addressError)
    }

    func testState_AddressError_Invalid() {
        let address = "address"
        input.address = address

        stub(mockAdapter) { mock in
            when(mock.validate(address: equal(to: address))).thenThrow(StubError.some)
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.addressError, AddressError.invalidAddress)
    }

    func testState_FeeCoinValue_CoinType() {
        let fee: Decimal = 0.123
        let amount: Decimal = 123.45
        let address = "address"

        stub(mockAdapter) { mock in
            when(mock.fee(for: equal(to: amount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(fee)
        }

        input.inputType = .coin
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCoinValue, CoinValue(coinCode: coinCode, value: fee))
    }

    func testState_FeeCoinValue_CurrencyType() {
        let rateValue: Decimal = 987.65
        let fee: Decimal = 0.123
        let amount: Decimal = 123.45
        let address = "address"
        let coinAmount = amount / rateValue

        stub(mockAdapter) { mock in
            when(mock.fee(for: equal(to: coinAmount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(fee)
        }

        interactorState.exchangeRate = rateValue
        input.inputType = .currency
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCoinValue, CoinValue(coinCode: coinCode, value: fee))
    }

    func testState_FeeCurrencyValue_CoinType() {
        let rateValue: Decimal = 987.65
        let fee: Decimal = 0.123
        let amount: Decimal = 123.45
        let address = "address"

        stub(mockAdapter) { mock in
            when(mock.fee(for: equal(to: amount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(fee)
        }

        interactorState.exchangeRate = rateValue
        input.inputType = .coin
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCurrencyValue, CurrencyValue(currency: baseCurrency, value: fee * rateValue))
    }

    func testState_FeeCurrencyValue_CurrencyType() {
        let rateValue: Decimal = 987.65
        let fee: Decimal = 0.123
        let amount: Decimal = 123.45
        let address = "address"
        let coinAmount = amount / rateValue

        stub(mockAdapter) { mock in
            when(mock.fee(for: equal(to: coinAmount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(fee)
        }

        interactorState.exchangeRate = rateValue
        input.inputType = .currency
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCurrencyValue, CurrencyValue(currency: baseCurrency, value: fee * rateValue))
    }

    func testState_feeCurrencyValue_currencyType_erc20() {
        let feeCoinCode = "ETH"
        let feeRateValue: Decimal = 789.65
        let fee: Decimal = 0.123
        let amount: Decimal = 123.45
        let address = "address"

        stub(mockAdapter) { mock in
            when(mock.feeCoinCode.get).thenReturn(feeCoinCode)
            when(mock.fee(for: equal(to: amount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(fee)
        }

        interactorState.feeExchangeRate = feeRateValue
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCurrencyValue, CurrencyValue(currency: baseCurrency, value: fee * feeRateValue))
    }

    func testState_erc20FeeCoinCode() {
        let feeCoinCode = "ETH"
        let fee: Decimal = 0.123
        let amount: Decimal = 123.45
        let address: String = "address"

        input.inputType = .coin
        input.amount = amount
        input.address = address

        stub(mockAdapter) { mock in
            when(mock.feeCoinCode.get).thenReturn(feeCoinCode)
            when(mock.fee(for: equal(to: amount), address: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(fee)
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCoinValue, CoinValue(coinCode: feeCoinCode, value: fee))
    }

    func testCopyAddress() {
        let address = "some_address"

        interactor.copy(address: address)

        verify(mockPasteboardManager).set(value: equal(to: address))
    }

    func testFetchRate() {
        let rateValue: Decimal = 987.65

        stub(mockRateStorage) { mock in
            when(mock.nonExpiredLatestRateValueObservable(forCoinCode: equal(to: coinCode), currencyCode: equal(to: baseCurrency.code))).thenReturn(Observable.just(rateValue))
        }

        interactor.fetchRate()

        XCTAssertEqual(interactorState.exchangeRate, rateValue)
        verify(mockDelegate).didUpdateRate()
    }

    func testFetchFeeRate() {
        let rateValue: Decimal = 987.65
        let feeCoinCode = "ETH"

        stub(mockAdapter) { mock in
            when(mock.feeCoinCode.get).thenReturn(feeCoinCode)
        }
        stub(mockRateStorage) { mock in
            when(mock.nonExpiredLatestRateValueObservable(forCoinCode: equal(to: coinCode), currencyCode: equal(to: baseCurrency.code))).thenReturn(Observable.just(0))
            when(mock.nonExpiredLatestRateValueObservable(forCoinCode: equal(to: feeCoinCode), currencyCode: equal(to: baseCurrency.code))).thenReturn(Observable.just(rateValue))
        }

        interactor.fetchRate()

        XCTAssertEqual(interactorState.feeExchangeRate, rateValue)
        verify(mockDelegate, times(2)).didUpdateRate()
    }

    func testFetchFeeRate_noFeeCoinCode() {
        stub(mockRateStorage) { mock in
            when(mock.nonExpiredLatestRateValueObservable(forCoinCode: equal(to: coinCode), currencyCode: equal(to: baseCurrency.code))).thenReturn(Observable.just(0))
        }

        interactor.fetchRate()

        XCTAssertNil(interactorState.feeExchangeRate)
        verify(mockRateStorage, never()).nonExpiredLatestRateValueObservable(forCoinCode: equal(to: "ETH"), currencyCode: equal(to: baseCurrency.code))
    }

    func testDefaultInputType() {
        let inputType = SendInputType.currency
        interactorState.exchangeRate = 2

        stub(mockLocalStorage) { mock in
            when(mock.sendInputType.get).thenReturn(inputType)
        }

        XCTAssertEqual(interactor.defaultInputType, inputType)
    }

    func testDefaultInputType_noValueInLocalStorage() {
        stub(mockLocalStorage) { mock in
            when(mock.sendInputType.get).thenReturn(nil)
        }

        XCTAssertEqual(interactor.defaultInputType, SendInputType.coin)
    }

    func testDefaultInputType_noRate() {
        let inputType = SendInputType.currency

        stub(mockLocalStorage) { mock in
            when(mock.sendInputType.get).thenReturn(inputType)
        }

        XCTAssertEqual(interactor.defaultInputType, SendInputType.coin)
    }

    func testSetInputType() {
        let inputType = SendInputType.currency

        stub(mockLocalStorage) { mock in
            when(mock.sendInputType.set(any())).thenDoNothing()
        }

        interactor.set(inputType: inputType)

        verify(mockLocalStorage).sendInputType.set(equal(to: inputType))
    }

    func testAvailableBalance_Coin() {
        let amount: Decimal = 123.45
        let address = "address"

        input.address = address

        stub(mockAdapter) { mock in
            when(mock.availableBalance(for: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(amount)
        }

        let availableBalance = interactor.totalBalanceMinusFee(forInputType: input.inputType, address: address, feeRatePriority: input.feeRatePriority)
        XCTAssertEqual(amount, availableBalance)
    }

    func testAvailableBalance_Currency() {
        let rateValue: Decimal = 987.65
        let amount: Decimal = 123.45
        let address = "address"

        interactorState.exchangeRate = rateValue
        input.inputType = .currency
        input.address = address

        stub(mockAdapter) { mock in
            when(mock.availableBalance(for: equal(to: address), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(amount)
        }

        let availableBalance = interactor.totalBalanceMinusFee(forInputType: input.inputType, address: address, feeRatePriority: input.feeRatePriority)
        let expectedBalanceMinusFee: Decimal = amount * rateValue
        XCTAssertEqual(expectedBalanceMinusFee, availableBalance)
    }

    func testSend() {
        let address = "address"
        let amount: Decimal = 13
        input.address = address
        input.amount = amount

        stub(mockAdapter) { mock in
            when(mock.sendSingle(to: any(), amount: any(), feeRatePriority: any())).thenReturn(Single.just(()))
        }

        interactor.send(userInput: input)

        verify(mockAdapter).sendSingle(to: equal(to: address), amount: equal(to: amount), feeRatePriority: equal(to: input.feeRatePriority))
    }

    func testSuccessSend() {
        let address = "address"
        let amount: Decimal = 13
        input.address = address
        input.amount = amount

        stub(mockAdapter) { mock in
            when(mock.sendSingle(to: equal(to: address), amount: equal(to: amount), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(Single.just(()))
        }

        interactor.send(userInput: input)

        verify(mockDelegate).didSend()
    }

    func testFailSend() {
        let address = "address"
        let amount: Decimal = 13
        input.address = address
        input.amount = amount
        let error = TestError()

        stub(mockAdapter) { mock in
            when(mock.sendSingle(to: equal(to: address), amount: equal(to: amount), feeRatePriority: equal(to: input.feeRatePriority))).thenReturn(Single.error(error))
        }

        interactor.send(userInput: input)

        verify(mockDelegate).didFailToSend(error: equal(to: error, type: TestError.self))
    }

    func testOnBecomeActive() {
        mockBackgroundManager.didBecomeActiveSubject.onNext(())

        verify(mockDelegate).onBecomeActive()
    }

}
