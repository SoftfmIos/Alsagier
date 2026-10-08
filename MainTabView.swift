import SwiftUI

struct MainTabView: View {
    @State private var selection = 0

    private struct TabStyle {
        let title: String
        let symbol: String
        let color: Color
    }

    private let tabs: [TabStyle] = [
        TabStyle(title: "Today", symbol: "clock", color: Color(red: 37/255, green: 99/255, blue: 166/255)),
        TabStyle(title: "Projects", symbol: "square.3.layers.3d", color: Color(red: 13/255, green: 148/255, blue: 136/255)),
        TabStyle(title: "Tasks", symbol: "checkmark", color: Color(red: 210/255, green: 138/255, blue: 40/255)),
        TabStyle(title: "Habits", symbol: "repeat", color: Color(red: 139/255, green: 92/255, blue: 183/255)),
        TabStyle(title: "More", symbol: "square.grid.2x2", color: Color(red: 100/255, green: 116/255, blue: 139/255))
    ]

    var body: some View {
        TabView(selection: $selection) {
            TodayView().tag(0)
            ProjectsView().tag(1)
            TasksView().tag(2)
            HabitsView().tag(3)
            MoreView().tag(4)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 2) {
                ForEach(tabs.indices, id: \.self) { index in
                    let tab = tabs[index]
                    let isSelected = selection == index
                    Button {
                        selection = index
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? tab.color.opacity(0.13) : Color.clear)
                                    .frame(width: 52, height: 35)
                                if index == 2 {
                                    // Two distinct checks, rather than the old single check-in-circle.
                                    HStack(spacing: -5) {
                                        Image(systemName: "checkmark")
                                        Image(systemName: "checkmark")
                                    }
                                    .font(.system(size: 17, weight: .semibold))
                                } else {
                                    Image(systemName: tab.symbol)
                                        .font(.system(size: 20, weight: .medium))
                                }
                            }
                            Text(LocalizedStringKey(tab.title))
                                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(isSelected ? tab.color : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(LocalizedStringKey(tab.title)))
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 5)
            .background(.regularMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
    }
}
