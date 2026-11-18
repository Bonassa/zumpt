# PRD-002: Always present

Status: Draft · Stage 5 · Updated 2026-11-18

## 1. Problem

Zumpt brings meetings and tasks together, but checking the day or capturing a task still means opening its window.
While working elsewhere, I can forget what I scheduled.

## 2. Solution

- I want a menu bar summary with links to details, so that I can check my next meeting and today's tasks.
- I want optional launch at login, so that Zumpt is ready every morning.
- I want a global shortcut to capture tasks, so that I do not lose ideas.
- I want reminders at task start times, so that I notice scheduled work.

## 3. Constraints

- The summary shows the next timed event starting later today and unfinished tasks scheduled today, in time order. It follows the week's calendar visibility and meeting cleanup rules, excluding all-day events from the next meeting.
- Closing the window keeps Zumpt running; Quit exits. The shortcut works while Zumpt runs.
- Settings persist: login launch and reminders start off; the shortcut starts unassigned. Login launch leaves the window closed.
- Capture takes only a title and saves to the existing backlog.
- Reminders follow macOS permissions and notification settings. One alert per scheduled start works even with Zumpt quit. Task changes replace or cancel pending alerts; opening Zumpt does not alert for past starts.
- Tasks remain local and calendars read-only. Meeting reminders, snooze and notification actions beyond opening the task are outside this stage.

## 4. Acceptance criteria

- Given a 14:00 meeting and today's unfinished tasks, when I open the summary at 13:00, then I see their titles and times in order.
- Given hidden calendars, declined, canceled, duplicate and all-day events, when I check the next meeting, then excluded events are absent and duplicates appear once.
- Given an empty section or denied calendar access, when I open the summary, then it explains that state; calendar denial leaves tasks available.
- Given an open summary, when tasks, events or the local day change, then it refreshes.
- Given a summary item, when I select it, then Zumpt opens its week and details.
- Given Zumpt is running, when I close its window, then the menu bar remains; Quit removes it.
- Given my saved login choice, when I log in, then Zumpt starts with its window closed only if enabled; Settings explains system blocks.
- Given my configured shortcut, when I use it from another app and save "Renovar CNH", then one backlog task is created and I return to that app.
- Given quick capture, when I press Escape or submit a blank title, then nothing is saved and I return to the previous app.
- Given an unavailable shortcut, when I assign it, then Settings explains the failure and keeps my previous choice.
- Given reminders are off, when I enable them, then permission is requested if needed; denial offers directions to macOS Settings.
- Given permitted reminders, when a future task starts, then one notification names it even with Zumpt quit; clicking opens its details.
- Given a pending reminder, when I rename or reschedule the task, then it uses the new title and time; completing, deleting or unscheduling cancels it.
- Given reminders are disabled or a start is past, when Zumpt opens, then no alert is scheduled; disabling reminders cancels pending alerts.
