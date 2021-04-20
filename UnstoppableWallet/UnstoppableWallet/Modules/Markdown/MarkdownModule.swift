import UIKit

struct MarkdownModule {

    static func viewController(url: URL) -> UIViewController {
        let provider = MarkdownPlainContentProvider(url: url, networkManager: App.shared.networkManager)
        let service = MarkdownService(provider: provider)
        let parser = MarkdownParser()
        let viewModel = MarkdownViewModel(service: service, parser: parser)

        return MarkdownViewController(viewModel: viewModel)
    }

    static func gitReleaseNotesMarkdownViewController(url: URL) -> UIViewController {
        let provider = MarkdownGitReleaseContentProvider(url: url, networkManager: App.shared.networkManager)
        let service = MarkdownService(provider: provider)
        let parser = MarkdownParser()
        let viewModel = MarkdownViewModel(service: service, parser: parser)

        return MarkdownViewController(viewModel: viewModel, showClose: true)
    }

}

enum MarkdownBlockViewItem {
    case header(attributedString: NSAttributedString, level: Int)
    case text(attributedString: NSAttributedString)
    case listItem(attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool)
    case blockQuote(attributedString: NSAttributedString, tightTop: Bool, tightBottom: Bool)
    case image(url: URL, type: MarkdownImageType, tight: Bool)
    case imageTitle(text: String)
}

enum MarkdownImageType {
    case landscape
    case portrait
    case square
}
