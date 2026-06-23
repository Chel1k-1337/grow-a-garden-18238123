-- ui.lua
-- Графический интерфейс с использованием Rayfield (очень надежная библиотека)
local ui = {}

function ui:Init(autobuy_module, lazarus_module)
    -- Загружаем Rayfield UI с официального сайта (ссылка Orion, к сожалению, умерла на GitHub)
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    -- Создаем главное окно
    local Window = Rayfield:CreateWindow({
       Name = "Grow a Garden 2 | Авто-Скупка",
       LoadingTitle = "Загрузка интерфейса...",
       LoadingSubtitle = "by Antigravity",
       ConfigurationSaving = {
          Enabled = true,
          FolderName = "GrowAGarden2_AutoBuy",
          FileName = "Config"
       },
       Discord = {
          Enabled = false,
          Invite = "",
          RememberJoins = true
       },
       KeySystem = false
    })

    -- Создаем вкладку
    local MainTab = Window:CreateTab("Главная", 4483362458)
    
    MainTab:CreateParagraph({Title = "Как управлять окном", Content = "1. Перетаскивание: хватайте мышкой за самую верхнюю панель с названием.\n2. Скрытие/Открытие: нажмите кнопку Правый Ctrl (RightControl) на клавиатуре."})

    local seedsList = {
        "Carrots", "Strawberries", "Blueberries", "Tomatoes", 
        "Bamboo", "Mushroom", "Mango", "Moon Bloom", "Dragon's Breath"
    }
    
    -- Выбор предмета
    MainTab:CreateDropdown({
       Name = "Выберите семена для покупки",
       Options = seedsList,
       CurrentOption = {"Carrots"},
       MultipleOptions = false,
       Flag = "TargetItemDropdown",
       Callback = function(Option)
           autobuy_module.TargetItem = Option[1]
       end,
    })

    -- Переключатель авто-покупки
    MainTab:CreateToggle({
       Name = "Включить авто-покупку",
       CurrentValue = false,
       Flag = "AutoBuyToggle",
       Callback = function(Value)
           autobuy_module.Enabled = Value
           if Value then
               autobuy_module:Start()
               Rayfield:Notify({
                   Title = "Включено",
                   Content = "Авто-покупка " .. autobuy_module.TargetItem .. " запущена.",
                   Duration = 3,
                   Image = 4483362458,
               })
           else
               autobuy_module:Stop()
               Rayfield:Notify({
                   Title = "Остановлено",
                   Content = "Авто-покупка выключена.",
                   Duration = 3,
                   Image = 4483362458,
               })
           end
       end,
    })
    
    -- Кнопка полного уничтожения интерфейса
    MainTab:CreateButton({
       Name = "Закрыть скрипт навсегда",
       Callback = function()
           autobuy_module:Stop()
           Rayfield:Destroy()
       end,
    })
    -- ==========================================
    -- Вкладка "Игрок" (Ускорение и т.д.)
    -- ==========================================
    local PlayerTab = Window:CreateTab("Игрок", 4483362458)

    local targetWalkSpeed = 16
    local targetJumpPower = 50

    -- Функция для обхода анти-чита/сброса скорости (сохраняет скорость)
    local function setupCharacter(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if targetWalkSpeed > 16 and humanoid.WalkSpeed ~= targetWalkSpeed then
                    humanoid.WalkSpeed = targetWalkSpeed
                end
            end)
            humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if targetJumpPower > 50 and humanoid.JumpPower ~= targetJumpPower then
                    humanoid.JumpPower = targetJumpPower
                end
            end)
            
            if targetWalkSpeed > 16 then humanoid.WalkSpeed = targetWalkSpeed end
            if targetJumpPower > 50 then humanoid.JumpPower = targetJumpPower end
        end
    end

    if game.Players.LocalPlayer.Character then
        setupCharacter(game.Players.LocalPlayer.Character)
    end
    game.Players.LocalPlayer.CharacterAdded:Connect(setupCharacter)

    PlayerTab:CreateInput({
       Name = "Ускорение (WalkSpeed)",
       PlaceholderText = "Введите скорость (например: 1000)",
       RemoveTextAfterFocusLost = false,
       Callback = function(Text)
            local speed = tonumber(Text)
            if speed then
                if speed > 1000 then speed = 1000 end
                targetWalkSpeed = speed
                if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
                end
            end
       end,
    })

    PlayerTab:CreateSlider({
       Name = "Высота прыжка (JumpPower)",
       Range = {50, 150},
       Increment = 1,
       Suffix = " Power",
       CurrentValue = 50,
       Flag = "JumpPowerSlider",
       Callback = function(Value)
            targetJumpPower = Value
            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
            end
       end,
    })

    -- Универсальные функции
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    
    local infiniteJumpEnabled = false
    UserInputService.JumpRequest:Connect(function()
        if infiniteJumpEnabled then
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    
    PlayerTab:CreateToggle({
       Name = "Бесконечный прыжок (Infinite Jump)",
       CurrentValue = false,
       Flag = "InfiniteJump",
       Callback = function(Value)
            infiniteJumpEnabled = Value
       end,
    })

    local noclipEnabled = false
    RunService.Stepped:Connect(function()
        if noclipEnabled then
            local char = game.Players.LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
    
    PlayerTab:CreateToggle({
       Name = "Хождение сквозь стены (Noclip)",
       CurrentValue = false,
       Flag = "Noclip",
       Callback = function(Value)
            noclipEnabled = Value
       end,
    })
    
    -- ==========================================
    -- Вкладка "Разное" (Универсальные скрипты)
    -- ==========================================
    local MiscTab = Window:CreateTab("Разное", 4483362458)
    
    MiscTab:CreateButton({
       Name = "Включить Anti-AFK (Анти-кик)",
       Callback = function()
            local vu = game:GetService("VirtualUser")
            game.Players.LocalPlayer.Idled:Connect(function()
                vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            end)
            Rayfield:Notify({
                Title = "Anti-AFK",
                Content = "Успешно! Теперь игра не выкинет вас за бездействие 20 минут.",
                Duration = 3,
                Image = 4483362458,
            })
       end,
    })

    local clickTpEnabled = false
    local UserInputService = game:GetService("UserInputService")
    local mouse = game.Players.LocalPlayer:GetMouse()

    PlayerTab:CreateToggle({
       Name = "Телепорт по клику (Левый Ctrl + Клик Мышью)",
       CurrentValue = false,
       Flag = "ClickTP",
       Callback = function(Value)
            clickTpEnabled = Value
       end,
    })

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if clickTpEnabled and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and mouse.Hit then
                    -- Телепортируем на позицию клика (чуть выше, чтобы не застрять в земле)
                    char.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
                end
            end
        end
    end)

    local RunService = game:GetService("RunService")
    local mouseUnlockConnection = nil

    PlayerTab:CreateToggle({
       Name = "Разблокировать мышку и 3-е лицо",
       CurrentValue = false,
       Flag = "UnlockMouseCam",
       Callback = function(Value)
            if Value then
                -- Отдаляем камеру
                local player = game.Players.LocalPlayer
                player.CameraMaxZoomDistance = 128
                
                -- Постоянно освобождаем мышку (так как игра может пытаться ее спрятать)
                mouseUnlockConnection = RunService.RenderStepped:Connect(function()
                    game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
                end)
            else
                -- Возвращаем настройки по умолчанию (игра сама заблокирует обратно)
                if mouseUnlockConnection then
                    mouseUnlockConnection:Disconnect()
                    mouseUnlockConnection = nil
                end
            end
       end,
    })

    local godModeConnection = nil
    PlayerTab:CreateToggle({
       Name = "Бесконечное ХП (God Mode)",
       CurrentValue = false,
       Flag = "GodMode",
       Callback = function(Value)
            if Value then
                godModeConnection = RunService.RenderStepped:Connect(function()
                    local char = game.Players.LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                        local hum = char.Humanoid
                        -- Если сервер доверяет клиенту, это сделает вас бессмертным
                        hum.MaxHealth = math.huge
                        hum.Health = math.huge
                    end
                end)
            else
                if godModeConnection then
                    godModeConnection:Disconnect()
                    godModeConnection = nil
                end
                -- Пытаемся вернуть нормальное ХП при выключении
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    local hum = char.Humanoid
                    if hum.MaxHealth > 1000000 then
                        hum.MaxHealth = 100
                        hum.Health = 100
                    end
                end
            end
       end,
    })

    -- ==========================================
    -- Вкладка "Визуалы" (ESP - CS2 Style)
    -- ==========================================
    local VisualsTab = Window:CreateTab("Визуалы", 4483362458)

    local espEnabled = false
    local ESP_Boxes = {}
    local Camera = workspace.CurrentCamera
    local RunService = game:GetService("RunService")

    local function createEspBox(player)
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Color3.fromRGB(255, 255, 255)
        box.Thickness = 1.5
        box.Filled = false
        
        local hpBarBg = Drawing.new("Square")
        hpBarBg.Visible = false
        hpBarBg.Color = Color3.fromRGB(0, 0, 0)
        hpBarBg.Thickness = 1
        hpBarBg.Filled = true
        
        local hpBar = Drawing.new("Square")
        hpBar.Visible = false
        hpBar.Color = Color3.fromRGB(0, 255, 0)
        hpBar.Thickness = 1
        hpBar.Filled = true
        
        local hpText = Drawing.new("Text")
        hpText.Visible = false
        hpText.Color = Color3.fromRGB(255, 255, 255)
        hpText.Size = 13
        hpText.Center = true
        hpText.Outline = true
        
        ESP_Boxes[player] = {Box = box, HPBarBg = hpBarBg, HPBar = hpBar, HPText = hpText}
    end

    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= game.Players.LocalPlayer then
            createEspBox(v)
        end
    end

    game.Players.PlayerAdded:Connect(function(player)
        createEspBox(player)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        if ESP_Boxes[player] then
            ESP_Boxes[player].Box:Remove()
            ESP_Boxes[player].HPBarBg:Remove()
            ESP_Boxes[player].HPBar:Remove()
            ESP_Boxes[player].HPText:Remove()
            ESP_Boxes[player] = nil
        end
    end)

    RunService.RenderStepped:Connect(function()
        for player, esp in pairs(ESP_Boxes) do
            if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local hrp = player.Character.HumanoidRootPart
                local hum = player.Character.Humanoid
                
                local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    -- Расчет размера бокса относительно дистанции
                    local size = (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.6, 0)).Y) / 2
                    local width = size / 1.5
                    local height = size

                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(hrpPos.X - width / 2, hrpPos.Y - height / 2)
                    esp.Box.Visible = true
                    
                    -- Полоска ХП
                    local hpPercent = hum.Health / hum.MaxHealth
                    
                    esp.HPBarBg.Size = Vector2.new(4, height + 2)
                    esp.HPBarBg.Position = Vector2.new(esp.Box.Position.X - 6, esp.Box.Position.Y - 1)
                    esp.HPBarBg.Visible = true

                    esp.HPBar.Size = Vector2.new(2, height * hpPercent)
                    esp.HPBar.Position = Vector2.new(esp.Box.Position.X - 5, esp.Box.Position.Y + height - (height * hpPercent))
                    esp.HPBar.Color = Color3.fromRGB(255 - (255 * hpPercent), 255 * hpPercent, 0)
                    esp.HPBar.Visible = true
                    
                    -- Текст ХП
                    esp.HPText.Text = tostring(math.floor(hum.Health)) .. " HP"
                    esp.HPText.Position = Vector2.new(esp.Box.Position.X - 20, esp.Box.Position.Y + height - (height * hpPercent) - 6)
                    esp.HPText.Visible = true
                else
                    esp.Box.Visible = false
                    esp.HPBarBg.Visible = false
                    esp.HPBar.Visible = false
                    esp.HPText.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.HPBarBg.Visible = false
                esp.HPBar.Visible = false
                esp.HPText.Visible = false
            end
        end
    end)

    VisualsTab:CreateToggle({
       Name = "ESP Box & HP (CS2 Style)",
       CurrentValue = false,
       Flag = "ESPBoxes",
       Callback = function(Value)
            espEnabled = Value
       end,
    })

    -- ==========================================
    -- Вкладка "Project Lazarus"
    -- ==========================================
    if lazarus_module then
        local LazarusTab = Window:CreateTab("Project Lazarus", 4483362458)
        
        LazarusTab:CreateParagraph({Title = "Внимание", Content = "Эти функции работают ТОЛЬКО в режиме Project Lazarus: Zombies."})
        
        LazarusTab:CreateToggle({
           Name = "Zombie ESP (Подсветка зомби сквозь стены)",
           CurrentValue = false,
           Flag = "LazarusESP",
           Callback = function(Value)
                lazarus_module.ESPEnabled = Value
           end,
        })
        
        LazarusTab:CreateToggle({
           Name = "Hitbox Expander (Гигантские головы)",
           CurrentValue = false,
           Flag = "LazarusHitbox",
           Callback = function(Value)
                lazarus_module.HitboxEnabled = Value
           end,
        })
        
        LazarusTab:CreateSlider({
           Name = "Размер головы зомби",
           Range = {5, 20},
           Increment = 1,
           Suffix = " Size",
           CurrentValue = 10,
           Flag = "LazarusHitboxSize",
           Callback = function(Value)
                lazarus_module.HitboxSize = Value
           end,
        })
    end
end

return ui
