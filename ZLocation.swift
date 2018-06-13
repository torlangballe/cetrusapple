//
//  ZLocation.swift
//  Zed
//
//  Created by Tor Langballe on /26/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

protocol ZLocationDelegate {
    func HandleLocationUpdated(_ pos:ZPos)
    func HandleLocationPlaceUpdated(_ error:Error?, placeNames:ZPlaceNames, pos:ZPos)
    func HandleNewHeadingDirectionDegrees(direction:Double)
}

class ZLocation: CLLocationManager, CLLocationManagerDelegate, ZTimerOwner {
    var oldPos = ZPos()
    var getPlace:Bool = true
    var zdelegate: ZLocationDelegate? = nil
    var fakePoints = [ZPos]()
    var fakeDurationSecs = 0.0
    var fakeStart = ZTime()
    var fakeTimer = ZRepeater()
    var enteredRegions = [ZPos]()
    var headingDirectionDegrees:Double? = nil
    
    func IsFakingPoints() -> Bool {
        return !fakePoints.isEmpty
    }
    
    func SetFakePoints(points:[ZPos], durationSecs:Double) {
        fakePoints = points
        fakeDurationSecs = durationSecs
        fakeStart = ZTime.Now
        fakeTimer.Set(10, owner: self, now:true) { [weak self] () in
            if self == nil {
                return false
            }
            let t = self!.fakeStart.Since() / self!.fakeDurationSecs
            if t > 1 {
                self!.StopFakePoints()
                if let (pos, _, _) = self!.GetCurrentLocation() {
                    self!.handleNewLocation(pos)
                }
                return false
            }
            let pos = ZGetTPositionInPosPath(path:self!.fakePoints, t:t)
            ZDebug.Print("FakePos:", pos, "t:", t)
            for case let region as CLCircularRegion in self!.monitoredRegions {
                let cpos = ZLocation.CLLocationCoordinate2DToZPos(region.center)
                if self!.enteredRegions.index(of:cpos) == nil {
                    let loc = ZLocation.ZPosToCLLocationCoordinate2D(pos)
                    if region.contains(loc) {
                        cApp.HandleLocationRegionCross(regionId:region.identifier, enter:true, fromAdd:true)
                        self!.enteredRegions.append(cpos)
                    }
                    break
                }
            }
            self!.handleNewLocation(pos)
            return true
        }
    }
    
    func StopFakePoints() {
        fakePoints = []
        fakeTimer.Stop()
        fakeDurationSecs = 0
        fakeStart = ZTime()
        if let (loc, _, _) = self.GetCurrentLocation() {
            oldPos = loc
        }
    }
    
    static func ReverseGeocode(_ pos:ZPos, done:@escaping (_ error:Error?, _ place:ZPlaceNames, _ pos:ZPos)->Void) {
        let loc = CLLocation(latitude:CLLocationDegrees(pos.y), longitude:CLLocationDegrees(pos.x))
        let geo = CLGeocoder()
        geo.reverseGeocodeLocation(loc) { (placemarks, error) in
            ZMainQue.async { () in
                var place = ZPlaceNames()
                var pos = ZPos()
                if error == nil {
                    if let pm = placemarks?[0] {
                        (place, pos) = getPlaceAndPos(pm)
                    }
                }
                done(error, place, pos)
            }
        }
    }

    static func ForwardGeocode(_ place:String, done:@escaping (_ error:Error?, _ place:ZPlaceNames, _ pos:ZPos)->Void) {
        let coder = CLGeocoder()
        coder.geocodeAddressString(place) { (placemarks, error) in
            ZMainQue.async { () in
                var place = ZPlaceNames()
                var pos = ZPos()
                if error == nil {
                    if let pm = placemarks?[0] {
                        (place, pos) = getPlaceAndPos(pm)
                    }
                }
                done(error, place, pos)
            }
        }
    }

    func handleNewLocation(_ pos:ZPos) {
        if pos != oldPos {
            oldPos = pos
            ZMainQue.async { () in
                self.zdelegate?.HandleLocationUpdated(pos)
                if self.getPlace {
                    ZLocation.ReverseGeocode(pos) { (error, place, pos) in
                        self.zdelegate?.HandleLocationPlaceUpdated(error, placeNames:place, pos:pos)
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if IsFakingPoints() {
            return
        }
        let loc = locations.last!
        var pos = ZPos()
        pos.x = Double(loc.coordinate.longitude)
        pos.y = Double(loc.coordinate.latitude)
        handleNewLocation(pos)
    }

    func RequestWhenInUseAuthorization() {
        self.requestWhenInUseAuthorization()
    }
    
    func StartUpdatingLocation(_ zdelegate:ZLocationDelegate, doPlace:Bool, significantOnly:Bool) {
        if !ZLocation.HasLocationEnabled() {
            //        getIPLocation(resp, ZFPos(0, 0));
            return;
        }
        self.zdelegate = zdelegate
        delegate = self
        self.desiredAccuracy = kCLLocationAccuracyBest //kCLLocationAccuracyNearestTenMeters; //kCLLocationAccuracyThreeKilometers; //kCLLocationAccuracyNearestTenMeters;
        self.distanceFilter = 50.0; //1000.0;
        self.getPlace = doPlace
        if significantOnly {
            self.startMonitoringSignificantLocationChanges()
        } else {
            self.startUpdatingLocation()
        }
    }

    func Stop(significantOnly:Bool) {

        if significantOnly {
            self.stopMonitoringSignificantLocationChanges()
        } else {
            self.stopUpdatingLocation()
        }
    }

    func CheckNotAuthorizedYet(inUse:Bool, ask:Bool) -> Bool {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            if ask {
                self.requestWhenInUseAuthorization()
            }
            return true
        }
        return false
    }
    
    static func HasLocationEnabled() -> Bool {

        if !CLLocationManager.locationServicesEnabled() {
            return false
        }
        let s = CLLocationManager.authorizationStatus()
        if s == CLAuthorizationStatus.authorizedWhenInUse || s == CLAuthorizationStatus.authorizedAlways { //  || s == CLAuthorizationStatus.notDetermined
            return true
        }
    
        return false;
    }

    func GetMovement() -> (Float, Float)? { // course in degrees, speed in m/s
        if let loc = self.location {            
            return (Float(loc.course), Float(loc.speed))
        }
        return nil
    }

    func GetCurrentLocation() -> (ZPos, ZTime, Float)? { // enabled, location-pos, time, altitude
        if IsFakingPoints() && !oldPos.IsNull() {
            //            ZDebug.Print("GetCurrentLocation (faked):", oldPos)
            return (oldPos, ZTime.Now, 0)
        }
        if let loc = self.location {
            let coord = loc.coordinate;
            let pos = ZPos(Float(coord.longitude), Float(coord.latitude))
            //            ZDebug.Print("GetCurrentLocation (current):", pos)
            return (pos, loc.timestamp, Float(loc.altitude))
        }
        if !oldPos.IsNull() {
            //            ZDebug.Print("GetCurrentLocation (oldpos):", oldPos)
            return (oldPos, ZTime.Now, 0)
        }
        return nil
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        ZDebug.Print("Monitoring failed for region with identifier: \(region!.identifier):", error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        ZDebug.Print("Location Manager failed with the following error:", error.localizedDescription)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let cr = region as? CLCircularRegion {
            let cpos = ZLocation.CLLocationCoordinate2DToZPos(cr.center)
            if self.enteredRegions.index(of:cpos) == nil {
                mainZApp?.HandleLocationRegionCross(regionId:region.identifier, enter:true, fromAdd:false)
                self.enteredRegions.append(cpos)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            mainZApp?.HandleLocationRegionCross(regionId:region.identifier, enter:false, fromAdd:false)
        }
    }

    func locationManager( _ manager:CLLocationManager, didUpdateHeading newHeading:CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        let dir = (newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading
        self.headingDirectionDegrees = dir
        zdelegate?.HandleNewHeadingDirectionDegrees(direction:dir)
    }

    func AddGeoMonitoredCircle(center:ZPos, radiusMeters:Double, id:String) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            if ZLocation.HasLocationEnabled() {
                let clampedRadius = min(radiusMeters, self.maximumRegionMonitoringDistance)
                let region = CLCircularRegion(center:ZLocation.ZPosToCLLocationCoordinate2D(center), radius:clampedRadius, identifier:id)
                region.notifyOnEntry = true
                region.notifyOnExit = false
                self.startMonitoring(for:region)
                if !oldPos.IsNull() {
                    let loc = ZLocation.ZPosToCLLocationCoordinate2D(oldPos)
                    if region.contains(loc) {
                        mainZApp?.HandleLocationRegionCross(regionId:region.identifier, enter:true, fromAdd:true)
                    }
                }
            }
        }
    }
    
    func RemoveGeoMonitoredCircle(id:String) {
        for region in self.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == id else { continue }
            self.stopMonitoring(for: circularRegion)
        }
    }

    func RemoveAllGeoMonitoredRegions() {
        for region in self.monitoredRegions {
            self.stopMonitoring(for:region)
        }
    }
    
    func StartGetHeadingDirections(start:Bool = true) {
        if CLLocationManager.headingAvailable() {
            if start {
                self.headingFilter = 5;
                self.startUpdatingHeading()
            }
        }
    }
    
    static func ZPosToCLLocationCoordinate2D(_ pos:ZPos) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(CLLocationDegrees(pos.y), CLLocationDegrees(pos.x))
    }

    static func CLLocationCoordinate2DToZPos(_ loc:CLLocationCoordinate2D) -> ZPos {
        return ZPos(loc.longitude, loc.latitude)
    }
    
    static func IsPosInCircle(circleCenter:ZPos, circleRadiusMeters:Double, pos:ZPos) -> Bool {
        let region = CLCircularRegion(center:ZLocation.ZPosToCLLocationCoordinate2D(circleCenter), radius:circleRadiusMeters, identifier:"")
        let dcoord = ZPosToCLLocationCoordinate2D(pos)
        if region.contains(dcoord) {
            return true
        }
        return false
    }
    
    static func DistanceInMetersBetweenLocations(_ loc1:ZPos, _ loc2:ZPos) -> Double {
        let lloc1 = CLLocation(latitude:CLLocationDegrees(loc1.y), longitude:CLLocationDegrees(loc1.x))
        let lloc2 = CLLocation(latitude:CLLocationDegrees(loc2.y), longitude:CLLocationDegrees(loc2.x))
        return lloc1.distance(from:lloc2)
    }

    static func VectorInMetersBetweenLocations(_ from:ZPos, _ to:ZPos) -> ZPos {
        var x = DistanceInMetersBetweenLocations(from, ZPos(to.x, from.y))
        var y = DistanceInMetersBetweenLocations(from, ZPos(from.x, to.y))
        if from.x > to.x {
            x = -x
        }
        if from.y > to.y {
            y = -y
        }
        return ZPos(x, y)
    }

    func GetImage(pos:ZPos, radiusMeters:Double, timeoutSecs:Double? = nil, type:ZMapType = .standard, imageSize:ZSize, showPOI:Bool = true, showBuildings:Bool = true, rotateToHeading:Bool = false, done:@escaping (_ image:ZImage?, _ metersPerPixel:Double, _ error:ZError?)->Void) {
        var size = imageSize
        // gets at device's screen scale
        let options = MKMapSnapshotOptions()
        
        let loc = ZLocation.ZPosToCLLocationCoordinate2D(pos) //CLLocation(latitude:CLLocationDegrees(vpos.y), longitude:CLLocationDegrees(pos.x))
        var d = Double(radiusMeters) * 2
        if rotateToHeading {
            size = size.EqualSided() * sqrt(2)
            d *= sqrt(2)
        }
        let mpp = d / size.w
        options.region = MKCoordinateRegionMakeWithDistance(loc, d, d) // we need to handle non-square image sizes too
        options.size = size.GetCGSize()
        options.showsPointsOfInterest = showPOI
        options.showsBuildings = showBuildings
        options.mapType = type // https://developer.apple.com/documentation/mapkit/mkmaptype

        let map = MKMapSnapshotter(options:options)
        let timer = ZTimer()
        if timeoutSecs != nil {
            ZMainQue.async {
                timer.Set(timeoutSecs!, owner:self) { () in
                    map.cancel()
                    done(nil, mpp, ZError(message:"timed out"))
                }
            }
        }
        map.start() { (snap, error) in
            timer.Stop()
            if error != nil {
                done(nil, mpp, error as? ZError ?? nil)
            } else {
                if rotateToHeading {
                    if let heading = mainLocation?.headingDirectionDegrees {
                        if let ri = snap!.image.Rotated(deg:heading) {
                            let r = ZRect(size:size).Align(imageSize, align:.Center)
                            let ci = ri.GetCropped(r)
                            done(ci, mpp, nil)
                            return
                        }
                    }
                }
                done(snap!.image, mpp, nil)
            }
        }
    }
}

private func getPlaceAndPos(_ pm:CLPlacemark) -> (ZPlaceNames, ZPos) {
    var place = ZPlaceNames()
    let coord = pm.location!.coordinate
    let pos = ZPos(coord.longitude, coord.latitude)
    place.streetNo = pm.subThoroughfare ?? ""                     // eg. 1
    place.route = pm.thoroughfare ?? ""                           // street address, eg. 1 Infinite Loop
    place.subLocality = pm.subLocality ?? ""                      // neighborhood, common name, eg. Mission District
    place.locality = pm.locality ?? ""                            // city, eg. Cupertino
    place.adminArea = pm.subAdministrativeArea ?? ""              // county, eg. Santa Clara
    place.adminAreaSuper = pm.administrativeArea ?? ""            // state, eg. CA
    place.countryCode = (pm.isoCountryCode ?? "").lowercased() // us, no etc
    place.countryName = pm.country ?? ""                          // united steaks
    if place.locality.isEmpty {
        place.locality = place.subLocality;
        place.locality = place.adminArea
    }
    if place.locality == "Greater London" {
        place.locality = "London"
    }
    return (place, pos)
}

var mainLocation:ZLocation? = nil
