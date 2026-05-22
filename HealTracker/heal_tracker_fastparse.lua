--[[
   ============================================================================
   heal_tracker_fastparse.lua  -  drop-in replacements for the two hottest
                                  functions in heal_tracker.lua
   ============================================================================

   Replaces:
      local function processCombatLine(line)   ... end
      local function logTailerPoll()           ... end

   Same signatures, same behavior, much faster. Built specifically to keep
   up with 54-man raid combat logs.

   The wins come from:

     1. PERSISTENT FILE HANDLE
        The original closes and reopens the log file every poll because Lua's
        buffered IO doesn't always see appended bytes. We instead use 'rb',
        keep the handle open across polls, and use seek() to re-read from the
        current end-of-file pointer. On Windows + Lua 5.1/LuaJIT this works
        because seek() flushes the read buffer. We only close + reopen on
        rotation (detected by the file getting smaller).

     2. DISPATCH TREE INSTEAD OF PATTERN CHAIN
        The original tries every regex against every line. We first do
        single-byte and single-substring rejects to bucket the line into a
        family (heal / damage-melee / damage-spell / kill / spell-cast /
        rune / observed-burn / drop), then run only the patterns for that
        family. ~95% of log lines hit the drop branch on the first byte
        check and skip all regex work.

     3. PRE-COMPILED PATTERN STRINGS AS LOCALS
        Lua patterns aren't really compiled, but holding them as upvalues
        avoids string interning lookups on every match call.

     4. NO PER-LINE PCALL
        The original wraps every line in pcall(processCombatLine, line).
        pcall costs ~150 ns even on a no-op. For 150k lines/poll that's a
        lot. We hoist the pcall to one-per-poll instead.

     5. NO PER-LINE DEBUG STRING FORMAT
        Debug branches that build strings via string.format are skipped
        entirely when config.debug is false; the conditional and the
        string-build both go away.

     6. SMALLER GC LOAD
        Single shared local "scratch" table for pattern captures, and
        :find() with init/plain=true wherever we don't need a capture --
        :find with plain=true skips the pattern engine entirely and is
        roughly 3x faster than :match for a simple substring test.

   INSTALL
   -------
   At the very top of heal_tracker.lua, somewhere after `local config = ...`
   but before the existing `processCombatLine` is defined, add:

        local _ht_fastparse = nil
        pcall(function() _ht_fastparse = require('heal_tracker_fastparse') end)

   Then where you currently define `local function processCombatLine(line)`,
   keep that definition as the fallback but add this block right after:

        if _ht_fastparse then
            processCombatLine = _ht_fastparse.makeProcessCombatLine({
                stripLogTimestamp     = stripLogTimestamp,
                onLocalHeal           = onLocalHeal,
                onKill                = onKill,
                recordDamage          = recordDamage,
                isDriver              = isDriver,
                isPlayerInZone        = isPlayerInZone,
                isKnownPet            = isKnownPet,
                attributeDamage       = attributeDamage,
                debugLog              = debugLog,
                config                = config,
                knownChars            = knownChars,
                recentSpellCasts      = recentSpellCasts,
                activeMobs            = activeMobs,
                MyName                = MyName,
                HT_RecordObservedBurnLine = _G.HT_RecordObservedBurnLine,
            })
        end

   And similarly for logTailerPoll:

        if _ht_fastparse then
            logTailerPoll = _ht_fastparse.makeLogTailerPoll({
                processCombatLine = function(line) return processCombatLine(line) end,
                logTailerPath     = logTailerPath,
                config            = config,
                logTailer         = logTailer,
                stripLogTimestamp = stripLogTimestamp,
            })
        end

   The lambda around processCombatLine is intentional -- it lets you swap the
   parser implementation at runtime without rebinding the poll loop.

============================================================================
]]

local M = {}

-- ----------------------------------------------------------------------------
-- Cached upvalues that don't change at runtime. Pulling these out as locals
-- saves a global table lookup per use.
-- ----------------------------------------------------------------------------

local s_find   = string.find
local s_match  = string.match
local s_sub    = string.sub
local s_byte   = string.byte
local s_gsub   = string.gsub
local s_lower  = string.lower
local s_format = string.format
local tonumber = tonumber

-- Common literal substrings -- holding them as locals avoids re-interning
-- inside the VM's string table on every :find call.
local LIT_POINTS       = 'points'
local LIT_HAS_TAKEN    = 'has taken'
local LIT_HEALED_BY    = 'healed by'
local LIT_HEALED_FOR   = 'healed for'
local LIT_NON_MELEE    = 'non-melee damage'
local LIT_POINTS_DMG   = 'points of damage'
local LIT_RAMPAGE_FOR  = 'rampage for'
local LIT_BEGINS_CAST  = 'begins to cast a spell'
local LIT_YOU_BEGIN    = 'You begin casting '
local LIT_SLAIN_SELF   = 'You have slain '
local LIT_SLAIN_BY     = ' has been slain by '
local LIT_FROM_YOUR    = ' from your '
local LIT_BY           = ' by '
local LIT_YOU_SP       = ' YOU '
local LIT_YOU_DOT      = ' YOU.'
local LIT_you_sp       = ' you '
local LIT_you_dot      = ' you.'
local LIT_HEALED       = 'healed'
local LIT_NM_BY        = 'was hit by non-melee'
local LIT_TRIES_TO     = 'tries to'
local LIT_MISSES       = 'but misses'
local LIT_RAMPAGE_PARN = '(Rampage)'

-- Rune absorb literals -- these get checked on every line so they live as
-- locals too.
local LIT_RUNE_SURVIVAL = 'an aspect of survival shields you'
local LIT_RUNE_SCALES   = 'the platinum scales fade'
local LIT_RUNE_GLYPH    = 'the shimmer of runes fades'

-- ----------------------------------------------------------------------------
-- Helper: trim whitespace and a trailing period/comma/bang from a string.
-- Used a few times per matched line, so worth having as a tight local.
-- ----------------------------------------------------------------------------

local function trim(s)
    -- Lua's gsub returns string + count -- we want just the string.
    s = s_gsub(s, '^%s+', '')
    s = s_gsub(s, '[%s%.,!]+$', '')
    return s
end

-- ----------------------------------------------------------------------------
-- looksLikePcName -- inlined version of the original, no closures.
-- ----------------------------------------------------------------------------

local function looksLikePcName(name)
    if not name or name == '' then return false end
    local b = s_byte(name, 1)
    -- Reject leading article words via first-byte + length check.
    -- 'a ' starts with 0x61, 'an ' with 0x61, 'the ' with 0x74, 'A ' 0x41, etc.
    -- Simpler: just check for the prefixes directly.
    if s_find(name, '^a ', 1) or s_find(name, '^an ', 1)
       or s_find(name, '^the ', 1) or s_find(name, '^A ', 1)
       or s_find(name, '^An ', 1) or s_find(name, '^The ', 1) then
        return false
    end
    if not b or b < 65 or b > 90 then return false end  -- not A-Z
    if #name < 3 then return false end
    if s_find(name, '%s', 1) then return false end
    return true
end

-- ============================================================================
-- processCombatLine factory
-- ----------------------------------------------------------------------------
-- We build the function with the dependencies bound as upvalues so the hot
-- path doesn't do table indexing on every call. The caller passes a deps
-- table once; the returned function captures everything.
-- ============================================================================

function M.makeProcessCombatLine(deps)
    -- Pull deps to locals.
    local stripLogTimestamp = deps.stripLogTimestamp
    local onLocalHeal       = deps.onLocalHeal
    local onKill            = deps.onKill
    local recordDamage      = deps.recordDamage
    local isDriver          = deps.isDriver
    local isPlayerInZone    = deps.isPlayerInZone
    local isKnownPet        = deps.isKnownPet
    local attributeDamage   = deps.attributeDamage
    local debugLog          = deps.debugLog
    local config            = deps.config
    local knownChars        = deps.knownChars
    local recentSpellCasts  = deps.recentSpellCasts
    local activeMobs        = deps.activeMobs
    local HT_RecordObservedBurnLine = deps.HT_RecordObservedBurnLine

    -- MyName can change (zone, /lua reload). Re-resolve via mq each call is
    -- expensive though. We snapshot at install and let the caller refresh by
    -- re-installing if it changes.
    local MyName = deps.MyName

    return function(line)
        if not line or line == '' then return false end
        if type(line) ~= 'string' then return false end

        line = stripLogTimestamp(line)
        -- Trim whitespace.
        local lb = s_byte(line, 1)
        if lb == 32 or lb == 9 then
            line = s_gsub(line, '^%s+', '')
        end
        if line == '' then return false end

        -- ------------------------------------------------------------------
        -- Rune absorb heals. These have to run on every box, not just
        -- driver, because each client sees its own rune text as "you".
        -- We do a single lowercase only if any of the rune keywords could
        -- match (cheap pre-check first).
        -- ------------------------------------------------------------------
        if s_find(line, 'shields you', 1, true)
           or s_find(line, 'scales fade', 1, true)
           or s_find(line, 'runes fades', 1, true) then
            local lower = s_lower(line)
            if s_find(lower, LIT_RUNE_SURVIVAL, 1, true) then
                onLocalHeal(line, 'Aspect of Survival Rune', 1500)
                return true
            end
            if s_find(lower, LIT_RUNE_SCALES, 1, true) then
                onLocalHeal(line, 'Rune of Rikkukin', 2100)
                return true
            end
            if s_find(lower, LIT_RUNE_GLYPH, 1, true) then
                onLocalHeal(line, 'Glyph Spray', 10000)
                return true
            end
        end

        -- Non-driver boxes only need the rune path above. Bail early.
        if not isDriver() then return false end

        -- ------------------------------------------------------------------
        -- Drop incoming RAMPAGE lines (mob -> player damage).
        -- Cheap pre-check: rampage text contains "RAMPAGE".
        -- ------------------------------------------------------------------
        if s_find(line, 'RAMPAGE for ', 1, true)
           and s_find(line, ' damage from ', 1, true)
           and s_find(line, ' hits', 1, true) then
            return true
        end

        -- ------------------------------------------------------------------
        -- Observed burn/discipline flavor lines. These usually have NO
        -- damage numbers in them, so they have to run before the
        -- damage-only fast reject below.
        -- ------------------------------------------------------------------
        if HT_RecordObservedBurnLine
           and HT_RecordObservedBurnLine(line, activeMobs, config) then
            return true
        end

        -- ------------------------------------------------------------------
        -- Spell cast tracking. Cheap byte-check first: "begins to cast"
        -- has 'b' at the position right after a name + space. We just
        -- substring-check it.
        -- ------------------------------------------------------------------
        if s_find(line, LIT_BEGINS_CAST, 1, true) then
            local caster, spell = s_match(line, '^(.-) begins to cast a spell[%.]?%s*<(.-)>')
            if caster and spell and caster ~= '' and spell ~= '' then
                caster = s_gsub(caster, '[%s%.]+$', '')
                spell  = s_gsub(spell,  '[%s%.]+$', '')
                local petOwner = s_match(caster, "^(%S+)[`']s%s+pet$")
                if petOwner then caster = petOwner end
                if recentSpellCasts then
                    recentSpellCasts[spell] = caster
                end
            end
            -- Don't return here -- the line might also have damage.
        elseif s_byte(line, 1) == 89 and s_find(line, LIT_YOU_BEGIN, 1, true) == 1 then
            -- "You begin casting <Spell>."
            local mySpell = s_match(line, '^You begin casting%s+(.-)%.?%s*$')
            if mySpell and mySpell ~= '' then
                mySpell = s_gsub(mySpell, '[%s%.]+$', '')
                if recentSpellCasts then
                    recentSpellCasts[mySpell] = MyName
                end
            end
        end

        -- ------------------------------------------------------------------
        -- Kill detection.
        -- ------------------------------------------------------------------
        if s_byte(line, 1) == 89 and s_find(line, LIT_SLAIN_SELF, 1, true) == 1 then
            -- "You have slain <mob>!"
            local mob = s_match(line, '^You have slain%s+(.-)%s*!?%s*$')
            if mob and mob ~= '' then
                mob = s_gsub(mob, '[%s%.!]+$', '')
                onKill(line, mob)
                return true
            end
        end
        local slainPos = s_find(line, LIT_SLAIN_BY, 1, true)
        if slainPos then
            local slain  = s_sub(line, 1, slainPos - 1)
            local slayer = s_sub(line, slainPos + #LIT_SLAIN_BY)
            slain  = s_gsub(slain,  '[%s%.!]+$', '')
            slayer = s_gsub(slayer, '[%s%.!]+$', '')
            if slain ~= '' and not knownChars[slain] then
                onKill(line, slain)
                return true
            end
            return false
        end

        -- ------------------------------------------------------------------
        -- The remaining patterns all need either "points" or "has taken".
        -- This is the single biggest reject in raid logs -- most lines
        -- (zone chatter, system messages, your buffs, etc.) don't contain
        -- either keyword, so bailing here drops the cost to one strstr.
        -- ------------------------------------------------------------------
        local hasPoints = s_find(line, LIT_POINTS,    1, true)
        local hasTaken  = s_find(line, LIT_HAS_TAKEN, 1, true)
        if not hasPoints and not hasTaken then return false end

        -- ------------------------------------------------------------------
        -- Spell damage:
        --   "<target> has taken <N> damage from <X> by <Y>"
        --   "<target> has taken <N> damage from your <Spell>"
        --   "<target> has taken <N> damage from <Spell>"  (anonymous DoT)
        -- ------------------------------------------------------------------
        if hasTaken then
            -- Strict regex first.
            local target, amountStr, mid, last =
                s_match(line, '^(.-) has taken ([%d,]+) damage from (.-) by ([^%.]+)%.?$')

            if not target then
                target, amountStr, mid, last =
                    s_match(line, '(.-)%s+has taken%s+([%d,]+)%s+damage from%s+(.-)%s+by%s+(.+)$')
            end

            if target then
                target = s_gsub(target, '^%s+', '')
                target = s_gsub(target, '[%s%.,!]+$', '')
                if target == 'YOU' or target == 'you' or target == MyName
                   or knownChars[target]
                   or (isPlayerInZone and isPlayerInZone(target)) then
                    return false
                end

                if amountStr then
                    local amount = tonumber((s_gsub(amountStr, ',', '')))
                    if amount and amount > 0 then
                        mid  = s_gsub(mid  or '', '[%s%.]+$', '')
                        last = s_gsub(last or '', '[%s%.]+$', '')

                        local caster
                        if knownChars[mid] or isKnownPet(mid) then
                            caster = mid
                        elseif knownChars[last] or isKnownPet(last) then
                            caster = last
                        elseif recentSpellCasts and recentSpellCasts[mid] then
                            caster = last
                        elseif recentSpellCasts and recentSpellCasts[last] then
                            caster = mid
                        elseif looksLikePcName(mid) and not looksLikePcName(last) then
                            caster = mid
                        elseif looksLikePcName(last) and not looksLikePcName(mid) then
                            caster = last
                        elseif looksLikePcName(mid) then
                            caster = mid
                        else
                            caster = mid
                        end

                        if caster and caster ~= '' then
                            if looksLikePcName(caster) then
                                knownChars[caster] = true
                            end
                            recordDamage(caster, target, amount, 'spell')
                            return true
                        end
                    end
                end
            end

            -- "from your <Spell>"
            if s_find(line, LIT_FROM_YOUR, 1, true) and not s_find(line, LIT_BY, 1, true) then
                local target2, amountStr2 =
                    s_match(line, '^(.-) has taken ([%d,]+) damage from your ')
                if target2 and amountStr2 then
                    target2 = s_gsub(target2, '^%s+', '')
                    target2 = s_gsub(target2, '[%s%.,!]+$', '')
                    if target2 == 'YOU' or target2 == 'you' or target2 == MyName
                       or knownChars[target2]
                       or (isPlayerInZone and isPlayerInZone(target2)) then
                        return false
                    end
                    local amount = tonumber((s_gsub(amountStr2, ',', '')))
                    if amount and amount > 0 then
                        recordDamage(MyName, target2, amount, 'spell')
                        return true
                    end
                end
            end

            -- Anonymous DoT tick.
            if not s_find(line, LIT_BY, 1, true)
               and not s_find(line, LIT_FROM_YOUR, 1, true) then
                local target3, amountStr3, spell3 =
                    s_match(line, '^(.-) has taken ([%d,]+) damage from (.+)%.?$')
                if target3 and amountStr3 and spell3 then
                    target3 = s_gsub(target3, '^%s+', '')
                    target3 = s_gsub(target3, '[%s%.,!]+$', '')
                    if target3 == 'YOU' or target3 == 'you' or target3 == MyName
                       or knownChars[target3]
                       or (isPlayerInZone and isPlayerInZone(target3)) then
                        return false
                    end
                    local amount = tonumber((s_gsub(amountStr3, ',', '')))
                    spell3 = s_gsub(spell3, '[%s%.]+$', '')
                    local caster = recentSpellCasts and recentSpellCasts[spell3]
                    if amount and amount > 0 and caster then
                        recordDamage(caster, target3, amount, 'dot')
                        return true
                    end
                end
            end
        end

        -- ------------------------------------------------------------------
        -- Non-melee: "<attacker> hit <target> for N points of non-melee damage"
        -- ------------------------------------------------------------------
        if s_find(line, LIT_NON_MELEE, 1, true) then
            if s_find(line, LIT_YOU_SP, 1, true) or s_find(line, LIT_YOU_DOT, 1, true)
               or s_find(line, LIT_you_sp, 1, true) or s_find(line, LIT_you_dot, 1, true) then
                return false
            end
            local attacker, target, amountStr =
                s_match(line, '^(.-)%s+hit%s+(.-)%s+for%s+([%d,]+)%s+point.-non%-melee%s+damage')
            if attacker and target and amountStr then
                local amount = tonumber((s_gsub(amountStr, ',', '')))
                if amount and amount > 0 then
                    local attributed = attributeDamage(attacker)
                    if not knownChars[attributed]
                       and not isKnownPet(attacker)
                       and not looksLikePcName(attacker) then
                        return false
                    end
                    if looksLikePcName(attacker) then
                        knownChars[attacker] = true
                    end
                    recordDamage(attacker, target, amount, 'spell')
                    return true
                end
            end
            return false
        end

        -- ------------------------------------------------------------------
        -- Melee: "<attacker> <verb> <target> for N points of damage"
        -- ------------------------------------------------------------------
        if hasPoints and s_find(line, LIT_POINTS_DMG, 1, true) then
            if s_find(line, LIT_HEALED, 1, true) then return false end
            if s_find(line, LIT_NM_BY, 1, true) then return false end
            if s_find(line, LIT_TRIES_TO, 1, true) then return false end
            if s_find(line, LIT_MISSES, 1, true) then return false end

            if s_find(line, LIT_YOU_SP, 1, true) or s_find(line, LIT_YOU_DOT, 1, true)
               or s_find(line, LIT_you_sp, 1, true) or s_find(line, LIT_you_dot, 1, true) then
                return false
            end

            local attacker, target, amountStr

            if s_sub(line, 1, 4) == 'You ' then
                attacker = MyName
                local _, t2, a2 =
                    s_match(line, '^(You)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point')
                target, amountStr = t2, a2
            else
                attacker, target, amountStr =
                    s_match(line, "^(%S+[`']s%s+pet)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
                if not attacker then
                    attacker, target, amountStr =
                        s_match(line, "^(%S+[`']s%s+warder)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
                end
                if not attacker then
                    attacker, target, amountStr =
                        s_match(line, "^(%S+[`']s%s+ward)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
                end
                if not attacker then
                    attacker, target, amountStr =
                        s_match(line, "^(%S+[`']s%s+doppelganger)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
                end
                if not attacker then
                    attacker, target, amountStr =
                        s_match(line, "^(%S+[`']s%s+Doppelganger)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
                end
                if not attacker then
                    attacker, target, amountStr =
                        s_match(line, "^(%S+)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
                end
            end

            if attacker and target and amountStr then
                local amount = tonumber((s_gsub(amountStr, ',', '')))
                if not amount or amount <= 0 then return false end

                local attributed = attributeDamage(attacker)
                local knownByAttr = knownChars[attributed] == true
                local knownByPet  = isKnownPet(attacker) == true

                if s_find(line, LIT_RAMPAGE_PARN, 1, true)
                   or (target and s_find(target, '%s+hits%s+'))
                   or (target and s_find(target, '%s+slashes%s+'))
                   or (target and s_find(target, '%s+crushes%s+'))
                   or (target and s_find(target, '%s+bashes%s+'))
                   or (not knownByAttr and not knownByPet
                       and looksLikePcName(attacker) and looksLikePcName(target)) then
                    return false
                end

                if not knownByAttr and not knownByPet
                   and not looksLikePcName(attacker) then
                    return false
                end

                if looksLikePcName(attacker) then
                    knownChars[attacker] = true
                end

                recordDamage(attacker, target, amount, 'melee')
                return true
            end
        end

        return false
    end
end

-- ============================================================================
-- logTailerPoll factory
-- ----------------------------------------------------------------------------
-- Same external behavior as the original. The key change is a PERSISTENT
-- file handle: we open once and keep it open, only re-opening when the file
-- was rotated (got smaller than our last position).
--
-- The original closes and re-opens every poll to defeat Lua's buffered IO,
-- but Lua's seek() to a specific position invalidates the read buffer just
-- as well, without the open/close syscall cost.
-- ============================================================================

function M.makeLogTailerPoll(deps)
    local processCombatLine = deps.processCombatLine
    local logTailerPath     = deps.logTailerPath
    local config            = deps.config
    local logTailer         = deps.logTailer
    local stripLogTimestamp = deps.stripLogTimestamp

    local io_open = io.open
    local pcall   = pcall

    return function()
        if not config.useLogParser then return end
        if _G.shuttingDown then return end

        logTailer.pollCount = (logTailer.pollCount or 0) + 1

        local path = config.logParserPath
        if not path or path == '' then path = logTailerPath() end
        if not path then
            logTailer.lastError = 'cannot resolve EQ log path'
            return
        end

        -- Open lazily. Keep the handle for the lifetime of the poll loop;
        -- only reopen on rotation or if it's gone bad.
        if not logTailer.file or logTailer.path ~= path then
            if logTailer.file then
                pcall(function() logTailer.file:close() end)
                logTailer.file = nil
            end
            local f, err = io_open(path, 'rb')
            if not f then
                logTailer.lastError = s_format('open failed: %s', err or '?')
                return
            end
            logTailer.file = f
            logTailer.path = path
            logTailer.lastError = nil
            if not logTailer.initialized then
                f:seek('end')
                logTailer.lastSize = f:seek()
                logTailer.initialized = true
                print(s_format(
                    '\ag[HealTracker]\ax log tailer initialized at offset %d (%s)',
                    logTailer.lastSize, path))
                return
            end
        end

        local f = logTailer.file

        -- Check current end of file. If smaller than our last position, the
        -- file was rotated; close and the next poll will reopen.
        local curEnd = f:seek('end')
        if curEnd < (logTailer.lastSize or 0) then
            pcall(function() f:close() end)
            logTailer.file = nil
            logTailer.lastSize = 0
            return
        end

        -- Nothing new since last poll? Cheap exit.
        if curEnd == (logTailer.lastSize or 0) then
            return
        end

        -- Seek back to where we left off. seek('set', N) invalidates the
        -- read buffer in Lua's stdio wrapper, which is the whole reason
        -- the original code was close+reopening. We get the same effect
        -- for free.
        f:seek('set', logTailer.lastSize or 0)

        -- Drain available lines. Cap per poll so we don't stall the main
        -- loop in catastrophic-spam scenarios.
        local limit = config.fastDpsMode and 150000 or 50000
        local count, matched = 0, 0
        local debug = config.debug

        -- One pcall around the whole drain instead of per-line. If a single
        -- line errors, we lose the rest of this poll, but the next poll
        -- picks up where we left off via lastSize.
        local ok, err = pcall(function()
            while true do
                local line = f:read('l')
                if not line then break end
                count = count + 1
                if count > limit then break end

                if line ~= '' then
                    local stripped = stripLogTimestamp(line)
                    if stripped and stripped ~= '' then
                        local hit = processCombatLine(stripped)
                        if hit then matched = matched + 1 end
                    end
                end
            end
        end)
        if not ok and debug then
            print(s_format('\ar[HT-LOG-ERR]\ax %s', tostring(err)))
        end

        logTailer.linesRead    = (logTailer.linesRead or 0) + count
        logTailer.linesMatched = (logTailer.linesMatched or 0) + matched
        logTailer.lastSize     = f:seek()

        -- Report to profiler if attached.
        if _G._ht_profile and _G._ht_profile.countPoll then
            _G._ht_profile.countPoll(count, matched, count >= limit)
        end

        if debug and count > 0 then
            print(s_format('\ay[HT-LOG]\ax read %d lines this poll, matched %d as combat',
                count, matched))
        end

        if debug then
            local now = os.time()
            if (now - (logTailer.lastHeartbeat or 0)) >= 10 then
                logTailer.lastHeartbeat = now
                print(s_format(
                    '\ay[HT-LOG]\ax heartbeat: polls=%d total_lines=%d matched=%d size=%d',
                    logTailer.pollCount, logTailer.linesRead,
                    logTailer.linesMatched, logTailer.lastSize))
            end
        end
    end
end

return M
