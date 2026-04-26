
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_ENABLED = true
local MAX_DISTANCE = 5000

local Container = Instance.new("Folder")
Container.Name = "\0ESP"
pcall(function() Container.Parent = CoreGui end)
if not Container.Parent then Container.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Cache: {[Player]: {Highlight: Highlight, Billboard: BillboardGui}} = {}

local function getJob(player: Player): (string, Color3)
    if player.Team then
        local n = player.Team.Name:lower()
        if n:find("police") or n:find("polizei") then return "POLICE", Color3.fromRGB(30,144,255) end
        if n:find("medic") or n:find("rettung") or n:find("sanit") then return "MEDIC", Color3.fromRGB(255,255,255) end
        if n:find("fire") or n:find("feuer") then return "FIRE", Color3.fromRGB(255,100,0) end
        if n:find("crim") then return "CRIMINAL", Color3.fromRGB(255,0,150) end
    end
    return "CIVIL", Color3.fromRGB(255,255,100)
end

local function copyName(name: string): boolean
    local setclip = (setclipboard or (syn and syn.write_clipboard) or toclipboard or writeclipboard)
    if setclip then
        local ok = pcall(setclip, name)
        return ok
    end
    return false
end
local function notify(title: string, text: string)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 1.5})
    end)
end
local function addESP(player: Player)
    if player == LocalPlayer then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "H_"..player.Name
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = Container

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "B_"..player.Name
    billboard.Size = UDim2.new(0, 230, 0, 58)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Active = true
    billboard.MaxDistance = MAX_DISTANCE
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboard.Parent = Container


    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromScale(1, 1)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BackgroundTransparency = 0.25
    main.BorderSizePixel = 0
    main.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = main

   
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 15
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Text = player.DisplayName
    nameLabel.Parent = main

   
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, -10, 0, 18)
    infoFrame.Position = UDim2.new(0, 5, 0, 22)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = infoFrame

    local jobLabel = Instance.new("TextLabel")
    jobLabel.Name = "Job"
    jobLabel.LayoutOrder = 1
    jobLabel.AutomaticSize = Enum.AutomaticSize.X
    jobLabel.Size = UDim2.new(0, 0, 1, 0)
    jobLabel.BackgroundTransparency = 1
    jobLabel.Font = Enum.Font.GothamBold
    jobLabel.TextSize = 11
    jobLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    jobLabel.TextStrokeTransparency = 0.7
    jobLabel.Text = "[CIVIL]"
    jobLabel.Parent = infoFrame

    local pseudoBtn = Instance.new("TextButton")
    pseudoBtn.Name = "Pseudo"
    pseudoBtn.LayoutOrder = 2
    pseudoBtn.AutomaticSize = Enum.AutomaticSize.X
    pseudoBtn.Size = UDim2.new(0, 0, 1, 0)
    pseudoBtn.BackgroundTransparency = 1
    pseudoBtn.Font = Enum.Font.GothamBold
    pseudoBtn.TextSize = 12
    pseudoBtn.TextColor3 = Color3.fromRGB(255, 230, 0) -- JAUNE
    pseudoBtn.TextStrokeTransparency = 0.4
    pseudoBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    pseudoBtn.Text = "@"..player.Name
    pseudoBtn.AutoButtonColor = false
    pseudoBtn.Active = true
    pseudoBtn.Selectable = true
    pseudoBtn.ZIndex = 10
    pseudoBtn.Parent = infoFrame


    pseudoBtn.MouseEnter:Connect(function()
        pseudoBtn.TextColor3 = Color3.fromRGB(255, 255, 120)
    end)
    pseudoBtn.MouseLeave:Connect(function()
        pseudoBtn.TextColor3 = Color3.fromRGB(255, 230, 0)
    end)

    -- Clic = copie
    pseudoBtn.MouseButton1Click:Connect(function()
        local ok = copyName(player.Name)
        notify("ESP", (ok and "Copié : " or "Pseudo : ") .. player.Name)
        -- Flash vert
        pseudoBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
        task.delay(0.4, function()
            if pseudoBtn.Parent then
                pseudoBtn.TextColor3 = Color3.fromRGB(255, 230, 0)
            end
        end)
    end)

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Dist"
    distLabel.LayoutOrder = 3
    distLabel.AutomaticSize = Enum.AutomaticSize.X
    distLabel.Size = UDim2.new(0, 0, 1, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 11
    distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    distLabel.TextStrokeTransparency = 0.7
    distLabel.Text = "• 0m"
    distLabel.Parent = infoFrame

    -- Barre de vie
    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1, -10, 0, 4)
    hpBar.Position = UDim2.new(0, 5, 1, -8)
    hpBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = main

    local hpCorner = Instance.new("UICorner")
    hpCorner.CornerRadius = UDim.new(1, 0)
    hpCorner.Parent = hpBar

    local hpFill = Instance.new("Frame")
    hpFill.Name = "HPFill"
    hpFill.Size = UDim2.fromScale(1, 1)
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 80)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBar

    local hpFillCorner = Instance.new("UICorner")
    hpFillCorner.CornerRadius = UDim.new(1, 0)
    hpFillCorner.Parent = hpFill

    Cache[player] = {Highlight = highlight, Billboard = billboard}
end

local function removeESP(player: Player)
    local data = Cache[player]
    if data then
        data.Highlight:Destroy()
        data.Billboard:Destroy()
        Cache[player] = nil
    end
end

-- Update loop
RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then
        for _, data in pairs(Cache) do
            data.Highlight.Enabled = false
            data.Billboard.Enabled = false
        end
        return
    end

    for player, data in pairs(Cache) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not (char and hrp and hum) or hum.Health <= 0 then
            data.Highlight.Enabled = false
            data.Billboard.Enabled = false
            continue
        end

        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
        if dist > MAX_DISTANCE then
            data.Highlight.Enabled = false
            data.Billboard.Enabled = false
            continue
        end

        local job, color = getJob(player)

        data.Highlight.Adornee = char
        data.Highlight.Enabled = true
        data.Highlight.FillColor = color
        data.Highlight.OutlineColor = color

        data.Billboard.Adornee = hrp
        data.Billboard.Enabled = true

        local main = data.Billboard:FindFirstChild("Main")
        if main then
            local nameLabel = main:FindFirstChild("Name") :: TextLabel
            local infoFrame = main:FindFirstChild("InfoFrame")
            local stroke = main:FindFirstChildOfClass("UIStroke")
            local hpBar = main:FindFirstChild("HPBar")
            local hpFill = hpBar and hpBar:FindFirstChild("HPFill") :: Frame

            if stroke then stroke.Color = color end
            if nameLabel then
                nameLabel.TextColor3 = color
                nameLabel.Text = player.DisplayName
            end
            if infoFrame then
                local jobLabel = infoFrame:FindFirstChild("Job") :: TextLabel
                local distLabel = infoFrame:FindFirstChild("Dist") :: TextLabel
                if jobLabel then
                    jobLabel.Text = "["..job.."]"
                    jobLabel.TextColor3 = color
                end
                if distLabel then
                    distLabel.Text = "• "..math.floor(dist).."m"
                end
            end
            if hpFill and hum.MaxHealth > 0 then
                local pct = hum.Health / hum.MaxHealth
                hpFill.Size = UDim2.new(pct, 0, 1, 0)
                if pct > 0.6 then hpFill.BackgroundColor3 = Color3.fromRGB(0,255,80)
                elseif pct > 0.3 then hpFill.BackgroundColor3 = Color3.fromRGB(255,200,0)
                else hpFill.BackgroundColor3 = Color3.fromRGB(255,50,50) end
            end
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
Players.PlayerAdded:Connect(addESP)
Players.PlayerRemoving:Connect(removeESP)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T then
        ESP_ENABLED = not ESP_ENABLED
        notify("ESP", ESP_ENABLED and "✅" or "❌")
    end
end)
Redesign graphique du bouton mobile
Améliorations visuelles :

Bouton circulaire moderne avec dégradé subtil
Icône œil (ImageLabel) au lieu d'emoji texte
Anneau lumineux animé (glow/pulse) selon l'état
Indicateur de statut LED en bas
Animations fluides via TweenService (hover/toggle)
Effet de pression (scale down) au touch

-- ========== BOUTON MOBILE (REDESIGN) ==========
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
    local TweenService = game:GetService("TweenService")

    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "\0ESPMobile"
    mobileGui.ResetOnSpawn = false
    mobileGui.IgnoreGuiInset = true
    mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() mobileGui.Parent = CoreGui end)
    if not mobileGui.Parent then mobileGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Conteneur principal (pour le scale au press)
    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Size = UDim2.fromOffset(64, 64)
    holder.Position = UDim2.new(0, 24, 0.5, -32)
    holder.BackgroundTransparency = 1
    holder.Parent = mobileGui

    -- Anneau lumineux extérieur (glow)
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.fromScale(1.6, 1.6)
    glow.Position = UDim2.fromScale(0.5, 0.5)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://4996891970" -- soft radial glow
    glow.ImageColor3 = Color3.fromRGB(0, 255, 140)
    glow.ImageTransparency = 0.4
    glow.Parent = holder

    -- Bouton principal
    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    btn.BackgroundTransparency = 0.05
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Active = true
    btn.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    -- Dégradé interne
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 42, 52)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 16, 22)),
    })
    gradient.Parent = btn

    -- Stroke fin
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 255, 140)
    stroke.Transparency = 0.1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn

    -- Icône œil
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.fromScale(0.55, 0.55)
    icon.Position = UDim2.fromScale(0.5, 0.42)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://10709790644" -- eye icon (Roblox lucide)
    icon.ImageColor3 = Color3.fromRGB(0, 255, 140)
    icon.Parent = btn

    -- LED de statut
    local led = Instance.new("Frame")
    led.Name = "LED"
    led.Size = UDim2.fromOffset(8, 8)
    led.Position = UDim2.fromScale(0.5, 0.82)
    led.AnchorPoint = Vector2.new(0.5, 0.5)
    led.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
    led.BorderSizePixel = 0
    led.Parent = btn

    local ledCorner = Instance.new("UICorner")
    ledCorner.CornerRadius = UDim.new(1, 0)
    ledCorner.Parent = led

    local ledStroke = Instance.new("UIStroke")
    ledStroke.Color = Color3.fromRGB(0, 255, 140)
    ledStroke.Thickness = 3
    ledStroke.Transparency = 0.6
    ledStroke.Parent = led

    -- Animation de pulsation du glow
    local pulseRunning = true
    task.spawn(function()
        while pulseRunning and holder.Parent do
            TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.7}):Play()
            task.wait(1.2)
            TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.35}):Play()
            task.wait(1.2)
        end
    end)

    -- Fonction de mise à jour visuelle de l'état
    local function applyState(enabled: boolean)
        local col = enabled and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 70, 90)
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(stroke, tweenInfo, {Color = col}):Play()
        TweenService:Create(icon, tweenInfo, {ImageColor3 = col}):Play()
        TweenService:Create(glow, tweenInfo, {ImageColor3 = col}):Play()
        TweenService:Create(led, tweenInfo, {BackgroundColor3 = col}):Play()
        TweenService:Create(ledStroke, tweenInfo, {Color = col}):Play()
    end

    -- Drag + Press
    local dragging, dragStart, startPos, moved = false, nil, nil, false

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = holder.Position
            TweenService:Create(holder, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Size = UDim2.fromOffset(58, 58)}):Play()
        end
    end)

    btn.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            holder.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            TweenService:Create(holder, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(64, 64)}):Play()
            if not moved then
                ESP_ENABLED = not ESP_ENABLED
                applyState(ESP_ENABLED)
                notify("ESP", ESP_ENABLED and "✅ Activé" or "❌ Désactivé")
            end
        end
    end)
end
