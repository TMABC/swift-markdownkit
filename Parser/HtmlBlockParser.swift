import Foundation

///`HtmlBlockParser`是一个块解析器，它解析 HTML 块并以`Block`枚举的`htmlBlock`情况的形式返回它们。`HtmlBlockParser`在`HtmlBlockParserPlugin`对象的帮助下实现这一点，它将各种受支持的 HTML 块变体的检测委托给这些对象。
open class HtmlBlockParser: BlockParser {
    
    /// 受支持的 HTML 块解析器插件类型列表；
    /// 在`HtmlBlockParser`的子类中重写此计算属性以创建自定义版本。
    open class var supportedParsers: [HtmlBlockParserPlugin.Type] {
        return [ScriptBlockParserPlugin.self,
                CommentBlockParserPlugin.self,
                ProcessingInstructionBlockParserPlugin.self,
                DeclarationBlockParserPlugin.self,
                CdataBlockParserPlugin.self,
                HtmlTagBlockParserPlugin.self
        ]
    }
    
    /// HTML 块解析器插件
    private var htmlParsers: [HtmlBlockParserPlugin]
    
    /// 默认初始化器
    public required init(docParser: DocumentParser) {
        self.htmlParsers = []
        for parserType in type(of: self).supportedParsers {
            self.htmlParsers.append(parserType.init())
        }
        super.init(docParser: docParser)
    }
    
    open override func parse() -> ParseResult {
        guard self.shortLineIndent, self.line[self.contentStartIndex] == "<" else {
            return .none
        }
        var cline = self.line[self.contentStartIndex..<self.contentEndIndex].lowercased()
        for parser in self.htmlParsers {
            if parser.startCondition(cline) {
                var lines: MarkdownLines = [self.line]
                while !self.finished && !parser.endCondition(cline) {
                    self.readNextLine()
                    if !self.finished {
                        if (parser.emptyLineTerminator && self.lineEmpty) || self.lazyContinuation {
                            break
                        } else {
                            lines.append(self.line)
                        }
                    }
                    cline = self.lineEmpty
                    ? "" : self.line[self.contentStartIndex..<self.contentEndIndex].lowercased()
                }
                if !self.finished && !self.lazyContinuation {
                    self.readNextLine()
                }
                if let last = lines.last, last.isEmpty {
                    lines.removeLast()
                }
                return .block(.htmlBlock(lines))
            }
        }
        return .none
    }
}

/// 抽象 HTML 块解析器插件根类，定义了插件的接口。
open class HtmlBlockParserPlugin {
    
    public required init() {}
    
    public func isWhitespace(_ ch: Character) -> Bool {
        switch ch {
        case " ", "\t", "\n", "\r", "\r\n", "\u{b}", "\u{c}":
            return true
        default:
            return false
        }
    }
    
    open func line(_ line: String,
                   at: String.Index,
                   startsWith str: String,
                   endsWith suffix: String? = nil,
                   htmlTagSuffix: Bool = true) -> Bool {
        var strIndex: String.Index = str.startIndex
        var index = at
        while strIndex < str.endIndex {
            guard index < line.endIndex, line[index] == str[strIndex] else {
                return false
            }
            strIndex = str.index(after: strIndex)
            index = line.index(after: index)
        }
        if htmlTagSuffix {
            guard index < line.endIndex else {
                return true
            }
            switch line[index] {
            case " ", "\t", "\u{b}", "\u{c}":
                return true
            case "\n", "\r", "\r\n":
                return true
            case ">":
                return true
            default:
                if let end = suffix {
                    strIndex = end.startIndex
                    while strIndex < end.endIndex {
                        guard index < line.endIndex, line[index] == end[strIndex] else {
                            return false
                        }
                        strIndex = end.index(after: strIndex)
                        index = line.index(after: index)
                    }
                    return true
                }
                return false
            }
        } else {
            return true
        }
    }
    
    open func startCondition(_ line: String) -> Bool {
        return false
    }
    
    open func endCondition(_ line: String) -> Bool {
        return false
    }
    
    open var emptyLineTerminator: Bool {
        return false
    }
}

public final class ScriptBlockParserPlugin: HtmlBlockParserPlugin {
    
    public override func startCondition(_ line: String) -> Bool {
        return self.line(line, at: line.startIndex, startsWith: "<script") ||
        self.line(line, at: line.startIndex, startsWith: "<pre") ||
        self.line(line, at: line.startIndex, startsWith: "<style")
    }
    
    public override func endCondition(_ line: String) -> Bool {
        return line.contains("</script>") ||
        line.contains("</pre>") ||
        line.contains("</style>")
    }
}

public final class CommentBlockParserPlugin: HtmlBlockParserPlugin {
    
    public override func startCondition(_ line: String) -> Bool {
        return self.line(line, at: line.startIndex, startsWith: "<!--", htmlTagSuffix: false)
    }
    
    public override func endCondition(_ line: String) -> Bool {
        return line.contains("-->")
    }
}

public final class ProcessingInstructionBlockParserPlugin: HtmlBlockParserPlugin {
    
    public override func startCondition(_ line: String) -> Bool {
        return self.line(line, at: line.startIndex, startsWith: "<?", htmlTagSuffix: false)
    }
    
    public override func endCondition(_ line: String) -> Bool {
        return line.contains("?>")
    }
}

public final class DeclarationBlockParserPlugin: HtmlBlockParserPlugin {
    
    public override func startCondition(_ line: String) -> Bool {
        var index: String.Index = line.startIndex
        guard index < line.endIndex && line[index] == "<" else {
            return false
        }
        index = line.index(after: index)
        guard index < line.endIndex && line[index] == "!" else {
            return false
        }
        index = line.index(after: index)
        guard index < line.endIndex else {
            return false
        }
        switch line[index] {
        case "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
            "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z":
            return true
        default:
            return false
        }
    }
    
    public override func endCondition(_ line: String) -> Bool {
        return line.contains(">")
    }
}

public final class CdataBlockParserPlugin: HtmlBlockParserPlugin {
    
    public override func startCondition(_ line: String) -> Bool {
        return self.line(line, at: line.startIndex, startsWith: "<![CDATA[", htmlTagSuffix: false)
    }
    
    public override func endCondition(_ line: String) -> Bool {
        return line.contains("]]>")
    }
}

public final class HtmlTagBlockParserPlugin: HtmlBlockParserPlugin {
    final let htmlTags = ["address", "article", "aside", "base", "basefont", "blockquote", "body",
                          "caption", "center", "col", "colgroup", "dd", "details", "dialog", "dir",
                          "div", "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form",
                          "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header",
                          "hr", "html", "iframe", "legend", "li", "link", "main", "menu", "menuitem",
                          "nav", "noframes", "ol", "optgroup", "option", "p", "param", "section",
                          "source", "summary", "table", "tbody", "td", "tfoot", "th", "thead",
                          "title", "tr", "track", "ul"]
    
    public override func startCondition(_ line: String) -> Bool {
        var index = line.startIndex
        guard index < line.endIndex && line[index] == "<" else {
            return false
        }
        index = line.index(after: index)
        if index < line.endIndex && line[index] == "/" {
            index = line.index(after: index)
        }
        for htmlTag in self.htmlTags {
            if self.line(line, at: index, startsWith: htmlTag, endsWith: "/>") {
                return true
            }
        }
        return false
    }
    
    public override var emptyLineTerminator: Bool {
        return true
    }
}
