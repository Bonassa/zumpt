# PRD-003: Recurring tasks

Status: Draft · Stage 4 · Updated 2026-11-18

## 1. Problem

Recreating routine tasks by hand makes them easy to forget.
Recurrence comes next, before menu bar features and reminders.

## 2. Solution

- I want daily, weekly, monthly or yearly tasks, so that routines appear automatically.
- I want a first date, optional time, interval and optional end date, so that repetition fits my routine.
- I want independent occurrences, so that missing one does not delay the next.
- I want to change one occurrence or this and following ones, so that exceptions do not break the routine.

## 3. Constraints

- Set repetition in task details. Intervals are positive whole numbers; weekly rules allow selected weekdays. End dates are inclusive; repetition otherwise continues.
- Timed occurrences appear in their weeks, lasting 30 minutes. Untimed series enter the backlog on each occurrence's date, showing that date. Future ones stay hidden.
- Occurrences follow fixed dates, independently of completion. After their day ends, unfinished occurrences become separate overdue backlog items. Reopening recovers missed occurrences without duplicates.
- Completing, reopening, dragging or unscheduling affects one occurrence. Renaming or deleting offers "This occurrence" and "This and following"; rule changes apply from the selected occurrence onward.
- Following means original recurrence dates. Series changes preserve earlier history and completed occurrences. Stopping repetition keeps the selected occurrence and removes later unfinished ones.
- Missing month dates use that month's last day without changing the original rule: January 31 becomes February 28, then March 31. February 29 uses February 28 in non-leap years. Clock changes keep local time; skipped times use the next valid time and repeated times occur once.
- Changes support undo. Existing tasks survive; series, exceptions and completions persist locally. Calendars remain read-only; reminders and repetition based on completion wait for later work.

## 4. Acceptance criteria

- Given a task, when I set daily repetition and its first date, then occurrences appear independently and details describe the rule.
- Given a weekly rule for Monday and Wednesday every two weeks, when I browse the weeks, then occurrences match those weekdays and interval.
- Given January 31 monthly or February 29 yearly repetition, when a date is missing, then it uses that month's last day and preserves the original rule.
- Given an untimed daily series, when its date begins, then one dated occurrence enters the backlog and future dates stay hidden.
- Given a Monday occurrence left unfinished, when Tuesday begins, then Monday is overdue and Tuesday appears on schedule.
- Given several missed dates while Zumpt was closed, when I reopen twice, then each missed occurrence appears overdue exactly once.
- Given an occurrence, when I complete and reopen it, then only its completion changes and future occurrences stay unchanged.
- Given an occurrence, when I drag or unschedule it, then only that occurrence moves and the repetition rule stays unchanged.
- Given a series, when I rename or delete one occurrence, then others remain; choosing this and following affects only that range's unfinished occurrences.
- Given a series, when I change its rule or stop repeating, then earlier history and completed occurrences remain.
- Given an end date, when I browse beyond it, then no new occurrences exist; invalid intervals or an end before the first date cannot be saved.
- Given a recurrence change, when I undo it, then the prior rule and affected occurrences return without duplicates.
- Given saved series and exceptions, when I restart, then they remain and nonrecurring tasks are unchanged.
