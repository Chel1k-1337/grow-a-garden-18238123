-- drone_point.lua
-- Специфичные модули для игры Drone Point

local drone_point = {}

drone_point.ESPEnabled = false
drone_point.LeadIndicatorEnabled = false
drone_point.BulletSpeed = 1000 -- Скорость снаряда (настраивается в UI)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Рисовалка для кружочка упреждения
local leadCircle = Drawing.new("Circle")
leadCircle.Visible = false
leadCircle.Color = Color3.fromRGB(0, 255, 0)
leadCircle.Thickness = 2
leadCircle.Radius = 15
leadCircle.Filled = false
leadCircle.Transparency = 1

local function getDrones()
    local drones = {}
    -- 1. Дроны могут быть персонажами других игроков
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(drones, player.Character)
        end
    end
    -- 2. Либо это отдельные NPC/Модели в воркспейсе
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find("drone") and obj:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(obj) then
                table.insert(drones, obj)
            end
        end
    end
    return drones
end

local function getVelocity(model)
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if root then
        return root.AssemblyLinearVelocity
    end
    return Vector3.new(0, 0, 0)
end

function drone_point:Init()
    local activeHighlights = {}

    RunService.RenderStepped:Connect(function()
        local drones = getDrones()
        
        -- ESP Logic
        if drone_point.ESPEnabled then
            local currentDrones = {}
            for _, drone in pairs(drones) do
                currentDrones[drone] = true
                if not activeHighlights[drone] then
                    local h = Instance.new("Highlight")
                    h.Name = "DroneESP"
                    h.FillColor = Color3.fromRGB(0, 150, 255)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = drone
                    activeHighlights[drone] = h
                end
            end
            -- Чистка старых ESP
            for drone, h in pairs(activeHighlights) do
                if not currentDrones[drone] or not drone.Parent then
                    h:Destroy()
                    activeHighlights[drone] = nil
                end
            end
        else
            -- Удаляем все ESP если выключено
            for drone, h in pairs(activeHighlights) do
                if h and h.Parent then h:Destroy() end
            end
            table.clear(activeHighlights)
        end

        -- Lead Indicator Logic (Кружок упреждения)
        if drone_point.LeadIndicatorEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myPos = LocalPlayer.Character.HumanoidRootPart.Position
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            
            local closestDrone = nil
            local shortestDist = math.huge
            local closestPredictedPos = nil
            
            for _, drone in pairs(drones) do
                local root = drone:FindFirstChild("HumanoidRootPart") or drone.PrimaryPart
                if root then
                    -- Расчет упреждения
                    local distToDrone = (root.Position - myPos).Magnitude
                    local timeToHit = distToDrone / drone_point.BulletSpeed
                    local predictedPos = root.Position + (getVelocity(drone) * timeToHit)
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    if onScreen then
                        local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        -- Находим ближайший к мышке кружок упреждения
                        if distToMouse < shortestDist then
                            shortestDist = distToMouse
                            closestDrone = drone
                            closestPredictedPos = screenPos
                        end
                    end
                end
            end
            
            if closestDrone and closestPredictedPos then
                leadCircle.Position = Vector2.new(closestPredictedPos.X, closestPredictedPos.Y)
                leadCircle.Visible = true
            else
                leadCircle.Visible = false
            end
        else
            leadCircle.Visible = false
        end
    end)
end

return drone_point
