import UIKit
import CoreHaptics

final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        prepareHaptics()
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            engine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                self?.restartEngine()
            }

            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                self?.restartEngine()
            }
        } catch {
            print("Haptic engine creation failed: \(error)")
        }

        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactRigid.prepare()
        impactSoft.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    private func restartEngine() {
        try? engine?.start()
    }

    // MARK: - Public Methods

    func toolSelected() {
        selectionFeedback.selectionChanged()
    }

    func panelCreated() {
        impactMedium.impactOccurred()
    }

    func panelSnapped() {
        impactRigid.impactOccurred()
    }

    func bubbleCreated() {
        impactLight.impactOccurred()
    }

    func bubbleTypeChanged() {
        selectionFeedback.selectionChanged()
    }

    func textConfirmed() {
        impactLight.impactOccurred()
    }

    func pageChanged() {
        impactLight.impactOccurred()
    }

    func pageDeleted() {
        notificationFeedback.notificationOccurred(.warning)
    }

    func exportComplete() {
        notificationFeedback.notificationOccurred(.success)
    }

    func faceDetected() {
        impactLight.impactOccurred()
    }

    func undoRedo() {
        impactLight.impactOccurred()
    }

    func error() {
        notificationFeedback.notificationOccurred(.error)
    }

    func success() {
        notificationFeedback.notificationOccurred(.success)
    }

    func warning() {
        notificationFeedback.notificationOccurred(.warning)
    }

    func tap() {
        impactLight.impactOccurred()
    }

    func drag() {
        impactSoft.impactOccurred(intensity: 0.5)
    }

    func drop() {
        impactMedium.impactOccurred()
    }

    // MARK: - Custom Patterns

    func bubbleInflate() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else {
            impactSoft.impactOccurred()
            return
        }

        var events = [CHHapticEvent]()

        for i in stride(from: 0, to: 0.3, by: 0.05) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i / 0.3))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: i, duration: 0.05)
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            impactSoft.impactOccurred()
        }
    }

    func drawingStroke(pressure: CGFloat) {
        let intensity = min(1.0, max(0.1, pressure))
        impactSoft.impactOccurred(intensity: intensity)
    }
}
