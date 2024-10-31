import Foundation

/// 一个块解析器，用于解析 ATX 标题（形式为`## Header`），返回`heading`块
open class AtxHeadingParser: BlockParser {
    public override func parse() -> ParseResult {
        guard self.shortLineIndent else {
            return .none
        }
        var i = self.contentStartIndex
        var level = 0
        while i < self.contentEndIndex && self.line[i] == "#" && level < 7 {
            i = self.line.index(after: i)
            level += 1
        }
        guard level > 0 && level < 7 && (i >= self.contentEndIndex || self.line[i] == " ") else {
            return .none
        }
        while i < self.contentEndIndex && self.line[i] == " " {
            i = self.line.index(after: i)
        }
        guard i < self.contentEndIndex else {
            let res: MarkdownBlock = .heading(level, MarkdownText(self.line[i..<i]))
            self.readNextLine()
            return .block(res)
        }
        var e = self.line.index(before: self.contentEndIndex)
        while e > i && self.line[e] == " " {
            e = self.line.index(before: e)
        }
        if e > i && self.line[e] == "#" {
            let e0 = e
            while e > i && self.line[e] == "#" {
                e = self.line.index(before: e)
            }
            if e >= i && self.line[e] == " " {
                while e >= i && self.line[e] == " " {
                    e = self.line.index(before: e)
                }
            } else {
                e = e0
            }
        }
        let res: MarkdownBlock = .heading(level, MarkdownText(self.line[i...e]))
        self.readNextLine()
        return .block(res)
    }
    
}
