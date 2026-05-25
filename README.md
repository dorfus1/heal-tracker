# HealTracker Lua for MacroQuest / EverQuest

Professional real-time Heal, DPS, Spell, and Fight History tracker for EverQuest using MacroQuest Lua + MQ2HealParse support.

Designed for:
- Groups
- Raids
- E3/E3Next setups
- Project Lazarus
- Live DPS tracking similar to GamParse
- Persistent fight history and comparisons

---

# Features

## Live DPS Tracker
- Real-time live DPS window
- GamParse-style live updates
- Top 10 live DPS display
- Damage percentages
- Compact mini tracker
- Mob con-color support
- Fight timer
- Million/k/m number formatting

## Heal Tracking
- Incoming heal detection
- Rune absorb tracking
- Heal source breakdowns
- Healing received drilldowns
- Mini live heal tracker

## Spell Tracking
- Spell cast tracking
- Per-caster spell views
- Spell compare mode
- Spell cast counts
- Burn/disc detection

## Fight History
- Permanent fight archive
- Search/sort support
- Date filters
- Player comparisons
- Mob comparisons
- Damage type breakdowns

## Modern UI
- TurboLoot-style dashboard UI
- Rounded panels/buttons
- Glossy dark theme
- Compact mini windows
- Borderless popups
- Live UI hot-reload system

---

# Requirements

## MacroQuest
Requires:
- MacroQuest
- MQ2Lua
- MQ2HealParse

## Recommended
- E3Next / E3N compatible
- Project Lazarus compatible

---

# Installation

## Step 1 - Install Files

Place ALL HealTracker files into:

```text
MacroQuest/lua/
```

Example:

```text
C:\MacroQuest\lua\
```

or

```text
C:\E3N Beta\E3NextAndMQNextBinary-main\lua\
```

---

## Step 2 - Copy Included Files

Current required files:

```text
heal_tracker.lua
heal_tracker_ui_patch.lua
heal_tracker_windows_patch.lua
heal_tracker_commands_patch.lua
```

Optional image folder:

```text
# Screenshots

```

# Screenshots

## Main DPS Window

<a href="https://raw.githubusercontent.com/cnwalse-dev/heal-tracker/main/HealTracker/screenshots/LUA_DPS.png">
  <img src="https://raw.githubusercontent.com/cnwalse-dev/heal-tracker/main/HealTracker/screenshots/LUA_DPS.png" width="900">
</a>

## Heals Window

<a href="HealTracker/screenshots/LUA_HEALS.png">
  <img src="HealTracker/screenshots/LUA_HEALS.png?raw=true" width="900">
</a>

## Spells Window

<a href="HealTracker/screenshots/LUA_Spells.png">
  <img src="HealTracker/screenshots/LUA_Spells.png?raw=true" width="900">
</a>

## History Window

<a href="HealTracker/screenshots/LUA_History.png">
  <img src="HealTracker/screenshots/LUA_History.png?raw=true" width="900">
</a>

## After Fight Popup

<a href="HealTracker/screenshots/LUA_Afterfight.png">
  <img src="HealTracker/screenshots/LUA_Afterfight.png?raw=true" width="900">
</a>

## Live DPS Mini Tracker

<a href="HealTracker/screenshots/Live_DPS.png">
  <img src="HealTracker/screenshots/Live_DPS.png?raw=true" width="500">
</a>

## Live Heals Mini Tracker

<a href="HealTracker/screenshots/Live_Heals.png">
  <img src="HealTracker/screenshots/Live_Heals.png?raw=true" width="500">
</a>

Recommended logo path:

```text
heal_tracker_images/HealTracker.png
```

---

# Starting HealTracker

Run on ALL characters:

```text
/lua run heal_tracker
```

---

# MQ2HealParse Plugin

HealTracker works alongside:

```text
/plugin mq2healparse
```

MQ2HealParse assists with:
- Combat parsing
- Spell events
- Faster event handling

The Lua itself still maintains:
- Fight tracking
- DPS calculations
- UI
- History
- Comparisons
- Live parse logic

---

# Important Stability Notes

## DO NOT USE

```text
/lua stop heal_tracker
```

on the driver during combat/fight history activity.

MQ2Lua can crash EverQuest during hard unloads.

---

# Safe Reload System

HealTracker now includes a safe live reload system.

After updating files, use:

```text
/e3bcga /healtracker reloadsafe
```

This safely reloads:
- UI
- Window layouts
- Commands/settings

WITHOUT:
- Restarting EQ
- Restarting parser
- Losing live fights
- Crashing MQ2Lua

---

# Other Reload Commands

## Reload UI Only

```text
/healtracker reloadui
```

Reloads:
- Colors
- Theme
- Styling

---

## Reload Windows/Layout

```text
/healtracker reloadwindows
```

Reloads:
- Window layouts
- Compare panels
- Mini tracker layouts
- Popup rendering

---

## Reload Commands

```text
/healtracker reloadcommands
```

Reloads:
- Slash commands
- Command handlers
- Settings logic

---

# Main Commands

## General

```text
/healtracker
/healtracker show
/healtracker mini
/healtracker stop
/healtracker start
/healtracker reloadsafe
```

---

## DPS

```text
/healtracker fastdps on
/healtracker fastdps off
```

---

## Search

```text
/healtracker search froglok
/healtracker search
```

---

## Alpha / Transparency

```text
/healtracker alpha 100
/healtracker alpha 75
/healtracker alpha 50
```

---

## Driver

```text
/healtracker driver
/healtracker driver clear
/healtracker driver list
```

---

## Reset

```text
/healtracker reset
/healtracker fights clear
```

---

## Burn Mapping

```text
/healtracker burn list
/healtracker burn add <phrase> => <discipline>
/healtracker burn remove <phrase>
```

---

## Testing

```text
/healtracker test
/healtracker testkill
/healtracker testremote
```

---

# How HealTracker Works

## Driver Character
One character acts as the main parser/UI driver.

The driver:
- Tracks fights
- Owns UI
- Stores history
- Processes DPS/heals/spells
- Displays live parse windows

## Reporter Characters
Other characters:
- Send heal/combat information
- Share events with the driver
- Run lightweight tracking

---

# Mini Windows

## DPS Mini
- Live DPS
- Top 10
- Compact GamParse style

## Heal Mini
- Live healing
- Current fight
- Heal totals

---

# Compare Features

## Player Compare
Compare:
- Damage
- DPS
- Hits
- Max hit
- Spell casts
- Damage types
- Burns/discs

## Mob Compare
Compare:
- Fight totals
- DPS
- Duration
- Player contributions

---

# Damage Type Breakdown

Tracks:
- Melee
- Spell
- Proc
- DoT
- Pet
- Swarm Pet

---

# History System

Permanent archive includes:
- DPS fights
- Heals
- Spells
- Fight timestamps
- Drilldowns
- Compare support

---

# Recommended Update Workflow

1. Replace updated files
2. Run:

```text
/e3bcga healtracker reloadsafe
```

3. Continue playing normally

---

# Credits

Created by Dorfus
