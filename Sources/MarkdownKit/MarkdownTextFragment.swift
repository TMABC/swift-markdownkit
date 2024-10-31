import Foundation

/// 在 MarkdownKit 中，带有标记的文本被表示为一系列`MarkdownTextFragment`对象的序列。每个`MarkdownTextFragment`枚举变体代表一种内联标记形式。由于标记可以任意嵌套，所以这是一个递归数据结构（通过结构体`MarkdownText`）。
public enum MarkdownTextFragment: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    case text(Substring)
    case code(Substring)
    case emph(MarkdownText)
    case strong(MarkdownText)
    case link(MarkdownText, String?, String?)
    case autolink(MarkdownAutolinkType, Substring)
    case image(MarkdownText, String?, String?)
    case html(Substring)
    case delimiter(Character, Int, DelimiterRunType)
    case softLineBreak
    case hardLineBreak
    case custom(MarkdownCustomTextFragment)
    
    /// 返回此`MarkdownTextFragment`对象的描述，以字符串形式呈现，
    /// 就像文本将以 Markdown 形式表示一样。
    public var description: String {
        switch self {
        case .text(let str):
            return str.description
        case .code(let str):
            return "`\(str.description)`"
        case .emph(let text):
            return "*\(text.description)*"
        case .strong(let text):
            return "**\(text.description)**"
        case .link(let text, let uri, let title):
            return "[\(text.description)](\(uri?.description ?? "") \(title?.description ?? ""))"
        case .autolink(_, let uri):
            return "<\(uri.description)>"
        case .image(let text, let uri, let title):
            return "![\(text.description)](\(uri?.description ?? "") \(title?.description ?? ""))"
        case .html(let tag):
            return "<\(tag.description)>"
        case .delimiter(let ch, let n, let type):
            var res = String(ch)
            for _ in 1..<n {
                res.append(ch)
            }
            return type.contains(.image) ? "!" + res : res
        case .softLineBreak:
            return "\n"
        case .hardLineBreak:
            return "\n"
        case .custom(let customTextFragment):
            return customTextFragment.description
        }
    }
    
    /// 返回此`MarkdownTextFragment`对象的原始描述，
    /// 即如果文本片段以 Markdown 形式表示，但忽略所有标记。
    public var rawDescription: String {
        switch self {
        case .text(let str):
            return str.description
        case .code(let str):
            return str.description
        case .emph(let text):
            return text.rawDescription
        case .strong(let text):
            return text.rawDescription
        case .link(let text, _, _):
            return text.rawDescription
        case .autolink(_, let uri):
            return uri.description
        case .image(let text, _, _):
            return text.rawDescription
        case .html(let tag):
            return "<\(tag.description)>"
        case .delimiter(let ch, let n, let type):
            var res = String(ch)
            for _ in 1..<n {
                res.append(ch)
            }
            return type.contains(.image) ? "!" + res : res
        case .softLineBreak:
            return " "
        case .hardLineBreak:
            return " "
        case .custom(let customTextFragment):
            return customTextFragment.rawDescription
        }
    }
    
    /// 返回此`MarkdownTextFragment`对象的原始描述，
    /// 作为一个字符串，其中所有标记都被忽略
    public var string: String {
        switch self {
        case .html(_):
            return ""
        case .delimiter(let ch, let n, _):
            var res = String(ch)
            for _ in 1..<n {
                res.append(ch)
            }
            return res
        default:
            return self.rawDescription
        }
    }
    
    /// 返回此`MarkdownTextFragment`对象的调试描述。
    public var debugDescription: String {
        switch self {
        case .text(let str):
            return "text(\(str.debugDescription))"
        case .code(let str):
            return "code(\(str.debugDescription))"
        case .emph(let text):
            return "emph(\(text.debugDescription))"
        case .strong(let text):
            return "strong(\(text.debugDescription))"
        case .link(let text, let uri, let title):
            return "link(\(text.debugDescription), " +
            "\(uri?.debugDescription ?? "nil"), \(title?.debugDescription ?? "nil"))"
        case .autolink(let type, let uri):
            return "autolink(\(type.debugDescription), \(uri.debugDescription))"
        case .image(let text, let uri, let title):
            return "image(\(text.debugDescription), " +
            "\(uri?.debugDescription ?? "nil"), \(title?.debugDescription ?? "nil"))"
        case .html(let tag):
            return "html(\(tag.debugDescription))"
        case .delimiter(let ch, let n, let runType):
            return "delimiter(\(ch.debugDescription), \(n), \(runType))"
        case .softLineBreak:
            return "softLineBreak"
        case .hardLineBreak:
            return "hardLineBreak"
        case .custom(let customTextFragment):
            return customTextFragment.debugDescription
        }
    }
    
    /// 比较两个给定的文本片段是否相等
    public static func == (lhs: MarkdownTextFragment, rhs: MarkdownTextFragment) -> Bool {
        switch (lhs, rhs) {
        case (.text(let llstr), .text(let rstr)):
            return llstr == rstr
        case (.code(let lstr), .code(let rstr)):
            return lstr == rstr
        case (.emph(let ltext), .emph(let rtext)):
            return ltext == rtext
        case (.strong(let ltext), .strong(let rtext)):
            return ltext == rtext
        case (.link(let ltext, let ls1, let ls2), .link(let rtext, let rs1, let rs2)):
            return ltext == rtext && ls1 == rs1 && ls2 == rs2
        case (.autolink(let ltype, let lstr), .autolink(let rtype, let rstr)):
            return ltype == rtype && lstr == rstr
        case (.image(let ltext, let ls1, let ls2), .image(let rtext, let rs1, let rs2)):
            return ltext == rtext && ls1 == rs1 && ls2 == rs2
        case (.html(let lstr), .html(let rstr)):
            return lstr == rstr
        case (.delimiter(let lch, let ln, let ld), .delimiter(let rch, let rn, let rd)):
            return lch == rch && ln == rn && ld == rd
        case (.softLineBreak, .softLineBreak):
            return true
        case (.hardLineBreak, .hardLineBreak):
            return true
        case (.custom(let lctf), .custom(let rctf)):
            return lctf.equals(to: rctf)
        default:
            return false
        }
    }
}

/// 表示自动链接类型。
public enum MarkdownAutolinkType: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    case uri
    case email
    
    public var description: String {
        switch self {
        case .uri:
            return "uri"
        case .email:
            return "email"
        }
    }
    
    public var debugDescription: String {
        return self.description
    }
}

/// 行是子字符串数组
public typealias MarkdownLines = ContiguousArray<Substring>

/// 每个分隔符运行被分类为一组类型，这些类型通过`DelimiterRunType`结构体来表示。
public struct DelimiterRunType: OptionSet, CustomStringConvertible {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let leftFlanking = DelimiterRunType(rawValue: 1 << 0)
    public static let rightFlanking = DelimiterRunType(rawValue: 1 << 1)
    public static let leftPunctuation = DelimiterRunType(rawValue: 1 << 2)
    public static let rightPunctuation = DelimiterRunType(rawValue: 1 << 3)
    public static let escaped = DelimiterRunType(rawValue: 1 << 4)
    public static let image = DelimiterRunType(rawValue: 1 << 5)
    
    public var description: String {
        var res = ""
        if self.rawValue & 0x1 == 0x1 {
            res = "\(res)\(res.isEmpty ? "" : ", ")leftFlanking"
        }
        if self.rawValue & 0x2 == 0x2 {
            res = "\(res)\(res.isEmpty ? "" : ", ")rightFlanking"
        }
        if self.rawValue & 0x4 == 0x4 {
            res = "\(res)\(res.isEmpty ? "" : ", ")leftPunctuation"
        }
        if self.rawValue & 0x8 == 0x8 {
            res = "\(res)\(res.isEmpty ? "" : ", ")rightPunctuation"
        }
        if self.rawValue & 0x10 == 0x10 {
            res = "\(res)\(res.isEmpty ? "" : ", ")escaped"
        }
        if self.rawValue & 0x20 == 0x20 {
            res = "\(res)\(res.isEmpty ? "" : ", ")image"
        }
        return "[\(res)]"
    }
}
