//
//  ZImageBox.swift
//  capsulefm
//
//  Created by Tor Langballe on /2/8/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import UIKit

class ZImageBox : ZContainerView {
    var nameBase = ""
    let imageActivity: ZActivityIndicator
    let imageView = ZImageView(zimage:nil, maxSize:ZSize(150, 150))
    var imageUrl = ""
    var deleteButton = ZImageView(namedImage:"cross.small.png")
    let addButton = ZImageView(namedImage:"add.small.png")
    let linkButton = ZImageView(namedImage:"link.small.png")
    var image: ZImage? = nil
    var scaleSize:ZSize? = nil
    
    init(image:ZImage?, url:String, showTools:Bool = true) {
        if image != nil {
            imageView.edited = true
        } else if url.isEmpty {
            imageView.SetImage(ZImage(named:"photo.png"))
        }
        imageActivity = ZActivityIndicator()

        super.init(name:"imagebox")

        minSize = ZSize(182, 182)
        imageUrl = url
        self.image = image
        imageView.contentMode = .scaleAspectFit
        SetCornerRadius(2)
        SetBackgroundColor(ZColor(white:0, a:0.4))

        imageView.AddTarget(self, forEventType:.pressed)
    
        Add(imageView, align:.HorCenter | .Top, marg:ZSize(16, 16))
        Add(imageActivity, align:.HorCenter | .Top, marg:ZSize(0, 4))

        if showTools {
            let h1 = ZHStackView(space:7)
            h1.Add(addButton, align:.Right | .Bottom)
            addButton.AddTarget(self, forEventType:.pressed)
            AddGestureTo(addButton, type:.longpress)
            
            h1.Add(linkButton, align:.Right | .Bottom)
            linkButton.AddTarget(self, forEventType:.pressed)

            h1.Add(deleteButton, align:.Left | .Bottom)
            deleteButton.AddTarget(self, forEventType:.pressed)
            Add(h1, align:.Right | .Bottom | .HorExpand | .NonProp, marg:ZSize(6, 4))
        }
        
        if image != nil {
            uploadImage(image!) { [weak self] (downloadUrl, error) in
                if error == nil {
                    self?.imageView.SetImage(image)
                    self?.imageUrl = downloadUrl
                    self?.valueTarget?.HandleValueChanged(self!)
                }
            }
        } else if !url.isEmpty {
            imageView.DownloadFromUrl(url)
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    fileprivate func uploadImage(_ image:ZImage, done:@escaping (_ downloadUrl:String, _ error:Error?)->Void) {
        if let data = UIImageJPEGRepresentation(image, 0.8) {
            imageActivity.Start()
            let name = nameBase +  ZTime.Now.GetIsoString(format:ZTime.IsoFormatCompact) + ".jpeg"
            cApp.b2.UploadFileToBucket(data, buckedId:"dcfcd1d546bc530d55590c12", bucketName:"cappubphoto", name:name) { (url, fileId, error) in
                self.imageActivity.Start(false)
                if error != nil {
                    ZAlert.ShowError("Error uploading image", error:error!)
                }
                done(url, error)
            }
        } else {
            done("", ZError(message:"Couldn't make image"))
        }
    }
    
    fileprivate func updateButtons() {
        deleteButton.Usable = (imageView.image != nil)
    }
    
    override func HandleGestureType(_ type: ZGestureType, view: ZView, pos: ZPos, delta: ZPos, state: ZGestureState, taps: Int, touches: Int, dir: ZAlignment, velocity: ZPos, gvalue: Float, name: String) -> Bool {
        if type == .longpress && state == .began && view.View() == addButton {
            takePhoto(library:false)
            return true
        }
        return false
    }
    
    func takePhoto(library:Bool) {
        ZPhotoPicker.TakePhotoAtTarget(addButton, library:library) { [weak self] (image) in
            var vimage = image
            if vimage != nil {
                if self?.scaleSize != nil {
                    vimage = vimage!.GetScaledInSize(self!.scaleSize!)
                    let r = ZRect(size:ZSize(vimage!.size)).Align(self!.scaleSize!, align:.Center)
                    vimage = vimage!.GetCropped(r)
                }
                self?.uploadImage(vimage!) { (downloadUrl, error) in
                    if error == nil {
                        self?.imageView.SetImage(vimage)
                        self?.imageUrl = downloadUrl
                    }
                }
            }
        }
    }
    
    override func HandlePressed(_ sender: ZView, pos: ZPos) {
        switch sender.View() {
            case deleteButton:
                imageUrl = ""
                imageView.SetImage(nil)
                return
            
            case addButton:
                takePhoto(library:true)
                return
            
            case linkButton:
                ZAlert.GetText(ZTS("set image url:"), content:imageUrl) { [weak self] (text, result) in
                    if result == .ok {
                        self?.imageUrl = text
                        self?.imageActivity.Start()
                        self?.imageView.DownloadFromUrl(text) { [weak self] (success) in
                            self?.imageActivity.Start(false)
                        }
                    }
                }
            
            default:
                break
        }
    }
}

