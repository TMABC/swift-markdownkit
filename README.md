# Swift MarkdownKit

<p>
<a href="https://developer.apple.com/osx/"><img src="https://img.shields.io/badge/Platform-macOS%20%7C%20iOS%20%7C%20Linux-blue.svg?style=flat" alt="Platform: macOS | iOS | Linux" /></a>
<a href="https://developer.apple.com/swift/"><img src="https://img.shields.io/badge/Language-Swift%205.7-green.svg?style=flat" alt="Language: Swift 5.7" /></a>
<a href="https://developer.apple.com/xcode/"><img src="https://img.shields.io/badge/IDE-Xcode%2014-orange.svg?style=flat" alt="IDE: Xcode 14" /></a>
<a href="https://raw.githubusercontent.com/objecthub/swift-markdownkit/master/LICENSE"><img src="http://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License: Apache" /></a>
</p>

## 概述

_Swift MarkdownKit_是一个用于解析[Markdown](https://daringfireball.net/projects/markdown/)格式文本的框架。支持的语法基于[CommonMark Markdown 规范](https://commonmark.org)。_Swift MarkdownKit_还提供了该解析器的扩展版本，能够处理 Markdown 表格。

_Swift MarkdownKit_为 Markdown 定义了一种抽象语法，它提供了一个将字符串解析为抽象语法树的解析器，并带有用于创建 HTML 和[属性字符串](https://developer.apple.com/documentation/foundation/nsattributedstring)的生成器。

## Using the framework

### Parsing Markdown

类[`MarkdownParser`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/Parser/MarkdownParser.swift)
提供了一个简单的API来解析字符串中的Markdown。解析器返回一个抽象语法树
表示字符串中的Markdown结构：

```swift
let markdown = MarkdownParser.standard.parse("""
                 # Header
                 ## Sub-header
                 And this is a **paragraph**.
                 """)
print(markdown)
```

执行这段代码将会输出以下类型为`Block`的数据结构：

```swift
document(heading(1, text("Header")),
         heading(2, text("Sub-header")),
         paragraph(text("And this is a "),
                   strong(text("paragraph")),
                   text("."))))
```

[`Block`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/Block.swift)
is a recursively defined enumeration of cases with associated values (also called an _algebraic datatype_).
Case `document` refers to the root of a document. It contains a sequence of blocks. In the example above, two
different types of blocks appear within the document: `heading` and `paragraph`. A `heading` case consists
of a heading level (as its first argument) and heading text (as the second argument). A `paragraph` case simply
consists of text.

Text is represented using the struct
[`Text`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/Text.swift)
which is effectively a sequence of `TextFragment` values.
[`TextFragment`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/TextFragment.swift)
is yet another recursively defined enumeration with associated values. The example above shows two different
`TextFragment` cases in action: `text` and `strong`. Case `text` represents plain strings. Case `strong`
contains a `Text`  object, i.e. it encapsulates a sequence of `TextFragment` values which are
"marked up strongly".

### 解析 "extended" Markdown

"ExtendedMarkdownParser"类具有与“MarkdownParser”相同的接口，但除了 [CommonMark 规范](https://commonmark.org) 定义的块类型之外，还支持表格和定义列表。[表格](https://github.github.com/gfm/#tables-extension-)基于 [GitHub 风格的 Markdown 规范](https://github.github.com/gfm/)，并进行了一项扩展：在表格块中，可以转义换行符，以便能够在多行上编写单元格文本。以下是一个示例：
Class `ExtendedMarkdownParser` has the same interface like `MarkdownParser` but supports tables and
definition lists in addition to the block types defined by the [CommonMark specification](https://commonmark.org).
[Tables](https://github.github.com/gfm/#tables-extension-) are based on the
[GitHub Flavored Markdown specification](https://github.github.com/gfm/) with one extension: within a table
block, it is possible to escape newline characters to enable cell text to be written on multiple lines. Here is an example:

```
| Column 1     | Column 2       |
| ------------ | -------------- |
| This text \
  is very long | More cell text |
| Last line    | Last cell      |        
```

[Definition lists](https://www.markdownguide.org/extended-syntax/#definition-lists) are implemented in an
ad hoc fashion. A definition consists of terms and their corresponding definitions. Here is an example of two
definitions:

```
Apple
: Pomaceous fruit of plants of the genus Malus in the family Rosaceae.

Orange
: The fruit of an evergreen tree of the genus Citrus.
: A large round juicy citrus fruit with a tough bright reddish-yellow rind.
```

### Configuring the Markdown parser

The Markdown dialect supported by `MarkdownParser` is defined by two parameters: a sequence of
_block parsers_ (each represented as a subclass of
[`BlockParser`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/Parser/BlockParser.swift)),
and a sequence of _inline transformers_ (each represented as a subclass of
[`InlineTransformer`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/Parser/InlineTransformer.swift)).
The initializer of class `MarkdownParser` accepts both components optionally. The default configuration
(neither block parsers nor inline transformers are provided for the initializer) is able to handle Markdown based on the
[CommonMark specification](https://commonmark.org).

Since `MarkdownParser` objects are stateless (beyond the configuration of block parsers and inline
transformers), there is a predefined default `MarkdownParser` object accessible via the static property
`MarkdownParser.standard`. This default parsing object is used in the example above.

New markdown parsers with different configurations can also be created by subclassing
[`MarkdownParser`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/Parser/MarkdownParser.swift)
and by overriding the class properties `defaultBlockParsers` and `defaultInlineTransformers`. Here is
an example of how class
[`ExtendedMarkdownParser`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/Parser/ExtendedMarkdownParser.swift)
is derived from `MarkdownParser` simply by overriding
`defaultBlockParsers` and by specializing `standard` in a covariant fashion.

```swift
open class ExtendedMarkdownParser: MarkdownParser {
  override open class var defaultBlockParsers: [BlockParser.Type] {
    return self.blockParsers
  }
  private static let blockParsers: [BlockParser.Type] =
    MarkdownParser.defaultBlockParsers + [TableParser.self]
  override open class var standard: ExtendedMarkdownParser {
    return self.singleton
  }
  private static let singleton: ExtendedMarkdownParser = ExtendedMarkdownParser()
}
```

### Extending the Markdown parser

With version 1.1 of the MarkdownKit framework, it is now also possible to extend the abstract
syntax supported by MarkdownKit. Both `Block` and `TextFragment` enumerations now include
a `custom` case which refers to objects representing the extended syntax. These objects have to
implement protocol [`CustomBlock`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/CustomBlock.swift) for blocks and [`CustomTextFragment`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/CustomTextFragment.swift) for text fragments.

Here is a simple example how one can add support for "underline" (e.g. `this is ~underlined~ text`)
and "strikethrough" (e.g. `this is using ~~strike-through~~`) by subclassing existing inline transformers.

First, a new custom text fragment type has to be implemented for representing underlined and
strike-through text. This is done with an enumeration which implements the `CustomTextFragment` protocol:

```swift
enum LineEmphasis: CustomTextFragment {
  case underline(Text)
  case strikethrough(Text)

  func equals(to other: CustomTextFragment) -> Bool {
    guard let that = other as? LineEmphasis else {
      return false
    }
    switch (self, that) {
      case (.underline(let lhs), .underline(let rhs)):
        return lhs == rhs
      case (.strikethrough(let lhs), .strikethrough(let rhs)):
        return lhs == rhs
      default:
        return false
    }
  }
  func transform(via transformer: InlineTransformer) -> TextFragment {
    switch self {
      case .underline(let text):
        return .custom(LineEmphasis.underline(transformer.transform(text)))
      case .strikethrough(let text):
        return .custom(LineEmphasis.strikethrough(transformer.transform(text)))
    }
  }
  func generateHtml(via htmlGen: HtmlGenerator) -> String {
    switch self {
      case .underline(let text):
        return "<u>" + htmlGen.generate(text: text) + "</u>"
      case .strikethrough(let text):
        return "<s>" + htmlGen.generate(text: text) + "</s>"
    }
  }
  func generateHtml(via htmlGen: HtmlGenerator,
                    and attrGen: AttributedStringGenerator?) -> String {
    return self.generateHtml(via: htmlGen)
  }
  var rawDescription: String {
    switch self {
      case .underline(let text):
        return text.rawDescription
      case .strikethrough(let text):
        return text.rawDescription
    }
  }
  var description: String {
    switch self {
      case .underline(let text):
        return "~\(text.description)~"
      case .strikethrough(let text):
        return "~~\(text.description)~~"
    }
  }
  var debugDescription: String {
    switch self {
      case .underline(let text):
        return "underline(\(text.debugDescription))"
      case .strikethrough(let text):
        return "strikethrough(\(text.debugDescription))"
    }
  }
}
```

接下来，需要扩展两个内联转换器以识别新的强调分隔符“~”

```swift
final class EmphasisTestTransformer: EmphasisTransformer {
  override public class var supportedEmphasis: [Emphasis] {
    return super.supportedEmphasis + [
             Emphasis(ch: "~", special: false, factory: { double, text in
               return .custom(double ? LineEmphasis.strikethrough(text)
                                     : LineEmphasis.underline(text))
             })]
  }
}
final class DelimiterTestTransformer: DelimiterTransformer {
  override public class var emphasisChars: [Character] {
    return super.emphasisChars + ["~"]
  }
}
```

最后，可以创建一个新的扩展 Markdown 解析器

```swift
final class EmphasisTestMarkdownParser: MarkdownParser {
  override public class var defaultInlineTransformers: [InlineTransformer.Type] {
    return [DelimiterTestTransformer.self,
            CodeLinkHtmlTransformer.self,
            LinkTransformer.self,
            EmphasisTestTransformer.self,
            EscapeTransformer.self]
  }
  override public class var standard: EmphasisTestMarkdownParser {
    return self.singleton
  }
  private static let singleton: EmphasisTestMarkdownParser = EmphasisTestMarkdownParser()
}
```

### 处理 Markdown

用抽象语法树表示 Markdown 文本的用法具有这样的优势，即处理此类数据非常容易，特别是对其进行转换和提取信息。下面是一个简短的 Swift 代码片段，说明了如何处理抽象语法树以提取所有顶级标题（即此代码打印 Markdown 格式文本的顶级大纲）。

```swift
let markdown = MarkdownParser.standard.parse("""
                   # First *Header*
                   ## Sub-header
                   And this is a **paragraph**.
                   # Second **Header**
                   And this is another paragraph.
                 """)

func topLevelHeaders(doc: Block) -> [String] {
  guard case .document(let topLevelBlocks) = doc else {
    preconditionFailure("markdown block does not represent a document")
  }
  var outline: [String] = []
  for block in topLevelBlocks {
    if case .heading(1, let text) = block {
      outline.append(text.rawDescription)
    }
  }
  return outline
}

let headers = topLevelHeaders(doc: markdown)
print(headers)
```

这将打印一个具有以下两个条目的数组：

```swift
["First Header", "Second Header"]
```

### Converting Markdown into other formats

_Swift MarkdownKit_ currently provides two different _generators_, i.e. Markdown processors which
output, for a given Markdown document, a corresponding representation in a different format.

[`HtmlGenerator`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/HTML/HtmlGenerator.swift)
defines a simple mapping from Markdown into HTML. Here is an example for the usage of the generator: 

```swift
let html = HtmlGenerator.standard.generate(doc: markdown)
```

There are currently no means to customize `HtmlGenerator` beyond subclassing. Here is an example that
defines a customized HTML generator which formats `blockquote` Markdown blocks using HTML tables:

```swift
open class CustomizedHtmlGenerator: HtmlGenerator {
  open override func generate(block: Block, tight: Bool = false) -> String {
    switch block {
      case .blockquote(let blocks):
        return "<table><tbody><tr><td style=\"background: #bbb; width: 0.2em;\"  />" +
               "<td style=\"width: 0.2em;\" /><td>\n" +
               self.generate(blocks: blocks) +
               "</td></tr></tbody></table>\n"
      default:
        return super.generate(block: block, tight: tight)
    }
  }
}
```

_Swift MarkdownKit_ also comes with a generator for attributed strings.
[`AttributedStringGenerator`](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKit/AttributedString/AttributedStringGenerator.swift)
uses a customized HTML generator internally to define the translation from Markdown into
`NSAttributedString`. The initializer of `AttributedStringGenerator` provides a number of
parameters for customizing the style of the generated attributed string. 

```swift
let generator = AttributedStringGenerator(fontSize: 12,
                                          fontFamily: "Helvetica, sans-serif",
                                          fontColor: "#33C",
                                          h1Color: "#000")
let attributedStr = generator.generate(doc: markdown)
```

## 使用命令行工具

The _Swift MarkdownKit_ Xcode project also implements a
[very simple command-line tool](https://github.com/objecthub/swift-markdownkit/blob/master/Sources/MarkdownKitProcess/main.swift)
for either translating a single Markdown text file into HTML or for translating all Markdown files within a given
directory into HTML.

该工具旨在为特定用例的定制提供基础。构建二进制文件的最简单方法是使用 Swift 包管理器（SPM）：

```sh
> git clone https://github.com/objecthub/swift-markdownkit.git
Cloning into 'swift-markdownkit'...
remote: Enumerating objects: 70, done.
remote: Counting objects: 100% (70/70), done.
remote: Compressing objects: 100% (54/54), done.
remote: Total 70 (delta 13), reused 65 (delta 11), pack-reused 0
Unpacking objects: 100% (70/70), done.
> cd swift-markdownkit
> swift build -c release
[1/3] Compiling Swift Module 'MarkdownKit' (25 sources)
[2/3] Compiling Swift Module 'MarkdownKitProcess' (1 sources)
[3/3] Linking ./.build/x86_64-apple-macosx/release/MarkdownKitProcess
> ./.build/x86_64-apple-macosx/release/MarkdownKitProcess
usage: mdkitprocess <source> [<target>]
where: <source> is either a Markdown file or a directory containing Markdown files
       <target> is either an HTML file or a directory in which HTML files are written
```

## 已知问题

存在一些限制和已知问题：

- Markdown 解析器目前不完全以符合 CommonMark 的方式支持_link reference definitions_。可以定义链接引用定义并使用它们，但在某些极端情况下，当前的实现与规范的行为不同。

## 要求

构建_Swift MarkdownKit_框架的组件需要以下技术。命令行工具可以使用_Swift Package Manager_进行编译，因此在这种情况下，并不严格需要_Xcode_。同样，仅为了在_Xcode_中编译框架并试用命令行工具，也不需要_Swift Package Manager_。

- [Xcode 14](https://developer.apple.com/xcode/)
- [Swift 5.7](https://developer.apple.com/swift/)
- [Swift Package Manager](https://swift.org/package-manager/)

## Copyright

Author: Matthias Zenger (<matthias@objecthub.net>)  
Copyright © 2019-2024 Google LLC.  
_Please note: This is not an official Google product._
