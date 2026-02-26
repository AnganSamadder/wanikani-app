import Foundation
import WaniKaniCore

@MainActor
final class SubjectDetailsViewModel: ObservableObject {
    @Published private(set) var subject: SubjectSnapshot
    @Published private(set) var relatedComponents: [SubjectSnapshot] = []
    @Published private(set) var relatedAmalgamations: [SubjectSnapshot] = []
    @Published private(set) var visuallySimilar: [SubjectSnapshot] = []
    @Published private(set) var studyMaterial: StudyMaterialSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false

    private unowned let reviewViewModel: ReviewSessionViewModel

    init(subject: SubjectSnapshot, reviewViewModel: ReviewSessionViewModel) {
        self.subject = subject
        self.reviewViewModel = reviewViewModel
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        if let refreshed = await reviewViewModel.fetchSubjectDetail(id: subject.id) {
            subject = refreshed
        }

        async let componentsTask = reviewViewModel.fetchRelatedSubjects(ids: subject.componentSubjectIDs)
        async let amalgamationsTask = reviewViewModel.fetchRelatedSubjects(ids: subject.amalgamationSubjectIDs)
        async let similarTask = reviewViewModel.fetchRelatedSubjects(ids: subject.visuallySimilarSubjectIDs)
        async let studyTask = reviewViewModel.fetchStudyMaterial(subjectID: subject.id)

        relatedComponents = await componentsTask
        relatedAmalgamations = await amalgamationsTask
        visuallySimilar = await similarTask
        studyMaterial = await studyTask
    }

    func saveStudyMaterial(
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String]
    ) async {
        let previous = studyMaterial
        studyMaterial = StudyMaterialSnapshot(
            subjectID: subject.id,
            meaningNote: meaningNote,
            readingNote: readingNote,
            meaningSynonyms: meaningSynonyms,
            updatedAt: Date()
        )
        isSaving = true
        defer { isSaving = false }

        let result = await reviewViewModel.saveStudyMaterial(
            subjectID: subject.id,
            meaningNote: meaningNote,
            readingNote: readingNote,
            meaningSynonyms: meaningSynonyms
        )
        studyMaterial = result ?? previous
    }
}
