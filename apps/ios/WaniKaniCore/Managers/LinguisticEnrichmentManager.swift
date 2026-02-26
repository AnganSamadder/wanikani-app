import Foundation

public struct EnrichedDetail: Sendable {
    public let pitchPatterns: [PitchPattern]
    public let strokeOrderSVG: String?

    public init(pitchPatterns: [PitchPattern], strokeOrderSVG: String?) {
        self.pitchPatterns = pitchPatterns
        self.strokeOrderSVG = strokeOrderSVG
    }

    public static let empty = EnrichedDetail(pitchPatterns: [], strokeOrderSVG: nil)
}

/// Owns pitch accent and stroke order providers, enriching subjects with linguistic data.
@MainActor
public final class LinguisticEnrichmentManager: ObservableObject {
    private let pitchAccentProvider = PitchAccentProvider()
    private let strokeOrderProvider = StrokeOrderProvider()

    /// Attribution strings for display in Settings.
    public static let attributionEntries: [String] = [
        "Kanjium (CC BY-SA 4.0)",
        "KanjiVG (CC BY-SA 3.0)"
    ]

    public init() {}

    public func enrich(subject: SubjectSnapshot) async -> EnrichedDetail {
        let characters = subject.characters ?? subject.slug
        let reading = subject.primaryReading ?? ""

        async let pitchTask: [PitchPattern] = {
            await withTaskGroup(of: [PitchPattern].self) { group in
                group.addTask {
                    await self.pitchAccentProvider.patterns(for: characters, reading: reading)
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    return []
                }
                let result = await group.next() ?? []
                group.cancelAll()
                return result
            }
        }()

        async let strokeTask: String? = {
            guard let firstChar = characters.first else { return nil as String? }
            return await withTaskGroup(of: String?.self) { group in
                group.addTask {
                    try? await self.strokeOrderProvider.strokeOrderSVG(for: firstChar)
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    return nil
                }
                let result = await group.next() ?? nil
                group.cancelAll()
                return result
            }
        }()

        let (pitch, stroke) = await (pitchTask, strokeTask)
        return EnrichedDetail(pitchPatterns: pitch, strokeOrderSVG: stroke)
    }
}
