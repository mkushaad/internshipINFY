import SwiftUI

extension Color {
    // Shared Theme Colors
    static let themeBackground = Color(hex: "F8F6F2")
    static let themeAccent = Color(hex: "B08A45")
    static let themeText = Color(hex: "2D2A26")
    static let themeCard = Color.white

    // Hex Helper
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
