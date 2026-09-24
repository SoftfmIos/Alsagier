import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder.fill") }
            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
            HabitsView()
                .tabItem { Label("Habits", systemImage: "repeat.circle.fill") }
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
    }
}
