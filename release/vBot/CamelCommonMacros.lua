---@diagnostic disable: undefined-global
-- Camel Hub COMMON MACROS
-- Shared by every character.
--
-- This file owns:
--   F6              -> CaveBot + TargetBot ON/OFF
--   Anti-Push       -> SAFE version: ONLY 3031 Gold + 3035 Platinum
--   AFK Anti-PK     -> shared defensive/offensive fight-mode controller
--
-- Rescue/Summoner logic is intentionally NOT stored here.

CamelCommon = CamelCommon or {}

-- ================================================================
-- CAVE + TARGET
-- ================================================================

CamelCommon.CaveTarget = CamelCommon.CaveTarget or {}

function CamelCommon.CaveTarget.isOn()
  return CaveBot and TargetBot and CaveBot.isOn() and TargetBot.isOn()
end

function CamelCommon.CaveTarget.setOn()
  if CaveBot and CaveBot.setOn then CaveBot.setOn() end
  if TargetBot and TargetBot.setOn then TargetBot.setOn() end
end

function CamelCommon.CaveTarget.setOff()
  if CaveBot and CaveBot.setOff then CaveBot.setOff() end
  if TargetBot and TargetBot.setOff then TargetBot.setOff() end
end

function CamelCommon.CaveTarget.toggle()
  if not CaveBot or not TargetBot then
    warn("[Camel Hub] CaveBot/TargetBot not available.")
    return
  end

  if CaveBot.isOn() or TargetBot.isOn() then
    CamelCommon.CaveTarget.setOff()
    info("CaveBot + TargetBot: OFF")
  else
    CamelCommon.CaveTarget.setOn()
    info("CaveBot + TargetBot: ON")
  end
end

hotkey("F6", "On/Off CaveTarget", function()
  CamelCommon.CaveTarget.toggle()
end)

-- ================================================================
-- SAFE ANTI-PUSH
-- ================================================================
-- Canonical Camel Hub version.
-- It NEVER uses helmets/equipment or a configurable item list.
-- Only Gold Coin (3031) and Platinum Coin (3035).

local dropGold = false
local antiPushWanted = nil
if storage and storage._macros then
  antiPushWanted = storage._macros["Anti-Push"]
end

CamelCommon.AntiPush = macro(500, "Anti-Push", function()
  local me = g_game.getLocalPlayer()
  if not me then return end

  if dropGold then
    local gold = findItem(3031)
    if gold then
      g_game.move(gold, me:getPosition(), 1)
      dropGold = false
    end
  else
    local platinum = findItem(3035)
    if platinum then
      g_game.move(platinum, me:getPosition(), 1)
      dropGold = true
    end
  end

  delay(500)
end)

-- Respect the character's previous stored state.
-- New characters default to OFF for safety.
if CamelCommon.AntiPush then
  if antiPushWanted == true and CamelCommon.AntiPush.setOn then
    CamelCommon.AntiPush:setOn()
  elseif antiPushWanted ~= true and CamelCommon.AntiPush.setOff then
    CamelCommon.AntiPush:setOff()
  end
end

-- Backwards-compatible global used by some older Camel Hub icon files.
AthalarAntiPushMacro = CamelCommon.AntiPush

-- ================================================================
-- AFK ANTI-PK
-- ================================================================

local antiPkWanted = nil
if storage and storage._macros then
  antiPkWanted = storage._macros["AFK Anti-PK vBot"]
end

CamelCommon.AntiPK = macro(200, "AFK Anti-PK vBot", function()
  local me = g_game.getLocalPlayer()
  if not me then return end

  local playerAttackingMe = false

  for _, spec in pairs(getSpectators()) do
    if spec:isPlayer() and not spec:isLocalPlayer() then
      if spec:isTimedSquareVisible() then
        playerAttackingMe = true
        break
      end
    end
  end

  -- Player attacking us -> defensive mode.
  if playerAttackingMe then
    if g_game.getFightMode() ~= 3 then
      g_game.setFightMode(3)
    end
    return
  end

  -- Fighting a monster -> offensive mode.
  local target = g_game.getAttackingCreature()
  if target and target:isMonster() then
    if g_game.getFightMode() ~= 1 then
      g_game.setFightMode(1)
    end
  end
end)

-- Respect the character's previous stored state.
-- New characters default to OFF.
if CamelCommon.AntiPK then
  if antiPkWanted == true and CamelCommon.AntiPK.setOn then
    CamelCommon.AntiPK:setOn()
  elseif antiPkWanted ~= true and CamelCommon.AntiPK.setOff then
    CamelCommon.AntiPK:setOff()
  end
end
