import SwiftUI

struct TodayLogView: View {
    @StateObject private var viewModel = DayLogViewModel()
    @State private var showAddSet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.groups.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No sets logged",
                        systemImage: "checklist",
                        description: Text("Tap + to log the first exercise for this day.")
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.groups) { group in
                            Section(group.exerciseName) {
                                ForEach(group.entries) { entry in
                                    SetRow(entry: entry)
                                }
                                .onDelete { offsets in
                                    Task {
                                        for index in offsets {
                                            await viewModel.deleteEntry(group.entries[index])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red).padding()
                }
            }
            .navigationTitle("Today's Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSet = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddSet) {
                AddSetView(viewModel: viewModel)
            }
            .task { await viewModel.load() }
        }
    }
}

private struct SetRow: View {
    let entry: WorkoutEntry

    var body: some View {
        HStack {
            Text("Set \(entry.setNumber)")
                .font(.subheadline.weight(.medium))
                .frame(width: 60, alignment: .leading)

            if let reps = entry.reps {
                Text("\(reps) reps")
            }
            if let weight = entry.weight {
                Text("\(weight.formattedTrimmed) lb")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let notes = entry.notes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .foregroundStyle(.secondary)
                    .help(notes)
            }
        }
    }
}

extension Double {
    var formattedTrimmed: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

#Preview {
    TodayLogView()
}
