import Foundation

/// `DocumentParser`实现了针对一系列`BlockParsers`和一个输入字符串的 Markdown 块解析。`DocumentParser`对象是有状态的，并且只能用于解析单个 Markdown 格式的文档/字符串。
open class ExtendedDocumentParser: DocumentParser {
    
    /// 将给定的`Block`对象数组规范化，并以`Blocks`对象的形式返回
    open override func bundle(blocks: [MarkdownBlock]) -> MarkdownBlocks {
        // 首先，像以前一样捆绑列表
        let bundled = super.bundle(blocks: blocks)
        if bundled.count < 2 {
            return bundled
        }
        // 接下来，将描述列表及其对应的项目捆绑到定义列表中。
        var res: MarkdownBlocks = []
        var definitions: MarkdownDefinitions = []
        var i = 1
        while i < bundled.count {
            guard case .paragraph(let text) = bundled[i - 1],
                  case .list(_, _, let listItems) = bundled[i],
                  case .some(.listItem(.bullet(":"), _, _)) = listItems.first else {
                if definitions.count > 0 {
                    res.append(.definitionList(definitions))
                    definitions.removeAll()
                }
                res.append(bundled[i - 1])
                i += 1
                continue
            }
            definitions.append(MarkdownDefinition(item: text, descriptions: listItems))
            i += 2
        }
        if definitions.count > 0 {
            res.append(.definitionList(definitions))
            definitions.removeAll()
        }
        if i < bundled.count + 1 {
            res.append(bundled[i - 1])
        }
        return res
    }
}
