import Foundation

public struct NamedCharacters {
    public static func decode(entity: String) -> Character? {
        if let ch = NamedCharacters.namedCharacterMap[entity] {
            return ch
        } else if entity.hasPrefix("&#X") || entity.hasPrefix("&#x") {
            let num = String(entity[entity.index(entity.startIndex, offsetBy: 3)...].dropLast())
            return NamedCharacters.character(from: num, base: 16)
        } else if entity.hasPrefix("&#") {
            let num = String(entity[entity.index(entity.startIndex, offsetBy: 2)...].dropLast())
            return NamedCharacters.character(from: num, base: 10)
        } else {
            return nil
        }
    }
    
    private static func character(from string: String, base: Int) -> Character? {
        guard let code = UInt32(string, radix: base),
              let unicodeScalar = UnicodeScalar(code) else {
            return nil
        }
        return Character(unicodeScalar)
    }
    
    // 使用懒加载的静态属性
    public static var namedCharacterMap: [String: Character] = {
        guard let url = Bundle.main.url(forResource: "named_characters", withExtension: "json") else {
            fatalError("无法找到named_characters.json文件")
        }
        
        do {
            let data = try Data(contentsOf: url)
            let jsonDecoder = JSONDecoder()
            let jsonObject = try jsonDecoder.decode([String: String].self, from: data)
            
            var map: [String: Character] = [:]
            for (key,value) in jsonObject {
                map[key] = Character(value)
            }
            
            return map
        } catch {
            fatalError("解析named_characters.json文件出错: \(error)")
        }
    }()
    
    public static let characterNameMap: [Character : String] = {
        var map = [Character : String](minimumCapacity: NamedCharacters.namedCharacterMap.count)
        for (k, v) in NamedCharacters.namedCharacterMap {
            map[v] = k
        }
        return map
    }()
}
