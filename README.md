[README.md](https://github.com/user-attachments/files/27492506/README.md)
# heal-tracker
A MacroQuest Lua script for EverQuest multiboxers. Tracks group heals, damage (DPS), and spell casts across all your boxes, displays them in an ImGui window on your driver character, and persists fight history across reloads.  Inspired by Gamparse but live, in-game, and zero-configuration once your driver is set up.
# heal_tracker

A MacroQuest Lua script for EverQuest multiboxers. Tracks group heals, damage (DPS), and spell casts across all your boxes, displays them in an ImGui window on your driver character, and persists fight history across reloads.

Inspired by Gamparse but live, in-game, and zero-configuration once your driver is set up.

---

## Features

- **Live heal, damage, and spell-cast tracking** with per-character breakdowns
- **Multi-box aware** — runs on every character, but only the driver shows the UI and aggregates data
- **Per-fight snapshots** triggered by slain messages OR a configurable damage-inactivity timeout
- **Pet attribution** — pet damage rolls into the owner's row (Gamparse-style "Owner + pets")
- **Toggle pets split out** as nested rows for visibility
- **Combine multiple fights** into a single aggregated view via checkboxes
- **Spell cast log** — see what each character cast and how many times
- **Captures damage from outside your group** — raid mates and zone allies are auto-recognized
- **Manual spell→caster mappings** for DoT ticks that EQ writes without caster attribution
- **Persistent storage** — fight history, configs, and mappings survive `/lua reload`
- **Driver-only UI** — reporters run silently in the background, no window flicker or duplicate windows

---

## Installation

1. Place `heal_tracker.lua` in your MacroQuest `lua/` directory:
   ```
   <MQ>/lua/heal_tracker/heal_tracker.lua
   ```
2. On every character you want to participate (typically your whole group), run:
   ```
   /lua run heal_tracker
   ```
3. On your main / tank character, designate it as the driver:
   ```
   /healtracker driver
   ```
   The window opens automatically on driver characters.

That's it. Damage, heals, and spell casts will start being captured the moment combat begins.

---

## How it works

- **Reporters** (every box) watch their local chat for heal events and broadcast them to the driver via the MQ Actors framework. They don't show a UI.
- **Driver** (whichever character you designate) watches its own chat for damage and spell-cast events (which EQ shows to your screen for everyone in your group), aggregates everything, and renders the UI.
- **Fight lifecycle:** a fight starts when the first damage event lands on a mob. It ends on either a slain message OR after `fightTimeoutSeconds` of no damage activity (default 8s). Heals and damage during downtime are NOT recorded — this eliminates buff-tick noise and ensures DPS calculations reflect actual time-on-mob.
- **Pet attribution:** any line like `<Owner>'s pet hits...` is automatically credited to the owner. Named pets (e.g. `Hookerr`, `Eyehp`) need a one-time map setup via `/healtracker pet add`.
- **Persistent storage** lives in `<MQ>/config/heal_tracker/`:
  - `config.lua` — settings, drivers list, pet/spell mappings
  - `fights.lua` — heal fight history
  - `damage.lua` — damage fight history
  - `spells.lua` — spell-cast history

---

## UI tabs

- **Session** — running totals since the script started or last reset
- **Heals** — per-fight heal breakdown with per-character + per-healer details, multi-fight combine, copy-to-clipboard
- **DPS** — per-fight damage breakdown with per-attacker DPS, max hit, hits. Pets shown as `Owner + pets` by default; toggle "Split pets from owner" for nested view. Multi-fight combine.
- **Spells** — flat list of every spell cast plus per-caster breakdown
- **Settings** — fight timeout, debug, auto-reset, mini-mode toggle

There's also a mini bar mode for compact display.

---

## Slash commands

### General
| Command | Description |
|---|---|
| `/healtracker` | Show status (driver/reporter, totals, timeout, in-combat) |
| `/healtracker show` | Toggle the window open/closed |
| `/healtracker mini` | Toggle mini bar / full window |
| `/healtracker stop` | Exit the script cleanly |

### Driver management
| Command | Description |
|---|---|
| `/healtracker driver` | Make THIS character a driver |
| `/healtracker driver clear` | Remove THIS character from drivers |
| `/healtracker driver list` | Show all driver names |

### Session & fights
| Command | Description |
|---|---|
| `/healtracker reset` | Clear session totals (broadcasts to group) |
| `/healtracker report` | Print session totals to chat |
| `/healtracker fights` | Show count of recorded fights |
| `/healtracker fights clear` | Wipe ALL history (heals + damage + spells) |
| `/healtracker autoreset on\|off` | Snapshot a fight on each kill (default on) |
| `/healtracker timeout N` | End fight after N seconds of no damage. 0 = off. Default 8 |

### Pet attribution
| Command | Description |
|---|---|
| `/healtracker pet add <pet> <owner>` | Map a named pet to its owner |
| `/healtracker pet remove <pet>` | Remove a pet mapping |
| `/healtracker pet list` | Show all pet → owner mappings |
| `/healtracker pet clear` | Wipe all pet mappings |

Examples:
```
/healtracker pet add Hookerr Screamz
/healtracker pet add Hooker Ayehop
/healtracker pet add Eyehp Eyehop
```

Note: pets in possessive form (`Eyehop's pet`, `Bob's warder`) are auto-attributed and don't need a manual map.

### Spell attribution
For DoT ticks that come without a caster (`<mob> has taken N damage from <Spell>.`):

| Command | Description |
|---|---|
| `/healtracker spell add <Spell> <Caster>` | Map a DoT spell to its caster |
| `/healtracker spell remove <Spell>` | Remove a spell mapping |
| `/healtracker spell list` | Show all spell → caster mappings |
| `/healtracker spell clear` | Wipe all spell mappings |

Spell names can have spaces — the LAST argument is treated as the caster:
```
/healtracker spell add Dread Pyre Screamz
/healtracker spell add Funeral Pyre of Keladar Screamz
/healtracker spell add Turn Undead Dorias
```

### Other
| Command | Description |
|---|---|
| `/healtracker min N` | Ignore heals below N HP (default 1) |
| `/healtracker debug` | Toggle debug logging in chat |

### Testing
| Command | Description |
|---|---|
| `/healtracker test [healer] [amt]` | Inject a fake local heal |
| `/healtracker testremote [tgt] [hlr] [amt]` | Inject a fake remote heal (driver only) |
| `/healtracker testkill [mob]` | Inject a fake kill snapshot (driver only) |

---

## Damage line formats supported

The script handles the major EQ damage-line formats:

- **Melee third-person:** `Bob hits a goblin for 596 points of damage.`
- **Melee first-person:** `You bash a goblin for 1342 points of damage.`
- **Possessive pet:** `Bob's pet backstabs a goblin for 596 points of damage.`
- **Non-melee (DoT/proc):** `Bob hit a goblin for 4648 points of non-melee damage.`
- **Spell with caster — Format A:** `a goblin has taken 3100 damage from Horror by Bob.`
- **Spell with caster — Format B:** `a goblin has taken 28561 damage from Bob by Turn Undead.`
- **Spell anonymous:** `a goblin has taken 9126 damage from Dread Pyre.` (resolved via observed casts or `spell add` map)
- **Your spell:** `a goblin has taken 1234 damage from your Force Strike.`
- **Paladin Slay Undead:** `Bob's holy blade cleanses his target!(3858)`

---

## Tips for accurate tracking

- **Set up pet mappings once** for any named pets in your group (e.g., necromancer pets named "Hookerr", mage pets named "Hooker", etc.).
- **Add spell mappings** for your group's main DoT spells the first time you see `[HealTracker] SPELL-ANON UNRESOLVED: <SpellName>` in debug mode. Once mapped, they'll be auto-attributed forever.
- **Adjust `fightTimeoutSeconds`** based on your encounter style. 6-10s is typical. Long-pause raid fights may need higher.
- **Run on every box you want heals from** — the driver only sees damage/spell-casts, but heals to other boxes need each box reporting.
- **Driver designation persists** in config — once you `/healtracker driver` on your main, it stays the driver across reloads and zoning.

---

## Architecture notes

For anyone reading the code:

- **Single Lua file** — no module split, ~3300 lines
- **Three parallel data scopes** — heals (`fights[]`), damage (`damageFights[]`), spells (`spellsFights[]`) — kept index-aligned so `fights[i]`, `damageFights[i]`, `spellsFights[i]` all refer to the same fight
- **Lazy fight-start timing** — duration timer starts on first damage event, not on script boot or last kill, for accurate DPS
- **Debounced disk saves** at 3-second intervals to avoid I/O during combat
- **All callbacks pcall-wrapped** with `shuttingDown` latches at every entry point to handle MQ teardown gracefully
- **Actor-based cross-box messaging** — uses MQ's Actors framework, NOT chat broadcast, to avoid spam
- **Single broad melee event** (`'#*# for #*# point#*#damage#*#'`) replaces what was originally 60+ verb-specific events — handles every melee verb without needing a maintained list
- **Case-insensitive pet name lookups** — `petOwners` map can be added with any casing; lookups try exact match first, then lowercase scan
- **Auto-discovery of player characters** — `knownChars` set is populated from group members, raid members, heal events, and a Spawn TLO fallback for non-grouped/non-raided allies in the zone

---

## Known limitations

- **DoT ticks applied before script start** can't be attributed unless the caster is in `config.spellOwners`. Cast events populate the live map, but if a DoT was already ticking when the script loaded, you'll need a manual mapping.
- **Crashes occasionally on `/lua stop`** — known re-entry issue in the `mq2lua` engine itself. Data is safe due to debounced saves. Workaround: use `/lua reload heal_tracker` or `/healtracker stop`.
- **Mob name on timeout fights** is best-effort — if the damage scope tracked a single target, it's used; otherwise the placeholder `(timeout)` is used.

---

## Configuration file

`<MQ>/config/heal_tracker/config.lua` — auto-generated, edit at your own risk:

```lua
return {
    drivers              = { "Dorfus" },
    petOwners            = { Hookerr = "Screamz", Hooker = "Ayehop" },
    spellOwners          = { ["Dread Pyre"] = "Screamz" },
    fightTimeoutSeconds  = 8,
    autoResetOnKill      = true,
    minHealAmount        = 1,
    debug                = false,
    splitPetsInDps       = false,
    miniMode             = false,
    -- ... etc
}
```

---

## License

MIT — do whatever you want with it.

## Credits

Modeled after [loot_money.lua](#) and inspired by Gamparse's reporting layout.
Built for E3Next/MacroQuest Beta builds; should work on standard MQ as well.
