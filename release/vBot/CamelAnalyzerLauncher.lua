---@diagnostic disable: undefined-global
-- Camel Hub Main launcher for the Sabuezo Analyzer.

setDefaultTab("Main")

local analyzerMainUi = setupUI([[
Panel
  height: 23
  margin-top: 2

  Button
    id: open
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 21
    text-align: center
    text: Analyzer
]])

analyzerMainUi.open.onClick = function()
  if Analyzer and Analyzer.toggleMainWindow then
    Analyzer.toggleMainWindow()
  else
    warn("[Camel Analyzer] Analyzer no esta disponible.")
  end
end
