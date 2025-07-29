import SwiftUI

enum UIConstants {
    // Layout
    static let cornerRadius: CGFloat = 8
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 8
    static let iconSize: CGFloat = 24

    // Colors
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let error = Color.red
        static let success = Color.green
        static let warning = Color.orange
        static let background = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    }

    // Fonts
    enum Fonts {
        static let title = Font.title
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption
        static let footnote = Font.footnote
    }

    // Animation
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}
