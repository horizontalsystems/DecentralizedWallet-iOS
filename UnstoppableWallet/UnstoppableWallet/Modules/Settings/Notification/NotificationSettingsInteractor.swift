import RxSwift

class NotificationSettingsInteractor {
    weak var delegate: INotificationSettingsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let priceAlertManager: IPriceAlertManager
    private let notificationManager: INotificationManager

    private let localStorage: ILocalStorage

    init(priceAlertManager: IPriceAlertManager, notificationManager: INotificationManager, appManager: IAppManager, localStorage: ILocalStorage) {
        self.priceAlertManager = priceAlertManager
        self.notificationManager = notificationManager
        self.localStorage = localStorage

        appManager.willEnterForegroundObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didEnterForeground()
                })
                .disposed(by: disposeBag)

        priceAlertManager.updateObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.onAlertsUpdate()
                })
                .disposed(by: disposeBag)
    }

}

extension NotificationSettingsInteractor: INotificationSettingsInteractor {

    var pushNotificationsOn: Bool {
        get {
            localStorage.pushNotificationsOn
        }
        set {
            localStorage.pushNotificationsOn = newValue
        }
    }

    var alerts: [PriceAlert] {
        priceAlertManager.priceAlerts
    }

    func updateTopics() {
        priceAlertManager.updateTopics()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] error in
                    self?.delegate?.didFailUpdateTopics(error: error)
                }, onCompleted: { [weak self] in
                    self?.delegate?.didUpdateTopics()
                })
                .disposed(by: disposeBag)
    }

    func requestPermission() {
        notificationManager.requestPermission { [weak self] granted in
            if granted {
                self?.delegate?.didGrantPermission()
            } else {
                self?.delegate?.didDenyPermission()
            }
        }
    }

    func deleteAllAlerts() {
        priceAlertManager.deleteAllAlerts()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] in
                    self?.delegate?.didSaveAlerts()
                }, onError: { [weak self] error in
                    self?.delegate?.didFailSaveAlerts(error: error)
                })
                .disposed(by: disposeBag)
    }

}
