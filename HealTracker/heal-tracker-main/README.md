# HealTracker

A real-time heal and damage tracker for EverQuest, built on MacroQuest. Designed to keep up with 54-man raid logs without falling behind.

Combines a native C++ MacroQuest plugin (`MQ2HealParse`) that parses combat lines at thousands per second with a feature-rich Lua frontend (`heal_tracker.lua`) that handles aggregation, persistence, an ImGui UI, fight history, triggers, and cross-box heal broadcasting.

## Screenshots

### DPS Dashboard
Per-attacker totals, hits, DPS, max hit and percent of total. Right pane breaks down damage type per player (melee/spell/proc/DoT/pet/swarm) with compare mode for side-by-side player analysis.

<img width="2343" height="1332" alt="image" src="https://github.com/user-attachments/assets/9ac66bfc-2cb0-4671-9cf6-dd59ac260cfa" />



### Heals Dashboard
Per-target healing breakdown showing every player who received healing, with source-by-source detail (total HP, count, average, max heal). Includes rune absorbs as fixed-value heal credits.

<img width="2345" height="1334" alt="image" src="https://github.com/user-attachments/assets/de387980-c731-4d1e-b621-f697f5cca738" />



### Live Mini Trackers
Two collapsible floating bars. The DPS tracker shows active-fight DPS in real time. The Heal tracker shows who's healing who. Toggle between modes from the mini-bar itself.

<img width="248" height="209" alt="image" src="https://github.com/user-attachments/assets/5407d7cf-52ab-408c-b832-6fc10cfcb05d" />

<img width="226" height="109" alt="image" src="https://github.com/user-attachments/assets/18f61e4a-7d37-44f8-b3f8-a39441bbed17" />


## Features

- **Real-time heal tracking** — captures heals on/by/to you, runes, and self-procs. Cross-box: every character reports its received heals back to the driver via MQ Actor IPC so the driver sees the entire raid.
- **Real-time DPS tracking** — per-fight attribution by attacker, with pets folded into owners. Damage-type breakdown (melee, spell, proc, DoT, pet, swarm) per player. Compare mode for side-by-side analysis.
- **Fight history** — every kill auto-snapshots a fight to disk. Browse, filter, search, range-select, and combine prior pulls.
- **Spell cast tracking** — tracks cast counts per caster for the driver's session.
- **Raid triggers** — alert on arbitrary chat patterns with optional beep, banner, and chat-log entry.
- **Native parser** — combat lines are parsed in-process via `OnIncomingChat`, not via log-file tailing. No `mq.TLO.Spawn` lookups in the hot path. The Lua frontend only sees pre-parsed structured events drained from an in-memory queue.
- **No chat-window noise** — plugin/Lua communication uses an in-memory event queue (drained via TLO each frame). Nothing appears in the EQ chatbox or MQ console.


## Files

```
heal_tracker.lua                 main script (UI, aggregation, fight tracking, triggers, persistence)
heal_tracker_bridge.lua          plugin -> Lua event bridge
heal_tracker_fastparse.lua       optimized Lua fallback parser (used if plugin is absent)
MQ2HealParse/MQ2HealParse.cpp    native C++ plugin source
MQ2HealParse/MQ2HealParse.vcxproj   Visual Studio project file
```

## Installation

### 1. Install the plugin DLL

Copy `MQ2HealParse.dll` into your MacroQuest plugins folder (typically the same folder as your other MQ2 plugin DLLs).

### 2. Install the Lua scripts

Copy these three files into your MQ Lua directory (e.g. `MacroQuest/lua/`):

- `heal_tracker.lua`
- `heal_tracker_bridge.lua`
- `heal_tracker_fastparse.lua`

### 3. Load it up

In-game on every character that should participate:

```
/plugin mq2healparse load
/lua run heal_tracker
```

On a clean load you should see:
```
[HealTracker] fast parser engaged (processCombatLine)
[HealTracker] fast parser engaged (logTailerPoll)
[HealTracker-Bridge] installed; MQ2HealParse plugin active
[HealTracker-Bridge] Lua log tailer disabled (plugin is now parsing)
[HealTracker] bindLocalEvents() SKIPPED -- plugin is driving events
```

### 4. Set your driver

The **driver** is the character that aggregates raid-wide damage and serves as the central UI. Every other box reports its received heals to the driver via MQ Actor IPC.

```
/healtracker driver set <YourMainCharacter>
```

## How it works

EQ writes each character's combat events (heals received, damage taken/dealt, kills, casts) only to that character's own log. To get a complete raid picture, the plugin runs on every box and parses that box's local chat stream natively in C++.

- On **non-driver boxes**, the bridge forwards only received-heal events (data the driver can't see in its own log) over MQ Actor IPC to the driver.
- On the **driver box**, the bridge forwards everything — heals, damage, kills, spell casts — into the heal_tracker UI.

The plugin hooks `OnIncomingChat()` so it sees each chat line the instant EQ generates it, before the log file is written. Parsed events are pushed onto an in-memory queue. Each frame, the Lua bridge drains the queue via the `${HealParse.Drain[N]}` TLO and routes events into `recordHeal`/`recordDamage`/`recordSpellCast`/`onKill`. No chat-stream lines, no MQ console noise.

## Commands

### `/healtracker` (main UI / Lua-side)
```
/healtracker                     show status
/healtracker show | hide         toggle main window
/healtracker mini                toggle live mini bar
/healtracker driver set <name>   set the driver character
/healtracker debug on | off      verbose chat logging
/healtracker timeout <N>         seconds of idle before fight closes (default 10)
/healtracker reset               clear current session
/healtracker search <text>       filter fights by mob name
```

### `/healparse` (plugin commands)
```
/healparse status                show plugin counters (lines seen, matched, events queued)
/healparse on | off              pause/resume parsing (plugin stays loaded)
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

`${HealParse}` exposes parser internals:

```
${HealParse.Enabled}             bool
${HealParse.LinesSeen}           total lines processed
${HealParse.LinesMatched}        lines that matched a parser
${HealParse.EventsPosted}        events forwarded to Lua
${HealParse.QueueDepth}          pending events not yet drained
${HealParse.Drain[N]}            pop up to N events (used internally by bridge)
${HealParse.TotalDamage}         sum across all attackers
${HealParse.TotalHeals}          sum across all targets
${HealParse.DamageBy[Name]}      total damage by Name
${HealParse.HealsOn[Name]}       total heals received by Name
${HealParse.SpellCasts[Name]}    spell casts by Name
```

## Troubleshooting

**Plugin loaded but tracker shows nothing.**
Run `/htbridge`. If `events_posted` from the plugin is climbing but bridge `heal`/`damage` counters aren't, the bridge isn't receiving — verify `heal_tracker_bridge.lua` is in your Lua dir and reload heal_tracker.

**Damage double-counted (~2x).**
The Lua's own chat-event listeners are still firing alongside the plugin. Verify you see `bindLocalEvents() SKIPPED` on load. If not, your `heal_tracker.lua` is out of date.

**Fights not closing on kill.**
Run `/htbridge` and watch the `kill` counter while killing mobs. If it's climbing, the plugin's emitting kills fine — verify with `/healtracker debug on` for `KILL closed immediately` lines. If `kill` counter isn't climbing, the bridge's raw-slain fallback should catch them — make sure your `heal_tracker_bridge.lua` is current.

**Heal events not showing from other boxes.**
The plugin must be loaded AND `heal_tracker.lua` must be running on every character. Driver receives heal events via MQ Actor IPC.

**Want to stop parsing temporarily.**
`/healparse off`. Note that `/log off` does **not** stop the plugin — the plugin reads from EQ's in-process chat stream, not the log file.

## Performance

In a 54-man raid, the original pure-Lua parser hit ~13ms per combat line (dominated by synchronous `mq.TLO.Spawn` lookups for player/NPC classification on every damage event). The plugin path is sub-100µs per line because all classification uses a cached known-player set populated as combat unfolds. The Lua frontend only gets pre-classified events drained from an in-memory queue.

## Credits

Built iteratively to solve raid-scale parser lag on Project Lazarus. The plugin design borrows the in-process `OnIncomingChat` approach from `MQ2DPSAdv` but exposes the parsed data to a richer Lua UI.
