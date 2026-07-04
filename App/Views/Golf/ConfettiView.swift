import SwiftUI

/// Lightweight confetti burst in Sweetens Cove colors. Fires once on appear
/// and fades out — used for birdies in-round and the PB celebration.
struct ConfettiView: View {
    var particleCount: Int = 40
    var duration: Double = 1.8

    private struct Particle {
        let angle: Double
        let speed: Double
        let size: CGFloat
        let color: Color
        let spin: Double
        let isCircle: Bool
    }

    @State private var startDate: Date?

    private var particles: [Particle] {
        let colors = [GolfTheme.sky, GolfTheme.fairway, GolfTheme.flag, GolfTheme.gold]
        return (0..<particleCount).map { index in
            // Deterministic pseudo-random spread so the view is cheap to rebuild.
            let t = Double(index) / Double(particleCount)
            let jitter = Double((index * 7919) % 100) / 100.0
            return Particle(
                angle: t * 2 * .pi + jitter * 0.4,
                speed: 120 + jitter * 220,
                size: 5 + CGFloat(jitter) * 6,
                color: colors[index % colors.count],
                spin: (jitter - 0.5) * 12,
                isCircle: index % 3 == 0)
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let startDate else { return }
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed < duration else { return }
                let progress = elapsed / duration
                let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
                let gravity = 260 * elapsed * elapsed

                for particle in particles {
                    let distance = particle.speed * elapsed
                    let x = center.x + cos(particle.angle) * distance
                    let y = center.y + sin(particle.angle) * distance * 0.7 + gravity
                    let opacity = 1 - progress
                    let rect = CGRect(x: x, y: y, width: particle.size, height: particle.size)

                    var piece = context
                    piece.translateBy(x: rect.midX, y: rect.midY)
                    piece.rotate(by: .radians(particle.spin * elapsed))
                    piece.translateBy(x: -rect.midX, y: -rect.midY)
                    piece.opacity = opacity

                    let path = particle.isCircle
                        ? Path(ellipseIn: rect)
                        : Path(roundedRect: rect, cornerRadius: 1)
                    piece.fill(path, with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { startDate = Date() }
    }
}
