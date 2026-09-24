import Foundation
@MainActor final class AppStore:ObservableObject {
 @Published var projects:[Project]=[];@Published var tasks:[ExecutiveTask]=[];@Published var habits:[Habit]=[];@Published var vault:[VaultItem]=[];@Published var schedule:[ScheduleBlock]=[]
 private let key="alsagier.v4.state"
 private struct State:Codable{var projects:[Project];var tasks:[ExecutiveTask];var habits:[Habit];var vault:[VaultItem];var schedule:[ScheduleBlock]}
 init(){load()}
 func save(){if let d=try? JSONEncoder().encode(State(projects:projects,tasks:tasks,habits:habits,vault:vault,schedule:schedule)){UserDefaults.standard.set(d,forKey:key)}}
 func load(){guard let d=UserDefaults.standard.data(forKey:key),let s=try? JSONDecoder().decode(State.self,from:d) else{return};projects=s.projects;tasks=s.tasks;habits=s.habits;vault=s.vault;schedule=s.schedule}
 func addProject(_ n:String,_ m:Int,_ c:ProjectColor){projects.append(Project(name:n,dailyMinutes:m,color:c));save()}
 func toggleProject(_ p:Project){if let i=projects.firstIndex(where:{$0.id==p.id}){projects[i].isClosed.toggle();save()}}
 func deleteProject(_ p:Project){projects.removeAll{$0.id==p.id};save()}
 func addTask(_ t:String,_ d:Int,_ p:UUID?,_ q:TaskPriority){tasks.append(ExecutiveTask(title:t,durationMinutes:d,projectID:p,priority:q));save()}
 func completeTask(_ t:ExecutiveTask){if let i=tasks.firstIndex(where:{$0.id==t.id}){tasks[i].isCompleted.toggle();save()}}
 func deleteTask(_ t:ExecutiveTask){tasks.removeAll{$0.id==t.id};save()}
 func addHabit(_ n:String,_ d:Int,_ w:Set<Int>){habits.append(Habit(name:n,durationMinutes:d,weekdays:w));save()}
 func deleteHabit(_ h:Habit){habits.removeAll{$0.id==h.id};save()}
 func addVault(_ t:String,_ k:VaultKind){vault.append(VaultItem(title:t,kind:k));save()}
 func completeVault(_ v:VaultItem){if let i=vault.firstIndex(where:{$0.id==v.id}){vault[i].isCompleted.toggle();save()}}
 func deleteVault(_ v:VaultItem){vault.removeAll{$0.id==v.id};save()}
 func generateDay(calendarBlocks:[ScheduleBlock],prayerBlocks:[ScheduleBlock]){
  let now=Date(),end=Calendar.current.date(bySettingHour:23,minute:59,second:59,of:now)!;var result=(calendarBlocks+prayerBlocks).filter{$0.end>now}.sorted{$0.start<$1.start};var cursor=now.addingTimeInterval(600)
  func free(_ proposed:Date,_ mins:Int)->Date?{var s=proposed;let dur=TimeInterval(mins*60);while s.addingTimeInterval(dur)<=end{if let x=result.first(where:{s<$0.end && s.addingTimeInterval(dur)>$0.start}){s=x.end}else{return s}};return nil}
  let wd=Calendar.current.component(.weekday,from:now)
  for h in habits where h.weekdays.contains(wd){if let s=free(cursor,h.durationMinutes){let b=ScheduleBlock(title:h.name,start:s,end:s.addingTimeInterval(Double(h.durationMinutes*60)),kind:.habit,projectID:nil,sourceID:h.id,locked:false);result.append(b);cursor=b.end}}
  var used:[UUID:Int]=[:]
  for t in tasks.filter({!$0.isCompleted}).sorted(by:{$0.priority.weight > $1.priority.weight}){
   if let pid=t.projectID,let p=projects.first(where:{$0.id==pid && !$0.isClosed}),used[pid,default:0]+t.durationMinutes>p.dailyMinutes{continue}
   if let s=free(cursor,t.durationMinutes){let b=ScheduleBlock(title:t.title,start:s,end:s.addingTimeInterval(Double(t.durationMinutes*60)),kind:.task,projectID:t.projectID,sourceID:t.id,locked:false);result.append(b);cursor=b.end;if let pid=t.projectID{used[pid,default:0]+=t.durationMinutes}}
  }
  for v in vault where !v.isCompleted {if let s=free(cursor,v.durationMinutes){let b=ScheduleBlock(title:v.title,start:s,end:s.addingTimeInterval(Double(v.durationMinutes*60)),kind:v.kind == .call ? .call:.email,projectID:nil,sourceID:v.id,locked:false);result.append(b);cursor=b.end}}
  schedule=result.sorted{$0.start<$1.start};save()
 }
 func late15(){let now=Date();var r=schedule.filter{$0.locked || $0.start<=now};let moving=schedule.filter{!$0.locked && $0.start>now}.sorted{$0.start<$1.start};var cursor=now.addingTimeInterval(900);for old in moving{let d=old.end.timeIntervalSince(old.start);var s=max(cursor,old.start.addingTimeInterval(900));while let x=r.first(where:{s<$0.end && s.addingTimeInterval(d)>$0.start}){s=x.end};var b=old;b.start=s;b.end=s.addingTimeInterval(d);r.append(b);cursor=b.end};schedule=r.sorted{$0.start<$1.start};save()}
}