--!strict
-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ESP  ·  LocalScript  ·  Security Test PoC                  ║
-- ║  Auteur : collaboration développeur / test anticheat         ║
-- ║  Usage  : cadre de test de sécurité autorisé uniquement      ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ─── Services ────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")

-- ─── Références locales ───────────────────────────────────────────────────────
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ─── Configuration ────────────────────────────────────────────────────────────
local ESP_ENABLED  = true
local MAX_DISTANCE = 5000

-- ─── Utilitaires d'indétectabilité ───────────────────────────────────────────
-- Génère un nom d'instance aléatoire pour éviter les patterns fixes
-- scannés par les anticheat basés sur regex/nom d'instance.
local CHARSET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function randomName(len: number): string
    local out = {}
    for _ = 1, len do
        local idx = math.random(1, #CHARSET)
        out[#out + 1] = CHARSET:sub(idx, idx)
    end
    return table.concat(out)
end

-- Wrappers d'accès aux fonctions executor — évite les détections par
-- scan de globals non-standard exposées en clair dans le bytecode.
local _setclipboard: ((s: string) -> ())? = (getfenv :: any)()["set" .. "clipboard"]

-- ─── Conteneur ESP (CoreGui ou PlayerGui fallback) ────────────────────────────
-- Le nom du conteneur est randomisé à chaque exécution.
local Container: Folder
do
    local f = Instance.new("Folder")
    f.Name = randomName(12) -- nom aléatoire, non signable par regex
    local ok = pcall(function() f.Parent = CoreGui end)
    if not ok or not f.Parent then
        f.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    Container = f
end

-- ─── Types ────────────────────────────────────────────────────────────────────
type ESPEntry = {
    Highlight : Highlight,
    Billboard : BillboardGui,
    Connections: { RBXScriptConnection },
}

-- ─── Cache ────────────────────────────────────────────────────────────────────
local Cache: { [Player]: ESPEntry } = {}

-- ─── Helpers UI ──────────────────────────────────────────────────────────────
local function notify(title: string, text: string)
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title    = title,
        Text     = text,
        Duration = 2,
    })
end

local function copyToClipboard(text: string): boolean
    if _setclipboard then
        _setclipboard(text)
        return true
    end
    return false
end

-- ─── Logique métier ──────────────────────────────────────────────────────────
-- Retourne le rôle et la couleur associée selon l'équipe du joueur.
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

-- ─── Création de l'ESP par joueur ─────────────────────────────────────────────
local function addESP(player: Player)
    if player == LocalPlayer then return end
    if Cache[player] then return end

    local connections: { RBXScriptConnection } = {}

    -- Highlight — adornee assigné dynamiquement dans le Heartbeat
    local highlight = Instance.new("Highlight")
    highlight.Name                = randomName(8)
    highlight.FillTransparency    = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled             = false
    highlight.Parent              = Container

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name           = randomName(8)
    billboard.Size           = UDim2.new(0, 120, 0, 38)
    billboard.StudsOffset    = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop    = true
    billboard.LightInfluence = 0
    billboard.Active         = true
    billboard.MaxDistance    = MAX_DISTANCE
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboard.Enabled        = false
    billboard.Parent         = Container

    -- Fond arrondi
    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.fromScale(1, 1)
    frame.BackgroundColor3       = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel        = 0
    frame.Parent                 = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent       = frame

    local stroke = Instance.new("UIStroke")
    stroke.Name      = "JobStroke"
    stroke.Color     = Color3.fromRGB(245, 0, 0)
    stroke.Thickness = 1.5
    stroke.Parent    = frame

    -- Layout vertical pour les deux labels
    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 1)
    layout.Parent              = frame

    -- Label nom
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name                   = "NameLabel"
    nameLabel.Size                   = UDim2.new(1, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3             = Color3.fromRGB(235, 235, 255)
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextSize               = 12
    nameLabel.TextXAlignment         = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment         = Enum.TextYAlignment.Center
    nameLabel.Text                   = "" .. player.Name
    nameLabel.Parent                 = frame

    -- Label job (manquant dans l'original — bug corrigé)
    local jobLabel = Instance.new("TextLabel")
    jobLabel.Name                   = "JobLabel"
    jobLabel.Size                   = UDim2.new(1, 0, 0, 14)
    jobLabel.BackgroundTransparency = 1
    jobLabel.Font                   = Enum.Font.Gotham
    jobLabel.TextSize               = 10
    jobLabel.TextXAlignment         = Enum.TextXAlignment.Center
    jobLabel.TextYAlignment         = Enum.TextYAlignment.Center
    jobLabel.Text                   = "CIVIL"
    jobLabel.TextColor3             = Color3.fromRGB(12, 255, 174)
    jobLabel.Parent                 = frame

    -- Bouton clic (copie du pseudo)
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size                   = UDim2.fromScale(1, 1)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text                   = ""
    clickBtn.ZIndex                 = 10
    clickBtn.Parent                 = frame

    local lastClick = 0
    local c1 = clickBtn.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastClick < 0.6 then return end
        lastClick = now
        local tag = "@" .. player.Name
        if copyToClipboard(tag) then
            notify("ESP · Copié", tag)
        else
            notify("ESP · Info", "setclipboard indisponible")
        end
    end)
    connections[#connections + 1] = c1

    Cache[player] = {
        Highlight   = highlight,
        Billboard   = billboard,
        Connections = connections,
    }
end

-- ─── Suppression propre de l'ESP ──────────────────────────────────────────────
local function removeESP(player: Player)
    local entry = Cache[player]
    if not entry then return end

    -- Déconnexion des événements avant destruction (évite les fuites)
    for _, conn in entry.Connections do
        conn:Disconnect()
    end

    pcall(function() entry.Highlight:Destroy() end)
    pcall(function() entry.Billboard:Destroy() end)
    Cache[player] = nil
end

-- ─── Initialisation des joueurs existants ─────────────────────────────────────
for _, p in Players:GetPlayers() do
    task.spawn(addESP, p)
end
Players.PlayerAdded:Connect(addESP)
Players.PlayerRemoving:Connect(removeESP)

-- ─── Heartbeat principal ──────────────────────────────────────────────────────
-- Throttlé à ~20 Hz (toutes les 3 frames ~60 fps) pour réduire
-- la charge CPU et limiter la surface de détection par profiling.
local _tick = 0
RunService.Heartbeat:Connect(function()
    _tick += 1
    if _tick % 3 ~= 0 then return end

    for player, entry in Cache do
        -- ESP désactivé : éteindre toutes les entrées et continuer
        if not ESP_ENABLED then
            entry.Highlight.Enabled = false
            entry.Billboard.Enabled = false
            continue
        end

        -- Récupération sécurisée du personnage
        local char = player.Character
        if not char or not char:IsDescendantOf(workspace) then
            entry.Highlight.Enabled = false
            entry.Billboard.Enabled = false
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not hrp then
            entry.Highlight.Enabled = false
            entry.Billboard.Enabled = false
            continue
        end

        -- Calcul de distance caméra → personnage
        local dist    = (hrp.Position - Camera.CFrame.Position).Magnitude
        local inRange = dist <= MAX_DISTANCE

        entry.Highlight.Enabled  = inRange
        entry.Billboard.Enabled  = inRange

        -- Adornee : corrigé (manquant dans l'original pour le Highlight)
        if entry.Highlight.Adornee ~= char then
            entry.Highlight.Adornee = char
        end
        if entry.Billboard.Adornee ~= hrp then
            entry.Billboard.Adornee = hrp
        end

        -- Mise à jour des labels uniquement si visible
        if inRange then
            local jobName, jobColor = getJobInfo(player)
            local bb    = entry.Billboard
            local fr    = bb:FindFirstChildOfClass("Frame")
            if fr then
                local s  = fr:FindFirstChild("JobStroke")   :: UIStroke?
                local nl = fr:FindFirstChild("NameLabel")   :: TextLabel?
                local jl = fr:FindFirstChild("JobLabel")    :: TextLabel?
                if s  then s.Color       = jobColor end
                if nl then nl.Text       = "@" .. player.Name end
                if jl then
                    jl.Text       = jobName
                    jl.TextColor3 = jobColor
                end
            end
        end
    end
end)

-- ─── Toggle clavier (T) ───────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T then
        ESP_ENABLED = not ESP_ENABLED
        notify("ESP", ESP_ENABLED and "Activé" or "Désactivé")
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
--  BOUTON FLOTTANT (ScreenGui)
-- ═════════════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = randomName(10)
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local sgOk = pcall(function() screenGui.Parent = CoreGui end)
if not sgOk or not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Conteneur principal du bouton
local holder = Instance.new("Frame")
holder.Name                   = "Holder"
holder.Size                   = UDim2.fromOffset(64, 64)
holder.Position               = UDim2.new(1, -80, 0.5, -32)
holder.BackgroundColor3       = Color3.fromRGB(15, 15, 20)
holder.BackgroundTransparency = 0.2
holder.BorderSizePixel        = 0
holder.Parent                 = screenGui

local holderCorner = Instance.new("UICorner")
holderCorner.CornerRadius = UDim.new(1, 0)
holderCorner.Parent       = holder

local holderStroke = Instance.new("UIStroke")
holderStroke.Color     = Color3.fromRGB(0, 255, 140)
holderStroke.Thickness = 2
holderStroke.Parent    = holder

-- Icône centrale
local icon = Instance.new("ImageLabel")
icon.Size                   = UDim2.fromOffset(34, 34)
icon.Position               = UDim2.new(0.5, -17, 0.5, -17)
icon.BackgroundTransparency = 1
icon.Image                  = "rbxassetid://73235408221031"
icon.ImageColor3            = Color3.fromRGB(0, 255, 140)
icon.ScaleType              = Enum.ScaleType.Fit
icon.Parent                 = holder

-- Halo lumineux (glow)
local glow = Instance.new("ImageLabel")
glow.Size                   = UDim2.fromOffset(80, 80)
glow.Position               = UDim2.new(0.5, -40, 0.5, -40)
glow.BackgroundTransparency = 1
glow.Image                  = "rbxassetid://5028857084"
glow.ImageColor3            = Color3.fromRGB(0, 255, 140)
glow.ImageTransparency      = 0.5
glow.ZIndex                 = 0
glow.Parent                 = holder

-- LED d'état (coin supérieur droit)
local led = Instance.new("Frame")
led.Size             = UDim2.fromOffset(10, 10)
led.Position         = UDim2.new(1, -12, 0, 2)
led.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
led.BorderSizePixel  = 0
led.ZIndex           = 5
led.Parent           = holder

local ledCorner = Instance.new("UICorner")
ledCorner.CornerRadius = UDim.new(1, 0)
ledCorner.Parent       = led

local ledStroke = Instance.new("UIStroke")
ledStroke.Color     = Color3.fromRGB(255, 255, 255)
ledStroke.Thickness = 1
ledStroke.Parent    = led

-- Zone d'interaction (bouton transparent par-dessus tout)
local btn = Instance.new("TextButton")
btn.Size                   = UDim2.fromScale(1, 1)
btn.BackgroundTransparency = 1
btn.Text                   = ""
btn.ZIndex                 = 10
btn.Parent                 = holder

-- ─── Animation de pulsation du halo ──────────────────────────────────────────
-- Utilise une connexion RenderStepped détruite avec le holder
-- plutôt qu'une boucle `while true` pour éviter les goroutines orphelines.
local glowConn: RBXScriptConnection
do
    local glowPhase  = false
    local glowClock  = 0
    local GLOW_PERIOD = 1.2

    glowConn = RunService.Heartbeat:Connect(function(dt: number)
        -- Vérification que le holder existe encore
        if not holder.Parent then
            glowConn:Disconnect()
            return
        end
        glowClock += dt
        if glowClock < GLOW_PERIOD then return end
        glowClock = 0
        glowPhase = not glowPhase
        TweenService:Create(
            glow,
            TweenInfo.new(GLOW_PERIOD, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { ImageTransparency = glowPhase and 0.35 or 0.7 }
        ):Play()
    end)
end

-- ─── Synchronisation visuelle état ESP ───────────────────────────────────────
local function applyState(enabled: boolean)
    local col       = enabled and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 70, 90)
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(holderStroke, tweenInfo, { Color = col }):Play()
    TweenService:Create(icon,        tweenInfo, { ImageColor3 = col }):Play()
    TweenService:Create(glow,        tweenInfo, { ImageColor3 = col }):Play()
    TweenService:Create(led,         tweenInfo, { BackgroundColor3 = col }):Play()
    TweenService:Create(ledStroke,   tweenInfo, { Color = col }):Play()
end

-- État visuel initial cohérent avec ESP_ENABLED
applyState(ESP_ENABLED)

-- ─── Drag & tap (tactile) ─────────────────────────────────────────────────────
local dragging  = false
local dragStart: Vector3 = Vector3.zero
local startPos  = holder.Position
local moved     = false

btn.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging  = true
    moved     = false
    dragStart = input.Position
    startPos  = holder.Position
    TweenService:Create(
        holder,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad),
        { Size = UDim2.fromOffset(58, 58) }
    ):Play()
end)

btn.InputChanged:Connect(function(input: InputObject)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    if delta.Magnitude > 6 then moved = true end
    holder.Position = UDim2.new(
        startPos.X.Scale,  startPos.X.Offset  + delta.X,
        startPos.Y.Scale,  startPos.Y.Offset  + delta.Y
    )
end)

btn.InputEnded:Connect(function(input: InputObject)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = false
    TweenService:Create(
        holder,
        TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(64, 64) }
    ):Play()
    if not moved then
        ESP_ENABLED = not ESP_ENABLED
        applyState(ESP_ENABLED)
        notify("ESP", ESP_ENABLED and "Activé" or "Désactivé")
    end
end)

-- ─── Clic souris (desktop) ────────────────────────────────────────────────────
btn.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    applyState(ESP_ENABLED)
    notify("ESP", ESP_ENABLED and "Activé" or "Désactivé")
end)
