import RxSwift

class NotificationSettingsInteractor {
    weak var delegate: INotificationSettingsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let priceAlertManager: IPriceAlertManager
    private let notificationManager: INotificationManager

    init(priceAlertManager: IPriceAlertManager, notificationManager: INotificationManager, appManager: IAppManager) {
        self.priceAlertManager = priceAlertManager
        self.notificationManager = notificationManager

        appManager.willEnterForegroundObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didEnterForeground()
                })
                .disposed(by: disposeBag)
    }

}

extension NotificationSettingsInteractor: INotificationSettingsInteractor {

    var alerts: [PriceAlert] {
        priceAlertManager.priceAlerts
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

    func save(priceAlerts: [PriceAlert]) {
        priceAlertManager.save(priceAlerts: priceAlerts)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] error in
                    self?.delegate?.didFailSaveAlerts(error: error)
                }, onCompleted: { [weak self] in
                    self?.delegate?.didSaveAlerts()
                })
                .disposed(by: disposeBag)
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
