//
//  ZCues.swift
//  cetrus
//
//  Created by Tor Langballe on /23/3/18.
//

import Foundation

let lineSecs = 2.0
let lineWidth = 300
let speechBlock = 10.0

private struct Chunk {
    var pos = 0.0
    var file = ZFileUrl()
    var index = 0
}

struct ZCue : Codable, Equatable {
    private enum CodingKeys: String, CodingKey { case type, start, end, value, subvalue }
    enum CueType:String { case inlineSpeech = "inspeech", inlineTitle = "intitle", inlineImageUrl = "inimageurl", audioRange = "audiorange", chapter = "chapter", audioLine = "audioline", parentUrl = "parenturl" }
    
    var type = ""
    var start = 0.0
    var end = 0.0
    var value:String? = nil
    var subvalue:String? = nil
    var image:ZImage? = nil
    
    var intSamples100 = [Int]()
    
    var Duration:Double {
        return end - start
    }

    static func ==(lhs: ZCue, rhs: ZCue) -> Bool {
        return lhs.type == rhs.type && lhs.start == rhs.start && lhs.end == rhs.end
    }
    
    func IsSuperior(cue:ZCue) -> Bool {
        if self.type == ZCue.CueType.inlineSpeech.rawValue && cue.type == ZCue.CueType.audioLine.rawValue {
            if start <= cue.end && end >= cue.start {
                return true
            }
        }
        return false
    }
}

class ZCues {
    var downloadedAt = ZTime()
    var langCode = ""
    var list = [ZCue]()
    
    func AddFromAudioFile(file:ZFileUrl, langCode:String, got:@escaping (_ error:Error?)->Void) {
        ZGetBackgroundQue().async { [weak self] () in
            var err:Error? = nil
            if let e = self?.addChaptersFromAudioFile(file:file, langCode:langCode) {
                err = e
            }
            if let e = self?.addAudioLinesFromAudioFile(file:file) {
                err = e
            }
            self?.list.sort { $0.start < $1.start }
            ZMainQue.async {
                got(err)
            }
        }
    }
    
    private func GetLength() -> Double? {
        for c in list where c.type == ZCue.CueType.audioRange.rawValue {
            if c.start > 0 {
                return nil
            }
            return c.end
        }
        return nil
    }
    
    func Merge(_ cues:[ZCue], save:Bool) {
        if !cues.isEmpty {
            var merged = list
            merged.removeIf { cues.contains($0) }
            for c in cues {
                merged.removeIf { c.IsSuperior(cue:$0)}
            }
            merged += cues
            merged.sort { $0.start < $1.start }
            list = merged
        }
    }
    
    private func addChaptersFromAudioFile(file:ZFileUrl, langCode:String) -> Error? {
        var cues = [ZCue]()
        let asset = AVAsset(url:file.url!)
        let code = ZLocale.GetBCPFromLanguageAndCountryCode(langCode:langCode, countryCode:"")
        let metaGroups = asset.chapterMetadataGroups(bestMatchingPreferredLanguages:[code, "und"])
        
        for group in metaGroups {
            var cue = ZCue()
            cue.start = CMTimeGetSeconds(group.timeRange.start)
            cue.end = CMTimeGetSeconds(group.timeRange.end)
            cue.type = ZCue.CueType.chapter.rawValue
            for m in group.items where m.identifier != nil {
                switch m.identifier! {
                case AVMetadataIdentifier.id3MetadataUserURL:
                    if cue.subvalue == nil {
                        cue.subvalue = m.stringValue ?? ""
                    }
                    
                case AVMetadataIdentifier.id3MetadataTitleDescription:
                    if cue.value == nil {
                        cue.value = m.stringValue ?? ""
                    }
                    
                case AVMetadataIdentifier.id3MetadataAttachedPicture:
                    if cue.image == nil && m.dataValue != nil {
                        cue.image = ZImage(data:m.dataValue!)
                    }
                    
                default:
                    break
                }
            }
            if cue.value != nil {
                cues.append(cue)
            }
        }
        Merge(cues, save:true)
        return nil
    }
    
    func negSqrt(_ a:Float) -> Float {
        return sqrt(abs(a)) * sign(a)
    }
    
    private func addAudioLinesFromAudioFile(file:ZFileUrl) -> Error? {
        var cues = [ZCue]()
        let chunkSecs = lineSecs / Double(lineWidth)
        var samples = [Float]()
        let err = ZReadAudioFileMonoSecondChunks(file:file, secs:chunkSecs) { s, pos in
            samples.append(s[0])
        }
        if err != nil {
            return err
        }
        var max:Float = 0.0
        for s in samples {
            maximize(&max, s)
        }
        for (i, _) in samples.enumerated() {
            samples[i] = negSqrt(samples[i] / max)
        }
        var duration = 0.0
        if GetLength() == nil {
            (duration, _, _) = ZAudioFileGetInfo(file:file)
            if duration != 0 {
                var cue = ZCue()
                cue.type = ZCue.CueType.audioRange.rawValue
                cue.end = duration
                cues.append(cue)
            }
        }
        print("addAudioLinesFromAudioFile:", samples.count, lineSecs, duration)
        var pos = 0.0
        var i = 0
        var array = [Int]()
        while pos < duration {
            let v = samples[i]
            let n = Int(v * 100)
            array.append(n)
            i += 1
            if array.count == lineWidth || i >= samples.count {
                var cue = ZCue()
                cue.type = ZCue.CueType.audioLine.rawValue
                cue.start = pos
                cue.end = pos + lineSecs
                cue.intSamples100 = array
                //                print("array:", array[0 ..< 30])
                array.removeAll()
                cues.append(cue)
                pos += lineSecs
            }
        }
        Merge(cues, save:true)
        
        return nil
    }
    
    private func addCue(_ concated:inout [ZCue], pos:Double, add:inout ZCue, threshold:inout Double) {
        var c = add
        c.start += pos
        c.end += pos
        concated.append(c)
        add.start = 0
        add.value = ""
        add.end = 0
        threshold += lineSecs
    }
    
    private func appendOneCue(add:inout ZCue, c:ZCue) {
        add.end = c.end
        add.value = ZStrUtil.ConcatNonEmpty(items:add.value!, c.value!)
    }
    
    private func concatSpeech(cues:[ZCue], chunk:Chunk) -> [ZCue] {
        var add = ZCue()
        var concated = [ZCue]()
        var threshold = lineSecs
        
        add.value = ""
        add.subvalue = "\(chunk.index)"
        add.type = ZCue.CueType.inlineSpeech.rawValue
        
        for c in cues {
            if add.start == 0 {
                add.start = c.start
                add.value = c.value
            } else {
                if c.end >= threshold {
                    if c.end > threshold + 0.3 {
                        addCue(&concated, pos:chunk.pos, add:&add, threshold:&threshold)
                        appendOneCue(add:&add, c:c)
                    } else {
                        appendOneCue(add:&add, c:c)
                        addCue(&concated, pos:chunk.pos, add:&add, threshold:&threshold)
                    }
                } else {
                    appendOneCue(add:&add, c:c)
                }
            }
        }
        if add.start > 0 {
            addCue(&concated, pos:chunk.pos, add:&add, threshold:&threshold)
        }
        return concated
    }
    
    private func setNewSpeechCues(cues:[ZCue], chunk:Chunk, originalUrl:String) {
        var truncated =  cues
        if chunk.index != 0 {
            truncated.removeIf { $0.end < chunk.pos + 1 }
        }
        let concated = concatSpeech(cues:cues, chunk:chunk)
        Merge(concated, save:true)
        PodcastPlayView.current?.SetNewCues(list, mediaUrl:originalUrl)
        mainSync.AppendStoryCues(audioUrl:originalUrl, cues:concated) { error in
            if error != nil {
                ZDebug.Print("setNewSpeechCue err:", error!.localizedDescription)
            }
        }
    }
    
    private func speechToTextForChunk(chunk:Chunk, originalUrl:String, done:@escaping ()->Void) {
        let rec = ZSpeechRecognizer()
        let loc = ZLocale.GetBCPFromLanguageAndCountryCode(langCode:langCode, countryCode:"")
        
        rec.RecognizeFromFile(file:chunk.file, locale:loc) { [weak self] (state, cues, error) in
            if error != nil {
                ZDebug.Print("speechToTextForChunk rec err: ", error!.localizedDescription, originalUrl)
            } else {
                self?.setNewSpeechCues(cues:cues, chunk:chunk, originalUrl:originalUrl)
            }
            done()
        }
    }
    
    
    private func trySpeechToText(chunks:inout [Chunk], originalUrl:String) {
        let waitGroup = DispatchGroup()
        waitGroup.enter()
        var useChunks = chunks
        var best = chunks.first!
        var index = -1
        mainSync.GetStoryCues(audioUrl:originalUrl) { [weak self] (cloudCues, modified, error) in
            if self != nil {
                self!.Merge(cloudCues, save:true)
                let cues = self!.list
                useChunks.removeIf {
                    for c in cues where c.type == ZCue.CueType.inlineSpeech.rawValue {
                        if c.start <= $0.pos + speechBlock - 1 && c.end >= $0.pos + 1 {
                            return true
                        }
                    }
                    return false
                }
                if PodcastPlayView.current?.mediaUrl == originalUrl {
                    let pos = PodcastPlayView.current!.currentSecs + 10
                    for (i, c) in useChunks.enumerated() {
                        if abs(c.pos - pos) < abs(best.pos - pos) {
                            best = c
                            index = i
                        }
                    }
                }
                best.index = index
                self!.speechToTextForChunk(chunk:best, originalUrl:originalUrl) { () in
                    waitGroup.leave()
                }
            } else {
                waitGroup.leave()
            }
        }
        if waitGroup.wait(timeout: ZDispatchTimeInSecs(1000)) == .timedOut {
            ZDebug.Print("trySpeechToText timeout: ", originalUrl)
        }
        if index != -1 {
            chunks.remove(at:index)
        }
    }
    
    func addSpeechFromAudioFileInBackground(file:ZFileUrl, originalUrl:String) {
        if #available(iOS 11.0, *) {
            ZSpeechRecognizer.RequestToUse() { (accepted) in
                if !accepted {
                    return
                }
                if ZSpeechRecognizer.limiter.IsExceded() {
                    ZDebug.Print("ZCues.addSpeechFromAudioFileInBackground: rate limited (\(ZSpeechRecognizer.limiter.max))")
                    return
                }
                ZGetBackgroundQue().async { [weak self] () in
                    let name = ZFileUrl.GetLegalFilename(originalUrl)
                    let folder = ZFolders.GetFileInFolderType(.temporary, addPath:name)
                    folder.CreateFolder()
                    var (_, sampleRate, err) = ZAudioFileGetInfo(file:file)
                    if err == nil {
                        var chunks = [Chunk]()
                        var tailSecond = [Float]()
                        err = ZReadAudioFileMonoSecondChunks(file:file, secs:speechBlock) { samples, pos in
                            var chunk = Chunk()
                            chunk.pos = pos
                            chunk.file = folder.AppendedPath("\(pos).aiff")
                            if tailSecond.count > 0 {
                                chunk.pos -= 1
                            }
                            let array = tailSecond + samples
                            if !chunk.file.Exists() {
                                let err = ZWriteAudioSamplesToAiffFile(toFile:chunk.file, samples:array, sampleRate:sampleRate, channels:1)
                                if err != nil {
                                    ZDebug.Print("addSpeechFromAudioFileInBackground write err:", err!.localizedDescription)
                                    return // skips this closure
                                }
                            }
                            tailSecond = Array(samples[max(0, samples.count - sampleRate) ..< samples.count])
                            chunks.append(chunk)
                        }
                        if err != nil {
                            ZDebug.Print("addSpeechFromAudioFileInBackground readFileChunk err:", err!.localizedDescription)
                        }
                        while PodcastPlayView.current?.mediaUrl == originalUrl {
                            self?.trySpeechToText(chunks:&chunks, originalUrl:originalUrl)
                        }
                    }
                    if err != nil {
                        ZDebug.Print("addSpeechFromAudioFileInBackground get file info err:", err!.localizedDescription)
                    }
                }
            }
        }
    }
}

class ZAllCues : ZUrlCache {
    var map = [String:ZCues]()
    let initMutex = ZMutex()
    
    init(folderName:String = "zcues") {
        super.init(name:folderName)
    }
    
    func LoadFromFolder() {
        initMutex.Lock()
        ZGetBackgroundQue().async { [weak self] () in
            self?.folder.Walk { [weak self] file, info in
                if let data = ZJSONData(fileUrl:file) {
                    let cs = ZCues()
                    let err = data.Decode(&cs.list)
                    if err != nil {
                        ZDebug.Print("ZCues.LoadFromFolder err:", err!.localizedDescription, file.AbsString)
                    } else {
                        var url = ""
                        for c in cs.list {
                            if c.type == ZCue.CueType.parentUrl.rawValue {
                                url = c.value ?? ""
                            }
                        }
                        if !url.isEmpty {
                            self!.map[url] = cs
                        }
                    }
                }
                return true
            }
            self?.initMutex.Unlock()
        }
    }
    
    func getCapsuleCueUrlForMediaUrl(mediaUrl:String) -> (String, Error?) {
        return ("", nil)
    }
    
    func GetForSequence(_ seq:Sequence, got:@escaping (_ cues:ZCues, _ mediaUrl:String, _ error:Error?)->Void) {
        var cues = ZCues()
        guard let url = seq.GetMediaUrl() else {
            got(cues, "", ZError(message:"no media url"))
            return
        }
        var cachedUrlFile = ZFileUrl()
        if !cApp.download.cache.HasFile(url, file:&cachedUrlFile) { // note it is cApp.download.cache, not self, that is also a cache
            got(cues, url, nil)
            return
        }
        if let c = map[url] {
            cues = c
            cues.addSpeechFromAudioFileInBackground(file:cachedUrlFile, originalUrl:url)
            got(cues, url, nil)
        } else {
            mainSync.GetStoryCues(audioUrl:url) { [weak self] cloudCues, modified, error in
                cues.list = cloudCues
                cues.langCode = seq.langCode
                self?.map[url] = cues // maybe we need to anchor it here, so it doesn't deinit
                cues.AddFromAudioFile(file:cachedUrlFile, langCode:cues.langCode) { [weak self] err in
                    self?.map[url] = cues
                    cues.addSpeechFromAudioFileInBackground(file:cachedUrlFile, originalUrl:url)
                    got(cues, url, err)
                }
            }
        }
    }
}


