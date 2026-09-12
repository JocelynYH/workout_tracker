import SwiftUI

struct ExercisesView: View {
    @StateObject private var viewModel = ExercisesViewModel()
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.exercises.isEmpty {
                    ProgressView()
                } else if viewModel.exercises.isEmpty {
                    ContentUnavailableView(
                        "No exercises yet",
                        systemImage: "dumbbell",
                        description: Text("Add the exercises from your workout book with the + button.")
                    )
                } else {
                    List {
                        ForEach(viewModel.exercises) { exercise in
                            VStack(alignment: .leading) {
                                Text(exercise.name).font(.body)
                                if let category = exercise.category, !category.isEmpty {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            Task { await viewModel.delete(at: offsets) }
                        }
                    }
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddExerciseView(viewModel: viewModel)
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }
}

private struct AddExerciseView: View {
    @ObservedObject var viewModel: ExercisesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name)
                TextField("Category (optional)", text: $category)
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addExercise(
                                name: name, category: category.isEmpty ? nil : category
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ExercisesView()
}
