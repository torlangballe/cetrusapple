//
//  ZImageRecognition.swift
//  PocketProbe
//
//  Created by Tor Langballe on /13/12/17.
//  Copyright © 2017 Bridgetech. All rights reserved.
//

import UIKit
import ImageIO
import CoreImage

extension ZImage {
    func FindFaces(got:(_ faces:[ZFaceInfo])->Void) {
        if let ci = GetCIImage() {
            let opts = [
                CIDetectorAccuracy : CIDetectorAccuracyHigh
            ]
            
            //            let detector = CIDetector(ofType:CIDetectorTypeFace, context:CIContext(), options:opts)!
            let detector = ZOpenFaceDetector(opts)!
            let fopts = [
                CIDetectorSmile: true,
                CIDetectorEyeBlink: true,
                ]
            let features = detector.features(in:ci, options:fopts)
            if features.count > 0 { // , options:opts
                var faces = [ZFaceInfo]()
                for f in features {
                    if let fi = f as? CIFaceFeature {
                        var face = ZFaceInfo()
                        if fi.hasFaceAngle {
                            face.faceAngle = fi.faceAngle
                        }
                        face.hasSmile = fi.hasSmile
                        face.leftEyeClosed = fi.leftEyeClosed
                        face.rightEyeClosed = fi.rightEyeClosed
                        faces.append(face)
                    }
                }
                if faces.count > 0 {
                    got(faces)
                }
            }
        }
    }
}
