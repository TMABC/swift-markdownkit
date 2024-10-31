import Foundation

/// “内联解析器（InlineParser）”实现了给定一系列“内联转换器（InlineTransformer）”类作为其配置的 Markdown 内联文本标记解析。“内联解析器（InlineParser）”对象无状态，可重复用于解析许多 Markdown 块的内联文本。
open class InlineParser {
    
    /// 实现内联解析功能的内联转换器序列。
    private var inlineTransformers: [InlineTransformer]
    
    /// 输入文档块
    private let block: MarkdownBlock
    
    /// 链接引用声明
    public private(set) var linkRefDef: [String : (String, String?)]
    
    /// Initializer
    init(inlineTransformers: [InlineTransformer.Type], input: MarkdownBlock) {
        self.block = input
        self.linkRefDef = [:]
        self.inlineTransformers = []
        for transformerType in inlineTransformers {
            self.inlineTransformers.append(transformerType.init(owner: self))
        }
    }
    
    /// 遍历输入块并将所有内联转换器应用于所有文本。
    open func parse() -> MarkdownBlock {
        // First, collect all link reference definitions
        self.collectLinkRefDef(self.block)
        // Second, apply inline transformers
        return self.parse(self.block)
    }
    
    /// 遍历一个 Markdown 块，并将链接引用定义输入到`linkRefDef`中。
    public func collectLinkRefDef(_ block: MarkdownBlock) {
        switch block {
        case .document(let blocks):
            self.collectLinkRefDef(blocks)
        case .blockquote(let blocks):
            self.collectLinkRefDef(blocks)
        case .list(_, _, let blocks):
            self.collectLinkRefDef(blocks)
        case .listItem(_, _, let blocks):
            self.collectLinkRefDef(blocks)
        case .referenceDef(let label, let dest, let title):
            if title.isEmpty {
                let canonical = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                self.linkRefDef[canonical] = (String(dest), nil)
            } else {
                var str = ""
                for line in title {
                    str += line.description
                }
                self.linkRefDef[label] = (String(dest), str)
            }
        default:
            break
        }
    }
    
    /// 遍历一组 Markdown 块，并将链接引用定义输入到`linkRefDef`中。
    public func collectLinkRefDef(_ blocks: MarkdownBlocks) {
        for block in blocks {
            self.collectLinkRefDef(block)
        }
    }
    
    /// 解析一个 Markdown 块，并返回一个新的块，其中所有内联文本标记都使用`TextFragment`对象表示。
    open func parse(_ block: MarkdownBlock) -> MarkdownBlock {
        switch block {
        case .document(let blocks):
            return .document(self.parse(blocks))
        case .blockquote(let blocks):
            return .blockquote(self.parse(blocks))
        case .list(let start, let tight, let blocks):
            return .list(start, tight, self.parse(blocks))
        case .listItem(let type, let tight, let blocks):
            return .listItem(type, tight, self.parse(blocks))
        case .paragraph(let lines):
            return .paragraph(self.transform(lines))
        case .thematicBreak:
            return .thematicBreak
        case .heading(let level, let lines):
            return .heading(level, self.transform(lines))
        case .indentedCode(let lines):
            return .indentedCode(lines)
        case .fencedCode(let info, let lines):
            return .fencedCode(info, lines)
        case .htmlBlock(let lines):
            return .htmlBlock(lines)
        case .referenceDef(let label, let dest, let title):
            return .referenceDef(label, dest, title)
        case .table(let header, let align, let rows):
            return .table(self.transform(header), align, self.transform(rows))
        case .definitionList(let defs):
            return .definitionList(self.transform(defs))
        case .custom(let customBlock):
            return customBlock.parse(via: self)
        }
    }
    
    /// 解析一系列 Markdown 块，并返回一个新的序列，其中所有内联文本标记都使用`TextFragment`对象表示。
    public func parse(_ blocks: MarkdownBlocks) -> MarkdownBlocks {
        var res: MarkdownBlocks = []
        for block in blocks {
            res.append(self.parse(block))
        }
        return res
    }
    
    /// 将原始 Markdown 文本进行转换，并返回一个新的`Text`对象，在该对象中，所有内联标记都使用`TextFragment`对象表示
    public func transform(_ text: MarkdownText) -> MarkdownText {
        var res = text
        for transformer in self.inlineTransformers {
            res = transformer.transform(res)
        }
        return res
    }
    
    /// 转换原始的 Markdown 行，并返回一个新的`MarkdownTableRow`对象，其中所有内联标记都使用`TextFragment`对象表示
    public func transform(_ row: MarkdownTableRow) -> MarkdownTableRow {
        var res = MarkdownTableRow()
        for cell in row {
            res.append(self.transform(cell))
        }
        return res
    }
    
    /// 转换原始的 Markdown 表格，并返回一个新的`MarkdownTableRows`对象，其中所有内联标记都使用`TextFragment`对象表示
    public func transform(_ rows: MarkdownTableRows) -> MarkdownTableRows {
        var res = MarkdownTableRows()
        for row in rows {
            res.append(self.transform(row))
        }
        return res
    }
    
    public func transform(_ defs: MarkdownDefinitions) -> MarkdownDefinitions {
        var res = MarkdownDefinitions()
        for def in defs {
            res.append(MarkdownDefinition(item: self.transform(def.item),
                                  descriptions: self.parse(def.descriptions)))
        }
        return res
    }
}
