# Zumpt roadmap

The big picture of the project: why it exists, the decisions already made, what is done and what comes next.
Detailed requirements for each upcoming piece of work live in [prds/](prds/README.md).

## Why Zumpt exists

To-do lists end up abandoned and stale because nobody keeps opening them, while the calendar stays open all day.
Zumpt puts the tasks inside the calendar, so seeing the day also means seeing what needs to be done.

That only works if Zumpt replaces the calendar used all day.
Every feature is judged by one question: is Zumpt at least as good as the Calendar app on the Mac for daily use, plus the tasks?

## Decisions

| Topic | Decision | Why |
| --- | --- | --- |
| Platform | Native macOS app in Swift and SwiftUI, macOS 26 or later | Menu bar, notifications, shortcuts and widgets are first class, and there is no server to run |
| Calendar data | Read-only from the Calendar app on the Mac through EventKit | Every account already set up there (Google, Exchange, iCloud) works with no OAuth or tenant approval |
| Writing to calendars | Never | Zumpt is a place to look at the day, not another calendar client to keep in sync |
| Tasks | Stored by Zumpt with SwiftData, schema ready for CloudKit | Tasks are the part Zumpt owns, and sync can be turned on later without a migration |
| Devices | Mac only, signed with a free Apple ID | iPhone and CloudKit sync need the paid Apple Developer Program, so they wait |
| Language | English source with a Brazilian Portuguese translation, following the system language and region | The Mac runs in English with the Brazilian region |
| Quality | End-to-end UI tests on a fixture calendar, unit tests in ZumptKit, strict lint, warnings as errors | Every change is checked the way the app is used |

## Done

| Stage | What shipped |
| --- | --- |
| 1. Scaffold | XcodeGen project, ZumptKit package, unit and UI tests, `swift format` lint, Makefile |
| 2. Week view | Calendar access flow, week grid with all-day row, overlapping events in columns, now indicator, week navigation, sidebar with per-calendar visibility |
| 2. Clean calendar | Declined and canceled meetings hidden, copies of the same meeting merged across and within calendars |
| 2. Meeting details | Popover with time, repeat rule, join button for video calls, location, calendar, response, guests and notes |
| 3. Tasks in the week | Backlog next to the week with quick add on ⌘N, tasks dragged into the week and back, completing, renaming and deleting with undo, overdue tasks returning to the top of the backlog, as described in [PRD-001](prds/001-tasks-in-the-week.md) |
| 3. Layout and task details | Sidebar tabs for Calendar and Backlog, backlog filters (All Tasks and Overdue), backlog that can be hidden with ⌥⌘B, task details in a popover on click |

## Next

Stages are ordered by how much they help Zumpt replace the calendar used all day.

| Stage | Scope | PRD |
| --- | --- | --- |
| 4. Always present | Menu bar item with the next meeting and today's tasks, launch at login, global shortcut to add a task, notifications for scheduled tasks | Not written |
| 5. Navigation | Mini month in the sidebar, Day and Month views, Events, Tasks and Completed filters, search | Not written |
| 6. Organization | Scopes (Personal and Work), projects, subtasks, due dates, recurring tasks | Not written |
| 7. Smart scheduling | Free slots between meetings, fit the backlog into free time automatically, natural-language quick add such as "Review contract tomorrow 3pm #Work" | Not written |
| Later | iPhone app and widgets with CloudKit sync | Not written |

## Out of scope

- Writing to external calendars, including "busy" blocks for tasks.
- Responding to invites inside Zumpt, since EventKit cannot do it; the details popover opens the event in the Calendar app instead.
- Windows, Linux and the web.

## Open questions and risks

- **Open in Calendar** uses an undocumented `ical://ekevent/` link and still needs to be confirmed against real events.
- **Exchange accounts** in the Calendar app have relied on Exchange Web Services, which Microsoft is retiring in Exchange Online.
  If that sync stops, Zumpt loses those events too, because it only reads what the Calendar app has.
- **Very light calendar colors** produce pale event blocks that are hard to tell apart from the background.

## Design reference

The screens were first explored in a Claude Design canvas: https://claude.ai/artifact/8Fda7P12hKsMMHzARX1MyY.
The canvas still shows ideas that were dropped since, such as reserving time in Outlook and storing tasks inside external calendars.
