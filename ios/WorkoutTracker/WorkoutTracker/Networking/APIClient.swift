import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case server(String)
    case decoding
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The API base URL in Settings is invalid."
        case .server(let message): return message
        case .decoding: return "Received an unexpected response from the server."
        case .unauthorized: return "Your session expired. Please log in again."
        }
    }
}

/// Thin REST client for the Workout Tracker backend. Reads the current auth
/// token from Keychain on every request so it always reflects the signed-in user.
struct APIClient {
    static let shared = APIClient()

    private func url(_ path: String) throws -> URL {
        guard let url = URL(string: AppConfig.apiBaseURL + path) else {
            throw APIError.invalidURL
        }
        return url
    }

    private func send<Response: Decodable>(
        _ method: String,
        _ path: String,
        body: Encodable? = nil,
        authorized: Bool = true
    ) async throws -> Response {
        var request = URLRequest(url: try url(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authorized {
            guard let token = KeychainStore.loadToken() else { throw APIError.unauthorized }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }

        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorPayload.self, from: data))?.error
                ?? "Request failed with status \(http.statusCode)"
            throw APIError.server(message)
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    // MARK: - Auth

    func register(email: String, password: String, displayName: String?) async throws -> AuthResponse {
        try await send(
            "POST", "/auth/register",
            body: RegisterRequest(email: email, password: password, displayName: displayName),
            authorized: false
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await send(
            "POST", "/auth/login",
            body: LoginRequest(email: email, password: password),
            authorized: false
        )
    }

    func me() async throws -> MeResponse {
        try await send("GET", "/auth/me")
    }

    // MARK: - Exercises

    func fetchExercises() async throws -> [Exercise] {
        let response: ExercisesResponse = try await send("GET", "/exercises")
        return response.exercises
    }

    func createExercise(name: String, category: String?) async throws -> Exercise {
        let response: ExerciseResponse = try await send(
            "POST", "/exercises", body: ExerciseRequest(name: name, category: category)
        )
        return response.exercise
    }

    func deleteExercise(id: Int) async throws {
        let _: EmptyResponse = try await send("DELETE", "/exercises/\(id)")
    }

    // MARK: - Workouts

    func fetchDayLog(date: String) async throws -> [WorkoutEntry] {
        let response: EntriesResponse = try await send("GET", "/workouts?date=\(date)")
        return response.entries
    }

    func fetchHistory(exerciseId: Int) async throws -> [WorkoutEntry] {
        let response: EntriesResponse = try await send("GET", "/workouts/history?exerciseId=\(exerciseId)")
        return response.entries
    }

    func logSet(
        exerciseId: Int, date: String, setNumber: Int, reps: Int?, weight: Double?, notes: String?
    ) async throws -> WorkoutEntry {
        let response: EntryResponse = try await send(
            "POST", "/workouts",
            body: LogSetRequest(
                exerciseId: exerciseId, date: date, setNumber: setNumber,
                reps: reps, weight: weight, notes: notes
            )
        )
        return response.entry
    }

    func deleteEntry(id: Int) async throws {
        let _: EmptyResponse = try await send("DELETE", "/workouts/\(id)")
    }
}

// MARK: - Request/response payloads

private struct RegisterRequest: Encodable { let email: String; let password: String; let displayName: String? }
private struct LoginRequest: Encodable { let email: String; let password: String }
private struct ExerciseRequest: Encodable { let name: String; let category: String? }
private struct LogSetRequest: Encodable {
    let exerciseId: Int; let date: String; let setNumber: Int
    let reps: Int?; let weight: Double?; let notes: String?
}

struct AuthResponse: Decodable { let token: String; let user: User }
struct MeResponse: Decodable { let user: User }
struct ExercisesResponse: Decodable { let exercises: [Exercise] }
struct ExerciseResponse: Decodable { let exercise: Exercise }
struct EntriesResponse: Decodable { let entries: [WorkoutEntry] }
struct EntryResponse: Decodable { let entry: WorkoutEntry }
struct ErrorPayload: Decodable { let error: String }
struct EmptyResponse: Decodable {}

/// Type-erasing wrapper so `send` can accept any Encodable body.
private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { self.encodeClosure = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeClosure(encoder) }
}
