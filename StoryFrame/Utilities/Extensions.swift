import SwiftUI
import UIKit

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - CGPoint Extensions
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }

    func normalized() -> CGPoint {
        let length = sqrt(x * x + y * y)
        guard length > 0 else { return .zero }
        return CGPoint(x: x / length, y: y / length)
    }

    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    func perpendicular() -> CGPoint {
        CGPoint(x: -y, y: x)
    }

    func rotated(by angle: CGFloat) -> CGPoint {
        let cosA = cos(angle)
        let sinA = sin(angle)
        return CGPoint(x: x * cosA - y * sinA, y: x * sinA + y * cosA)
    }
}

// MARK: - CGSize Extensions
extension CGSize {
    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return width / height
    }

    func scaled(to fit: CGSize) -> CGSize {
        let widthRatio = fit.width / width
        let heightRatio = fit.height / height
        let ratio = min(widthRatio, heightRatio)
        return CGSize(width: width * ratio, height: height * ratio)
    }
}

// MARK: - CGRect Extensions
extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    func contains(point: CGPoint, tolerance: CGFloat = 0) -> Bool {
        let expanded = insetBy(dx: -tolerance, dy: -tolerance)
        return expanded.contains(point)
    }

    func scaled(by factor: CGFloat) -> CGRect {
        CGRect(
            x: origin.x * factor,
            y: origin.y * factor,
            width: width * factor,
            height: height * factor
        )
    }
}

// MARK: - Path Extensions
extension Path {
    static func polygon(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Date Extensions
extension Date {
    func relativeFormat() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func shortFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Array Extensions
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Geometry Helpers
struct GeometryHelpers {
    static func closestPointOnEllipse(center: CGPoint, size: CGSize, to point: CGPoint) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let angle = atan2(dy, dx)
        return CGPoint(
            x: center.x + cos(angle) * size.width / 2,
            y: center.y + sin(angle) * size.height / 2
        )
    }

    static func pointInPolygon(_ point: CGPoint, polygon: [CGPoint]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let xi = polygon[i].x, yi = polygon[i].y
            let xj = polygon[j].x, yj = polygon[j].y

            if ((yi > point.y) != (yj > point.y)) &&
                (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi) {
                inside = !inside
            }
            j = i
        }

        return inside
    }

    static func centroid(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { $0 + $1 }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}

// MARK: - Image Extensions
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func thumbnail(maxDimension: CGFloat) -> UIImage {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return resized(to: newSize)
    }
}

// MARK: - Angle Extension
extension Angle {
    var normalized: Angle {
        var degrees = self.degrees.truncatingRemainder(dividingBy: 360)
        if degrees < 0 { degrees += 360 }
        return .degrees(degrees)
    }
}

// MARK: - Canvas Coordinate System
/// Helper for converting between screen coordinates and canvas (page) coordinates
struct CanvasCoordinateSystem {
    let zoomScale: CGFloat
    let panOffset: CGSize
    let pageSize: CGSize
    let viewSize: CGSize

    /// The combined display scale (includes fit-to-screen and user zoom)
    var displayScale: CGFloat {
        let fitScale = min(
            (viewSize.width - 40) / pageSize.width,
            (viewSize.height - 40) / pageSize.height
        )
        return fitScale * zoomScale
    }

    /// Convert screen touch point to canvas (page) coordinates
    /// Use this when processing touch/drag gestures to get the position in page space
    func screenToCanvas(_ screenPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: screenPoint.x / displayScale,
            y: screenPoint.y / displayScale
        )
    }

    /// Convert canvas (page) coordinates to screen position for rendering
    /// Use this when positioning elements on screen
    func canvasToScreen(_ canvasPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: canvasPoint.x * displayScale,
            y: canvasPoint.y * displayScale
        )
    }

    /// Convert canvas rect to screen rect (for selection boxes, hit testing)
    func canvasRectToScreen(_ canvasRect: CGRect) -> CGRect {
        return canvasRect.scaled(by: displayScale)
    }

    /// Get the size of the canvas in screen coordinates
    var screenCanvasSize: CGSize {
        CGSize(
            width: pageSize.width * displayScale,
            height: pageSize.height * displayScale
        )
    }

    /// Get visible canvas area in page coordinates
    var visibleCanvasRect: CGRect {
        let topLeft = screenToCanvas(.zero)
        let size = CGSize(
            width: viewSize.width / displayScale,
            height: viewSize.height / displayScale
        )
        return CGRect(origin: topLeft, size: size)
    }

    /// Center point of visible canvas in page coordinates (for placing new elements)
    var visibleCanvasCenter: CGPoint {
        let rect = visibleCanvasRect
        return CGPoint(x: rect.midX, y: rect.midY)
    }
}
