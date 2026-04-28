--!strict
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer  = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local ESP_ENABLED  = true
local MAX_DISTANCE = 5000
local Container = Instance.new("Folder")
Container.Name = "\0ESP"
pcall(function() Container.Parent = CoreGui end)
if not Container.Parent then
    Container.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
type ESPEntry = {
    Highlight : Highlight,
    Billboard : BillboardGui,
}
local Cache: { [Player]: ESPEntry } = {}
local function notify(title: string, text: string)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = 2,
        })
    end)
end
local function copyToClipboard(text: string): boolean
    if setclipboard then
        setclipboard(text)
        return true
    end
    return false
end

local function getJobInfo(player: Player): (string, Color3)
    if player.Team then
        local n = player.Team.Name:lower()
        if n:find("police") or n:find("polizei") then
            return "POLICE", Color3.fromRGB(0, 44, 88)
        end
        if n:find("medic") or n:find("rettung") or n:find("sanit") then
            return "MEDIC", Color3.fromRGB(216, 0, 0)
        end
        if n:find("fire") or n:find("feuer") then
            return "FIRE", Color3.fromRGB(117, 0, 0)
        end
    end
    return "CIVIL", Color3.fromRGB(12, 255, 174)
end

local function addESP(player: Player)
    if player == LocalPlayer then return end
    if Cache[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name               = "H_" .. player.Name
    highlight.FillTransparency   = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent             = Container
    local billboard = Instance.new("BillboardGui")
    billboard.Name            = "B_" .. player.Name
    billboard.Size            = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset     = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop     = true
    billboard.LightInfluence  = 0
    billboard.Active          = true
    billboard.MaxDistance     = MAX_DISTANCE
    billboard.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    billboard.Parent          = Container
    local frame = Instance.new("Frame")
    frame.Size            = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(230, 230, 253)
    frame.BackgroundTransparency = 0.75
    frame.BorderSizePixel = 0
    frame.Parent          = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.fromRGB(245, 0, 0)
    stroke.Thickness = 1.5
    stroke.Parent    = frame
   local nameLabel = Instance.new("TextLabel")
   nameLabel.Name                   = "NameLabel"
   nameLabel.Size          = UDim2.new(1, 0, 0.5, 0)
   nameLabel.Position      = UDim2.new(0, 0, 0, 0)
   nameLabel.TextXAlignment = Enum.TextXAlignment.Center
nameLabel.TextYAlignment = Enum.TextYAlignment.Center  
   nameLabel.BackgroundTransparency = 1
   nameLabel.TextColor3             = Color3.fromRGB(0, 0, 0)
   nameLabel.Font                   = Enum.Font.GothamBold
   nameLabel.TextScaled             = true   
   nameLabel.Text                   = ":" .. player.Name
   nameLabel.Parent                 = frame
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size                 = UDim2.fromScale(1, 1)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text                 = ""
    clickBtn.ZIndex               = 10
    clickBtn.Parent               = frame
    local lastClick = 0
    clickBtn.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastClick < 0.6 then return end
        lastClick = now

        local tag = "" .. player.Name
        local ok = copyToClipboard(tag)
        if ok then
            notify("Copied", tag)
        else
            warn("[ESP] setclipboard indisponible — pseudo : " .. tag)
            notify("Bug", "Contact owner")
        end
    end)

    Cache[player] = { Highlight = highlight, Billboard = billboard }
end
local function removeESP(player: Player)
    local entry = Cache[player]
    if not entry then return end
    pcall(function() entry.Highlight:Destroy() end)
    pcall(function() entry.Billboard:Destroy() end)
    Cache[player] = nil
end

for _, p in Players:GetPlayers() do
    task.spawn(addESP, p)
end
Players.PlayerAdded:Connect(addESP)
Players.PlayerRemoving:Connect(removeESP)

RunService.Heartbeat:Connect(function()
    if not ESP_ENABLED then
        for _, entry in Cache do
            entry.Highlight.Enabled = false
            entry.Billboard.Enabled = false
        end
        return
    end

    for player, entry in Cache do
        local ok, char = pcall(function()
            return player.Character
        end)
        if not ok or not char then
            entry.Highlight.Enabled  = false
            entry.Billboard.Enabled  = false
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or not char:IsDescendantOf(workspace) then
            entry.Highlight.Enabled  = false
            entry.Billboard.Enabled  = false
            continue
        end

        -- Sa mere la pute la distance enfin
        local camPos  = Camera.CFrame.Position
        local dist    = (hrp.Position - camPos).Magnitude
        local inRange = dist <= MAX_DISTANCE

        entry.Highlight.Enabled  = inRange
        entry.Billboard.Enabled  = inRange
        entry.Billboard.Adornee  = hrp

        if inRange then
            local jobName, jobColor = getJobInfo(player)
            local bb   = entry.Billboard
            local frame = bb:FindFirstChildOfClass("Frame")
            if frame then
                local stroke = frame:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = jobColor end
                local nameLabel = frame:FindFirstChild("NameLabel")
                if nameLabel then
                    (nameLabel :: TextLabel).Text = "@" .. player.Name
                end
                local jobLabel = frame:FindFirstChild("JobLabel")
                if jobLabel then
                    (jobLabel :: TextLabel).Text      = jobName
                    ;(jobLabel :: TextLabel).TextColor3 = jobColor
                end
            end
        end
    end
end)


-- T 
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T then
        ESP_ENABLED = not ESP_ENABLED
        notify("ESP", ESP_ENABLED and "Activer" or "Cacher")
    end
end)
local screenGui = Instance.new("ScreenGui")
screenGui.Name              = "ESPToggleGui"
screenGui.ResetOnSpawn      = false
screenGui.IgnoreGuiInset    = true
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local holder = Instance.new("Frame")
holder.Name                  = "Holder"
holder.Size                  = UDim2.fromOffset(64, 64)
holder.Position              = UDim2.new(1, -80, 0.5, -32)
holder.BackgroundColor3      = Color3.fromRGB(15, 15, 20)
holder.BackgroundTransparency = 0.2
holder.BorderSizePixel       = 0
holder.Parent                = screenGui
local holderCorner = Instance.new("UICorner")
holderCorner.CornerRadius = UDim.new(1, 0)
holderCorner.Parent = holder
local holderStroke = Instance.new("UIStroke")
holderStroke.Color     = Color3.fromRGB(0, 255, 140)
holderStroke.Thickness = 2
holderStroke.Parent    = holder
local icon = Instance.new("ImageLabel")
icon.Size                  = UDim2.fromOffset(34, 34)
icon.Position              = UDim2.new(0.5, -17, 0.5, -17)
icon.BackgroundTransparency = 1
icon.Image                 = "rbxassetid://73235408221031"
icon.ImageColor3           = Color3.fromRGB(0, 255, 140)
icon.ScaleType             = Enum.ScaleType.Fit
icon.Parent                = holder
local glow = Instance.new("ImageLabel")
glow.Size                  = UDim2.fromOffset(80, 80)
glow.Position              = UDim2.new(0.5, -40, 0.5, -40)
glow.BackgroundTransparency = 1
glow.Image                 = "rbxassetid://5028857084"
glow.ImageColor3           = Color3.fromRGB(0, 255, 140)
glow.ImageTransparency     = 0.5
glow.ZIndex                = 0
glow.Parent                = holder
local led = Instance.new("Frame")
led.Size             = UDim2.fromOffset(10, 10)
led.Position         = UDim2.new(1, -12, 0, 2)
led.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
led.BorderSizePixel  = 0
led.ZIndex           = 5
led.Parent           = holder
local ledCorner = Instance.new("UICorner")
ledCorner.CornerRadius = UDim.new(1, 0)
ledCorner.Parent = led

local ledStroke = Instance.new("UIStroke")
ledStroke.Color     = Color3.fromRGB(255, 255, 255)
ledStroke.Thickness = 1
ledStroke.Parent    = led
local btn = Instance.new("TextButton")
btn.Size                  = UDim2.fromScale(1, 1)
btn.BackgroundTransparency = 1
btn.Text                  = ""
btn.ZIndex                = 10
btn.Parent                = holder
task.spawn(function()
    while holder.Parent do
        TweenService:Create(glow,
            TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { ImageTransparency = 0.7 }
        ):Play()
        task.wait(1.2)
        TweenService:Create(glow,
            TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { ImageTransparency = 0.35 }
        ):Play()
        task.wait(1.2)
    end
end)
local function applyState(enabled: boolean)
    local col      = enabled and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 70, 90)
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(holderStroke, tweenInfo, { Color = col }):Play()
    TweenService:Create(icon,        tweenInfo, { ImageColor3 = col }):Play()
    TweenService:Create(glow,        tweenInfo, { ImageColor3 = col }):Play()
    TweenService:Create(led,         tweenInfo, { BackgroundColor3 = col }):Play()
    TweenService:Create(ledStroke,   tweenInfo, { Color = col }):Play()
end
local dragging  = false
local dragStart: Vector3? = nil
local startPos: UDim2?   = nil
local moved     = false
btn.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging  = true
    moved     = false
    dragStart = input.Position
    startPos  = holder.Position
    TweenService:Create(holder,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad),
        { Size = UDim2.fromOffset(58, 58) }
    ):Play()
end)
btn.InputChanged:Connect(function(input: InputObject)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - (dragStart :: Vector3)
    if delta.Magnitude > 6 then moved = true end
    local sp = startPos :: UDim2
    holder.Position = UDim2.new(
        sp.X.Scale, sp.X.Offset + delta.X,
        sp.Y.Scale, sp.Y.Offset + delta.Y
    )
end)
btn.InputEnded:Connect(function(input: InputObject)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = false
    TweenService:Create(holder,
        TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(64, 64) }
    ):Play()
    if not moved then
        ESP_ENABLED = not ESP_ENABLED
        applyState(ESP_ENABLED)
        notify("ESP", ESP_ENABLED and "Allumé" or "Eteint")
    end
end)
