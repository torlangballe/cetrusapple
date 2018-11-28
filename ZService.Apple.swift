//
//  ZService.Apple.swift
//
//  Created by Tor Langballe on 11/26/18.

// #package com.github.torlangballe.cetrusandroid

import Foundation

open class ZService {
    var keepAlive = false
    
    public required init() {
        
    }
    
    open func DoService() {
        
    }
    
    class func Start(_ aclass: AnyClass) {
        let serviceClass = aclass as! ZService.Type
        let service = serviceClass.init()
        service.DoService()
    }
}
