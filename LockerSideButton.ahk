;LockerSideButton version 1.0.3 (C) 2026 Tatsuhiko Shoji
;The sources for LockerSideButton are distributed under the MIT open source license

; Version 1.0.3 2026/08/19

#Requires AutoHotkey v2.0

Persistent(true)

LButtonMonitorActive := false
LButtonMonitorStart := 0
RButtonMonitorActive := false
RButtonMonitorStart := 0
startX := 0
startY := 0
lastWheelEvent := ""

LButton::
{
    global LButtonMonitorActive
    global RButtonMonitorActive

    if (A_PriorHotkey = "LButton" && A_TimeSincePriorHotkey < 50)
        return

    if (LButtonMonitorActive)
        return

    if (RButtonMonitorActive)
        return

    LButtonMonitorActive := true
    LButtonMonitorStart := A_TickCount

    Log("LButton hotkey start")
    Send("{LButton Down}")
    SetTimer(LButtonMonitor, 10)
    return
}

LButtonMonitor() {
    global LButtonMonitorActive
    global LButtonMonitorStart
    global lastWheelEvent

    if (!LButtonMonitorActive)
        return

    ; 左ボタンが離れたら通常のアップを返す
    if (!GetKeyState("LButton", "P")) {
        Log("LButton released normally")
        Send("{LButton Up}")
        LButtonMonitorActive := false
        SetTimer(LButtonMonitor, 0)
        return
    }

    ; 右ボタンが押されたら中断して XButton2
    if (GetKeyState("RButton", "P")) {
        Log("RButton detected")
        Send("{LButton Up}")
        Send("{XButton2}")
        LButtonMonitorActive := false
        SetTimer(LButtonMonitor, 0)
        KeyWait("RButton")
        return
    }

    ; ホイールは押下状態を持たないため GetKeyState では検知できず、専用ホットキーが立てるフラグで判定する
    if (lastWheelEvent != "") {
        Log(lastWheelEvent " detected")
        Send("{LButton Up}")
        LButtonMonitorActive := false
        SetTimer(LButtonMonitor, 0)
        lastWheelEvent := ""
        return
    }

    ; 長時間の監視は安全のため打ち切る
    ;if (A_TickCount - LButtonMonitorStart > 1500) {
    ;    Log("LButton monitor timeout")
    ;    Send("{LButton Up}")
    ;    LButtonMonitorActive := false
    ;    SetTimer(LButtonMonitor, 0)
    ;}
}

RButton::
{
    global LButtonMonitorActive
    global RButtonMonitorActive
    global startX
    global startY

    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < 50)
        return

    if (RButtonMonitorActive)
        return

    if (LButtonMonitorActive)
        return

    RButtonMonitorActive := true
    RButtonMonitorStart := A_TickCount

    Log("RButton hotkey start")
    MouseGetPos(&startX, &startY)
    SetTimer(RButtonMonitor, 10)
    return
}

RButtonMonitor() {
    global RButtonMonitorActive
    global RButtonMonitorStart
    global lastWheelEvent
    global startX
    global startY

    if (!RButtonMonitorActive)
        return

    if (!GetKeyState("RButton", "P")) {
        Log("RButton released - normal right click")
        Send("{RButton Down}")
        Send("{RButton Up}")
        RButtonMonitorActive := false
        SetTimer(RButtonMonitor, 0)
        return
    }

    if (GetKeyState("LButton", "P")) {
        Log("LButton detected")
        Send("{XButton1}")
        RButtonMonitorActive := false
        SetTimer(RButtonMonitor, 0)
        KeyWait("LButton")
        return
    }

    MouseGetPos(&curX, &curY)
    if (Abs(curX - startX) > 4 || Abs(curY - startY) > 4) {
        Log("Drag detected")
        Send("{RButton Down}")
        RButtonMonitorActive := false
        SetTimer(RButtonMonitor, 0)
        KeyWait("RButton")
        Send("{RButton Up}")
        return
    }

    if (lastWheelEvent != "") {
        Log(lastWheelEvent " detected")
        Send("{RButton Down}")
        RButtonMonitorActive := false
        SetTimer(RButtonMonitor, 0)
        lastWheelEvent := ""
        KeyWait("RButton")
        Send("{RButton Up}")
        return
    }

    ;if (A_TickCount - RButtonMonitorStart > 1500) {
    ;    Log("RButton monitor timeout")
    ;    Send("{RButton Down}")
    ;    Send("{RButton Up}")
    ;    RButtonMonitorActive := false
    ;    SetTimer(RButtonMonitor, 0)
    ;}
}

; ホイールは押下状態を持たないため、専用ホットキーでイベントをフラグに記録する
WheelDown::
{
    global LButtonMonitorActive, RButtonMonitorActive, lastWheelEvent
    if (LButtonMonitorActive || RButtonMonitorActive) {
        lastWheelEvent := "WheelDown"
        return
    }
    Send("{WheelDown}")
}

WheelUp::
{
    global LButtonMonitorActive, RButtonMonitorActive, lastWheelEvent
    if (LButtonMonitorActive || RButtonMonitorActive) {
        lastWheelEvent := "WheelUp"
        return
    }
    Send("{WheelUp}")
}

WheelLeft::
{
    global LButtonMonitorActive, RButtonMonitorActive, lastWheelEvent
    if (LButtonMonitorActive || RButtonMonitorActive) {
        lastWheelEvent := "WheelLeft"
        return
    }
    Send("{WheelLeft}")
}

WheelRight::
{
    global LButtonMonitorActive, RButtonMonitorActive, lastWheelEvent
    if (LButtonMonitorActive || RButtonMonitorActive) {
        lastWheelEvent := "WheelRight"
        return
    }
    Send("{WheelRight}")
}

Log(msg)
{
    ;FileAppend(
    ;    Format("{1} {2}`n",FormatTime("HH:mm:ss.SSS"),msg),
    ;        "h:\test\mouse-debug.log"
    ;)
}
