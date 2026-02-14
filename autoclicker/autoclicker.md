# AUTOCLICKER
> [!IMPORTANT]
> > SetTimer is limited by windows event scheduler.

> [!NOTE]
> > Windows event scheduler resolution: \
> > Frequency: 64hz \
> > Interval:  15.625 ms \
> > Max Speed: 64.000 CPS

## Intro
In autohotkey_set_timer.ahk i wanted to make a simple autoclicker.\

that could reach 100 CPS (Clicks Per Second).\
i did not want to use dll calls to test ahk native speeds\ 
and to not make the code too complicated.

## Considerations
Theoretically the script could do 64 CPS,\
but it efffectively caps at 16 CPS in Autohotkey v1.

The click intervals reported in the logs were ~62-63 ms,\
meaning 1 click every 4 Ticks.

i thought that it was because i had many yields:
```
SetTimer:   outside loop
Sleep:      outside loop, startup/exit
FileAppend: inside loop, ~1ms
Click:      inside loop, calls "SendInput" to kernel
return:     inside loop, mandatory
```

```
for every loop iteration:
1. Click handler ends
2. return
3. AHK blocks in MsgWaitForMultipleObjects() [Yield #1]

4. Windows timer expires
5. WM_TIMER posted to message queue

6. Scheduler resumes AHK thread [Yield #1 ends]
7. Message is dispatched

8. ClickLoop executes
9. return
10. AHK blocks again [Yield #2]
```
---
## Attempt #1
at first i thought the additional 1-3 ticks were because of `FileAppend` taking CPU time.\
so i came up with this version that shows cps as a tooltip instead of logging to a file.([autoclicker set timer no i/o](https://github.com/Kromamak/ahk_v1_scripts/blob/main/autoclicker/autoclicker_set_timer_no_io.ahk))

---

no improvements, still 16 CPS
i tried to run it at high priority adding: `Process, Priority,, High` ([autoclicker set timer no i/o high priority](https://github.com/Kromamak/ahk_v1_scripts/blob/main/autoclicker/autoclicker_set_timer_no_io_high_priority.ahk))

---

i later discovered that WM_TIMER (`SetTimer`) is low priority by defalt.\
the speed was still 16 CPS, so the problem was not I/O or priority settings.

---

```
Each click requires:  
1. Blocking in the message loop  
2. Waiting for WM_TIMER  
3. Scheduler wake-up  
4. Message dispatch  
5. Handler execution  
6. Blocking again  
```
These steps introduce multiple mandatory yields per iteration.

Even if Windows scheduler resolution is ~15.6 ms, AutoHotkey v1 cannot reliably execute one click per tick when using SetTimer.
Each click requires multiple scheduler wake-ups and message dispatches.

As a result, each click takes ~62 ms, limiting the speed to approximately 16 CPS.

i decided to keep the first version i had as it was already as fast as possible and stable enough.

This limit is structural and cannot be overcome in AutoHotkey v1,\
not without using higher-resolution timers, DLL calls, or native code.\
i later used this as inspiration to build my rust autoclicker, as i wanted a faster and reliable autoclicker.


