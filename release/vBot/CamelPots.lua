---@diagnostic disable: undefined-global
-- Camel Hub - quick potion/item actions for Athalar.
-- These are ACTION buttons/icons (one click = one use), not ON/OFF loops.

setDefaultTab("HP")

CamelPots = CamelPots or {}

CamelPots.items = {
  swift = 12066,
  buff = 11768,
  fullHp = 12081
}

local function findItemSafe(itemId)
  if not g_game.isOnline() then return nil end
  return findItem(itemId)
end

-- Swift Pot: use item ON the local player.
function CamelPots.useSwift()
  if not player then return false end
  local item = findItemSafe(CamelPots.items.swift)
  if not item then return false end
  g_game.useWith(item, player)
  return true
end

-- Buff Pot: consume/use the item directly.
function CamelPots.useBuff()
  local item = findItemSafe(CamelPots.items.buff)
  if not item then return false end
  g_game.use(item)
  return true
end

-- Full HP: potion used ON the local player.
function CamelPots.useFullHp()
  if not player then return false end
  local item = findItemSafe(CamelPots.items.fullHp)
  if not item then return false end
  g_game.useWith(item, player)
  return true
end

-- Compact HP row: replaces the space previously occupied by Eat/Conjure Food.
local potUi = setupUI([[
Panel
  height: 21

  Button
    id: swift
    anchors.left: parent.left
    anchors.top: parent.top
    width: 57
    height: 19
    text: Swift Pot
    font: verdana-10px

  Button
    id: buff
    anchors.left: prev.right
    anchors.top: prev.top
    margin-left: 2
    width: 55
    height: 19
    text: Buff Pot
    font: verdana-10px

  Button
    id: fullHp
    anchors.left: prev.right
    anchors.right: parent.right
    anchors.top: prev.top
    margin-left: 2
    height: 19
    text: Full HP
    font: verdana-10px
]])

potUi.swift.onClick = function() CamelPots.useSwift() end
potUi.buff.onClick = function() CamelPots.useBuff() end
potUi.fullHp.onClick = function() CamelPots.useFullHp() end

-- Floating ACTION icons. Existing icon positions are never modified.
local function createActionIcon(id, text, itemId, x, y, callback)
  local icon = addIcon(id, {
    text = text,
    item = itemId,
    switchable = false,
    moveable = true
  }, function()
    callback()
  end)

  if icon then
    if icon.breakAnchors then icon:breakAnchors() end
    if icon.setSize then icon:setSize({height = 42, width = 48}) end
    if icon.text then icon.text:setFont("verdana-11px-rounded") end
    if icon.item then icon.item:setMarginTop(14) end

    if AthalarIconEditor then
      AthalarIconEditor.register(id, text:gsub("\n", " "), icon, x, y)
    elseif icon.move then
      icon:move(x, y)
    end
  end
  return icon
end

CamelPots.swiftIcon = createActionIcon(
  "SwiftPotIcon", "Swift\nPot", CamelPots.items.swift, 205, 365, CamelPots.useSwift
)

CamelPots.buffIcon = createActionIcon(
  "BuffPotIcon", "Buff\nPot", CamelPots.items.buff, 270, 365, CamelPots.useBuff
)

CamelPots.fullHpIcon = createActionIcon(
  "FullHPPotIcon", "Full HP", CamelPots.items.fullHp, 335, 365, CamelPots.useFullHp
)

UI.Separator()
