import Foundation

/// `ExtendedMarkdownParser`对象用于解析表示为字符串的 Markdown 文本，使用 MarkdownKit 实现的对 CommonMark 规范的所有扩展。
///
/// `ExtendedMarkdownParser`对象本身定义了解析器的配置。
/// 从某种意义上说，它是无状态的，因为它可以用于解析许多输入字符串。
/// 这是通过`parse`函数完成的。`parse`返回一个表示给定输入字符串的 Markdown 文本的抽象语法树。
///
/// `ExtendedMarkdownParser`对象的`parse`方法将输入字符串的解析委托给两种类型的处理器：
/// 一个`BlockParser`对象和一个`InlineTransformer`对象。
/// `BlockParser`解析 Markdown 块结构，返回一个忽略内联标记的抽象语法树。
/// `InlineTransformer`对象用于解析 Markdown 块文本中的特定类型的内联标记，用表示标记的抽象语法树替换匹配的文本。
///
/// `ExtendedMarkdownParser`的`parse`方法分两个阶段进行：
/// 在第一阶段，通过“BlockParser”识别输入字符串的块结构
/// 在第二阶段，遍历块结构，并将原始文本中的标记替换为结构化表示
open class ExtendedMarkdownParser: MarkdownParser {
    
    /// 默认的块解析器列表。此列表的顺序很重要。
    override open class var defaultBlockParsers: [BlockParser.Type] {
        return self.blockParsers
    }
    
    private static let blockParsers: [BlockParser.Type] = MarkdownParser.headingParsers + [
        IndentedCodeBlockParser.self,
        FencedCodeBlockParser.self,
        HtmlBlockParser.self,
        LinkRefDefinitionParser.self,
        BlockquoteParser.self,
        ExtendedListItemParser.self,
        TableParser.self
    ]
    
    /// 定义了一个默认实现
    override open class var standard: ExtendedMarkdownParser {
        return self.singleton
    }
    
    private static let singleton: ExtendedMarkdownParser = ExtendedMarkdownParser()
    
    /// 子类中用于自定义文档解析的工厂方法。
    open override func documentParser(blockParsers: [BlockParser.Type],
                                      input: String) -> DocumentParser {
        return ExtendedDocumentParser(blockParsers: blockParsers, input: input)
    }
}
