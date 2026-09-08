---@diagnostic disable: undefined-global
setDefaultTab("Main")

-- Camel Hub grouped in-game script editor.
-- Each group owns an independent code block.
--
-- EXP8 SAFE:
-- Los macros de los Script Groups se crean con macro() ORIGINAL, sin
-- interceptar ni cambiar argumentos. Una vez creados, solo movemos su
-- BotSwitch visual desde Main hacia la ventana In-Game Script Groups.
-- Esto evita romper firmas de macro/hotkey y conserva AthalarMacroRegistry.
local panelName = "camelScriptGroups"

local function defaultGroups(legacyCode)
  return {
    {name = "Actual",         enabled = true,  code = legacyCode or ""},
    {name = "PvP",            enabled = false, code = ""},
    {name = "Rescate",        enabled = false, code = ""},
    {name = "Hunt",           enabled = false, code = ""},
    {name = "Utilidades",     enabled = false, code = ""},
    {name = "Pruebas",        enabled = false, code = ""}
  }
end

if not storage[panelName] or type(storage[panelName]) ~= "table" then
  storage[panelName] = {groups = defaultGroups(storage.ingame_hotkeys or "")}
end

local config = storage[panelName]
if type(config.groups) ~= "table" or #config.groups == 0 then
  config.groups = defaultGroups(storage.ingame_hotkeys or "")
end

local defaults = defaultGroups("")
for i = 1, 6 do
  if type(config.groups[i]) ~= "table" then
    config.groups[i] = defaults[i]
  end

  local group = config.groups[i]
  group.name = tostring(group.name or defaults[i].name)
  group.enabled = group.enabled == true
  group.code = type(group.code) == "string" and group.code or ""
end

local root = g_ui.getRootWidget()
local editorWindow

if root then
  editorWindow = UI.createWindow("CamelScriptGroupsWindow", root)
  editorWindow:hide()

  editorWindow.closeButton.onClick = function()
    editorWindow:hide()
  end

  editorWindow.reloadButton.onClick = function()
    reload()
  end
end

local runtimeStatus = {}
local groupMacroCounts = {}

CamelScriptGroups = CamelScriptGroups or {}
CamelScriptGroups.getMacroParent = function()
  if editorWindow and editorWindow.macroList then
    return editorWindow.macroList
  end
  return nil
end

local function registryCount()
  if not AthalarMacroRegistry or type(AthalarMacroRegistry.entries) ~= "table" then
    return 0
  end
  return #AthalarMacroRegistry.entries
end

local function moveNewMacroSwitches(firstIndex, lastIndex)
  if not editorWindow or not editorWindow.macroList then return 0 end
  if not AthalarMacroRegistry or type(AthalarMacroRegistry.entries) ~= "table" then return 0 end

  local moved = 0

  for index = firstIndex, lastIndex do
    local entry = AthalarMacroRegistry.entries[index]
    local object = entry and entry.macro
    local switch = object and object.switch

    if switch and type(switch.setParent) == "function" then
      local ok = pcall(function()
        if switch.breakAnchors then
          switch:breakAnchors()
        end
        switch:setParent(editorWindow.macroList)
      end)

      if ok then
        moved = moved + 1
      else
        warn("[Camel Script Groups] No se pudo mover el switch: " .. tostring(entry and entry.name))
      end
    end
  end

  return moved
end

-- Ejecuta los grupos SIN reemplazar macro().
-- Después de cada grupo, detecta los macros nuevos registrados y mueve
-- únicamente sus switches visuales a la ventana.
for i, group in ipairs(config.groups) do
  groupMacroCounts[i] = 0

  if group.enabled and group.code:len() > 3 then
    local beforeCount = registryCount()
    local chunk, compileError = load(group.code, "camel_group_" .. i .. "_" .. group.name)

    if not chunk then
      runtimeStatus[i] = "ERROR"
      warn("[Camel Script Group: " .. group.name .. "] compile error: " .. tostring(compileError))
    else
      local ok, runError = pcall(chunk)

      if ok then
        local afterCount = registryCount()
        groupMacroCounts[i] = moveNewMacroSwitches(beforeCount + 1, afterCount)
        runtimeStatus[i] = "ON"
      else
        runtimeStatus[i] = "ERROR"
        warn("[Camel Script Group: " .. group.name .. "] runtime error: " .. tostring(runError))
      end
    end

  elseif group.enabled then
    runtimeStatus[i] = "EMPTY"
  else
    runtimeStatus[i] = "OFF"
  end
end

local function setStatusLabel(label, value)
  if not label then return end
  label:setText(value)

  if value == "ON" then
    label:setColor("green")
  elseif value == "ERROR" then
    label:setColor("red")
  elseif value == "EMPTY" then
    label:setColor("orange")
  else
    label:setColor("#aaaaaa")
  end
end

local function openGroupEditor(index)
  local group = config.groups[index]
  if not group then return end

  UI.MultilineEditorWindow(group.code or "", {
    title = "Script Group " .. index .. " - " .. (group.name or "Group"),
    description = "Macros in this group are isolated from the other groups. Save to store the code, then reload the bot."
  }, function(text)
    group.code = text or ""

    if index == 1 then
      storage.ingame_hotkeys = group.code
    end

    reload()
  end)
end

local function rebuildRows()
  if not editorWindow or not editorWindow.list then return end

  editorWindow.list:destroyChildren()

  for i, group in ipairs(config.groups) do
    local row = UI.createWidget("CamelScriptGroupRow", editorWindow.list)
    local index = i
    local rowGroup = group

    row.enabled:setChecked(rowGroup.enabled == true)
    row.name:setText(rowGroup.name)

    local status = runtimeStatus[index] or (rowGroup.enabled and "EMPTY" or "OFF")
    setStatusLabel(row.status, status)

    if row.count then
      row.count:setText(tostring(groupMacroCounts[index] or 0))
    end

    row.enabled.onClick = function(widget)
      local newValue = not widget:isChecked()
      widget:setChecked(newValue)
      rowGroup.enabled = newValue
      reload()
    end

    row.name.onTextChange = function(widget, text)
      rowGroup.name = tostring(text or "Group " .. index)
    end

    row.edit.onClick = function()
      openGroupEditor(index)
    end
  end
end

local button = UI.Button("In-Game Script Groups", function()
  if not editorWindow then return end

  rebuildRows()
  editorWindow:show()
  editorWindow:raise()
  editorWindow:focus()
end)

if button.setImageColor then
  button:setImageColor("#2de0d7")
end

if button.setTooltip then
  button:setTooltip(
    "Edita macros Lua por grupos. Los switches de macros activos " ..
    "se muestran dentro de esta ventana."
  )
end

UI.Separator()
