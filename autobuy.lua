-- autobuy.lua
local autobuy = {
    Enabled = false,
    TargetItem = "Carrots",
}

local vim = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

-- ПРОКРУТКА СКРОЛЛА К НУЖНОМУ ЭЛЕМЕНТУ
local function scrollIntoView(guiElement)
    local parent = guiElement.Parent
    while parent and parent ~= game do
        if parent:IsA("ScrollingFrame") then
            -- Вычисляем позицию элемента внутри скролл-фрейма
            local targetCanvasY = guiElement.AbsolutePosition.Y - parent.AbsolutePosition.Y + parent.CanvasPosition.Y
            -- Центрируем
            targetCanvasY = targetCanvasY - (parent.AbsoluteSize.Y / 2) + (guiElement.AbsoluteSize.Y / 2)
            if targetCanvasY < 0 then targetCanvasY = 0 end
            
            parent.CanvasPosition = Vector2.new(parent.CanvasPosition.X, targetCanvasY)
            task.wait(0.2) -- Ждем пока UI обновится
            warn("[AutoBuy] Прокрутили меню к товару!")
            return true
        end
        parent = parent.Parent
    end
    return false
end

-- ЖЕСТКИЙ КЛИК (УЛУЧШЕННЫЙ)
local function hardClick(gui, isPrecise)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        
        local x = gui.AbsolutePosition.X + (gui.AbsoluteSize.X / 2)
        local y = gui.AbsolutePosition.Y + (gui.AbsoluteSize.Y / 2)
        
        -- Строго один точный клик в центр элемента
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.02)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        
        -- Если это кнопки телепорта, делаем веерный клик для надежности
        if not isPrecise then
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y - 20, 0, true, game, 1)
            task.wait(0.02)
            vim:SendMouseButtonEvent(x, y - 20, 0, false, game, 1)
            
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y + 20, 0, true, game, 1)
            task.wait(0.02)
            vim:SendMouseButtonEvent(x, y + 20, 0, false, game, 1)
        end
    end)
end

-- КЛИК ПО ОБЫЧНОЙ КНОПКЕ
local function clickGenericButton(buttonName)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not LocalPlayer then return false end
    
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenX = workspace.CurrentCamera.ViewportSize.X
    local screenY = workspace.CurrentCamera.ViewportSize.Y
    local searchLower = string.lower(buttonName)
    
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("GuiButton") and gui.Visible and gui.AbsoluteSize.X > 5 and gui.AbsoluteSize.Y > 5 then
            if gui.AbsolutePosition.X >= -100 and gui.AbsolutePosition.Y >= -100 and gui.AbsolutePosition.X <= screenX + 100 and gui.AbsolutePosition.Y <= screenY + 100 then
                local match = false
                
                if string.find(string.lower(gui.Name), searchLower) then match = true end
                if gui:IsA("TextButton") and gui.Text ~= "" and string.find(string.lower(gui.Text), searchLower) then match = true end
                
                for _, child in pairs(gui:GetChildren()) do
                    if child:IsA("TextLabel") and child.Text ~= "" and string.find(string.lower(child.Text), searchLower) then
                        match = true
                    end
                end
                
                if not match and gui.Parent and gui.Parent.AbsoluteSize.Y < 150 then
                    for _, sibling in pairs(gui.Parent:GetChildren()) do
                        if sibling:IsA("TextLabel") and string.find(string.lower(sibling.Text), searchLower) then
                            match = true
                        end
                    end
                end

                if match then
                    warn("[AutoBuy] Нашли кнопку телепорта " .. buttonName .. "! Нажимаем!")
                    hardClick(gui, false) -- Телепорт кликается 2 раза (с Inset и без), чтобы 100% попасть
                    return true
                end
            end
        end
    end
    
    warn("[AutoBuy] ВНИМАНИЕ: Не удалось найти кнопку " .. buttonName .. "!")
    return false
end

-- ОТКРЫТИЕ МЕНЮ ЧЕРЕЗ NPC/СТЕНД
local function openShopMenu()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local root = char.HumanoidRootPart
    
    local foundAny = false
    
    -- Ищем и активируем ВСЕ возможные кнопки (ProximityPrompt) в радиусе 40 стадов
    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local part = prompt.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - root.Position).Magnitude
                if dist < 40 then
                    warn("[AutoBuy] Активируем ProximityPrompt магазина...")
                    
                    if fireproximityprompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                    
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        local key = prompt.KeyboardKeyCode
                        vim:SendKeyEvent(true, key, false, game)
                        task.wait(prompt.HoldDuration + 0.1)
                        vim:SendKeyEvent(false, key, false, game)
                    end)
                    
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.1)
                        prompt:InputHoldEnd()
                    end)
                    
                    foundAny = true
                end
            end
        end
    end
    
    -- Также ищем обычные клик-детекторы (если магазин работает через клик мышкой по стенду)
    for _, detector in pairs(workspace:GetDescendants()) do
        if detector:IsA("ClickDetector") then
            local part = detector.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - root.Position).Magnitude
                if dist < 40 then
                    warn("[AutoBuy] Активируем ClickDetector магазина...")
                    if fireclickdetector then 
                        pcall(function() fireclickdetector(detector) end)
                    end
                    foundAny = true
                end
            end
        end
    end
    
    if not foundAny then
        warn("[AutoBuy] В радиусе 40 стадов не найдено магазина или NPC!")
    end
    
    return foundAny
end

-- УМНЫЙ КЛИК ПО ТОВАРУ (Поиск кнопки по позиции и защита от NO STOCK)
local function clickItemBuyButton(itemName)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local targetTextLabel = nil
    
    -- 1. Находим текст с названием семян
    local searchTerm = string.lower(itemName)
    if itemName == "Carrots" then searchTerm = "carrot" end
    if itemName == "Strawberries" then searchTerm = "strawberry" end
    if itemName == "Blueberries" then searchTerm = "blueberry" end
    if itemName == "Tomatoes" then searchTerm = "tomato" end
    if itemName == "Bamboo" then searchTerm = "bamboo" end
    
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Text ~= "" then
            if string.find(string.lower(gui.Text), searchTerm) then
                targetTextLabel = gui
                break
            end
        end
    end
    
    if targetTextLabel then
        warn("[AutoBuy] Выбираем товар: " .. itemName)
        
        -- Ищем карточку товара (коричневый фон). 
        -- Обязательно проверяем любой GuiObject (включая ImageLabel) с высотой 60-170.
        local parent = targetTextLabel.Parent
        local maxDepth = 5
        local depth = 0
        local card = nil
        while parent and not parent:IsA("ScreenGui") and depth < maxDepth do
            if parent:IsA("GuiObject") then
                local sizeY = parent.AbsoluteSize.Y
                local sizeX = parent.AbsoluteSize.X
                -- Карточка товара примерно 80-120 пикселей в высоту. 
                -- < 170 гарантирует, что мы не выберем ВЕСЬ список (ScrollingFrame)!
                if sizeY >= 60 and sizeY <= 170 and sizeX >= 150 then
                    card = parent
                    break
                end
            end
            parent = parent.Parent
            depth = depth + 1
        end
        
        -- ШАГ 1: Кликаем ровно в центр карточки товара
        if card then
            warn("[AutoBuy] Нашли карточку товара! Кликаем ровно по центру.")
            hardClick(card, true)
        else
            warn("[AutoBuy] Карточка не найдена, кликаем по тексту.")
            hardClick(targetTextLabel, true)
        end
        
        task.wait(1) -- Ждем 1 секунду, чтобы кнопка покупки 100% появилась
        
        -- ШАГ 2: Ищем появившуюся кнопку с ценой
        local buyButton = nil
        local outOfStockFound = false
        
        -- Кнопка покупки появляется прямо под карточкой товара.
        for _, gui in pairs(PlayerGui:GetDescendants()) do
            if gui:IsA("GuiButton") and gui.Visible and gui.AbsolutePosition.Y > targetTextLabel.AbsolutePosition.Y then
                local isRobux = false
                local isOutOfStock = false
                local hasPrice = false
                
                -- Проверяем содержимое кнопки на символ цента (¢)
                if gui:IsA("TextButton") and string.find(gui.Text, "¢") then hasPrice = true end
                
                for _, child in pairs(gui:GetDescendants()) do
                    if child:IsA("ImageLabel") and typeof(child.Image) == "string" and string.find(string.lower(child.Image), "robux") then
                        isRobux = true
                    end
                    if child:IsA("TextLabel") and string.find(string.lower(child.Text), "out of stock") then
                        isOutOfStock = true
                    end
                    if child:IsA("TextLabel") and string.find(child.Text, "¢") then
                        hasPrice = true
                    end
                end
                
                if not isRobux then
                    if isOutOfStock then
                        outOfStockFound = true
                    elseif hasPrice then
                        -- Это 100% кнопка покупки за монеты!
                        -- Но нам нужна та, которая ближе всего к нашему товару (ниже текста)
                        local diffY = gui.AbsolutePosition.Y - targetTextLabel.AbsolutePosition.Y
                        if diffY < 200 then
                            buyButton = gui
                            break
                        end
                    end
                end
            end
        end
        
        if outOfStockFound and not buyButton then
            warn("[AutoBuy] Товар " .. itemName .. " сейчас не в наличии (NO STOCK)!")
            return false
        elseif buyButton then
            warn("[AutoBuy] Нашли зеленую кнопку покупки для " .. itemName .. ". Покупаем!")
            hardClick(buyButton, true) -- СТРОГО 1 точный клик
            return true
        else
            warn("[AutoBuy] Не удалось найти появившуюся кнопку цены для " .. itemName)
        end
    else
        warn("[AutoBuy] ВНИМАНИЕ: Не удалось найти надпись товара '" .. itemName .. "' в магазине!")
    end
    
    return false
end

-- УМНОЕ ЗАКРЫТИЕ МАГАЗИНА
local function clickCloseButton()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenX = workspace.CurrentCamera.ViewportSize.X
    local screenY = workspace.CurrentCamera.ViewportSize.Y
    
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("GuiButton") and gui.Visible and gui.AbsoluteSize.X > 5 and gui.AbsoluteSize.Y > 5 then
            if gui.AbsolutePosition.X >= 0 and gui.AbsolutePosition.Y >= 0 and gui.AbsolutePosition.X <= screenX and gui.AbsolutePosition.Y <= screenY then
                
                -- Ищем ПРОСТО по красному цвету фона (как ты и просил)
                if gui.BackgroundColor3.R > 0.6 and gui.BackgroundColor3.G < 0.4 and gui.BackgroundColor3.B < 0.4 then
                    warn("[AutoBuy] Нашли КРАСНУЮ кнопку! Нажимаем 1 раз.")
                    hardClick(gui, true)
                    return true -- Делаем строго 1 клик и останавливаемся!
                end
                
            end
        end
    end
    
    warn("[AutoBuy] Красная кнопка не найдена!")
    return false
end

function autobuy:Start()
    self.Enabled = true
    task.spawn(function()
        while self.Enabled do
            self:PerformAutoBuyCycle()
            task.wait(10) -- Оставил 10 секунд для тестов
        end
    end)
end

function autobuy:Stop()
    self.Enabled = false
end

function autobuy:PerformAutoBuyCycle()
    warn("[AutoBuy] --- Новый цикл ---")
    
    warn("[AutoBuy] Телепортируемся в магазин (Seeds)...")
    clickGenericButton("Seeds")
    task.wait(4)
    if not self.Enabled then return end
    
    warn("[AutoBuy] Открываем меню...")
    openShopMenu()
    task.wait(3) -- Ждем 3 секунды, чтобы меню 100% успело прогрузиться на экране
    if not self.Enabled then return end
    
    warn("[AutoBuy] Ищем товар и покупаем...")
    clickItemBuyButton(self.TargetItem)
    task.wait(1)
    if not self.Enabled then return end
    
    warn("[AutoBuy] Закрываем магазин...")
    clickCloseButton()
    task.wait(1)
    
    warn("[AutoBuy] Возвращаемся на базу (Garden)...")
    clickGenericButton("Garden")
end

return autobuy
