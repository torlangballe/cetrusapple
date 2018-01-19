//
//  ZActivity.swift
//  capsulefm
//
//  Created by Tor Langballe on /11/12/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit

class ZActivityIndicator: UIActivityIndicatorView, ZView {
    func View() -> UIView {
        return self
    }
    var objectName = "activity"

    init(big:Bool = true, dark:Bool = false) {
        let uistyle = big ? UIActivityIndicatorViewStyle.whiteLarge : (dark ? UIActivityIndicatorViewStyle.gray : UIActivityIndicatorViewStyle.white)
        super.init(activityIndicatorStyle:uistyle)
    }
    
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func Start(_ start:Bool = true, whenVisible:Bool = true) {
        let method = (start ? "startAnimating" : "stopAnimating")
        self.performSelector(onMainThread: Selector(method), with:nil, waitUntilDone:true)
    }
}
