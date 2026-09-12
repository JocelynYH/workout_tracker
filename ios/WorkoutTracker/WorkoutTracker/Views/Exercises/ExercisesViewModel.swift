import Foundation

@MainActor
final class ExercisesViewModel: ObservableObject {
    @Published private(set) var exercises: [Exercise] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            exercises = try await APIClient.shared.fetchExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addExercise(name: String, category: String?) async {
        do {
            _ = try await APIClient.shared.createExercise(name: name, category: category)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        for index in offsets {
            do {
                try await APIClient.shared.deleteExercise(id: exercises[index].id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        await load()
    }
}
