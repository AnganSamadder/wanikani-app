import SwiftUI
import WaniKaniCore
import WebKit

struct SubjectDetailsPanel: View {
    let subject: SubjectSnapshot
    @State private var isExpanded = true
    @State private var enrichedDetail: EnrichedDetail = .empty
    @State private var isLoadingEnrichment = false
    @EnvironmentObject private var audioService: AudioPlaybackService

    @StateObject private var enrichmentManager = LinguisticEnrichmentManager()

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 16) {
                meaningsSection
                if subject.hasReadings {
                    readingsSection
                }
                if let mnemonic = subject.meaningMnemonic {
                    mnemonicSection(title: "Meaning Mnemonic", text: mnemonic, hint: subject.meaningHint)
                }
                if let mnemonic = subject.readingMnemonic {
                    mnemonicSection(title: "Reading Mnemonic", text: mnemonic, hint: subject.readingHint)
                }
                if !subject.contextSentences.isEmpty {
                    contextSentencesSection
                }
                if !enrichedDetail.pitchPatterns.isEmpty {
                    pitchAccentSection
                }
                if let svg = enrichedDetail.strokeOrderSVG, subject.object == "kanji" {
                    strokeOrderSection(svg: svg)
                }
                if !subject.pronunciationAudios.isEmpty {
                    audioSection
                }
            }
            .padding(.top, 8)
        } label: {
            Text("Details")
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task {
            isLoadingEnrichment = true
            enrichedDetail = await enrichmentManager.enrich(subject: subject)
            isLoadingEnrichment = false
        }
    }

    // MARK: - Meanings

    private var meaningsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Meanings")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(subject.meanings, id: \.meaning) { meaning in
                HStack(spacing: 4) {
                    Text(meaning.meaning)
                        .font(meaning.primary ? .body.weight(.semibold) : .body)
                    if meaning.primary {
                        Text("Primary")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            if !subject.auxiliaryMeanings.isEmpty {
                // AuxiliaryMeaning uses `type` ("whitelist" = accepted, "blacklist" = rejected)
                let accepted = subject.auxiliaryMeanings.filter { $0.type == "whitelist" }
                if !accepted.isEmpty {
                    Text("Also: " + accepted.map { $0.meaning }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Readings

    private var readingsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Readings")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(subject.readings, id: \.reading) { reading in
                HStack(spacing: 6) {
                    Text(reading.reading)
                        .font(reading.primary ? .body.weight(.semibold) : .body)
                    if let type = reading.type {
                        Text(type)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Mnemonics

    private func mnemonicSection(title: String, text: String, hint: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
            if let hint = hint {
                DisclosureGroup("Show hint") {
                    Text(hint)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Context Sentences

    private var contextSentencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Context Sentences")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(subject.contextSentences.prefix(3), id: \.ja) { sentence in
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

    // MARK: - Pitch Accent

    private var pitchAccentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pitch Accent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if isLoadingEnrichment {
                Text("Loading…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(enrichedDetail.pitchPatterns, id: \.pattern) { pattern in
                    Text(pattern.pattern)
                        .font(.body.monospaced())
                }
            }
        }
    }

    // MARK: - Stroke Order

    private func strokeOrderSection(svg: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stroke Order")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            SVGWebView(svgString: svg)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pronunciation")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(subject.pronunciationAudios, id: \.url) { audio in
                if let url = URL(string: audio.url) {
                    Button {
                        audioService.toggle(url: url)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: audioService.isPlaying && audioService.currentURL == url
                                  ? "stop.circle.fill"
                                  : "play.circle.fill")
                            // AudioMetadata uses `voiceActorName`, not `voice`
                            Text(audio.metadata?.voiceActorName ?? "Audio")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .tint(.accentColor)
                }
            }
        }
    }
}

// MARK: - SVG Web View

private struct SVGWebView: UIViewRepresentable {
    let svgString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <html><body style="margin:0;padding:0;background:transparent;">
        \(svgString)
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
