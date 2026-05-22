--[[
   ============================================================================
   heal_tracker_bridge.lua  -  MQ2HealParse plugin -> heal_tracker.lua bridge
   ============================================================================

   What this is
   ------------
   A thin shim that lets the native MQ2HealParse plugin feed your existing
   heal_tracker.lua's UI, fight tracking, persistence, and Actor broadcasts.

   How it works
   ------------
   The MQ2HealParse plugin sees every combat line as EQ generates it (via
   OnIncomingChat) and parses it in native C++ -- ~50x faster than the Lua
   path. Each parsed event is emitted as a tagged chat line in this format:

       /hpevt|<kind>|key1=value1|key2=value2|...

   This bridge registers one mq.event() that captures those lines, parses
   the key=value payload, and calls into your existing heal_tracker hooks:

       heal       -> recordHeal(target, healer, amount)
       damage     -> recordDamage(attacker, target, amount, type)
       spell_cast -> recordSpellCast(caster, spell)
       kill       -> onKill('PLUGIN_KILL', mob)

   All the heavy lifting -- file IO, pattern matching, spawn lookups --
   happens in the plugin. The Lua just does the cheap aggregation and UI.

   When the plugin is driving events, the Lua log tailer is disabled
   (config.useLogParser = false) to avoid double-counting -- both paths
   would otherwise feed the same combat lines.

   Install
   -------
   Drop this file in your MQ Lua dir next to heal_tracker.lua. The
   integration in heal_tracker.lua (added automatically when you applied
   the patches I sent) does:

       _G._ht_bridge = require('heal_tracker_bridge')
       _G._ht_bridge.install({ ... hooks ... })
============================================================================
]]

local mq = require('mq')

local M = {}

-- ---------------------------------------------------------------------------
-- Escape decoding. The plugin escapes | and = inside values so the kv parser
-- can rely on those delimiters. We reverse that here.
-- ---------------------------------------------------------------------------
local function unescape(v)
    if not v then return '' end
    v = v:gsub('%%7C', '|')
    v = v:gsub('%%3D', '=')
    return v
end

-- ---------------------------------------------------------------------------
-- Parse "key1=value1|key2=value2|..." into a table.
-- ---------------------------------------------------------------------------
local function parseKv(s)
    local out = {}
    for part in s:gmatch('[^|]+') do
        local k, v = part:match('^([^=]+)=(.*)$')
        if k then out[k] = unescape(v) end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- State -- hook table set by install().
-- ---------------------------------------------------------------------------
local hooks = nil

-- ---------------------------------------------------------------------------
-- Stats (for the /healparse_bridge debug command).
-- ---------------------------------------------------------------------------
local stats = {
    heal_events    = 0,
    damage_events  = 0,
    spell_events   = 0,
    kill_events    = 0,
    parse_errors   = 0,
    last_event_ms  = 0,
}

-- ---------------------------------------------------------------------------
-- Dispatcher. Each plugin event lands here.
-- Format: "<kind>|<k=v>|<k=v>|..."
-- (No "/hpevt|" prefix -- the chat-line protocol was replaced with a
-- direct in-memory queue drained via the HealParse.Drain TLO.)
-- ---------------------------------------------------------------------------
local function dispatch_raw(line)
    if not hooks then return end
    stats.last_event_ms = (mq.gettime and mq.gettime()) or 0

    local kind, kvs = line:match('^([^|]+)|(.*)$')
    if not kind then
        kind = line
        kvs  = ''
    end
    local data = parseKv(kvs)

    if kind == 'heal' then
        local amount = tonumber(data.amount) or 0
        if amount <= 0 then return end
        if hooks.recordHeal then
            -- The plugin already filters out heals below the configured
            -- min, but we double-check here in case the user changed
            -- config.minHealAmount in Lua after plugin load.
            local minHeal = (hooks.config and hooks.config.minHealAmount) or 1
            if amount < minHeal then return end
            local ok = pcall(hooks.recordHeal,
                             data.target or 'unknown',
                             data.healer or 'unknown',
                             amount)
            if ok then stats.heal_events = stats.heal_events + 1
            else stats.parse_errors = stats.parse_errors + 1 end
        end

    elseif kind == 'damage' then
        -- Damage is driver-only. Non-drivers ignore damage events; the
        -- driver aggregates damage from EVERYONE in zone (because EQ's log
        -- on the driver's box shows all combat that character witnesses).
        if hooks.isDriver and not hooks.isDriver() then return end
        local amount = tonumber(data.amount) or 0
        if amount <= 0 then return end
        if hooks.recordDamage then
            local t = data.type or 'melee'
            -- Normalize 'nonmelee' (plugin) to 'spell' (Lua expects this).
            if t == 'nonmelee' then t = 'spell' end
            local ok = pcall(hooks.recordDamage,
                             data.attacker or 'unknown',
                             data.target   or 'unknown',
                             amount, t)
            if ok then stats.damage_events = stats.damage_events + 1
            else stats.parse_errors = stats.parse_errors + 1 end
        end

    elseif kind == 'spell_cast' then
        if hooks.isDriver and not hooks.isDriver() then return end
        if hooks.recordSpellCast then
            local ok = pcall(hooks.recordSpellCast,
                             data.caster or 'unknown',
                             data.spell  or 'unknown')
            if ok then stats.spell_events = stats.spell_events + 1
            else stats.parse_errors = stats.parse_errors + 1 end
        end

    elseif kind == 'kill' then
        if hooks.isDriver and not hooks.isDriver() then return end
        if hooks.onKill then
            local ok = pcall(hooks.onKill, 'PLUGIN_KILL', data.mob or '?')
            if ok then stats.kill_events = stats.kill_events + 1
            else stats.parse_errors = stats.parse_errors + 1 end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Public: drain pending plugin events. Call from heal_tracker.lua's main
-- loop every iteration. Pulls up to maxEvents events from the plugin's
-- in-memory queue via ${HealParse.Drain[N]} and dispatches them through
-- recordHeal/recordDamage/etc.
--
-- This replaces the original mq.event-based design which emitted events
-- via WriteChatColor. That worked but every event line appeared in the
-- MQ debug chat window (the EQ chat filter only catches EQ chat windows,
-- not MQ's own console). The new design uses an in-memory queue with no
-- chat-stream involvement, so nothing spams anywhere.
-- ---------------------------------------------------------------------------
function M.drain(maxEvents)
    if not hooks then return 0 end
    maxEvents = maxEvents or 256

    local payload
    local ok = pcall(function()
        payload = mq.TLO.HealParse.Drain(maxEvents)()
    end)
    if not ok or not payload or payload == '' then return 0 end

    local processed = 0
    -- Events are joined by '\n'. Each is "kind|k=v|k=v|...".
    for line in payload:gmatch('[^\n]+') do
        pcall(dispatch_raw, line)
        processed = processed + 1
    end
    return processed
end

-- ---------------------------------------------------------------------------
-- Public: install the bridge.
-- ---------------------------------------------------------------------------
function M.install(opts)
    hooks = opts or {}

    if M._installed then
        -- Already installed; just refresh hook table.
        return true
    end

    -- ------------------------------------------------------------------
    -- Fallback raw-slain listeners
    -- ------------------------------------------------------------------
    -- The plugin's ParseKill has filters that may drop some kill lines.
    -- These mq.event listeners hook the raw "slain" chat lines as a safety
    -- net. They run in PARALLEL to the plugin's kill events -- if the
    -- plugin already emitted a kill, calling onKill again is safe
    -- (snapshotFight is idempotent when the scope is already closed).
    if hooks.onKill and hooks.isDriver then
        mq.event('hp_raw_slain_you', '#1# has been slain by #2#!', function(_, slain, slayer)
            if not hooks.isDriver() then return end
            if not slain or slain == '' then return end
            slain = slain:gsub('^%s+', ''):gsub('%s+$', '')
            if slain == 'You' or slain == 'you' or slain == (hooks.MyName or '') then return end
            if slain:find("[`']s pet")           then return end
            if slain:find("[`']s warder")        then return end
            if slain:find("[`']s ward")          then return end
            if slain:find("[`']s swarm")         then return end
            if slain:find("[`']s doppelganger")  then return end
            if slain:find("animated corpse")     then return end
            if hooks.knownChars and hooks.knownChars[slain] then return end
            local ok = pcall(hooks.onKill, 'BRIDGE_RAW_KILL', slain)
            if ok then stats.kill_events = stats.kill_events + 1
            else stats.parse_errors = stats.parse_errors + 1 end
        end)

        mq.event('hp_raw_slain_self', 'You have slain #1#!', function(_, slain)
            if not hooks.isDriver() then return end
            if not slain or slain == '' then return end
            slain = slain:gsub('^%s+', ''):gsub('%s+$', '')
            local ok = pcall(hooks.onKill, 'BRIDGE_RAW_KILL', slain)
            if ok then stats.kill_events = stats.kill_events + 1
            else stats.parse_errors = stats.parse_errors + 1 end
        end)
    end

    M._installed = true

    -- Verify plugin is loaded and report status.
    local ok, plugin_on = pcall(function() return mq.TLO.HealParse.Enabled() end)
    if ok and plugin_on then
        print('\ag[HealTracker-Bridge]\ax installed; \atMQ2HealParse\ax plugin active')

        -- Disable the Lua log tailer to prevent double-counting. The plugin
        -- is now the single source of truth for combat events.
        if hooks.config then
            hooks.config.useLogParser = false
            print('\ag[HealTracker-Bridge]\ax Lua log tailer disabled (plugin is now parsing)')
        end
    else
        print('\ay[HealTracker-Bridge]\ax installed, but \arMQ2HealParse plugin not detected.\ax')
        print('\ay[HealTracker-Bridge]\ax run \at/plugin mq2healparse load\ax to enable native parsing.')
        print('\ay[HealTracker-Bridge]\ax (Falling back to the Lua log tailer.)')
    end

    -- Add a debug command so you can sanity-check the bridge is receiving
    -- events from the plugin.
    mq.bind('/htbridge', function(arg)
        local nowMs = (mq.gettime and mq.gettime()) or 0
        local sincelast = stats.last_event_ms > 0
                          and ((nowMs - stats.last_event_ms) / 1000) or -1
        print(string.format(
            '\at[HealTracker-Bridge]\ax events: heal=%d  damage=%d  spell=%d  kill=%d  errors=%d',
            stats.heal_events, stats.damage_events,
            stats.spell_events, stats.kill_events, stats.parse_errors))
        if sincelast >= 0 then
            print(string.format(
                '\at[HealTracker-Bridge]\ax last event: %.1fs ago', sincelast))
        else
            print('\at[HealTracker-Bridge]\ax no events received yet')
        end
        local okp, plugin_on = pcall(function() return mq.TLO.HealParse.Enabled() end)
        if okp then
            print(string.format(
                '\at[HealTracker-Bridge]\ax plugin: enabled=%s lines_seen=%s matched=%s events_posted=%s',
                tostring(plugin_on),
                tostring(mq.TLO.HealParse.LinesSeen()),
                tostring(mq.TLO.HealParse.LinesMatched()),
                tostring(mq.TLO.HealParse.EventsPosted())))
        else
            print('\at[HealTracker-Bridge]\ax plugin: NOT DETECTED')
        end
    end)

    return true
end

-- ---------------------------------------------------------------------------
-- Public: query plugin status from Lua.
-- ---------------------------------------------------------------------------
function M.pluginStatus()
    local s = {}
    pcall(function()
        s.enabled       = mq.TLO.HealParse.Enabled()
        s.linesSeen     = mq.TLO.HealParse.LinesSeen()
        s.linesMatched  = mq.TLO.HealParse.LinesMatched()
        s.eventsPosted  = mq.TLO.HealParse.EventsPosted()
        s.knownChars    = mq.TLO.HealParse.KnownChars()
        s.totalDamage   = mq.TLO.HealParse.TotalDamage()
        s.totalHeals    = mq.TLO.HealParse.TotalHeals()
    end)
    s.bridge = {
        heal_events   = stats.heal_events,
        damage_events = stats.damage_events,
        spell_events  = stats.spell_events,
        kill_events   = stats.kill_events,
        parse_errors  = stats.parse_errors,
    }
    return s
end

return M
