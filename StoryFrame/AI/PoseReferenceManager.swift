import Vision
import UIKit
import SwiftUI
import ARKit

// MARK: - Detected Pose Model

struct DetectedPose: Identifiable {
    let id = UUID()
    let joints: [String: CGPoint]
    let confidence: Float

    // Joint connections for skeleton drawing
    static let connections: [(String, String)] = [
        // Spine
        ("root", "spine"),
        ("spine", "neck"),
        ("neck", "head"),

        // Left arm
        ("neck", "left_shoulder"),
        ("left_shoulder", "left_elbow"),
        ("left_elbow", "left_wrist"),

        // Right arm
        ("neck", "right_shoulder"),
        ("right_shoulder", "right_elbow"),
        ("right_elbow", "right_wrist"),

        // Left leg
        ("root", "left_hip"),
        ("left_hip", "left_knee"),
        ("left_knee", "left_ankle"),

        // Right leg
        ("root", "right_hip"),
        ("right_hip", "right_knee"),
        ("right_knee", "right_ankle")
    ]

    func draw(in context: GraphicsContext, scale: CGFloat, color: Color = .blue, lineWidth: CGFloat = 2) {
        // Draw connections
        for (from, to) in Self.connections {
            if let fromPoint = joints[from], let toPoint = joints[to] {
                var path = Path()
                path.move(to: CGPoint(x: fromPoint.x * scale, y: fromPoint.y * scale))
                path.addLine(to: CGPoint(x: toPoint.x * scale, y: toPoint.y * scale))
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }

        // Draw joints
        for (_, point) in joints {
            let scaledPoint = CGPoint(x: point.x * scale, y: point.y * scale)
            let circle = Path(ellipseIn: CGRect(
                x: scaledPoint.x - 4,
                y: scaledPoint.y - 4,
                width: 8,
                height: 8
            ))
            context.fill(circle, with: .color(color))
        }
    }
}

// MARK: - Pose Reference Manager

@MainActor
final class PoseReferenceManager: ObservableObject {
    @Published var detectedPose: DetectedPose?
    @Published var isProcessing = false

    func detectPose(in image: UIImage) async -> DetectedPose? {
        guard let cgImage = image.cgImage else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        // Try 3D pose detection first (iOS 17+)
        if #available(iOS 17.0, *) {
            if let pose = await detect3DPose(cgImage: cgImage) {
                detectedPose = pose
                return pose
            }
        }

        // Fall back to 2D pose detection
        if let pose = await detect2DPose(cgImage: cgImage) {
            detectedPose = pose
            return pose
        }

        return nil
    }

    @available(iOS 17.0, *)
    private func detect3DPose(cgImage: CGImage) async -> DetectedPose? {
        let request = VNDetectHumanBodyPose3DRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])

            guard let observation = request.results?.first else { return nil }

            var joints: [String: CGPoint] = [:]
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

            let jointNames: [(VNHumanBodyPose3DObservation.JointName, String)] = [
                (.root, "root"),
                (.topHead, "head"),
                (.leftShoulder, "left_shoulder"),
                (.rightShoulder, "right_shoulder"),
                (.leftElbow, "left_elbow"),
                (.rightElbow, "right_elbow"),
                (.leftWrist, "left_wrist"),
                (.rightWrist, "right_wrist"),
                (.leftHip, "left_hip"),
                (.rightHip, "right_hip"),
                (.leftKnee, "left_knee"),
                (.rightKnee, "right_knee"),
                (.leftAnkle, "left_ankle"),
                (.rightAnkle, "right_ankle"),
                (.spine, "spine"),
                (.centerHead, "neck")
            ]

            for (visionName, localName) in jointNames {
                // Use pointInImage to get the 2D projection of the 3D joint
                if let point2D = try? observation.pointInImage(visionName) {
                    // Vision coordinates are normalized (0-1) with origin at bottom-left
                    let x = point2D.x * imageSize.width
                    let y = (1 - point2D.y) * imageSize.height
                    joints[localName] = CGPoint(x: x, y: y)
                }
            }

            return DetectedPose(joints: joints, confidence: 1.0)

        } catch {
            print("3D Pose detection failed: \(error)")
            return nil
        }
    }

    private func detect2DPose(cgImage: CGImage) async -> DetectedPose? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])

            guard let observation = request.results?.first else { return nil }

            var joints: [String: CGPoint] = [:]
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

            let jointMapping: [(VNHumanBodyPoseObservation.JointName, String)] = [
                (.root, "root"),
                (.nose, "head"),
                (.neck, "neck"),
                (.leftShoulder, "left_shoulder"),
                (.rightShoulder, "right_shoulder"),
                (.leftElbow, "left_elbow"),
                (.rightElbow, "right_elbow"),
                (.leftWrist, "left_wrist"),
                (.rightWrist, "right_wrist"),
                (.leftHip, "left_hip"),
                (.rightHip, "right_hip"),
                (.leftKnee, "left_knee"),
                (.rightKnee, "right_knee"),
                (.leftAnkle, "left_ankle"),
                (.rightAnkle, "right_ankle")
            ]

            for (visionName, localName) in jointMapping {
                if let point = try? observation.recognizedPoint(visionName),
                   point.confidence > 0.3 {
                    let x = point.location.x * imageSize.width
                    let y = (1 - point.location.y) * imageSize.height
                    joints[localName] = CGPoint(x: x, y: y)
                }
            }

            // Add spine point between root and neck if both exist
            if let root = joints["root"], let neck = joints["neck"] {
                joints["spine"] = CGPoint(
                    x: (root.x + neck.x) / 2,
                    y: (root.y + neck.y) / 2
                )
            }

            return DetectedPose(joints: joints, confidence: 1.0)

        } catch {
            print("2D Pose detection failed: \(error)")
            return nil
        }
    }
}

// MARK: - Pose Reference Overlay

struct PoseReferenceOverlay: View {
    let pose: DetectedPose?
    let scale: CGFloat
    let color: Color
    let opacity: Double

    var body: some View {
        if let pose = pose {
            Canvas { context, size in
                pose.draw(
                    in: context,
                    scale: scale,
                    color: color,
                    lineWidth: 3
                )
            }
            .opacity(opacity)
        }
    }
}

// MARK: - Perspective Grid Generator

struct PerspectiveGrid: Identifiable {
    let id = UUID()
    let vanishingPoint1: CGPoint
    let vanishingPoint2: CGPoint?
    let horizonY: CGFloat
    let type: PerspectiveType

    enum PerspectiveType {
        case onePoint
        case twoPoint
        case threePoint
    }

    func draw(in context: GraphicsContext, size: CGSize, color: Color = .cyan.opacity(0.5), lineWidth: CGFloat = 0.5) {
        let vp1 = CGPoint(x: vanishingPoint1.x * size.width, y: vanishingPoint1.y * size.height)
        let horizon = horizonY * size.height

        // Draw horizon line
        var horizonPath = Path()
        horizonPath.move(to: CGPoint(x: 0, y: horizon))
        horizonPath.addLine(to: CGPoint(x: size.width, y: horizon))
        context.stroke(horizonPath, with: .color(color.opacity(0.8)), lineWidth: 1)

        // Draw vanishing point
        let vpCircle = Path(ellipseIn: CGRect(x: vp1.x - 4, y: vp1.y - 4, width: 8, height: 8))
        context.fill(vpCircle, with: .color(color))

        // Draw perspective lines from VP1
        let lineCount = 12
        for i in 0...lineCount {
            let t = CGFloat(i) / CGFloat(lineCount)
            let bottomX = t * size.width

            var path = Path()
            path.move(to: vp1)
            path.addLine(to: CGPoint(x: bottomX, y: size.height))
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }

        // If two-point perspective
        if let vp2 = vanishingPoint2, type == .twoPoint {
            let vp2Scaled = CGPoint(x: vp2.x * size.width, y: vp2.y * size.height)

            // Draw VP2
            let vp2Circle = Path(ellipseIn: CGRect(x: vp2Scaled.x - 4, y: vp2Scaled.y - 4, width: 8, height: 8))
            context.fill(vp2Circle, with: .color(color))

            // Draw perspective lines from VP2
            for i in 0...lineCount {
                let t = CGFloat(i) / CGFloat(lineCount)
                let bottomX = t * size.width

                var path = Path()
                path.move(to: vp2Scaled)
                path.addLine(to: CGPoint(x: bottomX, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
    }
}

// MARK: - Perspective Grid Manager

@MainActor
final class PerspectiveGridManager: ObservableObject {
    @Published var currentGrid: PerspectiveGrid?
    @Published var isScanning = false

    func createOnePointGrid(vanishingPoint: CGPoint, horizonY: CGFloat) {
        currentGrid = PerspectiveGrid(
            vanishingPoint1: vanishingPoint,
            vanishingPoint2: nil,
            horizonY: horizonY,
            type: .onePoint
        )
    }

    func createTwoPointGrid(vp1: CGPoint, vp2: CGPoint, horizonY: CGFloat) {
        currentGrid = PerspectiveGrid(
            vanishingPoint1: vp1,
            vanishingPoint2: vp2,
            horizonY: horizonY,
            type: .twoPoint
        )
    }

    // Create grid from detected planes (LiDAR)
    func createFromPlanes(planes: [ARPlaneAnchor], cameraTransform: simd_float4x4) {
        // Simplified: create a basic 2-point perspective based on detected planes
        // In a full implementation, this would analyze plane orientations

        var horizontalPlanes: [ARPlaneAnchor] = []
        var verticalPlanes: [ARPlaneAnchor] = []

        for plane in planes {
            if plane.alignment == .horizontal {
                horizontalPlanes.append(plane)
            } else {
                verticalPlanes.append(plane)
            }
        }

        // If we have vertical planes, try to extract vanishing points
        if verticalPlanes.count >= 2 {
            // Use plane normals to estimate vanishing points
            createTwoPointGrid(
                vp1: CGPoint(x: 0.2, y: 0.3),
                vp2: CGPoint(x: 0.8, y: 0.3),
                horizonY: 0.35
            )
        } else if !horizontalPlanes.isEmpty {
            // One-point perspective from floor plane
            createOnePointGrid(
                vanishingPoint: CGPoint(x: 0.5, y: 0.3),
                horizonY: 0.35
            )
        }
    }

    func clearGrid() {
        currentGrid = nil
    }
}

// MARK: - Perspective Grid Overlay

struct PerspectiveGridOverlay: View {
    let grid: PerspectiveGrid?
    let opacity: Double

    var body: some View {
        if let grid = grid {
            Canvas { context, size in
                grid.draw(in: context, size: size)
            }
            .opacity(opacity)
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    VStack {
        // Pose overlay preview
        PoseReferenceOverlay(
            pose: DetectedPose(
                joints: [
                    "head": CGPoint(x: 150, y: 50),
                    "neck": CGPoint(x: 150, y: 80),
                    "spine": CGPoint(x: 150, y: 130),
                    "root": CGPoint(x: 150, y: 180),
                    "left_shoulder": CGPoint(x: 110, y: 90),
                    "right_shoulder": CGPoint(x: 190, y: 90),
                    "left_elbow": CGPoint(x: 80, y: 130),
                    "right_elbow": CGPoint(x: 220, y: 130),
                    "left_wrist": CGPoint(x: 60, y: 170),
                    "right_wrist": CGPoint(x: 240, y: 170),
                    "left_hip": CGPoint(x: 130, y: 190),
                    "right_hip": CGPoint(x: 170, y: 190),
                    "left_knee": CGPoint(x: 120, y: 260),
                    "right_knee": CGPoint(x: 180, y: 260),
                    "left_ankle": CGPoint(x: 110, y: 330),
                    "right_ankle": CGPoint(x: 190, y: 330)
                ],
                confidence: 1.0
            ),
            scale: 1.0,
            color: .blue,
            opacity: 0.8
        )
        .frame(width: 300, height: 400)
        .background(Color.gray.opacity(0.2))

        // Perspective grid preview
        PerspectiveGridOverlay(
            grid: PerspectiveGrid(
                vanishingPoint1: CGPoint(x: 0.3, y: 0.2),
                vanishingPoint2: CGPoint(x: 0.8, y: 0.2),
                horizonY: 0.25,
                type: .twoPoint
            ),
            opacity: 0.6
        )
        .frame(width: 300, height: 200)
        .background(Color.white)
    }
}
