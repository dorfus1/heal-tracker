--[[
   ============================================================================
   Heal Tracker  v3.10.1  -  group heal/DPS/spell aggregator with persistence
   ============================================================================

   v3.10.1 changes:
     - Replaced inline search-box widget with /healtracker search slash
       command. The MQ ImGui Lua binding for InputText was triggering
       overlay-pause errors that we couldn't resolve. The slash command
       sidesteps the binding issue entirely. Usage:
         /healtracker search froglok    (filter current tab to "froglok")
         /healtracker search            (clear filter on current tab)
       The active filter shows at the top of each tab's fight list with
       a "Clear" button.

   v3.10.0 changes:
     - History tab Date/Time/Mob/amount columns are now sortable.
     - Search filter on Heals, DPS, Spells, History tabs (now via
       /healtracker search slash command -- see v3.10.1).

   v3.9.1 changes:
     - History tab now has a View mode picker (DPS / Heals / Spells / All).
       Switches both the list's right-column metric (total dmg vs. heals
       vs. casts) and the right-pane drill-down (which sections show).

   v3.9.0 changes:
     - New "History" tab. Browses the persistent fight archive with
       date-range filters (Today / Last 24h / Last 7d / Last 30d / All /
       Custom N days). Click any archived fight to drill into the full
       per-character damage breakdown -- same view as the live DPS tab.
     - "Load filtered into current view" button bulk-loads matching
       archived fights into the active in-memory state, so the regular
       Heals/DPS/Spells tabs can show them with sort/combine/select-all
       all working as usual.
     - New archive.lua file in <MQ>/config/heal_tracker/ stores full
       fight detail (per-character breakdowns) for every snapshot.
       Append-only, never wiped by /healtracker fights clear.

   v3.8.1 changes:
     - Added permanent append-only fight history log. Every snapshotted
       fight writes a one-line summary to <MQ>/config/heal_tracker/history.log
       This file is NEVER wiped by /healtracker fights clear -- it's the
       user's permanent record. New /healtracker log command shows the
       path and entry count.

   v3.8.0 changes:
     - Sortable column headers on Heals/DPS/Spells fight lists. Click any
       column header (When/Mob/Dmg/HP/Casts) to cycle the sort order.
     - Tab persistence improved: the active tab no longer resets to Session
       after each fight. Session moved to a later position in the tab bar
       so the worst-case fallback lands on Heals (more useful) instead.
     - Mini mode toggle now restores the user's last active tab when
       expanding back to the full window.
     - Necromancer swarm pets ("X's Animated Corpse") now properly attribute
       damage to the owner. Same generic possessive-form matching applies
       to any "<Owner>'s <something>" pet/swarm/proc form.
     - Pet/swarm deaths no longer trigger spurious kill snapshots.
     - Timeout fights (no slain message after fightTimeoutSeconds of
       inactivity) are now discarded instead of recorded as "(timeout)"
       entries -- in-progress data treated as noise.
     - DPS table sorts purely by total damage descending; the driver's row
       is no longer pinned to the top.
     - Character names sanitized from comments and example strings; this
       file is safe to redistribute.

   KNOWN LIMITATIONS
     - "/lua stop heal_tracker" may crash EQ via vsprintf_s_l in mq2lua.
       This is a known engine-level re-entry issue, not script-specific.
       Workarounds: use "/healtracker stop", "/lua reload heal_tracker",
       or just leave the script running. Data is debounce-saved every
       3 seconds, so no meaningful data is lost on crash.
     - DoT ticks applied before script start cannot be auto-attributed.
       Use "/healtracker spell add <Spell> <Caster>" to map them.

   ============================================================================

   ARCHITECTURE
   ------------
   Run on every box. The window only opens on a SPECIFIC character marked
   as a driver. Other boxes run silently.

     Reporter (every non-driver box):
       - Watches its own EQ chat for "<Healer> has healed you for <N> points."
       - Sends the heal to other heal_tracker scripts via MQ Actors.

     Driver (the named driver character only):
       - Same heal detection.
       - Watches for damage and spell-cast events from group/raid chat.
       - Watches for kill messages and snapshots heals/damage/spells into
         per-fight records.
       - Fight timeout watchdog: if no damage events come in for
         fightTimeoutSeconds, the in-progress data is discarded as noise.
       - Persists fight history, config, pet maps, and spell maps to disk.

   COMMANDS
   --------
     /healtracker                     -- print quick status
     /healtracker driver [clear|list] -- driver management
     /healtracker show                -- toggle the window (driver only)
     /healtracker mini                -- toggle minimize between mini and full
     /healtracker report              -- print totals to chat
     /healtracker reset               -- clear session totals (broadcast)
     /healtracker fights clear        -- wipe ALL recorded fights
     /healtracker autoreset on|off    -- toggle auto-reset on kill
     /healtracker idle N              -- idle-reset after N seconds (0=off)
     /healtracker min N               -- ignore heals below N (default 1)
     /healtracker debug               -- toggle debug logging
     /healtracker test [healer] [amt]
     /healtracker testremote [target] [healer] [amt]
     /healtracker testkill [mobname]
     /healtracker stop

   @version heal_tracker.lua 3.5.0
--]]

local mq    = require('mq')
local ImGui = require('ImGui')

local okActors, Actors = pcall(require, 'actors')
if not okActors or not Actors then
    print('\ar[HealTracker]\ax FATAL: this script requires the MQ Actors framework.')
    return
end

local M = { running = true }
local shuttingDown = false

-- =============================================================================
-- Identity & configuration
-- =============================================================================

local MyName   = mq.TLO.Me.CleanName() or 'unknown'
local MyServer = (mq.TLO.EverQuest.Server() or 'unknown'):gsub(' ', '_')

local config = {
    drivers          = {},
    debug            = false,
    minHealAmount    = 1,
    windowOpen       = false,
    miniMode         = false,
    miniColumns      = 2,
    -- What to show on the mini collapsed bar: 'heals' shows live session
    -- heals (the original behavior), 'dps' shows the in-progress fight's
    -- DPS so far. Toggle on the bar itself or via /healtracker miniview.
    miniShowDps      = false,
    autoResetOnKill  = true,
    killGraceMs      = 500,
    -- Named-pet -> owner mapping. EQ has no marker on the actual pet
    -- name in chat, so the user has to tell us. Configure with
    --   /healtracker pet add PetName Necro
    -- The map persists in config.lua across restarts.
    petOwners        = {},
    -- Manual spell -> caster map for DoT/spell damage lines that
    -- arrive without a "by <caster>" suffix. EQ writes most DoT ticks
    -- as just "<mob> has taken N damage from <Spell>." with no
    -- attribution -- if we never observed the cast (because the spell
    -- was cast before the script started, or was a long-running DoT
    -- from before the latest snapshot), we have no way to know who
    -- to credit. The user can pre-populate this map with known DoT
    -- spells via /healtracker spell add "Dread Pyre" Necro.
    -- Case-insensitive lookup in code; persisted across restarts.
    spellOwners      = {},
    -- DPS tab: when true, show pets as separate rows under their
    -- owner. When false (default), pets are folded into the owner's
    -- row labeled "<Owner> + pets".
    splitPetsInDps   = false,
    -- Fight timeout. A fight starts on the first damage event landing
    -- on a mob and ends either on a slain message OR after this many
    -- seconds of no damage activity. Heals received while no fight is
    -- active are NOT recorded. Set to 0 to disable timeout (fights only
    -- end on slain messages).
    fightTimeoutSeconds = 8,
    -- How long (seconds) to keep showing the LAST fight on the mini
    -- collapsed bar after the fight ends. After this many seconds of
    -- no damage activity, the mini view clears to "No active fight."
    -- Set to 0 to clear immediately (default = 5 seconds).
    miniLingerSeconds = 5,
    -- Primary-target-only kill detection. When true (default), a slain
    -- message only ends the current fight if the slain mob has taken
    -- a significant share of the fight's total damage (i.e. it's a
    -- primary target, not just an add). This prevents boss fights
    -- from getting split into chunks every time an add dies. Set to
    -- false to revert to the old behavior where ANY slain message
    -- ends the fight (Gamparse-style, simpler but fragments long
    -- multi-mob encounters).
    primaryTargetOnly = true,
    -- Damage share threshold (as a fraction, 0-1) that a slain mob
    -- needs to have for its death to count as fight-ending under
    -- primaryTargetOnly mode. Default 0.20 (20%) -- a typical add
    -- takes much less than 20% of the boss's damage, so deaths of
    -- adds get ignored. Lower this if your group sometimes leaves
    -- bosses at low HP while killing adds (the boss might end up
    -- below 20%). Higher = more strict (only kills the very biggest
    -- target end the fight).
    primaryTargetThreshold = 0.20,
}

local function isDriver()
    for _, name in ipairs(config.drivers or {}) do
        if name == MyName then return true end
    end
    return false
end

-- =============================================================================
-- State
-- =============================================================================

local function emptyScope(label)
    return {
        label    = label,
        stats    = {},
        total    = 0,
        count    = 0,
        max      = 0,
        -- started is set LAZILY -- the first heal event into this
        -- scope stamps it. This way the heal-fight duration reflects
        -- actual time spent healing in this fight, not "time since
        -- the script booted" or "time since the last reset".
        started  = nil,
        ended    = nil,
    }
end

local session      = emptyScope(nil)
local currentFight = emptyScope(nil)
local fights       = {}

-- Damage tracking (driver only). Parallel to the heal state above:
--   damageFights[i] mirrors fights[i] -- same indices = same fight.
-- Each damage scope has shape:
--   {
--     stats = { [attacker] = { total, count, max, targets = {[mob]={total,count,max}} } },
--     total, count, max, started, ended, label
--   }
-- Pets are folded into their owner ("Tank`s pet" -> "Tank") so the
-- DPS table shows one row per real player. The kill snapshot path
-- snapshots BOTH heal and damage scopes at the same time so the two
-- lists stay aligned across restarts.
local function emptyDamageScope(label)
    return {
        label   = label,
        stats   = {},
        total   = 0,
        count   = 0,
        max     = 0,
        -- started is set LAZILY -- the first damage event into this
        -- scope stamps it. This way the fight-duration timer (used for
        -- DPS calculations) reflects actual time-on-mob, not "time
        -- since the last kill" or "time since the script booted".
        started = nil,
        ended   = nil,
    }
end

-- Per-mob damage tracking. Each mob the group damages gets its OWN
-- scope, keyed by mob name. When the mob dies, we snapshot ONLY that
-- mob's scope as a single fight entry. This preserves boss damage
-- across add deaths -- bosses no longer get fragmented when an add
-- dies during the encounter.
--
-- Each mob's scope has its own `started` (first hit) and `lastHitAt`
-- so the timeout watchdog can age them out independently.
--
-- Shape:
--   activeMobs = {
--     ["a goblin"]    = damageScope (with started, lastHitAt, etc.),
--     ["Boss Mob"]    = damageScope,
--     ...
--   }
local activeMobs         = {}
local damageFights       = {}

-- Helper: return the scope for `mobName`, creating it if needed.
-- Stamps `started` to now on first creation.
local function getOrCreateMobScope(mobName)
    if not mobName or mobName == '' then return nil end
    local s = activeMobs[mobName]
    if not s then
        s = emptyDamageScope(mobName)
        s.started = os.time()
        s.lastHitAt = os.time()
        -- Capture the mob's level via Spawn TLO while it's alive. Used
        -- to color the mob name in the UI based on EQ's consider
        -- system (red = much higher, white = even, blue/green = lower).
        -- We only get one chance -- once the mob is dead, the spawn
        -- info is gone. Stored as mobLevel on the scope so it survives
        -- snapshotting into damageFights[].
        local ok, lvl = pcall(function()
            local sp = mq.TLO.Spawn('npc "' .. mobName .. '"')
            if sp() then return tonumber(sp.Level()) end
            return nil
        end)
        if ok and lvl then s.mobLevel = lvl end
        activeMobs[mobName] = s
    end
    return s
end

-- Returns the EQ-consider color (RGB triple) for a mob given its level
-- relative to MyLevel. Thresholds:
--   red    : 4+ levels above
--   yellow : 1-3 levels above
--   white  : even level
--   dark   : 1-5 levels below       (dark blue)
--   cyan   : 6-13 levels below      (light blue)
--   green  : 14-20 levels below
--   gray   : 21+ levels below
-- Falls back to white if level info is missing.
local function mobLevelColor(mobLevel)
    if not mobLevel or mobLevel == 0 then
        return 1.0, 1.0, 1.0  -- white default when unknown
    end
    local myLvl = 0
    pcall(function() myLvl = tonumber(mq.TLO.Me.Level()) or 0 end)
    if myLvl == 0 then return 1.0, 1.0, 1.0 end

    local diff = mobLevel - myLvl  -- positive = mob above me, negative = below
    if diff >= 4 then
        return 1.00, 0.30, 0.30  -- red
    elseif diff >= 1 then
        return 1.00, 1.00, 0.20  -- yellow
    elseif diff == 0 then
        return 1.00, 1.00, 1.00  -- white
    elseif diff >= -5 then
        return 0.40, 0.55, 1.00  -- dark blue (1-5 below)
    elseif diff >= -13 then
        return 0.40, 0.85, 1.00  -- cyan / light blue (6-13 below)
    elseif diff >= -20 then
        return 0.30, 1.00, 0.30  -- green (14-20 below)
    else
        return 0.55, 0.55, 0.55  -- gray (21+ below)
    end
end

-- Helper: build a synthetic combined scope summing damage across all
-- currently-active mobs. Used by the mini view and Session tab to
-- show "everything that's happening right now". Read-only -- doesn't
-- mutate activeMobs.
local function combineActiveMobs()
    local combined = emptyDamageScope('Active')
    local earliestStart = nil
    for _, mobScope in pairs(activeMobs) do
        if mobScope.started and (not earliestStart or mobScope.started < earliestStart) then
            earliestStart = mobScope.started
        end
        for atk, s in pairs(mobScope.stats or {}) do
            combined.stats[atk] = combined.stats[atk] or
                { total = 0, count = 0, max = 0, targets = {}, pets = {},
                  firstHit = nil, lastHit = nil }
            local cs = combined.stats[atk]
            cs.total = cs.total + (s.total or 0)
            cs.count = cs.count + (s.count or 0)
            if (s.max or 0) > cs.max then cs.max = s.max end
            for tgt, t in pairs(s.targets or {}) do
                cs.targets[tgt] = cs.targets[tgt] or { total = 0, count = 0, max = 0 }
                cs.targets[tgt].total = cs.targets[tgt].total + (t.total or 0)
                cs.targets[tgt].count = cs.targets[tgt].count + (t.count or 0)
                if (t.max or 0) > cs.targets[tgt].max then
                    cs.targets[tgt].max = t.max
                end
            end
            for petName, p in pairs(s.pets or {}) do
                cs.pets[petName] = cs.pets[petName] or { total = 0, count = 0, max = 0 }
                cs.pets[petName].total = cs.pets[petName].total + (p.total or 0)
                cs.pets[petName].count = cs.pets[petName].count + (p.count or 0)
                if (p.max or 0) > cs.pets[petName].max then
                    cs.pets[petName].max = p.max
                end
            end
            if s.firstHit and (not cs.firstHit or s.firstHit < cs.firstHit) then
                cs.firstHit = s.firstHit
            end
            if s.lastHit and (not cs.lastHit or s.lastHit > cs.lastHit) then
                cs.lastHit = s.lastHit
            end
        end
        combined.total = combined.total + (mobScope.total or 0)
        combined.count = combined.count + (mobScope.count or 0)
        if (mobScope.max or 0) > combined.max then combined.max = mobScope.max end
    end
    combined.started = earliestStart
    return combined
end

-- Spell cast tracking (driver only). Parallel to heal and damage state:
--   spellsFights[i] mirrors fights[i] / damageFights[i] -- same indices.
-- Each scope has shape:
--   {
--     stats = { [caster] = { total, casts = {[spellName] = count} } },
--     total, started, ended, label
--   }
-- The driver sees both its own "You begin casting <Spell>." and other
-- group members' "<Caster> begins to cast a spell. <Spell>" lines, so
-- no cross-box messaging is needed.
local function emptySpellsScope(label)
    return {
        label   = label,
        stats   = {},
        total   = 0,    -- total cast count across all casters
        started = nil,  -- lazy-stamped on first cast
        ended   = nil,
    }
end

local currentSpellsFight = emptySpellsScope(nil)
local spellsFights       = {}

local killGraceUntil = 0
local lastKillName, lastKillAt = nil, 0

-- Mini view linger state. When fights complete (kill or timeout),
-- their final scope is pushed onto a queue. The mini bar then cycles
-- through the queue, displaying each fight for config.miniLingerSeconds
-- before advancing to the next. After the queue empties, the bar
-- shows live combat (or the "no active fight" placeholder).
--
-- This way, if you kill 4 mobs back-to-back, you can see each fight's
-- full breakdown one at a time, even if combat moved on quickly.
--
-- miniQueue          = array of completed fight scopes waiting to display
-- miniQueueCurrentAt = os.time() when the head-of-queue fight started
--                      its display window. 0 = nothing displaying yet.
-- miniLastSnapshot   = while combat is active, this tracks the live
--                      scope so when the fight ends we can push a
--                      frozen copy onto the queue.
local miniQueue          = {}
local miniQueueCurrentAt = 0
local miniLastSnapshot   = nil
local miniLastSnapshotAt = 0

-- Fight-active state. A fight starts on the first damage event landing
-- on a mob and ends on either a slain message or a no-damage timeout.
-- All heals AND damage are gated on this -- if no fight is active,
-- they're discarded. This eliminates idle-time noise from regen procs,
-- buff heals between pulls, etc.
--
--   fightActive    = boolean, true between first-damage and end-of-fight
--   lastDamageAt   = ms timestamp of most recent damage event, used by
--                    the timeout watchdog to end fights after inactivity
local fightActive  = false
local lastDamageAt = 0

-- Set of character names known to be "on our side" (group members
-- running heal_tracker, plus any named pets configured via petOwners).
-- Populated from three sources:
--   1. Heal events (target / healer fields)
--   2. The Group TLO -- refreshed periodically so back-line casters
--      who never get healed are still recognized
--   3. config.petOwners keys (pets that the user has mapped explicitly)
-- Used by damage parsers to filter out mob-on-player and mob-on-mob
-- damage, and by the kill detector to distinguish kills from deaths.
local knownChars = {}

-- Tracks names that hit known mobs but were filtered out as non-PC.
-- These are typically named pets that haven't been mapped yet
-- (Pookie, Hookerr, etc.). Used by the Settings tab pet-mapping UI
-- so users can see what unmapped attackers have appeared.
--   key: attacker name
--   value: { count = N, lastSeen = ts, lastTarget = "..." }
local unmappedDamage = {}
knownChars[MyName] = true
local function noteKnownChar(name)
    if type(name) == 'string' and name ~= '' and name ~= 'unknown' then
        knownChars[name] = true
    end
end

local lastGroupRefresh = 0
local function refreshKnownCharsFromGroup()
    if shuttingDown then return end
    if (os.time() - lastGroupRefresh) < 5 then return end
    lastGroupRefresh = os.time()
    pcall(function()
        if shuttingDown then return end

        -- Group members.
        local size = tonumber(mq.TLO.Group.Members()) or 0
        for i = 1, size do
            if shuttingDown then return end
            local m = mq.TLO.Group.Member(i)
            if m() then
                local name = m.CleanName() or m.Name() or m()
                if type(name) == 'string' and name ~= '' then
                    name = name:gsub('^%s+', ''):gsub('%s+$', '')
                    knownChars[name] = true
                end
            end
        end

        -- Raid members. The Raid TLO returns 0 if not in a raid, so
        -- this is a no-op for solo or grouped-only setups. When in a
        -- raid, all 60+ raid members get added so their damage to the
        -- same mobs you're fighting is credited correctly.
        local raidSize = tonumber(mq.TLO.Raid.Members()) or 0
        for i = 1, raidSize do
            if shuttingDown then return end
            local m = mq.TLO.Raid.Member(i)
            if m and m() then
                local name = m.CleanName() or m.Name() or m()
                if type(name) == 'string' and name ~= '' then
                    name = name:gsub('^%s+', ''):gsub('%s+$', '')
                    knownChars[name] = true
                end
            end
        end

        for petName, ownerName in pairs(config.petOwners or {}) do
            knownChars[petName]   = true
            knownChars[ownerName] = true
        end
    end)
end

-- Check if `name` is a real player character in the current zone via
-- the Spawn TLO. Used as a last-resort filter pass-through for damage
-- lines from non-group, non-raid players who are fighting the same mob
-- (e.g., random allies in a public zone, mercenaries from other groups,
-- folks who joined the fight). Caches positive results into knownChars
-- so the lookup only happens once per unique attacker name.
--
-- Wrapped in pcall because Spawn lookups can transiently fail during
-- zoning. Caches via knownChars so the next damage line skips the
-- TLO call entirely.
local function isPlayerInZone(name)
    if type(name) ~= 'string' or name == '' then return false end
    if knownChars[name] then return true end
    local found = false
    pcall(function()
        local sp = mq.TLO.Spawn(string.format('pc =%s', name))
        if sp and sp() then
            local typ = sp.Type()
            if typ == 'PC' then
                found = true
                knownChars[name] = true
            end
        end
    end)
    return found
end

-- Fights tab selection state. fightSelected[idx]=true means the user has
-- ticked the checkbox on that fight (used for combine + multi-select copy).
-- selectedFightIdx is the single click-selected row for the right-pane
-- drilldown when no checkboxes are ticked.
local fightSelected = {}
local selectedFightIdx = nil

-- Selection state for the DPS tab. Independent from the Heals tab so
-- the user can drill into different fights in each. Has both a
-- click-selected single index AND a checkbox set for combine.
local selectedDamageIdx = nil
local damageSelected = {}

-- Selection state for the Spells tab. Independent of the other tabs.
local selectedSpellsIdx = nil
local spellsSelected = {}

-- Sort state for each fight-list table. Each entry is a {col, dir}
-- pair where col is 'when' / 'mob' / 'amount' and dir is 'asc' or 'desc'.
-- Default: newest first (col='when', dir='desc').
local healsSort  = { col = 'when', dir = 'desc' }
local damageSort = { col = 'when', dir = 'desc' }
local spellsSort = { col = 'when', dir = 'desc' }
local historySort = { col = 'when', dir = 'desc' }

-- Per-tab search filters. The user types a substring; fights whose
-- mob name doesn't contain the substring (case-insensitive) are
-- hidden from the list. Empty string = no filter.
local healsSearch   = ''
local damageSearch  = ''
local spellsSearch  = ''
local historySearch = ''

-- Tab restoration tracking. The render callback compares these to
-- the current fight counts each frame; if they differ, the active
-- tab is force-restored to config.lastTab. Module-level locals (not
-- _G) so we don't touch globals during MQ teardown.
local htLastFightCount = 0
local htLastDmgCount   = 0
local htLastSpCount    = 0

-- History tab state.
--   archiveCache: results of the last loadArchive() call, kept here so
--     we don't reload from disk every render frame
--   archiveRange: which preset is active ('today', '24h', '7d', '30d', 'all', 'custom')
--   archiveCustomDays: integer, used when range='custom'
--   archiveSelectedTs: timestamp of the entry the user clicked, for drill-down
--   archiveMode: which data type to focus the right-pane view on:
--     'all'   = show everything (default)
--     'dps'   = damage breakdown only
--     'heals' = heal breakdown only
--     'spells'= spell cast breakdown only
local archiveCache       = nil
local archiveCacheRange  = nil
local archiveRange       = '7d'
local archiveCustomDays  = 30
local archiveSelectedTs  = nil
local archiveMode        = 'all'

-- Multi-select state for the History tab. Maps timestamp -> true for
-- each checked archive entry. Keyed by timestamp (rec.ts) rather than
-- index because the index can change when the date range filter
-- shifts which entries are in archiveCache.
local archiveSelected    = {}
-- Trigger to refresh when set externally (e.g. on snapshot).
-- Marker that says "the next reload should go to disk". Set when the
-- tab is first opened or after a snapshot, cleared after refresh.
local archiveNeedsRefresh = true
local mobSpellsNeedsRefresh = true

-- Sort state for the right-pane per-character breakdown tables.
local healsCharSort  = { col = 'total', dir = 'desc' }
local damageCharSort = { col = 'total', dir = 'desc' }
local spellsCharSort = { col = 'total', dir = 'desc' }

-- Helper: render a sortable column header. Click cycles desc -> asc -> desc.
-- Returns true if the user clicked it this frame.
local function sortHeader(label, sortState, colKey)
    local arrow = ''
    if sortState.col == colKey then
        arrow = (sortState.dir == 'asc') and ' \\^' or ' v'
    end
    -- Use a Selectable so the whole cell is clickable. Compact size,
    -- aligned left.
    if ImGui.Selectable(label .. arrow .. '##sort_' .. label, false) then
        if sortState.col == colKey then
            sortState.dir = (sortState.dir == 'asc') and 'desc' or 'asc'
        else
            sortState.col = colKey
            sortState.dir = 'desc'
        end
        return true
    end
    return false
end

-- Helper: build a sorted index list from a fight array. Sorted by
-- the given column ('when', 'mob', 'amount') in the given direction.
-- Returns array of indices into the original array (so other state
-- like selection checkboxes still works by index).
local function sortedFightIndices(arr, sortState, amountField)
    local indices = {}
    for i = 1, #arr do indices[i] = i end
    local col = sortState.col or 'when'
    local desc = (sortState.dir or 'desc') == 'desc'
    table.sort(indices, function(a, b)
        local fa, fb = arr[a], arr[b]
        local va, vb
        if col == 'when' then
            va = fa.ended or fa.started or 0
            vb = fb.ended or fb.started or 0
        elseif col == 'mob' then
            va = (fa.label or ''):lower()
            vb = (fb.label or ''):lower()
        elseif col == 'amount' then
            va = fa[amountField] or 0
            vb = fb[amountField] or 0
        else
            va, vb = a, b
        end
        if va == vb then return a < b end
        if desc then return va > vb end
        return va < vb
    end)
    return indices
end

-- Same as sortedFightIndices but ALSO filters out fights whose mob
-- label doesn't contain the search substring (case-insensitive).
-- Empty search returns the unfiltered sorted list.
local function filteredSortedIndices(arr, sortState, amountField, search, labelKey)
    local raw = sortedFightIndices(arr, sortState, amountField)
    if not search or search == '' then return raw end
    local needle = search:lower()
    local out = {}
    for _, i in ipairs(raw) do
        local fight = arr[i]
        local label = (fight and fight[labelKey or 'label']) or ''
        if label:lower():find(needle, 1, true) then
            table.insert(out, i)
        end
    end
    return out
end

-- (showSearchStatus / mob filter helpers are defined later, after THEME
-- and btn() so we can use them without scoping issues. See the section
-- right after btn() definition.)
local showSearchStatus  -- forward declaration; assigned below
local uniqueMobsFromFights  -- forward declaration; assigned below

local function clearFightSelection()
    fightSelected   = {}
    selectedFightIdx = nil
    selectedDamageIdx = nil
    damageSelected  = {}
    selectedSpellsIdx = nil
    spellsSelected  = {}
end

local function getSelectedIndices()
    local out = {}
    for idx, on in pairs(fightSelected) do
        if on and fights[idx] then table.insert(out, idx) end
    end
    table.sort(out)
    return out
end

local function getSelectedDamageIndices()
    local out = {}
    for idx, on in pairs(damageSelected) do
        if on and damageFights[idx] then table.insert(out, idx) end
    end
    table.sort(out)
    return out
end

local function getSelectedSpellsIndices()
    local out = {}
    for idx, on in pairs(spellsSelected) do
        if on and spellsFights[idx] then table.insert(out, idx) end
    end
    table.sort(out)
    return out
end

local function nowMs()
    return mq.gettime and mq.gettime() or (os.time() * 1000)
end

-- =============================================================================
-- Persistence
-- =============================================================================

local function dataDir()
    return mq.configDir .. '/heal_tracker'
end

local lfs_ok, lfs = pcall(require, 'lfs')
local dirChecked, dirExists = false, false

local function ensureDir()
    if dirChecked then return dirExists end
    dirChecked = true
    local probe = dataDir() .. '/.probe'
    local f = io.open(probe, 'w')
    if f then
        f:close(); os.remove(probe)
        dirExists = true; return true
    end
    if lfs_ok and lfs and lfs.mkdir then
        pcall(function() lfs.mkdir(dataDir()) end)
        local f2 = io.open(probe, 'w')
        if f2 then
            f2:close(); os.remove(probe)
            dirExists = true; return true
        end
    end
    dirExists = false
    return false
end

local function resolvedConfigPath()
    if ensureDir() then
        return string.format('%s/config.lua', dataDir())
    end
    return string.format('%s/heal_tracker_config.lua', mq.configDir)
end

local function resolvedFightsPath()
    if ensureDir() then
        return string.format('%s/fights.lua', dataDir())
    end
    return string.format('%s/heal_tracker_fights.lua', mq.configDir)
end

local function resolvedDamagePath()
    if ensureDir() then
        return string.format('%s/damage.lua', dataDir())
    end
    return string.format('%s/heal_tracker_damage.lua', mq.configDir)
end

local function resolvedSpellsPath()
    if ensureDir() then
        return string.format('%s/spells.lua', dataDir())
    end
    return string.format('%s/heal_tracker_spells.lua', mq.configDir)
end

-- Permanent append-only fight history log. One human-readable line per
-- fight, written every time a fight is snapshotted. SURVIVES "Clear all
-- fights" -- this file is intentionally never wiped by the script. The
-- user is responsible for archiving or pruning it manually if it grows
-- too large.
local function resolvedHistoryLogPath()
    if ensureDir() then
        return string.format('%s/history.log', dataDir())
    end
    return string.format('%s/heal_tracker_history.log', mq.configDir)
end

-- Persistent fight archive. Unlike fights.lua/damage.lua/spells.lua
-- (which mirror the active in-memory state and get overwritten on
-- every save), this file is APPEND-ONLY. Each entry is a self-
-- contained Lua-serializable record that holds heal + damage + spell
-- data for one fight. The History tab reads from here.
--
-- Format: one record per `return` in the file. We append by writing
-- a separator + serialized record. Loading parses with iterative
-- pattern matching on the separator.
--
-- Archive lives alongside the active files but is never wiped by
-- "Clear all fights".
local function resolvedArchivePath()
    if ensureDir() then
        return string.format('%s/archive.lua', dataDir())
    end
    return string.format('%s/heal_tracker_archive.lua', mq.configDir)
end

local function serialize(tbl, indent)
    indent = indent or ''
    local nextIndent = indent .. '  '
    local isArray, n = true, 0
    for k in pairs(tbl) do
        n = n + 1
        if type(k) ~= 'number' then isArray = false; break end
    end
    if isArray then
        for i = 1, n do
            if tbl[i] == nil then isArray = false; break end
        end
    end
    local parts = { '{\n' }
    if isArray then
        for i = 1, n do
            local v = tbl[i]
            local valStr
            if type(v) == 'table' then valStr = serialize(v, nextIndent)
            elseif type(v) == 'string' then valStr = string.format('%q', v)
            elseif v == nil then valStr = 'nil'
            else valStr = tostring(v) end
            table.insert(parts, string.format('%s%s,\n', nextIndent, valStr))
        end
    else
        for k, v in pairs(tbl) do
            local keyStr
            if type(k) == 'string' then keyStr = string.format('[%q]', k)
            else keyStr = string.format('[%s]', tostring(k)) end
            local valStr
            if type(v) == 'table' then valStr = serialize(v, nextIndent)
            elseif type(v) == 'string' then valStr = string.format('%q', v)
            elseif v == nil then valStr = 'nil'
            else valStr = tostring(v) end
            table.insert(parts, string.format('%s%s = %s,\n', nextIndent, keyStr, valStr))
        end
    end
    table.insert(parts, indent .. '}')
    return table.concat(parts)
end

local function saveConfig()
    local f = io.open(resolvedConfigPath(), 'w')
    if not f then return end
    -- Build a filtered copy. Keys starting with "_" are transient
    -- runtime flags that shouldn't persist across reloads.
    local saveable = {}
    for k, v in pairs(config) do
        if type(k) ~= 'string' or k:sub(1, 1) ~= '_' then
            saveable[k] = v
        end
    end
    f:write('return ')
    f:write(serialize(saveable))
    f:write('\n')
    f:close()
end

local function loadConfig()
    local ok, data = pcall(dofile, resolvedConfigPath())
    if ok and type(data) == 'table' then
        for k, v in pairs(data) do config[k] = v end
        config.windowOpen = isDriver()
    end
end

local fightsDirty = false
local lastFightsFlush = 0
local FIGHTS_FLUSH_INTERVAL = 3

local function saveFights(force)
    if not isDriver() then return end
    if not force then
        fightsDirty = true
        return
    end
    local f = io.open(resolvedFightsPath(), 'w')
    if not f then return end
    f:write('return ')
    f:write(serialize(fights))
    f:write('\n')
    f:close()
    fightsDirty = false
    lastFightsFlush = os.time()
end

local function flushFightsIfDirty()
    if not fightsDirty then return end
    if not isDriver() then fightsDirty = false; return end
    if (os.time() - lastFightsFlush) < FIGHTS_FLUSH_INTERVAL then return end
    saveFights(true)
end

local function loadFights()
    local ok, data = pcall(dofile, resolvedFightsPath())
    if ok and type(data) == 'table' then
        fights = data
    end
end

-- Damage persistence -- same dirty/debounce pattern as fights.
local damageDirty = false
local lastDamageFlush = 0

local function saveDamage(force)
    if not isDriver() then return end
    if not force then
        damageDirty = true
        return
    end
    local f = io.open(resolvedDamagePath(), 'w')
    if not f then return end
    f:write('return ')
    f:write(serialize(damageFights))
    f:write('\n')
    f:close()
    damageDirty = false
    lastDamageFlush = os.time()
end

local function flushDamageIfDirty()
    if not damageDirty then return end
    if not isDriver() then damageDirty = false; return end
    if (os.time() - lastDamageFlush) < FIGHTS_FLUSH_INTERVAL then return end
    saveDamage(true)
end

local function loadDamage()
    local ok, data = pcall(dofile, resolvedDamagePath())
    if ok and type(data) == 'table' then
        damageFights = data
    end
end

-- Spells persistence -- same dirty/debounce pattern.
local spellsDirty = false
local lastSpellsFlush = 0

local function saveSpells(force)
    if not isDriver() then return end
    if not force then
        spellsDirty = true
        return
    end
    local f = io.open(resolvedSpellsPath(), 'w')
    if not f then return end
    f:write('return ')
    f:write(serialize(spellsFights))
    f:write('\n')
    f:close()
    spellsDirty = false
    lastSpellsFlush = os.time()
end

local function flushSpellsIfDirty()
    if not spellsDirty then return end
    if not isDriver() then spellsDirty = false; return end
    if (os.time() - lastSpellsFlush) < FIGHTS_FLUSH_INTERVAL then return end
    saveSpells(true)
end

local function loadSpells()
    local ok, data = pcall(dofile, resolvedSpellsPath())
    if ok and type(data) == 'table' then
        spellsFights = data
    end
end

-- =============================================================================
-- Aggregation
-- =============================================================================

local function bumpScope(scope, target, healer, amount)
    scope.stats[target] = scope.stats[target] or
        { total = 0, count = 0, max = 0, healers = {} }
    local s = scope.stats[target]
    s.total = s.total + amount
    s.count = s.count + 1
    if amount > s.max then s.max = amount end

    s.healers[healer] = s.healers[healer] or { total = 0, count = 0, max = 0 }
    s.healers[healer].total = s.healers[healer].total + amount
    s.healers[healer].count = s.healers[healer].count + 1
    if amount > s.healers[healer].max then
        s.healers[healer].max = amount
    end

    scope.total = scope.total + amount
    scope.count = scope.count + 1
    if amount > scope.max then scope.max = amount end
end

local function recordHeal(target, healer, amount)
    target = target or 'unknown'
    healer = healer or 'unknown'
    amount = tonumber(amount) or 0
    if amount < config.minHealAmount then return end

    -- Build the known-character set as a side effect so the kill
    -- detector can later distinguish "ally killed mob" from "ally died".
    -- This happens BEFORE the fight-active gate so out-of-combat heals
    -- still teach us who's in the group.
    noteKnownChar(target)
    noteKnownChar(healer)

    -- Fight-active gate. Out-of-combat heals are discarded entirely.
    -- Exception: the kill grace window keeps late-arriving heals
    -- credited to the just-ended fight (the killing-blow heal often
    -- arrives the same frame as the slain message but slightly after
    -- it).
    if not fightActive and nowMs() >= killGraceUntil then
        return
    end

    bumpScope(session, target, healer, amount)

    if config.autoResetOnKill and isDriver()
       and nowMs() < killGraceUntil
       and #fights > 0 then
        bumpScope(fights[#fights], target, healer, amount)
        saveFights()
    else
        -- Lazy-stamp started so heal-fight duration reflects time
        -- since the FIRST heal of this encounter, not since script
        -- boot or the last reset. This brings heal duration in line
        -- with damage duration (which already does this).
        if not currentFight.started then
            currentFight.started = os.time()
        end
        bumpScope(currentFight, target, healer, amount)
    end
end

local function resetSession()
    session = emptyScope(nil)
end

-- =============================================================================
-- Damage tracking (driver only)
-- =============================================================================

-- Pet attribution: collapse "<owner>`s pet" / "<owner>'s pet" / "<owner>`s
-- warder" into "<owner>". EQ uses backtick most of the time but quote
-- occasionally; both are caught.
-- Pet attribution.
--
-- EQ pets come in two flavors that need separate handling:
--   1. Generic owned pet text: "<owner>'s pet" / "<owner>`s pet" / warder
--      We strip the suffix and credit the owner. EZ in regex.
--   2. Named pets: necro/mage/beastlord pets summon with random names
--      like "PetName" -- there is NO marker in the chat line
--      tying them back to their owner. The user has to TELL us via
--      config.petOwners. Add entries with /healtracker pet add
--      <petname> <owner>.
--
-- Also strips a trailing period (EQ sometimes writes "Splort." as a
-- spell-name attacker, with the period included). Without this, "Bob"
-- and "Bob." would be tracked as different attackers.
local function attributeDamage(attacker)
    if type(attacker) ~= 'string' or attacker == '' then return 'unknown' end

    -- Strip trailing period and whitespace.
    attacker = attacker:gsub('[%s%.]+$', '')

    -- Possessive-form owner extraction. Order matters: try the most
    -- specific patterns first, then fall back to generic.
    local owner = attacker:match("^(.-)[`']s%s+pet$")
                  or attacker:match("^(.-)[`']s%s+warder$")
                  or attacker:match("^(.-)[`']s%s+ward$")
                  or attacker:match("^(.-)[`']s%s+Animated Corpse$")
                  or attacker:match("^(.-)[`']s%s+Swarm$")
    if owner and owner ~= '' then
        -- Teach knownChars about resolved owners so downstream filters
        -- pass even if the owner has never been healed.
        knownChars[owner] = true
        return owner
    end

    -- Generic possessive fallback: if the attacker has the form
    -- "<X>'s <something>", and <X> is a known character, attribute to
    -- <X>. This catches all the various swarm/proc/summoned pet
    -- suffixes EQ uses (Animated Corpse, Swarm of Decay, Vexing
    -- Mercenary, etc.) without needing to enumerate every variant.
    local maybeOwner = attacker:match("^(.-)[`']s%s+%S")
    if maybeOwner and maybeOwner ~= '' and knownChars[maybeOwner] then
        return maybeOwner
    end

    -- User-supplied named-pet map (config.petOwners[pet] = owner).
    -- Case-insensitive lookup so the user can type the pet name in any
    -- case via /healtracker pet add. EQ always sends pet names with a
    -- capital first letter (e.g. "PetName"), but we don't want to force
    -- the user to remember capitalization.
    local map = config.petOwners or {}
    if map[attacker] then
        knownChars[map[attacker]] = true
        return map[attacker]
    end
    local lowerAttacker = attacker:lower()
    for petName, ownerName in pairs(map) do
        if petName:lower() == lowerAttacker then
            knownChars[ownerName] = true
            return ownerName
        end
    end

    return attacker
end

-- Case-insensitive lookup of a name in config.petOwners. Returns true
-- if the name is mapped (regardless of casing) -- used by damage
-- filters to recognize pets even when the user typed the petOwners
-- entry in a different case than EQ writes.
local function isKnownPet(name)
    if type(name) ~= 'string' or name == '' then return false end
    local map = config.petOwners or {}
    if map[name] then return true end
    local lower = name:lower()
    for petName in pairs(map) do
        if petName:lower() == lower then return true end
    end
    return false
end

-- Bump damage stats. The `attacker` arg is the OWNER name (after pet
-- attribution) -- this is what the table aggregates by. The optional
-- `rawName` is the original chat-line attacker name; if it differs
-- from the owner, the damage is also tracked as a sub-entry under
-- s.pets[rawName] so the UI can show pet-vs-owner contributions.
local function bumpDamageScope(scope, attacker, target, amount, rawName)
    scope.stats[attacker] = scope.stats[attacker] or
        { total = 0, count = 0, max = 0, targets = {}, pets = {},
          firstHit = nil, lastHit = nil }
    local s = scope.stats[attacker]
    s.total = s.total + amount
    s.count = s.count + 1
    if amount > s.max then s.max = amount end

    -- Track first and last hit timestamps so we can compute the
    -- character's active time window (lastHit - firstHit). Used for
    -- Gamparse-style "active dps" reports vs "sustained dps" (which
    -- uses the full fight duration).
    local now = os.time()
    if not s.firstHit then s.firstHit = now end
    s.lastHit = now

    s.targets[target] = s.targets[target] or { total = 0, count = 0, max = 0 }
    s.targets[target].total = s.targets[target].total + amount
    s.targets[target].count = s.targets[target].count + 1
    if amount > s.targets[target].max then
        s.targets[target].max = amount
    end

    -- Pet sub-entry. Only if rawName was a pet (i.e. attribution
    -- mapped it to a different owner). If rawName equals attacker,
    -- this is a self-attack -- no pet sub-entry needed.
    s.pets = s.pets or {}
    if rawName and rawName ~= attacker then
        s.pets[rawName] = s.pets[rawName] or { total = 0, count = 0, max = 0 }
        s.pets[rawName].total = s.pets[rawName].total + amount
        s.pets[rawName].count = s.pets[rawName].count + 1
        if amount > s.pets[rawName].max then
            s.pets[rawName].max = amount
        end
    end

    scope.total = scope.total + amount
    scope.count = scope.count + 1
    if amount > scope.max then scope.max = amount end
end

local function recordDamage(rawAttacker, target, amount)
    if not isDriver() then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if not target or target == '' then return end

    local rawName = rawAttacker or 'unknown'
    -- Strip trailing punctuation/whitespace so "Bob." and "Bob" don't
    -- create separate sub-entries.
    if type(rawName) == 'string' then
        rawName = rawName:gsub('[%s%.]+$', '')
    end
    local attacker = attributeDamage(rawName)
    -- Normalize "You" / "you" to MyName so the driver's own damage shows
    -- under their character name in the table.
    if attacker == 'You' or attacker == 'you' then
        attacker = MyName
    end
    if rawName == 'You' or rawName == 'you' then
        rawName = MyName
    end

    -- Mark the fight as active. The first damage event in any fight
    -- transitions us from "idle" to "in combat" -- heals start being
    -- recorded from this moment on, and the timeout watchdog starts
    -- watching for inactivity. lastDamageAt is updated on every
    -- subsequent damage event so the timeout resets while the fight
    -- is alive.
    -- Reject damage where the TARGET is a known PC. Mobs are the
    -- things we track fights against; PCs taking incidental damage
    -- (DoT splash, recoil, fall damage, charm-pet attacking owner,
    -- etc.) should not create an activeMobs scope. Without this,
    -- a PC name like "Eyehop" can become a "fight" entry and
    -- accumulate spell/heal data that actually belongs to the real
    -- mob fight happening alongside it.
    if knownChars[target] then return end
    if isPlayerInZone and isPlayerInZone(target) then return end

    fightActive  = true
    lastDamageAt = nowMs()

    -- Per-mob routing: each mob has its own scope. Damage to mob X
    -- goes only into mob X's scope, so when X dies, ONLY X's totals
    -- snapshot. Other mobs' scopes continue independently.
    --
    -- Kill-grace: if this is a late hit for the mob that just died
    -- (within killGraceMs of its slain message), tack it onto the
    -- just-snapshotted fight at damageFights[#damageFights] rather
    -- than starting a new scope (which would create a tiny one-hit
    -- fight entry).
    if target == lastKillName
       and nowMs() < killGraceUntil
       and #damageFights > 0 then
        local last = damageFights[#damageFights]
        if last and last.label == target then
            bumpDamageScope(last, attacker, target, amount, rawName)
            saveDamage()
            return
        end
    end

    -- Lazy fight-start: the scope's started timestamp is stamped on
    -- creation (first damage event for that mob).
    local mobScope = getOrCreateMobScope(target)
    if not mobScope then return end
    mobScope.lastHitAt = os.time()

    bumpDamageScope(mobScope, attacker, target, amount, rawName)
end

-- =============================================================================
-- Spell cast tracking (driver only)
-- =============================================================================

-- Map of spell name -> last caster who cast it (case-sensitive). Used
-- to resolve DoT damage lines that don't include a "by <caster>"
-- suffix. EQ writes some DoT ticks as just "<mob> has taken N damage
-- from <Spell>." with no caster attribution -- the only way to know
-- who cast it is to remember our own cast events. Cleared on session
-- reset.
local recentSpellCasts = {}

local function recordSpellCast(caster, spellName)
    if not isDriver() then return end
    if type(caster) ~= 'string' or caster == '' then return end
    if type(spellName) ~= 'string' or spellName == '' then return end

    -- Trim whitespace.
    caster    = caster:gsub('^%s+', ''):gsub('%s+$', '')
    spellName = spellName:gsub('^%s+', ''):gsub('%s+$', '')

    -- Remember the last caster of each spell so DoT ticks without an
    -- explicit "by <caster>" can be attributed correctly.
    recentSpellCasts[spellName] = caster

    if not currentSpellsFight.started then
        currentSpellsFight.started = os.time()
    end

    local s = currentSpellsFight.stats[caster]
    if not s then
        s = { total = 0, casts = {} }
        currentSpellsFight.stats[caster] = s
    end
    s.total = s.total + 1
    s.casts[spellName] = (s.casts[spellName] or 0) + 1

    currentSpellsFight.total = currentSpellsFight.total + 1
end

-- Append a one-line human-readable summary of a just-snapshotted fight
-- to the persistent history log. The log file is append-only and
-- survives "Clear all fights" -- this is the user's permanent record.
--
-- Line format (tab-separated for easy spreadsheet import):
--   [YYYY-MM-DD HH:MM:SS]  mob  dur=Ns  dmg=N (N dps)  hits=N  heals=N  topDmg=Name(N)
--
-- Each line is < ~250 chars. A year of heavy raiding might produce
-- ~50k lines = a few MB, well within reasonable file sizes. If the
-- user's log grows uncomfortably large they can archive/delete it
-- manually -- the script never auto-rotates.
local function appendHistoryLog(healFight, dmgFight, spellsFight, mobName)
    if not isDriver() then return end
    pcall(function()
        local f = io.open(resolvedHistoryLogPath(), 'a')
        if not f then return end

        local ts = os.date('%Y-%m-%d %H:%M:%S',
            (dmgFight and dmgFight.ended)
            or (healFight and healFight.ended)
            or os.time())

        local dmgTotal = (dmgFight and dmgFight.total) or 0
        local dmgHits  = (dmgFight and dmgFight.count) or 0
        local dmgDur   = 0
        if dmgFight and dmgFight.started and dmgFight.ended then
            dmgDur = math.max(0, dmgFight.ended - dmgFight.started)
        end
        local dps = 0
        if dmgDur > 0 then dps = math.floor(dmgTotal / dmgDur) end

        local healTotal = (healFight and healFight.total) or 0

        -- Top damager: scan stats and pick the row with the highest
        -- total damage. Used as a quick "who was the MVP" indicator.
        local topName, topTotal = '-', 0
        if dmgFight and dmgFight.stats then
            for atk, s in pairs(dmgFight.stats) do
                if (s.total or 0) > topTotal then
                    topName = atk
                    topTotal = s.total
                end
            end
        end

        -- Spell-cast count (total casts across all casters in this fight).
        local spellCount = (spellsFight and spellsFight.total) or 0

        local line = string.format(
            '[%s]\t%s\tdur=%ds\tdmg=%d (%d dps)\thits=%d\theals=%d\tspells=%d\ttopDmg=%s(%d)\n',
            ts, mobName or '?',
            dmgDur, dmgTotal, dps, dmgHits, healTotal, spellCount,
            topName, topTotal)

        f:write(line)
        f:close()
    end)
end

-- Append a complete fight record (heals + damage + spells) to the
-- persistent archive. Each record is serialized as a Lua table
-- between sentinel markers so we can parse them back later.
--
-- Sentinel-based format:
--   --[[ HT_RECORD_START ts=<unix> ]]
--   { fight = {...}, damage = {...}, spells = {...}, mob = "...", ts = N }
--   --[[ HT_RECORD_END ]]
--
-- Why not one big Lua table? An archive of 50,000+ fights would have
-- to be loaded entirely into memory just to read one entry. The
-- sentinel approach lets us scan for date ranges with a streaming
-- read and only deserialize matching records.
local function appendArchive(healFight, dmgFight, spellsFight, mobName)
    if not isDriver() then return end
    pcall(function()
        local f = io.open(resolvedArchivePath(), 'a')
        if not f then return end

        local ts = (dmgFight and dmgFight.ended)
                   or (healFight and healFight.ended)
                   or os.time()

        local record = {
            ts     = ts,
            mob    = mobName or '?',
            fight  = healFight,
            damage = dmgFight,
            spells = spellsFight,
        }

        f:write(string.format('--[[ HT_RECORD_START ts=%d ]]\n', ts))
        f:write('return ')
        f:write(serialize(record))
        f:write('\n--[[ HT_RECORD_END ]]\n')
        f:close()
    end)
end

-- Load archive records, optionally filtered by a date range. Returns
-- an array of {ts, mob, fight, damage, spells} tables sorted by ts.
-- Date filtering uses unix timestamps (start/endTs in seconds). Pass
-- nil for either bound to leave it open.
--
-- Streaming-ish: scans the file line-by-line for sentinels, only
-- deserializes records whose timestamp falls in range. For very
-- large archives this avoids loading the full file into memory.
local function loadArchive(startTs, endTs)
    local results = {}
    local path = resolvedArchivePath()
    local f = io.open(path, 'r')
    if not f then return results end

    local inRecord = false
    local recordTs = 0
    local recordLines = {}

    for line in f:lines() do
        local foundTs = line:match('^%-%-%[%[ HT_RECORD_START ts=(%d+) %]%]%s*$')
        if foundTs then
            inRecord = true
            recordTs = tonumber(foundTs) or 0
            recordLines = {}
            -- Skip if outside requested range. Set inRecord=false to
            -- ignore the body until we hit the END sentinel.
            if (startTs and recordTs < startTs) or
               (endTs   and recordTs > endTs) then
                inRecord = false
            end
        elseif line:match('^%-%-%[%[ HT_RECORD_END %]%]%s*$') then
            if inRecord and #recordLines > 0 then
                local code = table.concat(recordLines, '\n')
                local ok, fn = pcall(load, code)
                if ok and fn then
                    local ok2, rec = pcall(fn)
                    if ok2 and type(rec) == 'table' then
                        table.insert(results, rec)
                    end
                end
            end
            inRecord = false
            recordLines = {}
        elseif inRecord then
            table.insert(recordLines, line)
        end
    end
    f:close()

    table.sort(results, function(a, b) return (a.ts or 0) < (b.ts or 0) end)
    return results
end

local function snapshotFight(mobName)
    if not isDriver() then return end
    if not mobName or mobName == '' then return end

    -- Per-mob model: snapshot ONLY this mob's damage scope.
    local mobDmgScope = activeMobs[mobName]

    -- If this mob has no recorded damage AND nothing else has data
    -- either, we have nothing to snapshot. Discard.
    local hasDmg   = mobDmgScope and mobDmgScope.count and mobDmgScope.count > 0
    local hasHeal  = currentFight.count > 0
    local hasSpell = currentSpellsFight.total > 0
    if not hasDmg and not hasHeal and not hasSpell then
        return
    end

    -- Build a damage entry. If the mob had no scope (we only saw heals
    -- and the mob was killed by, say, a DoT we missed), create an empty
    -- one so indices stay aligned with fights[] / spellsFights[].
    if not mobDmgScope then
        mobDmgScope = emptyDamageScope(mobName)
        mobDmgScope.started = os.time()
    end
    mobDmgScope.label = mobDmgScope.label or mobName
    mobDmgScope.ended = os.time()
    if not mobDmgScope.started then
        mobDmgScope.started = mobDmgScope.ended
    end
    -- Pre-compute and freeze the duration on the scope so the mini
    -- view's queue can display static DPS during the linger window.
    -- The DPS calc inside the mini view will use _frozenDur if present.
    mobDmgScope._frozenDur = math.max(1, mobDmgScope.ended - mobDmgScope.started)
    table.insert(damageFights, mobDmgScope)
    -- Push onto the mini view queue so the bar displays this fight
    -- for config.miniLingerSeconds (cycling through if multiple
    -- fights queue up).
    table.insert(miniQueue, mobDmgScope)
    if config.debug then
        print(string.format('\ag[HealTracker]\ax queued %s for last-fight display (queue size: %d)',
            mobName, #miniQueue))
    end
    -- This mob is dead; remove its scope from the active map so future
    -- damage doesn't go into it.
    activeMobs[mobName] = nil

    -- Heals and spells aren't per-mob (chat lines don't say what mob
    -- the heal/cast was for). To handle multi-mob encounters correctly,
    -- we accumulate heals/spells across the WHOLE encounter and only
    -- snapshot+reset them when ALL mobs are dead (no more activeMobs).
    --
    -- This means heal/spell fight count won't always equal damage
    -- fight count -- a 5-mob AoE pull might produce 5 damage entries
    -- but only 1 heal entry covering the entire pull. The heal entry
    -- gets labeled with the LAST mob killed.
    --
    -- Why not snapshot heals on every kill? Because heals get
    -- ATTRIBUTED to whichever mob died at the moment, even though
    -- they were healing through the WHOLE fight. So the boss kill
    -- (after a long fight with adds dying along the way) would only
    -- show the last few seconds of heals -- everything else snapshotted
    -- with the previous add deaths and got LOST to the user's view.
    local stillActive = false
    for _ in pairs(activeMobs) do stillActive = true; break end

    if stillActive then
        -- Other mobs still being damaged. Don't snapshot heals/spells
        -- yet -- keep accumulating into the same scope so the entire
        -- encounter is captured.
        --
        -- However, we DO need a heal-fight entry at this position so
        -- damageFights[i]/fights[i] indices stay reasonably aligned
        -- for code paths that assume so. Insert an EMPTY placeholder.
        local placeholder = emptyScope(nil)
        placeholder.label   = mobName
        placeholder.started = os.time()
        placeholder.ended   = os.time()
        table.insert(fights, placeholder)

        local sp_placeholder = emptySpellsScope(nil)
        sp_placeholder.label   = mobName
        sp_placeholder.started = os.time()
        sp_placeholder.ended   = os.time()
        table.insert(spellsFights, sp_placeholder)
    else
        -- Last mob in the encounter. Snapshot the accumulated heals
        -- and spells, then reset.
        local heal = currentFight
        heal.label = heal.label or mobName
        heal.ended = os.time()
        if not heal.started then heal.started = heal.ended end
        -- Carry mobLevel from the damage scope so the UI can color
        -- the mob name with EQ-consider colors here too.
        if mobDmgScope and mobDmgScope.mobLevel then
            heal.mobLevel = mobDmgScope.mobLevel
        end
        table.insert(fights, heal)

        local sp = currentSpellsFight
        sp.label = sp.label or mobName
        sp.ended = os.time()
        if not sp.started then sp.started = sp.ended end
        if mobDmgScope and mobDmgScope.mobLevel then
            sp.mobLevel = mobDmgScope.mobLevel
        end
        table.insert(spellsFights, sp)

        currentFight       = emptyScope(nil)
        currentSpellsFight = emptySpellsScope(nil)

        -- Encounter is over. Reset session counters if configured.
        if config.autoResetOnKill then
            resetSession()
        end
        fightActive  = false
        lastDamageAt = 0
    end

    killGraceUntil = nowMs() + (config.killGraceMs or 500)
    lastKillName = mobName
    lastKillAt   = os.time()

    -- After a fight snapshot, the in-memory list grew. Trigger one
    -- frame of tab-restoration so ImGui doesn't lose track of which
    -- tab the user was on if any layout change rebuilt the bar.
    config._restoreTab = true

    saveFights()
    saveDamage()
    saveSpells()

    -- Append to the persistent fight log (one-line summary). This
    -- file is append-only and never wiped by "Clear all fights" --
    -- it's the user's permanent quick-reference record.
    appendHistoryLog(
        fights[#fights],
        damageFights[#damageFights],
        spellsFights[#spellsFights],
        mobName)

    -- Also append the FULL fight data (per-character breakdowns and
    -- all) to the archive. The History tab loads from here, allowing
    -- full drill-down of any past fight even after "Clear all fights"
    -- has wiped the active in-memory state.
    appendArchive(
        fights[#fights],
        damageFights[#damageFights],
        spellsFights[#spellsFights],
        mobName)

    -- The History tab's cached results are now stale. Mark for refresh
    -- so the next time the user opens History, we reload from disk.
    archiveNeedsRefresh = true
    mobSpellsNeedsRefresh = true
end

-- Fight timeout watchdog. Ends the current fight if no damage has been
-- recorded for fightTimeoutSeconds. Snapshots whatever was accumulated
-- (heals + damage + spells) as a real fight entry and resets state.
-- Called from the main loop. Cheap when no fight is active.
local function checkFightTimeout()
    if shuttingDown then return end
    if not isDriver() then return end
    local timeout = config.fightTimeoutSeconds or 0
    if timeout <= 0 then return end  -- timeout disabled

    -- Per-mob timeout: each mob has its own lastHitAt timestamp. If
    -- a mob has been idle for `timeout` seconds (e.g. boss became
    -- inactive while we killed adds), snapshot THAT mob's accumulated
    -- damage as a fight entry and remove it from activeMobs. Other
    -- mobs continue tracking normally.
    --
    -- This matches Gamparse-style "stale fight" behavior: if you stop
    -- damaging a boss to kill adds, after N seconds the boss's
    -- accumulated damage gets recorded as a fight you can combine
    -- with later boss-fight entries via the History tab. Nothing
    -- gets thrown away.
    local nowSec = os.time()
    local toSnap = {}
    for mobName, mobScope in pairs(activeMobs) do
        local lastHit = mobScope.lastHitAt or mobScope.started or 0
        if (nowSec - lastHit) >= timeout then
            -- Only snapshot if there's actual damage. Empty scopes
            -- (mob name appeared but no damage recorded) are discarded.
            if (mobScope.count or 0) > 0 then
                table.insert(toSnap, mobName)
            else
                activeMobs[mobName] = nil
            end
        end
    end
    for _, mobName in ipairs(toSnap) do
        if config.debug then
            print(string.format('\ay[HealTracker]\ax MOB TIMEOUT: %s went idle, snapshotting partial fight',
                mobName))
        end
        snapshotFight(mobName)
    end

    -- If no mobs left active and no global damage, fully reset.
    local anyActive = false
    for _ in pairs(activeMobs) do anyActive = true; break end
    if not anyActive then
        if fightActive and lastDamageAt ~= 0 then
            local idleMs = nowMs() - lastDamageAt
            if idleMs >= (timeout * 1000) then
                -- All clear -- session is idle. Reset stale heal/spell
                -- scopes too (they aren't tied to specific mobs).
                if (currentFight.count or 0) == 0 and (currentSpellsFight.total or 0) == 0 then
                    -- Nothing pending; just flip flag.
                    fightActive  = false
                    lastDamageAt = 0
                end
            end
        end
    end
end

-- =============================================================================
-- Actors transport
-- =============================================================================

local actor

local function actorBroadcast(payload)
    if actor then
        pcall(function() actor:send(payload) end)
    end
end

local function setupActor()
    -- The actor callback runs from MQ's C-side dispatcher. If it errors
    -- during MQ teardown, the error propagates into MQ's status-line
    -- formatter -- which is what crashes in vsprintf_s_l on /lua stop.
    --
    -- We wrap with an OUTER pcall (catches errors from the message()
    -- userdata accessor itself) and an INNER pcall (catches errors from
    -- our handler body). Plus shuttingDown checks at every entry point.
    actor = Actors.register('heal_tracker', function(message)
        pcall(function()
            if shuttingDown then return end

            -- The message() call invokes a sol userdata accessor on the
            -- C++ side. During teardown this can fault. Guard it.
            local m
            local ok = pcall(function()
                m = message and message() or nil
            end)
            if not ok or type(m) ~= 'table' then return end

            if shuttingDown then return end

            if m.kind == 'heal' then
                if m.char == MyName then return end
                if not isDriver() then return end
                recordHeal(m.char or 'unknown', m.healer or 'unknown',
                           tonumber(m.amount) or 0)
            elseif m.kind == 'kill' then
                if not isDriver() then return end
                if m.from == MyName then return end
                onKill('REMOTE_KILL', m.mob or '?')
            elseif m.kind == 'reset_session' then
                resetSession()
                -- Intentionally NO print() here. During MQ teardown a
                -- pending actor message could fire after our shuttingDown
                -- flag is set but before MQ has finished tearing down
                -- the print buffer -- and that path crashes in
                -- vsprintf_s_l. Silent reset is the safe choice.
            end
        end)
    end)
end

-- =============================================================================
-- Local heal events
-- =============================================================================

local lastInKey, lastInAt = '', 0

local function onLocalHeal(line, healer, amount)
    if shuttingDown then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    local now = nowMs()
    local key = string.format('%s|%d', healer or '', amount)
    if key == lastInKey and (now - lastInAt) < 250 then return end
    lastInKey, lastInAt = key, now

    if config.debug then
        print(string.format('\ag[HealTracker]\ax LOCAL %s -> %s : %d',
                            healer or '?', MyName, amount))
    end

    if isDriver() then
        recordHeal(MyName, healer, amount)
    end

    actorBroadcast({
        kind   = 'heal',
        char   = MyName,
        healer = healer,
        amount = amount,
    })
end

-- =============================================================================
-- Kill detection (driver only)
-- =============================================================================

local lastKillKey, lastKillKeyAt = '', 0

local function onKill(line, mobName)
    if shuttingDown then return end
    if not isDriver() then return end
    if not config.autoResetOnKill then return end
    if not mobName or mobName == '' then return end

    local now = nowMs()
    if mobName == lastKillKey and (now - lastKillKeyAt) < 1000 then return end
    lastKillKey, lastKillKeyAt = mobName, now

    -- Only snapshot kills for mobs we actually damaged. Server-wide
    -- death messages ("Fabled Master Yael has been slain by Bingle,
    -- Bingleman, ...") get broadcast even when another group killed
    -- the mob in a different zone. Without this check, those random
    -- kill announcements create empty 0/0 fight entries cluttering
    -- the parse.
    --
    -- A mob "counts" if:
    --   - It has an active damage scope (we hit it during this fight)
    --   - OR it was just damaged within the kill grace window (last
    --     hit landed near-simultaneously with the death message)
    local hasActiveScope = activeMobs[mobName] ~= nil
    local recentlyDamaged = (mobName == lastKillName) and
                            ((now - (lastKillAt * 1000)) < 2000)
    if not hasActiveScope and not recentlyDamaged then
        if config.debug then
            print(string.format('\ay[HealTracker]\ax KILL ignored (not our fight): %s',
                mobName))
        end
        return
    end

    if config.debug then
        print(string.format('\ay[HealTracker]\ax KILL: %s', mobName))
    end

    snapshotFight(mobName)
end

local function bindLocalEvents()
    -- Every callback is wrapped in pcall. If an error fires during MQ
    -- teardown (script being torn down between scheduling and dispatch),
    -- pcall absorbs it instead of letting it propagate up to MQ's
    -- formatter, which is what was crashing in vsprintf_s_l on /lua stop.
    mq.event('heal_in_basic',
        '#1# has healed you for #2# point#*#',
        function(line, healer, amount)
            pcall(onLocalHeal, line, healer, amount)
        end)

    mq.event('heal_in_alt',
        '#*#have been healed by #1# for #2# point#*#',
        function(line, healer, amount)
            pcall(onLocalHeal, line, healer, amount)
        end)

    -- Self-proc heal pattern. EQ text:
    --   "You have been healed for 924 hit points by your Ward of Tunare Effect."
    -- All proc-healing on yourself is collapsed under the single "self-proc"
    -- label so it's easy to see at a glance how much your own procs healed
    -- you, without cluttering the table with one row per effect name.
    mq.event('heal_self_proc',
        'You have been healed for #1# hit point#*#by your #*#',
        function(line, amount)
            pcall(onLocalHeal, line, 'self-proc', amount)
        end)

    -- Self-cast heal. EQ text from the healer's own client:
    --   "You have healed Tank for 4819 points."
    -- We only credit this when the target name matches MyName -- i.e. when
    -- the healer healed himself. Heals on group members produce the same
    -- text on the healer's screen, but we DO NOT want to double-count those
    -- here -- the recipient's box will detect the heal via heal_in_basic
    -- ("Tank has healed you for X") and broadcast it back via Actors.
    -- Filtering on target == MyName makes this event a self-heal-only path.
    mq.event('heal_self_cast',
        'You have healed #1# for #2# point#*#',
        function(line, target, amount)
            if target == MyName then
                pcall(onLocalHeal, line, MyName, amount)
            end
        end)

    -- Kill detection. Two EQ patterns indicate "an ally killed something":
    --
    --   1. "You have slain <mob>!"
    --      Always a kill. Fires only on the box that landed the blow.
    --
    --   2. "<slain> has been slain by <slayer>!"
    --      Ambiguous -- this is also EQ's death message. We filter by
    --      checking knownChars (a set built up from heal events of all
    --      group members). If the SLAIN name is a known ally, it's an
    --      ally death and we IGNORE it. Pet deaths ("X`s pet" / "X's
    --      pet" / "X`s warder") are also ignored.
    --
    -- Reporters that detect a kill broadcast it via Actors so the driver
    -- can snapshot the fight even when the driver isn't the killer.

    mq.event('kill_self',
        'You have slain #*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                -- Manually extract the mob name. mq.event's #1# only
                -- catches a single word; mob names like "a goblin pawn"
                -- need a regex to grab the whole tail.
                local mob = line:match('You have slain%s+(.-)%s*!%s*$')
                              or line:match('You have slain%s+(.+)$')
                              or '?'
                mob = mob:gsub('[!%s]+$', '')
                actorBroadcast({ kind = 'kill', mob = mob, from = MyName })
                onKill(line, mob)
            end)
        end)

    mq.event('kill_passive',
        '#*#has been slain by#*#',
        function(line)
            pcall(function()
                if shuttingDown then return end

                -- Parse "<slain> has been slain by <slayer>!" manually
                -- so we can examine both sides.
                local slain, slayer =
                    line:match('^(.-)%s+has been slain by%s+(.-)%s*!?%s*$')
                if not slain or not slayer then return end
                slain  = slain:gsub('[!%.%s]+$', '')
                slayer = slayer:gsub('[!%.%s]+$', '')

                -- Reject ally deaths. "You" is the first-person form when
                -- the local character itself dies.
                if slain == 'You' or slain == 'you' then return end
                if knownChars[slain] then return end

                -- Stronger PC-detection: also check the live Spawn TLO.
                -- knownChars can lag (group/raid scan runs every 5s), so
                -- a recently-joined PC might not be in the cache yet.
                -- Looking up "pc =Name" via Spawn TLO catches anyone
                -- currently in the zone as a player. If they ARE a PC,
                -- this is an ally death -- skip it.
                if isPlayerInZone and isPlayerInZone(slain) then return end

                -- Reject pet/warder/swarm deaths. EQ writes these as
                -- "<Owner>'s <something> has been slain by <Slayer>!",
                -- where <something> can be "pet", "warder", "ward",
                -- "Animated Corpse", or any other swarm/summoned name.
                -- We don't want these triggering a snapshot since they
                -- aren't real fight-ending events.
                if slain:find("[`']s%s+pet$")    then return end
                if slain:find("[`']s%s+warder$") then return end
                if slain:find("[`']s%s+ward$")   then return end
                -- Generic check: if the slain name starts with
                -- "<KnownChar>'s ", it's an ally's pet/swarm dying.
                local maybeOwner = slain:match("^(.-)[`']s%s+%S")
                if maybeOwner and knownChars[maybeOwner] then return end

                -- It's a kill. Broadcast and run locally on the driver.
                actorBroadcast({ kind = 'kill', mob = slain, from = MyName })
                onKill(line, slain)
            end)
        end)

    -- =====================================================================
    -- DAMAGE EVENTS (driver-only)
    -- =====================================================================
    --
    -- Lessons learned from the previous broad-pattern approach:
    --
    --   1. mq.event tokens like #1# capture a SINGLE WORD only. So "Bond
    --      of the Forsaken Soul" gets captured as "Bond" -- the rest of
    --      the spell name leaks into the next match position. We now use
    --      Lua patterns inside the callback to slice up the line manually.
    --
    --   2. Broad verb-wildcards (#*#) match too much. "X hits Y for N"
    --      and "X heals Y for N" share structure, so we'd accidentally
    --      record heals as damage. We now register one event per common
    --      melee verb -- noisy but reliable.
    --
    --   3. EQ writes spell-name attackers in the third-person form as
    --     "<mob> has taken <N> damage from <Spell> by <Caster>"
    --      -- the SPELL name comes before "by" and the CASTER comes after.
    --      The previous code captured the spell name as attacker.
    --
    --   4. NPC->player damage ("froglok was hit by non-melee for N") is
    --      mob damaging us. NOT part of group DPS. Filter it out.
    --
    -- Patterns we now bind:
    --   M1. "<attacker> <verb>s <target> for <N> points of damage."
    --   M2. "You <verb> <target> for <N> points of damage."
    --   S1. "<target> has taken <N> damage from <spell> by <caster>."
    --   S2. "<target> has taken <N> damage from your <spell>."
    -- =====================================================================

    -- Helper for melee damage parsing. The mq.event matcher fires on the
    -- presence of " <verb> ", but token captures are unreliable for
    -- multi-word names. We re-parse with Lua patterns.
    -- Bind one event per melee verb. Mq.event triggers when the literal
    -- verb appears, so this is fast at the C level. We bind THREE forms
    -- per verb to cover all of EQ's text variants:
    --
    --   1. "<attacker> verbs <target>"   (third-person, e.g. "Bob hits a goblin")
    --   2. "<attacker> verbes <target>"  (third-person -es form, e.g. "crushes")
    --   3. "You verb <target>"            (first-person, no trailing s -- e.g.
    --                                      "You slash a goblin", "You bash a goblin")
    --
    -- Without #3, the driver's own melee never registers because EQ
    -- writes their attacks in first-person and our patterns expected
    -- the third-person form.
    -- Bind just TWO broad melee events instead of 66 verb-specific ones.
    -- Why: with 22 verbs * 3 forms each, mq.event was registering ~70+
    -- events on the script, and the bulk of them appeared to silently
    -- fail to fire (possibly an mq.event registration limit or a race).
    -- A single broad pattern matched against " for N points of damage."
    -- catches every melee variant -- hit, slash, crush, bash, pierce,
    -- backstab, gore, slice, etc. -- in one shot. The parser then
    -- handles the verb-agnostic extraction.
    --
    -- Two events because EQ damage text comes in two structural forms:
    --   1. "<attacker> <verb>(s/es) <target> for N points of damage."
    --      Third-person and "You verb..." both fit this.
    --   2. "<attacker> hit <target> for N points of non-melee damage."
    --      DoT/proc/nuke ticks (handled by the existing damage_nonmelee
    --      event below).

    -- Helper: parse and record a melee line. We accept ANY verb because
    -- the event matched the trailing "for N points of damage" pattern.
    -- The verb is whatever single word appears between attacker and
    -- target -- we don't validate it against a list, just extract it.
    local function parseGenericMelee(line)
        if shuttingDown then return end
        if not isDriver() then return end
        -- Skip heal lines that share structural similarity.
        if line:find('healed', 1, true) then return end
        if line:find('was hit by non-melee', 1, true) then return end
        -- Skip non-melee damage (DoT/proc) -- handled by damage_nonmelee.
        if line:find('non%-melee damage') then return end
        -- Skip miss / try lines.
        if line:find('tries to', 1, true) then return end
        if line:find('but misses', 1, true) then return end

        -- Pattern: <attacker> <verb> <target> for <N> points of damage
        -- The verb is one word after the attacker. The target may be
        -- multiple words. We use a greedy-then-lazy combination.
        --
        -- Try first-person form first (line starts with "You ").
        local attacker, target, amountStr
        if line:sub(1, 4) == 'You ' then
            -- "You <verb> <target> for <N> points of damage."
            attacker = 'You'
            local _, target2, amountStr2 =
                line:match('^(You)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point')
            target, amountStr = target2, amountStr2
        else
            -- Try possessive-pet form FIRST: "<Owner>'s pet <verb> ..."
            -- The generic regex below would mis-parse this as
            -- attacker="<Owner>'s" + verb="pet" + target="<verb> <mob>",
            -- which fails the filter check entirely. Catching the
            -- possessive form here keeps the multi-word attacker intact.
            -- Both apostrophe (') and backtick (`) are supported because
            -- EQ uses backticks by default but some clients emit
            -- straight apostrophes.
            attacker, target, amountStr =
                line:match("^(%S+[`']s%s+pet)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
            if not attacker then
                attacker, target, amountStr =
                    line:match("^(%S+[`']s%s+warder)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
            end
            if not attacker then
                attacker, target, amountStr =
                    line:match("^(%S+[`']s%s+ward)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
            end
            if not attacker then
                -- Generic third-person: "<attacker> <verb> <target> for ..."
                --
                -- Bare lazy `(.-)` matches the SHORTEST prefix, which
                -- mis-parses multi-word names like "Froglok bok knight"
                -- as attacker="Froglok" verb="bok" target="knight ...".
                -- To handle multi-word charm pets / named NPCs, we try
                -- progressively longer attacker prefixes (1, 2, 3, 4
                -- words) and pick the first one that resolves to a
                -- known character or mapped pet via attributeDamage.
                -- If none match, fall back to first-word (current
                -- behavior, for unmapped attackers we want to track
                -- in unmappedDamage so the user can map them later).
                local words = {}
                for w in line:gmatch('%S+') do
                    table.insert(words, w)
                    if #words >= 6 then break end  -- cap search
                end

                -- Try prefixes from longest (4 words) to shortest (1 word).
                -- Skip prefixes that don't have at least 2 more words after
                -- them (need at least: verb + 1-word target + "for" + N).
                for prefixLen = math.min(4, #words - 3), 1, -1 do
                    local candAttacker = table.concat(words, ' ', 1, prefixLen)
                    -- Build a regex that anchors on this exact prefix.
                    -- Lua patterns don't have alternation, so do this
                    -- by constructing a literal-prefix match:
                    local escaped = candAttacker:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
                    local pattern = '^' .. escaped .. '%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point'
                    local t, a = line:match(pattern)
                    if t and a then
                        -- Did this resolve to a known PC/pet?
                        local resolved = attributeDamage(candAttacker)
                        if knownChars[resolved] or knownChars[candAttacker]
                           or (config.petOwners and config.petOwners[candAttacker]) then
                            attacker = candAttacker
                            target = t
                            amountStr = a
                            break
                        end
                    end
                end

                -- If nothing matched, fall back to first-word parsing.
                -- This means unmapped multi-word names will be tracked
                -- under their first word -- not ideal, but at least
                -- they show up in unmappedDamage for the user to see.
                if not attacker then
                    attacker, _, target, amountStr =
                        line:match('^(.-)%s+(%S+)%s+(.-)%s+for%s+([%d,]+)%s+point')
                end
            end
        end

        if not attacker or not target or not amountStr then return end
        amountStr = amountStr:gsub(',', '')
        local amount = tonumber(amountStr)
        if not amount or amount <= 0 then return end

        -- Normalize "You" / "you" to MyName BEFORE the filter check.
        -- Without this, the driver's own first-person melee lines
        -- ("You bash a goblin for 100 points...") get rejected because
        -- "You" isn't in knownChars.
        if attacker == 'You' or attacker == 'you' then
            attacker = MyName
        end

        -- Filter mob-on-mob and mob-on-player damage.
        --
        -- An attacker's damage is recorded ONLY if they're in our
        -- group/raid (knownChars) OR they're a mapped pet (knownByPet).
        -- We deliberately do NOT accept "any PC in the zone" as an
        -- attacker -- that would pollute the parse with strangers
        -- attacking their own pets, AFK-zone background activity,
        -- merc battles, etc. If you raid with people outside your
        -- group, they'll be picked up by the raid TLO scan and added
        -- to knownChars automatically.
        local attributed = attributeDamage(attacker)
        local knownByAttr = knownChars[attributed] and true or false
        local knownByPet  = isKnownPet(attacker)

        if not knownByAttr and not knownByPet then
            -- Track this attacker as a potential pet to map. The
            -- Settings tab uses this to surface unattributed damage
            -- sources for the user to map. Skip junk -- only track
            -- attackers with a sensible name (single capitalized word
            -- or possessive form), and skip generic mob terms.
            local function trackCandidate(name)
                if not name or name == '' then return end
                if name:find('^a%s') or name:find('^an%s') or name:find('^the%s') then
                    return
                end
                local rec = unmappedDamage[name] or {
                    count = 0, total = 0, lastSeen = 0, lastTarget = ''
                }
                rec.count = rec.count + 1
                rec.total = rec.total + (amount or 0)
                rec.lastSeen = os.time()
                rec.lastTarget = target or rec.lastTarget
                unmappedDamage[name] = rec
            end

            -- Track the parsed first-word attacker.
            trackCandidate(attacker)

            -- ALSO try to track multi-word candidates from the line.
            -- For lines like "Froglok bok knight pierces froglok bok shaman
            -- for 730 points...", the parser fell back to attacker="Froglok"
            -- but the user might want to map the full charm-pet name
            -- "Froglok bok knight". We extract the longest sequence of
            -- words from the START of the line that DON'T look like
            -- generic mob words (i.e. that maintain the assumption that
            -- the first few words form a name). Heuristic: take the
            -- first 1-4 words, stopping when we hit a clear verb.
            -- This isn't perfect, but it gives the user multi-word
            -- options to pick from in the dropdown.
            local words = {}
            for w in line:gmatch('%S+') do
                table.insert(words, w)
                if #words >= 5 then break end
            end
            -- Common melee verbs that mark the END of an attacker name.
            local verbWords = {
                hits=true, slashes=true, slices=true, crushes=true, pierces=true,
                punches=true, kicks=true, bashes=true, claws=true, gores=true,
                slams=true, bites=true, mauls=true, rips=true, smashes=true,
                stings=true, strikes=true, lashes=true, hit=true, slash=true,
                slice=true, crush=true, pierce=true, punch=true, kick=true,
                bash=true, claw=true, gore=true, slam=true, bite=true,
                maul=true, rip=true, smash=true, sting=true, strike=true,
                lash=true, backstabs=true, backstab=true, frenzies=true,
                tries=true,
            }
            for prefixLen = 2, math.min(4, #words - 2) do
                -- The word RIGHT AFTER the prefix must be a verb for
                -- this prefix to be a plausible attacker name.
                local nextWord = words[prefixLen + 1]
                if nextWord and verbWords[nextWord:lower()] then
                    local candidate = table.concat(words, ' ', 1, prefixLen)
                    trackCandidate(candidate)
                end
            end

            if config.debug then
                print(string.format(
                    '\ay[HealTracker]\ax DROP DMG: %s -> %s (%d) -- attributed=%s knownChar=%s knownPet=%s',
                    attacker, target, amount,
                    attributed, tostring(knownByAttr), tostring(knownByPet)))
            end
            return
        end

        if config.debug then
            print(string.format(
                '\ag[HealTracker]\ax DMG: %s (-> %s) %s for %d',
                attacker, attributed, target, amount))
        end

        recordDamage(attacker, target, amount)
    end

    -- Single broad event covering ALL melee damage forms. The match
    -- text only needs to ensure "for N points of damage" appears
    -- somewhere in the line; everything else is parsed inside.
    mq.event('damage_melee_any',
        '#*# for #*# point#*#damage#*#',
        function(line)
            pcall(parseGenericMelee, line)
        end)

    -- Non-melee damage (DoT ticks, procs, certain nukes). EQ format:
    --   "Necro hit froglok bok knight for 4531 points of non-melee damage."
    -- Note the past-tense "hit" (without trailing s) and "non-melee" before
    -- "damage". This is structurally distinct from melee "hits" so we
    -- need a separate event. The MOB attacking us via "non-melee" looks
    -- different too: "froglok was hit by non-melee for 903 points" --
    -- and we filter that out as it's mob->player damage.
    mq.event('damage_nonmelee',
        '#*# hit #*# for #*# point#*#non-melee damage#*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                if not isDriver() then return end

                -- Mob -> player non-melee uses "<player> was hit by non-melee".
                -- Skip those.
                if line:find('was hit by non-melee', 1, true) then return end

                -- Parse: <attacker> hit <target> for <N> points of non-melee
                local attacker, target, amountStr =
                    line:match('^(.-)%s+hit%s+(.-)%s+for%s+([%d,]+)%s+point.-non%-melee')
                if not attacker or not target or not amountStr then return end

                amountStr = amountStr:gsub(',', '')
                local amount = tonumber(amountStr)
                if not amount or amount <= 0 then return end

                -- Filter mob->mob and mob->player damage. Only count when
                -- the attacker is one of our characters or a known pet.
                --
                -- We deliberately do NOT accept "any PC in the zone" as
                -- an attacker -- that would pollute the parse with
                -- strangers attacking their own pets, AFK-zone background
                -- activity, etc. If you raid with people outside your
                -- group, they'll be picked up by the raid TLO scan and
                -- added to knownChars automatically.
                local attributed = attributeDamage(attacker)
                if not knownChars[attributed]
                   and not isKnownPet(attacker) then
                    -- Print only attacker + amount, NEVER the original
                    -- line, to avoid retriggering this event via chat.
                    if config.debug then
                        print(string.format(
                            '\ay[HealTracker]\ax NM-DROP: %s amt=%d attr=%s',
                            attacker, amount, attributed))
                    end
                    return
                end

                if config.debug then
                    print(string.format(
                        '\ag[HealTracker]\ax NM-OK: %s (-> %s) amt=%d',
                        attacker, attributed, amount))
                end

                recordDamage(attacker, target, amount)
            end)
        end)

    -- Paladin Slay Undead (and similar holy-strike abilities). Format:
    --   "Tank's holy blade cleanses his target!(3858)"
    -- No verb, no "for N points", no target name -- the damage amount is
    -- in parentheses at the end. Target is implied from context (whatever
    -- the paladin is attacking) so we use a placeholder. EQ uses backtick
    -- and apostrophe variants for the possessive.
    mq.event('damage_slay_undead',
        '#*#holy blade cleanses #*# target#*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                if not isDriver() then return end

                -- Parse: "<attacker>'s holy blade cleanses <his/her/its>
                --         target!(<amount>)"
                -- Capture attacker (before the possessive marker) and
                -- amount (inside the parentheses at the end).
                local attacker = line:match("^(.-)[`']s%s+holy blade")
                local amountStr = line:match('%((%d[%d,]*)%)')
                if not attacker or not amountStr then return end
                amountStr = amountStr:gsub(',', '')
                local amount = tonumber(amountStr)
                if not amount or amount <= 0 then return end

                -- Filter: only count if attacker is one of ours.
                local attributed = attributeDamage(attacker)
                if not knownChars[attributed]
                   and not isKnownPet(attacker)
                   and not isPlayerInZone(attributed)
                   and not isPlayerInZone(attacker) then
                    return
                end

                if config.debug then
                    print(string.format(
                        '\ag[HealTracker]\ax DMG (slay): %s for %d',
                        attacker, amount))
                end

                -- Use a placeholder target since the line doesn't
                -- include the mob name. Other damage from the same
                -- fight will populate the real target name into the
                -- targets table; this just becomes one extra row.
                recordDamage(attacker, '(undead)', amount)
            end)
        end)

    -- Spell damage with explicit caster ("by <caster>" suffix).
    --   "a goblin has taken 1234 damage from Force Strike by Caster."
    -- We parse the target before "has taken", the amount after, and the
    -- caster after the last "by ".
    mq.event('damage_spell_by',
        '#*# has taken #*# damage from #*# by #*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                if not isDriver() then return end

                -- EQ uses TWO different orderings for this template:
                --   Format A: "<mob> has taken N damage from <Spell> by <Caster>"
                --             e.g. "... from Horror by Necro"
                --   Format B: "<mob> has taken N damage from <Caster> by <Spell>"
                --             e.g. "... from Cleric by Turn Undead"
                -- The two are indistinguishable structurally, so we
                -- disambiguate semantically: whichever capture is in
                -- knownChars is the caster. If neither matches, fall
                -- back to assuming Format A (last token is caster).
                local target, amountStr, mid, last =
                    line:match('^(.-) has taken ([%d,]+) damage from (.-) by ([^%.]+)%.?$')
                if not target then return end

                amountStr = amountStr:gsub(',', '')
                local amount = tonumber(amountStr)
                if not amount or amount <= 0 then return end

                mid  = mid:gsub('[%s%.]+$', '')
                last = last:gsub('[%s%.]+$', '')

                local caster
                if knownChars[mid] or isKnownPet(mid) then
                    -- Format B: "from <Caster> by <Spell>"
                    caster = mid
                elseif knownChars[last] or isKnownPet(last) then
                    -- Format A: "from <Spell> by <Caster>"
                    caster = last
                else
                    -- Caster isn't in our group/raid. Drop silently --
                    -- we deliberately don't accept "any PC in zone" as
                    -- a caster (would log strangers' DoT damage to mobs
                    -- we never touched).
                    return
                end

                recordDamage(caster, target, amount)
            end)
        end)

    -- Spell damage from "your" cast (no "by" suffix).
    --   "a goblin has taken 1234 damage from your Force Strike."
    mq.event('damage_spell_your',
        '#*# has taken #*# damage from your #*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                if not isDriver() then return end

                -- Skip if the line has " by " -- that's the third-person
                -- form already handled by damage_spell_by.
                if line:find(' by ', 1, true) then return end

                local target, amountStr =
                    line:match('^(.-) has taken ([%d,]+) damage from your ')
                if not target then return end

                amountStr = amountStr:gsub(',', '')
                local amount = tonumber(amountStr)
                if not amount or amount <= 0 then return end

                recordDamage(MyName, target, amount)
            end)
        end)

    -- Spell damage with NO caster attribution. Format:
    --   "<mob> has taken <N> damage from <Spell>."
    -- This is how EQ writes most DoT ticks for OTHER players' spells --
    -- there's no "by <caster>" suffix. We resolve the caster by looking
    -- up the spell name in recentSpellCasts (populated from cast events).
    -- If the spell isn't in the map (we missed the cast), the line is
    -- dropped silently rather than mis-attributing.
    mq.event('damage_spell_anon',
        '#*# has taken #*# damage from #*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                if not isDriver() then return end

                -- Skip the two more-specific forms.
                if line:find(' by ', 1, true) then return end
                if line:find('damage from your ', 1, true) then return end

                -- "<target> has taken <N> damage from <Spell>."
                local target, amountStr, spellName =
                    line:match('^(.-) has taken ([%d,]+) damage from ([^%.]+)%.?$')
                if not target or not amountStr or not spellName then return end

                amountStr = amountStr:gsub(',', '')
                local amount = tonumber(amountStr)
                if not amount or amount <= 0 then return end

                spellName = spellName:gsub('%s+$', '')

                -- Look up who last cast this spell. Try (in order):
                --   1. recentSpellCasts (observed during this session)
                --   2. config.spellOwners (manually-configured map)
                -- Each tier tries exact match first, then case-insensitive.
                local caster = recentSpellCasts[spellName]
                if not caster then
                    local lowerSpell = spellName:lower()
                    for sName, cName in pairs(recentSpellCasts) do
                        if sName:lower() == lowerSpell then
                            caster = cName
                            break
                        end
                    end
                end
                if not caster then
                    -- Fall back to the manual config map.
                    local map = config.spellOwners or {}
                    caster = map[spellName]
                    if not caster then
                        local lowerSpell = spellName:lower()
                        for sName, cName in pairs(map) do
                            if sName:lower() == lowerSpell then
                                caster = cName
                                break
                            end
                        end
                    end
                end
                if not caster then
                    -- We didn't see the cast and have no manual map
                    -- entry. Drop the line. With debug on this is
                    -- visible so the user can add a spell mapping.
                    if config.debug then
                        print(string.format(
                            '\ay[HealTracker]\ax SPELL-ANON UNRESOLVED: %s for %d (try /healtracker spell add)',
                            spellName, amount))
                    end
                    return
                end

                if config.debug then
                    print(string.format(
                        '\ag[HealTracker]\ax SPELL-ANON: %s -> %s amt=%d',
                        spellName, caster, amount))
                end

                recordDamage(caster, target, amount)
            end)
        end)

    -- =====================================================================
    -- SPELL CAST EVENTS (driver-only)
    -- =====================================================================
    -- Two patterns:
    --   "You begin casting <Spell>."
    --   "<Caster> begins to cast a spell. <Spell>"
    -- Spell name is wrapped in <> in the third-person form. We capture
    -- the inside of the angle brackets.
    -- =====================================================================

    mq.event('spell_cast_self',
        'You begin casting #*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                if not isDriver() then return end

                -- Strip "You begin casting " and trailing period.
                local spellName = line:match('^You begin casting%s+(.-)%.?%s*$')
                if not spellName or spellName == '' then return end
                recordSpellCast(MyName, spellName)
            end)
        end)

    mq.event('spell_cast_other',
        '#*# begins to cast a spell#*#',
        function(line)
            pcall(function()
                if shuttingDown then return end
                if not isDriver() then return end

                -- Format: "<Caster> begins to cast a spell. <SpellName>"
                -- The spell name is inside angle brackets.
                local caster, spellName =
                    line:match('^(.-) begins to cast a spell%.%s*<(.-)>')
                if not caster or not spellName then return end

                -- Branch: friendly cast vs mob cast.
                if knownChars[caster] then
                    -- Friendly cast -- log to spell-fights as before.
                    recordSpellCast(caster, spellName)
                    return
                end

                -- Mob cast: only log if this caster has an active mob
                -- scope (i.e. we're currently fighting them). Mobs out
                -- of zone or unrelated to current combat are ignored.
                local mobScope = activeMobs[caster]
                if not mobScope then return end
                mobScope.mobSpells = mobScope.mobSpells or {}
                -- New shape: per-spell record holding count + list of
                -- timestamps for each cast. Backward-compatible: older
                -- saved data may have just an integer here; UI handles
                -- both.
                local rec = mobScope.mobSpells[spellName]
                if type(rec) == 'number' then
                    -- Migrate old integer-count to the new shape.
                    rec = { count = rec, casts = {} }
                end
                if type(rec) ~= 'table' then
                    rec = { count = 0, casts = {} }
                end
                rec.count = (rec.count or 0) + 1
                rec.casts = rec.casts or {}
                table.insert(rec.casts, os.time())
                mobScope.mobSpells[spellName] = rec
            end)
        end)
end

-- =============================================================================
-- Helpers
-- =============================================================================

local function fmtNum(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out, i = s:reverse(), 0
    out = out:gsub('(%d%d%d)', function(g)
        i = i + 1
        return g .. (i*3 < #s and ',' or '')
    end)
    return out:reverse():gsub('^,', '')
end

local function countKeys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function buildRowsFor(scope)
    local rows = {}
    for char, s in pairs(scope.stats) do
        table.insert(rows, {
            char    = char,
            total   = s.total,
            count   = s.count,
            max     = s.max,
            healers = s.healers,
            isMe    = (char == MyName),
        })
    end
    table.sort(rows, function(a, b)
        if a.isMe ~= b.isMe then return a.isMe end
        return a.total > b.total
    end)
    return rows
end

-- Damage variant of buildRowsFor. Defined alongside its heal twin so
-- both are in scope before any draw function is parsed -- without this
-- ordering, drawMini's reference to buildDamageRows resolves to a nil
-- global at parse time and crashes the ImGui callback at runtime
-- ("MQOverlay paused due to ImGui error").
local function buildDamageRows(scope)
    local rows = {}
    for attacker, s in pairs(scope.stats) do
        local petCount = 0
        if s.pets then
            for _ in pairs(s.pets) do petCount = petCount + 1 end
        end
        table.insert(rows, {
            attacker = attacker,
            total    = s.total,
            count    = s.count,
            max      = s.max,
            targets  = s.targets,
            pets     = s.pets,
            hasPets  = petCount > 0,
            isMe     = (attacker == MyName),
        })
    end
    -- Sort purely by total damage descending. The driver's row no
    -- longer gets pinned to the top -- this matches Gamparse-style
    -- ordering where top damage dealers come first regardless of
    -- whether they're the local player.
    table.sort(rows, function(a, b)
        return a.total > b.total
    end)
    return rows
end

local function fightTopHealer(fight)
    local best, bestTotal = nil, 0
    for _, charStats in pairs(fight.stats) do
        for healer, h in pairs(charStats.healers) do
            if h.total > bestTotal then
                best, bestTotal = healer, h.total
            end
        end
    end
    return best, bestTotal
end

-- =============================================================================
-- Combine fights -- merge any number of fight entries into a single scope
-- =============================================================================
-- Used by the multi-select Fights UI. Returns a synthetic scope with the
-- same shape as a fight (so drawCharTable works on it directly) holding
-- the sum of every selected fight's stats. Pure function; doesn't mutate
-- anything in fights[].

local function combineFights(indices)
    local combined = emptyScope('Combined')
    combined.fightCount = 0
    combined.startedMin = nil
    combined.endedMax   = nil
    for _, idx in ipairs(indices) do
        local f = fights[idx]
        if f then
            combined.fightCount = combined.fightCount + 1
            for charName, s in pairs(f.stats) do
                combined.stats[charName] = combined.stats[charName] or
                    { total = 0, count = 0, max = 0, healers = {} }
                local cs = combined.stats[charName]
                cs.total = cs.total + (s.total or 0)
                cs.count = cs.count + (s.count or 0)
                if (s.max or 0) > cs.max then cs.max = s.max end

                for healer, h in pairs(s.healers) do
                    cs.healers[healer] = cs.healers[healer] or { total = 0, count = 0, max = 0 }
                    cs.healers[healer].total = cs.healers[healer].total + (h.total or 0)
                    cs.healers[healer].count = cs.healers[healer].count + (h.count or 0)
                    if (h.max or 0) > cs.healers[healer].max then
                        cs.healers[healer].max = h.max
                    end
                end
            end
            combined.total = combined.total + (f.total or 0)
            combined.count = combined.count + (f.count or 0)
            if (f.max or 0) > combined.max then combined.max = f.max end
            if f.started and (not combined.startedMin or f.started < combined.startedMin) then
                combined.startedMin = f.started
            end
            local fEnd = f.ended or f.started
            if fEnd and (not combined.endedMax or fEnd > combined.endedMax) then
                combined.endedMax = fEnd
            end
        end
    end
    return combined
end

-- Combine multiple damage fight entries into one synthetic scope.
-- Total duration is summed across the selected fights so combined
-- DPS = totalDmg / totalDur (NOT spread across calendar time).
local function combineDamageFights(indices)
    local combined = emptyDamageScope('Combined')
    combined.fightCount = 0
    combined.totalDuration = 0
    for _, idx in ipairs(indices) do
        local f = damageFights[idx]
        if f then
            combined.fightCount = combined.fightCount + 1
            local fDur = math.max(0, (f.ended or f.started or 0) - (f.started or 0))
            combined.totalDuration = combined.totalDuration + fDur

            for atk, s in pairs(f.stats) do
                combined.stats[atk] = combined.stats[atk] or
                    { total = 0, count = 0, max = 0, targets = {}, pets = {} }
                local cs = combined.stats[atk]
                cs.total = cs.total + (s.total or 0)
                cs.count = cs.count + (s.count or 0)
                if (s.max or 0) > cs.max then cs.max = s.max end

                for tgt, t in pairs(s.targets or {}) do
                    cs.targets[tgt] = cs.targets[tgt] or { total = 0, count = 0, max = 0 }
                    cs.targets[tgt].total = cs.targets[tgt].total + (t.total or 0)
                    cs.targets[tgt].count = cs.targets[tgt].count + (t.count or 0)
                    if (t.max or 0) > cs.targets[tgt].max then cs.targets[tgt].max = t.max end
                end

                cs.pets = cs.pets or {}
                for petName, p in pairs(s.pets or {}) do
                    cs.pets[petName] = cs.pets[petName] or { total = 0, count = 0, max = 0 }
                    cs.pets[petName].total = cs.pets[petName].total + (p.total or 0)
                    cs.pets[petName].count = cs.pets[petName].count + (p.count or 0)
                    if (p.max or 0) > cs.pets[petName].max then cs.pets[petName].max = p.max end
                end
            end

            combined.total = combined.total + (f.total or 0)
            combined.count = combined.count + (f.count or 0)
            if (f.max or 0) > combined.max then combined.max = f.max end
        end
    end
    return combined
end

-- Combine multiple spell-cast fight entries into one synthetic scope.
local function combineSpellsFights(indices)
    local combined = emptySpellsScope('Combined')
    combined.fightCount = 0
    for _, idx in ipairs(indices) do
        local s = spellsFights[idx]
        if s then
            combined.fightCount = combined.fightCount + 1
            for caster, cstats in pairs(s.stats or {}) do
                combined.stats[caster] = combined.stats[caster] or { total = 0, casts = {} }
                local cs = combined.stats[caster]
                cs.total = cs.total + (cstats.total or 0)
                for spell, n in pairs(cstats.casts or {}) do
                    cs.casts[spell] = (cs.casts[spell] or 0) + n
                end
            end
            combined.total = combined.total + (s.total or 0)
        end
    end
    return combined
end

-- =============================================================================
-- Archive combine helpers
-- =============================================================================
--
-- The above combine* functions operate on indices into the LIVE arrays
-- (fights / damageFights / spellsFights). The History tab needs
-- equivalents that operate on archive records, where each entry is
-- { ts, mob, fight, damage, spells }. Same combination logic, just
-- walks the nested .fight / .damage / .spells fields.
--
-- Takes a list of archive records (already filtered by the caller)
-- and returns a synthetic combined scope of each type. Returns
-- (combinedHeals, combinedDamage, combinedSpells, fightCount).

local function combineArchive(records)
    local cHeals  = emptyScope('Combined')
    local cDamage = emptyDamageScope('Combined')
    local cSpells = emptySpellsScope('Combined')
    cHeals.fightCount  = 0
    cDamage.fightCount = 0
    cDamage.totalDuration = 0
    cSpells.fightCount = 0

    for _, rec in ipairs(records) do
        -- Heals.
        local f = rec.fight
        if f then
            cHeals.fightCount = cHeals.fightCount + 1
            for charName, s in pairs(f.stats or {}) do
                cHeals.stats[charName] = cHeals.stats[charName] or
                    { total = 0, count = 0, max = 0, healers = {} }
                local cs = cHeals.stats[charName]
                cs.total = cs.total + (s.total or 0)
                cs.count = cs.count + (s.count or 0)
                if (s.max or 0) > cs.max then cs.max = s.max end
                for hname, h in pairs(s.healers or {}) do
                    cs.healers[hname] = cs.healers[hname] or { total = 0, count = 0, max = 0 }
                    cs.healers[hname].total = cs.healers[hname].total + (h.total or 0)
                    cs.healers[hname].count = cs.healers[hname].count + (h.count or 0)
                    if (h.max or 0) > cs.healers[hname].max then cs.healers[hname].max = h.max end
                end
            end
            cHeals.total = cHeals.total + (f.total or 0)
            cHeals.count = cHeals.count + (f.count or 0)
            if (f.max or 0) > cHeals.max then cHeals.max = f.max end
        end

        -- Damage.
        local d = rec.damage
        if d then
            cDamage.fightCount = cDamage.fightCount + 1
            local fDur = math.max(0, (d.ended or d.started or 0) - (d.started or 0))
            cDamage.totalDuration = cDamage.totalDuration + fDur

            for atk, s in pairs(d.stats or {}) do
                cDamage.stats[atk] = cDamage.stats[atk] or
                    { total = 0, count = 0, max = 0, targets = {}, pets = {} }
                local cs = cDamage.stats[atk]
                cs.total = cs.total + (s.total or 0)
                cs.count = cs.count + (s.count or 0)
                if (s.max or 0) > cs.max then cs.max = s.max end

                for tgt, t in pairs(s.targets or {}) do
                    cs.targets[tgt] = cs.targets[tgt] or { total = 0, count = 0, max = 0 }
                    cs.targets[tgt].total = cs.targets[tgt].total + (t.total or 0)
                    cs.targets[tgt].count = cs.targets[tgt].count + (t.count or 0)
                    if (t.max or 0) > cs.targets[tgt].max then cs.targets[tgt].max = t.max end
                end

                cs.pets = cs.pets or {}
                for petName, p in pairs(s.pets or {}) do
                    cs.pets[petName] = cs.pets[petName] or { total = 0, count = 0, max = 0 }
                    cs.pets[petName].total = cs.pets[petName].total + (p.total or 0)
                    cs.pets[petName].count = cs.pets[petName].count + (p.count or 0)
                    if (p.max or 0) > cs.pets[petName].max then cs.pets[petName].max = p.max end
                end
            end

            cDamage.total = cDamage.total + (d.total or 0)
            cDamage.count = cDamage.count + (d.count or 0)
            if (d.max or 0) > cDamage.max then cDamage.max = d.max end
        end

        -- Spells.
        local sp = rec.spells
        if sp then
            cSpells.fightCount = cSpells.fightCount + 1
            for caster, cstats in pairs(sp.stats or {}) do
                cSpells.stats[caster] = cSpells.stats[caster] or { total = 0, casts = {} }
                local cs = cSpells.stats[caster]
                cs.total = cs.total + (cstats.total or 0)
                for spell, n in pairs(cstats.casts or {}) do
                    cs.casts[spell] = (cs.casts[spell] or 0) + n
                end
            end
            cSpells.total = cSpells.total + (sp.total or 0)
        end
    end

    return cHeals, cDamage, cSpells
end

-- =============================================================================
-- Clipboard summary text
-- =============================================================================
-- Plain ASCII, short lines, designed to paste into in-game chat. Keep
-- newlines minimal -- when EQ pastes a multi-line block, each line gets
-- sent as its own chat message.

local function summaryText(scope, headerLabel)
    local lines = {}
    table.insert(lines, string.format('Heals (%s)', headerLabel or 'session'))
    table.insert(lines, string.format('Total: %s across %d heals',
        fmtNum(scope.total), scope.count))
    if scope.max and scope.max > 0 then
        local topName, topTotal = fightTopHealer(scope)
        if topName then
            table.insert(lines, string.format('Top healer: %s (%s)',
                topName, fmtNum(topTotal)))
        end
        table.insert(lines, string.format('Largest single: %s', fmtNum(scope.max)))
    end
    table.insert(lines, '----')
    for _, r in ipairs(buildRowsFor(scope)) do
        table.insert(lines, string.format('%s %s / %d heals',
            r.char, fmtNum(r.total), r.count))
    end
    return table.concat(lines, '\n')
end

-- =============================================================================
-- Gamparse-style DPS report
-- =============================================================================
--
-- Formats a damage scope as a single-line Gamparse-compatible report
-- suitable for /gu paste. Mirrors Gamparse's exact output:
--
--   <Mob> in <dur>s, <total>k @<group_sdps>sdps --- <Char> <total>k@<sdps>sdps (<active_dps>dps in <active>s) [<pct>%]
--
-- Where:
--   - "k" suffix means the value is divided by 1000 (rounded)
--   - "sdps" = sustained DPS (total / fight duration -- same denominator
--      for everyone)
--   - "active_dps" = the player's individual DPS during their active
--      window (total / activeTime, where activeTime = lastHit - firstHit)
--   - "[pct%]" = percentage of group total this player contributed
--   - Players sorted descending by total damage
--   - Pets fold into owner row (Gamparse doesn't separate them in /gu paste)
--
-- Takes a damage scope (with .total, .stats, .started, .ended) and
-- returns the formatted single-line string.

local function gamparseReport(d, mobLabel)
    if not d or (d.total or 0) == 0 then
        return string.format('%s in 0s, 0k @0sdps', mobLabel or 'fight')
    end

    -- Fight duration. For combined views, prefer .totalDuration if set.
    local dur = d.totalDuration
    if not dur or dur == 0 then
        dur = math.max(1, (d.ended or d.started or 0) - (d.started or 0))
    end
    if dur < 1 then dur = 1 end

    local groupTotal = d.total or 0
    local groupSdps  = math.floor(groupTotal / dur)

    -- Build sorted character rows. Sort descending by total damage.
    local rows = {}
    for atk, s in pairs(d.stats or {}) do
        local activeStart = s.firstHit or 0
        local activeEnd   = s.lastHit  or 0
        local activeDur   = math.max(1, activeEnd - activeStart)
        if activeDur < 1 then activeDur = 1 end

        table.insert(rows, {
            name      = atk,
            total     = s.total or 0,
            sdps      = math.floor((s.total or 0) / dur),
            activeDps = math.floor((s.total or 0) / activeDur),
            activeDur = activeDur,
        })
    end
    table.sort(rows, function(a, b) return a.total > b.total end)

    -- Decide how to label each row. If the player has pet sub-entries,
    -- we show "<Owner> + pets". Otherwise just the player name.
    local function labelFor(name, scope)
        local statRow = scope.stats[name]
        if statRow and statRow.pets and next(statRow.pets) then
            return name .. ' + pets'
        end
        return name
    end

    -- Format helpers.
    local function k(n)
        -- "k" suffix: divide by 1000, round to integer.
        return string.format('%dk', math.floor(n / 1000))
    end

    -- Build the output line.
    local parts = {}
    table.insert(parts, string.format(
        '%s in %ds, %s @%dsdps',
        mobLabel or 'fight', dur, k(groupTotal), groupSdps))

    for _, r in ipairs(rows) do
        local pct = (groupTotal > 0) and (r.total * 100 / groupTotal) or 0
        local pctStr
        if pct >= 10 then
            pctStr = string.format('%.2f', pct)
        else
            pctStr = string.format('%.2f', pct)
        end
        table.insert(parts, string.format(
            '%s %s@%dsdps (%ddps in %ds) [%s%%]',
            labelFor(r.name, d),
            k(r.total),
            r.sdps,
            r.activeDps,
            r.activeDur,
            pctStr))
    end

    return table.concat(parts, ' --- ')
end

local function copyToClipboard(text)
    local ok = pcall(function() ImGui.SetClipboardText(text) end)
    if not ok and config.debug then
        print('\ar[HealTracker]\ax clipboard copy failed')
    end
    return ok
end

local function printStatus()
    print(string.format('\ag[HealTracker]\ax \aw%s\ax (\at%s\ax)', MyName, MyServer))
    print(string.format('  Mode      : %s',
        isDriver() and '\agDRIVER\ax' or '\ayreporter\ax'))
    if #(config.drivers or {}) > 0 then
        print(string.format('  Drivers   : %s', table.concat(config.drivers, ', ')))
    end
    print(string.format('  Auto-reset: %s on each kill',
        config.autoResetOnKill and '\agON\ax' or '\arOFF\ax'))
    print(string.format('  Timeout   : %s',
        ((config.fightTimeoutSeconds or 0) > 0)
            and string.format('%ds of no damage ends a fight', config.fightTimeoutSeconds)
            or '\arOFF (only slain messages end fights)\ax'))
    print(string.format('  Active    : %s', fightActive and '\agIN COMBAT\ax' or 'idle'))
    print(string.format('  Session   : %s HP / %d heals',
        fmtNum(session.total), session.count))
    print(string.format('  Fights    : %d recorded', #fights))
end

local function printReport()
    print('\ag[HealTracker]\ax \awSession totals -- by character\ax')
    if session.count == 0 then
        print('  (no heals tracked yet)')
        return
    end
    for _, r in ipairs(buildRowsFor(session)) do
        print(string.format('  \at%-20s\ax  %s HP  (%d heals, avg %s, max %s)',
                            r.char, fmtNum(r.total), r.count,
                            fmtNum(r.total / math.max(1, r.count)),
                            fmtNum(r.max)))
    end
end


-- =============================================================================
-- ImGui registration
-- =============================================================================

local drawWindow
local drawLastFightWindow

local imguiRegistered = false

local function ensureImGuiRegistered()
    if imguiRegistered then return end
    imguiRegistered = true
    -- The render callback. Each branch (drawFull / drawMini) now has
    -- its OWN internal pcall around the body, between Begin and End.
    -- That ensures Begin/End stay balanced even if the body errors.
    -- We DON'T wrap drawWindow itself in pcall because that would skip
    -- the End() inside drawFull/drawMini. The shuttingDown gate is
    -- still here as the only outer protection.
    mq.imgui.init('HealTrackerGUI', function()
        if shuttingDown then return end
        drawWindow()
    end)

    -- Second window: the post-fight summary popup. Shows in a separate
    -- floating window so it can sit alongside the main mini bar without
    -- overlapping. Has its own ID so ImGui treats it as independent.
    mq.imgui.init('HealTrackerLastFight', function()
        if shuttingDown then return end
        drawLastFightWindow()
    end)
end

-- =============================================================================
-- Slash command
-- =============================================================================

local function slashCmd(...)
    if shuttingDown then return end
    local args = { ... }
    local cmd = (args[1] or ''):lower()

    if cmd == '' then printStatus(); return end

    if cmd == 'driver' then
        local sub = (args[2] or ''):lower()
        if sub == 'clear' then
            local kept = {}
            for _, n in ipairs(config.drivers or {}) do
                if n ~= MyName then table.insert(kept, n) end
            end
            config.drivers = kept
            saveConfig()
            print(string.format('\ag[HealTracker]\ax %s removed from drivers', MyName))
        elseif sub == 'list' then
            if #(config.drivers or {}) > 0 then
                print('\ag[HealTracker]\ax drivers: ' .. table.concat(config.drivers, ', '))
            else
                print('\ag[HealTracker]\ax no drivers set')
            end
        else
            local already = false
            for _, n in ipairs(config.drivers or {}) do
                if n == MyName then already = true; break end
            end
            if already then
                print(string.format('\ag[HealTracker]\ax %s is already a driver', MyName))
            else
                table.insert(config.drivers, MyName)
                saveConfig()
                print(string.format('\ag[HealTracker]\ax %s added as a driver', MyName))
                config.windowOpen = true
                ensureImGuiRegistered()
            end
        end
        return
    end

    if cmd == 'report' then printReport(); return end

    if cmd == 'show' or cmd == 'window' then
        if not isDriver() then
            print('\ay[HealTracker]\ax this character is not a driver. Run \at/healtracker driver\ax first.')
            return
        end
        config.windowOpen = not config.windowOpen
        if config.windowOpen then ensureImGuiRegistered() end
        return
    end

    if cmd == 'mini' or cmd == 'collapse' or cmd == 'minimize' then
        config.miniMode = not config.miniMode
        if not config.miniMode then
            -- Going from mini back to full window -- restore the tab
            -- the user was on before collapsing.
            config._restoreTab = true
        end
        saveConfig()
        return
    end

    if cmd == 'reset' then
        actorBroadcast({ kind = 'reset_session' })
        resetSession()
        print('\ag[HealTracker]\ax session totals cleared')
        return
    end

    if cmd == 'fights' then
        local sub = (args[2] or ''):lower()
        if sub == 'clear' then
            if not isDriver() then
                print('\ay[HealTracker]\ax fights are only kept on the driver')
                return
            end
            fights = {}
            currentFight = emptyScope(nil)
            damageFights = {}
            activeMobs = {}
            spellsFights = {}
            currentSpellsFight = emptySpellsScope(nil)
            clearFightSelection()
            saveFights(true)
            saveDamage(true)
            saveSpells(true)
            print('\ar[HealTracker]\ax fight + damage + spells history cleared')
            print('\ag[HealTracker]\ax (history.log is NOT cleared -- ' ..
                  'see /healtracker log for path)')
        else
            print(string.format('\ag[HealTracker]\ax %d fights recorded', #fights))
        end
        return
    end

    if cmd == 'log' then
        -- Show the path to the persistent fight history log. Useful
        -- when the user wants to open it in a text editor or import
        -- it into a spreadsheet.
        local path = resolvedHistoryLogPath()
        print(string.format('\ag[HealTracker]\ax fight history log: \at%s\ax', path))
        -- Also show how many entries are in it (line count) so the
        -- user has a sense of how big it's grown.
        local f = io.open(path, 'r')
        if f then
            local count = 0
            for _ in f:lines() do count = count + 1 end
            f:close()
            print(string.format('  contains %d fight entries (append-only, not affected by /healtracker fights clear)',
                count))
        else
            print('  no entries yet (will be created on the next fight snapshot)')
        end
        return
    end

    if cmd == 'search' then
        -- Apply a mob-name search filter to whichever tab the user is
        -- currently viewing. Filter is case-insensitive substring match.
        -- Run with no args to clear. Examples:
        --   /healtracker search lord       (filter to mobs containing "lord")
        --   /healtracker search froglok    (filter to mobs containing "froglok")
        --   /healtracker search            (clear filter on current tab)
        --
        -- Why a slash command instead of an inline ImGui input box:
        -- the MQ ImGui Lua binding for InputText caused overlay errors
        -- in this version; slash commands are 100% reliable.
        local terms = {}
        for i = 2, #args do table.insert(terms, args[i]) end
        local needle = table.concat(terms, ' ')

        local tab = config.lastTab or 'heals'
        local labelMap = {
            heals = 'Heals', dps = 'DPS', spells = 'Spells', history = 'History',
        }
        local label = labelMap[tab]
        if not label then
            print('\ay[HealTracker]\ax search applies to Heals/DPS/Spells/History tabs.')
            print('  Switch to one of those tabs first.')
            return
        end

        if tab == 'heals'   then healsSearch   = needle end
        if tab == 'dps'     then damageSearch  = needle end
        if tab == 'spells'  then spellsSearch  = needle end
        if tab == 'history' then historySearch = needle end

        if needle == '' then
            print(string.format('\ag[HealTracker]\ax cleared search filter on \at%s\ax tab', label))
        else
            print(string.format('\ag[HealTracker]\ax \at%s\ax tab now showing fights matching "%s"',
                label, needle))
        end
        return
    end

    if cmd == 'pet' then
        local sub = (args[2] or ''):lower()
        config.petOwners = config.petOwners or {}
        if sub == 'add' then
            -- Pet names can include spaces (e.g. "Wizard's pet"), so
            -- treat the LAST arg as the owner and everything between
            -- as the pet name. Same approach used by the spell add
            -- command. Note: most pets don't need explicit mapping --
            -- the possessive form ("<Owner>'s pet") is auto-attributed
            -- by attributeDamage() -- but named pets like "PetName"
            -- need this map.
            local n = #args
            if n < 4 then
                print('\ay[HealTracker]\ax usage: /healtracker pet add <petName> <ownerName>')
                print('  Multi-word pet names are OK: pet add Some Big Pet OwnerName')
                return
            end
            local ownerName = args[n]
            local parts = {}
            for i = 3, n - 1 do table.insert(parts, args[i]) end
            local petName = table.concat(parts, ' ')
            if petName == '' or ownerName == '' then
                print('\ay[HealTracker]\ax usage: /healtracker pet add <petName> <ownerName>')
                return
            end
            config.petOwners[petName] = ownerName
            saveConfig()
            knownChars[petName] = true
            knownChars[ownerName] = true
            print(string.format('\ag[HealTracker]\ax mapped pet \at%s\ax -> owner \at%s\ax',
                petName, ownerName))
        elseif sub == 'remove' or sub == 'rm' then
            local n = #args
            if n < 3 then
                print('\ay[HealTracker]\ax usage: /healtracker pet remove <petName>')
                return
            end
            local parts = {}
            for i = 3, n do table.insert(parts, args[i]) end
            local petName = table.concat(parts, ' ')
            config.petOwners[petName] = nil
            -- Clean up knownChars too -- the pet was added there when
            -- the mapping was created, and should no longer be treated
            -- as a "known PC" once unmapped.
            knownChars[petName] = nil
            saveConfig()
            print(string.format('\ag[HealTracker]\ax removed mapping for \at%s\ax', petName))
        elseif sub == 'list' or sub == '' then
            local count = 0
            for pet, owner in pairs(config.petOwners) do
                if count == 0 then print('\ag[HealTracker]\ax pet -> owner mappings:') end
                print(string.format('  \at%-20s\ax -> %s', pet, owner))
                count = count + 1
            end
            if count == 0 then
                print('\ag[HealTracker]\ax no pet mappings set')
                print('  Add one with: /healtracker pet add <petName> <ownerName>')
            end
        elseif sub == 'clear' then
            config.petOwners = {}
            saveConfig()
            print('\ag[HealTracker]\ax all pet mappings cleared')
        else
            print('\ay[HealTracker]\ax usage: /healtracker pet add|remove|list|clear')
        end
        return
    end

    if cmd == 'spell' then
        -- Manage the spell -> caster map used to attribute DoT damage
        -- when the chat line has no "by <caster>" suffix. Spell names
        -- can contain spaces, so we treat args[3..N-1] as the spell
        -- name and args[N] as the caster name (last token).
        local sub = (args[2] or ''):lower()
        config.spellOwners = config.spellOwners or {}
        if sub == 'add' then
            -- Need at least: sub spell... caster (3 args minimum: add Foo Bar)
            local n = #args
            if n < 4 then
                print('\ay[HealTracker]\ax usage: /healtracker spell add <Spell Name> <CasterName>')
                print('  Example: /healtracker spell add Dread Pyre Necro')
                return
            end
            -- Last arg is the caster, all middle args joined are the spell.
            local casterName = args[n]
            local parts = {}
            for i = 3, n - 1 do table.insert(parts, args[i]) end
            local spellName = table.concat(parts, ' ')
            if spellName == '' or casterName == '' then
                print('\ay[HealTracker]\ax usage: /healtracker spell add <Spell Name> <CasterName>')
                return
            end
            config.spellOwners[spellName] = casterName
            saveConfig()
            knownChars[casterName] = true
            print(string.format('\ag[HealTracker]\ax mapped spell \at%s\ax -> caster \at%s\ax',
                spellName, casterName))
        elseif sub == 'remove' or sub == 'rm' then
            local n = #args
            if n < 3 then
                print('\ay[HealTracker]\ax usage: /healtracker spell remove <Spell Name>')
                return
            end
            local parts = {}
            for i = 3, n do table.insert(parts, args[i]) end
            local spellName = table.concat(parts, ' ')
            config.spellOwners[spellName] = nil
            saveConfig()
            print(string.format('\ag[HealTracker]\ax removed spell mapping for \at%s\ax', spellName))
        elseif sub == 'list' or sub == '' then
            local count = 0
            for spell, caster in pairs(config.spellOwners) do
                if count == 0 then print('\ag[HealTracker]\ax spell -> caster mappings:') end
                print(string.format('  \at%-30s\ax -> %s', spell, caster))
                count = count + 1
            end
            if count == 0 then
                print('\ag[HealTracker]\ax no spell mappings set')
                print('  Add one with: /healtracker spell add <Spell Name> <CasterName>')
                print('  Example:      /healtracker spell add Dread Pyre Necro')
            end
        elseif sub == 'clear' then
            config.spellOwners = {}
            saveConfig()
            print('\ag[HealTracker]\ax all spell mappings cleared')
        else
            print('\ay[HealTracker]\ax usage: /healtracker spell add|remove|list|clear')
        end
        return
    end

    if cmd == 'autoreset' then
        local v = (args[2] or ''):lower()
        if v == 'on' or v == 'true' or v == '1' then
            config.autoResetOnKill = true
        elseif v == 'off' or v == 'false' or v == '0' then
            config.autoResetOnKill = false
        else
            config.autoResetOnKill = not config.autoResetOnKill
        end
        saveConfig()
        print(string.format('\ag[HealTracker]\ax auto-reset on kill: %s',
            config.autoResetOnKill and '\agON\ax' or '\arOFF\ax'))
        return
    end

    if cmd == 'timeout' or cmd == 'idle' then
        local n = tonumber(args[2])
        if n then
            config.fightTimeoutSeconds = math.max(0, math.floor(n))
            saveConfig()
            if config.fightTimeoutSeconds == 0 then
                print('\ag[HealTracker]\ax fight timeout \arDISABLED\ax (fights only end on slain messages)')
            else
                print(string.format('\ag[HealTracker]\ax fight timeout = %d seconds of no damage',
                    config.fightTimeoutSeconds))
            end
        else
            if (config.fightTimeoutSeconds or 0) == 0 then
                print('\ag[HealTracker]\ax fight timeout is OFF')
            else
                print(string.format('\ag[HealTracker]\ax fight timeout = %d seconds of no damage',
                    config.fightTimeoutSeconds))
            end
        end
        return
    end

    if cmd == 'linger' or cmd == 'minilinger' then
        local n = tonumber(args[2])
        if n then
            config.miniLingerSeconds = math.max(0, math.min(300, math.floor(n)))
            saveConfig()
            if config.miniLingerSeconds == 0 then
                print('\ag[HealTracker]\ax mini linger = 0 (clear immediately after fight)')
            else
                print(string.format('\ag[HealTracker]\ax mini linger = %d seconds after fight ends',
                    config.miniLingerSeconds))
            end
        else
            local cur = config.miniLingerSeconds or 5
            print(string.format('\ag[HealTracker]\ax mini linger = %d seconds (use /healtracker linger N to change)',
                cur))
        end
        return
    end

    if cmd == 'primary' or cmd == 'primarytarget' then
        local sub = (args[2] or ''):lower()
        if sub == 'on' or sub == 'true' or sub == '1' then
            config.primaryTargetOnly = true
            saveConfig()
            print('\ag[HealTracker]\ax primary-target-only kill detection \agON\ax')
            print('  add deaths during boss fights will be ignored')
        elseif sub == 'off' or sub == 'false' or sub == '0' then
            config.primaryTargetOnly = false
            saveConfig()
            print('\ag[HealTracker]\ax primary-target-only kill detection \arOFF\ax')
            print('  every slain message ends the fight (Gamparse-style)')
        elseif sub == 'threshold' then
            local n = tonumber(args[3])
            if n then
                if n > 1 then n = n / 100 end  -- accept "20" as 20%
                config.primaryTargetThreshold = math.max(0.01, math.min(0.99, n))
                saveConfig()
                print(string.format('\ag[HealTracker]\ax primary target threshold = %.1f%% of fight damage',
                    config.primaryTargetThreshold * 100))
            else
                print('\ay[HealTracker]\ax usage: /healtracker primary threshold <pct>  (e.g. 20)')
            end
        else
            print(string.format(
                '\ag[HealTracker]\ax primary-target-only = %s, threshold = %.1f%%',
                tostring(config.primaryTargetOnly), (config.primaryTargetThreshold or 0.2) * 100))
            print('  /healtracker primary on|off')
            print('  /healtracker primary threshold <pct>  (e.g. 20 for 20%)')
        end
        return
    end

    if cmd == 'min' or cmd == 'minheal' then
        local n = tonumber(args[2])
        if n then
            config.minHealAmount = math.max(0, math.floor(n))
            saveConfig()
            print(string.format('\ag[HealTracker]\ax minHeal = %d', config.minHealAmount))
        else
            print(string.format('\ag[HealTracker]\ax minHeal = %d', config.minHealAmount))
        end
        return
    end

    if cmd == 'debug' then
        config.debug = not config.debug
        saveConfig()
        print(string.format('\ag[HealTracker]\ax debug: %s',
                            config.debug and '\agON\ax' or '\arOFF\ax'))
        return
    end

    if cmd == 'test' then
        local fakeHealer = args[2] or 'TestCleric'
        local fakeAmount = tonumber(args[3]) or 1234
        onLocalHeal('TEST', fakeHealer, fakeAmount)
        return
    end

    if cmd == 'testremote' then
        local fakeTarget = args[2] or 'Tank'
        local fakeHealer = args[3] or 'Cleric'
        local fakeAmount = tonumber(args[4]) or 4500
        if isDriver() then
            recordHeal(fakeTarget, fakeHealer, fakeAmount)
        else
            print('\ay[HealTracker]\ax testremote only works on a driver box')
        end
        return
    end

    if cmd == 'testkill' then
        local mob = args[2] or 'a goblin'
        if isDriver() then
            onKill('TEST', mob)
        else
            print('\ay[HealTracker]\ax testkill only works on a driver box')
        end
        return
    end

    if cmd == 'stop' or cmd == 'quit' or cmd == 'exit' then
        M.running = false
        return
    end

    print('\ay[HealTracker]\ax commands: driver | show | mini | report | reset | fights clear | autoreset on|off | idle N | min N | debug | test | testremote | testkill | stop')
end

-- =============================================================================
-- Theme
-- =============================================================================

local THEME = {
    bg     = { 24/255, 28/255, 44/255, 248/255 },
    border = { 255/255, 188/255, 72/255, 240/255 },
    label    = { 0.62, 0.70, 0.86, 1.0 },
    valueAmt = { 0.99, 0.81, 0.30, 1.0 },
    -- Bright pure yellow used for damage/DPS values in the live mini
    -- bar and the Last Fight popup. Matches the in-game chat color
    -- for damage messages so the windows feel native.
    valueDps = { 1.00, 1.00, 0.20, 1.0 },
    -- Light baby blue for heal values (total HP, heal count, avg/max)
    -- on the Heals tab. Distinguishes heal totals from damage totals
    -- at a glance.
    valueHeal = { 0.60, 0.85, 1.00, 1.0 },
    you      = { 0.55, 1.00, 0.60, 1.0 },
    muted    = { 0.45, 0.48, 0.55, 1.0 },
}

local btnVariants = {
    primary   = { {30/255, 80/255, 160/255, 1}, {50/255, 100/255, 180/255, 1}, {1,1,1,1} },
    success   = { {60/255, 120/255, 80/255, 1}, {80/255, 140/255, 100/255, 1}, {228/255, 245/255, 232/255, 1} },
    -- Bright green active highlight, used for selected toggle buttons
    -- (View/Date range pickers in the History tab) so the user can
    -- clearly see which option is currently chosen.
    active    = { {50/255, 175/255, 95/255, 1}, {70/255, 200/255, 115/255, 1}, {255/255, 255/255, 255/255, 1} },
    amber     = { {130/255, 95/255, 35/255, 1}, {155/255, 120/255, 60/255, 1}, {255/255, 226/255, 145/255, 1} },
    danger    = { {145/255, 60/255, 55/255, 1}, {170/255, 85/255, 80/255, 1}, {255/255, 228/255, 228/255, 1} },
    secondary = { {55/255, 58/255, 65/255, 1}, {75/255, 78/255, 85/255, 1}, {220/255, 225/255, 235/255, 1} },
}

local function pushBtn(base, hover, text)
    ImGui.PushStyleColor(ImGuiCol.Button,        base[1], base[2], base[3], base[4] or 1)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hover[1], hover[2], hover[3], hover[4] or 1)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive,  hover[1], hover[2], hover[3], hover[4] or 1)
    ImGui.PushStyleColor(ImGuiCol.Text,          text[1], text[2], text[3], text[4] or 1)
end

local function btn(label, variant, w, h)
    local v = btnVariants[variant] or btnVariants.secondary
    pushBtn(v[1], v[2], v[3])
    local clicked = ImGui.Button(label, w or 0, h or 0)
    ImGui.PopStyleColor(4)
    return clicked
end

-- =============================================================================
-- Search filter helpers
-- =============================================================================
--
-- Two helpers used by Heals/DPS/Spells/History tabs to render a search
-- filter UI:
--
--   uniqueMobsFromFights(arr, labelKey)
--     Builds a sorted unique-mob-name list from an array of fight
--     records. The labelKey is which field on each record holds the
--     mob name ('label' for active fights, 'mob' for archive records).
--
--   showSearchStatus(currentSearch, idSuffix, mobList)
--     Renders the filter UI for one tab. Returns the (possibly
--     updated) search string. Has three pieces:
--       - Status text showing the active filter (or hint)
--       - "Pick mob" Combo dropdown listing all unique mobs in the
--         tab's data. Click one to filter to that mob.
--       - "Clear" button when a filter is active.
--     Uses ImGui.Combo (not InputText -- InputText has known issues
--     in this MQ ImGui Lua binding).

uniqueMobsFromFights = function(arr, labelKey)
    labelKey = labelKey or 'label'
    local seen = {}
    local out = {}
    for _, fight in ipairs(arr or {}) do
        local name = fight and fight[labelKey]
        if name and name ~= '' and not seen[name] then
            seen[name] = true
            table.insert(out, name)
        end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

-- Per-tab combo box selection index. Reset to 0 (= "Pick a mob..."
-- placeholder) on each render; we only act when the user actually
-- changes the selection.
local _comboIdx = { heals = 0, dps = 0, spells = 0, history = 0 }

-- Pet mapping UI state (Settings tab). Two combo indices: which
-- unmapped attacker to map (left), and which owner to map them to
-- (right). Reset to 0 (placeholders) after each successful mapping.
local _petMapPetIdx   = 0
local _petMapOwnerIdx = 0
-- Picked-name state for the BeginCombo-based pet/owner pickers. Stores
-- the actual picked string (not an index), avoiding 0-vs-1-based
-- ambiguity in ImGui.Combo. nil = nothing picked yet.
local _petMapPetName   = nil
local _petMapOwnerName = nil

showSearchStatus = function(currentSearch, idSuffix, mobList)
    -- Status line showing the currently active filter (or hint if none).
    if currentSearch and currentSearch ~= '' then
        -- Highlight green when a filter is active.
        ImGui.TextColored(0.55, 1.00, 0.60, 1.0,
            string.format('Filter: "%s"', currentSearch))
        ImGui.SameLine()
        if btn('Clear##clearfilter_' .. idSuffix, 'secondary', 0, 0) then
            -- Reset combo index too so the dropdown shows placeholder again.
            _comboIdx[idSuffix] = 0
            return ''
        end
    else
        ImGui.TextColored(0.45, 0.48, 0.55, 1.0,
            'Filter mob: pick from dropdown OR /healtracker search <text>')
    end

    -- Combo dropdown of unique mob names. Uses BeginCombo/EndCombo
    -- with Selectable items so we get the picked string directly,
    -- avoiding any 0-vs-1-based indexing ambiguity that ImGui.Combo
    -- has across different binding versions.
    if mobList and #mobList > 0 then
        ImGui.Text('Pick mob:')
        ImGui.SameLine()
        ImGui.SetNextItemWidth(220)

        -- The label shown at the top of the combo: current search if
        -- one is active, else placeholder.
        local previewLabel = (currentSearch and currentSearch ~= '')
                              and currentSearch
                              or '(pick a mob...)'
        local pickedName = nil

        if ImGui.BeginCombo('##mobcombo_' .. idSuffix, previewLabel) then
            for _, m in ipairs(mobList) do
                local isSelected = (m == currentSearch)
                if ImGui.Selectable(m, isSelected) then
                    -- User clicked this item. Capture the name -- it's
                    -- the actual displayed string the user picked, not
                    -- an index that could be off-by-one.
                    pickedName = m
                end
                if isSelected then
                    ImGui.SetItemDefaultFocus()
                end
            end
            ImGui.EndCombo()
        end

        if pickedName then
            return pickedName
        end
    end

    return currentSearch
end

-- =============================================================================
-- Last-fight window (separate floating window)
-- =============================================================================
--
-- A small floating window that shows the most recently completed fight
-- in a Gamparse-style condensed format. It pops up when a fight ends
-- and disappears after the linger timer expires.
--
-- When multiple fights complete in rapid succession, the window cycles
-- through them one at a time, displaying each for `linger` seconds.
-- New kills append to the queue.
--
-- Format per row:
--   <pos>. <Name>   <total>k @<sdps>sdps (<dps> in <active>s) [<pct>%]
--
-- Runs independently of the main mini bar. Main bar shows live combat;
-- this window shows the just-finished fight. Both visible at once.

local function drawLastFightWindow_impl()
    if shuttingDown then return end
    if not isDriver() then return end

    local linger = config.miniLingerSeconds or 0

    -- Advance the queue. Drop the head if its display time is up.
    if #miniQueue > 0 then
        if miniQueueCurrentAt == 0 then
            miniQueueCurrentAt = os.time()
        elseif (os.time() - miniQueueCurrentAt) >= linger then
            table.remove(miniQueue, 1)
            miniQueueCurrentAt = (#miniQueue > 0) and os.time() or 0
        end
    else
        miniQueueCurrentAt = 0
    end

    -- Don't render anything if the queue is empty.
    if #miniQueue == 0 then return end

    local fight = miniQueue[1]
    if not fight then return end

    local flags = bit32.bor(
        ImGuiWindowFlags.AlwaysAutoResize,
        ImGuiWindowFlags.NoCollapse,
        ImGuiWindowFlags.NoFocusOnAppearing,
        ImGuiWindowFlags.NoNav)

    local visible, _ = ImGui.Begin('Last Fight##HealTrackerLastFight', true, flags)
    if not visible then
        ImGui.End()
        return
    end

    pcall(function()
        local mobLabel  = fight.label or '?'
        local total     = fight.total or 0
        local dur       = fight._frozenDur or 1
        if dur < 1 then dur = 1 end
        local groupSdps = math.floor(total / dur)

        local mr, mg, mb = mobLevelColor(fight.mobLevel)
        ImGui.TextColored(mr, mg, mb, 1.0, mobLabel)
        ImGui.SameLine(0, 16)
        ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
            string.format('%dk @%dsdps in %ds', math.floor(total / 1000), groupSdps, dur))

        if #miniQueue > 1 then
            ImGui.SameLine(0, 16)
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                string.format('(1 of %d)', #miniQueue))
        end

        ImGui.Separator()

        local rows = buildDamageRows(fight)
        for i, r in ipairs(rows) do
            local activeDur = dur
            local stats = fight.stats and fight.stats[r.attacker]
            if stats and stats.firstHit and stats.lastHit then
                activeDur = math.max(1, stats.lastHit - stats.firstHit)
            end

            local sdps      = math.floor((r.total or 0) / dur)
            local activeDps = math.floor((r.total or 0) / activeDur)
            local pct       = (total > 0) and ((r.total or 0) * 100 / total) or 0

            local nameLabel = string.format('%d. %s', i, r.attacker)
            if r.isMe then nameLabel = nameLabel .. ' (you)' end
            if r.hasPets and not (config.splitPetsInDps == true) then
                nameLabel = nameLabel .. ' + pets'
            end

            -- All character names rendered in the green "you" color
            -- for visibility against the muted DPS/percent text.
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0, nameLabel)
            ImGui.SameLine(180)
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                string.format('%dk @%dsdps', math.floor((r.total or 0) / 1000), sdps))
            ImGui.SameLine()
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                string.format('(%ddps in %ds)', activeDps, activeDur))
            ImGui.SameLine()
            ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                string.format('[%.1f%%]', pct))
        end
    end)

    ImGui.End()
end

-- Bind the implementation to the forward-declared local. The
-- imgui registration at the top of the file references
-- drawLastFightWindow as a closure upvalue; this assignment makes
-- the upvalue point at our actual function.
drawLastFightWindow = drawLastFightWindow_impl

-- =============================================================================
-- Mini view
-- =============================================================================

local function drawMini()
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2.5)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, THEME.bg[1], THEME.bg[2], THEME.bg[3], THEME.bg[4])
    ImGui.PushStyleColor(ImGuiCol.Border,   THEME.border[1], THEME.border[2], THEME.border[3], THEME.border[4])

    local flags = bit32.bor(
        ImGuiWindowFlags.AlwaysAutoResize,
        ImGuiWindowFlags.NoResize,
        ImGuiWindowFlags.NoTitleBar,
        ImGuiWindowFlags.NoCollapse,
        ImGuiWindowFlags.NoSavedSettings,
        ImGuiWindowFlags.NoFocusOnAppearing,
        ImGuiWindowFlags.NoNav)

    local showDps = config.miniShowDps == true

    local _open, shouldDraw = ImGui.Begin('###HealTrackerMini', true, flags)
    -- Wrap body in pcall so a Lua error doesn't skip the End()
    -- below. Without this, an error mid-render leaves Begin without
    -- End and ImGui pauses the overlay with "Missing End()".
    pcall(function()
    if shouldDraw then
        if btn('+##ht_expand', 'amber', 0, 0) then
            config.miniMode = false
            -- Trigger tab restoration on the next render frame so we
            -- come back to whatever tab the user last had open instead
            -- of defaulting to the first tab.
            config._restoreTab = true
            saveConfig()
        end
        ImGui.SameLine(0, 8)
        ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                          showDps and 'DPS Tracker' or 'Heal Tracker')
        ImGui.SameLine(0, 8)
        -- Mode toggle. Single click flips between the two live views.
        local toggleLabel = showDps and 'Heals##ht_mini_toggle' or 'DPS##ht_mini_toggle'
        if btn(toggleLabel, 'secondary', 0, 0) then
            config.miniShowDps = not showDps
            saveConfig()
        end
        ImGui.SameLine(0, 8)
        if btn('Reset##ht_mini_reset', 'danger', 0, 0) then
            actorBroadcast({ kind = 'reset_session' })
            resetSession()
        end

        if showDps then
            ----------------------------------------------------------------
            -- DPS mini view: shows all IN-PROGRESS damage across every
            -- active mob. Once all mobs go inactive (kill or timeout),
            -- the live scope empties, but we keep showing the LAST
            -- snapshot for config.miniLingerSeconds before clearing.
            -- This way you can glance at the bar right after a kill
            -- and still see who did what.
            ----------------------------------------------------------------
            local liveScope = combineActiveMobs()

            -- Mini bar = always live, in-progress damage. The queue
            -- of completed fights is shown in a SEPARATE window
            -- (drawLastFightWindow) so you can see live dps and
            -- last-fight dps simultaneously.
            local displayScope = liveScope
            local isLingering = false

            -- Duration: use frozen value during linger; live calculation
            -- otherwise. Without the freeze, the linger display would
            -- show DPS steadily ticking down (because total stays
            -- constant but wall-clock duration keeps growing).
            local dur
            if isLingering and displayScope._frozenDur then
                dur = displayScope._frozenDur
            else
                dur = math.max(1, os.time() - (displayScope.started or os.time()))
            end
            if dur < 1 then dur = 1 end

            ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0, 'Total:')
            ImGui.SameLine(0, 4)
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              fmtNum(displayScope.total))
            ImGui.SameLine(0, 12)
            ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0, 'DPS:')
            ImGui.SameLine(0, 4)
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              fmtNum(displayScope.total / dur))
            if isLingering then
                ImGui.SameLine(0, 12)
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                                  '(last fight)')
            end
            if lastKillName then
                ImGui.SameLine(0, 12)
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                                  'Last kill: ' .. lastKillName)
            end

            ImGui.Separator()

            if (displayScope.count or 0) == 0 then
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                    'No active fight. Damage shows here in real time.')
            else
                local rows = buildDamageRows(displayScope)
                -- Single-column layout: each row reads as
                --   <Name>   <total>k @<dps>
                -- so the user sees both the cumulative damage and the
                -- live DPS at a glance.
                local tflags = bit32.bor(ImGuiTableFlags.SizingFixedFit,
                                         ImGuiTableFlags.NoBordersInBody)
                if ImGui.BeginTable('DpsMini', 2, tflags) then
                    ImGui.TableSetupColumn('name', ImGuiTableColumnFlags.WidthFixed, 110)
                    ImGui.TableSetupColumn('val',  ImGuiTableColumnFlags.WidthStretch)
                    for _, row in ipairs(rows) do
                        ImGui.TableNextRow()
                        -- Name column: highlighted for "you", append
                        -- " + pets" if the row aggregates pets.
                        ImGui.TableNextColumn()
                        local nameLabel = row.attacker
                        if row.hasPets and not (config.splitPetsInDps == true) then
                            nameLabel = nameLabel .. ' + pets'
                        end
                        -- All character names rendered in the green
                        -- "you" color for at-a-glance readability.
                        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                                          nameLabel)

                        -- Value column: "<total> @<dps>". Use fmtNum
                        -- (with thousands separators) for both so the
                        -- numbers stay readable even when totals are
                        -- millions and DPS is in the tens of thousands.
                        ImGui.TableNextColumn()
                        local rowDps = (row.total or 0) / dur
                        ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                          fmtNum(row.total or 0))
                        ImGui.SameLine(0, 4)
                        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, '@')
                        ImGui.SameLine(0, 4)
                        ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                          fmtNum(rowDps))
                    end
                    ImGui.EndTable()
                end
            end
        else
            ----------------------------------------------------------------
            -- Heals mini view (original behavior): rolling session totals.
            ----------------------------------------------------------------
            ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0, 'Total:')
            ImGui.SameLine(0, 4)
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              fmtNum(session.total))
            ImGui.SameLine(0, 12)
            ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0, 'Heals:')
            ImGui.SameLine(0, 4)
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              tostring(session.count))
            if lastKillName then
                ImGui.SameLine(0, 12)
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                                  'Last kill: ' .. lastKillName)
            end

            ImGui.Separator()

            if session.count == 0 then
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                    'No heals tracked yet.')
            else
                local rows = buildRowsFor(session)
                local cols = math.max(1, math.min(3, config.miniColumns or 2))
                local nrows = math.ceil(#rows / cols)
                local imguiCols = cols * 2
                local tflags = bit32.bor(ImGuiTableFlags.SizingFixedFit,
                                         ImGuiTableFlags.NoBordersInBody)
                if ImGui.BeginTable('HealMini', imguiCols, tflags) then
                    for ic = 1, cols do
                        ImGui.TableSetupColumn('name'..ic, ImGuiTableColumnFlags.WidthFixed, 80)
                        ImGui.TableSetupColumn('val'..ic,  ImGuiTableColumnFlags.WidthFixed, 70)
                    end
                    for r = 1, nrows do
                        ImGui.TableNextRow()
                        for c = 0, cols - 1 do
                            local idx = c * nrows + r
                            local row = rows[idx]
                            ImGui.TableNextColumn()
                            if row then
                                -- All names rendered in green.
                                ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                                                  row.char)
                                ImGui.TableNextColumn()
                                -- Heal values in light baby blue.
                                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                                  fmtNum(row.total))
                            else
                                ImGui.Text(''); ImGui.TableNextColumn(); ImGui.Text('')
                            end
                        end
                    end
                    ImGui.EndTable()
                end
            end
        end
    end
    end)  -- close pcall around the body

    ImGui.End()
    -- These pops balance the pushes BEFORE Begin() (window-level
    -- styling), so they need to run regardless of body errors.
    ImGui.PopStyleColor(2)
    ImGui.PopStyleVar(1)
end

-- =============================================================================
-- Full view
-- =============================================================================

local function drawCharTable(scope, idPrefix)
    if scope.count == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No heals in this scope.')
        return
    end
    if ImGui.BeginTable(idPrefix .. '_chars', 5,
                        bit32.bor(ImGuiTableFlags.Borders,
                                  ImGuiTableFlags.RowBg,
                                  ImGuiTableFlags.Resizable)) then
        ImGui.TableSetupColumn('Character')
        ImGui.TableSetupColumn('Total HP')
        ImGui.TableSetupColumn('Heals')
        ImGui.TableSetupColumn('Avg / heal')
        ImGui.TableSetupColumn('Max heal')
        ImGui.TableHeadersRow()

        for _, r in ipairs(buildRowsFor(scope)) do
            ImGui.TableNextRow()

            -- Character row -- plain label, no TreeNode. The per-healer
            -- breakdown below is always rendered, so there's nothing to
            -- expand or collapse.
            ImGui.TableNextColumn()
            local label = r.isMe and (r.char .. ' (you)') or r.char
            -- Names rendered in bright green.
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0, label)

            -- Heal values in light baby blue. Distinguishes heals from
            -- damage at a glance (damage uses bright yellow).
            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              fmtNum(r.total))
            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              tostring(r.count))
            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              fmtNum(r.total / math.max(1, r.count)))
            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              fmtNum(r.max))

            -- Always show per-healer breakdown.
            local hRows = {}
            for healer, h in pairs(r.healers) do
                table.insert(hRows, {
                    name = healer, total = h.total, count = h.count, max = h.max,
                })
            end
            table.sort(hRows, function(a, b) return a.total > b.total end)
            for _, h in ipairs(hRows) do
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                                  '    by ' .. h.name)
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                  fmtNum(h.total))
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                  tostring(h.count))
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                  fmtNum(h.total / math.max(1, h.count)))
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                  fmtNum(h.max))
            end
        end
        ImGui.EndTable()
    end
end

-- =============================================================================
-- DPS tab
-- =============================================================================

-- Draw the per-attacker breakdown table for a damage scope. Mirrors
-- drawCharTable but for damage instead of heals.
local function drawDamageCharTable(scope, idPrefix, durationSec)
    if scope.count == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No damage in this scope.')
        return
    end

    -- Use fight duration to compute per-attacker DPS. A 0-second fight
    -- (instant kill) falls back to 1 to avoid divide-by-zero.
    local dur = math.max(1, durationSec or 1)
    local split = config.splitPetsInDps == true

    if ImGui.BeginTable(idPrefix .. '_dmg_chars', 5,
                        bit32.bor(ImGuiTableFlags.Borders,
                                  ImGuiTableFlags.RowBg,
                                  ImGuiTableFlags.Resizable)) then
        ImGui.TableSetupColumn('Attacker')
        ImGui.TableSetupColumn('Total dmg')
        ImGui.TableSetupColumn('Hits')
        ImGui.TableSetupColumn('DPS')
        ImGui.TableSetupColumn('Max hit')
        ImGui.TableHeadersRow()

        for _, r in ipairs(buildDamageRows(scope)) do
            -- Owner row.
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            local label = r.attacker
            if r.isMe then label = label .. ' (you)' end
            -- Combined view: append "+ pets" suffix if any pet damage
            -- is rolled into this owner's total. Gamparse-style.
            if r.hasPets and not split then
                label = label .. ' + pets'
            end
            -- Names rendered in bright green.
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0, label)

            -- Damage / DPS values in bright yellow.
            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              fmtNum(r.total))
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.count))
            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              fmtNum(r.total / dur))
            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              fmtNum(r.max))

            -- Split view: render owner's own contribution + each pet
            -- as separate indented rows underneath. The owner's "self"
            -- damage is total-minus-pet-totals.
            if r.hasPets and split then
                local petSum = 0
                local petCount = 0
                local petMax = 0
                for _, p in pairs(r.pets) do
                    petSum   = petSum + p.total
                    petCount = petCount + p.count
                    if p.max > petMax then petMax = p.max end
                end
                local selfTotal = r.total - petSum
                local selfHits  = r.count - petCount
                if selfTotal > 0 then
                    ImGui.TableNextRow()
                    ImGui.TableNextColumn()
                    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                        '    ' .. r.attacker .. ' (own)')
                    ImGui.TableNextColumn()
                    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                      fmtNum(selfTotal))
                    ImGui.TableNextColumn(); ImGui.Text(tostring(selfHits))
                    ImGui.TableNextColumn()
                    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                      fmtNum(selfTotal / dur))
                    -- We don't store owner-only max separately; show "-"
                    ImGui.TableNextColumn(); ImGui.Text('-')
                end

                local petRows = {}
                for petName, p in pairs(r.pets) do
                    table.insert(petRows, {
                        name = petName, total = p.total, count = p.count, max = p.max,
                    })
                end
                table.sort(petRows, function(a, b) return a.total > b.total end)
                for _, p in ipairs(petRows) do
                    ImGui.TableNextRow()
                    ImGui.TableNextColumn()
                    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                        '    + ' .. p.name)
                    ImGui.TableNextColumn()
                    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                      fmtNum(p.total))
                    ImGui.TableNextColumn(); ImGui.Text(tostring(p.count))
                    ImGui.TableNextColumn()
                    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                      fmtNum(p.total / dur))
                    ImGui.TableNextColumn()
                    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                      fmtNum(p.max))
                end
            end
        end
        ImGui.EndTable()
    end
end

local function drawDpsTab()
    ImGui.Text(string.format('Recorded fights : %d', #damageFights))
    -- Count active mobs being damaged right now.
    local activeCount = 0
    local activeTotal = 0
    for _, mob in pairs(activeMobs) do
        activeCount = activeCount + 1
        activeTotal = activeTotal + (mob.total or 0)
    end
    if activeCount > 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            string.format('In progress     : %d active mob(s), %s total damage',
                activeCount, fmtNum(activeTotal)))
    end

    -- Split pets toggle. Lives at the top so it applies to whichever
    -- view is currently shown (single fight, click-selected, or combined).
    local newSplit, changedSplit = ImGui.Checkbox(
        'Split pets from owner', config.splitPetsInDps == true)
    if changedSplit then
        config.splitPetsInDps = newSplit
        saveConfig()
    end
    ImGui.SameLine()
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        '(off = "Owner + pets" combined; on = pets shown as nested rows)')

    local selDmg = getSelectedDamageIndices()
    local selDmgCount = #selDmg

    ImGui.Spacing()
    -- Search box for filtering by mob name.
    damageSearch = showSearchStatus(damageSearch, 'dps', uniqueMobsFromFights(damageFights, 'label'))

    if btn('Select all##dps_selall', 'secondary', 0, 0) then
        damageSelected = {}
        for i = 1, #damageFights do damageSelected[i] = true end
    end
    ImGui.SameLine()
    if btn('Select none##dps_selnone', 'secondary', 0, 0) then
        damageSelected = {}
    end
    ImGui.SameLine()
    if selDmgCount > 0 then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('%d selected', selDmgCount))
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'check fights to combine, or click a name to drill in')
    end

    ImGui.Separator()

    if #damageFights == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No damage recorded yet. Damage is captured driver-side and ' ..
            'snapshotted on each kill.')
        return
    end

    -- Two-pane layout: list left, drilldown right.
    if ImGui.BeginTable('DpsLayout', 2,
                        bit32.bor(ImGuiTableFlags.Resizable,
                                  ImGuiTableFlags.BordersInner)) then
        ImGui.TableSetupColumn('list', ImGuiTableColumnFlags.WidthStretch, 0.45)
        ImGui.TableSetupColumn('details', ImGuiTableColumnFlags.WidthStretch, 0.55)

        ImGui.TableNextRow()

        -- Left pane: fight list (sorted per damageSort).
        ImGui.TableNextColumn()
        if ImGui.BeginTable('DpsList', 5,
                            bit32.bor(ImGuiTableFlags.Borders,
                                      ImGuiTableFlags.RowBg,
                                      ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit)) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 28)
            ImGui.TableSetupColumn('When', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('Dmg',  ImGuiTableColumnFlags.WidthFixed, 80)
            ImGui.TableSetupColumn('DPS',  ImGuiTableColumnFlags.WidthFixed, 70)

            -- Custom sortable header row. Click a header to cycle sort
            -- (asc -> desc) on that column.
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); sortHeader('When', damageSort, 'when')
            ImGui.TableNextColumn(); sortHeader('Mob',  damageSort, 'mob')
            ImGui.TableNextColumn(); sortHeader('Dmg',  damageSort, 'amount')
            ImGui.TableNextColumn(); ImGui.Text('DPS')

            for _, i in ipairs(filteredSortedIndices(damageFights, damageSort, 'total', damageSearch, 'label')) do
                local d = damageFights[i]
                local dur = math.max(1, (d.ended or d.started or 0) - (d.started or 0))
                ImGui.TableNextRow()

                ImGui.TableNextColumn()
                local checked = damageSelected[i] or false
                local newC, ch = ImGui.Checkbox('##sel_dmg_' .. i, checked)
                if ch then damageSelected[i] = newC or nil end

                ImGui.TableNextColumn()
                ImGui.Text(os.date('%H:%M:%S', d.ended or d.started or os.time()))
                ImGui.TableNextColumn()
                local mobLabel = (d.label or '?') .. '##dmgfight_' .. i
                local mr, mg, mb = mobLevelColor(d.mobLevel)
                ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                if ImGui.Selectable(mobLabel, selectedDamageIdx == i,
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    selectedDamageIdx = i
                end
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                  fmtNum(d.total))
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                  fmtNum(d.total / dur))
            end
            ImGui.EndTable()
        end

        -- Right pane: priority order = combined (2+) > checked (1) > clicked
        ImGui.TableNextColumn()

        if selDmgCount >= 2 then
            local combined = combineDamageFights(selDmg)
            local dur = math.max(1, combined.totalDuration or 1)
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                string.format('Combined view: %d fights', combined.fightCount))
            ImGui.Text(string.format('Total dmg : %s', fmtNum(combined.total)))
            ImGui.Text(string.format('Hits      : %d', combined.count))
            ImGui.Text(string.format('Max hit   : %s', fmtNum(combined.max)))
            ImGui.Text(string.format('Combined fight time : %ds', dur))
            ImGui.Text(string.format('Group DPS : %s', fmtNum(combined.total / dur)))
            ImGui.Separator()
            drawDamageCharTable(combined, 'dpscombined', dur)

        elseif selDmgCount == 1 then
            local d = damageFights[selDmg[1]]
            local dur = math.max(1, (d.ended or d.started or 0) - (d.started or 0))
            ImGui.Text(string.format('Mob       : %s', d.label or '?'))
            ImGui.Text(string.format('Duration  : %ds', dur))
            ImGui.Text(string.format('Total dmg : %s', fmtNum(d.total)))
            ImGui.Text(string.format('Group DPS : %s', fmtNum(d.total / dur)))
            ImGui.Separator()
            drawDamageCharTable(d, 'dpsone' .. selDmg[1], dur)

        elseif selectedDamageIdx and damageFights[selectedDamageIdx] then
            local d = damageFights[selectedDamageIdx]
            local dur = math.max(1, (d.ended or d.started or 0) - (d.started or 0))
            ImGui.Text(string.format('Mob       : %s', d.label or '?'))
            ImGui.Text(string.format('Started   : %s', os.date('%H:%M:%S', d.started or 0)))
            ImGui.Text(string.format('Ended     : %s', os.date('%H:%M:%S', d.ended or d.started or 0)))
            ImGui.Text(string.format('Duration  : %ds', dur))
            ImGui.Text(string.format('Total dmg : %s', fmtNum(d.total)))
            ImGui.Text(string.format('Hits      : %d', d.count))
            ImGui.Text(string.format('Max hit   : %s', fmtNum(d.max)))
            ImGui.Text(string.format('Group DPS : %s', fmtNum(d.total / dur)))
            ImGui.Separator()
            drawDamageCharTable(d, 'dpsfight' .. selectedDamageIdx, dur)

        else
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                'Click a fight name on the left to drill in.')
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                'Or check 2+ fights to see a combined total.')
        end

        ImGui.EndTable()
    end
end

local function drawSessionTab()
    ImGui.Text(string.format('Tracked characters : %d', countKeys(session.stats)))
    ImGui.Text(string.format('Total HP healed    : %s', fmtNum(session.total)))
    ImGui.Text(string.format('Heal events        : %d', session.count))
    if session.count > 0 then
        local elapsed = math.max(1, os.time() - session.started)
        ImGui.Text(string.format('HPS                : %s', fmtNum(session.total / elapsed)))
        ImGui.Text(string.format('Largest single     : %s', fmtNum(session.max)))
    end
    if lastKillName then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            string.format('Last kill: %s (%ds ago)',
                lastKillName, os.time() - lastKillAt))
    end

    ImGui.Spacing()
    if btn('Reset session##ht_full_reset', 'danger', 0, 0) then
        actorBroadcast({ kind = 'reset_session' })
        resetSession()
    end
    ImGui.SameLine()
    if btn('Copy summary##ht_full_copy', 'amber', 0, 0) then
        copyToClipboard(summaryText(session, 'session'))
    end
    ImGui.SameLine()
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        '(reset broadcasts to all boxes)')

    ImGui.Separator()
    drawCharTable(session, 'session')
end

local function drawFightsTab()
    ImGui.Text(string.format('Fights recorded : %d', #fights))
    if currentFight.count > 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            string.format('In progress     : %s HP / %d heals',
                fmtNum(currentFight.total), currentFight.count))
    end

    local selIdx = getSelectedIndices()
    local selCount = #selIdx

    ImGui.Spacing()
    -- Search box for filtering by mob name.
    healsSearch = showSearchStatus(healsSearch, 'heals', uniqueMobsFromFights(fights, 'label'))

    -- Action bar: select all/none, clear all, with selection count.
    if btn('Select all##ht_fight_selall', 'secondary', 0, 0) then
        fightSelected = {}
        for i = 1, #fights do fightSelected[i] = true end
    end
    ImGui.SameLine()
    if btn('Select none##ht_fight_selnone', 'secondary', 0, 0) then
        clearFightSelection()
    end
    ImGui.SameLine()
    if selCount > 0 then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('%d selected', selCount))
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'check fights to combine, or click a name to drill in')
    end
    ImGui.SameLine(0, 16)
    if btn('Clear all fights##ht_fights_clear', 'danger', 0, 0) then
        fights = {}
        damageFights = {}
        spellsFights = {}
        clearFightSelection()
        saveFights(true)
        saveDamage(true)
        saveSpells(true)
    end

    ImGui.Separator()

    if #fights == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No fights recorded yet. Auto-reset on kill: ' ..
            (config.autoResetOnKill and 'ON' or 'OFF'))
        return
    end

    -- Two-pane layout: list on left, details / combined view on right.
    if ImGui.BeginTable('FightsLayout', 2,
                        bit32.bor(ImGuiTableFlags.Resizable,
                                  ImGuiTableFlags.BordersInner)) then
        ImGui.TableSetupColumn('list', ImGuiTableColumnFlags.WidthStretch, 0.45)
        ImGui.TableSetupColumn('details', ImGuiTableColumnFlags.WidthStretch, 0.55)

        ImGui.TableNextRow()

        ----------------------------------------------------------------
        -- Left pane: scrollable fight list with checkboxes
        ----------------------------------------------------------------
        ImGui.TableNextColumn()
        if ImGui.BeginTable('FightsList', 5,
                            bit32.bor(ImGuiTableFlags.Borders,
                                      ImGuiTableFlags.RowBg,
                                      ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit)) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 28)
            ImGui.TableSetupColumn('When', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('HP',   ImGuiTableColumnFlags.WidthFixed, 80)
            ImGui.TableSetupColumn('Heals',ImGuiTableColumnFlags.WidthFixed, 50)

            -- Sortable header row.
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); sortHeader('When', healsSort, 'when')
            ImGui.TableNextColumn(); sortHeader('Mob',  healsSort, 'mob')
            ImGui.TableNextColumn(); sortHeader('HP',   healsSort, 'amount')
            ImGui.TableNextColumn(); ImGui.Text('Heals')

            for _, i in ipairs(filteredSortedIndices(fights, healsSort, 'total', healsSearch, 'label')) do
                local f = fights[i]
                ImGui.TableNextRow()

                ImGui.TableNextColumn()
                local checked = fightSelected[i] or false
                local newChecked, changed = ImGui.Checkbox('##sel_fight_' .. i, checked)
                if changed then
                    fightSelected[i] = newChecked or nil
                end

                ImGui.TableNextColumn()
                ImGui.Text(os.date('%H:%M:%S', f.ended or f.started or os.time()))

                ImGui.TableNextColumn()
                local mobLabel = (f.label or '?') .. '##fight_' .. i
                local mr, mg, mb = mobLevelColor(f.mobLevel)
                ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                if ImGui.Selectable(mobLabel, selectedFightIdx == i,
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    selectedFightIdx = i
                end
                ImGui.PopStyleColor()

                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                  fmtNum(f.total))
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                  tostring(f.count))
            end
            ImGui.EndTable()
        end

        ----------------------------------------------------------------
        -- Right pane: priority order = combined (2+) > checked (1) > clicked
        ----------------------------------------------------------------
        ImGui.TableNextColumn()

        if selCount >= 2 then
            local combined = combineFights(selIdx)
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                string.format('Combined view: %d fights', combined.fightCount))

            if combined.startedMin and combined.endedMax then
                local span = combined.endedMax - combined.startedMin
                ImGui.Text(string.format('Time span : %s -> %s (%ds)',
                    os.date('%H:%M:%S', combined.startedMin),
                    os.date('%H:%M:%S', combined.endedMax),
                    span))
            end
            ImGui.Text(string.format('Total HP  : %s', fmtNum(combined.total)))
            ImGui.Text(string.format('Heals     : %d', combined.count))
            ImGui.Text(string.format('Largest   : %s', fmtNum(combined.max)))
            local topName, topTotal = fightTopHealer(combined)
            if topName then
                ImGui.Text(string.format('Top healer: %s (%s)', topName, fmtNum(topTotal)))
            end

            ImGui.Spacing()
            if btn('Copy combined to clipboard##ht_combined_copy', 'amber', 0, 0) then
                copyToClipboard(summaryText(combined,
                    string.format('Combined: %d fights', combined.fightCount)))
            end
            ImGui.SameLine()
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                '(paste with Ctrl+V into chat)')

            ImGui.Separator()
            drawCharTable(combined, 'combined')

        elseif selCount == 1 then
            local idx = selIdx[1]
            local f = fights[idx]
            ImGui.Text(string.format('Mob       : %s', f.label or '?'))
            ImGui.Text(string.format('Started   : %s', os.date('%H:%M:%S', f.started or 0)))
            ImGui.Text(string.format('Ended     : %s', os.date('%H:%M:%S', f.ended or f.started or 0)))
            local dur = (f.ended or f.started or 0) - (f.started or 0)
            if dur > 0 then ImGui.Text(string.format('Duration  : %ds', dur)) end
            ImGui.Text(string.format('Total HP  : %s', fmtNum(f.total)))
            ImGui.Text(string.format('Heals     : %d', f.count))
            ImGui.Text(string.format('Largest   : %s', fmtNum(f.max)))
            local topName, topTotal = fightTopHealer(f)
            if topName then
                ImGui.Text(string.format('Top healer: %s (%s)', topName, fmtNum(topTotal)))
            end
            ImGui.Spacing()
            if btn('Copy fight to clipboard##ht_one_copy', 'amber', 0, 0) then
                copyToClipboard(summaryText(f, f.label or 'fight'))
            end
            ImGui.Separator()
            drawCharTable(f, 'fight' .. idx)

        elseif selectedFightIdx and fights[selectedFightIdx] then
            local f = fights[selectedFightIdx]
            ImGui.Text(string.format('Mob       : %s', f.label or '?'))
            ImGui.Text(string.format('Started   : %s', os.date('%H:%M:%S', f.started or 0)))
            ImGui.Text(string.format('Ended     : %s', os.date('%H:%M:%S', f.ended or f.started or 0)))
            local dur = (f.ended or f.started or 0) - (f.started or 0)
            if dur > 0 then ImGui.Text(string.format('Duration  : %ds', dur)) end
            ImGui.Text(string.format('Total HP  : %s', fmtNum(f.total)))
            ImGui.Text(string.format('Heals     : %d', f.count))
            ImGui.Text(string.format('Largest   : %s', fmtNum(f.max)))
            local topName, topTotal = fightTopHealer(f)
            if topName then
                ImGui.Text(string.format('Top healer: %s (%s)', topName, fmtNum(topTotal)))
            end
            ImGui.Spacing()
            if btn('Copy fight to clipboard##ht_click_copy', 'amber', 0, 0) then
                copyToClipboard(summaryText(f, f.label or 'fight'))
            end
            ImGui.Separator()
            drawCharTable(f, 'fight' .. selectedFightIdx)

        else
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                'Click a fight name on the left to drill into it.')
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                'Or check 2+ fights to see a combined total.')
        end

        ImGui.EndTable()
    end
end

-- =============================================================================
-- Spells tab
-- =============================================================================
--
-- Two-pane layout matching the DPS tab. Left lists fights (newest first)
-- with mob name + total cast count + duration. Right shows the selected
-- fight: a flat list of every spell (sorted by total casts) AND a
-- per-caster breakdown showing each character's spell usage.

-- Build a flat aggregated list of {spell, total} across a spells scope.
local function buildSpellTotals(scope)
    local totals = {}
    for _, casterStats in pairs(scope.stats) do
        for spell, count in pairs(casterStats.casts) do
            totals[spell] = (totals[spell] or 0) + count
        end
    end
    local rows = {}
    for spell, count in pairs(totals) do
        table.insert(rows, { spell = spell, count = count })
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.spell < b.spell
    end)
    return rows
end

-- Build a per-caster breakdown: rows of {caster, total, spells={spell=count}}.
local function buildCasterRows(scope)
    local rows = {}
    for caster, s in pairs(scope.stats) do
        table.insert(rows, {
            caster = caster,
            total  = s.total,
            casts  = s.casts,
            isMe   = (caster == MyName),
        })
    end
    table.sort(rows, function(a, b)
        if a.isMe ~= b.isMe then return a.isMe end
        return a.total > b.total
    end)
    return rows
end

-- Helper: render the right-pane breakdown for a single spells scope
-- (either a single fight or a combined synthetic scope). Pulled out so
-- the combined view can reuse it.
local function drawSpellsDetail(s, idPrefix)
    -- Flat list: every unique spell across all casters.
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Spells cast (all casters)')
    if ImGui.BeginTable(idPrefix .. '_flat', 2,
                        bit32.bor(ImGuiTableFlags.Borders,
                                  ImGuiTableFlags.RowBg,
                                  ImGuiTableFlags.Resizable)) then
        ImGui.TableSetupColumn('Spell', ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn('Casts', ImGuiTableColumnFlags.WidthFixed, 60)
        ImGui.TableHeadersRow()
        for _, r in ipairs(buildSpellTotals(s)) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text(r.spell)
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.count))
        end
        ImGui.EndTable()
    end

    ImGui.Separator()

    -- Per-caster breakdown.
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Casts by character')
    if ImGui.BeginTable(idPrefix .. '_bycaster', 2,
                        bit32.bor(ImGuiTableFlags.Borders,
                                  ImGuiTableFlags.RowBg,
                                  ImGuiTableFlags.Resizable)) then
        ImGui.TableSetupColumn('Caster / Spell', ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn('Casts', ImGuiTableColumnFlags.WidthFixed, 60)
        ImGui.TableHeadersRow()
        for _, r in ipairs(buildCasterRows(s)) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            local label = r.isMe and (r.caster .. ' (you)') or r.caster
            if r.isMe then
                ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0, label)
            else
                ImGui.Text(label)
            end
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.total))

            local spellRows = {}
            for spell, count in pairs(r.casts) do
                table.insert(spellRows, { spell = spell, count = count })
            end
            table.sort(spellRows, function(a, b)
                if a.count ~= b.count then return a.count > b.count end
                return a.spell < b.spell
            end)
            for _, sr in ipairs(spellRows) do
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.TextColored(0.6, 0.85, 1.0, 1.0, '    ' .. sr.spell)
                ImGui.TableNextColumn(); ImGui.Text(tostring(sr.count))
            end
        end
        ImGui.EndTable()
    end
end

local function drawSpellsTab()
    ImGui.Text(string.format('Recorded fights : %d', #spellsFights))
    if currentSpellsFight.total > 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            string.format('In progress     : %d casts',
                currentSpellsFight.total))
    end

    local selSp = getSelectedSpellsIndices()
    local selSpCount = #selSp

    ImGui.Spacing()
    -- Search box for filtering by mob name.
    spellsSearch = showSearchStatus(spellsSearch, 'spells', uniqueMobsFromFights(spellsFights, 'label'))

    if btn('Select all##sp_selall', 'secondary', 0, 0) then
        spellsSelected = {}
        for i = 1, #spellsFights do spellsSelected[i] = true end
    end
    ImGui.SameLine()
    if btn('Select none##sp_selnone', 'secondary', 0, 0) then
        spellsSelected = {}
    end
    ImGui.SameLine()
    if selSpCount > 0 then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('%d selected', selSpCount))
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'check fights to combine, or click a name to drill in')
    end

    ImGui.Separator()

    if #spellsFights == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No spell casts recorded yet. Spells are tracked driver-side ' ..
            'and snapshotted on each kill.')
        return
    end

    if ImGui.BeginTable('SpellsLayout', 2,
                        bit32.bor(ImGuiTableFlags.Resizable,
                                  ImGuiTableFlags.BordersInner)) then
        ImGui.TableSetupColumn('list', ImGuiTableColumnFlags.WidthStretch, 0.40)
        ImGui.TableSetupColumn('details', ImGuiTableColumnFlags.WidthStretch, 0.60)

        ImGui.TableNextRow()

        -- Left pane
        ImGui.TableNextColumn()
        if ImGui.BeginTable('SpellsList', 4,
                            bit32.bor(ImGuiTableFlags.Borders,
                                      ImGuiTableFlags.RowBg,
                                      ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit)) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 28)
            ImGui.TableSetupColumn('When', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('Casts',ImGuiTableColumnFlags.WidthFixed, 60)

            -- Sortable header row.
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); sortHeader('When', spellsSort, 'when')
            ImGui.TableNextColumn(); sortHeader('Mob',  spellsSort, 'mob')
            ImGui.TableNextColumn(); sortHeader('Casts',spellsSort, 'amount')

            for _, i in ipairs(filteredSortedIndices(spellsFights, spellsSort, 'total', spellsSearch, 'label')) do
                local s = spellsFights[i]
                ImGui.TableNextRow()

                ImGui.TableNextColumn()
                local checked = spellsSelected[i] or false
                local newC, ch = ImGui.Checkbox('##sel_sp_' .. i, checked)
                if ch then spellsSelected[i] = newC or nil end

                ImGui.TableNextColumn()
                ImGui.Text(os.date('%H:%M:%S', s.ended or s.started or os.time()))
                ImGui.TableNextColumn()
                local mobLabel = (s.label or '?') .. '##spellsfight_' .. i
                local mr, mg, mb = mobLevelColor(s.mobLevel)
                ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                if ImGui.Selectable(mobLabel, selectedSpellsIdx == i,
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    selectedSpellsIdx = i
                end
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                  tostring(s.total))
            end
            ImGui.EndTable()
        end

        -- Right pane
        ImGui.TableNextColumn()

        if selSpCount >= 2 then
            local combined = combineSpellsFights(selSp)
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                string.format('Combined view: %d fights', combined.fightCount))
            ImGui.Text(string.format('Total casts : %d', combined.total))
            ImGui.Separator()
            drawSpellsDetail(combined, 'spcombined')

        elseif selSpCount == 1 then
            local s = spellsFights[selSp[1]]
            ImGui.Text(string.format('Mob       : %s', s.label or '?'))
            ImGui.Text(string.format('Total     : %d casts', s.total))
            ImGui.Separator()
            drawSpellsDetail(s, 'spone' .. selSp[1])

        elseif selectedSpellsIdx and spellsFights[selectedSpellsIdx] then
            local s = spellsFights[selectedSpellsIdx]
            local dur = math.max(1, (s.ended or s.started or 0) - (s.started or 0))
            ImGui.Text(string.format('Mob       : %s', s.label or '?'))
            ImGui.Text(string.format('Started   : %s', os.date('%H:%M:%S', s.started or 0)))
            ImGui.Text(string.format('Ended     : %s', os.date('%H:%M:%S', s.ended or s.started or 0)))
            ImGui.Text(string.format('Duration  : %ds', dur))
            ImGui.Text(string.format('Total     : %d casts', s.total))
            ImGui.Separator()
            drawSpellsDetail(s, 'spfight' .. selectedSpellsIdx)

        else
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                'Click a fight name on the left to drill in.')
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                'Or check 2+ fights to see a combined total.')
        end

        ImGui.EndTable()
    end
end

-- =============================================================================
-- History tab
-- =============================================================================
--
-- Browses the persistent fight archive. Lets the user filter by date
-- range, browse the matching fights, drill into any one to see full
-- per-character heal/damage/spell breakdowns, and load a selection
-- back into the active in-memory state so the regular Heals/DPS/Spells
-- tabs can show them with full functionality (combine, sort, etc.).

-- Compute (startTs, endTs) for the current archiveRange selection.
-- Returns two numbers or nils for "no bound".
local function rangeBounds()
    local now = os.time()
    if archiveRange == 'today' then
        -- Midnight today.
        local t = os.date('*t', now)
        t.hour, t.min, t.sec = 0, 0, 0
        return os.time(t), nil
    elseif archiveRange == '24h' then
        return now - 86400, nil
    elseif archiveRange == '7d' then
        return now - (86400 * 7), nil
    elseif archiveRange == '30d' then
        return now - (86400 * 30), nil
    elseif archiveRange == 'custom' then
        return now - (86400 * archiveCustomDays), nil
    else  -- 'all'
        return nil, nil
    end
end

-- Refresh the archive cache from disk if it's stale or if the user
-- changed the range. Throttled by archiveNeedsRefresh so we don't hit
-- disk every render frame.
local function refreshArchiveIfNeeded()
    local rangeKey = archiveRange .. ':' .. tostring(archiveCustomDays)
    if archiveNeedsRefresh or archiveCacheRange ~= rangeKey then
        local startTs, endTs = rangeBounds()
        archiveCache = loadArchive(startTs, endTs)
        archiveCacheRange = rangeKey
        archiveNeedsRefresh = false
    end
end

-- =============================================================================
-- Mobs tab: per-fight breakdown of spells the MOB cast at us
-- =============================================================================
--
-- For each completed fight (in damageFights), shows the mob name and
-- a list of spells that mob cast during the fight. Useful for
-- post-mortem analysis of boss mechanics, knowing what to interrupt
-- next time, etc.
--
-- Data model: each damage scope can have a `mobSpells = {[spellName]
-- = count}` table populated by the spell_cast_other event handler
-- (which routes mob "begins to cast" events into the active mob's
-- scope). Persists for free via saveDamage / loadDamage.

local selectedMobIdx = nil  -- index into damageFights[] or nil

-- Separate cache + date-range state for the Mob Spells tab. Mirrors
-- the History tab's archiveCache infrastructure but kept independent
-- so the two tabs don't fight over date ranges.
local mobSpellsCache         = nil
local mobSpellsCacheRange    = nil
local mobSpellsRangeMode     = 'today'   -- today | 24h | 7d | 30d | all | custom
local mobSpellsCustomDays    = 3
local mobSpellsSearch        = ''        -- mob name substring filter
local mobSpellsSelectedTs    = nil       -- which fight is drilled in

-- Refresh the Mob Spells archive cache if the date range changed.
-- Uses the same loadArchive() infrastructure as the History tab,
-- but maintains its own cache so the two tabs operate independently.
local function refreshMobSpellsArchiveIfNeeded()
    local rangeKey = mobSpellsRangeMode .. ':' .. tostring(mobSpellsCustomDays)
    if mobSpellsNeedsRefresh or mobSpellsCacheRange ~= rangeKey then
        local now = os.time()
        local startTs, endTs = nil, nil
        if mobSpellsRangeMode == 'today' then
            -- Midnight today, local time.
            local t = os.date('*t', now)
            t.hour, t.min, t.sec = 0, 0, 0
            startTs = os.time(t)
        elseif mobSpellsRangeMode == '24h' then
            startTs = now - 24*3600
        elseif mobSpellsRangeMode == '7d' then
            startTs = now - 7*24*3600
        elseif mobSpellsRangeMode == '30d' then
            startTs = now - 30*24*3600
        elseif mobSpellsRangeMode == 'custom' then
            startTs = now - (mobSpellsCustomDays or 3)*24*3600
        end
        -- 'all' leaves both nil for an unbounded fetch.
        mobSpellsCache = loadArchive(startTs, endTs)
        mobSpellsCacheRange = rangeKey
        mobSpellsNeedsRefresh = false
    end
end

local function drawMobsTab()
    if not isDriver() then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'Mob Spells view is only available on driver characters.')
        return
    end

    refreshMobSpellsArchiveIfNeeded()

    -- Date range buttons. Active mode renders bright green for
    -- visual at-a-glance state.
    ImGui.Text('Date range:')
    ImGui.SameLine()
    local function rangeBtn(label, mode)
        local variant = (mobSpellsRangeMode == mode) and 'active' or 'secondary'
        if btn(label .. '##mobs_range_' .. mode, variant, 0, 0) then
            mobSpellsRangeMode = mode
            mobSpellsNeedsRefresh = true
        end
        ImGui.SameLine()
    end
    rangeBtn('Today',    'today')
    rangeBtn('Last 24h', '24h')
    rangeBtn('Last 7d',  '7d')
    rangeBtn('Last 30d', '30d')
    rangeBtn('All',      'all')
    do
        local variant = (mobSpellsRangeMode == 'custom') and 'active' or 'secondary'
        if btn('Custom##mobs_range_custom', variant, 0, 0) then
            mobSpellsRangeMode = 'custom'
            mobSpellsNeedsRefresh = true
        end
    end
    if mobSpellsRangeMode == 'custom' then
        ImGui.SameLine()
        ImGui.SetNextItemWidth(80)
        local newDays, changed = ImGui.InputInt('days##mobs_days',
            mobSpellsCustomDays or 3, 1, 5)
        if changed then
            mobSpellsCustomDays = math.max(1, math.min(365, newDays))
            mobSpellsNeedsRefresh = true
        end
    end

    -- Mob name search filter via slash command (or by clearing).
    if btn('Refresh##mobs_refresh', 'secondary', 0, 0) then
        mobSpellsNeedsRefresh = true
    end
    ImGui.SameLine()

    local count = (mobSpellsCache and #mobSpellsCache) or 0

    -- Filter to fights that actually have mob spell data. No point
    -- showing melee-only fights here -- they'd just be empty rows.
    local filtered = {}
    if mobSpellsCache then
        for _, rec in ipairs(mobSpellsCache) do
            local mobSpells = rec.damage and rec.damage.mobSpells
            if mobSpells and next(mobSpells) ~= nil then
                -- Apply mob name search if any.
                local needle = (mobSpellsSearch ~= '' and mobSpellsSearch:lower()) or nil
                local mobName = rec.mob or ''
                if not needle or mobName:lower():find(needle, 1, true) then
                    table.insert(filtered, rec)
                end
            end
        end
    end

    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        string.format('%d fights with mob casts (of %d in range)',
            #filtered, count))

    if mobSpellsSearch ~= '' then
        ImGui.SameLine(0, 16)
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('Filter: "%s"', mobSpellsSearch))
        ImGui.SameLine()
        if btn('Clear##mobs_clearfilter', 'danger', 0, 0) then
            mobSpellsSearch = ''
        end
    end

    -- Mob name dropdown picker (combo of unique mobs in current results).
    do
        local seen = {}
        local mobList = {}
        for _, rec in ipairs(filtered) do
            local m = rec.mob
            if m and not seen[m] then
                seen[m] = true
                table.insert(mobList, m)
            end
        end
        table.sort(mobList, function(a, b) return a:lower() < b:lower() end)

        if #mobList > 0 then
            ImGui.Text('Pick mob:')
            ImGui.SameLine()
            ImGui.SetNextItemWidth(220)
            local previewLabel = (mobSpellsSearch ~= '') and mobSpellsSearch
                                  or '(pick a mob...)'
            if ImGui.BeginCombo('##mobspells_pick', previewLabel) then
                for _, m in ipairs(mobList) do
                    local isSelected = (m == mobSpellsSearch)
                    if ImGui.Selectable(m, isSelected) then
                        mobSpellsSearch = m
                    end
                    if isSelected then ImGui.SetItemDefaultFocus() end
                end
                ImGui.EndCombo()
            end
        end
    end

    ImGui.Separator()

    -- Two-pane layout.
    if ImGui.BeginTable('MobsLayout', 2,
                        bit32.bor(ImGuiTableFlags.Resizable,
                                  ImGuiTableFlags.BordersInner)) then
        ImGui.TableSetupColumn('list',    ImGuiTableColumnFlags.WidthStretch, 0.45)
        ImGui.TableSetupColumn('details', ImGuiTableColumnFlags.WidthStretch, 0.55)
        ImGui.TableNextRow()

        -- Left pane: list of archive fights with mob casts.
        ImGui.TableNextColumn()
        if ImGui.BeginTable('MobsFightList', 5,
                            bit32.bor(ImGuiTableFlags.Borders,
                                      ImGuiTableFlags.RowBg,
                                      ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit)) then
            ImGui.TableSetupColumn('Date',  ImGuiTableColumnFlags.WidthFixed, 88)
            ImGui.TableSetupColumn('Time',  ImGuiTableColumnFlags.WidthFixed, 60)
            ImGui.TableSetupColumn('Mob',   ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('Casts', ImGuiTableColumnFlags.WidthFixed, 50)
            ImGui.TableSetupColumn('Spells',ImGuiTableColumnFlags.WidthFixed, 50)
            ImGui.TableHeadersRow()

            -- Newest first.
            table.sort(filtered, function(a, b)
                return (a.ts or 0) > (b.ts or 0)
            end)

            for _, rec in ipairs(filtered) do
                local ts = rec.ts or 0
                local mobSpells = rec.damage and rec.damage.mobSpells or {}

                local totalCasts, uniqueSpells = 0, 0
                for _, sp in pairs(mobSpells) do
                    local n = (type(sp) == 'table') and (sp.count or 0) or sp
                    totalCasts = totalCasts + (n or 0)
                    uniqueSpells = uniqueSpells + 1
                end

                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.Text(os.date('%m/%d/%Y', ts))
                ImGui.TableNextColumn()
                ImGui.Text(os.date('%H:%M:%S', ts))
                ImGui.TableNextColumn()

                local mobLabel = (rec.mob or '?') .. '##mobsfight_' .. ts
                local mLvl = (rec.damage and rec.damage.mobLevel)
                            or (rec.fight and rec.fight.mobLevel)
                            or (rec.spells and rec.spells.mobLevel)
                local mr, mg, mb = mobLevelColor(mLvl)
                ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                if ImGui.Selectable(mobLabel, mobSpellsSelectedTs == ts,
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    mobSpellsSelectedTs = ts
                end
                ImGui.PopStyleColor()

                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                  tostring(totalCasts))
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                  tostring(uniqueSpells))
            end
            ImGui.EndTable()
        end

        -- Right pane: spell breakdown for selected fight.
        ImGui.TableNextColumn()

        local sel = nil
        if mobSpellsSelectedTs then
            for _, rec in ipairs(filtered) do
                if rec.ts == mobSpellsSelectedTs then sel = rec; break end
            end
        end

        if not sel then
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                'Click a fight on the left to see the mob\'s spell casts.')
        else
            local d = sel.damage or {}
            local mobSpells = d.mobSpells or {}
            local mr, mg, mb = mobLevelColor(d.mobLevel)
            ImGui.TextColored(mr, mg, mb, 1.0, sel.mob or '?')
            ImGui.SameLine(0, 12)
            local fightStart = d.started or sel.ts or os.time()
            local fightEnd   = d.ended or sel.ts or os.time()
            local dur = math.max(1, fightEnd - fightStart)
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                string.format('%ds fight, ended %s', dur,
                    os.date('%H:%M:%S', fightEnd)))
            ImGui.Separator()

            if next(mobSpells) == nil then
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                    'No spell casts recorded for this mob.')
            else
                -- Build sorted list: most-cast spell first.
                local rows = {}
                for spell, rec in pairs(mobSpells) do
                    if type(rec) == 'number' then
                        rec = { count = rec, casts = {} }
                    end
                    table.insert(rows, {
                        spell = spell,
                        count = rec.count or 0,
                        casts = rec.casts or {},
                    })
                end
                table.sort(rows, function(a, b)
                    if a.count ~= b.count then return a.count > b.count end
                    return a.spell:lower() < b.spell:lower()
                end)

                for _, r in ipairs(rows) do
                    local headerLabel = string.format('%s  -  %d cast%s##mobspell_%s',
                        r.spell, r.count, (r.count == 1) and '' or 's', r.spell)
                    ImGui.PushStyleColor(ImGuiCol.Text,
                        THEME.you[1], THEME.you[2], THEME.you[3], 1.0)
                    local opened = ImGui.TreeNode(headerLabel)
                    ImGui.PopStyleColor()
                    if opened then
                        if #r.casts == 0 then
                            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                                '    (no individual timestamps recorded)')
                        else
                            for idx, ts in ipairs(r.casts) do
                                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                                    string.format('    %d.', idx))
                                ImGui.SameLine()
                                ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                    os.date('%H:%M:%S', ts))
                                ImGui.SameLine()
                                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                                    string.format('(+%ds into fight)', ts - fightStart))
                            end
                        end
                        ImGui.TreePop()
                    end
                end

                ImGui.Spacing()
                if btn('Copy spell list##mobs_copy', 'secondary', 0, 0) then
                    local lines = { string.format('=== %s spells (%ds fight, %s) ===',
                        sel.mob or '?', dur,
                        os.date('%Y-%m-%d %H:%M:%S', fightEnd)) }
                    for _, r in ipairs(rows) do
                        table.insert(lines, string.format('  %s x %d',
                            r.spell, r.count))
                        if #r.casts > 0 then
                            for idx, ts in ipairs(r.casts) do
                                table.insert(lines, string.format('    %d. %s (+%ds)',
                                    idx, os.date('%H:%M:%S', ts), ts - fightStart))
                            end
                        end
                    end
                    copyToClipboard(table.concat(lines, '\n'))
                    print('\ag[HealTracker]\ax mob spell list copied to clipboard')
                end
            end
        end

        ImGui.EndTable()
    end
end

local function drawHistoryTab()
    if not isDriver() then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'History is only available on driver characters.')
        return
    end

    refreshArchiveIfNeeded()

    -- View mode picker. Determines what's shown in both the list
    -- (right column data) and the right-pane breakdown.
    --   'dps'    -> total damage per fight; right pane = damage table
    --   'heals'  -> total HP healed per fight; right pane = heal table
    --   'spells' -> total cast count per fight; right pane = spell list
    --   'all'    -> shows everything in the right pane
    ImGui.Text('View:')
    ImGui.SameLine()
    local function modeBtn(label, key)
        -- Bright green when this is the currently active mode; gray
        -- when not. Easy at-a-glance indicator.
        local variant = (archiveMode == key) and 'active' or 'secondary'
        if btn(label .. '##hist_mode_' .. key, variant, 0, 0) then
            archiveMode = key
        end
        ImGui.SameLine()
    end
    modeBtn('DPS',     'dps')
    modeBtn('Heals',   'heals')
    modeBtn('Spells',  'spells')
    modeBtn('All',     'all')
    ImGui.NewLine()

    -- Range picker.
    ImGui.Text('Date range:')
    ImGui.SameLine()
    local function rangeBtn(label, key)
        local variant = (archiveRange == key) and 'active' or 'secondary'
        if btn(label .. '##hist_range_' .. key, variant, 0, 0) then
            archiveRange = key
            archiveNeedsRefresh = true
        end
        ImGui.SameLine()
    end
    rangeBtn('Today',     'today')
    rangeBtn('Last 24h',  '24h')
    rangeBtn('Last 7d',   '7d')
    rangeBtn('Last 30d',  '30d')
    rangeBtn('All',       'all')
    rangeBtn('Custom',    'custom')
    ImGui.NewLine()

    if archiveRange == 'custom' then
        ImGui.Text('Last N days:')
        ImGui.SameLine()
        local newDays, ch = ImGui.InputInt('##hist_custom_days', archiveCustomDays, 1, 30)
        if ch then
            archiveCustomDays = math.max(1, newDays)
            archiveNeedsRefresh = true
        end
    end

    if btn('Refresh##hist_refresh', 'secondary', 0, 0) then
        archiveNeedsRefresh = true
    end
    ImGui.SameLine()

    -- Select all / Select none for the multi-select combine view.
    -- Each button highlights bright green when its state is currently
    -- "achieved" -- so "Select all" is green when every visible fight
    -- is checked, and "Select none" is green when nothing is checked.
    -- Gives at-a-glance feedback for what state the selection is in.
    local visibleCount = 0
    local checkedCount = 0
    do
        local needle = (historySearch ~= '' and historySearch:lower()) or nil
        for _, rec in ipairs(archiveCache or {}) do
            local mobName = rec.mob or ''
            if not needle or mobName:lower():find(needle, 1, true) then
                visibleCount = visibleCount + 1
                if archiveSelected[rec.ts or 0] then
                    checkedCount = checkedCount + 1
                end
            end
        end
    end
    local allChecked  = visibleCount > 0 and checkedCount == visibleCount
    local noneChecked = checkedCount == 0

    local selAllVariant  = allChecked  and 'active' or 'secondary'
    local selNoneVariant = noneChecked and 'active' or 'secondary'

    if btn('Select all##hist_selall', selAllVariant, 0, 0) then
        archiveSelected = {}
        local needle = (historySearch ~= '' and historySearch:lower()) or nil
        for _, rec in ipairs(archiveCache or {}) do
            local mobName = rec.mob or ''
            if rec.ts and (not needle or mobName:lower():find(needle, 1, true)) then
                archiveSelected[rec.ts] = true
            end
        end
    end
    ImGui.SameLine()
    if btn('Select none##hist_selnone', selNoneVariant, 0, 0) then
        archiveSelected = {}
    end
    ImGui.SameLine()

    -- Show how many fights are currently checked. Mirrors the
    -- "X selected" indicator on the DPS/Heals/Spells tabs.
    if checkedCount > 0 then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('%d selected', checkedCount))
        ImGui.SameLine()
    end

    -- Split-pets toggle (mirrors the DPS tab's). Affects how pets
    -- render in the damage breakdown table.
    local newSplit, splitChanged = ImGui.Checkbox(
        'Split pets from owner##hist_splitpets', config.splitPetsInDps == true)
    if splitChanged then
        config.splitPetsInDps = newSplit
        saveConfig()
    end

    local count = (archiveCache and #archiveCache) or 0
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        string.format('%d fights in range', count))

    -- Load-into-current-view button. Bulk-loads ALL filtered archive
    -- entries into the in-memory fights/damageFights/spellsFights
    -- arrays. This REPLACES current state.
    ImGui.SameLine(0, 16)
    if btn('Load filtered into current view##hist_load', 'amber', 0, 0) and count > 0 then
        fights, damageFights, spellsFights = {}, {}, {}
        for _, rec in ipairs(archiveCache) do
            table.insert(fights,       rec.fight  or emptyScope(rec.mob))
            table.insert(damageFights, rec.damage or emptyDamageScope(rec.mob))
            table.insert(spellsFights, rec.spells or emptySpellsScope(rec.mob))
        end
        clearFightSelection()
        print(string.format('\ag[HealTracker]\ax loaded %d archived fights into current view',
            #fights))
        print('  the active Heals/DPS/Spells tabs now show the loaded archive')
        print('  use \at/healtracker fights clear\ax to wipe and start fresh')
    end

    -- Mob name search filter. Independent from the date range -- both
    -- act as compound filters on the displayed list.
    historySearch = showSearchStatus(historySearch, 'history', uniqueMobsFromFights(archiveCache, 'mob'))

    ImGui.Separator()

    if count == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No archived fights in this range. The archive grows as fights are completed.')
        return
    end

    -- Choose the column header + value extractor based on mode.
    -- The list's "amount" column changes meaning per mode -- e.g.
    -- in heals mode it shows total HP healed instead of damage.
    local amtHeader, amtFn
    if archiveMode == 'heals' then
        amtHeader = 'Heals'
        amtFn = function(rec) return (rec.fight  and rec.fight.total)  or 0 end
    elseif archiveMode == 'spells' then
        amtHeader = 'Casts'
        amtFn = function(rec) return (rec.spells and rec.spells.total) or 0 end
    else  -- 'dps' or 'all'
        amtHeader = 'Dmg'
        amtFn = function(rec) return (rec.damage and rec.damage.total) or 0 end
    end

    -- Two-pane layout matching DPS tab: list left, details right.
    if ImGui.BeginTable('HistLayout', 2,
                        bit32.bor(ImGuiTableFlags.Resizable,
                                  ImGuiTableFlags.BordersInner)) then
        ImGui.TableSetupColumn('list', ImGuiTableColumnFlags.WidthStretch, 0.45)
        ImGui.TableSetupColumn('details', ImGuiTableColumnFlags.WidthStretch, 0.55)
        ImGui.TableNextRow()

        -- Left pane: list of archived fights.
        ImGui.TableNextColumn()
        if ImGui.BeginTable('HistList', 5,
                            bit32.bor(ImGuiTableFlags.Borders,
                                      ImGuiTableFlags.RowBg,
                                      ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit)) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 28)
            ImGui.TableSetupColumn('Date', ImGuiTableColumnFlags.WidthFixed, 90)
            ImGui.TableSetupColumn('Time', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn(amtHeader, ImGuiTableColumnFlags.WidthFixed, 80)

            -- Sortable header row.
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); sortHeader('Date',     historySort, 'when')
            ImGui.TableNextColumn(); sortHeader('Time',     historySort, 'when')
            ImGui.TableNextColumn(); sortHeader('Mob',      historySort, 'mob')
            ImGui.TableNextColumn(); sortHeader(amtHeader,  historySort, 'amount')

            -- Build a sorted + filtered index list for the archive.
            -- Note that archive records have a different shape from
            -- regular fights (use rec.ts/rec.mob instead of
            -- f.started/f.label) so we sort manually here rather than
            -- reusing sortedFightIndices.
            local sortedHist = {}
            for i = 1, #archiveCache do sortedHist[i] = i end
            local hcol  = historySort.col or 'when'
            local hdesc = (historySort.dir or 'desc') == 'desc'
            table.sort(sortedHist, function(a, b)
                local ra, rb = archiveCache[a], archiveCache[b]
                local va, vb
                if hcol == 'mob' then
                    va = (ra.mob or ''):lower()
                    vb = (rb.mob or ''):lower()
                elseif hcol == 'amount' then
                    va = amtFn(ra)
                    vb = amtFn(rb)
                else  -- 'when'
                    va = ra.ts or 0
                    vb = rb.ts or 0
                end
                if va == vb then return a < b end
                if hdesc then return va > vb end
                return va < vb
            end)
            -- Apply mob-name search filter.
            local needle = (historySearch ~= '' and historySearch:lower()) or nil
            for _, i in ipairs(sortedHist) do
                local rec = archiveCache[i]
                local mobName = rec.mob or ''
                if not needle or mobName:lower():find(needle, 1, true) then
                    local ts = rec.ts or 0
                    ImGui.TableNextRow()

                    -- Sel checkbox. Keyed by timestamp so selection
                    -- survives sort/filter changes.
                    ImGui.TableNextColumn()
                    local checked = archiveSelected[ts] or false
                    local newC, ch = ImGui.Checkbox('##hist_sel_' .. ts, checked)
                    if ch then archiveSelected[ts] = newC or nil end

                    ImGui.TableNextColumn(); ImGui.Text(os.date('%m/%d/%Y', ts))
                    ImGui.TableNextColumn(); ImGui.Text(os.date('%H:%M:%S', ts))
                    ImGui.TableNextColumn()
                    local mobLabel = (rec.mob or '?') .. '##histrow_' .. i
                    local mLvl = (rec.damage and rec.damage.mobLevel)
                                 or (rec.fight and rec.fight.mobLevel)
                                 or (rec.spells and rec.spells.mobLevel)
                    local mr, mg, mb = mobLevelColor(mLvl)
                    ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                    if ImGui.Selectable(mobLabel, archiveSelectedTs == ts,
                                        ImGuiSelectableFlags.SpanAllColumns) then
                        archiveSelectedTs = ts
                    end
                    ImGui.PopStyleColor()
                    ImGui.TableNextColumn()
                    -- Pick color based on what the View mode is
                    -- showing: yellow for damage/spells, baby blue
                    -- for heals.
                    local rowColor = THEME.valueDps
                    if archiveMode == 'heals' then
                        rowColor = THEME.valueHeal
                    end
                    ImGui.TextColored(rowColor[1], rowColor[2], rowColor[3], 1.0,
                                      fmtNum(amtFn(rec)))
                end
            end
            ImGui.EndTable()
        end

        -- Right pane: priority is combined view > drill-down.
        --   - If 2+ fights are checked, show the combined view with a
        --     copy-to-clipboard button.
        --   - Otherwise, show the drill-down for the singly-clicked
        --     fight (archiveSelectedTs).
        ImGui.TableNextColumn()

        -- Build the list of selected archive records.
        local selRecs = {}
        for _, rec in ipairs(archiveCache) do
            if rec.ts and archiveSelected[rec.ts] then
                table.insert(selRecs, rec)
            end
        end
        local selCount = #selRecs

        local showDps    = archiveMode == 'dps'    or archiveMode == 'all'
        local showHeals  = archiveMode == 'heals'  or archiveMode == 'all'
        local showSpells = archiveMode == 'spells' or archiveMode == 'all'

        if selCount >= 2 then
            -- COMBINED VIEW
            local cHeals, cDamage, cSpells = combineArchive(selRecs)

            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                string.format('Combined view: %d fights', selCount))

            ImGui.SameLine(0, 12)
            if btn('Copy##hist_copy_combined', 'secondary', 0, 0) then
                -- Build a multi-line text summary covering whichever
                -- mode sections are enabled. Falls through summaryText
                -- for heals (existing helper) and writes inline for
                -- damage/spells which don't have ready-made formatters.
                local lines = {}
                -- Header skipped when DPS is part of the report -- the
                -- gamparseReport line already starts with the mob label.
                local needHeader = not showDps or (cDamage.total or 0) == 0
                if needHeader then
                    table.insert(lines, string.format('=== Combined: %d fights ===', selCount))
                end

                if showDps and (cDamage.total or 0) > 0 then
                    -- Gamparse-style single-line report. Uses
                    -- "Combined: N fights" as the mob label.
                    local mobLabel = string.format('Combined: %d fights', selCount)
                    table.insert(lines, gamparseReport(cDamage, mobLabel))
                end

                if showHeals and (cHeals.total or 0) > 0 then
                    if #lines > 0 then table.insert(lines, '') end
                    table.insert(lines, summaryText(cHeals, 'combined'))
                end

                if showSpells and (cSpells.total or 0) > 0 then
                    if #lines > 0 then table.insert(lines, '') end
                    table.insert(lines, string.format(
                        'SPELLS  total_casts=%d', cSpells.total))
                    local srows = {}
                    for caster, cs in pairs(cSpells.stats or {}) do
                        table.insert(srows, { c = caster, t = cs.total or 0 })
                    end
                    table.sort(srows, function(a, b) return a.t > b.t end)
                    for _, r in ipairs(srows) do
                        table.insert(lines, string.format('  %s: %d', r.c, r.t))
                    end
                end

                copyToClipboard(table.concat(lines, '\n'))
                print('\ag[HealTracker]\ax combined report copied to clipboard')
            end

            -- Damage section.
            if showDps and (cDamage.total or 0) > 0 then
                local dur = math.max(1, cDamage.totalDuration or 0)
                ImGui.Text(string.format('Total dmg : %s', fmtNum(cDamage.total or 0)))
                ImGui.Text(string.format('Hits      : %d', cDamage.count or 0))
                ImGui.Text(string.format('Combined duration : %ds', dur))
                ImGui.Text(string.format('Group DPS : %s', fmtNum((cDamage.total or 0) / dur)))
                ImGui.Separator()
                ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                    'Damage breakdown')
                drawDamageCharTable(cDamage, 'histcombdmg', dur)
            end

            -- Heals section.
            if showHeals and (cHeals.total or 0) > 0 then
                if showDps then ImGui.Separator() end
                ImGui.Text(string.format('Total HP healed : %s', fmtNum(cHeals.total)))
                ImGui.Text(string.format('Heal events     : %d', cHeals.count or 0))
                ImGui.Separator()
                ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                    'Heal breakdown')
                drawCharTable(cHeals, 'histcombheal')
            end

            -- Spells section.
            if showSpells and (cSpells.total or 0) > 0 then
                if showDps or showHeals then ImGui.Separator() end
                ImGui.Text(string.format('Total spell casts : %d', cSpells.total))
                ImGui.Separator()
                ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                    'Spell breakdown')
                drawSpellsDetail(cSpells, 'histcombsp')
            end
        else
            -- SINGLE FIGHT DRILL-DOWN
            local selRec = nil
            if archiveSelectedTs then
                for _, r in ipairs(archiveCache) do
                    if r.ts == archiveSelectedTs then selRec = r; break end
                end
            end

            if not selRec then
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                    'Click a fight on the left to drill in, or check 2+ fights to combine.')
            else
                local d = selRec.damage
                local h = selRec.fight
                local s = selRec.spells

                ImGui.Text(string.format('Mob   : %s', selRec.mob or '?'))
                ImGui.Text(string.format('Date  : %s', os.date('%Y-%m-%d %H:%M:%S', selRec.ts)))

                ImGui.SameLine(0, 12)
                if btn('Copy##hist_copy_single', 'secondary', 0, 0) then
                    local lines = {}
                    -- If DPS is included, gamparseReport already has
                    -- the mob name as the leading token, so we skip
                    -- the "=== Mob @ Date ===" header in that case to
                    -- avoid duplication.
                    local needHeader = not showDps or not d or (d.total or 0) == 0
                    if needHeader then
                        table.insert(lines, string.format(
                            '=== %s @ %s ===',
                            selRec.mob or '?',
                            os.date('%Y-%m-%d %H:%M:%S', selRec.ts)))
                    end
                    if showDps and d and (d.total or 0) > 0 then
                        table.insert(lines,
                            gamparseReport(d, selRec.mob or 'fight'))
                    end
                    if showHeals and h and (h.total or 0) > 0 then
                        if #lines > 0 then table.insert(lines, '') end
                        table.insert(lines, summaryText(h, selRec.mob or 'fight'))
                    end
                    if showSpells and s and (s.total or 0) > 0 then
                        if #lines > 0 then table.insert(lines, '') end
                        table.insert(lines, string.format(
                            'SPELLS  total_casts=%d', s.total))
                    end
                    copyToClipboard(table.concat(lines, '\n'))
                    print('\ag[HealTracker]\ax fight report copied to clipboard')
                end

                -- DPS section.
                if showDps and d then
                    local dur = math.max(1, (d.ended or d.started or 0) - (d.started or 0))
                    ImGui.Text(string.format('Duration  : %ds', dur))
                    ImGui.Text(string.format('Total dmg : %s', fmtNum(d.total or 0)))
                    ImGui.Text(string.format('Hits      : %d', d.count or 0))
                    ImGui.Text(string.format('Group DPS : %s', fmtNum((d.total or 0) / dur)))
                    ImGui.Separator()
                    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                        'Damage breakdown')
                    drawDamageCharTable(d, 'histdmg' .. selRec.ts, dur)
                end

                -- Heals section.
                if showHeals and h and h.total and h.total > 0 then
                    if showDps then ImGui.Separator() end
                    ImGui.Text(string.format('Total HP healed : %s', fmtNum(h.total)))
                    ImGui.Text(string.format('Heal events     : %d', h.count or 0))
                    ImGui.Text(string.format('Largest single  : %s', fmtNum(h.max or 0)))
                    ImGui.Separator()
                    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                        'Heal breakdown')
                    drawCharTable(h, 'histheal' .. selRec.ts)
                elseif showHeals and not (h and h.total and h.total > 0) then
                    if showDps then ImGui.Separator() end
                    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                        'No heal data recorded for this fight.')
                end

                -- Spells section.
                if showSpells and s and s.total and s.total > 0 then
                    if showDps or showHeals then ImGui.Separator() end
                    ImGui.Text(string.format('Total spell casts : %d', s.total))
                    ImGui.Separator()
                    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                        'Spell breakdown')
                    drawSpellsDetail(s, 'histsp' .. selRec.ts)
                elseif showSpells and not (s and s.total and s.total > 0) then
                    if showDps or showHeals then ImGui.Separator() end
                    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                        'No spell data recorded for this fight.')
                end
            end
        end

        ImGui.EndTable()
    end
end

local function drawSettingsTab()
    ImGui.Text('Drivers (boxes that show this window):')
    if #(config.drivers or {}) > 0 then
        ImGui.TextColored(0.6, 1.0, 0.6, 1.0, '  ' .. table.concat(config.drivers, ', '))
    else
        ImGui.TextColored(1.0, 0.7, 0.4, 1.0, '  (none)')
    end
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Add a driver by running /healtracker driver on that character.')
    ImGui.Separator()

    local newAuto, changedAuto = ImGui.Checkbox(
        'Auto-reset session on each mob kill (snapshots a Fight entry)',
        config.autoResetOnKill)
    if changedAuto then
        config.autoResetOnKill = newAuto
        saveConfig()
    end

    ImGui.Separator()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Fight timeout')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'A fight starts on the first damage event and ends on a slain message')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'OR after this many seconds of no damage. 0 = only end on slain.')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Heals are only recorded while a fight is active.')

    ImGui.Text('Timeout (seconds, 0=off):')
    ImGui.SameLine()
    local newTo, changedTo = ImGui.InputInt('##timeoutSec',
        config.fightTimeoutSeconds or 8, 1, 5)
    if changedTo then
        config.fightTimeoutSeconds = math.max(0, newTo)
        saveConfig()
    end

    -- Live status badge so the user can see whether they're "in combat"
    -- according to the script's logic.
    if fightActive then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            'Status: IN COMBAT (recording)')
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'Status: idle (heals + damage are not being recorded)')
    end

    ImGui.Separator()

    ImGui.Text('Mini view columns:')
    ImGui.SameLine()
    local newCols, changedCols = ImGui.InputInt('##minicols', config.miniColumns or 2, 1, 1)
    if changedCols then
        config.miniColumns = math.max(1, math.min(3, newCols))
        saveConfig()
    end

    -- Mini view linger: how long the last fight stays visible on the
    -- collapsed bar after the fight ends. Useful for glancing at the
    -- bar right after a kill to see who topped the parse.
    ImGui.Text('Mini view linger (sec after fight ends):')
    ImGui.SameLine()
    local newLinger, changedLinger = ImGui.InputInt('##minilinger',
        config.miniLingerSeconds or 5, 1, 5)
    if changedLinger then
        config.miniLingerSeconds = math.max(0, math.min(300, newLinger))
        saveConfig()
    end
    ImGui.SameLine()
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        '(0 = clear immediately)')

    ImGui.Text('Min heal amount (skip below):')
    ImGui.SameLine()
    local newMin, changedM = ImGui.InputInt('##minheal', config.minHealAmount, 1, 10)
    if changedM then
        config.minHealAmount = math.max(0, newMin)
        saveConfig()
    end

    local newDbg, changedD = ImGui.Checkbox('Debug logging', config.debug)
    if changedD then config.debug = newDbg; saveConfig() end

    ImGui.Separator()
    if btn('Reset session totals##ht_settings_reset', 'danger', 0, 0) then
        actorBroadcast({ kind = 'reset_session' })
        resetSession()
    end
    ImGui.SameLine(0, 8)
    if btn('Clear ALL fight history##ht_settings_clear_fights', 'danger', 0, 0) then
        fights = {}
        damageFights = {}
        spellsFights = {}
        clearFightSelection()
        saveFights(true)
        saveDamage(true)
        saveSpells(true)
    end

    -- =========================================================
    -- Pet mappings UI
    -- =========================================================
    ImGui.Spacing()
    ImGui.Separator()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Pet -> Owner mappings')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Map named pets (e.g. "Hookerr") to their owner so their damage rolls into the owner row.')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Possessive-form pets ("Bob\'s pet") are auto-mapped and don\'t need entries here.')

    -- Show current mappings with per-row remove buttons.
    config.petOwners = config.petOwners or {}
    local mappingCount = 0
    for _ in pairs(config.petOwners) do mappingCount = mappingCount + 1 end

    if mappingCount > 0 then
        if ImGui.BeginTable('PetMapTable', 3,
                            bit32.bor(ImGuiTableFlags.Borders,
                                      ImGuiTableFlags.RowBg,
                                      ImGuiTableFlags.SizingFixedFit)) then
            ImGui.TableSetupColumn('Pet',    ImGuiTableColumnFlags.WidthStretch, 0.45)
            ImGui.TableSetupColumn('Owner',  ImGuiTableColumnFlags.WidthStretch, 0.45)
            ImGui.TableSetupColumn('',       ImGuiTableColumnFlags.WidthFixed, 70)
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text('Pet')
            ImGui.TableNextColumn(); ImGui.Text('Owner')
            ImGui.TableNextColumn(); ImGui.Text('')
            -- Sorted list for stable display.
            local pairs_list = {}
            for pet, owner in pairs(config.petOwners) do
                table.insert(pairs_list, { pet = pet, owner = owner })
            end
            table.sort(pairs_list, function(a, b) return a.pet:lower() < b.pet:lower() end)
            for _, p in ipairs(pairs_list) do
                ImGui.TableNextRow()
                ImGui.TableNextColumn(); ImGui.Text(p.pet)
                ImGui.TableNextColumn(); ImGui.Text(p.owner)
                ImGui.TableNextColumn()
                if btn('Remove##petmap_rm_' .. p.pet, 'danger', 0, 0) then
                    config.petOwners[p.pet] = nil
                    -- Also clean up knownChars: when we mapped this
                    -- pet originally, we added the pet name to
                    -- knownChars so the damage filter would pass.
                    -- Now that the mapping is gone, remove that entry
                    -- so the pet doesn't keep showing up in the Owner
                    -- dropdown as a "known PC" (which it isn't).
                    -- If the pet is ALSO a real PC for some reason,
                    -- the next group/raid TLO scan will re-add them.
                    knownChars[p.pet] = nil
                    saveConfig()
                end
            end
            ImGui.EndTable()
        end
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            '  (no pet mappings yet)')
    end

    -- Add new mapping. Two dropdowns:
    --   1. Pick an unmapped attacker name from the current/recent
    --      damage data -- typically a candidate pet that's showing up
    --      under its own name instead of the owner.
    --   2. Pick an owner from the known characters list.
    ImGui.Spacing()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Add new mapping:')

    -- Build unmapped-attacker candidate list. Two sources:
    --   1. unmappedDamage table -- attackers whose damage was filtered
    --      out as non-PC. These are the most-needed-mapping cases
    --      (named pets that haven't been mapped yet).
    --   2. damageFights -- attackers whose damage IS being recorded
    --      but who aren't already known/mapped. Edge case: damage
    --      from someone the script promoted to knownChars before the
    --      user mapped them.
    -- Both sources are filtered to exclude known players, mapped pets,
    -- and possessive-form names (auto-attributed).
    local petCandidates = {}
    do
        local seen = {}
        local function consider(name)
            if not name or name == '' then return end
            if seen[name] then return end
            -- Skip known players. They aren't pets.
            if knownChars[name] then return end
            -- Skip already-mapped pets.
            if config.petOwners[name] then return end
            -- Skip possessive-form pets. Auto-attribution handles them.
            if name:match("[`']s%s") then return end
            seen[name] = true
            table.insert(petCandidates, name)
        end
        -- Primary source: dropped damage attackers.
        for atk, _ in pairs(unmappedDamage) do
            consider(atk)
        end
        -- Secondary: live damage table.
        for _, fight in ipairs(damageFights or {}) do
            for atk, _ in pairs(fight.stats or {}) do
                consider(atk)
            end
        end
        table.sort(petCandidates, function(a, b) return a:lower() < b:lower() end)
    end

    -- Build owner candidate list (known characters from group/raid).
    -- Exclude names that are currently mapped AS pets -- those aren't
    -- valid owners. Also exclude any name that's CURRENTLY in the pet
    -- candidate list (an unmapped pet) since it shouldn't be picked
    -- as an owner of itself.
    local ownerCandidates = {}
    do
        local excluded = {}
        for petName, _ in pairs(config.petOwners or {}) do
            excluded[petName] = true
        end
        for _, petName in ipairs(petCandidates) do
            excluded[petName] = true
        end
        -- Also exclude anything in unmappedDamage. These are names that
        -- have appeared in damage events but were filtered out as
        -- non-PCs -- so they're pet candidates by definition. Don't
        -- offer them as owner choices.
        for petName, _ in pairs(unmappedDamage or {}) do
            excluded[petName] = true
        end
        local seen = {}
        for name, _ in pairs(knownChars) do
            if name and name ~= '' and not seen[name] and not excluded[name] then
                seen[name] = true
                table.insert(ownerCandidates, name)
            end
        end
        table.sort(ownerCandidates, function(a, b) return a:lower() < b:lower() end)
    end

    -- Pet picker dropdown. Uses BeginCombo+Selectable for unambiguous
    -- string-based picks (avoids 0-vs-1-based index issues).
    local pickedPet = nil
    do
        local previewLabel = '(pick a pet name...)'
        for petName, ownerName in pairs(config.petOwners or {}) do end
        if _petMapPetName and _petMapPetName ~= '' then
            previewLabel = _petMapPetName
        end
        ImGui.Text('Pet:')
        ImGui.SameLine()
        ImGui.SetNextItemWidth(180)
        if ImGui.BeginCombo('##petmap_pet', previewLabel) then
            for _, n in ipairs(petCandidates) do
                local isSelected = (_petMapPetName == n)
                if ImGui.Selectable(n, isSelected) then
                    _petMapPetName = n
                end
                if isSelected then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
        pickedPet = _petMapPetName
    end

    ImGui.SameLine()

    -- Owner picker dropdown.
    local pickedOwner = nil
    do
        local previewLabel = '(pick an owner...)'
        if _petMapOwnerName and _petMapOwnerName ~= '' then
            previewLabel = _petMapOwnerName
        end
        ImGui.Text('Owner:')
        ImGui.SameLine()
        ImGui.SetNextItemWidth(180)
        if ImGui.BeginCombo('##petmap_owner', previewLabel) then
            for _, n in ipairs(ownerCandidates) do
                local isSelected = (_petMapOwnerName == n)
                if ImGui.Selectable(n, isSelected) then
                    _petMapOwnerName = n
                end
                if isSelected then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
        pickedOwner = _petMapOwnerName
    end

    ImGui.SameLine()

    local canAdd = pickedPet ~= nil and pickedPet ~= '' and pickedOwner ~= nil and pickedOwner ~= ''
    if canAdd then
        if btn('Add mapping##petmap_add', 'success', 0, 0) then
            config.petOwners[pickedPet] = pickedOwner
            saveConfig()
            knownChars[pickedPet] = true
            knownChars[pickedOwner] = true
            -- Once mapped, remove from unmappedDamage so it stops
            -- appearing in the candidate dropdown.
            unmappedDamage[pickedPet] = nil
            print(string.format('\ag[HealTracker]\ax mapped pet \at%s\ax -> owner \at%s\ax',
                pickedPet, pickedOwner))
            _petMapPetIdx = 0
            _petMapOwnerIdx = 0
            _petMapPetName = nil
            _petMapOwnerName = nil
        end
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            '(pick both pet and owner above)')
    end

    if #petCandidates == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No unmapped pet candidates found. Pets show up here after they appear in damage events.')
    end
end

local function drawFull()
    ImGui.SetNextWindowSize(720, 540, ImGuiCond.FirstUseEver)
    local open, shouldDraw = ImGui.Begin('Heal Tracker###HealTrackerFull', config.windowOpen)

    if open == false then
        config.windowOpen = false
    end

    -- Wrap the body in pcall. If anything inside errors (Lua-side
    -- error, missing constant, etc.) we still need ImGui.End() to
    -- run, otherwise ImGui aborts with "Missing End()" and pauses
    -- the entire overlay. Catching errors here keeps the next frame
    -- recoverable.
    pcall(function()
        if shouldDraw and config.windowOpen then
            if btn('- Mini##ht_minimize', 'amber', 0, 0) then
                config.miniMode = true
                saveConfig()
            end
            ImGui.SameLine()
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                '(collapse to floating bar)')

            if ImGui.BeginTabBar('HealTrackerTabs') then
                -- Tab persistence: ImGui sometimes resets the active tab
                -- to the first one (Session) when the tab bar is rebuilt --
                -- e.g. after a fight ends and the count in the tab label
                -- changes. To prevent this we track the user's tab choice
                -- and force-select it on any frame where we detect a
                -- change (fight count went up).
                --
                -- ImGuiTabItemFlags_SetSelected = 2 (raw numeric value used
                -- because ImGuiTabItemFlags.SetSelected may not be exposed
                -- in all MQ ImGui Lua binding versions).
                local TAB_FLAG_NONE = 0
                local TAB_FLAG_SET_SELECTED = 2

                local lastTab = config.lastTab or 'session'
                local needsRestore = config._restoreTab
                                     or htLastFightCount ~= #fights
                                     or htLastDmgCount   ~= #damageFights
                                     or htLastSpCount    ~= #spellsFights
                htLastFightCount = #fights
                htLastDmgCount   = #damageFights
                htLastSpCount    = #spellsFights

                local function flagsFor(name)
                    if needsRestore and lastTab == name then
                        return TAB_FLAG_SET_SELECTED
                    end
                    return TAB_FLAG_NONE
                end

                -- Each tab is wrapped individually so an error in ONE
                -- tab's body doesn't skip the EndTabBar call below. If
                -- a tab body errors, we still call EndTabItem for it
                -- (because BeginTabItem returned true and we owe the
                -- matching End) and continue to the next tab.
                local function tab(label, key, drawFn)
                    if ImGui.BeginTabItem(label, flagsFor(key)) then
                        if not needsRestore then config.lastTab = key end
                        local ok, err = pcall(drawFn)
                        if not ok then
                            -- Always print tab errors so the user can
                            -- see what's actually wrong rather than
                            -- just a generic "Missing End()" message.
                            -- The tab content for this frame is broken
                            -- but EndTabItem still runs below so the
                            -- tab bar stays balanced.
                            ImGui.TextColored(1.0, 0.4, 0.4, 1.0,
                                'Tab render error: ' .. tostring(err))
                        end
                        ImGui.EndTabItem()
                    end
                end

                tab(string.format('Heals (%d)##ht_heals',  #fights),       'heals',   drawFightsTab)
                tab(string.format('DPS (%d)##ht_dps',      #damageFights), 'dps',     drawDpsTab)
                tab(string.format('Spells (%d)##ht_spells',#spellsFights), 'spells',  drawSpellsTab)
                tab(string.format('Mob Spells (%d)##ht_mobs', #damageFights), 'mobs',    drawMobsTab)
                tab('History##ht_history',                                 'history', drawHistoryTab)
                tab('Session##ht_session',                                 'session', drawSessionTab)
                tab('Settings##ht_settings',                               'settings',drawSettingsTab)

                -- Clear one-shot restore flag.
                config._restoreTab = false
                ImGui.EndTabBar()
            end
        end
    end)  -- close pcall around the body

    ImGui.End()
end

drawWindow = function()
    if shuttingDown then return end
    if not config.windowOpen then return end
    if not isDriver() then return end
    if config.miniMode then drawMini() else drawFull() end
end

-- =============================================================================
-- Cleanup -- runs when the script exits cleanly. On /lua stop, MQ aborts
-- the mq.delay coroutine and the script terminates immediately --
-- cleanup() may not run at all. So we keep this minimal: just set the
-- shutdown flag so any in-flight callbacks return early. Do NOT do
-- file I/O, do NOT print anything, do NOT call any MQ APIs. Anything
-- that touches MQ during teardown is a vsprintf_s_l crash waiting to
-- happen.
-- =============================================================================

local function cleanup()
    shuttingDown = true
end

-- =============================================================================
-- Boot
-- =============================================================================

local function boot()
    loadConfig()
    if isDriver() then
        loadFights()
        loadDamage()
        loadSpells()
    end
    bindLocalEvents()
    setupActor()
    -- LuaJIT (which MQ uses) provides unpack as a global; standard Lua
    -- 5.2+ provides table.unpack. Use whichever exists.
    local _unpack = table.unpack or unpack

    mq.bind('/healtracker', function(...)
        local n = select('#', ...)
        local args = {...}
        pcall(function() slashCmd(_unpack(args, 1, n)) end)
    end)

    if isDriver() then
        config.windowOpen = true
        ensureImGuiRegistered()
        print(string.format('\ag[HealTracker]\ax loaded for \aw%s\ax (\agDRIVER\ax mode)', MyName))
        print(string.format('\ag[HealTracker]\ax loaded %d past fights from disk', #fights))
        -- Prime the knownChars set from the Group TLO so back-line
        -- casters are recognized immediately, before any heals fire.
        refreshKnownCharsFromGroup()
    else
        print(string.format('\ag[HealTracker]\ax loaded for \aw%s\ax (reporter mode -- silent)', MyName))
        if #(config.drivers or {}) == 0 then
            print('\ay[HealTracker]\ax no drivers set. Run \at/healtracker driver\ax on your main.')
        end
    end
end

boot()

while M.running do
    mq.doevents()
    checkFightTimeout()
    refreshKnownCharsFromGroup()
    flushFightsIfDirty()
    flushDamageIfDirty()
    flushSpellsIfDirty()
    mq.delay(50)
end

cleanup()
