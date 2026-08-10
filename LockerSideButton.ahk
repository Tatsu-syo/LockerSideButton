;LockerSideButton version 1.0.0 (C) 2026 Tatsuhiko Shoji
;The sources for LockerSideButton are distributed under the MIT open source license

#Requires AutoHotkey v2.0

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
    Return
}
#HotIf

LButton::
{
    if (A_PriorHotkey = "LButton" && A_TimeSincePriorHotkey < 50)
        return

    Click("Down")

    ; 左ボタンが押されている間、10msごとに右ボタンが押されるか監視する
    while GetKeyState("LButton", "P")
    {
        Sleep 10
        if GetKeyState("RButton", "P")
        {
            Click("Up")         ; 左ボタンダウンをキャンセル
            Send("{XButton2}")
            KeyWait("RButton")
            return
        }
    }

    ; 左ボタンが離された（右は押されなかった）ので通常のアップ処理
    Click("Up")
    return
}

RButton::
{
    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < 50)
        return

    ; 右ボタンが押されている間、10msごとに左ボタンが押されるか監視する
    while GetKeyState("RButton", "P")
    {
        Sleep 10
        if GetKeyState("LButton", "P")
        {
            Send("{XButton1}")
            KeyWait("LButton")
            return
        }
    }

    Send("{RButton Down}")

    ; 右ボタンが離された（左は押されなかった）ので通常のアップ処理
    Click("Right")
    return
}