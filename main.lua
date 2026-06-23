-- main.lua
-- Основной файл загрузки (точка входа)

-- Загрузка скриптов напрямую с GitHub (добавлен ?v=tick() для обхода кэша Гитхаба)
local url_ui = "https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/ui.lua?v=" .. tostring(tick())
local url_autobuy = "https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/autobuy.lua?v=" .. tostring(tick())

local ui = loadstring(game:HttpGet(url_ui))()
local autobuy = loadstring(game:HttpGet(url_autobuy))()

ui:Init(autobuy)
