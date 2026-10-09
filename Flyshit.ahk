#Requires AutoHotkey v2.0
#UseHook
#MaxThreadsPerHotkey 2
SetMouseDelay(-1)
SetDefaultMouseSpeed(0)
ProcessSetPriority("Normal")
DllCall("winmm\timeBeginPeriod", "UInt", 1)

global recoilStrength := 0
global useRecoil := true
global autoClickEnabled := true
global macrosEnabled := true
global bhopEnabled := false
global bhopDelay := 40
global bhopStrafe := false
global edashEnabled := false
global edashDelay := 500
global edashMode := "Hold E"
global triggerEnabled := false
global triggerMode := "Hold RButton"
global triggerColors := ["0xFF0000", "0xFFFF00", "0xFF00FF"]
global triggerTol := 10
global triggerDelay := 20
global pickingSlot := 0

; ============ LICENSE SERVER (owner: set your licenses.json raw URL) ============
; Leave the placeholder to run without a license check.
global LICENSE_URL := "https://github.com/sevsev08007-ui/flyshit/blob/main/licenses.json"
global myHWID := "", licPlan := "", licDaysLeft := -1
global licGui := "", licRetry := false

; ================= APPEARANCE STATE =================
global currentBg := "151515"
global currentAccent := "7C5CFF"
global cardBg := "1E1E1E"
global topBg := "101010"
global blurEnabled := true
global blurAlpha := 170
global windowOpacity := 235
global alwaysTop := false

global myGui := ""
global TopBar := "", SideBar := "", Card1 := "", Card2 := "", Card3 := "", Card4 := "", Card5 := "", PillBg := ""
global TitleText := "", AccentDot := ""
global RecoilValue := "", RecoilSlider := ""
global StatusText := "", StatusHint := ""
global UseRecoilChk := "", TopToggleChk := "", BlurToggleChk := ""
global BgName := "", OpacityVal := "", OpacitySlider := ""
global ShowHotkeyCtrl := "", ToggleHotkeyCtrl := "", FooterText := ""
global BhopChk := "", BhopDelaySlider := "", BhopDelayVal := "", StrafeChk := ""
global EdashChk := "", EdashModeDDL := "", EdashDelayVal := "", EdashDelaySlider := "", EdashCard := ""
global MasterChk := ""
global DashCard := "", DashMacros := "", DashClicker := "", DashRecoil := "", DashBhop := "", DashEdash := "", DashTrigger := "", DashLicense := ""
global TriggerChk := "", TriggerModeDDL := ""
global TrigPrev1 := "", TrigHex1 := "", TrigPrev2 := "", TrigHex2 := "", TrigPrev3 := "", TrigHex3 := ""
global TriggerTolVal := "", TriggerTolSlider := "", TriggerDelayVal := "", TriggerDelaySlider := "", TriggerCard := ""

global pages := Map("Dash", [], "Main", [], "Trigger", [], "Bunny", [], "Edash", [], "Settings", [])
global navPills := Map(), navTexts := Map()
global navTree := []
global currentPage := "Main"

global showHotkey := "F2"
global toggleHotkey := "z"
global guiVisible := false

global loaderGui := "", loaderBar := "", loaderStatus := ""

LoadSettings()
myHWID := GetHWID()
lic := CheckLicense()
while (!lic["ok"]) {
    licRetry := false
    ShowLicense(lic["msg"])
    WinWaitClose("ahk_id " . licGui.Hwnd)
    if (!licRetry)
        ExitApp()
    lic := CheckLicense()
}
licPlan := lic["plan"]
licDaysLeft := lic["days"]
ShowLoader()
UpdateLoader(20, "building interface...")
BuildGui()
UpdateLoader(55, "registering hotkeys...")
RegisterHotkeys()
UpdateLoader(85, "applying blur...")
ApplyBlur()
UpdateLoader(100, "ready", 350)
loaderGui.Destroy()
myGui.Show("x5 y5 w520 h384")
guiVisible := true
ApplyBlur()
SetTimer(BhopLoop, 15)
SetTimer(EdashLoop, 25)
SetTimer(TriggerLoop, 5)
CoordMode("Pixel", "Screen")
return

; ================= LICENSE / HWID LOCK =================
GetHWID() {
    id := ""
    try id .= RegRead("HKLM\SOFTWARE\Microsoft\Cryptography", "MachineGuid")
    try {
        wmi := ComObjGet("winmgmts:\\.\root\cimv2")
        for d in wmi.ExecQuery("SELECT SerialNumber FROM Win32_DiskDrive WHERE MediaType='Fixed hard disk media'") {
            id .= "|" . d.SerialNumber
            break
        }
    }
    clean := RegExReplace(id, "[^A-Za-z0-9]", "")
    if (StrLen(clean) < 8)
        clean .= RegExReplace(A_ComputerName, "[^A-Za-z0-9]", "")
    return StrUpper(SubStr(clean, 1, 32))
}

FetchText(url) {
    wh := ComObject("WinHttp.WinHttpRequest.5.1")
    wh.SetTimeouts(8000, 8000, 8000, 8000)
    wh.Open("GET", url, false)
    wh.Send()
    if (wh.Status != 200)
        throw Error("HTTP " . wh.Status)
    return wh.ResponseText
}

; minimal JSON reader for {"HWID": {"plan": "30d", "since": "2026-10-09"}, ...}
ParseLicenses(text) {
    m := Map()
    pos := 1
    while (pos := RegExMatch(text, '"([^"]+)"\s*:\s*\{([^}]*)\}', &mm, pos)) {
        key := StrUpper(Trim(mm[1]))
        body := mm[2]
        plan := ""
        since := ""
        if (RegExMatch(body, '"plan"\s*:\s*"([^"]*)"', &p))
            plan := p[1]
        if (RegExMatch(body, '"since"\s*:\s*"([^"]*)"', &s))
            since := s[1]
        m[key] := Map("plan", plan, "since", since)
        pos := mm.Pos + mm.Len
    }
    return m
}

NormDate(s) {
    d := RegExReplace(s, "\D")
    if (StrLen(d) = 8)
        return d . "000000"
    if (StrLen(d) = 14)
        return d
    return ""
}

FmtDate(stamp) {
    return SubStr(stamp, 1, 4) . "-" . SubStr(stamp, 5, 2) . "-" . SubStr(stamp, 7, 2)
}

CheckLicense() {
    global LICENSE_URL, myHWID
    if (LICENSE_URL = "" || InStr(LICENSE_URL, "YOURNAME"))
        return Map("ok", true, "msg", "", "plan", "lifetime", "days", -1)
    try {
        sep := InStr(LICENSE_URL, "?") ? "&" : "?"
        all := ParseLicenses(FetchText(LICENSE_URL . sep . "t=" . A_TickCount))
    } catch as e {
        return Map("ok", false, "msg", "Can't reach license server. Check your internet and press Retry.", "plan", "", "days", 0)
    }
    key := StrUpper(myHWID)
    if (!all.Has(key))
        return Map("ok", false, "msg", "This HWID is not licensed. Send your HWID to the owner, then press Retry.", "plan", "", "days", 0)
    e := all[key]
    plan := Trim(e["plan"])
    since := NormDate(e["since"])
    if (StrLower(plan) = "lifetime")
        return Map("ok", true, "msg", "", "plan", "lifetime", "days", -1)
    if (!RegExMatch(plan, "^(\d+)([dDmM])$", &pm) || since = "")
        return Map("ok", false, "msg", "License entry is invalid. Contact the owner.", "plan", plan, "days", 0)
    n := Integer(pm[1])
    exp := (pm[2] = "m" || pm[2] = "M") ? DateAdd(since, n, "Months") : DateAdd(since, n, "Days")
    if (A_Now >= exp)
        return Map("ok", false, "msg", "License expired " . FmtDate(exp) . ". Renew to continue.", "plan", plan, "days", 0)
    return Map("ok", true, "msg", "", "plan", plan, "days", DateDiff(exp, A_Now, "Days"))
}

ShowLicense(msg) {
    global licGui, myHWID
    licGui := Gui("-Caption +Border +ToolWindow", "Flyshit License")
    licGui.BackColor := "151515"
    licGui.OnEvent("Close", LicenseClose)
    licGui.OnEvent("Escape", LicenseClose)
    licGui.SetFont("s13 cFFFFFF", "Segoe UI Bold")
    licGui.Add("Text", "x0 y14 w400 h28 Center BackgroundTrans", "FLYSHIT - LICENSE")
    licGui.SetFont("s9 cFF6666", "Segoe UI")
    licGui.Add("Text", "x24 y50 w352 h64 Center BackgroundTrans", msg)
    licGui.SetFont("s9 c888888", "Segoe UI")
    licGui.Add("Text", "x24 y118 w352 h18 BackgroundTrans", "Your HWID (send this to the owner):")
    licGui.SetFont("s9 cFFFFFF", "Consolas")
    licGui.Add("Edit", "x24 y138 w272 h26 ReadOnly Background1E1E1E cFFFFFF", myHWID)
    copyBtn := licGui.Add("Button", "x304 y138 w72 h26", "Copy")
    copyBtn.OnEvent("Click", CopyHWID)
    retryBtn := licGui.Add("Button", "x110 y184 w90 h28", "Retry")
    retryBtn.OnEvent("Click", LicenseRetry)
    exitBtn := licGui.Add("Button", "x210 y184 w90 h28", "Exit")
    exitBtn.OnEvent("Click", LicenseClose)
    x := (A_ScreenWidth - 400) // 2
    y := (A_ScreenHeight - 250) // 2
    licGui.Show("x" . x . " y" . y . " w400 h250")
}

CopyHWID(*) {
    global myHWID
    A_Clipboard := myHWID
    ToolTip("HWID copied - send it to the owner")
    SetTimer(HideToolTip, -800)
}

LicenseRetry(*) {
    global licGui, licRetry
    licRetry := true
    licGui.Destroy()
}

LicenseClose(*) {
    global licGui
    licGui.Destroy()
}

ShowLoader() {
    global loaderGui, loaderBar, loaderStatus, currentBg, currentAccent
    card := Lighten(currentBg, 16)
    loaderGui := Gui("-Caption +Border +ToolWindow", "Flyshit")
    loaderGui.BackColor := currentBg
    loaderGui.SetFont("s14 c" . currentAccent, "Segoe UI")
    loaderGui.Add("Text", "x0 y14 w400 h24 Center BackgroundTrans", "●")
    loaderGui.SetFont("s26 cFFFFFF", "Segoe UI Bold")
    loaderGui.Add("Text", "x0 y38 w400 h50 Center BackgroundTrans", "FLYSHIT")
    loaderGui.SetFont("s9 c888888", "Segoe UI")
    loaderGui.Add("Text", "x0 y92 w400 h20 Center BackgroundTrans", "recoil + autoclicker")
    loaderBar := loaderGui.Add("Progress", "x50 y120 w300 h10 -Theme Background" . card . " c" . currentAccent, 0)
    loaderGui.SetFont("s8 c777777", "Segoe UI")
    loaderStatus := loaderGui.Add("Text", "x0 y138 w400 h20 Center BackgroundTrans", "loading...")
    loaderGui.Add("Text", "x0 y172 w392 h18 Right BackgroundTrans", "v2.1")
    x := (A_ScreenWidth - 400) // 2
    y := (A_ScreenHeight - 200) // 2
    loaderGui.Show("x" . x . " y" . y . " w400 h200")
    try {
        SetAcrylic(loaderGui.Hwnd, 4, HexToABGR(currentBg, 170))
        RoundCorners(loaderGui.Hwnd)
    } catch {
    }
}

UpdateLoader(pct, text, pause := 300) {
    global loaderBar, loaderStatus
    loaderBar.Value := pct
    loaderStatus.Text := text
    Sleep(pause)
}

; looks for a file in the "assets" folder next to the script,
; falls back to the script folder, returns "" if nowhere to be found
AssetPath(name) {
    p1 := A_ScriptDir . "\assets\" . name
    if (FileExist(p1))
        return p1
    p2 := A_ScriptDir . "\" . name
    if (FileExist(p2))
        return p2
    return ""
}

; register a control on a tab page (shown/hidden by SwitchPage)
Reg(page, ctrl) {
    global pages
    pages[page].Push(ctrl)
    return ctrl
}

BuildNav() {
    global myGui, navTree, navPills, navTexts, topBg
    navTree := [
        Map("label", "DASHBOARD", "page", "Dash"),
        Map("label", "MAIN", "open", true, "kids", [["Main", "MAIN"], ["Trigger", "TRIGGER"]]),
        Map("label", "MACROS", "open", true, "kids", [["Bunny", "BUNNYHOP"], ["Edash", "E-DASH"]]),
        Map("label", "SETTINGS", "page", "Settings")
    ]
    for g in navTree {
        if (g.Has("kids")) {
            myGui.SetFont("s9 c888888", "Segoe UI Semibold")
            h := myGui.Add("Text", "x14 y76 w104 h26 Center BackgroundTrans vFOLDER_" . g["label"], "")
            h.OnEvent("Click", NavFolderClick)
            g["htxt"] := h
            for k in g["kids"] {
                key := k[1]
                pill := myGui.Add("Progress", "x20 y76 w98 h28 -Theme Background" . topBg . " c" . topBg . " Disabled", 100)
                myGui.SetFont("s9 c888888", "Segoe UI Semibold")
                txt := myGui.Add("Text", "x20 y76 w98 h28 Center BackgroundTrans v" . key, k[2])
                txt.OnEvent("Click", NavPageClick)
                navPills[key] := pill
                navTexts[key] := txt
            }
        } else {
            pill := myGui.Add("Progress", "x14 y76 w104 h30 -Theme Background" . topBg . " c" . topBg . " Disabled", 100)
            myGui.SetFont("s9 c888888", "Segoe UI Semibold")
            txt := myGui.Add("Text", "x14 y76 w104 h30 Center BackgroundTrans v" . g["page"], g["label"])
            txt.OnEvent("Click", NavPageClick)
            navPills[g["page"]] := pill
            navTexts[g["page"]] := txt
            g["pill"] := pill
            g["txt"] := txt
        }
    }
    LayoutNav()
}

NavPageClick(ctrl, *) {
    SwitchPage(ctrl.Name)
}

NavFolderClick(ctrl, *) {
    ToggleFolder(SubStr(ctrl.Name, 8))
}

ToggleFolder(label) {
    global navTree
    for g in navTree {
        if (g.Has("kids") && g["label"] = label) {
            g["open"] := !g["open"]
            break
        }
    }
    LayoutNav()
}

LayoutNav() {
    global navTree, navPills, navTexts, currentAccent
    y := 76
    for g in navTree {
        if (g.Has("kids")) {
            g["htxt"].Move(14, y, 104, 24)
            open := g["open"]
            g["htxt"].Text := (open ? "▾ " : "▸ ") . g["label"]
            g["htxt"].SetFont(open ? "s9 c" . currentAccent : "s9 c888888", "Segoe UI Semibold")
            y += 28
            if (open) {
                for k in g["kids"] {
                    key := k[1]
                    navPills[key].Move(20, y, 98, 26)
                    navTexts[key].Move(20, y, 98, 26)
                    navPills[key].Visible := true
                    navTexts[key].Visible := true
                    y += 30
                }
            } else {
                for k in g["kids"] {
                    navPills[k[1]].Visible := false
                    navTexts[k[1]].Visible := false
                }
            }
        } else {
            g["pill"].Move(14, y, 104, 30)
            g["txt"].Move(14, y, 104, 30)
            y += 34
        }
    }
}

SwitchPage(name) {
    global pages, navPills, navTexts, currentPage, currentAccent, currentBg, topBg
    currentPage := name
    for pg, ctrls in pages {
        show := (pg = name)
        for ctrl in ctrls
            ctrl.Visible := show
    }
    for key, pill in navPills {
        if (key = name) {
            pill.Opt("+Background" . currentAccent . " +c" . currentAccent)
            navTexts[key].SetFont("s9 c" . currentBg, "Segoe UI Semibold")
        } else {
            pill.Opt("+Background" . topBg . " +c" . topBg)
            navTexts[key].SetFont("s9 c888888", "Segoe UI Semibold")
        }
    }
}

BuildGui() {
    global myGui, currentBg, currentAccent, cardBg, topBg
    global recoilStrength, windowOpacity, blurEnabled, showHotkey, toggleHotkey, guiVisible
    global bhopEnabled, bhopDelay, bhopStrafe, macrosEnabled
    global edashEnabled, edashDelay, edashMode
    global triggerEnabled, triggerMode, triggerColors, triggerTol, triggerDelay
    global TopBar, SideBar, Card1, Card2, Card3, Card4, Card5, EdashCard, PillBg
    global DashCard, DashMacros, DashClicker, DashRecoil, DashBhop, DashEdash, DashTrigger, DashLicense
    global TitleText, AccentDot, RecoilValue, RecoilSlider, StatusText, StatusHint
    global UseRecoilChk, TopToggleChk, BlurToggleChk, MasterChk
    global BgName, OpacityVal, OpacitySlider
    global ShowHotkeyCtrl, ToggleHotkeyCtrl, FooterText
    global BhopChk, BhopDelaySlider, BhopDelayVal, StrafeChk
    global EdashChk, EdashModeDDL, EdashDelayVal, EdashDelaySlider, EdashCard
    global TriggerChk, TriggerModeDDL
    global TrigPrev1, TrigHex1, TrigPrev2, TrigHex2, TrigPrev3, TrigHex3
    global TriggerTolVal, TriggerTolSlider, TriggerDelayVal, TriggerDelaySlider, TriggerCard

    ; derive card shades from (possibly loaded) theme so a fresh build matches
    cardBg := Lighten(currentBg, 16)
    topBg := Lighten(currentBg, -8)

    myGui := Gui("-Caption +Border", "Flyshit")
    myGui.MarginX := 0
    myGui.MarginY := 0
    myGui.BackColor := currentBg
    myGui.OnEvent("Close", GuiClose)
    myGui.OnEvent("Escape", GuiEscape)

    ; ---------- TOP BAR (always visible) ----------
    myGui.SetFont("s11 cFFFFFF", "Segoe UI Semibold")
    TopBar := myGui.Add("Progress", "x0 y0 w520 h56 -Theme Background" . topBg . " c" . topBg . " Disabled", 100)
    TitleText := myGui.Add("Text", "x18 y8 w100 h24 BackgroundTrans cFFFFFF", "FLYSHIT")
    TitleText.OnEvent("Click", DragGui)
    myGui.SetFont("s7 cAAAAAA", "Segoe UI")
    dragSub := myGui.Add("Text", "x18 y30 w220 h16 BackgroundTrans", "recoil + autoclicker · v2.3")
    dragSub.OnEvent("Click", DragGui)
    logoPath := AssetPath("flsht.png")
    if (logoPath != "") {
        myGui.Add("Picture", "x122 y10 w36 h36", logoPath)
    } else {
        myGui.SetFont("s12 c7C5CFF", "Segoe UI")
        AccentDot := myGui.Add("Text", "x122 y8 w20 h24 BackgroundTrans", "●")
    }
    myGui.SetFont("s9 cDDDDDD", "Segoe UI")
    MasterChk := myGui.Add("Checkbox", "x312 y16 w124 h24 Background" . topBg . (macrosEnabled ? " Checked" : ""), "Macros enabled")
    MasterChk.OnEvent("Click", ToggleMaster)
    myGui.SetFont("s10 cAAAAAA", "Segoe UI")
    btnMin := myGui.Add("Text", "x448 y12 w24 h24 Center BackgroundTrans", "_")
    btnMin.OnEvent("Click", GuiMinimize)
    btnClose := myGui.Add("Text", "x476 y12 w28 h24 Center BackgroundTrans", "X")
    btnClose.OnEvent("Click", GuiClose)

    ; ---------- SIDEBAR TABS (always visible) ----------
    SideBar := myGui.Add("Progress", "x0 y56 w132 h328 -Theme Background" . topBg . " c" . topBg . " Disabled", 100)
    BuildNav()

    ; ================= PAGE: DASHBOARD =================
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    DashCard := Reg("Dash", myGui.Add("Progress", "x148 y72 w356 h232 -Theme Background" . cardBg . " c" . cardBg . " Disabled", 100))
    Reg("Dash", myGui.Add("Text", "x164 y84 w200 h18 BackgroundTrans", "DASHBOARD"))
    myGui.SetFont("s9 cBBBBBB", "Segoe UI")
    Reg("Dash", myGui.Add("Text", "x164 y110 w150 h22 BackgroundTrans", "Macros"))
    DashMacros := Reg("Dash", myGui.Add("Text", "x330 y110 w158 h22 Right BackgroundTrans", "ENABLED"))
    Reg("Dash", myGui.Add("Text", "x164 y134 w150 h22 BackgroundTrans", "Autoclicker"))
    DashClicker := Reg("Dash", myGui.Add("Text", "x330 y134 w158 h22 Right BackgroundTrans", "ON"))
    Reg("Dash", myGui.Add("Text", "x164 y158 w150 h22 BackgroundTrans", "Recoil"))
    DashRecoil := Reg("Dash", myGui.Add("Text", "x330 y158 w158 h22 Right BackgroundTrans", "ON"))
    Reg("Dash", myGui.Add("Text", "x164 y182 w150 h22 BackgroundTrans", "Bunnyhop"))
    DashBhop := Reg("Dash", myGui.Add("Text", "x330 y182 w158 h22 Right BackgroundTrans", "OFF"))
    Reg("Dash", myGui.Add("Text", "x164 y206 w150 h22 BackgroundTrans", "E-dash"))
    DashEdash := Reg("Dash", myGui.Add("Text", "x330 y206 w158 h22 Right BackgroundTrans", "OFF"))
    Reg("Dash", myGui.Add("Text", "x164 y230 w150 h22 BackgroundTrans", "Triggerbot"))
    DashTrigger := Reg("Dash", myGui.Add("Text", "x330 y230 w158 h22 Right BackgroundTrans", "OFF"))
    Reg("Dash", myGui.Add("Text", "x164 y254 w150 h22 BackgroundTrans", "License"))
    DashLicense := Reg("Dash", myGui.Add("Text", "x330 y254 w158 h22 Right BackgroundTrans", "Lifetime"))
    myGui.SetFont("s8 c666666", "Segoe UI")
    Reg("Dash", myGui.Add("Text", "x164 y280 w324 h18 Center BackgroundTrans", "live overview - updates as you toggle"))

    ; ================= PAGE: MAIN =================
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    Card1 := Reg("Main", myGui.Add("Progress", "x148 y72 w356 h148 -Theme Background" . cardBg . " c" . cardBg . " Disabled", 100))
    Reg("Main", myGui.Add("Text", "x164 y84 w200 h18 BackgroundTrans", "RECOIL CONTROL"))
    myGui.SetFont("s20 cFFFFFF", "Segoe UI Bold")
    RecoilValue := Reg("Main", myGui.Add("Text", "x164 y102 w100 h36 BackgroundTrans", String(recoilStrength)))
    myGui.SetFont("s9 c888888", "Segoe UI")
    Reg("Main", myGui.Add("Text", "x242 y114 w150 h20 BackgroundTrans", "/ 30 strength"))
    RecoilSlider := Reg("Main", myGui.Add("Slider", "x164 y146 w324 Range0-30 TickInterval1", recoilStrength))
    RecoilSlider.OnEvent("Change", UpdateRecoil)
    myGui.SetFont("s8 c666666", "Segoe UI")
    Reg("Main", myGui.Add("Text", "x164 y184 w324 h16 Center BackgroundTrans", "drag to tune pull-down compensation"))

    Card2 := Reg("Main", myGui.Add("Progress", "x148 y232 w356 h108 -Theme Background" . cardBg . " c" . cardBg . " Disabled", 100))
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    Reg("Main", myGui.Add("Text", "x164 y244 w200 h18 BackgroundTrans", "STATUS"))
    PillBg := Reg("Main", myGui.Add("Progress", "x164 y266 w160 h28 -Theme Background2A2A2A c2A2A2A Disabled", 100))
    myGui.SetFont("s9 cFF5555", "Segoe UI Bold")
    StatusText := Reg("Main", myGui.Add("Text", "x164 y266 w160 h28 Center BackgroundTrans", "DISABLED"))
    myGui.SetFont("s8 c888888", "Segoe UI")
    StatusHint := Reg("Main", myGui.Add("Text", "x334 y270 w150 h28 BackgroundTrans", "press  Z  to toggle"))
    myGui.SetFont("s9 cDDDDDD", "Segoe UI")
    UseRecoilChk := Reg("Main", myGui.Add("Checkbox", "x164 y302 w160 h22 Background" . cardBg . " Checked", "Recoil comp."))
    UseRecoilChk.OnEvent("Click", ToggleRecoil)
    TopToggleChk := Reg("Main", myGui.Add("Checkbox", "x328 y302 w160 h22 Background" . cardBg, "Always on top"))
    TopToggleChk.OnEvent("Click", ToggleTop)

    ; ================= PAGE: SETTINGS (background + hotkeys) =================
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    Card3 := Reg("Settings", myGui.Add("Progress", "x148 y72 w356 h268 -Theme Background" . cardBg . " c" . cardBg . " Disabled", 100))
    Reg("Settings", myGui.Add("Text", "x164 y84 w200 h18 BackgroundTrans", "BACKGROUND"))
    myGui.SetFont("s2", "Segoe UI")
    sw1 := Reg("Settings", myGui.Add("Text", "x164 y106 w44 h26 Background151515 +Border", ""))
    sw1.OnEvent("Click", (*) => ApplyTheme("151515", "7C5CFF", "Midnight  #151515"))
    sw2 := Reg("Settings", myGui.Add("Text", "x216 y106 w44 h26 Background2B2B40 +Border", ""))
    sw2.OnEvent("Click", (*) => ApplyTheme("2B2B40", "B8B8FF", "Lavender  #2B2B40"))
    sw3 := Reg("Settings", myGui.Add("Text", "x268 y106 w44 h26 Background0E141B +Border", ""))
    sw3.OnEvent("Click", (*) => ApplyTheme("0E141B", "38BDF8", "Ocean  #0E141B"))
    sw4 := Reg("Settings", myGui.Add("Text", "x320 y106 w44 h26 Background0F1511 +Border", ""))
    sw4.OnEvent("Click", (*) => ApplyTheme("0F1511", "4ADE80", "Forest  #0F1511"))
    sw5 := Reg("Settings", myGui.Add("Text", "x372 y106 w44 h26 Background1A0F12 +Border", ""))
    sw5.OnEvent("Click", (*) => ApplyTheme("1A0F12", "FF4D5E", "Crimson  #1A0F12"))
    sw6 := Reg("Settings", myGui.Add("Text", "x424 y106 w44 h26 Background171009 +Border", ""))
    sw6.OnEvent("Click", (*) => ApplyTheme("171009", "FB923C", "Sunset  #171009"))
    myGui.SetFont("s8 cAAAAAA", "Segoe UI")
    BgName := Reg("Settings", myGui.Add("Text", "x164 y140 w170 h18 BackgroundTrans", PresetLabel(currentBg)))
    customBtn := Reg("Settings", myGui.Add("Button", "x348 y138 w140 h24", "Custom..."))
    customBtn.OnEvent("Click", CustomBg)
    myGui.SetFont("s9 cBBBBBB", "Segoe UI")
    Reg("Settings", myGui.Add("Text", "x164 y166 w150 h18 BackgroundTrans", "Opacity"))
    OpacityVal := Reg("Settings", myGui.Add("Text", "x414 y166 w74 h18 Right BackgroundTrans", String(windowOpacity)))
    OpacitySlider := Reg("Settings", myGui.Add("Slider", "x164 y186 w324 Range150-255 TickInterval5", windowOpacity))
    OpacitySlider.OnEvent("Change", UpdateOpacity)
    myGui.SetFont("s9 cDDDDDD", "Segoe UI")
    BlurToggleChk := Reg("Settings", myGui.Add("Checkbox", "x164 y212 w200 h22 Background" . cardBg . (blurEnabled ? " Checked" : ""), "Blur background"))
    BlurToggleChk.OnEvent("Click", ToggleBlur)
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    Reg("Settings", myGui.Add("Text", "x164 y242 w200 h18 BackgroundTrans", "HOTKEYS"))
    myGui.SetFont("s9 cBBBBBB", "Segoe UI")
    Reg("Settings", myGui.Add("Text", "x164 y264 w110 h24 BackgroundTrans", "Show / Hide"))
    ShowHotkeyCtrl := Reg("Settings", myGui.Add("Hotkey", "x280 y262 w180 h24", showHotkey))
    ShowHotkeyCtrl.OnEvent("Change", OnShowHotkeyChange)
    Reg("Settings", myGui.Add("Text", "x164 y292 w110 h24 BackgroundTrans", "Toggle clicker"))
    ToggleHotkeyCtrl := Reg("Settings", myGui.Add("Hotkey", "x280 y290 w180 h24", toggleHotkey))
    ToggleHotkeyCtrl.OnEvent("Change", OnToggleHotkeyChange)

    ; ================= PAGE: TRIGGERBOT =================
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    TriggerCard := Reg("Trigger", myGui.Add("Progress", "x148 y72 w356 h240 -Theme Background" . cardBg . " c" . cardBg . " Disabled", 100))
    Reg("Trigger", myGui.Add("Text", "x164 y84 w200 h18 BackgroundTrans", "TRIGGERBOT"))
    myGui.SetFont("s9 cDDDDDD", "Segoe UI")
    TriggerChk := Reg("Trigger", myGui.Add("Checkbox", "x164 y106 w150 h22 Background" . cardBg . (triggerEnabled ? " Checked" : ""), "Enable triggerbot"))
    TriggerChk.OnEvent("Click", ToggleTrigger)
    TriggerModeDDL := Reg("Trigger", myGui.Add("DropDownList", "x320 y104 w168", ["Always on", "Hold RButton", "Hold XButton2"]))
    TriggerModeDDL.Text := triggerMode
    TriggerModeDDL.OnEvent("Change", UpdateTriggerMode)
    myGui.SetFont("s9 cBBBBBB", "Segoe UI")
    Reg("Trigger", myGui.Add("Text", "x164 y132 w324 h18 BackgroundTrans", "Enemy colors - any match fires"))
    TrigPrev1 := Reg("Trigger", myGui.Add("Text", "x164 y152 w36 h24 BackgroundFF0000 +Border", ""))
    TrigHex1 := Reg("Trigger", myGui.Add("Edit", "x208 y152 w100 h24", SubStr(triggerColors[1], 3)))
    TrigHex1.OnEvent("Change", (*) => UpdateTriggerHex(1))
    pick1 := Reg("Trigger", myGui.Add("Button", "x316 y152 w64 h24", "Pick"))
    pick1.OnEvent("Click", (*) => StartPick(1))
    TrigPrev2 := Reg("Trigger", myGui.Add("Text", "x164 y180 w36 h24 BackgroundFFFF00 +Border", ""))
    TrigHex2 := Reg("Trigger", myGui.Add("Edit", "x208 y180 w100 h24", SubStr(triggerColors[2], 3)))
    TrigHex2.OnEvent("Change", (*) => UpdateTriggerHex(2))
    pick2 := Reg("Trigger", myGui.Add("Button", "x316 y180 w64 h24", "Pick"))
    pick2.OnEvent("Click", (*) => StartPick(2))
    TrigPrev3 := Reg("Trigger", myGui.Add("Text", "x164 y208 w36 h24 BackgroundFF00FF +Border", ""))
    TrigHex3 := Reg("Trigger", myGui.Add("Edit", "x208 y208 w100 h24", SubStr(triggerColors[3], 3)))
    TrigHex3.OnEvent("Change", (*) => UpdateTriggerHex(3))
    pick3 := Reg("Trigger", myGui.Add("Button", "x316 y208 w64 h24", "Pick"))
    pick3.OnEvent("Click", (*) => StartPick(3))
    Reg("Trigger", myGui.Add("Text", "x164 y240 w140 h18 BackgroundTrans", "Tolerance"))
    TriggerTolVal := Reg("Trigger", myGui.Add("Text", "x274 y240 w40 h18 Right BackgroundTrans", String(triggerTol)))
    Reg("Trigger", myGui.Add("Text", "x330 y240 w84 h18 BackgroundTrans", "Shot delay"))
    TriggerDelayVal := Reg("Trigger", myGui.Add("Text", "x414 y240 w74 h18 Right BackgroundTrans", String(triggerDelay) . " ms"))
    TriggerTolSlider := Reg("Trigger", myGui.Add("Slider", "x164 y260 w150 Range0-60 TickInterval10", triggerTol))
    TriggerTolSlider.OnEvent("Change", UpdateTriggerTol)
    TriggerDelaySlider := Reg("Trigger", myGui.Add("Slider", "x330 y260 w158 Range0-500 TickInterval50", triggerDelay))
    TriggerDelaySlider.OnEvent("Change", UpdateTriggerDelay)
    myGui.SetFont("s8 c666666", "Segoe UI")
    Reg("Trigger", myGui.Add("Text", "x164 y286 w324 h18 Center BackgroundTrans", "pick shades per map so every skybox works"))

    ; ================= PAGE: BUNNYHOP =================
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    Card5 := Reg("Bunny", myGui.Add("Progress", "x148 y72 w356 h232 -Theme Background" . cardBg . " c" . cardBg . " Disabled", 100))
    Reg("Bunny", myGui.Add("Text", "x164 y84 w200 h18 BackgroundTrans", "BUNNYHOP"))
    myGui.SetFont("s9 cDDDDDD", "Segoe UI")
    BhopChk := Reg("Bunny", myGui.Add("Checkbox", "x164 y106 w220 h22 Background" . cardBg . (bhopEnabled ? " Checked" : ""), "Enable bunnyhop"))
    BhopChk.OnEvent("Click", ToggleBhop)
    StrafeChk := Reg("Bunny", myGui.Add("Checkbox", "x164 y130 w220 h22 Background" . cardBg . (bhopStrafe ? " Checked" : ""), "Auto-strafe (CS2 style)"))
    StrafeChk.OnEvent("Click", ToggleStrafe)
    myGui.SetFont("s9 cBBBBBB", "Segoe UI")
    Reg("Bunny", myGui.Add("Text", "x164 y158 w150 h18 BackgroundTrans", "Jump delay"))
    BhopDelayVal := Reg("Bunny", myGui.Add("Text", "x414 y158 w74 h18 Right BackgroundTrans", String(bhopDelay) . " ms"))
    BhopDelaySlider := Reg("Bunny", myGui.Add("Slider", "x164 y180 w324 Range10-150 TickInterval10", bhopDelay))
    BhopDelaySlider.OnEvent("Change", UpdateBhopDelay)
    myGui.SetFont("s8 c666666", "Segoe UI")
    Reg("Bunny", myGui.Add("Text", "x164 y208 w324 h18 Center BackgroundTrans", "hold SPACE - jumps + strafes like CS2"))

    ; ================= PAGE: E-DASH =================
    myGui.SetFont("s9 c888888", "Segoe UI Semibold")
    EdashCard := Reg("Edash", myGui.Add("Progress", "x148 y72 w356 h176 -Theme Background" . cardBg . " c" . cardBg . " Disabled", 100))
    Reg("Edash", myGui.Add("Text", "x164 y84 w200 h18 BackgroundTrans", "E-DASH (EVADE)"))
    myGui.SetFont("s9 cDDDDDD", "Segoe UI")
    EdashChk := Reg("Edash", myGui.Add("Checkbox", "x164 y106 w220 h22 Background" . cardBg . (edashEnabled ? " Checked" : ""), "Enable E-dash"))
    EdashChk.OnEvent("Click", ToggleEdash)
    myGui.SetFont("s9 cBBBBBB", "Segoe UI")
    Reg("Edash", myGui.Add("Text", "x164 y134 w80 h23 BackgroundTrans", "Trigger"))
    EdashModeDDL := Reg("Edash", myGui.Add("DropDownList", "x250 y132 w210", ["Hold E", "Hold W", "Always on"]))
    EdashModeDDL.Text := edashMode
    EdashModeDDL.OnEvent("Change", UpdateEdashMode)
    Reg("Edash", myGui.Add("Text", "x164 y162 w150 h18 BackgroundTrans", "Dash interval"))
    EdashDelayVal := Reg("Edash", myGui.Add("Text", "x414 y162 w74 h18 Right BackgroundTrans", String(edashDelay) . " ms"))
    EdashDelaySlider := Reg("Edash", myGui.Add("Slider", "x164 y184 w324 Range100-2000 TickInterval100", edashDelay))
    EdashDelaySlider.OnEvent("Change", UpdateEdashDelay)
    myGui.SetFont("s8 c666666", "Segoe UI")
    Reg("Edash", myGui.Add("Text", "x164 y212 w324 h18 Center BackgroundTrans", "spams E for Evade dashing"))

    ; ---------- FOOTER (always visible) ----------
    myGui.SetFont("s8 c777777", "Segoe UI")
    FooterText := myGui.Add("Text", "x148 y352 w356 h18 Center BackgroundTrans", "")

    if (AccentDot != "")
        AccentDot.SetFont("c" . currentAccent)
    RecoilValue.SetFont("cFFFFFF")

    SwitchPage("Dash")

    ; built hidden - shown after the loader finishes
    ; (transparency is applied by ApplyBlur after Show, since the HWND
    ;  doesn't exist until then)
    UpdateStatusUI()
    RefreshDashboard()
}

; ================= GUI LOGIC =================
UpdateRecoil(ctrl, *) {
    global RecoilValue, recoilStrength
    recoilStrength := ctrl.Value
    RecoilValue.Text := String(ctrl.Value)
    RefreshDashboard()
}

ToggleRecoil(ctrl, *) {
    global useRecoil
    useRecoil := ctrl.Value ? true : false
    RefreshDashboard()
}

ToggleMaster(ctrl, *) {
    global macrosEnabled
    macrosEnabled := ctrl.Value ? true : false
    SaveSettings()
    RefreshDashboard()
}

ToggleBlur(ctrl, *) {
    global blurEnabled
    blurEnabled := ctrl.Value ? true : false
    ApplyBlur()
    SaveSettings()
}

ToggleTop(ctrl, *) {
    global myGui, alwaysTop
    alwaysTop := ctrl.Value ? true : false
    WinSetAlwaysOnTop(alwaysTop ? 1 : 0, "ahk_id " . myGui.Hwnd)
}

UpdateOpacity(ctrl, *) {
    global OpacityVal, windowOpacity, blurAlpha, myGui
    windowOpacity := ctrl.Value
    OpacityVal.Text := String(ctrl.Value)
    WinSetTransparent(windowOpacity, "ahk_id " . myGui.Hwnd)
    ; feed blur tint alpha so blur gets denser with opacity: 150->120, 255->230
    blurAlpha := Round((windowOpacity - 150) / 105 * 110) + 120
    blurAlpha := ClampV(blurAlpha, 110, 230)
    ApplyBlur(false)
    SaveSettings()
}

DragGui(*) {
    global myGui
    PostMessage(0xA1, 2, 0, , "ahk_id " . myGui.Hwnd)
}

GuiMinimize(*) {
    global myGui
    myGui.Minimize()
}

GuiClose(*) {
    ExitApp()
}

GuiEscape(*) {
    global myGui, guiVisible, pickingSlot
    if (pickingSlot > 0) {
        pickingSlot := 0
        SetTimer(PickTipFollow, 0)
        ToolTip()
        return
    }
    myGui.Hide()
    guiVisible := false
}

; ================= CUSTOM HOTKEYS =================
RegisterHotkeys() {
    global showHotkey, toggleHotkey, ShowHotkeyCtrl, ToggleHotkeyCtrl
    static showOn := "", toggleOn := ""
    if (showOn != "") {
        try Hotkey(showOn, "Off")
    }
    if (toggleOn != "") {
        try Hotkey(toggleOn, "Off")
    }
    try {
        Hotkey(showHotkey, ToggleGui, "On")
    } catch {
        showHotkey := "F2"
        ShowHotkeyCtrl.Value := "F2"
        Hotkey(showHotkey, ToggleGui, "On")
    }
    showOn := showHotkey
    try {
        Hotkey("*" . toggleHotkey, ToggleClicker, "On")
    } catch {
        toggleHotkey := "z"
        ToggleHotkeyCtrl.Value := "z"
        Hotkey("*" . toggleHotkey, ToggleClicker, "On")
    }
    toggleOn := "*" . toggleHotkey
    UpdateFooter()
}

OnShowHotkeyChange(ctrl, *) {
    global showHotkey
    newKey := ctrl.Value
    if (newKey = "" || StrLower(newKey) = StrLower(showHotkey))
        return
    old := showHotkey
    try {
        Hotkey(old, "Off")
        Hotkey(newKey, ToggleGui, "On")
    } catch {
        ctrl.Value := old
        return
    }
    showHotkey := newKey
    UpdateFooter()
    SaveSettings()
}

OnToggleHotkeyChange(ctrl, *) {
    global toggleHotkey
    newKey := ctrl.Value
    if (newKey = "" || StrLower(newKey) = StrLower(toggleHotkey))
        return
    old := toggleHotkey
    try {
        Hotkey("*" . old, "Off")
        Hotkey("*" . newKey, ToggleClicker, "On")
    } catch {
        ctrl.Value := old
        return
    }
    toggleHotkey := newKey
    UpdateFooter()
    SaveSettings()
}

ToggleGui(*) {
    global myGui, guiVisible
    if (guiVisible) {
        myGui.Hide()
        guiVisible := false
    } else {
        myGui.Show("x5 y5 w520 h384")
        guiVisible := true
        ApplyBlur()
    }
}

ToggleClicker(*) {
    global autoClickEnabled
    autoClickEnabled := !autoClickEnabled
    UpdateStatusUI()
    RefreshDashboard()
    MouseGetPos(&mx, &my)
    if (autoClickEnabled)
        ToolTip("flyshit on", mx + 15, my + 15)
    else
        ToolTip("flyshit off", mx + 15, my + 15)
    SetTimer(HideToolTip, -800)
}

UpdateFooter() {
    global FooterText, StatusHint, showHotkey, toggleHotkey
    FooterText.Text := StrUpper(showHotkey) . "  show/hide  ·  " . StrUpper(toggleHotkey) . "  toggle clicker  ·  drag top bar to move"
    StatusHint.Text := "press  " . StrUpper(toggleHotkey) . "  to toggle"
}

RefreshDashboard() {
    global DashMacros, DashClicker, DashRecoil, DashBhop, DashEdash, DashTrigger, DashLicense
    global licPlan, licDaysLeft
    global macrosEnabled, autoClickEnabled, useRecoil, recoilStrength
    global bhopEnabled, bhopDelay, bhopStrafe
    global edashEnabled, edashDelay
    DashMacros.Text := macrosEnabled ? "ENABLED" : "DISABLED"
    DashMacros.SetFont(macrosEnabled ? "c4ADE80" : "cFF5555")
    DashClicker.Text := autoClickEnabled ? "ON" : "OFF"
    DashClicker.SetFont(autoClickEnabled ? "c4ADE80" : "cFF5555")
    DashRecoil.Text := useRecoil ? "ON · " . recoilStrength : "OFF"
    DashRecoil.SetFont(useRecoil ? "c4ADE80" : "cFF5555")
    DashBhop.Text := bhopEnabled ? "ON · " . bhopDelay . "ms" . (bhopStrafe ? " +strafe" : "") : "OFF"
    DashBhop.SetFont(bhopEnabled ? "c4ADE80" : "cFF5555")
    DashEdash.Text := edashEnabled ? "ON · " . edashDelay . "ms" : "OFF"
    DashEdash.SetFont(edashEnabled ? "c4ADE80" : "cFF5555")
    DashTrigger.Text := triggerEnabled ? "ON" : "OFF"
    DashTrigger.SetFont(triggerEnabled ? "c4ADE80" : "cFF5555")
    if (licDaysLeft < 0) {
        DashLicense.Text := "Lifetime"
        DashLicense.SetFont("c4ADE80")
    } else if (licDaysLeft > 3) {
        DashLicense.Text := licDaysLeft . "d left"
        DashLicense.SetFont("c4ADE80")
    } else {
        DashLicense.Text := licDaysLeft . "d left"
        DashLicense.SetFont("cFFB020")
    }
}

PresetLabel(bg) {
    u := StrUpper(bg)
    if (u = "151515")
        return "Midnight  #151515"
    if (u = "2B2B40")
        return "Lavender  #2B2B40"
    if (u = "0E141B")
        return "Ocean  #0E141B"
    if (u = "0F1511")
        return "Forest  #0F1511"
    if (u = "1A0F12")
        return "Crimson  #1A0F12"
    if (u = "171009")
        return "Sunset  #171009"
    return "Custom  #" . u
}

IsBindable(key) {
    try {
        Hotkey(key, (*) => 0)
        Hotkey(key, "Off")
        return true
    } catch {
        return false
    }
}

LoadSettings() {
    global showHotkey, toggleHotkey, currentBg, currentAccent, windowOpacity, blurEnabled, blurAlpha
    global bhopEnabled, bhopDelay, bhopStrafe, macrosEnabled
    global edashEnabled, edashDelay, edashMode
    global triggerEnabled, triggerMode, triggerColors, triggerTol, triggerDelay
    path := A_ScriptDir . "\Flyshit.ini"
    macrosEnabled := IniRead(path, "General", "Macros", "1") = "1"
    showHotkey := IniRead(path, "Hotkeys", "ShowHide", "F2")
    toggleHotkey := IniRead(path, "Hotkeys", "Toggle", "z")
    if (showHotkey = "" || !IsBindable(showHotkey))
        showHotkey := "F2"
    if (toggleHotkey = "" || !IsBindable("*" . toggleHotkey))
        toggleHotkey := "z"
    currentBg := StrUpper(IniRead(path, "Appearance", "Bg", currentBg))
    if (!RegExMatch(currentBg, "^[0-9A-F]{6}$"))
        currentBg := "151515"
    currentAccent := StrUpper(IniRead(path, "Appearance", "Accent", currentAccent))
    if (!RegExMatch(currentAccent, "^[0-9A-F]{6}$"))
        currentAccent := "7C5CFF"
    tmpOp := IniRead(path, "Appearance", "Opacity", String(windowOpacity))
    windowOpacity := IsInteger(tmpOp) ? ClampV(Integer(tmpOp), 150, 255) : 235
    blurEnabled := IniRead(path, "Appearance", "Blur", blurEnabled ? "1" : "0") = "1"
    blurAlpha := ClampV(Round((windowOpacity - 150) / 105 * 110) + 120, 110, 230)
    tmpBh := IniRead(path, "Bhop", "Delay", String(bhopDelay))
    bhopDelay := IsInteger(tmpBh) ? ClampV(Integer(tmpBh), 10, 150) : 40
    bhopEnabled := IniRead(path, "Bhop", "Enabled", "0") = "1"
    bhopStrafe := IniRead(path, "Bhop", "Strafe", "0") = "1"
    tmpEd := IniRead(path, "Edash", "Delay", String(edashDelay))
    edashDelay := IsInteger(tmpEd) ? ClampV(Integer(tmpEd), 100, 2000) : 500
    edashEnabled := IniRead(path, "Edash", "Enabled", "0") = "1"
    edashMode := IniRead(path, "Edash", "Mode", edashMode)
    if (edashMode != "Hold E" && edashMode != "Hold W" && edashMode != "Always on")
        edashMode := "Hold E"
    oldC := StrUpper(IniRead(path, "Trigger", "Color", ""))
    c1 := StrUpper(IniRead(path, "Trigger", "Color1", oldC != "" ? oldC : "0xFF0000"))
    c2 := StrUpper(IniRead(path, "Trigger", "Color2", "0xFFFF00"))
    c3 := StrUpper(IniRead(path, "Trigger", "Color3", "0xFF00FF"))
    allNew := ["0xFF0000", "0xFFFF00", "0xFF00FF"]
    triggerColors := [c1, c2, c3]
    for i, c in triggerColors {
        if (!RegExMatch(c, "^0x[0-9A-F]{6}$"))
            triggerColors[i] := allNew[i]
    }
    triggerMode := IniRead(path, "Trigger", "Mode", triggerMode)
    if (triggerMode != "Always on" && triggerMode != "Hold RButton" && triggerMode != "Hold XButton2")
        triggerMode := "Hold RButton"
    tmpTol := IniRead(path, "Trigger", "Tol", String(triggerTol))
    triggerTol := IsInteger(tmpTol) ? ClampV(Integer(tmpTol), 0, 60) : 10
    tmpTd := IniRead(path, "Trigger", "Delay", String(triggerDelay))
    triggerDelay := IsInteger(tmpTd) ? ClampV(Integer(tmpTd), 0, 500) : 20
    triggerEnabled := IniRead(path, "Trigger", "Enabled", "0") = "1"
}

SaveSettings() {
    global showHotkey, toggleHotkey, currentBg, currentAccent, windowOpacity, blurEnabled
    global bhopEnabled, bhopDelay, bhopStrafe, macrosEnabled
    global edashEnabled, edashDelay, edashMode
    global triggerEnabled, triggerMode, triggerColors, triggerTol, triggerDelay
    path := A_ScriptDir . "\Flyshit.ini"
    IniWrite(macrosEnabled ? "1" : "0", path, "General", "Macros")
    IniWrite(showHotkey, path, "Hotkeys", "ShowHide")
    IniWrite(toggleHotkey, path, "Hotkeys", "Toggle")
    IniWrite(currentBg, path, "Appearance", "Bg")
    IniWrite(currentAccent, path, "Appearance", "Accent")
    IniWrite(String(windowOpacity), path, "Appearance", "Opacity")
    IniWrite(blurEnabled ? "1" : "0", path, "Appearance", "Blur")
    IniWrite(String(bhopDelay), path, "Bhop", "Delay")
    IniWrite(bhopEnabled ? "1" : "0", path, "Bhop", "Enabled")
    IniWrite(bhopStrafe ? "1" : "0", path, "Bhop", "Strafe")
    IniWrite(String(edashDelay), path, "Edash", "Delay")
    IniWrite(edashEnabled ? "1" : "0", path, "Edash", "Enabled")
    IniWrite(edashMode, path, "Edash", "Mode")
    IniWrite(triggerColors[1], path, "Trigger", "Color1")
    IniWrite(triggerColors[2], path, "Trigger", "Color2")
    IniWrite(triggerColors[3], path, "Trigger", "Color3")
    IniWrite(triggerMode, path, "Trigger", "Mode")
    IniWrite(String(triggerTol), path, "Trigger", "Tol")
    IniWrite(String(triggerDelay), path, "Trigger", "Delay")
    IniWrite(triggerEnabled ? "1" : "0", path, "Trigger", "Enabled")
}

CustomBg(*) {
    global myGui, currentBg, currentAccent
    ib := InputBox("Enter hex color (e.g. 1A1A2E or #1A1A2E):", "Custom background", , currentBg)
    if (ib.Result != "OK")
        return
    newHex := RegExReplace(ib.Value, "^\s*#?\s*|\s*$")
    if (!RegExMatch(newHex, "^[0-9A-Fa-f]{6}$")) {
        MsgBox("Please enter 6 hex digits, e.g.`n1A1A2E", "Invalid color", 48)
        return
    }
    newHex := StrUpper(newHex)
    ApplyTheme(newHex, currentAccent, "Custom  #" . newHex)
}

ApplyTheme(bg, accent, label := "") {
    global myGui, currentBg, currentAccent, cardBg, topBg, currentPage
    global TopBar, SideBar, Card1, Card2, Card3, Card4, Card5, DashCard, EdashCard, TriggerCard, BgName, AccentDot, TitleText
    global UseRecoilChk, TopToggleChk, BlurToggleChk, BhopChk, MasterChk
    global EdashChk, StrafeChk, TriggerChk
    currentBg := bg
    currentAccent := accent
    cardBg := Lighten(bg, 16)
    topBg := Lighten(bg, -8)

    myGui.BackColor := bg
    TopBar.Opt("+Background" . topBg . " +c" . topBg)
    SideBar.Opt("+Background" . topBg . " +c" . topBg)
    MasterChk.Opt("+Background" . topBg)
    Card1.Opt("+Background" . cardBg . " +c" . cardBg)
    Card2.Opt("+Background" . cardBg . " +c" . cardBg)
    Card3.Opt("+Background" . cardBg . " +c" . cardBg)
    Card5.Opt("+Background" . cardBg . " +c" . cardBg)
    DashCard.Opt("+Background" . cardBg . " +c" . cardBg)
    EdashCard.Opt("+Background" . cardBg . " +c" . cardBg)
    TriggerCard.Opt("+Background" . cardBg . " +c" . cardBg)
    UseRecoilChk.Opt("+Background" . cardBg)
    TopToggleChk.Opt("+Background" . cardBg)
    BlurToggleChk.Opt("+Background" . cardBg)
    BhopChk.Opt("+Background" . cardBg)
    StrafeChk.Opt("+Background" . cardBg)
    EdashChk.Opt("+Background" . cardBg)
    TriggerChk.Opt("+Background" . cardBg)
    if (label != "")
        BgName.Text := label
    if (AccentDot != "")
        AccentDot.SetFont("c" . accent)
    TitleText.SetFont("cFFFFFF")
    SwitchPage(currentPage)
    LayoutNav()
    ApplyBlur()
    SaveSettings()
}

UpdateStatusUI() {
    global autoClickEnabled, StatusText, PillBg
    if (autoClickEnabled) {
        StatusText.SetFont("c4ADE80")
        StatusText.Text := "ENABLED"
        PillBg.Opt("+Background1A2E22 +c1A2E22")
    } else {
        StatusText.SetFont("cFF5555")
        StatusText.Text := "DISABLED"
        PillBg.Opt("+Background2A2A2A +c2A2A2A")
    }
}

; ================= TRIGGERBOT =================
ToggleTrigger(ctrl, *) {
    global triggerEnabled
    triggerEnabled := ctrl.Value ? true : false
    SaveSettings()
    RefreshDashboard()
}

UpdateTriggerMode(ctrl, *) {
    global triggerMode
    triggerMode := ctrl.Text
    SaveSettings()
}

UpdateTriggerHex(slot) {
    global triggerColors, TrigHex1, TrigHex2, TrigHex3, TrigPrev1, TrigPrev2, TrigPrev3
    edits := [TrigHex1, TrigHex2, TrigHex3]
    prevs := [TrigPrev1, TrigPrev2, TrigPrev3]
    edit := edits[slot]
    prev := prevs[slot]
    v := RegExReplace(edit.Text, "^\s*#?\s*|\s*$")
    if (RegExMatch(v, "^[0-9A-Fa-f]{6}$")) {
        triggerColors[slot] := "0x" . StrUpper(v)
        prev.Opt("+Background" . StrUpper(v))
        SaveSettings()
    }
}

ApplyTriggerSlot(slot, hex) {
    global triggerColors, TrigHex1, TrigHex2, TrigHex3, TrigPrev1, TrigPrev2, TrigPrev3
    hex := StrUpper(RegExReplace(hex, "^\s*#?\s*|\s*$"))
    if (!RegExMatch(hex, "^[0-9A-F]{6}$"))
        return
    triggerColors[slot] := "0x" . hex
    edits := [TrigHex1, TrigHex2, TrigHex3]
    prevs := [TrigPrev1, TrigPrev2, TrigPrev3]
    edits[slot].Value := hex
    prevs[slot].Opt("+Background" . hex)
    SaveSettings()
}

StartPick(slot) {
    global pickingSlot
    pickingSlot := slot
    ToolTip("Aim at an enemy pixel and LEFT-CLICK (Esc cancels)")
    SetTimer(PickTipFollow, 50)
}

PickTipFollow() {
    MouseGetPos(&mx, &my)
    ToolTip("Aim at an enemy pixel and LEFT-CLICK (Esc cancels)", mx + 15, my + 15)
}

UpdateTriggerTol(ctrl, *) {
    global triggerTol, TriggerTolVal
    triggerTol := ctrl.Value
    TriggerTolVal.Text := String(ctrl.Value)
    SaveSettings()
}

UpdateTriggerDelay(ctrl, *) {
    global triggerDelay, TriggerDelayVal
    triggerDelay := ctrl.Value
    TriggerDelayVal.Text := String(ctrl.Value) . " ms"
    SaveSettings()
}

; pixel triggerbot: fires when ANY registered enemy color appears at screen center
TriggerLoop() {
    global triggerEnabled, triggerMode, triggerColors, triggerTol, triggerDelay, macrosEnabled, pickingSlot
    static lastShot := 0
    if (pickingSlot > 0 || !macrosEnabled || !triggerEnabled || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
        return
    if (triggerMode = "Hold RButton" && !GetKeyState("RButton", "P"))
        return
    if (triggerMode = "Hold XButton2" && !GetKeyState("XButton2", "P"))
        return
    cx := A_ScreenWidth // 2
    cy := A_ScreenHeight // 2
    try {
        hit := false
        for c in triggerColors {
            if (PixelSearch(&fx, &fy, cx - 6, cy - 6, cx + 6, cy + 6, c, triggerTol)) {
                hit := true
                break
            }
        }
        if (hit) {
            now := A_TickCount
            if (now - lastShot >= triggerDelay) {
                DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0)
                DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0)
                lastShot := now
            }
        }
    } catch {
    }
}

; click-capture for the triggerbot color picker (Esc cancels via GuiEscape)
~LButton:: {
    global pickingSlot
    if (pickingSlot <= 0)
        return
    slot := pickingSlot
    pickingSlot := 0
    SetTimer(PickTipFollow, 0)
    ToolTip()
    MouseGetPos(&mx, &my)
    try {
        ApplyTriggerSlot(slot, SubStr(PixelGetColor(mx, my), 3))
    } catch {
    }
}

; ================= TOGGLE =================

HideToolTip() {
    ToolTip()
}

; ================= BUNNYHOP =================
ToggleBhop(ctrl, *) {
    global bhopEnabled
    bhopEnabled := ctrl.Value ? true : false
    SaveSettings()
    RefreshDashboard()
}

ToggleStrafe(ctrl, *) {
    global bhopStrafe
    bhopStrafe := ctrl.Value ? true : false
    SaveSettings()
    RefreshDashboard()
}

UpdateBhopDelay(ctrl, *) {
    global bhopDelay, BhopDelayVal
    bhopDelay := ctrl.Value
    BhopDelayVal.Text := String(ctrl.Value) . " ms"
    SaveSettings()
    RefreshDashboard()
}

; timer-driven CS2-style bhop: auto-jump + alternating A/D strafes while SPACE is held
BhopLoop() {
    global bhopEnabled, bhopDelay, bhopStrafe, macrosEnabled, pickingSlot
    global edashEnabled, edashDelay, edashMode
    global triggerEnabled, triggerMode, triggerColors, triggerTol, triggerDelay
        static lastJump := 0, lastStrafe := 0, dir := false
    if (pickingSlot > 0 || !macrosEnabled || !bhopEnabled || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
        return
    if (!GetKeyState("Space", "P"))
        return
    now := A_TickCount
    if (now - lastJump >= bhopDelay) {
        SendInput("{Blind}{Space}")
        lastJump := now
    }
    if (bhopStrafe && now - lastStrafe >= 100) {
        dir := !dir
        SendInput("{Blind}{" . (dir ? "a" : "d") . "}")
        lastStrafe := now
    }
}

; ================= E-DASH (EVADE) =================
ToggleEdash(ctrl, *) {
    global edashEnabled
    edashEnabled := ctrl.Value ? true : false
    SaveSettings()
    RefreshDashboard()
}

UpdateEdashMode(ctrl, *) {
    global edashMode
    edashMode := ctrl.Text
    SaveSettings()
}

UpdateEdashDelay(ctrl, *) {
    global edashDelay, EdashDelayVal
    edashDelay := ctrl.Value
    EdashDelayVal.Text := String(ctrl.Value) . " ms"
    SaveSettings()
    RefreshDashboard()
}

; timer-driven: re-presses E on an interval while the trigger is held (Evade dash)
EdashLoop() {
    global edashEnabled, edashDelay, edashMode, macrosEnabled, pickingSlot
    static lastDash := 0
    if (pickingSlot > 0 || !macrosEnabled || !edashEnabled || !WinActive("ahk_exe RobloxPlayerBeta.exe"))
        return
    active := false
    if (edashMode = "Always on")
        active := true
    else if (edashMode = "Hold W")
        active := GetKeyState("w", "P")
    else
        active := GetKeyState("e", "P")
    if (!active)
        return
    now := A_TickCount
    if (now - lastDash >= edashDelay) {
        SendInput("{Blind}{e}")
        lastDash := now
    }
}

; ================= AUTOCLICKER =================
#HotIf WinActive("ahk_exe RobloxPlayerBeta.exe")
~*LButton:: {
    global autoClickEnabled, useRecoil, recoilStrength, macrosEnabled, pickingSlot
    while GetKeyState("LButton", "P") && autoClickEnabled && macrosEnabled && !pickingSlot {
        DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0)
        DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0)
        if (useRecoil && recoilStrength > 0) {
            recoilAmount := Round(recoilStrength * 0.15)
            DllCall("mouse_event", "UInt", 0x0001, "UInt", 0, "UInt", recoilAmount)
        }
        Sleep(1)
    }
}
#HotIf

; ================= BLUR / ACRYLIC =================
ApplyBlur(applyOpacity := true) {
    global myGui, currentBg, blurEnabled, blurAlpha, windowOpacity
    if (!myGui || !WinExist("ahk_id " . myGui.Hwnd))
        return
    if (blurEnabled) {
        tint := HexToABGR(currentBg, blurAlpha)
        SetAcrylic(myGui.Hwnd, 4, tint) ; 4 = acrylic, falls back gracefully
    } else {
        SetAcrylic(myGui.Hwnd, 0, 0)    ; disable accent -> solid
    }
    if (applyOpacity)
        WinSetTransparent(windowOpacity, "ahk_id " . myGui.Hwnd)
    RoundCorners(myGui.Hwnd)
}

SetAcrylic(hwnd, state, tint) {
    accent := Buffer(16, 0)
    NumPut("Int", state, accent, 0)
    NumPut("Int", 2, accent, 4)
    NumPut("UInt", tint, accent, 8)
    NumPut("UInt", 0, accent, 12)
    dataSize := (A_PtrSize = 8) ? 24 : 12
    data := Buffer(dataSize, 0)
    NumPut("Int", 19, data, 0) ; WCA_ACCENT_POLICY = 19
    if (A_PtrSize = 8) {
        NumPut("Ptr", accent.Ptr, data, 8)
        NumPut("UInt", 16, data, 16)
    } else {
        NumPut("Ptr", accent.Ptr, data, 4)
        NumPut("UInt", 16, data, 8)
    }
    DllCall("user32\SetWindowCompositionAttribute", "Ptr", hwnd, "Ptr", data.Ptr)
}

RoundCorners(hwnd) {
    buf := Buffer(4, 0)
    NumPut("Int", 2, buf, 0)
    ; DWMWA_WINDOW_CORNER_PREFERENCE = 33, DWMWCP_ROUND = 2 (Win11, ignored elsewhere)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 33, "Ptr", buf.Ptr, "UInt", 4)
}

HexToABGR(hex, alpha) {
    hex := RegExReplace(hex, "^#")
    r := Integer("0x" . SubStr(hex, 1, 2))
    g := Integer("0x" . SubStr(hex, 3, 2))
    b := Integer("0x" . SubStr(hex, 5, 2))
    return (alpha << 24) | (b << 16) | (g << 8) | r
}

Lighten(hex, amt) {
    hex := RegExReplace(hex, "^#")
    r := ClampV(Integer("0x" . SubStr(hex, 1, 2)) + amt, 0, 255)
    g := ClampV(Integer("0x" . SubStr(hex, 3, 2)) + amt, 0, 255)
    b := ClampV(Integer("0x" . SubStr(hex, 5, 2)) + amt, 0, 255)
    return Format("{:02X}{:02X}{:02X}", r, g, b)
}

ClampV(v, lo, hi) {
    if (v < lo)
        return lo
    if (v > hi)
        return hi
    return v
}
