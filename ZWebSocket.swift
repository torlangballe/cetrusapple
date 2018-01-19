//
//  ZWebSocket.swift
//  Zed
//
//  Created by Tor Langballe on /25/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import Foundation

protocol ZWebSocketDelegate {
    func HandleWebSocketError(_ error:Error)
    func HandleWebSocketOpen()
    func HandleWebSocketClose(code:Int, reason:String)
    func HandleWebSocketMessage(_ message:String)
}

class ZWebSocket: NSObject, SRWebSocketDelegate {
    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        if let str = message as? String {
            delegate!.HandleWebSocketMessage(str)
        }
    }

    var socket:SRWebSocket? = nil
    var delegate:ZWebSocketDelegate? = nil
    /*
    override init() {
    }
    */
    func webSocketDidOpen(_ webSocket:SRWebSocket) {
        delegate!.HandleWebSocketOpen()
    }

    private func webSocket(_ webSocket:SRWebSocket, didFailWithError:NSError?) {
        delegate!.HandleWebSocketError(didFailWithError!)
    }

    func webSocket(_ webSocket:SRWebSocket , didCloseWithCode:Int, reason:String, wasClean:Bool) {
        delegate!.HandleWebSocketClose(code:didCloseWithCode, reason:reason)
    }
    
    func IsOpen() -> Bool {
        if socket == nil {
            return false
        }
        
        switch socket!.readyState {            
            case SRReadyState.CONNECTING, SRReadyState.OPEN: return true
            case SRReadyState.CLOSING, SRReadyState.CLOSED : return false
        }
    }
    
    func Open(_ url:String) {
        socket = SRWebSocket(url:URL(string:url))
        socket?.delegate = self
        socket?.open()
    }
    
    @discardableResult func Close() -> Bool {
        socket?.close()
        //        socket.delegate = nil
        socket = nil
        return true
    }
}
