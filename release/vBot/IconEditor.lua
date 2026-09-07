---@diagnostic disable: undefined-global
setDefaultTab("Main")

local panelName = "athalarIconEditor"
storage[panelName] = storage[panelName] or { positions = {}, visible = {} }
storage[panelName].positions = storage[panelName].positions or {}
storage[panelName].visible = storage[panelName].visible or {}
local config = storage[panelName]

AthalarIconEditor = AthalarIconEditor or {}
AthalarIconEditor.registry = AthalarIconEditor.registry or {}
AthalarIconEditor.order = AthalarIconEditor.order or {}

local function getWidgetPosition(widget, fallbackX, fallbackY)
  if widget and widget.getPosition then
    local ok, p = pcall(function() return widget:getPosition() end)
    if ok and p then
      return tonumber(p.x) or fallbackX or 0, tonumber(p.y) or fallbackY or 0
    end
  end
  return fallbackX or 0, fallbackY or 0
end

local function moveWidget(widget, x, y)
  if not widget or not widget.move then return false end
  x, y = math.max(0, tonumber(x) or 0), math.max(0, tonumber(y) or 0)
  local ok = pcall(function() widget:move(x, y) end)
  return ok
end

function AthalarIconEditor.register(id, name, widget, defaultX, defaultY)
  if not id or not widget then return widget end
  if not AthalarIconEditor.registry[id] then
    table.insert(AthalarIconEditor.order, id)
  end

  AthalarIconEditor.registry[id] = {
    id = id,
    name = name or id,
    widget = widget,
    defaultX = tonumber(defaultX) or 0,
    defaultY = tonumber(defaultY) or 0
  }

  local saved = config.positions[id]
  if saved then
    moveWidget(widget, saved.x, saved.y)
  else
    moveWidget(widget, defaultX, defaultY)
    local x, y = getWidgetPosition(widget, defaultX, defaultY)
    config.positions[id] = {x = x, y = y}
  end

  if config.visible[id] == nil then config.visible[id] = true end
  if config.visible[id] then
    if widget.show then widget:show() end
  else
    if widget.hide then widget:hide() end
  end

  return widget
end

function AthalarIconEditor.saveCurrent()
  for _, id in ipairs(AthalarIconEditor.order) do
    local data = AthalarIconEditor.registry[id]
    if data and data.widget then
      local x, y = getWidgetPosition(data.widget, data.defaultX, data.defaultY)
      config.positions[id] = {x = x, y = y}
    end
  end
end

function AthalarIconEditor.resetDefaults()
  for _, id in ipairs(AthalarIconEditor.order) do
    local data = AthalarIconEditor.registry[id]
    if data and data.widget then
      moveWidget(data.widget, data.defaultX, data.defaultY)
      config.positions[id] = {x = data.defaultX, y = data.defaultY}
      config.visible[id] = true
      if data.widget.show then data.widget:show() end
    end
  end
end

local editorWindow
local function rebuildRows()
  if not editorWindow or not editorWindow.list then return end
  editorWindow.list:destroyChildren()

  for _, id in ipairs(AthalarIconEditor.order) do
    local data = AthalarIconEditor.registry[id]
    if data and data.widget then
      local row = UI.createWidget('AthalarIconEditorRow', editorWindow.list)
      local rowData = data
      local rowId = id
      local rowWidget = row
      row.name:setText(rowData.name)
      local x, y = getWidgetPosition(rowData.widget, rowData.defaultX, rowData.defaultY)
      row.x:setValue(x)
      row.y:setValue(y)
      if row.visible then
        row.visible:setChecked(config.visible[rowId] ~= false)
        row.visible.onClick = function(widget)
          local value = not widget:isChecked()
          widget:setChecked(value)
          config.visible[rowId] = value
          if value then
            if rowData.widget.show then rowData.widget:show() end
          else
            if rowData.widget.hide then rowData.widget:hide() end
          end
        end
      end
      row.apply.onClick = function()
        local newX = rowWidget.x:getValue()
        local newY = rowWidget.y:getValue()
        if moveWidget(rowData.widget, newX, newY) then
          config.positions[rowId] = {x = newX, y = newY}
        end
      end
    end
  end
end

local root = g_ui.getRootWidget()
if root then
  editorWindow = UI.createWindow('AthalarIconEditorWindow', root)
  editorWindow:hide()

  editorWindow.closeButton.onClick = function() editorWindow:hide() end
  editorWindow.refresh.onClick = rebuildRows
  editorWindow.save.onClick = function()
    AthalarIconEditor.saveCurrent()
    rebuildRows()
  end
  editorWindow.reset.onClick = function()
    AthalarIconEditor.resetDefaults()
    rebuildRows()
  end
end

local editorButton = UI.Button("Icon Editor", function()
  if not editorWindow then return end
  rebuildRows()
  editorWindow:show()
  editorWindow:raise()
  editorWindow:focus()
end)
if editorButton.setImageColor then editorButton:setImageColor('#2de0d7') end
if editorButton.setTooltip then
  editorButton:setTooltip("Editor de posiciones para los iconos flotantes de Athalar.")
end

-- Si mueves un icono directamente en el mapa, guardar su posicion automaticamente.
macro(1000, function()
  AthalarIconEditor.saveCurrent()
end)

UI.Separator()
