#Persistent
#SingleInstance Force
Process, Priority,, High

speed := 10
toggle := false

lastReport := 0
clickCount := 0


F6::
toggle := !toggle
SetTimer, ClickLoop, % toggle ? speed : "Off"
return


ClickLoop:
    global lastReport, clickCount

    Click
    clickCount++

    now := A_TickCount

    if (now - lastReport >= 1000) {
        Tooltip, % "CPS: " clickCount
        clickCount := 0
        lastReport := now
    }
return


Esc::
Tooltip
ExitApp
return