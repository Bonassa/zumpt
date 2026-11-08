# Product requirements

One file per PRD, named `NNN-short-title.md` and numbered in sequence.
The big picture and the order of the stages live in [ROADMAP.md](../ROADMAP.md).

## PRDs

- [001](001-tasks-in-the-week.md): Tasks in the week · Stage 3 · Approved

## Rules for every PRD

- **Short.** Say only what is needed to understand the problem and build the solution.
- **Simple.** It says what and why, never how: no class names, frameworks or file paths, unless the item is a constraint.
- **Human friendly.** Plain words and short sentences, readable in two minutes by someone who never saw the code.
  A concrete example beats an abstract rule.
- **Four sections, always in this order:**
  1. **Problem:** the context, meaning what happens today and why it hurts.
  2. **Solution:** user stories.
  3. **Constraints:** the non-negotiable items; if one is broken, the work is not done.
  4. **Acceptance criteria:** the tests, written as Given, When, Then; each one becomes an end-to-end UI test.
- **Status** moves from Draft to Approved to In progress to Done, and work starts only on an Approved PRD.

## Adding a PRD

1. Copy [TEMPLATE.md](TEMPLATE.md) to the next number, such as `002-mini-month.md`.
2. Fill in the four sections, following the rules above.
3. Add it to the list above as `- [NNN](NNN-short-title.md): Title · Stage N · Draft`.
