--[[
  HealTracker command/settings hot-reload patch v3.21.54
  Safe layer: command/help/settings helpers only.
  Do NOT touch parser state, fight tables, events, actors, log tailer, or plugins.
--]]

local M = {}

function M.apply(ctx)
    _G.HT_COMMAND_PATCH_VERSION = 'v3.21.54-command-layer-1'
    _G.HT_COMMAND_PATCH_LOADED_AT = os.date('%Y-%m-%d %H:%M:%S')

    -- Safe metadata/help only. The main slash dispatcher still owns actual
    -- command execution, so this patch cannot accidentally break DPS parsing.
    _G.HT_COMMAND_PATCH_HELP = {
        '/healtracker reloadui       - reload UI colors/theme only',
        '/healtracker reloadwindows  - reload UI + window/layout helpers only',
        '/healtracker reloadcommands - reload command/settings helpers only',
        '/healtracker reloadsafe     - reload UI + windows + commands safely',
    }

    -- Small safe helper used for diagnostics. It does not call mq.cmd,
    -- unload plugins, clear fights, or modify parser data.
    _G.HT_PrintCommandPatchStatus = function()
        print('\ag[HealTracker]\ax Command patch: ' .. tostring(_G.HT_COMMAND_PATCH_VERSION or 'not loaded'))
    end

    if ctx and ctx.config then
        ctx.config.windowOpen = true
    end
end

return M
