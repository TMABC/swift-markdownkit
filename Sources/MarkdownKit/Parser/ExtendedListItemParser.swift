import Foundation

/// 一个用于解析列表项的块解析器。有两种类型的列表项：
/// _bullet list items_ 和_ordered list items_。它们使用`listItem`块表示，
/// 使用`bullet`或`ordered list type`。`ExtendedListItemParser`也
/// 接受“:”作为无序列表符号。这在定义列表中使用。
open class ExtendedListItemParser: ListItemParser {
    public required init(docParser: DocumentParser) {
        super.init(docParser: docParser, bulletChars: ["-", "+", "*", ":"])
    }
}
