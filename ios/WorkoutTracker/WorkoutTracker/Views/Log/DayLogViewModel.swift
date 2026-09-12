import Foundation

@MainActor
final class DayLogViewModel: ObservableObject {
    @Published var date = Date() {
        didSet { Task { await load() } }
    }
    @Published private(set) var groups: [ExerciseGroup] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter
    }()

    var dateKey: String { Self.dateFormatter.string(from: date) }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let entries = try await APIClient.shared.fetchDayLog(date: dateKey)
            groups = Self.group(entries)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addSet(exercise: Exercise, reps: Int?, weight: Double?, notes: String?) async {
        let nextSetNumber = (groups.first { $0.exerciseId == exercise.id }?.entries.count ?? 0) + 1
        do {
            _ = try await APIClient.shared.logSet(
                exerciseId: exercise.id, date: dateKey, setNumber: nextSetNumber,
                reps: reps, weight: weight, notes: notes
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEntry(_ entry: WorkoutEntry) async {
        do {
            try await APIClient.shared.deleteEntry(id: entry.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func group(_ entries: [WorkoutEntry]) -> [ExerciseGroup] {
        let byExercise = Dictionary(grouping: entries, by: \.exerciseId)
        return byExercise.map { exerciseId, entries in
            ExerciseGroup(
                exerciseId: exerciseId,
                exerciseName: entries.first?.exerciseName ?? "Exercise",
                entries: entries.sorted { $0.setNumber < $1.setNumber }
            )
        }
        .sorted { $0.exerciseName.localizedCaseInsensitiveCompare($1.exerciseName) == .orderedAscending }
    }
}
