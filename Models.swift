import Foundation
import SwiftUI
enum ProjectColor:String,Codable,CaseIterable,Identifiable { case blue,green,orange,purple,pink,teal,indigo,red; var id:String{rawValue}; var color:Color { switch self {case .blue:return .blue;case .green:return .green;case .orange:return .orange;case .purple:return .purple;case .pink:return .pink;case .teal:return .teal;case .indigo:return .indigo;case .red:return .red} } }
struct Project:Identifiable,Codable { var id=UUID(); var name:String; var dailyMinutes:Int; var color:ProjectColor; var isClosed=false }
enum TaskPriority:String,Codable,CaseIterable,Identifiable { case high="High",medium="Medium",low="Low"; var id:String{rawValue}; var weight:Int{self == .high ? 3 : self == .medium ? 2 : 1} }
struct ExecutiveTask:Identifiable,Codable { var id=UUID(); var title:String; var durationMinutes:Int; var projectID:UUID?; var priority:TaskPriority; var isCompleted=false; var createdAt=Date() }
struct Habit:Identifiable,Codable { var id=UUID(); var name:String; var durationMinutes:Int; var weekdays:Set<Int> }
enum VaultKind:String,Codable,CaseIterable,Identifiable { case call="Call",email="Email"; var id:String{rawValue} }
struct VaultItem:Identifiable,Codable { var id=UUID(); var title:String; var kind:VaultKind; var durationMinutes=15; var isCompleted=false }
enum BlockKind:String,Codable { case calendar,prayer,task,habit,call,email }
struct ScheduleBlock:Identifiable,Codable { var id=UUID();var title:String;var start:Date;var end:Date;var kind:BlockKind;var projectID:UUID?;var sourceID:UUID?;var locked:Bool }
