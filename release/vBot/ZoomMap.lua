-- Camel Hub - map zoom controls
-- Loaded before Auto Party so Tools order is:
-- Zoom In map -> Zoom Out map -> Camel Hub Party -> remaining tools.
setDefaultTab("Tools")

UI.Button("Zoom In map", function()
  zoomIn()
end)

UI.Button("Zoom Out map", function()
  zoomOut()
end)
