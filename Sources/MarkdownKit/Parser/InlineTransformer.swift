import Foundation

/// 类`InlineTransformer`定义了一个插件框架，
/// 该框架将带有 Markdown 标记的给定无结构或半结构化文本转换为使用`TextFragment`对象的结构化表示。
/// MarkdownKit 为每一类受支持的内联标记实现一个单独的内联转换器插件。
open class InlineTransformer {
    
    public unowned let owner: InlineParser
    
    required public init(owner: InlineParser) {
        self.owner = owner
    }
    
    open func transform(_ text: MarkdownText) -> MarkdownText {
        var res: MarkdownText = MarkdownText()
        var iterator = text.makeIterator()
        var element = iterator.next()
        while let fragment = element {
            element = self.transform(fragment, from: &iterator, into: &res)
        }
        return res
    }
    
    open func transform(_ fragment: MarkdownTextFragment,
                        from iterator: inout MarkdownText.Iterator,
                        into res: inout MarkdownText) -> MarkdownTextFragment? {
        switch fragment {
        case .text(_):
            res.append(fragment: fragment)
        case .code(_):
            res.append(fragment: fragment)
        case .emph(let inner):
            res.append(fragment: .emph(self.transform(inner)))
        case .strong(let inner):
            res.append(fragment: .strong(self.transform(inner)))
        case .link(let inner, let uri, let title):
            res.append(fragment: .link(self.transform(inner), uri, title))
        case .autolink(_, _):
            res.append(fragment: fragment)
        case .image(let inner, let uri, let title):
            res.append(fragment: .image(self.transform(inner), uri, title))
        case .html(_):
            res.append(fragment: fragment)
        case .delimiter(_, _, _):
            res.append(fragment: fragment)
        case .softLineBreak, .hardLineBreak:
            res.append(fragment: fragment)
        case .custom(let customTextFragment):
            res.append(fragment: customTextFragment.transform(via: self))
        }
        return iterator.next()
    }
}
