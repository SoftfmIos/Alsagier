import Foundation
import CoreLocation
@MainActor final class PrayerManager:NSObject,ObservableObject,CLLocationManagerDelegate {
 let lm=CLLocationManager();@Published var blocks:[ScheduleBlock]=[]
 override init(){super.init();lm.delegate=self}
 func request(){lm.requestWhenInUseAuthorization();lm.requestLocation()}
 func locationManager(_ manager:CLLocationManager,didFailWithError error:Error){}
 func locationManagerDidChangeAuthorization(_ manager:CLLocationManager){if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways{manager.requestLocation()}}
 func locationManager(_ manager:CLLocationManager,didUpdateLocations locations:[CLLocation]){guard let l=locations.last else{return};Task{await fetch(l.coordinate.latitude,l.coordinate.longitude)}}
 struct R:Decodable{struct D:Decodable{struct T:Decodable{let Fajr,Dhuhr,Asr,Maghrib,Isha:String};let timings:T};let data:D}
 func fetch(_ lat:Double,_ lon:Double) async {var u=URLComponents(string:"https://api.aladhan.com/v1/timings")!;u.queryItems=[.init(name:"latitude",value:"\(lat)"),.init(name:"longitude",value:"\(lon)"),.init(name:"method",value:"4")];guard let (d,_)=try? await URLSession.shared.data(from:u.url!),let r=try? JSONDecoder().decode(R.self,from:d) else{return};let t=r.data.timings;blocks=[("Fajr",t.Fajr),("Dhuhr",t.Dhuhr),("Asr",t.Asr),("Maghrib",t.Maghrib),("Isha",t.Isha)].compactMap{n,v in guard let s=v.split(separator:" ").first,let date=parse(String(s)) else{return nil};return ScheduleBlock(title:"\(n) Prayer",start:date.addingTimeInterval(-600),end:date.addingTimeInterval(1200),kind:.prayer,projectID:nil,sourceID:nil,locked:true)}}
 func parse(_ s:String)->Date?{let p=s.split(separator:":").compactMap{Int($0)};guard p.count>1 else{return nil};return Calendar.current.date(bySettingHour:p[0],minute:p[1],second:0,of:Date())}
}