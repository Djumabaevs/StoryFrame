import Vision
import UIKit
import SwiftUI

// MARK: - Detected Face Model

struct DetectedFace: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let mouthPosition: CGPoint
    let leftEyePosition: CGPoint?
    let rightEyePosition: CGPoint?
    let nosePosition: CGPoint?
    let confidence: Float

    var center: CGPoint {
        CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }

    var topCenter: CGPoint {
        CGPoint(x: boundingBox.midX, y: boundingBox.minY)
    }
}

// MARK: - Face Detection Manager

@MainActor
final class FaceDetectionManager: ObservableObject {
    @Published var detectedFaces: [DetectedFace] = []
    @Published var isProcessing = false

    private let faceDetectionRequest: VNDetectFaceRectanglesRequest
    private let faceLandmarksRequest: VNDetectFaceLandmarksRequest

    init() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest()
        faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    }

    func detectFaces(in image: UIImage) async -> [DetectedFace] {
        guard let cgImage = image.cgImage else { return [] }

        isProcessing = true
        defer { isProcessing = false }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([faceDetectionRequest, faceLandmarksRequest])

            guard let faceObservations = faceDetectionRequest.results else { return [] }
            let landmarkResults = faceLandmarksRequest.results ?? []

            var faces: [DetectedFace] = []
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

            for (index, observation) in faceObservations.enumerated() {
                let boundingBox = observation.boundingBox

                // Convert Vision coordinates (bottom-left origin, normalized) to UIKit coordinates
                let faceRect = CGRect(
                    x: boundingBox.minX * imageSize.width,
                    y: (1 - boundingBox.maxY) * imageSize.height,
                    width: boundingBox.width * imageSize.width,
                    height: boundingBox.height * imageSize.height
                )

                // Get landmarks if available
                var mouthPosition = CGPoint(x: faceRect.midX, y: faceRect.maxY - faceRect.height * 0.2)
                var leftEye: CGPoint?
                var rightEye: CGPoint?
                var nose: CGPoint?

                if index < landmarkResults.count {
                    let landmarks = landmarkResults[index].landmarks

                    if let outerLips = landmarks?.outerLips {
                        let points = outerLips.normalizedPoints
                        let avgX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
                        let avgY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)

                        mouthPosition = CGPoint(
                            x: faceRect.minX + avgX * faceRect.width,
                            y: faceRect.minY + (1 - avgY) * faceRect.height
                        )
                    }

                    if let leftEyeLandmark = landmarks?.leftEye {
                        let points = leftEyeLandmark.normalizedPoints
                        let avgX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
                        let avgY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
                        leftEye = CGPoint(
                            x: faceRect.minX + avgX * faceRect.width,
                            y: faceRect.minY + (1 - avgY) * faceRect.height
                        )
                    }

                    if let rightEyeLandmark = landmarks?.rightEye {
                        let points = rightEyeLandmark.normalizedPoints
                        let avgX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
                        let avgY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
                        rightEye = CGPoint(
                            x: faceRect.minX + avgX * faceRect.width,
                            y: faceRect.minY + (1 - avgY) * faceRect.height
                        )
                    }

                    if let noseLandmark = landmarks?.nose {
                        let points = noseLandmark.normalizedPoints
                        let avgX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
                        let avgY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
                        nose = CGPoint(
                            x: faceRect.minX + avgX * faceRect.width,
                            y: faceRect.minY + (1 - avgY) * faceRect.height
                        )
                    }
                }

                faces.append(DetectedFace(
                    boundingBox: faceRect,
                    mouthPosition: mouthPosition,
                    leftEyePosition: leftEye,
                    rightEyePosition: rightEye,
                    nosePosition: nose,
                    confidence: observation.confidence
                ))
            }

            detectedFaces = faces
            if !faces.isEmpty {
                HapticManager.shared.faceDetected()
            }

            return faces

        } catch {
            print("Face detection failed: \(error)")
            return []
        }
    }

    // MARK: - Bubble Positioning Suggestions

    func suggestBubblePosition(for faceIndex: Int, in panelRect: CGRect, bubbleSize: CGSize) -> (center: CGPoint, tailTarget: CGPoint)? {
        guard faceIndex < detectedFaces.count else { return nil }

        let face = detectedFaces[faceIndex]

        // Determine which side has more space
        let faceCenter = face.center
        let leftSpace = faceCenter.x - panelRect.minX
        let rightSpace = panelRect.maxX - faceCenter.x
        let topSpace = faceCenter.y - panelRect.minY

        var bubbleCenter: CGPoint

        // Position bubble based on available space
        if topSpace > bubbleSize.height + 20 {
            // Above the face
            if leftSpace > rightSpace {
                bubbleCenter = CGPoint(
                    x: max(panelRect.minX + bubbleSize.width/2 + 10, faceCenter.x - bubbleSize.width/2),
                    y: face.boundingBox.minY - bubbleSize.height/2 - 15
                )
            } else {
                bubbleCenter = CGPoint(
                    x: min(panelRect.maxX - bubbleSize.width/2 - 10, faceCenter.x + bubbleSize.width/2),
                    y: face.boundingBox.minY - bubbleSize.height/2 - 15
                )
            }
        } else if rightSpace > leftSpace {
            // To the right of face
            bubbleCenter = CGPoint(
                x: min(panelRect.maxX - bubbleSize.width/2 - 10, face.boundingBox.maxX + bubbleSize.width/2 + 10),
                y: max(panelRect.minY + bubbleSize.height/2 + 10, face.boundingBox.minY)
            )
        } else {
            // To the left of face
            bubbleCenter = CGPoint(
                x: max(panelRect.minX + bubbleSize.width/2 + 10, face.boundingBox.minX - bubbleSize.width/2 - 10),
                y: max(panelRect.minY + bubbleSize.height/2 + 10, face.boundingBox.minY)
            )
        }

        // Clamp to panel bounds
        bubbleCenter.x = max(panelRect.minX + bubbleSize.width/2 + 5, min(panelRect.maxX - bubbleSize.width/2 - 5, bubbleCenter.x))
        bubbleCenter.y = max(panelRect.minY + bubbleSize.height/2 + 5, min(panelRect.maxY - bubbleSize.height/2 - 5, bubbleCenter.y))

        return (center: bubbleCenter, tailTarget: face.mouthPosition)
    }

    // MARK: - Reading Order Suggestion

    func suggestReadingOrder(faces: [DetectedFace], readingDirection: String) -> [Int] {
        guard !faces.isEmpty else { return [] }

        let indexed = faces.enumerated().map { ($0.offset, $0.element) }

        let sorted: [(Int, DetectedFace)]
        if readingDirection == "rtl" {
            // Right to left (manga style)
            sorted = indexed.sorted { lhs, rhs in
                // First sort by vertical position (row)
                let rowThreshold: CGFloat = 50
                if abs(lhs.1.center.y - rhs.1.center.y) < rowThreshold {
                    // Same row - sort right to left
                    return lhs.1.center.x > rhs.1.center.x
                }
                // Different rows - sort top to bottom
                return lhs.1.center.y < rhs.1.center.y
            }
        } else {
            // Left to right (western style)
            sorted = indexed.sorted { lhs, rhs in
                let rowThreshold: CGFloat = 50
                if abs(lhs.1.center.y - rhs.1.center.y) < rowThreshold {
                    return lhs.1.center.x < rhs.1.center.x
                }
                return lhs.1.center.y < rhs.1.center.y
            }
        }

        return sorted.map { $0.0 }
    }
}

// MARK: - Face Detection Overlay View

struct FaceDetectionOverlay: View {
    let faces: [DetectedFace]
    let scale: CGFloat
    let showDetails: Bool

    var body: some View {
        ForEach(faces) { face in
            let scaledRect = face.boundingBox.scaled(by: scale)

            // Face bounding box
            Rectangle()
                .stroke(Color.cyan, lineWidth: 2)
                .frame(width: scaledRect.width, height: scaledRect.height)
                .position(x: scaledRect.midX, y: scaledRect.midY)

            // Mouth indicator
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .position(
                    x: face.mouthPosition.x * scale,
                    y: face.mouthPosition.y * scale
                )

            if showDetails {
                // Eye indicators
                if let leftEye = face.leftEyePosition {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .position(x: leftEye.x * scale, y: leftEye.y * scale)
                }

                if let rightEye = face.rightEyePosition {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .position(x: rightEye.x * scale, y: rightEye.y * scale)
                }

                // Nose indicator
                if let nose = face.nosePosition {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .position(x: nose.x * scale, y: nose.y * scale)
                }

                // Confidence label
                Text("\(Int(face.confidence * 100))%")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .position(x: scaledRect.midX, y: scaledRect.minY - 12)
            }
        }
    }
}

#Preview {
    FaceDetectionOverlay(
        faces: [
            DetectedFace(
                boundingBox: CGRect(x: 50, y: 50, width: 100, height: 120),
                mouthPosition: CGPoint(x: 100, y: 140),
                leftEyePosition: CGPoint(x: 80, y: 80),
                rightEyePosition: CGPoint(x: 120, y: 80),
                nosePosition: CGPoint(x: 100, y: 110),
                confidence: 0.95
            )
        ],
        scale: 1.0,
        showDetails: true
    )
    .frame(width: 300, height: 400)
    .background(Color.gray.opacity(0.3))
}
