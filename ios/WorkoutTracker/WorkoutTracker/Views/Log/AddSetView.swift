import SwiftUI

struct AddSetView: View {
    @ObservedObject var viewModel: DayLogViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var exercises: [Exercise] = []
    @State private var selectedExercise: Exercise?
    @State private var reps = ""
    @State private var weight = ""
    @State private var notes = ""
    @State private var isLoadingExercises = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    if isLoadingExercises {
                        ProgressView()
                    } else if exercises.isEmpty {
                        Text("Add an exercise on the Exercises tab first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Exercise", selection: $selectedExercise) {
                            Text("Select…").tag(Exercise?.none)
                            ForEach(exercises) { exercise in
                                Text(exercise.name).tag(Exercise?.some(exercise))
                            }
                        }
                    }
                }

                Section("Set details") {
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                    TextField("Weight (lb)", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Notes (optional)", text: $notes)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Log a Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(selectedExercise == nil)
                    }
                }
            }
            .task { await loadExercises() }
        }
    }

    private func loadExercises() async {
        isLoadingExercises = true
        do {
            exercises = try await APIClient.shared.fetchExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingExercises = false
    }

    private func save() async {
        guard let exercise = selectedExercise else { return }
        isSaving = true
        await viewModel.addSet(
            exercise: exercise,
            reps: Int(reps),
            weight: Double(weight),
            notes: notes.isEmpty ? nil : notes
        )
        isSaving = false
        dismiss()
    }
}

#Preview {
    AddSetView(viewModel: DayLogViewModel())
}
