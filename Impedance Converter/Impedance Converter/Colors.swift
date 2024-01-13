import SwiftUI

extension Color {
    // Custom initializer for hex color
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00ff00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000ff) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    // Function to adjust brightness
    func adjusted(brightness: Double) -> Color {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return self
        }

        let r = Double(components[0])
        let g = Double(components[1])
        let b = Double(components[2])

        return Color(red: min(r * brightness, 1.0),
                     green: min(g * brightness, 1.0),
                     blue: min(b * brightness, 1.0))
    }

    // Base Color Definitions
    static let baseLabelTextColor = Color(hex: "#969F91")
    static let baseComponentBackgroundColor = Color(hex: "#232521")
    static let baseDarkRed = Color(hex: "#400705")
    static let basePrimaryOrange = Color(hex: "#EF8046")
    static let baseSecondaryRed = Color(hex: "#D33533")
    static let baseAppBackgroundColor = Color(hex: "#A1BB9B")
    static let baseSegmentControlTintColor = Color(hex: "#D9CDAD").adjusted(brightness: 1.2)
    static let dimGridView = Color(hex:"#FFFFFF").adjusted(brightness:0.4)
    static let smithOuterCircle = Color(hex: "#CCCCCC")
    static let smithBackground = Color(hex: "#3A0C08").adjusted(brightness: 0.6)
}
