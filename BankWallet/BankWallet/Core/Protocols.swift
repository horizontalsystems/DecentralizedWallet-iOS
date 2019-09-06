import RxSwift
import GRDB

typealias CoinCode = String

protocol IRandomManager {
    func getRandomIndexes(max: Int, count: Int) -> [Int]
}

protocol ILocalStorage: class {
    var baseCurrencyCode: String? { get set }
    var baseBitcoinProvider: String? { get set }
    var baseDashProvider: String? { get set }
    var baseBinanceProvider: String? { get set }
    var baseEosProvider: String? { get set }
    var baseEthereumProvider: String? { get set }
    var lightMode: Bool { get set }
    var agreementAccepted: Bool { get set }
    var balanceSortType: BalanceSortType? { get set }
    var isBiometricOn: Bool { get set }
    var currentLanguage: String? { get set }
    var lastExitDate: Double { get set }
    var didLaunchOnce: Bool { get set }
    var sendInputType: SendInputType? { get set }
    var chartType: ChartType? { get set }
    var mainShownOnce: Bool { get set }
}

protocol ISecureStorage: class {
    var pin: String? { get }
    func set(pin: String?) throws
    var unlockAttempts: Int? { get }
    func set(unlockAttempts: Int?) throws
    var lockoutTimestamp: TimeInterval? { get }
    func set(lockoutTimestamp: TimeInterval?) throws

    func getString(forKey key: String) -> String?
    func set(value: String?, forKey key: String) throws
    func getData(forKey key: String) -> Data?
    func set(value: Data?, forKey key: String) throws
    func remove(for key: String) throws

    func clear() throws
}

protocol ILanguageManager {
    var currentLanguage: String { get set }
    var displayNameForCurrentLanguage: String { get }

    func localize(string: String) -> String
    func localize(string: String, arguments: [CVarArg]) -> String
}

protocol ILocalizationManager {
    var preferredLanguage: String? { get }
    var availableLanguages: [String] { get }
    func displayName(forLanguage language: String, inLanguage: String) -> String

    func setLocale(forLanguage language: String)
    func localize(string: String, language: String) -> String?
    func format(localizedString: String, arguments: [CVarArg]) -> String
}

protocol IAdapterManager: class {
    var adaptersReadySignal: Signal { get }
    func adapter(for wallet: Wallet) -> IAdapter?
    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter?
    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter?
    func depositAdapter(for wallet: Wallet) -> IDepositAdapter?
    func refresh()
}

protocol IAdapterFactory {
    func adapter(wallet: Wallet) -> IAdapter?
}

protocol IWalletManager: class {
    var wallets: [Wallet] { get }
    var walletsUpdatedSignal: Signal { get }
    func wallet(coin: Coin) -> Wallet?

    func preloadWallets()
    func enable(wallets: [Wallet])
}

protocol IAdapter: class {
    func start()
    func stop()
    func refresh()

    var debugInfo: String { get }
}

protocol IBalanceAdapter {
    var state: AdapterState { get }
    var stateUpdatedObservable: Observable<Void> { get }
    var balance: Decimal { get }
    var balanceUpdatedObservable: Observable<Void> { get }
}

protocol IDepositAdapter {
    var receiveAddress: String { get }
}

protocol ITransactionsAdapter {
    var confirmationsThreshold: Int { get }
    var lastBlockHeight: Int? { get }
    var lastBlockHeightUpdatedObservable: Observable<Void> { get }
    var transactionRecordsObservable: Observable<[TransactionRecord]> { get }
    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]>
}

protocol ISendBitcoinAdapter {
    func availableBalance(feeRate: Int, address: String?) -> Decimal
    func validate(address: String) throws
    func fee(amount: Decimal, feeRate: Int, address: String?) -> Decimal
    func sendSingle(amount: Decimal, address: String, feeRate: Int) -> Single<Void>
}

protocol ISendDashAdapter {
    func availableBalance(address: String?) -> Decimal
    func validate(address: String) throws
    func fee(amount: Decimal, address: String?) -> Decimal
    func sendSingle(amount: Decimal, address: String) -> Single<Void>
}

protocol ISendEthereumAdapter {
    func availableBalance(gasPrice: Int) -> Decimal
    var ethereumBalance: Decimal { get }
    func validate(address: String) throws
    func fee(gasPrice: Int) -> Decimal
    func sendSingle(amount: Decimal, address: String, gasPrice: Int) -> Single<Void>
}

protocol ISendEosAdapter {
    var availableBalance: Decimal { get }
    func validate(account: String) throws
    func sendSingle(amount: Decimal, account: String, memo: String?) -> Single<Void>
}

protocol ISendBinanceAdapter {
    var availableBalance: Decimal { get }
    var availableBinanceBalance: Decimal { get }
    func validate(address: String) throws
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol IWordsManager {
    func generateWords(count: Int) throws -> [String]
    func validate(words: [String]) throws
}

protocol IAuthManager {
    func login(withWords words: [String], syncMode: SyncMode) throws
    func logout() throws
}

protocol IAccountManager {
    var accounts: [Account] { get }
    func account(coinType: CoinType) -> Account?

    var accountsObservable: Observable<[Account]> { get }
    var deleteAccountObservable: Observable<Account> { get }

    func preloadAccounts()
    func update(account: Account)
    func create(account: Account)
    func delete(account: Account)
    func clear()
}

protocol IBackupManager {
    var allBackedUp: Bool { get }
    var allBackedUpObservable: Observable<Bool> { get }
    func setAccountBackedUp(id: String)
}

protocol IAccountCreator {
    func createNewAccount(defaultAccountType: DefaultAccountType, createDefaultWallets: Bool) throws -> Account
    func createRestoredAccount(accountType: AccountType, defaultSyncMode: SyncMode?, createDefaultWallets: Bool) -> Account
}

protocol IAccountFactory {
    func account(type: AccountType, backedUp: Bool, defaultSyncMode: SyncMode?) -> Account
}

protocol IWalletFactory {
    func wallet(coin: Coin, account: Account, syncMode: SyncMode?) -> Wallet
}

protocol IRestoreAccountDataSource {
    var restoreAccounts: [Account] { get }
}

protocol ILockManager {
    var isLocked: Bool { get }
    func lock()
    func didEnterBackground()
    func willEnterForeground()
}

protocol IPasscodeLockManager {
    var locked: Bool { get }
    func didFinishLaunching()
    func willEnterForeground()
}

protocol IBlurManager {
    func willResignActive()
    func didBecomeActive()
}

protocol IPinManager: class {
    var isPinSet: Bool { get }
    var biometryEnabled: Bool { get set }
    func store(pin: String) throws
    func validate(pin: String) -> Bool
    func clear() throws

    var isPinSetObservable: Observable<Bool> { get }
}

protocol ILockRouter {
    func showUnlock(delegate: IUnlockDelegate?)
}

protocol IPasscodeLockRouter {
    func showNoPasscode()
    func showLaunch()
}

protocol IBiometricManager {
    func validate(reason: String)
}

protocol BiometricManagerDelegate: class {
    func didValidate()
    func didFailToValidate()
}

protocol IRateManager {
    func nonExpiredLatestRate(coinCode: CoinCode, currencyCode: String) -> Rate?
    func syncLatestRates()
    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, date: Date) -> Single<Decimal>
    func clear()
}

protocol IRateStatsManager {
    func rateStats(coinCode: CoinCode, currencyCode: String) -> Single<ChartData>
}

protocol ISystemInfoManager {
    var appVersion: String { get }
    var biometryType: Single<BiometryType> { get }
    var passcodeSet: Bool { get }
}

protocol IBiometryManager {
    var biometryType: BiometryType { get }
    var biometryTypeObservable: Observable<BiometryType> { get }
    func refresh()
}

protocol IAppConfigProvider {
    var ipfsId: String { get }
    var ipfsGateways: [String] { get }

    var companyWebPageLink: String { get }
    var appWebPageLink: String { get }
    var reportEmail: String { get }
    var reportTelegramGroup: String { get }

    var reachabilityHost: String { get }
    var testMode: Bool { get }
    var infuraCredentials: (id: String, secret: String?) { get }
    var etherscanKey: String { get }
    var currencies: [Currency] { get }

    func defaultWords(count: Int) -> [String]
    var defaultEosCredentials: (String, String) { get }
    var disablePinLock: Bool { get }

    var defaultCoinCodes: [CoinCode] { get }
    var coins: [Coin] { get }

    var predefinedAccountTypes: [IPredefinedAccountType] { get }
}

protocol IFullTransactionInfoProvider {
    var providerName: String { get }
    func url(for hash: String) -> String?

    func retrieveTransactionInfo(transactionHash: String) -> Single<FullTransactionRecord?>
}

protocol IFullTransactionInfoAdapter {
    func convert(json: [String: Any]) -> FullTransactionRecord?
}

protocol IIpfsApiProvider {
    func gatewaysSingle<T>(singleProvider: @escaping (String, TimeInterval) -> Single<T>) -> Single<T>
}

protocol IRateApiProvider {
    func getLatestRateData(currencyCode: String) -> Single<LatestRateData>
    func getRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal>
}

protocol IRatesStatsApiProvider {
    func getRateStatsData(coinCode: String, currencyCode: String) -> Single<RateStatsData>
}

protocol IRateStorage {
    func latestRate(coinCode: CoinCode, currencyCode: String) -> Rate?
    func latestRateObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Rate>
    func timestampRateObservable(coinCode: CoinCode, currencyCode: String, date: Date) -> Observable<Rate?>
    func zeroValueTimestampRatesObservable(currencyCode: String) -> Observable<[Rate]>
    func save(latestRate: Rate)
    func save(rate: Rate)
    func clearRates()
}

protocol IEnabledWalletStorage {
    var enabledWallets: [EnabledWallet] { get }
    func save(enabledWallets: [EnabledWallet])
}

protocol IAccountStorage {
    var allAccounts: [Account] { get }
    func save(account: Account)
    func delete(account: Account)
    func clear()
}

protocol IKitCleaner {
    func clear()
}

protocol IAccountRecordStorage {
    var allAccountRecords: [AccountRecord] { get }
    func save(accountRecord: AccountRecord)
    func deleteAccountRecord(by id: String)
    func deleteAllAccountRecords()
}

protocol IJsonApiProvider {
    func getJson(requestObject: JsonApiProvider.RequestObject) -> Single<[String: Any]>
}

protocol ITransactionRecordStorage {
    func record(forHash hash: String) -> TransactionRecord?
    var nonFilledRecords: [TransactionRecord] { get }
    func set(rate: Double, transactionHash: String)
    func clearRates()

    func update(records: [TransactionRecord])
    func clearRecords()
}

protocol ICurrencyManager {
    var currencies: [Currency] { get }
    var baseCurrency: Currency { get }
    var baseCurrencyUpdatedSignal: Signal { get }

    func setBaseCurrency(code: String)
}

protocol IFullTransactionDataProviderManager {
    var dataProviderUpdatedSignal: Signal { get }

    func providers(for coin: Coin) -> [IProvider]
    func baseProvider(for coin: Coin) -> IProvider
    func setBaseProvider(name: String, for coin: Coin)

    func bitcoin(for name: String) -> IBitcoinForksProvider
    func dash(for name: String) -> IBitcoinForksProvider
    func eos(for name: String) -> IEosProvider
    func bitcoinCash(for name: String) -> IBitcoinForksProvider
    func ethereum(for name: String) -> IEthereumForksProvider
    func binance(for name: String) -> IBinanceProvider
}

protocol IPingManager {
    func serverAvailable(url: String, timeoutInterval: TimeInterval) -> Observable<TimeInterval>
}

protocol IEosProvider: IProvider {
    func convert(json: [String: Any], account: String) -> IEosResponse?
}

protocol IBitcoinForksProvider: IProvider {
    func convert(json: [String: Any]) -> IBitcoinResponse?
}

protocol IEthereumForksProvider: IProvider {
    func convert(json: [String: Any]) -> IEthereumResponse?
}

protocol IBinanceProvider: IProvider {
    func convert(json: [String: Any]) -> IBinanceResponse?
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IPeriodicTimer {
    var delegate: IPeriodicTimerDelegate? { get set }
    func schedule()
}

protocol IOneTimeTimer {
    var delegate: IPeriodicTimerDelegate? { get set }
    func schedule(date: Date)
}

protocol IPeriodicTimerDelegate: class {
    func onFire()
}

protocol ITransactionRateSyncer {
    func sync(currencyCode: String)
    func cancelCurrentSync()
}

protocol IPasteboardManager {
    var value: String? { get }
    func set(value: String)
}

protocol IUrlManager {
    func open(url: String, from controller: UIViewController?)
}

protocol IFullTransactionInfoProviderFactory {
    func provider(`for` wallet: Wallet) -> IFullTransactionInfoProvider
}

protocol ISettingsProviderMap {
    func providers(for coinCode: String) -> [IProvider]
    func bitcoin(for name: String) -> IBitcoinForksProvider
    func bitcoinCash(for name: String) -> IBitcoinForksProvider
    func ethereum(for name: String) -> IEthereumForksProvider
}

protocol IProvider {
    var name: String { get }
    func url(for hash: String) -> String?
    func reachabilityUrl(for hash: String) -> String
    func requestObject(for hash: String) -> JsonApiProvider.RequestObject
}

protocol ILockoutManager {
    var currentState: LockoutState { get }
    func didFailUnlock()
    func dropFailedAttempts()
}

protocol ILockoutUntilDateFactory {
    func lockoutUntilDate(failedAttempts: Int, lockoutTimestamp: TimeInterval, uptime: TimeInterval) -> Date
}

protocol ICurrentDateProvider {
    var currentDate: Date { get }
}

protocol IUptimeProvider {
    var uptime: TimeInterval { get }
}

protocol ILockoutTimeFrameFactory {
    func lockoutTimeFrame(failedAttempts: Int, lockoutTimestamp: TimeInterval, uptime: TimeInterval) -> TimeInterval
}

protocol IAddressParser {
    func parse(paymentAddress: String) -> AddressData
}

protocol IFeeRateProvider {
    func feeRate(for priority: FeeRatePriority) -> Int
    func duration(priority: FeeRatePriority) -> TimeInterval
}

protocol IEncryptionManager {
    func encrypt(data: Data) throws -> Data
    func decrypt(data: Data) throws -> Data
}

protocol IUUIDProvider {
    func generate() -> String
}

protocol IPredefinedAccountTypeManager {
    var allTypes: [IPredefinedAccountType] { get }
    func account(predefinedAccountType: IPredefinedAccountType) -> Account?
    func predefinedAccountType(accountType: AccountType) -> IPredefinedAccountType?
    func predefinedAccountType(coin: Coin) -> IPredefinedAccountType?
    func createAccount(predefinedAccountType: IPredefinedAccountType) throws
    func createAllAccounts()
}

protocol IPredefinedAccountType {
    var confirmationDescription: String { get }
    var backupTitle: String { get }
    var title: String { get }
    var coinCodes: String { get }
    var defaultAccountType: DefaultAccountType { get }
    func supports(accountType: AccountType) -> Bool
}

protocol IAppManager {
    func didFinishLaunching()
    func willResignActive()
    func didBecomeActive()
    func didEnterBackground()
    func willEnterForeground()
}

protocol IWalletStorage {
    func wallets(accounts: [Account]) -> [Wallet]
    func save(wallets: [Wallet])
}

protocol IDefaultWalletCreator {
    func createWallets(account: Account)
}

protocol IFeeCoinProvider {
    func feeCoin(coin: Coin) -> Coin?
    func feeCoinProtocol(coin: Coin) -> String?
}
