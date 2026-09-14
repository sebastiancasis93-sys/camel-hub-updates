---@diagnostic disable: undefined-global
-- Camel Hub bomb action icons.
-- Fire Bomb and Energy Bomb use their FIXED functional rune IDs under player.
-- Icon Editor may change only their DISPLAY item image.

local FIRE_BOMB_RUNE_ID = 3192
local ENERGY_BOMB_RUNE_ID = 3149

local function castRuneUnderPlayer(runeId)
  if not g_game.isOnline() or not player then return false end

  local playerPos = player:getPosition()
  if not playerPos then return false end

  local tile = g_map.getTile(playerPos)
  if not tile then return false end

  local targetThing = tile:getTopUseThing()
  if not targetThing then targetThing = player end

  useWith(runeId, targetThing)
  return true
end

FireBomb = FireBomb or {}
FireBomb.runeId = FIRE_BOMB_RUNE_ID
function FireBomb.castUnderPlayer()
  return castRuneUnderPlayer(FireBomb.runeId)
end

EnergyBomb = EnergyBomb or {}
EnergyBomb.runeId = ENERGY_BOMB_RUNE_ID
function EnergyBomb.castUnderPlayer()
  return castRuneUnderPlayer(EnergyBomb.runeId)
end

-- ACTION icons, not ON/OFF switches.
FireBomb.icon = addIcon("FireBombIcon", {
  text = "Fire\nBomb",
  item = FIRE_BOMB_RUNE_ID,
  switchable = false,
  moveable = true
}, function()
  FireBomb.castUnderPlayer()
end)

EnergyBomb.icon = addIcon("EnergyBombIcon", {
  text = "Energy\nBomb",
  item = ENERGY_BOMB_RUNE_ID,
  switchable = false,
  moveable = true
}, function()
  EnergyBomb.castUnderPlayer()
end)

-- Preserve Fire Bomb's existing default location. Energy Bomb gets its own
-- neighboring default location; saved per-profile positions always win.
if AthalarIconEditor then
  if FireBomb.icon then
    AthalarIconEditor.register("FireBombIcon", "Fire Bomb", FireBomb.icon, 429, 80, FIRE_BOMB_RUNE_ID)
  end
  if EnergyBomb.icon then
    AthalarIconEditor.register("EnergyBombIcon", "Energy Bomb", EnergyBomb.icon, 429, 130, ENERGY_BOMB_RUNE_ID)
  end
end
