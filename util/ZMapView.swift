//
//  ZMapView.swift
//  capsulefm
//
//  Created by Tor Langballe on /28/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import MapKit
import UIKit

typealias ZMapPolygon = MKPolygon
typealias ZMapType = MKMapType

class ZMapView : MKMapView, MKMapViewDelegate, ZView {
    var objectName = "mapview"
    
    var overlayPath: ZPath? = nil
    
    var tapHandler:((_ viewPos:ZPos, _ worldPos:ZPos, _ id:String)->Void)? = nil

    func View() -> UIView { return self }

    init(size:ZSize) {
        super.init(frame:ZRect(size:size).GetCGRect())
        delegate = self //ZGetTopViewController() as! ZViewController
        showsUserLocation = true
        showsCompass = true
        showsScale = true
        let gtap = UITapGestureRecognizer(target:self, action:#selector(self.didTapMap(_:)))
        self.addGestureRecognizer(gtap)
        
        //        showsPointsOfInterest = true
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func GetCoordInViewPos(_ coord:ZPos) -> ZPos {
        let coord = ZLocation.ZPosToCLLocationCoordinate2D(coord)
        let cgpos = self.convert(coord, toPointTo:self)
        return ZPos(cgpos)
    }
    
    @objc func didTapMap(_ gestureRecognizer: UIGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: self)

        let tapCoordinate = self.convert(tapPoint, toCoordinateFrom:self)
        let pos = ZLocation.CLLocationCoordinate2DToZPos(tapCoordinate)
        
        let mkpoint = MKMapPointForCoordinate(tapCoordinate)
        
        let overlays = self.overlays.filter { o in
            o is ZAnnotationCircle
        }
        
        var id = ""
        for overlay in overlays {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            let datPoint = circleRenderer.point(for:mkpoint)
            circleRenderer.invalidatePath()
            if circleRenderer.path.contains(datPoint) {
                let circle = overlay as! ZAnnotationCircle
                if !circle.info.interactive {
                    return
                }
                id = circle.info.id
                break
            }
        }
        tapHandler?(ZPos(tapPoint), pos, id)
    }
    
    func CenterMapOnLocation(_ pos:ZPos = ZPos(), radiusMeters:Float = 1000) {
        var vpos = pos
        if vpos.IsNull() {
            if mainLocation == nil || !ZLocation.HasLocationEnabled() {
                return
            }
            if let (p, _,_) = mainLocation!.GetCurrentLocation() {
                vpos = p
            } else {
                return
            }
        }
        let loc = CLLocation(latitude:CLLocationDegrees(vpos.y), longitude:CLLocationDegrees(vpos.x))
        let d = Double(radiusMeters) * 2
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(loc.coordinate, d, d)
        setRegion(coordinateRegion, animated:false)
    }
    
    @discardableResult func AddAnnotation(_ pos:ZPos, title: String, locationName: String) -> ZAnnotation {
        let pa = ZAnnotation(pos:pos, title:title, locationName:locationName)
        addAnnotation(pa)
        return pa
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ZAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView { // 2
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                //                view.canShowCallout = true
                //                view.calloutOffset = CGPoint(x: -5, y: 5)
                //                view.rightCalloutAccessoryView = UIButton(type:.DetailDisclosure) as UIView
            }
            //            view.isDraggable = true
            view.canShowCallout = false
            return view
        }
        return nil
    }
    
    func GetAnnotationPos(_ name:String = "") -> ZPos? {
        for a in annotations {
            if name.isEmpty || (a.title != nil && a.title! == name) {
                let pos = ZPos(a.coordinate.longitude, a.coordinate.latitude)
                return pos
            }
        }
        return nil
    }

    func AddCircle(center:ZPos, radiusMeters:Double, color:ZColor = ZColor(), lineWidth:Double = 0, lineColor:ZColor = ZColor(), id:String = "", info:ZAnnotationInfo = ZAnnotationInfo()) {
        let c = ZLocation.ZPosToCLLocationCoordinate2D(center)
        let r = CLLocationDistance(radiusMeters)
        let a = ZAnnotationCircle(center:c, radius:r)
        a.info = info
        a.title = "circle"
        a.info.color = color
        a.info.lineColor = lineColor
        a.info.lineWidth = lineWidth
        a.info.id = id
        self.add(a)
    }
    
    func lcoordsFromPath(_ path:ZPath) -> [CLLocationCoordinate2D] {
        var lcoords = [CLLocationCoordinate2D]()
        path.ForEachPart() { (part, coords:ZPos...) in
            switch part {
            case .move, .line:
                let c = coords[0]
                lcoords.append(CLLocationCoordinate2DMake(CLLocationDegrees(c.y), CLLocationDegrees(c.x)))
            case .close:
                let polygon = MKPolygon(coordinates:&lcoords, count:lcoords.count)
                self.add(polygon)
                lcoords = []
                
            default:
                break
            }
        }
        return lcoords
    }
    
    func AddPolygon(_ path:ZPath, info:ZAnnotationInfo = ZAnnotationInfo()) -> ZAnnotationPolygon {
        var lcoords = lcoordsFromPath(path)
        let polygon = ZAnnotationPolygon(coordinates:&lcoords, count:lcoords.count)
        polygon.info = info
        self.add(polygon)
        
        return polygon
    }

    func AddPolyline(_ path:ZPath, info:ZAnnotationInfo = ZAnnotationInfo()) -> ZAnnotationPolyline {
        var lcoords = lcoordsFromPath(path)
        let polyline = ZAnnotationPolyline(coordinates:&lcoords, count:lcoords.count)
        polyline.info = info
        self.add(polyline)
        
        return polyline
    }

    //override func rendererForOverlay(overlay: MKOverlay) -> MKOverlayRenderer? {

    func mapView(_ mapView: MKMapView, rendererFor overlay:MKOverlay) -> MKOverlayRenderer {
        if let o = overlay as? ZAnnotationPolygon {
            let renderer = MKPolygonRenderer(overlay:overlay)
            if !o.info.color.undefined {
                renderer.fillColor = o.info.color.color
            }
            if o.info.lineWidth != 0 && !o.info.lineColor.undefined {
                renderer.strokeColor = o.info.lineColor.color
            }
            renderer.lineWidth = CGFloat(o.info.lineWidth)
            return renderer
        }
        if let o = overlay as? ZAnnotationPolyline {
            let renderer = MKPolylineRenderer(overlay:overlay)
            if !o.info.color.undefined {
                renderer.fillColor = o.info.color.color
            }
            if o.info.lineWidth != 0 && !o.info.lineColor.undefined {
                renderer.strokeColor = o.info.lineColor.color
            }
            renderer.lineWidth = CGFloat(o.info.lineWidth)
            return renderer
        }
        if let o = overlay as? ZAnnotationCircle {
            let renderer = MKCircleRenderer(overlay:overlay)
            if !o.info.color.undefined {
                renderer.fillColor = o.info.color.color
            }
            if o.info.lineWidth != 0 && !o.info.lineColor.undefined {
                renderer.strokeColor = o.info.lineColor.color
            }
            renderer.lineWidth = CGFloat(o.info.lineWidth)
            return renderer
        }
        return MKOverlayRenderer(overlay:overlay)
    }
}

struct ZAnnotationInfo {
    var id = ""
    var color = ZColor(r:0, g:0, b:1, a:0.3)
    var lineWidth = 0.0
    var lineColor = ZColor()
    var interactive = true
}

class ZAnnotationCircle : MKCircle {
    var info = ZAnnotationInfo()
}

class ZAnnotationPolygon : MKPolygon {
    var info = ZAnnotationInfo()
}

class ZAnnotationPolyline : MKPolyline {
    var info = ZAnnotationInfo()
}

class ZAnnotation: NSObject, MKAnnotation {
    var info = ZAnnotationInfo()
    let title: String?
    let locationName: String
    var coord: CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        get { return coord }
        set { coord = newValue; print("newcoord:", newValue) }
    }
    
    init(pos:ZPos, title:String, locationName:String, id:String = "") {
        self.title = title
        self.locationName = locationName
        self.coord = CLLocationCoordinate2D(latitude:CLLocationDegrees(pos.y), longitude:CLLocationDegrees(pos.x))
        self.info.id = id
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}
