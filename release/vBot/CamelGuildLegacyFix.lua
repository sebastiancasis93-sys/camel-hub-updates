---@diagnostic disable: undefined-global
-- Camel Hub / Gampi Guild Legacy Macro Fix SAFE
-- Applies to ALL profiles used by Gampi.
--
-- IMPORTANT:
-- If "Auto Boost Guild" / "Auto Haste Guild" already exist in the active
-- profile, this module DOES NOT rewrite their callback, timeout or state.
-- It leaves the proven profile macros exactly as they were created.
--
-- If a Gampi profile does not contain them, this module creates them with
-- the same improved logic and the same names used by the existing icons.

local function isGampi()
  local okName, playerName = pcall(function()
    return player and player:getName()
  end)

  if okName and tostring(playerName or ""):lower() == "gampi" then
    return true
  end

  local okCfg, configName = pcall(function()
    return modules.game_bot.contentsPanel.config:getCurrentOption().text
  end)

  return okCfg and tostring(configName or ""):lower() == "gampi"
end

if not isGampi() then
  return
end

local sharedNextCastAt = 0
local boostCooldowns = {}
local hasteCooldowns = {}

local function isGuildAlly(c)
  if not c or not c:isPlayer() or c:isLocalPlayer() then
    return false
  end

  local okFriend, friend = pcall(function()
    return isFriend(c)
  end)

  if okFriend and friend == true then
    return true
  end

  local okEmblem, emblem = pcall(function()
    return c:getEmblem()
  end)

  return okEmblem and emblem == 1
end

local function canCast()
  return now >= sharedNextCastAt
end

local function registerCast()
  sharedNextCastAt = now + 2000
end

local function boostCallback()
  if not canCast() then return end

  for _, c in pairs(getSpectators()) do
    if isGuildAlly(c) then
      local name = c:getName()

      if now >= (boostCooldowns[name] or 0) then
        say('exura boost "' .. name .. '"')
        boostCooldowns[name] = now + 11000
        registerCast()
        return
      end
    end
  end
end

local function hasteCallback()
  if not canCast() then return end

  for _, c in pairs(getSpectators()) do
    if isGuildAlly(c) then
      local name = c:getName()

      if now >= (hasteCooldowns[name] or 0) then
        say('exura haste "' .. name .. '"')
        hasteCooldowns[name] = now + 4000
        registerCast()
        return
      end
    end
  end
end

local function registryMacro(name)
  if not AthalarMacroRegistry or not AthalarMacroRegistry.byName then
    return nil
  end

  local list = AthalarMacroRegistry.byName[name]
  if type(list) ~= "table" or #list == 0 then
    return nil
  end

  return list[#list]
end

local function createLegacyMacro(name, callback)
  local parent = nil

  if CamelScriptGroups and type(CamelScriptGroups.getMacroParent) == "function" then
    parent = CamelScriptGroups.getMacroParent()
  end

  return macro(600, name, callback, parent)
end

local function ensureLegacyMacro(name, callback)
  local object = registryMacro(name)

  -- SAFE: profile macro wins.
  -- Do not rewrite a macro that already exists.
  if object then
    return object
  end

  return createLegacyMacro(name, callback)
end

CamelGampiGuildLegacy = CamelGampiGuildLegacy or {}
CamelGampiGuildLegacy.version = "1.1-safe"
CamelGampiGuildLegacy.boost = ensureLegacyMacro("Auto Boost Guild", boostCallback)
CamelGampiGuildLegacy.haste = ensureLegacyMacro("Auto Haste Guild", hasteCallback)

CamelGampiGuildLegacy.getBoost = function()
  return registryMacro("Auto Boost Guild")
end

CamelGampiGuildLegacy.getHaste = function()
  return registryMacro("Auto Haste Guild")
end
