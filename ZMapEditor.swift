//
//  ZMapEditor.swift
//  capsulefm
//
//  Created by Tor Langballe on /7/8/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit
import MapKit

class ZMapEditor : ZStackView {
    let map:ZMapView
    var editButton = ZImageView(namedImage:"edit.png")
    var deleteButton = ZImageView(namedImage:"cross.png")
    var backspaceButton = ZImageView(namedImage:"backspace.png")
    var isDrawingPolygon = false
    var coordinates = [CLLocationCoordinate2D]()
    var drawingPolygon: ZMapPolygon? = nil
    var drawingAnnotation: ZAnnotation? = nil

    required init(size:ZSize, polygon:ZPath?) {
        map = ZMapView(size:size)
        super.init(name:"mapeditor")
        vertical = true
        space = 4
        
        Add(map, align:.Top | .Left | .Expand | .NonProp)
        let h1 = ZHStackView(space:8)
        h1.Add(deleteButton, align:.Left | .Bottom)
        deleteButton.AddTarget(self, forEventType:.pressed)
        h1.Add(editButton, align:.Right | .Bottom)
        editButton.AddTarget(self, forEventType:.pressed)
        h1.Add(backspaceButton, align:.Right | .Bottom)
        backspaceButton.AddTarget(self, forEventType:.pressed)
        
        polygon?.ForEachPart({ [weak self] (part, coords:ZPos...) in
            switch part {
                case .move, .line:
                    let c = coords[0]
                    self?.coordinates.append(CLLocationCoordinate2DMake(CLLocationDegrees(c.y), CLLocationDegrees(c.x)))
                default:
                    break
            }
        })
        Add(h1, align:.Bottom | .Right | .HorExpand | .NonProp, marg:ZSize(0, 5))
        updatePolygon()
        updateButtons()
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func StartEdit(_ edit:Bool = true) {
        isDrawingPolygon = edit
        map.isUserInteractionEnabled = !edit
        updateButtons()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDrawingPolygon {
            return
        }
        if let pos = touches.first?.location(in: self) {
            let loc = map.convert(pos, toCoordinateFrom:map)
            addCoordinate(loc, replaceLast:false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDrawingPolygon {
            return
        }
        if let pos = touches.first?.location(in: self) {
            let loc = map.convert(pos, toCoordinateFrom:map)
            addCoordinate(loc, replaceLast:true)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDrawingPolygon {
            return
        }
        if let pos = touches.first?.location(in: self) {
            let loc = map.convert(pos, toCoordinateFrom:map)
            addCoordinate(loc, replaceLast:true)
        }
        
        //    if ([self isClosingPolygonWithCoordinate:coordinate])
        //      [self didTouchUpInsideDrawButton:nil];
    }

    override func HandlePressed(_ sender: ZView, pos: ZPos) {
        switch sender.View() {
            case editButton:
                StartEdit(!isDrawingPolygon)
            
            case deleteButton:
                isDrawingPolygon = false
                coordinates.removeAll()
                updatePolygon()
                updateButtons()
            
            case backspaceButton:
                coordinates.removeLast()
                updatePolygon()
                updateButtons()
            
            default:
                break
        }
    }
    fileprivate func addCoordinate(_ coord:CLLocationCoordinate2D, replaceLast:Bool) {
        
        if replaceLast && coordinates.count > 0 {
            coordinates.removeLast()
        }
        coordinates.append(coord)
        let anno = map.AddAnnotation(ZPos(coord.longitude, coord.latitude), title:"", locationName:"")
        updatePolygon()
        drawingAnnotation = anno
        updateButtons()
    }
    
    func MakePathFromCoords() -> ZPath {
        let path = ZPath()
        path.MoveTo(ZPos(coordinates[0].longitude, coordinates[0].latitude))
        for i in 1 ..< coordinates.count {
            path.LineTo(ZPos(coordinates[i].longitude, coordinates[i].latitude))
        }
        return path
    }
    
    fileprivate func updatePolygon() {
        var poly: MKPolygon? = nil
        if coordinates.count > 1 {
            let path = MakePathFromCoords()
            poly = map.AddPolygon(path)
        }
        if drawingPolygon != nil {
            map.remove(drawingPolygon!)
        }
        drawingPolygon = poly
            
        if drawingAnnotation != nil {
            map.removeAnnotation(drawingAnnotation!)
        }
    }

    fileprivate func updateButtons() {
        deleteButton.Usable = (coordinates.count > 0)
        backspaceButton.Usable = (coordinates.count > 0 && isDrawingPolygon)
        var image = (ZImage(named:"edit.png"))
        if isDrawingPolygon {
            image = image?.TintedWithColor(ZColor.Yellow())
            ZAnimation.PulseView(editButton, scale:1.1, duration:0.5)
        } else {
            ZAnimation.RemoveAllFromView(editButton)
        }
        editButton.SetImage(image)
    }
}
