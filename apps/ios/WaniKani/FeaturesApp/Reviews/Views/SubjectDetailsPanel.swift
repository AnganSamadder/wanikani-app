import Foundation
import SwiftUI
import WaniKaniCore

struct SubjectDetailsPanel: View {
    let prefetchedEnrichment: EnrichedDetail?
    @State private var isExpanded = true
    @State private var fetchedEnrichment: EnrichedDetail = .empty
    @State private var meaningNoteInput = ""
    @State private var readingNoteInput = ""
    @State private var synonymInput = ""
    @State private var isAddingSynonym = false
    @State private var isEditingMeaningNote = false
    @State private var isEditingReadingNote = false
    @EnvironmentObject private var audioService: AudioPlaybackService
    @StateObject private var enrichmentManager = LinguisticEnrichmentManager()
    @StateObject private var detailsViewModel: SubjectDetailsViewModel
    private let maxInlinePitchPatterns = 1

    init(
        subject: SubjectSnapshot,
        reviewViewModel: ReviewSessionViewModel,
        prefetchedEnrichment: EnrichedDetail? = nil
    ) {
        self.prefetchedEnrichment = prefetchedEnrichment
        _detailsViewModel = StateObject(
            wrappedValue: SubjectDetailsViewModel(subject: subject, reviewViewModel: reviewViewModel)
        )
    }

    private var displaySubject: SubjectSnapshot {
        detailsViewModel.subject
    }

    private var subjectTint: Color {
        WKColor.forSubjectType(displaySubject.object)
    }

    private var userSynonyms: [String] {
        detailsViewModel.studyMaterial?.meaningSynonyms ?? []
    }

    private var relatedAmalgamationsTitle: String {
        displaySubject.object == "radical" ? "Found In Kanji" : "Found In Vocabulary"
    }

    private var effectiveEnrichment: EnrichedDetail {
        let prefetched = prefetchedEnrichment ?? .empty
        return EnrichedDetail(
            pitchPatterns: fetchedEnrichment.pitchPatterns.isEmpty ? prefetched.pitchPatterns : fetchedEnrichment.pitchPatterns,
            strokeOrderSVG: fetchedEnrichment.strokeOrderSVG ?? prefetched.strokeOrderSVG
        )
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 16) {
                if displaySubject.object == "vocabulary", !detailsViewModel.relatedComponents.isEmpty {
                    subjectGridSection(title: "Kanji Composition", subjects: detailsViewModel.relatedComponents)
                }

                overviewSection

                if !displaySubject.partsOfSpeech.isEmpty {
                    partsOfSpeechSection
                }

                if let mnemonic = displaySubject.meaningMnemonic {
                    mnemonicSection(title: "Meaning Mnemonic", text: mnemonic, hint: displaySubject.meaningHint)
                }
                if let mnemonic = displaySubject.readingMnemonic {
                    mnemonicSection(title: "Reading Mnemonic", text: mnemonic, hint: displaySubject.readingHint)
                }

                if !displaySubject.contextSentences.isEmpty {
                    contextSentencesSection
                }

                if displaySubject.object == "kanji", !detailsViewModel.relatedComponents.isEmpty {
                    subjectGridSection(title: "Radical Combination", subjects: detailsViewModel.relatedComponents)
                }

                if displaySubject.object == "kanji", !detailsViewModel.visuallySimilar.isEmpty {
                    subjectGridSection(title: "Visually Similar Kanji", subjects: detailsViewModel.visuallySimilar)
                }

                if !detailsViewModel.relatedAmalgamations.isEmpty {
                    subjectGridSection(title: relatedAmalgamationsTitle, subjects: detailsViewModel.relatedAmalgamations)
                }
            }
            .padding(.top, 8)
        } label: {
            Text("Details")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(subjectTint)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task {
            await detailsViewModel.load()
            meaningNoteInput = detailsViewModel.studyMaterial?.meaningNote ?? ""
            readingNoteInput = detailsViewModel.studyMaterial?.readingNote ?? ""
            fetchedEnrichment = await enrichmentManager.enrich(subject: displaySubject)
        }
    }

    // MARK: - Meanings

    @ViewBuilder
    private var overviewSection: some View {
        if displaySubject.object == "radical" {
            HStack(alignment: .top, spacing: 16) {
                meaningsSection
                    .frame(maxWidth: .infinity, alignment: .leading)
                studyMaterialSection
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } else {
            HStack(alignment: .top, spacing: 16) {
                leftColumnSection
                    .frame(maxWidth: .infinity, alignment: .leading)
                rightColumnSection
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var leftColumnSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            meaningsSection
            studyMaterialSection
        }
    }

    private var rightColumnSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            readingsSection
            if !displaySubject.pronunciationAudios.isEmpty {
                audioSection
            }
            if displaySubject.object == "kanji" {
                strokeOrderSection
            }
        }
    }

    private var meaningsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meaning")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(displaySubject.meanings.sorted { $0.primary && !$1.primary }, id: \.meaning) { meaning in
                Text(meaning.meaning)
                    .font(meaning.primary ? .body.weight(.semibold) : .body)
            }

            if !displaySubject.auxiliaryMeanings.isEmpty {
                let accepted = displaySubject.auxiliaryMeanings.filter { $0.type == "whitelist" }.map(\.meaning)
                if !accepted.isEmpty {
                    Text("Also accepted: \(accepted.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        }
        .textSelection(.enabled)
    }

    private var studyMaterialSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study Material")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("User Synonyms")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                if userSynonyms.isEmpty {
                    Text("No synonyms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(userSynonyms.joined(separator: ", "))
                        .font(.caption)
                }

            if isAddingSynonym {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Add synonym", text: $synonymInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lineLimit(1)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .submitLabel(.done)
                        .onSubmit {
                            Task {
                                await addSynonym()
                                isAddingSynonym = false
                            }
                        }

                    HStack(spacing: 8) {
                        Button("Add") {
                            Task {
                                await addSynonym()
                                isAddingSynonym = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(subjectTint)
                        .disabled(synonymInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || detailsViewModel.isSaving)

                        Button("Cancel") {
                            synonymInput = ""
                            isAddingSynonym = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                Button {
                        isAddingSynonym = true
                    } label: {
                        Label("Add Synonym", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(subjectTint)
                }
            }

            noteEditorSection(
                title: "Meaning Note",
                text: $meaningNoteInput,
                isEditing: $isEditingMeaningNote,
                placeholder: "Add meaning note",
                onSave: {
                    await saveStudyMaterial(
                        meaningNote: meaningNoteInput,
                        readingNote: readingNoteInput,
                        meaningSynonyms: userSynonyms
                    )
                },
                onCancel: {
                    meaningNoteInput = detailsViewModel.studyMaterial?.meaningNote ?? ""
                }
            )

            noteEditorSection(
                title: "Reading Note",
                text: $readingNoteInput,
                isEditing: $isEditingReadingNote,
                placeholder: "Add reading note",
                onSave: {
                    await saveStudyMaterial(
                        meaningNote: meaningNoteInput,
                        readingNote: readingNoteInput,
                        meaningSynonyms: userSynonyms
                    )
                },
                onCancel: {
                    readingNoteInput = detailsViewModel.studyMaterial?.readingNote ?? ""
                }
            )
        }
    }

    // MARK: - Readings

    private var readingsSection: some View {
        let accents = resolvePitchAccents(patterns: effectiveEnrichment.pitchPatterns)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Readings")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if !onyomiReadings.isEmpty {
                readingCategory(title: "On’yomi", readings: onyomiReadings, accents: accents)
            }

            if !kunyomiReadings.isEmpty {
                readingCategory(title: "Kun’yomi", readings: kunyomiReadings, accents: accents)
            }

            if !otherReadings.isEmpty {
                readingCategory(
                    title: (onyomiReadings.isEmpty && kunyomiReadings.isEmpty) ? "Reading" : "Other",
                    readings: otherReadings,
                    accents: accents
                )
            }

            if !displaySubject.hasReadings {
                Text("No readings for this subject.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .textSelection(.enabled)
    }

    private var onyomiReadings: [ReadingSnapshot] {
        displaySubject.readings.filter { $0.type?.lowercased() == "onyomi" }
            .sorted { $0.primary && !$1.primary }
    }

    private var kunyomiReadings: [ReadingSnapshot] {
        displaySubject.readings.filter { $0.type?.lowercased() == "kunyomi" }
            .sorted { $0.primary && !$1.primary }
    }

    private var otherReadings: [ReadingSnapshot] {
        displaySubject.readings.filter {
            guard let type = $0.type?.lowercased() else { return true }
            return type != "onyomi" && type != "kunyomi"
        }
        .sorted { $0.primary && !$1.primary }
    }

    @ViewBuilder
    private func readingCategory(title: String, readings: [ReadingSnapshot], accents: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            let hasPrimary = readings.contains { $0.primary }
            ForEach(Array(readings.enumerated()), id: \.offset) { index, reading in
                let readingText = formattedReading(reading.reading, type: reading.type)
                let displayAccents = effectiveAccents(for: reading.reading, accents: accents)
                let isBold = reading.primary || (!hasPrimary && index == 0)
                HStack(alignment: .top, spacing: 8) {
                    Text(readingText)
                        .font(isBold ? .body.weight(.semibold) : .body)
                        .layoutPriority(1)

                    if !displayAccents.isEmpty {
                        pitchAccentInline(reading: readingText, accents: displayAccents)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func pitchAccentInline(reading: String, accents: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(accents.prefix(maxInlinePitchPatterns)), id: \.self) { accent in
                PitchAccentContourView(
                    reading: reading,
                    accent: accent,
                    tint: subjectTint
                )
            }
        }
    }

    private func effectiveAccents(for reading: String, accents: [Int]) -> [Int] {
        if !accents.isEmpty {
            return accents
        }
        let moras = PitchAccentContourView.moras(from: reading)
        guard !moras.isEmpty else { return [] }
        if moras.count == 1 {
            return [0]
        }
        return [min(2, moras.count)]
    }

    private var partsOfSpeechSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Word Type")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(displaySubject.partsOfSpeech.joined(separator: ", "))
                .font(.body)
        }
    }

    private func formattedReading(_ reading: String, type: String?) -> String {
        guard type?.lowercased() == "onyomi" else { return reading }
        return reading.applyingTransform(.hiraganaToKatakana, reverse: false) ?? reading
    }

    // MARK: - Mnemonics

    private func mnemonicSection(title: String, text: String, hint: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            WKMarkupText(text: text)
            if let hint, !hint.isEmpty {
                DisclosureGroup("Hints") {
                    WKMarkupText(text: hint, font: .caption)
                        .padding(.top, 4)
                }
                .font(.caption)
            }
        }
        .textSelection(.enabled)
    }

    // MARK: - Context

    private var contextSentencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Context Sentences")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(displaySubject.contextSentences, id: \.ja) { sentence in
                VStack(alignment: .leading, spacing: 2) {
                    Text(sentence.ja)
                        .font(.body)
                    Text(sentence.en)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Stroke Order

    @ViewBuilder
    private var strokeOrderSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Stroke Order")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let svg = effectiveEnrichment.strokeOrderSVG {
                KanjiStrokeAnimationView(svgString: svg)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 220, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Text("Stroke order data unavailable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pronunciation")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(displaySubject.pronunciationAudios, id: \.url) { audio in
                if let url = URL(string: audio.url) {
                    Button {
                        audioService.toggle(url: url)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: audioService.isPlaying && audioService.currentURL == url
                                  ? "stop.circle.fill"
                                  : "play.circle.fill")
                            Text(audio.metadata?.voiceActorName ?? "Audio")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .tint(subjectTint)
                }
            }
        }
    }

    // MARK: - Related subjects

    private func subjectGridSection(title: String, subjects: [SubjectSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                ForEach(subjects) { related in
                    VStack(spacing: 2) {
                        Text(related.characters ?? related.slug)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        Text(related.primaryMeaning ?? related.slug)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(WKColor.backgroundForSubjectType(related.object))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Actions

    private func addSynonym() async {
        let trimmed = synonymInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let merged = Array(Set(userSynonyms + [trimmed])).sorted()
        await saveStudyMaterial(
            meaningNote: meaningNoteInput,
            readingNote: readingNoteInput,
            meaningSynonyms: merged
        )
        synonymInput = ""
    }

    private func saveStudyMaterial(
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String]
    ) async {
        await detailsViewModel.saveStudyMaterial(
            meaningNote: normalizedText(meaningNote),
            readingNote: normalizedText(readingNote),
            meaningSynonyms: meaningSynonyms
        )
        meaningNoteInput = detailsViewModel.studyMaterial?.meaningNote ?? ""
        readingNoteInput = detailsViewModel.studyMaterial?.readingNote ?? ""
    }

    private func normalizedText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func resolvePitchAccents(patterns: [PitchPattern]) -> [Int] {
        var ordered: [Int] = []
        for pattern in patterns {
            let values = pattern.pattern
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            for value in values where !ordered.contains(value) {
                ordered.append(value)
            }
        }
        return ordered
    }

    @ViewBuilder
    private func noteEditorSection(
        title: String,
        text: Binding<String>,
        isEditing: Binding<Bool>,
        placeholder: String,
        onSave: @escaping @Sendable () async -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if isEditing.wrappedValue {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Button(detailsViewModel.isSaving ? "Saving..." : "Save") {
                        Task {
                            await onSave()
                            isEditing.wrappedValue = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(subjectTint)
                    .disabled(detailsViewModel.isSaving)

                    Button("Cancel") {
                        onCancel()
                        isEditing.wrappedValue = false
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                let value = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    Text(value)
                        .font(.caption)
                }
                Button {
                    isEditing.wrappedValue = true
                } label: {
                    Label(value.isEmpty ? "Add Note" : "Edit Note", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(subjectTint)
            }
        }
    }
}

private struct PitchAccentContourView: View {
    let reading: String
    let accent: Int
    let tint: Color

    private let step: CGFloat = 17
    private let leadingInset: CGFloat = 4
    private let highY: CGFloat = 4
    private let lowY: CGFloat = 13
    private let dotRadius: CGFloat = 2.7

    private var moras: [String] {
        PitchAccentContourView.moras(from: reading)
    }

    private var graphWidth: CGFloat {
        max(CGFloat(max(moras.count - 1, 0)) * step + 12, 20)
    }

    private var points: [CGPoint] {
        moras.enumerated().map { index, _ in
            let isHigh = pitchLevel(for: index)
            return CGPoint(x: CGFloat(index) * step + leadingInset, y: isHigh ? highY : lowY)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                ForEach(Array(moras.enumerated()), id: \.offset) { _, mora in
                    Text(mora)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: step, alignment: .center)
                }
            }
            .padding(.top, 11)

            Canvas { context, _ in
                guard !points.isEmpty else { return }

                let contourPath = contourPath(for: points)
                context.stroke(
                    contourPath,
                    with: .color(tint.opacity(0.98)),
                    style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round)
                )

                for point in points {
                    let dotRect = CGRect(
                        x: point.x - dotRadius,
                        y: point.y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: dotRect), with: .color(tint.opacity(0.98)))
                }
            }
            .frame(width: graphWidth, height: 24)
        }
        .frame(width: graphWidth, height: 24, alignment: .topLeading)
    }

    private func contourPath(for points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        let leftGuideX = max(0, first.x - step * 0.4)
        path.move(to: CGPoint(x: leftGuideX, y: first.y))
        path.addLine(to: first)

        var previous = first
        for current in points.dropFirst() {
            if abs(previous.y - current.y) < .ulpOfOne {
                path.addLine(to: current)
            } else {
                // Keep diagonal transitions at exactly 45° by using equal run/rise.
                let rise = current.y - previous.y
                let diagonalRun = abs(rise)
                let diagonalStartX = max(previous.x, current.x - diagonalRun)

                if diagonalStartX > previous.x {
                    path.addLine(to: CGPoint(x: diagonalStartX, y: previous.y))
                }

                path.addLine(to: CGPoint(x: diagonalStartX + diagonalRun, y: current.y))
            }
            previous = current
        }

        if let last = points.last {
            path.addLine(to: CGPoint(x: last.x + step * 0.45, y: last.y))
        }

        return path
    }

    private func pitchLevel(for index: Int) -> Bool {
        if accent == 0 {
            return index > 0
        }
        return index < min(accent, moras.count)
    }

    static func moras(from reading: String) -> [String] {
        let smallKana = Set("ゃゅょぁぃぅぇぉャュョァィゥェォゎヮ")
        var result: [String] = []
        for scalar in reading {
            let char = String(scalar)
            if smallKana.contains(scalar), let last = result.last {
                result[result.count - 1] = last + char
            } else {
                result.append(char)
            }
        }
        return result.isEmpty ? [reading] : result
    }
}

// MARK: - Native Stroke Animation

private struct KanjiStrokePathModel: Identifiable {
    let id: Int
    let path: Path
    let length: CGFloat
}

private struct KanjiStrokeAnimationView: View {
    private struct StrokeTiming {
        let start: TimeInterval
        let duration: TimeInterval
        var end: TimeInterval { start + duration }
    }

    private let strokes: [KanjiStrokePathModel]
    private let timings: [StrokeTiming]
    private let totalDuration: TimeInterval
    private let strokeWidth: CGFloat
    private let viewBoxSize: CGFloat = Self.defaultViewBoxSize
    private static let defaultViewBoxSize: CGFloat = 109

    @State private var isPlaying = false
    @State private var animationStart = Date()
    @State private var pausedPosition: TimeInterval
    @State private var animationTask: Task<Void, Never>?

    init(svgString: String) {
        let rawModels = StrokeOrderSVGExtractor.makeStrokeModels(from: svgString)
        let models = Self.centeredStrokeModels(rawModels, in: Self.defaultViewBoxSize)
        self.strokes = models
        self.strokeWidth = models.count > 16 ? 4 : 5

        let speed: CGFloat = 150
        let gap: TimeInterval = 0.25
        let freeze: TimeInterval = 1

        var builtTimings: [StrokeTiming] = []
        builtTimings.reserveCapacity(models.count)

        var cursor: TimeInterval = 0
        for model in models {
            let duration = max(TimeInterval(model.length / speed), 0.08)
            builtTimings.append(StrokeTiming(start: cursor, duration: duration))
            cursor += duration + gap
        }

        if !builtTimings.isEmpty {
            cursor -= gap
            cursor += freeze
        }

        let finalDuration = max(cursor, 0)
        self.timings = builtTimings
        self.totalDuration = finalDuration
        _pausedPosition = State(initialValue: finalDuration)
    }

    private static func centeredStrokeModels(
        _ models: [KanjiStrokePathModel],
        in side: CGFloat
    ) -> [KanjiStrokePathModel] {
        guard !models.isEmpty else { return [] }

        var unionBounds = CGRect.null
        for model in models {
            unionBounds = unionBounds.union(model.path.boundingRect)
        }

        guard !unionBounds.isNull, unionBounds.width > 0, unionBounds.height > 0 else {
            return models
        }

        let inset: CGFloat = 6
        let availableSide = max(side - (inset * 2), 1)
        let scale = min(availableSide / unionBounds.width, availableSide / unionBounds.height)
        let scaledWidth = unionBounds.width * scale
        let scaledHeight = unionBounds.height * scale
        let offsetX = ((side - scaledWidth) / 2) - (unionBounds.minX * scale)
        let offsetY = ((side - scaledHeight) / 2) - (unionBounds.minY * scale)
        var transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: offsetX, ty: offsetY)

        return models.map { model in
            guard let transformedPath = model.path.cgPath.copy(using: &transform) else {
                return model
            }
            return KanjiStrokePathModel(
                id: model.id,
                path: Path(transformedPath),
                length: max(model.length * scale, 1)
            )
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isPlaying)) { timeline in
            GeometryReader { proxy in
                let elapsed = playbackPosition(at: timeline.date)
                let side = min(proxy.size.width, proxy.size.height)
                let scale = side / viewBoxSize

                ZStack {
                    if isPlaying {
                        ForEach(strokes) { stroke in
                            stroke.path
                                .stroke(
                                    Color.white.opacity(0.2),
                                    style: StrokeStyle(
                                        lineWidth: strokeWidth,
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )
                        }

                        ForEach(Array(strokes.enumerated()), id: \.offset) { index, stroke in
                            let trim = trimProgress(for: index, elapsed: elapsed)
                            if trim > 0 {
                                stroke.path
                                    .trim(from: 0, to: trim)
                                    .stroke(
                                        Color.white,
                                        style: StrokeStyle(
                                            lineWidth: strokeWidth,
                                            lineCap: .round,
                                            lineJoin: .round
                                        )
                                    )
                            }
                        }
                    } else {
                        ForEach(strokes) { stroke in
                            stroke.path
                                .stroke(
                                    Color.white,
                                    style: StrokeStyle(
                                        lineWidth: strokeWidth,
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )
                        }
                    }
                }
                .frame(width: viewBoxSize, height: viewBoxSize)
                .scaleEffect(scale)
                .frame(width: side, height: side, alignment: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .onTapGesture {
                    startOneShotAnimation()
                }
            }
        }
        .background(Color(.tertiarySystemBackground))
        .contentShape(Rectangle())
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
            isPlaying = false
            pausedPosition = totalDuration
        }
    }

    private func playbackPosition(at date: Date) -> TimeInterval {
        guard totalDuration > 0 else { return 0 }
        if isPlaying {
            return min(max(date.timeIntervalSince(animationStart), 0), totalDuration)
        }
        return pausedPosition
    }

    private func trimProgress(for index: Int, elapsed: TimeInterval) -> CGFloat {
        guard timings.indices.contains(index) else { return 0 }
        let timing = timings[index]
        if elapsed <= timing.start { return 0 }
        if elapsed >= timing.end { return 1 }
        return CGFloat((elapsed - timing.start) / timing.duration)
    }

    private func startOneShotAnimation() {
        guard totalDuration > 0 else { return }
        animationTask?.cancel()
        pausedPosition = 0
        animationStart = Date()
        isPlaying = true

        animationTask = Task { @MainActor in
            let nanos = UInt64(totalDuration * 1_000_000_000)
            if nanos > 0 {
                try? await Task.sleep(nanoseconds: nanos)
            }
            guard !Task.isCancelled else { return }
            isPlaying = false
            pausedPosition = totalDuration
            animationTask = nil
        }
    }
}

private enum StrokeOrderSVGExtractor {
    static func makeStrokeModels(from svgString: String) -> [KanjiStrokePathModel] {
        let pathData = strokePathData(from: svgString)
        return pathData.enumerated().compactMap { index, d in
            var parser = SVGPathParser(pathData: d)
            let cgPath = parser.parse()
            guard !cgPath.isEmpty else { return nil }

            let length = max(cgPath.approximateLength(), 1)
            return KanjiStrokePathModel(
                id: index,
                path: Path(cgPath),
                length: length
            )
        }
    }

    private static func strokePathData(from svgString: String) -> [String] {
        let strokePaths = capture(
            pattern: #"<path[^>]*id=['"][^'"]*-s\d+[^'"]*['"][^>]*d=['"]([^'"]+)['"][^>]*>"#,
            in: svgString
        )
        if !strokePaths.isEmpty {
            return strokePaths
        }

        return capture(
            pattern: #"<path[^>]*d=['"]([^'"]+)['"][^>]*>"#,
            in: svgString
        )
    }

    private static func capture(pattern: String, in input: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        let matches = regex.matches(in: input, options: [], range: range)
        return matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let captureRange = Range(match.range(at: 1), in: input) else {
                return nil
            }
            return String(input[captureRange])
        }
    }
}

private struct SVGPathParser {
    private let characters: [Character]
    private var index = 0
    private var previousCommand: Character?
    private var currentPoint = CGPoint.zero
    private var subpathStart = CGPoint.zero
    private var lastCubicControl: CGPoint?
    private var lastQuadControl: CGPoint?

    init(pathData: String) {
        self.characters = Array(pathData)
    }

    mutating func parse() -> CGPath {
        let path = CGMutablePath()

        while true {
            skipSeparators()
            guard index < characters.count else { break }

            let command: Character
            if characters[index].isLetter {
                command = characters[index]
                previousCommand = command
                index += 1
            } else if let previousCommand {
                command = previousCommand
            } else {
                break
            }

            switch command {
            case "M", "m":
                parseMove(path: path, relative: command == "m")
                lastCubicControl = nil
                lastQuadControl = nil
            case "L", "l":
                parseLine(path: path, relative: command == "l")
                lastCubicControl = nil
                lastQuadControl = nil
            case "H", "h":
                parseHorizontal(path: path, relative: command == "h")
                lastCubicControl = nil
                lastQuadControl = nil
            case "V", "v":
                parseVertical(path: path, relative: command == "v")
                lastCubicControl = nil
                lastQuadControl = nil
            case "C", "c":
                parseCubic(path: path, relative: command == "c")
                lastQuadControl = nil
            case "S", "s":
                parseSmoothCubic(path: path, relative: command == "s")
                lastQuadControl = nil
            case "Q", "q":
                parseQuadratic(path: path, relative: command == "q")
                lastCubicControl = nil
            case "T", "t":
                parseSmoothQuadratic(path: path, relative: command == "t")
                lastCubicControl = nil
            case "A", "a":
                parseArcAsLine(path: path, relative: command == "a")
                lastCubicControl = nil
                lastQuadControl = nil
            case "Z", "z":
                path.closeSubpath()
                currentPoint = subpathStart
                lastCubicControl = nil
                lastQuadControl = nil
            default:
                previousCommand = nil
            }
        }

        return path
    }

    private mutating func parseMove(path: CGMutablePath, relative: Bool) {
        var isFirst = true
        while let point = readPoint() {
            let resolved = resolve(point: point, relative: relative)
            if isFirst {
                path.move(to: resolved)
                subpathStart = resolved
                isFirst = false
            } else {
                path.addLine(to: resolved)
            }
            currentPoint = resolved
        }
    }

    private mutating func parseLine(path: CGMutablePath, relative: Bool) {
        while let point = readPoint() {
            let resolved = resolve(point: point, relative: relative)
            path.addLine(to: resolved)
            currentPoint = resolved
        }
    }

    private mutating func parseHorizontal(path: CGMutablePath, relative: Bool) {
        while let value = readCGFloat() {
            let x = relative ? currentPoint.x + value : value
            let resolved = CGPoint(x: x, y: currentPoint.y)
            path.addLine(to: resolved)
            currentPoint = resolved
        }
    }

    private mutating func parseVertical(path: CGMutablePath, relative: Bool) {
        while let value = readCGFloat() {
            let y = relative ? currentPoint.y + value : value
            let resolved = CGPoint(x: currentPoint.x, y: y)
            path.addLine(to: resolved)
            currentPoint = resolved
        }
    }

    private mutating func parseCubic(path: CGMutablePath, relative: Bool) {
        while let control1 = readPoint(),
              let control2 = readPoint(),
              let end = readPoint() {
            let c1 = resolve(point: control1, relative: relative)
            let c2 = resolve(point: control2, relative: relative)
            let resolvedEnd = resolve(point: end, relative: relative)
            path.addCurve(to: resolvedEnd, control1: c1, control2: c2)
            currentPoint = resolvedEnd
            lastCubicControl = c2
        }
    }

    private mutating func parseSmoothCubic(path: CGMutablePath, relative: Bool) {
        while let control2 = readPoint(),
              let end = readPoint() {
            let control1: CGPoint
            if let lastCubicControl {
                control1 = reflected(point: lastCubicControl, around: currentPoint)
            } else {
                control1 = currentPoint
            }

            let c2 = resolve(point: control2, relative: relative)
            let resolvedEnd = resolve(point: end, relative: relative)
            path.addCurve(to: resolvedEnd, control1: control1, control2: c2)
            currentPoint = resolvedEnd
            lastCubicControl = c2
        }
    }

    private mutating func parseQuadratic(path: CGMutablePath, relative: Bool) {
        while let control = readPoint(),
              let end = readPoint() {
            let c = resolve(point: control, relative: relative)
            let resolvedEnd = resolve(point: end, relative: relative)
            path.addQuadCurve(to: resolvedEnd, control: c)
            currentPoint = resolvedEnd
            lastQuadControl = c
        }
    }

    private mutating func parseSmoothQuadratic(path: CGMutablePath, relative: Bool) {
        while let end = readPoint() {
            let control: CGPoint
            if let lastQuadControl {
                control = reflected(point: lastQuadControl, around: currentPoint)
            } else {
                control = currentPoint
            }
            let resolvedEnd = resolve(point: end, relative: relative)
            path.addQuadCurve(to: resolvedEnd, control: control)
            currentPoint = resolvedEnd
            lastQuadControl = control
        }
    }

    private mutating func parseArcAsLine(path: CGMutablePath, relative: Bool) {
        while let _ = readCGFloat(),
              let _ = readCGFloat(),
              let _ = readCGFloat(),
              let _ = readCGFloat(),
              let _ = readCGFloat(),
              let x = readCGFloat(),
              let y = readCGFloat() {
            let resolved = relative
                ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                : CGPoint(x: x, y: y)
            path.addLine(to: resolved)
            currentPoint = resolved
        }
    }

    private func reflected(point: CGPoint, around center: CGPoint) -> CGPoint {
        CGPoint(x: center.x * 2 - point.x, y: center.y * 2 - point.y)
    }

    private func resolve(point: CGPoint, relative: Bool) -> CGPoint {
        guard relative else { return point }
        return CGPoint(x: currentPoint.x + point.x, y: currentPoint.y + point.y)
    }

    private mutating func readPoint() -> CGPoint? {
        guard let x = readCGFloat(), let y = readCGFloat() else { return nil }
        return CGPoint(x: x, y: y)
    }

    private mutating func readCGFloat() -> CGFloat? {
        skipSeparators()
        guard index < characters.count else { return nil }

        let start = index
        var hasDigits = false

        if characters[index] == "+" || characters[index] == "-" {
            index += 1
        }

        while index < characters.count, characters[index].isNumber {
            hasDigits = true
            index += 1
        }

        if index < characters.count, characters[index] == "." {
            index += 1
            while index < characters.count, characters[index].isNumber {
                hasDigits = true
                index += 1
            }
        }

        guard hasDigits else {
            index = start
            return nil
        }

        if index < characters.count, characters[index] == "e" || characters[index] == "E" {
            let exponentStart = index
            index += 1
            if index < characters.count, characters[index] == "+" || characters[index] == "-" {
                index += 1
            }
            var hasExponentDigits = false
            while index < characters.count, characters[index].isNumber {
                hasExponentDigits = true
                index += 1
            }
            if !hasExponentDigits {
                index = exponentStart
            }
        }

        let token = String(characters[start..<index])
        guard let value = Double(token) else {
            index = start
            return nil
        }
        return CGFloat(value)
    }

    private mutating func skipSeparators() {
        while index < characters.count {
            let char = characters[index]
            if char == " " || char == "," || char == "\n" || char == "\r" || char == "\t" {
                index += 1
            } else {
                break
            }
        }
    }
}

private extension CGPath {
    func approximateLength(samplesPerCurve: Int = 20) -> CGFloat {
        var totalLength: CGFloat = 0
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero

        forEach { element in
            switch element.type {
            case .moveToPoint:
                current = element.points[0]
                subpathStart = current
            case .addLineToPoint:
                let next = element.points[0]
                totalLength += current.distance(to: next)
                current = next
            case .addQuadCurveToPoint:
                let control = element.points[0]
                let end = element.points[1]
                var previous = current
                for step in 1...samplesPerCurve {
                    let t = CGFloat(step) / CGFloat(samplesPerCurve)
                    let point = CGPoint.quadraticBezier(t: t, p0: current, p1: control, p2: end)
                    totalLength += previous.distance(to: point)
                    previous = point
                }
                current = end
            case .addCurveToPoint:
                let control1 = element.points[0]
                let control2 = element.points[1]
                let end = element.points[2]
                var previous = current
                for step in 1...samplesPerCurve {
                    let t = CGFloat(step) / CGFloat(samplesPerCurve)
                    let point = CGPoint.cubicBezier(
                        t: t,
                        p0: current,
                        p1: control1,
                        p2: control2,
                        p3: end
                    )
                    totalLength += previous.distance(to: point)
                    previous = point
                }
                current = end
            case .closeSubpath:
                totalLength += current.distance(to: subpathStart)
                current = subpathStart
            @unknown default:
                break
            }
        }

        return totalLength
    }

    func forEach(_ body: @escaping (CGPathElement) -> Void) {
        let callbackInfo = CGPathCallbackBox(body)
        let info = Unmanaged.passRetained(callbackInfo)
        apply(info: info.toOpaque()) { info, element in
            guard let info else { return }
            let callbackInfo = Unmanaged<CGPathCallbackBox>.fromOpaque(info).takeUnretainedValue()
            callbackInfo.callback(element.pointee)
        }
        info.release()
    }
}

private final class CGPathCallbackBox {
    let callback: (CGPathElement) -> Void

    init(_ callback: @escaping (CGPathElement) -> Void) {
        self.callback = callback
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - x
        let dy = point.y - y
        return sqrt(dx * dx + dy * dy)
    }

    static func quadraticBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * p1.x + t * t * p2.x
        let y = oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    static func cubicBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * oneMinusT * p0.x
            + 3 * oneMinusT * oneMinusT * t * p1.x
            + 3 * oneMinusT * t * t * p2.x
            + t * t * t * p3.x
        let y = oneMinusT * oneMinusT * oneMinusT * p0.y
            + 3 * oneMinusT * oneMinusT * t * p1.y
            + 3 * oneMinusT * t * t * p2.y
            + t * t * t * p3.y
        return CGPoint(x: x, y: y)
    }
}
