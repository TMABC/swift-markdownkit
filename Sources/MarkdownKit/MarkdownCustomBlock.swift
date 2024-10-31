import Foundation

/// 协议`CustomBlock`定义了外部实现（即不是由 MarkdownKit 框架实现）的自定义 Markdown 元素的接口。
public protocol MarkdownCustomBlock: CustomStringConvertible, CustomDebugStringConvertible {
    var string: String { get }
    func equals(to other: MarkdownCustomBlock) -> Bool
    func parse(via parser: InlineParser) -> MarkdownBlock
    func generateHtml(via htmlGen: HtmlGenerator, tight: Bool) -> String
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    func generateHtml(via htmlGen: HtmlGenerator,
                      and attGen: AttributedStringGenerator?,
                      tight: Bool) -> String
#endif
}

extension MarkdownCustomBlock {
    /// 默认情况下，自定义块没有任何原始字符串内容
    public var string: String {
        return ""
    }
}
