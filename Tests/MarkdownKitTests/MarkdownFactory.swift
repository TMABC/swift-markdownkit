import Foundation
@testable import MarkdownKit

protocol MarkdownKitFactory {
}

extension MarkdownKitFactory {
    
    func document(_ bs: MarkdownBlock...) -> MarkdownBlock {
        return .document(ContiguousArray(bs))
    }
    
    func paragraph(_ strs: String?...) -> MarkdownBlock {
        var res = MarkdownText()
        for str in strs {
            if let str = str {
                if let last = res.last {
                    switch last {
                    case .softLineBreak, .hardLineBreak:
                        break
                    default:
                        res.append(fragment: .softLineBreak)
                    }
                }
                
                res.append(fragment: .text(Substring(str)))
            } else {
                res.append(fragment: .hardLineBreak)
            }
        }
        return .paragraph(res)
    }
    
    func paragraph(_ fragments: MarkdownTextFragment...) -> MarkdownBlock {
        var res = MarkdownText()
        for fragment in fragments {
            res.append(fragment: fragment)
        }
        return .paragraph(res)
    }
    
    func emph(_ fragments: MarkdownTextFragment...) -> MarkdownTextFragment {
        var res = MarkdownText()
        for fragment in fragments {
            res.append(fragment: fragment)
        }
        return .emph(res)
    }
    
    func strong(_ fragments: MarkdownTextFragment...) -> MarkdownTextFragment {
        var res = MarkdownText()
        for fragment in fragments {
            res.append(fragment: fragment)
        }
        return .strong(res)
    }
    
    func link(_ dest: String?, _ title: String?, _ fragments: MarkdownTextFragment...) -> MarkdownTextFragment {
        var res = MarkdownText()
        for fragment in fragments {
            res.append(fragment: fragment)
        }
        return .link(res, dest, title)
    }
    
    func image(_ dest: String?, _ title: String?, _ fragments: MarkdownTextFragment...) -> MarkdownTextFragment {
        var res = MarkdownText()
        for fragment in fragments {
            res.append(fragment: fragment)
        }
        return .image(res, dest, title)
    }
    
    func custom(_ factory: (MarkdownText) -> MarkdownCustomTextFragment,
                _ fragments: MarkdownTextFragment...) -> MarkdownTextFragment {
        var res = MarkdownText()
        for fragment in fragments {
            res.append(fragment: fragment)
        }
        return .custom(factory(res))
    }
    
    func atxHeading(_ level: Int, _ title: String) -> MarkdownBlock {
        return .heading(level, MarkdownText(Substring(title)))
    }
    
    func setextHeading(_ level: Int, _ strs: String?...) -> MarkdownBlock {
        var res = MarkdownText()
        for str in strs {
            if let str = str {
                if let last = res.last {
                    switch last {
                    case .softLineBreak, .hardLineBreak:
                        break
                    default:
                        res.append(fragment: .softLineBreak)
                    }
                }
                res.append(fragment: .text(Substring(str)))
            } else {
                res.append(fragment: .hardLineBreak)
            }
        }
        return .heading(level, res)
    }
    
    func blockquote(_ bs: MarkdownBlock...) -> MarkdownBlock {
        return .blockquote(ContiguousArray(bs))
    }
    
    func indentedCode(_ strs: Substring...) -> MarkdownBlock {
        return .indentedCode(ContiguousArray(strs))
    }
    
    func fencedCode(_ info: String?, _ strs: Substring...) -> MarkdownBlock {
        return .fencedCode(info, ContiguousArray(strs))
    }
    
    func list(_ num: Int, tight: Bool = true, _ bs: MarkdownBlock...) -> MarkdownBlock {
        return .list(num, tight, ContiguousArray(bs))
    }
    
    func list(tight: Bool = true, _ bs: MarkdownBlock...) -> MarkdownBlock {
        return .list(nil, tight, ContiguousArray(bs))
    }
    
    func listItem(_ num: Int, _ sep: Character, tight: Bool = false, _ bs: MarkdownBlock...) -> MarkdownBlock {
        return .listItem(.ordered(num, sep), tight, ContiguousArray(bs))
    }
    
    func listItem(_ bullet: Character, tight: Bool = false, _ bs: MarkdownBlock...) -> MarkdownBlock {
        return .listItem(.bullet(bullet), tight, ContiguousArray(bs))
    }
    
    func htmlBlock(_ lines: Substring...) -> MarkdownBlock {
        return .htmlBlock(ContiguousArray(lines))
    }
    
    func referenceDef(_ label: String, _ dest: Substring, _ title: Substring...) -> MarkdownBlock {
        return .referenceDef(label, dest, ContiguousArray(title))
    }
    
    func table(_ hdr: [Substring?], _ algn: [MarkdownTableAlignment], _ rw: [Substring?]...) -> MarkdownBlock {
        func toRow(_ arr: [Substring?]) -> MarkdownTableRow {
            var res = MarkdownTableRow()
            for a in arr {
                if let str = a {
                    let components = str.components(separatedBy: "$")
                    if components.count <= 1 {
                        res.append(MarkdownText(str))
                    } else {
                        var text = MarkdownText()
                        for component in components {
                            text.append(fragment: .text(Substring(component)))
                        }
                        res.append(text)
                    }
                } else {
                    res.append(MarkdownText())
                }
            }
            return res
        }
        var rows = MarkdownTableRows()
        for r in rw {
            rows.append(toRow(r))
        }
        return .table(toRow(hdr), ContiguousArray(algn), rows)
    }
    
    func definitionList(_ decls: (Substring, [[MarkdownBlock]])...) -> MarkdownBlock {
        var defs = MarkdownDefinitions()
        for decl in decls {
            var res = MarkdownBlocks()
            var tight = true
            for blocks in decl.1 {
                var content = MarkdownBlocks()
                for block in blocks {
                    content.append(block)
                }
                res.append(.listItem(.bullet(":"), tight, content))
                if content.count > 1 {
                    tight = false
                }
            }
            defs.append(MarkdownDefinition(item: MarkdownText(decl.0), descriptions: res))
        }
        return .definitionList(defs)
    }
}
