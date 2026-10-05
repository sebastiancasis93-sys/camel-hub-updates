---@diagnostic disable: undefined-global
-- Camel Slow PM Queue
-- Serializes non-urgent synchronization PMs so configuration broadcasts do not
-- create bursts that can trigger server anti-spam / movement penalties.

CamelSlowPM = CamelSlowPM or {}

local queueState = CamelSlowPM
queueState.items = type(queueState.items) == "table" and queueState.items or {}
queueState.running = queueState.running == true
queueState.nextAt = tonumber(queueState.nextAt) or 0

local DEFAULT_GAP = 15000

local function queueNow()
  return tonumber(now) or 0
end

local function normalizeItem(item)
  if type(item) ~= "table" then return nil end
  local recipient = tostring(item.recipient or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local message = tostring(item.message or "")
  if recipient == "" or message == "" then return nil end
  return {
    channel = tostring(item.channel or "default"),
    recipient = recipient,
    message = message,
    gapAfter = math.max(1000, tonumber(item.gapAfter) or DEFAULT_GAP),
    priority = tonumber(item.priority) or 0,
    guard = item.guard
  }
end

local pump
pump = function()
  if queueState.running then return end
  if #queueState.items == 0 then return end
  if not schedule then
    local item = table.remove(queueState.items, 1)
    if item then
      local allowed = true
      if type(item.guard) == "function" then
        local ok, value = pcall(item.guard)
        allowed = ok and value ~= false
      end
      if allowed then talkPrivate(item.recipient, item.message) end
      queueState.nextAt = queueNow() + (item.gapAfter or DEFAULT_GAP)
    end
    return
  end

  queueState.running = true
  local delay = math.max(0, (queueState.nextAt or 0) - queueNow())
  schedule(delay, function()
    queueState.running = false
    local item = table.remove(queueState.items, 1)
    if item then
      local allowed = true
      if type(item.guard) == "function" then
        local ok, value = pcall(item.guard)
        allowed = ok and value ~= false
      end
      if allowed then
        talkPrivate(item.recipient, item.message)
        queueState.nextAt = queueNow() + (item.gapAfter or DEFAULT_GAP)
      else
        queueState.nextAt = queueNow() + 100
      end
    end
    pump()
  end)
end

function queueState.enqueue(channel, recipient, message, gapAfter, guard)
  local item = normalizeItem({
    channel = channel,
    recipient = recipient,
    message = message,
    gapAfter = gapAfter,
    priority = 0,
    guard = guard
  })
  if not item then return false end
  table.insert(queueState.items, item)
  pump()
  return true
end

function queueState.replaceChannel(channel, items)
  channel = tostring(channel or "default")
  for i = #queueState.items, 1, -1 do
    if queueState.items[i].channel == channel then
      table.remove(queueState.items, i)
    end
  end
  local normalized = {}
  for _, raw in ipairs(items or {}) do
    raw.channel = channel
    local item = normalizeItem(raw)
    if item then table.insert(normalized, item) end
  end
  for _, item in ipairs(normalized) do
    local inserted = false
    for i, existing in ipairs(queueState.items) do
      if (item.priority or 0) > (existing.priority or 0) then
        table.insert(queueState.items, i, item)
        inserted = true
        break
      end
    end
    if not inserted then table.insert(queueState.items, item) end
  end
  pump()
  return true
end

function queueState.cancelChannel(channel)
  channel = tostring(channel or "default")
  for i = #queueState.items, 1, -1 do
    if queueState.items[i].channel == channel then
      table.remove(queueState.items, i)
    end
  end
end

function queueState.pending(channel)
  local count = 0
  for _, item in ipairs(queueState.items) do
    if not channel or item.channel == channel then count = count + 1 end
  end
  return count
end
