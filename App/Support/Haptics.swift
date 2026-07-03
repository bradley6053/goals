import UIKit

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func firm() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Rising triple-tap used for milestone reveals.
    static func unlock() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            generator.impactOccurred(intensity: 0.75)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            generator.impactOccurred(intensity: 1.0)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
