import SwiftUI
import SwiftData
import PhotosUI

/// Create + edit flow. Works on plain drafts and only touches SwiftData on
/// save, so cancel is always free.
struct GoalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Nil when creating a new goal.
    var goal: Goal?

    @State private var title = ""
    @State private var unit = "lbs"
    @State private var startText = ""
    @State private var targetText = ""
    @State private var accentName = "ember"
    @State private var rewardTitle = ""
    @State private var rewardImageData: Data?
    @State private var existingRewardFile: String?
    @State private var rewardPickerItem: PhotosPickerItem?
    @State private var hasDeadline = false
    @State private var targetDate = Date().addingTimeInterval(90 * 24 * 3600)
    @State private var milestones: [MilestoneDraft] = []
    @State private var loaded = false

    struct MilestoneDraft: Identifiable {
        let id = UUID()
        var existingUUID: UUID?
        var valueText = ""
        var rewardTitle = ""
        var imageData: Data?
        var existingImageFile: String?
        var pickerItem: PhotosPickerItem?
    }

    var body: some View {
        let accent = Accent.named(accentName)

        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        section("The goal") {
                            styledField("Lose 20 lbs", text: $title)
                            HStack(spacing: 12) {
                                labeledNumberField("Start", placeholder: "220", text: $startText)
                                labeledNumberField("Target", placeholder: "200", text: $targetText)
                                VStack(alignment: .leading, spacing: 6) {
                                    OverlineText("Unit")
                                    styledField("lbs", text: $unit)
                                        .frame(width: 80)
                                }
                            }
                            Toggle(isOn: $hasDeadline) {
                                Text("Deadline")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .tint(accent.primary)
                            .padding(.horizontal, 4)
                            if hasDeadline {
                                DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.textPrimary)
                                    .tint(accent.primary)
                                    .padding(.horizontal, 4)
                            }
                        }

                        section("Color") {
                            HStack(spacing: 14) {
                                ForEach(Accent.all) { option in
                                    Button {
                                        Haptics.tap()
                                        accentName = option.name
                                    } label: {
                                        Circle()
                                            .fill(option.gradient)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle().strokeBorder(
                                                    .white.opacity(accentName == option.name ? 0.9 : 0),
                                                    lineWidth: 3)
                                            )
                                            .shadow(color: option.primary.opacity(
                                                accentName == option.name ? 0.5 : 0), radius: 8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        section("The prize — what you get at the finish") {
                            styledField("Rolex Submariner", text: $rewardTitle)
                            photoPicker(
                                selection: $rewardPickerItem,
                                imageData: rewardImageData,
                                existingFile: existingRewardFile,
                                accent: accent)
                        }

                        section("Milestones — checkpoints with their own rewards") {
                            ForEach($milestones) { $draft in
                                milestoneEditor($draft, accent: accent)
                            }
                            Button {
                                Haptics.tap()
                                milestones.append(MilestoneDraft())
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add milestone")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(accent.primary)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }

                        EmberButton(title: goal == nil ? "Light it up" : "Save changes",
                                    accent: accent, systemImage: "flame.fill") {
                            save()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1 : 0.4)
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(goal == nil ? "New goal" : "Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .onAppear(perform: loadFromGoal)
            .onChange(of: rewardPickerItem) { _, item in
                loadPhoto(item) { rewardImageData = $0 }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private func section(_ header: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            OverlineText(header)
            content()
        }
    }

    private func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radiusInner))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusInner)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }

    private func labeledNumberField(_ label: String, placeholder: String,
                                    text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            OverlineText(label)
            styledField(placeholder, text: text)
                .keyboardType(.decimalPad)
        }
    }

    private func photoPicker(selection: Binding<PhotosPickerItem?>, imageData: Data?,
                             existingFile: String?, accent: Accent) -> some View {
        PhotosPicker(selection: selection, matching: .images) {
            ZStack {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let existing = ImageStore.image(existingFile) {
                    Image(uiImage: existing)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: Theme.radiusInner)
                        .fill(Theme.card)
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 26))
                            .foregroundStyle(accent.gradient)
                        Text("Add a photo of it")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusInner))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusInner)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
        }
    }

    private func milestoneEditor(_ draft: Binding<MilestoneDraft>, accent: Accent) -> some View {
        EmberCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Value e.g. 210", text: draft.valueText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(12)
                        .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 10))
                    Button {
                        Haptics.tap()
                        milestones.removeAll { $0.id == draft.wrappedValue.id }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                TextField("Reward — e.g. New running shoes", text: draft.rewardTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 10))
                PhotosPicker(selection: draft.pickerItem, matching: .images) {
                    HStack(spacing: 8) {
                        if let data = draft.wrappedValue.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if let img = ImageStore.image(draft.wrappedValue.existingImageFile) {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo.badge.plus")
                                .foregroundStyle(accent.primary)
                        }
                        Text("Reward photo")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                    .padding(10)
                    .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 10))
                }
                .onChange(of: draft.wrappedValue.pickerItem) { _, item in
                    loadPhoto(item) { data in
                        if let index = milestones.firstIndex(where: { $0.id == draft.wrappedValue.id }) {
                            milestones[index].imageData = data
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: - Load / Save

    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !rewardTitle.trimmingCharacters(in: .whitespaces).isEmpty,
              let start = Double(startText.replacingOccurrences(of: ",", with: ".")),
              let target = Double(targetText.replacingOccurrences(of: ",", with: "."))
        else { return false }
        return start != target
    }

    private func loadFromGoal() {
        guard let goal, !loaded else { return }
        loaded = true
        title = goal.title
        unit = goal.unit
        startText = GoalFormat.number(goal.startValue)
        targetText = GoalFormat.number(goal.targetValue)
        accentName = goal.accentName
        rewardTitle = goal.rewardTitle
        existingRewardFile = goal.rewardImageFile
        hasDeadline = goal.targetDate != nil
        if let date = goal.targetDate { targetDate = date }
        milestones = goal.orderedMilestones.map { milestone in
            MilestoneDraft(
                existingUUID: milestone.uuid,
                valueText: GoalFormat.number(milestone.value),
                rewardTitle: milestone.rewardTitle,
                existingImageFile: milestone.rewardImageFile)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?, into assign: @escaping (Data?) -> Void) {
        guard let item else { return }
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await MainActor.run { assign(data) }
        }
    }

    private func save() {
        guard let start = Double(startText.replacingOccurrences(of: ",", with: ".")),
              let target = Double(targetText.replacingOccurrences(of: ",", with: "."))
        else { return }

        let saved: Goal
        if let goal {
            saved = goal
            goal.title = title
            goal.unit = unit
            goal.startValue = start
            goal.targetValue = target
            goal.accentName = accentName
            goal.rewardTitle = rewardTitle
            goal.targetDate = hasDeadline ? targetDate : nil
        } else {
            saved = Goal(title: title, unit: unit, startValue: start, targetValue: target,
                         accentName: accentName, rewardTitle: rewardTitle,
                         targetDate: hasDeadline ? targetDate : nil)
            context.insert(saved)
        }

        if let data = rewardImageData, let file = ImageStore.save(data) {
            ImageStore.delete(saved.rewardImageFile)
            saved.rewardImageFile = file
        }

        // Reconcile milestones: update kept ones, remove dropped ones, add new.
        let draftUUIDs = Set(milestones.compactMap(\.existingUUID))
        for existing in saved.milestones where !draftUUIDs.contains(existing.uuid) {
            ImageStore.delete(existing.rewardImageFile)
            context.delete(existing)
        }
        for draft in milestones {
            guard let value = Double(draft.valueText.replacingOccurrences(of: ",", with: ".")),
                  !draft.rewardTitle.trimmingCharacters(in: .whitespaces).isEmpty
            else { continue }

            let milestone: Milestone
            if let uuid = draft.existingUUID,
               let existing = saved.milestones.first(where: { $0.uuid == uuid }) {
                milestone = existing
            } else {
                milestone = Milestone(value: value, rewardTitle: draft.rewardTitle)
                milestone.goal = saved
                context.insert(milestone)
            }
            milestone.value = value
            milestone.rewardTitle = draft.rewardTitle
            if let data = draft.imageData, let file = ImageStore.save(data) {
                ImageStore.delete(milestone.rewardImageFile)
                milestone.rewardImageFile = file
            }
        }

        try? context.save()
        if let allGoals = try? context.fetch(FetchDescriptor<Goal>()) {
            WidgetSnapshotStore.write(from: allGoals)
        }
        Haptics.firm()
        dismiss()
    }
}
