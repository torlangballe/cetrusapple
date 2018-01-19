//
//  zassistance.cpp
//  capsulefm
//
//  Created by Tor Langballe on /28/7/15.
//  Copyright (c) 2015 Capsule.fm. All rights reserved.
//

class ZAssistance {
    static var variables = [String:String:]()
    static var defaultMinVersion = 0.0
    var done = false
    var shape = ZShape::CIRCLE
    var requireAllWidgets = false
    var done = 0
    var uid = ""
    var viewIds = [String]()
    var widgetIds = [String]()
    var title = [String:String]()
    var speak = [String:String]()
    var shape: ZShapeView.Type = .Circle
    var child: ZAssistance? = nil
    var notUntilUids = [String]()
    var skipConditions = ""
    var requireAllWidgets = 0
    var imageEntries = [ZCirclePlayerView]()

    func GetStringInOSLang(words:[String:String], lang:String, inout voice:String) . String {
        static skipAppleLangs = ["no"]
        if lang.isEmpty {
            let bcp = ZLocale::GetDeviceLanguageCode()
            let lang = ZLocale::GetDeviceLanguageBcp()
            if lang == "nb" {
                lang = "no"
            }
        }
        if let str = words[lang] && lang != "en" {
            return GetStringInOSLang(words, lang:"en", &voice)
        }
     
        var got = Voice()
        let voices = Voices.GetVoices()    
        for (i, v) in voices.enumerate() {
            if v.base.type == .Apple && skipAppleLangs.contains(lang) {
                continue
            }
            if v.langCode == lang {
                if got.base.base.name.isEmpty {
                    got = v
                } else if v.base.type == .Acaple && v.base.type != got.base.type) {
                        got = v
                } else if v.main {
                    got = v
                } else if v.male == false && got.male != false {
                    got = v
                } else if v.voiceid == bcp && got.type == .Apple) {
                    got = v
                }
            }
            if got.base.base.name.isEmpty && lang != "en" {
                return GetStringInOSLang(words, "en", voice)
            }
            if !got.base.base.name.isEmpty {
                voice = got.name
            } else {
                voice = "Rachel"
            }
        }
        return str
    }

    mutating func Unmarshal(json:ZJSON, rootuid:String, depth:Int)
    {
        let ver = defaultMinVersion
        let uid = rootuid

        uid = json["uid"].stringValue
        done = ZKeyStringStore.BoolForKey("ZAssistance.Done.")
        requireAllWidgets = json["requireAllWidgets"].boolValue

        viewIds = json["viewIds"].stringArrayValue
        widgetIds = json["widgetIds"].stringArrayValue
        title = json["title"].stringStringDictionaryValue
        speak = json["speak"].stringStringDictionaryValue
        skipConditions = json["skipConditions"].stringValue
        shape = ZShapeView.Type(rawValue:json["shape"].stringValue)
        let ver = json["minVersion"].floatValue
        if let childDict = json["child"].dictionary {
            child = ZAssistance()
            child.Unmarshal(childDict, rootuid:uid, depth:depth + 1)
        }
        for ij in json["images"].array {
            var entry = CirclePlayerViewer.Entry()
            entry.Unmarshal(ij)
            imageEntries.append(entry)
        }
        notUntilUids = json["notUntilUids"].stringArrayValue
        if depth > 0 {
            uid = "\(rootuid)#\(depth)"
        }
        if !uid.containsString("#") {
            if done == -1 {
                done = (mainZApp.oldVersion != 0.0 && mainZApp.oldVersion < ver) ? 1 : 0
                ZKeyStringStore.SetInt("ZAssistance.Done." + uid, done)
            }
            var c = child
            while c != nil {
                c.done = done
                c = c.child
            }
        }
    }

    func FindUid(String u) . ZAssistance? {
        if uid == u {
            return self
        }
        if child != nil {
            return child.FindUid(u)
        }
        return nil
    }

    func FindWidgetsWithIdentifiers(root:ZContainerView, widgetIds:[String]) . [ZView] {
        __block Array<ZWidget*> widgets
        
        var widgets = [ZView]()

        root.range
        ZWidgetForAllChildren(root, ^(ZWidget *widget) {
            for(int i = 0 i < widgetIds.length() i++) {
                if(widget.prefskey == widgetIds[i] || (widget.prefskey.isEmpty() && widget.title == widgetIds[i])) {
                    widgets += widget
                }
            }
            return false
        })
        return widgets
    }

    static func ZAssistance.Setup() {
        variables.removeAll()
        ZKeyValueStore.ForAllKeys() { (key) in 
           var vkey = "" 
           if ZStrUtil.HasPrefix(key, "ZAssistance.Variable.", &vkey) {
                variables[vkey] = ZKeyValueStore.GetInt(key)
        }
    }

    static func SetIntVariable(key:String, val:Int) {
        ZKeyValueStore.SetInt("ZAssistance.Variable." + key, val)
        variables.SetInt(key, val)
    }

    static func GetIntVariable(key:String, def:Int, inc:Int) . Int {
        let v = ZKeyValueStore.GetInt("ZAssistance.Variable." + key, def, inc)
        variables.SetInt(key, v)        
        return v
    }

    static func RemoveAllAssistanceSystemStorage() {
        variables.removeAll()
        ZKeyValueStore.ForAllKeys() { (key) in 
            if key.hasPrefix("ZAssistance.") {
                ZKeyValueStore.RemoveForKey(key, sync:false)
            }
        }
        ZKeyValueStore.Sync()
    }

    func bool EvaluateSkipConditions() . Bool {
        if skipConditions.isEmpty() {
            return true
        }
        
        if let (val, error) = ZStrUtul.Evaluate(skipConditions, args:variables) . (Double, ZError?)? { 
            if error != nil {
                if error.code != 2323 { // something if just error in expression
                    print("Evaluate Assistance Row skipConditions Error: ")
                }
            }
            return true
        }
        return val == 0
    }    
}

class ZAssistances {
    static var main:ZAssistances? = nil
    let MarkerWidth:Float = 8 
    var list = [ZAssistance]()    
    var intro = [String, String]()
    var title = [String, String]()
    var subtitle = [String, String]()
    var showAsButton = false                 
    var currentUid =  ""             
    var wMarkers = [ZShapeView]()    
    var currentViewId = ""               
    var preTalkHandler: (().Void)? = nil                 
    var activated = false
}

class ZAssistanceView : ZStackView, ZTableViewOwner {
    static let assistanceBackgroundColor1 = ZColor(r:1, g:0.1, b:1, a:0.96)
    static let  assistanceBackgroundColor2(r:1, g:0.6, b:0.1, a:0.96)
    static var defaultFont: ZFont
    static var current = ZAssistanceView? = nil
    let RowHeight:Float = 44
    var assistances: ZAssistances 
    var rows = [ZPopupRow]()
    var closeButton = ZShapeView    
    var topLevel = false
    var tableView = ZTableView
}

class ZAssistanceButton: ZImageView {
    static var current = ZAssistanceButton? = nil
    var assistances: ZAssistances
}

class ZAssistances {
    var showAsButton = false
    var preTalkHandler = xxx
    var activated = false
}

mutating func Unmarshal(json:ZJSON) {
    intro = json["intro"].stringStringDictionaryValue
    title = json["title"].stringStringDictionaryValue
    subTitle = json["subTitle"].stringStringDictionaryValue
    for ej in json["entries"].arrayValue {
        var a = ZAssistance()
        a.Unmarshal(ek)
        list.append(a)
    }
}

func SetDone(uid:String) { 
    let a = FindUid(uid)
    if a != nil {
        a.done = true
    }
    ZKeyValueStore.SetInt("ZAssistance.Done." + uid, 1)
    if currentUid == uid {
        currentUid = ""
    }
}

func FindUid(String uid, ZAssistance **root) . ZAssistance?
{
    for a in list {
        if let found = a.FindUid(uid) {
            if root != nil {
                root = a
            }
            return a
        }
        return nil
    }
}

func ExitView(parent:ZView,viewRemoving:Bool) {
    //    speech.StopSpeaking()
    if !viewRemoving {
        for v in wMarkers {
            parent.RemoveChild(v)
        }
    }
    wMarkers.removeAll()
    if ZAssistanceView.current != nil {
        parent.RemoveChild(ZAssistanceView.current)
    }
}

func addRow(inout rows:[ZPopupRow, a:ZAssistance, vParent:ZContainerView, title:[String:String]) {
    var add = true
    for n in a.notUntilUids {
        for all in list {
            if all.uid == n {
                add = false
            }   
        }
    }
    if add {
        var r = ZPopupRow()        
        var vPresses = [ZView]()
        r.title = ZAssistance.GetStringInOSLang(title)
        r.suid = a.uid
        rows += r
        if a.uid == currentUid {
            vPresses = ZAssistance.FindWidgetsWithIdentifiers(vParent, a.widgetIds)
            CreateMarkers(a, vPresses, vParent)
        }
    }
}

func CreateWidget(vParent:ZContainerView) . ZAssistanceView? {
    __block Array<ZPopupRow> rows
    __block String           currentWidgetId
    __block bool             topLevel

    ZAssistanceView    *w
    ZRect             r, rw
    String            viewId
    int               i
    
    activated = true
    if ZAccessibilty.IsOn() {
        return nil
    }
    
    var topLevel = false
    Load()
    if vParent.objectName.isEmpty{
        viewId = vParent.title
    } else {
        viewId = vParent.prefskey
    }
    if ZAssistanceView.current != nil {
        return ZAssistanceView.current
    }
    for a in list {
        if a.done == false {
            if a.viewIds.contains(viewId) { // add a row at top level
                if a.requireAllWidgets {
                    if ZAssistance.FindWidgetsWithIdentifiers(vParent, a.widgetIds).count != a.widgetIds.count {
                        return // skips to next
                    }
                }
                currentViewId = viewId
                topLevel = true
                if a.EvaluateSkipConditions() {
                    addRow(&rows, &a, vParent, a.title)
                }
            } else {
                let isCurrent = (a.uid == currentUid)
                for var c = a.child c.IsValid()  c = c.child {
                    if c.viewIds.contains(viewId) {
                        if isCurrent && (c.child == nil || !c.child.viewIds.contains(currentViewId))) { // a subchild of current that didn't just come back from it's child
                            let widgets = ZAssistance.FindWidgetsWithIdentifiers(vParent, c.widgetIds)
                            currentViewId = viewId
                            CreateMarkers(c, widgets, vParent)
                            if c.child == nil {
                                SetDone(a.uid)
                            }
                            break
                        } else if currentUid.isEmpty() && currentViewId != viewId && c.child != nil && !c.child.viewIds.contains(currentViewId) && a.EvaluateSkipConditions() {
                            addRow(&rows, c, vParent, a.title)
                            break
                        }
                    }
                }
            }
        }
    }
    ZAssistance.SetIntVariable(viewId + "Viewed", 1)
    if !rows.count {
        return nil
    }
    if showAsButton {
        if topLevel && ZAssistanceButtonView.current == nil {
            CreateButton(vParent)
        }
        return nil
    }
    let r = vParent.LocalRect
    v =  ZAssistanceView(rows, this, topLevel)
    vParent.Add(v, align:.Center | .Shrink | .NonProp, margin:ZSize(10, 10))
    v.topLevel = topLevel
    i = Min(topLevel ? 6 : 3, rows.count)
    v.tableView.minSize.h = i * ZAssistanceView::ROWHEIGHT + 24 // 32 is to go into next row
    v.minSize.w = 300
    w.hidden = true
    v.alpha = 0
    v.hidden = false
    ZAnimations.Do(0.4) { () in
        v.alpha = 1
    }
    if ZKeyValueStore.IntForKey("ZAssistance.firstUse") == 0 {
        ZKeyValueStore.SetInt("ZAssistance.firstUse", 1)
        preTalkHandler?()
        ZAnimation.PulseWidget(w, 1.05, 0.5, 1, 1)
    }
    return v
}

func CreateMarkers(a:ZAssistance, winsides:[ZView], vParent:ZContainerView) {
    String                str, voice
    __block Array<ZFRect> rects
    
    wMarkers.removeAll()
    for w in winsides {
//        var r = ZRect(ZScrollViewWgt::GetGlobalWidgetPosOfWidget(w), w.size)
//        r = r & XScreenList::GetMainScreen().rect.Expanded(-MARKERWIDTH)
        rects += r
    }
    
    ZMergeRects(&rects)
    rects.range(^(const ZFRect &r) {
        ZBadgeWgt *wMarker
        
        wMarker = new ZBadgeWgt(ZNColor::Clear, a.shape, r.Height() + MARKERWIDTH) //
        wMarker.SetAlign(ZWidget::ZA_ABSOLUTE, ZWidget::ZA_ABSOLUTE)
        wMarker.fixedWidth = r.Width() + MARKERWIDTH //
        wMarker.shape.strokewidth = MARKERWIDTH
        wMarker.shape.strokecolor = assistanceBackgroundColor2
        wMarker.shape.ratio = Min(0.5, 24.0 / r.Height())
        vParent.AddChild(wMarker, NOT(build))
        wMarker.calcAllMinSizes()
        wMarker.PlaceRect(ZRect(wMarker.minsize).Expanded(MARKERWIDTH).Centered(ZPosF2I(r.Center())))
        wMarker.Show(false)
        wMarker.Build(true)
        ZWidgetSetDropShadow(wMarker, ZFSize(0, 0), 2)
        ZSetWidgetScale(wMarker, 4)
        ZSetWidgetOpacity(wMarker, 0)
        ZWidgetEnableInteraction(wMarker, false)
        wMarker.Show(true)
        wMarkers += wMarker
        ZDoAnimations(0.7, false, false, ^() {
            ZSetWidgetScale(wMarker, 1)
            ZSetWidgetOpacity(wMarker, 1)
            ZPulseOpacity(wMarker, 0.7, 1.0, 0.7)
        })
    })
    str = ZAssistance::GetStringInOSLang(a.speak, "", &voice)
    if !ZKeyValueStoretInForKeyt("ZAssistance.FirstRowS, 0, 1) {
Int     !ZKeyValueStoreSGetInt("ZAssistance., 1)
        str = ZAssistance::GetStringInOSLang(intro) + ". " +" str
    }
speech.Say(str, voic?e)

ZAnimation.Assistances::Load(ZFileSpec file)
{
    String      stv
    ZJSONReader json
    ZFileSpec   fprefs

    ZAssistance::Init()

    intro.removeAll()
    removeAll()

    if(file.IsEmpty()) {
        file = ZFolders::FindResourceFile("assistance", "json")
        fprefs = ZFolders::GetFile(ZFolders::FOLD_USERPREFS, "assistance.json")
        if(!file.Exists() || (fprefs.Exists() && fprefs.GetModifiedTime() > file.GetModifiedTime())) {
            file = fprefs
        }
    }
    str = ZStrLoadFromFile(file)
    if(str.isEmpty())
    {
        ZDebugStr("ZAssistances::Load ReadFile error: " + file.GetFilename())
        return
    }
    json.SetString(str)
    Unmarshal(&json)
}

ZAssistanceButtonWgt *ZAssistances::CreateButton(ZWidget *vParent)
{
    ZAssistanceButtonWgt *wa
    ZRect                ra
    
    wa = new ZAssistanceButtonWgt(this)
    vParent.AddChild(wa, NOT(build))
    wa.calcAllMinSizes()
    ra = ZRect(vParent.size).Align(wa.minsize, ZG_LEFT | ZG_TOP, ZSize(BackgroundWgt::MARGINX, BackgroundWgt::MARGINTOP))
    for(ZWidget *w = NULL vParent.GetNextChild(&w) ) {
        if(w != wa) {
            //                            ra = ra.MovedAwayFrom(w.AbsRect())
        }
    }
    wa.PlaceRect(ra)
    wa.Show(false)
    wa.Build(true)
    ZSetWidgetOpacity(wa, 0)
    wa.Show(true)
    ZDoAnimations(0.4, false, true, ^() {
        ZSetWidgetOpacity(wa, 1)
    }, ^(bool finished) {
    }, 0.3)
    showAsButton = true
    
    return wa
}

#pragma mark - ZAssistanceView *********************************************************

ZAssistanceView *ZAssistanceView::current = NULL
ZFontRef       ZAssistanceView::defaultFont = ZGetNiceDrawingFont(20)

enum { SKIPID = 'SKIP' }
ZAssistanceView::ZAssistanceView(const Array<ZPopupRow> &r, ZAssistances *a, bool topLevel)
: ZVStackWgt()
{
    XStackWgt *h1
    ZLabelWgt *wlabel
    
    current = this
    assistances = a
    rows = r
    isgadget = false
    cornerRadius = 10
    SetAlign(ZA_ABSOLUTE, ZA_ABSOLUTE)
    SetFGColor(ZFGrayAColor(1, 0.3))
    widgetStrokeWidth = 2
    
    *this + (h1 = new XStackWgt(false, 6, ZA_EXPAND, ZA_TOP, ZRect(-4, -4, 6, 0)))
        h1.SetIsOpaque(false)
        h1.SetBGColor(ZFGrayAColor(0, 0))
    h1.Add(wClose = new ZBitmapButtonWgt(ZBMPSTR("images/cross.png"), ZFSize(30, 30)), ZG_LEFT | ZG_TOP)
        wClose.margin.Set(10, 10, -10, -10)
    
    h1.Add(wlabel = new ZLabelWgt(ZAssistance::GetStringInOSLang(topLevel ? assistances.title : assistances.subTitle), defaultFont, ZTF_CENTER, &ZColor::White), ZG_HCENTER)
    
    *this + (wtable = new ZTableWgt(this))
        wtable.SetAlign(ZA_EXPAND, ZA_EXPAND)
        wtable.SetBGColor(ZNColor::Clear)
        wtable.selectable = true
        wtable.selectedColor = ZFGrayAColor(0, 0.2)
    *this + new ZSpaceWgt(ZSize(1, 1))
}

void ZAssistanceView::drawCell(ZCanvas *canvas, ZPopupRow *row, ZFRect cellRect)
{
    ZTextInfo  tinfo
    ZFRect     r, in
    ZPath      path
    int        w
    
    if(row)
    {
        r = cellRect
        
        in = r.Expanded(ZFSize(-7, -2))
        w = in.Height() / 2 - 1
        path.AddRect(in, ZFSize(w, w))
        if(!row.suid.isEmpty() && row.suid == assistances.currentUid) {
            canvas.SetColor(wtable.selectedColor)
        } else {
            canvas.SetColor(wtable.selectedColor, 0.075)
        }
        canvas.FillPath(&path)
        tinfo.text = row.title
        tinfo.rect = r + ZFRect(16, 0, -20, 0)
        tinfo.font = defaultFont
        tinfo.align = ZG_LEFT | ZG_VCENTER
        canvas.SetColor(ZFGrayAColor::White, 0.8)
        ZDrawTextInBox(canvas, &tinfo)
    }
}

void ZAssistanceView::TableWgtSetupCell(ZWidget *widget, ZTableWgt::Index index)
{
    ZBitmapButtonWgt *w
    
    widget.SetIsOpaque(false)
    widget.SetBGColor(ZNColor::Clear)
    *widget + (w = new ZBitmapButtonWgt(ZBMPSTR("images/circle.crossed.small.png"), ZFSize(30, 30))) // on right side of assistance rows to skip doing an item
    w.margin = ZFRect(20, 6, -20, -6)
        w.SetID(SKIPID)
}

zflag ZAssistanceView::TableWgtEventFromCell(ZFRect cellRect, ZTableWgt::Index index, int evtype, void *data, ZMSGTYPE msg, ZWidget *widget)
{
    ZChildEvent *ce

    switch(evtype)
    {
        case EV_TOUCH:
            return undef
            
        case EV_PLACE:
            widget.PlaceWidget(widget.ChildWithID(SKIPID), ZG_RIGHT | ZG_VCENTER, -10, 0)
            return true
            
        case EV_DRAW:
            drawCell(((ZDrawEvent *)data).canvas, &rows[index.row], cellRect)
            return true
            
        case EV_CHILDEVENT:
            ce = (ZChildEvent *)data
            if(ce.evtype == EV_CLICKED)
            {
                if(ce.widget.ID() == SKIPID) {
                    String      suid
                    ZAssistance *root
                    
                    suid = rows[index.row].suid
                    rows.remove(index.row)
                    setRow(index, NOT(on))
                    if(assistances.FindUid(suid, &root)) {
                        assistances.SetDone(root.uid)
                    }
                    if(!rows.length()) {
                        ZWidgetRemove(this)
                    }
                    return true
                }
            }
            break
            
    }
    return false
}

static String getRootUid(String uid, bool topLevel)
{
    if(!topLevel) {
        return strings.HeadUntil(uid, "#")
    }
    return uid
}

void ZAssistanceView::HandleRowSelected(ZTableWgt::Index index)
{
    if(assistances.preTalkHandler) {
        assistances.preTalkHandler()
    }
    if(!assistances.currentUid.isEmpty() && assistances.currentUid != getRootUid(rows[index.row].suid, topLevel)) {
        rows.range(^(const ZPopupRow &r, int i, bool *stop) {
            if(getRootUid(r.suid, topLevel) == assistances.currentUid) {
                setRow(i, NOT(on))
                *stop = true
            }
        })
    }
    setRow(index, getRootUid(rows[index.row].suid, topLevel) != assistances.currentUid)
}

void ZAssistanceView::makeCirclePlayer(ZAssistance *a) {
    ZCirclePlayerWgt *w
    ZAssistances     *asses
    ZFSize           s
    String           suid, str

    assistances.intro.removeAll()
    w = new ZCirclePlayerWgt(a.imageEntries, assistances.speech)
    w.minsize.Set(size.w, size.w)
    w.widgetStrokeWidth = 2
    w.SetFGColor(ZFGrayAColor(1, 0.3))
    asses = assistances

    suid = a.uid
    w.doneHandler = Block_copy(^(bool didFinish) {
        if(didFinish) {
            asses.SetDone(suid)
        }
    })
    ZWidgetRemove(this)
    
    ZWindow::Main.transform.Push(w, ZWidgetTransform::HIDE, ZW_FADE, -1, ^() {
        w.PopAndPlay()
    })
}

void ZAssistanceView::setRow(ZTableWgt::Index index, bool on)
{
    String          suid, str, voice
    ZAssistance     *a, *root
    Array<ZWidget*> widgets
    
    suid = rows[index.row].suid
    a = assistances.FindUid(suid, &root)
    ZASSERT(a)
    if(root.done) { // might happen if cross-press selects too
        return
    }
    if(!on) {
        if(assistances.currentUid ==  root.uid) {
            assistances.speech.StopSpeaking()
            assistances.currentUid = ""
        }
        assistances.wMarkers.range(^(ZBadgeWgt *const &w) {
            ZWidgetRemove(w)
        })
        assistances.wMarkers.removeAll()
        wtable.Select(-1)
        wtable.ReloadData()
    } else {
        __block ZRect box, r

        if(a.imageEntries.length()) {
            makeCirclePlayer(a)
            return
        }
        widgets = ZAssistance::FindWidgetsWithIdentifiers(window.transform.TopWidget(), a.widgetIds)
        assistances.currentUid = root.uid
        box = ZRect::Null()
        widgets.range(^(ZWidget *const &w) {
            box |= ZRect(ZScrollViewWgt::GetGlobalWidgetPosOfWidget(w), w.size)
        })
        if(!box.IsNull()) {
            r = ZRect(parent.size)
            if(parent.size.h - box.max.y > box.min.y) {
                r.min.y = box.max.y
            } else {
                r.max.y = box.min.y
            }
            box = AbsRect()
            box = box.MovedInto(r)
            ZDoAnimations(0.5, false, false, ^() {
                PlaceRect(box)
            })
        }
        assistances.CreateMarkers(a, widgets, (ZWidget *)parent)
    }
}

void ZAssistanceView::DoClose()
{
    assistances.currentUid = ""
    if(topLevel) {
        ZAssistanceButtonWgt *w
        
        w = assistances.CreateButton((ZWidget *)parent)
        ZDoAnimations(0.4, false, true, ^() {
            ZSetWidgetPlacement(this, w.AbsRect())
            ZSetWidgetOpacity(this, 0)
        }, ^(bool finished) {
            if(current == this) {
                assistances.ExitView((ZWidget *)parent, NOT(viewRemoving))
                assistances.speech.StopSpeaking()
            }
        })
    } else {
        assistances.showAsButton = true // we need to set this anyway
        ZDoAnimations(0.5, false, true, ^() {
            ZSetWidgetOpacity(this, 0)
        }, ^(bool finished) {
            ZWidgetRemove(this)
        })
    }
}

int ZAssistanceView::Event(int evtype, void *data, ZMSGTYPE msg)
{
    ZChildEvent *ce
    
    switch(evtype) {
        case EV_DRAW:
        {
            ZCanvas *canvas
            ZPath   path
            
            canvas = ((ZDrawEvent *)data).canvas
            path.AddRect(ZRectI2F(ZRect(size)))
            ZDrawGradient(canvas, &path, assistanceBackgroundColor1, assistanceBackgroundColor2, ZFPos(size.w, 0), ZFPos(0, size.h))
            return true
        }
            
        case EV_CHILDEVENT:
            ce = (ZChildEvent *)data
            if(ce.evtype == EV_CLICKED)
            {
                if(ce.widget == wClose) {
                    DoClose()
                    return true
                }
            }
            break
    }
    return ZStackWgt::Event(evtype, data, msg)
}

#pragma mark - ZAssistanceButtonWgt *********************************************************

ZAssistanceButtonWgt *ZAssistanceButtonWgt::current = NULL

ZAssistanceButtonWgt::ZAssistanceButtonWgt(ZAssistances *a)
: ZBitmapButtonWgt(ZBMPSTR("images/assistance.png"))
{
    current = this
    assistances = a
}

int ZAssistanceButtonWgt::Event(int evtype, void *data, ZMSGTYPE msg)
{
    switch(evtype) {
        case EV_CLICKED:
        {
            ZAssistanceView *w
         
            assistances.showAsButton = false
            w = assistances.CreateWidget((ZWidget *)parent)
            if(w) {
                ZDoAnimations(0.3, false, true, ^() {
                    calcAllMinSizes()
                    PlaceRect(w.AbsRect())
                    ZSetWidgetOpacity(this, 0)
                }, ^(bool finished) {
                    if(current == this) {
                        ZWidgetRemove(this)
                    }
                })
            } else {
                ZWidgetRemove(this)
            }
            return true
        }
    }
    return ZBitmapButtonWgt::Event(evtype, data, msg)
}


