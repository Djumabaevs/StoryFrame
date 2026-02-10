// Last reviewed: 2026-02-10
import SwiftUI

struct AppColors {
    // MARK: - Light Mode
    struct Light {
        static let background = Color(hex: "#FFFFFF")
        static let secondaryBackground = Color(hex: "#F7F7F7")
        static let cardBackground = Color(hex: "#FFFFFF")
        static let toolbar = Color(hex: "#FAFAFA")
        static let border = Color(hex: "#E5E5E5")
        static let textPrimary = Color(hex: "#1A1A1A")
        static let textSecondary = Color(hex: "#666666")
        static let accentOrange = Color(hex: "#FF6B35")
        static let accentPurple = Color(hex: "#7B68EE")
        static let panelBlue = Color(hex: "#4A90D9")
        static let successGreen = Color(hex: "#34C759")
    }

    // MARK: - Dark Mode
    struct Dark {
        static let background = Color(hex: "#1C1C1E")
        static let secondaryBackground = Color(hex: "#2C2C2E")
        static let cardBackground = Color(hex: "#3A3A3C")
        static let toolbar = Color(hex: "#2C2C2E")
        static let border = Color(hex: "#48484A")
        static let textPrimary = Color(hex: "#FFFFFF")
        static let textSecondary = Color(hex: "#A0A0A0")
        static let accentOrange = Color(hex: "#FF8C5A")
        static let accentPurple = Color(hex: "#9D8DF1")
        static let panelBlue = Color(hex: "#5AA3E8")
        static let successGreen = Color(hex: "#30D158")
    }
}

struct AppFonts {
    static func projectTitle() -> Font {
        .system(size: 24, weight: .bold, design: .rounded)
    }

    static func toolLabel() -> Font {
        .system(size: 11, weight: .medium)
    }

    static func pageNumber() -> Font {
        .system(size: 14, weight: .medium, design: .monospaced)
    }

    static func menuItem() -> Font {
        .system(size: 16, weight: .regular)
    }

    static func sectionHeader() -> Font {
        .system(size: 14, weight: .semibold)
    }

    static func bubbleText(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

struct AppConstants {
    static let defaultGutterWidth: CGFloat = 10
    static let minPanelSize: CGFloat = 50
    static let defaultBubbleSize = CGSize(width: 150, height: 80)
    static let maxUndoSteps = 50
    static let autoSaveInterval: TimeInterval = 30
    static let thumbnailSize = CGSize(width: 120, height: 180)

    struct Animation {
        static let quick: Double = 0.15
        static let standard: Double = 0.25
        static let slow: Double = 0.4
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Panel Template Presets
struct PanelTemplatePresets {
    static func createBuiltInTemplates(pageSize: CGSize) -> [(name: String, category: String, panels: [[CGPoint]])] {
        let w = pageSize.width
        let h = pageSize.height
        let margin: CGFloat = 20
        let gutter: CGFloat = 10

        return [
            // Action Templates
            (
                name: "Diagonal Split",
                category: "action",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h * 0.6), CGPoint(x: margin, y: h * 0.4)],
                    [CGPoint(x: margin, y: h * 0.4 + gutter), CGPoint(x: w - margin, y: h * 0.6 + gutter),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: margin, y: h - margin)]
                ]
            ),
            (
                name: "Dynamic Three",
                category: "action",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w * 0.6, y: margin),
                     CGPoint(x: w * 0.5, y: h * 0.5), CGPoint(x: margin, y: h * 0.5)],
                    [CGPoint(x: w * 0.6 + gutter, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h * 0.7), CGPoint(x: w * 0.5 + gutter, y: h * 0.5)],
                    [CGPoint(x: margin, y: h * 0.5 + gutter), CGPoint(x: w - margin, y: h * 0.7 + gutter),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: margin, y: h - margin)]
                ]
            ),

            // Conversation Templates
            (
                name: "Two Equal",
                category: "conversation",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w/2 - gutter/2, y: margin),
                     CGPoint(x: w/2 - gutter/2, y: h - margin), CGPoint(x: margin, y: h - margin)],
                    [CGPoint(x: w/2 + gutter/2, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: w/2 + gutter/2, y: h - margin)]
                ]
            ),
            (
                name: "Three Horizontal",
                category: "conversation",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h/3 - gutter/2), CGPoint(x: margin, y: h/3 - gutter/2)],
                    [CGPoint(x: margin, y: h/3 + gutter/2), CGPoint(x: w - margin, y: h/3 + gutter/2),
                     CGPoint(x: w - margin, y: h * 2/3 - gutter/2), CGPoint(x: margin, y: h * 2/3 - gutter/2)],
                    [CGPoint(x: margin, y: h * 2/3 + gutter/2), CGPoint(x: w - margin, y: h * 2/3 + gutter/2),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: margin, y: h - margin)]
                ]
            ),
            (
                name: "Four Grid",
                category: "conversation",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w/2 - gutter/2, y: margin),
                     CGPoint(x: w/2 - gutter/2, y: h/2 - gutter/2), CGPoint(x: margin, y: h/2 - gutter/2)],
                    [CGPoint(x: w/2 + gutter/2, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h/2 - gutter/2), CGPoint(x: w/2 + gutter/2, y: h/2 - gutter/2)],
                    [CGPoint(x: margin, y: h/2 + gutter/2), CGPoint(x: w/2 - gutter/2, y: h/2 + gutter/2),
                     CGPoint(x: w/2 - gutter/2, y: h - margin), CGPoint(x: margin, y: h - margin)],
                    [CGPoint(x: w/2 + gutter/2, y: h/2 + gutter/2), CGPoint(x: w - margin, y: h/2 + gutter/2),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: w/2 + gutter/2, y: h - margin)]
                ]
            ),

            // Establishing Templates
            (
                name: "Hero Top",
                category: "establishing",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h * 0.6), CGPoint(x: margin, y: h * 0.6)],
                    [CGPoint(x: margin, y: h * 0.6 + gutter), CGPoint(x: w/2 - gutter/2, y: h * 0.6 + gutter),
                     CGPoint(x: w/2 - gutter/2, y: h - margin), CGPoint(x: margin, y: h - margin)],
                    [CGPoint(x: w/2 + gutter/2, y: h * 0.6 + gutter), CGPoint(x: w - margin, y: h * 0.6 + gutter),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: w/2 + gutter/2, y: h - margin)]
                ]
            ),
            (
                name: "L-Shape",
                category: "establishing",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w * 0.65, y: margin),
                     CGPoint(x: w * 0.65, y: h * 0.65), CGPoint(x: margin, y: h * 0.65)],
                    [CGPoint(x: w * 0.65 + gutter, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h * 0.65), CGPoint(x: w * 0.65 + gutter, y: h * 0.65)],
                    [CGPoint(x: margin, y: h * 0.65 + gutter), CGPoint(x: w - margin, y: h * 0.65 + gutter),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: margin, y: h - margin)]
                ]
            ),

            // Montage Templates
            (
                name: "Six Grid",
                category: "montage",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w/3 - gutter/2, y: margin),
                     CGPoint(x: w/3 - gutter/2, y: h/2 - gutter/2), CGPoint(x: margin, y: h/2 - gutter/2)],
                    [CGPoint(x: w/3 + gutter/2, y: margin), CGPoint(x: w * 2/3 - gutter/2, y: margin),
                     CGPoint(x: w * 2/3 - gutter/2, y: h/2 - gutter/2), CGPoint(x: w/3 + gutter/2, y: h/2 - gutter/2)],
                    [CGPoint(x: w * 2/3 + gutter/2, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h/2 - gutter/2), CGPoint(x: w * 2/3 + gutter/2, y: h/2 - gutter/2)],
                    [CGPoint(x: margin, y: h/2 + gutter/2), CGPoint(x: w/3 - gutter/2, y: h/2 + gutter/2),
                     CGPoint(x: w/3 - gutter/2, y: h - margin), CGPoint(x: margin, y: h - margin)],
                    [CGPoint(x: w/3 + gutter/2, y: h/2 + gutter/2), CGPoint(x: w * 2/3 - gutter/2, y: h/2 + gutter/2),
                     CGPoint(x: w * 2/3 - gutter/2, y: h - margin), CGPoint(x: w/3 + gutter/2, y: h - margin)],
                    [CGPoint(x: w * 2/3 + gutter/2, y: h/2 + gutter/2), CGPoint(x: w - margin, y: h/2 + gutter/2),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: w * 2/3 + gutter/2, y: h - margin)]
                ]
            ),
            (
                name: "Vertical Strip",
                category: "montage",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h/5 - gutter/2), CGPoint(x: margin, y: h/5 - gutter/2)],
                    [CGPoint(x: margin, y: h/5 + gutter/2), CGPoint(x: w - margin, y: h/5 + gutter/2),
                     CGPoint(x: w - margin, y: h * 2/5 - gutter/2), CGPoint(x: margin, y: h * 2/5 - gutter/2)],
                    [CGPoint(x: margin, y: h * 2/5 + gutter/2), CGPoint(x: w - margin, y: h * 2/5 + gutter/2),
                     CGPoint(x: w - margin, y: h * 3/5 - gutter/2), CGPoint(x: margin, y: h * 3/5 - gutter/2)],
                    [CGPoint(x: margin, y: h * 3/5 + gutter/2), CGPoint(x: w - margin, y: h * 3/5 + gutter/2),
                     CGPoint(x: w - margin, y: h * 4/5 - gutter/2), CGPoint(x: margin, y: h * 4/5 - gutter/2)],
                    [CGPoint(x: margin, y: h * 4/5 + gutter/2), CGPoint(x: w - margin, y: h * 4/5 + gutter/2),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: margin, y: h - margin)]
                ]
            ),

            // Splash Templates
            (
                name: "Full Page",
                category: "splash",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: margin, y: h - margin)]
                ]
            ),
            (
                name: "Bleed Full",
                category: "splash",
                panels: [
                    [CGPoint(x: 0, y: 0), CGPoint(x: w, y: 0),
                     CGPoint(x: w, y: h), CGPoint(x: 0, y: h)]
                ]
            ),

            // Manga Templates
            (
                name: "Manga Dramatic",
                category: "manga",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w * 0.4, y: margin),
                     CGPoint(x: w * 0.35, y: h * 0.45), CGPoint(x: margin, y: h * 0.5)],
                    [CGPoint(x: w * 0.4 + gutter, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h * 0.35), CGPoint(x: w * 0.35 + gutter, y: h * 0.45)],
                    [CGPoint(x: margin, y: h * 0.5 + gutter), CGPoint(x: w * 0.55, y: h * 0.35 + gutter),
                     CGPoint(x: w * 0.55, y: h - margin), CGPoint(x: margin, y: h - margin)],
                    [CGPoint(x: w * 0.55 + gutter, y: h * 0.35 + gutter), CGPoint(x: w - margin, y: h * 0.35 + gutter),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: w * 0.55 + gutter, y: h - margin)]
                ]
            ),
            (
                name: "Manga Speed",
                category: "manga",
                panels: [
                    [CGPoint(x: margin, y: margin), CGPoint(x: w - margin, y: margin),
                     CGPoint(x: w - margin, y: h * 0.25), CGPoint(x: margin, y: h * 0.3)],
                    [CGPoint(x: margin, y: h * 0.3 + gutter), CGPoint(x: w * 0.5, y: h * 0.25 + gutter),
                     CGPoint(x: w * 0.45, y: h * 0.6), CGPoint(x: margin, y: h * 0.65)],
                    [CGPoint(x: w * 0.5 + gutter, y: h * 0.25 + gutter), CGPoint(x: w - margin, y: h * 0.25 + gutter),
                     CGPoint(x: w - margin, y: h * 0.65), CGPoint(x: w * 0.45 + gutter, y: h * 0.6)],
                    [CGPoint(x: margin, y: h * 0.65 + gutter), CGPoint(x: w - margin, y: h * 0.65 + gutter),
                     CGPoint(x: w - margin, y: h - margin), CGPoint(x: margin, y: h - margin)]
                ]
            )
        ]
    }
}
