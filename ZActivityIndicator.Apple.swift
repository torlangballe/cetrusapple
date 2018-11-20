//
//  ZActivity.swift
//  Cetrus
//
//  Created by Tor Langballe on /11/12/15.
//

import UIKit

class ZActivityIndicator: UIActivityIndicatorView, ZView {
    func View() -> UIView {
        return self
    }
    var objectName = "activity"

    init(big:Bool = true, dark:Bool = false) {
        var gray = UIActivityIndicatorViewStyle.white
        #if os(iOS)
        gray = UIActivityIndicatorViewStyle.gray
        #endif
        let uistyle = big ? UIActivityIndicatorViewStyle.whiteLarge : (dark ? gray : UIActivityIndicatorViewStyle.white)
        super.init(activityIndicatorStyle:uistyle)
    }
    
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func Start(_ start:Bool = true, whenVisible:Bool = true) {
        let method = (start ? "startAnimating" : "stopAnimating")
        self.performSelector(onMainThread: Selector(method), with:nil, waitUntilDone:true)
    }
}

func ZAddActivityToContainer(on:Bool, container:ZContainerView, align:ZAlignment, marg:ZSize = ZSize(0.0, 0.0)) {
    if on {
        let v = ZActivityIndicator(big:false)
        container.Add(v, align:ZAlignment.Right | ZAlignment.Top, marg:ZSize(0.0, 0.0))
        v.Start()
    } else {
        container.RemoveNamedChild("activity")
    }
    container.ArrangeChildren()
}


