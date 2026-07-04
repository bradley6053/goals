import SwiftUI

/// Cream cardstock container — the golf twin of EmberCard.
struct GolfCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(GolfTheme.card, in: RoundedRectangle(cornerRadius: GolfTheme.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: GolfTheme.radiusCard)
                    .strokeBorder(GolfTheme.stroke, lineWidth: 1)
            )
    }
}

/// Small-caps overline, e.g. "COURSE RECORD".
struct GolfOverline: View {
    let text: String
    var color: Color = GolfTheme.inkFaint

    init(_ text: String, color: Color = GolfTheme.inkFaint) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(GolfTheme.label(11))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

/// One stat in a row of chips: big value over a small label.
struct StatTile: View {
    let value: String
    let label: String
    var color: Color = GolfTheme.ink

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(GolfTheme.score(22))
                .foregroundStyle(color)
            Text(label.uppercased())
                .font(GolfTheme.label(9))
                .tracking(1.0)
                .foregroundStyle(GolfTheme.inkFaint)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Big tappable − / + stepper used for strokes, putts, penalties.
struct GolfStepper: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...20
    var display: ((Int) -> String)?

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(GolfTheme.label(11))
                .tracking(1.2)
                .foregroundStyle(GolfTheme.inkSoft)
            Spacer()
            HStack(spacing: 14) {
                stepButton("minus") {
                    if value > range.lowerBound { value -= 1 }
                }
                Text(display?(value) ?? "\(value)")
                    .font(GolfTheme.score(24))
                    .foregroundStyle(GolfTheme.ink)
                    .frame(minWidth: 56)
                stepButton("plus") {
                    if value < range.upperBound { value += 1 }
                }
            }
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(GolfTheme.card)
                .frame(width: 40, height: 40)
                .background(GolfTheme.fairway, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Yes/no pill toggle for fairway hit and GIR.
struct GolfToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(GolfTheme.label(11))
                .tracking(1.2)
                .foregroundStyle(GolfTheme.inkSoft)
            Spacer()
            Button {
                Haptics.tap()
                isOn.toggle()
            } label: {
                Text(isOn ? "YES" : "NO")
                    .font(GolfTheme.label(12))
                    .tracking(1.0)
                    .foregroundStyle(isOn ? GolfTheme.card : GolfTheme.inkSoft)
                    .frame(width: 64, height: 34)
                    .background(isOn ? AnyShapeStyle(GolfTheme.fairway)
                                     : AnyShapeStyle(GolfTheme.sand),
                                in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

/// A score cell with classic notation: circle = birdie or better
/// (doubled for eagle+), square = bogey (doubled for double+).
struct ScoreCell: View {
    let strokes: Int
    let par: Int
    var size: CGFloat = 26

    var body: some View {
        let type = GolfMath.scoreType(strokes: strokes, par: par)
        Text("\(strokes)")
            .font(GolfTheme.score(size * 0.52))
            .foregroundStyle(color(for: type))
            .frame(width: size, height: size)
            .overlay { decoration(for: type) }
    }

    private func color(for type: ScoreType) -> Color {
        switch type {
        case .albatross, .eagle, .birdie: return GolfTheme.birdie
        case .par: return GolfTheme.ink
        default: return GolfTheme.bogey
        }
    }

    @ViewBuilder
    private func decoration(for type: ScoreType) -> some View {
        switch type {
        case .birdie:
            Circle().strokeBorder(GolfTheme.birdie, lineWidth: 1.2)
        case .eagle, .albatross:
            Circle().strokeBorder(GolfTheme.birdie, lineWidth: 1.2)
            Circle().strokeBorder(GolfTheme.birdie, lineWidth: 1.2).padding(3)
        case .bogey:
            Rectangle().strokeBorder(GolfTheme.bogey, lineWidth: 1.2)
        case .doubleBogey, .worse:
            Rectangle().strokeBorder(GolfTheme.bogey, lineWidth: 1.2)
            Rectangle().strokeBorder(GolfTheme.bogey, lineWidth: 1.2).padding(3)
        case .par:
            EmptyView()
        }
    }
}

/// Classic paper scorecard: HOLE / PAR / SCORE rows, nine holes per band,
/// with OUT / IN / TOT columns.
struct ScorecardGrid: View {
    let results: [HoleResult]

    var body: some View {
        let front = results.filter { $0.holeNumber <= 9 }
        let back = results.filter { $0.holeNumber >= 10 }

        VStack(spacing: 12) {
            if !front.isEmpty {
                band(front, totalLabel: "OUT")
            }
            if !back.isEmpty {
                band(back, totalLabel: "IN")
            }
        }
    }

    private func band(_ holes: [HoleResult], totalLabel: String) -> some View {
        VStack(spacing: 0) {
            row(label: "HOLE",
                cells: holes.map { AnyView(headerText("\($0.holeNumber)")) },
                total: AnyView(headerText(totalLabel)),
                background: GolfTheme.fairway)
            row(label: "PAR",
                cells: holes.map { AnyView(parText("\($0.par)")) },
                total: AnyView(parText("\(holes.reduce(0) { $0 + $1.par })")),
                background: GolfTheme.sand)
            row(label: "SCORE",
                cells: holes.map { hole in
                    AnyView(ScoreCell(strokes: hole.strokes, par: hole.par, size: 24))
                },
                total: AnyView(
                    Text("\(GolfMath.totalStrokes(holes))")
                        .font(GolfTheme.score(13))
                        .foregroundStyle(GolfTheme.ink)),
                background: GolfTheme.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: GolfTheme.radiusInner))
        .overlay(
            RoundedRectangle(cornerRadius: GolfTheme.radiusInner)
                .strokeBorder(GolfTheme.stroke, lineWidth: 1)
        )
    }

    private func headerText(_ text: String) -> some View {
        Text(text)
            .font(GolfTheme.label(10))
            .foregroundStyle(GolfTheme.card)
    }

    private func parText(_ text: String) -> some View {
        Text(text)
            .font(GolfTheme.score(12))
            .foregroundStyle(GolfTheme.inkSoft)
    }

    private func row(label: String, cells: [AnyView], total: AnyView,
                     background: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(GolfTheme.label(8))
                .tracking(0.6)
                .foregroundStyle(background == GolfTheme.fairway
                                 ? GolfTheme.card.opacity(0.8) : GolfTheme.inkFaint)
                .frame(width: 44, alignment: .leading)
                .padding(.leading, 8)
            ForEach(cells.indices, id: \.self) { index in
                cells[index].frame(maxWidth: .infinity)
            }
            total
                .frame(width: 40)
                .background(background.opacity(background == GolfTheme.card ? 0 : 0.35))
        }
        .frame(height: 34)
        .background(background == GolfTheme.card ? GolfTheme.card : background.opacity(background == GolfTheme.sand ? 0.55 : 1))
    }
}

/// Passport stamp for a played course — dashed ring, initials, state.
struct StampView: View {
    let courseName: String
    let state: String
    let date: Date
    var color: Color = GolfTheme.fairway

    private var initials: String {
        let words = courseName.split(separator: " ")
            .filter { !["golf", "club", "course", "the", "at", "of"].contains($0.lowercased()) }
        return words.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .foregroundStyle(color)
                VStack(spacing: 1) {
                    Text(initials.isEmpty ? "GC" : initials)
                        .font(GolfTheme.display(22))
                        .foregroundStyle(color)
                    Text(state)
                        .font(GolfTheme.label(8))
                        .tracking(1.2)
                        .foregroundStyle(color.opacity(0.75))
                }
            }
            .frame(width: 76, height: 76)
            .rotationEffect(.degrees(Double((courseName.count % 5)) * 2.5 - 5))

            Text(date, format: .dateTime.month(.abbreviated).year())
                .font(GolfTheme.label(9))
                .foregroundStyle(GolfTheme.inkFaint)
        }
    }
}
