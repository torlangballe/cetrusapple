//
//  ZWebView.swift
//  Zed
//
//  Created by Tor Langballe on /7/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

protocol ZWebViewDelegate {
    func HandleFinishedDownload(_ view:ZWebView, url:String)
    func HandleFailedDownload(_ view:ZWebView, error:ZError)
    func HandleShouldNotLoadUrl(_ view:ZWebView, url:String) -> Bool
    func HandleEnableBack(_ view:ZWebView, enabled:Bool)
    func HandleEnableForward(_ view:ZWebView, enabled:Bool)
}

class ZWebView : UIWebView, ZView, UIWebViewDelegate {
    var content = ""
    var currentUrl:String
    
    var isInFullScreenPlayback = false
    var useCookies = false
    var zdelegate:ZWebViewDelegate? = nil
    var resourcecount = 0
    //var *wprogress = : ZActivityWgt     ;         // links to external progress
    var backButton:ZShapeView? = nil
    var forwardButton:ZShapeView? = nil
    var calculateSize = false
    var maxSize: ZSize
    var minSize: ZSize
    
    func View() -> UIView { return self }
    var objectName = "ZWebView"
//    var scrollviewTransparent = false             ;
//    var mobileizeURLs = true
    var makeUserAgentDesktopBrowser = ZDevice.IsIPad

    init(url:String, minSize:ZSize, scale:Bool = true, content:String = "") {
        currentUrl = url
        self.minSize = minSize
        self.maxSize = minSize
        super.init(frame:ZRect(size:minSize).GetCGRect())
        delegate = self
        dataDetectorTypes = UIDataDetectorTypes.link
        self.allowsInlineMediaPlayback = true
        mediaPlaybackRequiresUserAction = false                
        scalesPageToFit = scale
      //                 if(!bgcolor.IsUndef())
    //          [ webview setBackgroundColor: MacZNColorToNSColor(bgcolor) ];
    /*
                if(scrollviewTransparent)
                {
                    for(NSView *wview in [ [ [ webview subviews ] objectAtIndex:0 ] subviews ])
                        if([ wview isKindOfClass:[ NSImageView class ] ])
                            wview.hidden = YES;
                }
                */
        if !content.isEmpty {
            LoadContent(content, baseUrl:currentUrl)
         } else if !currentUrl.isEmpty {
            LoadURL(currentUrl)
        }
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        Stop()
        delegate = nil
        stopLoading()
    }

    func Clear() {
        LoadURL("about:blank")
    }

    func GetTextInHTML() -> String {
        return EvaluateJavascriptToString("document.documentElement.innerText;")
    }

    func webView(_ webView:UIWebView, didFailLoadWithError:Error) {
        zdelegate?.HandleFailedDownload(self, error:didFailLoadWithError as Error)
    }

    func webView(_ webView:UIWebView, shouldStartLoadWith req:URLRequest, navigationType:UIWebViewNavigationType) -> Bool {
        let url = req.url!.absoluteString
        return !zdelegate!.HandleShouldNotLoadUrl(self, url:url)
    }

    func webViewDidStartLoad(_ webView:UIWebView) {
        _ = self.request!.url!.absoluteString
    //        if(widget->wprogress->pushed == 0)
    //            widget->wprogress->Start();
    }

    func webViewDidFinishLoad(_ webView:UIWebView) {
        var url = self.request!.url!.absoluteString
        if url.isEmpty {
            url = EvaluateJavascriptToString("window.location")
        }
        self.currentUrl = url
        
        if calculateSize {
            let height = self.sizeThatFits(CGSize.zero).height
            minSize.h = min(maxSize.h, Double(height))
        }
        if backButton != nil {
            backButton!.Usable = webView.canGoBack
            zdelegate!.HandleEnableBack(self, enabled:self.canGoBack)
        }
        if forwardButton != nil {
            forwardButton!.Usable = webView.canGoForward
            zdelegate!.HandleEnableForward(self, enabled:self.canGoForward)
        }
    //    if(widget->wprogress)
    //        widget->wprogress->Stop();
        zdelegate!.HandleFinishedDownload(self, url:currentUrl)
    }
/*
    func touchesBegan(touches:NSSet, withEvent:UIEvent) {
        super.touchesBegan(touches, withEvent:withEvent)
    }

    func touchesCancelled(touches:NSSet, withEvent:UIEvent) {
        super.touchesCancelled(touches, withEvent:withEvent)
    }
*/
    
    func copyCookies(_ request:NSMutableURLRequest) {
        if let cookies = HTTPCookieStorage.shared.cookies {
            request.httpShouldHandleCookies = true
            if cookies.count > 0 {
                var dict = [String:String]()
                for cookie in cookies {
                    dict[cookie.name] = cookie.value
                }
                let header = dict.stringFromHttpParameters(escape:false)
                request.setValue(header, forHTTPHeaderField:"Cookie")
            }
        }
    }

    func LoadURL(_ url:String) {
        currentUrl = url
        content = ""
    
        resourcecount = 0
        let nsRequest = NSMutableURLRequest(url:URL(string:url)!)
        if makeUserAgentDesktopBrowser {
            nsRequest.setValue("%s Safari/528.16", forHTTPHeaderField:"User_Agent")
        }
        if useCookies {
            copyCookies(nsRequest)
        }
        self.loadRequest(nsRequest as URLRequest)
        //    if(wprogress)
        //        wprogress->Show(true);
    }

    func LoadContent(_ content:String, baseUrl:String, isJavaScriptCommand:Bool = false) {
        self.content = content;
        currentUrl = baseUrl
    
        if isJavaScriptCommand {
            EvaluateJavascriptToString(content)
        } else {
            self.loadHTMLString(content, baseURL:URL(string:baseUrl))
        }
    }
    
    func IsLoading() {
        return //self.IsLoading() infinite call?
    }
    
    func Stop() {
        self.stopLoading()
        //if(wprogress)
        //wprogress->Show(false);
    }
    
    var CanGoBack: Bool {
        return self.canGoBack
    }

    var CanGoForward: Bool {
        return self.canGoForward
    }

    func GoBack() {
        self.goBack()
        if backButton != nil {
            backButton!.Usable = self.canGoBack
        } else {
            zdelegate?.HandleEnableBack(self, enabled:self.canGoBack)
        }
    }

    func GoForward() {
        self.goForward()
        if forwardButton != nil {
            forwardButton!.Usable = self.canGoForward
        } else {
            zdelegate?.HandleEnableForward(self, enabled:self.canGoForward)
        }
    }
    
    var EstimatedProgress: Float {
        return 0.5;
        //mac:[ WEBVIEW estimatedProgress ];
    }

    @discardableResult func EvaluateJavascriptToString(_ java:String) -> String {
        let str = self.stringByEvaluatingJavaScript(from: java)
        return str ?? ""
    }
}

extension ZWebViewDelegate {
    func HandleShouldNotLoadUrl(_ view:ZWebView, url:String) -> Bool { return false }
    func HandleEnableBack(_ view:ZWebView, enabled:Bool) { }
    func HandleEnableForward(_ view:ZWebView, enabled:Bool) { }
}



