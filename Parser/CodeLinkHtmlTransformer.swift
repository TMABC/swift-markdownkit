import Foundation

/// 一种内联转换器，它提取代码跨度、自动链接和 HTML 标签，并将它们转换为`code`、`autolinks`和`html`文本片段。
open class CodeLinkHtmlTransformer: InlineTransformer {
    public override func transform(_ text: MarkdownText) -> MarkdownText {
        var res: MarkdownText = MarkdownText()
        var iterator = text.makeIterator()
        var element = iterator.next()
    loop: while let fragment = element {
        switch fragment {
        case .delimiter("`", let n, []):
            var scanner = iterator
            var next = scanner.next()
            var count = 0
            while let lookahead = next {
                count += 1
                switch lookahead {
                case .delimiter("`", n, _):
                    var scanner2 = iterator
                    var code = ""
                    for _ in 1..<count {
                        code += scanner2.next()?.rawDescription ?? ""
                    }
                    res.append(fragment: .code(Substring(code)))
                    iterator = scanner
                    element = iterator.next()
                    continue loop
                case .delimiter(_, _, _), .text(_), .softLineBreak, .hardLineBreak:
                    next = scanner.next()
                default:
                    res.append(fragment: fragment)
                    element = iterator.next()
                    continue loop
                }
            }
            res.append(fragment: fragment)
            element = iterator.next()
        case .delimiter("<", let n, []):
            var scanner = iterator
            var next = scanner.next()
            var count = 0
            while let lookahead = next {
                count += 1
                switch lookahead {
                case .delimiter(">", n, _):
                    var scanner2 = iterator
                    var content = ""
                    for _ in 1..<count {
                        content += scanner2.next()?.rawDescription ?? ""
                    }
                    if isURI(content) {
                        res.append(fragment: .autolink(.uri, Substring(content)))
                        iterator = scanner
                        element = iterator.next()
                        continue loop
                    } else if isEmailAddress(content) {
                        res.append(fragment: .autolink(.email, Substring(content)))
                        iterator = scanner
                        element = iterator.next()
                        continue loop
                    } else if isHtmlTag(content) {
                        res.append(fragment: .html(Substring(content)))
                        iterator = scanner
                        element = iterator.next()
                        continue loop
                    }
                    next = scanner.next()
                case .delimiter(_, _, _), .text(_), .softLineBreak, .hardLineBreak:
                    next = scanner.next()
                default:
                    res.append(fragment: fragment)
                    element = iterator.next()
                    continue loop
                }
            }
            res.append(fragment: fragment)
            element = iterator.next()
        default:
            element = self.transform(fragment, from: &iterator, into: &res)
        }
    }
        return res
    }
}
