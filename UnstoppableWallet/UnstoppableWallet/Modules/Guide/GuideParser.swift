import UIKit
import ThemeKit
import Down

class GuideParser {

    private let fonts = StaticFontCollection(
            heading1: .title2,
            heading2: .title3,
            heading3: .headline2,
            body: .body
    )

    private let colors = StaticColorCollection(
            heading1: .themeOz,
            heading2: .themeJacob,
            heading3: .themeJacob,
            body: .themeOz
    )

    private let paragraphStyles: StaticParagraphStyleCollection = {
        var paragraphStyles = StaticParagraphStyleCollection()

        let headingParagraphStyle = NSMutableParagraphStyle()

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = 6

        paragraphStyles.heading1 = headingParagraphStyle
        paragraphStyles.heading2 = headingParagraphStyle
        paragraphStyles.heading3 = headingParagraphStyle
        paragraphStyles.body = bodyParagraphStyle

        return paragraphStyles
    }()

}

extension GuideParser: IGuideParser {

    func viewItems(markdownFileName: String) -> [GuideBlockViewItem] {
        guard let url = Bundle.main.url(forResource: markdownFileName, withExtension: "md") else {
            return []
        }

        do {
            let string = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
            let down = Down(markdownString: string)

            let configuration = DownStylerConfiguration(
                    fonts: fonts,
                    colors: colors,
                    paragraphStyles: paragraphStyles
            )

            let styler = DownStyler(configuration: configuration)

            let tree = try down.toAST().wrap()

            guard let document = tree as? Document else {
                throw DownErrors.astRenderingError
            }

            let attributedStringVisitor = AttributedStringVisitor(styler: styler)
            let visitor = GuideVisitor(attributedStringVisitor: attributedStringVisitor, styler: styler)
            let block = document.accept(visitor)

            print(block)
            print(document.accept(DebugVisitor()))

            guard let documentBlock = block as? GuideVisitor.DocumentBlock else {
                return []
            }

            var viewItems = [GuideBlockViewItem]()

            for block in documentBlock.blocks {
                if let headingBlock = block as? GuideVisitor.HeadingBlock {
                    if headingBlock.level == 1 {
                        viewItems.append(.h1(attributedString: headingBlock.attributedString))
                    } else if headingBlock.level == 2 {
                        viewItems.append(.h2(attributedString: headingBlock.attributedString))
                    } else if headingBlock.level == 3 {
                        viewItems.append(.h3(attributedString: headingBlock.attributedString))
                    }
                }

                if let paragraphBlock = block as? GuideVisitor.ParagraphBlock {
                    viewItems.append(.text(attributedString: paragraphBlock.attributedString))
                }

                if let listBlock = block as? GuideVisitor.ListBlock {
                    for block in listBlock.blocks {
                        if let itemBlock = block as? GuideVisitor.ItemBlock {
                            for block in itemBlock.blocks {
                                if let paragraphBlock = block as? GuideVisitor.ParagraphBlock {
                                    viewItems.append(.listItem(attributedString: paragraphBlock.attributedString))
                                }
                            }
                        }
                    }
                }

                if let blockQuoteBlock = block as? GuideVisitor.BlockQuoteBlock {
                    for block in blockQuoteBlock.blocks {
                        if let paragraphBlock = block as? GuideVisitor.ParagraphBlock {
                            viewItems.append(.blockQuote(attributedString: paragraphBlock.attributedString))
                        }
                    }
                }

                if let imageBlock = block as? GuideVisitor.ImageBlock, let url = imageBlock.url {
                    viewItems.append(.image(url: url))

                    if let title = imageBlock.title {
                        viewItems.append(.imageTitle(text: title))
                    }
                }
            }

            return viewItems
        } catch {
            return []
        }
    }

}
