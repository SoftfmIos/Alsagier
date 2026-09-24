import SwiftUI

struct MoreView:View {
    @EnvironmentObject private var store:AppStore
    @EnvironmentObject private var calendar:CalendarManager
    @EnvironmentObject private var notifications:NotificationManager
    @State private var draft=AppSettings()

    var body:some View {
        NavigationStack {
            Form {
                Section("Day boundaries") {
                    Picker("Work ends",selection:$draft.workEndHour){ForEach(12...22,id:\.self){Text(time($0)).tag($0)}}
                    Picker("Personal planning until",selection:$draft.personalEndHour){ForEach(17...23,id:\.self){Text(time($0)).tag($0)}}
                }
                Section("Communication") {
                    Picker("Calls",selection:$draft.callsMinutes){ForEach([0,15,30,45,60],id:\.self){Text($0==0 ? "Off":"\($0) min").tag($0)}}
                    Picker("Email",selection:$draft.emailMinutes){ForEach([0,15,30,45,60],id:\.self){Text($0==0 ? "Off":"\($0) min").tag($0)}}
                }
                Section("Notifications") {
                    Picker("Before each block",selection:$draft.reminderMinutes){
                        Text("Off").tag(0); ForEach([2,5,10,15],id:\.self){Text("\($0) min").tag($0)}
                    }
                }
                Section("Permissions") {
                    Label(calendar.authorized ? "Calendar connected":"Calendar permission needed",systemImage:"calendar")
                    Label(notifications.authorized ? "Notifications enabled":"Notifications permission needed",systemImage:"bell")
                }
                Section("About") { Text("Alsagier By Softfm"); Text("Version 5.0").foregroundStyle(.secondary) }
            }.navigationTitle("More")
            .onAppear{draft=store.settings}
            .onChange(of:draft){_,new in store.updateSettings(new)}
        }
    }
    private func time(_ hour:Int)->String {
        let h=hour>12 ? hour-12:hour
        return "\(h):00 \(hour>=12 ? "PM":"AM")"
    }
}
