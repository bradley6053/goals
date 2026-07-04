import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let goal: Goal

    @State private var showingLogSheet = false
    @State private var showingEditor = false
    @State private var confirmingDelete = false
    @State private var celebration: CelebrationPayload?

    var body: some View {
        let accent = Accent.named(goal.accentName)

        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(accent: accent)
                    statsRow(accent: accent)
                        .padding(.horizontal, 16)
                    milestonesSection(accent: accent)
                        .padding(.horizontal, 16)
                    historySection
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 120)
            }
            .ignoresSafeArea(edges: .top)

            VStack {
                Spacer()
                if !goal.isComplete {
                    actionButton(accent: accent)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit goal", systemImage: "pencil") { showingEditor = true }
                    Button("Delete goal", systemImage: "trash", role: .destructive) {
                        confirmingDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogProgressSheet(goal: goal) { payload in
                celebration = payload
            }
        }
        .sheet(isPresented: $showingEditor) {
            GoalEditorView(goal: goal)
        }
        .confirmationDialog("Delete this goal?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete \"\(goal.title)\"", role: .destructive) { deleteGoal() }
        } message: {
            Text("This removes the goal, its milestones, and its history.")
        }
        .fullScreenCover(item: $celebration) { payload in
            CelebrationView(payload: payload)
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private func actionButton(accent: Accent) -> some View {
        switch goal.kind {
        case .numeric:
            EmberButton(title: "Log progress", accent: accent, systemImage: "plus") {
                showingLogSheet = true
            }
        case .count:
            EmberButton(title: "Check in  +1", accent: accent, systemImage: "flame.fill") {
                checkIn()
            }
        case .streak:
            if goal.hasCheckedInToday {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Checked in — see you tomorrow")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(accent.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radiusInner))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusInner)
                        .strokeBorder(accent.primary.opacity(0.4), lineWidth: 1)
                )
            } else {
                EmberButton(title: "Check in today", accent: accent, systemImage: "flame.fill") {
                    checkIn()
                }
            }
        }
    }

    private func checkIn() {
        if let payload = ProgressLogger.log(goal: goal, value: 1, note: nil, context: context) {
            celebration = payload
        } else {
            Haptics.success()
        }
    }

    // MARK: - Header

    private func header(accent: Accent) -> some View {
        let heroFile = goal.rewardImageFile ?? goal.nextMilestone?.rewardImageFile
        return ZStack(alignment: .bottomLeading) {
            Group {
                if let image = ImageStore.image(heroFile) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(colors: [accent.primary.opacity(0.4), Theme.bg],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                LinearGradient(colors: [Theme.bg.opacity(0.25), .clear, Theme.bg],
                               startPoint: .top, endPoint: .bottom)
            )

            VStack(alignment: .leading, spacing: 6) {
                OverlineText("The prize · \(goal.rewardTitle)", color: .white.opacity(0.75))
                Text(goal.title.uppercased())
                    .font(Theme.display(40))
                    .foregroundStyle(Theme.textPrimary)
                    .shadow(color: .black.opacity(0.8), radius: 8, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Stats

    private func statsRow(accent: Accent) -> some View {
        EmberCard {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        switch goal.kind {
                        case .numeric:
                            OverlineText("Progress")
                            Text(GoalFormat.signedDelta(
                                GoalMath.deltaFromStart(start: goal.startValue, current: goal.currentValue),
                                unit: goal.unit))
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(accent.gradient)
                        case .count:
                            OverlineText(goal.unit.isEmpty ? "So far" : goal.unit.capitalized)
                            Text(GoalFormat.countHeadline(
                                current: goal.currentValue, target: goal.targetValue))
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(accent.gradient)
                        case .streak:
                            OverlineText("Day streak")
                            Text("🔥 \(goal.currentStreak)")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(accent.gradient)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        switch goal.kind {
                        case .numeric:
                            OverlineText("Now")
                            Text(GoalFormat.value(goal.currentValue, unit: goal.unit))
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.textPrimary)
                            Text("of \(GoalFormat.value(goal.targetValue, unit: goal.unit))")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                        case .count:
                            OverlineText("To go")
                            Text(GoalFormat.number(max(0, goal.targetValue - goal.currentValue)))
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.textPrimary)
                            Text("of \(GoalFormat.value(goal.targetValue, unit: goal.unit))")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                        case .streak:
                            OverlineText("Best")
                            Text(GoalFormat.value(Double(goal.bestStreak), unit: "days"))
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.textPrimary)
                            Text("goal \(GoalFormat.value(goal.targetValue, unit: "days"))")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                GlowProgressBar(fraction: goal.fraction, accent: accent)
                if goal.kind == .streak {
                    recentDaysRow(accent: accent)
                }
                HStack {
                    if goal.kind == .streak && !goal.hasCheckedInToday
                        && goal.currentStreak > 0 && !goal.isComplete {
                        Text("Check in to keep it alive")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(accent.primary)
                    } else {
                        Text("\(Int((goal.fraction * 100).rounded()))% there")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if let date = goal.targetDate {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(20)
        }
    }

    /// Last-7-days dots (oldest first, today last) for streak goals.
    private func recentDaysRow(accent: Accent) -> some View {
        let dots = StreakMath.recentDays(dates: goal.entries.map(\.date))
        return HStack(spacing: 10) {
            OverlineText("Last 7 days")
            Spacer()
            ForEach(Array(dots.enumerated()), id: \.offset) { _, filled in
                Circle()
                    .fill(filled ? AnyShapeStyle(accent.gradient)
                                 : AnyShapeStyle(Color.white.opacity(0.12)))
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - Milestones

    private func milestonesSection(accent: Accent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            OverlineText("The road to the prize")
            VStack(spacing: 12) {
                ForEach(goal.orderedMilestones) { milestone in
                    MilestoneRowView(goal: goal, milestone: milestone, accent: accent) {
                        claim(milestone)
                    }
                }
                finalRewardRow(accent: accent)
            }
        }
    }

    private func finalRewardRow(accent: Accent) -> some View {
        let reached = goal.isComplete
        return EmberCard {
            HStack(spacing: 14) {
                RewardImageView(imageFile: goal.rewardImageFile, accent: accent, locked: !reached)
                    .frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 4) {
                    OverlineText(reached ? "Earned" : "The big one",
                                 color: reached ? accent.primary : Theme.textTertiary)
                    Text(goal.rewardTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(GoalFormat.milestoneLabel(
                        value: goal.targetValue, start: goal.startValue,
                        target: goal.targetValue, unit: goal.unit))
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(reached ? AnyShapeStyle(accent.gradient)
                                                 : AnyShapeStyle(Theme.textSecondary))
                }
                Spacer()
                if reached {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(accent.gradient)
                }
            }
            .padding(14)
        }
    }

    // MARK: - History

    private var historySection: some View {
        let recent = goal.entries.sorted { $0.date > $1.date }.prefix(10)
        return Group {
            if !recent.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    OverlineText(goal.kind == .numeric ? "Recent logs" : "Recent check-ins")
                    EmberCard {
                        VStack(spacing: 0) {
                            ForEach(Array(recent.enumerated()), id: \.element.uuid) { index, entry in
                                HStack {
                                    Text(entry.date, format: .dateTime.month(.abbreviated).day())
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Theme.textSecondary)
                                    if let note = entry.note, !note.isEmpty {
                                        Text(note)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Theme.textTertiary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    switch goal.kind {
                                    case .numeric:
                                        Text(GoalFormat.value(entry.value, unit: goal.unit))
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .monospacedDigit()
                                            .foregroundStyle(Theme.textPrimary)
                                    case .count:
                                        Text("+\(GoalFormat.number(entry.value))")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .monospacedDigit()
                                            .foregroundStyle(Theme.textPrimary)
                                    case .streak:
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Accent.named(goal.accentName).gradient)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 13)
                                if index < recent.count - 1 {
                                    Divider().overlay(Theme.stroke)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func claim(_ milestone: Milestone) {
        milestone.claimedAt = Date()
        try? context.save()
        Haptics.success()
    }

    private func deleteGoal() {
        ImageStore.delete(goal.rewardImageFile)
        for milestone in goal.milestones {
            ImageStore.delete(milestone.rewardImageFile)
        }
        context.delete(goal)
        try? context.save()
        if let allGoals = try? context.fetch(FetchDescriptor<Goal>()) {
            WidgetSnapshotStore.write(from: allGoals)
        }
        dismiss()
    }
}

// MARK: - Milestone row

struct MilestoneRowView: View {
    let goal: Goal
    let milestone: Milestone
    let accent: Accent
    let onClaim: () -> Void

    var body: some View {
        let reached = goal.isReached(milestone)
        let claimed = milestone.claimedAt != nil

        EmberCard {
            HStack(spacing: 14) {
                RewardImageView(imageFile: milestone.rewardImageFile, accent: accent, locked: !reached)
                    .frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 4) {
                    OverlineText(reached ? (claimed ? "Claimed" : "Unlocked") : "Locked",
                                 color: reached ? accent.primary : Theme.textTertiary)
                    Text(milestone.rewardTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(reached ? Theme.textPrimary : Theme.textSecondary)
                    Text(GoalFormat.milestoneLabel(
                        value: milestone.value, start: goal.startValue,
                        target: goal.targetValue, unit: goal.unit))
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(reached ? AnyShapeStyle(accent.gradient)
                                                 : AnyShapeStyle(Theme.textSecondary))
                }
                Spacer()
                if reached && !claimed {
                    Button {
                        onClaim()
                    } label: {
                        Text("CLAIM")
                            .font(Theme.label(12))
                            .tracking(1)
                            .foregroundStyle(.black.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(accent.gradient, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else if claimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(accent.gradient)
                }
            }
            .padding(14)
        }
        .opacity(reached ? 1 : 0.85)
    }
}
