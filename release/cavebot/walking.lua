-- Camel Hub Fast Walk EXP3
-- Fast on normal terrain; conservative only around floor transitions.

local expectedDirs = {}
local isWalking = false
local walkPath = {}
local walkPathIter = 0
local transitionWalking = false

local FAST_POLL = 20
local FAST_START_DELAY = 50
local TRANSITION_EXTRA_DELAY = 220

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

local function cleanPathParams(params)
  if not params then return nil end

  local cleaned = nil
  for key, value in pairs(params) do
    if key ~= "_transition" then
      cleaned = cleaned or {}
      cleaned[key] = value
    end
  end
  return cleaned
end

local function lockTransition(ms)
  CaveBot._transitionLockUntil = math.max(
    CaveBot._transitionLockUntil or 0,
    now + (ms or 350)
  )
end

CaveBot.resetWalking = function()
  expectedDirs = {}
  walkPath = {}
  walkPathIter = 0
  isWalking = false
  transitionWalking = false
end

CaveBot.doWalking = function()
  if CaveBot.Config.get("mapClick") then
    if isWalking and #expectedDirs > 0 then
      if playerAutoWalking() then
        CaveBot.delay(transitionWalking and 60 or FAST_POLL)
        return true
      end

      expectedDirs = {}
      isWalking = false
      transitionWalking = false
    end
    return false
  end

  if #expectedDirs == 0 then return false end

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

  -- Floor changes are special movement, not a normal direction.
  if oldPos.z ~= newPos.z then
    expectedDirs = {}
    walkPath = {}
    walkPathIter = 0
    isWalking = false
    transitionWalking = false

    local wait = CaveBot.Config.get("ping") + TRANSITION_EXTRA_DELAY
    lockTransition(wait + 200)
    CaveBot.delay(wait)
    return
  end

  local dirs = {
    {NorthWest, North, NorthEast},
    {West, 8, East},
    {SouthWest, South, SouthEast}
  }

  local dir = dirs[newPos.y - oldPos.y + 2]
  if dir then
    dir = dir[newPos.x - oldPos.x + 2]
  end
  if not dir then dir = 8 end

  if not isWalking or not expectedDirs[1] then
    walkPath = {}
    walkPathIter = 0
    CaveBot.delay(CaveBot.Config.get("ping") + player:getStepDuration(false, dir) + 150)
    return
  end

  if expectedDirs[1] ~= dir then
    expectedDirs = {}
    isWalking = false

    if transitionWalking then
      local wait = CaveBot.Config.get("ping") + player:getStepDuration(false, dir) + 120
      lockTransition(wait + 150)
      transitionWalking = false
      CaveBot.delay(wait)
    else
      transitionWalking = false
      CaveBot.delay(FAST_POLL)
    end
    return
  end

  table.remove(expectedDirs, 1)

  if CaveBot.Config.get("mapClick") then
    if #expectedDirs > 0 then
      CaveBot.delay(transitionWalking and 60 or FAST_POLL)
    else
      isWalking = false
      transitionWalking = false
    end
  end
end)

CaveBot.walkTo = function(dest, maxDist, params)
  local transition = params and params._transition == true
  local path = getPath(player:getPosition(), dest, maxDist, cleanPathParams(params))

  if not path or not path[1] then
    return false
  end

  local dir = path[1]

  if CaveBot.Config.get("mapClick") then
    -- Around stairs/ladders/exact transition points use the stock-style
    -- autowalk timing. Everywhere else retain Fast Walk EXP2 behavior.
    if transition then
      local ret = autoWalk(path)
      if ret then
        isWalking = true
        transitionWalking = true
        expectedDirs = {}

        for i, v in ipairs(path) do
          expectedDirs[i] = v
        end

        local step = player:getStepDuration(false, dir)
        local wait = CaveBot.Config.get("mapClickDelay") + math.max(
          CaveBot.Config.get("ping") + step,
          step * 2
        )

        lockTransition(wait + 150)
        CaveBot.delay(wait)
      end
      return ret
    end

    local started = false

    local ok = pcall(function()
      g_game.autoWalk(path, player:getPosition())
    end)

    if ok then
      started = true
    else
      local fallbackOk, fallbackRet = pcall(function()
        return autoWalk(path)
      end)
      started = fallbackOk and fallbackRet ~= false
    end

    if started then
      isWalking = true
      transitionWalking = false
      expectedDirs = {}

      for i, v in ipairs(path) do
        expectedDirs[i] = v
      end

      CaveBot.delay(math.max(
        FAST_START_DELAY,
        CaveBot.Config.get("mapClickDelay")
      ))
    end

    return started
  end

  g_game.walk(dir, false)
  isWalking = true
  transitionWalking = transition
  walkPath = path
  walkPathIter = 2
  expectedDirs = {dir}

  if transition then
    lockTransition(CaveBot.Config.get("ping") + player:getStepDuration(false, dir) + 200)
  end

  CaveBot.delay(CaveBot.Config.get("walkDelay") + player:getStepDuration(false, dir))
  return true
end
