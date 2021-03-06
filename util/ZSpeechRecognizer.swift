//
//  ZSpeechRecognizer.swift
//  capsulefm
//
//  Created by Tor Langballe on /2/12/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation
import Speech
import Accelerate

// https://developer.apple.com/library/content/samplecode/SpeakToMe/Listings/SpeakToMe_ViewController_swift.html#//apple_ref/doc/uid/TP40017110-SpeakToMe_ViewController_swift-DontLinkElementID_6
// https://developer.apple.com/reference/speech/sfspeechaudiobufferrecognitionrequest

class ZSpeechRecognizer : NSObject, SFSpeechRecognizerDelegate {
    enum TaskHint : Int { case unspecified = 0, dictation, search, confirmation }
    enum State: Int { case final, intermediate }
    static let limiter = ZRateLimiter(max:1000, durationSecs:ZTimeHour)
    var recognizer: SFSpeechRecognizer? = nil
    var request: SFSpeechAudioBufferRecognitionRequest? = nil
    var task: SFSpeechRecognitionTask? = nil
    let audioEngine = AVAudioEngine()
    var sampleConsumerFunction: ((_ sample:Float32)->Void)? = nil
    var splitIntoWords = false
    
    static func RequestToUse(done:@escaping (_ accepted:Bool)->Void) {
        SFSpeechRecognizer.requestAuthorization() { (status) in
            ZMainQue.async {
                switch status {
                case .authorized:
                    done(true)
                case .denied, .restricted, .notDetermined:
                    done(false)
                }
            }
        }
    }
    
    static func SupportedLocalesAsBCPCodes() -> [String] {
        var out = [String]()
        for loc in SFSpeechRecognizer.supportedLocales() {
            out.append(loc.identifier)
        }
        return out
    }
    
    func RecognizeFromFile(file:ZFileUrl, locale:String, done:@escaping (_ state:State, _ cues:[ZCue], _ error:Error?)->Void) {
        var loc = locale
        if loc == "no-NO" {
            loc = "nb-NO"
        }
        if recognizer == nil {
            recognizer = SFSpeechRecognizer(locale:Locale(identifier:loc))
            recognizer?.delegate = self
        }
        let request = SFSpeechURLRecognitionRequest(url:file.url!)
        request.shouldReportPartialResults = false
        request.taskHint = .unspecified
        ZSpeechRecognizer.limiter.Add()
        let split = splitIntoWords // we need to store this, as self is actually nil when closure completes
        task = recognizer?.recognitionTask(with:request) { [weak self] (result, error) in
            var cues = [ZCue]()
            if error == nil {
                for s in result!.bestTranscription.segments {
                    if split {
                        cues += splitSegment(s)
                    } else {
                        var cue = ZCue()
                        cue.type = ZCue.CueType.inlineSpeech.rawValue
                        cue.start = s.timestamp
                        cue.end = s.timestamp + s.duration
                        cue.value = s.substring
                        cues.append(cue)
                    }
                }
            }
            if error != nil || (result != nil && result!.isFinal) {
                self?.Stop()
                done(.final, cues, error)
            } else if result != nil {
                done(.intermediate, cues, nil)
            }
        }
    }
    
    func StartRecognizing(partial:Bool = true, locale:String, hint:TaskHint = .dictation, contextId:String = "", knownWords:[String] = [], done:@escaping (_ state:State, _ texts:[String], _ error:Error?)->Void) {
        ZSpeechRecognizer.limiter.Add()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setMode(AVAudioSessionModeMeasurement)
            try session.setActive(true, with: .notifyOthersOnDeactivation)
        } catch let error {
            done(.final, [], error)
            return
        }
        if recognizer == nil {
            recognizer = SFSpeechRecognizer(locale:Locale(identifier:locale))
            recognizer?.delegate = self
        }
        request = SFSpeechAudioBufferRecognitionRequest()
        if request == nil {
            done(.final, [], ZNewError("Error creating SFSpeechAudioBufferRecognitionRequest"))
            return
        }
        /*
        switch hint {
            case .unspecified:
                request!.taskHint = .unspecified
            case .dictation:
                request!.taskHint = .dictation
            case .search:
                request!.taskHint = .search
            case .confirmation:
                request!.taskHint = .confirmation
        }
 */
        request!.shouldReportPartialResults = partial
        if contextId != "" {
            //!            request!.interactionIdentifier = contextId
        }
        //!        request!.contextualStrings = knownWords
        task = recognizer?.recognitionTask(with:request!) { [weak self] (result, error) in
            var texts = [String]()
            if error == nil {
                for t in result!.transcriptions {
                    print("speach text:", t.formattedString)
                    texts.append(t.formattedString)
                }
            }
            if error != nil || (result != nil && result!.isFinal) {
                self?.Stop()
                done(.final, texts, error)
            } else if result != nil {
                done(.intermediate, texts, nil)
            }
        }
        //        let recordingFormat = inputNode.outputFormat(forBus: 0)

        //        let recordingFormat =  AVAudioFormat(standardFormatWithSampleRate:44100, channels:2)

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch let error {
            done(.final, [], error)
            return
        }
/*
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.request?.append(buffer)
            
            if buffer.format.channelCount > 0 {
                let len = Int(buffer.frameLength)
                let channels = UnsafeBufferPointer(start:buffer.floatChannelData, count:Int(buffer.format.channelCount))
                let floats = UnsafeBufferPointer(start:channels[0], count:len)

                var sum:Float32 = 0
                for i in 0 ..< len {
                    sum += abs(floats[i])
                }
                sum /= Float32(len)
                self.sampleConsumerFunction?(sum)
            }
        }
         */
    }
  
    //    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // do something
    //    }
    
    func Stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning {
            audioEngine.stop()
            request?.endAudio()
        } else {
            request = nil
            task = nil
        }
    }
}

private func splitSegment(_ segment:SFTranscriptionSegment) -> [ZCue] {
    var cues = [ZCue]()
    let parts = segment.substring.split(separator:" ")
    let len = Double(parts.count)
    for (i, p) in parts.enumerated() {
        var cue = ZCue()
        cue.type = ZCue.CueType.inlineSpeech.rawValue
        cue.start = segment.timestamp + segment.duration * Double(i) / len
        cue.end = segment.timestamp + segment.duration * Double(i+1) / len
        cue.value = String(p)
        cues.append(cue)
        print("speech text:", cue.start, cue.value ?? "", cue.end)
    }
    return cues
}


