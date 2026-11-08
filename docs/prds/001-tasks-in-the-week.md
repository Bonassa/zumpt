# PRD-001: Tasks in the week

Status: Approved · Stage 3 · Updated 2026-11-08

## 1. Problem

Zumpt shows my meetings but not my tasks yet, so the reason it exists is still missing.
Tasks kept in a separate list get forgotten because I stop opening that list, while the calendar stays open all day.

## 2. Solution

- I want to add a task by typing just its title, so that capturing it takes seconds.
- I want tasks without a time to wait in a backlog next to the week, so that I see them every time I look at my calendar.
- I want to drag a task into the week, so that it gets a time between my meetings.
- I want to drag a task to another time or back to the backlog, so that the week follows my plans when they change.
- I want to tick a task as done, so that what is left stands out.
- I want to rename or delete a task, so that typos and tasks I gave up on do not stay around.
- I want a task not done by the end of its day to come back to the backlog as overdue, so that it is never lost in the past.

## 3. Constraints

- The backlog is always visible next to the week.
- Tasks are stored only on this Mac and are never written to the Calendar app.
- Tasks look different from meetings at a glance.
- A task dropped into the week lasts 30 minutes.
- Every change I make can be undone with `⌘Z`.

## 4. Acceptance criteria

- Given an empty backlog, when I press `⌘N`, type "Renovar CNH" and press Return, then "Renovar CNH" shows in the backlog.
- Given a task in the backlog, when I drag it to Wednesday at 14:00, then it shows in the week from 14:00 to 14:30 and leaves the backlog.
- Given a task in the week, when I drag it to Thursday at 10:00, then it shows on Thursday from 10:00 to 10:30.
- Given a task in the week, when I drag it to the backlog, then it leaves the week and shows in the backlog.
- Given a task in the week, when I tick it, then it shows as done.
- Given a task in the backlog, when I tick it, then it leaves the backlog.
- Given a task in the backlog, when I rename it to "Renovar passaporte", then the backlog shows "Renovar passaporte".
- Given a task in the backlog, when I delete it, then it leaves the backlog.
- Given a task scheduled for 09:00 today and not done, when I look at the week in the afternoon, then it is still in the week.
- Given a task scheduled for yesterday and not done, when I open Zumpt, then it shows at the top of the backlog as overdue.
- Given a task I just moved, when I press `⌘Z`, then it is back where it was.
- Given a task in the backlog, when I quit Zumpt and open it again, then the task is still there.
