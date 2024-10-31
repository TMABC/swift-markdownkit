import Foundation

/// Markdown 块的枚举。此枚举定义了由 MarkdownKit 支持的 Markdown 的块结构，即抽象语法。
/// 内联文本的结构由`MarkdownText`结构体定义
public enum MarkdownBlock: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    case document(MarkdownBlocks)
    case blockquote(MarkdownBlocks)
    case list(Int?, Bool, MarkdownBlocks)
    case listItem(MarkdownListType, Bool, MarkdownBlocks)
    case paragraph(MarkdownText)
    case heading(Int, MarkdownText)
    case indentedCode(MarkdownLines)
    case fencedCode(String?, MarkdownLines)
    case htmlBlock(MarkdownLines)
    case referenceDef(String, Substring, MarkdownLines)
    case thematicBreak
    case table(MarkdownTableRow, MarkdownTableAlignments, MarkdownTableRows)
    case definitionList(MarkdownDefinitions)
    case custom(MarkdownCustomBlock)
    
    /// 返回块的描述作为字符串
    public var description: String {
        switch self {
        case .document(let blocks):
            return "document(\(MarkdownBlock.string(from: blocks))))"
        case .blockquote(let blocks):
            return "blockquote(\(MarkdownBlock.string(from: blocks))))"
        case .list(let start, let tight, let blocks):
            if let start = start {
                return "list(\(start), \(tight ? "tight" : "loose"), \(MarkdownBlock.string(from: blocks)))"
            } else {
                return "list(\(tight ? "tight" : "loose"), \(MarkdownBlock.string(from: blocks)))"
            }
        case .listItem(let type, let tight, let blocks):
            return "listItem(\(type), \(tight ? "tight" : "loose"), \(MarkdownBlock.string(from: blocks)))"
        case .paragraph(let text):
            return "paragraph(\(text.debugDescription))"
        case .heading(let level, let text):
            return "heading(\(level), \(text.debugDescription))"
        case .indentedCode(let lines):
            if let firstLine = lines.first {
                var code = firstLine.debugDescription
                for i in 1..<lines.count {
                    code = code + ", \(lines[i].debugDescription)"
                }
                return "indentedCode(\(code))"
            } else {
                return "indentedCode()"
            }
        case .fencedCode(let info, let lines):
            if let firstLine = lines.first {
                var code = firstLine.debugDescription
                for i in 1..<lines.count {
                    code = code + ", \(lines[i].debugDescription)"
                }
                if let info = info {
                    return "fencedCode(\(info), \(code))"
                } else {
                    return "fencedCode(\(code))"
                }
            } else {
                if let info = info {
                    return "fencedCode(\(info),)"
                } else {
                    return "fencedCode()"
                }
            }
        case .htmlBlock(let lines):
            if let firstLine = lines.first {
                var code = firstLine.debugDescription
                for i in 1..<lines.count {
                    code = code + ", \(lines[i].debugDescription)"
                }
                return "htmlBlock(\(code))"
            } else {
                return "htmlBlock()"
            }
        case .referenceDef(let label, let dest, let title):
            if let firstLine = title.first {
                var titleStr = firstLine.debugDescription
                for i in 1..<title.count {
                    titleStr = titleStr + ", \(title[i].debugDescription)"
                }
                return "referenceDef(\(label), \(dest), \(titleStr))"
            } else {
                return "referenceDef(\(label), \(dest))"
            }
        case .thematicBreak:
            return "thematicBreak"
        case .table(let header, let align, let rows):
            var res = MarkdownBlock.string(from: header) + ", "
            for a in align {
                res += a.description
            }
            for row in rows {
                res += ", " + MarkdownBlock.string(from: row)
            }
            return "table(\(res))"
        case .definitionList(let defs):
            var res = "definitionList"
            var sep = "("
            for def in defs {
                res += sep + def.description
                sep = "; "
            }
            return res + ")"
        case .custom(let customBlock):
            return customBlock.description
        }
    }
    
    /// Returns a debug description.
    public var debugDescription: String {
        switch self {
        case .custom(let customBlock):
            return customBlock.debugDescription
        default:
            return self.description
        }
    }
    
    /// Returns raw text for this block, i.e. ignoring all markup.
    public var string: String {
        switch self {
        case .document(let blocks):
            return blocks.string
        case .blockquote(let blocks):
            return blocks.string
        case .list(_, _, let blocks):
            return blocks.string
        case .listItem(_, _, let blocks):
            return blocks.string
        case .paragraph(let text):
            return text.string
        case .heading(_, let text):
            return text.string
        case .indentedCode(let lines):
            return lines.map { String($0) }.joined()
        case .fencedCode(_, let lines):
            return lines.map { String($0) }.joined(separator: "\n")
        case .htmlBlock(_):
            return ""
        case .referenceDef(_, _, let lines):
            return lines.map { String($0) }.joined(separator: " ")
        case .thematicBreak:
            return "\n\n"
        case .table(let headers, _, let rows):
            return headers.map { $0.string }.joined(separator: " | ") + "\n" +
            rows.map { $0.map { $0.string }.joined(separator: " | ") }
                .joined(separator: "\n")
        case .definitionList(let defs):
            return defs.map { $0.string }.joined(separator: "\n\n")
        case .custom(let obj):
            return obj.string
        }
    }
    
    fileprivate static func string(from blocks: MarkdownBlocks) -> String {
        var res = ""
        for block in blocks {
            if res.isEmpty {
                res = block.description
            } else {
                res = res + ", " + block.description
            }
        }
        return res
    }
    
    fileprivate static func string(from row: MarkdownTableRow) -> String {
        var res = "row("
        for cell in row {
            if res.isEmpty {
                res = cell.description
            } else {
                res = res + " | " + cell.description
            }
        }
        return res + ")"
    }
    
    /// 为两个块定义相等关系
    public static func == (lhs: MarkdownBlock, rhs: MarkdownBlock) -> Bool {
        switch (lhs, rhs) {
        case (.document(let lblocks), .document(let rblocks)):
            return lblocks == rblocks
        case (.blockquote(let lblocks), .blockquote(let rblocks)):
            return lblocks == rblocks
        case (.list(let ltype, let lt, let lblocks), .list(let rtype, let rt, let rblocks)):
            return ltype == rtype && lt == rt && lblocks == rblocks
        case (.listItem(let ltype, let lt, let lblocks), .listItem(let rtype, let rt, let rblocks)):
            return ltype == rtype && lt == rt && lblocks == rblocks
        case (.paragraph(let lstrs), .paragraph(let rstrs)):
            return lstrs == rstrs
        case (.heading(let ln, let lheadings), .heading(let rn, let rheadings)):
            return ln == rn && lheadings == rheadings
        case (.indentedCode(let lcode), .indentedCode(let rcode)):
            return lcode == rcode
        case (.fencedCode(let linfo, let lcode), .fencedCode(let rinfo, let rcode)):
            return linfo == rinfo && lcode == rcode
        case (.htmlBlock(let llines), .htmlBlock(let rlines)):
            return llines == rlines
        case (.referenceDef(let llab, let ldest, let lt), .referenceDef(let rlab, let rdest, let rt)):
            return llab == rlab && ldest == rdest && lt == rt
        case (.thematicBreak, .thematicBreak):
            return true
        case (.table(let lheader, let lalign, let lrows), .table(let rheader, let ralign, let rrows)):
            return lheader == rheader && lalign == ralign && lrows == rrows
        case (.definitionList(let ldefs), .definitionList(let rdefs)):
            return ldefs == rdefs
        case (.custom(let lblock), .custom(let rblock)):
            return lblock.equals(to: rblock)
        default:
            return false
        }
    }
}

/// Markdown 列表类型的枚举
public enum MarkdownListType: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    case bullet(Character)
    case ordered(Int, Character)
    
    public var startNumber: Int? {
        switch self {
        case .bullet(_):
            return nil
        case .ordered(let start, _):
            return start
        }
    }
    
    public func compatible(with other: MarkdownListType) -> Bool {
        switch (self, other) {
        case (.bullet(let lc), .bullet(let rc)):
            return lc == rc
        case (.ordered(_, let lc), .ordered(_, let rc)):
            return lc == rc
        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .bullet(let char):
            return "bullet(\(char.description))"
        case .ordered(let num, let delimiter):
            return "ordered(\(num), \(delimiter))"
        }
    }
    
    public var debugDescription: String {
        return self.description
    }
}

/// 行是文本数组
public typealias MarkdownTableRow = ContiguousArray<MarkdownText>
public typealias MarkdownTableRows = ContiguousArray<MarkdownTableRow>

/// 列对齐方式表示为`Alignment`枚举值的数组
public enum MarkdownTableAlignment: UInt, CustomStringConvertible, CustomDebugStringConvertible {
    case undefined = 0
    case left = 1
    case right = 2
    case center = 3
    
    public var description: String {
        switch self {
        case .undefined:
            return "-"
        case .left:
            return "L"
        case .right:
            return "R"
        case .center:
            return "C"
        }
    }
    
    public var debugDescription: String {
        return self.description
    }
}

public typealias MarkdownTableAlignments = ContiguousArray<MarkdownTableAlignment>

public struct MarkdownDefinition: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    public let item: MarkdownText
    public let descriptions: MarkdownBlocks
    
    public init(item: MarkdownText, descriptions: MarkdownBlocks) {
        self.item = item
        self.descriptions = descriptions
    }
    
    public var description: String {
        return "\(self.item.debugDescription) : \(MarkdownBlock.string(from: self.descriptions))"
    }
    
    public var debugDescription: String {
        return self.description
    }
    
    public var string: String {
        return "\(self.item.rawDescription): \(self.descriptions.string)"
    }
}

public typealias MarkdownDefinitions = ContiguousArray<MarkdownDefinition>
