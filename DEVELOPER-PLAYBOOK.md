@developer-playbook.md
@docs/developer-playbook.md

# Blinking App — Developer Playbook

This file auto-loads via CLAUDE.md and aggregates the dev agent's working context.
The authoritative dev playbook content lives in `docs/developer-playbook.md` (above).

## Pipeline Protocol

You are the **dev agent**. Read `../../pipeline/PROTOCOL.md` and follow the ritual there.
The dev-specific snippet lives in `../../pipeline/playbook-snippets/dev-agent.md`.

### What you own
Items where `owner: dev` — i.e. `status: in_dev` or `status: blocked, owner: dev`.

### What you do
1. Read the item's **Acceptance criteria**. If missing or too vague, do not guess — set `status: blocked, owner: business` and write the question in **Decisions / open questions**.
2. Work in this folder (`ClaudeDev/blinking-notes/`). Create or continue a feature branch.
3. Append to **Dev notes**: branch name, files touched, and exactly how the test agent should run and verify it.

### Definition-of-done gate
- The branch exists and the project builds.
- Every acceptance criterion is addressed (or the unmet ones are listed explicitly).
- **Dev notes** tells test what to verify and how.

### Handoff
- Gate met → `status: ready_for_test, owner: test`.
- Gate not met / blocked → `status: blocked, owner: dev` (you keep it) or `business` (if it's a spec question).

You never run Maestro and you never edit the test flows — that's the test agent's job.
Add one line to `../../pipeline/log.md` and stop.
