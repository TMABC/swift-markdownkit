import Foundation

/// 一种内联转换器，可去除反斜杠转义。
open class EscapeTransformer: InlineTransformer {
    
    public override func transform(_ fragment: MarkdownTextFragment,
                                   from iterator: inout MarkdownText.Iterator,
                                   into res: inout MarkdownText) -> MarkdownTextFragment? {
        switch fragment {
        case .text(let str):
            res.append(fragment: .text(self.resolveEscapes(str)))
        case .link(let inner, let uri, let title):
            res.append(fragment: .link(self.transform(inner), uri, self.resolveEscapes(title)))
        case .image(let inner, let uri, let title):
            res.append(fragment: .image(self.transform(inner), uri, self.resolveEscapes(title)))
        default:
            return super.transform(fragment, from: &iterator, into: &res)
        }
        return iterator.next()
    }
    
    private func resolveEscapes(_ str: String?) -> String? {
        if let str = str {
            return String(self.resolveEscapes(Substring(str)))
        } else {
            return nil
        }
    }
    
    private func resolveEscapes(_ str: Substring) -> Substring {
        guard !str.isEmpty else {
            return str
        }
        var res: String? = nil
        var i = str.startIndex
        while i < str.endIndex {
            if str[i] == "\\" {
                if res == nil {
                    res = String(str[str.startIndex..<i])
                }
                i = str.index(after: i)
                guard i < str.endIndex else {
                    break
                }
            }
            res?.append(str[i])
            i = str.index(after: i)
        }
        guard res == nil else {
            return Substring(res!)
        }
        return str
    }
}
