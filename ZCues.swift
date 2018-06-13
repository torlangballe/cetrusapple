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

class ZCues : Encodable {
    private enum CodingKeys: String, CodingKey { case langCode, list }
    var downloadedAt = ZTime()
    var langCode = ""
    var file = ZFileUrl()
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
    
    func appendCue(c:ZCue, add:ZCue) -> ZCue {
        var n = c
        if add.start > c.start {
            n.end = add.end
            n.value = (c.value ?? "") + " " + (add.value ?? "")
        } else {
            n.start = add.start
            n.value = (add.value ?? "") + " " + (c.value ?? "")
        }
        return n
    }
    
    func Merge(_ cues:[ZCue]) {
        if !cues.isEmpty {
            var merged = list
            merged.removeIf { cues.contains($0) }
            for c in cues {
                merged.removeIf { c.IsSuperior(cue:$0)}
            }
            let separate = cues.filter {
                for (i, m) in merged.enumerated() {
                    if m.type == $0.type && $0.start < m.end && $0.end > m.start {
                        merged[i] = appendCue(c:m, add:$0)
                        return false
                    }
                }
                return true
            }
            merged += separate
            merged.sort { $0.start < $1.start }
            list = merged
            let err = save()
            if err != nil {
                ZDebug.Print("ZCues.Merge save")
            }
        }
    }
    
    private func save() -> Error? {
//        let data = ZJSONData(object:self)
//        let err = data.SaveToFile(file)
//        return err
        return nil
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
        Merge(cues)
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
        Merge(cues)
        
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
                    addCue(&concated, pos:chunk.pos, add:&add, threshold:&threshold)
                    add.start = c.start
                    appendOneCue(add:&add, c:c)
                } else {
                    appendOneCue(add:&add, c:c)
                }
            }
        }
        if add.start > 0 {
            addCue(&concated, pos:chunk.pos, add:&add, threshold:&threshold)
        }
        for c in concated {
            print("cat:", chunk.index, chunk.pos, ":", c.start, c.value ?? "", c.end)
        }
        return concated
    }

    private func adjustReturnRemoved(_ cues:inout [ZCue], j:Int, i:Int, removed:inout Bool) -> Bool {
        if cues[j].value != nil && cues[i].value != nil {
            let vj = cues[j].value!
            let vi = cues[i].value!
            if vi.count < 30 && vj.count > vi.count * 3 / 2 {
                let word = (j < i) ? ZStrUtil.PopTailWord(&cues[j].value!) : ZStrUtil.PopHeadWord(&cues[j].value!)
                cues[i].value = (j < i) ? word + " " + vi : vi + " " + word
                if cues[j].value!.isEmpty {
                    cues.remove(at:j)
                    removed = true
                }
                return true
            }
        }
        return false
    }
    
    private func adjustLengthOfSpeechCues() -> Bool {
        var changed = false
        var cues = list
        var pi:Int? = nil
        for (i, c) in cues.enumerated() {
            if c.type == ZCue.CueType.inlineSpeech.rawValue {
                if pi != nil {
                    var removed = false
                    if adjustReturnRemoved(&cues, j:pi!, i:i, removed:&removed) || adjustReturnRemoved(&cues, j:i, i:pi!, removed:&removed) {
                        changed = true
                    }
                    if removed {
                        list = cues
                        return true
                    }
                }
                pi = i
            }
        }
        list = cues
        return changed
    }

    private func setNewSpeechCues(cues:[ZCue], chunk:Chunk, originalUrl:String) {
        var truncated =  cues
        if chunk.index != 0 {
            truncated.removeIf { $0.end < 1 }
        }
        let concated = concatSpeech(cues:truncated, chunk:chunk)
        Merge(concated)
        var count = 0
        while count < 3 && adjustLengthOfSpeechCues() {
            count += 1
        }
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
                self!.Merge(cloudCues)
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
                        var cdiff = c.pos - pos
                        if cdiff < 0 {
                            cdiff += 5000 // if it's in past make it sort AFTER all ahead
                        }
                        if abs(cdiff) < abs(best.pos - pos) {
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
    
    func addSpeechFromAudioFileInBackground(audioFile:ZFileUrl, originalUrl:String) {
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
                    var (_, sampleRate, err) = ZAudioFileGetInfo(file:audioFile)
                    if err == nil {
                        var chunks = [Chunk]()
                        var tailSecond = [Float]()
                        err = ZReadAudioFileMonoSecondChunks(file:audioFile, secs:speechBlock) { samples, pos in
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

class ZAllCues {
    var map = [String:ZCues]()
    let initMutex = ZMutex()
    let cache = ZUrlCache(name:"zcues")
    
    func LoadFromFolder() {
        initMutex.Lock()
        ZGetBackgroundQue().async { [weak self] () in
            self?.cache.folder.Walk { file, info in
                if let data = ZJSONData(fileUrl:file) {
                    let cs = ZCues()
                    cs.file = file
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
    
    private func getCapsuleCueUrlForMediaUrl(mediaUrl:String) -> (String, Error?) {
        return ("", nil)
    }
    
    private func getLangCodeFromSequence(_ seq:Sequence) -> String {
        var lang = seq.langCode
        var host = ""
        for s in seq.stories {
            if s.externalLink.isEmpty {
                host = ZUrl(string:s.externalLink).Host
            }
        }
        if lang == "en" {
            lang = "us"
            if host.hasSuffix("co.uk") {
                lang = "uk"
            }
        }
        return lang
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
        var onFile = false
        if let c = map[url] {
            onFile = true
            cues = c
        } else {
            cues.file = cache.MakeFile(url:url)
        }
        mainSync.GetStoryCues(audioUrl:url) { [weak self] cloudCues, modified, error in
            cues.Merge(cloudCues)
            cues.langCode = self?.getLangCodeFromSequence(seq) ?? "en"
            self?.map[url] = cues // maybe we need to anchor it here, so it doesn't deinit
            if onFile {
                cues.addSpeechFromAudioFileInBackground(audioFile:cachedUrlFile, originalUrl:url)
                got(cues, url, nil)
            } else {
                cues.AddFromAudioFile(file:cachedUrlFile, langCode:cues.langCode) { err in
                    cues.addSpeechFromAudioFileInBackground(audioFile:cachedUrlFile, originalUrl:url)
                    got(cues, url, err)
                }
            }
        }
    }
}


