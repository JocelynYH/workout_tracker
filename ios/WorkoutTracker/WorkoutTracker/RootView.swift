import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isCheckingSession {
                ProgressView()
            } else if authManager.isSignedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayLogView()
                .tabItem { Label("Today", systemImage: "checklist") }

            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "dumbbell") }

            HistoryView()
                .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
