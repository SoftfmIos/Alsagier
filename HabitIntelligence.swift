import Foundation

struct HabitProfile {
    let key: String
    let icon: String
    let defaultMinutes: Int
    let tracksWalking: Bool
    let progressBased: Bool
}

enum HabitIntelligence {
    private struct Rule { let key:String; let icon:String; let minutes:Int; let walking:Bool; let progress:Bool; let terms:[String] }
    // Specific activities are intentionally ordered before broad concepts such as workout, sea, reading and sleep.
    private static let rules:[Rule] = [
        .init(key:"quran",icon:"book.closed.fill",minutes:20,walking:false,progress:true,terms:["quran","qur'an","قران","القران","قرآن","القرآن","ورد القران","ورد القرآن"]),
        .init(key:"racket",icon:"tennis.racket",minutes:60,walking:false,progress:false,terms:["tennis","padel","paddle","squash","تنس","بادل","سكواش"]),
        .init(key:"football",icon:"soccerball",minutes:60,walking:false,progress:false,terms:["football","soccer","كرة قدم","كره قدم","كورة","كوره"]),
        .init(key:"basketball",icon:"basketball.fill",minutes:60,walking:false,progress:false,terms:["basketball","كرة سلة","كره سله","سلة","سله"]),
        .init(key:"volleyball",icon:"volleyball.fill",minutes:60,walking:false,progress:false,terms:["volleyball","كرة طائرة","كره طايره"]),
        .init(key:"golf",icon:"figure.golf",minutes:90,walking:false,progress:false,terms:["golf","جولف","قولف"]),
        .init(key:"bowling",icon:"figure.bowling",minutes:60,walking:false,progress:false,terms:["bowling","بولينج","بولنق"]),
        .init(key:"horse",icon:"figure.equestrian.sports",minutes:60,walking:false,progress:false,terms:["horse","riding","equestrian","خيل","فروسية","فروسيه","ركوب الخيل"]),
        .init(key:"fishing",icon:"fish.fill",minutes:120,walking:false,progress:false,terms:["fishing","صيد سمك","صيد","سنارة","سناره"]),
        .init(key:"jetski",icon:"water.waves",minutes:60,walking:false,progress:false,terms:["jet ski","jetski","جت سكي","دباب بحري"]),
        .init(key:"diving",icon:"figure.open.water.swim",minutes:90,walking:false,progress:false,terms:["scuba","diving","غوص","دايفنق"]),
        .init(key:"snorkel",icon:"figure.open.water.swim",minutes:60,walking:false,progress:false,terms:["snorkel","snorkeling","سنوركل","غوص سطحي"]),
        .init(key:"surf",icon:"figure.surfing",minutes:60,walking:false,progress:false,terms:["surf","surfing","سيرف","ركوب الامواج","ركوب الأمواج"]),
        .init(key:"waterski",icon:"figure.water.fitness",minutes:60,walking:false,progress:false,terms:["water ski","wakeboard","تزلج مائي","ويك بورد"]),
        .init(key:"kayak",icon:"figure.rower",minutes:60,walking:false,progress:false,terms:["kayak","canoe","rowing","كاياك","كانو","تجديف"]),
        .init(key:"boat",icon:"sailboat.fill",minutes:120,walking:false,progress:false,terms:["boat","yacht","sailing","قارب","يخت","ابحار","إبحار","طلعة بحر","طلعه بحر"]),
        .init(key:"swimming",icon:"figure.pool.swim",minutes:45,walking:false,progress:true,terms:["swim","swimming","سباحة","سباحه"]),
        .init(key:"running",icon:"figure.run",minutes:30,walking:false,progress:true,terms:["running","jogging","run","جري","ركض","هرولة","هروله"]),
        .init(key:"walking",icon:"figure.walk",minutes:45,walking:true,progress:true,terms:["walking","walk","steps","step","مشي","المشي","خطوات","خطوة","خطوه"]),
        .init(key:"cycling",icon:"bicycle",minutes:45,walking:false,progress:true,terms:["cycling","bicycle","bike","دراجة","دراجه","سيكل"]),
        .init(key:"boxing",icon:"figure.boxing",minutes:45,walking:false,progress:false,terms:["boxing","ملاكمة","ملاكمه","بوكسنق"]),
        .init(key:"martial",icon:"figure.martial.arts",minutes:60,walking:false,progress:false,terms:["martial arts","karate","judo","كاراتيه","جودو","فنون قتالية","فنون قتاليه"]),
        .init(key:"yoga",icon:"figure.yoga",minutes:30,walking:false,progress:true,terms:["yoga","يوغا","يوجا"]),
        .init(key:"stretch",icon:"figure.flexibility",minutes:15,walking:false,progress:true,terms:["stretch","stretching","استطالة","استطاله","تمطيط"]),
        .init(key:"hiking",icon:"figure.hiking",minutes:60,walking:false,progress:true,terms:["hiking","hike","هايكنق","مشي جبلي"]),
        .init(key:"climbing",icon:"figure.climbing",minutes:60,walking:false,progress:false,terms:["climbing","تسلق"]),
        .init(key:"workout",icon:"dumbbell.fill",minutes:60,walking:false,progress:true,terms:["gym","workout","exercise","fitness","training","النادي","نادي","تمرين","تمارين","رياضة","رياضه"]),
        .init(key:"camping",icon:"tent.fill",minutes:180,walking:false,progress:false,terms:["camping","تخييم","كشتة","كشته"]),
        .init(key:"sea",icon:"water.waves",minutes:120,walking:false,progress:false,terms:["sea","beach","ocean","بحر","شاطئ","شاطي"]),
        .init(key:"nature",icon:"leaf.fill",minutes:60,walking:false,progress:false,terms:["outdoor","nature","طبيعة","طبيعه","منتزه","بر"]),
        .init(key:"language",icon:"character.book.closed.fill",minutes:30,walking:false,progress:true,terms:["language","english","french","spanish","لغة","لغه","انجليزي","فرنسي"]),
        .init(key:"course",icon:"person.crop.rectangle.stack.fill",minutes:60,walking:false,progress:true,terms:["course","class","training course","دورة","دوره","كورس","تدريب"]),
        .init(key:"study",icon:"graduationcap.fill",minutes:60,walking:false,progress:true,terms:["study","studying","مذاكرة","مذاكره","دراسة","دراسه"]),
        .init(key:"learning",icon:"brain.head.profile.fill",minutes:30,walking:false,progress:true,terms:["learn","learning","تعلم","تعلّم"]),
        .init(key:"reading",icon:"book.fill",minutes:30,walking:false,progress:true,terms:["reading","read","book","books","قراءة","قراءه","كتاب","كتب"]),
        .init(key:"journal",icon:"book.closed.fill",minutes:15,walking:false,progress:true,terms:["journal","diary","يوميات","مذكرات"]),
        .init(key:"writing",icon:"pencil",minutes:30,walking:false,progress:true,terms:["writing","write","كتابة","كتابه"]),
        .init(key:"planning",icon:"calendar.badge.clock",minutes:15,walking:false,progress:true,terms:["planning","plan tomorrow","تخطيط","خطط"]),
        .init(key:"art",icon:"paintpalette.fill",minutes:45,walking:false,progress:true,terms:["drawing","painting","art","رسم","تلوين","فن"]),
        .init(key:"photo",icon:"camera.fill",minutes:45,walking:false,progress:false,terms:["photography","camera","تصوير","كاميرا"]),
        .init(key:"instrument",icon:"guitars.fill",minutes:30,walking:false,progress:true,terms:["piano","guitar","oud","بيانو","جيتار","عود"]),
        .init(key:"music",icon:"music.note",minutes:30,walking:false,progress:true,terms:["music","موسيقى"]),
        .init(key:"meditation",icon:"figure.mind.and.body",minutes:15,walking:false,progress:true,terms:["meditation","mindfulness","تأمل","تامل"]),
        .init(key:"breathing",icon:"wind",minutes:10,walking:false,progress:true,terms:["breathing","breath","تنفس"]),
        .init(key:"relax",icon:"leaf.circle.fill",minutes:30,walking:false,progress:true,terms:["relax","relaxation","rest","استرخاء","راحة","راحه"]),
        .init(key:"nap",icon:"bed.double.fill",minutes:30,walking:false,progress:true,terms:["nap","قيلولة","قيلوله"]),
        .init(key:"wake",icon:"sun.max.fill",minutes:5,walking:false,progress:false,terms:["wake up","early rise","استيقاظ","اصحى بدري"]),
        .init(key:"sleep",icon:"moon.zzz.fill",minutes:30,walking:false,progress:true,terms:["sleep","bedtime","نوم","النوم"]),
        .init(key:"water",icon:"drop.fill",minutes:5,walking:false,progress:true,terms:["water","hydration","ماء","مياه","شرب الماء"]),
        .init(key:"nosugar",icon:"nosign",minutes:5,walking:false,progress:true,terms:["no sugar","avoid sweets","بدون سكر","تقليل السكر"]),
        .init(key:"healthyfood",icon:"carrot.fill",minutes:30,walking:false,progress:true,terms:["healthy food","healthy meal","اكل صحي","أكل صحي","غذاء صحي"]),
        .init(key:"diet",icon:"fork.knife",minutes:30,walking:false,progress:true,terms:["diet","calories","حمية","حميه","دايت","سعرات"]),
        .init(key:"vitamin",icon:"pills.fill",minutes:5,walking:false,progress:false,terms:["vitamin","vitamins","supplement","فيتامين","فيتامينات","مكمل"]),
        .init(key:"medicine",icon:"cross.case.fill",minutes:5,walking:false,progress:false,terms:["medicine","medication","دواء","علاج","حبوب"]),
        .init(key:"coffee",icon:"cup.and.saucer.fill",minutes:15,walking:false,progress:false,terms:["coffee","قهوة","قهوه"]),
        .init(key:"fasting",icon:"moon.stars.fill",minutes:5,walking:false,progress:false,terms:["fasting","صيام","صوم"]),
        .init(key:"prayer",icon:"moon.stars.fill",minutes:15,walking:false,progress:false,terms:["prayer","salah","صلاة","صلاه"]),
        .init(key:"dhikr",icon:"sparkles",minutes:10,walking:false,progress:true,terms:["dhikr","athkar","ذكر","اذكار","أذكار"]),
        .init(key:"dua",icon:"heart.text.square.fill",minutes:10,walking:false,progress:true,terms:["dua","supplication","دعاء","ادعية","أدعية"]),
        .init(key:"parents",icon:"heart.fill",minutes:15,walking:false,progress:false,terms:["parents","mother","father","الوالدين","الوالدة","الوالد","امي","أمي","ابي","أبي"]),
        .init(key:"children",icon:"figure.2.and.child.holdinghands",minutes:60,walking:false,progress:false,terms:["children","kids","اطفال","أطفال","الابناء","الأبناء","عيالي"]),
        .init(key:"partner",icon:"heart.circle.fill",minutes:60,walking:false,progress:false,terms:["spouse","partner","زوج","زوجة","زوجه"]),
        .init(key:"family",icon:"figure.2.and.child.holdinghands",minutes:60,walking:false,progress:false,terms:["family","عائلة","عائله","الاسرة","الأسرة"]),
        .init(key:"friends",icon:"person.2.fill",minutes:60,walking:false,progress:false,terms:["friends","social","اصدقاء","أصدقاء","اصحاب","أصحاب","اجتماعيات"]),
        .init(key:"call",icon:"phone.fill",minutes:15,walking:false,progress:false,terms:["phone call","call","اتصال","مكالمة","مكالمه","اتصل"]),
        .init(key:"nophone",icon:"iphone.slash",minutes:60,walking:false,progress:true,terms:["no phone","digital detox","بدون جوال","تقليل الجوال"]),
        .init(key:"sociallimit",icon:"hourglass",minutes:30,walking:false,progress:true,terms:["social media","instagram","tiktok","سوشال ميديا","انستقرام","تيك توك"]),
        .init(key:"saving",icon:"banknote.fill",minutes:10,walking:false,progress:true,terms:["saving","save money","ادخار","توفير"]),
        .init(key:"budget",icon:"creditcard.fill",minutes:20,walking:false,progress:true,terms:["budget","expenses","ميزانية","ميزانيه","مصاريف"]),
        .init(key:"cleaning",icon:"sparkles",minutes:30,walking:false,progress:true,terms:["cleaning","clean","تنظيف","نظافة","نظافه"]),
        .init(key:"organize",icon:"square.grid.2x2.fill",minutes:30,walking:false,progress:true,terms:["organize","tidy","ترتيب","تنظيم"]),
        .init(key:"garden",icon:"leaf.fill",minutes:30,walking:false,progress:true,terms:["gardening","garden","زراعة","زراعه","حديقة","حديقه"]),
        .init(key:"pet",icon:"pawprint.fill",minutes:30,walking:false,progress:true,terms:["pet","dog","cat","حيوان اليف","حيوان أليف","كلب","قط"]),
        .init(key:"driving",icon:"car.fill",minutes:30,walking:false,progress:false,terms:["driving","قيادة","قياده","سواقة","سواقه"]),
        .init(key:"travel",icon:"airplane",minutes:120,walking:false,progress:false,terms:["travel","trip","سفر","رحلة","رحله"]),
        .init(key:"gaming",icon:"gamecontroller.fill",minutes:60,walking:false,progress:true,terms:["gaming","games","العاب","ألعاب","قيمز"]),
        .init(key:"care",icon:"hands.sparkles.fill",minutes:20,walking:false,progress:true,terms:["skincare","self care","عناية","عنايه","بشرة","بشره"]),
        .init(key:"shower",icon:"shower.fill",minutes:15,walking:false,progress:true,terms:["shower","cold shower","استحمام","شاور"]),
        .init(key:"scooter",icon:"scooter",minutes:45,walking:false,progress:false,terms:["scooter","سكوتر"])
    ]

    static func profile(for title:String) -> HabitProfile {
        let text = normalize(title)
        for r in rules where r.terms.contains(where: { text.contains(normalize($0)) }) {
            return HabitProfile(key:r.key, icon:r.icon, defaultMinutes:r.minutes, tracksWalking:r.walking, progressBased:r.progress)
        }
        return HabitProfile(key:"generic",icon:"checkmark.circle.fill",defaultMinutes:30,tracksWalking:false,progressBased:false)
    }

    static func explicitMinutes(in title:String) -> Int? {
        let t = title.replacingOccurrences(of:"٠",with:"0").replacingOccurrences(of:"١",with:"1").replacingOccurrences(of:"٢",with:"2").replacingOccurrences(of:"٣",with:"3").replacingOccurrences(of:"٤",with:"4").replacingOccurrences(of:"٥",with:"5").replacingOccurrences(of:"٦",with:"6").replacingOccurrences(of:"٧",with:"7").replacingOccurrences(of:"٨",with:"8").replacingOccurrences(of:"٩",with:"9")
        if t.localizedCaseInsensitiveContains("ساعة") || t.localizedCaseInsensitiveContains("ساعه") || t.localizedCaseInsensitiveContains("hour") {
            if let n = firstNumber(t) { return n * 60 }
        }
        if t.localizedCaseInsensitiveContains("دقيقة") || t.localizedCaseInsensitiveContains("دقيقه") || t.localizedCaseInsensitiveContains("min") {
            return firstNumber(t)
        }
        return nil
    }

    private static func firstNumber(_ s:String)->Int? {
        let digits = s.split(whereSeparator:{ !$0.isNumber }).compactMap{Int($0)}
        return digits.first
    }
    private static func normalize(_ s:String)->String {
        s.lowercased().folding(options:[.diacriticInsensitive,.widthInsensitive],locale:Locale(identifier:"ar"))
            .replacingOccurrences(of:"أ",with:"ا").replacingOccurrences(of:"إ",with:"ا").replacingOccurrences(of:"آ",with:"ا")
            .replacingOccurrences(of:"ة",with:"ه").replacingOccurrences(of:"ى",with:"ي").replacingOccurrences(of:"ؤ",with:"و").replacingOccurrences(of:"ئ",with:"ي")
    }
}
