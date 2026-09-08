---@diagnostic disable: undefined-global
-- Camel Hub Inmortal / Auto Protect
-- UI order module: intentionally loaded before Conditions.

setDefaultTab("HP")

-- ================================================================
-- Camel Hub Inmortal / Auto Protect
-- Recreates Sabuezo's 3-part Setup:
--   1) Magic Shield
--   2) Might / Ring
--   3) Amulet
-- ================================================================

CamelImmortal = CamelImmortal or {}

local immortalKey = "autoProtect_Ultra"
if type(storage[immortalKey]) ~= "table" then
  storage[immortalKey] = {}
end

local immortalCfg = storage[immortalKey]

immortalCfg.enabled = immortalCfg.enabled == true

immortalCfg.ering = immortalCfg.ering or {}
immortalCfg.ering.enabled = immortalCfg.ering.enabled == true
immortalCfg.ering.mode = immortalCfg.ering.mode == "spell" and "spell" or "ring"
immortalCfg.ering.hpAt = tonumber(immortalCfg.ering.hpAt) or 70
immortalCfg.ering.removeAt = tonumber(immortalCfg.ering.removeAt) or 85
immortalCfg.ering.dangerItem = tonumber(immortalCfg.ering.dangerItem) or 3051
immortalCfg.ering.normalItem = tonumber(immortalCfg.ering.normalItem) or 11792
immortalCfg.ering.spellOn = immortalCfg.ering.spellOn or "utamo vita"
immortalCfg.ering.spellOff = immortalCfg.ering.spellOff or "exana vita"
immortalCfg.ering.manaItemId = tonumber(immortalCfg.ering.manaItemId) or 35563
immortalCfg.ering.shieldItemHp = tonumber(immortalCfg.ering.shieldItemHp) or 50
immortalCfg.ering.manaItemMp = tonumber(immortalCfg.ering.manaItemMp) or 50

immortalCfg.ring = immortalCfg.ring or {}
immortalCfg.ring.enabled = immortalCfg.ring.enabled == true
immortalCfg.ring.hpAt = tonumber(immortalCfg.ring.hpAt) or 70
immortalCfg.ring.mpAt = tonumber(immortalCfg.ring.mpAt) or 70
immortalCfg.ring.dangerItem = tonumber(immortalCfg.ring.dangerItem) or 3048
immortalCfg.ring.normalItem = tonumber(immortalCfg.ring.normalItem) or 3004

immortalCfg.amulet = immortalCfg.amulet or {}
immortalCfg.amulet.enabled = immortalCfg.amulet.enabled == true
immortalCfg.amulet.hpAt = tonumber(immortalCfg.amulet.hpAt) or 70
immortalCfg.amulet.mpAt = tonumber(immortalCfg.amulet.mpAt) or 85
immortalCfg.amulet.dangerItem = tonumber(immortalCfg.amulet.dangerItem) or 3081
immortalCfg.amulet.normalItem = tonumber(immortalCfg.amulet.normalItem) or 11791

local immortalUi = setupUI([[
Panel
  height: 19

  BotSwitch
    id: enabled
    anchors.top: parent.top
    anchors.left: parent.left
    width: 130
    height: 17
    text-align: center
    text: Inmortal

  Button
    id: setup
    anchors.top: enabled.top
    anchors.left: enabled.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup
]])

local immortalWindow = nil
local immortalRuntime = {
  magicRingState = nil,
  magicSpellState = nil,
  ringState = nil,
  amuletState = nil,
  lastMove = 0,
  lastRecoveryUse = 0,
  lastSpellTry = 0
}

local SLOT_FINGER_SAFE = SlotFinger or 9
local SLOT_NECK_SAFE = SlotNeck or 2

local function clampPercent(value, fallback)
  value = tonumber(value) or fallback or 1
  if value < 1 then value = 1 end
  if value > 100 then value = 100 end
  return value
end

local function moveDelay()
  local ping = 0
  if g_game and g_game.getPing then
    local ok, value = pcall(function() return g_game.getPing() end)
    if ok then ping = tonumber(value) or 0 end
  end
  return math.max(150, ping * 2)
end

local function canMoveProtection()
  if now - (immortalRuntime.lastMove or 0) < moveDelay() then
    return false
  end
  immortalRuntime.lastMove = now
  return true
end

local function slotItem(slotName)
  if slotName == "finger" then
    return getFinger and getFinger() or nil
  elseif slotName == "neck" then
    return getNeck and getNeck() or nil
  end
  return nil
end

local knownEquippedIds = {
  [3051] = 3088, -- Energy Ring
  [3048] = 3090  -- Might Ring on common Tibia clients
}

local function slotHasConfiguredItem(slotName, itemId)
  local current = slotItem(slotName)
  if not current then return false end

  local currentId = current:getId()
  if currentId == itemId then return true end

  local transformed = knownEquippedIds[itemId]
  return transformed and currentId == transformed or false
end

local function equipConfiguredItem(itemId, slotName)
  itemId = tonumber(itemId)
  if not itemId or itemId <= 100 then return false end
  if slotHasConfiguredItem(slotName, itemId) then return true end
  if not canMoveProtection() then return false end

  if g_game and g_game.getClientVersion and g_game.getClientVersion() >= 910 and g_game.equipItemId then
    local ok = pcall(function()
      g_game.equipItemId(itemId)
    end)
    if ok then return true end
  end

  local item = findItem and findItem(itemId) or nil
  if not item then return false end

  local physicalSlot = slotName == "neck" and SLOT_NECK_SAFE or SLOT_FINGER_SAFE

  if type(moveToSlot) == "function" then
    local ok = pcall(function()
      moveToSlot(item, physicalSlot)
    end)
    if ok then return true end
  end

  if g_game and g_game.move then
    local ok = pcall(function()
      g_game.move(item, {x=65535, y=physicalSlot, z=0}, 1)
    end)
    if ok then return true end
  end

  return false
end

local function applySlotState(runtimeKey, desired, dangerItem, normalItem, slotName)
  if desired ~= immortalRuntime[runtimeKey] then
    immortalRuntime[runtimeKey] = nil
  end

  if immortalRuntime[runtimeKey] == desired then
    local current = slotItem(slotName)
    if current then return true end
  end

  local targetItem = desired == "danger" and dangerItem or normalItem
  if equipConfiguredItem(targetItem, slotName) then
    immortalRuntime[runtimeKey] = desired
    return true
  end

  return false
end

local function useItemOnSelf(itemId)
  itemId = tonumber(itemId)
  if not itemId or itemId <= 100 or not player then return false end

  if g_game and g_game.useInventoryItemWith then
    local ok = pcall(function()
      g_game.useInventoryItemWith(itemId, player, 0)
    end)
    if ok then return true end
  end

  local item = findItem and findItem(itemId) or nil
  if item and g_game and g_game.useWith then
    local ok = pcall(function()
      g_game.useWith(item, player, 0)
    end)
    if ok then return true end
  end

  if item and type(useWith) == "function" then
    local ok = pcall(function()
      useWith(itemId, player, 0)
    end)
    if ok then return true end
  end

  return false
end

local function castProtectSpell(words)
  words = tostring(words or "")
  if words == "" then return false end

  if type(canCast) == "function" then
    local ok, available = pcall(function() return canCast(words) end)
    if ok and available == false then return false end
  end

  if type(cast) == "function" then
    local ok = pcall(function()
      cast(words, 1000)
    end)
    if ok then return true end
  end

  if type(say) == "function" then
    local ok = pcall(function()
      say(words)
    end)
    if ok then return true end
  end

  return false
end

local function applyMagicShield(hp, mp)
  local cfg = immortalCfg.ering
  if not cfg.enabled then
    immortalRuntime.magicRingState = nil
    immortalRuntime.magicSpellState = nil
    return
  end

  local hpOn = clampPercent(cfg.hpAt, 70)
  local hpOff = clampPercent(cfg.removeAt, 85)
  if hpOff <= hpOn then
    hpOff = math.min(100, hpOn + 2)
    cfg.removeAt = hpOff
  end

  if cfg.mode == "spell" then
    local desired = immortalRuntime.magicSpellState

    if hp <= hpOn then
      desired = "danger"
    elseif hp >= hpOff then
      desired = "normal"
    end

    if desired and desired ~= immortalRuntime.magicSpellState and
       now - (immortalRuntime.lastSpellTry or 0) >= 250 then
      immortalRuntime.lastSpellTry = now
      local spell = desired == "danger" and cfg.spellOn or cfg.spellOff

      if castProtectSpell(spell) then
        immortalRuntime.magicSpellState = desired
      end
    end

    -- Sabuezo's setup includes one support item in Magic Shield spell mode.
    -- Use it only while in danger and only at the configured low HP/MP limit.
    if desired == "danger" and now - (immortalRuntime.lastRecoveryUse or 0) >= 1000 then
      local itemHp = clampPercent(cfg.shieldItemHp, 50)
      local itemMp = clampPercent(cfg.manaItemMp, itemHp)

      if hp <= itemHp or mp <= itemMp then
        if useItemOnSelf(cfg.manaItemId) then
          immortalRuntime.lastRecoveryUse = now
        end
      end
    end

    return
  end

  immortalRuntime.magicSpellState = nil

  local desired = immortalRuntime.magicRingState
  if hp <= hpOn then
    desired = "danger"
  elseif hp >= hpOff then
    desired = "normal"
  end

  if desired then
    applySlotState(
      "magicRingState",
      desired,
      cfg.dangerItem,
      cfg.normalItem,
      "finger"
    )
  end
end

local function applyMightRing(hp, mp)
  local cfg = immortalCfg.ring
  if not cfg.enabled then
    immortalRuntime.ringState = nil
    return
  end

  local danger =
    hp <= clampPercent(cfg.hpAt, 70) or
    mp <= clampPercent(cfg.mpAt, 70)

  applySlotState(
    "ringState",
    danger and "danger" or "normal",
    cfg.dangerItem,
    cfg.normalItem,
    "finger"
  )
end

local function applyAmulet(hp, mp)
  local cfg = immortalCfg.amulet
  if not cfg.enabled then
    immortalRuntime.amuletState = nil
    return
  end

  local danger =
    hp <= clampPercent(cfg.hpAt, 70) or
    mp <= clampPercent(cfg.mpAt, 85)

  applySlotState(
    "amuletState",
    danger and "danger" or "normal",
    cfg.dangerItem,
    cfg.normalItem,
    "neck"
  )
end

local function resetImmortalRuntime()
  immortalRuntime.magicRingState = nil
  immortalRuntime.magicSpellState = nil
  immortalRuntime.ringState = nil
  immortalRuntime.amuletState = nil
end

local function setImmortalEnabled(value)
  immortalCfg.enabled = value == true
  immortalUi.enabled:setOn(immortalCfg.enabled)
  resetImmortalRuntime()
end

immortalUi.enabled:setOn(immortalCfg.enabled)
immortalUi.enabled.onClick = function()
  setImmortalEnabled(not immortalCfg.enabled)
end

CamelImmortal.isOn = function()
  return immortalCfg.enabled == true
end

CamelImmortal.setOn = function()
  setImmortalEnabled(true)
end

CamelImmortal.setOff = function()
  setImmortalEnabled(false)
end

CamelImmortal.getConfig = function()
  return immortalCfg
end

local function updateMagicUi()
  if not immortalWindow then return end

  local cfg = immortalCfg.ering
  immortalWindow.ering.label:setText(
    "ON <= " .. cfg.hpAt .. "% | OFF >= " .. cfg.removeAt .. "%"
  )
  immortalWindow.ering.modeBtn:setText(
    cfg.mode == "spell" and "Mode: Spell" or "Mode: Ring"
  )

  immortalWindow.ering.ringMode:setVisible(cfg.mode ~= "spell")
  immortalWindow.ering.spellMode:setVisible(cfg.mode == "spell")
end

local function updateRingUi()
  if not immortalWindow then return end
  local cfg = immortalCfg.ring

  immortalWindow.ring.label:setText(
    "HP <= " .. cfg.hpAt .. "% | MP <= " .. cfg.mpAt .. "%"
  )
end

local function updateAmuletUi()
  if not immortalWindow then return end
  local cfg = immortalCfg.amulet

  immortalWindow.amulet.label:setText(
    "HP <= " .. cfg.hpAt .. "% | MP <= " .. cfg.mpAt .. "%"
  )
end

local rootWidget = g_ui.getRootWidget()
if rootWidget then
  immortalWindow = UI.createWindow("CamelImmortalWindow", rootWidget)
  immortalWindow:hide()

  -- Magic Shield
  immortalWindow.ering.enabled:setOn(immortalCfg.ering.enabled)
  immortalWindow.ering.enabled.onClick = function(widget)
    immortalCfg.ering.enabled = not immortalCfg.ering.enabled
    widget:setOn(immortalCfg.ering.enabled)
    immortalRuntime.magicRingState = nil
    immortalRuntime.magicSpellState = nil
  end

  immortalWindow.ering.modeBtn.onClick = function()
    immortalCfg.ering.mode =
      immortalCfg.ering.mode == "spell" and "ring" or "spell"

    immortalRuntime.magicRingState = nil
    immortalRuntime.magicSpellState = nil
    updateMagicUi()
  end

  immortalWindow.ering.hpThreshold:setValue(immortalCfg.ering.hpAt)
  immortalWindow.ering.hpThreshold.onValueChange = function(_, value)
    immortalCfg.ering.hpAt = value

    if immortalCfg.ering.removeAt <= value then
      immortalCfg.ering.removeAt = math.min(100, value + 2)
      immortalWindow.ering.mpThreshold:setValue(immortalCfg.ering.removeAt)
    end

    updateMagicUi()
  end

  immortalWindow.ering.mpThreshold:setValue(immortalCfg.ering.removeAt)
  immortalWindow.ering.mpThreshold.onValueChange = function(_, value)
    if value <= immortalCfg.ering.hpAt then
      value = math.min(100, immortalCfg.ering.hpAt + 2)
      immortalWindow.ering.mpThreshold:setValue(value)
    end

    immortalCfg.ering.removeAt = value
    updateMagicUi()
  end

  immortalWindow.ering.ringMode.dangerItem:setItemId(immortalCfg.ering.dangerItem)
  immortalWindow.ering.ringMode.dangerItem.onItemChange = function(widget)
    immortalCfg.ering.dangerItem = widget:getItemId()
    immortalRuntime.magicRingState = nil
  end

  immortalWindow.ering.ringMode.normalItem:setItemId(immortalCfg.ering.normalItem)
  immortalWindow.ering.ringMode.normalItem.onItemChange = function(widget)
    immortalCfg.ering.normalItem = widget:getItemId()
    immortalRuntime.magicRingState = nil
  end

  immortalWindow.ering.spellMode.spellOn:setText(immortalCfg.ering.spellOn)
  immortalWindow.ering.spellMode.spellOn.onTextChange = function(_, text)
    immortalCfg.ering.spellOn = text
    immortalRuntime.magicSpellState = nil
  end

  immortalWindow.ering.spellMode.spellOff:setText(immortalCfg.ering.spellOff)
  immortalWindow.ering.spellMode.spellOff.onTextChange = function(_, text)
    immortalCfg.ering.spellOff = text
    immortalRuntime.magicSpellState = nil
  end

  immortalWindow.ering.spellMode.manaItem:setItemId(immortalCfg.ering.manaItemId)
  immortalWindow.ering.spellMode.manaItem.onItemChange = function(widget)
    immortalCfg.ering.manaItemId = widget:getItemId()
  end

  immortalWindow.ering.spellMode.manaItemThreshold:setValue(immortalCfg.ering.shieldItemHp)
  immortalWindow.ering.spellMode.manaItemThreshold.onValueChange = function(_, value)
    immortalCfg.ering.shieldItemHp = value
    immortalCfg.ering.manaItemMp = value
    immortalWindow.ering.spellMode.manaPctLabel:setText(value .. "%")
  end
  immortalWindow.ering.spellMode.manaPctLabel:setText(
    immortalCfg.ering.shieldItemHp .. "%"
  )

  -- Might / Ring
  immortalWindow.ring.enabled:setOn(immortalCfg.ring.enabled)
  immortalWindow.ring.enabled.onClick = function(widget)
    immortalCfg.ring.enabled = not immortalCfg.ring.enabled
    widget:setOn(immortalCfg.ring.enabled)
    immortalRuntime.ringState = nil
  end

  immortalWindow.ring.hpThreshold:setValue(immortalCfg.ring.hpAt)
  immortalWindow.ring.hpThreshold.onValueChange = function(_, value)
    immortalCfg.ring.hpAt = value
    immortalRuntime.ringState = nil
    updateRingUi()
  end

  immortalWindow.ring.mpThreshold:setValue(immortalCfg.ring.mpAt)
  immortalWindow.ring.mpThreshold.onValueChange = function(_, value)
    immortalCfg.ring.mpAt = value
    immortalRuntime.ringState = nil
    updateRingUi()
  end

  immortalWindow.ring.dangerItem:setItemId(immortalCfg.ring.dangerItem)
  immortalWindow.ring.dangerItem.onItemChange = function(widget)
    immortalCfg.ring.dangerItem = widget:getItemId()
    immortalRuntime.ringState = nil
  end

  immortalWindow.ring.normalItem:setItemId(immortalCfg.ring.normalItem)
  immortalWindow.ring.normalItem.onItemChange = function(widget)
    immortalCfg.ring.normalItem = widget:getItemId()
    immortalRuntime.ringState = nil
  end

  -- Amulet
  immortalWindow.amulet.enabled:setOn(immortalCfg.amulet.enabled)
  immortalWindow.amulet.enabled.onClick = function(widget)
    immortalCfg.amulet.enabled = not immortalCfg.amulet.enabled
    widget:setOn(immortalCfg.amulet.enabled)
    immortalRuntime.amuletState = nil
  end

  immortalWindow.amulet.hpThreshold:setValue(immortalCfg.amulet.hpAt)
  immortalWindow.amulet.hpThreshold.onValueChange = function(_, value)
    immortalCfg.amulet.hpAt = value
    immortalRuntime.amuletState = nil
    updateAmuletUi()
  end

  immortalWindow.amulet.mpThreshold:setValue(immortalCfg.amulet.mpAt)
  immortalWindow.amulet.mpThreshold.onValueChange = function(_, value)
    immortalCfg.amulet.mpAt = value
    immortalRuntime.amuletState = nil
    updateAmuletUi()
  end

  immortalWindow.amulet.dangerItem:setItemId(immortalCfg.amulet.dangerItem)
  immortalWindow.amulet.dangerItem.onItemChange = function(widget)
    immortalCfg.amulet.dangerItem = widget:getItemId()
    immortalRuntime.amuletState = nil
  end

  immortalWindow.amulet.normalItem:setItemId(immortalCfg.amulet.normalItem)
  immortalWindow.amulet.normalItem.onItemChange = function(widget)
    immortalCfg.amulet.normalItem = widget:getItemId()
    immortalRuntime.amuletState = nil
  end

  immortalWindow.closeButton.onClick = function()
    immortalWindow:hide()
  end

  updateMagicUi()
  updateRingUi()
  updateAmuletUi()
end

immortalUi.setup.onClick = function()
  if not immortalWindow then return end
  immortalWindow:show()
  immortalWindow:raise()
  immortalWindow:focus()
end

macro(20, function()
  if not immortalCfg.enabled then return end

  local hp = hppercent()
  local mp = manapercent()

  -- Finger priority:
  -- Magic Shield manages Energy Ring/utamo; Might/Ring remains available
  -- as a separate Sabuezo-style protection module.
  applyMagicShield(hp, mp)
  applyMightRing(hp, mp)
  applyAmulet(hp, mp)
end)

UI.Separator()

