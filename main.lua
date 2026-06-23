-- main.lua
-- Основной файл загрузки (точка входа)

-- Загрузка скриптов напрямую с GitHub (добавлен ?v=tick() для обхода кэша Гитхаба)
local url_ui = "https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/ui.lua?v=" .. tostring(tick())
local url_autobuy = "https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/autobuy.lua?v=" .. tostring(tick())
local url_lazarus = "https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/lazarus.lua?v=" .. tostring(tick())
local url_drone = "https://raw.githubusercontent.com/Chel1k-1337/grow-a-garden-18238123/main/drone_point.lua?v=" .. tostring(tick())

local ui = loadstring(game:HttpGet(url_ui))()
local autobuy = loadstring(game:HttpGet(url_autobuy))()
local lazarus = loadstring(game:HttpGet(url_lazarus))()
local drone = loadstring(game:HttpGet(url_drone))()

-- Инициализируем игровые модули
lazarus:Init()
drone:Init()
ui:Init(autobuy, lazarus, drone)
