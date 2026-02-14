; autoclicker_timer.ahk
; Model:           SetTimer (event scheduler)
; CPU:             Low
; Precision:       Medium
; Limited to:      16 CPS max 
; Event scheduler: 64hz / 15.625 ms / 64.000 CPS
; Script speed:    4 Ticks / 62.5 ms / 16.000 CPS



;=== Launch Message ===============================
MouseGetPos, xpos, ypos
Tooltip, Autoclicker Launched!, %xpos%, % yPos + 30
Sleep, 2000
Tooltip
;==================================================

;=== CONFIG ====================================
speed := 60     ; Click interval in milliseconds
minSpeed := 10  ; Minimum allowed speed (ms)
toggle := false ; Clicker state
;===============================================

;=== TOGGLE ON/OFF ====================================================================
F6::
toggle := !toggle
SetTimer, ClickLoop, % toggle ? speed : "Off"

MouseGetPos, xpos, ypos
Tooltip, % "Autoclicker " (toggle ? "Activated!" : "Deactivated."), %xpos%, % yPos + 30
SetTimer, RemoveTooltip, -1000
return
;======================================================================================

;=== HOTKEYS ===============================================================
; --------------
; Increase delay
; --------------
=::
speed += 10
SetTimer, ClickLoop, % toggle ? speed : "Off"
MouseGetPos, xpos, ypos
cps := Round(1000.0 / speed, 2)
Tooltip, % "Delay: " speed " ms  |  Speed: " cps " cps", %xpos%, % yPos + 30
SetTimer, RemoveTooltip, -2000
return

; --------------
; Decrease delay 
; --------------
-::
speed := Max(minSpeed, speed - 10)
SetTimer, ClickLoop, % toggle ? speed : "Off"
MouseGetPos, xpos, ypos
cps := Round(1000.0 / speed, 2)
Tooltip, % "Delay: " speed " ms  |  Speed: " cps " cps", %xpos%, % yPos + 30
SetTimer, RemoveTooltip, -2000
return
;===========================================================================

;=== CLICK LOOP ==========================
ClickLoop:
FileAppend, %A_TickCount%`n, click_log.txt
Click
return
;=========================================

;=== REMOVE TOOLTIP ===
RemoveTooltip:
Tooltip
return
;======================

;=== Exit =======================================
Esc::
MouseGetPos, xpos, ypos
Tooltip, Autoclicker Closed., %xpos%, % yPos + 30
Sleep, 1000
Tooltip
ExitApp
return
;================================================

