---@diagnostic disable: undefined-global
-- Player List + Pazzur Guild Sync
-- Manual entries remain local/persistent. Guild-managed entries are refreshed from
-- pazzur.sytes.net and are tracked separately so a web sync never deletes manual data.

local link = "https://pazzur.sytes.net/characters/"
local spacing = "+"

setDefaultTab("Main")
local tabs = {"Friends", "Enemies", "BlackList"}
local panelName = "playerList"
local colors = {"#03C04A", "#fc4c4e", "orange"}

local GUILD_BASE_URL = "https://pazzur.sytes.net"
local GUILD_RULES_PATH = "/bot/CamelGuildSync.cfg"
local GUILD_CONFIG_MASTER = "Athalar"
local GUILD_SYNC_PREFIX = "GS1"
local GUILD_SYNC_INTERVAL = 1800000 -- 30 minutes
local GUILD_SYNC_RETRY = 300000 -- 5 minutes after a web failure
local GUILD_CONFIRM_RETRY = 120000 -- second confirmation before automatic removals
local GUILD_HTTP_GAP = 750
local GUILD_RULE_PM_GAP = 15000
local GUILD_RULE_BOOT_DELAY = 8000
local MAX_GUILDS_PER_GROUP = 12
local DEFAULT_GUILD_CLIENTS = {
  "Athalar", "Bonga", "Gampi", "Jon Snow", "Lemac", "Link",
  "Red Clair", "Tozkoparan", "Tronchito", "Valyria", "Wisin", "Yandel", "Zunga"
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

local function localPlayerName()
  local me = g_game.getLocalPlayer()
  return me and me:getName() or ""
end

local function isGuildMaster()
  return lower(localPlayerName()) == lower(GUILD_CONFIG_MASTER)
end

local function copyArray(source)
  local out = {}
  for _, value in ipairs(source or {}) do table.insert(out, value) end
  return out
end

local function normalizeNames(source, limit)
  local out, seen = {}, {}
  for _, value in ipairs(source or {}) do
    local clean = trim(value)
    local key = lower(clean)
    if clean ~= "" and not seen[key] and (not limit or #out < limit) then
      seen[key] = true
      table.insert(out, clean)
    end
  end
  return out
end

local function toSet(source)
  local set = {}
  for _, value in ipairs(source or {}) do
    local key = lower(value)
    if key ~= "" then set[key] = true end
  end
  return set
end

local function toDisplayMap(source)
  local out = {}
  for _, value in ipairs(source or {}) do
    local clean = trim(value)
    local key = lower(clean)
    if clean ~= "" and not out[key] then out[key] = clean end
  end
  return out
end

local function sortedArrayFromMap(map)
  local out = {}
  for _, value in pairs(map or {}) do table.insert(out, value) end
  table.sort(out, function(a, b) return lower(a) < lower(b) end)
  return out
end

local function replaceArray(target, source)
  while #target > 0 do table.remove(target) end
  for _, value in ipairs(source or {}) do table.insert(target, value) end
end

local function removeCaseInsensitive(list, name)
  local key = lower(name)
  for i = #list, 1, -1 do
    if lower(list[i]) == key then table.remove(list, i) end
  end
end

local function containsCaseInsensitive(list, name)
  local key = lower(name)
  for _, value in ipairs(list or {}) do
    if lower(value) == key then return true end
  end
  return false
end

local function addUnique(list, name)
  local clean = trim(name)
  if clean == "" or containsCaseInsensitive(list, clean) then return false end
  table.insert(list, clean)
  return true
end

if not storage[panelName] then
  storage[panelName] = {
    enemyList = {},
    friendList = {},
    blackList = {},
    groupMembers = true,
    outfits = false,
    marks = false,
    highlight = false,
    autoAdd = false,
    guildSyncEnabled = true
  }
end

local config = storage[panelName]
config.enemyList = type(config.enemyList) == "table" and config.enemyList or {}
config.friendList = type(config.friendList) == "table" and config.friendList or {}
config.blackList = type(config.blackList) == "table" and config.blackList or {}
if config.guildSyncEnabled == nil then config.guildSyncEnabled = true end

local guildState = type(config.guildSyncState) == "table" and config.guildSyncState or {}
config.guildSyncState = guildState

-- The first installation snapshot becomes the manual baseline. Afterwards only
-- Guild Sync-managed names are eligible for automatic removal.
if type(guildState.manualFriends) ~= "table" then guildState.manualFriends = copyArray(config.friendList) end
if type(guildState.manualEnemies) ~= "table" then guildState.manualEnemies = copyArray(config.enemyList) end
if type(guildState.manualBlacklist) ~= "table" then guildState.manualBlacklist = copyArray(config.blackList) end
if type(guildState.managedFriends) ~= "table" then guildState.managedFriends = {} end
if type(guildState.managedEnemies) ~= "table" then guildState.managedEnemies = {} end
if type(guildState.managedBlacklist) ~= "table" then guildState.managedBlacklist = {} end
if type(guildState.excludedFriends) ~= "table" then guildState.excludedFriends = {} end
if type(guildState.excludedEnemies) ~= "table" then guildState.excludedEnemies = {} end
if type(guildState.excludedBlacklist) ~= "table" then guildState.excludedBlacklist = {} end

local playerTables = {config.friendList, config.enemyList, config.blackList}
local manualTables = {guildState.manualFriends, guildState.manualEnemies, guildState.manualBlacklist}
local managedKeys = {"managedFriends", "managedEnemies", "managedBlacklist"}
local excludedKeys = {"excludedFriends", "excludedEnemies", "excludedBlacklist"}

-- Player cache helpers -------------------------------------------------------
local function clearCachedPlayers()
  CachedFriends = {}
  CachedEnemies = {}
end

local refreshStatus = function()
  for _, spec in ipairs(getSpectators()) do
    if spec:isPlayer() and not spec:isLocalPlayer() then
      if config.outfits then
        local specOutfit = spec:getOutfit()
        if isFriend(spec:getName()) then
          if config.highlight then spec:setMarked('#0000FF') end
          specOutfit.head = 88
          specOutfit.body = 88
          specOutfit.legs = 88
          specOutfit.feet = 88
          if storage.BOTserver and storage.BOTserver.outfit then
            local voc = vBot.BotServerMembers[spec:getName()]
            specOutfit.addons = 3
            if voc == 1 then specOutfit.type = 131
            elseif voc == 2 then specOutfit.type = 129
            elseif voc == 3 then specOutfit.type = 130
            elseif voc == 4 then specOutfit.type = 144 end
          end
          spec:setOutfit(specOutfit)
        elseif isEnemy(spec:getName()) then
          if config.highlight then spec:setMarked('#FF0000') end
          specOutfit.head = 94
          specOutfit.body = 94
          specOutfit.legs = 94
          specOutfit.feet = 94
          spec:setOutfit(specOutfit)
        end
      end
    end
  end
end

local checkStatus = function(creature)
  if not creature:isPlayer() or creature:isLocalPlayer() then return end
  local specName = creature:getName()
  local specOutfit = creature:getOutfit()
  if isFriend(specName) then
    if config.highlight then creature:setMarked('#0000FF') end
    if config.outfits then
      specOutfit.head = 88
      specOutfit.body = 88
      specOutfit.legs = 88
      specOutfit.feet = 88
      if storage.BOTserver and storage.BOTserver.outfit then
        local voc = vBot.BotServerMembers[creature:getName()]
        specOutfit.addons = 3
        if voc == 1 then specOutfit.type = 131
        elseif voc == 2 then specOutfit.type = 129
        elseif voc == 3 then specOutfit.type = 130
        elseif voc == 4 then specOutfit.type = 144 end
      end
      creature:setOutfit(specOutfit)
    end
  elseif isEnemy(specName) then
    if config.highlight then creature:setMarked('#FF0000') end
    if config.outfits then
      specOutfit.head = 94
      specOutfit.body = 94
      specOutfit.legs = 94
      specOutfit.feet = 94
      creature:setOutfit(specOutfit)
    end
  end
end

-- Shared Guild Rules --------------------------------------------------------
local function defaultGuildRules()
  return {
    revision = 1,
    enemyGuilds = {"Godslayers", "Walkers"},
    allyGuilds = {}
  }
end

local function normalizeGuildRules(source)
  source = type(source) == "table" and source or defaultGuildRules()
  return {
    revision = math.max(1, tonumber(source.revision) or 1),
    enemyGuilds = normalizeNames(source.enemyGuilds or {}, MAX_GUILDS_PER_GROUP),
    allyGuilds = normalizeNames(source.allyGuilds or {}, MAX_GUILDS_PER_GROUP)
  }
end

local function encodeGuildRules(source)
  local lines = {"version=1", "revision=" .. tostring(math.max(1, tonumber(source.revision) or 1))}
  for _, name in ipairs(source.enemyGuilds or {}) do table.insert(lines, "enemyGuild=" .. trim(name)) end
  for _, name in ipairs(source.allyGuilds or {}) do table.insert(lines, "allyGuild=" .. trim(name)) end
  return table.concat(lines, "\n") .. "\n"
end

local function decodeGuildRules(raw)
  if type(raw) ~= "string" or raw == "" then return nil end
  local out = {revision = 1, enemyGuilds = {}, allyGuilds = {}}
  for line in raw:gmatch("[^\r\n]+") do
    local key, value = line:match("^([^=]+)=(.*)$")
    if key == "revision" then out.revision = math.max(1, tonumber(value) or 1)
    elseif key == "enemyGuild" then table.insert(out.enemyGuilds, trim(value))
    elseif key == "allyGuild" then table.insert(out.allyGuilds, trim(value)) end
  end
  return normalizeGuildRules(out)
end

local function readGuildRulesRaw()
  if not g_resources or not g_resources.readFileContents then return nil end
  local ok, raw = pcall(function() return g_resources.readFileContents(GUILD_RULES_PATH) end)
  if ok and type(raw) == "string" and raw ~= "" then return raw end
  return nil
end

local function writeGuildRules(source)
  if not g_resources or not g_resources.writeFileContents then return false end
  local raw = encodeGuildRules(source)
  local ok = pcall(function() g_resources.writeFileContents(GUILD_RULES_PATH, raw) end)
  return ok, raw
end

local guildRules = decodeGuildRules(readGuildRulesRaw()) or defaultGuildRules()
guildRules = normalizeGuildRules(guildRules)
if not readGuildRulesRaw() then writeGuildRules(guildRules) end

local function guildRulesSignature(source)
  local copy = normalizeGuildRules(source)
  copy.revision = 1
  return encodeGuildRules(copy)
end

local function wireEscape(value)
  value = tostring(value or "")
  value = value:gsub("%%", "%%25")
  value = value:gsub("|", "%%7C")
  value = value:gsub(";", "%%3B")
  value = value:gsub("&", "%%26")
  return value
end

local function wireUnescape(value)
  value = tostring(value or "")
  value = value:gsub("%%26", "&")
  value = value:gsub("%%3B", ";")
  value = value:gsub("%%7C", "|")
  value = value:gsub("%%25", "%%")
  return value
end

local function encodeGuildListWire(list)
  local out = {}
  for _, name in ipairs(list or {}) do table.insert(out, wireEscape(name)) end
  return table.concat(out, ";")
end

local function decodeGuildListWire(raw)
  local out = {}
  for part in tostring(raw or ""):gmatch("[^;]+") do
    local clean = trim(wireUnescape(part))
    if clean ~= "" then table.insert(out, clean) end
  end
  return normalizeNames(out, MAX_GUILDS_PER_GROUP)
end

local function guildRulePayload(source)
  return "E=" .. encodeGuildListWire(source.enemyGuilds) .. "&A=" .. encodeGuildListWire(source.allyGuilds)
end

local function decodeGuildRulePayload(raw, revision)
  local enemies, allies = tostring(raw or ""):match("^E=(.-)&A=(.*)$")
  if enemies == nil then return nil end
  return normalizeGuildRules({
    revision = revision,
    enemyGuilds = decodeGuildListWire(enemies),
    allyGuilds = decodeGuildListWire(allies)
  })
end

local function buildGuildRuleFrames(source)
  local revision = math.max(1, tonumber(source.revision) or 1)
  local payload = guildRulePayload(source)
  local single = GUILD_SYNC_PREFIX .. "|C|" .. tostring(revision) .. "|" .. payload
  if #single <= 220 then return {single} end

  local chunks = {}
  local chunkSize = 140
  local index = 1
  while index <= #payload do
    table.insert(chunks, payload:sub(index, index + chunkSize - 1))
    index = index + chunkSize
  end
  local frames = {GUILD_SYNC_PREFIX .. "|B|" .. tostring(revision) .. "|" .. tostring(#chunks)}
  for i, chunk in ipairs(chunks) do
    table.insert(frames, GUILD_SYNC_PREFIX .. "|X|" .. tostring(revision) .. "|" .. tostring(i) .. "|" .. chunk)
  end
  table.insert(frames, GUILD_SYNC_PREFIX .. "|E|" .. tostring(revision))
  return frames
end

local function guildParticipants()
  local seen, out = {}, {}
  local me = lower(localPlayerName())
  local function addName(name)
    name = trim(name)
    local key = lower(name)
    if key ~= "" and key ~= me and not seen[key] then
      seen[key] = true
      table.insert(out, name)
    end
  end

  for _, name in ipairs(DEFAULT_GUILD_CLIENTS) do addName(name) end

  local rescueConfig = CamelRescueSystem and CamelRescueSystem.getConfig and CamelRescueSystem.getConfig() or nil
  if rescueConfig then
    local function addRows(rows, max)
      for i = 1, max do
        local row = rows and rows[i] or nil
        addName(row and row.name or "")
      end
    end
    addRows(rescueConfig.rescue, 6)
    addRows(rescueConfig.summoners, 4)
  end
  return out
end

local function queueGuildRuleFrames(channel, recipients, source)
  local frames = buildGuildRuleFrames(source)
  local revision = math.max(1, tonumber(source.revision) or 1)
  local items = {}
  for _, recipient in ipairs(recipients or {}) do
    for _, frame in ipairs(frames) do
      table.insert(items, {
        recipient = recipient,
        message = frame,
        gapAfter = GUILD_RULE_PM_GAP,
        priority = 1,
        guard = function()
          return isGuildMaster() and math.max(1, tonumber(guildRules.revision) or 1) == revision
        end
      })
    end
  end
  if CamelSlowPM and CamelSlowPM.replaceChannel then
    CamelSlowPM.replaceChannel(channel, items)
  else
    local delay = 0
    for _, item in ipairs(items) do
      local recipientCopy = item.recipient
      local messageCopy = item.message
      local guardCopy = item.guard
      schedule(delay, function()
        if guardCopy() then talkPrivate(recipientCopy, messageCopy) end
      end)
      delay = delay + GUILD_RULE_PM_GAP
    end
  end
end

local function broadcastGuildRules()
  queueGuildRuleFrames("guild-rules-broadcast", guildParticipants(), guildRules)
end

local function sendGuildRulesTo(recipient)
  queueGuildRuleFrames("guild-rules:" .. lower(recipient), {recipient}, guildRules)
end

-- URL / HTML helpers --------------------------------------------------------
local function urlEncode(value)
  value = tostring(value or ""):gsub(" ", "+")
  return (value:gsub("([^%w%-%._~+])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function urlDecode(value)
  value = tostring(value or ""):gsub("%+", " ")
  return (value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

local function parseCharacterGuild(html)
  if type(html) ~= "string" or #html < 50 then return nil, false end
  if not html:find("Character Information", 1, true) then return nil, false end
  local pos = html:find("Guild membership", 1, true)
  if not pos then return "", true end
  local sample = html:sub(pos, math.min(#html, pos + 900))
  local encoded = sample:match("/guilds/([^\"'#?]+)")
  if not encoded then return "", true end
  return trim(urlDecode(encoded)), true
end

local function parseGuildMembers(html)
  if type(html) ~= "string" or #html < 50 then return nil end
  local startPos = html:find("Guild Members", 1, true)
  if not startPos then return nil end
  local endPos = #html + 1
  local invitedPos = html:find("Invited Characters", startPos, true)
  local footerPos = html:find("All rights reserved", startPos, true)
  local onlinePos = html:find(">ONLINE<", startPos, true)
  if invitedPos and invitedPos < endPos then endPos = invitedPos end
  if footerPos and footerPos < endPos then endPos = footerPos end
  if onlinePos and onlinePos < endPos then endPos = onlinePos end
  local block = html:sub(startPos, endPos - 1)
  local out, seen = {}, {}

  local function addEncoded(encoded)
    local clean = trim(urlDecode(encoded))
    local key = lower(clean)
    if clean ~= "" and not seen[key] then
      seen[key] = true
      table.insert(out, clean)
    end
  end

  for encoded in block:gmatch("href%s*=%s*[\"'][^\"']*/characters/([^\"'#?]+)") do addEncoded(encoded) end
  if #out == 0 then
    for encoded in block:gmatch("/characters/([^\"'#?]+)") do addEncoded(encoded) end
  end
  if #out == 0 then return nil end
  return out
end

-- Guild-managed Player List state ------------------------------------------
local listWidgets = {}
local ListWindow
local guildRuntime = {
  inProgress = false,
  status = "Waiting",
  currentGuild = trim(guildState.currentGuild or ""),
  lastSuccessText = trim(guildState.lastSuccessText or ""),
  scheduleToken = 0,
  ruleBuffers = {}
}

local function managedSetForIndex(index)
  return toSet(guildState[managedKeys[index]] or {})
end

local function excludedSetForIndex(index)
  return toSet(guildState[excludedKeys[index]] or {})
end

local function isManagedOnly(index, name)
  return managedSetForIndex(index)[lower(name)] and not toSet(manualTables[index])[lower(name)]
end

local function captureManualFromActual()
  for index = 1, 3 do
    local managed = managedSetForIndex(index)
    for _, name in ipairs(playerTables[index]) do
      if not managed[lower(name)] then addUnique(manualTables[index], name) end
    end
    replaceArray(manualTables[index], normalizeNames(manualTables[index]))
  end
end

local function addExcluded(index, name)
  addUnique(guildState[excludedKeys[index]], name)
end

local function clearExcluded(index, name)
  removeCaseInsensitive(guildState[excludedKeys[index]], name)
end

local function rebuildActualLists()
  local friendMap, enemyMap, blackMap = {}, {}, {}
  local function addMap(map, list, excluded)
    local excludedSet = toSet(excluded)
    for _, name in ipairs(list or {}) do
      local key = lower(name)
      if key ~= "" and not excludedSet[key] and not map[key] then map[key] = trim(name) end
    end
  end

  addMap(friendMap, guildState.manualFriends, {})
  addMap(friendMap, guildState.managedFriends, guildState.excludedFriends)
  addMap(enemyMap, guildState.manualEnemies, {})
  addMap(enemyMap, guildState.managedEnemies, guildState.excludedEnemies)
  addMap(blackMap, guildState.manualBlacklist, {})
  addMap(blackMap, guildState.managedBlacklist, guildState.excludedBlacklist)

  -- Friends are the safety override. A manual friend or own/ally guild member is
  -- never simultaneously treated as an enemy/blacklist target.
  for key, _ in pairs(friendMap) do
    enemyMap[key] = nil
    blackMap[key] = nil
  end

  replaceArray(config.friendList, sortedArrayFromMap(friendMap))
  replaceArray(config.enemyList, sortedArrayFromMap(enemyMap))
  replaceArray(config.blackList, sortedArrayFromMap(blackMap))
  clearCachedPlayers()
  refreshStatus()
end

local function guildSetSignature(friendNames, enemyNames)
  local f = normalizeNames(friendNames)
  local e = normalizeNames(enemyNames)
  table.sort(f, function(a,b) return lower(a) < lower(b) end)
  table.sort(e, function(a,b) return lower(a) < lower(b) end)
  return table.concat(f, "\n") .. "\n::ENEMIES::\n" .. table.concat(e, "\n")
end

local function mergeNames(a, b)
  local out = copyArray(a)
  for _, name in ipairs(b or {}) do addUnique(out, name) end
  return normalizeNames(out)
end

local function applyGuildManaged(friendNames, enemyNames, currentGuild)
  captureManualFromActual()
  friendNames = normalizeNames(friendNames)
  enemyNames = normalizeNames(enemyNames)
  local selfKey = lower(localPlayerName())
  local filteredFriends, filteredEnemies = {}, {}
  local friendSet = {}
  for _, name in ipairs(friendNames) do
    if lower(name) ~= selfKey then
      addUnique(filteredFriends, name)
      friendSet[lower(name)] = true
    end
  end
  for _, name in ipairs(enemyNames) do
    local key = lower(name)
    if key ~= selfKey and not friendSet[key] then addUnique(filteredEnemies, name) end
  end

  local signature = guildSetSignature(filteredFriends, filteredEnemies)
  if guildState.pendingSignature == signature then
    guildState.pendingCount = (tonumber(guildState.pendingCount) or 0) + 1
  else
    guildState.pendingSignature = signature
    guildState.pendingCount = 1
  end

  local newFriendSet = toSet(filteredFriends)
  local newEnemySet = toSet(filteredEnemies)
  local removalCandidate = false
  for _, name in ipairs(guildState.managedFriends or {}) do
    if not newFriendSet[lower(name)] then removalCandidate = true break end
  end
  if not removalCandidate then
    for _, name in ipairs(guildState.managedEnemies or {}) do
      if not newEnemySet[lower(name)] then removalCandidate = true break end
    end
  end

  local firstSync = guildState.hasSynced ~= true
  local confirmed = firstSync or not removalCandidate or (tonumber(guildState.pendingCount) or 0) >= 2
  if confirmed then
    guildState.managedFriends = filteredFriends
    guildState.managedEnemies = filteredEnemies
    guildState.managedBlacklist = copyArray(filteredEnemies)
    guildState.hasSynced = true
  else
    -- First sight of a changed roster: add newcomers immediately but wait for a
    -- second identical successful sync before removing old managed names.
    guildState.managedFriends = mergeNames(guildState.managedFriends, filteredFriends)
    guildState.managedEnemies = mergeNames(guildState.managedEnemies, filteredEnemies)
    guildState.managedBlacklist = mergeNames(guildState.managedBlacklist, filteredEnemies)
  end

  guildRuntime.currentGuild = trim(currentGuild)
  guildState.currentGuild = guildRuntime.currentGuild
  local okTime, textTime = pcall(function() return os.date("%H:%M") end)
  guildRuntime.lastSuccessText = okTime and textTime or "OK"
  guildState.lastSuccessText = guildRuntime.lastSuccessText
  rebuildActualLists()
  return confirmed
end

-- UI rendering -------------------------------------------------------------
local function openPlayerUrl(name)
  g_platform.openUrl(link .. urlEncode(name))
end

local function renderList(index)
  local list = listWidgets[index]
  if not list then return end
  for _, child in ipairs(list:getChildren() or {}) do child:destroy() end
  local playerList = playerTables[index]
  for _, name in ipairs(playerList) do
    local label = UI.createWidget("PlayerLabel", list)
    label:setText(name)
    if isManagedOnly(index, name) and label.setTooltip then label:setTooltip("Guild Sync") end
    label.remove.onClick = function()
      local managed = managedSetForIndex(index)[lower(name)] == true
      removeCaseInsensitive(playerList, name)
      if containsCaseInsensitive(manualTables[index], name) then
        removeCaseInsensitive(manualTables[index], name)
      end
      if managed then addExcluded(index, name) end
      label:destroy()
      clearCachedPlayers()
      refreshStatus()
    end
    label.onMouseRelease = function(widget, mousePos, mouseButton)
      if mouseButton == 2 then
        local child = rootWidget:recursiveGetChildByPos(mousePos)
        if child == widget then
          local menu = g_ui.createWidget('PopupMenu')
          menu:setId("blzMenu")
          menu:setGameMenu(true)
          menu:addOption('Check Player', function() openPlayerUrl(widget:getText()) end, "")
          menu:addOption('Copy Name', function() g_window.setClipboardText(widget:getText()) end, "")
          menu:display(mousePos)
          return true
        end
      end
    end
  end
end

local function renderAllLists()
  for i = 1, 3 do renderList(i) end
end

local function updateGuildUi()
  if not ListWindow or not ListWindow.settings then return end
  local settings = ListWindow.settings
  if settings.GuildSyncEnabled then settings.GuildSyncEnabled:setChecked(config.guildSyncEnabled ~= false) end
  if settings.GuildOwn then
    settings.GuildOwn:setText("Your Guild: " .. (guildRuntime.currentGuild ~= "" and guildRuntime.currentGuild or "None / unknown"))
  end
  if settings.GuildStatus then
    local last = guildRuntime.lastSuccessText ~= "" and (" | last " .. guildRuntime.lastSuccessText) or ""
    settings.GuildStatus:setText("Status: " .. guildRuntime.status .. last)
  end
  if settings.GuildEnemyGuilds then
    settings.GuildEnemyGuilds:setText("Enemy Guilds (" .. tostring(#guildRules.enemyGuilds) .. ")")
    if settings.GuildEnemyGuilds.setEnabled then settings.GuildEnemyGuilds:setEnabled(isGuildMaster()) end
  end
  if settings.GuildAllyGuilds then
    settings.GuildAllyGuilds:setText("Ally Guilds (" .. tostring(#guildRules.allyGuilds) .. ")")
    if settings.GuildAllyGuilds.setEnabled then settings.GuildAllyGuilds:setEnabled(isGuildMaster()) end
  end
end

local function setGuildStatus(text)
  guildRuntime.status = tostring(text or "")
  updateGuildUi()
end

-- HTTP synchronization ------------------------------------------------------
local startGuildSync
local function scheduleGuildSync(delay)
  guildRuntime.scheduleToken = guildRuntime.scheduleToken + 1
  local token = guildRuntime.scheduleToken
  if not schedule then return end
  schedule(math.max(0, tonumber(delay) or GUILD_SYNC_INTERVAL), function()
    if token ~= guildRuntime.scheduleToken then return end
    if startGuildSync then startGuildSync(false) end
  end)
end

local function fetchGuildQueue(requests, index, friendNames, enemyNames, done)
  if index > #requests then done(true, friendNames, enemyNames) return end
  local request = requests[index]
  HTTP.get(GUILD_BASE_URL .. "/guilds/" .. urlEncode(request.name), function(data, err)
    if err or type(data) ~= "string" then
      done(false, nil, nil, "HTTP " .. request.name)
      return
    end
    local members = parseGuildMembers(data)
    if not members then
      done(false, nil, nil, "Invalid guild page: " .. request.name)
      return
    end
    if request.friend then
      for _, name in ipairs(members) do addUnique(friendNames, name) end
    end
    if request.enemy then
      for _, name in ipairs(members) do addUnique(enemyNames, name) end
    end
    schedule(GUILD_HTTP_GAP, function()
      fetchGuildQueue(requests, index + 1, friendNames, enemyNames, done)
    end)
  end)
end

startGuildSync = function(manual)
  if guildRuntime.inProgress then
    setGuildStatus("Sync already running")
    return
  end
  if config.guildSyncEnabled == false and not manual then
    setGuildStatus("OFF")
    scheduleGuildSync(GUILD_SYNC_INTERVAL)
    return
  end
  if not HTTP or not HTTP.get then
    setGuildStatus("HTTP unavailable - keeping lists")
    scheduleGuildSync(GUILD_SYNC_RETRY)
    return
  end

  local selfName = localPlayerName()
  if selfName == "" then
    setGuildStatus("Player unavailable - keeping lists")
    scheduleGuildSync(GUILD_SYNC_RETRY)
    return
  end

  guildRuntime.inProgress = true
  setGuildStatus("Reading Pazzur...")
  HTTP.get(GUILD_BASE_URL .. "/characters/" .. urlEncode(selfName), function(data, err)
    if err or type(data) ~= "string" then
      guildRuntime.inProgress = false
      setGuildStatus("Offline - keeping last valid lists")
      scheduleGuildSync(GUILD_SYNC_RETRY)
      return
    end

    local ownGuild, validCharacter = parseCharacterGuild(data)
    if not validCharacter then
      guildRuntime.inProgress = false
      setGuildStatus("Invalid character page - keeping lists")
      scheduleGuildSync(GUILD_SYNC_RETRY)
      return
    end

    local requestMap, requests = {}, {}
    local function addGuildRequest(name, isFriendGuild, isEnemyGuild)
      local clean = trim(name)
      local key = lower(clean)
      if clean == "" then return end
      local row = requestMap[key]
      if not row then
        row = {name = clean, friend = false, enemy = false}
        requestMap[key] = row
        table.insert(requests, row)
      end
      if isFriendGuild then row.friend = true end
      if isEnemyGuild then row.enemy = true end
    end

    if ownGuild and ownGuild ~= "" then addGuildRequest(ownGuild, true, false) end
    for _, guildName in ipairs(guildRules.allyGuilds or {}) do addGuildRequest(guildName, true, false) end
    for _, guildName in ipairs(guildRules.enemyGuilds or {}) do addGuildRequest(guildName, false, true) end

    -- Friend role wins if a guild is accidentally configured in both groups.
    for _, row in ipairs(requests) do if row.friend then row.enemy = false end end

    fetchGuildQueue(requests, 1, {}, {}, function(ok, friends, enemies, why)
      guildRuntime.inProgress = false
      if not ok then
        setGuildStatus("Failed (" .. tostring(why or "web") .. ") - keeping lists")
        scheduleGuildSync(GUILD_SYNC_RETRY)
        return
      end
      local confirmed = applyGuildManaged(friends, enemies, ownGuild or "")
      renderAllLists()
      if confirmed then
        setGuildStatus("Synced: " .. tostring(#guildState.managedFriends) .. " friends / " .. tostring(#guildState.managedEnemies) .. " enemies")
        scheduleGuildSync(GUILD_SYNC_INTERVAL)
      else
        setGuildStatus("Roster changed - confirming removals in 2 min")
        scheduleGuildSync(GUILD_CONFIRM_RETRY)
      end
    end)
  end)
end

-- Window -------------------------------------------------------------------
rootWidget = g_ui.getRootWidget()
if rootWidget then
  ListWindow = UI.createWindow('PlayerListWindow', rootWidget)
  ListWindow:hide()

  UI.Button("Player Lists", function()
    renderAllLists()
    updateGuildUi()
    ListWindow:show()
    ListWindow:raise()
    ListWindow:focus()
  end)

  ListWindow.settings.Members:setChecked(config.groupMembers)
  ListWindow.settings.Members.onClick = function(widget)
    config.groupMembers = not config.groupMembers
    if not config.groupMembers then clearCachedPlayers() end
    refreshStatus()
    widget:setChecked(config.groupMembers)
  end

  ListWindow.settings.Outfit:setChecked(config.outfits)
  ListWindow.settings.Outfit.onClick = function(widget)
    config.outfits = not config.outfits
    widget:setChecked(config.outfits)
    refreshStatus()
  end

  ListWindow.settings.NeutralsAreEnemy:setChecked(config.marks)
  ListWindow.settings.NeutralsAreEnemy.onClick = function(widget)
    config.marks = not config.marks
    widget:setChecked(config.marks)
  end

  ListWindow.settings.Highlight:setChecked(config.highlight)
  ListWindow.settings.Highlight.onClick = function(widget)
    config.highlight = not config.highlight
    widget:setChecked(config.highlight)
  end

  ListWindow.settings.AutoAdd:setChecked(config.autoAdd == true)
  ListWindow.settings.AutoAdd.onClick = function(widget)
    config.autoAdd = not config.autoAdd
    widget:setChecked(config.autoAdd)
  end

  ListWindow.settings.GuildSyncEnabled:setChecked(config.guildSyncEnabled ~= false)
  ListWindow.settings.GuildSyncEnabled.onClick = function(widget)
    config.guildSyncEnabled = not (config.guildSyncEnabled ~= false)
    widget:setChecked(config.guildSyncEnabled ~= false)
    if config.guildSyncEnabled then
      setGuildStatus("Queued")
      scheduleGuildSync(1000)
    else
      setGuildStatus("OFF - existing lists kept")
    end
  end

  ListWindow.settings.GuildSyncNow.onClick = function()
    guildRuntime.scheduleToken = guildRuntime.scheduleToken + 1
    startGuildSync(true)
  end

  local function parseGuildEditor(text)
    text = tostring(text or ""):gsub(",", "\n")
    local out = {}
    for line in text:gmatch("[^\r\n]+") do addUnique(out, trim(line)) end
    return normalizeNames(out, MAX_GUILDS_PER_GROUP)
  end

  local function saveRuleGroup(key, values)
    if not isGuildMaster() then
      warn("[Guild Sync] Solo " .. GUILD_CONFIG_MASTER .. " puede publicar Guild Rules.")
      return
    end
    local nextRules = normalizeGuildRules(guildRules)
    nextRules[key] = normalizeNames(values, MAX_GUILDS_PER_GROUP)
    if guildRulesSignature(nextRules) == guildRulesSignature(guildRules) then
      setGuildStatus("Rules unchanged - no PM sent")
      return
    end
    nextRules.revision = math.max(1, tonumber(guildRules.revision) or 1) + 1
    local ok = writeGuildRules(nextRules)
    guildRules = nextRules
    updateGuildUi()
    broadcastGuildRules()
    setGuildStatus("Rules rev " .. tostring(guildRules.revision) .. " queued (15s PM gap)")
    if not ok then warn("[Guild Sync] No se pudo escribir " .. GUILD_RULES_PATH) end
    guildRuntime.scheduleToken = guildRuntime.scheduleToken + 1
    scheduleGuildSync(1000)
  end

  ListWindow.settings.GuildEnemyGuilds.onClick = function()
    if not isGuildMaster() then warn("[Guild Sync] Solo " .. GUILD_CONFIG_MASTER .. " puede editar guilds enemigas.") return end
    UI.MultilineEditorWindow(table.concat(guildRules.enemyGuilds, "\n"), {
      title = "Guild Sync - Enemy Guilds",
      description = "Una guild por linea. Sus miembros van a Enemies + BlackList. Maximo " .. tostring(MAX_GUILDS_PER_GROUP) .. "."
    }, function(text) saveRuleGroup("enemyGuilds", parseGuildEditor(text)) end)
  end

  ListWindow.settings.GuildAllyGuilds.onClick = function()
    if not isGuildMaster() then warn("[Guild Sync] Solo " .. GUILD_CONFIG_MASTER .. " puede editar guilds aliadas.") return end
    UI.MultilineEditorWindow(table.concat(guildRules.allyGuilds, "\n"), {
      title = "Guild Sync - Ally Guilds",
      description = "Una guild por linea. Sus miembros van a Friends. Tu guild actual ya se detecta automaticamente."
    }, function(text) saveRuleGroup("allyGuilds", parseGuildEditor(text)) end)
  end

  local TabBar = ListWindow.tmpTabBar
  TabBar:setContentWidget(ListWindow.tmpTabContent)

  for v = 1, 3 do
    local listPanel = g_ui.createWidget("tPanel")
    local playerList = playerTables[v]
    listPanel:setId(tabs[v] .. "Tab")
    TabBar:addTab(tabs[v], listPanel)
    local addButton = listPanel.add
    local nameTab = listPanel.name
    local list = listPanel.list
    listWidgets[v] = list

    local tabButton = TabBar.buttonsPanel:getChildren()[v]
    tabButton.onStyleApply = function(widget)
      if TabBar:getCurrentTab() == widget then widget:setColor(colors[v]) end
    end

    addButton.onClick = function()
      local names = string.split(nameTab:getText(), ",")
      if #names == 0 then warn("vBot[PlayerList]: Name is missing!") return end
      for i = 1, #names do
        local name = trim(names[i])
        if name == "" then
          warn("vBot[PlayerList]: Name is missing!")
        else
          clearExcluded(v, name)
          if addUnique(manualTables[v], name) then
            addUnique(playerList, name)
          else
            warn("vBot[PlayerList]: Player " .. name .. " is already added!")
          end
        end
      end
      nameTab:setText("")
      rebuildActualLists()
      renderAllLists()
    end

    nameTab.onKeyPress = function(widget, keyCode, keyboardModifiers)
      if keyCode ~= 5 then return false end
      addButton.onClick()
      return true
    end
  end

  function addBlackListPlayer(name)
    if addUnique(guildState.manualBlacklist, name) then
      addUnique(config.blackList, name)
      rebuildActualLists()
      renderList(3)
    end
  end

  updateGuildUi()
  renderAllLists()
end

-- Guild Rules PM protocol ---------------------------------------------------
local ruleBuffers = {}
local function applyIncomingGuildRules(incoming)
  if not incoming then return end
  local localRevision = math.max(1, tonumber(guildRules.revision) or 1)
  if incoming.revision < localRevision then return end
  local ok = writeGuildRules(incoming)
  guildRules = normalizeGuildRules(incoming)
  updateGuildUi()
  setGuildStatus("Rules synced from " .. GUILD_CONFIG_MASTER .. " (rev " .. tostring(guildRules.revision) .. ")")
  if not ok then warn("[Guild Sync] Rules recibidas; cache local no pudo escribirse.") end
  guildRuntime.scheduleToken = guildRuntime.scheduleToken + 1
  scheduleGuildSync(1000)
end

onTalk(function(name, level, mode, text, channelId, pos)
  if not name or not text then return end
  if text:sub(1, #GUILD_SYNC_PREFIX + 1) ~= GUILD_SYNC_PREFIX .. "|" then return end

  local requesterRevision = text:match("^" .. GUILD_SYNC_PREFIX .. "|Q|(%d+)$")
  if requesterRevision then
    if isGuildMaster() then
      local requesterKey = lower(name)
      local allowed = false
      for _, participant in ipairs(guildParticipants()) do
        if lower(participant) == requesterKey then allowed = true break end
      end
      if allowed and tonumber(requesterRevision) ~= math.max(1, tonumber(guildRules.revision) or 1) then
        sendGuildRulesTo(name)
      end
    end
    return
  end

  if lower(name) ~= lower(GUILD_CONFIG_MASTER) then return end

  local singleRevision, singlePayload = text:match("^" .. GUILD_SYNC_PREFIX .. "|C|(%d+)|(.*)$")
  if singleRevision then
    applyIncomingGuildRules(decodeGuildRulePayload(singlePayload, tonumber(singleRevision) or 1))
    return
  end

  local beginRevision, total = text:match("^" .. GUILD_SYNC_PREFIX .. "|B|(%d+)|(%d+)$")
  if beginRevision then
    local rev = tonumber(beginRevision) or 1
    ruleBuffers[rev] = {total = tonumber(total) or 0, chunks = {}, started = now}
    return
  end

  local chunkRevision, index, chunk = text:match("^" .. GUILD_SYNC_PREFIX .. "|X|(%d+)|(%d+)|(.*)$")
  if chunkRevision then
    local rev = tonumber(chunkRevision) or 1
    local stage = ruleBuffers[rev]
    if stage then
      stage.started = now
      stage.chunks[tonumber(index) or 0] = chunk or ""
    end
    return
  end

  local endRevision = text:match("^" .. GUILD_SYNC_PREFIX .. "|E|(%d+)$")
  if endRevision then
    local rev = tonumber(endRevision) or 1
    local stage = ruleBuffers[rev]
    ruleBuffers[rev] = nil
    if not stage or stage.total < 1 then return end
    local parts = {}
    for i = 1, stage.total do if stage.chunks[i] == nil then return end; table.insert(parts, stage.chunks[i]) end
    applyIncomingGuildRules(decodeGuildRulePayload(table.concat(parts, ""), rev))
    return
  end
end)

-- One silent revision request at startup. No repeated polling over PM.
if schedule then
  local stagger = 0
  local name = localPlayerName()
  for i = 1, #name do stagger = (stagger + string.byte(name, i) * i) % 12000 end
  schedule(GUILD_RULE_BOOT_DELAY + stagger, function()
    if not isGuildMaster() then
      talkPrivate(GUILD_CONFIG_MASTER, GUILD_SYNC_PREFIX .. "|Q|" .. tostring(math.max(1, tonumber(guildRules.revision) or 1)))
    end
  end)

  local bootDelay = 12000 + stagger
  scheduleGuildSync(bootDelay)
end

-- Existing Player List events ----------------------------------------------
onTextMessage(function(mode, text)
  if not config.autoAdd then return end
  if CaveBot.isOff() or TargetBot.isOff() then return end
  if not text:find("Warning! The murder of") then return end
  text = string.split(text, "Warning! The murder of ")[1]
  text = string.split(text, " was not justified.")[1]
  addBlackListPlayer(text)
end)

onCreatureAppear(function(creature)
  checkStatus(creature)
end)

onPlayerPositionChange(function(x, y)
  if x.z ~= y.z then
    schedule(20, function() refreshStatus() end)
  end
end)
