import XCTest
@testable import MarkdownKit

class MarkdownExtension: XCTestCase, MarkdownKitFactory {
    
    enum LineEmphasis: MarkdownCustomTextFragment {
        case underline(MarkdownText)
        case strikethrough(MarkdownText)
        
        func equals(to other: MarkdownCustomTextFragment) -> Bool {
            guard let that = other as? LineEmphasis else {
                return false
            }
            switch (self, that) {
            case (.underline(let lhs), .underline(let rhs)):
                return lhs == rhs
            case (.strikethrough(let lhs), .strikethrough(let rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
        
        func transform(via transformer: InlineTransformer) -> MarkdownTextFragment {
            switch self {
            case .underline(let text):
                return .custom(LineEmphasis.underline(transformer.transform(text)))
            case .strikethrough(let text):
                return .custom(LineEmphasis.strikethrough(transformer.transform(text)))
            }
        }
        
        func generateHtml(via htmlGen: HtmlGenerator) -> String {
            switch self {
            case .underline(let text):
                return "<u>" + htmlGen.generate(text: text) + "</u>"
            case .strikethrough(let text):
                return "<s>" + htmlGen.generate(text: text) + "</s>"
            }
        }
        
        func generateHtml(via htmlGen: HtmlGenerator,
                          and attrGen: AttributedStringGenerator?) -> String {
            return self.generateHtml(via: htmlGen)
        }
        
        var rawDescription: String {
            switch self {
            case .underline(let text):
                return text.rawDescription
            case .strikethrough(let text):
                return text.rawDescription
            }
        }
        
        var description: String {
            switch self {
            case .underline(let text):
                return "~\(text.description)~"
            case .strikethrough(let text):
                return "~~\(text.description)~~"
            }
        }
        
        var debugDescription: String {
            switch self {
            case .underline(let text):
                return "underline(\(text.debugDescription))"
            case .strikethrough(let text):
                return "strikethrough(\(text.debugDescription))"
            }
        }
    }
    
    final class EmphasisTestTransformer: EmphasisTransformer {
        override public class var supportedEmphasis: [Emphasis] {
            return super.supportedEmphasis + [
                Emphasis(ch: "~", special: false, factory: { double, text in
                    return .custom(double ? LineEmphasis.strikethrough(text)
                                   : LineEmphasis.underline(text))
                })]
        }
    }
    
    final class DelimiterTestTransformer: DelimiterTransformer {
        override public class var emphasisChars: [Character] {
            return super.emphasisChars + ["~"]
        }
    }
    
    final class EmphasisTestMarkdownParser: MarkdownParser {
        override public class var defaultInlineTransformers: [InlineTransformer.Type] {
            return [DelimiterTestTransformer.self,
                    CodeLinkHtmlTransformer.self,
                    LinkTransformer.self,
                    EmphasisTestTransformer.self,
                    EscapeTransformer.self]
        }
        override public class var standard: EmphasisTestMarkdownParser {
            return self.singleton
        }
        private static let singleton: EmphasisTestMarkdownParser = EmphasisTestMarkdownParser()
    }
    
    private func parse(_ str: String) -> MarkdownBlock {
        return EmphasisTestMarkdownParser.standard.parse(str)
    }
    
    private func generateHtml(_ str: String) -> String {
        return HtmlGenerator().generate(doc: EmphasisTestMarkdownParser.standard.parse(str))
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func testExtendedDelimiters() throws {
        XCTAssertEqual(parse("~foo bar"),
                       document(paragraph(.delimiter("~", 1, .leftFlanking),
                                          .text("foo bar"))))
        XCTAssertEqual(parse("~~foo bar"),
                       document(paragraph(.delimiter("~", 2, .leftFlanking),
                                          .text("foo bar"))))
        XCTAssertEqual(parse("~~foo~ bar"),
                       document(paragraph(.delimiter("~", 1, .leftFlanking),
                                          custom(LineEmphasis.underline, .text("foo")),
                                          .text(" bar"))))
        XCTAssertEqual(parse("~~foo\\~ bar"),
                       document(paragraph(.delimiter("~", 2, .leftFlanking),
                                          .text("foo~ bar"))))
        XCTAssertEqual(parse("~~foo~~ bar"),
                       document(paragraph(custom(LineEmphasis.strikethrough, .text("foo")),
                                          .text(" bar"))))
        XCTAssertEqual(parse("ok ~~~foo~~~ bar"),
                       document(paragraph(.text("ok "),
                                          custom(LineEmphasis.underline,
                                                 custom(LineEmphasis.strikethrough, .text("foo"))),
                                          .text(" bar"))))
        XCTAssertEqual(parse("combined *~foo~* bar"),
                       document(paragraph(.text("combined "),
                                          emph(custom(LineEmphasis.underline, .text("foo"))),
                                          .text(" bar"))))
        XCTAssertEqual(parse("combined ~*foo bar*~"),
                       document(paragraph(.text("combined "),
                                          custom(LineEmphasis.underline, emph(.text("foo bar"))))))
        XCTAssertEqual(parse("combined *~foo~ bar*"),
                       document(paragraph(.text("combined "),
                                          emph(custom(LineEmphasis.underline, .text("foo")),
                                               .text(" bar")))))
    }
    
    func testExtendedDelimitersHtml() {
        XCTAssertEqual(generateHtml("one ~two~\n~~three~~ four"),
                       "<p>one <u>two</u>\n<s>three</s> four</p>")
        XCTAssertEqual(generateHtml("### Sub ~and~ heading ###\nAnd this is the text."),
                       "<h3>Sub <u>and</u> heading</h3>\n<p>And this is the text.</p>")
        XCTAssertEqual(generateHtml("expressive, ~~simple~, ~~and~~ ~elegant~~"),
                       "<p>expressive, <u><u>simple</u>, <s>and</s> <u>elegant</u></u></p>")
    }
}
