//
//  ZSpeech.swift
//  Zed
//
//  Created by Tor Langballe on /13/11/15.
//  Copyright © 2015 Capsule.fm. All rights reserved.
//

//let acaLicenseId = "\"606 0 Gn2B #COMMERCIAL#CAPSULE FM Germany\"\nWCGYVQV3zl2GSqfS5hGJ4BjuQ%noNxuQEBnEZykHR3U4L98ThQRS$ovt\nT6UAouRvW$YllB2gPqdQb@lpcoA6yq9Ms7B$RauljFYrA3l#\nWGuCaFK5hK7g5qNwIeQhqS##\n"
//let acaUserId:BB_U32 = 0x019290fb
//let acaPassword:BB_U32 = 0x001d32cd
let acaLicenseId = "\"7570 0 Gn2B #COMMERCIAL#CAPSULE FM Germany\"\nXOfuIiFu%!trcrA824ZomovLVjOda4WMzVfl!$ZEXViejVEDUOnIXZtdmR##\nRO5WOOdKf%ZV6GAFdZrwKIRLYoqEaoVVCsMXDrGRCNto65j#\nRO$WY@pdFuq53D!c5464aQ##\n"
let acaUserId:BB_U32 = 0x42326e47
let acaPassword:BB_U32 = 0x0031fb03

import AVFoundation

struct ZVoice
{
    var base = ZSpeechAttributes()
    var voiceId = ""
    var countryCode = ""
    var male = -1
};

protocol ZSpeechDelegate {
    func HandleSpeechDone(_ speech:ZSpeech)
}

class ZSpeech: ZObject, AVSpeechSynthesizerDelegate {
    static var speakingCount = 0
    var acaTTS: AcapelaSpeech
    var appleSynth: AVSpeechSynthesizer
    var acaLicense: AcapelaLicense
    var acaSetupData: AcapelaSetup
    var first = true
    var zdelegate:ZSpeechDelegate? = nil
    var rendering = false
    let lock = NSLock()
    
    init(folders:[ZFileUrl]) {
        appleSynth = AVSpeechSynthesizer()
        acaLicense = AcapelaLicense(license:acaLicenseId, user:acaUserId, passwd:acaPassword)
        ZSpeech.SetVoiceFolders(folders)
        acaSetupData = AcapelaSetup()
        acaSetupData.initialize()
        if acaSetupData.currentVoice != nil {
            acaTTS = AcapelaSpeech(voice:acaSetupData.currentVoice!, license:acaLicense)
        } else {
            acaTTS = AcapelaSpeech()
        }
        super.init()
        acaTTS.setDelegate(self)
        appleSynth.delegate = self
//        for v in AVSpeechSynthesisVoice.speechVoices() {
//            print("applevoice:", v.name, v.language)
//        }
    }
    
    deinit {
        //  [ acaSetupData release ];
        //  [ acaLicense release ];
        //  [ acaTTS release ];
        //  [ acaResponder release ];
    }
    
    func GetTextAudio(_ text:String, voice:ZVoice, volume:Float = 1, file:ZFileUrl, substitute:Bool = false) -> Error? {
        var vvoice = voice
        vvoice.base.type = .acapela
        if let error = setVoiceInfo(&vvoice, volume:volume, substitute:substitute) {
            return error
        }
        rendering = true;
        lock.lock()
        acaTTS.startSpeakingStringSync(text, to:file.url! as URL?)
        // returns false even when ok, so ignoring, check file exists instead.
        lock.unlock()
        rendering = false;
        if !file.Exists() {
            return ZError(message:"ZSpeech:GetTextAudio:No file created")
        }
        return nil
    }

    func RefreshVoices() {
        AcapelaSpeech.refreshVoiceList()
    }
    
    static func SetVoiceFolders(_ folders:[ZFileUrl]) {
        var folds = [String]()
        for f in folders {
            #if (arch(i386) || arch(x86_64)) && os(iOS) // hack to make SHORTER path names for simulator, was just over 255, test in iPhone too!
//            #if targetEnvironment(simulator) // hack to make SHORTER path names for simulator, was just over 255, test in iPhone too!
                let store = ZFolders.GetFileInFolderType(.preferences, addPath:"voicelinks")
                store.CreateFolder()
                let name = f.GetName()
                let nfolder = store.AppendedPath(name)
                if !nfolder.Exists() {
                    f.CopyTo(nfolder)
                }
                folds.append(nfolder.url!.path)
            #else
                folds.append(f.url!.path)
            #endif
        }
        AcapelaSpeech.setVoicesDirectoryArray(folds)
    }

    @discardableResult func Say(_ str:String, voiceName:String, volume:Float = 1, done:(()->Void)? = nil) -> Bool {
        if let v = GetVoiceForName(voiceName) {
            return Say(str, voice:v, volume:volume, done:done)
        }
        return false
    }
    
    @discardableResult func Say(_ str:String, voice:ZVoice, volume:Float = 1, substitute:Bool = false, done:(()->Void)? = nil) -> Bool {
        var vvoice = voice
        if  setVoiceInfo(&vvoice, volume:volume, substitute:substitute) != nil {
            return false
        }
        if voice.base.type == .acapela {
            var ok = acaTTS.setVoice(voice.voiceId)
            if !ok {
                ZDebug.Print("ZSpeech::Say: failed setVoice:\(voice.voiceId)/\(vvoice.base.name)")
                return false
            }
            ZSpeech.speakingCount += 1;
            //            acaTTS.setVolume(volume)
            lock.lock()
            ok = acaTTS.startSpeaking(str)
            lock.unlock()
            return ok
        }
        if voice.base.type == .apple {
            let utterance = AVSpeechUtterance(string:str)
            utterance.voice = AVSpeechSynthesisVoice(identifier:voice.voiceId)
            utterance.volume = volume
            print("utterance rate, pitchMult:", utterance.rate, utterance.pitchMultiplier, voice.base.pitch)
            utterance.rate /= voice.base.speed
            utterance.pitchMultiplier = voice.base.pitch
            appleSynth.speak(utterance)
            return true
        }
        return false
    }
    
    func GetVoiceForName(_ name:String) -> ZVoice? {
        let voices = GetVoices()
        for v in voices where v.base.name == name {
            return v
        }
        return nil
    }
    
    func mapLocale(_ bcpCode:String) -> (String, String) {
        var (lang, ccode) = ZLocale.GetLangCodeAndCountryFromLocaleId(bcpCode)
        if lang == "nb" || lang == "nn" {
            lang = "no"
        }
        ccode = ccode.lowercased()
        if ccode == "gb" {
            ccode = "uk"
            lang = "uk"
        }
        return (lang, ccode)
    }
    
    func GetVoices() -> [ZVoice] {
        var voices = [ZVoice]()
        for v in AcapelaSpeech.availableVoices() as! [String] {
            var voice = ZVoice()
            if let att = AcapelaSpeech.attributes(forVoice: v) {
                voice.base.name = att[AcapelaVoiceName] as! String
                voice.voiceId = att[AcapelaVoiceIdentifier] as! String
                let locale = att[AcapelaVoiceLocaleIdentifier] as! String
                (voice.base.langCode, voice.countryCode) = mapLocale(locale)
                let gender = att[AcapelaVoiceGender] as! String
                if(gender == AcapelaVoiceGenderMale) {
                    voice.male = 1;
                } else if(gender == AcapelaVoiceGenderFemale) {
                    voice.male = 0;
                }
                voice.base.type = .acapela
                voices.append(voice)
            }
            //    ZDebugStr("voice: " + v.name + "\t" + v.voiceid + "\t" + v.langCode);
        }
        for v in AVSpeechSynthesisVoice.speechVoices() {
            let locale = v.language
            var voice = ZVoice()
            (voice.base.langCode, voice.countryCode) = mapLocale(locale)
            voice.voiceId = v.identifier
            voice.base.name = v.name
            voice.base.type = .apple
            voices.append(voice)
        }
        return voices
    }
    
    func setVoiceInfo(_ voice:inout ZVoice, volume:Float, substitute:Bool = false) -> Error? {
        let voices = GetVoices()
        var sameLangVoice = ZVoice()
        for v in voices where v.base.type == voice.base.type {
            if (!voice.voiceId.isEmpty && v.voiceId == voice.voiceId) || v.base.name == voice.base.name {
                voice.voiceId = v.voiceId
                voice.base.type = v.base.type
                switch voice.base.type {
                    case .acapela:
                        if !acaTTS.setVoice(voice.voiceId) {
                            return ZError(message:"ZSpeech setVoice error for:" + voice.base.name)
                        }
                        acaTTS.setVolume(volume * 100)
                        acaTTS.setRate(acaTTS.rate() * voice.base.speed)
                        acaTTS.setVoiceShaping(Int32(voice.base.pitch * Float(100)))
                        return nil
                    
                    case .apple:
                        // apple speech synth sets up utterance at say
                        return nil
                    
                    default:
                        break
                }
            } else {
                if v.base.langCode == voice.base.langCode {
                    sameLangVoice = v
                }
            }
        }
        if substitute && !sameLangVoice.base.name.isEmpty {
            voice = sameLangVoice
            return setVoiceInfo(&voice, volume:volume, substitute:false)
        }
        return ZError(message:"ZSpeech setVoice: voice not found: " + voice.base.name)
    }
    
    func StopSpeaking() {
        if acaTTS.isSpeaking() {
            if !rendering {
                acaTTS.stopSpeaking()
            } else {
                //       SetTimer(200, T_STOP);
            }
        }
        if appleSynth.isSpeaking {
            appleSynth.stopSpeaking(at: AVSpeechBoundary.word)
        }
    }
    
    func PauseSpeaking() {
        if appleSynth.isSpeaking {
            appleSynth.pauseSpeaking(at: AVSpeechBoundary.word)
        }
    }
    
    func IsSpeaking() -> Bool {
        if appleSynth.isSpeaking {
            return true
        }
        return acaTTS.isSpeaking()
    }
    
    override func speechSynthesizer(_ speech:AcapelaSpeech, didFinishSpeaking:Bool) {
        ZMainQue.async { () in
            ZSpeech.speakingCount -= 1
            if ZSpeech.speakingCount > 0 {
                ZDebug.Print("Finished speaking")
                self.zdelegate?.HandleSpeechDone(self)
            }
        }
    }
    
    override func speechSynthesizer(_ speech:AcapelaSpeech, willSpeakWord:NSRange, of ofString:String) {
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.zdelegate?.HandleSpeechDone(self)        
    }
}

var mainSpeech: ZSpeech? = nil

/*
 ar-SA, Name: Maged
 cs-CZ, Name: Zuzana
 da-DK, Name: Sara
 de-DE, Name: Anna
 el-GR, Name: Melina
 en-AU, Name: Karen
 en-GB, Name: Daniel
 en-IE, Name: Moira
 en-US, Name: Samantha
 en-ZA, Name: Tessa
 es-ES, Name: Monica
 es-MX, Name: Paulina
 fi-FI, Name: Satu
 fr-CA, Name: Amelie
 fr-FR, Name: Thomas
 he-IL, Name: Carmit
 hi-IN, Name: Lekha
 hu-HU, Name: Mariska
 id-ID, Name: Damayanti
 it-IT, Name: Alice
 ja-JP, Name: Kyoko
 ko-KR, Name: Yuna
 nl-BE, Name: Ellen
 nl-NL, Name: Xander
 no-NO, Name: Nora
 pl-PL, Name: Zosia
 pt-BR, Name: Luciana
 pt-PT, Name: Joana
 ro-RO, Name: Ioana
 ru-RU, Name: Milena
 sk-SK, Name: Laura
 sv-SE, Name: Alva
 th-TH, Name: Kanya
 tr-TR, Name: Yelda
 zh-CN, Name: Ting-Ting, Quality
 zh-HK, Name: Sin-Ji, Quality
 zh-TW, Name: Mei-Jia, Quality
*/

