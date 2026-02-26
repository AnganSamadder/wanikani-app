import Foundation

@MainActor
public final class SubjectRepository: SubjectRepositoryProtocol {
    private enum Constants {
        static let fetchChunkSize = 100
    }

    private let persistenceManager: PersistenceManager
    private let api: WaniKaniAPI?
    
    public init(persistenceManager: PersistenceManager, api: WaniKaniAPI? = nil) {
        self.persistenceManager = persistenceManager
        self.api = api
    }
    
    public func fetchSubject(id: Int) async throws -> SubjectSnapshot? {
        if let local = persistenceManager.fetchSubjectSnapshot(id: id) {
            if shouldRefreshDetail(for: local) {
                try? await fetchAndPersist(subjectIDs: [id])
                return persistenceManager.fetchSubjectSnapshot(id: id) ?? local
            }
            return local
        }

        try await fetchAndPersist(subjectIDs: [id])
        return persistenceManager.fetchSubjectSnapshot(id: id)
    }

    public func fetchSubjects(ids: [Int]) async throws -> [SubjectSnapshot] {
        guard !ids.isEmpty else { return [] }
        let orderedIDs = uniqueInOrder(ids)

        var byID = Dictionary(
            uniqueKeysWithValues: persistenceManager.fetchSubjectSnapshots(ids: orderedIDs).map { ($0.id, $0) }
        )
        let missingIDs = orderedIDs.filter { byID[$0] == nil }
        let staleIDs = orderedIDs.filter {
            guard let snapshot = byID[$0] else { return false }
            return shouldRefreshDetail(for: snapshot)
        }
        let idsToFetch = uniqueInOrder(missingIDs + staleIDs)

        if !idsToFetch.isEmpty {
            for chunk in chunked(idsToFetch, size: Constants.fetchChunkSize) {
                try await fetchAndPersist(subjectIDs: chunk)
            }

            for snapshot in persistenceManager.fetchSubjectSnapshots(ids: idsToFetch) {
                byID[snapshot.id] = snapshot
            }
        }

        return orderedIDs.compactMap { byID[$0] }
    }

    private func uniqueInOrder(_ ids: [Int]) -> [Int] {
        var seen: Set<Int> = []
        var ordered: [Int] = []
        ordered.reserveCapacity(ids.count)
        for id in ids where seen.insert(id).inserted {
            ordered.append(id)
        }
        return ordered
    }

    private func chunked(_ ids: [Int], size: Int) -> [[Int]] {
        guard size > 0, !ids.isEmpty else { return [] }

        var chunks: [[Int]] = []
        chunks.reserveCapacity((ids.count + size - 1) / size)

        var index = 0
        while index < ids.count {
            let endIndex = min(index + size, ids.count)
            chunks.append(Array(ids[index..<endIndex]))
            index = endIndex
        }
        return chunks
    }

    private func fetchAndPersist(subjectIDs: [Int]) async throws {
        guard let api, !subjectIDs.isEmpty else { return }
        let fetched = try await api.getAllSubjects(subjectIDs: subjectIDs)
        guard !fetched.isEmpty else { return }
        persistenceManager.saveSubjects(fetched)
    }

    private func shouldRefreshDetail(for subject: SubjectSnapshot) -> Bool {
        // Older cached snapshots may exist without newly-added relation/detail fields.
        // Refresh those subjects on-demand so the review details panel can render parity sections.
        switch subject.object {
        case "kanji":
            let hasCoreRelations = !subject.componentSubjectIDs.isEmpty || !subject.amalgamationSubjectIDs.isEmpty
            let hasSimilarity = !subject.visuallySimilarSubjectIDs.isEmpty
            let hasMnemonic = !(subject.meaningMnemonic?.isEmpty ?? true) || !(subject.readingMnemonic?.isEmpty ?? true)
            return !hasCoreRelations && !hasSimilarity && !hasMnemonic
        case "vocabulary", "kana_vocabulary":
            let hasComposition = !subject.componentSubjectIDs.isEmpty
            let hasContext = !subject.contextSentences.isEmpty
            let hasPOS = !subject.partsOfSpeech.isEmpty
            return !hasComposition && !hasContext && !hasPOS
        default:
            return false
        }
    }
}
