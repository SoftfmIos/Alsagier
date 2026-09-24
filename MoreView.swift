import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var calendar: CalendarManager
    @EnvironmentObject private var notifications: NotificationManager

    @State private var title = ""
    @State private var kind = VaultKind.call
    @State private var duration = 15

    var body: some View {
        NavigationStack {
            List {
                Section("Calls & Email Vault") {
                    TextField("Item", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(VaultKind.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Duration", selection: $duration) {
                        ForEach([15, 30, 45, 60], id: \.self) { value in
                            Text("\(value) minutes").tag(value)
                        }
                    }
                    Button("Add to Vault") {
                        store.addVault(title: title, kind: kind, duration: duration)
                        title = ""
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    ForEach(store.vault) { item in
                        HStack {
                            Image(systemName: item.kind == .call ? "phone.fill" : "envelope.fill")
                                .foregroundStyle(item.kind == .call ? Color.purple : Color.teal)
                            Text(item.title).strikethrough(item.isCompleted)
                            Spacer()
                            Button { store.toggleVault(item) } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            }
                            .buttonStyle(.borderless)
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) { store.deleteVault(item) }
                        }
                    }
                }

                Section("Permissions") {
                    Label(calendar.authorized ? "Calendar connected" : "Calendar permission needed", systemImage: "calendar")
                    Label(notifications.authorized ? "Notifications enabled" : "Notifications permission needed", systemImage: "bell")
                }

                Section("About") {
                    Text("Alsagier By Softfm")
                    Text("V4.3")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("More")
        }
    }
}
