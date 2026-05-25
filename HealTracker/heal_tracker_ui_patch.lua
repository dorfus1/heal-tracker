-- heal_tracker_ui_patch.lua
-- UI-only patch hook for HealTracker v3.21.52+
-- Replace this file for future UI/theme/button-only updates, then run:
--   /healtracker reloadui
-- or:
--   /healtracker reloadwindows
-- Do NOT put parser, event, actor, plugin, or log tailer changes here.

local M = {}

function M.apply(ctx)
    -- ctx.mq, ctx.ImGui, ctx.config, ctx.THEME are provided by heal_tracker.lua.
    -- Small visible test marker for the safe reload chain.
    _G.HT_UI_PATCH_VERSION = 'v3.21.54-ui-patch'

    -- These are UI-only hints for future render code. They do not touch parser state.
    _G.HT_UI_ACCENT_MODE = 'reload-safe-blue-gold'
    _G.HT_UI_ROW_SHADE_REV = (_G.HT_UI_ROW_SHADE_REV or 0) + 1
end

return M
