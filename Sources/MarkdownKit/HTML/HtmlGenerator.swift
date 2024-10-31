import Foundation

/// `HtmlGenerator`提供了将 Markdown 块转换为 HTML 的功能。其实现是可扩展的，允许`HtmlGenerator`的子类覆盖单个 Markdown 结构如何转换为 HTML
open class HtmlGenerator {
    
    /// 默认的`HtmlGenerator`实现。
    public static let standard = HtmlGenerator()
    
    public init() {}
    
    /// `generate`接受一个表示 Markdown 文档的块，并以字符串形式返回相应的 HTML 表示
    open func generate(doc: MarkdownBlock) -> String {
        guard case .document(let blocks) = doc else {
            preconditionFailure("cannot generate HTML from \(doc)")
        }
        return self.generate(blocks: blocks)
    }
    
    open func generate(blocks: MarkdownBlocks, tight: Bool = false) -> String {
        var res = ""
        for block in blocks {
            res += self.generate(block: block, tight: tight)
        }
        return res
    }
    
    open func generate(block: MarkdownBlock, tight: Bool = false) -> String {
        switch block {
        case .document(_):
            preconditionFailure("broken block \(block)")
        case .blockquote(let blocks):
            return "<blockquote>\n" + self.generate(blocks: blocks) + "</blockquote>\n"
        case .list(let start, let tight, let blocks):
            if let startNumber = start {
                return "<ol start=\"\(startNumber)\">\n" +
                self.generate(blocks: blocks, tight: tight) +
                "</ol>\n"
            } else {
                return "<ul>\n" + self.generate(blocks: blocks, tight: tight) + "</ul>\n"
            }
        case .listItem(_, _, let blocks):
            if tight, let text = blocks.text {
                return "<li>" + self.generate(text: text) + "</li>\n"
            } else {
                return "<li>" + self.generate(blocks: blocks) + "</li>\n"
            }
        case .paragraph(let text):
            return "<p>" + self.generate(text: text) + "</p>\n"
        case .heading(let n, let text):
            let tag = "h\(n > 0 && n < 7 ? n : 1)>"
            return "<\(tag)\(self.generate(text: text))</\(tag)\n"
        case .indentedCode(let lines):
            return "<pre><code>" +
            self.generate(lines: lines).encodingPredefinedXmlEntities() +
            "</code></pre>\n"
        case .fencedCode(let lang, let lines):
            if let language = lang {
                return "<pre><code class=\"\(language)\">" +
                self.generate(lines: lines, separator: "").encodingPredefinedXmlEntities() +
                "</code></pre>\n"
            } else {
                return "<pre><code>" +
                self.generate(lines: lines, separator: "").encodingPredefinedXmlEntities() +
                "</code></pre>\n"
            }
        case .htmlBlock(let lines):
            return self.generate(lines: lines)
        case .referenceDef(_, _, _):
            return ""
        case .thematicBreak:
            return "<hr />\n"
        case .table(let header, let align, let rows):
            var tagsuffix: [String] = []
            for a in align {
                switch a {
                case .undefined:
                    tagsuffix.append(">")
                case .left:
                    tagsuffix.append(" align=\"left\">")
                case .right:
                    tagsuffix.append(" align=\"right\">")
                case .center:
                    tagsuffix.append(" align=\"center\">")
                }
            }
            var html = "<table><thead><tr>\n"
            var i = 0
            for head in header {
                html += "<th\(tagsuffix[i])\(self.generate(text: head))</th>"
                i += 1
            }
            html += "\n</tr></thead><tbody>\n"
            for row in rows {
                html += "<tr>"
                i = 0
                for cell in row {
                    html += "<td\(tagsuffix[i])\(self.generate(text: cell))</td>"
                    i += 1
                }
                html += "</tr>\n"
            }
            html += "</tbody></table>\n"
            return html
        case .definitionList(let defs):
            var html = "<dl>\n"
            for def in defs {
                html += "<dt>" + self.generate(text: def.item) + "</dt>\n"
                for descr in def.descriptions {
                    if case .listItem(_, _, let blocks) = descr {
                        if blocks.count == 1,
                           case .paragraph(let text) = blocks.first! {
                            html += "<dd>" + self.generate(text: text) + "</dd>\n"
                        } else {
                            html += "<dd>" + self.generate(blocks: blocks) + "</dd>\n"
                        }
                    }
                }
            }
            html += "</dl>\n"
            return html
        case .custom(let customBlock):
            return customBlock.generateHtml(via: self, tight: tight)
        }
    }
    
    open func generate(text: MarkdownText) -> String {
        var res = ""
        for fragment in text {
            res += self.generate(textFragment: fragment)
        }
        return res
    }
    
    open func generate(textFragment fragment: MarkdownTextFragment) -> String {
        switch fragment {
        case .text(let str):
            return String(str).decodingNamedCharacters().encodingPredefinedXmlEntities()
        case .code(let str):
            return "<code>" + String(str).encodingPredefinedXmlEntities() + "</code>"
        case .emph(let text):
            return "<em>" + self.generate(text: text) + "</em>"
        case .strong(let text):
            return "<strong>" + self.generate(text: text) + "</strong>"
        case .link(let text, let uri, let title):
            let titleAttr = title == nil ? "" : " title=\"\(title!)\""
            return "<a href=\"\(uri ?? "")\"\(titleAttr)>" + self.generate(text: text) + "</a>"
        case .autolink(let type, let str):
            switch type {
            case .uri:
                return "<a href=\"\(str)\">\(str)</a>"
            case .email:
                return "<a href=\"mailto:\(str)\">\(str)</a>"
            }
        case .image(let text, let uri, let title):
            let titleAttr = title == nil ? "" : " title=\"\(title!)\""
            if let uri = uri {
                return "<img src=\"\(uri)\" alt=\"\(text.rawDescription)\"\(titleAttr)/>"
            } else {
                return self.generate(text: text)
            }
        case .html(let tag):
            return "<\(tag.description)>"
        case .delimiter(let ch, let n, _):
            let char: String
            switch ch {
            case "<":
                char = "&lt;"
            case ">":
                char = "&gt;"
            default:
                char = String(ch)
            }
            var res = char
            for _ in 1..<n {
                res.append(char)
            }
            return res
        case .softLineBreak:
            return "\n"
        case .hardLineBreak:
            return "<br/>"
        case .custom(let customTextFragment):
            return customTextFragment.generateHtml(via: self)
        }
    }
    
    open func generate(lines: MarkdownLines, separator: String = "\n") -> String {
        var res = ""
        for line in lines {
            if res.isEmpty {
                res = String(line)
            } else {
                res += separator + line
            }
        }
        return res
    }
}
