import RxSwift
import RxRelay
import RxCocoa

class RestoreWordsViewModel {
    private let service: RestoreWordsService

    private let accountTypeRelay = PublishRelay<AccountType>()
    private let errorRelay = PublishRelay<Error>()

    init(service: RestoreWordsService) {
        self.service = service
    }

    var wordCount: Int {
        service.wordCount
    }

    var defaultWordsText: String {
        service.defaultWords.joined(separator: " ")
    }

    var accountTypeSignal: Signal<AccountType> {
        accountTypeRelay.asSignal()
    }

    var errorSignal: Signal<Error> {
        errorRelay.asSignal()
    }

    func onProceed(text: String?) {
        do {
            guard let text = text else {
                throw WordsError.emptyText
            }

            let words = text
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                    .map { $0.lowercased() }

            let accountType = try service.accountType(words: words)

            accountTypeRelay.accept(accountType)
        } catch {
            errorRelay.accept(error.convertedError)
        }
    }

}

extension RestoreWordsViewModel {

    enum WordsError: Error {
        case emptyText
    }

}
