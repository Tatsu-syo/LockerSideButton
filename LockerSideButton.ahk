;LockerSideButton version 1.0.0 (C) 2026 Tatsuhiko Shoji
;The sources for LockerSideButton are distributed under the MIT open source license

#Requires AutoHotkey v2.0

Persistent(true)

LButton::
{
    if (A_PriorHotkey = "LButton" && A_TimeSincePriorHotkey < 50)
        return

    Log("LButton hotkey start")

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
    }

    Log("RButton Not detected")

    ; 左ボタンが離された（右は押されなかった）ので通常のアップ処理
    Send("{LButton Up}")
    return
}

RButton::
{
    Log("RButton hotkey start")

    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < 50)
        return

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
    FileAppend(
        Format("{1} {2}`n",FormatTime("HH:mm:ss.SSS"),msg),
            "h:\test\mouse-debug.log"
    )
}
