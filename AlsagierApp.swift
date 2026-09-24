import SwiftUI
@main struct AlsagierApp: App {
 @StateObject var store=AppStore(); @StateObject var cal=CalendarManager(); @StateObject var notes=NotificationManager()
 var body: some Scene { WindowGroup { MainTabView().environmentObject(store).environmentObject(cal).environmentObject(notes).task { await cal.requestAccessAndLoad(); await notes.requestAuthorization() } } }
}