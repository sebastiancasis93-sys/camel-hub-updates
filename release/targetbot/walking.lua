-- Camel Hub Fast Walk EXP1 - Athalar only
-- Allows OTCv8 walking to queue the next TargetBot step instead of waiting
-- for the previous step to be completely finished first.

local dest
local maxDist
local params

TargetBot.walkTo = function(_dest, _maxDist, _params)
  dest = _dest
  maxDist = _maxDist
  params = _params
end

TargetBot.walk = function()
  if not dest then return end

  -- CaveBot can briefly reserve movement for doors/stairs/floor transitions.
  -- TargetBot still attacks; only its walking is paused.
  if CaveBot then
    if (CaveBot._interactionLockUntil or 0) > now then return end
    if (CaveBot._transitionLockUntil or 0) > now then return end
  end

  local pos = player:getPosition()
  if pos.z ~= dest.z then return end

  local dist = math.max(
    math.abs(pos.x - dest.x),
    math.abs(pos.y - dest.y)
  )

  if params.precision and params.precision >= dist then
    return
  end

  if params.marginMin and params.marginMax then
    if dist >= params.marginMin and dist <= params.marginMax then
      return
    end
  end

  local path = getPath(pos, dest, maxDist, params)
  if not path or not path[1] then
    return
  end

  -- Deliberately do not block just because the current step is still moving.
  -- OTCv8's normal walk() layer handles canWalk/prewalk/nextWalkDir.
  local ok = pcall(function()
    walk(path[1], 0)
  end)

  if not ok then
    pcall(function()
      g_game.walk(path[1], true)
    end)
  end
end
