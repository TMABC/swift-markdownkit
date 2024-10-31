import Foundation

/// 代码块解析器用于解析不同类型的代码块。`CodeBlockParser`在两个具体实现`IndentedCodeBlockParser`和`FencedCodeBlockParser`之间实现了共享逻辑。
open class CodeBlockParser: BlockParser {
    
    public func formatIndentedLine(_ n: Int = 4) -> Substring {
        var index = self.line.startIndex
        var indent = 0
        while index < self.line.endIndex && indent < n {
            if self.line[index] == " " {
                indent += 1
            } else if self.line[index] == "\t" {
                indent += 4
            } else {
                break
            }
            index = self.line.index(after: index)
        }
        return self.line[index..<self.line.endIndex]
    }
}

/// 一个解析缩进代码块的代码块解析器，它会解析缩进的代码块并返回`indentedCode`块。
public final class IndentedCodeBlockParser: CodeBlockParser {
    
    public override var mayInterruptParagraph: Bool {
        return false
    }
    
    public override func parse() -> ParseResult {
        guard !self.shortLineIndent else {
            return .none
        }
        var code: MarkdownLines = [self.formatIndentedLine()]
        var emptyLines: MarkdownLines = []
        self.readNextLine()
        while !self.finished && self.lineEmpty {
            self.readNextLine()
        }
        while !self.finished && (!self.shortLineIndent || self.lineEmpty) {
            if self.lineEmpty {
                emptyLines.append(self.formatIndentedLine())
            } else {
                if emptyLines.count > 0 {
                    code.append(contentsOf: emptyLines)
                    emptyLines.removeAll()
                }
                code.append(self.formatIndentedLine())
            }
            self.readNextLine()
        }
        return .block(.indentedCode(code))
    }
}

/// 一个解析带围栏代码块的代码块解析器，返回`fencedCode`
public final class FencedCodeBlockParser: CodeBlockParser {
    
    public override func parse() -> ParseResult {
        guard self.shortLineIndent else {
            return .none
        }
        let fenceChar = self.line[self.contentStartIndex]
        guard fenceChar == "`" || fenceChar == "~" else {
            return .none
        }
        let fenceIndent = self.lineIndent
        var fenceLength = 1
        var index = self.line.index(after: self.contentStartIndex)
        while index < self.contentEndIndex && self.line[index] == fenceChar {
            fenceLength += 1
            index = self.line.index(after: index)
        }
        guard fenceLength >= 3 else {
            return .none
        }
        let info = self.line[index..<self.contentEndIndex]
            .trimmingCharacters(in: CharacterSet.whitespaces)
        guard !info.contains("`") && !info.contains("~") else {
            return .none
        }
        self.readNextLine()
        var code: MarkdownLines = []
        while !self.finished {
            if !self.lineEmpty && self.shortLineIndent {
                var fenceCloseLength = 0
                index = self.contentStartIndex
                while index < self.contentEndIndex && self.line[index] == fenceChar {
                    fenceCloseLength += 1
                    index = self.line.index(after: index)
                }
                if fenceCloseLength >= fenceLength {
                    while index < self.contentEndIndex && isUnicodeWhitespace(self.line[index]) {
                        index = self.line.index(after: index)
                    }
                    if index == self.contentEndIndex {
                        break
                    }
                }
            }
            code.append(self.formatIndentedLine(fenceIndent))
            self.readNextLine()
        }
        self.readNextLine()
        return .block(.fencedCode(info.isEmpty ? nil : info, code))
    }
}
