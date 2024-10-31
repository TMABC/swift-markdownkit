import Foundation

/// 一个解析块引用并返回`blockquote`块的块解析器
open class BlockquoteParser: BlockParser {
    
    private final class BlockquoteContainer: MarkdownNestedContainer {
        
        public override var indentRequired: Bool {
            return true
        }
        
        public override func skipIndent(input: String,
                                        startIndex: String.Index,
                                        endIndex: String.Index) -> String.Index? {
            var index = startIndex
            var indent = 0
            while index < endIndex && input[index] == " " {
                indent += 1
                index = input.index(after: index)
            }
            guard indent < 4 && index < endIndex && input[index] == ">" else {
                return nil
            }
            index = input.index(after: index)
            if index < endIndex && input[index] == " " {
                index = input.index(after: index)
            }
            return index
        }
        
        public override func makeBlock(_ docParser: DocumentParser) -> MarkdownBlock {
            return .blockquote(docParser.bundle(blocks: self.content))
        }
        
        public override var debugDescription: String {
            return self.outer.debugDescription + " <- blockquote"
        }
    }
    
    public override func parse() -> ParseResult {
        guard self.shortLineIndent && self.line[self.contentStartIndex] == ">" else {
            return .none
        }
        let i = self.line.index(after: self.contentStartIndex)
        if i < self.contentEndIndex && self.line[i] == " " {
            self.docParser.resetLineStart(self.line.index(after: i))
        } else {
            self.docParser.resetLineStart(i)
        }
        return .container(BlockquoteContainer.init)
    }
}
