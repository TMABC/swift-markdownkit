#if os(iOS) || os(watchOS) || os(tvOS)

import UIKit

extension UIColor {
    public var hexString: String {
        guard let components = self.cgColor.components else {
            return "#FFFFFF"
        }
        var red = 0
        var green = 0
        var blue = 0
        if components.count >= 3 {
            red = Int(round(components[0] * 0xff))
            green = Int(round(components[1] * 0xff))
            blue = Int(round(components[2] * 0xff))
        } else if components.count >= 1 {
            red = Int(round(components[0] * 0xff))
            green = Int(round(components[0] * 0xff))
            blue = Int(round(components[0] * 0xff))
        }
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

#elseif os(macOS)

import Cocoa

extension NSColor {
    
    public var hexString: String {
        guard let rgb = self.usingColorSpace(NSColorSpace.deviceRGB) else {
            return "#FFFFFF"
        }
        let red   = Int(round(rgb.redComponent * 0xff))
        let green = Int(round(rgb.greenComponent * 0xff))
        let blue  = Int(round(rgb.blueComponent * 0xff))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

public let mdDefaultColor = NSColor.textColor.hexString
public let mdDefaultBackgroundColor = NSColor.textBackgroundColor.hexString

#endif

#if os(iOS)

public let mdDefaultColor = UIColor.label.hexString
public let mdDefaultBackgroundColor = UIColor.systemBackground.hexString

#elseif os(tvOS)

public let mdDefaultColor = UIColor.label.hexString
public let mdDefaultBackgroundColor = UIColor.white.hexString

#elseif os(watchOS)

public let mdDefaultColor = UIColor.black.hexString
public let mdDefaultBackgroundColor = UIColor.white.hexString

#endif
