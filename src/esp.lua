
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
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "\0ESPMobile"
    mobileGui.ResetOnSpawn = false
    mobileGui.IgnoreGuiInset = true
    mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() mobileGui.Parent = CoreGui end)
    if not mobileGui.Parent then mobileGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.Size = UDim2.fromOffset(60, 60)
    btn.Position = UDim2.new(0, 20, 0.5, -30)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btn.BackgroundTransparency = 0.25
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(0, 255, 100)
    btn.TextStrokeTransparency = 0.5
    btn.Text = "ESP\n✅"
    btn.AutoButtonColor = false
    btn.Active = true
    btn.Parent = mobileGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Parent = btn

    local dragging, dragStart, startPos, moved = false, nil, nil, false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            btn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if not moved then
                ESP_ENABLED = not ESP_ENABLED
                btn.Text = "ESP\n"..(ESP_ENABLED and "✅" or "❌")
                local col = ESP_ENABLED and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
                btn.TextColor3 = col
                stroke.Color = col
                notify("ESP", ESP_ENABLED and "✅" or "❌")
            end
        end
    end)
end

