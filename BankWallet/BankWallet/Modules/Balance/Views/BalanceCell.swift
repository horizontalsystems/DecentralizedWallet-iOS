import UIKit
import UIExtensions
import HUD
import RxSwift
import SnapKit

class BalanceCell: UITableViewCell {
    private static let minimumProgress = 10

    private let roundedBackground = UIView()
    private let clippingView = UIView()

    private let coinIconImageView = CoinIconImageView()
    private let nameLabel = UILabel()
    private let currencyValueLabel = UILabel()
    private let coinValueLabel = UILabel()
    private let rateLabel = UILabel()

    private let chartView = UIView()
    private let percentDeltaLabel = UILabel()

    private let syncSpinner = HUDProgressView(
            progress: Float(BalanceCell.minimumProgress) / 100,
            strokeLineWidth: BalanceTheme.spinnerLineWidth,
            radius: BalanceTheme.spinnerDonutRadius,
            strokeColor: BalanceTheme.spinnerLineColor,
            donutColor: BalanceTheme.spinnerDonutColor,
            duration: 2
    )

    private let failedImageView = UIImageView()

    private let receiveButton = RespondButton()
    private let payButton = RespondButton()
    private let chartButton = RespondButton()

    private var onPay: (() -> ())?
    private var onReceive: (() -> ())?
    private var onChart: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(BalanceTheme.cellPadding)
            maker.leadingMargin.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.bottom.equalToSuperview()
        }
        roundedBackground.backgroundColor = BalanceTheme.roundedBackgroundColor
        roundedBackground.layer.shadowOpacity = BalanceTheme.roundedBackgroundShadowOpacity
        roundedBackground.layer.cornerRadius = BalanceTheme.roundedBackgroundCornerRadius
        roundedBackground.layer.shadowColor = BalanceTheme.roundedBackgroundShadowColor.cgColor
        roundedBackground.layer.shadowRadius = 4
        roundedBackground.layer.shadowOffset = CGSize(width: 0, height: 4)

        roundedBackground.addSubview(clippingView)
        clippingView.backgroundColor = .clear
        clippingView.clipsToBounds = true
        clippingView.layer.cornerRadius = BalanceTheme.roundedBackgroundCornerRadius
        clippingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        clippingView.addSubview(coinIconImageView)
        coinIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
        }

        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.coinIconImageView.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.centerY.equalTo(self.coinIconImageView.snp.centerY)
        }
        nameLabel.font = BalanceTheme.cellTitleFont
        nameLabel.textColor = BalanceTheme.cellTitleColor
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellBigMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.rateTopMargin)
        }
        rateLabel.font = BalanceTheme.rateFont
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.nameLabel.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
        }
        coinValueLabel.font = BalanceTheme.coinValueFont
        coinValueLabel.textColor = BalanceTheme.coinValueColor
        coinValueLabel.textAlignment = .right

        clippingView.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateLabel.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.centerY.equalTo(self.rateLabel.snp.centerY)
        }
        currencyValueLabel.font = BalanceTheme.currencyValueFont
        currencyValueLabel.textAlignment = .right

        syncSpinner.backgroundColor = BalanceTheme.spinnerBackgroundColor
        syncSpinner.layer.cornerRadius = BalanceTheme.spinnerSideSize / 2
        clippingView.addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.center.equalTo(self.coinIconImageView.snp.center)
            maker.size.equalTo(BalanceTheme.spinnerSideSize)
        }

        failedImageView.image = UIImage(named: "Attention Icon")
        clippingView.addSubview(failedImageView)
        failedImageView.snp.makeConstraints { maker in
            maker.center.equalTo(self.coinIconImageView.snp.center)
        }

        clippingView.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.buttonsTopMargin)
            maker.height.equalTo(BalanceTheme.buttonsHeight)
        }
        receiveButton.onTap = { [weak self] in self?.receive() }
        receiveButton.backgrounds = ButtonTheme.greenBackgroundDictionary
        receiveButton.textColors = ButtonTheme.textColorDictionary
        receiveButton.cornerRadius = BalanceTheme.buttonCornerRadius
        receiveButton.titleLabel.text = "balance.deposit".localized

        clippingView.addSubview(payButton)
        payButton.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.buttonsTopMargin)
            maker.height.equalTo(BalanceTheme.buttonsHeight)
            maker.width.equalTo(receiveButton)
        }
        payButton.onTap = { [weak self] in self?.pay() }
        payButton.backgrounds = ButtonTheme.yellowBackgroundDictionary
        payButton.textColors = ButtonTheme.textColorDictionary
        payButton.cornerRadius = BalanceTheme.buttonCornerRadius
        payButton.titleLabel.text = "balance.send".localized

        clippingView.addSubview(chartButton)
        chartButton.wrapperView.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.smallMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.smallMargin)
        }
        chartButton.snp.makeConstraints { maker in
            maker.leading.equalTo(payButton.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellSmallMargin)
            maker.height.equalTo(BalanceTheme.buttonsHeight)
            maker.width.equalTo(40)
        }
        chartButton.onTap = { [weak self] in self?.chart() }
        chartButton.backgrounds = ButtonTheme.redBackgroundDictionary
        chartButton.textColors = ButtonTheme.textColorDictionary
        chartButton.cornerRadius = BalanceTheme.buttonCornerRadius
        chartButton.titleLabel.text = "\u{20aa}"

        clippingView.addSubview(chartView)
        chartView.layer.masksToBounds = true
        chartView.layer.cornerRadius = BalanceTheme.chartCornerRadius
        chartView.backgroundColor = .lightGray
        chartView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellSmallMargin)
            maker.size.equalTo(CGSize(width: BalanceTheme.chartWidth, height: BalanceTheme.chartHeight))
        }
        clippingView.addSubview(percentDeltaLabel)
        percentDeltaLabel.font = BalanceTheme.percentDeltaFont
        percentDeltaLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.chartView.snp.bottom).offset(BalanceTheme.cellBigMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: BalanceViewItem, isStatModeOn: Bool, selected: Bool, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ()), onChart: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive
        self.onChart = onChart

        bindView(item: item, isStatModeOn: isStatModeOn, selected: selected, animated: animated)
    }

    func bindView(item: BalanceViewItem, isStatModeOn: Bool, selected: Bool, animated: Bool = false) {
        var synced = false

        coinIconImageView.bind(coin: item.coin)
        nameLabel.text = item.coin.title.localized

        receiveButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)

        if item.state == AdapterState.synced || item.state == AdapterState.notReady  {
            synced = true
            coinIconImageView.isHidden = false
        } else {
            coinIconImageView.isHidden = true
        }
        if case .synced = item.state, item.coinValue.value > 0 {
            payButton.state = .active
        } else {
            payButton.state = .disabled
        }
        if case .notReady = item.state {
            receiveButton.state = .disabled
        } else {
            receiveButton.state = .active
        }

        if case let .syncing(progress, _) = item.state {
            syncSpinner.isHidden = false
            syncSpinner.set(progress: Float(max(BalanceCell.minimumProgress, progress)) / 100)
            syncSpinner.startAnimating()
        } else {
            syncSpinner.isHidden = true
            syncSpinner.stopAnimating()
        }

        if case let .syncing(_, lastBlockDate) = item.state, selected {
            if let lastBlockDate = lastBlockDate {
                rateLabel.text = "balance.synced_through".localized(DateHelper.instance.formatSyncedThroughDate(from: lastBlockDate))
            } else {
                rateLabel.text = "balance.syncing".localized
            }
            rateLabel.textColor = BalanceTheme.rateColor
        } else if let value = item.exchangeValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) {
            rateLabel.text = "balance.rate_per_coin".localized(formattedValue, item.coinValue.coin.code)
            rateLabel.textColor = item.rateExpired ? BalanceTheme.rateExpiredColor : BalanceTheme.rateColor
        } else {
            rateLabel.text = " " // space required for constraints
        }

        if let value = item.currencyValue, value.value != 0 {
            currencyValueLabel.text = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01))
            let nonZeroBalanceTextColor = item.rateExpired || !synced ? BalanceTheme.nonZeroBalanceExpiredTextColor : BalanceTheme.nonZeroBalanceTextColor
            currencyValueLabel.textColor = value.value > 0 ? nonZeroBalanceTextColor : BalanceTheme.zeroBalanceTextColor
        } else {
            currencyValueLabel.text = nil
        }

        coinValueLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue, fractionPolicy: .threshold(high: 0.01, low: 0))
        coinValueLabel.alpha = synced ? 1 : 0.3

        if case .notSynced = item.state {
            failedImageView.isHidden = false
        } else {
            failedImageView.isHidden = true
        }

        currencyValueLabel.isHidden = isStatModeOn && !selected
        coinValueLabel.isHidden = isStatModeOn && !selected
        chartView.isHidden = !isStatModeOn || selected
        percentDeltaLabel.isHidden = !isStatModeOn || selected

        let fallDown = item.percentDelta < 0
        percentDeltaLabel.textColor = fallDown ? BalanceTheme.percentDeltaDownColor : BalanceTheme.percentDeltaUpColor
        percentDeltaLabel.text = "\(fallDown ? "" : "+")\(item.percentDelta)%"
    }

    func unbind() {
    }

    func receive() {
        onReceive?()
    }

    func pay() {
        onPay?()
    }

    func chart() {
        onChart?()
    }

    deinit {
    }

}
