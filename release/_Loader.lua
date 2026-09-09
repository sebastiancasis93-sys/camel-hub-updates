-- Camel Hub / UI ordered loader
-- Keeps all working modules and only changes their visual load order.

local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

-- Import all vBot OTUI styles first.
local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/vBot", true, false)
for i, file in ipairs(configFiles) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
    g_ui.importStyle(file)
  end
end

local function loadScript(name)
  if name:find("/") then
    return dofile("/" .. name .. ".lua")
  end
  return dofile("/vBot/" .. name .. ".lua")
end

-- Libraries/config first. These do not define the requested Main layout.
local bootstrapFiles = {
  "items",
  "vlib",
  "new_cavebot_lib",
  "configs",
  "AthalarMacroRegistry"
}

for _, file in ipairs(bootstrapFiles) do
  loadScript(file)
end

-- ================================================================
-- MAIN - requested visual order
-- 1. Banner
-- 2. Updater
-- 3. vBot Settings and Scripts
-- 4. Extras PVP
-- 5. Icon Editor
-- 6. Player List
-- 7. Bot Server
-- 8. In-Game Script Editor
-- 9. Macros del jugador (label is placed at the end of this loader)
-- ================================================================

-- 1) Banner
loadScript("main")

-- 2) Updater - still fully isolated so an updater problem cannot stop the bot.
local updaterOk, updaterErr = pcall(function()
  loadScript("CamelHubUpdater")
end)
if not updaterOk then
  warn("[Camel Hub Updater] Disabled safely: " .. tostring(updaterErr))
end

-- 3-8) Main modules
local mainUiFiles = {
  "extras",
  "extrasPvp",
  "IconEditor",
  "playerlist",
  "BotServer",
  "ingame_editor"
}

for _, file in ipairs(mainUiFiles) do
  loadScript(file)
end

-- Remaining modules keep their existing behavior/order as much as possible.
local luaFiles = {
  "FireBomb",

  -- Cave / target settings
  "cave_target_settings",
  "cavebot",

  -- alarms is Tools; kept in the same functional area as before
  "alarms",

  -- HP
  -- Inmortal must appear directly ABOVE Conditions.
  "CamelImmortal",
  "Conditions",
  "Equipper",
  "friend_healer",
  "zFreeScripts/zAutoBuff",
  "HealBot",
  "Buffguild",              -- Guild Buff V23 (Sabuezo) in former Simple Equipper position
  "CamelPots",

  -- Combat / utility
  "pushmax",
  "TimerExecutor",
  "combo",
  "AttackBot",
  "pvp_support",
  "Dropper",
  "Containers",
  "quiver_manager",
  "quiver_label",
  "ZoomMap",
  "zFreeScripts/z_Auto-Party",
  "tools",
  "exeta",
  "spy_level",
  "supplies",
  "depositer_config",
  "npc_talk",
  "xeno_menu",
  "hold_target",
  "cavebot_control_panel",
  "CamelQuickActions",
  "CamelCommonMacros",

  -- Must be last among normal modules: creates icons after controllers exist.
  "AthalarIcons"
}

for _, file in ipairs(luaFiles) do
  loadScript(file)
end

-- 9) This is the visual divider before character/private macros that load
-- after the standard Camel Hub modules.
setDefaultTab("Main")
UI.Separator()
UI.Label("Macros del jugador:")
UI.Separator()

-- Sabuezo Analyzer completo debajo de Macros del jugador.
loadScript("analyzer")
loadScript("CamelAnalyzerLauncher")
