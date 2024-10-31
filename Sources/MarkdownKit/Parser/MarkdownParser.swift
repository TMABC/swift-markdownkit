import Foundation

/// `MarkdownParser`对象用于解析表示为字符串的 Markdown 文本。
/// `MarkdownParser`对象本身定义了解析器的配置。
/// 从某种意义上说，它是无状态的，因为它可以用于解析许多输入字符串。
/// 这是通过`parse`函数完成的。
/// `parse`为给定的输入字符串返回表示 Markdown 文本的抽象语法树。
///
/// `MarkdownParser`对象的`parse`方法将输入字符串的解析委托给两种类型的处理器：
/// 一个`BlockParser`对象和一个`InlineTransformer`对象。
/// `BlockParser`解析 Markdown 块结构，返回一个抽象语法树，忽略内联标记。
/// `InlineTransformer`对象用于解析 Markdown 块文本中的特定类型的内联标记，
/// 用表示标记的抽象语法树替换匹配的文本。
///
/// `MarkdownParser`的`parse`方法分两个阶段操作：
/// 在第一阶段，通过`BlockParser`识别输入字符串的块结构。
/// 在第二阶段，遍历块结构，并将原始文本中的标记替换为结构化表示。
open class MarkdownParser {
    
    ///默认的块解析器列表。此列表的顺序很重要。
    open class var defaultBlockParsers: [BlockParser.Type] {
        return self.blockParsers
    }
    
    private static let blockParsers: [BlockParser.Type] = MarkdownParser.headingParsers + [
        IndentedCodeBlockParser.self,
        FencedCodeBlockParser.self,
        HtmlBlockParser.self,
        LinkRefDefinitionParser.self,
        BlockquoteParser.self,
        ListItemParser.self
    ]
    
    public static let headingParsers: [BlockParser.Type] = [
        AtxHeadingParser.self,
        SetextHeadingParser.self,
        ThematicBreakParser.self
    ]
    
    /// 默认的内联转换器列表。此列表的顺序很重要。
    open class var defaultInlineTransformers: [InlineTransformer.Type] {
        return self.inlineTransformers
    }
    
    private static let inlineTransformers: [InlineTransformer.Type] = [
        DelimiterTransformer.self,
        CodeLinkHtmlTransformer.self,
        LinkTransformer.self,
        EmphasisTransformer.self,
        EscapeTransformer.self
    ]
    
    /// 定义了一个默认实现
    open class var standard: MarkdownParser {
        return self.singleton
    }
    
    private static let singleton: MarkdownParser = MarkdownParser()
    
    /// 自定义的块解析器列表；如果通过构造函数提供此列表，它将覆盖`defaultBlockParsers`。
    private let customBlockParsers: [BlockParser.Type]?
    
    /// 自定义的内联转换器列表；如果通过构造函数提供此列表，它将覆盖`defaultInlineTransformers`。
    private let customInlineTransformers: [InlineTransformer.Type]?
    
    /// 块解析被委托给一个有状态的`DocumentParser`对象，该对象实现了一种协议，用于调用其初始化器根据`blockParsers`参数中提供的类型创建的`BlockParser`对象。
    public func documentParser(input: String) -> DocumentParser {
        return self.documentParser(blockParsers: self.customBlockParsers ??
                                   type(of: self).defaultBlockParsers,
                                   input: input)
    }
    
    /// 用于在子类中自定义文档解析的工厂方法
    open func documentParser(
        blockParsers: [BlockParser.Type],
        input: String
    ) -> DocumentParser {
        return DocumentParser(
            blockParsers: blockParsers,
            input: input
        )
    }
    
    /// 内联解析是通过无状态的`InlineParser`对象执行的，该对象实现了一种协议，用于调用`InlineTransformer`对象。由于内联解析器是无状态的，因此会延迟创建单个对象，并在解析所有输入时重复使用。
    public func inlineParser(input: MarkdownBlock) -> InlineParser {
        return self.inlineParser(
            inlineTransformers: self.customInlineTransformers ??
                                 type(of: self).defaultInlineTransformers,
            input: input
        )
    }
    
    /// 用于在子类中自定义内联解析的工厂方法
    open func inlineParser(
        inlineTransformers: [InlineTransformer.Type],
        input: MarkdownBlock
    ) -> InlineParser {
        return InlineParser(
            inlineTransformers: inlineTransformers,
            input: input
        )
    }
    
    /// `MarkdownParser`对象的构造函数；它接受一个块解析器列表、一个内联转换器列表以及一个输入字符串作为参数。
    public init(blockParsers: [BlockParser.Type]? = nil,
                inlineTransformers: [InlineTransformer.Type]? = nil) {
        self.customBlockParsers = blockParsers
        self.customInlineTransformers = inlineTransformers
    }
    
    /// 调用解析器并返回 Markdown 语法的抽象语法树
    /// 如果 `blockOnly` 设置为 `true`（默认为 `false`），则仅调用块解析器，不执行内联解析。
    public func parse(_ str: String, blockOnly: Bool = false) -> MarkdownBlock {
        let doc = self.documentParser(input: str).parse()
        if blockOnly {
            return doc
        } else {
            return self.inlineParser(input: doc).parse()
        }
    }
}
