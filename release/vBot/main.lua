local version = "4.8"
local currentVersion
local available = false

storage.checkVersion = storage.checkVersion or 0

-- check max once per 12hours
if os.time() > storage.checkVersion + (12 * 60 * 60) then

    storage.checkVersion = os.time()
    
    HTTP.get("https://raw.githubusercontent.com/Vithrax/vBot/main/vBot/version.txt", function(data, err)
        if err then
          warn("[vBot updater]: Unable to check version:\n" .. err)
          return
        end

        currentVersion = data
        available = true
    end)

end

local camelHubBanner = setupUI([[
Panel
  height: 62
  margin-top: 2
  margin-left: 3
  margin-right: 3
  background-color: #10131bcc
  border: 1 #21f6ff
  padding: 3
  layout: verticalBox

  Label
    height: 11
    text-align: center
    font: verdana-11px-rounded
    color: #21f6ff
    !text: tr('.-<==-<>-==-<>-==>-.')

  Label
    height: 20
    text-align: center
    font: verdana-11px-rounded
    color: #00ffff
    !text: tr('CAMEL HUB')

  Label
    height: 18
    text-align: center
    font: verdana-11px-rounded
    color: #d85cff
    !text: tr('Peru')

  Label
    height: 11
    text-align: center
    font: verdana-11px-rounded
    color: #d85cff
    !text: tr('`-<==-<>-==-<>-==>-`')
]])

UI.Separator()

schedule(5000, function()

    if not available then return end
    if currentVersion ~= version then
        
        UI.Separator()
        UI.Label("New vBot is available for download! v"..currentVersion)
        UI.Button("Go to vBot GitHub Page", function() g_platform.openUrl("https://github.com/Vithrax/vBot") end)
        UI.Separator()
        
    end

end)