import Foundation

/// 一个块解析器，用于解析 Setext 标题（带有文本下划线的标题）并返回`heading`块。
open class SetextHeadingParser: BlockParser {
    
    public override func parse() -> ParseResult {
        guard self.shortLineIndent,
              !self.lazyContinuation,
              let plines = self.prevParagraphLines,
              !plines.isEmpty else {
            return .none
        }
        let ch = self.line[self.contentStartIndex]
        let level: Int
        switch ch {
        case "=":
            level = 1
        case "-":
            level = 2
        default:
            return .none
        }
        var i = self.contentStartIndex
        while i < self.contentEndIndex && self.line[i] == ch {
            i = self.line.index(after: i)
        }
        skipWhitespace(in: self.line, from: &i, to: self.contentEndIndex)
        guard i >= self.contentEndIndex else {
            return .none
        }
        self.consumeParagraphLines()
        self.readNextLine()
        return .block(.heading(level, plines.finalized()))
    }
}
