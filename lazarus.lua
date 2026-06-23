-- lazarus.lua
-- Специфичные модули для игры Project Lazarus

local lazarus = {}

lazarus.ESPEnabled = false
lazarus.HitboxEnabled = false
lazarus.HitboxSize = 10

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function isZombie(model)
    if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") then
        -- Убедимся, что это не игрок
        if not Players:GetPlayerFromCharacter(model) then
            -- В Project Lazarus у зомби обычно есть Humanoid с Health > 0
            if model.Humanoid.Health > 0 then
                return true
            end
        end
    end
    return false
end

function lazarus:Init()
    local zombies = {}

    -- Оптимизированный поиск зомби раз в секунду (чтобы не лагало)
    task.spawn(function()
        while true do
            task.wait(1)
            local newZombies = {}
            
            -- Зомби могут быть в корне Workspace или в специальных папках
            local containers = {workspace}
            if workspace:FindFirstChild("Baddies") then table.insert(containers, workspace.Baddies) end
            if workspace:FindFirstChild("Zombies") then table.insert(containers, workspace.Zombies) end
            if workspace:FindFirstChild("Ignore") then table.insert(containers, workspace.Ignore) end
            
            for _, container in pairs(containers) do
                for _, obj in pairs(container:GetChildren()) do
                    if isZombie(obj) then
                        table.insert(newZombies, obj)
                    end
                end
            end
            
            zombies = newZombies
        end
    end)

    -- Быстрое обновление визуалов и хитбоксов каждый кадр
    RunService.RenderStepped:Connect(function()
        for _, obj in pairs(zombies) do
            if obj and obj.Parent and obj:FindFirstChild("Head") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
                local head = obj.Head
                
                -- 1. Увеличение хитбоксов
                if lazarus.HitboxEnabled then
                    head.Size = Vector3.new(lazarus.HitboxSize, lazarus.HitboxSize, lazarus.HitboxSize)
                    head.Transparency = 0.7
                    head.BrickColor = BrickColor.new("Bright red")
                    head.CanCollide = false
                else
                    if head.Size.X > 5 then
                        -- Возвращаем примерный размер головы
                        head.Size = Vector3.new(1.2, 1.2, 1.2)
                        head.Transparency = 0
                    end
                end

                -- 2. ESP на зомби
                local highlight = obj:FindFirstChild("LazarusESP")
                if lazarus.ESPEnabled then
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "LazarusESP"
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = obj
                    end
                else
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end
        end
    end)
end

return lazarus
