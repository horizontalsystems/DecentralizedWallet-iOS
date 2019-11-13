import Foundation

class LockManager {
    private let pinManager: IPinManager
    private let localStorage: ILocalStorage
    private let lockRouter: ILockRouter

    private let lockTimeout: Double = 60
    private(set) var isLocked: Bool = false

    init(pinManager: IPinManager, localStorage: ILocalStorage, lockRouter: ILockRouter) {
        self.pinManager = pinManager
        self.localStorage = localStorage
        self.lockRouter = lockRouter
    }

}

extension LockManager: ILockManager {

    func didEnterBackground() {
        guard !isLocked else {
            return
        }

        App.shared.debugLogger?.add(log: "LockManager set lastExitDate")
        localStorage.lastExitDate = Date().timeIntervalSince1970
    }

    func willEnterForeground() {
        guard !isLocked else {
            return
        }

        let exitTimestamp = localStorage.lastExitDate
        let now = Date().timeIntervalSince1970

        guard now - exitTimestamp > lockTimeout else {
            App.shared.debugLogger?.add(log: "LockManager lock time not reached")
            return
        }

        lock()
    }

    func lock() {
        App.shared.debugLogger?.add(log: "LockManager want to lock")

        guard pinManager.isPinSet else {
            return
        }

        isLocked = true
        lockRouter.showUnlock(delegate: self)
    }

}

extension LockManager: IUnlockDelegate {

    func onUnlock() {
        isLocked = false
    }

    func onCancelUnlock() {
    }

}
