import Foundation

/// 用于解析列表项的块解析器。
/// 有两种类型的列表项：
/// _项目符号列表项_和_有序列表项_。它们使用`listItem`块表示，
/// 使用`bullet`或`ordered list type`。
open class ListItemParser: BlockParser {
    /// 一组受支持的项目符号字符
    private let bulletChars: Set<Character>
    
    /// 用于扩展`ListItemParser`
    public init(docParser: DocumentParser, bulletChars: Set<Character>) {
        self.bulletChars = bulletChars
        super.init(docParser: docParser)
    }
    
    public required init(docParser: DocumentParser) {
        self.bulletChars = ["-", "+", "*"]
        super.init(docParser: docParser)
    }
    
    private class BulletListItemContainer: MarkdownNestedContainer {
        let bullet: Character
        let indent: Int
        let tight: Bool
        
        init(bullet: Character, tight: Bool, indent: Int, outer: MarkdownContainer) {
            self.bullet = bullet
            self.indent = indent
            self.tight = tight
            super.init(outer: outer)
        }
        
        public override func skipIndent(input: String,
                                        startIndex: String.Index,
                                        endIndex: String.Index) -> String.Index? {
            var index = startIndex
            var indent = 0
        loop: while index < endIndex && indent < self.indent {
            switch input[index] {
            case " ":
                indent += 1
            case "\t":
                indent += 4
            default:
                break loop
            }
            index = input.index(after: index)
        }
            guard index <= endIndex && indent >= self.indent else {
                return nil
            }
            return index
        }
        
        public override func makeBlock(_ docParser: DocumentParser) -> MarkdownBlock {
            return .listItem(.bullet(self.bullet), self.tight, docParser.bundle(blocks: self.content))
        }
        
        public override var debugDescription: String {
            return self.outer.debugDescription + " <- bulletListItem(\(self.bullet))"
        }
    }
    
    private final class OrderedListItemContainer: BulletListItemContainer {
        let number: Int
        
        init(number: Int, delimiter: Character, tight: Bool, indent: Int, outer: MarkdownContainer) {
            self.number = number
            super.init(bullet: delimiter, tight: tight, indent: indent, outer: outer)
        }
        
        public override func makeBlock(_ docParser: DocumentParser) -> MarkdownBlock {
            return .listItem(.ordered(self.number, self.bullet),
                             self.tight,
                             docParser.bundle(blocks: self.content))
        }
        
        public override var debugDescription: String {
            return self.outer.debugDescription + " <- orderedListItem(\(self.number), \(self.bullet))"
        }
    }
    
    public override func parse() -> ParseResult {
        guard self.shortLineIndent else {
            return .none
        }
        var i = self.contentStartIndex
        var listMarkerIndent = 0
        var marker: Character = self.line[i]
        var number: Int? = nil
        switch marker {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            var n = self.line[i].wholeNumberValue!
            i = self.line.index(after: i)
            listMarkerIndent += 1
        numloop: while i < self.contentEndIndex && listMarkerIndent < 8 {
            switch self.line[i] {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                n = n * 10 + self.line[i].wholeNumberValue!
            default:
                break numloop
            }
            i = self.line.index(after: i)
            listMarkerIndent += 1
        }
            guard i < self.contentEndIndex else {
                return .none
            }
            number = n
            marker = self.line[i]
            switch marker {
            case ".", ")":
                break
            default:
                return .none
            }
        default:
            if self.bulletChars.contains(marker) {
                break
            }
            return .none
        }
        i = self.line.index(after: i)
        listMarkerIndent += 1
        var indent = 0
    loop: while i < self.contentEndIndex && indent < 4 {
        switch self.line[i] {
        case " ":
            indent += 1
        case "\t":
            indent += 4
        default:
            break loop
        }
        i = self.line.index(after: i)
    }
        guard i >= self.contentEndIndex || indent > 0 else {
            return .none
        }
        if indent > 4 {
            indent = 1
        }
        indent += self.lineIndent + listMarkerIndent
        self.docParser.resetLineStart(i)
        let tight = !self.prevLineEmpty
        if let number = number {
            return .container { encl in
                OrderedListItemContainer(number: number,
                                         delimiter: marker,
                                         tight: tight,
                                         indent: indent,
                                         outer: encl)
            }
        } else {
            return .container { encl in
                BulletListItemContainer(bullet: marker, tight: tight, indent: indent, outer: encl)
            }
        }
    }
}
