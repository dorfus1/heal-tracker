-- heal_tracker_windows_patch.lua
-- Window/layout-only patch hook for HealTracker v3.21.54+
-- Replace this file for future window, popup, mini tracker, compare panel,
-- and table-layout experiments, then run:
--   /healtracker reloadwindows
-- Do NOT put parser, event, actor, plugin, or log tailer changes here.

local M = {}

function M.apply(ctx)
    -- This first patch is intentionally conservative: it only sets window/layout
    -- globals that future UI rendering can read. It does not replace parser logic,
    -- unregister events, touch fights, or touch mq2healparse.
    _G.HT_WINDOW_PATCH_VERSION = 'v3.21.54-window-patch'
    _G.HT_WINDOW_RELOAD_COUNT = (_G.HT_WINDOW_RELOAD_COUNT or 0) + 1

    -- Safe layout hints for future window renderers.
    _G.HT_WINDOW_PATCH = _G.HT_WINDOW_PATCH or {}
    _G.HT_WINDOW_PATCH.roundedPanels = true
    _G.HT_WINDOW_PATCH.comparePanelReady = true
    _G.HT_WINDOW_PATCH.popupLayoutReady = true
    _G.HT_WINDOW_PATCH.miniTrackerLayoutReady = true
end

return M
