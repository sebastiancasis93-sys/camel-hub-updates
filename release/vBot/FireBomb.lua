---@diagnostic disable: undefined-global
-- Fire Bomb action icon, estilo Sabuezo.
-- Click en el icono = usa una Fire Bomb Rune exactamente en el SQM del player.

local FIRE_BOMB_RUNE_ID = 3192

FireBomb = FireBomb or {}
FireBomb.runeId = FIRE_BOMB_RUNE_ID

function FireBomb.castUnderPlayer()
  if not g_game.isOnline() or not player then return false end

  local playerPos = player:getPosition()
  if not playerPos then return false end

  local tile = g_map.getTile(playerPos)
  if not tile then return false end

  -- Equivale a usar la runa con click sobre el mismo tile donde estas parado.
  -- En un tile ocupado por el player, getTopUseThing() devuelve el thing
  -- apropiado para enviar el use-with a ese SQM.
  local targetThing = tile:getTopUseThing()
  if not targetThing then
    targetThing = player
  end

  useWith(FireBomb.runeId, targetThing)
  return true
end

-- Icono de ACCION, no switch ON/OFF.
-- switchable=false hace que cada click ejecute la accion inmediatamente.
FireBomb.icon = addIcon("FireBombIcon", {
  text = "Fire\nBomb",
  item = FIRE_BOMB_RUNE_ID,
  switchable = false,
  moveable = true
}, function()
  FireBomb.castUnderPlayer()
end)


-- Registrar el icono en el editor de posiciones de Athalar.
if AthalarIconEditor and FireBomb.icon then
  AthalarIconEditor.register("FireBombIcon", "Fire Bomb", FireBomb.icon, 429, 80)
end
