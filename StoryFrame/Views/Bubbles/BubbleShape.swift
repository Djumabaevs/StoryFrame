import SwiftUI

struct BubbleShape: Shape {
    let bubbleType: String
    let tailPosition: CGPoint
    let tailStyle: String
    let center: CGPoint
    let size: CGSize

    var rect: CGRect {
        CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    func path(in drawRect: CGRect) -> Path {
        var path = Path()

        switch bubbleType {
        case "oval":
            path.addEllipse(in: rect)
            if tailStyle != "none" {
                addTail(to: &path)
            }

        case "rectangle":
            let cornerRadius: CGFloat = 8
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            if tailStyle != "none" {
                addTail(to: &path)
            }

        case "cloud":
            path = cloudPath()
            if tailStyle != "none" {
                addCloudTail(to: &path)
            }

        case "burst":
            path = burstPath(points: 12)

        case "whisper":
            path.addEllipse(in: rect)
            if tailStyle != "none" {
                addTail(to: &path)
            }

        case "electronic":
            path = electronicPath()
            if tailStyle != "none" {
                addTail(to: &path)
            }

        case "drip":
            path = dripPath()

        default:
            path.addEllipse(in: rect)
            if tailStyle != "none" {
                addTail(to: &path)
            }
        }

        return path
    }

    // MARK: - Tail Drawing

    private func addTail(to path: inout Path) {
        let tailBase = closestPointOnEllipse(to: tailPosition)

        let direction = CGPoint(
            x: tailPosition.x - tailBase.x,
            y: tailPosition.y - tailBase.y
        )
        let perpendicular = direction.perpendicular().normalized() * 10

        let baseLeft = CGPoint(x: tailBase.x + perpendicular.x, y: tailBase.y + perpendicular.y)
        let baseRight = CGPoint(x: tailBase.x - perpendicular.x, y: tailBase.y - perpendicular.y)

        if tailStyle == "curved" {
            let controlOffset = direction.normalized() * 15
            let control = CGPoint(x: tailBase.x + controlOffset.x, y: tailBase.y + controlOffset.y)

            path.move(to: baseLeft)
            path.addQuadCurve(to: tailPosition, control: control)
            path.addQuadCurve(to: baseRight, control: control)
            path.addLine(to: baseLeft)
        } else {
            path.move(to: baseLeft)
            path.addLine(to: tailPosition)
            path.addLine(to: baseRight)
            path.addLine(to: baseLeft)
        }
    }

    private func addCloudTail(to path: inout Path) {
        let tailBase = closestPointOnEllipse(to: tailPosition)

        // Cloud tail uses small circles leading to the tail point
        let dx = tailPosition.x - tailBase.x
        let dy = tailPosition.y - tailBase.y
        let distance = sqrt(dx * dx + dy * dy)
        let bubbleCount = max(2, Int(distance / 15))

        for i in 1...bubbleCount {
            let t = CGFloat(i) / CGFloat(bubbleCount + 1)
            let x = tailBase.x + dx * t
            let y = tailBase.y + dy * t
            let radius = 8 * (1 - t * 0.5)

            path.addEllipse(in: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }
    }

    private func closestPointOnEllipse(to point: CGPoint) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let angle = atan2(dy, dx)
        return CGPoint(
            x: center.x + cos(angle) * size.width / 2,
            y: center.y + sin(angle) * size.height / 2
        )
    }

    // MARK: - Shape Paths

    private func cloudPath() -> Path {
        var path = Path()
        let bubbleCount = 10
        let radius = min(size.width, size.height) / 5

        // Outer cloud bubbles
        for i in 0..<bubbleCount {
            let angle = (CGFloat(i) / CGFloat(bubbleCount)) * 2 * .pi
            let x = center.x + cos(angle) * (size.width/2 - radius * 0.5)
            let y = center.y + sin(angle) * (size.height/2 - radius * 0.5)
            path.addEllipse(in: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }

        // Fill center
        path.addEllipse(in: rect.insetBy(dx: radius * 0.8, dy: radius * 0.8))

        return path
    }

    private func burstPath(points: Int) -> Path {
        var path = Path()
        let outerRadius = min(size.width, size.height) / 2
        let innerRadius = outerRadius * 0.6

        for i in 0..<(points * 2) {
            let angle = (CGFloat(i) / CGFloat(points * 2)) * 2 * .pi - .pi/2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }

    private func electronicPath() -> Path {
        var path = Path()
        let notch: CGFloat = 8

        path.move(to: CGPoint(x: rect.minX + notch, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + notch))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + notch))
        path.closeSubpath()

        return path
    }

    private func dripPath() -> Path {
        var path = Path()

        // Main oval (upper 80% of height)
        let ovalRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height * 0.8
        )
        path.addEllipse(in: ovalRect)

        // Add drips at the bottom
        let dripCount = 3
        let dripWidth = rect.width / CGFloat(dripCount + 1)

        for i in 1...dripCount {
            let x = rect.minX + dripWidth * CGFloat(i)
            let dripHeight = CGFloat.random(in: 12...20)
            let startY = ovalRect.maxY - 5

            path.move(to: CGPoint(x: x - 4, y: startY))
            path.addQuadCurve(
                to: CGPoint(x: x, y: startY + dripHeight),
                control: CGPoint(x: x - 6, y: startY + dripHeight/2)
            )
            path.addQuadCurve(
                to: CGPoint(x: x + 4, y: startY),
                control: CGPoint(x: x + 6, y: startY + dripHeight/2)
            )
        }

        return path
    }
}

// MARK: - Bubble Style Modifier

extension View {
    func whisperStyle() -> some View {
        self.overlay(
            BubbleShape(
                bubbleType: "whisper",
                tailPosition: .zero,
                tailStyle: "none",
                center: .zero,
                size: .zero
            )
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
        )
    }
}

// MARK: - Preview Bubble

struct BubblePreview: View {
    let type: BubbleType

    var body: some View {
        BubbleShape(
            bubbleType: type.rawValue,
            tailPosition: CGPoint(x: 60, y: 90),
            tailStyle: "curved",
            center: CGPoint(x: 50, y: 40),
            size: CGSize(width: 80, height: 50)
        )
        .fill(Color.white)
        .overlay(
            BubbleShape(
                bubbleType: type.rawValue,
                tailPosition: CGPoint(x: 60, y: 90),
                tailStyle: "curved",
                center: CGPoint(x: 50, y: 40),
                size: CGSize(width: 80, height: 50)
            )
            .stroke(Color.black, lineWidth: 2)
        )
        .frame(width: 100, height: 100)
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(BubbleType.allCases) { type in
            HStack {
                Text(type.displayName)
                    .frame(width: 80, alignment: .leading)
                BubblePreview(type: type)
            }
        }
    }
    .padding()
}
