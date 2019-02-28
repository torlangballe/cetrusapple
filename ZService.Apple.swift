//
//  ZService.Apple.swift
//
//  Created by Tor Langballe on 11/26/18.

// #package com.github.torlangballe.cetrusandroid

import Foundation

// On iOS ZService is a dummy at the moment, just runs code.
open class ZService : ZObject {
    var keepAlive = false
    
    override public required init() {
        
    }
    
    open func DoService() {
        
    }
    
    class func Start(_ aclass: AnyClass) {
        let serviceClass = aclass as! ZService.Type
        let service = serviceClass.init()
        service.DoService()
    }
}
