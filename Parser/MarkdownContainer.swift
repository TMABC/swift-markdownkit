import Foundation

/// 一个`Container`包含一系列正在被解析的块。
/// `Container`可以嵌套。子类`NestedContainer`实现了一个嵌套容器，即具有一个封闭容器的容器。
open class MarkdownContainer: CustomDebugStringConvertible {
    public var content: [MarkDownBlock] = []
    
    open func makeBlock(_ docParser: DocumentParser) -> MarkDownBlock {
        return .document(docParser.bundle(blocks: self.content))
    }
    
    internal func parseIndent(input: String,
                              startIndex: String.Index,
                              endIndex: String.Index) -> (String.Index, MarkdownContainer) {
        return (startIndex, self)
    }
    
    internal func outermostIndentRequired(upto: MarkdownContainer) -> MarkdownContainer? {
        return nil
    }
    
    internal func `return`(to container: MarkdownContainer? = nil, for: DocumentParser) -> MarkdownContainer {
        return self
    }
    
    open var debugDescription: String {
        return "doc"
    }
}

/// `NestedContainer`表示具有"outer" 容器的容器。
open class NestedContainer: MarkdownContainer {
    internal let outer: MarkdownContainer
    
    public init(outer: MarkdownContainer) {
        self.outer = outer
    }
    
    open var indentRequired: Bool {
        return false
    }
    
    open func skipIndent(input: String,
                         startIndex: String.Index,
                         endIndex: String.Index) -> String.Index? {
        return startIndex
    }
    
    open override func makeBlock(_ docParser: DocumentParser) -> MarkDownBlock {
        preconditionFailure("makeBlock() not defined")
    }
    
    internal final override func parseIndent(input: String,
                                             startIndex: String.Index,
                                             endIndex: String.Index) -> (String.Index, MarkdownContainer) {
        let (index, container) = self.outer.parseIndent(input: input,
                                                        startIndex: startIndex,
                                                        endIndex: endIndex)
        guard container === self.outer else {
            return (index, container)
        }
        guard let res = self.skipIndent(input: input, startIndex: index, endIndex: endIndex) else {
            return (index, self.outer)
        }
        return (res, self)
    }
    
    internal final override func outermostIndentRequired(upto container: MarkdownContainer) -> MarkdownContainer? {
        if self === container {
            return nil
        } else if self.indentRequired {
            return self.outer.outermostIndentRequired(upto: container) ?? self.outer
        } else {
            return self.outer.outermostIndentRequired(upto: container)
        }
    }
    
    internal final override func `return`(to container: MarkdownContainer? = nil,
                                          for docParser: DocumentParser) -> MarkdownContainer {
        if self === container {
            return self
        } else {
            self.outer.content.append(self.makeBlock(docParser))
            return self.outer.return(to: container, for: docParser)
        }
    }
}
