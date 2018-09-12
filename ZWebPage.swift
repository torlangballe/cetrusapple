//
//  ZWebPage.swift
//  Zed
//
//  Created by Tor Langballe on /8/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZWebPageView: ZStackView, ZWebViewDelegate {
    var webView: ZWebView
    var zdelegate:ZWebViewDelegate? = nil
    static weak var current:ZWebPageView? = nil
    
    init(title:String, url:String, delegate:ZWebViewDelegate? = nil) {
        webView = ZWebView(url: url, minSize:ZSize(ZScreen.Main.size.w, 400), scale:false)
        let titleBar = ZTitleBar(text:title)
        
        super.init(name:"webpageview")
        
        SetBackgroundColor(ZColor.White())
        isOpaque = true
        vertical = true

        if delegate == nil {
            webView.zdelegate = self
        } else {
            webView.zdelegate = delegate!
        }
        webView.useCookies = true
        ZWebPageView.current = self
        Add(webView, align:.Top | .HorCenter | .Expand | .NonProp)
        Add(titleBar, align:.Bottom | .HorCenter | .HorExpand | .NonProp)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit {
        ZWebPageView.current = nil
    }
    
    static func Close() {
        assert(ZWebPageView.current != nil)
        ZWebPageView.current?.Pop()
    }
    
    func HandleFinishedDownload(_ view:ZWebView, url:String) {
        if zdelegate != nil {
            return zdelegate!.HandleFinishedDownload(view, url:url)
        }
        //        spin->stop
    }
    
    func HandleFailedDownload(_ view: ZWebView, error: ZError) {
        if zdelegate != nil {
            return zdelegate!.HandleFailedDownload(view, error:error)
        }
        //        spin->stop
    }
    
    func HandleEnableBack(_ view:ZWebView, enabled:Bool) {
    }
    
    func HandleEnableForward(_ view:ZWebView, enabled:Bool) {
    }
    
    func HandleShouldNotLoadUrl(_ view:ZWebView, url:String) -> Bool {
        if zdelegate != nil {
            return zdelegate!.HandleShouldNotLoadUrl(view, url:url)
        }
        return false
    }
}
