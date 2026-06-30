-- lazarus.lua
-- Специфичные модули для игры Project Lazarus

local lazarus = {}

lazarus.ESPEnabled = false
lazarus.SilentAimEnabled = false
lazarus.SilentAimFOV = 150
lazarus.RenderFOV = false
lazarus.AimbotEnabled = false
lazarus.AimbotWallCheck = true
lazarus.AimbotSmoothing = 1
lazarus.TriggerBotEnabled = false
lazarus.InfiniteAmmoEnabled = false
lazarus.NoRecoilEnabled = false
lazarus.RapidFireEnabled = false

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
                
                -- Хитбоксы удалены по просьбе пользователя

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

    -- Оружейные модули (через getgc)
    task.spawn(function()
        while true do
            task.wait(3)
            if lazarus.InfiniteAmmoEnabled or lazarus.NoRecoilEnabled or lazarus.RapidFireEnabled then
                pcall(function()
                    for _, v in pairs(getgc(true)) do
                        if type(v) == "table" then
                            if rawget(v, "Ammo") or rawget(v, "StoredAmmo") or rawget(v, "Recoil") or rawget(v, "FireRate") then
                                if lazarus.InfiniteAmmoEnabled then
                                    if rawget(v, "Ammo") then v.Ammo = 9999 end
                                    if rawget(v, "StoredAmmo") then v.StoredAmmo = 9999 end
                                    if rawget(v, "Mag") then v.Mag = 9999 end
                                    if rawget(v, "MaxAmmo") then v.MaxAmmo = 9999 end
                                end
                                if lazarus.NoRecoilEnabled then
                                    if rawget(v, "Recoil") then v.Recoil = 0 end
                                    if rawget(v, "Spread") then v.Spread = 0 end
                                    if rawget(v, "MinSpread") then v.MinSpread = 0 end
                                    if rawget(v, "MaxSpread") then v.MaxSpread = 0 end
                                end
                                if lazarus.RapidFireEnabled then
                                    if rawget(v, "FireRate") then v.FireRate = 0.05 end
                                    if rawget(v, "Cooldown") then v.Cooldown = 0.05 end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    local Camera = workspace.CurrentCamera
    local UserInputService = game:GetService("UserInputService")
    
    local function isVisible(targetPart)
        local origin = Camera.CFrame.Position
        local direction = (targetPart.Position - origin)
        local raycastParams = RaycastParams.new()
        
        local ignoreList = {Camera}
        if Players.LocalPlayer.Character then
            table.insert(ignoreList, Players.LocalPlayer.Character)
        end
        raycastParams.FilterDescendantsInstances = ignoreList
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result then
            -- Если луч попал в часть зомби, то он видим
            if result.Instance:IsDescendantOf(targetPart.Parent) then
                return true
            end
            -- Иначе перед нами стена
            return false
        end
        return true
    end

    local function getClosestZombieToMouse()
        local mousePos = UserInputService:GetMouseLocation()
        local closestZombie = nil
        local shortestDist = math.huge
        
        for _, obj in pairs(zombies) do
            if obj and obj.Parent and obj:FindFirstChild("Head") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(obj.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < lazarus.SilentAimFOV then
                        -- Проверка на стены для аимбота
                        local canAim = true
                        if lazarus.AimbotWallCheck then
                            canAim = isVisible(obj.Head)
                        end
                        
                        if canAim and dist < shortestDist then
                            shortestDist = dist
                            closestZombie = obj
                        end
                    end
                end
            end
        end
        return closestZombie
    end

    local FOVring = Drawing.new("Circle")
    FOVring.Visible = false
    FOVring.Thickness = 1
    FOVring.Color = Color3.fromRGB(255, 255, 255)
    FOVring.Filled = false
    FOVring.Transparency = 1

    -- Camera Aimbot Loop
    RunService.RenderStepped:Connect(function()
        -- Обновление круга FOV
        if lazarus.RenderFOV then
            FOVring.Visible = true
            FOVring.Radius = lazarus.SilentAimFOV
            local mousePos = UserInputService:GetMouseLocation()
            FOVring.Position = mousePos
        else
            FOVring.Visible = false
        end

        if lazarus.AimbotEnabled then
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local target = getClosestZombieToMouse()
                if target and target:FindFirstChild("Head") then
                    local targetPos = target.Head.Position
                    local currentCameraCFrame = Camera.CFrame
                    
                    -- Сглаживание наводки (1 = мгновенно, >1 = плавнее)
                    local newCFrame = CFrame.new(currentCameraCFrame.Position, targetPos)
                    Camera.CFrame = currentCameraCFrame:Lerp(newCFrame, 1 / lazarus.AimbotSmoothing)
                end
            end
        end

        -- TriggerBot
        if lazarus.TriggerBotEnabled and mouse1click then
            -- Пускаем луч из центра экрана, чтобы проверить есть ли под прицелом зомби
            local screenPoint = Camera.ViewportSize / 2
            local ray = Camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
            
            local raycastParams = RaycastParams.new()
            local ignoreList = {Camera}
            if Players.LocalPlayer.Character then
                table.insert(ignoreList, Players.LocalPlayer.Character)
            end
            raycastParams.FilterDescendantsInstances = ignoreList
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result and result.Instance then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                if model and isZombie(model) then
                    mouse1click()
                end
            end
        end
    end)

    local success = pcall(function() return hookmetamethod end)
    if success and hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if lazarus.SilentAimEnabled and not checkcaller() then
                if method == "Raycast" then
                    local origin = args[1]
                    local closestZombie = getClosestZombieToMouse()
                    if closestZombie and closestZombie:FindFirstChild("Head") then
                        local headPos = closestZombie.Head.Position
                        local newDirection = (headPos - origin).Unit * 1000
                        args[2] = newDirection
                        return oldNamecall(self, unpack(args))
                    end
                elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local ray = args[1]
                    local closestZombie = getClosestZombieToMouse()
                    if closestZombie and closestZombie:FindFirstChild("Head") then
                        local headPos = closestZombie.Head.Position
                        local newDirection = (headPos - ray.Origin).Unit * ray.Direction.Magnitude
                        args[1] = Ray.new(ray.Origin, newDirection)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end)
    else
        warn("Твой экзекутор не поддерживает hookmetamethod! Silent Aim работать не будет.")
    end
end

return lazarus
