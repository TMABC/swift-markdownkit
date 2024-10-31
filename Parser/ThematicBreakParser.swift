import Foundation

/// 一个解析主题分隔符并返回`thematicBreak`的块解析器。
open class ThematicBreakParser: BlockParser {
    
    public override func parse() -> ParseResult {
        guard self.shortLineIndent else {
            return .none
        }
        var i = self.contentStartIndex
        let ch = self.line[i]
        switch ch {
        case "-", "_", "*":
            break
        default:
            return .none
        }
        var count = 0
        while i < self.contentEndIndex {
            switch self.line[i] {
            case " ", "\t":
                break
            case ch:
                count += 1
            default:
                return .none
            }
            i = self.line.index(after: i)
        }
        guard count >= 3 else {
            return .none
        }
        self.readNextLine()
        return .block(.thematicBreak)
    }
}
