import Foundation
import EventKit
@MainActor final class CalendarManager:ObservableObject {
 let store=EKEventStore();@Published var authorized=false;@Published var todayBlocks:[ScheduleBlock]=[]
 func requestAccessAndLoad() async {do{authorized=try await store.requestFullAccessToEvents();if authorized{loadToday()}}catch{authorized=false}}
 func loadToday(){let c=Calendar.current,s=c.startOfDay(for:Date()),e=c.date(byAdding:.day,value:1,to:s)!;todayBlocks=store.events(matching:store.predicateForEvents(withStart:s,end:e,calendars:nil)).filter{!$0.isAllDay}.map{ScheduleBlock(title:$0.title ?? "Calendar",start:$0.startDate,end:$0.endDate,kind:.calendar,projectID:nil,sourceID:nil,locked:true)}.sorted{$0.start<$1.start}}
}