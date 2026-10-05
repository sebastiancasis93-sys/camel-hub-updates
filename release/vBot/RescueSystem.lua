---@diagnostic disable: undefined-global
-- Camel Hub Rescue System R13 Low-Traffic Sync - Updated Base / 4 Summoners
-- Central configurable rescue system: 6 rescue characters + 4 summoners.
-- Each installation keeps a local cache at /bot/CamelRescueSystem.cfg.
-- Cross-PC/VPS synchronization is distributed through private in-game messages.
-- Athalar is the authoritative Config Master; Summoner 1 remains Leader/Dispatcher.

setDefaultTab("Tools")

CamelRescueSystem = CamelRescueSystem or {}

local CONFIG_PATH = "/bot/CamelRescueSystem.cfg"
local CONFIG_MASTER = "Athalar"
local SYNC_PREFIX = "RS13"
local SYNC_REQUEST_BOOT_DELAY = 5000
local SYNC_BOOT_RETRY_EVERY = 120000
local SYNC_BOOT_MAX_REQUESTS = 1
local SYNC_FRAME_INTERVAL = 12000
local SYNC_RECIPIENT_GAP = 15000
local SYNC_DELTA_INTERVAL = 15000
local SYNC_BUFFER_TIMEOUT = 300000
local EYE_ID = 11954
local SUMMON_COOLDOWN = 8000000 -- preserve existing behavior
local CONFIRM_TIME = 800
local SOS_REPEAT = 20000
local ATTACK_SOS_REPEAT = 20000
local ATTACK_MEMORY = 10000
local SAFE_SWITCH_DELAY = 15000
local PZ_REARM_DELAY = 5000
local PZ_STATE_BOOT_DELAY = 5000
local SUMMON_EYE_DELAY = 2500
local SUMMON_ACCEPT_DELAY = 2000

local DEFAULT_ENEMIES = {
  "Go Sniper", "Techmovil", "Atenea", "Tank Master",
  "Ma Nu", "Inoske", "Anfernee", "Alma Marcela",
  "Soy Rp", "Welt", "Marcela Contrasas",
  "Yacompropc Kuiny", "Star", "Cha Hae-in",
  "Sung Jinwoo", "Rey Demonio Baran", "Gato Madre",
  "Roronoa Zoro", "The Punisher", "Malcom",
  "Francis", "Reese", "Dewey", "Chicles",
  "Mclovin Returns", "Aetherion", "Aries'war",
  "Dark Paladin", "Manny", "Zart Ales", "Npc",
  "Beru", "Antares", "Ver Gansitos", "Pepe Nator",
  "Este Wei", "Chucho Pvp", "Druid Emperatriiz",
  "Brooke", "Trans Zecsual", "Druid Emperatriz",
  "Chucho Pvpp", "Dior", "Surgeon", "Catartasis",
  "Seth", "Pinina", "Reverse Pro", "Avada Kedavra",
  "Crucio", "Imperio"
}

local function trim(value)
  local text = tostring(value or "")
  text = text:gsub("^%s+", "")
  text = text:gsub("%s+$", "")
  return text
end

local function lower(value)
  return trim(value):lower()
end

local function copyConfig(source)
  local out = {
    revision = math.max(1, tonumber(source.revision) or 1),
    enabled = source.enabled == true,
    usePlayerListEnemies = source.usePlayerListEnemies ~= false,
    enemies = {},
    rescue = {},
    summoners = {}
  }
  for _, name in ipairs(source.enemies or {}) do
    local clean = trim(name)
    if clean ~= "" then table.insert(out.enemies, clean) end
  end
  for i = 1, 6 do
    local row = source.rescue and source.rescue[i] or nil
    out.rescue[i] = {
      enabled = row and row.enabled == true or false,
      name = trim(row and row.name or "")
    }
  end
  for i = 1, 4 do
    local row = source.summoners and source.summoners[i] or nil
    out.summoners[i] = {
      enabled = row and row.enabled == true or false,
      name = trim(row and row.name or ""),
      safeProfile = trim(row and row.safeProfile or "")
    }
  end
  return out
end

local function defaultConfig()
  return {
    revision = 1,
    enabled = true,
    usePlayerListEnemies = true,
    enemies = DEFAULT_ENEMIES,
    rescue = {
      {enabled = true,  name = "Athalar"},
      {enabled = true,  name = "Lemac"},
      {enabled = true,  name = "Valyria"},
      {enabled = true,  name = "Tronchito"},
      {enabled = false, name = "Gampi"},
      {enabled = true,  name = "Link"}
    },
    summoners = {
      {enabled = true, name = "Red Clair", safeProfile = "Safe_DP_Mirari"},
      {enabled = true, name = "Jon Snow",  safeProfile = "Safe_DP_Tripoli"},
      {enabled = true, name = "Wisin",     safeProfile = "Safe_DP_Shiva"},
      {enabled = true, name = "Yandel",    safeProfile = "Safe_DP_Viridia"}
    }
  }
end

local function normalizeConfig(source)
  source = type(source) == "table" and source or defaultConfig()
  local base = defaultConfig()
  local out = {
    revision = math.max(1, tonumber(source.revision) or tonumber(base.revision) or 1),
    enabled = source.enabled ~= false,
    usePlayerListEnemies = source.usePlayerListEnemies ~= false,
    enemies = {},
    rescue = {},
    summoners = {}
  }

  local seenEnemies = {}
  local incomingEnemies = source.enemies
  if type(incomingEnemies) ~= "table" then incomingEnemies = base.enemies end
  for _, name in ipairs(incomingEnemies) do
    local clean = trim(name)
    local key = clean:lower()
    if clean ~= "" and not seenEnemies[key] and #out.enemies < 200 then
      seenEnemies[key] = true
      table.insert(out.enemies, clean)
    end
  end

  for i = 1, 6 do
    local src = source.rescue and source.rescue[i] or nil
    local def = base.rescue[i]
    out.rescue[i] = {
      enabled = src and src.enabled == true or (src == nil and def.enabled or false),
      name = trim(src and src.name or def.name)
    }
  end

  for i = 1, 4 do
    local src = source.summoners and source.summoners[i] or nil
    local def = base.summoners[i]
    out.summoners[i] = {
      enabled = src and src.enabled == true or (src == nil and def.enabled or false),
      name = trim(src and src.name or def.name),
      safeProfile = trim(src and src.safeProfile or def.safeProfile)
    }
  end

  return out
end

local function encodeConfig(source)
  local lines = {
    "version=3",
    "revision=" .. tostring(math.max(1, tonumber(source.revision) or 1)),
    "enabled=" .. (source.enabled and "1" or "0"),
    "usePlayerListEnemies=" .. (source.usePlayerListEnemies ~= false and "1" or "0")
  }
  for i = 1, 6 do
    local row = source.rescue[i]
    table.insert(lines, "rescue" .. i .. "=" .. (row.enabled and "1" or "0") .. "|" .. trim(row.name))
  end
  for i = 1, 4 do
    local row = source.summoners[i]
    table.insert(lines, "summoner" .. i .. "=" .. (row.enabled and "1" or "0") .. "|" .. trim(row.name) .. "|" .. trim(row.safeProfile))
  end
  for _, name in ipairs(source.enemies or {}) do
    local clean = trim(name)
    if clean ~= "" then table.insert(lines, "enemy=" .. clean) end
  end
  return table.concat(lines, "\n") .. "\n"
end

local function escapeWire(value)
  value = tostring(value or "")
  value = value:gsub("%%", "%%25")
  value = value:gsub("|", "%%7C")
  value = value:gsub(";", "%%3B")
  value = value:gsub(",", "%%2C")
  return value
end

local function unescapeWire(value)
  value = tostring(value or "")
  value = value:gsub("%%2C", ",")
  value = value:gsub("%%3B", ";")
  value = value:gsub("%%7C", "|")
  value = value:gsub("%%25", "%%")
  return value
end

local function encodeRescueWire(source)
  local rows = {}
  for i = 1, 6 do
    local row = source.rescue[i]
    rows[i] = (row.enabled and "1" or "0") .. "," .. escapeWire(trim(row.name))
  end
  return table.concat(rows, ";")
end

local function encodeSummonerWire(source)
  local rows = {}
  for i = 1, 4 do
    local row = source.summoners[i]
    rows[i] = (row.enabled and "1" or "0") .. "," .. escapeWire(trim(row.name)) .. "," .. escapeWire(trim(row.safeProfile))
  end
  return table.concat(rows, ";")
end

local function encodeEnemyChunks(source, maxLen)
  maxLen = tonumber(maxLen) or 110
  local chunks, current = {}, ""
  for _, name in ipairs(source.enemies or {}) do
    local encoded = escapeWire(trim(name))
    if encoded ~= "" then
      local candidate = current == "" and encoded or (current .. ";" .. encoded)
      if #candidate > maxLen and current ~= "" then
        table.insert(chunks, current)
        current = encoded
      else
        current = candidate
      end
    end
  end
  if current ~= "" or #chunks == 0 then table.insert(chunks, current) end
  return chunks
end

local function decodeEnemyChunk(raw, target)
  for part in tostring(raw or ""):gmatch("[^;]+") do
    local name = trim(unescapeWire(part))
    if name ~= "" then table.insert(target.enemies, name) end
  end
end

local function emptyWireConfig(enabled, usePlayerListEnemies, revision)
  local out = {
    revision = math.max(1, tonumber(revision) or 1),
    enabled = enabled == true,
    usePlayerListEnemies = usePlayerListEnemies ~= false,
    enemies = {},
    rescue = {},
    summoners = {}
  }
  for i = 1, 6 do out.rescue[i] = {enabled = false, name = ""} end
  for i = 1, 4 do out.summoners[i] = {enabled = false, name = "", safeProfile = ""} end
  return out
end

local function decodeRescueWire(raw, target)
  local index = 0
  for part in tostring(raw or ""):gmatch("[^;]+") do
    index = index + 1
    if index > 6 then break end
    local flag, name = part:match("^([01]),(.*)$")
    if flag then target.rescue[index] = {enabled = flag == "1", name = trim(unescapeWire(name))} end
  end
  return index == 6
end

local function decodeSummonerWire(raw, target)
  local index = 0
  for part in tostring(raw or ""):gmatch("[^;]+") do
    index = index + 1
    if index > 4 then break end
    local flag, name, profile = part:match("^([01]),([^,]*),(.*)$")
    if flag then
      target.summoners[index] = {
        enabled = flag == "1",
        name = trim(unescapeWire(name)),
        safeProfile = trim(unescapeWire(profile))
      }
    end
  end
  return index == 4
end

local function decodeConfig(raw)
  if type(raw) ~= "string" or raw:len() < 5 then return nil end
  local out = defaultConfig()
  local sawEnemy = false

  for line in raw:gmatch("[^\r\n]+") do
    local key, value = line:match("^([^=]+)=(.*)$")
    if key == "revision" then
      out.revision = math.max(1, tonumber(value) or 1)
    elseif key == "enabled" then
      out.enabled = value == "1"
    elseif key == "usePlayerListEnemies" then
      out.usePlayerListEnemies = value ~= "0"
    elseif key == "enemy" then
      if not sawEnemy then out.enemies = {}; sawEnemy = true end
      local clean = trim(value)
      if clean ~= "" then table.insert(out.enemies, clean) end
    elseif key then
      local rindex = tonumber(key:match("^rescue(%d+)$"))
      local sindex = tonumber(key:match("^summoner(%d+)$"))
      if rindex and rindex >= 1 and rindex <= 6 then
        local flag, name = value:match("^([01])|(.*)$")
        if flag then
          out.rescue[rindex] = {enabled = flag == "1", name = trim(name)}
        end
      elseif sindex and sindex >= 1 and sindex <= 4 then
        local flag, name, profile = value:match("^([01])|([^|]*)|(.*)$")
        if flag then
          out.summoners[sindex] = {
            enabled = flag == "1",
            name = trim(name),
            safeProfile = trim(profile)
          }
        end
      end
    end
  end

  return normalizeConfig(out)
end

local function readSharedRaw()
  if not g_resources or not g_resources.readFileContents then return nil end
  local ok, raw = pcall(function()
    return g_resources.readFileContents(CONFIG_PATH)
  end)
  if ok and type(raw) == "string" and raw:len() > 0 then return raw end
  return nil
end

local function writeShared(source)
  if not g_resources or not g_resources.writeFileContents then return false end
  local raw = encodeConfig(source)
  local ok = pcall(function()
    g_resources.writeFileContents(CONFIG_PATH, raw)
  end)
  return ok, raw
end

local stored = type(storage.rescueSystem) == "table" and storage.rescueSystem or nil
local firstRaw = readSharedRaw()
local config = decodeConfig(firstRaw) or normalizeConfig(stored or defaultConfig())
storage.rescueSystem = copyConfig(config)
local lastSharedRaw = firstRaw or ""
local sharedEnemySet = {}

local function rebuildSharedEnemySet(source)
  sharedEnemySet = {}
  for _, name in ipairs((source and source.enemies) or {}) do
    local key = lower(name)
    if key ~= "" then sharedEnemySet[key] = true end
  end
end
rebuildSharedEnemySet(config)

-- Runtime state ---------------------------------------------------
local candidate = nil
local candidateSince = 0
local rescueTaken = false
local lastSOS = 0
local switchToSafe = false
local switchTimer = 0
local safeProfile = nil
local safeProfileSender = nil
local attackDanger = false
local lastRealPlayerAttack = 0
local lastAttackSOS = 0

-- Detector diagnostic state. These are runtime-only and never control the system.
local detectorLastEnemy = ""
local detectorLastSource = ""
local detectorLastSeenAt = 0
local detectorLastSOSAt = 0
local detectorError = ""

-- Local rescue lifecycle. A rescued character stays blocked until it physically
-- reaches Protection Zone, then remains SAFE_PZ until it leaves PZ for 5 seconds.
local rescueState = "ARMED" -- ARMED / TRANSIT / SAFE_PZ / EXIT_WAIT
local pzWasIn = nil
local pzExitAt = 0
local pzStateAnnounced = nil

-- Dispatcher-side target lifecycle, learned through SAFE/READY messages.
-- This is independent from Athalar being Config Master. Red Clair owns live rescue state.
local targetState = {}
local workerAssignments = {}

local requests = {}
local leaderBusy = false
local leaderCooldownUntil = 0
local workerFree = {false, false, false, false}
local leaderTarget = nil
local leaderStep = 0
local leaderTimer = 0

local workerBusy = false
local workerCooldownUntil = 0
local workerTarget = nil
local workerStep = 0
local workerTimer = 0
local workerLastFree = 0

local syncBuffers = {}
local syncSequence = 0
local syncSendTailAt = 0
local lastSyncReceived = 0
local lastSyncRequest = 0
local syncRequestCount = 0
local syncAcknowledged = false
local bootAt = now


local function resetRuntime()
  candidate = nil
  candidateSince = 0
  rescueTaken = false
  lastSOS = 0
  switchToSafe = false
  switchTimer = 0
  safeProfile = nil
  safeProfileSender = nil
  attackDanger = false
  lastRealPlayerAttack = 0
  lastAttackSOS = 0
  rescueState = "ARMED"
  pzWasIn = nil
  pzExitAt = 0
  pzStateAnnounced = nil

  requests = {}
  targetState = {}
  workerAssignments = {}
  leaderBusy = false
  leaderTarget = nil
  leaderStep = 0
  leaderTimer = 0
  workerFree = {false, false, false, false}

  workerBusy = false
  workerTarget = nil
  workerStep = 0
  workerTimer = 0
  workerLastFree = 0
end

local function setConfig(newConfig, raw)
  config = normalizeConfig(newConfig)
  storage.rescueSystem = copyConfig(config)
  lastSharedRaw = raw or encodeConfig(config)
  rebuildSharedEnemySet(config)
  resetRuntime()
end

local function localPlayerName()
  local me = g_game.getLocalPlayer()
  return me and me:getName() or ""
end

local function participantInConfig(name, source, includeDisabled)
  local key = lower(name)
  if key == "" then return false end
  source = source or config
  for i = 1, 6 do
    local row = source.rescue[i]
    if row and (includeDisabled or row.enabled) and lower(row.name) == key then return true end
  end
  for i = 1, 4 do
    local row = source.summoners[i]
    if row and (includeDisabled or row.enabled) and lower(row.name) == key then return true end
  end
  return false
end

local function isLocalConfigMaster()
  return lower(localPlayerName()) == lower(CONFIG_MASTER)
end

local function participantNames(source, extraSource)
  local seen, out = {}, {}
  local me = lower(localPlayerName())
  local function addFrom(cfg)
    if not cfg then return end
    for i = 1, 6 do
      local row = cfg.rescue and cfg.rescue[i] or nil
      local name = trim(row and row.name or "")
      local key = lower(name)
      if key ~= "" and key ~= me and not seen[key] then seen[key] = true; table.insert(out, name) end
    end
    for i = 1, 4 do
      local row = cfg.summoners and cfg.summoners[i] or nil
      local name = trim(row and row.name or "")
      local key = lower(name)
      if key ~= "" and key ~= me and not seen[key] then seen[key] = true; table.insert(out, name) end
    end
  end
  addFrom(source)
  addFrom(extraSource)
  return out
end

local function configContentSignature(source)
  local snapshot = copyConfig(source)
  snapshot.revision = 1
  return encodeConfig(snapshot)
end

local function sameEnemyList(a, b)
  return table.concat((a and a.enemies) or {}, "\n") == table.concat((b and b.enemies) or {}, "\n")
end

local function sameExceptEnemies(a, b)
  return a.enabled == b.enabled
    and a.usePlayerListEnemies == b.usePlayerListEnemies
    and encodeRescueWire(a) == encodeRescueWire(b)
    and encodeSummonerWire(a) == encodeSummonerWire(b)
end

local function sameExceptEnabled(a, b)
  return a.usePlayerListEnemies == b.usePlayerListEnemies
    and encodeRescueWire(a) == encodeRescueWire(b)
    and encodeSummonerWire(a) == encodeSummonerWire(b)
    and sameEnemyList(a, b)
end

local function slowQueueReplace(channel, items)
  if CamelSlowPM and CamelSlowPM.replaceChannel then
    CamelSlowPM.replaceChannel(channel, items)
    return true
  end

  -- Conservative fallback for older loaders: still serialize all frames.
  if schedule then
    local cursor = math.max(tonumber(now) or 0, syncSendTailAt or 0)
    for _, item in ipairs(items or {}) do
      local recipientCopy = item.recipient
      local messageCopy = item.message
      local guardCopy = item.guard
      local delay = math.max(0, cursor - (tonumber(now) or 0))
      schedule(delay, function()
        local allowed = true
        if type(guardCopy) == "function" then
          local ok, value = pcall(guardCopy)
          allowed = ok and value ~= false
        end
        if allowed then talkPrivate(recipientCopy, messageCopy) end
      end)
      cursor = cursor + math.max(1000, tonumber(item.gapAfter) or SYNC_DELTA_INTERVAL)
    end
    syncSendTailAt = cursor
    return true
  end

  for _, item in ipairs(items or {}) do
    local allowed = true
    if type(item.guard) == "function" then
      local ok, value = pcall(item.guard)
      allowed = ok and value ~= false
    end
    if allowed then talkPrivate(item.recipient, item.message) end
  end
  return true
end

local function buildWireMessages(prefix, source)
  syncSequence = syncSequence + 1
  local wireRev = tostring(now) .. "-" .. tostring(syncSequence)
  local messages = {
    prefix .. "|B|" .. wireRev .. "|" .. (source.enabled and "1" or "0") .. "," .. (source.usePlayerListEnemies ~= false and "1" or "0") .. "," .. tostring(math.max(1, tonumber(source.revision) or 1)),
    prefix .. "|R|" .. wireRev .. "|" .. encodeRescueWire(source),
    prefix .. "|S|" .. wireRev .. "|" .. encodeSummonerWire(source)
  }
  local enemyChunks = encodeEnemyChunks(source, 105)
  for i, chunk in ipairs(enemyChunks) do
    table.insert(messages, prefix .. "|X|" .. wireRev .. "|" .. tostring(i) .. "," .. tostring(#enemyChunks) .. "|" .. chunk)
  end
  table.insert(messages, prefix .. "|E|" .. wireRev .. "|")
  return messages
end

local function buildWireItems(prefix, recipient, source)
  recipient = trim(recipient)
  if recipient == "" then return {} end
  local sourceRevision = math.max(1, tonumber(source.revision) or 1)
  local messages = buildWireMessages(prefix, source)
  local items = {}
  for i, message in ipairs(messages) do
    table.insert(items, {
      recipient = recipient,
      message = message,
      gapAfter = (i == #messages) and SYNC_RECIPIENT_GAP or SYNC_FRAME_INTERVAL,
      priority = 5,
      guard = function()
        return isLocalConfigMaster() and math.max(1, tonumber(config.revision) or 1) == sourceRevision
      end
    })
  end
  return items
end

local function sendWireConfig(prefix, recipient, source, baseDelay)
  -- baseDelay is retained for API compatibility; the global slow queue owns timing.
  local items = buildWireItems(prefix, recipient, source)
  if #items == 0 then return false end
  slowQueueReplace("rescue-full:" .. lower(recipient), items)
  return true
end

local function broadcastWireConfig(source, extraSource)
  local items = {}
  for _, recipient in ipairs(participantNames(source, extraSource)) do
    for _, item in ipairs(buildWireItems(SYNC_PREFIX, recipient, source)) do
      table.insert(items, item)
    end
  end
  slowQueueReplace("rescue-broadcast", items)
  return #items > 0
end

local function buildEnemyDeltaMessage(previousConfig, nextConfig)
  local previousSet, nextSet = {}, {}
  for _, name in ipairs(previousConfig.enemies or {}) do previousSet[lower(name)] = true end
  for _, name in ipairs(nextConfig.enemies or {}) do nextSet[lower(name)] = true end

  local added, removed = {}, {}
  for _, name in ipairs(nextConfig.enemies or {}) do
    if not previousSet[lower(name)] then table.insert(added, escapeWire(name)) end
  end
  for _, name in ipairs(previousConfig.enemies or {}) do
    if not nextSet[lower(name)] then table.insert(removed, escapeWire(name)) end
  end

  local message = SYNC_PREFIX .. "|Y|" .. tostring(math.max(1, tonumber(nextConfig.revision) or 1)) .. "|" .. table.concat(added, ";") .. "|" .. table.concat(removed, ";")
  if #message > 220 then return nil end
  return message
end

local function broadcastSimple(message, source, extraSource, revision)
  local items = {}
  local expectedRevision = math.max(1, tonumber(revision) or tonumber(source.revision) or 1)
  for _, recipient in ipairs(participantNames(source, extraSource)) do
    table.insert(items, {
      recipient = recipient,
      message = message,
      gapAfter = SYNC_DELTA_INTERVAL,
      priority = 10,
      guard = function()
        return isLocalConfigMaster() and math.max(1, tonumber(config.revision) or 1) == expectedRevision
      end
    })
  end
  slowQueueReplace("rescue-broadcast", items)
  return #items > 0
end

local function broadcastStateDelta(source, extraSource)
  local revision = math.max(1, tonumber(source.revision) or 1)
  local message = SYNC_PREFIX .. "|T|" .. tostring(revision) .. "|" .. (source.enabled and "1" or "0")
  return broadcastSimple(message, source, extraSource, revision)
end

local function broadcastEnemyDelta(previousConfig, nextConfig)
  local message = buildEnemyDeltaMessage(previousConfig, nextConfig)
  if not message then return false end
  return broadcastSimple(message, nextConfig, previousConfig, nextConfig.revision)
end

local function requestMasterSync()
  if isLocalConfigMaster() or syncAcknowledged then return false end
  if syncRequestCount >= SYNC_BOOT_MAX_REQUESTS then return false end
  local revision = math.max(1, tonumber(config.revision) or 1)
  talkPrivate(CONFIG_MASTER, SYNC_PREFIX .. "|Q|" .. tostring(revision))
  lastSyncRequest = now
  syncRequestCount = syncRequestCount + 1
  return true
end

local function rescueSlotByName(name)
  local key = lower(name)
  if key == "" then return nil end
  for i = 1, 6 do
    local row = config.rescue[i]
    if row.enabled and lower(row.name) == key then return i, row end
  end
  return nil
end

local function summonerSlotByName(name)
  local key = lower(name)
  if key == "" then return nil end
  for i = 1, 4 do
    local row = config.summoners[i]
    if row.enabled and lower(row.name) == key then return i, row end
  end
  return nil
end

local function leaderRow()
  local row = config.summoners[1]
  if row and row.enabled and trim(row.name) ~= "" then return row end
  return nil
end

local function selfRescueRow()
  local _, row = rescueSlotByName(localPlayerName())
  return row
end

local function selfSummonerSlot()
  local index = summonerSlotByName(localPlayerName())
  return index
end

local function canonicalRescueName(name)
  local _, row = rescueSlotByName(name)
  return row and row.name or nil
end

local function safeProfileForSummoner(name)
  local _, row = summonerSlotByName(name)
  return row and row.safeProfile or nil
end

-- Safe DP is fully dynamic per configured summoner slot.  The rescued client
-- validates the profile locally because each PC/VPS may have its own /bot tree.
local function caveProfileExists(profileName)
  profileName = trim(profileName)
  if profileName == "" then return false end
  if not g_resources or not g_resources.fileExists then return nil end
  if not modules or not modules.game_bot or not modules.game_bot.contentsPanel then return nil end
  local configWidget = modules.game_bot.contentsPanel.config
  if not configWidget or not configWidget.getCurrentOption then return nil end
  local option = configWidget:getCurrentOption()
  local configName = option and option.text or nil
  if not configName or configName == "" then return nil end
  return g_resources.fileExists("/bot/" .. configName .. "/cavebot_configs/" .. profileName .. ".cfg")
end

local function activeSystem()
  return config.enabled == true
end

local function localInPz()
  if type(isInPz) ~= "function" then return false end
  local ok, value = pcall(function() return isInPz() end)
  return ok and value == true
end

local function announceLocalRescueState(state)
  local row = selfRescueRow()
  local leader = leaderRow()
  if not row or not leader or trim(leader.name) == "" then return false end
  if pzStateAnnounced == state then return false end
  if state == "SAFE_PZ" then
    talkPrivate(leader.name, "SAFE:" .. row.name)
  elseif state == "ARMED" then
    talkPrivate(leader.name, "READY:" .. row.name)
  else
    return false
  end
  pzStateAnnounced = state
  return true
end

local function localRescueAllowed()
  return rescueState == "ARMED" and not localInPz() and not rescueTaken
end

local function playerListEntryName(value)
  if type(value) == "string" then return trim(value) end
  if type(value) == "table" then
    return trim(value.name or value.playerName or value.text or "")
  end
  return ""
end

local function isLocalPlayerListEnemy(name)
  if config.usePlayerListEnemies == false then return false end
  local list = storage and storage.playerList and storage.playerList.enemyList or nil
  if type(list) ~= "table" then return false end
  local key = lower(name)
  -- pairs() is intentional: it also supports non-sequential tables.
  for _, entry in pairs(list) do
    if lower(playerListEntryName(entry)) == key then return true end
  end
  return false
end

local function configuredEnemySource(name, creature)
  local key = lower(name)
  if key == "" then return nil end
  if sharedEnemySet[key] then return "Shared" end
  if isLocalPlayerListEnemy(name) then return "Player List" end

  -- Compatibility fallback: use vBot's own enemy resolver when Player List is enabled.
  -- This keeps Rescue aligned with the Player List module even on profiles where its
  -- internal representation differs from a plain array of strings.
  if config.usePlayerListEnemies ~= false and type(isEnemy) == "function" then
    local ok, result = pcall(function() return isEnemy(creature or name) end)
    if ok and result == true then return "Player List" end
  end
  return nil
end

local function inspectEnemyCreature(spec)
  if not spec then return nil end
  local okPlayer, isPlayerValue = pcall(function() return spec:isPlayer() end)
  if not okPlayer or not isPlayerValue then return nil end
  local okLocal, isLocalValue = pcall(function() return spec:isLocalPlayer() end)
  if okLocal and isLocalValue then return nil end
  local okName, name = pcall(function() return spec:getName() end)
  if not okName or not name or trim(name) == "" then return nil end
  local source = configuredEnemySource(name, spec)
  if source then return name, source end
  return nil
end

local function findEnemy()
  detectorError = ""
  local ok, spectators = pcall(function() return getSpectators() end)
  if not ok or type(spectators) ~= "table" then
    -- Some client builds prefer the explicit multifloor argument.
    ok, spectators = pcall(function() return getSpectators(false) end)
  end
  if not ok or type(spectators) ~= "table" then
    detectorError = "getSpectators"
    return nil
  end

  for _, spec in pairs(spectators) do
    local name, source = inspectEnemyCreature(spec)
    if name then return name, source end
  end
  return nil
end

local function sendSOS()
  local row = selfRescueRow()
  local leader = leaderRow()
  if not row or not leader or not localRescueAllowed() then return false end

  -- Anti-mute guard: Enemy SOS and Player Attack SOS share one global PM cooldown.
  -- The first SOS is immediate; while danger continues, retries are sparse.
  if detectorLastSOSAt > 0 and now - detectorLastSOSAt < SOS_REPEAT then
    return false
  end

  talkPrivate(leader.name, "SOS:" .. row.name)
  detectorLastSOSAt = now
  return true
end

local function targetRescueAllowed(target)
  local slot = rescueSlotByName(target)
  if not slot then return false end
  local state = targetState[slot]
  return state ~= "SAFE_PZ" and state ~= "TRANSIT"
end

local function addRequest(target)
  local slot, row = rescueSlotByName(target)
  if not slot or not row or not targetRescueAllowed(row.name) then return end
  requests[slot] = row.name
end

local function bestRequest()
  for i = 1, 6 do
    if requests[i] then
      if targetRescueAllowed(requests[i]) then
        return i, requests[i]
      else
        requests[i] = nil
      end
    end
  end
  return nil
end

local function cancelLeaderTarget(target)
  if leaderTarget and lower(leaderTarget) == lower(target) then
    leaderBusy = false
    leaderTarget = nil
    leaderStep = 0
    leaderTimer = 0
  end
end

local function cancelWorkerAssignments(target)
  local key = lower(target)
  for i = 2, 4 do
    if workerAssignments[i] and lower(workerAssignments[i]) == key then
      local worker = config.summoners[i]
      if worker and worker.enabled and trim(worker.name) ~= "" then
        talkPrivate(worker.name, "CANCEL:" .. target)
      end
      workerAssignments[i] = nil
      workerFree[i] = false
    end
  end
end

local function markTargetState(target, state)
  local slot, row = rescueSlotByName(target)
  if not slot or not row then return false end
  targetState[slot] = state
  if state == "SAFE_PZ" then
    requests[slot] = nil
    cancelLeaderTarget(row.name)
    cancelWorkerAssignments(row.name)
  end
  return true
end

local function startLeader(target)
  local slot = rescueSlotByName(target)
  if not slot or not targetRescueAllowed(target) then return end
  requests[slot] = nil
  targetState[slot] = "TRANSIT"
  leaderBusy = true
  leaderTarget = target
  leaderStep = 1
  leaderTimer = now
  talkPrivate(target, "TAKEN:" .. target)
end

local function sendWorker(workerSlot, target)
  local slot = rescueSlotByName(target)
  local worker = config.summoners[workerSlot]
  if not slot or not targetRescueAllowed(target) or not worker or not worker.enabled or trim(worker.name) == "" then return false end
  requests[slot] = nil
  targetState[slot] = "TRANSIT"
  workerAssignments[workerSlot] = target
  workerFree[workerSlot] = false
  talkPrivate(worker.name, "ASSIGN:" .. target)
  return true
end

-- UI --------------------------------------------------------------
g_ui.loadUIFromString([[
CamelRescueTargetRow < Panel
  height: 24

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 18

  Label
    id: slot
    anchors.left: enabled.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
    width: 22
    text-align: center
    font: verdana-11px-rounded

  TextEdit
    id: name
    anchors.left: slot.right
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
    height: 20
    font: verdana-11px-rounded

CamelRescueSummonerRow < Panel
  height: 43

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.top: parent.top
    margin-top: 3
    width: 18

  Label
    id: slot
    anchors.left: enabled.right
    anchors.top: parent.top
    margin-left: 4
    margin-top: 4
    width: 62
    font: verdana-11px-rounded

  TextEdit
    id: name
    anchors.left: slot.right
    anchors.right: parent.right
    anchors.top: parent.top
    margin-left: 4
    height: 20
    font: verdana-11px-rounded

  Label
    id: profileLabel
    anchors.left: slot.left
    anchors.top: name.bottom
    margin-top: 3
    width: 62
    text: Safe DP
    font: verdana-11px-rounded
    color: #aaaaaa

  TextEdit
    id: profile
    anchors.left: name.left
    anchors.right: parent.right
    anchors.top: name.bottom
    margin-top: 3
    height: 20
    font: verdana-11px-rounded

CamelRescueSystemWindow < MainWindow
  !text: tr('Rescue System')
  size: 500 570
  @onEscape: self:hide()

  CheckBox
    id: systemEnabled
    anchors.left: parent.left
    anchors.top: parent.top
    margin-left: 12
    margin-top: 10
    width: 120
    !text: tr('System enabled')

  Label
    id: configMaster
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: systemEnabled.bottom
    margin-left: 12
    margin-right: 12
    margin-top: 6
    height: 18
    text: Config Master: Athalar
    font: verdana-11px-rounded
    color: #64df7c

  CheckBox
    id: usePlayerListEnemies
    anchors.left: parent.left
    anchors.top: configMaster.bottom
    margin-left: 12
    margin-top: 7
    width: 210
    !text: tr('Use Player List -> Enemies')

  Button
    id: enemyListButton
    anchors.right: parent.right
    anchors.verticalCenter: usePlayerListEnemies.verticalCenter
    margin-right: 12
    width: 220
    height: 23
    text: Shared Enemy List

  Label
    id: detectorStatus
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: usePlayerListEnemies.bottom
    margin-left: 12
    margin-right: 12
    margin-top: 6
    height: 18
    text: Detector: ARMED
    font: verdana-11px-rounded
    color: #64df7c

  Label
    id: rescueHeader
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: detectorStatus.bottom
    margin-left: 12
    margin-right: 12
    margin-top: 8
    height: 18
    text: Rescue Characters (priority 1 - 6)
    font: verdana-11px-rounded
    color: #ffb24a

  Panel
    id: rescueList
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: rescueHeader.bottom
    margin-left: 12
    margin-right: 12
    height: 144
    layout:
      type: verticalBox
      fit-children: true

  Label
    id: summonerHeader
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: rescueList.bottom
    margin-left: 12
    margin-right: 12
    margin-top: 8
    height: 18
    text: Summoners (1 = Leader / Dispatcher)
    font: verdana-11px-rounded
    color: #ffb24a

  Panel
    id: summonerList
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: summonerHeader.bottom
    margin-left: 12
    margin-right: 12
    height: 172
    layout:
      type: verticalBox
      fit-children: true

  Label
    id: status
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: summonerList.bottom
    margin-left: 12
    margin-right: 12
    margin-top: 7
    height: 18
    text-align: center
    font: verdana-11px-rounded
    color: #cfd3d7
    text: Ready

  Button
    id: save
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-left: 12
    margin-bottom: 10
    width: 225
    height: 24
    text: SAVE

  Button
    id: close
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 12
    margin-bottom: 10
    width: 225
    height: 24
    text: CLOSE
]])

local root = g_ui.getRootWidget()
local window = root and UI.createWindow("CamelRescueSystemWindow", root) or nil
local rescueRows = {}
local summonerRows = {}
local enemyDraft = {}
local updateSectionState = function() end

local function setEnabledSafe(widget, value)
  if widget and widget.setEnabled then widget:setEnabled(value == true) end
end

local function applyAuthorityUi()
  if not window then return end
  local canEdit = isLocalConfigMaster()
  setEnabledSafe(window.systemEnabled, canEdit)
  setEnabledSafe(window.usePlayerListEnemies, canEdit)
  setEnabledSafe(window.enemyListButton, canEdit)
  setEnabledSafe(window.save, canEdit)
  for i = 1, 6 do
    local row = rescueRows[i]
    if row then
      setEnabledSafe(row.enabled, canEdit)
      setEnabledSafe(row.name, canEdit)
    end
  end
  for i = 1, 4 do
    local row = summonerRows[i]
    if row then
      setEnabledSafe(row.enabled, canEdit)
      setEnabledSafe(row.name, canEdit)
      setEnabledSafe(row.profile, canEdit)
    end
  end
  if window.configMaster then
    window.configMaster:setText("Config Master: " .. CONFIG_MASTER .. (canEdit and "  (EDITABLE)" or "  (SOLO LECTURA)"))
    window.configMaster:setColor(canEdit and "#64df7c" or "#aaaaaa")
  end
end

local function updateWindowFromConfig()
  if not window then return end
  window.systemEnabled:setChecked(config.enabled == true)
  window.usePlayerListEnemies:setChecked(config.usePlayerListEnemies ~= false)
  if window.enemyListButton then window.enemyListButton:setText("Shared Enemy List (" .. tostring(#(config.enemies or {})) .. ")") end

  for i = 1, 6 do
    local row = rescueRows[i]
    local data = config.rescue[i]
    if row and data then
      row.enabled:setChecked(data.enabled == true)
      row.name:setText(data.name or "")
    end
  end

  for i = 1, 4 do
    local row = summonerRows[i]
    local data = config.summoners[i]
    if row and data then
      row.enabled:setChecked(data.enabled == true)
      row.name:setText(data.name or "")
      row.profile:setText(data.safeProfile or "")
    end
  end

  local rescueCount = 0
  local summonerCount = 0
  for i = 1, 6 do if config.rescue[i].enabled then rescueCount = rescueCount + 1 end end
  for i = 1, 4 do if config.summoners[i].enabled then summonerCount = summonerCount + 1 end end
  if isLocalConfigMaster() then
    window.status:setText(tostring(rescueCount) .. " rescue / " .. tostring(summonerCount) .. " summoners | Enemies: " .. tostring(#(config.enemies or {})) .. " shared" .. (config.usePlayerListEnemies ~= false and " + Player List" or ""))
    window.status:setColor("#64df7c")
  else
    window.status:setText(tostring(rescueCount) .. " rescue / " .. tostring(summonerCount) .. " summoners | " .. tostring(#(config.enemies or {})) .. " shared enemies | Solo lectura")
    window.status:setColor("#cfd3d7")
  end
  applyAuthorityUi()
end

local function validateConfig(candidateConfig)
  if not candidateConfig.enabled then return true end
  local used = {}
  local activeRescue = 0

  for i = 1, 6 do
    local row = candidateConfig.rescue[i]
    if row.enabled then
      row.name = trim(row.name)
      if row.name == "" then return false, "Rescue " .. i .. ": falta nombre" end
      local key = lower(row.name)
      if used[key] then return false, "Nombre duplicado: " .. row.name end
      used[key] = true
      activeRescue = activeRescue + 1
    end
  end

  if activeRescue == 0 then return false, "Activa al menos 1 Rescue Character" end

  for i = 1, 4 do
    local row = candidateConfig.summoners[i]
    if row.enabled then
      row.name = trim(row.name)
      row.safeProfile = trim(row.safeProfile)
      if row.name == "" then return false, "Summoner " .. i .. ": falta nombre" end
      if row.safeProfile == "" then return false, "Summoner " .. i .. ": falta Safe DP" end
      local key = lower(row.name)
      if used[key] then return false, "Nombre duplicado: " .. row.name end
      used[key] = true
    end
  end

  local leader = candidateConfig.summoners[1]
  if not leader.enabled or trim(leader.name) == "" then
    return false, "Summoner 1 (Leader) debe estar activo"
  end

  return true
end

if window then
  window:hide()

  for i = 1, 6 do
    local row = UI.createWidget("CamelRescueTargetRow", window.rescueList)
    row.slot:setText(tostring(i))
    rescueRows[i] = row
  end

  for i = 1, 4 do
    local row = UI.createWidget("CamelRescueSummonerRow", window.summonerList)
    row.slot:setText(i == 1 and "1 Leader" or tostring(i))
    row.profile:setTooltip("CaveBot profile usado 15 segundos despues de aceptar el summon.")
    summonerRows[i] = row
  end

  window.close.onClick = function() window:hide() end
  if window.closeButton then window.closeButton.onClick = function() window:hide() end end

  local function parseEnemyEditor(text)
    local out, seen = {}, {}
    text = tostring(text or ""):gsub(",", "\n")
    for line in text:gmatch("[^\r\n]+") do
      local clean = trim(line)
      local key = lower(clean)
      if clean ~= "" and not seen[key] and #out < 200 then
        seen[key] = true
        table.insert(out, clean)
      end
    end
    return out
  end

  window.enemyListButton.onClick = function()
    if not isLocalConfigMaster() then
      warn("[Rescue System] Solo " .. CONFIG_MASTER .. " puede editar Shared Enemy List.")
      return
    end
    UI.MultilineEditorWindow(table.concat(enemyDraft, "\n"), {
      title = "Rescue System - Shared Enemy List",
      description = "Un enemigo por linea (tambien acepta comas). Maximo 200. Esta lista se sincroniza desde Athalar a todas las PCs/VPS. Player List -> Enemies se suma automaticamente si esta activado."
    }, function(text)
      enemyDraft = parseEnemyEditor(text)
      window.enemyListButton:setText("Shared Enemy List (" .. tostring(#enemyDraft) .. ")")
      window.status:setText("Lista editada: " .. tostring(#enemyDraft) .. " enemigos. Pulsa SAVE para publicar.")
      window.status:setColor("#ffb24a")
    end)
  end

  window.save.onClick = function()
    local nextConfig = {
      enabled = window.systemEnabled:isChecked(),
      usePlayerListEnemies = window.usePlayerListEnemies:isChecked(),
      enemies = enemyDraft,
      rescue = {},
      summoners = {}
    }

    for i = 1, 6 do
      nextConfig.rescue[i] = {
        enabled = rescueRows[i].enabled:isChecked(),
        name = trim(rescueRows[i].name:getText())
      }
    end

    for i = 1, 4 do
      nextConfig.summoners[i] = {
        enabled = summonerRows[i].enabled:isChecked(),
        name = trim(summonerRows[i].name:getText()),
        safeProfile = trim(summonerRows[i].profile:getText())
      }
    end

    local valid, err = validateConfig(nextConfig)
    if not valid then
      window.status:setText(err or "Configuracion invalida")
      window.status:setColor("#ff6262")
      return
    end

    nextConfig = normalizeConfig(nextConfig)
    local previousConfig = copyConfig(config)

    if not isLocalConfigMaster() then
      window.status:setText("Solo " .. CONFIG_MASTER .. " puede guardar la configuracion")
      window.status:setColor("#ffb24a")
      warn("[Rescue System] Solo el Config Master " .. CONFIG_MASTER .. " puede editar/publicar.")
      updateWindowFromConfig()
      return
    end

    -- Avoid a full cross-PC PM broadcast when SAVE was pressed without changes.
    if configContentSignature(nextConfig) == configContentSignature(config) then
      window.status:setText("Sin cambios - no se enviaron PM")
      window.status:setColor("#64df7c")
      return
    end

    local enabledOnly = previousConfig.enabled ~= nextConfig.enabled and sameExceptEnabled(previousConfig, nextConfig)
    local enemyOnly = not sameEnemyList(previousConfig, nextConfig) and sameExceptEnemies(previousConfig, nextConfig)

    nextConfig.revision = math.max(1, tonumber(config.revision) or 1) + 1
    local ok, raw = writeShared(nextConfig)
    setConfig(nextConfig, raw)
    updateSectionState()

    local modeText = "full sync"
    if enabledOnly then
      broadcastStateDelta(nextConfig, previousConfig)
      modeText = "1 PM/cliente (estado)"
    elseif enemyOnly and broadcastEnemyDelta(previousConfig, nextConfig) then
      modeText = "1 PM/cliente (delta enemigos)"
    else
      broadcastWireConfig(nextConfig, previousConfig)
    end

    window.status:setText("Guardado rev " .. tostring(config.revision) .. " - " .. modeText)
    window.status:setColor("#64df7c")
    info("[Rescue System] Configuracion global en cola lenta: " .. modeText .. ".")
    if not ok then warn("[Rescue System] No se pudo actualizar cache local " .. CONFIG_PATH) end
  end

  updateWindowFromConfig()
end

-- Dedicated compact Tools section. Only this row is visible until opened.
-- The config button fills all remaining width; the master toggle has its own
-- fixed slot on the right so the labels can never overlap.
UI.Separator()
local sectionUi = setupUI([[
Panel
  height: 24

  Button
    id: master
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 52
    text: ON

  Button
    id: open
    anchors.left: parent.left
    anchors.right: master.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    margin-right: 6
    text: Rescue System
]])

updateSectionState = function()
  if not sectionUi or not sectionUi.master then return end
  local canEdit = isLocalConfigMaster()
  setEnabledSafe(sectionUi.master, canEdit)
  if config.enabled then
    sectionUi.master:setText("ON")
    if sectionUi.master.setColor then sectionUi.master:setColor("#64df7c") end
  else
    sectionUi.master:setText("OFF")
    if sectionUi.master.setColor then sectionUi.master:setColor("#ff6262") end
  end
  if sectionUi.master.setTooltip then
    sectionUi.master:setTooltip(canEdit and ("Control global. Config Master: " .. CONFIG_MASTER) or ("Solo " .. CONFIG_MASTER .. " puede cambiar ON/OFF global."))
  end
  if sectionUi.open and sectionUi.open.setTooltip then
    sectionUi.open:setTooltip((config.enabled and "Rescue System activo. " or "Rescue System apagado. ") .. (canEdit and "Click para configurar." or ("Solo lectura; Config Master: " .. CONFIG_MASTER .. ".")))
  end
end

local function openRescueWindow()
  if not window then return end
  enemyDraft = {}
  for _, name in ipairs(config.enemies or {}) do table.insert(enemyDraft, name) end
  updateWindowFromConfig()
  if window.enemyListButton then window.enemyListButton:setText("Shared Enemy List (" .. tostring(#enemyDraft) .. ")") end
  window:show()
  window:raise()
  window:focus()
end

sectionUi.open.onClick = openRescueWindow
sectionUi.master.onClick = function()
  if not isLocalConfigMaster() then
    warn("[Rescue System] Solo " .. CONFIG_MASTER .. " puede cambiar ON/OFF global.")
    return
  end

  local nextConfig = copyConfig(config)
  nextConfig.enabled = not config.enabled
  local previousConfig = copyConfig(config)
  nextConfig.revision = math.max(1, tonumber(config.revision) or 1) + 1
  local ok, raw = writeShared(nextConfig)
  setConfig(nextConfig, raw)
  updateSectionState()
  updateWindowFromConfig()
  broadcastStateDelta(nextConfig, previousConfig)
  info("[Rescue System] " .. (config.enabled and "ON" or "OFF") .. " en cola lenta (1 PM por cliente).")
  if not ok then warn("[Rescue System] No se pudo actualizar cache local " .. CONFIG_PATH) end
end

updateSectionState()

CamelRescueSystem.open = openRescueWindow
CamelRescueSystem.getConfig = function() return copyConfig(config) end

-- Reload the local cache automatically for clients sharing this same installation.
macro(1000, function()
  local raw = readSharedRaw()
  if raw and raw ~= lastSharedRaw then
    local parsed = decodeConfig(raw)
    if parsed then
      setConfig(parsed, raw)
      updateSectionState()
      if window and window:isVisible() then updateWindowFromConfig() end
      lastSyncReceived = now
      info("[Rescue System] Cache local actualizada.")
    end
  end
end)

-- Detector status shown only inside the Rescue System window.
macro(500, function()
  if not window or not window.detectorStatus then return end
  if not activeSystem() then
    window.detectorStatus:setText("Detector: OFF")
    window.detectorStatus:setColor("#aaaaaa")
    return
  end
  if not selfRescueRow() then
    window.detectorStatus:setText("Detector: STANDBY (not a rescue character)")
    window.detectorStatus:setColor("#aaaaaa")
    return
  end
  if rescueState == "SAFE_PZ" then
    window.detectorStatus:setText("Detector: SAFE PZ | rescue blocked")
    window.detectorStatus:setColor("#64df7c")
    return
  end
  if rescueState == "TRANSIT" then
    window.detectorStatus:setText("Detector: TRANSIT | waiting Protection Zone")
    window.detectorStatus:setColor("#ffb24a")
    return
  end
  if rescueState == "EXIT_WAIT" then
    local left = math.max(0, math.ceil((PZ_REARM_DELAY - (now - pzExitAt)) / 1000))
    window.detectorStatus:setText("Detector: LEFT PZ | armed in " .. tostring(left) .. "s")
    window.detectorStatus:setColor("#ffb24a")
    return
  end
  if detectorError ~= "" then
    window.detectorStatus:setText("Detector ERROR: " .. detectorError)
    window.detectorStatus:setColor("#ff6262")
    return
  end
  if detectorLastSOSAt > 0 and now - detectorLastSOSAt < 2500 then
    window.detectorStatus:setText("Detector: SOS SENT -> " .. tostring((leaderRow() and leaderRow().name) or "Leader") .. " | retry 20s")
    window.detectorStatus:setColor("#ffb24a")
    return
  end
  if detectorLastEnemy ~= "" and now - detectorLastSeenAt < 1500 then
    window.detectorStatus:setText("Detector: ENEMY " .. detectorLastEnemy .. " [" .. detectorLastSource .. "]")
    window.detectorStatus:setColor("#ff6262")
    return
  end
  window.detectorStatus:setText("Detector: ARMED | waiting enemy")
  window.detectorStatus:setColor("#64df7c")
end)

-- Cross-PC/VPS synchronization over private in-game messages.
-- R13 keeps silent revision handshakes and adds low-traffic deltas.
-- Full frames are reserved for startup revision mismatch or structural changes.
local function wireBufferKey(prefix, sender, rev)
  return prefix .. ":" .. lower(sender) .. ":" .. tostring(rev or "")
end

local function processWirePart(prefix, senderName, text)
  local kind, rev, payload = text:match("^" .. prefix .. "|([BRSXE])|([^|]+)|(.*)$")
  if not kind then return false end

  local key = wireBufferKey(prefix, senderName, rev)
  if kind == "B" then
    local enabledFlag, playerListFlag, revision = payload:match("^([01]),([01]),(%d+)$")
    if not enabledFlag then return true end
    syncBuffers[key] = {
      cfg = emptyWireConfig(enabledFlag == "1", playerListFlag == "1", tonumber(revision) or 1),
      gotR = false,
      gotS = false,
      enemyChunks = {},
      enemyChunkTotal = 0,
      started = now
    }
    return true
  end

  local stage = syncBuffers[key]
  if not stage then return true end
  stage.started = now

  if kind == "R" then
    stage.gotR = decodeRescueWire(payload, stage.cfg)
    return true
  elseif kind == "S" then
    stage.gotS = decodeSummonerWire(payload, stage.cfg)
    return true
  elseif kind == "X" then
    local index, total, chunk = payload:match("^(%d+),(%d+)|(.*)$")
    index, total = tonumber(index), tonumber(total)
    if index and total and index >= 1 and total >= 1 and index <= total and total <= 40 then
      stage.enemyChunkTotal = total
      stage.enemyChunks[index] = chunk or ""
    end
    return true
  elseif kind ~= "E" then
    return true
  end

  syncBuffers[key] = nil
  if not stage.gotR or not stage.gotS then return true end
  if stage.enemyChunkTotal < 1 then return true end
  stage.cfg.enemies = {}
  for i = 1, stage.enemyChunkTotal do
    if stage.enemyChunks[i] == nil then return true end
    decodeEnemyChunk(stage.enemyChunks[i], stage.cfg)
  end
  local incoming = normalizeConfig(stage.cfg)
  local valid, err = validateConfig(incoming)
  if not valid and incoming.enabled then
    warn("[Rescue System] Sync rechazado: " .. tostring(err or "config invalida"))
    return true
  end

  if lower(senderName) ~= lower(CONFIG_MASTER) then return true end
  local ok, raw = writeShared(incoming)
  setConfig(incoming, raw)
  lastSyncReceived = now
  syncAcknowledged = true
  updateSectionState()
  if window and window:isVisible() then
    updateWindowFromConfig()
    window.status:setText("Sincronizado desde Config Master: " .. senderName)
    window.status:setColor("#64df7c")
  end
  if not ok then warn("[Rescue System] Sync recibido; cache local no pudo escribirse.") end
  return true
end

onTalk(function(name, level, mode, text, channelId, pos)
  if not name or not text then return end
  if text:sub(1, #SYNC_PREFIX + 1) ~= SYNC_PREFIX .. "|" then return end

  local requesterRevision = text:match("^" .. SYNC_PREFIX .. "|Q|(%d+)$")
  if requesterRevision then
    if isLocalConfigMaster() and participantInConfig(name, config, true) then
      local masterRevision = math.max(1, tonumber(config.revision) or 1)
      if tonumber(requesterRevision) ~= masterRevision then
        -- Matching revisions stay silent so multiple VPS boots do not create ACK bursts.
        sendWireConfig(SYNC_PREFIX, name, config)
      end
    end
    return
  end

  local ackRevision = text:match("^" .. SYNC_PREFIX .. "|A|(%d+)$")
  if ackRevision then
    if lower(name) == lower(CONFIG_MASTER) then
      local localRevision = math.max(1, tonumber(config.revision) or 1)
      if tonumber(ackRevision) == localRevision then
        syncAcknowledged = true
        lastSyncReceived = now
        if window and window:isVisible() then
          window.status:setText("Config al dia (rev " .. tostring(localRevision) .. ")")
          window.status:setColor("#64df7c")
        end
      end
    end
    return
  end

  local stateRevision, stateFlag = text:match("^" .. SYNC_PREFIX .. "|T|(%d+)|([01])$")
  if stateRevision then
    if lower(name) == lower(CONFIG_MASTER) then
      local incomingRevision = tonumber(stateRevision) or 0
      local localRevision = math.max(1, tonumber(config.revision) or 1)
      if incomingRevision >= localRevision then
        local incoming = copyConfig(config)
        incoming.revision = incomingRevision
        incoming.enabled = stateFlag == "1"
        local ok, raw = writeShared(incoming)
        setConfig(incoming, raw)
        lastSyncReceived = now
        syncAcknowledged = true
        updateSectionState()
        if window and window:isVisible() then updateWindowFromConfig() end
        if not ok then warn("[Rescue System] Estado recibido; cache local no pudo escribirse.") end
      end
    end
    return
  end

  local enemyRevision, addedRaw, removedRaw = text:match("^" .. SYNC_PREFIX .. "|Y|(%d+)|([^|]*)|(.*)$")
  if enemyRevision then
    if lower(name) == lower(CONFIG_MASTER) then
      local incomingRevision = tonumber(enemyRevision) or 0
      local localRevision = math.max(1, tonumber(config.revision) or 1)
      if incomingRevision >= localRevision then
        local incoming = copyConfig(config)
        local removeSet = {}
        for part in tostring(removedRaw or ""):gmatch("[^;]+") do
          local clean = trim(unescapeWire(part))
          if clean ~= "" then removeSet[lower(clean)] = true end
        end
        local kept = {}
        for _, enemyName in ipairs(incoming.enemies or {}) do
          if not removeSet[lower(enemyName)] then table.insert(kept, enemyName) end
        end
        incoming.enemies = kept
        local present = {}
        for _, enemyName in ipairs(incoming.enemies or {}) do present[lower(enemyName)] = true end
        for part in tostring(addedRaw or ""):gmatch("[^;]+") do
          local clean = trim(unescapeWire(part))
          local key = lower(clean)
          if clean ~= "" and not present[key] and #incoming.enemies < 200 then
            present[key] = true
            table.insert(incoming.enemies, clean)
          end
        end
        incoming.revision = incomingRevision
        incoming = normalizeConfig(incoming)
        local ok, raw = writeShared(incoming)
        setConfig(incoming, raw)
        lastSyncReceived = now
        syncAcknowledged = true
        updateSectionState()
        if window and window:isVisible() then updateWindowFromConfig() end
        if not ok then warn("[Rescue System] Delta de enemigos recibido; cache local no pudo escribirse.") end
      end
    end
    return
  end

  -- Only the fixed Config Master may send authoritative full configuration frames.
  if lower(name) == lower(CONFIG_MASTER) then
    processWirePart(SYNC_PREFIX, name, text)
  end
end)

-- Remote PCs/VPS perform version sync only at startup. If the Config Master is
-- temporarily offline, the client makes only one startup request and then keeps
-- its local cache. Full config is received only when revisions differ; no polling continues.
macro(5000, function()
  if isLocalConfigMaster() or syncAcknowledged then return end
  if now - bootAt < SYNC_REQUEST_BOOT_DELAY then return end
  if syncRequestCount >= SYNC_BOOT_MAX_REQUESTS then return end
  if lastSyncRequest == 0 or now - lastSyncRequest >= SYNC_BOOT_RETRY_EVERY then
    requestMasterSync()
  end
end)

macro(10000, function()
  for key, stage in pairs(syncBuffers) do
    if not stage or now - (stage.started or now) > SYNC_BUFFER_TIMEOUT then syncBuffers[key] = nil end
  end
end)

-- Protection Zone lifecycle -------------------------------------
-- Every configured rescue character owns its own live state, regardless of PC/VPS.
-- SAFE/READY is sent once per state transition to the Summon Leader/Dispatcher.
macro(250, function()
  if not activeSystem() then return end
  local row = selfRescueRow()
  if not row then return end

  local inPz = localInPz()
  if pzWasIn == nil then
    pzWasIn = inPz
    if inPz then
      rescueState = "SAFE_PZ"
      rescueTaken = true
    elseif rescueTaken then
      rescueState = "TRANSIT"
    else
      rescueState = "ARMED"
    end
  end

  if inPz then
    pzExitAt = 0
    if rescueState ~= "SAFE_PZ" then
      rescueState = "SAFE_PZ"
      rescueTaken = true
      candidate = nil
      candidateSince = 0
      attackDanger = false
      lastRealPlayerAttack = 0
      lastAttackSOS = 0
      lastSOS = 0
      detectorLastSOSAt = 0
      pzStateAnnounced = nil
    end
    if now - bootAt >= PZ_STATE_BOOT_DELAY then announceLocalRescueState("SAFE_PZ") end
  else
    if pzWasIn == true then
      rescueState = "EXIT_WAIT"
      rescueTaken = true
      pzExitAt = now
      candidate = nil
      candidateSince = 0
      attackDanger = false
      lastRealPlayerAttack = 0
      pzStateAnnounced = nil
    elseif rescueState == "EXIT_WAIT" and pzExitAt > 0 and now - pzExitAt >= PZ_REARM_DELAY then
      rescueState = "ARMED"
      rescueTaken = false
      pzExitAt = 0
      candidate = nil
      candidateSince = 0
      lastSOS = 0
      lastAttackSOS = 0
      detectorLastSOSAt = 0
      pzStateAnnounced = nil
      announceLocalRescueState("ARMED")
    elseif rescueState == "ARMED" and pzStateAnnounced == nil and now - bootAt >= PZ_STATE_BOOT_DELAY then
      announceLocalRescueState("ARMED")
    end
  end

  pzWasIn = inPz
end)

-- Rescue character logic -----------------------------------------
-- Internal rescue loops are intentionally anonymous. Named macros remember their
-- previous ON/OFF state in storage._macros; hiding such a switch can leave a
-- detector OFF with no way for the user to turn it back on. Rescue System's
-- master ON/OFF is now the only authority.
macro(100, function()
  if not activeSystem() then return end
  local selfRow = selfRescueRow()
  if not selfRow or not localRescueAllowed() then return end

  local enemy, source = findEnemy()
  if not enemy then
    candidate = nil
    candidateSince = 0
    return
  end

  detectorLastEnemy = enemy
  detectorLastSource = source or "Enemy"
  detectorLastSeenAt = now

  if candidate ~= enemy then
    candidate = enemy
    candidateSince = now
    return
  end

  if now - candidateSince < CONFIRM_TIME then return end
  if lastSOS == 0 or now - lastSOS >= SOS_REPEAT then
    if sendSOS() then lastSOS = now end
  end
end)

macro(100, function()
  if not activeSystem() or not selfRescueRow() or not localRescueAllowed() then return end
  if not attackDanger then return end

  if now - lastRealPlayerAttack >= ATTACK_MEMORY then
    attackDanger = false
    lastRealPlayerAttack = 0
    lastAttackSOS = 0
    return
  end

  if lastAttackSOS == 0 or now - lastAttackSOS >= ATTACK_SOS_REPEAT then
    if sendSOS() then lastAttackSOS = now end
  end
end)

macro(200, function()
  if not activeSystem() or not selfRescueRow() then return end
  if not switchToSafe or not safeProfile then return end
  if now - switchTimer < SAFE_SWITCH_DELAY then return end

  local exists = caveProfileExists(safeProfile)
  if exists == false then
    warn("[Rescue System] Safe DP inexistente para " .. tostring(safeProfileSender or "summoner") .. ": " .. tostring(safeProfile))
  elseif CaveBot and CaveBot.setCurrentProfile then
    CaveBot.setCurrentProfile(safeProfile)
  else
    warn("[Rescue System] CaveBot no disponible para cambiar a " .. tostring(safeProfile))
  end

  switchToSafe = false
  switchTimer = 0
  safeProfile = nil
  safeProfileSender = nil
  -- Do NOT re-arm here. The character stays TRANSIT until isInPz() confirms
  -- arrival at Protection Zone, then SAFE_PZ blocks all future summons.
  rescueTaken = true
  if rescueState ~= "SAFE_PZ" then rescueState = "TRANSIT" end
  candidate = nil
  candidateSince = 0
  lastSOS = 0
end)

-- Event-assisted detection. The periodic scanner remains authoritative and
-- performs the 800 ms confirmation, while this records enemies immediately
-- when the client announces their appearance.
onCreatureAppear(function(creature)
  if not activeSystem() or not selfRescueRow() or not localRescueAllowed() then return end
  local enemy, source = inspectEnemyCreature(creature)
  if not enemy then return end
  detectorLastEnemy = enemy
  detectorLastSource = source or "Enemy"
  detectorLastSeenAt = now
  if candidate ~= enemy then
    candidate = enemy
    candidateSince = now
  end
end)

onTextMessage(function(mode, text)
  if not activeSystem() or not selfRescueRow() or not localRescueAllowed() then return end
  if mode ~= 16 or not text then return end

  if string.match(text, "hitpoints due to an attack")
  and not string.match(text, "hitpoints due to an attack by a ") then
    attackDanger = true
    lastRealPlayerAttack = now
    if sendSOS() then
      lastAttackSOS = now
    end
  end
end)

-- Shared message protocol ----------------------------------------
onTalk(function(name, level, mode, text, channelId, pos)
  if not activeSystem() or not name or not text then return end
  local sender = lower(name)
  local me = localPlayerName()

  -- Rescue target accepts only configured summoners.
  local selfTarget = selfRescueRow()
  if selfTarget then
    local senderSummoner = summonerSlotByName(name)
    if senderSummoner then
      local isTakenMessage = text == "TAKEN:" .. selfTarget.name
      local isAcceptMessage = text == "ACCEPT_SUMMON:" .. selfTarget.name

      -- Final local safety gate: while SAFE_PZ or during the 5s exit grace,
      -- never accept a summon even if a stale assignment reaches this client.
      if (rescueState == "SAFE_PZ" or rescueState == "EXIT_WAIT" or localInPz())
      and (isTakenMessage or isAcceptMessage) then
        rescueTaken = true
        if localInPz() then
          rescueState = "SAFE_PZ"
          pzStateAnnounced = nil
          announceLocalRescueState("SAFE_PZ")
        end
      elseif isTakenMessage then
        rescueTaken = true
        rescueState = "TRANSIT"
        pzStateAnnounced = nil
        attackDanger = false
        lastRealPlayerAttack = 0
        lastAttackSOS = 0
      elseif isAcceptMessage then
        rescueTaken = true
        rescueState = "TRANSIT"
        pzStateAnnounced = nil
        attackDanger = false
        lastRealPlayerAttack = 0
        lastAttackSOS = 0
        safeProfile = safeProfileForSummoner(name)
        safeProfileSender = name
        say("!aceptar")
        switchToSafe = safeProfile ~= nil and trim(safeProfile) ~= ""
        switchTimer = now
        if not switchToSafe then
          warn("[Rescue System] " .. tostring(name) .. " no tiene Safe DP configurado.")
        end
      end
    end
  end

  local mySummonerSlot = selfSummonerSlot()
  if not mySummonerSlot then return end
  local leader = leaderRow()
  if not leader then return end

  -- Leader / Dispatcher receives SOS and worker states.
  if mySummonerSlot == 1 then
    local rescueSlot, rescueRow = rescueSlotByName(name)
    if rescueSlot and rescueRow then
      if text == "SAFE:" .. rescueRow.name then
        markTargetState(rescueRow.name, "SAFE_PZ")
        return
      elseif text == "READY:" .. rescueRow.name then
        targetState[rescueSlot] = "ARMED"
        requests[rescueSlot] = nil
        return
      elseif text == "SOS:" .. rescueRow.name then
        if targetRescueAllowed(rescueRow.name) then
          targetState[rescueSlot] = "ARMED"
          addRequest(rescueRow.name)
        end
        return
      end
    end

    local senderSlot = summonerSlotByName(name)
    if senderSlot and senderSlot >= 2 then
      if text == "STATE:FREE" then
        workerFree[senderSlot] = true
        workerAssignments[senderSlot] = nil
        return
      elseif text == "STATE:BUSY" or text == "STATE:COOLDOWN" then
        workerFree[senderSlot] = false
        if text == "STATE:COOLDOWN" then workerAssignments[senderSlot] = nil end
        return
      elseif text:sub(1, 8) == "DECLINE:" then
        workerFree[senderSlot] = false
        workerAssignments[senderSlot] = nil
        local target = canonicalRescueName(text:sub(9))
        if target then
          local slot = rescueSlotByName(target)
          if slot and targetState[slot] ~= "SAFE_PZ" then
            targetState[slot] = "ARMED"
            addRequest(target)
          end
        end
        return
      end
    end
    return
  end

  -- Worker summoners accept assignments/cancellations only from configured leader.
  if sender ~= lower(leader.name) then return end

  if text:sub(1, 7) == "CANCEL:" then
    local target = canonicalRescueName(text:sub(8))
    if target and workerTarget and lower(workerTarget) == lower(target) then
      workerBusy = false
      workerTarget = nil
      workerStep = 0
      workerTimer = 0
      if now < workerCooldownUntil then
        talkPrivate(leader.name, "STATE:COOLDOWN")
      else
        talkPrivate(leader.name, "STATE:FREE")
        workerLastFree = now
      end
    end
    return
  end

  if text:sub(1, 7) ~= "ASSIGN:" then return end
  local target = canonicalRescueName(text:sub(8))
  if not target then return end

  if workerBusy or now < workerCooldownUntil or not findItem(EYE_ID) then
    talkPrivate(leader.name, "DECLINE:" .. target)
    return
  end

  workerBusy = true
  workerTarget = target
  workerStep = 1
  workerTimer = now
  talkPrivate(leader.name, "STATE:BUSY")
  talkPrivate(target, "TAKEN:" .. target)
end)

-- Leader dispatcher and summon engine.
macro(200, function()
  if not activeSystem() or selfSummonerSlot() ~= 1 then return end
  local _, target = bestRequest()
  if not target then return end

  if not targetRescueAllowed(target) then return end

  if not leaderBusy and now >= leaderCooldownUntil and findItem(EYE_ID) then
    startLeader(target)
    return
  end

  for i = 2, 4 do
    if workerFree[i] and config.summoners[i].enabled then
      if sendWorker(i, target) then return end
    end
  end
end)

macro(100, function()
  if not activeSystem() or selfSummonerSlot() ~= 1 then return end
  if leaderStep == 0 then return end

  if leaderStep == 1 then
    if not findItem(EYE_ID) then
      if leaderTarget then
        local slot = rescueSlotByName(leaderTarget)
        if slot and targetState[slot] ~= "SAFE_PZ" then
          targetState[slot] = "ARMED"
          addRequest(leaderTarget)
        end
      end
      leaderBusy = false
      leaderTarget = nil
      leaderStep = 0
      return
    end

    use(EYE_ID)
    leaderStep = 2
    leaderTimer = now
    return
  end

  if leaderStep == 2 then
    if now - leaderTimer < SUMMON_EYE_DELAY then return end
    if not leaderTarget then
      leaderBusy = false
      leaderStep = 0
      return
    end

    say("!invocar " .. leaderTarget)
    leaderCooldownUntil = now + SUMMON_COOLDOWN
    leaderStep = 3
    leaderTimer = now
    return
  end

  if leaderStep == 3 then
    if now - leaderTimer < SUMMON_ACCEPT_DELAY then return end
    if leaderTarget then talkPrivate(leaderTarget, "ACCEPT_SUMMON:" .. leaderTarget) end
    leaderBusy = false
    leaderTarget = nil
    leaderStep = 0
    leaderTimer = 0
  end
end)

-- Worker summon engine (Summoners 2-4).
macro(100, function()
  local mySlot = selfSummonerSlot()
  if not activeSystem() or not mySlot or mySlot < 2 then return end
  local leader = leaderRow()
  if not leader or workerStep == 0 then return end

  if workerStep == 1 then
    if not findItem(EYE_ID) then
      if workerTarget then talkPrivate(leader.name, "DECLINE:" .. workerTarget) end
      workerBusy = false
      workerTarget = nil
      workerStep = 0
      workerTimer = 0
      return
    end

    use(EYE_ID)
    workerStep = 2
    workerTimer = now
    return
  end

  if workerStep == 2 then
    if now - workerTimer < SUMMON_EYE_DELAY then return end
    if not workerTarget then
      workerBusy = false
      workerStep = 0
      workerTimer = 0
      return
    end

    say("!invocar " .. workerTarget)
    workerCooldownUntil = now + SUMMON_COOLDOWN
    workerStep = 3
    workerTimer = now
    return
  end

  if workerStep == 3 then
    if now - workerTimer < SUMMON_ACCEPT_DELAY then return end
    if workerTarget then talkPrivate(workerTarget, "ACCEPT_SUMMON:" .. workerTarget) end

    workerBusy = false
    workerTarget = nil
    workerStep = 0
    workerTimer = 0
    talkPrivate(leader.name, "STATE:COOLDOWN")
  end
end)

macro(5000, function()
  local mySlot = selfSummonerSlot()
  if not activeSystem() or not mySlot or mySlot < 2 then return end
  if workerBusy or now < workerCooldownUntil then return end
  local leader = leaderRow()
  if not leader then return end

  if workerLastFree == 0 or now - workerLastFree >= 120000 then
    talkPrivate(leader.name, "STATE:FREE")
    workerLastFree = now
  end
end)
