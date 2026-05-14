--[[
   ============================================================================
   Heal Tracker  v3.20.3  -  group heal/DPS/spell aggregator with persistence
   ============================================================================



   v3.22.4 changes:
     - Added Turbo Batch DPS mode for Fast DPS parsing.
     - Common damage lines are now aggregated in memory during each log poll and applied once per batch.

   v3.22.5 changes:
     - Increased Turbo Batch DPS chunk size for high-spam raids / multiple groups.
     - Fast DPS mode now allows up to 1,000,000 new log lines per poll instead of 300,000.
     - Normal mode line budget raised to 250,000.
     - Group/raid/class background scanning is throttled longer during active combat so parsing gets priority.
     - Added cached NPC/player target checks to avoid expensive Spawn TLO lookups on every hit.
     - Live DPS should now update in larger GamParse-style chunks and catch up faster in multi-group fights.

   v3.22.1 changes:
     - Fixed mapped multi-word pet names in the log-file melee parser.
     - Charm/named pets such as 'froglok bok knight' now stay intact and fold into their mapped owner instead of showing as only 'Froglok'.

   v3.22.0 changes:
     - Added raid-window class auto-scan for DPS/parse class labels.
     - New /healtracker class scan|list|autoscan on|off commands.
     - Class map persists to config/heal_tracker/class_map.lua and config.lua.

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

   v3.21.1 changes:
     - Added History pin/favorite support with a Pinned date-range filter.
     - Added export/copy buttons for DPS, Heals, Burns, Spells, Mob Spells, and Full Fight reports.


   v3.21.2 changes:
     - Fixed pet owner mappings not persisting after reload/restart.
     - Pet mappings now also save to config/heal_tracker/pet_owners.lua.
     - Mini-position auto-save no longer risks wiping pet owner mappings.

   v3.22.3 changes:
     - Turbo Fast DPS parser path added for common melee, pet, spell, and non-melee damage lines.
     - Fast mode now bypasses the full parser/pcall for obvious damage spam so live DPS stays closer to GamParse.
     - Group/class autoscan throttled during active fights to reduce DPS tab/live tracker lag.

   v3.20.10 changes:
     - Compared Melee Disciplines now filters out caster-only burns such as First Spire of Arcanum.
     - Burn database still records observed caster burns, but the melee compare section only shows melee-relevant disciplines/burns.

   v3.21.0 changes:
     - Added expanded Paladin observed burn mappings: BP, 2.5 Epic, Glint, and Kunzar Shield.
     - Added cast-start phrase matching support for Fiery Sanctuary and Warlord's Bravery.

   v3.20.9 changes:
     - Player Compare now includes Spell Casts for each compared player.
     - Compare spell-cast counts are matched by player name, including rows like "Name + pets" and "Name (you)".

   v3.20.9 changes:
     - Fixed Player Compare damage-type percent display so values show as Damage (Percent) instead of looking like oversized percentages.
     - Added compared spell list showing which spells each compared player cast and how many times.

   v3.21.0 changes:
     - Added observed burn/discipline mapping system for compare analysis.
     - Built-in rule: "muscles bulge with the force of will" => Crystal Palm Discipline.
     - Player Compare now includes Melee Disciplines used and compares observed discipline timing/counts.

   v3.20.9 changes:
     - Player Compare Winner column now shows Tie when both compared values are equal.

   v3.20.8 changes:
     - Unified Alpha / Transparency setting across the full main UI, collapsed live DPS/heal tracker, and completed-fight popup.
     - Settings Alpha buttons now adjust every Heal Tracker window together.

   v3.20.7 changes:
     - Heal mini tracker now uses the same compact layout style as the DPS mini tracker.
     - Current fight/mob name is moved onto its own line above the heal stats.
     - Heal mini rows now auto-size by name/value length and use the rounded row styling.

   v3.20.6 changes:
     - Fixed named pet damage being dropped on multi-word named mobs.
     - PC-name detection now requires a single-word name so NPCs like Arena Terris Thule are not mistaken for players.
     - This restores named pet rows/mapping candidates such as Hooker hitting named bosses.

   v3.20.6 changes:
     - /healtracker stop now uses a crash-safe soft-stop mode instead of forcing MQ2Lua to unload while ImGui callbacks are registered.
     - Stop hides all Heal Tracker windows, closes the log tailer safely, disables parsing/saving work, and leaves a dormant idle loop to avoid the MacroQuest vsprintf_s_l crash.
     - Use /lua reload heal_tracker to start it again after using /healtracker stop.

   v3.20.6 changes:
     - Added Settings tab toggle button for Live DPS Fast Mode.
     - Fast DPS mode now saves immediately when changed from Settings or slash command.
     - Startup now re-saves current config so persistent settings stay refreshed after login/reload.
     - Confirmed saved config includes mini linger timer, pet owner links, fast DPS mode, mini position, alpha, timeout, and other settings.

   v3.20.6 changes:
     - Settings Alpha quick buttons now highlight only the currently selected alpha value.
     - Fixed 100% alpha button staying bright blue when 25%, 50%, or 75% is selected.

   v3.20.6 changes:
     - Added per-player Damage Type Breakdown for melee, spell, proc, DoT, pet, and swarm-pet damage.
     - Damage rows now store type totals while parsing so the UI can show class optimization details without rescanning logs.

   v3.20.6 changes:
     - Added DPS player compare mode for Damage Type Breakdown.
     - Click Compare beside two players to view side-by-side totals, DPS, and melee/spell/proc/DoT/pet/swarm percentages.
     - Compare panel includes quick clear controls and highlights the higher value on each row.

   v3.20.5 changes:
     - Live DPS mini tracker now formats million-plus damage/DPS values with 3 decimal places.
     - Example: 1200000 now displays as 1.200m instead of 1.2m.

   v3.20.4 changes:
     - Fixed timestamped EQ log non-melee nuke lines not always parsing.
     - processCombatLine now defensively strips [date time] prefixes even if called directly.
     - Non-melee parser now uses a more flexible pattern for large nuke/proc lines like Ayehop hit The Legendary Venril Sathir for 470452 points of non-melee damage.

   v3.20.3 changes:
     - Live DPS mini tracker now auto-expands width based on the longest visible DPS row.
     - Keeps the compact mini layout but prevents damage/DPS numbers from being cut off.
     - Uses capped dynamic name/value column widths so the tracker only grows when needed.

   v3.20.1 changes:
     - Extra-rounded inner table/header shading and pill-style scrollbars.
     - Rounded fight-list row interiors across DPS, Heals, Spells, History, Mob Spells, and Triggers.

v3.20.1 changes:
     - Real rounded inner row/header shading pass.
     - Native square table row/header fills are disabled so rounded cards show through.
     - Fight-list tables on every tab are wrapped in rounded panels.
     - Scrollbars are thinner with maximum rounding for a pill/circle look.

v3.20.1 changes:
     - Ultra-compact completed-fight mini popup: shorter row text and tighter columns.
     - Shortened live DPS mini tracker: mob name moved to its own line and stat row tightened.
     - Removed long active-DPS-in-seconds text from mini popup rows to reduce window width.
     - Kept percent display in compact whole-number format.

v3.20.0 changes:
     - Rounded-row UI pass based on the latest mockup.
     - Removed visible checkbox/select-box column from fight selection tables where possible.
     - Fight rows now rely on row highlighting/click selection instead of separate checkbox boxes.
     - Increased safe rounding for windows, child panels, frames, popups, grabs, tabs, and scrollbars.
     - Tuned row/header/button colors to better match the rounded blue dashboard mockup.
     - Still avoids unsafe DrawList, gradients, shadows, and risky custom rendering.

v3.19.9 changes:
     - Stage-40 final release polish pass.
     - Final tiny consistency pass across window, panel, row, button, and border colors.
     - Preserved the stable glossy dashboard look from the last no-crash build.
     - No layout rewrite, DrawList, shadows, gradients, or risky style changes added.
     - This should be treated as the finished MQ-safe glossy UI version.

v3.19.8 changes:
     - Stage-39 master balance pass.
     - Final small tuning across panel, row, header, and button colors.
     - Balanced cyan highlights against the warmer gold values for a cleaner finished look.
     - Softened panel contrast slightly so long sessions are easier on the eyes.
     - Maintained the proven MQ-safe rendering path.

v3.19.7 changes:
     - Stage-38 final row-balance pass.
     - Fine-tuned alternating row colors for better readability.
     - Slightly adjusted selected-row color to stay clear without being too bright.
     - Kept the warmer gold/yellow value accents from Stage 37.
     - Maintained the proven MQ-safe rendering path.

v3.19.6 changes:
     - Stage-37 final value-pop pass.
     - Slightly warmed and brightened gold/yellow value accents.
     - Tuned checkmark and slider active colors to match the final gold value theme.
     - Kept blue/cyan selection colors stable from the previous no-crash build.
     - Maintained the proven MQ-safe rendering path.

v3.19.5 changes:
     - Stage-36 final edge-polish pass.
     - Slightly refined table header, table border, and child panel contrast.
     - Tuned dark panel depth so sections remain separated without looking too harsh.
     - Kept button/row highlight colors in the same balanced blue/cyan range.
     - Maintained the proven MQ-safe rendering path.

v3.19.4 changes:
     - Stage-35 final micro-polish pass.
     - Very small tuning pass on borders, separators, and framed controls.
     - Improved consistency between row highlights and button hover/active colors.
     - Kept the current stable look while avoiding overly bright glare.
     - Maintained the proven MQ-safe rendering path.

v3.19.3 changes:
     - Stage-34 ultimate balance pass.
     - Softened the brightest active colors slightly so the dashboard stays readable during long sessions.
     - Balanced row, button, and header highlights for a cleaner finished look.
     - Kept gold/yellow values bright without overpowering the blue glass theme.
     - Maintained the proven MQ-safe rendering path.

v3.19.2 changes:
     - Stage-33 final navigation pop pass.
     - Made top/action buttons a little brighter on hover and active state.
     - Tuned active-page/nav highlight colors for clearer page focus.
     - Slightly warmed gold accents while keeping readability on dark panels.
     - Kept the proven MQ-safe rendering path.

v3.19.1 changes:
     - Stage-32 final depth-safe polish pass.
     - Deepened the main dashboard shell one more step for stronger contrast.
     - Slightly brightened table headers and active row highlights so sections read clearer.
     - Tuned scrollbar and resize-grip colors to match the final cyan/gloss theme.
     - Kept all changes on the proven MQ-safe rendering path.

v3.19.0 changes:
     - Stage-31 final soft-glow safe pass.
     - Added a subtle brighter cyan feel to hover/active borders and separators using only safe ImGui colors.
     - Slightly improved active navigation/button contrast without changing layout.
     - Tuned panel/frame contrast so controls look a little more raised.
     - Still uses the proven MQ-safe rendering path with no DrawList, shadows, gradients, or risky style pushes.

v3.18.9 changes:
     - Stage-30 final readability and contrast pass.
     - Slightly brightened normal text and secondary text for easier reading.
     - Tuned table row colors to keep the glossy look while improving long-list readability.
     - Made gold/yellow values a little warmer and more visible.
     - Kept all changes on the stable MQ-safe rendering path.

v3.18.8 changes:
     - Stage-29 final glossy dashboard pass.
     - Refined blue/cyan highlight balance across buttons, selected rows, and active controls.
     - Slightly deepened panel shading to increase floating-card separation.
     - Tuned border brightness so framed sections remain visible without overpowering the UI.
     - Kept the stable MQ-safe rendering path with no DrawList or unsafe style usage.

v3.18.7 changes:
     - Stage-28 compact/dashboard polish pass.
     - Tightened dashboard spacing and visual grouping for a cleaner layout.
     - Smoothed frame and child rounding for more consistent card-style sections.
     - Slightly refined separator and border contrast to help section framing.
     - Maintained the stable MQ-safe rendering path.

v3.18.6 changes:
     - Stage-27 final balance pass.
     - Balanced the blue/cyan highlights so selected rows are clear but not too bright.
     - Slightly softened alternating row contrast for easier long-session reading.
     - Kept gold value text bright and readable against the darker panels.
     - Preserved the proven MQ-safe rendering path.

v3.18.5 changes:
     - Stage-26 window/frame finish pass.
     - Tuned title bar, menu/frame, and window background colors for a more unified glossy shell.
     - Slightly strengthened outer border and separator visibility.
     - Refined popup background color so dropdowns/menus match the dashboard better.
     - Kept all changes MQ-safe with no DrawList, gradients, shadows, or risky style pushes.

v3.18.4 changes:
     - Stage-25 controls finish pass.
     - Polished checkbox/select-square, slider, and grab colors.
     - Made framed controls look more consistent with the glossy blue dashboard theme.
     - Slightly improved active/hover feedback on controls without adding unsafe drawing.
     - Kept the proven MQ-safe rendering path.

v3.18.3 changes:
     - Stage-24 table/list finish pass.
     - Tuned table row colors for cleaner contrast without becoming too bright.
     - Strengthened table borders and header backgrounds so list sections look more framed.
     - Slightly adjusted hover/selected colors to reduce glare while keeping selections obvious.
     - Kept the proven MQ-safe rendering path.

v3.18.2 changes:
     - Stage-23 selected-focus polish pass.
     - Made selected rows, active buttons, and active framed controls stand out more clearly.
     - Added a slightly warmer gold checkmark/accent tone for selected controls.
     - Tuned navigation/button contrast so active pages are easier to spot.
     - Kept the stable MQ-safe rendering path.

v3.18.1 changes:
     - Stage-22 final dashboard tuning pass.
     - Slightly deepened the main window and child-panel backgrounds for more contrast.
     - Tuned border/separator colors to make panels look more framed.
     - Improved resize-grip and scrollbar highlights to match the glossy blue theme.
     - Kept all rendering MQ-safe with no DrawList, shadows, gradients, or risky style pushes.

v3.18.0 changes:
     - Stage-21 text/readability polish pass.
     - Brightened normal text slightly for better readability on dark panels.
     - Strengthened gold/yellow accent values used by names, totals, DPS, and selected controls.
     - Tuned disabled/secondary text so it is still readable without overpowering the dashboard.
     - Kept the stable MQ-safe rendering path with no DrawList, shadows, or gradients.

v3.17.9 changes:
     - Stage-20 right-side detail panel polish pass.
     - Darkened framed child panels and popups for a stronger dashboard/card look.
     - Brightened frame hover/active states to make selectors and controls feel more responsive.
     - Tuned scrollbar grab colors to better match the blue/cyan glossy theme.
     - Kept all changes MQ-safe with no DrawList, shadows, gradients, or risky style pushes.

v3.17.8 changes:
     - Stage-19 row depth and panel refinement pass.
     - Increased contrast between alternating rows to create more visual depth.
     - Brightened selected-row highlighting for easier fight tracking.
     - Darkened background panels slightly to make floating sections stand out more.
     - Kept all rendering fully MQ-safe with no DrawList or shadow rendering.

v3.17.7 changes:
     - Stage-18 navigation and header polish pass.
     - Brightened active/hover button colors so the selected page stands out more.
     - Increased table/header contrast for a cleaner dashboard look.
     - Tuned separator and border blues for stronger section framing.
     - Kept all changes MQ-safe: no DrawList, gradients, shadows, or new risky style pushes.

v3.17.6 changes:
     - Stage-17 final consistency pass.
     - Polished table/header contrast one more step.
     - Made selected rows and active controls slightly brighter so the current focus is easier to see.
     - Tuned gold/yellow text accents for better readability against the darker glossy panels.
     - Kept all rendering on the proven MQ-safe path.

v3.17.5 changes:
     - Stage-16 final safe UI polish pass.
     - Slightly taller frames/buttons for a more premium dashboard feel.
     - Stronger table header contrast and cleaner row separation.
     - More consistent cyan/blue highlight color across hover, selected rows, and buttons.
     - Kept the proven no-crash MQ-safe rendering path.

v3.17.4 changes:
     - Stage-15 REAL UI pass with visibly stronger glossy colors.
     - Darkened the main glass panels and row bands.
     - Brightened hover/selected row states and top button states.
     - Strengthened blue/cyan dashboard contrast without unsafe DrawList calls.
     - Built from the last stable Stage-14 file.

v3.17.3 changes:
     - Stage-14 REAL UI pass with visible glossy dashboard updates.
     - Increased safe MQ-compatible window/frame/child rounding.
     - Improved spacing and darker panel presentation for clearer section separation.
     - Refined dashboard feel while remaining fully crash-safe.

v3.17.2 changes:
     - Stage-13 crash-safe glossy refinement pass.
     - Tightened dashboard spacing and section alignment.
     - Improved consistency of glossy panel styling across History, DPS, Heals, and Spells.
     - Slightly brighter hover states and cleaner visual separation for breakdown panes.
     - Preserved MQ-safe rendering path with no DrawList or PushStyleVar usage.

   v3.17.0 changes:
     - Stage-11 crash-safe final dashboard polish pass.
     - Deepened the blue-black glass theme and softened contrast between row bands.
     - Brighter cyan panel borders, cleaner separators, and stronger active page emphasis.
     - Larger 3D select squares and slightly taller stat cards for a more dashboard-like feel.
     - Still avoids DrawList, gradients, shadows, and PushStyleVar for MQ stability.

   v3.16.9 changes:
     - Stage-10 crash-safe glossy polish pass.
     - Larger dashboard canvas with taller navigation buttons.
     - Active page button now gets a brighter marker so the selected page is clearer.
     - Stronger blue-black panel backgrounds and brighter section borders.
     - Stat cards and page framing were tightened to look closer to the mockup while staying MQ-safe.

   v3.16.7 changes:
     - Stage-8 crash-safe glossy polish pass.
     - Larger main dashboard window and taller Turbo-style page buttons.
     - Richer blue/black panel colors and brighter cyan dividers.
     - More obvious 3D select squares with checkmark-style ON state.
     - Stronger dashboard stat cards and cleaner page framing without DrawList calls.

   v3.16.6 changes:
     - Stage-7 crash-safe glossy polish pass.
     - Stronger dark-blue dashboard contrast and brighter panel dividers.
     - Bigger 3D-style select squares for all fight lists.
     - More polished stat cards with clearer labels and yellow values.
     - Sharper Turbo-style top/action button coloring without unsafe DrawList calls.

   v3.15.4 changes:
     - Added rounded floating-row styling for fight list rows.
     - Heals, DPS, History, and Mob Spells fight lists now use softer 3D-style row panels.
     - Reduced sharp table grid lines on those lists for a cleaner Turbo-style look.

   v3.15.5 changes:
     - Added glossy rounded-card styling across DPS, Heals, Spells, and History lists.
     - Right-side detail breakdown tables now use floating 3D rounded rows.
     - Select boxes on fight rows are now rounded 3D square toggle buttons.
     - Polished the UI to better match the dark TurboLoot-style dashboard mockup.

   v3.16.3 changes:
     - Stage-4 crash-safe glossy polish pass.
     - Stronger mockup-style section headers and panel framing.
     - More 3D-looking selector buttons on every list.
     - Deeper blue/black row shading and brighter selected-row contrast.
     - Still avoids DrawList, gradients, shadows, and PushStyleVar for MQ stability.

   v3.16.2 changes:
     - Stage-3 crash-safe glossy polish pass.
     - Stronger dashboard contrast, brighter headers, cleaner bordered panels.
     - Larger beveled 3D select buttons and stronger selected-row shading.
     - More mockup-like blue/black table styling without unsafe DrawList calls.

   v3.16.1 changes:
     - Stage-2 crash-safe glossy improvements.
     - Improved row shading, toggle buttons, panels, and selector styling.

   v3.16.0 changes:
     - Stage-1 crash-safe glossy conversion based on the mockup.
     - Uses only MQ-safe ImGui widgets/styles: buttons, child panels, tables, and color pushes.
     - Adds a darker dashboard skin, bordered page panel, stronger row contrast,
       brighter headers, and larger 3D-style select boxes.
     - Avoids DrawList/AddRectFilled/gradient/shadow calls that crashed MQ2Lua.

   v3.10.5 changes:
     - Fixed debug logger: removed invalid /mqchat call and uses /echo safely.
     - Hardened log melee parsing so mob-to-player / Rampage incoming hits
       cannot create fake live DPS targets such as "Muram hits Zaxbys".

   v3.15.3 changes:
     - Removed the Session tab from the full window.
     - Replaced the ImGui tab bar with TurboLoot-style page buttons across the top.
     - Heals, DPS, Spells, History, Triggers, and Settings now switch pages with rounded toggle buttons.

   v3.15.6 changes:
     - Full glossy dashboard UI conversion: rounded panels, card rows, 3D selectors, and side-by-side detail panes.
     - Heals, DPS, Spells, and History pages now use custom rounded row cards instead of flat spreadsheet rows.

   v3.15.2 changes:
     - Fixed Lua load error: main function has more than 200 local variables.
     - Bright yellow Last Fight color tables now use _G storage instead of
       adding new top-level locals.

   v3.15.1 changes:
     - Updated Last Fight popup text colors to use bright yellow styling.
     - Names, totals, DPS values, and fight statistics are now easier to read.

   v3.15.0 changes:
     - Reworked selection controls on Heals, DPS, Spells, and History tabs.
     - Removed Select none buttons.
     - Select all is now a toggle: click once to select visible fights, click again to deselect them.
     - Added Select Range mode. Click Select Range, click the first fight, then click the last fight;
       every visible row between them is selected for combining.
     - Range select works from either the checkbox column or the mob-name row click.

   v3.14.9 changes:
     - Rounded all UI action buttons with smoother TurboLoot-style corners.
     - Updated Select all / Select none / Split pets / Refresh / action buttons
       to use cleaner rounded edges instead of sharp corners.
     - Uses a locally balanced style push/pop inside the button helper to keep
       MQ ImGui stable.

   v3.14.8 changes:
     - Replaced split-pets checkboxes with TurboLoot-style ON/OFF toggle buttons.
     - Added the same split-pets toggle to the History tab.
     - Cleaned up Select all / Select none / Refresh buttons with consistent
       professional sizing and darker TurboLoot-style button colors.
     - Kept all changes MQ-safe by avoiding PushStyleVar/PopStyleVar.

   v3.14.7 changes:
     - Emergency ImGui stability fix.
     - Removed all remaining PushStyleVar/PopStyleVar usage to fully prevent
       Missing PopStyleVar() overlay pauses.
     - Keeps color theme, alpha fade, live DPS layout, Last Fight popup, and
       parser fixes intact.

   v3.14.6 changes:
     - Fixed ImGui Critical Failure: Missing PopStyleVar().
     - Removed risky floating-window style var pushes from mini and Last Fight windows.
     - Keeps alpha, color, DPS layout, and parser fixes stable.

   v3.14.5 changes:
     - Fixed MQOverlay pause caused by unsupported/risky ImGui style vars.
     - Rounded UI styling now uses a safer MQ-compatible style set.
     - Kept rounded corners while removing risky padding/spacing pushes.

   v3.14.4 changes:
     - Updated UI styling with a more polished TurboLoot-inspired look.
     - Added rounded corners to the main Heal Tracker window, mini tracker,
       and Last Fight popup.
     - Added softer padding, frame rounding, popup rounding, and cleaner
       dark blue-gray panel styling.
     - Kept the live mini and Last Fight popup borderless while giving them
       rounded edges.

   v3.14.3 changes:
     - Fixed MacroQuest crash when the Last Fight popup appears.
     - Restored the safe MQ ImGui Begin(name, open, flags) call signature while
       keeping the Last Fight popup borderless and without a visible title bar/X.

   v3.14.2 changes:
     - Live DPS mini tracker window is now borderless.
     - Last Fight popup window is now borderless.
     - Removed the Last Fight popup title bar and top-right X close button.

   v3.14.1 changes:
     - Last Fight popup now uses the same alpha/transparency setting as the live DPS mini tracker.
     - /healtracker alpha <0-100> now controls both live mini and Last Fight popup fade level.

   v3.14.0 changes:
     - Last Fight popup now uses the same GamParse-style color format as the live DPS mini.
     - Added blue alternating row highlights to the after-fight DPS popup.
     - Last Fight popup names and values now use the same gold/yellow mini theme.
     - Mob name remains con-colored.

   v3.13.9 changes:
     - Fixed mini live DPS window only showing the + button after the gold theme update.
     - Moved the mini gold color definition before the mini renderer so labels no longer
       error during draw.

   v3.13.8 changes:
     - Adjusted live DPS mini colors to better match GamParse styling.
     - Softer gold/yellow used for tracker labels and character names.
     - Mob con-color highlighting remains unchanged.

   v3.13.7 changes:
     - Unified live DPS mini text colors.
     - DPS Tracker, Total, DPS, Time, Mob labels, and character names now use
       the same yellow color as the DPS numbers.
     - Active mob name still preserves con-color formatting.

   v3.13.6 changes:
     - Live DPS mini character names now use GamParse-style yellow text.
     - Updated alternating live DPS row highlights to a brighter blue/purple
       color scheme matching GamParse more closely.

   v3.13.5 changes:
     - Changed live DPS mini alternating row highlights from red tones to
       blue-toned GamParse-style shading for improved readability.

   v3.13.4 changes:
     - Live DPS mini rows now use alternating shaded row backgrounds.
     - Added configurable mini tracker alpha/transparency from 0 to 100.
     - New command: /healtracker alpha <0-100>
     - Settings tab now includes Mini window alpha control.

   v3.13.3 changes:
     - Live DPS mini value column is now right-aligned GamParse-style.
     - Damage, DPS, and percent text stays lined up vertically down the right side
       instead of starting immediately after each character name.

   v3.13.2 changes:
     - Live DPS mini rows now include each player's percentage of total damage.
     - DPS parse breakdown tables now include a percent column showing each
       attacker/pet contribution to total fight damage.
     - Percent display matches GamParse-style readability for live and saved parses.

   v3.13.1 changes:
     - Live DPS mini rows now show compact GamParse-style damage values.
     - Examples: 10,573 -> 11k, 234,000 -> 234k, 1,200,000 -> 1.2m.
     - DPS value remains full/readable after the @ symbol.

   v3.13.0 changes:
     - Live DPS mini rows now display as "damage @ dpsdps" for easier reading.
     - Live Heals mini window now shows "Current fight:" instead of "Last kill:".
     - Live Heals mini mob name now uses the same con-color formatting as the
       DPS mini tracker.

   v3.12.9 changes:
     - Fixed melee parser support for enchanter doppelganger swarm pets.
     - The parser now captures "Owner`s doppelganger <verb> <mob> for N"
       before the generic one-word attacker parser can split it incorrectly.
     - Doppelganger damage now appears under the owner as a pet row when
       split-pets is enabled, or under "Owner + pets" when combined.

   v3.12.8 changes:
     - Added enchanter swarm pet attribution for doppelgangers.
     - Damage from lines like "Zaxbys`s doppelganger hits <mob>" now folds
       into the owner row as "Zaxbys + pets" instead of being missed or
       treated as a separate attacker.
     - Strengthened possessive swarm-pet fallback for future pet/proc forms.

   v3.12.7 changes:
     - Fixed History tab duplicate ImGui IDs when multiple fights save during the
       same second. History selection now uses a unique archive row key instead
       of timestamp alone.
     - Duplicate mob names/timestamps no longer share the same checkbox,
       selectable row, or drill-down selection key.

   v3.12.6 changes:
     - Fixed History tab ImGui duplicate ID conflicts when multiple fights have
       the same mob name, timestamp, or repeated Copy/select controls.
     - History controls now use unique hidden IDs so Dear ImGui no longer
       reports "2 visible items with conflicting ID" errors.

   v3.12.5 changes:
     - Restored the cleaner Heals parse drill-down layout.
     - Heals tab now shows healing received by player across the top.
     - Clicking a player shows a readable Source / Total HP / Count / Avg / Max table
       for that player's healers, rune absorbs, and self-procs.

   v3.12.4 changes:
     - Hard-blocked malformed fake mob labels that start with combat verbs
       such as "hits Draevok Boneweaver", "slashes X", or "backstabs X".
     - Fake verb-starting targets are now rejected before active mob creation,
       before live DPS focus, and before fight snapshot/history save.
     - Older saved configs with long fight timeouts are capped back down to
       10 seconds so zoning/evac or stopping attacks triggers the after-fight
       popup much faster.

   v3.12.3 changes:
     - Live DPS tracker now colors the active mob name by con color.
     - Live display uses the same mob-level fallback lookup as the DPS/Heals
       parse tabs, so red-con mobs should no longer show white when level
       capture was missed at fight start.

   v3.12.2 changes:
     - Improved mob con-color display on DPS and Heals parse tabs.
     - If a fight did not capture mob level at combat start, the UI now
       tries to resolve the mob level again by mob name before falling
       back to white.
     - Added a looser Spawn lookup fallback for multi-word/named mobs
       so red-con mobs are less likely to show as white.

   v3.12.1 changes:
     - Increased the default last-fight popup linger duration to 10 seconds.
     - Completed fight popups now remain visible longer after combat ends.

   v3.12.0 changes:
     - Raised the minimum damage required to save a fight to 10,000.
     - Prevents tiny/noise fights and trivial low-damage events from
       cluttering DPS history and popup windows.

   v3.11.9 changes:
     - Very short fights now save to the parse as long as they record real damage.
     - Default minimum damage-to-record threshold lowered to 1.
     - Helps 1-second fights/trash kills still appear in saved DPS history.

   v3.11.8 changes:
     - Added a live fight timer to the mini/live DPS tracker.
     - Timer displays as MM:SS beside Total and DPS.

   v3.11.7 changes:
     - Increased maximum log parser throughput to 50,000 lines per poll.
     - Further improves live DPS responsiveness during extremely heavy
       raid spam and large AE encounters.

   v3.11.6 changes:
     - Fight timeout snapshots now pop the after-fight DPS window immediately.
     - Timeout-ended fights are moved to the front of the last-fight popup queue
       and the popup timer is restarted when the timeout fires.

   v3.11.5 changes:
     - Live DPS mini tracker now shows only the top 10 DPS characters.
     - Last-fight DPS popup now shows only the top 10 DPS characters.
     - Rows are sorted by total damage descending and update dynamically
       as players pass each other during the fight.

   v3.11.4 changes:
     - Live DPS display inactivity timeout raised to 10 seconds before
       clearing the active encounter from the mini/live DPS tracker.

   v3.11.3 changes:
     - Live DPS target now prefers the highest-total active mob instead
       of the most recently hit mob. This prevents AoE damage on adds
       from stealing the live DPS display away from the named/boss.

   v3.11.2 changes:
     - Same fake target fix as v3.11.1, but without adding any new
       top-level local variables. This avoids Lua's 200-local limit.
     - Rejects malformed incoming mob damage targets such as
       "hits Zaxbys", "backstabs Dorias", and "Muram hits Zaxbys".

   v3.11.0 changes:
     - FULL script file rebuilt from working v3.10.7 base.
     - Log tailer now processes up to 20000 new log lines per poll.
     - Keeps prior fixes for bad mob->player melee/spell damage entering live DPS.

   v3.10.6 changes:
     - Fixed live DPS blanking/switching when mob spell damage hit a player.
       Incoming lines like "Zaxbys has taken damage from Overlord Mata Muram"
       are now dropped inside the spell parser before recordDamage().
     - Debug logging is MQ/Lua console only now, removing /mqchat errors and
       duplicate /echo debug spam.

   v3.10.7 changes:
     - Speed pass for live DPS log parsing: main loop delay reduced from 50ms
       to 10ms and log tailer per-poll line budget raised to 20000.
       This helps the live DPS display stay close to real time during heavy
       raid spam.
     - Live display idle cutoff increased from 5s to 8s so temporary log
       bursts/backlog do not make the mini DPS bar go blank mid-fight.

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
     /healtracker fastdps on|off      -- faster live DPS polling mode
     /healtracker burn list           -- list observed burn/disc message mappings
     /healtracker burn add <phrase> => <discipline>
     /healtracker burn remove <phrase>
     /healtracker class scan          -- scan raid/group window and save player classes
     /healtracker class list          -- list saved class mappings
     /healtracker class autoscan on|off -- toggle automatic raid class scanning
     /healtracker test [healer] [amt]
     /healtracker testremote [target] [healer] [amt]
     /healtracker testkill [mobname]
     /healtracker stop

   @version heal_tracker.lua 3.22.4
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
-- Crash-safe soft stop state. On some MQ2Lua builds, fully exiting a Lua
-- script while ImGui callbacks are still registered can crash EverQuest.
-- /healtracker stop now enters a dormant mode instead of forcing unload.
local htSoftStopped = false
local htSoftStopClosed = false

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
    -- Alpha/transparency for the floating mini tracker window, 0-100.
    -- 100 = fully opaque, 0 = nearly invisible.
    miniAlphaPercent = 100,
    -- What to show on the mini collapsed bar: 'heals' shows live session
    -- heals (the original behavior), 'dps' shows the in-progress fight's
    -- DPS so far. Toggle on the bar itself or via /healtracker miniview.
    miniShowDps      = false,
    -- Saved screen position for the minimized/mini tracker window.
    -- Drag the mini tracker where you want it; the position is saved
    -- automatically and restored on the next script launch.
    miniPosX         = nil,
    miniPosY         = nil,
    autoResetOnKill  = true,
    killGraceMs      = 500,
    -- Named-pet -> owner mapping. EQ has no marker on the actual pet
    -- name in chat, so the user has to tell us. Configure with
    --   /healtracker pet add PetName Necro
    -- The map persists in config.lua across restarts.
    petOwners        = {},
    classMap         = {},
    classAutoScan    = true,
    classAutoScanSeconds = 60,
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
    fightTimeoutSeconds = 10,
    -- How long (seconds) to keep showing the LAST fight on the mini
    -- collapsed bar after the fight ends. After this many seconds of
    -- no damage activity, the mini view clears to "No active fight."
    -- Set to 0 to clear immediately (default = 5 seconds).
    miniLingerSeconds = 10,
    -- Minimum fight duration (seconds) for a fight to be queued onto
    -- the mini-view popup. Short fights (boss adds, trash mobs killed
    -- in 1-3 seconds) flood the popup queue and obscure the real
    -- fights you care about. Default 10s. Fights below this duration
    -- are still saved to history -- only the popup queue is filtered.
    miniMinDuration = 0,
    -- Minimum total damage a fight must reach before it's recorded
    -- as a fight entry. Trash adds in boss encounters often take only
    -- 5-30k damage each and clutter the parse with 20+ tiny entries
    -- per boss kill. Default 50k -- catches mini-bosses and important
    -- adds, filters out trash. Set to 0 to record all fights.
    minDamageToRecord = 10000,
    -- Live DPS target focus: 'highest' keeps the display on the highest-damage active mob
    -- so AoE hits on adds do not steal focus from the named/boss.
    liveDpsFocusMode = 'highest',
    -- Maximum rows shown in live DPS and completed-fight mini popup.
    liveDpsMaxRows = 10,
    -- Live DPS Fast Mode. Toggle with /healtracker fastdps on|off.
    -- Prioritizes log parsing and live display during active combat.
    fastDpsMode = true,
    -- Observed burn / discipline message mapping. These are visible EQ log
    -- flavor lines from other players, not normal spell cast lines. The key
    -- is the text after the player name, matched case-insensitively.
    -- Example log line: "Handys muscles bulge with the force of will."
    -- maps to Handys -> Crystal Palm Discipline.
    burnDiscMap = {
        -- Permanent Project Lazarus burn/disc phrase database built from spells_us.txt.
        -- Keys are visible log phrases after the player name; values are the burn/disc label shown in Compare.
        ['a bestial fury consumes you'] = 'Bestial Fury Discipline',
        ['a consuming rage takes over your weapons'] = 'Furious Discipline',
        ['a glowing shimmer of runes surrounds you'] = 'Glyph Spray',
        ['a protective spirit guards you'] = 'Protective Spirit Discipline',
        ['a shadowy auspice protects you'] = 'Umbral Auspice',
        ['a spirit of rage fills your body'] = 'Spirit of Rage Discipline',
        ['a wild spirit fills your body'] = 'Bestial Alignment',
        ['adopts an aggressive stance'] = 'Razor\'s Edge Discipline',
        ['aim is sharpened by a steadied hand'] = 'Deadly Aim Discipline',
        ['an unholy aura envelops your body'] = 'Unholy Aura Discipline',
        ['armor shimmers with radiance'] = 'Warrior\'s Auspice Effect III',
        ['arms begin to blur'] = 'Speed Focus Discipline',
        ['arms feel alive with mystic energy'] = 'Kinesthetics Discipline',
        ['assumes a defensive fighting style'] = 'Defensive Discipline',
        ['assumes a precise fighting style'] = 'Precision Discipline',
        ['assumes an aggressive fighting style'] = 'Aggressive Discipline',
        ['assumes an evasive fighting style'] = 'Evasive Discipline',
        ['assumes the fighting style of a holy guardian'] = 'Holy Guardian Discipline',
        ['assumes the fighting style of an unholy guardian'] = 'Unholy Guardian Discipline',
        ['attacks are hastened by anger'] = 'Vengeful Flurry Discipline',
        ['attacks are hastened by discipline'] = 'Rapid Kick Discipline',
        ['attacks are hastened by vicious anger'] = 'Vicious Flurry Discipline',
        ['attacks become perfectly aligned'] = 'Twisted Chance Discipline',
        ['attacks take on deadly precision'] = 'Deadly Precision Discipline',
        ['becomes an embodiment of arcane force'] = 'Elemental Union',
        ['becomes an embodiment of mystic force'] = 'Elemental Union',
        ['begins to move with unequaled grace'] = 'Planeswalk Discipline',
        ['begins to sprint'] = 'Sprint Discipline',
        ['blood boils with rage'] = 'Unpredictable Rage Discipline',
        ['body becomes as hard as stone'] = 'Stonewall Discipline',
        ['body becomes impenetrable'] = 'Impenetrable Discipline',
        ['body begins to move with instinctual grace'] = 'Fortitude Discipline',
        ['body blurs as they take on the spirit of the monkey'] = 'Monkey\'s Spirit Discipline',
        ['body is consumed in rage'] = 'Furious Discipline',
        ['body is filled with silent fury'] = 'Silentfist Discipline',
        ['bow crackles with natural energy'] = 'Trueshot Discipline',
        ['channels the power of the forest'] = 'Guardian of the Forest',
        ['dances about nimbly'] = 'Deftdance Discipline',
        ['dark albatross circle overhead'] = 'Auspice',
        ['drops into a crouch'] = 'Counterforce Discipline',
        ['enters a blood rage'] = 'Blood Rage Discipline',
        ['enters an accelerated frenzy'] = 'Frenzied Burnout',
        ['eyes gleam with energy'] = 'Duelist Discipline',
        ['eyes gleam with iron will'] = 'Fearless Discipline',
        ['eyes gleam with madness'] = 'Savage Spirit',
        ['eyes glow violet'] = 'Spiritual Discipline',
        ['face becomes twisted with fury'] = 'Whirlwind Discipline',
        ['face is filled with anger'] = 'Inspired Anger Discipline',
        ['face twists into a burning rage'] = 'Burning Rage Discipline',
        ['face twists with resolve'] = 'Indomitable Discipline',
        ['falls into a reckless rage'] = 'Reckless Discipline',
        ['feels energized'] = 'Essence of Ruaabri',
        ['feet become one with the earth'] = 'Stonestance Discipline',
        ['feet glow with mystic power'] = 'Thunderkick Discipline',
        ['fist clenches with fatal fervor'] = 'Ashenhand Discipline',
        ['fist clenches with steely fervor'] = 'Ironfist Discipline',
        ['fists begin to blur'] = 'Hundred Fists Discipline',
        ['focus becomes perfect'] = 'Charge Discipline',
        ['focused anger lends speed to your attacks'] = 'Vengeful Flurry Discipline',
        ['glows with energy'] = 'Life Burn Recourse',
        ['goes mad with the power of the spirits'] = 'Frenzy of Spirit',
        ['goes pale with fear'] = 'Auspice',
        ['hands speeds up'] = 'Blinding Speed Discipline',
        ['has become more resistant'] = 'Resistant Discipline',
        ['has been disciplined'] = 'Discipline',
        ['has been filled with a spirit of rage'] = 'Spirit of Rage Discipline',
        ['healing power temporarily forks in two'] = 'Healing Twincast',
        ['instincts are sharpened by the auspice of the hunter'] = 'Auspice of the Hunter',
        ['is assaulted by savage claws'] = 'Savage Spirit Claw Strike',
        ['is consumed by a blind rage'] = 'Blind Rage Discipline',
        ['is consumed in a bestial fury'] = 'Bestial Fury Discipline',
        ['is covered in slithering black glyphs'] = 'Glyph of Darkness',
        ['is engulfed in a shield of lightning'] = 'Shocking Defense Discipline',
        ['is enveloped in a twining aura'] = 'Twincast Aura',
        ['is enveloped in an unholy aura'] = 'Unholy Aura Discipline',
        ['is filled with a battle sense'] = 'Battle Sense Discipline',
        ['is filled with a savage spirit'] = 'Savage Spirit',
        ['is filled with a wild spirit'] = 'Bestial Alignment',
        ['is filled with focused fury'] = 'Focused Fury Discipline',
        ['is empowered by rage'] = 'Valorous Rage',
        ['you embrace the rage within'] = 'Valorous Rage',
        ['armor of the inquisitor gathers around your body'] = 'Armor of the Inquisitor',
        ['armor of the inquisitor gathers around'] = 'Armor of the Inquisitor',
        ['is filled with outrider\'s accuracy'] = 'Outrider\'s Accuracy',
        ['is filled with wounded rage'] = 'Wounded Rage Discipline',
        ['is guarded by a protective spirit'] = 'Protective Spirit Discipline',
        ['is healed'] = 'Glyph of Recovery',
        ['is imbued with ruaabri\'s fury'] = 'Ruaabri\'s Fury',
        ['is infused'] = 'Glyph of Frantic Infusion',
        ['is infused with a wild spirit'] = 'Savage Spirit Infusion',
        ['is obscured by shadows'] = 'Imperceptible Discipline',
        ['is overcome by a berserking rage'] = 'Berserking Discipline',
        ['is protected by a shadowy auspice'] = 'Umbral Auspice',
        ['is protected from harm'] = 'Auspice of Shadows',
        ['is surrounded by a shimmer of runes'] = 'Glyph Spray',
        ['is surrounded by an aura of mystical energy'] = 'Aura of Runes Discipline',
        ['is surrounded by swirling symbols'] = 'Riftseeker\'s Glyph',
        ['is surrounded in an aura of sanctification'] = 'Sanctification Discipline',
        ['looks perfectly focused'] = 'Concentration Discipline',
        ['lowers their defenses'] = 'Offensive Discipline',
        ['magic is serenely focused'] = 'Serenity\'s Twincast',
        ['magic splits'] = 'Twincast',
        ['mind sharpens and strength flows into their body'] = 'Intensity of the Resolute',
        ['movements quicken'] = 'Frenzied Stabbing Discipline',
        ['muscles bulge with brutal power'] = 'Brutal Onslaught Discipline',
        ['muscles bulge with malicious power'] = 'Malicious Onslaught Discipline',
        ['muscles bulge with savage power'] = 'Savage Onslaught Discipline',
        ['muscles bulge with spectral power'] = 'Spectral Onslaught Discipline',
        ['muscles bulge with the force of will'] = 'Crystal Palm Discipline',
        ['prepares to deftly avoid the next magical attack'] = 'Spell Evasion Discipline',
        ['pure poison pumps from your pores'] = 'Aspbleeder Discipline',
        ['raises a shield to deflect incoming attacks'] = 'Deflection Discipline',
        ['raises a shield with determined strength to deflect incoming attacks'] = 'Rampart Discipline III',
        ['raises a shield with full strength to deflect incoming attacks'] = 'Rampart Discipline',
        ['raises a shield with renewed strength to deflect incoming attacks'] = 'Rampart Discipline II',
        ['regains control'] = 'Discipline Unbound',
        ['roars in anger'] = 'Cleaving Rage Discipline',
        ['roars with fury'] = 'Cleaving Anger Discipline',
        ['roars with madness'] = 'Cleaving Madness Discipline',
        ['shadows cloak your attacks'] = 'Imperceptible Discipline',
        ['shifts to a lithe defensive stance'] = 'DoN Fleet-Footed Discipline',
        ['skin glows with dark energy'] = 'Leechcurse Discipline',
        ['speeds up to match the beat of the music'] = 'Quick Time',
        ['steels their mind and will'] = 'Unflinching Will Discipline',
        ['steels themselves for a final stand'] = 'Final Stand Discipline',
        ['steels themselves for a last stand'] = 'Last Stand Discipline',
        ['steps into the dream world'] = 'Dreamwalk Discipline',
        ['succumbs to the slaver\'s commands'] = 'Discipline of Slaves',
        ['takes careful aim at their target'] = 'Knifeplay Discipline',
        ['the fires of life fuel your potential to replenish yourself'] = 'Life Burn Recourse',
        ['the power of the forest surges through your muscles'] = 'Guardian of the Forest',
        ['the sensei\'s focus further hones your defenses'] = 'Third Spire of the Sensei\'s Guard',
        ['the sensei\'s focus further hones your offensive skill'] = 'Third Spire of the Sensei\'s Onslaught',
        ['the sensei\'s focus hones your senses'] = 'Third Spire of the Sensei\'s Focus',
        ['turns a vile shade of green'] = 'Aspbleeder Discipline',
        ['voice becomes perfectly melodious'] = 'Puretone Discipline',
        ['you are engulfed in a shield of divine light'] = 'BP',
        ['is engulfed in a shield of divine light'] = 'BP',
        ['engulfed in a shield of divine light'] = 'BP',
        ['you are enveloped in the flames of the dauntless'] = '2.5 Epic',
        ['is enveloped in the flames of the dauntless'] = '2.5 Epic',
        ['flames of the dauntless'] = '2.5 Epic',
        ['you seek shelter, guarded by radiant flame'] = 'Glint',
        ['fiery sanctuary'] = 'Glint',
        ['you begin casting fiery sanctuary'] = 'Glint',
        ['begins to cast a spell. <fiery sanctuary>'] = 'Glint',
        ['begins to cast a spell <fiery sanctuary>'] = 'Glint',
        ["warlord's bravery"] = 'Kunzar Shield',
        ["you begin casting warlord's bravery"] = 'Kunzar Shield',
        ["begins to cast a spell. <warlord's bravery>"] = 'Kunzar Shield',
        ["begins to cast a spell <warlord's bravery>"] = 'Kunzar Shield',
        ['weapon is bathed in a hallowed light'] = 'Hallowforge Discipline',
        ['weapon is bathed in a holy light'] = 'Holyforge Discipline',
        ['weapon is bathed in a pure light'] = 'Pureforge Discipline',
        ['weapons begin to move much easier'] = 'Weapon Affinity Discipline',
        ['weapons begin to spin'] = 'Weapon Shield Discipline',
        ['weapons crackle with natural energy'] = 'Bosquestalker\'s Discipline',
        ['weapons move with uncanny grace'] = 'Counterattack Discipline',
        ['wounds begin to close'] = 'Healing Will Discipline',
        ['you are assaulted by savage claws'] = 'Savage Spirit Claw Strike',
        ['you are clawed with savage fury'] = 'Second Spire of the Savage Lord Effect',
        ['you are consumed in a blind rage'] = 'Blind Rage Discipline',
        ['you are engulfed in a shield of lightning'] = 'Shocking Defense Discipline',
        ['you are enveloped in a twining aura'] = 'Twincast Aura',
        ['you are filled with a burning rage'] = 'Burning Rage Discipline',
        ['you are filled with a cleaving madness'] = 'Cleaving Madness Discipline',
        ['you are filled with a cleaving rage'] = 'Cleaving Rage Discipline',
        ['you are filled with a savage spirit'] = 'Savage Spirit',
        ['you are filled with an acute battle sense'] = 'Battle Sense Discipline',
        ['you are filled with cleaving acrimony'] = 'Cleaving Acrimony Discipline',
        ['you are filled with cleaving anger'] = 'Cleaving Anger Discipline',
        ['you are filled with focused fury'] = 'Focused Fury Discipline',
        ['you are filled with inspired anger'] = 'Inspired Anger Discipline',
        ['you are filled with reckless fury'] = 'Reckless Discipline',
        ['you are healed'] = 'Glyph of Recovery',
        ['you are imbued with ruaabri\'s fury'] = 'Ruaabri\'s Fury',
        ['you are infused with a wild spirit'] = 'Savage Spirit Infusion',
        ['you are protected from harm'] = 'Auspice of Shadows',
        ['you are struck by an enormous blast of magical energies'] = 'Mana Burn',
        ['you are surrounded by a swirl of strange glyphs'] = 'Riftseeker\'s Glyph',
        ['you are surrounded by an aura of mystical energy'] = 'Aura of Runes Discipline',
        ['you assume a defensive fighting style'] = 'Defensive Discipline',
        ['you assume a precise fighting style'] = 'Precision Discipline',
        ['you assume an aggressive fighting style'] = 'Aggressive Discipline',
        ['you assume an evasive fighting style'] = 'Evasive Discipline',
        ['you assume the fighting style of a holy guardian'] = 'Holy Guardian Discipline',
        ['you assume the fighting style of an unholy guardian'] = 'Unholy Guardian Discipline',
        ['you become an embodiment of arcane force'] = 'Elemental Union',
        ['you become an embodiment of mystic force'] = 'Elemental Union',
        ['you become an embodiment of mystical force'] = 'Elemental Union',
        ['you become one with your weapons'] = 'Weapon Affinity Discipline',
        ['you begin to move with unequal grace'] = 'Planeswalk Discipline',
        ['you begin to sprint'] = 'Sprint Discipline',
        ['you brace your shield with full strength to deflect incoming attacks'] = 'Rampart Discipline',
        ['you channel your will into magical resistance'] = 'Resistant Discipline',
        ['you dance about nimbly'] = 'Deftdance Discipline',
        ['you drop into a crouch, ready to counter any attacks'] = 'Counterforce Discipline',
        ['you enter a blood rage'] = 'Blood Rage Discipline',
        ['you feel different'] = 'Group Guardian of the Forest Effect',
        ['you feel energized'] = 'Essence of Ruaabri',
        ['you feel unstoppable'] = 'Deadeye Discipline',
        ['you fill yourself with anger'] = 'Glyph of Angry Thoughts',
        ['you fill yourself with outrider\'s accuracy'] = 'Outrider\'s Accuracy',
        ['you fly into a berserking rage!'] = 'Berserking Discipline',
        ['you focus on the first spire of ancestors'] = 'First Spire of Ancestors',
        ['you focus on the first spire of arcanum'] = 'First Spire of Arcanum',
        ['you focus on the first spire of divinity'] = 'First Spire of Divinity',
        ['you focus on the first spire of elements'] = 'First Spire of Elements',
        ['you focus on the first spire of enchantment'] = 'First Spire of Enchantment',
        ['you focus on the first spire of holiness'] = 'First Spire of Holiness',
        ['you focus on the first spire of nature'] = 'First Spire of Nature',
        ['you focus on the first spire of necromancy'] = 'First Spire of Necromancy',
        ['you focus on the first spire of savagery'] = 'First Spire of Savagery',
        ['you focus on the first spire of the minstrels'] = 'First Spire of the Minstrels',
        ['you focus on the first spire of the pathfinders'] = 'First Spire of the Pathfinders',
        ['you focus on the first spire of the rake'] = 'First Spire of the Rake',
        ['you focus on the first spire of the reavers'] = 'First Spire of the Reavers',
        ['you focus on the first spire of the savage lord'] = 'First Spire of the Savage Lord',
        ['you focus on the first spire of the sensei'] = 'First Spire of the Sensei',
        ['you focus on the first spire of the warlord'] = 'First Spire of the Warlord',
        ['you focus on the second spire of ancestors'] = 'Second Spire of Ancestors',
        ['you focus on the second spire of arcanum'] = 'Second Spire of Arcanum',
        ['you focus on the second spire of divinity'] = 'Second Spire of Divinity',
        ['you focus on the second spire of elements'] = 'Second Spire of Elements',
        ['you focus on the second spire of enchantment'] = 'Second Spire of Enchantment',
        ['you focus on the second spire of holiness'] = 'Second Spire of Holiness',
        ['you focus on the second spire of nature'] = 'Second Spire of Nature',
        ['you focus on the second spire of necromancy'] = 'Second Spire of Necromancy',
        ['you focus on the second spire of savagery'] = 'Second Spire of Savagery',
        ['you focus on the second spire of the minstrels'] = 'Second Spire of the Minstrels',
        ['you focus on the second spire of the pathfinders'] = 'Second Spire of the Pathfinders',
        ['you focus on the second spire of the rake'] = 'Second Spire of the Rake',
        ['you focus on the second spire of the reavers'] = 'Second Spire of the Reavers',
        ['you focus on the second spire of the savage lord'] = 'Second Spire of the Savage Lord',
        ['you focus on the second spire of the sensei'] = 'Second Spire of the Sensei',
        ['you focus on the second spire of the warlord'] = 'Second Spire of the Warlord',
        ['you focus on the third spire of ancestors'] = 'Third Spire of Ancestors',
        ['you focus on the third spire of arcanum'] = 'Third Spire of Arcanum',
        ['you focus on the third spire of divinity'] = 'Third Spire of Divinity',
        ['you focus on the third spire of elements'] = 'Third Spire of Elements',
        ['you focus on the third spire of enchantment'] = 'Third Spire of Enchantment',
        ['you focus on the third spire of holiness'] = 'Third Spire of Holiness',
        ['you focus on the third spire of nature'] = 'Third Spire of Nature',
        ['you focus on the third spire of necromancy'] = 'Third Spire of Necromancy',
        ['you focus on the third spire of savagery'] = 'Third Spire of Savagery',
        ['you focus on the third spire of the minstrels'] = 'Third Spire of the Minstrels',
        ['you focus on the third spire of the pathfinders'] = 'Third Spire of the Pathfinders',
        ['you focus on the third spire of the rake'] = 'Third Spire of the Rake',
        ['you focus on the third spire of the reavers'] = 'Third Spire of the Reavers',
        ['you focus on the third spire of the savage lord'] = 'Third Spire of the Savage Lord',
        ['you focus on the third spire of the sensei'] = 'Null Spire of the Sensei',
        ['you focus on the third spire of the warlord'] = 'Third Spire of the Warlord',
        ['you forego caution and steel yourself for a final stand'] = 'Final Stand Discipline',
        ['you gather your strength'] = 'Glyph of Courage',
        ['you have not obeyed orders!'] = 'Discipline',
        ['you instincts take over as you avoid every attack'] = 'Fortitude Discipline',
        ['you life force burns away'] = 'Life Burn',
        ['you lower your defenses to add strength to your attacks'] = 'Offensive Discipline',
        ['you mask your spell casting'] = 'Silent Casting',
        ['you place yourself on the razor\'s edge'] = 'Razor\'s Edge Discipline',
        ['you prepare to deftly avoid the next magical attack'] = 'Spell Evasion Discipline',
        ['you raise your shield to deflect incoming attacks'] = 'Deflection Discipline',
        ['you raise your shield with determined strength to deflect incoming attacks'] = 'Rampart Discipline III',
        ['you raise your shield with renewed strength to deflect incoming attacks'] = 'Rampart Discipline II',
        ['you shift to a lithe defensive stance'] = 'DoN Fleet-Footed Discipline',
        ['you speed up to match the beat of the music'] = 'Quick Time',
        ['you steel your mind and will'] = 'Unflinching Will Discipline',
        ['you steel yourself for a last stand'] = 'Last Stand Discipline',
        ['you step into the dream world'] = 'Dreamwalk Discipline',
        ['you succumb to the slaver\'s command'] = 'Discipline of Slaves',
        ['you take careful aim'] = 'Knifeplay Discipline',
        ['you will your wounds to close'] = 'Healing Will Discipline',
        ['your armor shimmers with radiance'] = 'Warrior\'s Auspice Effect III',
        ['your arms begin to move faster'] = 'Speed Focus Discipline',
        ['your arms feel alive with mystic energy'] = 'Kinesthetics Discipline',
        ['your attacks flow perfectly together'] = 'Twisted Chance Discipline',
        ['your attacks take on deadly precision'] = 'Deadly Precision Discipline',
        ['your blood boils with rage'] = 'Unpredictable Rage Discipline',
        ['your body becomes as hard as stone'] = 'Stonewall Discipline',
        ['your body becomes impenetrable'] = 'Impenetrable Discipline',
        ['your body becomes one with the earth'] = 'Stonestance Discipline',
        ['your body blurs as you take on the spirit of the monkey'] = 'Monkey\'s Spirit Discipline',
        ['your body channels the spirits of battle'] = 'Frenzy of Spirit',
        ['your body is filled with silent fury'] = 'Silentfist Discipline',
        ['your body is surrounded in an aura of sanctification'] = 'Sanctification Discipline',
        ['your bow crackles with natural energy'] = 'Trueshot Discipline',
        ['your eyes tingle'] = 'Spiritual Discipline',
        ['your feet glow with mystic power'] = 'Thunderkick Discipline',
        ['your fists begin to blur'] = 'Hundred Fists Discipline',
        ['your focus becomes perfect'] = 'Charge Discipline',
        ['your focus on the third spire of the sensei decreases'] = 'Null Spire of the Sensei Minor Effect II',
        ['your focus on the third spire of the sensei increases'] = 'Null Spire of the Sensei Major Effect III',
        ['your hand steadies, sharpening your aim'] = 'Deadly Aim Discipline',
        ['your hands clench with fatal fervor'] = 'Ashenhand Discipline',
        ['your hands clench with steely fervor'] = 'Ironfist Discipline',
        ['your hands speeds up'] = 'Blinding Speed Discipline',
        ['your healing power temporarily forks in two'] = 'Healing Twincast',
        ['your healing spells are strengthened'] = 'Ruaabri\'s Reckless Renewal',
        ['your heart pounds as your movements quicken'] = 'Frenzied Stabbing Discipline',
        ['your inner focus aligns'] = 'Concentration Discipline',
        ['your instincts are sharpened by the auspice of the hunter'] = 'Auspice of the Hunter',
        ['your instincts take over as you turn aside every attack'] = 'Whirlwind Discipline',
        ['your magic is serenely focused'] = 'Serenity\'s Twincast',
        ['your magic splits'] = 'Twincast',
        ['your mind is lost'] = 'Discipline Unbound',
        ['your mind sharpens and strength flows into your body'] = 'Intensity of the Resolute',
        ['your muscles bulge with brutal power'] = 'Brutal Onslaught Discipline',
        ['your muscles bulge with malicious power'] = 'Malicious Onslaught Discipline',
        ['your muscles bulge with savage power'] = 'Savage Onslaught Discipline',
        ['your muscles bulge with the force of will'] = 'Innerflame Discipline',
        ['your muscles quiver with power'] = 'Duelist Discipline',
        ['your regimented discipline hastens your attacks'] = 'Rapid Kick Discipline',
        ['your skin glows with dark energy'] = 'Leechcurse Discipline',
        ['your voice becomes perfectly melodious'] = 'Puretone Discipline',
        ['your weapon is bathed in a hallowed light'] = 'Hallowforge Discipline',
        ['your weapon is bathed in a holy light'] = 'Holyforge Discipline',
        ['your weapon is bathed in a pure light'] = 'Pureforge Discipline',
        ['your weapons begin to spin'] = 'Weapon Shield Discipline',
        ['your weapons crackle with natural energy'] = 'Bosquestalker\'s Discipline',
        ['your weapons move with uncanny grace'] = 'Counterattack Discipline',
        ['your will becomes indomitable'] = 'Indomitable Discipline',
        ['your will drives fear from your mind'] = 'Fearless Discipline',
        ['your wounded state fills you with rage'] = 'Wounded Rage Discipline',
    },
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
    -- User-defined raid event triggers. Each trigger watches every
    -- chat line for its pattern and fires an overlay alert + beep
    -- when matched. Useful for boss mechanics: "begins casting Death
    -- Touch" -> warning popup + audible alert.
    --
    -- Each trigger is a table with:
    --   pattern      = substring to match (case-insensitive)
    --   label        = text shown on the alert popup
    --   color        = "red" | "orange" | "yellow" | "white" | "blue" | "green"
    --   beep         = bool, fire /beep when matched
    --   beepCount    = number of beeps (1-5)
    --   dismissAfter = seconds before alert auto-dismisses (0 = manual)
    --   mobFilter    = optional substring; only fire if line ALSO contains this
    --   enabled      = bool, disable without deleting
    triggers = {
        -- Pre-loaded examples (disabled by default). Uncomment / enable
        -- to use, or add your own via the Triggers tab.
        -- { pattern = 'begins casting Death Touch', label = 'DUCK NOW!',
        --   color = 'red', beep = true, beepCount = 3, dismissAfter = 8,
        --   enabled = false },
    },
    -- Pinned/favorite archive fights. Keys are History row keys that point
    -- at append-only archive records, so pins survive normal clear actions.
    pinnedArchiveFights = {},
    -- Use the EQ log file as the primary damage source (Gamparse-style).
    -- When true, the driver tail-reads its EQ log file and parses
    -- damage events from there. This gives complete coverage of every
    -- damage event the driver can see -- including raid members'
    -- damage that may not broadcast cleanly via MQ chat events.
    -- Heals and spells continue to use the Actors framework / MQ
    -- chat events regardless of this setting.
    --
    -- Requires "/log on" enabled in EQ. Without that, no log file
    -- exists for us to read.
    useLogParser = true,
    -- Manual override for the EQ log file path. When empty/nil, the
    -- script auto-detects via mq.TLO.EverQuest.Path() and standard
    -- naming. Set this to override -- useful when:
    --   - EQ is installed in a non-standard location
    --   - server name has spaces or unusual characters
    --   - you want to point at an archived log for offline analysis
    -- Example: 'C:\\Users\\Public\\RoF\\Project Lazarus\\Logs\\eqlog_Dorfus_Project Lazarus.txt'
    -- Set via: /healtracker logparser path <full path>
    logParserPath = '',
}



-- Debug logger: prints to the MQ/Lua console when config.debug is enabled.
-- Keep this console-only: /mqchat is an options command on some MQ builds,
-- and /echo can duplicate every debug line in copied logs.
local function debugLog(msg)
    if not config.debug then return end
    print(string.format('[HealTracker] %s', tostring(msg)))
end

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
-- Pending mob casts buffer. When a mob casts a spell BEFORE we have
-- an activeMobs scope for them (e.g. boss casts during pull/pre-combat
-- before we land first damage), we stash the cast here. When damage
-- subsequently begins on that mob, getOrCreateMobScope drains matching
-- pending casts into the new scope. Old entries (>15s) get pruned.
-- Format: { {caster=str, spell=str, ts=N}, ... }
local pendingMobCasts    = {}

-- =============================================================================
-- EQ log file tailer (driver-only, damage-only)
-- =============================================================================
--
-- Gamparse-style: read the driver's EQ log file directly to capture
-- every damage event the driver can see, including raid members'
-- damage that doesn't broadcast through MQ chat events. The log
-- captures the same lines the player sees in chat -- but importantly,
-- ALL of them, not filtered by what we hooked via mq.event.
--
-- Heals continue to come from the Actors framework (each box reports
-- its heals to the driver) since the log only sees heals within the
-- driver's range. Spells/mob spells continue from chat events.
local logTailer = {
    file        = nil,         -- io.open handle on the log file
    path        = nil,         -- full path to the log
    lastSize    = 0,           -- bytes read so far (used to detect truncation)
    enabled     = true,        -- can be toggled via /healtracker logparser on|off
    initialized = false,       -- becomes true once the first open succeeds
    lastError   = nil,         -- last error string for status display
    -- Diagnostics counters: how many polls have run, how many lines
    -- have been read, how many matched a damage pattern.
    pollCount     = 0,
    linesRead     = 0,
    linesMatched  = 0,
    lastHeartbeat = 0,
}
local damageFights       = {}

-- Helper: return the scope for `mobName`, creating it if needed.
-- Stamps `started` to now on first creation.
local function getOrCreateMobScope(mobName)
    if not mobName or mobName == '' then return nil end
    if _G.HT_IsBadDamageMobLabel and _G.HT_IsBadDamageMobLabel(mobName) then return nil end
    local s = activeMobs[mobName]
    -- If the existing scope is marked _dying (the named mob was just
    -- killed), don't return it -- we want this damage to start a fresh
    -- fight, not roll into the dying scope. Snapshot the dying scope
    -- now (so it doesn't sit in activeMobs forever waiting for idle
    -- timeout), then fall through to create a new one.
    if s and s._dying then
        if (s.count or 0) > 0 then
            -- Inline-snapshot it. We can't call snapshotFight() here
            -- because that's defined later (forward reference issues).
            -- Just freeze duration, push into damageFights, and clear.
            s.label = s.label or mobName
            s.ended = os.time()
            if not s.started then s.started = s.ended end
            s._frozenDur = math.max(1, s.ended - s.started)
            local minDamage = tonumber(config.minDamageToRecord) or 5
            if (s.total or 0) >= minDamage and not (_G.HT_IsIncomingDamageTargetName and _G.HT_IsIncomingDamageTargetName(s.label, knownChars)) then
                table.insert(damageFights, s)
                local minDur = tonumber(config.miniMinDuration) or 0
                if s._frozenDur >= minDur then
                    table.insert(miniQueue, s)
                end
            end
        end
        activeMobs[mobName] = nil
        s = nil  -- force creation of a new scope below
    end
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
            if sp and sp() then return tonumber(sp.Level()) end
            local sp2 = mq.TLO.Spawn('npc ' .. mobName)
            if sp2 and sp2() then return tonumber(sp2.Level()) end
            return nil
        end)
        if ok and lvl then s.mobLevel = lvl end
        activeMobs[mobName] = s
        if _G.HT_AttachPendingBurnsToScope then
            pcall(_G.HT_AttachPendingBurnsToScope, s)
        end

        -- Drain any pending casts whose caster name fuzzy-matches this
        -- new mob. Bosses often cast a spell BEFORE first damage lands
        -- (pull mechanic, opening cast, etc.) -- those casts get queued
        -- in pendingMobCasts and attached here when the scope appears.
        --
        -- "Fuzzy match" handles the case where the cast line uses just
        -- "Freya" but the damage line uses "Freya the Frost Giant" --
        -- if either name contains the other (case-insensitive), it's
        -- considered the same mob.
        local kept = {}
        local mobLower = mobName:lower()
        for _, p in ipairs(pendingMobCasts) do
            local cLower = (p.caster or ''):lower()
            local matches = (cLower == mobLower)
                            or (cLower ~= '' and (mobLower:find(cLower, 1, true)
                                                  or cLower:find(mobLower, 1, true)))
            if matches then
                s.mobSpells = s.mobSpells or {}
                local rec = s.mobSpells[p.spell]
                if type(rec) == 'number' then
                    rec = { count = rec, casts = {} }
                end
                if type(rec) ~= 'table' then
                    rec = { count = 0, casts = {} }
                end
                rec.count = (rec.count or 0) + 1
                rec.casts = rec.casts or {}
                table.insert(rec.casts, p.ts)
                s.mobSpells[p.spell] = rec
            else
                table.insert(kept, p)
            end
        end
        pendingMobCasts = kept
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

-- Resolve mob level at render time if the fight did not capture mobLevel.
-- Stored on _G to avoid increasing the script's top-level local count.
_G.HT_ResolveMobLevel = function(label, existingLevel)
    local lvl = tonumber(existingLevel) or 0
    if lvl > 0 then return lvl end
    if type(label) ~= 'string' or label == '' then return nil end

    local ok, found = pcall(function()
        local sp = mq.TLO.Spawn('npc "' .. label .. '"')
        if sp and sp() then
            return tonumber(sp.Level()) or nil
        end

        -- Fallback: exact name lookup can fail on some named/multi-word mobs.
        -- Try looser NPC search by name text.
        local sp2 = mq.TLO.Spawn('npc ' .. label)
        if sp2 and sp2() then
            return tonumber(sp2.Level()) or nil
        end

        return nil
    end)

    if ok and found and found > 0 then return found end
    return existingLevel
end


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
-- Returns the single live damage scope to display in the mini view.
-- Two stop conditions:
--   1. Mob dies (scope flagged _dying) -- excluded from the search.
--      Live tracker switches to the next-most-recent live mob, or
--      empty if nothing else is being engaged.
--   2. No damage for 5 seconds -- live tracker goes empty even if
--      the mob is technically still alive in zone. The full inactivity
--      timeout (config.fightTimeoutSeconds, default 8s) still fires
--      independently to snapshot the fight to damageFights[]. The
--      5s window here is just for the LIVE display.
--
-- Returns an empty 'Active' scope when nothing qualifies.
local LIVE_DISPLAY_IDLE_THRESHOLD = 10  -- seconds

local function combineActiveMobs()
    local empty = emptyDamageScope('Active')
    local nowSec = os.time()

    -- Live DPS focus rule:
    -- Prefer the active mob with the HIGHEST accumulated damage, not the
    -- newest hit. This keeps the live DPS display locked on the named/boss
    -- while AoE nukes, ripostes, rampage, or splash damage touch nearby adds.
    --
    -- Small add scopes are ignored once a larger named/boss scope exists.
    -- The old behavior picked the most-recently-damaged mob, which caused
    -- the mini/live DPS display to cycle between the named and adds.
    local best = nil
    local bestTotal = -1
    local bestLastHit = 0
    local minLiveFocusDamage = tonumber(config.minDamageToRecord) or 5

    for _, mobScope in pairs(activeMobs) do
        if not mobScope._dying then
            local lh = mobScope.lastHitAt or mobScope.started or 0
            local total = mobScope.total or 0

            -- Do not consider fully idle mobs for live display.
            if (nowSec - lh) < LIVE_DISPLAY_IDLE_THRESHOLD then
                -- If this is a tiny add scope and we already have a better
                -- boss/named candidate, leave focus on the bigger target.
                if total >= minLiveFocusDamage or not best then
                    if total > bestTotal or (total == bestTotal and lh > bestLastHit) then
                        best = mobScope
                        bestTotal = total
                        bestLastHit = lh
                    end
                end
            end
        end
    end

    if not best then return empty end

    local out = emptyDamageScope(best.label or 'Active')
    out.stats   = best.stats
    out.total   = best.total or 0
    out.count   = best.count or 0
    out.max     = best.max or 0
    out.started = best.started
    out.mobLevel = best.mobLevel
    return out
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
_G.HT_MiniQueueShownTotal = _G.HT_MiniQueueShownTotal or 0
_G.HT_MiniQueueBatchTotal = _G.HT_MiniQueueBatchTotal or 0

-- Active raid event alerts. When a trigger pattern matches a chat
-- line, an alert is pushed onto this queue. The Alerts overlay
-- window renders all active alerts and auto-dismisses them after
-- their configured timeout. Manual dismiss = click the X on the alert.
--
-- Each alert: { id, label, color, firedAt, dismissAfter, sourceLine }
local activeAlerts       = {}
local nextAlertId        = 1
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

    _G.HT_PlayerZoneCache = _G.HT_PlayerZoneCache or {}
    local now = nowMs and nowMs() or math.floor(os.clock() * 1000)
    local key = name:lower()
    local cached = _G.HT_PlayerZoneCache[key]
    if cached and (now - (cached.at or 0)) < 10000 then
        return cached.val == true
    end

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
    _G.HT_PlayerZoneCache[key] = { val = found, at = now }
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
--   archiveRange: which preset is active ('today', '24h', '7d', '30d', 'all', 'custom', 'pinned')
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
-- History performance guard: date ranges can contain thousands of fights.
-- Do not render the huge history fight list until the user picks/searches a mob.
-- Cache the dropdown mob list per archive load/range so we avoid rebuilding it every frame.
local archiveMobListCache = nil
local archiveMobListCacheKey = nil
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
    -- Deferred/cached UI rendering performance pass:
    -- Sorting/filtering large fight arrays every ImGui frame is one of the
    -- biggest UI costs during raids. Cache each visible-index result briefly.
    -- Parser data still updates in real time; this only throttles heavy UI list
    -- rebuilding to a few times per second.
    _G.HT_UIVisibleIndexCache = _G.HT_UIVisibleIndexCache or {}

    local count = #(arr or {})
    local lk = labelKey or 'label'
    local first = (arr and arr[1] and tostring(arr[1][lk] or '')) or ''
    local last = (arr and arr[count] and tostring(arr[count][lk] or '')) or ''
    local key = table.concat({
        tostring(arr or 'nil'),
        tostring(count),
        tostring((sortState and sortState.col) or 'when'),
        tostring((sortState and sortState.dir) or 'desc'),
        tostring(amountField or ''),
        tostring(search or ''),
        tostring(lk),
        first,
        last
    }, '|')

    local now = (mq and mq.gettime and mq.gettime()) or (os.time() * 1000)
    local cache = _G.HT_UIVisibleIndexCache[key]
    local ttl = (config and config.fastDpsMode) and 180 or 300
    if cache and cache.indices and ((now - (cache.t or 0)) < ttl) then
        return cache.indices
    end

    local raw = sortedFightIndices(arr, sortState, amountField)
    local out = raw
    if search and search ~= '' then
        local needle = search:lower()
        out = {}
        for _, i in ipairs(raw) do
            local fight = arr[i]
            local label = (fight and fight[lk]) or ''
            if label:lower():find(needle, 1, true) then
                table.insert(out, i)
            end
        end
    end

    -- Keep only current cache item per list key shape to avoid unbounded growth.
    if _G.HT_UIVisibleIndexCacheCount and _G.HT_UIVisibleIndexCacheCount > 20 then
        _G.HT_UIVisibleIndexCache = {}
        _G.HT_UIVisibleIndexCacheCount = 0
    end
    _G.HT_UIVisibleIndexCache[key] = { indices = out, t = now }
    _G.HT_UIVisibleIndexCacheCount = (_G.HT_UIVisibleIndexCacheCount or 0) + 1
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
    if _G.HT_SavePetOwners then pcall(_G.HT_SavePetOwners) end
    if _G.HT_SaveClassMap then pcall(_G.HT_SaveClassMap) end
end



-- Dedicated pet-owner persistence. Kept on _G instead of local helpers so this
-- file does not push the large top-level Lua chunk over the 200-local limit.
_G.HT_PetOwnersPath = function()
    local base = nil
    if dataDir then base = dataDir() end
    if base and base ~= '' then
        return string.format('%s/pet_owners.lua', base)
    end
    return string.format('%s/heal_tracker_pet_owners.lua', mq.configDir or '.')
end

_G.HT_SavePetOwners = function()
    if type(config) ~= 'table' then return false end
    config.petOwners = config.petOwners or {}
    local path = _G.HT_PetOwnersPath and _G.HT_PetOwnersPath() or nil
    if not path or path == '' then return false end
    local f = io.open(path, 'w')
    if not f then return false end
    f:write('return ')
    f:write(serialize(config.petOwners or {}))
    f:write('\n')
    f:close()
    return true
end

_G.HT_LoadPetOwners = function()
    if type(config) ~= 'table' then return false end
    local path = _G.HT_PetOwnersPath and _G.HT_PetOwnersPath() or nil
    if not path or path == '' then return false end
    local ok, data = pcall(dofile, path)
    if ok and type(data) == 'table' then
        config.petOwners = data
        return true
    end
    config.petOwners = config.petOwners or {}
    return false
end

_G.HT_ClassMapPath = function()
    local base = nil
    if dataDir then base = dataDir() end
    if base and base ~= '' then return string.format('%s/class_map.lua', base) end
    return string.format('%s/heal_tracker_class_map.lua', mq.configDir or '.')
end

_G.HT_SaveClassMap = function()
    if type(config) ~= 'table' then return false end
    config.classMap = config.classMap or {}
    local path = _G.HT_ClassMapPath and _G.HT_ClassMapPath() or nil
    if not path or path == '' then return false end
    local f = io.open(path, 'w')
    if not f then return false end
    f:write('return ')
    f:write(serialize(config.classMap or {}))
    f:write('\n')
    f:close()
    return true
end

_G.HT_LoadClassMap = function()
    if type(config) ~= 'table' then return false end
    local path = _G.HT_ClassMapPath and _G.HT_ClassMapPath() or nil
    if not path or path == '' then return false end
    local ok, data = pcall(dofile, path)
    if ok and type(data) == 'table' then config.classMap = data; return true end
    config.classMap = config.classMap or {}
    return false
end

_G.HT_NormalizeClassName = function(cls)
    cls = tostring(cls or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if cls == '' or cls == 'NULL' or cls == 'nil' then return '' end
    local low = cls:lower()
    local m = { warrior='WAR', war='WAR', cleric='CLR', clr='CLR', paladin='PAL', pal='PAL', ranger='RNG', rng='RNG', shadowknight='SHD', ['shadow knight']='SHD', shd='SHD', sk='SHD', druid='DRU', dru='DRU', monk='MNK', mnk='MNK', bard='BRD', brd='BRD', rogue='ROG', rog='ROG', shaman='SHM', shm='SHM', necromancer='NEC', necro='NEC', nec='NEC', wizard='WIZ', wiz='WIZ', magician='MAG', mage='MAG', mag='MAG', enchanter='ENC', enc='ENC', beastlord='BST', bst='BST', berserker='BER', ber='BER', zerker='BER' }
    return m[low] or cls:upper()
end

_G.HT_CleanClassActorName = function(name)
    name = tostring(name or '')
    name = name:gsub('%s%+%s+pets$', ''):gsub('%s%+%s+pet$', '')
    name = name:gsub('%s*%(%s*you%s*%)%s*$', '')
    name = name:gsub('[`' .. "'" .. ']s$', '')
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    return name
end

_G.HT_GetPlayerClass = function(name)
    name = _G.HT_CleanClassActorName(name or '')
    if name == '' or type(config) ~= 'table' then return '' end
    config.classMap = config.classMap or {}
    return tostring(config.classMap[name] or config.classMap[name:lower()] or '')
end

_G.HT_FormatNameWithClass = function(name)
    local clean = _G.HT_CleanClassActorName and _G.HT_CleanClassActorName(name or '') or tostring(name or '')
    local cls = _G.HT_GetPlayerClass and _G.HT_GetPlayerClass(clean) or ''
    if cls and cls ~= '' then return string.format('%s [%s]', tostring(name or ''), cls) end
    return tostring(name or '')
end

_G.HT_ScanRaidClasses = function(verbose)
    if shuttingDown or type(config) ~= 'table' then return 0 end
    config.classMap = config.classMap or {}
    local changed, scanned = false, 0
    local function put(name, cls)
        name = _G.HT_CleanClassActorName(name or '')
        cls = _G.HT_NormalizeClassName(cls or '')
        if name ~= '' and cls ~= '' then
            if config.classMap[name] ~= cls then config.classMap[name] = cls; changed = true end
            if knownChars then knownChars[name] = true end
            scanned = scanned + 1
        end
    end
    pcall(function()
        local size = tonumber(mq.TLO.Group.Members()) or 0
        for i = 1, size do
            local m = mq.TLO.Group.Member(i)
            if m and m() then
                local name = m.CleanName() or m.Name() or m()
                local cls = ''
                pcall(function() cls = tostring((m.Class.ShortName and m.Class.ShortName()) or (m.Class.Name and m.Class.Name()) or m.Class() or '') end)
                put(name, cls)
            end
        end
        put(MyName, mq.TLO.Me.Class.ShortName() or mq.TLO.Me.Class.Name() or mq.TLO.Me.Class() or '')
    end)
    pcall(function()
        local size = tonumber(mq.TLO.Raid.Members()) or 0
        for i = 1, size do
            local m = mq.TLO.Raid.Member(i)
            if m and m() then
                local name = m.CleanName() or m.Name() or m()
                local cls = ''
                pcall(function() cls = tostring((m.Class.ShortName and m.Class.ShortName()) or (m.Class.Name and m.Class.Name()) or m.Class() or '') end)
                put(name, cls)
            end
        end
    end)
    if changed then pcall(_G.HT_SaveClassMap) end
    if verbose then
        print(string.format('\ag[HealTracker]\ax class scan found \at%d\ax class entries%s', scanned, changed and ' and saved updates' or ''))
        if _G.HT_ClassMapPath then print('  Class map file: ' .. _G.HT_ClassMapPath()) end
    end
    return scanned
end

_G.HT_ClassAutoScanTick = function()
    if shuttingDown or not (config and config.classAutoScan ~= false) then return end
    if not isDriver or not isDriver() then return end
    if (os.time() - tonumber(_G.HT_LastClassAutoScan or 0)) < math.max(15, tonumber(config.classAutoScanSeconds) or 60) then return end
    _G.HT_LastClassAutoScan = os.time()
    pcall(_G.HT_ScanRaidClasses, false)
end

_G.HT_ClassCommand = function(args)
    args = args or {}
    config.classMap = config.classMap or {}
    local sub = tostring(args[2] or ''):lower()
    if sub == 'scan' or sub == '' then _G.HT_ScanRaidClasses(true); return end
    if sub == 'list' then
        local n = 0
        for name, cls in pairs(config.classMap or {}) do
            if n == 0 then print('\ag[HealTracker]\ax saved player classes:') end
            print(string.format('  \at%-20s\ax -> %s', name, cls)); n = n + 1
        end
        if n == 0 then print('\ay[HealTracker]\ax no saved classes yet. Use /healtracker class scan while in raid.') end
        if _G.HT_ClassMapPath then print('  Class map file: ' .. _G.HT_ClassMapPath()) end
        return
    end
    if sub == 'autoscan' then
        local v = tostring(args[3] or ''):lower()
        if v == 'on' or v == '1' or v == 'true' then config.classAutoScan = true; saveConfig(); print('\ag[HealTracker]\ax class autoscan ON'); return end
        if v == 'off' or v == '0' or v == 'false' then config.classAutoScan = false; saveConfig(); print('\ay[HealTracker]\ax class autoscan OFF'); return end
        print(string.format('\ag[HealTracker]\ax class autoscan is %s', config.classAutoScan ~= false and '\agON\ax' or '\arOFF\ax'))
        print('  Usage: /healtracker class autoscan on|off'); return
    end
    if sub == 'add' then
        if not args[3] or not args[4] then print('\ay[HealTracker]\ax usage: /healtracker class add <Name> <Class>'); return end
        config.classMap[tostring(args[3])] = _G.HT_NormalizeClassName(args[4]); saveConfig()
        print(string.format('\ag[HealTracker]\ax class mapped \at%s\ax -> %s', tostring(args[3]), tostring(config.classMap[tostring(args[3])])))
        return
    end
    if sub == 'remove' or sub == 'rm' then
        if not args[3] then print('\ay[HealTracker]\ax usage: /healtracker class remove <Name>'); return end
        config.classMap[tostring(args[3])] = nil; saveConfig()
        print(string.format('\ag[HealTracker]\ax removed class mapping for \at%s\ax', tostring(args[3]))); return
    end
    print('\ay[HealTracker]\ax usage: /healtracker class scan|list|autoscan on|off|add|remove')
end

local function loadConfig()
    local ok, data = pcall(dofile, resolvedConfigPath())
    if ok and type(data) == 'table' then
        for k, v in pairs(data) do config[k] = v end
        config.windowOpen = isDriver()
        config.miniAlphaPercent = math.max(0, math.min(100, tonumber(config.miniAlphaPercent) or 100))
        -- v3.12.4: cap old saved fight timeout values so zoning/evac stops
        -- do not take 60 seconds before the after-fight popup appears.
        config.fightTimeoutSeconds = math.min(10, math.max(1, tonumber(config.fightTimeoutSeconds) or 10))
        -- v3.11.9: allow very short fights to save as long as they have real damage.
        -- Older saved configs may still have this higher from previous builds.
        config.minDamageToRecord = math.max(10000, tonumber(config.minDamageToRecord) or 10000)
        config.miniLingerSeconds = math.max(10, tonumber(config.miniLingerSeconds) or 10)
        config.miniPosX = tonumber(config.miniPosX)
        config.miniPosY = tonumber(config.miniPosY)
        -- v3.22.2 speed build: default Fast DPS ON so live parser stays close
        -- to GamParse during 2+ group raid spam. You can still turn it off
        -- during the current session with /healtracker fastdps off if needed.
        config.fastDpsMode = true
        if type(config.pinnedArchiveFights) ~= 'table' then config.pinnedArchiveFights = {} end
    end
    if type(config.pinnedArchiveFights) ~= 'table' then config.pinnedArchiveFights = {} end
    if _G.HT_LoadPetOwners then pcall(_G.HT_LoadPetOwners) end
    if _G.HT_LoadClassMap then pcall(_G.HT_LoadClassMap) end
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
                  or attacker:match("^(.-)[`']s%s+doppelganger$")
                  or attacker:match("^(.-)[`']s%s+Doppelganger$")
                  or attacker:match("^(.-)[`']s%s+Swarm$")
    if owner and owner ~= '' then
        -- Teach knownChars about resolved owners so downstream filters
        -- pass even if the owner has never been healed.
        knownChars[owner] = true
        return owner
    end

    -- Generic possessive fallback: if the attacker has the form
    -- "<X>'s <something>", attribute common swarm/pet/proc forms to <X>.
    -- This catches enchanter doppelgangers and future named swarm pets even
    -- if the owner was not already learned in knownChars.
    local maybeOwner, petSuffix = attacker:match("^(.-)[`']s%s+(.+)$")
    if maybeOwner and maybeOwner ~= '' then
        local suffixLower = (petSuffix or ''):lower()
        if knownChars[maybeOwner]
           or suffixLower:find('pet', 1, true)
           or suffixLower:find('warder', 1, true)
           or suffixLower:find('ward', 1, true)
           or suffixLower:find('corpse', 1, true)
           or suffixLower:find('swarm', 1, true)
           or suffixLower:find('doppelganger', 1, true)
           or suffixLower:find('illusion', 1, true)
           or suffixLower:find('servant', 1, true)
           or suffixLower:find('minion', 1, true) then
            knownChars[maybeOwner] = true
            return maybeOwner
        end
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


-- Mapped multi-word pet melee parser for log-file DPS lines.
-- EQ charm/named pets can be multi-word NPC names, e.g.
--   "froglok bok knight pierces <mob> for 788 points of damage."
-- A simple first-word melee parser turns that into attacker="froglok".
-- This helper checks the saved pet-owner map first and returns the full
-- mapped pet name when the line starts with it.
_G.HT_ParseMappedPetMelee = _G.HT_ParseMappedPetMelee or function(line)
    if type(line) ~= 'string' or line == '' then return nil, nil, nil end
    if not config or not config.petOwners then return nil, nil, nil end
    local lowerLine = line:lower()
    for petName, _ in pairs(config.petOwners or {}) do
        local pet = tostring(petName or ''):gsub('^%s+', ''):gsub('%s+$', '')
        if pet ~= '' then
            local petLower = pet:lower()
            if lowerLine:sub(1, #petLower) == petLower then
                local rest = line:sub(#pet + 1)
                if rest:match('^%s+%S+%s+') then
                    local target, amountStr = rest:match('^%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point')
                    if target and amountStr then
                        return pet, target, amountStr
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

-- Bump damage stats. The `attacker` arg is the OWNER name (after pet
-- attribution) -- this is what the table aggregates by. The optional
-- `rawName` is the original chat-line attacker name; if it differs
-- from the owner, the damage is also tracked as a sub-entry under
-- s.pets[rawName] so the UI can show pet-vs-owner contributions.
local function bumpDamageScope(scope, attacker, target, amount, rawName, dmgType)
    scope.stats[attacker] = scope.stats[attacker] or
        { total = 0, count = 0, max = 0, targets = {}, pets = {}, dmgTypes = {},
          firstHit = nil, lastHit = nil }
    local s = scope.stats[attacker]

    -- Damage Type Breakdown storage.  This is intentionally stored per
    -- attacker while parsing so the UI can display melee/spell/proc/DoT/pet/swarm
    -- totals without re-reading or re-classifying old log lines.
    dmgType = tostring(dmgType or 'auto'):lower()
    if rawName and rawName ~= attacker then
        local rn = tostring(rawName):lower()
        if rn:find('doppelganger', 1, true)
           or rn:find('servant', 1, true)
           or rn:find('minion', 1, true)
           or rn:find('swarm', 1, true) then
            dmgType = 'swarm'
        elseif dmgType == 'auto' or dmgType == '' or dmgType == 'melee' then
            dmgType = 'pet'
        end
    end
    if dmgType == 'nuke' or dmgType == 'nonmelee' then dmgType = 'spell' end
    if dmgType ~= 'melee' and dmgType ~= 'spell' and dmgType ~= 'proc'
       and dmgType ~= 'dot' and dmgType ~= 'pet' and dmgType ~= 'swarm' then
        dmgType = 'melee'
    end
    s.dmgTypes = s.dmgTypes or {}
    s.dmgTypes[dmgType] = s.dmgTypes[dmgType] or { total = 0, count = 0, max = 0 }
    s.dmgTypes[dmgType].total = s.dmgTypes[dmgType].total + amount
    s.dmgTypes[dmgType].count = s.dmgTypes[dmgType].count + 1
    if amount > (s.dmgTypes[dmgType].max or 0) then s.dmgTypes[dmgType].max = amount end

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


-- Reject malformed incoming mob damage targets produced by broad melee parsing.
-- This is intentionally stored on _G instead of declared as a top-level local,
-- because this Lua script is already near the 200 local-variable limit.

-- Return true when the damage target resolves as an NPC in zone.
-- This prevents named mobs that share/overlap player names from being
-- filtered as "known character" targets, which can make live DPS stop.
-- Stored on _G to avoid adding top-level locals to this large script.
_G.HT_NpcTargetCache = _G.HT_NpcTargetCache or {}
_G.HT_NpcTargetCacheMs = _G.HT_NpcTargetCacheMs or 0
_G.HT_TargetLooksLikeNpc = function(target)
    if type(target) ~= 'string' or target == '' then return false end
    local t = target:gsub('^%s+', ''):gsub('%s+$', '')
    if t == '' then return false end

    -- Spawn TLO lookups are expensive when a raid is producing hundreds of
    -- damage lines per second. Cache both positive and negative answers for a
    -- short window so Fast DPS does not fall behind GamParse during spam.
    local now = nowMs and nowMs() or math.floor(os.clock() * 1000)
    local key = t:lower()
    local cached = _G.HT_NpcTargetCache[key]
    if cached and (now - (cached.at or 0)) < 10000 then
        return cached.val == true
    end

    local ok, found = pcall(function()
        local sp = mq.TLO.Spawn('npc "' .. t .. '"')
        if sp and sp() then return true end

        local sp2 = mq.TLO.Spawn('npc =' .. t)
        if sp2 and sp2() then return true end

        local sp3 = mq.TLO.Spawn('npc ' .. t)
        if sp3 and sp3() then return true end

        return false
    end)

    local val = ok and found == true
    _G.HT_NpcTargetCache[key] = { val = val, at = now }
    return val
end

_G.HT_IsIncomingDamageTargetName = function(target, known)
    if type(target) ~= 'string' or target == '' then return false end

    local t = target:gsub('^%s+', ''):gsub('%s+$', '')
    local tl = t:lower()

    if tl == 'you' or tl:find(' you', 1, true) then return true end
    if known and known[t] then return true end

    local verbs = {
        'hits', 'slashes', 'pierces', 'crushes', 'bashes', 'kicks',
        'strikes', 'punches', 'mauls', 'bites', 'claws', 'gores',
        'backstabs', 'frenzies'
    }

    for _, v in ipairs(verbs) do
        local suffix = tl:match('^' .. v .. '%s+(.+)$')
        if suffix then
            return true
        end

        local afterVerb = tl:match('%s+' .. v .. '%s+(.+)$')
        if afterVerb then
            if afterVerb == 'you' then return true end
            if known then
                for name in pairs(known) do
                    if type(name) == 'string' and name ~= '' and afterVerb == name:lower() then
                        return true
                    end
                end
            end
        end
    end

    return false
end



-- Reject malformed fake mob labels produced by broad incoming-hit parsing.
-- Examples:
--   "hits Draevok Boneweaver"
--   "backstabs Zaxbys"
--   "slashes SomeName"
-- Stored on _G to avoid increasing this large script's top-level local count.
_G.HT_IsBadDamageMobLabel = function(label)
    if type(label) ~= 'string' or label == '' then return false end
    local t = label:gsub('^%s+', ''):gsub('%s+$', '')
    local tl = t:lower()

    -- These words at the start mean the parser captured the combat verb
    -- as part of the mob name. A real mob fight label should not start
    -- with "hits ", "slashes ", "backstabs ", etc.
    local badStarts = {
        'hits ', 'hit ', 'slashes ', 'slash ', 'pierces ', 'pierce ',
        'crushes ', 'crush ', 'bashes ', 'bash ', 'kicks ', 'kick ',
        'strikes ', 'strike ', 'punches ', 'punch ', 'mauls ', 'maul ',
        'bites ', 'bite ', 'claws ', 'claw ', 'gores ', 'gore ',
        'backstabs ', 'backstab ', 'frenzies ', 'frenzy ',
        'rampages ', 'rampage '
    }

    for _, prefix in ipairs(badStarts) do
        if tl:sub(1, #prefix) == prefix then
            return true
        end
    end

    return false
end


local function recordDamage(rawAttacker, target, amount, dmgType)
    if not isDriver() then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if not target or target == '' then return end

    if config.debug then
        debugLog(string.format('recordDamage atk=[%s] tgt=[%s] amt=%d', tostring(rawAttacker), tostring(target), amount))
    end

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

    -- Normalize the target name. EQ produces a few quirky forms:
    --   "<X>'s pet hits on <Target> for ..."  -- some pets use "hits on"
    --   "<X> hits on <Target>"                -- ditto for some attacks
    --   trailing punctuation / whitespace
    -- Without this, the same boss can show up as both "Ladonna" and
    -- "on Ladonna" in the parser, splitting the fight.
    if type(target) == 'string' then
        target = target:gsub('^%s+', ''):gsub('%s+$', '')
        -- Strip leading "on " (and "On ") -- only if followed by a
        -- non-empty rest, so we don't accidentally turn the literal
        -- mob name "on a goblin" into "a goblin" if such a thing existed.
        local stripped = target:match('^[Oo]n%s+(.+)$')
        if stripped and stripped ~= '' then target = stripped end
        -- Strip trailing punctuation that sometimes leaks in from
        -- different EQ chat variants.
        target = target:gsub('[%s%.,!]+$', '')

        -- Normalize compressed possessive-form pet names. EQ writes the
        -- same pet two ways:
        --   "a greater skeleton`s pet" (informational lines, with spaces)
        --   "agreaterskeleton`s pet"   (damage lines, possessive compressed)
        -- Without normalization these become two separate scopes that
        -- never merge, polluting the active-mobs list.
        --
        -- Strategy: when we see a possessive-pet target, check if any
        -- existing activeMobs entry has the SAME name with spaces stripped.
        -- If so, route this damage to that canonical entry.
        local petOwner = target:match("^(.+)[`']s%s+pet$")
        if petOwner and not petOwner:find('%s') then
            -- petOwner is a single word -- might be compressed.
            local compressedKey = petOwner:lower()
            for activeName, _ in pairs(activeMobs) do
                local activeOwner = activeName:match("^(.+)[`']s%s+pet$")
                if activeOwner and activeOwner ~= petOwner then
                    -- Strip spaces and compare lowercase. If they match,
                    -- this is the same pet.
                    if activeOwner:gsub('%s', ''):lower() == compressedKey then
                        -- Re-route to the canonical (spaced) name.
                        target = activeName
                        break
                    end
                end
            end
        end
    end

    if _G.HT_IsBadDamageMobLabel and _G.HT_IsBadDamageMobLabel(target) then
        if config.debug and debugLog then
            debugLog(string.format('SKIP: malformed damage target ignored (%s)', tostring(target)))
        end
        return
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
    -- Some named mobs can match names in knownChars or player lookups.
    -- If the target resolves as an NPC, keep the damage and allow the
    -- live DPS scope to be created. This fixes fights like "Ture" being
    -- skipped with: SKIP: incoming mob/player damage target ignored.
    local targetLooksNpc = (_G.HT_TargetLooksLikeNpc and _G.HT_TargetLooksLikeNpc(target)) or false

    if (not targetLooksNpc) and _G.HT_IsIncomingDamageTargetName and _G.HT_IsIncomingDamageTargetName(target, knownChars) then
        if config.debug and debugLog then
            debugLog(string.format('SKIP: incoming mob/player damage target ignored (%s)', tostring(target)))
        end
        return
    end

    if (not targetLooksNpc) and knownChars[target] then return end
    if (not targetLooksNpc) and isPlayerInZone and isPlayerInZone(target) then return end

    -- Reject possessive-form pet targets ("X's pet", "X's warder", etc.).
    -- These are pets/wards belonging to mobs (or rarely PCs) -- we
    -- don't want them creating fight entries. Mob pets clutter the
    -- parse with low-damage transient scopes that never close cleanly
    -- (Spawn TLO can't resolve possessive names, and they rapidly
    -- come and go). Damage from your raid hitting these pets is
    -- still recorded but rolls up under whatever the target ACTUALLY
    -- is rather than creating a separate "X's pet" fight entry.
    if type(target) == 'string' and target:match("[`']s%s+%S+$") then
        if config.debug then
            debugLog(string.format('SKIP: pet-target damage ignored (%s)', target))
        end
        return
    end

    fightActive  = true
    lastDamageAt = nowMs()

    -- Per-mob routing: each mob has its own scope. Damage to mob X
    -- goes only into mob X's scope, so when X dies, ONLY X's totals
    -- snapshot. Other mobs' scopes continue independently.
    --
    -- Same-name mob safety:
    -- Older builds used killGraceMs to force any damage to the same mob
    -- name back into the just-saved fight. That broke back-to-back pulls
    -- of two mobs with the same name: the first hits on mob #2 were added
    -- to mob #1, so mob #2 never got its own active scope / popup entry.
    --
    -- With immediate snapshot-on-kill, prefer correctness for live fights:
    -- damage after a kill starts a fresh scope, even if the displayed mob
    -- name is identical. The minDamageToRecord filter prevents one-tick
    -- corpse noise from becoming saved parses.

    -- Lazy fight-start: the scope's started timestamp is stamped on
    -- creation (first damage event for that mob).
    local mobScope = getOrCreateMobScope(target)
    if not mobScope then return end

    -- Don't update lastHitAt if the scope is already marked dying.
    -- Post-death DoT ticks would otherwise keep extending the activity
    -- timer and prevent the watchdog from snapshotting the fight.
    -- The damage values are still recorded into the scope (just without
    -- shifting the dying flag back to alive).
    if not mobScope._dying then
        mobScope.lastHitAt = os.time()
    end

    bumpDamageScope(mobScope, attacker, target, amount, rawName, dmgType)
end



-- Turbo Batch DPS support. Fast parser lines are aggregated during one log poll
-- and then applied as compact hit batches. This avoids doing the full fight
-- routing/bookkeeping for every single hit line while preserving totals, hit
-- counts, max hit, damage type breakdowns, and pet sub-rows.
_G.HT_TurboBatchActive = false
_G.HT_TurboBatchDamage = _G.HT_TurboBatchDamage or {}

_G.HT_BumpDamageScopeBatch = function(scope, attacker, target, totalAmount, rawName, dmgType, hitCount, maxHit)
    if not scope or not attacker or not target then return end
    totalAmount = tonumber(totalAmount) or 0
    hitCount = tonumber(hitCount) or 1
    maxHit = tonumber(maxHit) or totalAmount
    if totalAmount <= 0 or hitCount <= 0 then return end

    scope.stats[attacker] = scope.stats[attacker] or
        { total = 0, count = 0, max = 0, targets = {}, pets = {}, dmgTypes = {},
          firstHit = nil, lastHit = nil }
    local s = scope.stats[attacker]

    dmgType = tostring(dmgType or 'auto'):lower()
    if rawName and rawName ~= attacker then
        local rn = tostring(rawName):lower()
        if rn:find('doppelganger', 1, true)
           or rn:find('servant', 1, true)
           or rn:find('minion', 1, true)
           or rn:find('swarm', 1, true) then
            dmgType = 'swarm'
        elseif dmgType == 'auto' or dmgType == '' or dmgType == 'melee' then
            dmgType = 'pet'
        end
    end
    if dmgType == 'nuke' or dmgType == 'nonmelee' then dmgType = 'spell' end
    if dmgType ~= 'melee' and dmgType ~= 'spell' and dmgType ~= 'proc'
       and dmgType ~= 'dot' and dmgType ~= 'pet' and dmgType ~= 'swarm' then
        dmgType = 'melee'
    end

    s.dmgTypes = s.dmgTypes or {}
    s.dmgTypes[dmgType] = s.dmgTypes[dmgType] or { total = 0, count = 0, max = 0 }
    s.dmgTypes[dmgType].total = s.dmgTypes[dmgType].total + totalAmount
    s.dmgTypes[dmgType].count = s.dmgTypes[dmgType].count + hitCount
    if maxHit > (s.dmgTypes[dmgType].max or 0) then s.dmgTypes[dmgType].max = maxHit end

    s.total = s.total + totalAmount
    s.count = s.count + hitCount
    if maxHit > (s.max or 0) then s.max = maxHit end

    local now = os.time()
    if not s.firstHit then s.firstHit = now end
    s.lastHit = now

    s.targets[target] = s.targets[target] or { total = 0, count = 0, max = 0 }
    s.targets[target].total = s.targets[target].total + totalAmount
    s.targets[target].count = s.targets[target].count + hitCount
    if maxHit > (s.targets[target].max or 0) then s.targets[target].max = maxHit end

    s.pets = s.pets or {}
    if rawName and rawName ~= attacker then
        s.pets[rawName] = s.pets[rawName] or { total = 0, count = 0, max = 0 }
        s.pets[rawName].total = s.pets[rawName].total + totalAmount
        s.pets[rawName].count = s.pets[rawName].count + hitCount
        if maxHit > (s.pets[rawName].max or 0) then s.pets[rawName].max = maxHit end
    end

    scope.total = scope.total + totalAmount
    scope.count = scope.count + hitCount
    if maxHit > (scope.max or 0) then scope.max = maxHit end
end

_G.HT_RecordDamageBatch = function(rawAttacker, target, totalAmount, dmgType, hitCount, maxHit)
    if not isDriver() then return end
    totalAmount = tonumber(totalAmount) or 0
    hitCount = tonumber(hitCount) or 1
    maxHit = tonumber(maxHit) or totalAmount
    if totalAmount <= 0 or hitCount <= 0 then return end
    if not target or target == '' then return end

    local rawName = rawAttacker or 'unknown'
    if type(rawName) == 'string' then rawName = rawName:gsub('[%s%.]+$', '') end
    local attacker = attributeDamage(rawName)
    if attacker == 'You' or attacker == 'you' then attacker = MyName end
    if rawName == 'You' or rawName == 'you' then rawName = MyName end

    if type(target) == 'string' then
        target = target:gsub('^%s+', ''):gsub('%s+$', '')
        local stripped = target:match('^[Oo]n%s+(.+)$')
        if stripped and stripped ~= '' then target = stripped end
        target = target:gsub('[%s%.,!]+$', '')
        local petOwner = target:match("^(.+)[`']s%s+pet$")
        if petOwner and not petOwner:find('%s') then
            local compressedKey = petOwner:lower()
            for activeName, _ in pairs(activeMobs) do
                local activeOwner = activeName:match("^(.+)[`']s%s+pet$")
                if activeOwner and activeOwner ~= petOwner then
                    if activeOwner:gsub('%s', ''):lower() == compressedKey then
                        target = activeName
                        break
                    end
                end
            end
        end
    end

    if _G.HT_IsBadDamageMobLabel and _G.HT_IsBadDamageMobLabel(target) then return end

    local targetLooksNpc = (_G.HT_TargetLooksLikeNpc and _G.HT_TargetLooksLikeNpc(target)) or false
    if (not targetLooksNpc) and _G.HT_IsIncomingDamageTargetName and _G.HT_IsIncomingDamageTargetName(target, knownChars) then return end
    if (not targetLooksNpc) and knownChars[target] then return end
    if (not targetLooksNpc) and isPlayerInZone and isPlayerInZone(target) then return end
    if type(target) == 'string' and target:match("[`']s%s+%S+$") then return end

    fightActive  = true
    lastDamageAt = nowMs()

    local mobScope = getOrCreateMobScope(target)
    if not mobScope then return end
    if not mobScope._dying then mobScope.lastHitAt = os.time() end

    _G.HT_BumpDamageScopeBatch(mobScope, attacker, target, totalAmount, rawName, dmgType, hitCount, maxHit)
end

_G.HT_QueueOrRecordDamage = function(rawAttacker, target, amount, dmgType)
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if _G.HT_TurboBatchActive then
        _G.HT_TurboBatchDamage = _G.HT_TurboBatchDamage or {}
        local key = tostring(rawAttacker or '') .. '\t' .. tostring(target or '') .. '\t' .. tostring(dmgType or 'melee')
        local r = _G.HT_TurboBatchDamage[key]
        if not r then
            r = { attacker = rawAttacker, target = target, dmgType = dmgType, total = 0, count = 0, max = 0 }
            _G.HT_TurboBatchDamage[key] = r
        end
        r.total = r.total + amount
        r.count = r.count + 1
        if amount > (r.max or 0) then r.max = amount end
    else
        recordDamage(rawAttacker, target, amount, dmgType)
    end
end

_G.HT_FlushTurboBatchDamage = function()
    local b = _G.HT_TurboBatchDamage
    if not b then return end
    _G.HT_TurboBatchActive = false
    for _, r in pairs(b) do
        if r and r.total and r.total > 0 then
            _G.HT_RecordDamageBatch(r.attacker, r.target, r.total, r.dmgType, r.count, r.max)
        end
    end
    _G.HT_TurboBatchDamage = {}
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
    if _G.HT_IsBadDamageMobLabel and _G.HT_IsBadDamageMobLabel(mobName) then
        activeMobs[mobName] = nil
        return
    end

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

    -- Skip recording the fight entirely if it's too small to be
    -- interesting. Boss encounters generate dozens of "fight" entries
    -- for adds/pets that take 1-3s and 5-15k damage each. These flood
    -- the parse and obscure the actual boss kill. Default threshold:
    -- 100k damage. Boss-class fights blow past this, trash doesn't.
    local minDamage = tonumber(config.minDamageToRecord) or 5
    if (_G.HT_IsBadDamageMobLabel and _G.HT_IsBadDamageMobLabel(mobDmgScope.label or mobName)) or (mobDmgScope.total or 0) < minDamage then
        if config.debug then
            print(string.format('\ay[HealTracker]\ax skipped %s from parse (only %s damage, threshold %s)',
                mobName, fmtNum(mobDmgScope.total or 0), fmtNum(minDamage)))
        end
        -- Still remove from activeMobs (it's dead/done) but don't
        -- record it anywhere. If this was the last active mob, also
        -- clear the shared heal/spell/live-fight state so a filtered
        -- tiny parse cannot block future last-fight popups.
        activeMobs[mobName] = nil

        local stillActiveAfterSkip = false
        for _ in pairs(activeMobs) do stillActiveAfterSkip = true; break end
        if not stillActiveAfterSkip then
            currentFight       = emptyScope(nil)
            currentSpellsFight = emptySpellsScope(nil)
            fightActive        = false
            lastDamageAt       = 0
            killGraceUntil     = 0
        end

        config._restoreTab = true
        return
    end

    table.insert(damageFights, mobDmgScope)

    -- Push onto the mini view queue so the bar displays this fight
    -- for config.miniLingerSeconds (cycling through if multiple
    -- fights queue up).
    --
    -- Skip queueing if the fight was very short (under
    -- config.miniMinDuration seconds, default 10). Boss encounters
    -- usually involve killing a swarm of trash adds whose individual
    -- fights are 1-3 seconds.
    local minDur = tonumber(config.miniMinDuration) or 0
    if mobDmgScope._frozenDur >= minDur then
        -- Queue a frozen COPY, not the live activeMobs table.
        -- Uses _G counters so we don't add locals to this very large Lua chunk.
        do
            local q = {
                label = mobDmgScope.label or mobName,
                total = mobDmgScope.total or 0,
                count = mobDmgScope.count or 0,
                max = mobDmgScope.max or 0,
                started = mobDmgScope.started,
                ended = mobDmgScope.ended,
                _frozenDur = mobDmgScope._frozenDur,
                mobLevel = mobDmgScope.mobLevel,
                stats = {},
                _queuedAt = os.time(),
            }

            for atk, s in pairs(mobDmgScope.stats or {}) do
                q.stats[atk] = s
            end

            table.insert(miniQueue, q)
            _G.HT_MiniQueueBatchTotal = (_G.HT_MiniQueueBatchTotal or 0) + 1
        end

        -- If no popup is currently timing, start the timer now.
        -- If one is already showing, DO NOT reset the timer; this lets
        -- the current popup finish, then the next queued fight appears.
        if miniQueueCurrentAt == 0 then
            miniQueueCurrentAt = os.time()
        end

        if config.debug then
            print(string.format('\ag[HealTracker]\ax queued %s for last-fight display (queue size: %d)',
                mobName, #miniQueue))
        end
    elseif config.debug then
        print(string.format('\ay[HealTracker]\ax skipped %s from popup (only %ds, threshold %ds)',
            mobName, mobDmgScope._frozenDur, minDur))
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
        local idle = (nowSec - lastHit) >= timeout

        -- Pure inactivity timeout. If no damage has been recorded for
        -- this mob in `timeout` seconds, the fight is over from our
        -- perspective. Snapshot it.
        --
        -- We do NOT use Spawn TLO checks anymore. They created too many
        -- problems:
        --   - Same-named generic mobs ("a death beetle", "a goblin
        --     worker") wandering the zone kept reading "alive" forever
        --   - Mob pets ("X`s pet") can't be resolved by Spawn TLO
        --   - Different instances of same name caused false negatives
        --
        -- Inactivity is a clean signal: no damage = no active fight.
        -- The fight may be "still going" in some cosmic sense (mob
        -- alive somewhere, raid will resume), but for parse purposes
        -- the fight ends when we stop hitting it.
        if idle then
            if (mobScope.count or 0) > 0 then
                table.insert(toSnap, mobName)
            else
                -- No damage recorded -- discard the empty scope.
                activeMobs[mobName] = nil
            end
        end
    end
    for _, mobName in ipairs(toSnap) do
        if config.debug then
            print(string.format('\ay[HealTracker]\ax MOB TIMEOUT: %s went idle, snapshotting partial fight',
                mobName))
        end
        -- Timeout snapshots should show the after-fight popup immediately.
        -- snapshotFight() appends to miniQueue; move that new popup to the
        -- front and restart the popup timer so timeout-ended fights are not
        -- hidden behind older queued popups.
        local beforeQueueCount = #miniQueue
        snapshotFight(mobName)
        if #miniQueue > beforeQueueCount then
            local timeoutPopup = table.remove(miniQueue, #miniQueue)
            table.insert(miniQueue, 1, timeoutPopup)
            miniQueueCurrentAt = os.time()
        end
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
    if not mobName or mobName == '' then return end

    local now = nowMs()
    -- Do not suppress same-name slain messages. Two trash mobs with the
    -- same displayed name can die within one second of each other; de-duping
    -- by name causes the second kill to be ignored and can leave the last
    -- fight popup queue stuck. Duplicate kill lines are harmless because
    -- snapshotFight() removes the active scope; a repeated line simply finds
    -- no active scope and records nothing.
    lastKillKey, lastKillKeyAt = mobName, now

    lastKillName = mobName
    lastKillAt   = os.time()
    killGraceUntil = nowMs() + (config.killGraceMs or 500)

    -- Mark the scope as dying so the next damage event for the same
    -- name STARTS A NEW scope rather than rolling into this one. This
    -- handles the multi-instance trash case: kill mob #1, start hitting
    -- mob #2 of the same name -- we don't want mob #2's damage to be
    -- credited under mob #1's fight entry.
    --
    -- The dying scope still gets snapshotted via inactivity timeout
    -- normally (within fightTimeoutSeconds of last hit). We're not
    -- forcing an early close here -- post-kill DoT ticks and any
    -- straggling damage to the dead mob still go into THIS scope
    -- until it idles out.
    --
    -- getOrCreateMobScope checks the _dying flag: if true, it creates
    -- a fresh scope under a uniquified key (mobName#2, mobName#3, etc)
    -- so the previous scope and the new one stay separate.
    if activeMobs[mobName] then
        -- Close the mob immediately on a slain message. The previous
        -- behavior only marked the scope as _dying and waited for the
        -- inactivity timeout, which made the after-fight DPS popup appear
        -- several seconds late and left dead mobs visible in the live DPS
        -- tracker. Late damage ticks during killGraceMs are still appended
        -- to the just-saved fight by recordDamage().
        snapshotFight(mobName)
    else
        -- No active scope found. Still update last-kill state so the UI
        -- shows the kill name, but do not create an empty parse.
        lastKillName = mobName
        lastKillAt   = os.time()
    end

    if config.debug then
        print(string.format('\ay[HealTracker]\ax KILL closed immediately: %s',
            mobName))
    end
end

-- =============================================================================
-- Raid event triggers
-- =============================================================================
--
-- evaluateTriggers walks every active trigger and fires an alert if
-- its pattern (substring, case-insensitive) appears in the chat line.
-- Called from a generic catch-all event hooked in bindLocalEvents.
--
-- Action chain on match:
--   1. Push an alert onto activeAlerts (rendered by drawAlertsWindow)
--   2. Fire /beep N times (spaced 100ms apart) if trigger.beep is true
--   3. Print to chat (yellow [HealTracker] line) for log trail

local function fireAlert(trigger, sourceLine)
    local id = nextAlertId
    nextAlertId = nextAlertId + 1

    table.insert(activeAlerts, {
        id           = id,
        label        = trigger.label or trigger.pattern or '!',
        color        = trigger.color or 'red',
        firedAt      = os.time(),
        dismissAfter = trigger.dismissAfter or 8,
        sourceLine   = sourceLine,
    })

    if trigger.beep then
        local count = math.max(1, math.min(5, trigger.beepCount or 1))
        for i = 1, count do
            local delayMs = (i - 1) * 100
            -- mq.delay can't be called from inside an event handler
            -- safely; use cmdf with delayed execution via /timed.
            mq.cmdf('/timed %d /beep', math.floor(delayMs / 100))
        end
    end

    -- Print to chat as a permanent log trail. Yellow + bold.
    print(string.format('\ay[HealTracker ALERT]\ax \aw%s\ax', trigger.label or trigger.pattern))
end

local function evaluateTriggers(line)
    if shuttingDown then return end
    if not isDriver() then return end
    if not line or line == '' then return end
    local triggers = config.triggers or {}
    if #triggers == 0 then return end

    local lowerLine = line:lower()
    for _, t in ipairs(triggers) do
        if t.enabled ~= false and t.pattern and t.pattern ~= '' then
            local needle = t.pattern:lower()
            if lowerLine:find(needle, 1, true) then
                -- Optional mob filter: only fire if mob name is also
                -- present in the line. Lets you scope a generic
                -- pattern to one specific boss.
                local mobOk = true
                if t.mobFilter and t.mobFilter ~= '' then
                    mobOk = lowerLine:find(t.mobFilter:lower(), 1, true) ~= nil
                end
                if mobOk then
                    fireAlert(t, line)
                end
            end
        end
    end
end

-- =============================================================================
-- Log tailer implementation (driver-only)
-- =============================================================================

-- Resolve the absolute path to the EQ log file.
--
-- If config.logParserPath is set, it's used verbatim (manual override).
-- Otherwise we auto-detect using mq.TLO.EverQuest.Path() and the
-- character/server name. EQ's log filename uses the server name AS-IS
-- (with spaces preserved) -- e.g. "eqlog_Dorfus_Project Lazarus.txt"
-- on a server called "Project Lazarus".
--
-- We try several path variants since different EQ installs and
-- emulator servers vary slightly in directory structure.
local function logTailerPath()
    local server = mq.TLO.EverQuest.Server() or 'unknown'
    local char = MyName or 'unknown'

    -- Manual override. Two forms accepted:
    --   1. Full file path -- used as-is (legacy form, must match the
    --      current character's filename or it'll be wrong)
    --   2. Directory only -- auto-fills the filename per character.
    --      We detect "directory" by checking if it doesn't end in .txt
    --      AND it doesn't contain "eqlog_". This is the recommended
    --      form: set the Logs directory once, every character builds
    --      its own filename automatically.
    if config.logParserPath and config.logParserPath ~= '' then
        local p = config.logParserPath
        local lower = p:lower()
        local looksLikeFile = lower:find('%.txt$') or lower:find('eqlog_')
        if looksLikeFile then
            return p
        else
            -- Treat as directory; append per-character filename.
            -- Strip trailing slashes/backslashes for clean concat.
            p = p:gsub('[\\/]+$', '')
            return string.format('%s\\eqlog_%s_%s.txt', p, char, server)
        end
    end

    -- Full auto-detect via MQ TLO.
    local ok, path = pcall(function()
        local eqPath = mq.TLO.EverQuest.Path() or ''
        if eqPath == '' then return nil end
        return string.format('%s\\Logs\\eqlog_%s_%s.txt',
            eqPath, char, server)
    end)
    if not ok or not path then return nil end
    return path
end

-- Open or re-open the log file. Idempotent.
local function logTailerOpen()
    if not config.useLogParser then return false end
    if logTailer.file then
        pcall(function() logTailer.file:close() end)
        logTailer.file = nil
    end
    local path = logTailerPath()
    if not path then
        logTailer.lastError = 'cannot resolve EQ log path'
        return false
    end
    local f, err = io.open(path, 'rb')
    if not f then
        logTailer.lastError = string.format('open failed: %s', err or '?')
        return false
    end
    -- On first open, seek to end so we don't replay history.
    if not logTailer.initialized then
        f:seek('end')
        logTailer.lastSize = f:seek()
        logTailer.initialized = true
    else
        local sz = f:seek('end')
        if sz < (logTailer.lastSize or 0) then
            -- Log was rotated. Start fresh.
            logTailer.lastSize = sz
        else
            f:seek('set', logTailer.lastSize or 0)
        end
    end
    logTailer.file = f
    logTailer.path = path
    logTailer.lastError = nil
    return true
end

-- Strip "[Sun Nov 09 22:32:14 2025] " prefix from a log line.
local function stripLogTimestamp(line)
    local stripped = line:match('^%[[^%]]+%]%s*(.+)$')
    return stripped or line
end

-- Combat line processor. Tries each damage pattern in order and
-- routes any matched event into recordDamage. Mirrors the logic in
-- the chat-event handlers, but operates on log-file lines.
--

-- Observed burn / discipline tracking from visible EQ flavor lines.
-- These lines can be seen for players outside your own team, so this watches
-- the raw log text instead of relying on group/raid membership. Matching burns
-- are attached to all active mob scopes so DPS Compare can show discipline
-- timing for any parsed player.
_G.HT_PendingBurnEvents = _G.HT_PendingBurnEvents or {}

_G.HT_CleanCompareActorName = _G.HT_CleanCompareActorName or function(n)
    n = tostring(n or '')
    n = n:gsub('%s%+%s+pets$', '')
    n = n:gsub('%s%+%s+pet$', '')
    n = n:gsub('%s*%(%s*you%s*%)%s*$', '')
    n = n:gsub('[`' .. "'" .. ']s$', '')
    n = n:gsub('^%s+', ''):gsub('%s+$', '')
    return n
end


_G.HT_ResolveObservedPlayerClass = _G.HT_ResolveObservedPlayerClass or function(player)
    player = _G.HT_CleanCompareActorName(player or '')
    if player == '' then return nil end
    if _G.HT_GetPlayerClass then
        local mapped = _G.HT_GetPlayerClass(player)
        if mapped and mapped ~= '' then return tostring(mapped):lower() end
    end
    local cls = nil
    pcall(function()
        local sp = mq.TLO.Spawn(string.format('pc =%s', player))
        if sp and sp() then
            local c = sp.Class()
            if c and c() then cls = tostring(c() or '') end
            if (not cls or cls == '') and sp.Class.ShortName then cls = tostring(sp.Class.ShortName() or '') end
        end
    end)
    if cls and cls ~= '' then return cls:lower() end
    return nil
end

_G.HT_RecordObservedBurnEvent = _G.HT_RecordObservedBurnEvent or function(player, discName, phrase, activeScopes)
    player = _G.HT_CleanCompareActorName(player or '')
    if player == '' or player:lower() == 'you' or player:lower() == 'your' then player = MyName end
    local matchedAny = false
    for _, scope in pairs(activeScopes or {}) do
        if scope and not scope._dying then
            _G.HT_AttachBurnToScope(scope, player, tostring(discName), tostring(phrase), os.time())
            matchedAny = true
        end
    end
    if not matchedAny then
        table.insert(_G.HT_PendingBurnEvents, { player = player, name = tostring(discName), phrase = tostring(phrase), at = os.time() })
    end
    if config and config.debug then print(string.format('\ag[HT-BURN]\ax %s -> %s', tostring(player), tostring(discName))) end
    return true
end

_G.HT_AttachBurnToScope = _G.HT_AttachBurnToScope or function(scope, player, discName, phrase, ts)
    if not scope or not player or player == '' or not discName or discName == '' then return end
    scope.discBurns = scope.discBurns or {}
    player = _G.HT_CleanCompareActorName(player)
    scope.discBurns[player] = scope.discBurns[player] or {}
    ts = tonumber(ts) or os.time()
    local rel = 0
    if scope.started then rel = math.max(0, ts - scope.started) end
    -- Avoid duplicate inserts if the same line is seen twice in the same second.
    for _, rec in ipairs(scope.discBurns[player]) do
        if rec and rec.name == discName and math.abs((tonumber(rec.at) or 0) - ts) <= 1 then
            return
        end
    end
    table.insert(scope.discBurns[player], {
        name = discName,
        phrase = phrase,
        at = ts,
        rel = rel,
    })
end

_G.HT_AttachPendingBurnsToScope = _G.HT_AttachPendingBurnsToScope or function(scope)
    if not scope then return end
    local now = os.time()
    local kept = {}
    for _, b in ipairs(_G.HT_PendingBurnEvents or {}) do
        if b and b.player and b.name and (now - (tonumber(b.at) or now)) <= 30 then
            _G.HT_AttachBurnToScope(scope, b.player, b.name, b.phrase, b.at)
        elseif b and (now - (tonumber(b.at) or now)) <= 30 then
            table.insert(kept, b)
        end
    end
    _G.HT_PendingBurnEvents = kept
end

_G.HT_RecordObservedBurnLine = _G.HT_RecordObservedBurnLine or function(line, activeScopes, cfg)
    if type(line) ~= 'string' or line == '' then return false end
    cfg = cfg or config or {}
    local map = cfg.burnDiscMap or {}
    local lower = line:lower():gsub('^%s+', ''):gsub('%s+$', '')

    -- Paladin / class-specific focus messages. Project Lazarus spire lines seen on
    -- other players can be generic: "Name is filled with focus."  That phrase is
    -- shared by multiple classes, so do NOT map it globally to Wizard/Arcanum.
    -- If the visible player resolves as a Paladin, record it as the Paladin spire
    -- for melee compare. If class cannot be resolved, ignore it to avoid false burns.
    do
        local player = line:match('^%s*(.-)%s+is filled with focus%.?%s*$')
        if player and player ~= '' then
            local cls = _G.HT_ResolveObservedPlayerClass(player) or ''
            if cls:find('paladin', 1, true) or cls == 'pal' then
                return _G.HT_RecordObservedBurnEvent(player, 'Third Spire of Holiness', 'is filled with focus', activeScopes)
            end
        end
    end

    -- Armor of the Inquisitor can print with the spell name first instead of the
    -- player name first. Catch common other-player forms here.
    do
        local player = line:match("[Aa]rmor of the [Ii]nquisitor gathers around%s+(.+)[`']s body")
                    or line:match('[Aa]rmor of the [Ii]nquisitor gathers around%s+(.+)%s+body')
        if player and player ~= '' and not player:lower():find('your', 1, true) then
            return _G.HT_RecordObservedBurnEvent(player, 'Armor of the Inquisitor', 'Armor of the Inquisitor gathers around', activeScopes)
        end
    end

    for phrase, discName in pairs(map) do
        local ph = tostring(phrase or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
        if ph ~= '' then
            local a, b = lower:find(ph, 1, true)
            if a then
                local player = line:sub(1, a - 1):gsub('^%s+', ''):gsub('%s+$', '')
                player = player:gsub('[%s%.:,;%-]+$', '')
                if player == '' or player:lower() == 'you' or player:lower() == 'your' then
                    player = MyName
                end
                player = _G.HT_CleanCompareActorName(player)
                local matchedAny = false
                for _, scope in pairs(activeScopes or {}) do
                    if scope and not scope._dying then
                        _G.HT_AttachBurnToScope(scope, player, tostring(discName), tostring(phrase), os.time())
                        matchedAny = true
                    end
                end
                if not matchedAny then
                    table.insert(_G.HT_PendingBurnEvents, {
                        player = player,
                        name = tostring(discName),
                        phrase = tostring(phrase),
                        at = os.time(),
                    })
                end
                if config and config.debug then
                    print(string.format('\ag[HT-BURN]\ax %s -> %s', tostring(player), tostring(discName)))
                end
                return true
            end
        end
    end
    return false
end

-- Returns true if a damage event was recorded, false otherwise.

-- Fast DPS helper: damage lines are the overwhelming majority during raids.
-- The burn/disc scanner loops over a large phrase database, so do NOT run it
-- on obvious damage lines. This keeps live DPS much closer to GamParse under
-- heavy raid spam without disabling burn tracking for normal flavor/cast lines.
_G.HT_FastLooksLikeDamageLine = _G.HT_FastLooksLikeDamageLine or function(lowerLine)
    if type(lowerLine) ~= 'string' or lowerLine == '' then return false end
    if lowerLine:find(' for ', 1, true) and (lowerLine:find('point', 1, true) or lowerLine:find('damage', 1, true)) then return true end
    if lowerLine:find(' has taken ', 1, true) and lowerLine:find(' damage ', 1, true) then return true end
    if lowerLine:find(' was hit by ', 1, true) and lowerLine:find(' non%-melee ', 1, false) then return true end
    if lowerLine:find(' damage from ', 1, true) then return true end
    return false
end


-- Ultra-fast live DPS path. During raids most log lines are plain damage lines.
-- This bypasses the large full parser for the common formats so the mini tracker
-- stays much closer to GamParse. Returns true=recorded, false=known damage line
-- intentionally dropped, nil=not handled here; fall back to full parser.
_G.HT_LooksLikePcNameFast = _G.HT_LooksLikePcNameFast or function(name)
    if type(name) ~= 'string' or name == '' then return false end
    if #name < 3 or name:find('%s') then return false end
    if name:find('^a%s') or name:find('^an%s') or name:find('^the%s') or name:find('^A%s') or name:find('^An%s') or name:find('^The%s') then return false end
    return name:match('^[A-Z]') ~= nil
end

_G.HT_FastDamageAttackerAllowed = _G.HT_FastDamageAttackerAllowed or function(attacker)
    if not attacker or attacker == '' then return false end
    if isKnownPet and isKnownPet(attacker) then return true end
    if attributeDamage and knownChars then
        if knownChars[attributeDamage(attacker)] then return true end
    end
    return _G.HT_LooksLikePcNameFast(attacker)
end

_G.HT_FastProcessDamageLine = _G.HT_FastProcessDamageLine or function(line)
    if type(line) ~= 'string' or line == '' then return nil end
    if not line:find('damage', 1, true) and not line:find('point', 1, true) then return nil end
    if line:find(' YOU ', 1, true) or line:find(' YOU.', 1, true) or line:find(' you ', 1, true) or line:find(' you.', 1, true) then return false end
    if line:find('(Rampage)', 1, true) or line:find('healed', 1, true) or line:find('but misses', 1, true) or line:find('tries to', 1, true) then return false end

    -- "Caster hit mob for N points of non-melee damage."
    if line:find('non%-melee damage') then
        _G.htFastAtk, _G.htFastTgt, _G.htFastAmt = line:match('^(.-)%s+hit%s+(.-)%s+for%s+([%d,]+)%s+point.-non%-melee%s+damage')
        if _G.htFastAtk and _G.htFastTgt and _G.htFastAmt then
            if not _G.HT_FastDamageAttackerAllowed(_G.htFastAtk) then return false end
            _G.htFastNum = tonumber((_G.htFastAmt:gsub(',', '')))
            if _G.htFastNum and _G.htFastNum > 0 then
                if _G.HT_LooksLikePcNameFast(_G.htFastAtk) then knownChars[_G.htFastAtk] = true end
                _G.HT_QueueOrRecordDamage(_G.htFastAtk, _G.htFastTgt:gsub('[%s%.,!]+$', ''), _G.htFastNum, 'spell')
                return true
            end
        end
        return nil
    end

    -- "Mob has taken N damage from Spell by Caster." or reversed emulator forms.
    if line:find('has taken', 1, true) then
        _G.htFastTgt, _G.htFastAmt, _G.htFastMid, _G.htFastLast = line:match('^(.-)%s+has taken%s+([%d,]+)%s+damage from%s+(.-)%s+by%s+([^%.]+)%.?$')
        if _G.htFastTgt and _G.htFastAmt then
            _G.htFastTgt = _G.htFastTgt:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%s%.,!]+$', '')
            if _G.htFastTgt == 'YOU' or _G.htFastTgt == 'you' or _G.htFastTgt == MyName or knownChars[_G.htFastTgt] then return false end
            _G.htFastMid = (_G.htFastMid or ''):gsub('[%s%.]+$', '')
            _G.htFastLast = (_G.htFastLast or ''):gsub('[%s%.]+$', '')
            if knownChars[_G.htFastMid] or (isKnownPet and isKnownPet(_G.htFastMid)) or _G.HT_LooksLikePcNameFast(_G.htFastMid) then
                _G.htFastCaster = _G.htFastMid
            elseif knownChars[_G.htFastLast] or (isKnownPet and isKnownPet(_G.htFastLast)) or _G.HT_LooksLikePcNameFast(_G.htFastLast) then
                _G.htFastCaster = _G.htFastLast
            else
                return nil
            end
            _G.htFastNum = tonumber((_G.htFastAmt:gsub(',', '')))
            if _G.htFastNum and _G.htFastNum > 0 then
                if _G.HT_LooksLikePcNameFast(_G.htFastCaster) then knownChars[_G.htFastCaster] = true end
                _G.HT_QueueOrRecordDamage(_G.htFastCaster, _G.htFastTgt, _G.htFastNum, 'spell')
                return true
            end
        end
        -- "Mob has taken N damage from your Spell."
        _G.htFastTgt, _G.htFastAmt = line:match('^(.-)%s+has taken%s+([%d,]+)%s+damage from your%s+')
        if _G.htFastTgt and _G.htFastAmt then
            _G.htFastTgt = _G.htFastTgt:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%s%.,!]+$', '')
            if _G.htFastTgt == 'YOU' or _G.htFastTgt == 'you' or _G.htFastTgt == MyName or knownChars[_G.htFastTgt] then return false end
            _G.htFastNum = tonumber((_G.htFastAmt:gsub(',', '')))
            if _G.htFastNum and _G.htFastNum > 0 then
                _G.HT_QueueOrRecordDamage(MyName, _G.htFastTgt, _G.htFastNum, 'spell')
                return true
            end
        end
        return nil
    end

    -- "Attacker hits mob for N points of damage." Mapped multi-word pets are checked first.
    if line:find('points of damage', 1, true) then
        _G.htFastAtk, _G.htFastTgt, _G.htFastAmt = nil, nil, nil
        if line:sub(1, 4) == 'You ' then
            _G.htFastAtk = MyName
            _G.htFastTgt, _G.htFastAmt = line:match('^You%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point')
        else
            if _G.HT_ParseMappedPetMelee then _G.htFastAtk, _G.htFastTgt, _G.htFastAmt = _G.HT_ParseMappedPetMelee(line) end
            if not _G.htFastAtk then _G.htFastAtk, _G.htFastTgt, _G.htFastAmt = line:match("^(%S+[`']s%s+pet)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point") end
            if not _G.htFastAtk then _G.htFastAtk, _G.htFastTgt, _G.htFastAmt = line:match("^(%S+[`']s%s+warder)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point") end
            if not _G.htFastAtk then _G.htFastAtk, _G.htFastTgt, _G.htFastAmt = line:match("^(%S+[`']s%s+doppelganger)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point") end
            if not _G.htFastAtk then _G.htFastAtk, _G.htFastTgt, _G.htFastAmt = line:match('^(%S+)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point') end
        end
        if _G.htFastAtk and _G.htFastTgt and _G.htFastAmt then
            if _G.htFastTgt:find('%s+hits%s+') or _G.htFastTgt:find('%s+slashes%s+') or _G.htFastTgt:find('%s+crushes%s+') or _G.htFastTgt:find('%s+bashes%s+') then return false end
            if not _G.HT_FastDamageAttackerAllowed(_G.htFastAtk) then return false end
            _G.htFastNum = tonumber((_G.htFastAmt:gsub(',', '')))
            if _G.htFastNum and _G.htFastNum > 0 then
                if _G.HT_LooksLikePcNameFast(_G.htFastAtk) then knownChars[_G.htFastAtk] = true end
                _G.HT_QueueOrRecordDamage(_G.htFastAtk, _G.htFastTgt:gsub('[%s%.,!]+$', ''), _G.htFastNum, 'melee')
                return true
            end
        end
        return nil
    end
    return nil
end

local function processCombatLine(line)
    if shuttingDown then return false end
    if type(line) ~= 'string' or line == '' then return false end

    -- Defensive cleanup: log tailer already strips timestamps, but some
    -- MQ/chat/debug paths can still pass full EQ log lines like:
    --   [Wed May 13 20:11:08 2026] Ayehop hit The Legendary Venril Sathir for ...
    -- Strip that here too so anchored parser patterns still work.
    line = stripLogTimestamp(line)
    line = line:gsub('^%s+', ''):gsub('%s+$', '')

    -- Rune/absorb heal credit from log lines. This MUST run on every
    -- character, not just the driver, because each client sees its own
    -- rune text as "you". onLocalHeal records it locally on the driver
    -- and broadcasts it through Actors from non-drivers just like normal
    -- incoming heals.
    local lowerLine = line:lower()
    if lowerLine:find('an aspect of survival shields you', 1, true) then
        pcall(onLocalHeal, line, 'Aspect of Survival Rune', 1500)
        return true
    end
    if lowerLine:find('the platinum scales fade', 1, true) then
        pcall(onLocalHeal, line, 'Rune of Rikkukin', 2100)
        return true
    end

    if lowerLine:find('the shimmer of runes fades', 1, true) then
        pcall(onLocalHeal, line, 'Glyph Spray', 10000)
        return true
    end

    -- Only the driver should parse damage/spells/kills from the log.
    -- Non-drivers still tail the log now, but only for rune heal reports.
    if not isDriver() then
        return false
    end

    -- Drop incoming RAMPAGE lines before any damage parser can
    -- misread the mob name as a player target or create a fake fight.
    -- Example E3/common line:
    --   "<Eyehop> RAMPAGE for 3128 damage from Ture hits"
    -- All RAMPAGE hits are mob -> player damage, not outgoing DPS.
    if lowerLine:find('rampage for', 1, true)
       and lowerLine:find(' damage from ', 1, true)
       and lowerLine:find(' hits', 1, true) then
        if config.debug then
            print(string.format('\ay[HT-RAMPAGE-DROP]\ax incoming rampage ignored: %s', tostring(line)))
        end
        return true
    end

    -- Observed burn/discipline flavor lines from any visible player.
    -- Speed fix: do not run the expensive burn phrase scan on obvious damage
    -- lines. During raids, nearly every log line is damage, and scanning the
    -- full burn database before parsing each hit makes live DPS fall behind.
    if (not (_G.HT_FastLooksLikeDamageLine and _G.HT_FastLooksLikeDamageLine(lowerLine)))
       and _G.HT_RecordObservedBurnLine
       and _G.HT_RecordObservedBurnLine(line, activeMobs, config) then
        return true
    end

    -- Spell cast tracking from log lines. The chat-event handler
    -- catches "<Caster> begins to cast a spell. <Spell>" lines too,
    -- but log-based tracking is a robust fallback: any spell cast
    -- visible to the driver (in their log) gets recorded, even if
    -- the chat event missed it (out-of-range, raid filter, etc.).
    -- Required for anonymous DoT tick attribution.
    do
        -- "<Caster> begins to cast a spell. <Spell>"  (or with no period before spell)
        local caster, spell = line:match('^(.-) begins to cast a spell[%.]?%s*<(.-)>')
        if caster and spell and caster ~= '' and spell ~= '' then
            -- Strip trailing punctuation/whitespace.
            caster = caster:gsub('[%s%.]+$', '')
            spell  = spell:gsub('[%s%.]+$', '')
            -- Skip pet casts ("X`s pet begins to cast" -- attribute to owner).
            local petOwner = caster:match("^(%S+)[`']s%s+pet$")
            if petOwner then caster = petOwner end
            if recentSpellCasts then recentSpellCasts[spell] = caster end
        end
        -- "You begin casting <Spell>."
        local mySpell = line:match('^You begin casting%s+(.-)%.?%s*$')
        if mySpell and mySpell ~= '' then
            mySpell = mySpell:gsub('[%s%.]+$', '')
            if recentSpellCasts then recentSpellCasts[mySpell] = MyName end
        end
    end

    -- Kill detection from log lines. CRITICAL: without this, the log
    -- parser path doesn't snapshot fights when mobs die. The MQ chat
    -- event handlers also catch these but they may be filtered/missed
    -- in raid context. The log file is the authoritative source.
    --
    -- Two formats:
    --   "You have slain <mob>!"
    --   "<mob> has been slain by <slayer>!"
    do
        local slainSelf = line:match('^You have slain%s+(.-)%s*!?%s*$')
        if slainSelf and slainSelf ~= '' then
            slainSelf = slainSelf:gsub('[%s%.!]+$', '')
            if config.debug then
                print(string.format('\ag[HT-KILL]\ax driver killed: %s', slainSelf))
            end
            pcall(onKill, line, slainSelf)
            return true
        end
        local slainPassive, slayer = line:match('^(.-)%s+has been slain by%s+(.+)%s*!?%s*$')
        if slainPassive and slainPassive ~= '' then
            slainPassive = slainPassive:gsub('[%s%.!]+$', '')
            -- Skip if the slain target is a known PC (group/raid death).
            if not knownChars[slainPassive] then
                if config.debug then
                    print(string.format('\ag[HT-KILL]\ax %s slain by %s',
                        slainPassive, tostring(slayer)))
                end
                pcall(onKill, line, slainPassive)
                return true
            end
        end
    end

    local hasPoints = line:find('points', 1, true)
    local hasTaken  = line:find('has taken', 1, true)
    if not hasPoints and not hasTaken then return false end

    -- Helper: "looks like a PC name". Single capitalized word, no
    -- generic mob article prefixes. Used to populate knownChars
    -- from log activity so we don't depend on the raid TLO scan.
    -- This is permissive on purpose -- false positives (a mob with a
    -- proper-noun-looking name) just mean we record their damage too,
    -- which is fine for the log-parser path.
    local function looksLikePcName(name)
        if type(name) ~= 'string' or name == '' then return false end
        if name:find('^a%s') or name:find('^an%s')
           or name:find('^the%s') or name:find('^A%s')
           or name:find('^An%s') or name:find('^The%s') then
            return false
        end
        -- First char uppercase, rest mostly lowercase with optional
        -- single trailing word for charm pets.
        if not name:match('^[A-Z]') then return false end
        -- Reject single/two-letter "names". When the regex captures
        -- just "A" from "A jack o lantern hits Eyehop`s pet for X",
        -- the single letter passes the capitalized-first-letter check
        -- but obviously isn't a real PC name. EQ PC names are 3+ chars.
        if #name < 3 then return false end
        -- EQ player names are single words. Multi-word names here are
        -- almost always NPCs/named mobs (ex: Arena Terris Thule).
        -- Without this, named pets like Hooker attacking a multi-word
        -- boss can be dropped as a fake player-vs-player line.
        if name:find('%s') then return false end
        return true
    end

    -- ------------------------------------------------------------------
    -- Spell damage: "<target> has taken <N> damage from <X> by <Y>"
    -- ------------------------------------------------------------------
    if hasTaken then
        -- Strip leading/trailing whitespace defensively. EQ log lines
        -- can have stray whitespace (especially after timestamp strip)
        -- and Project Lazarus / emulator servers sometimes inject
        -- non-printing characters that confuse anchored regexes.
        local cleanLine = line:gsub('^%s+', ''):gsub('%s+$', '')

        -- Try the strict regex first.
        local target, amountStr, mid, last =
            cleanLine:match('^(.-) has taken ([%d,]+) damage from (.-) by ([^%.]+)%.?$')

        -- Fallback: same regex but UNANCHORED at the end. Catches lines
        -- with trailing junk after the period (rare but seen on some
        -- emulator servers).
        if not target then
            target, amountStr, mid, last =
                cleanLine:match('(.-)%s+has taken%s+([%d,]+)%s+damage from%s+(.-)%s+by%s+(.+)$')
        end

        if config.debug then
            print(string.format('\ay[HT-SP]\ax target=[%s] amt=[%s] mid=[%s] last=[%s]',
                tostring(target), tostring(amountStr), tostring(mid), tostring(last)))
            -- If match failed, dump the raw bytes to detect hidden chars.
            if not target then
                local bytes = ''
                for i = 1, math.min(#cleanLine, 100) do
                    bytes = bytes .. string.format('%02X ', cleanLine:byte(i))
                end
                print(string.format('\ar[HT-SP-FAIL]\ax bytes: %s', bytes))
                print(string.format('\ar[HT-SP-FAIL]\ax len=%d  line=[%s]',
                    #cleanLine, cleanLine))
            end
        end
        -- Drop mob -> player spell damage before it reaches recordDamage().
        -- Example to ignore:
        --   "Zaxbys has taken 713 damage from Overlord Mata Muram by Torment of Body."
        -- These incoming AE/DoT lines are not group DPS and can make the
        -- live tracker switch to a player name or go blank.
        if target then
            target = target:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%s%.,!]+$', '')
            if target == 'YOU' or target == 'you' or target == MyName
               or knownChars[target]
               or (isPlayerInZone and isPlayerInZone(target)) then
                if config.debug then
                    debugLog(string.format('DROP spell damage to player target=[%s] src=[%s] spell=[%s]',
                        tostring(target), tostring(mid), tostring(last)))
                end
                return false
            end
        end

        if target and amountStr then
            local amount = tonumber((amountStr:gsub(',', '')))
            if amount and amount > 0 then
                mid  = (mid or ''):gsub('[%s%.]+$', '')
                last = (last or ''):gsub('[%s%.]+$', '')

                -- Pick whichever capture is the caster vs spell name.
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
                    -- Last resort: default to mid (Format B is more
                    -- common on Project Lazarus and similar emulator
                    -- servers). Better to attribute to *something* than
                    -- to silently drop the damage.
                    caster = mid
                end

                if config.debug then
                    print(string.format('\ay[HT-SP]\ax disambiguated caster=[%s]',
                        tostring(caster)))
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

        -- "from your <Spell>"
        if line:find(' from your ', 1, true) and not line:find(' by ', 1, true) then
            local target2, amountStr2 =
                line:match('^(.-) has taken ([%d,]+) damage from your ')
            if target2 and amountStr2 then
                target2 = target2:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%s%.,!]+$', '')
                if target2 == 'YOU' or target2 == 'you' or target2 == MyName
                   or knownChars[target2]
                   or (isPlayerInZone and isPlayerInZone(target2)) then
                    if config.debug then
                        debugLog(string.format('DROP your-spell damage to player target=[%s]', tostring(target2)))
                    end
                    return false
                end
                local amount = tonumber((amountStr2:gsub(',', '')))
                if amount and amount > 0 then
                    recordDamage(MyName, target2, amount, 'spell')
                    return true
                end
            end
        end

        -- Anonymous DoT tick
        if not line:find(' by ', 1, true) and not line:find(' from your ', 1, true) then
            local target3, amountStr3, spell3 =
                line:match('^(.-) has taken ([%d,]+) damage from (.+)%.?$')
            if target3 and amountStr3 and spell3 then
                target3 = target3:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%s%.,!]+$', '')
                if target3 == 'YOU' or target3 == 'you' or target3 == MyName
                   or knownChars[target3]
                   or (isPlayerInZone and isPlayerInZone(target3)) then
                    if config.debug then
                        debugLog(string.format('DROP anonymous spell damage to player target=[%s]', tostring(target3)))
                    end
                    return false
                end
                local amount = tonumber((amountStr3:gsub(',', '')))
                spell3 = spell3:gsub('[%s%.]+$', '')
                local caster = recentSpellCasts and recentSpellCasts[spell3]
                if amount and amount > 0 and caster then
                    recordDamage(caster, target3, amount, 'dot')
                    return true
                end
            end
        end
    end

    -- ------------------------------------------------------------------
    -- Non-melee: "<attacker> hit <target> for <N> points of non-melee damage"
    -- ------------------------------------------------------------------
    if line:find('non%-melee damage') then
        -- Mob -> PC damage. Skip ("X hits YOU/you for N").
        if line:find(' YOU ', 1, true) or line:find(' YOU.', 1, true)
           or line:find(' you ', 1, true) or line:find(' you.', 1, true) then
            return false
        end
        local cleanLine = line:gsub('^%s+', ''):gsub('%s+$', '')
        local attacker, target, amountStr =
            cleanLine:match('^(.-)%s+hit%s+(.-)%s+for%s+([%d,]+)%s+point.-non%-melee%s+damage')
        if config.debug then
            print(string.format('\ay[HT-NM]\ax atk=[%s] tgt=[%s] amt=[%s]',
                tostring(attacker), tostring(target), tostring(amountStr)))
        end
        if attacker and target and amountStr then
            local amount = tonumber((amountStr:gsub(',', '')))
            if amount and amount > 0 then
                -- Hard gate: drop if attacker is a mob (starts with
                -- a/an/the/A/An/The article). Mob -> mob damage and
                -- mob -> PC-where-PC-isn't-named-YOU damage shouldn't
                -- be tracked. This catches lines like:
                --   "A jack o lantern hits Eyehop`s pet for 7080..."
                -- which would otherwise be parsed as group damage.
                local attributed = attributeDamage(attacker)
                if not knownChars[attributed]
                   and not isKnownPet(attacker)
                   and not looksLikePcName(attacker) then
                    if config.debug then
                        print(string.format(
                            '\ay[HT-NM-DROP]\ax non-PC attacker: %s', attacker))
                    end
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
    -- Melee: "<attacker> <verb> <target> for <N> points of damage"
    -- ------------------------------------------------------------------
    if hasPoints and line:find('points of damage') then
        if line:find('healed', 1, true) then return false end
        if line:find('was hit by non-melee', 1, true) then return false end
        if line:find('tries to', 1, true) then return false end
        if line:find('but misses', 1, true) then return false end

        -- Mob -> PC damage. EQ writes these as "X hits YOU for N" or
        -- "X hits you for N". The literal word "YOU" or "you" as the
        -- target means the player is being hit. We don't track this
        -- as it's incoming damage, not group DPS, AND the parser
        -- would otherwise create bogus fights named "suffering hits
        -- YOU" or similar by mis-extracting the multi-word attacker.
        if line:find(' YOU ', 1, true) or line:find(' YOU.', 1, true)
           or line:find(' you ', 1, true) or line:find(' you.', 1, true) then
            return false
        end

        local attacker, target, amountStr

        if line:sub(1, 4) == 'You ' then
            attacker = MyName
            local _, t2, a2 =
                line:match('^(You)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point')
            target, amountStr = t2, a2
        else
            -- Possessive-pet forms.
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
                attacker, target, amountStr =
                    line:match("^(%S+[`']s%s+doppelganger)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
            end
            if not attacker then
                attacker, target, amountStr =
                    line:match("^(%S+[`']s%s+Doppelganger)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
            end
            if not attacker then
                -- Mapped multi-word pet names must be checked before the
                -- first-word fallback. Without this, a mapped pet like
                -- "froglok bok knight" parses as attacker="froglok"
                -- and will not fold into its owner.
                if _G.HT_ParseMappedPetMelee then
                    attacker, target, amountStr = _G.HT_ParseMappedPetMelee(line)
                end
            end
            if not attacker then
                -- Generic third-person fallback. PC names are single words.
                -- Multi-word mapped pets are handled directly above.
                attacker, target, amountStr =
                    line:match("^(%S+)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
            end
        end

        if attacker and target and amountStr then
            local amount = tonumber((amountStr:gsub(',', '')))
            if not amount or amount <= 0 then return false end

            if config.debug then
                print(string.format('\ay[HT-ML]\ax atk=[%s] tgt=[%s] amt=%d',
                    tostring(attacker), tostring(target), amount))
            end

            -- Hard gate: only outgoing player/pet melee should reach recordDamage().
            -- The broad melee regex can mis-split multi-word NPC attackers:
            --   "Overlord Mata Muram hits Zaxbys for 1052... (Rampage)"
            -- used to become atk=[Overlord], tgt=[Muram hits Zaxbys]. That fake
            -- target then hijacked the live DPS display. Drop obvious incoming
            -- mob->player lines before they can create activeMobs entries.
            local attributed = attributeDamage(attacker)
            local knownByAttr = knownChars[attributed] == true
            local knownByPet  = isKnownPet(attacker) == true

            if line:find('(Rampage)', 1, true)
               or (target and target:find('%s+hits%s+'))
               or (target and target:find('%s+slashes%s+'))
               or (target and target:find('%s+crushes%s+'))
               or (target and target:find('%s+bashes%s+'))
               or (not knownByAttr and not knownByPet
                   and looksLikePcName(attacker) and looksLikePcName(target)) then
                if config.debug then
                    print(string.format(
                        '\ay[HT-ML-DROP]\ax incoming/misparsed mob hit: %s -> %s',
                        tostring(attacker), tostring(target)))
                end
                return false
            end

            if not knownByAttr
               and not knownByPet
               and not looksLikePcName(attacker) then
                if config.debug then
                    print(string.format(
                        '\ay[HT-ML-DROP]\ax non-PC attacker: %s', attacker))
                end
                return false
            end

            -- Auto-populate knownChars when we observe damage from
            -- something that looks like a PC name. Mobs attacking us
            -- get filtered out by recordDamage's target check (target
            -- == known PC -> drop).
            if looksLikePcName(attacker) then
                knownChars[attacker] = true
            end

            recordDamage(attacker, target, amount, 'melee')
            return true
        else
            if config.debug then
                print(string.format('\ar[HT-ML-FAIL]\ax line did not match: %s', line:sub(1, 80)))
            end
        end
    end

    return false
end

-- Read all new lines from the log file and feed each through the
-- combat-line processor. Called from the main loop.
local function logTailerPoll()
    if not config.useLogParser then return end
    -- Tail logs on every character. Non-drivers only use this to report
    -- local rune absorbs to the driver; damage parsing still returns
    -- immediately unless this character is the driver.
    if shuttingDown then return end

    logTailer.pollCount = (logTailer.pollCount or 0) + 1

    -- Close-reopen pattern: Lua's buffered file handles aggressively
    -- cache, and seek() doesn't always invalidate the buffer when the
    -- underlying file has new data appended. The reliable way to see
    -- new content is to close and reopen the file each poll, seeking
    -- back to where we left off.
    if logTailer.file then
        pcall(function() logTailer.file:close() end)
        logTailer.file = nil
    end

    local path = config.logParserPath
    if not path or path == '' then path = logTailerPath() end
    if not path then
        logTailer.lastError = 'cannot resolve EQ log path'
        return
    end

    local f, err = io.open(path, 'rb')
    if not f then
        logTailer.lastError = string.format('open failed: %s', err or '?')
        return
    end

    -- On first open, seek to end so we don't replay history.
    if not logTailer.initialized then
        f:seek('end')
        logTailer.lastSize = f:seek()
        logTailer.initialized = true
        logTailer.path = path
        logTailer.lastError = nil
        f:close()
        logTailer.file = nil
        print(string.format(
            '\ag[HealTracker]\ax log tailer initialized at offset %d (%s)',
            logTailer.lastSize, path))
        return
    end

    -- Resume from last known position. If the file shrank (rotation),
    -- start over from end.
    local sz = f:seek('end')
    if sz < (logTailer.lastSize or 0) then
        logTailer.lastSize = sz
    else
        f:seek('set', logTailer.lastSize or 0)
    end

    logTailer.file = f
    logTailer.path = path
    logTailer.lastError = nil

    local count = 0
    local matched = 0
    local turboBatchThisPoll = (config.fastDpsMode and isDriver() and _G.HT_FastProcessDamageLine and _G.HT_RecordDamageBatch)
    if turboBatchThisPoll then
        _G.HT_TurboBatchActive = true
        _G.HT_TurboBatchDamage = {}
    end
    while true do
        if shuttingDown then return end
        local line = logTailer.file:read('l')
        if not line then break end
        count = count + 1
        if count > (config.fastDpsMode and 1000000 or 250000) then break end
        local stripped = stripLogTimestamp(line)
        if stripped and stripped ~= '' then
            if config.debug and not (config.fastDpsMode and fightActive) then
                print(string.format('\ay[HT-LOG]\ax %s', stripped))
            end
            _G.htFastPollHit = nil
            if config.fastDpsMode and isDriver() and _G.HT_FastProcessDamageLine then
                _G.htFastPollHit = _G.HT_FastProcessDamageLine(stripped)
            end
            if _G.htFastPollHit == true then
                matched = matched + 1
            elseif _G.htFastPollHit == nil then
                local ok, hit = pcall(processCombatLine, stripped)
                if ok and hit then
                    matched = matched + 1
                elseif not ok and config.debug then
                    -- Show pcall errors so we can debug parser issues that
                    -- would otherwise be silently swallowed.
                    print(string.format('\ar[HT-ERR]\ax processCombatLine error: %s',
                        tostring(hit)))
                    print(string.format('  on line: %s', stripped:sub(1, 100)))
                end
            end
        end
    end

    if turboBatchThisPoll and _G.HT_FlushTurboBatchDamage then
        pcall(_G.HT_FlushTurboBatchDamage)
    else
        _G.HT_TurboBatchActive = false
    end

    logTailer.linesRead    = (logTailer.linesRead or 0) + count
    logTailer.linesMatched = (logTailer.linesMatched or 0) + matched
    logTailer.lastSize = logTailer.file:seek()
    pcall(function() logTailer.file:close() end)
    logTailer.file = nil

    if config.debug and count > 0 then
        print(string.format('\ay[HT-LOG]\ax read %d lines this poll, matched %d as combat',
            count, matched))
    end

    -- Heartbeat every 10 seconds when debug on. Lets you see the
    -- tailer is running even when no combat is happening.
    if config.debug then
        local now = os.time()
        if (now - (logTailer.lastHeartbeat or 0)) >= 10 then
            logTailer.lastHeartbeat = now
            print(string.format(
                '\ay[HT-LOG]\ax heartbeat: polls=%d total_lines=%d matched=%d size=%d',
                logTailer.pollCount, logTailer.linesRead,
                logTailer.linesMatched, logTailer.lastSize))
        end
    end
end

local function logTailerClose()
    if logTailer.file then
        pcall(function() logTailer.file:close() end)
        logTailer.file = nil
    end
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



    -- Rune/absorb heal credit. Project Lazarus text:
    --   "An aspect of survival shields you"
    -- Treat this as a 1500 HP protective rune landing on the local
    -- character. Each box catches its own "you" message and broadcasts
    -- it to the driver the same way normal incoming heals do.
    mq.event('heal_rune_aspect_survival',
        '#*#An aspect of survival shields you#*#',
        function(line)
            pcall(onLocalHeal, line, 'Aspect of Survival Rune', 1500)
        end)

    -- Rune/absorb heal credit. Project Lazarus text:
    --   "The platinum scales fade"
    -- Treat this as a 2100 HP protective rune that was consumed on
    -- the local character. Each box catches its own message and
    -- broadcasts it to the driver like a normal incoming heal.
    mq.event('heal_rune_platinum_scales',
        '#*#The platinum scales fade#*#',
        function(line)
            pcall(onLocalHeal, line, 'Rune of Rikkukin', 2100)
        end)


    -- Rune/absorb heal credit. Project Lazarus text:
    --   "The shimmer of runes fades"
    -- Treat this as a 10000 HP Glyph Spray rune absorb on the local character.
    -- Each box catches its own message and broadcasts it to the driver.
    mq.event('heal_rune_glyph_spray',
        '#*#The shimmer of runes fades#*#',
        function(line)
            pcall(onLocalHeal, line, 'Glyph Spray', 10000)
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
        -- When the log parser is active, the driver gets damage data
        -- from the log file instead. Skip the chat-event path to
        -- avoid double-counting. Reporters (non-driver boxes) don't
        -- run damage events at all, so this gate is a no-op for them.
        if config.useLogParser then return end
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
                attacker, target, amountStr =
                    line:match("^(%S+[`']s%s+doppelganger)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
            end
            if not attacker then
                attacker, target, amountStr =
                    line:match("^(%S+[`']s%s+Doppelganger)%s+%S+%s+(.-)%s+for%s+([%d,]+)%s+point")
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
        -- PC-in-zone fallback: catches raid allies whose names haven't
        -- been picked up by the raid TLO scan yet (the scan runs every
        -- 5s; in the first few seconds of a raid kill, some raid
        -- members may not be in knownChars yet). isPlayerInZone checks
        -- SPECIFICALLY the current zone via Spawn TLO -- it doesn't
        -- include random PCs from other zones, so it's safe.
        local knownByZone = isPlayerInZone(attributed) or isPlayerInZone(attacker)

        if not knownByAttr and not knownByPet and not knownByZone then
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

        recordDamage(attacker, target, amount, 'melee')
    end

    -- Incoming RAMPAGE lines are always mob -> player damage.
    -- Ignore them explicitly so they never reach the broad melee parser
    -- or cause a mob name to be stored as a player/known character.
    mq.event('damage_rampage_incoming',
        '#*#RAMPAGE for #*# damage from #*# hits#*#',
        function(line)
            pcall(function()
                if config.debug then
                    print(string.format('\ay[HT-RAMPAGE-DROP]\ax incoming rampage ignored: %s', tostring(line)))
                end
            end)
        end)

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
                if config.useLogParser then return end

                -- Mob -> player non-melee uses "<player> was hit by non-melee".
                -- Skip those.
                if line:find('was hit by non-melee', 1, true) then return end

                -- Parse: <attacker> hit <target> for <N> points of non-melee
                local cleanLine = stripLogTimestamp(line):gsub('^%s+', ''):gsub('%s+$', '')
                local attacker, target, amountStr =
                    cleanLine:match('^(.-)%s+hit%s+(.-)%s+for%s+([%d,]+)%s+point.-non%-melee%s+damage')
                if not attacker or not target or not amountStr then return end

                amountStr = amountStr:gsub(',', '')
                local amount = tonumber(amountStr)
                if not amount or amount <= 0 then return end

                -- Filter mob->mob and mob->player damage. Accept the
                -- attacker if any of:
                --   - knownChars (group/raid TLO scan)
                --   - mapped pet
                --   - real PC in the current zone (catches raid allies
                --     whose names haven't been picked up by the raid TLO
                --     scan yet -- the scan runs every 5s, so in the
                --     first few seconds of a raid, names may lag).
                -- We're explicit about IN-ZONE so random PCs from other
                -- zones don't pollute the parse.
                local attributed = attributeDamage(attacker)
                if not knownChars[attributed]
                   and not isKnownPet(attacker)
                   and not isPlayerInZone(attributed)
                   and not isPlayerInZone(attacker) then
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

                recordDamage(attacker, target, amount, 'spell')
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
                if config.useLogParser then return end

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
                recordDamage(attacker, '(undead)', amount, 'proc')
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
                if config.useLogParser then return end

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
                elseif isPlayerInZone(mid) then
                    -- Format B with a raid ally not yet in knownChars.
                    caster = mid
                elseif isPlayerInZone(last) then
                    -- Format A with a raid ally not yet in knownChars.
                    caster = last
                else
                    -- Neither candidate is a recognized PC. Could be a
                    -- mob's DoT or a random non-PC attacker. Drop.
                    return
                end

                recordDamage(caster, target, amount, 'spell')
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
                if config.useLogParser then return end

                -- Skip if the line has " by " -- that's the third-person
                -- form already handled by damage_spell_by.
                if line:find(' by ', 1, true) then return end

                local target, amountStr =
                    line:match('^(.-) has taken ([%d,]+) damage from your ')
                if not target then return end

                amountStr = amountStr:gsub(',', '')
                local amount = tonumber(amountStr)
                if not amount or amount <= 0 then return end

                recordDamage(MyName, target, amount, 'spell')
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
                if config.useLogParser then return end

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

                recordDamage(caster, target, amount, 'spell')
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

                -- EQ produces several variants of "begins to cast a spell"
                -- depending on era / spell / NPC type:
                --   "<Caster> begins to cast a spell. <SpellName>"  (with period and angle brackets)
                --   "<Caster> begins to cast a spell <SpellName>"   (no period, angle brackets)
                --   "<Caster> begins to cast a spell. (SpellName)"  (with period and parens)
                --   "<Caster> begins to cast a spell (SpellName)"   (no period, parens)
                --   "<Caster> begins casting <SpellName>"           (raid encounter NPCs)
                -- Try each pattern in order until one matches.
                local caster, spellName
                local patterns = {
                    '^(.-) begins to cast a spell%.%s*<(.-)>',
                    '^(.-) begins to cast a spell%s*<(.-)>',
                    '^(.-) begins to cast a spell%.%s*%((.-)%)',
                    '^(.-) begins to cast a spell%s*%((.-)%)',
                    '^(.-) begins casting%s+(.-)%.?$',
                }
                for _, pat in ipairs(patterns) do
                    caster, spellName = line:match(pat)
                    if caster and spellName then break end
                end
                if not caster or not spellName then return end

                -- Trim whitespace.
                caster = caster:match('^%s*(.-)%s*$') or caster
                spellName = spellName:match('^%s*(.-)%s*$') or spellName
                if caster == '' or spellName == '' then return end

                -- Branch: friendly cast vs mob cast.
                if knownChars[caster] then
                    -- Friendly cast -- log to spell-fights as before.
                    recordSpellCast(caster, spellName)
                    return
                end

                -- Mob cast routing. Try several strategies in order:
                --   1. Exact match in activeMobs
                --   2. Fuzzy match (caster name contains/contained-by an
                --      active mob name; handles "Freya" vs "Freya the
                --      Frost Giant")
                --   3. Buffer in pendingMobCasts; getOrCreateMobScope
                --      will drain matching pending casts when damage
                --      starts on a mob with this name (handles bosses
                --      that cast pre-engagement)
                local mobScope = activeMobs[caster]
                if not mobScope then
                    local cLower = caster:lower()
                    for activeName, s in pairs(activeMobs) do
                        local aLower = activeName:lower()
                        if aLower == cLower
                           or aLower:find(cLower, 1, true)
                           or cLower:find(aLower, 1, true) then
                            mobScope = s
                            break
                        end
                    end
                end

                if not mobScope then
                    -- No matching scope -- buffer for later. Prune
                    -- entries older than 15s while we're here so the
                    -- buffer doesn't grow unbounded.
                    local now = os.time()
                    local kept = {}
                    for _, p in ipairs(pendingMobCasts) do
                        if (now - (p.ts or 0)) < 15 then
                            table.insert(kept, p)
                        end
                    end
                    pendingMobCasts = kept
                    table.insert(pendingMobCasts, {
                        caster = caster,
                        spell = spellName,
                        ts = now,
                    })
                    return
                end

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

    -- Catch-all event for raid trigger evaluation. Fires on EVERY
    -- chat line so we can scan for user-defined patterns. Use #*#
    -- to match any line content. The event handler is cheap when
    -- no triggers are configured (early-out in evaluateTriggers).
    mq.event('trigger_scan',
        '#*#',
        function(line)
            pcall(function()
                evaluateTriggers(line)
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

-- Inverted view of buildRowsFor. Instead of grouping by the person
-- being healed (with healers as sub-rows), group by the HEALER --
-- with the targets they healed as sub-rows.
--
-- Output rows: { healer, total, count, max, targets = { [name] = {total,count,max} } }
-- where total/count/max are the healer's TOTAL output across all targets.
local function buildHealerRowsFor(scope)
    -- Walk the existing target-keyed scope.stats and re-pivot it.
    local healers = {}
    for target, s in pairs(scope.stats) do
        for healerName, h in pairs(s.healers or {}) do
            healers[healerName] = healers[healerName] or {
                healer  = healerName,
                total   = 0,
                count   = 0,
                max     = 0,
                targets = {},
                isMe    = (healerName == MyName),
            }
            local hr = healers[healerName]
            hr.total = hr.total + (h.total or 0)
            hr.count = hr.count + (h.count or 0)
            if (h.max or 0) > hr.max then hr.max = h.max end
            hr.targets[target] = {
                total = h.total or 0,
                count = h.count or 0,
                max   = h.max or 0,
            }
        end
    end

    local rows = {}
    for _, hr in pairs(healers) do table.insert(rows, hr) end
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
local function buildDamageRows(scope, maxRows)
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
            dmgTypes = s.dmgTypes,
            hasPets  = petCount > 0,
            isMe     = (attacker == MyName),
        })
    end
    -- Sort purely by total damage descending. This keeps live DPS and
    -- the last-fight popup dynamically ordered: when someone passes
    -- another player, their row moves up immediately.
    table.sort(rows, function(a, b)
        return (a.total or 0) > (b.total or 0)
    end)

    -- Optional row limit used by the live DPS tracker and last-fight
    -- popup. The full DPS tab does not pass maxRows, so it still shows
    -- the complete breakdown.
    maxRows = tonumber(maxRows) or 0
    if maxRows > 0 then
        while #rows > maxRows do
            table.remove(rows)
        end
    end

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
                    { total = 0, count = 0, max = 0, targets = {}, pets = {}, dmgTypes = {} }
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

                cs.dmgTypes = cs.dmgTypes or {}
                for typ, dt in pairs(s.dmgTypes or {}) do
                    cs.dmgTypes[typ] = cs.dmgTypes[typ] or { total = 0, count = 0, max = 0 }
                    cs.dmgTypes[typ].total = cs.dmgTypes[typ].total + (dt.total or 0)
                    cs.dmgTypes[typ].count = cs.dmgTypes[typ].count + (dt.count or 0)
                    if (dt.max or 0) > (cs.dmgTypes[typ].max or 0) then cs.dmgTypes[typ].max = dt.max or 0 end
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
                    { total = 0, count = 0, max = 0, targets = {}, pets = {}, dmgTypes = {} }
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


_G.HT_SpellSummaryText = _G.HT_SpellSummaryText or function(scope, headerLabel)
    local lines = {}
    table.insert(lines, string.format('SPELLS (%s)', headerLabel or 'fight'))
    table.insert(lines, string.format('Total casts: %d', (scope and scope.total) or 0))
    local rows = {}
    for caster, cs in pairs((scope and scope.stats) or {}) do
        table.insert(rows, { name = caster, total = cs.total or 0, casts = cs.casts or {} })
    end
    table.sort(rows, function(a, b) return a.total > b.total end)
    for _, r in ipairs(rows) do
        table.insert(lines, string.format('%s: %d casts', r.name, r.total))
        local spells = {}
        for spell, n in pairs(r.casts or {}) do
            table.insert(spells, { name = spell, count = n or 0 })
        end
        table.sort(spells, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return a.name:lower() < b.name:lower()
        end)
        for _, sp in ipairs(spells) do
            table.insert(lines, string.format('  %s x%d', sp.name, sp.count))
        end
    end
    return table.concat(lines, '\n')
end

_G.HT_BurnSummaryTextFromDamage = _G.HT_BurnSummaryTextFromDamage or function(scope, headerLabel)
    local lines = {}
    table.insert(lines, string.format('BURNS (%s)', headerLabel or 'fight'))
    local rows = {}
    for player, list in pairs((scope and scope.discBurns) or {}) do
        for _, rec in ipairs(list or {}) do
            table.insert(rows, {
                player = player,
                name = rec.name or '?',
                rel = tonumber(rec.rel) or 0,
                at = tonumber(rec.at) or 0,
            })
        end
    end
    table.sort(rows, function(a, b)
        if a.rel ~= b.rel then return a.rel < b.rel end
        if a.player ~= b.player then return a.player < b.player end
        return a.name < b.name
    end)
    if #rows == 0 then
        table.insert(lines, 'No observed burn/disc messages recorded.')
    else
        for _, r in ipairs(rows) do
            table.insert(lines, string.format('+%ds %s - %s', r.rel, r.player, r.name))
        end
    end
    return table.concat(lines, '\n')
end

_G.HT_BurnSummaryTextFromRecords = _G.HT_BurnSummaryTextFromRecords or function(records, headerLabel)
    local lines = { string.format('BURNS (%s)', headerLabel or 'combined') }
    local rows = {}
    for _, rec in ipairs(records or {}) do
        local d = rec.damage
        local mob = rec.mob or (d and d.label) or '?'
        for player, list in pairs((d and d.discBurns) or {}) do
            for _, b in ipairs(list or {}) do
                table.insert(rows, {
                    mob = mob,
                    player = player,
                    name = b.name or '?',
                    rel = tonumber(b.rel) or 0,
                    at = tonumber(b.at) or tonumber(rec.ts) or 0,
                })
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.at ~= b.at then return a.at < b.at end
        if a.player ~= b.player then return a.player < b.player end
        return a.name < b.name
    end)
    if #rows == 0 then
        table.insert(lines, 'No observed burn/disc messages recorded.')
    else
        for _, r in ipairs(rows) do
            table.insert(lines, string.format('%s +%ds %s - %s', r.mob, r.rel, r.player, r.name))
        end
    end
    return table.concat(lines, '\n')
end

_G.HT_MobSpellSummaryText = _G.HT_MobSpellSummaryText or function(d, headerLabel)
    local lines = { string.format('MOB SPELLS (%s)', headerLabel or 'fight') }
    local mobSpells = (d and d.mobSpells) or {}
    local rows = {}
    for spell, rec in pairs(mobSpells) do
        if type(rec) == 'number' then rec = { count = rec, casts = {} } end
        table.insert(rows, { spell = spell, count = rec.count or 0, casts = rec.casts or {} })
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.spell:lower() < b.spell:lower()
    end)
    if #rows == 0 then
        table.insert(lines, 'No mob spell casts recorded.')
    else
        local fightStart = (d and d.started) or 0
        for _, r in ipairs(rows) do
            table.insert(lines, string.format('%s x%d', r.spell, r.count))
            for idx, ts in ipairs(r.casts or {}) do
                table.insert(lines, string.format('  %d. %s (+%ds)', idx, os.date('%H:%M:%S', ts), ts - fightStart))
            end
        end
    end
    return table.concat(lines, '\n')
end

_G.HT_FullArchiveReportText = _G.HT_FullArchiveReportText or function(rec)
    local lines = {}
    table.insert(lines, string.format('=== %s @ %s ===', rec.mob or '?', os.date('%Y-%m-%d %H:%M:%S', rec.ts or os.time())))
    if rec.damage and (rec.damage.total or 0) > 0 then table.insert(lines, gamparseReport(rec.damage, rec.mob or 'fight')) end
    if rec.fight and (rec.fight.total or 0) > 0 then table.insert(lines, ''); table.insert(lines, summaryText(rec.fight, rec.mob or 'fight')) end
    if rec.damage then table.insert(lines, ''); table.insert(lines, _G.HT_BurnSummaryTextFromDamage(rec.damage, rec.mob or 'fight')) end
    if rec.spells and (rec.spells.total or 0) > 0 then table.insert(lines, ''); table.insert(lines, _G.HT_SpellSummaryText(rec.spells, rec.mob or 'fight')) end
    if rec.damage then table.insert(lines, ''); table.insert(lines, _G.HT_MobSpellSummaryText(rec.damage, rec.mob or 'fight')) end
    return table.concat(lines, '\n')
end

_G.HT_CombinedArchiveReportText = _G.HT_CombinedArchiveReportText or function(records, cHeals, cDamage, cSpells)
    local lines = { string.format('=== Combined: %d fights ===', #(records or {})) }
    if cDamage and (cDamage.total or 0) > 0 then table.insert(lines, gamparseReport(cDamage, string.format('Combined: %d fights', #(records or {})))) end
    if cHeals and (cHeals.total or 0) > 0 then table.insert(lines, ''); table.insert(lines, summaryText(cHeals, 'combined')) end
    table.insert(lines, ''); table.insert(lines, _G.HT_BurnSummaryTextFromRecords(records, 'combined'))
    if cSpells and (cSpells.total or 0) > 0 then table.insert(lines, ''); table.insert(lines, _G.HT_SpellSummaryText(cSpells, 'combined')) end
    return table.concat(lines, '\n')
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
local drawAlertsWindow

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

    -- Third window: raid event alerts overlay. Auto-hides when no
    -- alerts are active. Independent from main window and last-fight
    -- popup so it can be positioned over the actual game viewport
    -- where the user's eyes are during combat.
    mq.imgui.init('HealTrackerAlerts', function()
        if shuttingDown then return end
        drawAlertsWindow()
    end)
end

-- =============================================================================
-- Slash command
-- =============================================================================

local function slashCmd(...)
    if shuttingDown then return end
    local args = { ... }
    local cmd = tostring(args[1] or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')

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

    if cmd == 'minipos' or cmd == 'miniposition' then
        local sub = (args[2] or ''):lower()
        if sub == 'reset' or sub == 'clear' then
            config.miniPosX = nil
            config.miniPosY = nil
            saveConfig()
            print('\ag[HealTracker]\ax mini tracker saved position cleared. Move it again to save a new spot.')
        else
            if config.miniPosX and config.miniPosY then
                print(string.format('\ag[HealTracker]\ax mini tracker saved position: \at%d, %d\ax', tonumber(config.miniPosX) or 0, tonumber(config.miniPosY) or 0))
                print('  Use \at/healtracker minipos reset\ax to clear it.')
            else
                print('\ag[HealTracker]\ax no mini tracker position saved yet. Drag the mini tracker to save it.')
            end
        end
        return
    end

    if cmd == 'alpha' or cmd == 'minialpha' then
        local v = tonumber(args[2] or '')
        if not v then
            print(string.format('\ag[HealTracker]\ax UI alpha is currently \at%d\ax (0-100)', tonumber(config.miniAlphaPercent) or 100))
            print('  Usage: \at/healtracker alpha 75\ax')
            return
        end
        config.miniAlphaPercent = math.max(0, math.min(100, math.floor(v)))
        saveConfig()
        print(string.format('\ag[HealTracker]\ax UI alpha set to \at%d\ax', config.miniAlphaPercent))
        return
    end

    if cmd == 'active' or cmd == 'activemobs' then
        -- Diagnostic: list all currently-active mob scopes. Useful when
        -- the live DPS view won't clear after a kill -- this shows
        -- exactly what's still being tracked as "active" so you can
        -- see whether activeMobs is failing to drain.
        local count = 0
        local nowSec = os.time()
        local rows = {}
        for mobName, scope in pairs(activeMobs) do
            count = count + 1
            local idle = nowSec - (scope.lastHitAt or scope.started or nowSec)
            table.insert(rows, {
                name = mobName,
                total = scope.total or 0,
                idle = idle,
                dying = scope._dying and 'DYING' or '',
                killClosed = scope._killClosed and 'KILL-CLOSED' or '',
            })
        end
        if count == 0 then
            print('\ag[HealTracker]\ax no active mobs (live DPS view is clear)')
        else
            print(string.format('\ay[HealTracker]\ax %d active mob(s):', count))
            table.sort(rows, function(a, b) return a.total > b.total end)
            for _, r in ipairs(rows) do
                print(string.format('  %-40s  %s damage  idle=%ds  %s %s',
                    r.name, fmtNum(r.total), r.idle, r.dying, r.killClosed))
            end
            print('  Use /healtracker clearactive to force-close all of these.')
        end
        return
    end

    if cmd == 'clearactive' or cmd == 'forceclose' then
        -- Force-close every active mob scope. Used when the live DPS
        -- view gets stuck on a fight that should have ended.
        local closed = 0
        for mobName, _ in pairs(activeMobs) do
            -- Snapshot it (will be filtered by minDamageToRecord if too small)
            pcall(snapshotFight, mobName)
            closed = closed + 1
        end
        -- Hard-clear in case any didn't snapshot cleanly.
        activeMobs = {}
        miniQueueCurrentAt = 0
        print(string.format('\ag[HealTracker]\ax force-closed %d active mob(s)', closed))
        return
    end

    if cmd == 'clearpets' or cmd == 'cleanpets' then
        -- Drop any possessive-form pet scopes from activeMobs. These
        -- shouldn't be there (the new filter prevents new ones from
        -- being created) but legacy ones may linger from before the
        -- filter was added.
        local dropped = 0
        for mobName, _ in pairs(activeMobs) do
            if mobName:match("[`']s%s+%S+$") then
                activeMobs[mobName] = nil
                dropped = dropped + 1
            end
        end
        print(string.format('\ag[HealTracker]\ax dropped %d pet scope(s) from active list',
            dropped))
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
            -- Queue the clear to run from the main Lua loop, not from a slash/UI
            -- callback. Mutating the fight arrays and writing files while ImGui is
            -- drawing can crash some MQ2Lua builds when pinned fights are involved.
            _G.HT_PendingClearFights = true
            _G.HT_PendingClearSource = 'slash'
            print('\ay[HealTracker]\ax clear queued; it will run safely on the next tick')
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

    if cmd == 'logparser' then
        local sub = (args[2] or ''):lower()
        if sub == 'on' or sub == 'true' or sub == '1' then
            config.useLogParser = true
            saveConfig()
            logTailer.initialized = false
            logTailerOpen()
            print('\ag[HealTracker]\ax log parser \agENABLED\ax (driver damage from EQ log file)')
            if logTailer.path then
                print('\ag[HealTracker]\ax reading: ' .. logTailer.path)
            end
            return
        end
        if sub == 'off' or sub == 'false' or sub == '0' then
            config.useLogParser = false
            saveConfig()
            logTailerClose()
            print('\ay[HealTracker]\ax log parser \arDISABLED\ax (using MQ chat events for damage)')
            return
        end
        if sub == 'path' then
            -- Reconstruct the rest of the line as the path. MQ slash
            -- args split on whitespace and strip quotes, so a path with
            -- spaces (e.g. "Project Lazarus") arrives as multiple args.
            -- Re-join from arg index 3 onward.
            local newPath = table.concat(args, ' ', 3)
            -- Strip surrounding quotes if user typed them anyway.
            newPath = newPath:gsub('^"', ''):gsub('"$', '')
            newPath = newPath:gsub('^%s+', ''):gsub('%s+$', '')

            if newPath == '' or newPath == 'clear' or newPath == 'reset' then
                config.logParserPath = ''
                saveConfig()
                logTailer.initialized = false
                logTailerClose()
                print('\ag[HealTracker]\ax log path cleared (using auto-detect)')
                if logTailerPath() then
                    print('  auto-detected: ' .. logTailerPath())
                end
                return
            end

            -- Detect whether user gave a directory or a full file path.
            local lower = newPath:lower()
            local looksLikeFile = lower:find('%.txt$') or lower:find('eqlog_')

            if looksLikeFile then
                -- Verify the specific file exists.
                local f = io.open(newPath, 'rb')
                if not f then
                    print(string.format('\ar[HealTracker]\ax cannot open: %s', newPath))
                    print('\ar[HealTracker]\ax path NOT saved. Check spelling and that the file exists.')
                    return
                end
                f:close()
                config.logParserPath = newPath
                saveConfig()
                logTailer.initialized = false
                print(string.format('\ag[HealTracker]\ax log file path set: %s', newPath))
                return
            end

            -- Directory form: save it, then verify by resolving to the
            -- per-character filename and trying that.
            config.logParserPath = newPath
            saveConfig()
            logTailer.initialized = false
            local resolved = logTailerPath()
            print(string.format('\ag[HealTracker]\ax log directory set: %s', newPath))
            print(string.format('  for this character resolves to: %s', resolved or '(unresolved)'))
            if resolved then
                local f = io.open(resolved, 'rb')
                if f then
                    f:close()
                    print('  \agfile is readable\ax')
                else
                    print('  \aywarning:\ax this file is NOT readable yet. Make sure /log on is enabled in EQ.')
                end
            end
            return
        end
        -- No arg: print status.
        print(string.format('\ag[HealTracker]\ax log parser: %s',
            config.useLogParser and '\agON\ax' or '\arOFF\ax'))
        if config.logParserPath and config.logParserPath ~= '' then
            print('  manual path: ' .. config.logParserPath)
        else
            print('  auto-detect: ' .. (logTailerPath() or '(failed)'))
        end
        if config.useLogParser then
            if logTailer.lastError then
                print('  \arlast error:\ax ' .. logTailer.lastError)
            end
            print(string.format(
                '  diagnostics: polls=%d, lines_read=%d, lines_matched=%d, size=%d',
                logTailer.pollCount or 0,
                logTailer.linesRead or 0,
                logTailer.linesMatched or 0,
                logTailer.lastSize or 0))
            if (logTailer.pollCount or 0) > 0 and (logTailer.linesRead or 0) == 0 then
                print('  \ay==> tailer is polling but reading 0 lines.\ax')
                print('  \ay==> Check that "/log on" is enabled in EQ -- the file must be growing.\ax')
            end
            if (logTailer.linesRead or 0) > 0 and (logTailer.linesMatched or 0) == 0 then
                print('  \ay==> Tailer reading lines but matching 0 as combat.\ax')
                print('  \ay==> Run "/healtracker debug" then pull a mob to see line content.\ax')
            end
            if not logTailer.initialized then
                print('  \aystatus:\ax not yet initialized (waiting for first successful poll)')
            else
                print('  \agstatus:\ax initialized')
            end
        end
        print('  Use: /healtracker logparser on|off')
        print('  Use: /healtracker logparser path <directory>     (e.g. C:\\Users\\Public\\RoF\\Project Lazarus\\Logs)')
        print('     -> auto-fills the per-character filename. RECOMMENDED.')
        print('  Use: /healtracker logparser path <full file>     (specific file -- char-specific)')
        print('  Use: /healtracker logparser path clear           (revert to auto-detect)')
        return
    end

    if cmd == 'trigger' or cmd == 'triggers' then
        config.triggers = config.triggers or {}
        local sub = (args[2] or ''):lower()

        if sub == 'list' or sub == '' then
            if #config.triggers == 0 then
                print('\ag[HealTracker]\ax no triggers configured')
            else
                print('\ag[HealTracker]\ax triggers:')
                for i, t in ipairs(config.triggers) do
                    local en = (t.enabled ~= false) and '\agON\ax ' or '\arOFF\ax'
                    print(string.format(
                        '  %d. [%s] "%s" -> "%s" color=%s beep=%s dismiss=%ds',
                        i, en, t.pattern or '', t.label or '',
                        t.color or 'red',
                        t.beep and tostring(t.beepCount or 1) or 'no',
                        t.dismissAfter or 8))
                end
            end
            return
        end

        if sub == 'add' then
            -- Parse the rest of the line. Syntax:
            --   /healtracker trigger add <pattern> | <label> [opts]
            --
            -- MQ's slash binding strips quotes and splits on whitespace,
            -- so we can't use quoted strings to delimit pattern/label.
            -- Instead use ' | ' (space-pipe-space) as the separator.
            -- Trailing options use key=value form.
            --
            -- Example:
            --   /healtracker trigger add Out of the corner of your eye | Duck Now! | color=red beep=3
            local raw = table.concat(args, ' ', 3)

            -- Strip any leading/trailing quotes the user may have typed
            -- out of habit (they don't help here but shouldn't break it).
            raw = raw:gsub('"', '')

            -- Split on " | " (the explicit separator).
            local parts = {}
            for chunk in (raw .. ' | '):gmatch('(.-)%s+|%s+') do
                table.insert(parts, chunk)
            end
            -- Last chunk has no trailing separator -- catch it via fallback.
            if #parts < 2 then
                print('\ar[HealTracker]\ax syntax: /healtracker trigger add <pattern> | <label> [| opts]')
                print('\ar[HealTracker]\ax example: /healtracker trigger add begins casting Death Touch | DUCK NOW! | color=red beep=3')
                return
            end

            local pattern = parts[1]
            local label   = parts[2]
            local optsStr = parts[3] or ''

            -- Trim whitespace.
            pattern = pattern:match('^%s*(.-)%s*$') or pattern
            label   = label:match('^%s*(.-)%s*$') or label

            -- Translate the literal two-character sequence "\n" (a
            -- backslash followed by n) into a real newline character.
            -- Lets users type multi-line labels at the slash command:
            --   ... | PAL - water\nSK - earth\nWAR - fire | ...
            -- which renders as three stacked lines on the alert popup.
            label = label:gsub('\\n', '\n')

            if pattern == '' or label == '' then
                print('\ar[HealTracker]\ax pattern and label cannot be empty')
                return
            end

            local t = {
                pattern = pattern,
                label = label,
                color = 'red',
                beep = true,
                beepCount = 2,
                dismissAfter = 8,
                enabled = true,
            }
            for kv in optsStr:gmatch('(%S+)') do
                local k, v = kv:match('^(%w+)=(.+)$')
                if k and v then
                    k = k:lower()
                    if k == 'color' then
                        t.color = v:lower()
                    elseif k == 'beep' then
                        local n = tonumber(v)
                        if n and n > 0 then
                            t.beep = true
                            t.beepCount = math.max(1, math.min(5, n))
                        else
                            t.beep = false
                        end
                    elseif k == 'dismiss' then
                        t.dismissAfter = tonumber(v) or 8
                    elseif k == 'mob' then
                        t.mobFilter = v
                    end
                end
            end

            table.insert(config.triggers, t)
            saveConfig()
            print(string.format('\ag[HealTracker]\ax trigger added: "%s" -> "%s"',
                t.pattern, t.label))
            return
        end

        if sub == 'remove' or sub == 'rm' then
            local n = tonumber(args[3])
            if not n or not config.triggers[n] then
                print('\ar[HealTracker]\ax usage: /healtracker trigger remove <number>')
                return
            end
            local removed = table.remove(config.triggers, n)
            saveConfig()
            print(string.format('\ag[HealTracker]\ax removed trigger: "%s"',
                removed.pattern or ''))
            return
        end

        if sub == 'toggle' then
            local n = tonumber(args[3])
            local t = n and config.triggers[n]
            if not t then
                print('\ar[HealTracker]\ax usage: /healtracker trigger toggle <number>')
                return
            end
            t.enabled = not (t.enabled ~= false)
            saveConfig()
            print(string.format('\ag[HealTracker]\ax trigger %d now %s',
                n, t.enabled and '\agON\ax' or '\arOFF\ax'))
            return
        end

        if sub == 'test' then
            local n = tonumber(args[3])
            local t = n and config.triggers[n]
            if not t then
                print('\ar[HealTracker]\ax usage: /healtracker trigger test <number>')
                return
            end
            fireAlert(t, '(test)')
            return
        end

        if sub == 'clear' then
            config.triggers = {}
            saveConfig()
            print('\ag[HealTracker]\ax all triggers cleared')
            return
        end

        print('\ay[HealTracker]\ax unknown trigger sub-command. Try: list, add, remove, toggle, test, clear')
        return
    end

    if cmd == 'class' or cmd == 'classes' then
        if _G.HT_ClassCommand then _G.HT_ClassCommand(args) end
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
            -- Remove the pet from knownChars (if it was there) so future
            -- damage events route through attributeDamage and credit
            -- the owner instead of the pet's name.
            knownChars[petName] = nil
            knownChars[ownerName] = true
            unmappedDamage[petName] = nil
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
            if _G.HT_PetOwnersPath then
                print(string.format('  Saved pet map file: %s', _G.HT_PetOwnersPath()))
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

    if cmd == 'burn' or cmd == 'disc' or cmd == 'discipline' then
        local sub = tostring(args[2] or ''):lower()
        config.burnDiscMap = config.burnDiscMap or {}
        if sub == 'list' or sub == '' then
            print('\ag[HealTracker]\ax observed burn / discipline mappings:')
            local n = 0
            for phrase, disc in pairs(config.burnDiscMap or {}) do
                n = n + 1
                print(string.format('  %d. "%s" => %s', n, tostring(phrase), tostring(disc)))
            end
            if n == 0 then
                print('  none configured')
            end
            return
        end
        if sub == 'add' then
            local rest = {}
            for i = 3, #args do table.insert(rest, tostring(args[i])) end
            local txt = table.concat(rest, ' ')
            local phrase, disc = txt:match('^(.-)%s*=>%s*(.+)$')
            if not phrase or phrase == '' or not disc or disc == '' then
                print('\ar[HealTracker]\ax usage: /healtracker burn add <visible message phrase> => <discipline name>')
                print('\ay[HealTracker]\ax example: /healtracker burn add muscles bulge with the force of will => Crystal Palm Discipline')
                return
            end
            phrase = phrase:lower():gsub('^%s+', ''):gsub('%s+$', '')
            disc = disc:gsub('^%s+', ''):gsub('%s+$', '')
            config.burnDiscMap[phrase] = disc
            saveConfig()
            print(string.format('\ag[HealTracker]\ax burn mapping added: "%s" => %s', phrase, disc))
            return
        end
        if sub == 'remove' or sub == 'rm' or sub == 'delete' then
            local rest = {}
            for i = 3, #args do table.insert(rest, tostring(args[i])) end
            local phrase = table.concat(rest, ' '):lower():gsub('^%s+', ''):gsub('%s+$', '')
            if phrase == '' then
                print('\ar[HealTracker]\ax usage: /healtracker burn remove <visible message phrase>')
                return
            end
            if config.burnDiscMap[phrase] then
                config.burnDiscMap[phrase] = nil
                saveConfig()
                print(string.format('\ag[HealTracker]\ax burn mapping removed: "%s"', phrase))
            else
                print(string.format('\ay[HealTracker]\ax no burn mapping found for "%s"', phrase))
            end
            return
        end
        print('\ar[HealTracker]\ax usage: /healtracker burn list | add <phrase> => <discipline> | remove <phrase>')
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
            local cur = config.miniLingerSeconds or 10
            print(string.format('\ag[HealTracker]\ax mini linger = %d seconds (use /healtracker linger N to change)',
                cur))
        end
        return
    end

    if cmd == 'minminduration' or cmd == 'minduration' or cmd == 'minimumduration' then
        local n = tonumber(args[2])
        if n then
            config.miniMinDuration = math.max(0, math.min(300, math.floor(n)))
            saveConfig()
            print(string.format('\ag[HealTracker]\ax popup min duration = %d seconds (fights shorter than this skip the popup queue)',
                config.miniMinDuration))
        else
            local cur = config.miniMinDuration or 10
            print(string.format('\ag[HealTracker]\ax popup min duration = %d seconds',
                cur))
            print('  Fights shorter than this don\'t appear in the popup queue (still saved to history).')
            print('  Use /healtracker minduration N to change.')
        end
        return
    end

    if cmd == 'mindamage' or cmd == 'minimumdamage' then
        local n = tonumber(args[2])
        if n then
            config.minDamageToRecord = math.max(0, math.floor(n))
            saveConfig()
            print(string.format('\ag[HealTracker]\ax min damage to record = %s (fights below this are dropped entirely)',
                fmtNum(config.minDamageToRecord)))
        else
            local cur = config.minDamageToRecord or 5
            print(string.format('\ag[HealTracker]\ax min damage to record = %s',
                fmtNum(cur)))
            print('  Fights below this damage threshold are not added to the parse.')
            print('  Default: 100,000. Set to 0 to record everything.')
            print('  Use /healtracker mindamage N to change.')
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

    if cmd == 'fastdps' or cmd == 'fast' or cmd == 'livedpsfast' then
        local sub = tostring(args[2] or ''):lower()
        if sub == 'on' or sub == '1' or sub == 'true' then
            config.fastDpsMode = true
            saveConfig()
            print('\ag[HealTracker]\ax Live DPS Fast Mode: \agON\ax')
            print('  Faster log polling is enabled. Heavy disk flushes are delayed while combat is active.')
            return
        elseif sub == 'off' or sub == '0' or sub == 'false' then
            config.fastDpsMode = false
            saveConfig()
            print('\ag[HealTracker]\ax Live DPS Fast Mode: \arOFF\ax')
            return
        elseif sub == 'status' or sub == '' then
            print(string.format('\ag[HealTracker]\ax Live DPS Fast Mode: %s',
                config.fastDpsMode and '\agON\ax' or '\arOFF\ax'))
            print('  Use: /healtracker fastdps on|off')
            return
        end
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
        -- Crash-safe SOFT stop. Fully exiting MQ2Lua while ImGui callbacks are
        -- still registered can crash some builds at vsprintf_s_l. Instead, hide
        -- every window, close the log tailer once, disable parser work, and keep
        -- the Lua in a dormant idle loop. Reload the script to start it again.
        config.windowOpen = false
        config.miniMode = false
        htSoftStopped = true
        shuttingDown = true
        _G.HT_StopRequested = true
        pcall(saveConfig)
        print('\ag[HealTracker]\ax stopped safely. Use /lua reload heal_tracker to start it again.')
        return
    end

    print('\ay[HealTracker]\ax commands: driver | show | mini | report | reset | fights clear | autoreset on|off | idle N | min N | debug | test | testremote | testkill | stop')
end

-- =============================================================================
-- Theme
-- =============================================================================

local THEME = {
    bg     = { 0/255, 2/255, 10/255, 252/255 },
    border = {0.170, 0.620, 0.860, 1.00},
    label    = { 0.84, 0.94, 1.00, 1.0 },
    valueAmt = { 1.00, 0.86, 0.22, 1.0 },
    -- Bright pure yellow used for damage/DPS values in the live mini
    -- bar and the Last Fight popup. Matches the in-game chat color
    -- for damage messages so the windows feel native.
    valueDps = { 1.00, 1.00, 0.20, 1.0 },
    -- Light baby blue for heal values (total HP, heal count, avg/max)
    -- on the Heals tab. Distinguishes heal totals from damage totals
    -- at a glance.
    valueHeal = { 0.60, 0.85, 1.00, 1.0 },
    you      = { 0.55, 1.00, 0.60, 1.0 },
    muted    = { 0.62, 0.70, 0.84, 1.0 },
    rowFloatA = { 1/255, 11/255, 34/255, 0.998 },
    rowFloatB = { 6/255, 42/255, 96/255, 0.998 },
    rowFloatSel = { 22/255, 168/255, 255/255, 1.00 },
    rowFloatHeader = { 7/255, 43/255, 96/255, 0.995 },
    rowFloatBorder = { 160/255, 220/255, 255/255, 0.92 },
    rowFloatTop = { 1.0, 1.0, 1.0, 0.055 },
    selectBox = { 10/255, 28/255, 58/255, 1.0 },
    selectBoxOn = { 34/255, 140/255, 245/255, 1.0 },
    selectBoxBorder = { 155/255, 210/255, 255/255, 0.90 },
}



_G.HT_UIAlpha = function()
    return math.max(0.10, math.min(1.00, (tonumber(config.miniAlphaPercent) or 100) / 100))
end

-- Apply the same user alpha to filled UI colors. Text stays fully readable,
-- but panel/card/table/button backgrounds fade with the transparency setting.
_G.HT_FillAlpha = function(extra)
    local a = (_G.HT_UIAlpha and _G.HT_UIAlpha()) or 1.00
    if extra then a = a + extra end
    return math.max(0.08, math.min(1.00, a))
end

_G.HT_BorderAlpha = function(extra)
    local a = (_G.HT_UIAlpha and _G.HT_UIAlpha()) or 1.00
    if extra then a = a + extra end
    return math.max(0.18, math.min(1.00, a))
end

_G.HT_PushGlossyTheme = function()
    _G.HT_GlossyStyleVarCount = 0
    local function safeStyleVar(var, a, b)
        if var == nil then return end
        local ok = pcall(function()
            if b ~= nil then ImGui.PushStyleVar(var, a, b) else ImGui.PushStyleVar(var, a) end
        end)
        if ok then _G.HT_GlossyStyleVarCount = (_G.HT_GlossyStyleVarCount or 0) + 1 end
    end

    safeStyleVar(ImGuiStyleVar.WindowRounding, 18)
    safeStyleVar(ImGuiStyleVar.ChildRounding, 18)
    safeStyleVar(ImGuiStyleVar.PopupRounding, 18)
    safeStyleVar(ImGuiStyleVar.FrameRounding, 20)
    safeStyleVar(ImGuiStyleVar.GrabRounding, 20)
    -- Rounded/smaller scrollbars. These are protected because some MQ ImGui
    -- builds expose fewer style vars than stock Dear ImGui.
    safeStyleVar(ImGuiStyleVar.ScrollbarRounding, 999)
    safeStyleVar(ImGuiStyleVar.ScrollbarSize, 7)
    safeStyleVar(ImGuiStyleVar.GrabMinSize, 14)
    -- Stage-11 safe glossy theme. Still uses only PushStyleColor.
    -- No DrawList, no gradients, no PushStyleVar.
    -- Tie the full main UI transparency to the same Alpha setting used by
    -- the collapsed live DPS/heal tracker and completed-fight popup.
    local uiAlpha = (_G.HT_UIAlpha and _G.HT_UIAlpha()) or 1.00
    THEME.bg[4] = uiAlpha
    THEME.rowFloatA[4] = uiAlpha
    THEME.rowFloatB[4] = _G.HT_FillAlpha(0.03)
    THEME.rowFloatHeader[4] = _G.HT_FillAlpha(0.04)
    THEME.selectBox[4] = _G.HT_FillAlpha(0.08)
    THEME.rowFloatSel[4] = _G.HT_FillAlpha(0.14)
    THEME.selectBoxOn[4] = _G.HT_FillAlpha(0.14)
    THEME.rowFloatBorder[4] = _G.HT_BorderAlpha(0.02)
    ImGui.PushStyleColor(ImGuiCol.WindowBg,        0.000, 0.001, 0.005, uiAlpha)
    ImGui.PushStyleColor(ImGuiCol.ChildBg,         0.000, 0.010, 0.038, uiAlpha)
    ImGui.PushStyleColor(ImGuiCol.PopupBg,         0.006, 0.014, 0.030, uiAlpha)
    ImGui.PushStyleColor(ImGuiCol.Border,          0.78, 0.94, 1.00, _G.HT_BorderAlpha(0.08))
    ImGui.PushStyleColor(ImGuiCol.FrameBg,         0.010, 0.030, 0.070, _G.HT_FillAlpha(0.02))
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered,  0.13, 0.32, 0.58, _G.HT_FillAlpha(0.10))
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive,   0.08, 0.48, 0.90, _G.HT_FillAlpha(0.14))
    ImGui.PushStyleColor(ImGuiCol.Header,          0.030, 0.090, 0.180, _G.HT_FillAlpha(0.04))
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered,   0.18, 0.48, 0.82, _G.HT_FillAlpha(0.12))
    ImGui.PushStyleColor(ImGuiCol.HeaderActive,    0.06, 0.58, 1.00, _G.HT_FillAlpha(0.14))
    -- Native ImGui table fills are square-cornered. Keep them transparent so
    -- our rounded row/header cards drawn underneath are visible.
    ImGui.PushStyleColor(ImGuiCol.TableHeaderBg,   0.000, 0.000, 0.000, 0.00)
    ImGui.PushStyleColor(ImGuiCol.TableRowBg,      0.000, 0.000, 0.000, 0.00)
    ImGui.PushStyleColor(ImGuiCol.TableRowBgAlt,   0.000, 0.000, 0.000, 0.00)
    ImGui.PushStyleColor(ImGuiCol.TableBorderStrong, 0.58, 0.78, 1.00, _G.HT_BorderAlpha(0.02))
    ImGui.PushStyleColor(ImGuiCol.TableBorderLight,  0.28, 0.44, 0.66, _G.HT_BorderAlpha(-0.06))
    ImGui.PushStyleColor(ImGuiCol.TextSelectedBg,  0.08, 0.58, 1.00, _G.HT_FillAlpha(0.10))
    ImGui.PushStyleColor(ImGuiCol.Button,          0.008, 0.045, 0.110, _G.HT_FillAlpha(0.04))
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered,   0.18, 0.54, 0.96, _G.HT_FillAlpha(0.12))
    ImGui.PushStyleColor(ImGuiCol.ButtonActive,    0.06, 0.62, 1.00, _G.HT_FillAlpha(0.14))
    ImGui.PushStyleColor(ImGuiCol.Separator,       0.72, 0.92, 1.00, _G.HT_BorderAlpha(0.06))
    ImGui.PushStyleColor(ImGuiCol.ScrollbarBg,     0.006, 0.012, 0.024, _G.HT_FillAlpha(-0.45))
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrab,   0.20, 0.58, 1.00, _G.HT_FillAlpha(0.10))
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrabHovered, 0.45, 0.78, 1.00, _G.HT_FillAlpha(0.14))
    ImGui.PushStyleColor(ImGuiCol.CheckMark,       1.00, 0.90, 0.24, 1.00)
    return 24
end

_G.HT_PopGlossyTheme = function(n)
    ImGui.PopStyleColor(n or 24)
    ImGui.PopStyleVar(_G.HT_GlossyStyleVarCount or 5)
end


local btnVariants = {
    primary   = { {20/255, 170/255, 255/255, 1}, {160/255, 235/255, 255/255, 1}, {1,1,1,1} },
    success   = { {60/255, 120/255, 80/255, 1}, {80/255, 140/255, 100/255, 1}, {228/255, 245/255, 232/255, 1} },
    -- Bright green active highlight, used for selected toggle buttons
    -- (View/Date range pickers in the History tab) so the user can
    -- clearly see which option is currently chosen.
    active    = { {38/255, 165/255, 112/255, 1}, {80/255, 210/255, 150/255, 1}, {255/255, 255/255, 255/255, 1} },
    amber     = { {130/255, 95/255, 35/255, 1}, {155/255, 120/255, 60/255, 1}, {255/255, 226/255, 145/255, 1} },
    danger    = { {145/255, 60/255, 55/255, 1}, {170/255, 85/255, 80/255, 1}, {255/255, 228/255, 228/255, 1} },
    secondary = { {2/255, 26/255, 72/255, 1}, {112/255, 176/255, 250/255, 1}, {238/255, 248/255, 255/255, 1} },
}

local function pushBtn(base, hover, text)
    local ba = math.min(base[4] or 1, _G.HT_FillAlpha(0.06))
    local ha = math.min(hover[4] or 1, _G.HT_FillAlpha(0.14))
    ImGui.PushStyleColor(ImGuiCol.Button,        base[1], base[2], base[3], ba)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hover[1], hover[2], hover[3], ha)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive,  hover[1], hover[2], hover[3], ha)
    ImGui.PushStyleColor(ImGuiCol.Text,          text[1], text[2], text[3], text[4] or 1)
end

local function btn(label, variant, w, h)
    local v = btnVariants[variant] or btnVariants.secondary
    pushBtn(v[1], v[2], v[3])

    -- Extra-rounded glossy dashboard buttons to match the updated mockup.
    -- Uses a balanced Push/Pop pair to stay MQ-safe while softening the
    -- sharp rectangular edges on the top navigation/page buttons.
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 18)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)

    local clicked = ImGui.Button(label, w or 0, h or 0)

    ImGui.PopStyleVar(2)
    ImGui.PopStyleColor(4)
    return clicked
end

-- Rounded floating row helper for fight-list/detail tables.
-- This version draws a soft rounded background behind each row when the
-- MQ ImGui draw-list binding is available. If a build does not expose
-- DrawList safely, it falls back to the old table row background path.
_G.HT_DrawFloatingRowBg = function(rowNo, selected, widthOverride, heightOverride, radiusOverride)
    local isHeader = (tonumber(rowNo) or 0) < 0
    local c = isHeader and THEME.rowFloatHeader or (selected and THEME.rowFloatSel or (((rowNo or 0) % 2 == 0) and THEME.rowFloatA or THEME.rowFloatB))

    local drawn = false
    if ImGui.GetWindowDrawList and ImGui.GetCursorScreenPos and ImGui.GetColorU32 then
        local ok = pcall(function()
            local dl = ImGui.GetWindowDrawList()
            if not dl then return end

            local x, y = ImGui.GetCursorScreenPos()
            local w = tonumber(widthOverride)
            if not w or w <= 0 then
                if ImGui.GetColumnWidth then
                    w = math.max(80, (tonumber(ImGui.GetColumnWidth()) or 420) - 4)
                elseif ImGui.GetWindowWidth then
                    w = math.max(80, (tonumber(ImGui.GetWindowWidth()) or 420) - 18)
                else
                    w = 420
                end
            end

            local h = tonumber(heightOverride) or 26
            local radius = tonumber(radiusOverride) or 15
            local col = ImGui.GetColorU32(c[1], c[2], c[3], c[4] or 1.0)
            local border = ImGui.GetColorU32(THEME.rowFloatBorder[1], THEME.rowFloatBorder[2], THEME.rowFloatBorder[3], selected and _G.HT_BorderAlpha(0.10) or _G.HT_BorderAlpha(-0.35))
            local x1, y1, x2, y2 = x + 2, y + 1, x + w - 4, y + h - 1

            -- MQ/ImGui Lua bindings differ by build. Try all common call forms.
            local function tryFilled()
                if dl.AddRectFilled then
                    local ok1 = pcall(function() dl.AddRectFilled(x1, y1, x2, y2, col, radius) end)
                    if ok1 then return true end
                    local ok2 = pcall(function() dl:AddRectFilled(x1, y1, x2, y2, col, radius) end)
                    if ok2 then return true end
                end
                if ImGui.DrawList_AddRectFilled then
                    local ok3 = pcall(function() ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, col, radius) end)
                    if ok3 then return true end
                end
                return false
            end
            local function tryBorder()
                if dl.AddRect then
                    pcall(function() dl.AddRect(x1, y1, x2, y2, border, radius, 0, 1.0) end)
                    pcall(function() dl:AddRect(x1, y1, x2, y2, border, radius, 0, 1.0) end)
                end
                if ImGui.DrawList_AddRect then
                    pcall(function() ImGui.DrawList_AddRect(dl, x1, y1, x2, y2, border, radius, 0, 1.0) end)
                end
            end

            drawn = tryFilled()
            if drawn then tryBorder() end
        end)
        if not ok then drawn = false end
    end

    -- Fallback: make native square row fill very subtle if drawlist is not exposed.
    if not drawn and ImGui.TableSetBgColor and ImGui.GetColorU32 then
        local ok, col = pcall(function()
            return ImGui.GetColorU32(c[1], c[2], c[3], _G.HT_FillAlpha(-0.55))
        end)
        if ok and col then
            pcall(function() ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, col) end)
        end
    end
end

-- MQ-safe selector. Square and colored, but avoids InvisibleButton/DrawList.
-- Returns: newValue, changed
_G.HT_SelectBox = function(id, value)
    -- Stage-11 larger 3D square selector using only safe ImGui buttons.
    -- This keeps the mockup-style select box look without DrawList or style vars.
    local label = value and '●##' or '○##'
    local variant = value and 'primary' or 'secondary'
    if btn(label .. id, variant, 54, 30) then
        return not value, true
    end
    return value, false
end

-- TurboLoot-style compact toggle button. This avoids ImGui style vars for MQ stability.
-- Returns: newValue, changed
_G.HT_ToggleButton = function(label, id, value)
    local shown = (value == true) and ('●  ' .. label) or ('○  ' .. label)
    local variant = (value == true) and 'active' or 'secondary'
    if btn(shown .. '##' .. id, variant, 160, 24) then
        return not value, true
    end
    return value, false
end



_G.HT_StatCard = function(id, label, value, w, h)
    -- Stage-11 dashboard stat card. Uses only PushStyleColor + BeginChild/Text/Separator.
    -- This gives the top strip more of a glossy card look without DrawList.
    local ww = w or 120
    local hh = h or 68
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.001, 0.026, 0.078, _G.HT_FillAlpha(0.04))
    ImGui.PushStyleColor(ImGuiCol.Border,  0.68, 0.90, 1.00, _G.HT_BorderAlpha(0.06))
    ImGui.BeginChild('##stat_' .. tostring(id), ww, hh, true)
    ImGui.TextColored(0.86, 0.98, 1.00, 1.0, '▰ ' .. tostring(label or ''))
    ImGui.Separator()
    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0, tostring(value or '0'))
    ImGui.EndChild()
    ImGui.PopStyleColor(2)
end

_G.HT_DrawDashboardStrip = function(page, availX)
    local totalDmg = 0
    for _, d in ipairs(damageFights or {}) do totalDmg = totalDmg + (tonumber(d.total) or 0) end
    local totalHeals = 0
    for _, h in ipairs(fights or {}) do totalHeals = totalHeals + (tonumber(h.total) or 0) end
    local totalCasts = 0
    for _, s in ipairs(spellsFights or {}) do totalCasts = totalCasts + (tonumber(s.total) or 0) end

    local count = 5
    local w = math.max(102, math.floor(((tonumber(availX) or 660) - ((count - 1) * 8)) / count))
    _G.HT_StatCard('active_page', 'PAGE', string.upper(tostring(page or 'HEALS')), w, 68)
    ImGui.SameLine()
    _G.HT_StatCard('dmg_count', 'DPS FIGHTS', tostring(#(damageFights or {})), w, 68)
    ImGui.SameLine()
    _G.HT_StatCard('dmg_total', 'TOTAL DMG', fmtNum(totalDmg), w, 68)
    ImGui.SameLine()
    _G.HT_StatCard('heal_total', 'TOTAL HEALS', fmtNum(totalHeals), w, 68)
    ImGui.SameLine()
    _G.HT_StatCard('cast_total', 'SPELL CASTS', fmtNum(totalCasts), w, 68)
end

-- Safe glossy page/panel wrapper. Child windows with borders are much safer
-- than custom DrawList rounded rectangles in MQ2Lua, but still give the UI
-- the framed dashboard feel from the mockup.
_G.HT_BeginPanel = function(id, title, w, h)
    -- Extra-rounded panel wrapper. Directly pushes ChildRounding here so
    -- every page/list/detail box gets real rounded corners, not only buttons.
    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 22)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.000, 0.014, 0.050, _G.HT_FillAlpha(0.04))
    ImGui.PushStyleColor(ImGuiCol.Border,  0.60, 0.84, 1.00, _G.HT_BorderAlpha(0.04))
    ImGui.BeginChild(id, w or 0, h or 0, true)
    if title and title ~= '' then
        ImGui.TextColored(0.88, 0.99, 1.00, 1.0, '▰ ' .. tostring(title))
        ImGui.Separator()
    end
end

_G.HT_EndPanel = function()
    ImGui.EndChild()
    ImGui.PopStyleColor(2)
    ImGui.PopStyleVar(1)
end


-- Real rounded table/container helper.
-- Native ImGui tables draw square outer borders. These helpers put tables
-- inside rounded bordered Child panels and use inner grid lines only, so the
-- visible boxes have rounded corners like the mockup while staying MQ-safe.
_G.HT_RoundedTableFlags = function(extraFlags)
    -- Important: native ImGui table borders/row backgrounds are square.
    -- Keep tables mostly borderless so our rounded child panels and rounded
    -- row cards are what the user sees.
    local f = ImGuiTableFlags.Resizable or 0
    if ImGuiTableFlags.NoBordersInBody then f = bit32.bor(f, ImGuiTableFlags.NoBordersInBody) end
    if ImGuiTableFlags.NoBordersInBodyUntilResize then f = bit32.bor(f, ImGuiTableFlags.NoBordersInBodyUntilResize) end
    if extraFlags then f = bit32.bor(f, extraFlags) end
    return f
end

_G.HT_BeginRoundedBox = function(id, h)
    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 24)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 8, 7)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.000, 0.014, 0.050, _G.HT_FillAlpha(0.04))
    ImGui.PushStyleColor(ImGuiCol.Border,  0.64, 0.90, 1.00, _G.HT_BorderAlpha(0.06))
    ImGui.BeginChild('##roundbox_' .. tostring(id), 0, h or 0, true)
end

_G.HT_EndRoundedBox = function()
    ImGui.EndChild()
    ImGui.PopStyleColor(2)
    ImGui.PopStyleVar(2)
end

_G.HT_RoundedTableHeight = function(rowCount, extra)
    rowCount = tonumber(rowCount) or 1
    return math.max(58, math.min(380, 32 + (rowCount * 24) + (extra or 8)))
end

_G.HT_TableHeaderRow = function(labels)
    ImGui.TableNextRow()
    _G.HT_DrawFloatingRowBg(-1, false, nil, 24, 16)
    for _, label in ipairs(labels or {}) do
        ImGui.TableNextColumn()
        ImGui.TextColored(0.90, 0.98, 1.00, 1.0, tostring(label or ''))
    end
end

_G.HT_SectionTitle = function(title, subtitle)
    ImGui.TextColored(0.90, 0.99, 1.00, 1.0, '▰ ' .. tostring(title or ''))
    if subtitle and subtitle ~= '' then
        ImGui.SameLine()
        ImGui.TextColored(0.62, 0.78, 0.98, 1.0, tostring(subtitle))
    end
    ImGui.Separator()
end

-- Consistent neat action button sizes.
_G.HT_ActionButtonW = 96
_G.HT_ActionButtonH = 26

-- Range select mode for fight lists. Click Select Range, then click first row and last row.
_G.HT_RangeMode = _G.HT_RangeMode or {}
_G.HT_RangeStart = _G.HT_RangeStart or {}

_G.HT_RangeButton = function(tabName)
    local active = _G.HT_RangeMode[tabName] == true
    local variant = active and 'active' or 'secondary'
    if btn((active and 'Range ON' or 'Select Range') .. '##range_' .. tabName, variant, 120, _G.HT_ActionButtonH or 22) then
        _G.HT_RangeMode[tabName] = not active
        _G.HT_RangeStart[tabName] = nil
    end
end

_G.HT_HandleRangeClick = function(tabName, rowNo, keyValue, visibleKeys, selectedTable)
    if _G.HT_RangeMode[tabName] ~= true then return false end

    -- Store both the visible row number and the actual fight key.  The DPS
    -- tab can be sorted/filtered and its visible row positions can shift, so
    -- using the real fight key makes range selection reliable on that tab.
    if not _G.HT_RangeStart[tabName] then
        _G.HT_RangeStart[tabName] = { row = rowNo, key = keyValue }
        selectedTable[keyValue] = true
        return true
    end

    local startKey = _G.HT_RangeStart[tabName].key
    local a = tonumber(_G.HT_RangeStart[tabName].row) or rowNo
    local b = tonumber(rowNo) or a

    -- Prefer key lookup inside the currently visible sorted list. This fixes
    -- DPS Select Range when the visible order differs from raw damageFights[].
    if type(visibleKeys) == 'table' then
        for pos, k in ipairs(visibleKeys) do
            if k == startKey then a = pos end
            if k == keyValue then b = pos end
        end
    end

    if a > b then a, b = b, a end
    for pos = a, b do
        local k = visibleKeys and visibleKeys[pos]
        if k ~= nil then selectedTable[k] = true end
    end
    _G.HT_RangeMode[tabName] = false
    _G.HT_RangeStart[tabName] = nil
    return true
end



-- Dedicated DPS range selector. This intentionally does NOT share the generic
-- range state because the DPS list has its own selectedDamageIdx/damageSelected
-- path and can be resorted/filtered independently. The other tabs already work;
-- this keeps DPS isolated and reliable.
_G.HT_DpsRangeMode = _G.HT_DpsRangeMode or false
_G.HT_DpsRangeStart = _G.HT_DpsRangeStart or nil
-- DPS rows have several clickable Selectable cells. One physical click can
-- sometimes fire more than one cell on the same row in the same UI frame.
-- Without this debounce, the first cell stores the range start and the next
-- cell immediately treats that same click as the range end, turning Range OFF
-- before the user can click the second fight.
_G.HT_DpsRangeSuppressIdx = _G.HT_DpsRangeSuppressIdx or nil
_G.HT_DpsRangeSuppressUntil = _G.HT_DpsRangeSuppressUntil or 0
-- Prevent the mouse click that turns Range ON from also being consumed by
-- the DPS fight list underneath/near it on the same UI frame. Without this,
-- some MQ/ImGui builds immediately process that same click as a row click and
-- the DPS range mode appears to turn itself off right away.
_G.HT_DpsRangeArmUntil = _G.HT_DpsRangeArmUntil or 0
_G.HT_DpsRangeClickedButtonAt = _G.HT_DpsRangeClickedButtonAt or 0

_G.HT_DpsRangeButton = function()
    local active = _G.HT_DpsRangeMode == true
    local variant = active and 'active' or 'secondary'
    if btn((active and 'Range ON' or 'Select Range') .. '##range_dps_real', variant, 120, _G.HT_ActionButtonH or 22) then
        local tNow = nowMs and nowMs() or (os.time() * 1000)
        _G.HT_DpsRangeMode = not active
        _G.HT_DpsRangeStart = nil
        _G.HT_DpsRangeSuppressIdx = nil
        _G.HT_DpsRangeSuppressUntil = 0
        -- Small arming delay: Range ON stays on after pressing the button.
        -- The first DPS row click is ignored until after this moment, so the
        -- same physical click cannot start/end the range instantly.
        if _G.HT_DpsRangeMode == true then
            _G.HT_DpsRangeArmUntil = tNow + 450
            _G.HT_DpsRangeClickedButtonAt = tNow
        else
            _G.HT_DpsRangeArmUntil = 0
            _G.HT_DpsRangeClickedButtonAt = 0
        end
    end
end

_G.HT_HandleDpsRangeClick = function(clickedIdx, visibleIdxList)
    if _G.HT_DpsRangeMode ~= true then return false end
    if not clickedIdx then return true end

    damageSelected = damageSelected or {}

    local tNow = nowMs and nowMs() or (os.time() * 1000)
    -- If this row click is happening immediately after pressing the DPS Range
    -- button, consume it but do not choose a start/end row. This is what keeps
    -- Range ON from shutting off right after the button click.
    if tonumber(_G.HT_DpsRangeArmUntil or 0) > tNow then
        return true
    end

    if _G.HT_DpsRangeSuppressIdx == clickedIdx
       and tonumber(_G.HT_DpsRangeSuppressUntil or 0) > tNow then
        return true
    end

    if not _G.HT_DpsRangeStart then
        _G.HT_DpsRangeStart = clickedIdx
        damageSelected[clickedIdx] = true
        selectedDamageIdx = clickedIdx
        -- Longer debounce for MQ ImGui: several Selectable cells on the same
        -- DPS row can report clicked during one physical click. Keep Range ON
        -- after the first named is selected, and wait for a different/next
        -- click before completing the range.
        _G.HT_DpsRangeSuppressIdx = clickedIdx
        _G.HT_DpsRangeSuppressUntil = tNow + 900
        return true
    end

    -- Clicking the same first row again while still armed should not complete
    -- and shut off the range. It simply keeps that row selected and waits for
    -- the second row.
    if _G.HT_DpsRangeStart == clickedIdx then
        damageSelected[clickedIdx] = true
        selectedDamageIdx = clickedIdx
        return true
    end

    local startIdx = _G.HT_DpsRangeStart
    local a, b = nil, nil
    for pos, idx in ipairs(visibleIdxList or {}) do
        if idx == startIdx then a = pos end
        if idx == clickedIdx then b = pos end
    end

    -- If something changed between clicks, fall back to selecting both endpoints
    -- instead of silently doing nothing.
    if not a or not b then
        damageSelected[startIdx] = true
        damageSelected[clickedIdx] = true
    else
        if a > b then a, b = b, a end
        for pos = a, b do
            local idx = visibleIdxList[pos]
            if idx then damageSelected[idx] = true end
        end
    end

    selectedDamageIdx = clickedIdx
    _G.HT_DpsRangeMode = false
    _G.HT_DpsRangeStart = nil
    _G.HT_DpsRangeSuppressIdx = nil
    _G.HT_DpsRangeSuppressUntil = 0
    return true
end

_G.HT_SelectAllToggle = function(visibleKeys, selectedTable)
    local total = 0
    local checked = 0
    for _, k in ipairs(visibleKeys or {}) do
        total = total + 1
        if selectedTable[k] then checked = checked + 1 end
    end
    local turnOn = not (total > 0 and checked == total)
    if not turnOn then
        for _, k in ipairs(visibleKeys or {}) do selectedTable[k] = nil end
    else
        for _, k in ipairs(visibleKeys or {}) do selectedTable[k] = true end
    end
    return turnOn
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
--     Uses a safe InputText wrapper plus BeginCombo/Selectable so the
--     History tab can search without rendering thousands of rows.

uniqueMobsFromFights = function(arr, labelKey)
    labelKey = labelKey or 'label'

    -- Deferred/cached UI rendering performance pass:
    -- Building unique mob dropdown lists can become expensive when the
    -- History/DPS/Heals arrays contain thousands of entries. Cache the
    -- mob list for a short time and only rebuild when the backing array,
    -- label key, or item count changes. This keeps typing/clicking smooth
    -- during raids without changing parse data.
    _G.HT_UIMobListCache = _G.HT_UIMobListCache or {}
    local arrKey = tostring(arr or 'nil')
    local count = #(arr or {})
    local first = (arr and arr[1] and arr[1][labelKey]) or ''
    local last = (arr and arr[count] and arr[count][labelKey]) or ''
    local cacheKey = arrKey .. '|' .. tostring(labelKey) .. '|' .. tostring(count) .. '|' .. tostring(first) .. '|' .. tostring(last)
    local cache = _G.HT_UIMobListCache[cacheKey]
    local now = (mq and mq.gettime and mq.gettime()) or (os.time() * 1000)
    if cache and cache.list and ((now - (cache.t or 0)) < 1500) then
        return cache.list
    end

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

    _G.HT_UIMobListCache = {}
    _G.HT_UIMobListCache[cacheKey] = { list = out, t = now }
    return out
end

-- Per-tab combo box selection index. Reset to 0 (= "Pick a mob..."
-- placeholder) on each render; we only act when the user actually
-- changes the selection.
local _comboIdx = { heals = 0, dps = 0, spells = 0, history = 0 }

-- Text typed into the mob search boxes. Kept on _G so this large Lua
-- does not add more top-level locals and trip Lua's 200-local limit.
_G.HT_MobSearchText = _G.HT_MobSearchText or {}
_G.HT_InputTextSafe = _G.HT_InputTextSafe or function(label, value)
    value = tostring(value or '')

    -- Different MQ ImGui builds have returned InputText values in
    -- different orders. This wrapper accepts either:
    --   newText, changed
    --   changed, newText
    -- and safely falls back if the binding is unavailable.
    local ok, a, b = pcall(function()
        return ImGui.InputText(label, value)
    end)
    if not ok then
        return value, false
    end

    if type(a) == 'string' then
        return a, (b == true)
    elseif type(b) == 'string' then
        return b, (a == true)
    end

    return value, false
end

-- Pet mapping UI state (Settings tab). Two combo indices: which
-- unmapped attacker to map (left), and which owner to map them to
-- (right). Reset to 0 (placeholders) after each successful mapping.
local _petMap = {
    petIdx = 0, ownerIdx = 0,
    -- Picked-name state for the BeginCombo-based pet/owner pickers.
    -- nil = nothing picked yet.
    petName = nil, ownerName = nil,
}

showSearchStatus = function(currentSearch, idSuffix, mobList)
    _G.HT_MobSearchText = _G.HT_MobSearchText or {}

    -- Keep the visible text box synced with an active filter, but allow
    -- the user to keep typing partial names without the dropdown fighting it.
    if currentSearch and currentSearch ~= '' and (_G.HT_MobSearchText[idSuffix] or '') == '' then
        _G.HT_MobSearchText[idSuffix] = currentSearch
    end

    -- Status line showing the currently active filter (or hint if none).
    if currentSearch and currentSearch ~= '' then
        ImGui.TextColored(0.55, 1.00, 0.60, 1.0,
            string.format('Filter: "%s"', currentSearch))
        ImGui.SameLine()
        if btn('Clear##clearfilter_' .. idSuffix, 'secondary', 0, 0) then
            _comboIdx[idSuffix] = 0
            _G.HT_MobSearchText[idSuffix] = ''
            return ''
        end
    else
        ImGui.TextColored(0.45, 0.48, 0.55, 1.0,
            'Filter mob: type a name, pick from dropdown, OR /healtracker search <text>')
    end

    -- Search box. Typing here immediately filters the fight list. This
    -- is especially important for History because the full range can be
    -- thousands of rows and is intentionally hidden until a mob filter exists.
    ImGui.Text('Search mob:')
    ImGui.SameLine()
    ImGui.SetNextItemWidth(220)
    local typed = _G.HT_MobSearchText[idSuffix] or currentSearch or ''
    local newTyped, typedChanged = _G.HT_InputTextSafe('##mobsearch_' .. idSuffix, typed)
    if typedChanged then
        _G.HT_MobSearchText[idSuffix] = newTyped or ''
        _comboIdx[idSuffix] = 0
        currentSearch = newTyped or ''
    end

    -- If the typed text narrows the mob list to exactly one mob, show
    -- that as the detected match and allow one-click selection. We do
    -- not force-replace the typed text while the user is still typing.
    local typedLower = ((_G.HT_MobSearchText[idSuffix] or ''):lower())
    local detected = nil
    local detectCount = 0
    if mobList and #mobList > 0 and typedLower ~= '' then
        for _, m in ipairs(mobList) do
            if m:lower():find(typedLower, 1, true) then
                detected = m
                detectCount = detectCount + 1
                if detectCount > 1 then break end
            end
        end
    end
    if detectCount == 1 and detected and detected ~= currentSearch then
        ImGui.SameLine()
        if btn('Use: ' .. detected .. '##use_detected_' .. idSuffix, 'active', 0, 0) then
            _G.HT_MobSearchText[idSuffix] = detected
            return detected
        end
    end

    -- Combo dropdown of unique mob names. When text is typed, the dropdown
    -- only shows matching mobs, so it becomes an auto-complete picker.
    if mobList and #mobList > 0 then
        ImGui.Text('Pick mob:')
        ImGui.SameLine()
        ImGui.SetNextItemWidth(260)

        local previewLabel = (currentSearch and currentSearch ~= '')
                              and currentSearch
                              or '(pick a mob...)'
        local pickedName = nil

        if ImGui.BeginCombo('##mobcombo_' .. idSuffix, previewLabel) then
            local shown = 0
            for _, m in ipairs(mobList) do
                if typedLower == '' or m:lower():find(typedLower, 1, true) then
                    shown = shown + 1
                    local isSelected = (m == currentSearch)
                    if ImGui.Selectable(m, isSelected) then
                        pickedName = m
                    end
                    if isSelected then
                        ImGui.SetItemDefaultFocus()
                    end
                end
            end
            if shown == 0 then
                ImGui.TextColored(0.45, 0.48, 0.55, 1.0, 'No matching mobs')
            end
            ImGui.EndCombo()
        end

        if pickedName then
            _G.HT_MobSearchText[idSuffix] = pickedName
            return pickedName
        end
    end

    return currentSearch
end


-- Mini/Completed Fight popup theme helper.
-- Keeps the floating DPS mini window and completed-fight popup matched to
-- the main glossy blue Heal Tracker UI without using unsafe shadow/gradient code.
_G.HT_PushMiniPopupTheme = function(alpha)
    _G.HT_MiniPopupStyleVarCount = 0
    local function safeStyleVar(var, a, b)
        if var == nil then return end
        local ok = pcall(function()
            if b ~= nil then ImGui.PushStyleVar(var, a, b) else ImGui.PushStyleVar(var, a) end
        end)
        if ok then _G.HT_MiniPopupStyleVarCount = (_G.HT_MiniPopupStyleVarCount or 0) + 1 end
    end

    alpha = math.max(0.10, math.min(1.00, tonumber(alpha) or 1.00))
    safeStyleVar(ImGuiStyleVar.WindowRounding, 18)
    safeStyleVar(ImGuiStyleVar.ChildRounding, 18)
    safeStyleVar(ImGuiStyleVar.PopupRounding, 18)
    safeStyleVar(ImGuiStyleVar.FrameRounding, 18)
    safeStyleVar(ImGuiStyleVar.GrabRounding, 18)
    safeStyleVar(ImGuiStyleVar.ScrollbarRounding, 999)
    safeStyleVar(ImGuiStyleVar.ScrollbarSize, 7)
    safeStyleVar(ImGuiStyleVar.WindowBorderSize, 1)
    safeStyleVar(ImGuiStyleVar.FrameBorderSize, 1)

    ImGui.PushStyleColor(ImGuiCol.WindowBg,        0.000, 0.006, 0.025, alpha)
    ImGui.PushStyleColor(ImGuiCol.ChildBg,         0.000, 0.014, 0.050, math.min(1.0, alpha + 0.08))
    ImGui.PushStyleColor(ImGuiCol.PopupBg,         0.000, 0.010, 0.035, math.min(1.0, alpha + 0.08))
    ImGui.PushStyleColor(ImGuiCol.Border,          0.62, 0.88, 1.00, 0.96)
    ImGui.PushStyleColor(ImGuiCol.FrameBg,         0.006, 0.035, 0.095, 0.98)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered,  0.12, 0.34, 0.62, 0.98)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive,   0.05, 0.55, 1.00, 0.98)
    ImGui.PushStyleColor(ImGuiCol.Button,          0.010, 0.055, 0.135, 1.00)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered,   0.17, 0.54, 0.96, 1.00)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive,    0.06, 0.64, 1.00, 1.00)
    ImGui.PushStyleColor(ImGuiCol.Header,          0.020, 0.080, 0.170, 0.96)
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered,   0.17, 0.48, 0.84, 0.96)
    ImGui.PushStyleColor(ImGuiCol.HeaderActive,    0.06, 0.60, 1.00, 0.96)
    ImGui.PushStyleColor(ImGuiCol.Separator,       0.58, 0.86, 1.00, 0.92)
    ImGui.PushStyleColor(ImGuiCol.ScrollbarBg,     0.000, 0.010, 0.030, 0.35)
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrab,   0.22, 0.66, 1.00, 0.98)
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrabHovered, 0.48, 0.84, 1.00, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TableHeaderBg,   0.000, 0.000, 0.000, 0.00)
    ImGui.PushStyleColor(ImGuiCol.TableRowBg,      0.000, 0.000, 0.000, 0.00)
    ImGui.PushStyleColor(ImGuiCol.TableRowBgAlt,   0.000, 0.000, 0.000, 0.00)
    return 20
end

_G.HT_PopMiniPopupTheme = function(n)
    ImGui.PopStyleColor(n or 20)
    ImGui.PopStyleVar(_G.HT_MiniPopupStyleVarCount or 0)
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

    -- Use the same alpha/transparency setting as the live mini DPS tracker.
    local lastFightAlpha = math.max(0, math.min(100, tonumber(config.miniAlphaPercent) or 100)) / 100
    local lastFightThemeColors = _G.HT_PushMiniPopupTheme(lastFightAlpha)

    local linger = tonumber(config.miniLingerSeconds) or 5
    if linger < 1 then linger = 1 end

    -- Advance the queue. Drop only the head when its display time is up.
    -- New fights can be appended while the first popup is visible; they
    -- remain queued and show next instead of being lost.
    if #miniQueue > 0 then
        if miniQueueCurrentAt == 0 then
            miniQueueCurrentAt = os.time()
        elseif (os.time() - miniQueueCurrentAt) >= linger then
            table.remove(miniQueue, 1)
            _G.HT_MiniQueueShownTotal = (_G.HT_MiniQueueShownTotal or 0) + 1
            if #miniQueue > 0 then
                miniQueueCurrentAt = os.time()
            else
                miniQueueCurrentAt = 0
                _G.HT_MiniQueueShownTotal = 0
                _G.HT_MiniQueueBatchTotal = 0
            end
        end
    else
        miniQueueCurrentAt = 0
    end

    -- Don't render anything if the queue is empty.
    if #miniQueue == 0 then
        _G.HT_PopMiniPopupTheme(lastFightThemeColors)
        return
    end

    local fight = miniQueue[1]
    if not fight then
        _G.HT_PopMiniPopupTheme(lastFightThemeColors)
        return
    end

    local flags = bit32.bor(
        ImGuiWindowFlags.AlwaysAutoResize,
        ImGuiWindowFlags.NoTitleBar,
        ImGuiWindowFlags.NoCollapse,
        ImGuiWindowFlags.NoFocusOnAppearing,
        ImGuiWindowFlags.NoNav)

    local visible, _ = ImGui.Begin('Last Fight##HealTrackerLastFight', true, flags)
    if not visible then
        ImGui.End()
        _G.HT_PopMiniPopupTheme(lastFightThemeColors)
        return
    end

    pcall(function()
        local mobLabel  = fight.label or '?'
        local total     = fight.total or 0
        local dur       = fight._frozenDur or 1
        if dur < 1 then dur = 1 end
        local groupSdps = math.floor(total / dur)

        local mr, mg, mb = mobLevelColor(_G.HT_ResolveMobLevel and _G.HT_ResolveMobLevel(fight.label, fight.mobLevel) or fight.mobLevel)
        ImGui.TextColored(mr, mg, mb, 1.0, mobLabel)
        ImGui.SameLine(0, 8)
        ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0,
            string.format('%s @%s in %ds',
                (_G.HT_CompactDamage and _G.HT_CompactDamage(total) or string.format('%dk', math.floor(total / 1000))),
                fmtNum(groupSdps), dur))

        if #miniQueue > 1 then
            ImGui.SameLine(0, 8)
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                string.format('(%d)', #miniQueue))
        end

        ImGui.Separator()

        local rows = buildDamageRows(fight, config.liveDpsMaxRows or 10)
        local tflags = bit32.bor(ImGuiTableFlags.SizingStretchProp,
                                 ImGuiTableFlags.NoBordersInBody)
        if ImGui.BeginTable('LastFightDpsRows', 2, tflags) then
            ImGui.TableSetupColumn('name', ImGuiTableColumnFlags.WidthFixed, 150)
            ImGui.TableSetupColumn('val',  ImGuiTableColumnFlags.WidthFixed, 150)

            for i, r in ipairs(rows) do
                ImGui.TableNextRow()
                if _G.HT_DrawFloatingRowBg then
                    _G.HT_DrawFloatingRowBg(i, false, (ImGui.GetWindowWidth and ((tonumber(ImGui.GetWindowWidth()) or 320) - 18) or 300), 22, 14)
                end

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

                ImGui.TableNextColumn()
                ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, nameLabel)

                ImGui.TableNextColumn()
                -- Ultra-compact row text so the completed-fight popup stays short.
                -- Old format included active DPS timing and made the window too wide:
                --   64k @ 2,125dps (21,259dps in 3s) [49.2%]
                -- New format:
                --   64k @2.1k [49%]
                local valueText = string.format('%s @%s [%d%%]',
                    (_G.HT_CompactDamage and _G.HT_CompactDamage(r.total or 0) or string.format('%dk', math.floor((r.total or 0) / 1000))),
                    (_G.HT_CompactDamage and _G.HT_CompactDamage(sdps) or fmtNum(sdps)),
                    math.floor(pct + 0.5))
                local availX = ImGui.GetContentRegionAvail()
                local textW = ImGui.CalcTextSize(valueText)
                if type(availX) == 'table' then availX = availX[1] or 0 end
                if type(textW) == 'table' then textW = textW[1] or 0 end
                if availX and textW and availX > textW then
                    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (availX - textW))
                end
                ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, valueText)
            end

            ImGui.EndTable()
        end
    end)

    ImGui.End()
    _G.HT_PopMiniPopupTheme(lastFightThemeColors)
end

-- Bind the implementation to the forward-declared local. The
-- imgui registration at the top of the file references
-- drawLastFightWindow as a closure upvalue; this assignment makes
-- the upvalue point at our actual function.
drawLastFightWindow = drawLastFightWindow_impl

-- =============================================================================
-- Raid event alerts overlay
-- =============================================================================
--
-- Floating window showing active triggered alerts. Auto-hides when no
-- alerts are active. Each alert renders large bold text in its
-- configured color, with a Dismiss button to manually clear it.
-- Auto-dismiss after the trigger's configured timeout.

-- Color name -> RGB. Used by alert rendering and the trigger UI.
local ALERT_COLORS = {
    red    = { 1.00, 0.30, 0.30 },
    orange = { 1.00, 0.65, 0.20 },
    yellow = {1.000, 0.950, 0.320, 1.00},
    white  = { 1.00, 1.00, 1.00 },
    blue   = { 0.50, 0.70, 1.00 },
    green  = { 0.40, 1.00, 0.40 },
}

local function drawAlertsWindow_impl()
    if shuttingDown then return end
    if not isDriver() then return end

    -- Drop expired alerts and ones the user manually dismissed via the
    -- red X. We use an explicit _dismissed flag rather than mutating
    -- dismissAfter, because dismissAfter <= 0 is a legitimate config
    -- value meaning "manual dismiss only, never auto-expire" -- if
    -- we set it to -1 to force expiry, the prune branch would treat
    -- it as "manual only" and KEEP the alert forever.
    local nowSec = os.time()
    local kept = {}
    for _, a in ipairs(activeAlerts) do
        if not a._dismissed then
            local life = a.dismissAfter or 8
            -- life <= 0 means manual-dismiss-only (no auto-expire).
            if life <= 0 or (nowSec - a.firedAt) < life then
                table.insert(kept, a)
            end
        end
    end
    activeAlerts = kept

    if #activeAlerts == 0 then return end

    local flags = bit32.bor(
        ImGuiWindowFlags.AlwaysAutoResize,
        ImGuiWindowFlags.NoTitleBar,
        ImGuiWindowFlags.NoCollapse,
        ImGuiWindowFlags.NoFocusOnAppearing,
        ImGuiWindowFlags.NoNav)

    -- ImGui.Begin returns (visible_for_drawing, still_open). If the
    -- user clicked the title-bar X, still_open becomes false. We
    -- treat that as "dismiss all alerts" since the window has no
    -- other content -- closing it should clear the queue.
    local visible, stillOpen = ImGui.Begin('Raid Alerts##HealTrackerAlerts', true, flags)
    if stillOpen == false then
        for _, a in ipairs(activeAlerts) do
            a._dismissed = true
        end
        if visible then ImGui.End() end
        return
    end
    if not visible then
        ImGui.End()
        return
    end

    pcall(function()
        for _, a in ipairs(activeAlerts) do
            local rgb = ALERT_COLORS[a.color] or ALERT_COLORS.red

            -- Split the label on newlines so multi-line alerts render
            -- one line per row. The timer + dismiss button hang off
            -- the LAST line (looks like a single block with the X
            -- aligned to the right of the message).
            local label = a.label or '!'
            local lines = {}
            for chunk in (label .. '\n'):gmatch('(.-)\n') do
                table.insert(lines, chunk)
            end
            if #lines == 0 then table.insert(lines, label) end

            ImGui.PushStyleColor(ImGuiCol.Text, rgb[1], rgb[2], rgb[3], 1.0)
            for i, line in ipairs(lines) do
                ImGui.Text('  ' .. line .. '  ')
                if i < #lines then
                    -- not the last line; nothing else attaches here
                else
                    -- Last line: pop color so the timer+X aren't tinted,
                    -- then attach the timer and dismiss button on the
                    -- same row.
                    ImGui.PopStyleColor()

                    ImGui.SameLine(0, 12)
                    local life = a.dismissAfter or 8
                    if life > 0 then
                        local remaining = math.max(0, life - (nowSec - a.firedAt))
                        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                            string.format('(%ds)', remaining))
                        ImGui.SameLine(0, 8)
                    end

                    if btn('X##alert_' .. a.id, 'danger', 0, 0) then
                        a._dismissed = true
                    end
                end
            end
        end
    end)

    ImGui.End()
end

drawAlertsWindow = drawAlertsWindow_impl

-- =============================================================================
-- Mini view
-- =============================================================================


-- Compact damage formatter for live DPS mini rows.
-- 10573 -> 10k, 234000 -> 234k, 1200000 -> 1.200m
_G.HT_CompactDamage = function(n)
    n = tonumber(n) or 0
    if n >= 1000000 then
        return string.format('%.3fm', n / 1000000)
    end
    if n >= 1000 then
        return string.format('%dk', math.floor((n / 1000) + 0.5))
    end
    return tostring(math.floor(n + 0.5))
end


-- Bright yellow used by Last Fight popup and live DPS.
-- Stored on _G to avoid Lua's 200 top-level local variable limit.
_G.HT_MINI_BRIGHT_YELLOW = _G.HT_MINI_BRIGHT_YELLOW or {1.00, 0.93, 0.15, 1.00}
_G.HT_MINI_BRIGHT_YELLOW_DIM = _G.HT_MINI_BRIGHT_YELLOW_DIM or {0.95, 0.88, 0.10, 1.00}

-- Softer GamParse-style gold/yellow used for mini tracker text.
_G.HT_MiniGold = _G.HT_MiniGold or {0.96, 0.84, 0.18, 1.0}

-- Mini tracker position persistence. Kept on _G so it doesn't add more
-- long-lived local state to this already-large Lua file.
_G.HT_LastMiniPosSaveMs = _G.HT_LastMiniPosSaveMs or 0
_G.HT_LastMiniPosChangeMs = _G.HT_LastMiniPosChangeMs or 0
_G.HT_LastMiniPosX = _G.HT_LastMiniPosX or nil
_G.HT_LastMiniPosY = _G.HT_LastMiniPosY or nil
_G.HT_MiniPosDirty = _G.HT_MiniPosDirty or false
_G.HT_MiniPosApplied = _G.HT_MiniPosApplied or false

_G.HT_ReadImGuiVec2 = function(a, b)
    if type(a) == 'table' then
        return tonumber(a[1] or a.x or a.X), tonumber(a[2] or a.y or a.Y)
    end
    return tonumber(a), tonumber(b)
end

_G.HT_ApplySavedMiniPosition = function()
    if _G.HT_MiniPosApplied then return end
    local x = tonumber(config.miniPosX)
    local y = tonumber(config.miniPosY)
    if not x or not y then return end
    _G.HT_MiniPosApplied = true
    pcall(function()
        if ImGuiCond and ImGuiCond.Once then
            ImGui.SetNextWindowPos(x, y, ImGuiCond.Once)
        elseif ImGuiCond and ImGuiCond.FirstUseEver then
            ImGui.SetNextWindowPos(x, y, ImGuiCond.FirstUseEver)
        else
            ImGui.SetNextWindowPos(x, y)
        end
    end)
end

_G.HT_SaveMiniPositionIfMoved = function(force)
    if not ImGui.GetWindowPos then return end
    local ok, a, b = pcall(ImGui.GetWindowPos)
    if not ok then return end
    local x, y = _G.HT_ReadImGuiVec2(a, b)
    if not x or not y then return end
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    local oldX = tonumber(config.miniPosX)
    local oldY = tonumber(config.miniPosY)
    local t = nowMs()

    -- Always keep the live config updated so a later save writes the latest
    -- position, even if the user is still dragging the mini window.
    if oldX ~= x or oldY ~= y then
        config.miniPosX = x
        config.miniPosY = y
        _G.HT_LastMiniPosX = x
        _G.HT_LastMiniPosY = y
        _G.HT_LastMiniPosChangeMs = t
        _G.HT_MiniPosDirty = true
    end

    if not _G.HT_MiniPosDirty and not force then return end

    -- Save the final dropped position quickly, but avoid disk spam while the
    -- window is actively being dragged. This fixes the mini live DPS tracker
    -- reverting after restarting EQ/MQ because the last position only lived
    -- in memory and never made it to config.lua.
    local mouseDown = false
    pcall(function()
        if ImGui.IsMouseDown then mouseDown = ImGui.IsMouseDown(0) == true end
    end)

    local lastSave = tonumber(_G.HT_LastMiniPosSaveMs) or 0
    local lastChange = tonumber(_G.HT_LastMiniPosChangeMs) or 0
    local saveNow = force == true
        or (not mouseDown and (t - lastSave) >= 250)
        or ((t - lastSave) >= 1500 and (t - lastChange) >= 250)

    if saveNow then
        saveConfig()
        _G.HT_LastMiniPosSaveMs = t
        _G.HT_MiniPosDirty = false
    end
end
local function drawMini()
    local miniAlpha = math.max(0, math.min(100, tonumber(config.miniAlphaPercent) or 100)) / 100
    local miniThemeColors = _G.HT_PushMiniPopupTheme(miniAlpha)

    local flags = bit32.bor(
        ImGuiWindowFlags.AlwaysAutoResize,
        ImGuiWindowFlags.NoResize,
        ImGuiWindowFlags.NoTitleBar,
        ImGuiWindowFlags.NoCollapse,
        ImGuiWindowFlags.NoSavedSettings,
        ImGuiWindowFlags.NoFocusOnAppearing,
        ImGuiWindowFlags.NoNav)

    local showDps = config.miniShowDps == true

    if _G.HT_ApplySavedMiniPosition then _G.HT_ApplySavedMiniPosition() end

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
        ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0,
                          showDps and 'DPS Tracker' or 'Heal Tracker')
        ImGui.SameLine(0, 8)
        -- Mode toggle. Single click flips between the two live views.
        local toggleLabel = showDps and 'Heals##ht_mini_toggle' or 'DPS##ht_mini_toggle'
        if btn(toggleLabel, 'secondary', 0, 0) then
            config.miniShowDps = not showDps
            saveConfig()
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

            -- Keep the live DPS mini short: mob name goes on its own line,
            -- then the compact stat row stays narrow underneath it.
            if (displayScope.count or 0) > 0 and displayScope.label and displayScope.label ~= '' then
                local liveMobLevel = _G.HT_ResolveMobLevel and _G.HT_ResolveMobLevel(displayScope.label, displayScope.mobLevel) or displayScope.mobLevel
                local mr, mg, mb = mobLevelColor(liveMobLevel)
                ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'Mob:')
                ImGui.SameLine(0, 4)
                ImGui.TextColored(mr, mg, mb, 1.0, displayScope.label)
            end

            ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'Total:')
            ImGui.SameLine(0, 3)
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              (_G.HT_CompactDamage and _G.HT_CompactDamage(displayScope.total or 0) or fmtNum(displayScope.total)))
            ImGui.SameLine(0, 8)
            ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'DPS:')
            ImGui.SameLine(0, 3)
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              (_G.HT_CompactDamage and _G.HT_CompactDamage((displayScope.total or 0) / dur) or fmtNum((displayScope.total or 0) / dur)))
            ImGui.SameLine(0, 8)
            ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'Time:')
            ImGui.SameLine(0, 3)
            ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                              string.format('%02d:%02d', math.floor(dur / 60), dur % 60))
            if isLingering then
                ImGui.SameLine(0, 8)
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, '(last)')
            end

            ImGui.Separator()

            if (displayScope.count or 0) == 0 then
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                    'No active fight. Damage shows here in real time.')
            else
                local rows = buildDamageRows(displayScope, config.liveDpsMaxRows or 10)
                -- Single-column layout: each row reads as
                --   <Name>   <total>k @<dps>
                -- so the user sees both the cumulative damage and the
                -- live DPS at a glance.
                -- Auto-width live DPS table: stay compact, but widen when names/numbers need it.
                -- This prevents long damage/DPS values from being clipped while keeping normal fights short.
                local miniNameW = 105
                local miniValW  = 95
                pcall(function()
                    for _, row in ipairs(rows) do
                        local nameLabel = row.attacker or ''
                        if row.hasPets and not (config.splitPetsInDps == true) then
                            nameLabel = nameLabel .. ' + pets'
                        end
                        local rowDps = (row.total or 0) / dur
                        local rowPct = ((displayScope.total or 0) > 0) and ((row.total or 0) * 100 / (displayScope.total or 1)) or 0
                        local valueText = string.format('%s @%s [%d%%]',
                            (_G.HT_CompactDamage and _G.HT_CompactDamage(row.total or 0) or fmtNum(row.total or 0)),
                            (_G.HT_CompactDamage and _G.HT_CompactDamage(rowDps) or fmtNum(rowDps)),
                            math.floor(rowPct + 0.5))
                        local nw = ImGui.CalcTextSize(nameLabel)
                        local vw = ImGui.CalcTextSize(valueText)
                        if type(nw) == 'table' then nw = nw[1] or 0 end
                        if type(vw) == 'table' then vw = vw[1] or 0 end
                        miniNameW = math.max(miniNameW, math.min(175, (tonumber(nw) or 0) + 12))
                        miniValW  = math.max(miniValW,  math.min(150, (tonumber(vw) or 0) + 12))
                    end
                end)

                local tflags = bit32.bor(ImGuiTableFlags.SizingFixedFit,
                                         ImGuiTableFlags.NoBordersInBody)
                if ImGui.BeginTable('DpsMini', 2, tflags) then
                    ImGui.TableSetupColumn('name', ImGuiTableColumnFlags.WidthFixed, miniNameW)
                    ImGui.TableSetupColumn('val',  ImGuiTableColumnFlags.WidthFixed, miniValW)
                    for rowIdx, row in ipairs(rows) do
                        ImGui.TableNextRow()
                        if _G.HT_DrawFloatingRowBg then
                            _G.HT_DrawFloatingRowBg(rowIdx, false, (ImGui.GetWindowWidth and ((tonumber(ImGui.GetWindowWidth()) or 320) - 18) or 300), 22, 14)
                        end
                        -- Name column: highlighted for "you", append
                        -- " + pets" if the row aggregates pets.
                        ImGui.TableNextColumn()
                        local nameLabel = row.attacker
                        if row.hasPets and not (config.splitPetsInDps == true) then
                            nameLabel = nameLabel .. ' + pets'
                        end
                        -- Use same yellow as DPS numbers for names
                        ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0,
                                          nameLabel)

                        -- Right-aligned value column, GamParse style.
                        -- Keeps damage/DPS/% visually lined up down the right edge.
                        ImGui.TableNextColumn()
                        local rowDps = (row.total or 0) / dur
                        local rowPct = ((displayScope.total or 0) > 0) and ((row.total or 0) * 100 / (displayScope.total or 1)) or 0
                        local valueText = string.format('%s @%s [%d%%]',
                            (_G.HT_CompactDamage and _G.HT_CompactDamage(row.total or 0) or fmtNum(row.total or 0)),
                            (_G.HT_CompactDamage and _G.HT_CompactDamage(rowDps) or fmtNum(rowDps)),
                            math.floor(rowPct + 0.5))
                        local availX = ImGui.GetContentRegionAvail()
                        local textW = ImGui.CalcTextSize(valueText)
                        if type(availX) == 'table' then availX = availX[1] or 0 end
                        if type(textW) == 'table' then textW = textW[1] or 0 end
                        if availX and textW and availX > textW then
                            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (availX - textW))
                        end
                        ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0, valueText)
                    end
                    ImGui.EndTable()
                end
            end
        else
            ----------------------------------------------------------------
            -- Heals mini view: compact themed layout matching DPS mini.
            -- Mob/current fight gets its own line, stats are kept tight,
            -- and healer rows auto-size so longer names/values do not clip.
            ----------------------------------------------------------------
            local healLiveScope = combineActiveMobs()
            local healDur = math.max(1, os.time() - (healLiveScope.started or os.time()))
            if healDur < 1 then healDur = 1 end

            if (healLiveScope.count or 0) > 0 and healLiveScope.label and healLiveScope.label ~= '' then
                local healMobLevel = _G.HT_ResolveMobLevel and _G.HT_ResolveMobLevel(healLiveScope.label, healLiveScope.mobLevel) or healLiveScope.mobLevel
                local hmr, hmg, hmb = mobLevelColor(healMobLevel)
                ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'Mob:')
                ImGui.SameLine(0, 4)
                ImGui.TextColored(hmr, hmg, hmb, 1.0, healLiveScope.label)
            else
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, 'Mob: none')
            end

            ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'Total:')
            ImGui.SameLine(0, 3)
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              (_G.HT_CompactDamage and _G.HT_CompactDamage(session.total or 0) or fmtNum(session.total)))
            ImGui.SameLine(0, 8)
            ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'Heals:')
            ImGui.SameLine(0, 3)
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              tostring(session.count or 0))
            if (healLiveScope.count or 0) > 0 then
                ImGui.SameLine(0, 8)
                ImGui.TextColored(_G.HT_MiniGold[1], _G.HT_MiniGold[2], _G.HT_MiniGold[3], 1.0, 'Time:')
                ImGui.SameLine(0, 3)
                ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                  string.format('%02d:%02d', math.floor(healDur / 60), healDur % 60))
            end

            ImGui.Separator()

            if session.count == 0 then
                ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                    'No heals tracked yet.')
            else
                local rows = buildRowsFor(session)
                local miniNameW = 95
                local miniValW = 70
                pcall(function()
                    for _, row in ipairs(rows) do
                        local nameText = row.char or ''
                        local valueText = (_G.HT_CompactDamage and _G.HT_CompactDamage(row.total or 0) or fmtNum(row.total or 0))
                        local nw = ImGui.CalcTextSize(nameText)
                        local vw = ImGui.CalcTextSize(valueText)
                        if type(nw) == 'table' then nw = nw[1] or 0 end
                        if type(vw) == 'table' then vw = vw[1] or 0 end
                        miniNameW = math.max(miniNameW, math.min(155, (tonumber(nw) or 0) + 12))
                        miniValW = math.max(miniValW, math.min(120, (tonumber(vw) or 0) + 12))
                    end
                end)

                local tflags = bit32.bor(ImGuiTableFlags.SizingFixedFit,
                                         ImGuiTableFlags.NoBordersInBody)
                if ImGui.BeginTable('HealMini', 2, tflags) then
                    ImGui.TableSetupColumn('name', ImGuiTableColumnFlags.WidthFixed, miniNameW)
                    ImGui.TableSetupColumn('val',  ImGuiTableColumnFlags.WidthFixed, miniValW)
                    for rowIdx, row in ipairs(rows) do
                        ImGui.TableNextRow()
                        if _G.HT_DrawFloatingRowBg then
                            _G.HT_DrawFloatingRowBg(rowIdx, false, (ImGui.GetWindowWidth and ((tonumber(ImGui.GetWindowWidth()) or 260) - 18) or 240), 22, 14)
                        end
                        ImGui.TableNextColumn()
                        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
                                          row.char or '?')
                        ImGui.TableNextColumn()
                        local valueText = (_G.HT_CompactDamage and _G.HT_CompactDamage(row.total or 0) or fmtNum(row.total or 0))
                        local availX = ImGui.GetContentRegionAvail()
                        local textW = ImGui.CalcTextSize(valueText)
                        if type(availX) == 'table' then availX = availX[1] or 0 end
                        if type(textW) == 'table' then textW = textW[1] or 0 end
                        if availX and textW and availX > textW then
                            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (availX - textW))
                        end
                        ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                                          valueText)
                    end
                    ImGui.EndTable()
                end
            end
        end
    end
    end)  -- close pcall around the body

    if shouldDraw and _G.HT_SaveMiniPositionIfMoved then _G.HT_SaveMiniPositionIfMoved() end

    ImGui.End()
    -- These pops balance the pushes BEFORE Begin() (window-level
    -- styling), so they need to run regardless of body errors.
    _G.HT_PopMiniPopupTheme(miniThemeColors)
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

    -- Cleaner heal parse layout:
    -- 1) Tabs/buttons across the top show healing received by each player.
    -- 2) Clicking a player shows exactly who healed that player.
    -- 3) Source table lists healer/rune/self-proc totals for the selected player.
    _G.HT_HealTargetSelection = _G.HT_HealTargetSelection or {}

    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Healing received by player. Click a player tab to see who healed them, including rune absorbs.')

    local rows = buildRowsFor(scope)
    if #rows == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No player heal rows to display.')
        return
    end

    local selected = _G.HT_HealTargetSelection[idPrefix]
    local foundSelected = false
    for _, r in ipairs(rows) do
        if r.char == selected then foundSelected = true; break end
    end
    if not foundSelected then
        selected = rows[1].char
        _G.HT_HealTargetSelection[idPrefix] = selected
    end

    -- Player tabs/buttons. This avoids relying on ImGui tab APIs that vary
    -- between MQ builds, but visually works like the prior tab strip.
    for i, r in ipairs(rows) do
        if i > 1 then ImGui.SameLine(0, 4) end

        local label = string.format('%s (%s)', r.char or '?', fmtNum(r.total or 0))
        local isSelected = (r.char == selected)

        if isSelected then
            if btn(label .. '##heal_target_' .. idPrefix .. '_' .. i, 'primary', 0, 0) then
                _G.HT_HealTargetSelection[idPrefix] = r.char
            end
        else
            if btn(label .. '##heal_target_' .. idPrefix .. '_' .. i, 'secondary', 0, 0) then
                _G.HT_HealTargetSelection[idPrefix] = r.char
            end
        end
    end

    ImGui.Separator()

    local targetRow = nil
    for _, r in ipairs(rows) do
        if r.char == _G.HT_HealTargetSelection[idPrefix] then
            targetRow = r
            break
        end
    end
    if not targetRow then targetRow = rows[1] end
    if not targetRow then return end

    local total = tonumber(targetRow.total) or 0
    local count = tonumber(targetRow.count) or 0
    local avg = total / math.max(1, count)
    local maxHeal = tonumber(targetRow.max) or 0

    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        string.format('Player: %s', targetRow.char or '?'))
    ImGui.Text(string.format('Total healing received: %s', fmtNum(total)))
    ImGui.Text(string.format('Total healed others: %s', fmtNum(scope.stats[targetRow.char] and scope.stats[targetRow.char].healedOthers or 0)))
    ImGui.Text(string.format('Total heals / rune procs: %d', count))
    ImGui.Text(string.format('Average received: %s', fmtNum(avg)))
    ImGui.Text(string.format('Largest heal/rune: %s', fmtNum(maxHeal)))

    ImGui.Spacing()

    _G.HT_BeginRoundedBox(idPrefix .. '_heal_sources_box', 92)
    if ImGui.BeginTable(idPrefix .. '_heal_sources', 5, _G.HT_RoundedTableFlags()) then
        ImGui.TableSetupColumn('Source')
        ImGui.TableSetupColumn('Total HP')
        ImGui.TableSetupColumn('Count')
        ImGui.TableSetupColumn('Avg')
        ImGui.TableSetupColumn('Max')
        _G.HT_TableHeaderRow({'Source', 'Total HP', 'Count', 'Avg', 'Max'})

        local sourceRows = {}
        for healer, h in pairs(targetRow.healers or {}) do
            local hTotal = tonumber(h.total) or 0
            local hCount = tonumber(h.count) or 0
            table.insert(sourceRows, {
                name = healer,
                total = hTotal,
                count = hCount,
                avg = hTotal / math.max(1, hCount),
                max = tonumber(h.max) or 0,
                isMe = (healer == MyName),
            })
        end

        table.sort(sourceRows, function(a, b)
            if (a.total or 0) == (b.total or 0) then
                return tostring(a.name or '') < tostring(b.name or '')
            end
            return (a.total or 0) > (b.total or 0)
        end)

        for _, h in ipairs(sourceRows) do
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(0, false)

            ImGui.TableNextColumn()
            local name = h.name or '?'
            if h.isMe then name = name .. ' (you)' end
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0, name)

            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              fmtNum(h.total or 0))

            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              tostring(h.count or 0))

            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              fmtNum(h.avg or 0))

            ImGui.TableNextColumn()
            ImGui.TextColored(THEME.valueHeal[1], THEME.valueHeal[2], THEME.valueHeal[3], 1.0,
                              fmtNum(h.max or 0))
        end

        ImGui.EndTable()
    end
    _G.HT_EndRoundedBox()
end

-- =============================================================================
-- DPS tab
-- =============================================================================

-- Draw the per-attacker breakdown table for a damage scope. Mirrors
-- drawCharTable but for damage instead of heals.


_G.HT_DpsComparePick = _G.HT_DpsComparePick or {}

_G.HT_DpsCompareToggle = _G.HT_DpsCompareToggle or function(name)
    if type(name) ~= 'string' or name == '' then return end
    local pick = _G.HT_DpsComparePick or {}
    _G.HT_DpsComparePick = pick
    if pick[1] == name then
        pick[1] = pick[2]
        pick[2] = nil
        return
    end
    if pick[2] == name then
        pick[2] = nil
        return
    end
    if not pick[1] then
        pick[1] = name
    elseif not pick[2] then
        pick[2] = name
    else
        pick[1] = pick[2]
        pick[2] = name
    end
end

_G.HT_DpsCompareIsPicked = _G.HT_DpsCompareIsPicked or function(name)
    local pick = _G.HT_DpsComparePick or {}
    return pick[1] == name or pick[2] == name
end

_G.HT_DpsTypeTotal = _G.HT_DpsTypeTotal or function(st, key)
    if not st or not st.dmgTypes then return 0 end
    local rec = st.dmgTypes[key]
    if not rec then return 0 end
    return tonumber(rec.total) or 0
end

_G.HT_DpsCompareCell = _G.HT_DpsCompareCell or function(valueText, isWinner)
    if isWinner then
        ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0, valueText)
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, valueText)
    end
end

_G.HT_DrawDpsTypeCompare = _G.HT_DrawDpsTypeCompare or function(scope, idPrefix, typeOrder, durationSec, spellsScope)
    local pick = _G.HT_DpsComparePick or {}
    if not pick[1] or not pick[2] then
        ImGui.Spacing()
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'Compare mode: click Compare beside two players to compare their damage type breakdowns.')
        return
    end
    if not scope or not scope.stats or not scope.stats[pick[1]] or not scope.stats[pick[2]] then return end

    local aName, bName = pick[1], pick[2]
    local a, b = scope.stats[aName], scope.stats[bName]
    local dur = math.max(1, tonumber(durationSec) or ((scope.ended or os.time()) - (scope.started or os.time())) or 1)
    local aTotal, bTotal = a.total or 0, b.total or 0

    local function cleanCompareName(n)
        if _G.HT_CleanCompareActorName then return _G.HT_CleanCompareActorName(n) end
        n = tostring(n or '')
        n = n:gsub('%s%+%s+pets$', '')
        n = n:gsub('%s%+%s+pet$', '')
        n = n:gsub('%s*%(%s*you%s*%)%s*$', '')
        n = n:gsub('^%s+', ''):gsub('%s+$', '')
        return n
    end

    local function spellCastCountFor(n)
        if not spellsScope or not spellsScope.stats then return 0 end
        local key = cleanCompareName(n)
        local direct = spellsScope.stats[n] or spellsScope.stats[key]
        if direct then return tonumber(direct.total) or 0 end
        local low = key:lower()
        for caster, rec in pairs(spellsScope.stats or {}) do
            if cleanCompareName(caster):lower() == low then
                return tonumber(rec.total) or 0
            end
        end
        return 0
    end

    local function spellCastTableFor(n)
        if not spellsScope or not spellsScope.stats then return {} end
        local key = cleanCompareName(n)
        local rec = spellsScope.stats[n] or spellsScope.stats[key]
        if not rec then
            local low = key:lower()
            for caster, r in pairs(spellsScope.stats or {}) do
                if cleanCompareName(caster):lower() == low then
                    rec = r
                    break
                end
            end
        end
        return (rec and rec.casts) or {}
    end

    local function isMeleeCompareDiscName(name)
        name = tostring(name or '')
        local low = name:lower()
        if low == '' then return false end

        -- Do not show caster/healer spires or caster burns in the MELEE discipline compare.
        -- They may still be recorded in the fight data for future caster compare views.
        local casterOnly = {
            'first spire of arcanum',      -- Wizard
            'first spire of elements',     -- Magician
            'first spire of enchantment',  -- Enchanter
            'first spire of necromancy',   -- Necromancer
            'first spire of divinity',     -- Cleric
            'first spire of nature',       -- Druid
            'first spire of ancestors',    -- Shaman
            'twincast',
            'healing twincast',
            'serenity',
            'elemental union',
        }
        for _, bad in ipairs(casterOnly) do
            if low:find(bad, 1, true) then return false end
        end

        -- Keep true melee/ranged ADPS and melee disciplines even when the name does not
        -- literally contain "Discipline".
        local meleeKeep = {
            'discipline',
            'crystal palm',
            'quick time',
            'auspice of the hunter',
            'guardian of the forest',
            'outrider',
            'trueshot',
            'ashenhand',
            'speed focus',
            'glyph of recovery',
            'first spire of the sensei',
            'first spire of the warlord',
            'first spire of the rake',
            'first spire of the pathfinders',
            'first spire of the savage lord',
            'first spire of savagery',
            'first spire of the reavers',
            'frenzy of spirit',
            'savage spirit',
            'bestial alignment',
            'rake',
            'duelist',
            'deadly precision',
            'focused fury',
            'juggernaut',
            'blinding speed',
            'hallowforge',
            'third spire of holiness',
            'valorous rage',
            'armor of the inquisitor',
            'inquisitor',
        }
        for _, keep in ipairs(meleeKeep) do
            if low:find(keep, 1, true) then return true end
        end
        return false
    end

    local function filterMeleeCompareDiscList(list)
        local out = {}
        for _, rec in ipairs(list or {}) do
            if rec and isMeleeCompareDiscName(rec.name) then
                table.insert(out, rec)
            end
        end
        table.sort(out, function(a, b)
            local ar = tonumber(a and a.rel) or 999999
            local br = tonumber(b and b.rel) or 999999
            if ar ~= br then return ar < br end
            return tostring(a and a.name or '') < tostring(b and b.name or '')
        end)
        return out
    end

    local function discBurnListFor(n)
        if not scope or not scope.discBurns then return {} end
        local key = cleanCompareName(n)
        local direct = scope.discBurns[n] or scope.discBurns[key]
        if direct then return filterMeleeCompareDiscList(direct) end
        local low = key:lower()
        for player, list in pairs(scope.discBurns or {}) do
            if cleanCompareName(player):lower() == low then
                return filterMeleeCompareDiscList(list or {})
            end
        end
        return {}
    end

    local function discBurnCountFor(n)
        local list = discBurnListFor(n)
        return #list
    end

    ImGui.Spacing()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0, 'Player Compare')
    ImGui.SameLine()
    if ImGui.Button('Clear Compare##' .. tostring(idPrefix)) then
        _G.HT_DpsComparePick = {}
    end

    _G.HT_BeginRoundedBox(idPrefix .. '_compare_box', _G.HT_RoundedTableHeight(12, 8))
    if ImGui.BeginTable(idPrefix .. '_compare_tbl', 4, _G.HT_RoundedTableFlags()) then
        ImGui.TableSetupColumn('Metric')
        ImGui.TableSetupColumn(aName)
        ImGui.TableSetupColumn(bName)
        ImGui.TableSetupColumn('Winner')
        _G.HT_TableHeaderRow({'Metric', aName, bName, 'Winner'})

        local function row(metric, av, bv, asText, bsText)
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(0, false)
            ImGui.TableNextColumn(); ImGui.Text(metric)
            ImGui.TableNextColumn(); _G.HT_DpsCompareCell(asText or fmtNum(av), av >= bv)
            ImGui.TableNextColumn(); _G.HT_DpsCompareCell(bsText or fmtNum(bv), bv >= av)
            ImGui.TableNextColumn()
            if av == bv then ImGui.Text('Tie') elseif av > bv then ImGui.Text(aName) else ImGui.Text(bName) end
        end

        row('Total Damage', aTotal, bTotal, fmtNum(aTotal), fmtNum(bTotal))
        row('DPS', aTotal / dur, bTotal / dur, fmtNum(aTotal / dur), fmtNum(bTotal / dur))
        row('Hits', a.count or 0, b.count or 0, tostring(a.count or 0), tostring(b.count or 0))
        row('Max Hit', a.max or 0, b.max or 0, fmtNum(a.max or 0), fmtNum(b.max or 0))
        row('Spell Casts', spellCastCountFor(aName), spellCastCountFor(bName),
            tostring(spellCastCountFor(aName)), tostring(spellCastCountFor(bName)))
        row('Melee Disciplines', discBurnCountFor(aName), discBurnCountFor(bName),
            tostring(discBurnCountFor(aName)), tostring(discBurnCountFor(bName)))

        for _, info in ipairs(typeOrder or {}) do
            local av = _G.HT_DpsTypeTotal(a, info.key)
            local bv = _G.HT_DpsTypeTotal(b, info.key)
            local ap = (aTotal > 0) and (av * 100 / aTotal) or 0
            local bp = (bTotal > 0) and (bv * 100 / bTotal) or 0
            row(info.label .. ' Damage', ap, bp,
                string.format('%s (%.0f%%)', fmtNum(av), ap),
                string.format('%s (%.0f%%)', fmtNum(bv), bp))
        end

        ImGui.EndTable()
    end
    _G.HT_EndRoundedBox()

    local aCasts = spellCastTableFor(aName)
    local bCasts = spellCastTableFor(bName)
    local spellRows = {}
    local seen = {}
    for spell, n in pairs(aCasts or {}) do
        seen[spell] = true
        table.insert(spellRows, { spell = spell, a = tonumber(n) or 0, b = tonumber((bCasts or {})[spell]) or 0 })
    end
    for spell, n in pairs(bCasts or {}) do
        if not seen[spell] then
            table.insert(spellRows, { spell = spell, a = 0, b = tonumber(n) or 0 })
        end
    end
    table.sort(spellRows, function(x, y)
        local xt = (x.a or 0) + (x.b or 0)
        local yt = (y.a or 0) + (y.b or 0)
        if xt ~= yt then return xt > yt end
        return tostring(x.spell or '') < tostring(y.spell or '')
    end)

    ImGui.Spacing()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0, 'Compared Spells Cast')
    if #spellRows == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, 'No spell cast detail recorded for these players on this fight.')
    else
        local shown = math.min(#spellRows, 40)
        _G.HT_BeginRoundedBox(idPrefix .. '_compare_spells_box', _G.HT_RoundedTableHeight(shown, 8))
        if ImGui.BeginTable(idPrefix .. '_compare_spells_tbl', 4, _G.HT_RoundedTableFlags()) then
        ImGui.TableSetupColumn('Spell')
        ImGui.TableSetupColumn(aName)
        ImGui.TableSetupColumn(bName)
        ImGui.TableSetupColumn('Winner')
        _G.HT_TableHeaderRow({'Spell', aName, bName, 'Winner'})
        for i = 1, shown do
            local r = spellRows[i]
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(0, false)
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.spell or ''))
            ImGui.TableNextColumn(); _G.HT_DpsCompareCell(tostring(r.a or 0), (r.a or 0) >= (r.b or 0))
            ImGui.TableNextColumn(); _G.HT_DpsCompareCell(tostring(r.b or 0), (r.b or 0) >= (r.a or 0))
            ImGui.TableNextColumn()
            if (r.a or 0) == (r.b or 0) then ImGui.Text('Tie') elseif (r.a or 0) > (r.b or 0) then ImGui.Text(aName) else ImGui.Text(bName) end
        end
            ImGui.EndTable()
        end
        _G.HT_EndRoundedBox()
    end

    local function buildDiscRows()
        local rows = {}
        local listA = discBurnListFor(aName) or {}
        local listB = discBurnListFor(bName) or {}
        local maxN = math.max(#listA, #listB)
        for i = 1, maxN do
            local da = listA[i]
            local db = listB[i]
            table.insert(rows, {
                aName = da and da.name or '',
                aRel = da and tonumber(da.rel) or nil,
                bName = db and db.name or '',
                bRel = db and tonumber(db.rel) or nil,
            })
        end
        return rows
    end

    local discRows = buildDiscRows()
    ImGui.Spacing()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0, 'Compared Melee Disciplines')
    if #discRows == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, 'No observed melee discipline/burn messages recorded for these players on this fight.')
    else
        local shownDisc = math.min(#discRows, 20)
        _G.HT_BeginRoundedBox(idPrefix .. '_compare_discs_box', _G.HT_RoundedTableHeight(shownDisc, 8))
        if ImGui.BeginTable(idPrefix .. '_compare_discs_tbl', 4, _G.HT_RoundedTableFlags()) then
            ImGui.TableSetupColumn('Burn #')
            ImGui.TableSetupColumn(aName)
            ImGui.TableSetupColumn(bName)
            ImGui.TableSetupColumn('Earlier')
            _G.HT_TableHeaderRow({'Burn #', aName, bName, 'Earlier'})
            local function fmtDisc(name, rel)
                if not name or name == '' then return '-' end
                rel = tonumber(rel)
                if rel then
                    return string.format('%02d:%02d %s', math.floor(rel / 60), rel % 60, tostring(name))
                end
                return tostring(name)
            end
            for i = 1, shownDisc do
                local r = discRows[i]
                ImGui.TableNextRow()
                _G.HT_DrawFloatingRowBg(0, false)
                ImGui.TableNextColumn(); ImGui.Text(tostring(i))
                ImGui.TableNextColumn(); ImGui.Text(fmtDisc(r.aName, r.aRel))
                ImGui.TableNextColumn(); ImGui.Text(fmtDisc(r.bName, r.bRel))
                ImGui.TableNextColumn()
                if r.aRel and r.bRel then
                    if r.aRel == r.bRel then ImGui.Text('Tie') elseif r.aRel < r.bRel then ImGui.Text(aName) else ImGui.Text(bName) end
                elseif r.aRel then
                    ImGui.Text(aName)
                elseif r.bRel then
                    ImGui.Text(bName)
                else
                    ImGui.Text('-')
                end
            end
            ImGui.EndTable()
        end
        _G.HT_EndRoundedBox()
    end
end

_G.HT_DrawDamageTypeBreakdown = _G.HT_DrawDamageTypeBreakdown or function(scope, idPrefix, durationSec, spellsScope)
    if not scope or not scope.stats then return end
    local typeOrder = {
        { key = 'melee', label = 'Melee' },
        { key = 'spell', label = 'Spell' },
        { key = 'proc',  label = 'Proc'  },
        { key = 'dot',   label = 'DoT'   },
        { key = 'pet',   label = 'Pet'   },
        { key = 'swarm', label = 'Swarm' },
    }
    local rows = {}
    for attacker, st in pairs(scope.stats or {}) do
        local total = st.total or 0
        local dt = st.dmgTypes or {}
        local any = false
        for _, info in ipairs(typeOrder) do
            if dt[info.key] and (dt[info.key].total or 0) > 0 then any = true break end
        end
        if any and total > 0 then
            table.insert(rows, { attacker = attacker, total = total, dt = dt })
        end
    end
    table.sort(rows, function(a, b) return (a.total or 0) > (b.total or 0) end)
    if #rows == 0 then return end

    ImGui.Spacing()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Damage Type Breakdown')
    _G.HT_BeginRoundedBox(idPrefix .. '_dtype_box', _G.HT_RoundedTableHeight(#rows, 8))
    if ImGui.BeginTable(idPrefix .. '_dtype_tbl', 8, _G.HT_RoundedTableFlags()) then
        ImGui.TableSetupColumn('Player')
        ImGui.TableSetupColumn('Melee')
        ImGui.TableSetupColumn('Spell')
        ImGui.TableSetupColumn('Proc')
        ImGui.TableSetupColumn('DoT')
        ImGui.TableSetupColumn('Pet')
        ImGui.TableSetupColumn('Swarm')
        ImGui.TableSetupColumn('Top type')
        _G.HT_TableHeaderRow({'Player','Melee','Spell','Proc','DoT','Pet','Swarm','Top type'})
        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(0, false)
            ImGui.TableNextColumn()
            if ImGui.Button((_G.HT_DpsCompareIsPicked(row.attacker) and 'Compare ON' or 'Compare') .. '##cmp_' .. tostring(idPrefix) .. '_' .. tostring(row.attacker)) then
                _G.HT_DpsCompareToggle(row.attacker)
            end
            ImGui.SameLine()
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0, (_G.HT_FormatNameWithClass and _G.HT_FormatNameWithClass(row.attacker) or row.attacker))
            local bestLabel, bestTotal = '-', 0
            for _, info in ipairs(typeOrder) do
                local val = row.dt[info.key] and (row.dt[info.key].total or 0) or 0
                if val > bestTotal then bestTotal, bestLabel = val, info.label end
                ImGui.TableNextColumn()
                if val > 0 then
                    local pct = val * 100 / math.max(1, row.total or 0)
                    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                        string.format('%s %.0f%%', fmtNum(val), pct))
                else
                    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, '-')
                end
            end
            ImGui.TableNextColumn()
            ImGui.Text(bestLabel)
        end
        ImGui.EndTable()
    end
    _G.HT_EndRoundedBox()
    if _G.HT_DrawDpsTypeCompare then
        _G.HT_DrawDpsTypeCompare(scope, idPrefix, typeOrder, durationSec, spellsScope)
    end
end

local function drawDamageCharTable(scope, idPrefix, durationSec, spellsScope)
    if scope.count == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No damage in this scope.')
        return
    end

    -- Use fight duration to compute per-attacker DPS. A 0-second fight
    -- (instant kill) falls back to 1 to avoid divide-by-zero.
    local dur = math.max(1, durationSec or 1)
    local split = config.splitPetsInDps == true

    local _dpsRows = buildDamageRows(scope)
    local _dpsRowCount = #_dpsRows
    if split then
        for _, _r in ipairs(_dpsRows) do
            if _r.hasPets and _r.pets then
                for _ in pairs(_r.pets) do _dpsRowCount = _dpsRowCount + 1 end
                _dpsRowCount = _dpsRowCount + 1
            end
        end
    end
    _G.HT_BeginRoundedBox(idPrefix .. '_dmg_chars_box', _G.HT_RoundedTableHeight(_dpsRowCount, 10))
    if ImGui.BeginTable(idPrefix .. '_dmg_chars', 6, _G.HT_RoundedTableFlags()) then
        ImGui.TableSetupColumn('Attacker')
        ImGui.TableSetupColumn('Total dmg')
        ImGui.TableSetupColumn('Hits')
        ImGui.TableSetupColumn('DPS')
        ImGui.TableSetupColumn('Max hit')
        ImGui.TableSetupColumn('%')
        _G.HT_TableHeaderRow({'Attacker', 'Total dmg', 'Hits', 'DPS', 'Max hit', '%'})

        for _, r in ipairs(_dpsRows) do
            -- Owner row.
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(0, false)
            ImGui.TableNextColumn()
            local label = r.attacker
            if r.isMe then label = label .. ' (you)' end
            -- Combined view: append "+ pets" suffix if any pet damage
            -- is rolled into this owner's total. Gamparse-style.
            if r.hasPets and not split then
                label = label .. ' + pets'
            end
            -- Names rendered in bright green.
            ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0, (_G.HT_FormatNameWithClass and _G.HT_FormatNameWithClass(label) or label))

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
            ImGui.TableNextColumn()
            local pct = ((scope.total or 0) > 0) and ((r.total or 0) * 100 / (scope.total or 1)) or 0
            ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                              string.format('%.1f%%', pct))

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
                    _G.HT_DrawFloatingRowBg(0, false)
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
                    ImGui.TableNextColumn()
                    local petPct = ((scope.total or 0) > 0) and ((p.total or 0) * 100 / (scope.total or 1)) or 0
                    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                                      string.format('%.1f%%', petPct))
                end
            end
        end
        ImGui.EndTable()
    end
    _G.HT_EndRoundedBox()
    if _G.HT_DrawDamageTypeBreakdown then
        _G.HT_DrawDamageTypeBreakdown(scope, idPrefix, durationSec, spellsScope)
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

    -- LIVE ACTIVE FIGHTS PANEL
    -- Show in-progress damage broken down per mob, with attacker rows.
    -- Critical for boss fights: previously you could ONLY see the boss
    -- in the parse AFTER it died, and during the kill there was no way
    -- to verify damage was being attributed correctly. Now you can
    -- watch the boss accumulate damage in real time.
    if activeCount > 0 then
        ImGui.Spacing()
        ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
            'Active fights (live):')
        -- Sort active mobs by total damage descending so the boss
        -- (highest damage) appears at the top.
        _G.HT_ActiveMobUICache = _G.HT_ActiveMobUICache or { t = 0, rows = {} }
        local activeNow = (mq and mq.gettime and mq.gettime()) or (os.time() * 1000)
        local sortedActive = _G.HT_ActiveMobUICache.rows or {}
        if (activeNow - (_G.HT_ActiveMobUICache.t or 0)) > 120 then
            sortedActive = {}
            for mobName, mobScope in pairs(activeMobs) do
                table.insert(sortedActive, { name = mobName, scope = mobScope })
            end
            table.sort(sortedActive, function(a, b)
                return (a.scope.total or 0) > (b.scope.total or 0)
            end)
            _G.HT_ActiveMobUICache.rows = sortedActive
            _G.HT_ActiveMobUICache.t = activeNow
        end

        -- Compact one-line summary per mob.
        for _, entry in ipairs(sortedActive) do
            local mobName = entry.name
            local mobScope = entry.scope
            local total = mobScope.total or 0
            local started = mobScope.started or os.time()
            local dur = math.max(1, os.time() - started)
            local dps = total / dur
            -- mobLevelColor returns 3 separate values (r, g, b), not a
            -- table. Capture them directly.
            local r, g, b = 1.0, 1.0, 1.0
            if mobLevelColor then
                local ok, cr, cg, cb = pcall(mobLevelColor, mobScope.mobLevel)
                if ok and type(cr) == 'number' then
                    r, g, b = cr, cg, cb
                end
            end
            ImGui.Bullet()
            ImGui.TextColored(r, g, b, 1.0, mobName)
            ImGui.SameLine()
            ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                string.format('  %s total / %s/s / %ds',
                    fmtNum(total), fmtNum(dps), dur))
        end
        ImGui.Spacing()
        ImGui.Separator()
    end

    -- Split pets toggle. Lives at the top so it applies to whichever
    -- view is currently shown (single fight, click-selected, or combined).
    local newSplit, changedSplit = _G.HT_ToggleButton('Split pets', 'dps_splitpets_toggle', config.splitPetsInDps == true)
    if changedSplit then
        config.splitPetsInDps = newSplit
        saveConfig()
    end
    ImGui.SameLine()
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        config.splitPetsInDps and 'ON: pets shown as nested rows' or 'OFF: Owner + pets combined')

    local selDmg = getSelectedDamageIndices()
    local selDmgCount = #selDmg

    ImGui.Spacing()
    -- Search box for filtering by mob name.
    damageSearch = showSearchStatus(damageSearch, 'dps', uniqueMobsFromFights(damageFights, 'label'))

    local dpsVisible = filteredSortedIndices(damageFights, damageSort, 'total', damageSearch, 'label')
    local function handleDpsRangePick(rowNo, idx)
        return _G.HT_HandleDpsRangeClick(idx, dpsVisible)
    end
    local dpsAllChecked = (#dpsVisible > 0)
    for _, vi in ipairs(dpsVisible) do if not damageSelected[vi] then dpsAllChecked = false; break end end
    if btn((dpsAllChecked and 'Deselect all' or 'Select all') .. '##dps_selall_toggle',
           dpsAllChecked and 'active' or 'secondary', _G.HT_ActionButtonW, _G.HT_ActionButtonH) then
        _G.HT_SelectAllToggle(dpsVisible, damageSelected)
    end
    ImGui.SameLine()
    _G.HT_DpsRangeButton()
    ImGui.SameLine()
    if selDmgCount > 0 then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('%d selected', selDmgCount))
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'select fights/range to combine, or click a name to drill in')
    end
    ImGui.SameLine(0, 16)
    if btn('Clear all fights##dps_clear_all_fights', 'danger', 0, 0) then
        -- Do not clear arrays/save files from inside the ImGui draw callback.
        -- Queue it for the main loop so pinned fights cannot crash MQ2Lua.
        _G.HT_PendingClearFights = true
        _G.HT_PendingClearSource = 'dps_ui'
        print('\ay[HealTracker]\ax clear queued; it will run safely on the next tick')
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
        if _G.HT_SectionTitle then _G.HT_SectionTitle('Fight List', 'click a mob to view details') end
        _G.HT_BeginRoundedBox('DpsList_outer', 0)
        if ImGui.BeginTable('DpsList', 5,
                            _G.HT_RoundedTableFlags(bit32.bor(ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit))) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 0)
            ImGui.TableSetupColumn('When', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('Dmg',  ImGuiTableColumnFlags.WidthFixed, 80)
            ImGui.TableSetupColumn('DPS',  ImGuiTableColumnFlags.WidthFixed, 70)

            -- Custom sortable header row. Click a header to cycle sort
            -- (asc -> desc) on that column.
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(-1, false, nil, 24, 16)
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); sortHeader('When', damageSort, 'when')
            ImGui.TableNextColumn(); sortHeader('Mob',  damageSort, 'mob')
            ImGui.TableNextColumn(); sortHeader('Dmg',  damageSort, 'amount')
            ImGui.TableNextColumn(); ImGui.Text('DPS')

            for rowNo, i in ipairs(dpsVisible) do
                local d = damageFights[i]
                local dur = math.max(1, (d.ended or d.started or 0) - (d.started or 0))
                ImGui.TableNextRow()
                _G.HT_DrawFloatingRowBg(rowNo, selectedDamageIdx == i or damageSelected[i])

                ImGui.TableNextColumn()
                local checked = damageSelected[i] or false
                local newC, ch = _G.HT_SelectBox('sel_dmg_' .. i, checked)
                if ch then
                    if not handleDpsRangePick(rowNo, i) then
                        damageSelected[i] = newC or nil
                    end
                end

                -- Make the entire DPS fight row participate in Select Range.
                -- The DPS tab used to only handle range clicks from the tiny select
                -- pill or mob-name cell. In practice, users click the time/damage/DPS
                -- cells too, so those clicks never completed the range on this tab.
                -- Each visible cell now uses the same handler, while preserving the
                -- existing selected-row drill-down behavior when Range mode is off.
                ImGui.TableNextColumn()
                if ImGui.Selectable(os.date('%H:%M:%S', d.ended or d.started or os.time()) .. '##dps_when_' .. i,
                                    selectedDamageIdx == i or damageSelected[i]) then
                    if not handleDpsRangePick(rowNo, i) then
                        selectedDamageIdx = i
                    end
                end

                ImGui.TableNextColumn()
                local pinPrefix = ''
                if _G.HT_FindArchiveKeyForLiveFight then
                    local pinKey = _G.HT_FindArchiveKeyForLiveFight(d, fights[i], spellsFights[i])
                    if pinKey and config.pinnedArchiveFights and config.pinnedArchiveFights[pinKey] == true then
                        pinPrefix = '★ '
                    end
                end
                local mobLabel = pinPrefix .. (d.label or '?') .. '##dmgfight_' .. i
                local mr, mg, mb = mobLevelColor(d.mobLevel)
                ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                if ImGui.Selectable(mobLabel, selectedDamageIdx == i or damageSelected[i],
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    if not handleDpsRangePick(rowNo, i) then
                        selectedDamageIdx = i
                    end
                end
                ImGui.PopStyleColor()

                ImGui.TableNextColumn()
                ImGui.PushStyleColor(ImGuiCol.Text, THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0)
                if ImGui.Selectable(fmtNum(d.total) .. '##dps_total_' .. i,
                                    selectedDamageIdx == i or damageSelected[i]) then
                    if not handleDpsRangePick(rowNo, i) then
                        selectedDamageIdx = i
                    end
                end
                ImGui.PopStyleColor()

                ImGui.TableNextColumn()
                ImGui.PushStyleColor(ImGuiCol.Text, THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0)
                if ImGui.Selectable(fmtNum(d.total / dur) .. '##dps_dps_' .. i,
                                    selectedDamageIdx == i or damageSelected[i]) then
                    if not handleDpsRangePick(rowNo, i) then
                        selectedDamageIdx = i
                    end
                end
                ImGui.PopStyleColor()
            end
            ImGui.EndTable()
        end
        _G.HT_EndRoundedBox()

        -- Right pane: priority order = combined (2+) > checked (1) > clicked
        -- Re-read DPS selection after drawing the left list. Range selection can
        -- change damageSelected while the list is being rendered, and the DPS tab
        -- previously used the stale count captured before the row clicks.
        selDmg = getSelectedDamageIndices()
        selDmgCount = #selDmg
        ImGui.TableNextColumn()
        if _G.HT_SectionTitle then _G.HT_SectionTitle('Breakdown', 'selected fight / combined view') end

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
            local combinedHeals = combineFights(selDmg)
            local combinedSpells = combineSpellsFights(selDmg)
            local liveRecs = {}
            for _, idx in ipairs(selDmg) do
                table.insert(liveRecs, {
                    ts = (damageFights[idx] and damageFights[idx].ended) or os.time(),
                    mob = (damageFights[idx] and damageFights[idx].label) or '?',
                    fight = fights[idx], damage = damageFights[idx], spells = spellsFights[idx],
                })
            end
            if btn('Copy DPS Report##dps_copy_combined_dps', 'amber', 0, 0) then
                copyToClipboard(gamparseReport(combined, string.format('Combined: %d fights', combined.fightCount)))
                print('\ag[HealTracker]\ax DPS report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Heals##dps_copy_combined_heals', 'secondary', 0, 0) then
                copyToClipboard(summaryText(combinedHeals, 'combined'))
                print('\ag[HealTracker]\ax heals report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Burns##dps_copy_combined_burns', 'secondary', 0, 0) then
                copyToClipboard(_G.HT_BurnSummaryTextFromRecords(liveRecs, 'combined'))
                print('\ag[HealTracker]\ax burn report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Full Fight##dps_copy_combined_full', 'amber', 0, 0) then
                copyToClipboard(_G.HT_CombinedArchiveReportText(liveRecs, combinedHeals, combined, combinedSpells))
                print('\ag[HealTracker]\ax full combined report copied to clipboard')
            end
            ImGui.Separator()
            drawDamageCharTable(combined, 'dpscombined', dur, combinedSpells)

        elseif selDmgCount == 1 then
            local d = damageFights[selDmg[1]]
            local dur = math.max(1, (d.ended or d.started or 0) - (d.started or 0))
            ImGui.Text(string.format('Mob       : %s', d.label or '?'))
            ImGui.Text(string.format('Duration  : %ds', dur))
            ImGui.Text(string.format('Total dmg : %s', fmtNum(d.total)))
            ImGui.Text(string.format('Group DPS : %s', fmtNum(d.total / dur)))
            local oneIdx = selDmg[1]
            local oneRec = { ts = d.ended or os.time(), mob = d.label or '?', fight = fights[oneIdx], damage = d, spells = spellsFights[oneIdx] }
            if _G.HT_DrawPinButtonForLiveFight then
                _G.HT_DrawPinButtonForLiveFight('dps_pin_one_' .. tostring(oneIdx), d, fights[oneIdx], spellsFights[oneIdx])
                ImGui.SameLine(0, 8)
            end
            if btn('Copy DPS Report##dps_copy_one_dps', 'amber', 0, 0) then
                copyToClipboard(gamparseReport(d, d.label or 'fight'))
                print('\ag[HealTracker]\ax DPS report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Burns##dps_copy_one_burns', 'secondary', 0, 0) then
                copyToClipboard(_G.HT_BurnSummaryTextFromDamage(d, d.label or 'fight'))
                print('\ag[HealTracker]\ax burn report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Full Fight##dps_copy_one_full', 'amber', 0, 0) then
                copyToClipboard(_G.HT_FullArchiveReportText(oneRec))
                print('\ag[HealTracker]\ax full fight report copied to clipboard')
            end
            ImGui.Separator()
            drawDamageCharTable(d, 'dpsone' .. selDmg[1], dur, spellsFights[selDmg[1]])

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
            local oneRec = { ts = d.ended or os.time(), mob = d.label or '?', fight = fights[selectedDamageIdx], damage = d, spells = spellsFights[selectedDamageIdx] }
            if _G.HT_DrawPinButtonForLiveFight then
                _G.HT_DrawPinButtonForLiveFight('dps_pin_click_' .. tostring(selectedDamageIdx), d, fights[selectedDamageIdx], spellsFights[selectedDamageIdx])
                ImGui.SameLine(0, 8)
            end
            if btn('Copy DPS Report##dps_copy_click_dps', 'amber', 0, 0) then
                copyToClipboard(gamparseReport(d, d.label or 'fight'))
                print('\ag[HealTracker]\ax DPS report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Burns##dps_copy_click_burns', 'secondary', 0, 0) then
                copyToClipboard(_G.HT_BurnSummaryTextFromDamage(d, d.label or 'fight'))
                print('\ag[HealTracker]\ax burn report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Full Fight##dps_copy_click_full', 'amber', 0, 0) then
                copyToClipboard(_G.HT_FullArchiveReportText(oneRec))
                print('\ag[HealTracker]\ax full fight report copied to clipboard')
            end
            ImGui.Separator()
            drawDamageCharTable(d, 'dpsfight' .. selectedDamageIdx, dur, spellsFights[selectedDamageIdx])

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

    -- Action bar: select all toggle, range select, clear all, with selection count.
    local healsVisible = filteredSortedIndices(fights, healsSort, 'total', healsSearch, 'label')
    local healsAllChecked = (#healsVisible > 0)
    for _, vi in ipairs(healsVisible) do if not fightSelected[vi] then healsAllChecked = false; break end end
    if btn((healsAllChecked and 'Deselect all' or 'Select all') .. '##ht_fight_selall_toggle',
           healsAllChecked and 'active' or 'secondary', _G.HT_ActionButtonW, _G.HT_ActionButtonH) then
        _G.HT_SelectAllToggle(healsVisible, fightSelected)
    end
    ImGui.SameLine()
    _G.HT_RangeButton('heals')
    ImGui.SameLine()
    if selCount > 0 then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('%d selected', selCount))
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'select fights/range to combine, or click a name to drill in')
    end
    ImGui.SameLine(0, 16)
    if btn('Clear all fights##ht_fights_clear', 'danger', 0, 0) then
        -- Do not clear arrays/save files from inside the ImGui draw callback.
        -- Queue it for the main loop so pinned fights cannot crash MQ2Lua.
        _G.HT_PendingClearFights = true
        _G.HT_PendingClearSource = 'ui'
        print('\ay[HealTracker]\ax clear queued; it will run safely on the next tick')
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
        _G.HT_BeginRoundedBox('FightsList_outer', 0)
        if ImGui.BeginTable('FightsList', 5,
                            _G.HT_RoundedTableFlags(bit32.bor(ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit))) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 0)
            ImGui.TableSetupColumn('When', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('HP',   ImGuiTableColumnFlags.WidthFixed, 80)
            ImGui.TableSetupColumn('Heals',ImGuiTableColumnFlags.WidthFixed, 50)

            -- Sortable header row.
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(-1, false, nil, 24, 16)
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); sortHeader('When', healsSort, 'when')
            ImGui.TableNextColumn(); sortHeader('Mob',  healsSort, 'mob')
            ImGui.TableNextColumn(); sortHeader('HP',   healsSort, 'amount')
            ImGui.TableNextColumn(); ImGui.Text('Heals')

            for rowNo, i in ipairs(healsVisible) do
                local f = fights[i]
                ImGui.TableNextRow()
                _G.HT_DrawFloatingRowBg(rowNo, selectedFightIdx == i or fightSelected[i])

                ImGui.TableNextColumn()
                local checked = fightSelected[i] or false
                local newChecked, changed = _G.HT_SelectBox('sel_fight_' .. i, checked)
                if changed then
                    if not _G.HT_HandleRangeClick('heals', rowNo, i, healsVisible, fightSelected) then
                        fightSelected[i] = newChecked or nil
                    end
                end

                ImGui.TableNextColumn()
                ImGui.Text(os.date('%H:%M:%S', f.ended or f.started or os.time()))

                ImGui.TableNextColumn()
                local mobLabel = (f.label or '?') .. '##fight_' .. i
                local mr, mg, mb = mobLevelColor(f.mobLevel)
                ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                if ImGui.Selectable(mobLabel, selectedFightIdx == i,
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    if not _G.HT_HandleRangeClick('heals', rowNo, i, healsVisible, fightSelected) then
                        selectedFightIdx = i
                    end
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
        _G.HT_EndRoundedBox()

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
    local _spellTotals = buildSpellTotals(s)
    _G.HT_BeginRoundedBox(idPrefix .. '_flat_box', _G.HT_RoundedTableHeight(#_spellTotals, 10))
    if ImGui.BeginTable(idPrefix .. '_flat', 2, _G.HT_RoundedTableFlags()) then
        ImGui.TableSetupColumn('Spell', ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn('Casts', ImGuiTableColumnFlags.WidthFixed, 60)
        _G.HT_TableHeaderRow({'Spell', 'Casts'})
        for _, r in ipairs(_spellTotals) do
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(0, false)
            ImGui.TableNextColumn(); ImGui.Text(r.spell)
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.count))
        end
        ImGui.EndTable()
    end
    _G.HT_EndRoundedBox()

    ImGui.Separator()

    -- Per-caster breakdown.
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Casts by character')
    local _casterRows = buildCasterRows(s)
    local _casterRowCount = #_casterRows
    for _, _r in ipairs(_casterRows) do
        for _ in pairs(_r.casts or {}) do _casterRowCount = _casterRowCount + 1 end
    end
    _G.HT_BeginRoundedBox(idPrefix .. '_bycaster_box', _G.HT_RoundedTableHeight(_casterRowCount, 10))
    if ImGui.BeginTable(idPrefix .. '_bycaster', 2, _G.HT_RoundedTableFlags()) then
        ImGui.TableSetupColumn('Caster / Spell', ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn('Casts', ImGuiTableColumnFlags.WidthFixed, 60)
        _G.HT_TableHeaderRow({'Caster / Spell', 'Casts'})
        for _, r in ipairs(_casterRows) do
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(0, false)
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
                _G.HT_DrawFloatingRowBg(0, false)
                ImGui.TableNextColumn()
                ImGui.TextColored(0.6, 0.85, 1.0, 1.0, '    ' .. sr.spell)
                ImGui.TableNextColumn(); ImGui.Text(tostring(sr.count))
            end
        end
        ImGui.EndTable()
    end
    _G.HT_EndRoundedBox()
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

    local spellsVisible = filteredSortedIndices(spellsFights, spellsSort, 'total', spellsSearch, 'label')
    local spellsAllChecked = (#spellsVisible > 0)
    for _, vi in ipairs(spellsVisible) do if not spellsSelected[vi] then spellsAllChecked = false; break end end
    if btn((spellsAllChecked and 'Deselect all' or 'Select all') .. '##sp_selall_toggle',
           spellsAllChecked and 'active' or 'secondary', _G.HT_ActionButtonW, _G.HT_ActionButtonH) then
        _G.HT_SelectAllToggle(spellsVisible, spellsSelected)
    end
    ImGui.SameLine()
    _G.HT_RangeButton('spells')
    ImGui.SameLine()
    if selSpCount > 0 then
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('%d selected', selSpCount))
    else
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'select fights/range to combine, or click a name to drill in')
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
        _G.HT_BeginRoundedBox('SpellsList_outer', 0)
        if ImGui.BeginTable('SpellsList', 4,
                            _G.HT_RoundedTableFlags(bit32.bor(ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit))) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 0)
            ImGui.TableSetupColumn('When', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('Casts',ImGuiTableColumnFlags.WidthFixed, 60)

            -- Sortable header row.
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(-1, false, nil, 24, 16)
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); sortHeader('When', spellsSort, 'when')
            ImGui.TableNextColumn(); sortHeader('Mob',  spellsSort, 'mob')
            ImGui.TableNextColumn(); sortHeader('Casts',spellsSort, 'amount')

            for rowNo, i in ipairs(spellsVisible) do
                local s = spellsFights[i]
                ImGui.TableNextRow()
                _G.HT_DrawFloatingRowBg(rowNo, selectedSpellsIdx == i or spellsSelected[i])

                ImGui.TableNextColumn()
                local checked = spellsSelected[i] or false
                local newC, ch = _G.HT_SelectBox('sel_sp_' .. i, checked)
                if ch then
                    if not _G.HT_HandleRangeClick('spells', rowNo, i, spellsVisible, spellsSelected) then
                        spellsSelected[i] = newC or nil
                    end
                end

                ImGui.TableNextColumn()
                ImGui.Text(os.date('%H:%M:%S', s.ended or s.started or os.time()))
                ImGui.TableNextColumn()
                local mobLabel = (s.label or '?') .. '##spellsfight_' .. i
                local mr, mg, mb = mobLevelColor(s.mobLevel)
                ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                if ImGui.Selectable(mobLabel, selectedSpellsIdx == i,
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    if not _G.HT_HandleRangeClick('spells', rowNo, i, spellsVisible, spellsSelected) then
                        selectedSpellsIdx = i
                    end
                end
                ImGui.PopStyleColor()
                ImGui.TableNextColumn()
                ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                                  tostring(s.total))
            end
            ImGui.EndTable()
        end
        _G.HT_EndRoundedBox()

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
        archiveMobListCache = nil
        archiveMobListCacheKey = nil
        archiveNeedsRefresh = false
    end
end

local function getArchiveMobList()
    local key = tostring(archiveCacheRange or '') .. ':' .. tostring((archiveCache and #archiveCache) or 0)
    if archiveMobListCache and archiveMobListCacheKey == key then
        return archiveMobListCache
    end
    archiveMobListCache = uniqueMobsFromFights(archiveCache or {}, 'mob')
    archiveMobListCacheKey = key
    return archiveMobListCache
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
local mobSpellsView = {
    cache = nil, cacheRange = nil,
    rangeMode = 'today',  -- today | 24h | 7d | 30d | all | custom
    customDays = 3,
    search = '',          -- mob name substring filter
    selectedTs = nil,     -- which fight is drilled in
}

-- Refresh the Mob Spells archive cache if the date range changed.
-- Uses the same loadArchive() infrastructure as the History tab,
-- but maintains its own cache so the two tabs operate independently.
local function refreshMobSpellsArchiveIfNeeded()
    local rangeKey = mobSpellsView.rangeMode .. ':' .. tostring(mobSpellsView.customDays)
    if mobSpellsNeedsRefresh or mobSpellsView.cacheRange ~= rangeKey then
        local now = os.time()
        local startTs, endTs = nil, nil
        if mobSpellsView.rangeMode == 'today' then
            -- Midnight today, local time.
            local t = os.date('*t', now)
            t.hour, t.min, t.sec = 0, 0, 0
            startTs = os.time(t)
        elseif mobSpellsView.rangeMode == '24h' then
            startTs = now - 24*3600
        elseif mobSpellsView.rangeMode == '7d' then
            startTs = now - 7*24*3600
        elseif mobSpellsView.rangeMode == '30d' then
            startTs = now - 30*24*3600
        elseif mobSpellsView.rangeMode == 'custom' then
            startTs = now - (mobSpellsView.customDays or 3)*24*3600
        end
        -- 'all' leaves both nil for an unbounded fetch.
        mobSpellsView.cache = loadArchive(startTs, endTs)
        mobSpellsView.cacheRange = rangeKey
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
        local variant = (mobSpellsView.rangeMode == mode) and 'active' or 'secondary'
        if btn(label .. '##mobs_range_' .. mode, variant, 0, 0) then
            mobSpellsView.rangeMode = mode
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
        local variant = (mobSpellsView.rangeMode == 'custom') and 'active' or 'secondary'
        if btn('Custom##mobs_range_custom', variant, 0, 0) then
            mobSpellsView.rangeMode = 'custom'
            mobSpellsNeedsRefresh = true
        end
    end
    if mobSpellsView.rangeMode == 'custom' then
        ImGui.SameLine()
        ImGui.SetNextItemWidth(80)
        local newDays, changed = ImGui.InputInt('days##mobs_days',
            mobSpellsView.customDays or 3, 1, 5)
        if changed then
            mobSpellsView.customDays = math.max(1, math.min(365, newDays))
            mobSpellsNeedsRefresh = true
        end
    end

    -- Mob name search filter via slash command (or by clearing).
    if btn('Refresh##mobs_refresh', 'secondary', 0, 0) then
        mobSpellsNeedsRefresh = true
    end
    ImGui.SameLine()

    local count = (mobSpellsView.cache and #mobSpellsView.cache) or 0

    -- Filter to fights that actually have mob spell data. No point
    -- showing melee-only fights here -- they'd just be empty rows.
    local filtered = {}
    if mobSpellsView.cache then
        for _, rec in ipairs(mobSpellsView.cache) do
            local mobSpells = rec.damage and rec.damage.mobSpells
            if mobSpells and next(mobSpells) ~= nil then
                -- Apply mob name search if any.
                local needle = (mobSpellsView.search ~= '' and mobSpellsView.search:lower()) or nil
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

    if mobSpellsView.search ~= '' then
        ImGui.SameLine(0, 16)
        ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
            string.format('Filter: "%s"', mobSpellsView.search))
        ImGui.SameLine()
        if btn('Clear##mobs_clearfilter', 'danger', 0, 0) then
            mobSpellsView.search = ''
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
            local previewLabel = (mobSpellsView.search ~= '') and mobSpellsView.search
                                  or '(pick a mob...)'
            if ImGui.BeginCombo('##mobspells_pick', previewLabel) then
                for _, m in ipairs(mobList) do
                    local isSelected = (m == mobSpellsView.search)
                    if ImGui.Selectable(m, isSelected) then
                        mobSpellsView.search = m
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
        _G.HT_BeginRoundedBox('MobsFightList_outer', 0)
        if ImGui.BeginTable('MobsFightList', 5,
                            _G.HT_RoundedTableFlags(bit32.bor(ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit))) then
            ImGui.TableSetupColumn('Date',  ImGuiTableColumnFlags.WidthFixed, 88)
            ImGui.TableSetupColumn('Time',  ImGuiTableColumnFlags.WidthFixed, 60)
            ImGui.TableSetupColumn('Mob',   ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('Casts', ImGuiTableColumnFlags.WidthFixed, 50)
            ImGui.TableSetupColumn('Spells',ImGuiTableColumnFlags.WidthFixed, 50)
            _G.HT_TableHeaderRow({'Date', 'Time', 'Mob', 'Casts', 'Spells'})

            -- Newest first.
            table.sort(filtered, function(a, b)
                return (a.ts or 0) > (b.ts or 0)
            end)

            for rowNo, rec in ipairs(filtered) do
                local ts = rec.ts or 0
                local mobSpells = rec.damage and rec.damage.mobSpells or {}

                local totalCasts, uniqueSpells = 0, 0
                for _, sp in pairs(mobSpells) do
                    local n = (type(sp) == 'table') and (sp.count or 0) or sp
                    totalCasts = totalCasts + (n or 0)
                    uniqueSpells = uniqueSpells + 1
                end

                ImGui.TableNextRow()
                _G.HT_DrawFloatingRowBg(rowNo, mobSpellsView.selectedTs == ts)
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
                if ImGui.Selectable(mobLabel, mobSpellsView.selectedTs == ts,
                                    ImGuiSelectableFlags.SpanAllColumns) then
                    mobSpellsView.selectedTs = ts
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
        _G.HT_EndRoundedBox()

        -- Right pane: spell breakdown for selected fight.
        ImGui.TableNextColumn()

        local sel = nil
        if mobSpellsView.selectedTs then
            for _, rec in ipairs(filtered) do
                if rec.ts == mobSpellsView.selectedTs then sel = rec; break end
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


-- Unique key for archive/history rows.
-- Timestamp alone is not unique because multiple snapshots can save in the same second.
-- Stored on _G to avoid adding more top-level locals to this large Lua script.
_G.HT_ArchiveRowKey = function(rec, idx)
    if type(rec) ~= 'table' then return tostring(idx or 0) end
    local dmg = (rec.damage and rec.damage.total) or 0
    local heals = (rec.fight and rec.fight.total) or 0
    local casts = (rec.spells and rec.spells.total) or 0
    -- Stable pin key: do not include the visible row index. History range/search
    -- filters can change indexes, so including idx made favorites disappear or
    -- fail to line up from the DPS tab. This key follows the saved fight itself.
    return tostring(rec.ts or 0) .. ':' ..
           tostring(rec.mob or rec.label or '') .. ':' ..
           tostring(dmg) .. ':' .. tostring(heals) .. ':' .. tostring(casts)
end

_G.HT_FindArchiveKeyForLiveFight = function(dmgFight, healFight, spellsFight)
    if type(dmgFight) ~= 'table' then return nil end

    -- FAST PATH ONLY. The prior fixed-pin build tried to call loadArchive()
    -- from inside the DPS tab every rendered row/frame so it could match the
    -- exact saved history row. That made the DPS tab lag badly on large
    -- history files.
    --
    -- Use the same stable key format directly from the live fight data instead.
    -- This is O(1), does not touch disk/archive while drawing, and still lines
    -- up with history rows because archive records use the same timestamp, mob,
    -- damage total, heal total, and cast total values.
    local ts = dmgFight.ended or dmgFight.started or os.time()
    local mob = dmgFight.label or dmgFight.mob or '?'
    return _G.HT_ArchiveRowKey({
        ts = ts,
        mob = mob,
        fight = healFight,
        damage = dmgFight,
        spells = spellsFight,
    }, 0)
end

_G.HT_DrawPinButtonForLiveFight = function(buttonId, dmgFight, healFight, spellsFight)
    config.pinnedArchiveFights = config.pinnedArchiveFights or {}
    local key = _G.HT_FindArchiveKeyForLiveFight(dmgFight, healFight, spellsFight)
    if not key then return end
    local isPinned = config.pinnedArchiveFights[key] == true
    if btn((isPinned and '★ Unpin Fight' or '★ Pin Fight') .. '##' .. buttonId,
           isPinned and 'amber' or 'secondary', 0, 0) then
        if isPinned then
            config.pinnedArchiveFights[key] = nil
            print('\ay[HealTracker]\ax fight unpinned')
        else
            config.pinnedArchiveFights[key] = true
            print('\ag[HealTracker]\ax fight pinned')
        end
        saveConfig()
    end
end


-- Crash-safe clear for the DPS tab. Do NOT read archive.lua while the Clear
-- button is being handled. The previous build restored pinned fights by loading
-- the full archive during the UI callback, which could hard-crash MQ2Lua.
-- This version only filters the already-loaded current fight arrays and keeps
-- pinned rows in place.
_G.HT_ClearUnpinnedCurrentFights = function()
    config.pinnedArchiveFights = config.pinnedArchiveFights or {}
    clearFightSelection()

    local keptFights, keptDamage, keptSpells = {}, {}, {}
    for i, dmgFight in ipairs(damageFights or {}) do
        local healFight = fights and fights[i] or nil
        local spellFight = spellsFights and spellsFights[i] or nil
        local key = nil
        if _G.HT_FindArchiveKeyForLiveFight then
            key = _G.HT_FindArchiveKeyForLiveFight(dmgFight, healFight, spellFight)
        end
        if key and config.pinnedArchiveFights[key] == true then
            table.insert(keptFights, healFight or emptyScope((dmgFight and dmgFight.label) or nil))
            table.insert(keptDamage, dmgFight)
            table.insert(keptSpells, spellFight or emptySpellsScope((dmgFight and dmgFight.label) or nil))
        end
    end

    fights = keptFights
    damageFights = keptDamage
    spellsFights = keptSpells
    return #keptDamage
end


-- Rebuild the active/current fight lists from pinned archive records only.
-- This is called only when the user clears fights, so it does not run every
-- DPS frame and will not reintroduce the DPS-tab lag from the earlier pin build.
_G.HT_RestorePinnedFightsToCurrentView = function()
    config.pinnedArchiveFights = config.pinnedArchiveFights or {}

    local hasPins = false
    for _, v in pairs(config.pinnedArchiveFights) do
        if v == true then hasPins = true; break end
    end
    if not hasPins then
        return 0
    end

    local pinnedRecords = {}
    local records = loadArchive(nil, nil) or {}
    for idx, rec in ipairs(records) do
        local key = _G.HT_ArchiveRowKey(rec, idx)
        if config.pinnedArchiveFights[key] == true then
            table.insert(pinnedRecords, rec)
        end
    end

    -- Keep the same newest-first feel as the live DPS/History views.
    table.sort(pinnedRecords, function(a, b) return (a.ts or 0) > (b.ts or 0) end)

    fights, damageFights, spellsFights = {}, {}, {}
    for _, rec in ipairs(pinnedRecords) do
        table.insert(fights,       rec.fight  or emptyScope(rec.mob))
        table.insert(damageFights, rec.damage or emptyDamageScope(rec.mob))
        table.insert(spellsFights, rec.spells or emptySpellsScope(rec.mob))
    end

    return #pinnedRecords
end


local function drawHistoryTab()
    if not isDriver() then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'History is only available on driver characters.')
        return
    end

    refreshArchiveIfNeeded()
    config.pinnedArchiveFights = config.pinnedArchiveFights or {}

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
    modeBtn('DPS',        'dps')
    modeBtn('Heals',      'heals')
    modeBtn('Spells',     'spells')
    modeBtn('Mob Spells', 'mobspells')
    modeBtn('All',        'all')
    ImGui.NewLine()

    -- Range picker.
    ImGui.Text('Date range:')
    ImGui.SameLine()
    local function rangeBtn(label, key)
        local variant = (archiveRange == key) and 'active' or 'secondary'
        if btn(label .. '##hist_range_' .. key, variant, 0, 0) then
            archiveRange = key
            archiveNeedsRefresh = true
            historySearch = ''
            archiveSelected = {}
            archiveSelectedTs = nil
            archiveSelectedKey = nil
        end
        ImGui.SameLine()
    end
    rangeBtn('Today',     'today')
    rangeBtn('Last 24h',  '24h')
    rangeBtn('Last 7d',   '7d')
    rangeBtn('Last 30d',  '30d')
    rangeBtn('All',       'all')
    rangeBtn('Pinned',    'pinned')
    rangeBtn('Custom',    'custom')
    ImGui.NewLine()

    if archiveRange == 'custom' then
        ImGui.Text('Last N days:')
        ImGui.SameLine()
        local newDays, ch = ImGui.InputInt('##hist_custom_days', archiveCustomDays, 1, 30)
        if ch then
            archiveCustomDays = math.max(1, newDays)
            archiveNeedsRefresh = true
            historySearch = ''
            archiveSelected = {}
            archiveSelectedTs = nil
            archiveSelectedKey = nil
        end
    end

    if btn('Refresh##hist_refresh', 'secondary', _G.HT_ActionButtonW, _G.HT_ActionButtonH) then
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
        if needle or archiveRange == 'pinned' then for i, rec in ipairs(archiveCache or {}) do
            local mobName = rec.mob or ''
            local rowKey = _G.HT_ArchiveRowKey and _G.HT_ArchiveRowKey(rec, i) or tostring(rec.ts or i or 0)
            local passesPinned = archiveRange ~= 'pinned' or config.pinnedArchiveFights[rowKey] == true
            if passesPinned and (not needle or mobName:lower():find(needle, 1, true)) then
                visibleCount = visibleCount + 1
                if archiveSelected[rowKey] then
                    checkedCount = checkedCount + 1
                end
            end
        end end
    end
    local allChecked  = visibleCount > 0 and checkedCount == visibleCount
    local selAllVariant  = allChecked  and 'active' or 'secondary'

    if btn((allChecked and 'Deselect all' or 'Select all') .. '##hist_selall_toggle',
           selAllVariant, _G.HT_ActionButtonW, _G.HT_ActionButtonH) then
        local visibleKeys = {}
        local needle = (historySearch ~= '' and historySearch:lower()) or nil
        if needle or archiveRange == 'pinned' then for i, rec in ipairs(archiveCache or {}) do
            local mobName = rec.mob or ''
            if rec.ts then
                local rowKey = _G.HT_ArchiveRowKey and _G.HT_ArchiveRowKey(rec, i) or tostring(rec.ts or i or 0)
                local passesPinned = archiveRange ~= 'pinned' or config.pinnedArchiveFights[rowKey] == true
                if passesPinned and (not needle or mobName:lower():find(needle, 1, true)) then
                    table.insert(visibleKeys, rowKey)
                end
            end
        end end
        _G.HT_SelectAllToggle(visibleKeys, archiveSelected)
    end
    ImGui.SameLine()
    _G.HT_RangeButton('history')
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
    local newSplit, splitChanged = _G.HT_ToggleButton('Split pets', 'hist_splitpets_toggle', config.splitPetsInDps == true)
    if splitChanged then
        config.splitPetsInDps = newSplit
        saveConfig()
    end
    ImGui.SameLine()
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        config.splitPetsInDps and 'ON: pets nested' or 'OFF: Owner + pets')

    local count = (archiveCache and #archiveCache) or 0
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        string.format('%d fights in range', count))

    -- Load-into-current-view button. Bulk-loads ALL filtered archive
    -- entries into the in-memory fights/damageFights/spellsFights
    -- arrays. This REPLACES current state.
    ImGui.SameLine(0, 16)
    if btn('Load filtered into current view##hist_load', 'amber', 0, 0) and count > 0 and historySearch ~= '' then
        fights, damageFights, spellsFights = {}, {}, {}
        local needleLoad = historySearch:lower()
        for _, rec in ipairs(archiveCache) do
            local mobName = rec.mob or ''
            if mobName:lower():find(needleLoad, 1, true) then
                table.insert(fights,       rec.fight  or emptyScope(rec.mob))
                table.insert(damageFights, rec.damage or emptyDamageScope(rec.mob))
                table.insert(spellsFights, rec.spells or emptySpellsScope(rec.mob))
            end
        end
        clearFightSelection()
        print(string.format('\ag[HealTracker]\ax loaded %d archived fights into current view',
            #fights))
        print('  the active Heals/DPS/Spells tabs now show the loaded archive')
        print('  use \at/healtracker fights clear\ax to wipe and start fresh')
    end

    -- Mob name search filter. Independent from the date range -- both
    -- act as compound filters on the displayed list.
    historySearch = showSearchStatus(historySearch, 'history', getArchiveMobList())

    ImGui.Separator()

    if count == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No archived fights in this range. The archive grows as fights are completed.')
        return
    end

    if (not historySearch or historySearch == '') and archiveRange ~= 'pinned' then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'Pick a mob from the dropdown to load the history list for this date range.')
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'The full range is hidden on purpose to prevent lag when thousands of fights exist.')
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
    elseif archiveMode == 'mobspells' then
        -- Sum of cast counts across all spells the mob cast.
        amtHeader = 'MobCasts'
        amtFn = function(rec)
            local mobSpells = rec.damage and rec.damage.mobSpells
            if not mobSpells then return 0 end
            local total = 0
            for _, s in pairs(mobSpells) do
                total = total + ((type(s) == 'table' and s.count) or s or 0)
            end
            return total
        end
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
        _G.HT_BeginRoundedBox('HistList_outer', 0)
        if ImGui.BeginTable('HistList', 6,
                            _G.HT_RoundedTableFlags(bit32.bor(ImGuiTableFlags.ScrollY,
                                      ImGuiTableFlags.SizingFixedFit))) then
            ImGui.TableSetupColumn('Sel',  ImGuiTableColumnFlags.WidthFixed, 0)
            ImGui.TableSetupColumn('Pin',  ImGuiTableColumnFlags.WidthFixed, 34)
            ImGui.TableSetupColumn('Date', ImGuiTableColumnFlags.WidthFixed, 90)
            ImGui.TableSetupColumn('Time', ImGuiTableColumnFlags.WidthFixed, 64)
            ImGui.TableSetupColumn('Mob',  ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn(amtHeader, ImGuiTableColumnFlags.WidthFixed, 80)

            -- Sortable header row.
            ImGui.TableNextRow()
            _G.HT_DrawFloatingRowBg(-1, false, nil, 24, 16)
            ImGui.TableNextColumn(); ImGui.Text('Sel')
            ImGui.TableNextColumn(); ImGui.Text('Pin')
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
            local histVisible = {}
            for _, i in ipairs(sortedHist) do
                local rec = archiveCache[i]
                local mobName = rec.mob or ''
                local ts = rec.ts or 0
                local rowKey = _G.HT_ArchiveRowKey and _G.HT_ArchiveRowKey(rec, i) or tostring(ts) .. ':' .. tostring(i)
                local passesPinned = archiveRange ~= 'pinned' or config.pinnedArchiveFights[rowKey] == true
                if passesPinned and (not needle or mobName:lower():find(needle, 1, true)) then
                    table.insert(histVisible, rowKey)
                    local rowNo = #histVisible
                    ImGui.TableNextRow()
                    _G.HT_DrawFloatingRowBg(rowNo, archiveSelectedKey == rowKey or archiveSelected[rowKey])

                    -- Sel checkbox. Keyed by unique archive row key because multiple
                    -- fights can share the exact same timestamp.
                    ImGui.TableNextColumn()
                    local checked = archiveSelected[rowKey] or false
                    local newC, ch = _G.HT_SelectBox('hist_sel_' .. rowKey, checked)
                    if ch then
                        if not _G.HT_HandleRangeClick('history', rowNo, rowKey, histVisible, archiveSelected) then
                            archiveSelected[rowKey] = newC or nil
                        end
                    end

                    ImGui.TableNextColumn()
                    local isPinned = config.pinnedArchiveFights[rowKey] == true
                    if btn((isPinned and '★ Pinned' or '★ Pin') .. '##hist_pin_' .. rowKey,
                           isPinned and 'amber' or 'secondary', 0, 0) then
                        if isPinned then
                            config.pinnedArchiveFights[rowKey] = nil
                            print('\ay[HealTracker]\ax fight unpinned')
                        else
                            config.pinnedArchiveFights[rowKey] = true
                            print('\ag[HealTracker]\ax fight pinned')
                        end
                        saveConfig()
                    end

                    ImGui.TableNextColumn(); ImGui.Text(os.date('%m/%d/%Y', ts))
                    ImGui.TableNextColumn(); ImGui.Text(os.date('%H:%M:%S', ts))
                    ImGui.TableNextColumn()
                    local mobLabel = (rec.mob or '?') .. '##histrow_' .. rowKey
                    local mLvl = (rec.damage and rec.damage.mobLevel)
                                 or (rec.fight and rec.fight.mobLevel)
                                 or (rec.spells and rec.spells.mobLevel)
                    local mr, mg, mb = mobLevelColor(mLvl)
                    ImGui.PushStyleColor(ImGuiCol.Text, mr, mg, mb, 1.0)
                    if ImGui.Selectable(mobLabel, archiveSelectedKey == rowKey,
                                        ImGuiSelectableFlags.SpanAllColumns) then
                        if not _G.HT_HandleRangeClick('history', rowNo, rowKey, histVisible, archiveSelected) then
                            archiveSelectedTs = ts
                            archiveSelectedKey = rowKey
                        end
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
        _G.HT_EndRoundedBox()

        -- Right pane: priority is combined view > drill-down.
        --   - If 2+ fights are checked, show the combined view with a
        --     copy-to-clipboard button.
        --   - Otherwise, show the drill-down for the singly-clicked
        --     fight (archiveSelectedTs).
        ImGui.TableNextColumn()

        -- Build the list of selected archive records.
        local selRecs = {}
        for i, rec in ipairs(archiveCache) do
            local rowKey = _G.HT_ArchiveRowKey and _G.HT_ArchiveRowKey(rec, i) or tostring(rec.ts or i or 0)
            if archiveSelected[rowKey] then
                table.insert(selRecs, rec)
            end
        end
        local selCount = #selRecs

        local showDps       = archiveMode == 'dps'       or archiveMode == 'all'
        local showHeals     = archiveMode == 'heals'     or archiveMode == 'all'
        local showSpells    = archiveMode == 'spells'    or archiveMode == 'all'
        local showMobSpells = archiveMode == 'mobspells' or archiveMode == 'all'

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

            ImGui.SameLine(0, 8)
            if btn('Copy DPS Report##hist_copy_combined_dps', 'amber', 0, 0) then
                copyToClipboard(gamparseReport(cDamage, string.format('Combined: %d fights', selCount)))
                print('\ag[HealTracker]\ax DPS report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Heals##hist_copy_combined_heals', 'secondary', 0, 0) then
                copyToClipboard(summaryText(cHeals, 'combined'))
                print('\ag[HealTracker]\ax heals report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Burns##hist_copy_combined_burns', 'secondary', 0, 0) then
                copyToClipboard(_G.HT_BurnSummaryTextFromRecords(selRecs, 'combined'))
                print('\ag[HealTracker]\ax burn report copied to clipboard')
            end
            ImGui.SameLine(0, 8)
            if btn('Copy Full Fight##hist_copy_combined_full', 'amber', 0, 0) then
                copyToClipboard(_G.HT_CombinedArchiveReportText(selRecs, cHeals, cDamage, cSpells))
                print('\ag[HealTracker]\ax full combined report copied to clipboard')
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
                drawDamageCharTable(cDamage, 'histcombdmg', dur, cSpells)
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
            if archiveSelectedKey then
                for i, r in ipairs(archiveCache) do
                    local rowKey = _G.HT_ArchiveRowKey and _G.HT_ArchiveRowKey(r, i) or tostring(r.ts or i or 0)
                    if rowKey == archiveSelectedKey then selRec = r; break end
                end
            elseif archiveSelectedTs then
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
                    -- Mob spells with per-cast timestamps.
                    if showMobSpells and d and d.mobSpells and next(d.mobSpells) then
                        if #lines > 0 then table.insert(lines, '') end
                        table.insert(lines, 'MOB SPELLS:')
                        local fightStart = d.started or selRec.ts or 0
                        local rows = {}
                        for spell, rec in pairs(d.mobSpells) do
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
                            table.insert(lines, string.format('  %s x %d',
                                r.spell, r.count))
                            for idx, ts in ipairs(r.casts) do
                                table.insert(lines, string.format('    %d. %s (+%ds)',
                                    idx, os.date('%H:%M:%S', ts), ts - fightStart))
                            end
                        end
                    end
                    copyToClipboard(table.concat(lines, '\n'))
                    print('\ag[HealTracker]\ax fight report copied to clipboard')
                end
                ImGui.SameLine(0, 8)
                if btn('Copy DPS Report##hist_copy_single_dps', 'amber', 0, 0) then
                    copyToClipboard(gamparseReport(d, selRec.mob or 'fight'))
                    print('\ag[HealTracker]\ax DPS report copied to clipboard')
                end
                ImGui.SameLine(0, 8)
                if btn('Copy Heals##hist_copy_single_heals', 'secondary', 0, 0) then
                    copyToClipboard(summaryText(h or emptyScope(selRec.mob), selRec.mob or 'fight'))
                    print('\ag[HealTracker]\ax heals report copied to clipboard')
                end
                ImGui.SameLine(0, 8)
                if btn('Copy Burns##hist_copy_single_burns', 'secondary', 0, 0) then
                    copyToClipboard(_G.HT_BurnSummaryTextFromDamage(d, selRec.mob or 'fight'))
                    print('\ag[HealTracker]\ax burn report copied to clipboard')
                end
                ImGui.SameLine(0, 8)
                if btn('Copy Spells##hist_copy_single_spells', 'secondary', 0, 0) then
                    copyToClipboard(_G.HT_SpellSummaryText(s or emptySpellsScope(selRec.mob), selRec.mob or 'fight'))
                    print('\ag[HealTracker]\ax spell report copied to clipboard')
                end
                ImGui.SameLine(0, 8)
                if btn('Copy Full Fight##hist_copy_single_full', 'amber', 0, 0) then
                    copyToClipboard(_G.HT_FullArchiveReportText(selRec))
                    print('\ag[HealTracker]\ax full fight report copied to clipboard')
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
                    drawDamageCharTable(d, 'histdmg' .. selRec.ts, dur, selRec.spells)
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

                -- Mob Spells section -- the mob's own spell rotation
                -- with per-cast timestamps. Each spell renders as an
                -- expandable TreeNode showing every individual cast's
                -- HH:MM:SS plus the +N seconds offset from fight start.
                if showMobSpells then
                    if showDps or showHeals or showSpells then ImGui.Separator() end
                    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
                        'Mob spells cast at us')
                    local mobSpells = d and d.mobSpells or {}
                    if not next(mobSpells) then
                        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
                            '  No spell casts recorded for this mob.')
                    else
                        -- Build sorted list: most-cast first.
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

                        local fightStart = (d and d.started) or selRec.ts or os.time()
                        for _, r in ipairs(rows) do
                            local headerLabel = string.format(
                                '%s  -  %d cast%s##histmobsp_%d_%s',
                                r.spell, r.count,
                                (r.count == 1) and '' or 's',
                                selRec.ts or 0, r.spell)
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
                    end
                end
            end
        end

        ImGui.EndTable()
    end
end

-- =============================================================================
-- Triggers tab
-- =============================================================================
--
-- User-defined raid event triggers. Each trigger watches every chat
-- line for its pattern (substring, case-insensitive) and fires an
-- alert popup + optional /beep when matched. Persists to config.

-- New-trigger form state. Filled in by the user, committed via the
-- "Add trigger" button. Reset to defaults after a successful add.
local _newTrigger = {
    pattern      = '',
    label        = '',
    color        = 'red',
    beep         = true,
    beepCount    = 2,
    dismissAfter = 8,
    mobFilter    = '',
}
local _editTriggerIdx = nil  -- index of trigger being edited (nil = none)

_G.HT_DrawTriggersTab = function()
    ImGui.Text('Raid event triggers')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Watch chat lines for patterns. When matched, show an overlay alert + /beep.')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Substring match, case-insensitive. Example: "begins casting Death Touch"')
    ImGui.Separator()

    -- Existing triggers list.
    local triggers = config.triggers or {}
    config.triggers = triggers

    if #triggers == 0 then
        ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
            'No triggers configured. Add one below.')
    else
        _G.HT_BeginRoundedBox('TriggerList_outer', 0)
        if ImGui.BeginTable('TriggerList', 7,
                            _G.HT_RoundedTableFlags(ImGuiTableFlags.SizingFixedFit)) then
            ImGui.TableSetupColumn('On',      ImGuiTableColumnFlags.WidthFixed, 28)
            ImGui.TableSetupColumn('Pattern', ImGuiTableColumnFlags.WidthStretch, 0.45)
            ImGui.TableSetupColumn('Label',   ImGuiTableColumnFlags.WidthStretch, 0.30)
            ImGui.TableSetupColumn('Color',   ImGuiTableColumnFlags.WidthFixed, 60)
            ImGui.TableSetupColumn('Beep',    ImGuiTableColumnFlags.WidthFixed, 50)
            ImGui.TableSetupColumn('Auto-X',  ImGuiTableColumnFlags.WidthFixed, 50)
            ImGui.TableSetupColumn('',        ImGuiTableColumnFlags.WidthFixed, 60)
            _G.HT_TableHeaderRow({'On', 'Pattern', 'Label', 'Color', 'Beep', 'Auto-X', ''})

            local toRemove = nil
            for i, t in ipairs(triggers) do
                ImGui.TableNextRow()

                -- Enable checkbox.
                ImGui.TableNextColumn()
                local checked = t.enabled ~= false
                local newC, ch = ImGui.Checkbox('##trig_en_' .. i, checked)
                if ch then
                    t.enabled = newC
                    saveConfig()
                end

                -- Pattern (clickable name shows source line of last fire).
                ImGui.TableNextColumn()
                ImGui.Text(t.pattern or '')

                -- Label (the alert text shown in the overlay).
                ImGui.TableNextColumn()
                local rgb = ALERT_COLORS[t.color] or ALERT_COLORS.red
                ImGui.TextColored(rgb[1], rgb[2], rgb[3], 1.0, t.label or '')

                -- Color name.
                ImGui.TableNextColumn()
                ImGui.Text(t.color or 'red')

                -- Beep indicator.
                ImGui.TableNextColumn()
                if t.beep then
                    ImGui.TextColored(THEME.valueDps[1], THEME.valueDps[2], THEME.valueDps[3], 1.0,
                        string.format('x%d', t.beepCount or 1))
                else
                    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0, '-')
                end

                -- Auto-dismiss timeout.
                ImGui.TableNextColumn()
                ImGui.Text(string.format('%ds', t.dismissAfter or 8))

                -- Action buttons.
                ImGui.TableNextColumn()
                if btn('Test##trig_test_' .. i, 'secondary', 0, 0) then
                    fireAlert(t, '(test)')
                end
                ImGui.SameLine(0, 4)
                if btn('X##trig_rm_' .. i, 'danger', 0, 0) then
                    toRemove = i
                end
            end

            if toRemove then
                table.remove(triggers, toRemove)
                saveConfig()
            end

            ImGui.EndTable()
        end
        _G.HT_EndRoundedBox()
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Add a new trigger via slash command:')
    ImGui.Spacing()
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger add <pattern> | <label> [| opts]')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        '    Use " | " (space-pipe-space) to separate pattern from label.')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        '    Use \\n inside the label for multi-line alerts (e.g. PAL - water\\nSK - earth).')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        '    Opts: color=red|orange|yellow|white|blue|green  beep=N (0-5)  dismiss=N (sec, 0=manual)')
    ImGui.Spacing()
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Examples:')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger add begins casting Death Touch | DUCK NOW! | color=red beep=3 dismiss=8')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger add shouts ENRAGE | BOSS ENRAGED | color=orange beep=2')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger add Out of the corner of your eye | Duck Now! | color=red beep=2')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger add elemental rifts open | PAL - water\\nSK - earth\\nWAR - fire | color=yellow beep=3')
    ImGui.Spacing()
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Other commands:')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger list      Show all configured triggers')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger remove N  Remove trigger by number')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger toggle N  Enable/disable trigger N')
    ImGui.TextColored(THEME.you[1], THEME.you[2], THEME.you[3], 1.0,
        '  /healtracker trigger test N    Fire trigger N for testing')
end

_G.HT_DrawSettingsTab = function()
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
        'Live DPS Fast Mode')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Prioritizes live DPS parsing and delays heavier save work during combat.')
    local fastLabel = config.fastDpsMode and 'Fast DPS: ON##settings_fastdps_toggle' or 'Fast DPS: OFF##settings_fastdps_toggle'
    if btn(fastLabel, config.fastDpsMode and 'primary' or 'normal', 170, 0) then
        config.fastDpsMode = not config.fastDpsMode
        saveConfig()
        print(string.format('\ag[HealTracker]\ax Live DPS Fast Mode: %s',
            config.fastDpsMode and '\agON\ax' or '\arOFF\ax'))
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
        config.fightTimeoutSeconds or 5, 1, 5)
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

    ImGui.Separator()
    ImGui.TextColored(THEME.label[1], THEME.label[2], THEME.label[3], 1.0,
        'Alpha / Transparency')
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        'Controls transparency for the full UI, mini tracker, and completed-fight popup.')
    ImGui.Text('Alpha percent (0 = most transparent, 100 = solid):')
    ImGui.SameLine()
    local newAlpha, changedAlpha = ImGui.InputInt('##miniAlpha',
        config.miniAlphaPercent or 100, 5, 10)
    if changedAlpha then
        config.miniAlphaPercent = math.max(0, math.min(100, newAlpha))
        saveConfig()
    end
    ImGui.TextColored(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1.0,
        string.format('Current alpha: %d%%', tonumber(config.miniAlphaPercent) or 100))
    if btn('25%##alpha25', ((tonumber(config.miniAlphaPercent) or 100) == 25) and 'primary' or 'normal', 62, 0) then
        config.miniAlphaPercent = 25
        saveConfig()
    end
    ImGui.SameLine()
    if btn('50%##alpha50', ((tonumber(config.miniAlphaPercent) or 100) == 50) and 'primary' or 'normal', 62, 0) then
        config.miniAlphaPercent = 50
        saveConfig()
    end
    ImGui.SameLine()
    if btn('75%##alpha75', ((tonumber(config.miniAlphaPercent) or 100) == 75) and 'primary' or 'normal', 62, 0) then
        config.miniAlphaPercent = 75
        saveConfig()
    end
    ImGui.SameLine()
    if btn('100%##alpha100', ((tonumber(config.miniAlphaPercent) or 100) == 100) and 'primary' or 'normal', 70, 0) then
        config.miniAlphaPercent = 100
        saveConfig()
    end

    -- Mini view linger: how long the last fight stays visible on the
    -- collapsed bar after the fight ends. Useful for glancing at the
    -- bar right after a kill to see who topped the parse.
    ImGui.Text('Mini view linger (sec after fight ends):')
    ImGui.SameLine()
    local newLinger, changedLinger = ImGui.InputInt('##minilinger',
        config.miniLingerSeconds or 10, 1, 5)
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
        local restoredPins = 0
        if _G.HT_RestorePinnedFightsToCurrentView then
            restoredPins = _G.HT_RestorePinnedFightsToCurrentView() or 0
        end
        saveFights(true)
        saveDamage(true)
        saveSpells(true)
        if restoredPins > 0 then
            print(string.format('\ag[HealTracker]\ax cleared unpinned fights; kept %d pinned fight(s)', restoredPins))
        end
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
        _G.HT_BeginRoundedBox('PetMapTable_outer', 0)
        if ImGui.BeginTable('PetMapTable', 3,
                            _G.HT_RoundedTableFlags(ImGuiTableFlags.SizingFixedFit)) then
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
        _G.HT_EndRoundedBox()
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

    -- Build pet candidate list. Sources:
    --   1. unmappedDamage table -- attackers whose damage was filtered
    --      out as non-PC. (Less useful now that the log parser auto-
    --      promotes everything to knownChars, but still relevant for
    --      pets that came in via the chat-event path.)
    --   2. damageFights -- everyone who's done damage in any fight,
    --      INCLUDING those auto-added to knownChars. The user might
    --      want to map a name like "Pookie" as a pet even though the
    --      log parser thinks it's a PC.
    -- Filtered to exclude:
    --   - The driver themselves (always a real PC)
    --   - Already-mapped pets (no point listing them again)
    --   - Possessive-form names ("X`s pet" -- auto-attributed)
    local petCandidates = {}
    do
        local seen = {}
        local function consider(name)
            if not name or name == '' then return end
            if seen[name] then return end
            if name == MyName then return end
            -- Skip already-mapped pets.
            if (config.petOwners or {})[name] then return end
            -- Skip possessive-form names (auto-attributed).
            if name:match("[`']s%s") then return end
            seen[name] = true
            table.insert(petCandidates, name)
        end
        -- Primary: explicitly-rejected attackers.
        for atk, _ in pairs(unmappedDamage or {}) do
            consider(atk)
        end
        -- Secondary: live damage table -- ALL attackers, since the new
        -- log parser auto-adds everything to knownChars and the user
        -- needs to pick out which ones are actually pets.
        for _, fight in ipairs(damageFights or {}) do
            for atk, _ in pairs(fight.stats or {}) do
                consider(atk)
            end
        end
        -- Tertiary: known characters that aren't the driver. This
        -- catches names auto-added by the log parser even before
        -- they've appeared in a recorded fight.
        for name, _ in pairs(knownChars or {}) do
            consider(name)
        end
        table.sort(petCandidates, function(a, b) return a:lower() < b:lower() end)
    end

    -- Build owner candidate list. Includes all known PCs plus the
    -- driver themselves. Doesn't exclude pet candidates -- the user
    -- might be mapping pet "Hooker" -> owner "Hookerr", and Hookerr
    -- might also be a pet candidate (because everything-that-does-
    -- damage now appears as a candidate). Just let the user pick.
    local ownerCandidates = {}
    do
        local excluded = {}
        for petName, _ in pairs(config.petOwners or {}) do
            -- A mapped pet can't be an owner of another pet.
            excluded[petName] = true
        end
        local seen = {}
        local function consider(name)
            if not name or name == '' then return end
            if seen[name] or excluded[name] then return end
            -- Owners are usually single-word capitalized names. Skip
            -- possessive-form names since those are pets.
            if name:match("[`']s%s") then return end
            seen[name] = true
            table.insert(ownerCandidates, name)
        end
        for name, _ in pairs(knownChars or {}) do consider(name) end
        -- Always include the driver as a possible owner.
        consider(MyName)
        -- Also include every PC who's done damage in any fight.
        for _, fight in ipairs(damageFights or {}) do
            for atk, _ in pairs(fight.stats or {}) do
                consider(atk)
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
        if _petMap.petName and _petMap.petName ~= '' then
            previewLabel = _petMap.petName
        end
        ImGui.Text('Pet:')
        ImGui.SameLine()
        ImGui.SetNextItemWidth(180)
        if ImGui.BeginCombo('##petmap_pet', previewLabel) then
            for _, n in ipairs(petCandidates) do
                local isSelected = (_petMap.petName == n)
                if ImGui.Selectable(n, isSelected) then
                    _petMap.petName = n
                end
                if isSelected then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
        pickedPet = _petMap.petName
    end

    ImGui.SameLine()

    -- Owner picker dropdown.
    local pickedOwner = nil
    do
        local previewLabel = '(pick an owner...)'
        if _petMap.ownerName and _petMap.ownerName ~= '' then
            previewLabel = _petMap.ownerName
        end
        ImGui.Text('Owner:')
        ImGui.SameLine()
        ImGui.SetNextItemWidth(180)
        if ImGui.BeginCombo('##petmap_owner', previewLabel) then
            for _, n in ipairs(ownerCandidates) do
                local isSelected = (_petMap.ownerName == n)
                if ImGui.Selectable(n, isSelected) then
                    _petMap.ownerName = n
                end
                if isSelected then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
        pickedOwner = _petMap.ownerName
    end

    ImGui.SameLine()

    local canAdd = pickedPet ~= nil and pickedPet ~= '' and pickedOwner ~= nil and pickedOwner ~= ''
    if canAdd then
        if btn('Add mapping##petmap_add', 'success', 0, 0) then
            config.petOwners[pickedPet] = pickedOwner
            saveConfig()
            -- Remove the pet from knownChars so future damage events
            -- route through attributeDamage (which now maps pet -> owner)
            -- instead of being recorded as direct damage from the pet.
            knownChars[pickedPet] = nil
            -- Make sure the owner is in knownChars (sanity).
            knownChars[pickedOwner] = true
            -- Remove from unmappedDamage so it stops appearing as a
            -- pending candidate.
            unmappedDamage[pickedPet] = nil
            print(string.format('\ag[HealTracker]\ax mapped pet \at%s\ax -> owner \at%s\ax',
                pickedPet, pickedOwner))
            print('  Note: existing recorded fights still show old attribution.')
            print('  Future damage from \at' .. pickedPet ..
                  '\ax will be credited to \at' .. pickedOwner .. '\ax.')
            _petMap.petIdx = 0
            _petMap.ownerIdx = 0
            _petMap.petName = nil
            _petMap.ownerName = nil
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




_G.HT_drawFull = function()
    ImGui.SetNextWindowSize(1180, 780, ImGuiCond.FirstUseEver)
    local _htGlossyPop = (_G.HT_PushGlossyTheme and _G.HT_PushGlossyTheme()) or 0
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

            -- TurboLoot-style page navigation. The old ImGui tabs were
            -- replaced with rounded toggle buttons so the window looks
            -- cleaner and more consistent with the Turbo UI.
            if config.lastTab == nil or config.lastTab == 'session' then
                config.lastTab = 'heals'
            end

            local page = config.lastTab or 'heals'
            local needsRestore = config._restoreTab
                                 or htLastFightCount ~= #fights
                                 or htLastDmgCount   ~= #damageFights
                                 or htLastSpCount    ~= #spellsFights
            htLastFightCount = #fights
            htLastDmgCount   = #damageFights
            htLastSpCount    = #spellsFights
            config._restoreTab = false

            local availX = ImGui.GetContentRegionAvail()
            if type(availX) == 'table' then availX = availX[1] or 0 end
            availX = tonumber(availX) or 660
            local bw = math.max(96, math.floor((availX - 36) / 6))
            local bh = 44

            local function pageButton(label, key)
                local active = (page == key)
                local shown = active and ('● ' .. label) or ('  ' .. label)
                if btn(shown .. '##page_' .. key, active and 'primary' or 'secondary', bw, bh) then
                    page = key
                    config.lastTab = key
                    saveConfig()
                end
            end

            -- Single-row glossy page buttons like TurboLoot / dashboard mockup.
            pageButton('✚ Heals', 'heals')
            ImGui.SameLine()
            pageButton('⚔ DPS', 'dps')
            ImGui.SameLine()
            pageButton('✦ Spells', 'spells')
            ImGui.SameLine()
            pageButton('▣ History', 'history')
            ImGui.SameLine()
            pageButton('⚠ Triggers', 'triggers')
            ImGui.SameLine()
            pageButton('⚙ Settings', 'settings')

            ImGui.Separator()
            if _G.HT_DrawDashboardStrip then
                _G.HT_DrawDashboardStrip(page, availX)
                ImGui.Separator()
            end

            local pageTitle = ({heals='Heals Dashboard', dps='DPS Dashboard', spells='Spells Dashboard', history='History Dashboard', triggers='Trigger Dashboard', settings='Settings Dashboard'})[page] or 'Dashboard Page'
            if _G.HT_BeginPanel then _G.HT_BeginPanel('##ht_page_panel', pageTitle, 0, 0) end

            local function drawPage(key, drawFn)
                if page ~= key then return end
                local ok, err = pcall(drawFn)
                if not ok then
                    ImGui.TextColored(1.0, 0.4, 0.4, 1.0,
                        'Page render error: ' .. tostring(err))
                end
            end

            -- Preserve the user's selected page while fight counts update.
            -- The Session page was intentionally removed.
            if needsRestore and (page == 'session' or page == nil) then
                page = 'heals'
                config.lastTab = 'heals'
            end

            drawPage('heals',    drawFightsTab)
            drawPage('dps',      drawDpsTab)
            drawPage('spells',   drawSpellsTab)
            drawPage('history',  drawHistoryTab)
            drawPage('triggers', _G.HT_DrawTriggersTab)
            drawPage('settings', _G.HT_DrawSettingsTab)

            if _G.HT_EndPanel then _G.HT_EndPanel() end
        end
    end)  -- close pcall around the body

    ImGui.End()
    if _htGlossyPop and _htGlossyPop > 0 and _G.HT_PopGlossyTheme then _G.HT_PopGlossyTheme(_htGlossyPop) end
end

drawWindow = function()
    if shuttingDown then return end
    if not config.windowOpen then return end
    if not isDriver() then return end
    if config.miniMode then drawMini() else _G.HT_drawFull() end
end


-- =============================================================================
-- v3.15.8 crash-safe UI restoration
-- =============================================================================
-- The experimental full custom DrawList dashboard was removed because it could
-- crash MacroQuest when expanding from the collapsed mini tracker on some builds.
-- This version restores the missing full-window renderer and avoids native custom DrawList calls.

-- =============================================================================
-- Cleanup -- runs when the script exits cleanly. On /lua stop, MQ aborts
-- the mq.delay coroutine and the script terminates immediately --
-- cleanup() may not run at all. So we keep this minimal: just set the
-- shutdown flag so any in-flight callbacks return early. Do NOT do
-- file I/O, do NOT print anything, do NOT call any MQ APIs. Anything
-- that touches MQ during teardown is a vsprintf_s_l crash waiting to
-- happen.
-- =============================================================================

_G.HT_cleanup = function()
    shuttingDown = true
end


-- Process queued fight clears outside ImGui/slash callbacks. This is intentionally
-- global-backed to avoid adding more top-level locals to this very large script.
_G.HT_ProcessPendingClearFights = function()
    if not _G.HT_PendingClearFights then return end
    _G.HT_PendingClearFights = false

    local keptPins = 0
    if _G.HT_ClearUnpinnedCurrentFights then
        keptPins = _G.HT_ClearUnpinnedCurrentFights() or 0
    else
        fights = {}
        damageFights = {}
        spellsFights = {}
        clearFightSelection()
    end

    currentFight = emptyScope(nil)
    activeMobs = {}
    currentSpellsFight = emptySpellsScope(nil)

    saveFights(true)
    saveDamage(true)
    saveSpells(true)

    if keptPins > 0 then
        print(string.format('\ag[HealTracker]\ax cleared unpinned fights; kept %d pinned fight(s)', keptPins))
    else
        print('\ar[HealTracker]\ax fight + damage + spells history cleared')
    end
    print('\ag[HealTracker]\ax (history.log is NOT cleared -- see /healtracker log for path)')
end

-- =============================================================================
-- Boot
-- =============================================================================

_G.HT_boot = function()
    loadConfig()
    if _G.HT_LoadClassMap then pcall(_G.HT_LoadClassMap) end
    if _G.HT_ScanRaidClasses then pcall(_G.HT_ScanRaidClasses, false) end
    -- Refresh config on every login/reload so current saved settings
    -- persist cleanly, including mini linger, pet links, Fast DPS mode,
    -- mini position, alpha, timeout, and user maps.
    saveConfig()
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

_G.HT_boot()

while M.running do
    mq.doevents()
    if _G.HT_ProcessPendingClearFights then
        pcall(_G.HT_ProcessPendingClearFights)
    end

    if htSoftStopped or _G.HT_StopRequested then
        if not htSoftStopClosed then
            htSoftStopClosed = true
            pcall(logTailerClose)
        end
        -- Stay alive but dormant. This avoids the MQ2Lua/ImGui teardown crash
        -- caused by fully unloading the script while callbacks still exist.
        mq.delay(1000)
    else
        logTailerPoll()
        checkFightTimeout()
        -- Group/raid TLO scans are useful but expensive if run every zero-delay tick.
        -- Throttle them so the live damage parser gets CPU first during combat.
        _G.HT_NextKnownRefreshMs = _G.HT_NextKnownRefreshMs or 0
        if nowMs() >= _G.HT_NextKnownRefreshMs then
            _G.HT_NextKnownRefreshMs = nowMs() + ((config.fastDpsMode and fightActive) and 5000 or 1000)
            refreshKnownCharsFromGroup()
            if _G.HT_ClassAutoScanTick then pcall(_G.HT_ClassAutoScanTick) end
        end
        -- Fast DPS mode prioritizes live combat parsing. Disk/history flushes
        -- are delayed while combat is active to reduce stutter and parser lag.
        if not (config.fastDpsMode and fightActive) then
            flushFightsIfDirty()
            flushDamageIfDirty()
            flushSpellsIfDirty()
        end
        -- Faster polling keeps live DPS closer to the EQ log during high-spam fights.
        mq.delay(config.fastDpsMode and 0 or 5)
    end
end

_G.HT_cleanup()
pcall(logTailerClose)
