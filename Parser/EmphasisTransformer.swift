import Foundation

/// 一种内联转换器，它提取强调标记并将其转换为`emph`和`strong`文本片段
open class EmphasisTransformer: InlineTransformer {
    
    /// 指定强调类型的插件。`ch`指强调字符，`special`表示该字符是否用于其他用例（例如，“*”和“-”应标记为“special”），`factory`是一个闭包，从两个参数构造文本片段：第一个参数表示是否是双重用法，第二个参数表示被强调的文本。
    public struct Emphasis {
        let ch: Character
        let special: Bool
        let factory: (Bool, MarkdownText) -> MarkdownTextFragment
    }
    
    /// 默认支持强调。覆盖此属性以更改所支持的内容
    open class var supportedEmphasis: [Emphasis] {
        let factory = { (double: Bool, text: MarkdownText) -> MarkdownTextFragment in
            double ? .strong(text) : .emph(text)
        }
        return [Emphasis(ch: "*", special: true, factory: factory),
                Emphasis(ch: "_", special: false, factory: factory)]
    }
    
    /// 强调映射，在内部用于确定字符如何用于强调标记
    private var emphasis: [Character : Emphasis] = [:]
    
    required public init(owner: InlineParser) {
        super.init(owner: owner)
        for emph in type(of: self).supportedEmphasis {
            self.emphasis[emph.ch] = emph
        }
    }
    
    private struct Delimiter: CustomStringConvertible {
        let ch: Character
        let special: Bool
        let runType: DelimiterRunType
        var count: Int
        var index: Int
        
        init(_ ch: Character, _ special: Bool, _ rtype: DelimiterRunType, _ count: Int, _ index: Int) {
            self.ch = ch
            self.special = special
            self.runType = rtype
            self.count = count
            self.index = index
        }
        
        var isOpener: Bool {
            return self.runType.contains(.leftFlanking) &&
            (self.special ||
             !self.runType.contains(.rightFlanking) ||
             self.runType.contains(.leftPunctuation))
        }
        
        var isCloser: Bool {
            return self.runType.contains(.rightFlanking) &&
            (self.special ||
             !self.runType.contains(.leftFlanking) ||
             self.runType.contains(.rightPunctuation))
        }
        
        var countMultipleOf3: Bool {
            return self.count % 3 == 0
        }
        
        func isOpener(for ch: Character) -> Bool {
            return self.ch == ch && self.isOpener
        }
        
        func isCloser(for ch: Character) -> Bool {
            return self.ch == ch && self.isCloser
        }
        
        var description: String {
            return "Delimiter(\(self.ch), \(self.special), \(self.runType), \(self.count), \(self.index))"
        }
    }
    
    private typealias DelimiterStack = [Delimiter]
    
    public override func transform(_ text: MarkdownText) -> MarkdownText {
        // 计算分隔符栈
        var res: MarkdownText = MarkdownText()
        var iterator = text.makeIterator()
        var element = iterator.next()
        var delimiters = DelimiterStack()
        while let fragment = element {
            switch fragment {
            case .delimiter(let ch, let n, let type):
                delimiters.append(Delimiter(ch, self.emphasis[ch]?.special ?? false, type, n, res.count))
                res.append(fragment: fragment)
                element = iterator.next()
            default:
                element = self.transform(fragment, from: &iterator, into: &res)
            }
        }
        self.processEmphasis(&res, &delimiters)
        return res
    }
    
    private func isSupportedEmphasisCloser(_ delimiter: Delimiter) -> Bool {
        for ch in self.emphasis.keys {
            if delimiter.isCloser(for: ch) {
                return true
            }
        }
        return false
    }
    
    private func processEmphasis(_ res: inout MarkdownText, _ delimiters: inout DelimiterStack) {
        var currentPos = 0
    loop: while currentPos < delimiters.count {
        var potentialCloser = delimiters[currentPos]
        if self.isSupportedEmphasisCloser(potentialCloser) {
            var i = currentPos - 1
            while i >= 0 {
                var potentialOpener = delimiters[i]
                if potentialOpener.isOpener(for: potentialCloser.ch) &&
                    ((!potentialCloser.isOpener && !potentialOpener.isCloser) ||
                     (potentialCloser.countMultipleOf3 && potentialOpener.countMultipleOf3) ||
                     ((potentialOpener.count + potentialCloser.count) % 3 != 0)) {
                    // 扣除计数
                    let delta = potentialOpener.count > 1 && potentialCloser.count > 1 ? 2 : 1
                    delimiters[i].count -= delta
                    delimiters[currentPos].count -= delta
                    potentialOpener = delimiters[i]
                    potentialCloser = delimiters[currentPos]
                    // 收集碎片
                    var nestedText = MarkdownText()
                    for fragment in res[potentialOpener.index+1..<potentialCloser.index] {
                        nestedText.append(fragment: fragment)
                    }
                    // 替换现有的片段
                    var range = [MarkdownTextFragment]()
                    if potentialOpener.count > 0 {
                        range.append(.delimiter(potentialOpener.ch,
                                                potentialOpener.count,
                                                potentialOpener.runType))
                    }
                    if let factory = self.emphasis[potentialOpener.ch]?.factory {
                        range.append(factory(delta > 1, nestedText))
                    } else {
                        for fragment in nestedText {
                            range.append(fragment)
                        }
                    }
                    if potentialCloser.count > 0 {
                        range.append(.delimiter(potentialCloser.ch,
                                                potentialCloser.count,
                                                potentialCloser.runType))
                    }
                    let shift = range.count - potentialCloser.index + potentialOpener.index - 1
                    res.replace(from: potentialOpener.index, to: potentialCloser.index, with: range)
                    // 更新分隔符栈
                    if potentialCloser.count == 0 {
                        delimiters.remove(at: currentPos)
                    }
                    if potentialOpener.count == 0 {
                        delimiters.remove(at: i)
                        currentPos -= 1
                    } else {
                        i += 1
                    }
                    var j = i
                    while j < currentPos {
                        delimiters.remove(at: i)
                        j += 1
                    }
                    currentPos = i
                    while i < delimiters.count {
                        delimiters[i].index += shift
                        i += 1
                    }
                    continue loop
                }
                i -= 1
            }
            if !potentialCloser.isOpener {
                delimiters.remove(at: currentPos)
                continue loop
            }
        }
        currentPos += 1
    }
    }
}
