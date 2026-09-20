;LockerSideButton version 1.0.4 (C) 2026 Tatsuhiko Shoji
;The sources for LockerSideButton are distributed under the MIT open source license

; Version 1.0.4 2026/09/20

#Requires AutoHotkey v2.0

Persistent(true)

LButtonMonitorActive := false
LButtonMonitorStart := 0
RButtonMonitorActive := false
RButtonMonitorStart := 0
LstartX := 0
LstartY := 0
RstartX := 0
RstartY := 0
lastWheelEvent := ""
ByLButton := false
LButtonSynthDown := false
RButtonSynthDown := false
logEnabled := true

$LButton::
{
    global LButtonMonitorActive
    global RButtonMonitorActive
    global LButtonSynthDown

    if (A_PriorHotkey = "LButton" && A_TimeSincePriorHotkey < 50)
        return

    if (LButtonMonitorActive)
        return

    if (RButtonMonitorActive)
        return

    if (LButtonSynthDown)
        return

    LButtonMonitorActive := true
    LButtonMonitorStart := A_TickCount

    Log("LButton hotkey start")
    MouseGetPos(&startX, &startY)
    LButtonSynthDown := false
    SetTimer(LButtonMonitor, 20)
    return
}

LButtonMonitor() {
    global LButtonMonitorActive
    global LButtonMonitorStart
    global lastWheelEvent
    global LstartX
    global LstartY
    global ByLButton
    global LButtonSynthDown

    static busy := false
    if (busy)
        return
    busy := true

    try {
        if (!LButtonMonitorActive)
            return

        ByLButton := false

        ; 左ボタンが離れたら通常のアップを返す
        if (!GetKeyState("LButton", "P")) {
            Log("LButton released normally")
            ;Send("{LButton Down}")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
                LButtonSynthDown := false
            } else {
                Send("{LButton Down}")
                Send("{LButton Up}")
            }
            LButtonMonitorActive := false
            SetTimer(LButtonMonitor, 0)
            return
        }

        ; 右ボタンが押されたら中断して XButton2
        if (GetKeyState("RButton", "P")) {
            Log("RButton detected")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            }
            Send("{XButton2}")
            LButtonMonitorActive := false
            SetTimer(LButtonMonitor, 0)
            ByLButton := true
            KeyWait("RButton")
            return
        }


        MouseGetPos(&curX, &curY)
        if (Abs(curX - LstartX) > 4 || Abs(curY - LstartY) > 4) {
            Log("Drag detected by LButton")
            LButtonMonitorActive := false
            SetTimer(LButtonMonitor, 0)
            Send("{LButton Down}")
            KeyWait("LButton")
            Send("{LButton Up}")
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
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            } else {
                Send("{LButton Down}")
                Send("{LButton Up}")
            }
            LButtonMonitorActive := false
            SetTimer(LButtonMonitor, 0)
            lastWheelEvent := ""
            KeyWait("LButton")
            return
        }

        ; 長時間の監視は安全のため打ち切る
        if (A_TickCount - LButtonMonitorStart > 2500) {
        ;    Log("LButton monitor timeout")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
                LButtonSynthDown := false
            } else {
                Send("{LButton Down}")
                Send("{LButton Up}")
            }
            LButtonMonitorActive := false
            SetTimer(LButtonMonitor, 0)
        }
    } finally {
        busy := false
    }        
}

$RButton::
{
    global LButtonMonitorActive
    global RButtonMonitorActive
    global RstartX
    global RstartY
    global ByLButton
    global RButtonSynthDown

    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < 50)
        return

    if (RButtonMonitorActive)
        return

    if (LButtonMonitorActive)
        return

    if (RButtonSynthDown)
        return

    ;if (ByLButton) {
    ;    ByLButton := false
    ;    return
    ;}

    RButtonMonitorActive := true
    RButtonMonitorStart := A_TickCount

    Log("RButton hotkey start")
    MouseGetPos(&RstartX, &RstartY)
    SetTimer(RButtonMonitor, 20)
    return
}

RButtonMonitor() {
    global RButtonMonitorActive
    global RButtonMonitorStart
    global lastWheelEvent
    global RstartX
    global RstartY
    global RButtonSynthDown

    static busy := false
    if (busy)
        return
    busy := true

    try {
        if (!RButtonMonitorActive)
            return

        if (!GetKeyState("RButton", "P")) {
            Log("RButton released - normal right click")
            ;Send("{RButton Down}")
            ;Send("{RButton Up}")
            if (RButtonSynthDown) {
                Send("{RButton Up}")
                RButtonSynthDown := false
            } else {
                Send("{RButton Down}")
                Send("{RButton Up}")
            }
            RButtonMonitorActive := false
            SetTimer(RButtonMonitor, 0)
            return
        }

        if (GetKeyState("LButton", "P")) {
            Log("LButton detected")
            if (RButtonSynthDown) {
                Send("{RButton Up}")
            }
            Send("{XButton1}")
            KeyWait("LButton")
            RButtonMonitorActive := false
            SetTimer(RButtonMonitor, 0)
            return
        }

        MouseGetPos(&curX, &curY)
        if (Abs(curX - RstartX) > 4 || Abs(curY - RstartY) > 4) {
            Log("Drag detected by RButton")
            RButtonMonitorActive := false
            SetTimer(RButtonMonitor, 0)
            ;Send("{RButton Down}")
            ;KeyWait("RButton")
            ;Send("{RButton Up}")
            return
        }

        ; 開始時にのみ合成 Down を送ってドラッグを成立させる
        if (!RButtonSynthDown) {
            Send("{RButton Down}")
            RButtonSynthDown := true
        }

        if (lastWheelEvent != "") {
            if (RButtonSynthDown) {
                Send("{RButton Up}")
            } else {
                Send("{RButton Down}")
                Send("{RButton Up}")
            }
            Log(lastWheelEvent " detected")
            RButtonMonitorActive := false
            SetTimer(RButtonMonitor, 0)
            lastWheelEvent := ""
            ;Send("{RButton Down}")
            ;KeyWait("RButton")
            ;Send("{RButton Up}")
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
            RButtonMonitorActive := false
            SetTimer(RButtonMonitor, 0)
        }
    } finally {
        busy := false
    }        
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
    global logEnabled
    if (!logEnabled)
        return
    FileAppend(
        Format("{1} {2}`n",FormatTime("HH:mm:ss.SSS"),msg),
            "h:\test\mouse-debug.log"
    )
}
