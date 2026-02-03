import UIKit
import PDFKit
import PencilKit

// MARK: - Comic Exporter

final class ComicExporter {

    // MARK: - Export Single Page as PNG

    func exportPage(_ page: ComicPage, project: ComicProject, scale: CGFloat = 2.0) -> UIImage? {
        let size = CGSize(
            width: project.pageWidth * scale,
            height: project.pageHeight * scale
        )

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // White background
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            ctx.scaleBy(x: scale, y: scale)

            // Draw panels
            for panel in page.sortedPanels {
                drawPanel(panel, in: ctx, pageSize: CGSize(width: project.pageWidth, height: project.pageHeight))
            }

            // Draw layers (PencilKit drawings)
            for layer in page.sortedLayers {
                if layer.isVisible, let drawingData = layer.drawingData {
                    drawPencilKitLayer(drawingData, opacity: layer.opacity, in: ctx)
                }
            }
        }
    }

    // MARK: - Export Full Comic as PDF

    func exportComic(_ project: ComicProject, includeBleed: Bool = false) -> Data? {
        let pageSize = CGSize(width: project.pageWidth, height: project.pageHeight)

        let pdfData = NSMutableData()

        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: nil, nil) else {
            return nil
        }

        let pdfInfo: [CFString: Any] = [
            kCGPDFContextTitle: project.title,
            kCGPDFContextCreator: "StoryFrame"
        ]

        for page in project.sortedPages {
            var mediaBox = CGRect(origin: .zero, size: pageSize)

            pdfContext.beginPDFPage(pdfInfo as CFDictionary)

            // White background
            pdfContext.setFillColor(UIColor.white.cgColor)
            pdfContext.fill(mediaBox)

            // Draw panels
            for panel in page.sortedPanels {
                drawPanel(panel, in: pdfContext, pageSize: pageSize)
            }

            // Draw layers
            for layer in page.sortedLayers {
                if layer.isVisible, let drawingData = layer.drawingData {
                    drawPencilKitLayer(drawingData, opacity: layer.opacity, in: pdfContext)
                }
            }

            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()

        return pdfData as Data
    }

    // MARK: - Export as Webtoon (Vertical Scroll)

    func exportWebtoon(_ project: ComicProject, maxWidth: CGFloat = 800) -> UIImage? {
        let scale = maxWidth / project.pageWidth
        let pageHeight = project.pageHeight * scale
        let totalHeight = pageHeight * CGFloat(project.pages.count)

        let size = CGSize(width: maxWidth, height: totalHeight)

        // Check if total size is reasonable
        guard totalHeight < 50000 else {
            print("Webtoon too large, consider exporting in chunks")
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            var yOffset: CGFloat = 0

            for page in project.sortedPages {
                ctx.saveGState()
                ctx.translateBy(x: 0, y: yOffset)
                ctx.scaleBy(x: scale, y: scale)

                // Draw page content
                for panel in page.sortedPanels {
                    drawPanel(panel, in: ctx, pageSize: CGSize(width: project.pageWidth, height: project.pageHeight))
                }

                for layer in page.sortedLayers {
                    if layer.isVisible, let drawingData = layer.drawingData {
                        drawPencilKitLayer(drawingData, opacity: layer.opacity, in: ctx)
                    }
                }

                ctx.restoreGState()
                yOffset += pageHeight
            }
        }
    }

    // MARK: - Export for Print (CMYK PDF with Bleed)

    func exportForPrint(_ project: ComicProject, bleed: CGFloat = 9) -> Data? {
        let pageWidth = project.pageWidth + (bleed * 2)
        let pageHeight = project.pageHeight + (bleed * 2)
        let pageSize = CGSize(width: pageWidth, height: pageHeight)

        let pdfData = NSMutableData()

        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: nil, nil) else {
            return nil
        }

        let pdfInfo: [CFString: Any] = [
            kCGPDFContextTitle: project.title,
            kCGPDFContextCreator: "StoryFrame - Print Ready"
        ]

        for page in project.sortedPages {
            pdfContext.beginPDFPage(pdfInfo as CFDictionary)

            // White background
            pdfContext.setFillColor(UIColor.white.cgColor)
            pdfContext.fill(CGRect(origin: .zero, size: pageSize))

            // Offset for bleed
            pdfContext.translateBy(x: bleed, y: bleed)

            // Draw content
            for panel in page.sortedPanels {
                drawPanel(panel, in: pdfContext, pageSize: CGSize(width: project.pageWidth, height: project.pageHeight))
            }

            for layer in page.sortedLayers {
                if layer.isVisible, let drawingData = layer.drawingData {
                    drawPencilKitLayer(drawingData, opacity: layer.opacity, in: pdfContext)
                }
            }

            // Draw crop marks
            pdfContext.translateBy(x: -bleed, y: -bleed)
            drawCropMarks(in: pdfContext, pageSize: pageSize, bleed: bleed)

            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()

        return pdfData as Data
    }

    // MARK: - Private Drawing Methods

    private func drawPanel(_ panel: Panel, in context: CGContext, pageSize: CGSize) {
        let points = panel.framePoints
        guard points.count >= 3 else { return }

        context.saveGState()

        // Create panel path
        context.beginPath()
        context.move(to: points[0])
        for point in points.dropFirst() {
            context.addLine(to: point)
        }
        context.closePath()

        // Fill background
        if let bgColor = panel.backgroundColor {
            context.setFillColor(UIColor(hex: bgColor).cgColor)
            context.fillPath()

            // Recreate path for stroke
            context.beginPath()
            context.move(to: points[0])
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            context.closePath()
        } else {
            context.setFillColor(UIColor.white.cgColor)
            context.fillPath()

            context.beginPath()
            context.move(to: points[0])
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            context.closePath()
        }

        // Draw border
        context.setStrokeColor(UIColor(hex: panel.borderColor).cgColor)
        context.setLineWidth(panel.borderWidth)
        context.strokePath()

        // Draw bubbles
        for bubble in panel.bubbles {
            drawBubble(bubble, in: context)
        }

        // Draw text elements
        for textElement in panel.textElements {
            drawTextElement(textElement, in: context)
        }

        context.restoreGState()
    }

    private func drawBubble(_ bubble: SpeechBubble, in context: CGContext) {
        context.saveGState()

        let center = CGPoint(x: bubble.centerX, y: bubble.centerY)
        let size = CGSize(width: bubble.width, height: bubble.height)
        let rect = CGRect(
            x: center.x - size.width/2,
            y: center.y - size.height/2,
            width: size.width,
            height: size.height
        )

        // Draw bubble shape
        context.beginPath()

        switch bubble.bubbleType {
        case "oval":
            context.addEllipse(in: rect)
        case "rectangle":
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
            context.addPath(path.cgPath)
        case "burst":
            drawBurstPath(in: context, rect: rect, points: 12)
        default:
            context.addEllipse(in: rect)
        }

        // Fill
        context.setFillColor(UIColor(hex: bubble.fillColor).withAlphaComponent(bubble.fillOpacity).cgColor)
        context.fillPath()

        // Recreate path for stroke
        context.beginPath()
        switch bubble.bubbleType {
        case "oval":
            context.addEllipse(in: rect)
        case "rectangle":
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
            context.addPath(path.cgPath)
        case "burst":
            drawBurstPath(in: context, rect: rect, points: 12)
        default:
            context.addEllipse(in: rect)
        }

        // Stroke
        context.setStrokeColor(UIColor(hex: bubble.borderColor).cgColor)
        context.setLineWidth(bubble.borderWidth)
        context.strokePath()

        // Draw tail if not burst type
        if bubble.bubbleType != "burst" && bubble.tailStyle != "none" {
            drawBubbleTail(bubble, in: context, rect: rect)
        }

        // Draw text
        if !bubble.text.isEmpty {
            let textRect = rect.insetBy(dx: 10, dy: 10)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = bubble.textAlignment == "left" ? .left :
                                       bubble.textAlignment == "right" ? .right : .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: bubble.fontSize, weight: .bold),
                .foregroundColor: UIColor(hex: bubble.fontColor),
                .paragraphStyle: paragraphStyle
            ]

            let attributedString = NSAttributedString(string: bubble.text, attributes: attributes)
            attributedString.draw(in: textRect)
        }

        context.restoreGState()
    }

    private func drawBurstPath(in context: CGContext, rect: CGRect, points: Int) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.6

        for i in 0..<(points * 2) {
            let angle = (CGFloat(i) / CGFloat(points * 2)) * 2 * .pi - .pi/2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if i == 0 {
                context.move(to: point)
            } else {
                context.addLine(to: point)
            }
        }
        context.closePath()
    }

    private func drawBubbleTail(_ bubble: SpeechBubble, in context: CGContext, rect: CGRect) {
        let tailPoint = CGPoint(x: bubble.tailX, y: bubble.tailY)
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Calculate tail base
        let dx = tailPoint.x - center.x
        let dy = tailPoint.y - center.y
        let angle = atan2(dy, dx)

        let baseX = center.x + cos(angle) * rect.width / 2
        let baseY = center.y + sin(angle) * rect.height / 2

        let perpAngle = angle + .pi / 2
        let baseOffset: CGFloat = 10

        let baseLeft = CGPoint(
            x: baseX + cos(perpAngle) * baseOffset,
            y: baseY + sin(perpAngle) * baseOffset
        )
        let baseRight = CGPoint(
            x: baseX - cos(perpAngle) * baseOffset,
            y: baseY - sin(perpAngle) * baseOffset
        )

        context.beginPath()
        context.move(to: baseLeft)
        context.addLine(to: tailPoint)
        context.addLine(to: baseRight)
        context.closePath()

        context.setFillColor(UIColor(hex: bubble.fillColor).cgColor)
        context.fillPath()

        context.beginPath()
        context.move(to: baseLeft)
        context.addLine(to: tailPoint)
        context.addLine(to: baseRight)

        context.setStrokeColor(UIColor(hex: bubble.borderColor).cgColor)
        context.setLineWidth(bubble.borderWidth)
        context.strokePath()
    }

    private func drawTextElement(_ element: TextElement, in context: CGContext) {
        context.saveGState()

        let point = CGPoint(x: element.x, y: element.y)

        // Apply rotation if needed
        if element.rotation != 0 {
            context.translateBy(x: point.x, y: point.y)
            context.rotate(by: element.rotation * .pi / 180)
            context.translateBy(x: -point.x, y: -point.y)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = element.alignment == "left" ? .left :
                                   element.alignment == "right" ? .right : .center

        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: element.fontName, size: element.fontSize) ?? UIFont.systemFont(ofSize: element.fontSize, weight: .bold),
            .foregroundColor: UIColor(hex: element.fontColor),
            .paragraphStyle: paragraphStyle
        ]

        // Add shadow effect if needed
        if element.effect == "shadow" {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
            shadow.shadowOffset = CGSize(width: 2, height: 2)
            shadow.shadowBlurRadius = 0
            attributes[.shadow] = shadow
        }

        let textRect = CGRect(
            x: point.x - element.width / 2,
            y: point.y - element.fontSize / 2,
            width: element.width,
            height: element.fontSize * 2
        )

        let attributedString = NSAttributedString(string: element.text, attributes: attributes)
        attributedString.draw(in: textRect)

        context.restoreGState()
    }

    private func drawPencilKitLayer(_ data: Data, opacity: Double, in context: CGContext) {
        guard let drawing = try? PKDrawing(data: data) else { return }

        context.saveGState()
        context.setAlpha(opacity)

        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: drawing.bounds)
        }

        context.restoreGState()
    }

    private func drawCropMarks(in context: CGContext, pageSize: CGSize, bleed: CGFloat) {
        context.saveGState()

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(0.5)

        let markLength: CGFloat = 10

        // Top-left corner
        context.move(to: CGPoint(x: bleed, y: 0))
        context.addLine(to: CGPoint(x: bleed, y: bleed - 2))

        context.move(to: CGPoint(x: 0, y: bleed))
        context.addLine(to: CGPoint(x: bleed - 2, y: bleed))

        // Top-right corner
        context.move(to: CGPoint(x: pageSize.width - bleed, y: 0))
        context.addLine(to: CGPoint(x: pageSize.width - bleed, y: bleed - 2))

        context.move(to: CGPoint(x: pageSize.width, y: bleed))
        context.addLine(to: CGPoint(x: pageSize.width - bleed + 2, y: bleed))

        // Bottom-left corner
        context.move(to: CGPoint(x: bleed, y: pageSize.height))
        context.addLine(to: CGPoint(x: bleed, y: pageSize.height - bleed + 2))

        context.move(to: CGPoint(x: 0, y: pageSize.height - bleed))
        context.addLine(to: CGPoint(x: bleed - 2, y: pageSize.height - bleed))

        // Bottom-right corner
        context.move(to: CGPoint(x: pageSize.width - bleed, y: pageSize.height))
        context.addLine(to: CGPoint(x: pageSize.width - bleed, y: pageSize.height - bleed + 2))

        context.move(to: CGPoint(x: pageSize.width, y: pageSize.height - bleed))
        context.addLine(to: CGPoint(x: pageSize.width - bleed + 2, y: pageSize.height - bleed))

        context.strokePath()
        context.restoreGState()
    }
}
