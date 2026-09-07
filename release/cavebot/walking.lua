-- Camel Hub Fast Walk EXP1 - Athalar only
-- Removes avoidable CaveBot waiting while preserving normal pathfinding.

local expectedDirs = {}
local isWalking = false
local walkPath = {}
local walkPathIter = 0

local FAST_POLL = 20
local FAST_START_DELAY = 50

local function playerAutoWalking()
  if not player then return false end

  if player.isAutoWalking then
    local ok, value = pcall(function()
      return player:isAutoWalking()
    end)
    if ok and value then return true end
  end

  if player.isWalking then
    local ok, value = pcall(function()
      return player:isWalking()
    end)
    if ok and value then return true end
  end

  return false
end

CaveBot.resetWalking = function()
  expectedDirs = {}
  walkPath = {}
  walkPathIter = 0
  isWalking = false
end

CaveBot.doWalking = function()
  if CaveBot.Config.get("mapClick") then
    if isWalking and #expectedDirs > 0 then
      if playerAutoWalking() then
        CaveBot.delay(FAST_POLL)
        return true
      end

      -- Autowalk stopped early: let normal goto recalculate immediately.
      expectedDirs = {}
      isWalking = false
    end
    return false
  end

  if #expectedDirs == 0 then
    return false
  end

  if #expectedDirs >= 3 then
    CaveBot.resetWalking()
  end

  local dir = walkPath[walkPathIter]
  if dir then
    g_game.walk(dir, false)
    table.insert(expectedDirs, dir)
    walkPathIter = walkPathIter + 1
    CaveBot.delay(CaveBot.Config.get("walkDelay") + player:getStepDuration(false, dir))
    return true
  end

  return false
end

onPlayerPositionChange(function(newPos, oldPos)
  if not oldPos or not newPos then return end

  local dirs = {
    {NorthWest, North, NorthEast},
    {West, 8, East},
    {SouthWest, South, SouthEast}
  }

  local dir = dirs[newPos.y - oldPos.y + 2]
  if dir then
    dir = dir[newPos.x - oldPos.x + 2]
  end
  if not dir then
    dir = 8
  end

  if not isWalking or not expectedDirs[1] then
    walkPath = {}
    walkPathIter = 0
    CaveBot.delay(CaveBot.Config.get("ping") + player:getStepDuration(false, dir) + 150)
    return
  end

  if expectedDirs[1] ~= dir then
    expectedDirs = {}
    isWalking = false
    CaveBot.delay(FAST_POLL)
    return
  end

  table.remove(expectedDirs, 1)

  if CaveBot.Config.get("mapClick") then
    if #expectedDirs > 0 then
      -- Stock vBot waits another full step here. Poll while autowalk continues.
      CaveBot.delay(FAST_POLL)
    else
      -- Final confirmed step: allow the next waypoint immediately.
      isWalking = false
    end
  end
end)

CaveBot.walkTo = function(dest, maxDist, params)
  local path = getPath(player:getPosition(), dest, maxDist, params)
  if not path or not path[1] then
    return false
  end

  local dir = path[1]

  if CaveBot.Config.get("mapClick") then
    local started = false

    -- Give OTCv8 the current start position so it may prewalk the first step.
    local ok = pcall(function()
      g_game.autoWalk(path, player:getPosition())
    end)

    if ok then
      started = true
    else
      -- Compatibility fallback to stock vBot helper.
      local fallbackOk, fallbackRet = pcall(function()
        return autoWalk(path)
      end)
      started = fallbackOk and fallbackRet ~= false
    end

    if started then
      isWalking = true
      expectedDirs = {}
      for i, v in ipairs(path) do
        expectedDirs[i] = v
      end

      -- Stock vBot used at least 2 x stepDuration here.
      -- We only wait briefly; doWalking blocks while autowalk is truly active.
      CaveBot.delay(math.max(
        FAST_START_DELAY,
        CaveBot.Config.get("mapClickDelay")
      ))
    end

    return started
  end

  -- Non-mapClick behavior kept stock.
  g_game.walk(dir, false)
  isWalking = true
  walkPath = path
  walkPathIter = 2
  expectedDirs = {dir}
  CaveBot.delay(CaveBot.Config.get("walkDelay") + player:getStepDuration(false, dir))
  return true
end
