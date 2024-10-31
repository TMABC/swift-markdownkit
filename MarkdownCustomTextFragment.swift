import Foundation

/// 协议`CustomTextFragment`定义了外部实现（即不是由 MarkdownKit 框架实现）的自定义 Markdown 文本片段的接口
public protocol MarkdownCustomTextFragment: CustomStringConvertible, CustomDebugStringConvertible {
    func equals(to other: MarkdownCustomTextFragment) -> Bool
    func transform(via transformer: InlineTransformer) -> MarkdownTextFragment
    func generateHtml(via htmlGen: HtmlGenerator) -> String
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    func generateHtml(via htmlGen: HtmlGenerator, and attrGen: AttributedStringGenerator?) -> String
#endif
    var rawDescription: String { get }
}
