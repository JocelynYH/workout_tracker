import Foundation

struct User: Codable, Equatable {
    let id: Int
    let email: String
    let displayName: String?
}

struct Exercise: Codable, Equatable, Identifiable, Hashable {
    let id: Int
    var name: String
    var category: String?
    let createdAt: String?
}

struct WorkoutEntry: Codable, Equatable, Identifiable {
    let id: Int
    let exerciseId: Int
    let exerciseName: String
    let exerciseCategory: String?
    let date: String
    var setNumber: Int
    var reps: Int?
    var weight: Double?
    var notes: String?
    let createdAt: String?
}

/// Sets for a single exercise, grouped for display on the day log screen.
struct ExerciseGroup: Identifiable {
    var id: Int { exerciseId }
    let exerciseId: Int
    let exerciseName: String
    var entries: [WorkoutEntry]
}
