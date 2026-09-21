;LockerSideButton version 1.0.4 (C) 2026 Tatsuhiko Shoji
;The sources for LockerSideButton are distributed under the MIT open source license

; Version 1.0.4 2026/09/20

#Requires AutoHotkey v2.0
#Warn VarUnset
#Warn LocalSameAsGlobal

Persistent(true)

LButtonMonitorActive := false
LButtonMonitorStart := 0
RButtonMonitorActive := false
LstartX := 0
LstartY := 0
RstartX := 0
RstartY := 0
lastWheelEvent := ""
ByLButton := false
ByRButton := false
LButtonSynthDown := false
RButtonSynthDown := false
logEnabled := true

$LButton::
{
    global LButtonMonitorActive
    global RButtonMonitorActive
    global LButtonMonitorStart
    global LstartX
    global LstartY
    global ByLButton
    global ByRButton
    global LButtonSynthDown

    if (A_PriorHotkey = "LButton" && A_TimeSincePriorHotkey < 50)
        return

    Log("L pressed — L:" GetKeyState("LButton","P") " R:" GetKeyState("RButton","P") " A_PriorHotkey:" A_PriorHotkey)
    Log("LButtonMonitorActive: " LButtonMonitorActive )
    Log("RButtonMonitorActive: " RButtonMonitorActive)
    Log("ByRButton: " ByRButton )
    Log("LButtonSynthDown: " LButtonSynthDown)

    ; Another hook guard
    if (ByRButton) {
        ByRButton := false
        return
    }

    if (LButtonMonitorActive)
        return

    if (RButtonMonitorActive)
        return

    if (LButtonSynthDown)
        return

    ; Start monitoring LButton
    LButtonMonitorActive := true
    ByLButton := true
    LButtonMonitorStart := A_TickCount

    Log("LButton hotkey start")
    MouseGetPos(&LstartX, &LstartY)
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
    global ByRButton
    global LButtonSynthDown

    static busy := false
    if (busy)
        return
    busy := true

    try {
        if (!LButtonMonitorActive) {
            ByLButton := false
            return
        }

        ByRButton := false

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
            LButtonMonitorActive := false
            ByLButton := false
            return
        }

        ; 右ボタンが押されたら中断して XButton2
        if (GetKeyState("RButton", "P")) {
            Log("RButton detected")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            }
            Send("{XButton2}")
            KeyWait("RButton")
            SetTimer(LButtonMonitor, 0)
            LButtonSynthDown := false
            LButtonMonitorActive := false
            ByLButton := false
            return
        }


        MouseGetPos(&curX, &curY)
        if (Abs(curX - LstartX) > 4 || Abs(curY - LstartY) > 4) {
            Log("Drag detected by LButton")
            if (LButtonSynthDown) {
                Send("{LButton Up}")
            }
            SetTimer(LButtonMonitor, 0)
            LButtonMonitorActive := false
            LButtonSynthDown := false
            ByLButton := false
            ;Send("{LButton Down}")
            ;KeyWait("LButton")
            ;Send("{LButton Up}")
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
            KeyWait("LButton")
            SetTimer(LButtonMonitor, 0)
            LButtonMonitorActive := false
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
            LButtonMonitorActive := false
            LButtonSynthDown := false
            ByLButton := false
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
    global ByRButton
    global RButtonSynthDown

    Log("R pressed — L:" GetKeyState("LButton","P") " R:" GetKeyState("RButton","P") " A_PriorHotkey:" A_PriorHotkey)
    Log("LButtonMonitorActive: " LButtonMonitorActive)
    Log("RButtonMonitorActive: " RButtonMonitorActive)
    Log("ByLButton: " ByLButton )
    Log("RButtonSynthDown: " RButtonSynthDown)

    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < 50)
        return

    ; Another hook guard
    if (ByLButton) {
        ByLButton := false
        return
    }

    if (RButtonMonitorActive)
        return

    if (LButtonMonitorActive)
        return

    ; Start monitoring RButton
    RButtonSynthDown := false
    ByRButton := true

    ;if (LButtonMonitorActive) {
    ;    Log("RButton pressed while L held — consume and send XButton1")
    ;    Send("{XButton1}") ; 右→左の組み合わせで戻る等
    ;    KeyWait("RButton") ; 物理解放を待つ（これで重複発火抑制）
    ;    return
    ;}
    ; 通常の右クリック動作：明示的に発生させる（必要なら）
    ;Send("{RButton Down}{RButton Up}")
    ;return

    RButtonMonitorActive := true
    RButtonMonitorStart := A_TickCount

    Log("RButton hotkey start")
    MouseGetPos(&RstartX, &RstartY)

    while(RButtonMonitorActive) {
        RButtonMonitor(RButtonMonitorStart)
        ;Log("RButton monitoring loop :" RButtonMonitorActive)
        if (!RButtonMonitorActive)
            return

        Sleep(20)
    }

    RButtonMonitorActive := false
    RButtonSynthDown := false
    ByRButton := false

    Log("RButton hotkey end")

;    SetTimer(RButtonMonitor, 20)
;    return
}

RButtonMonitor(RButtonMonitorStart) {
    global RButtonMonitorActive
    global lastWheelEvent
    global RstartX
    global RstartY
    global RButtonSynthDown

    static busy := false
    if (busy)
        return
    busy := true

    ;Log("RButton monitoring")

    try {
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
            RButtonMonitorActive := false
            ;SetTimer(RButtonMonitor, 0)
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
            RButtonSynthDown := false
            ;SetTimer(RButtonMonitor, 0)
            return
        }

        MouseGetPos(&curX, &curY)
        if (Abs(curX - RstartX) > 4 || Abs(curY - RstartY) > 4) {
            Log("Drag detected by RButton")
            ;SetTimer(RButtonMonitor, 0)
            if (RButtonSynthDown) {
                Send("{RButton Up}")
                RButtonSynthDown := false
            }
            RButtonMonitorActive := false
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
            lastWheelEvent := ""
            RButtonSynthDown := false
            RButtonMonitorActive := false
            ;SetTimer(RButtonMonitor, 0)
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
            RButtonSynthDown := false
            RButtonMonitorActive := false
            ;SetTimer(RButtonMonitor, 0)
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
