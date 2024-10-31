import Foundation

/// `BlockParser` 解析一种特定类型的 Markdown 块。类`BlockParser`定义了此类块解析器的框架。每种不同的块类型都有其自己的`BlockParser`子类
open class BlockParser {
  /// 调用`parse`方法的结果
  public enum ParseResult {
    case none
    case block(MarkdownBlock)
    case container((MarkdownContainer) -> MarkdownContainer)
  }

  unowned let docParser: DocumentParser
  
  public required init(docParser: DocumentParser) {
    self.docParser = docParser
  }
  
  public var finished: Bool {
    return self.docParser.finished
  }

  public var prevParagraphLines: MarkdownText? {
    return self.docParser.prevParagraphLines
  }

  public func consumeParagraphLines() {
    self.docParser.prevParagraphLines = nil
  }
  
  public var line: Substring {
    return self.docParser.line
  }
  
  public var contentStartIndex: Substring.Index {
    return self.docParser.contentStartIndex
  }
  
  public var contentEndIndex: Substring.Index {
    return self.docParser.contentEndIndex
  }
  
  public var lineIndent: Int {
    return self.docParser.lineIndent
  }
  
  public var lineEmpty: Bool {
    return self.docParser.lineEmpty
  }

  public var prevLineEmpty: Bool {
    return self.docParser.prevLineEmpty
  }
  
  public var shortLineIndent: Bool {
    return self.docParser.shortLineIndent
  }

  public var lazyContinuation: Bool {
    return self.docParser.lazyContinuation
  }
  
  open func readNextLine() {
    self.docParser.readNextLine()
  }

  open var mayInterruptParagraph: Bool {
    return true
  }
  
  open func parse() -> ParseResult {
    return .none
  }
}

///
/// `RestorableBlockParser` objects are `BlockParser` objects which restore the
/// `DocumentParser` state in case their `parse` method fails (the `ParseResult` is `.none`).
/// 
open class RestorableBlockParser: BlockParser {
  private var docParserState: DocumentParserState

  public required init(docParser: DocumentParser) {
    self.docParserState = DocumentParserState(docParser)
    super.init(docParser: docParser)
  }

  open override func parse() -> ParseResult {
    self.docParser.copyState(&self.docParserState)
    let res = self.tryParse()
    if case .none = res {
      self.docParser.restoreState(self.docParserState)
      return .none
    } else {
      return res
    }
  }

  open func tryParse() -> ParseResult {
    return .none
  }
}
