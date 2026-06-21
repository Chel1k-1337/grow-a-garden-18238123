-- main.lua
-- Основной файл загрузки (точка входа)

-- Загрузка скриптов напрямую с GitHub
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/ui.lua"))()
local autobuy = loadstring(game:HttpGet("https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/autobuy.lua"))()

ui:Init(autobuy)
