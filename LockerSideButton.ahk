;LockerSideButton version 1.0.4 (C) 2026 Tatsuhiko Shoji
;The sources for LockerSideButton are distributed under the MIT open source license
/************************************************************************
 * @description LockerSideButton
 * @author 
 * @date 2026/09/22
 * @version 1.0.4
 ***********************************************************************/

#Requires AutoHotkey v2.0
#Warn VarUnset
#Warn LocalSameAsGlobal
#HotIf !WinActive("ahk_exe vmware.exe")

; Use Input mode for more reliable synthesized key delivery
SendMode("Input")

Persistent(true)

ActiveButton := ""
LButtonMonitorStart := 0
LstartX := 0
LstartY := 0
RstartX := 0
RstartY := 0
lastWheelEvent := ""
ByLButton := false
ByRButton := false
LButtonSynthDown := false
RButtonSynthDown := false
logEnabled := false
IsDevEnv := 0

; グローバル変数
PendingNav := ""

; 1回だけ遅延送信する関数（名前で呼ぶ）
DoPendingNav() {
    global PendingNav
    if (PendingNav = "")
        return
    tmp := PendingNav
    PendingNav := ""
    ; 合成 Up 等のクリーンアップ待ち
    Sleep(60)                         
    ; コンテキストメニュー等を閉じる
    Send("{Esc}")
    ; コンテキストメニューが閉じるのを待つ
    ;Sleep(10)                         
    ; Visual Studio 宛に送る（ControlSend の引数順に注意）
    ControlSend(tmp, , "ahk_exe devenv.exe")
    ; 必要ならフォールバック: 
    ;SendInput(tmp)
}

IsHookTarget() {
    return !WinActive("ahk_exe vmware.exe")
}

IsVisualStudio() {
    return IsHookTarget() && WinActive("ahk_exe devenv.exe")
}

; マウス左ボタンフック
$LButton::
{
    global ActiveButton
    global LButtonMonitorStart
    global LstartX
    global LstartY
    global ByLButton
    global ByRButton
    global LButtonSynthDown
    global IsDevEnv

    if (A_PriorHotkey = "LButton" && A_TimeSincePriorHotkey < 50)
        return

    Critical("On")

    Log("L pressed — L:" GetKeyState("LButton","P") " R:" GetKeyState("RButton","P") " A_PriorHotkey:" A_PriorHotkey)
    Log("ActiveButton: " ActiveButton )
    Log("ByRButton: " ByRButton )
    Log("LButtonSynthDown: " LButtonSynthDown)

    ; Another hook guard
    if (ActiveButton != "") {
        Critical("Off")
        return
    }

    if (LButtonSynthDown) {
        Critical("Off")
        return
    }

    ; Start monitoring LButton
    ActiveButton := "L"
    ByLButton := true
    LButtonSynthDown := false
    MouseGetPos(&LstartX, &LstartY)
    LButtonMonitorStart := A_TickCount
    IsDevEnv := WinActive("ahk_exe devenv.exe")

    Log("LButton hotkey start")

    Critical("Off")
 
    SetTimer(LButtonMonitor, 20)
    return
}

; 左ボタン押下後のアクション監視実施関数
LButtonMonitor() {
    global ActiveButton
    global LButtonMonitorStart
    global lastWheelEvent
    global LstartX
    global LstartY
    global ByLButton
    global ByRButton
    global LButtonSynthDown
    global IsDevEnv
    global PendingNav

    static busy := false
    if (busy)
        return
    busy := true

    try {
        if (ActiveButton != "L") {
            return
        }

        ; 左ボタンが離れたら通常のアップを返す
        if (!GetKeyState("LButton", "P")) {
            Log("LButton released normally")
            ;Send("{LButton Down}")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            } else {
                Send("{LButton Down}")
                Send("{LButton Up}")
            }
            SetTimer(LButtonMonitor, 0)
            LButtonSynthDown := false
            ActiveButton := ""
            ByLButton := false
            return
        }

        ; 右ボタンが押されたら中断して XButton2
        if (GetKeyState("RButton", "P")) {
            Log("RButton detected")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            }
            ;Send("{XButton2}")

            if (IsDevEnv != 0) {
                PendingNav := "^+-"
                SetTimer(DoPendingNav, -1)
            } else {
                Click("X2")
            }

            ;KeyWait("RButton")
            SetTimer(LButtonMonitor, 0)
            LButtonSynthDown := false
            ActiveButton := ""
            ByLButton := false
            return
        }

        ; ドラッグ判定
        MouseGetPos(&curX, &curY)
        if (Abs(curX - LstartX) > 4 || Abs(curY - LstartY) > 4) {
            Log("Drag detected by LButton")
            KeyWait("LButton")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            }
            SetTimer(LButtonMonitor, 0)
            ActiveButton := ""
            LButtonSynthDown := false
            ByLButton := false
            return
        }

        ; 開始時にのみ合成 Down を送ってドラッグを成立させる
        if (!LButtonSynthDown) {
            Send("{LButton Down}")
            LButtonSynthDown := true
        }

        ; ホイールは押下状態を持たないため GetKeyState では検知できず、専用ホットキーが立てるフラグで判定する
        if (lastWheelEvent != "") {
            Log(lastWheelEvent " detected")
            KeyWait("LButton")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            }
            SetTimer(LButtonMonitor, 0)
            ActiveButton := ""
            LButtonSynthDown := false
            ByLButton := false
            lastWheelEvent := ""
            return
        }

        ; 長時間の監視は安全のため打ち切る
        if (A_TickCount - LButtonMonitorStart > 2500) {
        ;    Log("LButton monitor timeout")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            } else {
                Send("{LButton Down}")
                Send("{LButton Up}")
            }
            SetTimer(LButtonMonitor, 0)
            ActiveButton := ""
            LButtonSynthDown := false
            ByLButton := false
        }
    } finally {
        busy := false
    }        
}

; マウス右ボタンフック
$RButton::
{
    global ActiveButton
    global RstartX
    global RstartY
    global ByLButton
    global ByRButton
    global RButtonSynthDown
    global IsDevEnv

    Critical("On")

    Log("R pressed — L:" GetKeyState("LButton","P") " R:" GetKeyState("RButton","P") " A_PriorHotkey:" A_PriorHotkey)
    Log("ActiveButton: " ActiveButton)
    Log("ByLButton: " ByLButton )
    Log("RButtonSynthDown: " RButtonSynthDown)

    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < 50)
        return

    ; Another hook guard
    if (ActiveButton) {
        Critical("Off")
        return
    }

    ; Start monitoring RButton
    ActiveButton := "R"
    ByRButton := true
    RButtonSynthDown := false
    MouseGetPos(&RstartX, &RstartY)
    RButtonMonitorStart := A_TickCount
    IsDevEnv := WinActive("ahk_exe devenv.exe")

    Log("RButton hotkey start")

    Critical("Off")

    while(ActiveButton == "R") {
        RButtonMonitor(RButtonMonitorStart)
        ;Log("RButton monitoring loop :" RButtonMonitorActive)
        if (ActiveButton != "R")
            return

        Sleep(20)
    }

    ActiveButton := ""
    RButtonSynthDown := false
    ByRButton := false

    Log("RButton hotkey end")

;    SetTimer(RButtonMonitor, 20)
;    return
}

; 右ボタン押下後のアクション監視実施関数
RButtonMonitor(RButtonMonitorStart) {
    global ActiveButton
    global lastWheelEvent
    global RstartX
    global RstartY
    global RButtonSynthDown
    global ByRButton
    global IsDevEnv
    global PendingNav

    static busy := false
    if (busy)
        return
    busy := true

    ;Log("RButton monitoring")

    try {
        if (ActiveButton != "R") {
            return
        }

        if (!GetKeyState("RButton", "P")) {
            Log("RButton released - normal right click")
            ;Send("{RButton Down}")
            ;Send("{RButton Up}")
            if (RButtonSynthDown) {
                Send("{RButton Up}")
            } else {
                Send("{RButton Down}")
                Send("{RButton Up}")
            }
            RButtonSynthDown := false
            ActiveButton := ""
            ByRButton := false
            ;SetTimer(RButtonMonitor, 0)
            return
        }

        if (GetKeyState("LButton", "P")) {
            Log("LButton detected")
            if (RButtonSynthDown) {
                Send("{RButton Up}")
            }
            ;Send("{XButton1}")

            if (IsDevEnv != 0) {
                PendingNav := "^-"
                SetTimer(DoPendingNav, -1)
            } else {
                Click("X1")
            }

            ;KeyWait("LButton")
            ActiveButton := ""
            RButtonSynthDown := false
            ByRButton := false
            ;SetTimer(RButtonMonitor, 0)
            return
        }

        MouseGetPos(&curX, &curY)
        if (Abs(curX - RstartX) > 4 || Abs(curY - RstartY) > 4) {
            Log("Drag detected by RButton")
            KeyWait("RButton")
            ;SetTimer(RButtonMonitor, 0)
            if (RButtonSynthDown) {
                Send("{RButton Up}")
            }
            ActiveButton := ""
            RButtonSynthDown := false
            ByRButton := false
            return
        }

        ; 開始時にのみ合成 Down を送ってドラッグを成立させる
        if (!RButtonSynthDown) {
            Send("{RButton Down}")
            RButtonSynthDown := true
        }

        if (lastWheelEvent != "") {
            Log(lastWheelEvent " detected")
            KeyWait("RButton")
            if (RButtonSynthDown) {
                Send("{RButton Up}")
            }
            ActiveButton := ""
            RButtonSynthDown := false
            ByRButton := false
            lastWheelEvent := ""
            return
        }

        if (A_TickCount - RButtonMonitorStart > 2500) {
        ;    Log("RButton monitor timeout")
            if (RButtonSynthDown) {
                Send("{RButton Up}")
                RButtonSynthDown := false
            } else {
                Send("{RButton Down}")
                Send("{RButton Up}")
            }
            RButtonSynthDown := false
            ActiveButton := ""
            ByRButton := false
            ;SetTimer(RButtonMonitor, 0)
        }
    } finally {
        busy := false
    }        
}

; ホイールは押下状態を持たないため、専用ホットキーでイベントをフラグに記録する
; ホイール下回転フラグ記録フック
WheelDown::
{
    global ActiveButton, lastWheelEvent
    if (ActiveButton != "") {
        lastWheelEvent := "WheelDown"
        ;return
    }
    Send("{WheelDown}")
}

; ホイール上回転フラグ記録フック
WheelUp::
{
    global ActiveButton, lastWheelEvent
    if (ActiveButton != "") {
        lastWheelEvent := "WheelUp"
        ;return
    }
    Send("{WheelUp}")
}

; ホイール左チルトフラグ記録フック
WheelLeft::
{
    global ActiveButton, lastWheelEvent
    if (ActiveButton != "") {
        lastWheelEvent := "WheelLeft"
        ;return
    }
    Send("{WheelLeft}")
}

; ホイール右チルトフラグ記録フック
WheelRight::
{
    global ActiveButton, lastWheelEvent
    if (ActiveButton != "") {
        lastWheelEvent := "WheelRight"
        ;return
    }
    Send("{WheelRight}")
}

; テスト用ログ記録関数
Log(msg)
{
    global logEnabled
    if (!logEnabled)
        return
    FileAppend(
        Format("{1} {2}`n",FormatTime("HH:mm:ss.SSS"),msg),
            "h:\test\mouse-debug.log"
    )
}

F12::Send("^-")
;F12::ControlSend("^-",  ,"ahk_exe devenv.exe")
#HotIf
