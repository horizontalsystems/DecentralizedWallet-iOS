import UIKit
import RxSwift
import SnapKit
import HSHDWalletKit

class RestoreWordsViewController: WalletViewController {
    let disposeBag = DisposeBag()
    let delegate: IRestoreWordsViewDelegate

    let restoreDescription = "restore.words.description".localized
    var words: [String]

    let layout = UICollectionViewFlowLayout()
    let collectionView: UICollectionView
    var onReturnSubject = PublishSubject<IndexPath>()

    var keyboardFrameDisposable: Disposable?

    init(delegate: IRestoreWordsViewDelegate) {
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.delegate = delegate
        words = [String](repeating: "", count: self.delegate.wordsCount)

        super.init()

        collectionView.delegate = self
        collectionView.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "restore.title".localized

        subscribeKeyboard()

        view.addSubview(collectionView)
        collectionView.backgroundColor = .clear
        layout.sectionInset = UIEdgeInsets(top: RestoreTheme.listMargin, left: RestoreTheme.collectionSideMargin, bottom: RestoreTheme.listMargin, right: RestoreTheme.collectionSideMargin)
        layout.minimumInteritemSpacing = RestoreTheme.interItemSpacing
        layout.minimumLineSpacing = RestoreTheme.lineSpacing
        collectionView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        collectionView.registerCell(forClass: RestoreWordCell.self)
        collectionView.registerView(forClass: DescriptionCollectionHeader.self, flowSupplementaryKind: .header)

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if keyboardFrameDisposable == nil {
            subscribeKeyboard()
        }
        DispatchQueue.main.async  {
            self.becomeResponder(at: IndexPath(item: 0, section: 0))
        }
    }

    @objc func restoreDidTap() {
        view.endEditing(true)

        delegate.didTapRestore(words: words)
    }

    private func subscribeKeyboard() {
        keyboardFrameDisposable = NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                self?.onKeyboardFrameChange(notification)
            })
        keyboardFrameDisposable?.disposed(by: disposeBag)
    }

    private func onKeyboardFrameChange(_ notification: Notification) {
        let screenKeyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let height = view.height + view.y
        let keyboardHeight = height - screenKeyboardFrame.origin.y

        let duration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let curve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue

        updateUI(keyboardHeight: keyboardHeight, duration: duration, options: UIView.AnimationOptions(rawValue: curve << 16))
    }

    private func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIView.AnimationOptions, completion: (() -> ())? = nil) {
        var insets: UIEdgeInsets = collectionView.contentInset
        insets.bottom = keyboardHeight
        collectionView.contentInset = insets
        collectionView.scrollIndicatorInsets = insets
    }

    private func becomeResponder(at indexPath: IndexPath) {
        guard indexPath.row < words.count else {
            restoreDidTap()
            return
        }

        onReturnSubject.onNext(indexPath)
    }

    private func onTextChange(word: String?, at indexPath: IndexPath) {
        words[indexPath.item] = word?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
    }

    @objc func cancelDidTap() {
        delegate.didTapCancel()
    }

}

extension RestoreWordsViewController: IRestoreWordsView {

    func showCancelButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))
    }

    func showNextButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(restoreDidTap))
    }

    func showRestoreButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(restoreDidTap))
    }

    func show(defaultWords: [String]) {
        for (index, defaultWord) in defaultWords.enumerated() {
            if index < words.count {
                words[index] = defaultWord
            }
        }
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}

extension RestoreWordsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - RestoreTheme.interItemSpacing - RestoreTheme.collectionSideMargin * 2
        return CGSize(width: width / 2, height: RestoreTheme.itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: RestoreWordCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? RestoreWordCell {
            cell.bind(onReturnSubject: onReturnSubject, indexPath: indexPath, index: indexPath.item + 1, word: words[indexPath.row], returnKeyType: indexPath.row + 1 < words.count ? .next : .done, onReturn: { [weak self] in
                self?.becomeResponder(at: IndexPath(item: indexPath.item + 1, section: 0))
            }, onTextChange: { [weak self] string in
                self?.onTextChange(word: string, at: indexPath)
            })
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? RestoreWordCell {
            if cell.inputField.textField.isFirstResponder {
                view.endEditing(true)
            }
        }
    }

//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: DescriptionCollectionHeader.self), for: indexPath)
//        if let header = header as? DescriptionCollectionHeader {
//            header.bind(text: restoreDescription)
//        }
//        return header
//    }

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        let width = collectionView.bounds.width
//        let height = DescriptionCollectionHeader.height(forContainerWidth: width, text: restoreDescription)
//        return CGSize(width: width, height: height)
//    }

}
