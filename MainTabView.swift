import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "rectangle.split.1x2.fill") }
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "square.stack.3d.up.fill") }
            TasksView()
                .tabItem { Label("Tasks", systemImage: "checkmark.circle.fill") }
            HabitsView()
                .tabItem { Label("Habits", systemImage: "repeat") }
            MoreView()
                .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
        }
    }
}
