import UIKit
import ThemeKit
import UniswapKit
import HUD

class SwapViewController: ThemeViewController {
    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2

    private let delegate: ISwapViewDelegate

    private let scrollView = UIScrollView()
    private let container = UIView()

    private let topLineView = UIView()

    private let fromHeaderView = SwapHeaderView()
    private let fromInputView = SwapInputView()

    private let fromBalanceView = AdditionalDataWithErrorView()
    private let allowanceView = AdditionalDataWithLoadingView()

    private let separatorLineView = UIView()

    private let toHeaderView = SwapHeaderView()
    private let toInputView = SwapInputView()

    private let swapAreaWrapper = UIView()
    private let toPriceView = AdditionalDataView()
    private let toPriceImpactView = AdditionalDataView()
    private let minMaxView = AdditionalDataView()

    private let button = ThemeButton()

    private let swapErrorLabel = UILabel()

    init(delegate: ISwapViewDelegate) {
        self.delegate = delegate

        super.init()

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.title".localized
        view.backgroundColor = .themeDarker

        view.addSubview(scrollView)

        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag

        scrollView.addSubview(container)

        container.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view)
            maker.top.bottom.equalTo(self.scrollView)
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info Icon Medium")?.tinted(with: .themeJacob), style: .plain, target: self, action: #selector(onInfo))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        initLayout()
        delegate.onViewDidLoad()
    }

    private func initLayout() {
        fromInputView.delegate = self
        toInputView.delegate = self

        container.addSubview(topLineView)
        container.addSubview(fromHeaderView)
        container.addSubview(fromInputView)
        container.addSubview(fromBalanceView)
        container.addSubview(allowanceView)
        container.addSubview(separatorLineView)
        container.addSubview(toHeaderView)
        container.addSubview(toInputView)

        container.addSubview(swapAreaWrapper)
        swapAreaWrapper.addSubview(toPriceView)
        swapAreaWrapper.addSubview(toPriceImpactView)
        swapAreaWrapper.addSubview(minMaxView)
        swapAreaWrapper.addSubview(button)

        container.addSubview(swapErrorLabel)

        topLineView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        topLineView.backgroundColor = .themeSteel20

        fromHeaderView.snp.makeConstraints { maker in
            maker.top.equalTo(topLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        fromHeaderView.set(title: "swap.you_pay".localized)
        fromHeaderView.setBadge(text: "swap.estimated".localized)
        fromHeaderView.setBadge(hidden: true)

        fromInputView.snp.makeConstraints { maker in
            maker.top.equalTo(fromHeaderView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        fromInputView.set(maxButtonVisible: false)

        fromBalanceView.snp.makeConstraints { maker in
            maker.top.equalTo(fromInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        allowanceView.snp.makeConstraints {maker in
            maker.top.equalTo(fromBalanceView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        separatorLineView.snp.makeConstraints { maker in
            maker.top.equalTo(allowanceView.snp.bottom).offset(CGFloat.margin1x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorLineView.backgroundColor = .themeSteel20

        toHeaderView.snp.makeConstraints { maker in
            maker.top.equalTo(separatorLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        toHeaderView.set(title: "swap.you_get".localized)
        toHeaderView.setBadge(text: "swap.estimated".localized)
        toHeaderView.setBadge(hidden: false)

        toInputView.snp.makeConstraints { maker in
            maker.top.equalTo(toHeaderView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        toInputView.set(maxButtonVisible: false)

        swapAreaWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(toInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        swapAreaWrapper.isHidden = true

        toPriceView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        toPriceImpactView.snp.makeConstraints { maker in
            maker.top.equalTo(toPriceView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        minMaxView.snp.makeConstraints { maker in
            maker.top.equalTo(toPriceImpactView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        button.snp.makeConstraints { maker in
            maker.top.equalTo(minMaxView.snp.bottom).offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(50)
        }

        button.apply(style: .primaryYellow)
        button.addTarget(self, action: #selector(onButtonTouchUp), for: .touchUpInside)

        swapErrorLabel.snp.makeConstraints { maker in
            maker.top.equalTo(toInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        swapErrorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        swapErrorLabel.font = .caption
        swapErrorLabel.textColor = .themeLucian
        swapErrorLabel.numberOfLines = 0
    }

    private func setSwapArea(hidden: Bool) {
        swapAreaWrapper.isHidden = hidden
    }

    private func set(exactType: TradeType) {
        fromHeaderView.setBadge(hidden: exactType == .exactIn)
        toHeaderView.setBadge(hidden: exactType == .exactOut)
    }

    private func set(viewItem: AdditionalViewItem, for additionalView: AdditionalDataView) {
        additionalView.bind(title: viewItem.title.localized, value: viewItem.value?.localized)
        additionalView.setValue(customColor: viewItem.customColor)
    }

    private func type(for view: SwapInputView) -> TradeType {
        view == fromInputView ? .exactIn : .exactOut
    }

    @objc func onClose() {
        delegate.onClose()
    }

    @objc func onInfo() {
        delegate.onTapInfo()
    }

    @objc func onButtonTouchUp() {
        delegate.onButtonClicked()
    }

}

extension SwapViewController: ISwapView {

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func bind(swapAreaViewItem: SwapModule.SwapAreaViewItem) {
        set(viewItem: swapAreaViewItem.minMaxItem, for: minMaxView)
        set(viewItem: swapAreaViewItem.executionPriceItem, for: toPriceView)
        set(viewItem: swapAreaViewItem.priceImpactItem, for: toPriceImpactView)

        button.setTitle(swapAreaViewItem.buttonTitle.localized, for: .normal)
        button.isEnabled = swapAreaViewItem.buttonEnabled
    }

    func bind(viewItem: SwapModule.ViewItem) {
        set(exactType: viewItem.exactType)

        fromInputView.set(tokenCode: viewItem.tokenIn)
        toInputView.set(tokenCode: viewItem.tokenOut ?? "swap.token".localized)

        switch viewItem.exactType {
        case .exactIn: toInputView.set(text: viewItem.estimatedAmount)
        case .exactOut: fromInputView.set(text: viewItem.estimatedAmount)
        }

        fromBalanceView.bind(title: "swap.balance".localized, value: viewItem.balance)
        fromBalanceView.bind(error: viewItem.balanceError?.localizedDescription)

        if let allowance = viewItem.allowance {
            allowanceView.set(hidden: false)

            allowanceView.bind(title: "swap.allowance", value: allowance.data)
            if case .loading = allowance {
                allowanceView.set(loading: true)
            }
        } else {
            allowanceView.set(hidden: true)
        }

        setSwapArea(hidden: true)
        swapErrorLabel.isHidden = true
        fromHeaderView.set(loading: true)

        guard let swapAreaItem = viewItem.swapAreaItem else {
            return
        }

        switch swapAreaItem {
        case .failed(let error):
            swapErrorLabel.isHidden = false
            swapErrorLabel.text = error?.localizedDescription
        case .loading:
            fromHeaderView.set(loading: false)
        case .completed(let data):
            setSwapArea(hidden: false)

            bind(swapAreaViewItem: data)
        }
    }

    func amount(type: TradeType) -> String? {
        switch type {
        case .exactOut: return toInputView.text
        case .exactIn: return fromInputView.text
        }
    }

    func dismissWithSuccess() {
        navigationController?.dismiss(animated: true)
        HudHelper.instance.showSuccess()
    }

}

extension SwapViewController: ISwapInputViewDelegate {

    func isValid(_ inputView: SwapInputView, text: String) -> Bool {
        if delegate.isValid(type: type(for: inputView), text: text) {
            return true
        } else {
            inputView.shakeView()
            return false
        }
    }

    func willChangeAmount(_ inputView: SwapInputView, text: String?) {
        delegate.willChangeAmount(type: type(for: inputView), text: text)
    }

    func onMaxClicked(_ inputView: SwapInputView) {
    }

    func onTokenSelectClicked(_ inputView: SwapInputView) {
        delegate.onTokenSelect(type: type(for: inputView))
    }

}
