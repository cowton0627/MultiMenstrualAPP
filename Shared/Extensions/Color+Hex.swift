//
//  Color+Hex.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/1.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let s = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHexString() -> String {
        UIColor(self).toHexString()
    }
    
    static func tryFromHex(_ hex: String) -> Color? {
        let s = hex.replacingOccurrences(of: "#", with: "")
        var x: UInt64 = 0
        guard s.count == 6,
              Scanner(string: s).scanHexInt64(&x) == true else { return nil }
        return Color(hex: hex)
    }
}

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0, 
            g: CGFloat = 0,
            b: CGFloat = 0,
            a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return "#000000" }
        return String(format: "#%02X%02X%02X", 
                      Int(round(r*255)), Int(round(g*255)), Int(round(b*255)))
    }
}

