# PRD-003: Recurring tasks

Status: Draft · Stage 4 · Updated 2026-11-18

## 1. Problem

Recreating routine tasks by hand makes them easy to forget.
Recurrence comes before menu bar features and reminders.

## 2. Solution

- I want daily, weekly, monthly or yearly tasks, so that routines appear automatically.
- I want a required first date, optional time, interval and optional end date, so that repetition fits my routine.
- I want independent occurrences, so that missing one does not delay the next.
- I want to change one occurrence or this and following ones, so that exceptions do not break the routine.

## 3. Constraints

- Set repetition in task details. Intervals are positive whole numbers; weekly rules allow selected weekdays. End dates are inclusive; repetition otherwise continues.
- Every occurrence has a date and stays in the calendar, never the backlog. Timed ones last 30 minutes; date-only ones appear in the all-day row.
- Fixed dates are independent of completion. After its day ends, an unfinished occurrence stays on its date, marked overdue. Reopening marks missed occurrences overdue without duplicates.
- Completing, reopening or rescheduling affects one occurrence. Dates cannot be cleared and backlog drops are blocked. Renaming or deleting offers "This occurrence" and "This and following"; rule changes apply from the selected occurrence onward.
- Following means original recurrence dates. Series changes preserve earlier history and completed occurrences. Stopping repetition keeps the selected occurrence and removes later unfinished ones.
- Missing monthly dates use that month's last day, preserving the original rule. February 29 uses February 28 in non-leap years. Clock changes keep local time; skipped times use the next valid time and repeated times occur once.
- Changes support undo. Existing tasks survive; series, exceptions and completions persist locally. Calendars remain read-only; reminders and repetition based on completion wait for later work.

## 4. Acceptance criteria

- Given a backlog task, when I save daily repetition with a first date, then dated occurrences replace it in the calendar.
- Given repetition every two weeks on Monday and Wednesday, when I browse weeks, then occurrences follow that pattern.
- Given January 31 monthly or February 29 yearly repetition, when a date is missing, then it uses that month's last day and preserves the original rule.
- Given a date-only series, when I browse a week, then its occurrences appear on their dates in the all-day row, including future weeks.
- Given Monday's occurrence is unfinished, when Tuesday begins, then Monday stays on Monday marked overdue, Tuesday appears on schedule and neither enters the backlog.
- Given missed dates, when I reopen Zumpt twice, then each occurrence stays overdue on its date, without duplicates or backlog entries.
- Given an occurrence, when I complete and reopen it, then only its completion changes and future occurrences stay unchanged.
- Given an occurrence, when I reschedule it, then only it moves and the rule stays unchanged; clearing its date or dropping it in the backlog is blocked.
- Given a series, when I rename or delete one occurrence, then others remain; choosing this and following affects only that range's unfinished occurrences.
- Given a series, when I change or stop repetition, then earlier history and completed occurrences remain.
- Given an end date, when I browse beyond it, then no new occurrences exist; missing first dates, invalid intervals or earlier end dates cannot be saved.
- Given a recurrence change, when I undo it, then the prior rule and affected occurrences return without duplicates.
- Given saved series and exceptions, when I restart, then they remain and nonrecurring tasks are unchanged.
