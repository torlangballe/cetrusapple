//
//  ZAudio.swift
//  Zed
//
//  Created by Tor Langballe on /20/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

import AVFoundation
import MediaPlayer

struct ZMediaItem {
    enum MediaType:Int { case none = 0, audio = 1, speech = 2 }
    var background = false
    var type = MediaType.none
    var local = true   // if !local it's a streaming track for audio. for speech it's a VaaS TTS, with link in url and actual text in spokenText
    var url = ""   // stream or jingle or background. In capsule.fm, "provider" from parent story might be used to authenticate stream if it's spotify etc
    var text = ""
    var start = ZAudioAttributes()
    var end = ZAudioAttributes()
    var voice = ZSpeechAttributes()
    var loops = 1
    var service = ""
    var label = ""
    var id = 0
    
    var calculatedDuration = 0.0 // convenience variable, stores calculated duration
    var processedText = ""       // convenience variable, stores text after processed for last minute changes (macros etc)
    var authenticatedUrl = ""    // calculated at GetNext
    var error = ""     
    
    func GetTemporaryTextRenderFolder() -> ZFileUrl {
        let folder = ZFolders.GetFileInFolderType(.temporary, addPath:"RenderedText")
        if !folder.Exists() {
            folder.CreateFolder()
        }
        return folder
    }
    
    mutating func RenderTextToTemporary() -> Error? {
        var voice = ZVoice()
        voice.base = self.voice
        let hash = "\(voice.base.name) \(voice.base.speed) \(voice.base.pitch) \(voice.base.langCode) \(voice.base.type) \(text)".hashValue
        let name = voice.base.name + ZFileUrl.GetLegalFilename(ZStrUtil.Head(text, chars:40)) + "-" + String(abs(hash)) + ".aiff"
        let outFile = GetTemporaryTextRenderFolder().AppendedPath(name, isDir:false)
        voice.base = self.voice
        if !outFile.Exists() || text != processedText {
            if let error = mainSpeech!.GetTextAudio(self.processedText, voice:voice, file:outFile, substitute:true) {
                return error
            }
        }
        assert(outFile.Exists())
        url = String(describing: outFile.url!)
        assert(!url.isEmpty)
        return nil
    }
    
    func Marshal() -> ZJSON {
        var  json = ZJSON.JDict()
        json["type"] = ZJSON(type == .speech ? "speech" : type == .audio ? "audio" : "none")
        json["background"] = JSON(background)
        json["local"] = JSON(local)
        json["url"] = JSON(url)
        json["text"] = JSON(text)
        json["start"] = start.Marshal()
        json["end"] = end.Marshal()
        json["voice"] = voice.Marshal()
        json["loops"] = ZJSON(loops)
        json["service"] = JSON(service)
        json["label"] = JSON(label)
        json["id"] = JSON(id)
        return json
    }

    mutating func Unmarshal(_ json:ZJSON) {
        switch json["type"] {
        case "speech":
            type = .speech
        case "audio":
            type = .audio
        default:
            type = .none
        }
        background = json["background"].boolValue
        local = json["local"].boolValue
        url = json["url"].stringValue
        text = json["text"].stringValue
        start.Marshal(json["start"])
        end.Marshal(json["end"])
        if type == .speech {
            voice.Marshal(json["voice"])
        }
        loops = json["loops"].intValue
        service = json["service"].stringValue
        label = json["label"].stringValue
        id = json["label"].intValue
    }
}

struct ZSpeechAttributes {
    enum SpeechType: Int { case none = 0, acapela = 1, apple = 2 }
    var type:SpeechType = .acapela
    var name = ""
    var speed = Float(1) // 1 is normal for voice
    var pitch = Float(1) // 1 is normal for voice
    var langCode = ""

    func Marshal() -> ZJSON {
        var  json = ZJSON.JDict()
        json["type"] = ZJSON(type == .acapela ? "acapela" : type == .apple ? "apple" : "none")
        json["name"] = JSON(name)
        json["speed"] = JSON(speed)
        json["pitch"] = JSON(pitch)
        json["langcode"] = JSON(langCode)
        return json
    }
    
    mutating func Marshal(_ json:ZJSON) {
        switch json["type"] {
        case "acapela":
            type = .acapela
        case "apple":
            type = .apple
        default:
            type = .none
            
        }
        name = json["name"].stringValue
        langCode = json["langcode"].stringValue
        speed = json["speed"].floatValue
        pitch = json["pitch"].floatValue
    }
}

struct ZAudioAttributes {
    var volume = Float(1)     // 0 - 1 or more than one perhaps for more volume
    var azimuth = Float(0)    // degrees -180 + 180
    var distance = 0.0        // meters 0 - 10000
    var elevation = 0.0       // +/- 90 degrees
    var fadeSecs = 0.0        // seconds of fade of start / end of part AFTER cropping
    var cropSecs = 0.0        // how many seconds to crop from start/end of entire track
    var overlapSecs = 0.0     // Negative value is pause at start or space at end
    var absPosSecs = 0.0      // This in convenience, position of start/end of mediaItem after layed out

    func Marshal() -> ZJSON {
        var  json = ZJSON.JDict()
        json["volume"] = JSON(volume)
        json["azimuth"] = JSON(azimuth)
        json["distance"] = JSON(distance)
        json["elevation"] = JSON(elevation)
        json["fadeSecs"] = JSON(fadeSecs)
        json["cropSecs"] = JSON(cropSecs)
        json["overlapSecs"] = JSON(overlapSecs)
        json["absPosSecs"] = JSON(absPosSecs)
        return json
    }
    
    mutating func Marshal(_ json:ZJSON) {
        volume = json["volume"].floatValue
        azimuth = json["azimuth"].floatValue
        distance = json["distance"].doubleValue
        elevation = json["elevation"].doubleValue
        fadeSecs = json["fadeSecs"].doubleValue
        cropSecs = json["cropSecs"].doubleValue
        overlapSecs = json["overlapSecs"].doubleValue
        absPosSecs = json["absPosSecs"].doubleValue
    }
}

struct ZSoundRange { // this is NOT part of ZMediaItem
    
    var start:Double
    var end:Double
    
    init(start:Double = 0, end:Double = 0) {
        self.start = start
        self.end = end
    }
    
    var Length: Double {
        get { return end - start }
    }
}

