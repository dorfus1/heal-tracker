# HealTracker

A high-performance heal and damage tracker for EverQuest, built on MacroQuest. Designed to keep up with 54-man raid logs in real time.

Combines a native C++ plugin (`MQ2HealParse`) that parses combat lines at multi-thousands-per-second with a feature-rich Lua frontend (`heal_tracker.lua`) that handles aggregation, persistence, an ImGui UI, fight history, triggers, and cross-box heal broadcasting.

## What it does

- **Real-time heal tracking** — captures heals to you, on you, by you, runes, and self-procs. Cross-box: every character reports its received heals to the driver so the driver sees a full raid picture.
- **Real-time DPS tracking** — per-fight DPS attribution by attacker (with pets folded into owners). Live mini bar plus full DPS tab with per-target and per-damage-type breakdowns.
- **Fight history** — auto-snapshots every fight, persisted to disk. Browse and compare prior pulls.
- **Raid triggers** — alert on arbitrary chat patterns (special abilities, mob calls, etc.) with optional beep and on-screen banner.
- **Native parser** — combat lines are parsed in-process via `OnIncomingChat`, not via log-file tailing. No `mq.TLO.Spawn` lookups in the hot path, no file IO, no Lua regex on the hot path. The Lua frontend only sees pre-parsed structured events.

## Requirements

- MacroQuest (any modern build; verified on the Project Lazarus MQ fork)
- A working MQ plugin build environment (Visual Studio 2022 + MacroQuest source) to compile `MQ2HealParse.dll`

## Files

```
heal_tracker.lua             main script (UI, aggregation, fight tracking, triggers, persistence)
heal_tracker_bridge.lua      bridges the plugin's events into heal_tracker.lua's hooks
heal_tracker_fastparse.lua   optimized Lua fallback parser (used if the plugin is absent)
MQ2HealParse/MQ2HealParse.cpp   native C++ plugin source
MQ2HealParse/MQ2HealParse.vcxproj   Visual Studio project file
```

## Installation

### 1. Compile the plugin

1. Drop the `MQ2HealParse/` folder into your MacroQuest plugin source tree (e.g. `MacroQuest/plugins/MQ2HealParse/`).
2. Add `MQ2HealParse.vcxproj` to the MacroQuest solution in Visual Studio.
3. Build x64-Release.
4. `MQ2HealParse.dll` ends up in your MQ plugins folder.

### 2. Install the Lua scripts

Drop these three files into your MQ Lua directory (e.g. `MacroQuest/lua/`):

- `heal_tracker.lua`
- `heal_tracker_bridge.lua`
- `heal_tracker_fastparse.lua`

### 3. Load it up

In-game on every character that should participate (driver and all healers/dps):

```
/plugin mq2healparse load
/lua run heal_tracker
```

On reload you should see:
```
[HealTracker] fast parser engaged (processCombatLine)
[HealTracker] fast parser engaged (logTailerPoll)
[HealTracker-Bridge] installed; MQ2HealParse plugin active
[HealTracker-Bridge] Lua log tailer disabled (plugin is now parsing)
[HealTracker] bindLocalEvents() SKIPPED -- plugin is driving events
```

### 4. Set your driver

The **driver** is the character that aggregates raid-wide damage and serves as the central UI. Every other box reports its received heals to the driver via MQ's Actor IPC.

```
/healtracker driver set <YourMainCharacter>
```

## How it works

EQ writes each character's combat events (heals received, damage taken/dealt, kills, casts) only to that character's own log. To get a complete raid picture, the plugin runs on every box and parses that box's local chat stream natively in C++. On non-driver boxes the bridge forwards only heal events (the data EQ doesn't replicate to other characters). On the driver box, the bridge forwards everything — heals, damage, kills, spell casts.

The plugin hooks `OnIncomingChat()` so it sees each line the instant EQ generates it (before the log file is even written). Parsed events are emitted as tagged chat lines (`/hpevt|kind|key=value|...`) which the bridge captures via `mq.event` and routes into `recordHeal`/`recordDamage`/`recordSpellCast`/`onKill`. The bridge auto-filters those plumbing lines from the visible chatbox.

## Commands

### `/healtracker` (Lua-side commands)
```
/healtracker                     show status
/healtracker show | hide         toggle main window
/healtracker mini                toggle live DPS mini bar
/healtracker driver set <name>   set the driver character
/healtracker debug on | off      verbose chat logging
/healtracker timeout <N>         seconds of idle before fight closes (default 10)
/healtracker reset               clear current session
```

### `/healparse` (plugin commands)
```
/healparse status                show plugin counters
/healparse on | off              pause/resume parsing
/healparse reset                 clear plugin's internal counters
/healparse debug on | off        log every matched line to chat
/healparse pet add <pet> <owner> map a named pet to its owner
/healparse pet del <pet>
/healparse pet list
```

### `/htbridge` (diagnostic)
```
/htbridge                        show bridge event counters and plugin TLO state
```

## TLO

`${HealParse.X}` exposes parser internals:

```
${HealParse.Enabled}             bool
${HealParse.LinesSeen}           total lines processed
${HealParse.LinesMatched}        lines that matched a parser
${HealParse.EventsPosted}        events forwarded to Lua
${HealParse.TotalDamage}         sum across all attackers
${HealParse.TotalHeals}          sum across all targets
${HealParse.DamageBy[Name]}      total damage by Name
${HealParse.HealsOn[Name]}       total heals received by Name
${HealParse.SpellCasts[Name]}    spell casts by Name
```

## Troubleshooting

**Plugin loaded but tracker shows nothing.** Run `/htbridge`. If `events_posted` from the plugin is climbing but bridge `heal/damage` counters aren't, the bridge isn't receiving — verify `heal_tracker_bridge.lua` is in your Lua dir and reload heal_tracker.

**Damage double-counted (~2x).** The Lua's own chat-event listeners are still firing alongside the plugin. Check that you see `bindLocalEvents() SKIPPED` on load. If not, your `heal_tracker.lua` is out of date.

**Fights not closing on kill.** Run `/htbridge` and watch the `kill` counter while killing mobs. If it's climbing, the plugin's emitting kills fine — check `/healtracker debug on` for `KILL closed immediately`. If `kill` counter isn't climbing, the bridge's raw-slain fallback should be catching them — make sure your `heal_tracker_bridge.lua` is current.

**Heal events not showing from other boxes.** The plugin must be loaded AND `heal_tracker.lua` must be running on every character. Driver receives heal events via MQ Actor IPC.

**Want to stop parsing temporarily.** `/healparse off`. `/log off` does **not** stop the plugin — it reads from EQ's in-process chat stream, not the log file.

## Performance

In a 54-man raid, the original pure-Lua parser hit ~13ms per combat line (dominated by synchronous `mq.TLO.Spawn` lookups for player/NPC classification on every damage event). The plugin path is sub-100µs per line because all classification is done from a cached known-player set populated as combat unfolds. The Lua frontend only gets pre-classified events.

## Credits

Built iteratively to solve raid-scale parser lag on Project Lazarus. The plugin design intentionally mirrors `MQ2DPSAdv`'s approach but feeds a richer Lua UI.
