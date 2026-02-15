# AUTOCLICKER
> [!NOTE]
> > Windows event scheduler resolution: \
> > Frequency: 64hz \
> > Interval:  15.625 ms \
> > Max Speed: 64.000 CPS

---

## Intro
In autohotkey_set_timer.ahk i wanted to make a simple autoclicker.

Target CPS: `100`\
Objectives: `test native ahk speeds.`\
Contraints: `no high-resolution timers or dll calls`

### File: [autoclicker_set_timer.ahk](https://github.com/Kromamak/ahk_v1_scripts/blob/main/autoclicker/autoclicker_set_timer.ahk)

---

## Considerations

Initial measurements:\
`CPS: ~16`\
`Intervals: ~62-63 ms`

1 scheduler tick:\
`15.625 ms`

then:\
`15.625 x 4 = 62.5`

meaning:\
`1 click = 4 Ticks`

so far in my script we have:
```
SetTimer:   outside loop
Sleep:      outside loop, startup/exit
FileAppend: inside loop, ~1ms
Click:      inside loop, calls "SendInput" to kernel
return:     inside loop, mandatory
```
so iside the ClickLoop we only have `FileAppend` and `Click` + the mandatory `return`

i initially thought the 4 ticks were because:
```
ClickLooop:
tick #1-2: write to logs (FileAppend)
tick #3: click injection (Click)
tick #4: new timer in queue
```
the main offender is `fileAppend`

---

## Attempt #1
at first i thought the additional 1-3 ticks were because of `FileAppend` taking CPU time.\
so i came up with this version that shows cps as a tooltip instead of logging to a file.([autoclicker set timer no i/o](https://github.com/Kromamak/ahk_v1_scripts/blob/main/autoclicker/autoclicker_set_timer_no_io.ahk))
> no improvements, still 16 CPS

---

## Attempt #2
i tried to run it at high priority adding: `Process, Priority,, High` ([autoclicker set timer no i/o high priority](https://github.com/Kromamak/ahk_v1_scripts/blob/main/autoclicker/autoclicker_set_timer_no_io_high_priority.ahk))
> the speed was still 16 CPS, so the problem was not I/O or priority settings.

i later discovered that WM_TIMER (`SetTimer`) is low priority by defalt and is not controlled by thread priority

---
## Timings
I later researched timings for each operation.

| Operation   | Cost  |
| ----------- | ----- |
| WM dispatch | ~μs   |
| SendInput   | ~μs   |
| FileAppend  | ~1 ms |
| return      | ~ns   |

event scheduler tick: 15.625 ms

so all operations should fit in a single tick.

---

## Final Considerations
> [!IMPORTANT]
> > SetTimer is limited by windows event scheduler.\
> > Theoretically the script could do 64 CPS,\
> > but it efffectively caps at 16 CPS in Autohotkey v1.

Autohotkey uses `MsgWaitForMultipleObjects()` instead of `sleep()`.

`sleep()`: thread sleeps and ignores messages in queue\
`MsgWaitForMultipleObjects()`: thread wakes when messages or events arrive

1. program is toggled on 
```
in Autohotkey:

MsgWaitForMultipleObjects() [→ sleep starts]
```
2. during sleep a single yield happens.
```
in the kernel: 

[→ yield starts]
 1. thread is blocked (enters WAITING state)
 2. Windows timer expires
 3. WM_TIMER is queued
 4. Thread is marked runnable
[→ yield ends] 
```
3. yield ends and the program wakes up
```
in Autohotkey:

1. MsgWaitForMultipleObjects() returns [→ sleep ends]
2. AHK dispatches WM_TIMER
3. ClickLoop runs
4. return
```
---
after all of this, we know that:
```
Each click requires:

1. Blocking (sleep/yield)

2. Timer expires and WM_TIMER is queued again

3. Thread wake-up  
4. WM_TIMER dispatch  
5. Handler executes
6. Blocking again  
```
Each click requires\
1 yield phase\
1 scheduler wake-up\
1 WM_TIMER dispatch

```
In Autohotkey v1:
- Minimum timer granularity ≈ 15.6 ms
- Message-driven dispatch
- Interpreter overhead
- SendInput latency
- Coalescing behavior
~60 ms stable cadence
```

As a result, each click takes ~62 ms, limiting the speed to approximately 16 CPS.


## Conclusion:
Even if Windows scheduler resolution is ~15.6 ms,\
`AutoHotkey v1 cannot reliably execute one click per tick using SetTimer.`\

i decided to keep the first version i had as it was already as fast as possible and stable enough.

This limit is structural and cannot be overcome in AutoHotkey v1,\
not without using higher-resolution timers, DLL calls, or native code.\
i later used this as inspiration to build my rust autoclicker, as i wanted a faster and reliable autoclicker.


