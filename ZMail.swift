//
//  ZMail.swift
//  Zed
//
//  Created by Tor Langballe on /15/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import UIKit
import MessageUI

class ZMail {
    struct Address {
        var address = ""
        var name = ""
    }
    var sender = [Address]()
    var replyto = [Address]()
    var cc = [Address]()
    var bcc = [Address]()
    var from = [Address]()
    var to = [Address]()
    var subject = ""
    var body = ""
}

class ZMailComposer : MFMailComposeViewController, MFMailComposeViewControllerDelegate {
    var doneHandler: ((_ sent:Bool)->Void)?

    func mailComposeController(_ controller:MFMailComposeViewController, didFinishWith result:MFMailComposeResult, error:Error?) {
        self.dismiss(animated: false) { () in
            if self.doneHandler != nil {
                self.doneHandler!((result == MFMailComposeResult.sent))
            }
        }
    }
    func CanSend() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    func PopDraft(_ mail:ZMail, files:[ZFileUrl] = [ZFileUrl](), isHtml:Bool = false, done:@escaping (_ sent:Bool)->Void) {
        mailComposeDelegate = self
        doneHandler = done
        setSubject(mail.subject)
        setToRecipients(getAddresses(mail.to))
        setCcRecipients(getAddresses(mail.cc))
        setBccRecipients(getAddresses(mail.bcc))
        if !mail.body.isEmpty {
            setMessageBody(mail.body, isHTML:isHtml)
        }
        for f in files {
            do {
                let data = try ZData(contentsOf:f.url! as URL)
                let mime = f.GetMimeTypeFromExtension()
                addAttachmentData(data as Data, mimeType:mime, fileName:(f.url?.path)!)
            } catch let error {
                ZDebug.Print("popDraft:", error)
            }
        }
        ZGetTopViewController()!.present(self, animated:true) { () in }
    }
}
    
private func getAddresses(_ addresses:[ZMail.Address]) -> [String] {
    var all = [String]()
    for a in addresses {
        all.append(a.address)
    }
    return all
}


