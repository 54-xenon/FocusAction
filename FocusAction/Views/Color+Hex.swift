//
//  Color+Hex.swift
//  FocusAction
//
//  iOS/watchOS共通のView部品
//  Tagの背景色をSwiftDataにString(hex)として保存するための相互変換
//  UIKit(UIColor)に依存せず、SwiftUI標準APIのみで完結させることでwatchOSでも共有できるようにしている

import SwiftUI

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString.removeAll { $0 == "#" }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }

    func toHexString() -> String {
        let resolved = resolve(in: EnvironmentValues())
        return String(
            format: "#%02X%02X%02X",
            Int((resolved.red * 255).rounded()),
            Int((resolved.green * 255).rounded()),
            Int((resolved.blue * 255).rounded())
        )
    }
}
