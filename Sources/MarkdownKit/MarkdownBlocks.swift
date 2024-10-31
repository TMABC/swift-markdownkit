import Foundation

/// 一个规范化的块序列，以数组形式表示
public typealias MarkdownBlocks = ContiguousArray<MarkdownBlock>

extension MarkdownBlocks {
    /// 返回单个`MarkdownBlocks`对象的文本。单个`MarkdownBlocks`对象包含一个段落。如果此对象不是单个`MarkdownBlocks`对象，则此属性返回`nil`
    public var text: MarkdownText? {
        if self.count == 1,
           case .paragraph(let text) = self[0] {
            return text
        } else {
            return nil
        }
    }
    
    /// 如果这是一个单例`MarkdownBlocks`对象，则返回 true。
    public var isSingleton: Bool {
        return self.count == 1
    }
    
    /// 返回此块序列的原始文本
    public var string: String {
        return self.map { $0.string }.joined(separator: "\n")
    }
}
