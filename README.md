[README.md](https://github.com/user-attachments/files/27553099/README.md)
# Heal Tracker

A real-time heal, damage, and raid event tracker for MacroQuest (EverQuest multiboxing). Built around the MQ Actors framework — runs on every box in your group/raid and aggregates everything to a designated "driver" character that displays the UI.

## Features

- **Per-mob fight tracking** — each mob is its own independent scope, so add deaths don't fragment boss fights
- **Heals tracking** — total HP healed per character with per-healer breakdown
- **DPS tracking** — total damage per attacker, with pet attribution and split/combined views
- **Spell tracking** — what your group cast each fight (group spells)
- **Mob spell tracking** — every spell each mob cast at you, with per-cast timestamps
- **Persistent history** — all data archived to disk, queryable by date range
- **Live mini bar** — at-a-glance combat readout with linger and queue support
- **Last Fight popup** — Gamparse-style summary window after each fight
- **EQ-consider colors** — mob names colored by relative level (red/yellow/white/blue/green/gray)
- **Raid event triggers** — pattern-based chat watchers with overlay alerts and beep sounds

## Installation

1. Download `heal_tracker.lua`
2. Place it in `<MQ-folder>/lua/heal_tracker/heal_tracker.lua`
3. From in-game, type `/lua run heal_tracker` on every box in your group
4. On your driver character (the one whose screen will show the UI), run `/healtracker driver`

The script needs to run on every character to capture their heals and damage. Only driver characters display the UI window.

## Configuration files

Stored in `<MQ-folder>/config/heal_tracker/`:

- `config.lua` — settings, drivers list, pet mappings, triggers
- `fights.lua` — recent heal fight snapshots
- `damage.lua` — recent damage fight snapshots (includes mob spells)
- `spells.lua` — recent spell-cast fight snapshots
- `archive.lua` — permanent history archive (all fights ever recorded)
- `history.log` — append-only text log of all events

The archive is preserved across `/healtracker fights clear` so your history is never lost.

## UI tabs

- **Heals (N)** — fight list with per-character heal breakdown
- **DPS (N)** — fight list with per-attacker damage and DPS breakdown
- **Spells (N)** — fight list with group spell casts per fight
- **History** — full archive search with date range, view modes (DPS/Heals/Spells/Mob Spells/All), and mob filtering
- **Session** — rolling totals across all fights this session
- **Triggers** — manage raid event triggers and view a help reference for the slash commands
- **Settings** — driver management, pet/owner mappings, behavior toggles

## Color scheme

- **Green** — character names (yours and your group's)
- **Bright yellow** — damage and DPS values
- **Light baby blue** — heal values
- **Mob names** colored by EQ-consider:
  - **Red** — 4+ levels above you
  - **Yellow** — 1-3 levels above
  - **White** — even level
  - **Dark blue** — 1-5 levels below
  - **Light blue** — 6-13 levels below
  - **Green** — 14-20 levels below
  - **Gray** — 21+ levels below

## Slash commands

All commands start with `/healtracker`. Run with no arguments to see the current status.

### Driver / window control

| Command | What it does |
|---|---|
| `/healtracker` | Show current status (driver mode, fight count, etc.) |
| `/healtracker driver` | Toggle this character as a driver (UI shows only on drivers) |
| `/healtracker show` | Open/raise the main window |
| `/healtracker mini` | Toggle the mini collapsed view |
| `/healtracker stop` | Cleanly stop the script (preferred over `/lua stop`) |

### Reset / clearing

| Command | What it does |
|---|---|
| `/healtracker reset` | Reset session counters (Session tab) |
| `/healtracker fights clear` | Wipe in-memory fights (archive preserved) |
| `/healtracker autoreset on\|off` | Toggle whether session auto-resets after each fight |

### Reporting

| Command | What it does |
|---|---|
| `/healtracker report` | Print a Gamparse-style summary of the most recent fight to chat |
| `/healtracker log` | Print where the persistent log file lives |

### Search / filtering

| Command | What it does |
|---|---|
| `/healtracker search` | Clear the active mob name filter on the current tab |
| `/healtracker search <text>` | Filter the current tab to fights matching `<text>` (substring) |

### Behavior tuning

| Command | What it does |
|---|---|
| `/healtracker timeout N` | Set fight timeout in seconds (default 8). Idle mobs save as fights after this long |
| `/healtracker linger N` | Set Last Fight linger seconds (default 5) |
| `/healtracker min N` | Minimum heal amount to record (filters out very small heals) |
| `/healtracker debug` | Toggle verbose debug output to chat |

### Pet / owner mapping

For pets whose names don't match the standard "X's pet" format. After mapping, the pet's damage rolls up into the owner's row.

| Command | What it does |
|---|---|
| `/healtracker pet add <petname> <owner>` | Map `petname` → `owner` (multi-word pet names supported) |
| `/healtracker pet remove <petname>` | Unmap a pet |
| `/healtracker pet list` | List all pet mappings |
| `/healtracker pet clear` | Wipe all pet mappings |

You can also do this via the Settings tab using dropdowns.

### Spell / caster mapping

Custom spell-to-caster overrides for tracking spell casts that the auto-detection misses.

| Command | What it does |
|---|---|
| `/healtracker spell add <spell> <caster>` | Map a spell name to a caster |
| `/healtracker spell remove <spell>` | Remove a spell mapping |
| `/healtracker spell list` | List all spell mappings |
| `/healtracker spell clear` | Wipe all spell mappings |

### Raid event triggers

Pattern-based chat watchers that fire overlay alerts + beep sounds when matched. Useful for boss mechanics: `begins casting Death Touch` → DUCK NOW popup with three beeps.

#### List / inspect

| Command | What it does |
|---|---|
| `/healtracker trigger list` | Show all configured triggers with their settings |

#### Add a trigger

```
/healtracker trigger add <pattern> | <label> [| opts]
```

- **`<pattern>`** — substring to match in chat (case-insensitive). Whatever appears in the chat line.
- **` | `** — literal space-pipe-space separator. Required between pattern and label.
- **`<label>`** — text shown in the alert popup. Use `\n` (backslash-n) for line breaks.
- **`[| opts]`** — optional third chunk with `key=value` options:
  - `color=red|orange|yellow|white|blue|green` (default: red)
  - `beep=N` — beep count, 0-5 (default: 2; 0 = silent)
  - `dismiss=N` — auto-dismiss seconds, 0 = manual only (default: 8)
  - `mob=<name>` — only fire if this mob name is also in the chat line

**Examples:**

```
/healtracker trigger add begins casting Death Touch | DUCK NOW! | color=red beep=3 dismiss=8

/healtracker trigger add shouts ENRAGE | BOSS ENRAGED | color=orange beep=2

/healtracker trigger add Out of the corner of your eye | Duck Now! | color=red beep=2

/healtracker trigger add elemental rifts open | PAL - Water\nSK - Earth\nWAR - Fire | color=yellow beep=3 dismiss=12

/healtracker trigger add Mind Crash | CC BREAK | color=yellow beep=1 mob=Aaryonar
```

The last example uses `mob=` so it only fires when both "Mind Crash" AND "Aaryonar" appear in the line — useful when the same spell name is used by trash mobs you don't want to alert on.

#### Manage existing triggers

| Command | What it does |
|---|---|
| `/healtracker trigger remove N` | Remove trigger number N (from `trigger list`) |
| `/healtracker trigger toggle N` | Enable / disable trigger N (preserves the entry) |
| `/healtracker trigger test N` | Fire trigger N now to test alert positioning / sound |
| `/healtracker trigger clear` | Wipe all triggers |

You can also toggle/test/remove triggers via the Triggers tab UI.

### Test / debug

| Command | What it does |
|---|---|
| `/healtracker test` | Inject a fake heal event for testing aggregation |
| `/healtracker testremote` | Test the actor broadcast path |
| `/healtracker testkill` | Inject a fake kill event for testing fight snapshots |

## Tabs in detail

### Heals tab

Left pane: list of completed fights with When, Mob, Total HP, and heal count. Click a row to drill in. Multi-select with the Sel checkbox to combine multiple fights into a single view.

Right pane: per-character breakdown showing Total HP, heal count, average heal, and max heal. Each character expands to show their per-healer breakdown (who healed them, how much).

### DPS tab

Same structure as Heals. Per-attacker breakdown with Total dmg, hits, DPS, max hit. Toggle "Split pets from owner" to see pet contributions as nested rows underneath each owner.

### Spells tab

Fight list of all spells your group cast during each fight. Useful for counting buffs, heals, nukes, debuffs.

### History tab

Full archive search. Date range presets: Today, Last 24h, Last 7d, Last 30d, All, Custom (last N days). View modes change what the right pane shows:

- **DPS** — damage breakdown
- **Heals** — heal breakdown
- **Spells** — group spell breakdown
- **Mob Spells** — mob spell rotation with per-cast timestamps (expandable)
- **All** — everything stacked

Mob picker dropdown filters to a specific mob. Multi-select to combine fights or use "Load filtered into current view" to bulk-load archived fights into the active in-memory tabs.

### Session tab

Rolling totals across all fights since the last session reset. Per-character totals for both heals and damage. Quick reset button.

### Triggers tab

Configured triggers shown as a table:

| On | Pattern | Label | Color | Beep | Auto-X | Actions |
|---|---|---|---|---|---|---|
| ☑ | begins casting Death Touch | DUCK NOW! | red | x3 | 8s | Test / X |

Action buttons: **Test** fires the alert immediately so you can see/hear how it'll appear; **X** removes the trigger.

The tab also includes a help reference for the slash command syntax.

### Settings tab

- Drivers list with per-name add/remove
- Pet/owner mapping dropdowns (auto-populated from observed unmapped damage)
- Toggle: Split pets from owner
- Toggle: Auto-reset session on kill
- Toggle: Mini view default
- Mini columns count (1-3)
- Linger seconds slider
- Fight timeout slider

## Last Fight popup

After each completed fight, a separate floating window pops up showing the Gamparse-style summary:

```
Mob name (colored by consider) - 814k @81415sdps in 10s
1. Walse + pets    350k @35094sdps  (35094dps in 10s)  [43.1%]
2. Eyehop + pets   170k @17029sdps  (28383dps in 6s)   [20.9%]
...
```

Names in green, totals/DPS in yellow, parens/percent in muted gray. The window cycles through queued fights if multiple fights end in quick succession (`(1 of 3)` indicator at top).

## Live mini bar

A compact floating bar showing combined damage across all currently-active mobs:

```
+ DPS Tracker  Heals  Reset
Total: 484,920    DPS: 37,301    Last kill: froglok krup enchanter

Walse + pets       168,977 @ 12,998
Ayehop + pets      117,985 @  9,075
Screamz + pets      83,680 @  6,436
...
```

Updates every frame during combat. Lingers for `linger N` seconds after the last fight ends, then clears.

Toggle between damage view and heals view with the buttons at the top. Reset wipes the session.

## Raid alerts overlay

Floating window that appears only when triggers fire. Stacks alerts vertically; each shows:

- The alert label in the configured color (red/orange/yellow/etc.)
- Multi-line labels render as multiple stacked lines
- Countdown timer in seconds
- X button to dismiss manually

Auto-hides when all alerts are dismissed or expire. Reposition by dragging the title bar — position is remembered across sessions.

## Driver vs reporter mode

- **Driver characters** (in the `drivers` config list) display the UI, store all data, and run kill detection. Set with `/healtracker driver`.
- **Reporter characters** silently broadcast their local heals and damage events to the driver via MQ Actors. No UI. They consume minimal CPU.

You can have multiple drivers (e.g. tank + cleric) — each will show its own independent UI and aggregate from all reporters.

## Known issues

- `/lua stop` can crash MQ in `vsprintf_s_l` due to an engine re-entry bug during teardown. Use `/healtracker stop` or `/lua reload` instead.
- `ImGui.InputText` causes overlay errors in the current MQ binding, so all text input is via slash commands and dropdown pickers.
- Older fights from before specific feature releases won't have data for newer features (mob levels, mob spells). New fights will populate fully.

## Architecture notes

- **Per-mob fight model** — each mob has an independent damage scope. Boss fights aren't fragmented when adds die.
- **Per-encounter heals/spells** — heals and spells snapshot when the LAST mob in an encounter dies (preserving the full fight context). Empty placeholders maintain index alignment with the damage fight list.
- **Stale-fight saving** — mobs idle for `fightTimeoutSeconds` save as fights rather than getting discarded.
- **Persistent archive** — every snapshotted fight is appended to `archive.lua` with sentinel-bracketed records for streaming reads. Never wiped by clear commands.
- **Smart attacker parser** — multi-word pet names (e.g. charmed mobs) parsed by trying longest known prefix first.
- **Strict attribution** — only group/raid characters and mapped pets count as attackers. Strangers walking by with their pets won't pollute your parse.

## License

This is community/personal-use software. Do whatever you want with it.
