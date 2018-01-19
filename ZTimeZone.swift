//
//  ZTimeZone.swift
//  Zed
//
//  Created by Tor Langballe on /3/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
/*
ZStrStr oldZones[] =
{
    { "Africa/Asmera", "Africa/Asmara" },
    { "AKST9AKDT", "America/Anchorage" },
    { "Africa/Timbuktu", "Africa/Bamako" },
    { "America/Argentina/ComodRivadavia", "America/Argentina/Catamarca" },
    { "America/Atka", "America/Adak" },
    { "America/Buenos_Aires", "America/Argentina/Buenos_Aires" },
    { "America/Catamarca", "America/Argentina/Catamarca" },
    { "America/Coral_Harbour", "America/Atikokan" },
    { "America/Cordoba", "America/Argentina/Cordoba" },
    { "America/Ensenada", "America/Tijuana" },
    { "America/Fort_Wayne", "America/Indiana/Indianapolis" },
    { "America/Indianapolis", "America/Indiana/Indianapolis" },
    { "America/Jujuy", "America/Argentina/Jujuy" },
    { "America/Knox_IN", "America/Indiana/Knox" },
    { "America/Louisville", "America/Kentucky/Louisville" },
    { "America/Mendoza", "America/Argentina/Mendoza" },
    { "America/Porto_Acre", "America/Rio_Branco" },
    { "America/Rosario", "America/Argentina/Cordoba" },
    { "America/Virgin", "America/St_Thomas" },
    { "Asia/Ashkhabad", "Asia/Ashgabat" },
    { "Asia/Calcutta", "Asia/Kolkata" },
    { "Asia/Chungking", "Asia/Chongqing" },
    { "Asia/Dacca", "Asia/Dhaka" },
    { "Asia/Istanbul", "Europe/Istanbul" },
    { "Asia/Katmandu", "Asia/Kathmandu" },
    { "Asia/Macao", "Asia/Macau" },
    { "Asia/Saigon", "Asia/Ho_Chi_Minh" },
    { "Asia/Tel_Aviv", "Asia/Jerusalem" },
    { "Asia/Thimbu", "Asia/Thimphu" },
    { "Asia/Ujung_Pandang", "Asia/Makassar" },
    { "Asia/Ulan_Bator", "Asia/Ulaanbaatar" },
    { "Atlantic/Faeroe", "Atlantic/Faroe" },
    { "Atlantic/Jan_Mayen", "Europe/Oslo" },
    { "Australia/ACT", "Australia/Sydney" },
    { "Australia/Canberra", "Australia/Sydney" },
    { "Australia/LHI", "Australia/Lord_Howe" },
    { "Australia/North", "Australia/Darwin" },
    { "Australia/NSW", "Australia/Sydney" },
    { "Australia/Queensland", "Australia/Brisbane" },
    { "Australia/South", "Australia/Adelaide" },
    { "Australia/Tasmania", "Australia/Hobart" },
    { "Australia/Victoria", "Australia/Melbourne" },
    { "Australia/West", "Australia/Perth" },
    { "Australia/Yancowinna", "Australia/Broken_Hill" },
    { "Brazil/Acre", "America/Rio_Branco" },
    { "Brazil/DeNoronha", "America/Noronha" },
    { "Brazil/East", "America/Sao_Paulo" },
    { "Brazil/West", "America/Manaus" },
    { "Canada/Atlantic", "America/Halifax" },
    { "Canada/Central", "America/Winnipeg" },
    { "Canada/Eastern", "America/Toronto" },
    { "Canada/East-Saskatchewan", "America/Regina" },
    { "Canada/Mountain", "America/Edmonton" },
    { "Canada/Newfoundland", "America/St_Johns" },
    { "Canada/Pacific", "America/Vancouver" },
    { "Canada/Saskatchewan", "America/Regina" },
    { "Canada/Yukon", "America/Whitehorse" },
    { "Chile/Continental", "America/Santiago" },
    { "Chile/EasterIsland", "Pacific/Easter" },
    { "Cuba", "America/Havana" },
    { "Egypt", "Africa/Cairo" },
    { "Eire", "Europe/Dublin" },
    { "Etc/GMT", "UTC" },
    { "Etc/GMT+0", "UTC" },
    { "Etc/UCT", "UTC" },
    { "Etc/Universal", "UTC" },
    { "Etc/UTC", "UTC" },
    { "Etc/Zulu", "UTC" },
    { "Europe/Belfast", "Europe/London" },
    { "Europe/Nicosia", "Asia/Nicosia" },
    { "Europe/Tiraspol", "Europe/Chisinau" },
    { "GB", "Europe/London" },
    { "GB-Eire", "Europe/London" },
    { "GMT", "UTC" },
    { "GMT+0", "UTC" },
    { "GMT0", "UTC" },
    { "GMT-0", "UTC" },
    { "Greenwich", "UTC" },
    { "Hongkong", "Asia/Hong_Kong" },
    { "Iceland", "Atlantic/Reykjavik" },
    { "Iran", "Asia/Tehran" },
    { "Israel", "Asia/Jerusalem" },
    { "Jamaica", "America/Jamaica" },
    { "Japan", "Asia/Tokyo" },
    { "JST-9", "Asia/Tokyo" },
    { "Kwajalein", "Pacific/Kwajalein" },
    { "Libya", "Africa/Tripoli" },
    { "Mexico/BajaNorte", "America/Tijuana" },
    { "Mexico/BajaSur", "America/Mazatlan" },
    { "Mexico/General", "America/Mexico_City" },
    { "Navajo", "America/Denver" },
    { "NZ", "Pacific/Auckland" },
    { "NZ-CHAT", "Pacific/Chatham" },
    { "Pacific/Ponape", "Pacific/Pohnpei" },
    { "Pacific/Samoa", "Pacific/Pago_Pago" },
    { "Pacific/Truk", "Pacific/Chuuk" },
    { "Pacific/Yap", "Pacific/Chuuk" },
    { "Poland", "Europe/Warsaw" },
    { "Portugal", "Europe/Lisbon" },
    { "PRC", "Asia/Shanghai" },
    { "ROC", "Asia/Taipei" },
    { "ROK", "Asia/Seoul" },
    { "Singapore", "Asia/Singapore" },
    { "Turkey", "Europe/Istanbul" },
    { "UCT", "UTC" },
    { "Universal", "UTC" },
    { "US/Alaska", "America/Anchorage" },
    { "US/Aleutian", "America/Adak" },
    { "US/Arizona", "America/Phoenix" },
    { "US/Central", "America/Chicago" },
    { "US/Eastern", "America/New_York" },
    { "US/East-Indiana", "America/Indiana/Indianapolis" },
    { "US/Hawaii", "Pacific/Honolulu" },
    { "US/Indiana-Starke", "America/Indiana/Knox" },
    { "US/Michigan", "America/Detroit" },
    { "US/Mountain", "America/Denver" },
    { "US/Pacific", "America/Los_Angeles" },
    { "US/Pacific-New", "America/Los_Angeles" },
    { "US/Samoa", "Pacific/Pago_Pago" },
    { "W-SU", "Europe/Moscow" },
    { "Zulu", "UTC" },
    { NULL, NULL}
};

*/

typealias ZTimeZone = TimeZone

extension ZTimeZone {
    
    // use:
    // self.name
    // self.secondsFromGMT
    //
    static var UTC: ZTimeZone {
        return ZTimeZone(identifier:"UTC")!
    }

    static var DeviceZone: ZTimeZone {
        return TimeZone.autoupdatingCurrent
        //        snew = oldZones->GetValue(szone);
        //        if(snew.Size())
        //        return XTimeZone::FromName(snew);
    }
    
    var NiceName: String {
        var last = ZStrUtil.TailUntil(identifier, sep:"/")
        last = last.replacingOccurrences(of: "_", with:"")
        return last
    }

    var HoursFromUTC: Double {
        return Double(secondsFromGMT()) / 3600
    }
    
    func CalculateOffsetHours(_ time:ZTime = ZTime.Now, localDeltaHours:inout Double) -> Double {
        let secs = secondsFromGMT(for: time as Date)
        let lsecs = TimeZone.autoupdatingCurrent.secondsFromGMT(for: time as Date)
        localDeltaHours = Double(secs - lsecs) / 3600
        return Double(secs) / 3600
    }
    
    func IsUTC() -> Bool {
        return self == ZTimeZone.UTC
    }
}

/*
int XTimeZone::GetZonesWithOffset(ZList<XTimeZone> *list, float offset, bool fractions)
{
    NSArray    *nsarray;
    NSTimeZone *nstz;
    int        i, count;
    double     o;
    
    if(list)
    list->Empty();
    
    count = 0;
    nsarray = [ NSTimeZone knownTimeZoneNames ];
    for(i = 0; i < [ nsarray count ]; i += 1)
    {
        nstz = [ NSTimeZone timeZoneWithName: (NSString *)[ nsarray objectAtIndex: i ] ];
        o = [ nstz secondsFromGMT ] * 3600;
        if(!fractions)
        o = int(o);    
        if(o == offset)
        {
            if(list)
            list->AddLast(XTimeZone(nstz));
            count += 1;
        }
    }
    
    return count;
}

*/
