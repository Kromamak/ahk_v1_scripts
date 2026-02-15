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

### File:

---

## Considerations

Initial measurements:\
`CPS: ~16`\
`Intervals: ~62-63 ms`

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

i then thought the 4 ticks were because:
```
Initial Hypothesis:
tick #1: timer expiration
tick #2: click injection (
tick #3: write to logs (FileAppend)
tick #4: new timer in queue
```

i thought that it was because i had many yields:
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
(yield = thread stops running and lets the OS scheduler run something else.)

```
for every loop iteration:
1. Windows timer expires
2. WM_TIMER is queued
3. Thread becomes runnable
4. Message is dispatched
5. Click handler executes (including logging)
6. AHK returns to MsgWaitForMultipleObjects() (thread idle)
```

so far we have:
```
1. timer expiration
2. message delivery
3. click injection + return
4. re-idle and eligible again
```
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

## Final Considerations
> [!IMPORTANT]
> > SetTimer is limited by windows event scheduler.\
> > Theoretically the script could do 64 CPS,\
> > but it efffectively caps at 16 CPS in Autohotkey v1.

| Operation   | Cost  |
| ----------- | ----- |
| WM dispatch | ~μs   |
| SendInput   | ~μs   |
| FileAppend  | ~1 ms |
| return      | ~ns   |

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


