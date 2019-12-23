import UIKit
import SnapKit

class BackupWordsController: WalletViewController {
    private let delegate: IBackupWordsViewDelegate

    private let scrollView = UIScrollView()
    private let wordsLabel = UILabel()

    private let proceedButtonHolder = GradientView(gradientHeight: .margin4x, viewHeight: .heightBottomWrapperBar, fromColor: UIColor.appTyler.withAlphaComponent(0), toColor: .appTyler)
    private let proceedButton: UIButton = .appYellow

    init(delegate: IBackupWordsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        title = "backup.private_key".localized

        view.addSubview(scrollView)

        view.addSubview(proceedButtonHolder)
        proceedButtonHolder.addSubview(proceedButton)
        scrollView.addSubview(wordsLabel)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.marginTextSide)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        wordsLabel.numberOfLines = 0
        wordsLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.scrollView)
            maker.top.equalTo(self.scrollView).offset(CGFloat.margin2x)
            maker.bottom.equalTo(self.scrollView.snp.bottom).inset(CGFloat.heightBottomWrapperBar)
        }

        proceedButtonHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            maker.height.equalTo(CGFloat.heightBottomWrapperBar)
        }

        proceedButton.setTitle(delegate.isBackedUp ? "backup.close".localized : "button.next".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector(nextDidTap), for: .touchUpInside)

        proceedButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.marginButtonSide)
            maker.height.equalTo(CGFloat.heightButton)
        }


        let joinedWords = delegate.words.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        let attributedText = NSMutableAttributedString(string: joinedWords)
        attributedText.addAttribute(NSAttributedString.Key.font, value: UIFont.appHeadline1, range: NSMakeRange(0, joinedWords.count))
        attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.appOz, range: NSMakeRange(0, joinedWords.count))
        wordsLabel.attributedText = attributedText

    }

    @objc func nextDidTap() {
        delegate.didTapProceed()
    }

}
