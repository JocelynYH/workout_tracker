import SwiftUI

struct HistoryView: View {
    @State private var exercises: [Exercise] = []
    @State private var selectedExercise: Exercise?
    @State private var entries: [WorkoutEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "No exercises yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Add exercises on the Exercises tab to see history here.")
                    )
                } else {
                    Picker("Exercise", selection: $selectedExercise) {
                        Text("Select an exercise").tag(Exercise?.none)
                        ForEach(exercises) { exercise in
                            Text(exercise.name).tag(Exercise?.some(exercise))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()

                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if let errorMessage {
                        Spacer()
                        Text(errorMessage).foregroundStyle(.red)
                        Spacer()
                    } else if selectedExercise != nil && entries.isEmpty {
                        Spacer()
                        Text("No sets logged for this exercise yet.")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        List {
                            ForEach(groupedByDate, id: \.date) { day in
                                Section(day.date) {
                                    ForEach(day.entries) { entry in
                                        HStack {
                                            Text("Set \(entry.setNumber)")
                                                .frame(width: 60, alignment: .leading)
                                            if let reps = entry.reps { Text("\(reps) reps") }
                                            Spacer()
                                            if let weight = entry.weight {
                                                Text("\(weight.formattedTrimmed) lb")
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .task { await loadExercises() }
            .onChange(of: selectedExercise) { _, newValue in
                Task { await loadHistory(for: newValue) }
            }
        }
    }

    private var groupedByDate: [(date: String, entries: [WorkoutEntry])] {
        let grouped = Dictionary(grouping: entries, by: \.date)
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, entries: $0.value.sorted { $0.setNumber < $1.setNumber }) }
    }

    private func loadExercises() async {
        do {
            exercises = try await APIClient.shared.fetchExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadHistory(for exercise: Exercise?) async {
        guard let exercise else {
            entries = []
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            entries = try await APIClient.shared.fetchHistory(exerciseId: exercise.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    HistoryView()
}
