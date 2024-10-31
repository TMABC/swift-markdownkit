import Foundation

/// 结构体`Text`用于表示内联文本
/// 一个`Text`结构体由一系列的`TextFragment`对象组成
public struct MarkdownText: Collection, Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    public typealias Index = ContiguousArray<MarkdownTextFragment>.Index
    public typealias Iterator = ContiguousArray<MarkdownTextFragment>.Iterator
    
    private var fragments: ContiguousArray<MarkdownTextFragment> = []
    
    public init(_ str: Substring? = nil) {
        if let str = str {
            self.fragments.append(.text(str))
        }
    }
    
    public init(_ fragment: MarkdownTextFragment) {
        self.fragments.append(fragment)
    }
    
    /// Returns `true` if the text is empty.
    public var isEmpty: Bool {
        return self.fragments.isEmpty
    }
    
    /// Returns the first text fragment if available.
    public var first: MarkdownTextFragment? {
        return self.fragments.first
    }
    
    /// Returns the last text fragment if available.
    public var last: MarkdownTextFragment? {
        return self.fragments.last
    }
    
    /// Appends a line of text, potentially followed by a hard line break
    mutating public func append(line: Substring, withHardLineBreak: Bool) {
        let n = self.fragments.count
        if n > 0, case .text(let str) = self.fragments[n - 1] {
            if str.last == "\\" {
                let newline = str[str.startIndex..<str.index(before: str.endIndex)]
                if newline.isEmpty {
                    self.fragments[n - 1] = .hardLineBreak
                } else {
                    self.fragments[n - 1] = .text(newline)
                    self.fragments.append(.hardLineBreak)
                }
            } else {
                self.fragments.append(.softLineBreak)
            }
        }
        self.fragments.append(.text(line))
        if withHardLineBreak {
            self.fragments.append(.hardLineBreak)
        }
    }
    
    /// Appends a given text fragment.
    mutating public func append(fragment: MarkdownTextFragment) {
        self.fragments.append(fragment)
    }
    
    /// Replaces the text fragments between `from` and `to` with a given array of text
    /// fragments.
    mutating public func replace(from: Int, to: Int, with fragments: [MarkdownTextFragment]) {
        self.fragments.replaceSubrange(from...to, with: fragments)
    }
    
    /// Returns an iterator over all text fragments.
    public func makeIterator() -> Iterator {
        return self.fragments.makeIterator()
    }
    
    /// Returns the start index.
    public var startIndex: Index {
        return self.fragments.startIndex
    }
    
    /// Returns the end index.
    public var endIndex: Index {
        return self.fragments.endIndex
    }
    
    /// Returns the text fragment at the given index.
    public subscript (position: Index) -> Iterator.Element {
        return self.fragments[position]
    }
    
    /// Advances the given index by one place.
    public func index(after i: Index) -> Index {
        return self.fragments.index(after: i)
    }
    
    /// Returns a description of this `Text` object as a string as if the text would be
    /// represented in Markdown.
    public var description: String {
        var res = ""
        for fragment in self.fragments {
            res = res + fragment.description
        }
        return res
    }
    
    /// 返回此`Text`对象的原始描述字符串，即如同文本以 Markdown 表示但忽略所有标记
    public var rawDescription: String {
        return self.fragments.map { $0.rawDescription }.joined()
    }
    
    /// 返回此`Text`对象的一个原始描述字符串，其中所有标记都被忽略
    public var string: String {
        return self.fragments.map { $0.string }.joined()
    }
    
    /// 返回此`Text`对象的调试描述
    public var debugDescription: String {
        var res = ""
        for fragment in self.fragments {
            if res.isEmpty {
                res = fragment.debugDescription
            } else {
                res = res + ", \(fragment.debugDescription)"
            }
        }
        return res
    }
    
    /// 通过移除尾部换行符来完成`Text`对象的最终化
    public func finalized() -> MarkdownText {
        if let lastLine = self.fragments.last {
            switch lastLine {
            case .hardLineBreak, .softLineBreak:
                var plines = self
                plines.fragments.removeLast()
                return plines
            default:
                return self
            }
        } else {
            return self
        }
    }
    
    /// 为`Text`对象定义了一种相等关系
    public static func == (lhs: MarkdownText, rhs: MarkdownText) -> Bool {
        return lhs.fragments == rhs.fragments
    }
}
