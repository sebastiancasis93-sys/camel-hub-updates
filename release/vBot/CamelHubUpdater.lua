-- Camel Hub Updater v1.0.0
-- Generated from the CURRENT Athalar/Lemac/Tronchito/Gampi/Valyria builds.
-- Updates ONLY common whitelisted code.
-- Character profiles, storage, routes, icons and character macros are protected.

setDefaultTab("Main")

CamelHubUpdater = CamelHubUpdater or {}
CamelHubUpdater.clientVersion = "1.0.1"

local panelKey = "camelHubUpdater"
storage[panelKey] = storage[panelKey] or {}
local cfg = storage[panelKey]
cfg.version = cfg.version or "1.0.0"
cfg.manifestUrl = (cfg.manifestUrl and cfg.manifestUrl ~= "") and cfg.manifestUrl or "https://raw.githubusercontent.com/sebastiancasis93-sys/camel-hub-updates/main/manifest.json"
if cfg.autoReload == nil then cfg.autoReload = true end

local COMMON_PATHS = {
  ["cavebot/actions.lua"] = true,
  ["cavebot/bank.lua"] = true,
  ["cavebot/buy_supplies.lua"] = true,
  ["cavebot/cavebot.lua"] = true,
  ["cavebot/cavebot.otui"] = true,
  ["cavebot/clear_tile.lua"] = true,
  ["cavebot/config.lua"] = true,
  ["cavebot/config.otui"] = true,
  ["cavebot/d_withdraw.lua"] = true,
  ["cavebot/depositor.lua"] = true,
  ["cavebot/doors.lua"] = true,
  ["cavebot/editor.lua"] = true,
  ["cavebot/editor.otui"] = true,
  ["cavebot/example_functions.lua"] = true,
  ["cavebot/extension_template.lua"] = true,
  ["cavebot/imbuing.lua"] = true,
  ["cavebot/inbox_withdraw.lua"] = true,
  ["cavebot/lure.lua"] = true,
  ["cavebot/minimap.lua"] = true,
  ["cavebot/pos_check.lua"] = true,
  ["cavebot/recorder.lua"] = true,
  ["cavebot/sell_all.lua"] = true,
  ["cavebot/stand_lure.lua"] = true,
  ["cavebot/supply_check.lua"] = true,
  ["cavebot/tasker.lua"] = true,
  ["cavebot/travel.lua"] = true,
  ["cavebot/walking.lua"] = true,
  ["cavebot/withdraw.lua"] = true,
  ["targetbot/creature.lua"] = true,
  ["targetbot/creature_attack.lua"] = true,
  ["targetbot/creature_editor.lua"] = true,
  ["targetbot/creature_editor.otui"] = true,
  ["targetbot/creature_priority.lua"] = true,
  ["targetbot/looting.lua"] = true,
  ["targetbot/looting.otui"] = true,
  ["targetbot/target.lua"] = true,
  ["targetbot/target.otui"] = true,
  ["targetbot/walking.lua"] = true,
  ["vBot/AttackBot.lua"] = true,
  ["vBot/AttackBot.otui"] = true,
  ["vBot/BotServer.lua"] = true,
  ["vBot/BotServer.otui"] = true,
  ["vBot/CamelPots.lua"] = true,
  ["vBot/Conditions.lua"] = true,
  ["vBot/Conditions.otui"] = true,
  ["vBot/Containers.lua"] = true,
  ["vBot/Dropper.lua"] = true,
  ["vBot/Equipper.lua"] = true,
  ["vBot/FireBomb.lua"] = true,
  ["vBot/HealBot.lua"] = true,
  ["vBot/HealBot.otui"] = true,
  ["vBot/IconEditor.lua"] = true,
  ["vBot/IconEditor.otui"] = true,
  ["vBot/Sio.lua"] = true,
  ["vBot/TimerExecutor.lua"] = true,
  ["vBot/TimerExecutor.otui"] = true,
  ["vBot/ZoomMap.lua"] = true,
  ["vBot/alarms.lua"] = true,
  ["vBot/alarms.otui"] = true,
  ["vBot/analyzer.lua"] = true,
  ["vBot/analyzer.otui"] = true,
  ["vBot/cast_food.lua"] = true,
  ["vBot/cave_target_settings.lua"] = true,
  ["vBot/cave_target_settings.otui"] = true,
  ["vBot/cavebot.lua"] = true,
  ["vBot/cavebot_control_panel.lua"] = true,
  ["vBot/combo.lua"] = true,
  ["vBot/combo.otui"] = true,
  ["vBot/configs.lua"] = true,
  ["vBot/depositer_config.lua"] = true,
  ["vBot/depositer_config.otui"] = true,
  ["vBot/equip.lua"] = true,
  ["vBot/equipper.otui"] = true,
  ["vBot/exeta.lua"] = true,
  ["vBot/extras.lua"] = true,
  ["vBot/extras.otui"] = true,
  ["vBot/extrasPvp.lua"] = true,
  ["vBot/extrasPvp.otui"] = true,
  ["vBot/friend_healer.lua"] = true,
  ["vBot/friend_healer.otui"] = true,
  ["vBot/hold_target.lua"] = true,
  ["vBot/ingame_editor.otui"] = true,
  ["vBot/items.lua"] = true,
  ["vBot/main.lua"] = true,
  ["vBot/new_cavebot_lib.lua"] = true,
  ["vBot/npc_talk.lua"] = true,
  ["vBot/playerlist.lua"] = true,
  ["vBot/playerlist.otui"] = true,
  ["vBot/pushmax.lua"] = true,
  ["vBot/pushmax.otui"] = true,
  ["vBot/pvp_support.lua"] = true,
  ["vBot/quiver_label.lua"] = true,
  ["vBot/quiver_manager.lua"] = true,
  ["vBot/siolist.otui"] = true,
  ["vBot/spy_level.lua"] = true,
  ["vBot/supplies.lua"] = true,
  ["vBot/supplies.otui"] = true,
  ["vBot/tools.lua"] = true,
  ["vBot/vlib.lua"] = true,
  ["vBot/xeno_menu.lua"] = true,
  ["zFreeScripts/zAutoBuff.lua"] = true,
  ["zFreeScripts/z_Auto-Party.lua"] = true,
  ["vBot/CamelHubUpdater.lua"] = true,
}

local function normalizePath(path)
  path = tostring(path or ""):gsub("\\", "/")
  path = path:gsub("^/+", ""):gsub("/+$", "")
  return path
end

local function isAllowedPath(path)
  path = normalizePath(path)
  if path == "" or path:find("..", 1, true) then return false end
  return COMMON_PATHS[path] == true
end

local function getConfigName()
  local ok, name = pcall(function()
    return modules.game_bot.contentsPanel.config:getCurrentOption().text
  end)
  if ok and type(name) == "string" and name ~= "" then return name end
  return "CamelHub"
end

local function targetPath(rel)
  return "/bot/" .. getConfigName() .. "/" .. normalizePath(rel)
end

local function trim(s)
  return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function adler32(data)
  data = data or ""
  local MOD = 65521
  local a = 1
  local b = 0

  for i = 1, #data do
    a = (a + string.byte(data, i)) % MOD
    b = (b + a) % MOD
  end

  return string.format("%08x", b * 65536 + a)
end

local function verifyData(data, entry)
  data = data or ""

  if entry.size and tonumber(entry.size) ~= #data then
    return false, "Tamano invalido: " .. tostring(entry.path)
  end

  if entry.adler32 and tostring(entry.adler32) ~= "" then
    local actual = adler32(data)
    local expected = tostring(entry.adler32):lower()
    if actual ~= expected then
      return false, "Checksum invalido: " .. tostring(entry.path)
    end
    return true
  end

  return false, "Manifest sin checksum compatible: " .. tostring(entry.path)
end

local function readLocal(rel)
  local full = targetPath(rel)
  if not g_resources.fileExists(full) then return nil end
  local ok, data = pcall(function()
    return g_resources.readFileContents(full)
  end)
  if ok then return data end
  return nil
end

local function localMatches(entry)
  local rel = normalizePath(entry.path)
  if not isAllowedPath(rel) then return true end
  local data = readLocal(rel)
  if not data then return false end
  local ok = verifyData(data, entry)
  return ok == true
end

local function safeVersion(v)
  return tostring(v or "unknown"):gsub("[^%w%._%-]", "_")
end

local function ensureDir(path)
  if not g_resources.directoryExists(path) then
    pcall(function() g_resources.makeDir(path) end)
  end
end

local function backupFile(rel)
  local data = readLocal(rel)
  if not data then return end

  local root = "/bot/" .. getConfigName() .. "/_camelhub_backups"
  local folder = root .. "/from_" .. safeVersion(cfg.version)

  ensureDir(root)
  ensureDir(folder)

  local flat = normalizePath(rel):gsub("/", "__")
  pcall(function()
    g_resources.writeFileContents(folder .. "/" .. flat, data)
  end)
end

local ui = setupUI([[
Panel
  height: 100
  margin-top: 2

  Label
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    width: 108
    height: 18
    text-align: center
    font: verdana-11px-rounded
    background: #006060
    color: #ffffff
    text: CAMEL UPDATER

  Button
    id: check
    anchors.top: title.top
    anchors.left: title.right
    margin-left: 3
    width: 52
    height: 18
    text: Check

  Button
    id: update
    anchors.top: title.top
    anchors.left: check.right
    anchors.right: parent.right
    margin-left: 3
    height: 18
    text: Update

  Label
    id: urlLabel
    anchors.top: title.bottom
    anchors.left: parent.left
    margin-top: 4
    width: 42
    height: 18
    text: URL:

  TextEdit
    id: url
    anchors.top: urlLabel.top
    anchors.left: urlLabel.right
    anchors.right: parent.right
    height: 18
    text: ""

  Label
    id: status
    anchors.top: url.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 4
    height: 50
    text-align: center
    text-wrap: true
    font: verdana-11px-rounded
    background: #292A2A
    color: #cfd3d7
    text: Camel Hub 1.0.0
]])

ui.url:setText(cfg.manifestUrl or "https://raw.githubusercontent.com/sebastiancasis93-sys/camel-hub-updates/main/manifest.json")
ui.url.onTextChange = function(widget, text)
  cfg.manifestUrl = trim(text)
end

local lastManifest = nil
local installing = false

local function setStatus(text, color)
  ui.status:setText(tostring(text or ""))
  ui.status:setColor(color or "#cfd3d7")
end

local function validateManifest(manifest)
  if type(manifest) ~= "table" or type(manifest.files) ~= "table" then
    return false, "Manifest invalido"
  end

  if tostring(manifest.product or "") ~= "Camel Hub" then
    return false, "Manifest no pertenece a Camel Hub"
  end

  if tostring(manifest.channel or "stable") ~= "stable" then
    return false, "Canal no permitido"
  end

  for _, entry in ipairs(manifest.files) do
    local rel = normalizePath(entry.path)

    -- Strong rule: a manifest containing ANY non-common path is rejected.
    if not isAllowedPath(rel) then
      return false, "Ruta protegida/no permitida en manifest: " .. rel
    end

    if type(entry.url) ~= "string" or not entry.url:match("^https://") then
      return false, "URL invalida: " .. rel
    end

    if not entry.adler32 or tostring(entry.adler32) == "" then
      return false, "Falta checksum: " .. rel
    end

    if entry.size == nil then
      return false, "Falta size: " .. rel
    end
  end

  return true
end

local function pendingFiles(manifest)
  local pending = {}
  for _, entry in ipairs(manifest.files or {}) do
    local rel = normalizePath(entry.path)
    if isAllowedPath(rel) and not localMatches(entry) then
      table.insert(pending, entry)
    end
  end
  return pending
end

local function fetchManifest(callback)
  local url = trim(cfg.manifestUrl)

  if url == "" or not url:match("^https://") then
    setStatus("Pega la URL HTTPS del manifest de Camel Hub.", "#ffd166")
    if callback then callback(nil) end
    return
  end

  setStatus("Revisando actualizaciones...", "#ffd166")

  HTTP.get(url, function(data, err)
    if err or not data then
      setStatus("No se pudo leer manifest.\n" .. tostring(err or "sin datos"), "#ff8a8a")
      if callback then callback(nil) end
      return
    end

    local ok, manifest = pcall(function()
      return json.decode(data)
    end)

    if not ok then
      setStatus("Manifest JSON invalido.", "#ff8a8a")
      if callback then callback(nil) end
      return
    end

    local valid, why = validateManifest(manifest)
    if not valid then
      setStatus(why, "#ff8a8a")
      if callback then callback(nil) end
      return
    end

    lastManifest = manifest
    if callback then callback(manifest) end
  end)
end

local function showManifest(manifest)
  if not manifest then return end

  local pending = pendingFiles(manifest)
  local remote = tostring(manifest.version or "?")

  if #pending == 0 then
    cfg.version = remote
    setStatus("Camel Hub " .. remote .. "\nTodo actualizado.", "#8cff9a")
  else
    setStatus(
      "Instalada: " .. tostring(cfg.version) ..
      " | Disponible: " .. remote ..
      "\nArchivos comunes pendientes: " .. #pending,
      "#ffd166"
    )
  end
end

local function installNext(manifest, list, index, installed)
  if index > #list then
    installing = false
    cfg.version = tostring(manifest.version or cfg.version)

    setStatus(
      "Actualizado a Camel Hub " .. cfg.version ..
      "\n" .. installed .. " archivo(s). Recargando...",
      "#8cff9a"
    )

    if cfg.autoReload and type(reload) == "function" then
      schedule(800, function()
        pcall(reload)
      end)
    end
    return
  end

  local entry = list[index]
  local rel = normalizePath(entry.path)

  setStatus(
    "Actualizando " .. index .. "/" .. #list .. "\n" .. rel,
    "#ffd166"
  )

  HTTP.get(entry.url, function(data, err)
    if err or not data then
      installing = false
      setStatus(
        "Descarga fallida: " .. rel .. "\n" .. tostring(err or "sin datos"),
        "#ff8a8a"
      )
      return
    end

    local verified, why = verifyData(data, entry)
    if not verified then
      installing = false
      setStatus(why, "#ff8a8a")
      return
    end

    backupFile(rel)

    local ok, writeErr = pcall(function()
      g_resources.writeFileContents(targetPath(rel), data)
    end)

    if not ok then
      installing = false
      setStatus(
        "No se pudo escribir: " .. rel .. "\n" .. tostring(writeErr),
        "#ff8a8a"
      )
      return
    end

    local written = readLocal(rel)
    local verifiedAfter, whyAfter = verifyData(written or "", entry)

    if not verifiedAfter then
      installing = false
      setStatus(
        "Verificacion posterior fallo: " .. rel .. "\n" .. tostring(whyAfter),
        "#ff8a8a"
      )
      return
    end

    schedule(40, function()
      installNext(manifest, list, index + 1, installed + 1)
    end)
  end)
end

local function installManifest(manifest)
  if installing or not manifest then return end

  local list = pendingFiles(manifest)

  if #list == 0 then
    showManifest(manifest)
    return
  end

  installing = true
  installNext(manifest, list, 1, 0)
end

ui.check.onClick = function()
  fetchManifest(showManifest)
end

ui.update.onClick = function()
  if installing then return end

  if lastManifest then
    installManifest(lastManifest)
  else
    fetchManifest(function(manifest)
      if manifest then installManifest(manifest) end
    end)
  end
end

setStatus(
  "Camel Hub " .. tostring(cfg.version) .. " | Updater " .. tostring(CamelHubUpdater.clientVersion) ..
  "\nPerfiles, storage, rutas e iconos protegidos.",
  "#9dd1ce"
)
