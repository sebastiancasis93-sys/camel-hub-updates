setDefaultTab("Tools")
local panelName = "combobot"
local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('ComboBot')

  Button
    id: combos
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup

]])
ui:setId(panelName)

if not storage[panelName] then
  storage[panelName] = {
    enabled = false,
    onSayEnabled = false,
    onShootEnabled = false,
    onCastEnabled = false,
    followLeaderEnabled = false,
    attackLeaderTargetEnabled = false,
    attackSpellEnabled = false,
    attackItemToggle = false,
    sayLeader = "",
    shootLeader = "",
    castLeader = "",
    sayPhrase = "",
    spell = "",
    serverLeader = "",
    item = 3155,
    attack = "",
    follow = "",
    commandsEnabled = true,
    serverEnabled = false,
    serverLeaderTarget = false,
    serverTriggers = true
  }
end

local config = storage[panelName]

ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
config.enabled = not config.enabled
widget:setOn(config.enabled)
end

AthalarModules = AthalarModules or {}
AthalarModules.ComboBot = {
  isOn = function() return config.enabled == true end,
  setOn = function() config.enabled = true; ui.title:setOn(true) end,
  setOff = function() config.enabled = false; ui.title:setOn(false) end
}

ui.combos.onClick = function(widget)
  comboWindow:show()
  comboWindow:raise()
  comboWindow:focus()
end

rootWidget = g_ui.getRootWidget()
if rootWidget then
  comboWindow = UI.createWindow('ComboWindow', rootWidget)
  comboWindow:hide()

  -- bot item

  comboWindow.actions.attackItem:setItemId(config.item)
  comboWindow.actions.attackItem.onItemChange = function(widget)
    config.item = widget:getItemId()
  end

  -- switches

  comboWindow.actions.commandsToggle:setOn(config.commandsEnabled)
  comboWindow.actions.commandsToggle.onClick = function(widget)
    config.commandsEnabled = not config.commandsEnabled
    widget:setOn(config.commandsEnabled)
  end

  comboWindow.server.botServerToggle:setOn(config.serverEnabled)
  comboWindow.server.botServerToggle.onClick = function(widget)
    config.serverEnabled = not config.serverEnabled
    widget:setOn(config.serverEnabled)
  end

  comboWindow.server.Triggers:setOn(config.serverTriggers)
  comboWindow.server.Triggers.onClick = function(widget)
    config.serverTriggers = not config.serverTriggers
    widget:setOn(config.serverTriggers)
  end

  comboWindow.server.targetServerLeaderToggle:setOn(config.serverLeaderTarget)
  comboWindow.server.targetServerLeaderToggle.onClick = function(widget)
    config.serverLeaderTarget = not config.serverLeaderTarget
    widget:setOn(config.serverLeaderTarget)
  end  

  -- buttons
  comboWindow.closeButton.onClick = function(widget)
    comboWindow:hide()
  end

  -- combo boxes

  comboWindow.actions.followLeader:setOption(config.follow)
  comboWindow.actions.followLeader.onOptionChange = function(widget)
    config.follow = widget:getCurrentOption().text
  end

  comboWindow.actions.attackLeaderTarget:setOption(config.attack)
  comboWindow.actions.attackLeaderTarget.onOptionChange = function(widget)
    config.attack = widget:getCurrentOption().text
  end

  -- checkboxes
  comboWindow.trigger.onSayToggle:setChecked(config.onSayEnabled)
  comboWindow.trigger.onSayToggle.onClick = function(widget)
    config.onSayEnabled = not config.onSayEnabled
    widget:setChecked(config.onSayEnabled)
  end

  comboWindow.trigger.onShootToggle:setChecked(config.onShootEnabled)
  comboWindow.trigger.onShootToggle.onClick = function(widget)
    config.onShootEnabled = not config.onShootEnabled
    widget:setChecked(config.onShootEnabled)
  end

  comboWindow.trigger.onCastToggle:setChecked(config.onCastEnabled)
  comboWindow.trigger.onCastToggle.onClick = function(widget)
    config.onCastEnabled = not config.onCastEnabled
    widget:setChecked(config.onCastEnabled)
  end  

  comboWindow.actions.followLeaderToggle:setChecked(config.followLeaderEnabled)
  comboWindow.actions.followLeaderToggle.onClick = function(widget)
    config.followLeaderEnabled = not config.followLeaderEnabled
    widget:setChecked(config.followLeaderEnabled)
  end
  
  comboWindow.actions.attackLeaderTargetToggle:setChecked(config.attackLeaderTargetEnabled)
  comboWindow.actions.attackLeaderTargetToggle.onClick = function(widget)
    config.attackLeaderTargetEnabled = not config.attackLeaderTargetEnabled
    widget:setChecked(config.attackLeaderTargetEnabled)
  end 
  
  comboWindow.actions.attackSpellToggle:setChecked(config.attackSpellEnabled)
  comboWindow.actions.attackSpellToggle.onClick = function(widget)
    config.attackSpellEnabled = not config.attackSpellEnabled
    widget:setChecked(config.attackSpellEnabled)
  end
  
  comboWindow.actions.attackItemToggle:setChecked(config.attackItemEnabled)
  comboWindow.actions.attackItemToggle.onClick = function(widget)
    config.attackItemEnabled = not config.attackItemEnabled
    widget:setChecked(config.attackItemEnabled)
  end
  
  -- text edits
  comboWindow.trigger.onSayLeader:setText(config.sayLeader)
  comboWindow.trigger.onSayLeader.onTextChange = function(widget, text)
    config.sayLeader = text
  end
  
  comboWindow.trigger.onShootLeader:setText(config.shootLeader)
  comboWindow.trigger.onShootLeader.onTextChange = function(widget, text)
    config.shootLeader = text
  end

  comboWindow.trigger.onCastLeader:setText(config.castLeader)
  comboWindow.trigger.onCastLeader.onTextChange = function(widget, text)
    config.castLeader = text
  end

  comboWindow.trigger.onSayPhrase:setText(config.sayPhrase)
  comboWindow.trigger.onSayPhrase.onTextChange = function(widget, text)
    config.sayPhrase = text
  end
  
  comboWindow.actions.attackSpell:setText(config.spell)
  comboWindow.actions.attackSpell.onTextChange = function(widget, text)
    config.spell = text
  end

  comboWindow.server.botServerLeader:setText(config.serverLeader)
  comboWindow.server.botServerLeader.onTextChange = function(widget, text)
    config.serverLeader = text
  end  
end

-- bot server
-- [[ join party made by Frosty ]] --

local shouldCloseWindow = false
local firstInvitee = true
local isInComboTeam = false
macro(10, function()
  if shouldCloseWindow and config.serverEnabled and config.enabled then
    local channelsWindow = modules.game_console.channelsWindow
    if channelsWindow then
      local child = channelsWindow:getChildById("buttonCancel")
      if child then
        child:onClick()
        shouldCloseWindow = false
        isInComboTeam = true
      end
    end
  end
end)

comboWindow.server.partyButton.onClick = function(widget)
  if config.serverEnabled and config.enabled then 
    if config.serverLeader:len() > 0 and storage.BotServerChannel:len() > 0 then 
      talkPrivate(config.serverLeader, "request invite " .. storage.BotServerChannel)
    else
      error("Request failed. Lack of data.")
    end
  end
end

onTextMessage(function(mode, text)
  if config.serverEnabled and config.enabled then
    if mode == 20 then
      if string.find(text, "invited you to") then
        local regex = "[a-zA-Z]*"
        local regexData = regexMatch(text, regex)
        if regexData[1][1]:lower() == config.serverLeader:lower() then
          local leader = getCreatureByName(regexData[1][1])
          if leader then
            g_game.partyJoin(leader:getId())
            g_game.requestChannels()
            g_game.joinChannel(1)
            shouldCloseWindow = true
          end
        end
      end
    end
  end
end)

onTalk(function(name, level, mode, text, channelId, pos)
  if config.serverEnabled and config.enabled then
    if mode == 4 then
      if string.find(text, "request invite") then
        local access = string.match(text, "%d.*")
        if access and access == storage.BotServerChannel then
          local minion = getCreatureByName(name)
          if minion then
            g_game.partyInvite(minion:getId())
            if firstInvitee then
              g_game.requestChannels()
              g_game.joinChannel(1)
              shouldCloseWindow = true
              firstInvitee = false
            end
          end
        else
          talkPrivate(name, "Incorrect access key!")
        end
      end
    end
  end
  -- [[ End of Frosty's Code ]] -- 
  if config.enabled and config.enabled then
    if name:lower() == config.sayLeader:lower() and string.find(text, config.sayPhrase) and config.onSayEnabled then
      startCombo = true
    end
    if (config.castLeader and name:lower() == config.castLeader:lower()) and isAttSpell(text) and config.onCastEnabled then
      startCombo = true
    end
  end
  if config.enabled and config.commandsEnabled and (config.shootLeader and name:lower() == config.shootLeader:lower()) or (config.sayLeader and name:lower() == config.sayLeader:lower()) or (config.castLeader and name:lower() == config.castLeader:lower()) then
    if string.find(text, "ue") then
      say(config.spell)
    elseif string.find(text, "sd") then
      local params = string.split(text, ",")
      if #params == 2 then
        local target = params[2]:trim()
        if getCreatureByName(target) then
          useWith(3155, getCreatureByName(target))
        end
      end
    elseif string.find(text, "att") then
      local attParams = string.split(text, ",")
      if #attParams == 2 then
        local atTarget = attParams[2]:trim()
        if getCreatureByName(atTarget) and config.attack == "COMMAND TARGET" then
          g_game.attack(getCreatureByName(atTarget))
        end
      end
    end
  end
  if isAttSpell(text) and config.enabled and config.serverEnabled then
    BotServer.send("trigger", "start")
  end
end)

onMissle(function(missle)
  if config.enabled and config.onShootEnabled then 
    if not config.shootLeader or config.shootLeader:len() == 0 then
      return
    end
    local src = missle:getSource()
    if src.z ~= posz() then
      return
    end
    local from = g_map.getTile(src)
    local to = g_map.getTile(missle:getDestination())
    if not from or not to then
      return
    end
    local fromCreatures = from:getCreatures()
    local toCreatures = to:getCreatures()
    if #fromCreatures ~= 1 or #toCreatures ~= 1 then
      return
    end
    local c1 = fromCreatures[1]
    local t1 = toCreatures[1]
    leaderTarget = t1
    if c1:getName():lower() == config.shootLeader:lower() then
      if config.attackItemEnabled and config.item and config.item > 100 and findItem(config.item) then
        useWith(config.item, t1)
      end
      if config.attackSpellEnabled and config.spell:len() > 1 then
        say(config.spell)
      end 
    end
  end
end)

macro(10, function()
  if not config.enabled or not config.attackLeaderTargetEnabled then return end
  if leaderTarget and config.attack == "LEADER TARGET" then
    if not getTarget() or (getTarget() and getTarget():getName() ~= leaderTarget:getName()) then
      g_game.attack(leaderTarget)
    end
  end
  if config.enabled and config.serverEnabled and config.attack == "SERVER LEADER TARGET" and serverTarget then
    if serverTarget and not getTarget() or (getTarget() and getTarget():getname() ~= serverTarget)
    then
      g_game.attack(serverTarget)
    end
  end
end)


-- ================================================================
-- Camel Hub Fast Follow
-- Common ComboBot follow engine for every character.
--
-- Stock ComboBot waited until player:isWalking() became false before
-- calculating the leader's newest position. That creates a visible
-- stop/recalculate/step rhythm, especially on fast characters.
--
-- This version refreshes the leader position continuously and lets
-- OTCv8's walk() layer queue/prewalk the next direction while the
-- current step is still finishing.
-- ================================================================

local toFollow
local toFollowPos = {}
local lastFollowDir = nil
local lastFollowWalk = 0

local FOLLOW_INTERVAL = 50
local FOLLOW_REISSUE_MS = 80
local FOLLOW_MAX_DISTANCE = 20

local function resolveFollowName()
  if leaderTarget and config.follow == "LEADER TARGET" and leaderTarget:isPlayer() then
    return leaderTarget:getName()
  elseif config.follow == "SERVER LEADER TARGET" and config.serverLeader:len() ~= 0 then
    if type(serverTarget) == "string" then
      return serverTarget
    elseif serverTarget and serverTarget.getName then
      return serverTarget:getName()
    end
  elseif config.follow == "SERVER LEADER" and config.serverLeader:len() ~= 0 then
    return config.serverLeader
  elseif config.follow == "LEADER" then
    if config.onSayEnabled and config.sayLeader:len() ~= 0 then
      return config.sayLeader
    elseif config.onCastEnabled and config.castLeader:len() ~= 0 then
      return config.castLeader
    elseif config.onShootEnabled and config.shootLeader:len() ~= 0 then
      return config.shootLeader
    end
  end
  return nil
end

local function refreshFollowPosition(name)
  if not name or name == "" then return end
  local target = getCreatureByName(name)
  if target then
    local tpos = target:getPosition()
    if tpos then
      toFollowPos[tpos.z] = tpos
    end
  end
end

macro(FOLLOW_INTERVAL, function()
  if not config.enabled or not config.followLeaderEnabled then
    toFollow = nil
    lastFollowDir = nil
    return
  end

  toFollow = resolveFollowName()
  if not toFollow then
    lastFollowDir = nil
    return
  end

  -- Always refresh visible leader position, even while already walking.
  refreshFollowPosition(toFollow)

  local p = toFollowPos[posz()]
  if not p then return end

  local myPos = player:getPosition()
  if not myPos or myPos.z ~= p.z then return end

  local dist = math.max(
    math.abs(myPos.x - p.x),
    math.abs(myPos.y - p.y)
  )

  -- Standard ComboBot behavior: stay within one sqm of the leader.
  if dist <= 1 then
    lastFollowDir = nil
    return
  end

  local path = getPath(myPos, p, FOLLOW_MAX_DISTANCE, {
    ignoreNonPathable = true,
    precision = 1,
    ignoreStairs = false
  })

  if not path or not path[1] then
    return
  end

  local dir = path[1]

  -- Avoid pointless repeated calls for the exact same direction inside
  -- a tiny window, while still reacting immediately when the leader turns.
  if dir == lastFollowDir and now - lastFollowWalk < FOLLOW_REISSUE_MS then
    return
  end

  local ok = pcall(function()
    walk(dir, 0)
  end)

  if not ok then
    -- Compatibility fallback for clients where the global walk helper differs.
    pcall(function()
      g_game.walk(dir, true)
    end)
  end

  lastFollowDir = dir
  lastFollowWalk = now
end)

onCreaturePositionChange(function(creature, oldPos, newPos)
  if not creature or not newPos or not toFollow then return end
  if creature:getName():lower() == tostring(toFollow):lower() then
    -- Save every floor position. When the leader goes through stairs/holes,
    -- the follower can still reach the last known position on its current floor.
    toFollowPos[newPos.z] = newPos
    if oldPos and oldPos.z ~= newPos.z then
      toFollowPos[oldPos.z] = oldPos
    end
  end
end)

local timeout = now
macro(10, function()
  if config.enabled and startCombo then
    if config.attackItemEnabled and config.item and config.item > 100 and findItem(config.item) then
      useWith(config.item, getTarget())
    end
    if config.attackSpellEnabled and config.spell:len() > 1 then
      say(config.spell)
    end
    startCombo = false
  end
  -- attack part / server
  if BotServer._websocket and config.enabled and config.serverEnabled then
    if target() and now - timeout > 500 then
      targetPos = target():getName()
      BotServer.send("target", targetPos)
      timeout = now
    end
  end
end)

onUseWith(function(pos, itemId, target, subType)
  if BotServer._websocket and itemId == 3155 then
    BotServer.send("useWith", target:getPosition())
  end
end)

if BotServer._websocket and config.enabled and config.serverEnabled then
  BotServer.listen("trigger", function(name, message)
    if message == "start" and name:lower() ~= player:getName():lower() and name:lower() == config.serverLeader:lower() and config.serverTriggers then
      startCombo = true
    end
  end)
  BotServer.listen("target", function(name, message)
    if name:lower() ~= player:getName():lower() and name:lower() == config.serverLeader:lower() then
      if not target() or target():getName() == getCreatureByName(message) then
        if config.serverLeaderTarget then
          serverTarget = getCreatureByName(message)
          g_game.attack(getCreatureByName(message))
        end
      end
    end
  end)
  BotServer.listen("useWith", function(name, message)
   local tile = g_map.getTile(message)
   if config.serverTriggers and name:lower() ~= player:getName():lower() and name:lower() == config.serverLeader:lower() and config.attackItemEnabled and config.item and findItem(config.item) then
    useWith(config.item, tile:getTopUseThing())
   end
  end)
end