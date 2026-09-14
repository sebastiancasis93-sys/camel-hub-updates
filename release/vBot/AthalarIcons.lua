---@diagnostic disable: undefined-global
-- Camel Hub universal floating controls.
-- Same catalog for every profile. Vocation-only controls are created only
-- when their real macro/action exists in that profile.

local active = {}
local usedIds = {}
local FALLBACK_ICON_ITEM_ID = 3031

local function setColor(widget, enabled, offColor)
  local color = enabled and "green" or (offColor or "red")
  if widget and widget.text then widget.text:setColor(color) end
end

local function styleIcon(widget)
  if not widget then return end
  if widget.breakAnchors then widget:breakAnchors() end
  if widget.setSize then widget:setSize({height = 42, width = 48}) end
  if widget.text then widget.text:setFont("verdana-11px-rounded") end
  if widget.item then widget.item:setMarginTop(14) end
end

local function controllerState(controller)
  if not controller or not controller.isOn then return false end
  local ok, value = pcall(function() return controller:isOn() end)
  return ok and value == true
end

local function registerEditor(id, label, widget, x, y)
  if AthalarIconEditor and widget then
    AthalarIconEditor.register(id, label, widget, x, y)
  elseif widget and widget.move then
    widget:move(x, y)
  end
end

local function createControllerIcon(label, controller, itemId, options)
  if not controller or not controller.isOn or not controller.setOn or not controller.setOff then return nil end
  options = options or {}
  local id = options.id
  if not id or usedIds[id] then return nil end
  usedIds[id] = true

  local guard = {syncing = false, booting = true}
  local params = {
    text = options.text or label,
    switchable = true,
    moveable = true,
    item = itemId or FALLBACK_ICON_ITEM_ID
  }

  local initial = controllerState(controller)
  local widget = addIcon(id, params, function(icon, on)
    if guard.booting or guard.syncing then return end
    if on then
      pcall(function() controller:setOn() end)
    else
      pcall(function() controller:setOff() end)
    end
    setColor(icon, controllerState(controller), options.offColor)
  end)

  guard.booting = false
  if not widget then return nil end
  styleIcon(widget)
  guard.syncing = true
  if widget.setOn then pcall(function() widget:setOn(initial) end) end
  guard.syncing = false
  setColor(widget, initial, options.offColor)
  registerEditor(id, label, widget, options.x or 0, options.y or 0)

  table.insert(active, {
    widget = widget,
    controller = controller,
    guard = guard,
    offColor = options.offColor
  })
  return widget
end

local function createActionIcon(label, id, itemId, x, y, callback, text)
  if not id or usedIds[id] or type(callback) ~= "function" then return nil end
  usedIds[id] = true

  local widget = addIcon(id, {
    text = text or label,
    item = itemId or FALLBACK_ICON_ITEM_ID,
    switchable = false,
    moveable = true
  }, function()
    pcall(callback)
  end)

  if not widget then return nil end
  styleIcon(widget)
  registerEditor(id, label, widget, x or 0, y or 0)
  return widget
end

local function registryMacro(name)
  if not AthalarMacroRegistry or not AthalarMacroRegistry.byName then return nil end
  local list = AthalarMacroRegistry.byName[name]
  if type(list) ~= "table" or #list == 0 then return nil end
  return list[#list]
end

local function registryMacroAny(names)
  for _, name in ipairs(names or {}) do
    local object = registryMacro(name)
    if object then return object, name end
  end
  return nil, nil
end

local function createMacroIconAny(names, label, id, x, y, itemId, text, silent)
  local object = registryMacroAny(names)
  if not object then
    if not silent then
      warn("[Camel Hub Icons] Macro not found for: " .. tostring(label))
    end
    return nil
  end
  return createControllerIcon(label, object, itemId, {
    id = id, x = x, y = y, text = text or label
  })
end

-- ================================================================
-- COMMON CATALOG
-- ================================================================

if CamelCommon and CamelCommon.CaveTarget then
  local combined = createControllerIcon("Cave + Target", CamelCommon.CaveTarget, 12108, {
    id = "CaveTargetIcon", text = "Cave+\nTarget", x = 270, y = 50
  })

  macro(200, function()
    if not combined or not combined.text or not CaveBot or not TargetBot then return end
    local c, t = CaveBot.isOn(), TargetBot.isOn()
    if c ~= t then combined.text:setColor("orange") end
  end)
end

if CamelCommon and CamelCommon.AntiPush then
  createControllerIcon("Anti Push", CamelCommon.AntiPush, {id=3031,count=100}, {
    id = "AntiPushIcon", text = "Anti\nPush", x = 335, y = 50
  })
end

AthalarModules = AthalarModules or {}
createControllerIcon("PUSHMAX", AthalarModules.PushMax, 3002, {
  id = "PUSHMAXIcon", text = "PUSHMAX", x = 205, y = 100
})
createControllerIcon("ComboBot", AthalarModules.ComboBot, 3155, {
  id = "ComboBotIcon", text = "ComboBot", x = 274, y = 100
})
createControllerIcon("Auto Buff", AutoBuff, 2131, {
  id = "AutoBuffIcon", text = "Auto\nBuff", x = 335, y = 100
})
createControllerIcon("Hold Wall", HoldWall, 3180, {
  id = "HoldWallIcon", text = "Hold\nWall", x = 205, y = 150
})

if CamelCommon and CamelCommon.AntiPK then
  createControllerIcon("Anti PK", CamelCommon.AntiPK, 2393, {
    id = "MacroAFKAntiPKvBotIcon", text = "Anti PK", x = 335, y = 150
  })
end

createMacroIconAny({"Hold Target"}, "Hold Target",
  "MacroHoldTargetIcon", 270, 150, 3077, "Hold\nTarget")

createControllerIcon("Exiva Target", ExivaTarget, 3267, {
  id = "ExivaTargetIcon", text = "Exiva\nTarget", x = 205, y = 225
})
createControllerIcon("Exiva Last", ExivaLast, 11450, {
  id = "ExivaLastIcon", text = "Exiva\nLast", x = 270, y = 225
})
createControllerIcon("Timer Executor", TimerExecutor, 3320, {
  id = "TimerExecutorIcon", text = "Timer\nExec", x = 335, y = 225
})
createControllerIcon("Friend Healer", FriendHealer, 3160, {
  id = "FriendHealerIcon", text = "Friend\nHealer", x = 205, y = 325
})

if CamelQuickActions then
  createActionIcon("Nitro", "NitroIcon", 12123, 270, 325, CamelQuickActions.useNitro, "Nitro")
  createActionIcon("Escape", "EscapeIcon", 11914, 335, 325, CamelQuickActions.useEscape, "Escape")
  createActionIcon("Paralyze", "ParalyzeIcon", 12136, 205, 375, CamelQuickActions.useParalyze, "Paralyze")
  createActionIcon("Stam Pot", "StamPotIcon", 11766, 270, 375, CamelQuickActions.useStamPot, "Stam\nPot")
end

-- Fire Bomb (3192), Energy Bomb (3149), Swift Pot (12066), Buff Pot (11768)
-- and Full HP (12081) create/register their action icons from FireBomb.lua
-- and CamelPots.lua. Their DISPLAY item can still be edited in Icon Editor.

-- ================================================================
-- KNIGHT (optional)
-- ================================================================
createMacroIconAny({"Exeta Res", "Exeta res spam", "Exeta Res Spam"}, "Exeta Res",
  "MacroExetaResIcon", 205, 200, 2932, "Exeta Res", true)

-- ================================================================
-- DRUID / MAGE OPTIONAL CONTROLS
-- ================================================================
createMacroIconAny({"Auto Boost Guild"}, "Boost Guild",
  "DruidBoostGuildIcon", 205, 515, 12014, "Boost\nGuild", true)
createMacroIconAny({"Auto Exevo Mas Vor"}, "Mas Vor",
  "DruidMasVorIcon", 270, 515, 12010, "Mas\nVor", true)
createMacroIconAny({"Auto Haste Guild"}, "Haste Guild",
  "DruidHasteGuildIcon", 335, 515, 12000, "Haste\nGuild", true)
createMacroIconAny({"Mana Training"}, "Mana Train",
  "MageManaTrainIcon", 205, 565, 12174, "Mana\nTrain", true)

if CamelQuickActions and CamelQuickActions.useParalyzeRune then
  createActionIcon("Para Rune", "DruidParaRuneIcon", 3165, 270, 565,
    CamelQuickActions.useParalyzeRune, "Para\nRune")
end

-- Keep switch icons synchronized with their real controller/macro state.
macro(200, function()
  for _, data in ipairs(active) do
    local enabled = controllerState(data.controller)
    if data.widget and data.widget.isOn and data.widget:isOn() ~= enabled then
      data.guard.syncing = true
      pcall(function() data.widget:setOn(enabled) end)
      data.guard.syncing = false
    end
    setColor(data.widget, enabled, data.offColor)
  end
end)
