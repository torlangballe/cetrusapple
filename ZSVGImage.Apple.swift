//
//  ZSVGImage.Apple.swift
//
//  Created by Tor Langballe on 19/03/2019.
//
// #package com.github.torlangballe.cetrusandroid

import Foundation
import SVGKit


class ZSVGImage {
    let image: SVGKImage?

    init(data:ZData) {
        image = SVGKImage(data: data)
    }
    
    func Draw(canvas: ZCanvas) {
        image?.render(to: canvas.context, antiAliased: true, curveFlatnessFactor:1.0, interpolationQuality:.medium, flipYaxis:false)
    }
}

