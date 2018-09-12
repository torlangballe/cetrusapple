//
//  ZSocial.swift
//  capsulefm
//
//  Created by Tor Langballe on /8/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import MessageUI
import Social

enum ZSocialType { case none, twitter, facebook, message, email }

class ZSocial {
    struct Post {
        var text = ""
        var subject = ""
        var to = ""
        var surl = ""
        var image: ZImage? = nil
    }
    
    static func GetTypeName(_ type:ZSocialType) -> String {

        switch type {
            case .twitter:
                return "twitter"
            case .facebook:
                return "facebook"
            case .message:
                return "message"
            case .email:
                return "email"
            default:
                return ""
        }
    }

    static func GetTypeFromName(_ name:String) -> ZSocialType {
        
        switch name {
        case "twitter":
            return .twitter
        case "facebook":
            return .facebook
        case "message":
            return .message
        case "email":
            return .email
        default:
            return .none
        }
    }

    static func ComposePostingToSend(_ type:ZSocialType, post:Post, done:@escaping (_ sent:Bool) -> Void) {
        var str = post.subject.isEmpty ? post.text : post.subject
        switch type {
        case .email:
                let mail = ZMail()
                mail.subject = str
                mail.body = post.surl
                ZMailComposer().PopDraft(mail) { (sent) in
                    done(sent)
                }
            case .message:
                let m = MessageView()
                str = ZStr.ConcatNonEmpty(sep:" ", items:[str, post.surl])
                m.Send(str, done:done)


//            case .facebook:
//                shareWithFacebook(post, done:done)

            default:
                let socialSheet = SLComposeViewController(forServiceType:getSLServiceFromType(type))
                socialSheet?.setInitialText(str)
                if post.image != nil {
                    socialSheet?.add(post.image)
                }
                if !post.surl.isEmpty {
                    socialSheet?.add(URL(string:post.surl))
                }
                socialSheet?.completionHandler = { (result) in
                    done(result == .done)
                }
                ZGetTopViewController()!.present(socialSheet!, animated:true, completion:nil)
        }
    }


    static func IsServiceAvailable(_ type:ZSocialType) -> Bool {
        if type == .message {
            return MFMessageComposeViewController.canSendText()
        }
    
        if(type == .facebook) {
            let t = FBSDKAccessToken.current()
            return t != nil
        }
        return SLComposeViewController.isAvailable(forServiceType: getSLServiceFromType(type))
    }
}

class MessageView : MFMessageComposeViewController, MFMessageComposeViewControllerDelegate {

    var done:((_ sent:Bool) -> Void)? = nil
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion:nil)
        done?(result == MessageComposeResult.sent)
    }

    func Send(_ str:String, done:@escaping (_ sent:Bool) -> Void) {
        if MFMessageComposeViewController.canSendText() {
            self.done = done
            self.body = str
            self.messageComposeDelegate = self
            //ZDoInFuture:
            ZGetTopViewController()!.present(self, animated:true, completion:nil)
        }
    }
}

private func getSLServiceFromType(_ type:ZSocialType) -> String {
    switch type {
        case .twitter:
            return SLServiceTypeTwitter
        case .facebook:
            return SLServiceTypeFacebook
        default:
            return ""
    }
}
/*
private func shareWithFacebook(_ post:ZSocial.Post, done:((_ sent:Bool) -> Void)?) {

    let content = FBSDKShareLinkContent()

    //    content.contentTitle = post.text // doesn't add anything...
    //    content.contentDescription = post.text // doesn't add anything...
    
    if !post.surl.isEmpty {
        content.contentURL = URL(string:post.surl)
        ZDebug.Print("shareWithFacebook URL: ", post.surl);
    }
    let v = ZGetTopViewController() as! ZViewController
    v.facebookShareDone = done
    FBSDKShareDialog.show(from: v,  with:content, delegate:v)
}
*/


