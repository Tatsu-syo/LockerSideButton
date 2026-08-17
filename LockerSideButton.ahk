;LockerSideButton version 1.0.3 (C) 2026 Tatsuhiko Shoji
;The sources for LockerSideButton are distributed under the MIT open source license

; Version 1.0.3 2026/08/18

#Requires AutoHotkey v2.0

Persistent(true)

addtionalItems := ["WheelDown", "WheelUp", "WheelLeft", "WheelRight"]

LButton::
{
    if (A_PriorHotkey = "LButton" && A_TimeSincePriorHotkey < 50)
        return

    global addtionalItems

    Log("LButton hotkey start")

    start := A_TickCount

    Send("{LButton Down}")

    Log("send LButton DOWN")

    ; 左ボタンが押されている間、10msごとに右ボタンが押されるか監視する
    while GetKeyState("LButton", "P")
    {
        Sleep 10
        if GetKeyState("RButton", "P")
        {
            Log("RButton detected")
            Send("{LButton Up}")         ; 左ボタンダウンをキャンセル
            Send("{XButton2}")

            KeyWait("RButton")
            Log("LButton hotkey end")
            return
        }

        ; Mouse Button with Wheels
        Loop(4) {
            Sleep 10
            if GetKeyState(addtionalItems[A_Index], "P")
            {
                Log(addtionalItems[A_Index] "WheelDown detected")
                KeyWait("LButton")
                Send("{LButton Up}")
                Log("LButton hotkey end " addtionalItems[A_Index])
                return
            }
        }

        if (A_TickCount - start > 500) {
            break
        }
    }

    Log("RButton Not detected")

    ; 左ボタンが離された（右は押されなかった）ので通常のアップ処理
    Send("{LButton Up}")
    return
}

RButton::
{
    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < 50)
        return

    global addtionalItems

    Log("RButton hotkey start")

    start := A_TickCount

    MouseGetPos(&startX, &startY)

    ; 右ボタンが押されている間、10msごとに左ボタン押下またはドラッグ開始を監視する
    while GetKeyState("RButton", "P")
    {
        Sleep 10

        if GetKeyState("LButton", "P")
        {
            Log("LButton detected")
            Send("{XButton1}")
            KeyWait("LButton")
            Log("RButton hotkey end")
            return
        }

        ; 閾値を超えた移動でドラッグと判定し即座に RButtonDown を送信する
        MouseGetPos(&curX, &curY)
        if (Abs(curX - startX) > 4 || Abs(curY - startY) > 4)
        {
            Log("Drag detected")
            Send("{RButton Down}")
            KeyWait("RButton")
            Send("{RButton Up}")
            Log("RButton hotkey end (drag)")
            return
        }

        ; Mouse Button with Wheels
        Loop(4) {
            Sleep 10
            if GetKeyState(addtionalItems[A_Index], "P")
            {
                Log(addtionalItems[A_Index] "WheelDown detected")
                Send("{RButton Down}")
                KeyWait("RButton")
                Send("{RButton Up}")
                Log("RButton hotkey end " addtionalItems[A_Index])
                return
            }
        }

        if (A_TickCount - start > 500) {
            break
        }
    }

    Log("LButton Not detected")

    ; 通常の右クリック: まとめて送信（Chromium の SetCapture を回避）
    Send("{RButton Down}")
    Send("{RButton Up}")
    return
}

;#When left button is held down, suppress the normal right-button behavior
#HotIf GetKeyState("LButton", "P")
RButton::
{
    Return
}
#HotIf

#HotIf GetKeyState("RButton", "P")
LButton::
{
    Log("LButton not allowed")
    Return
}
#HotIf

Log(msg)
{
    ;FileAppend(
    ;    Format("{1} {2}`n",FormatTime("HH:mm:ss.SSS"),msg),
    ;        "h:\test\mouse-debug.log"
    ;)
}
