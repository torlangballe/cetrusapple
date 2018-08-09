//
//  ZPlaceNames.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

struct ZPlaceNames {
    var streetNo = ""
    var route = ""
    var subLocality = ""
    var locality = ""
    var adminArea = ""
    var adminAreaSuper = ""
    var countryCode = ""
    var countryName = ""
   
    func Marshal() -> ZJSON {
        var json = ZJSON.JDict()
        json["streetNo"] = ZJSON(streetNo)
        json["route"] = ZJSON(route)
        json["subLocality"] = ZJSON(subLocality)
        json["locality"] = ZJSON(locality)
        json["adminarea"] = ZJSON(adminArea)
        json["adminareasuper"] = ZJSON(adminAreaSuper)
        json["countrycode"] = ZJSON(countryCode)
        json["countryname"] = ZJSON(countryName)
        return json
    }

    mutating func Unmarshal(_ json: ZJSON) {
        streetNo = ZJSON("streetNo").stringValue
        route = ZJSON("route").stringValue
        subLocality = ZJSON("subLocality").stringValue
        locality = ZJSON("locality").stringValue
        adminArea = ZJSON("adminarea").stringValue
        adminAreaSuper = ZJSON("adminareasuper").stringValue
        countryCode = ZJSON("countrycode").stringValue
        countryName = ZJSON("countryname").stringValue
    }
    
    func Concat() -> String {
        var str = ZStr.ConcatNonEmpty(items:streetNo, route, " ")
        str = ZStr.ConcatNonEmpty(separator:", ", items:str, subLocality, locality)
        str = ZStr.ConcatNonEmpty(separator:", ", items:str, adminArea, countryName)
        return str
    }
}
