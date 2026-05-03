--!strict
-- ─── 1. Globals (locals = +rapide, -hooks détectables) ───────────────────────
local _pcall      = pcall
local _mathrandom = math.random
local _mathfloor  = math.floor
local _osclock    = os.clock
local _stringbyte = string.byte
local _stringchar = string.char
local _tableconcat= table.concat
local _bxor       = bit32.bxor

-- ─── 2. Services ──────────────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local CAS        = game:GetService("ContextActionService")
local Workspace  = workspace
local Camera     = Workspace.CurrentCamera
local LP         = Players.LocalPlayer
if not LP then return end

-- ─── 3. Drawing ───────────────────────────────────────────────────────────────
local _Drawing: any
do
    for _, src in {
        function() return (_G    :: any).Drawing end,
        function() return (shared:: any).Drawing end,
        function() return getfenv and (getfenv :: any)(0)["Drawing"] or nil end,
    } do
        local ok, v = _pcall(src)
        if ok and v ~= nil then _Drawing = v; break end
    end
    if not _Drawing then return end
end

local function newDraw(kind: string): any
    local ok, obj = _pcall(function() return _Drawing.new(kind) end)
    return ok and obj or nil
end

-- ─── 4. newcclosure ───────────────────────────────────────────────────────────
local _newcc: (((...any)->...any)->(...any)->...any)
do
    local id = function(f) return f end
    local found: any = nil
    for _, src in {
        function() return getfenv and (getfenv :: any)(0)["newcclosure"] or nil end,
        function() return (_G    :: any).newcclosure end,
        function() return (shared:: any).newcclosure end,
    } do
        local ok, v = _pcall(src)
        if ok and type(v) == "function" then found = v; break end
    end
    _newcc = found or id
end

-- ─── 5. Clipboard ─────────────────────────────────────────────────────────────
local _clip: (s: string) -> ()
do
    local found: any = nil
    for _, src in {
        function() return getfenv and (getfenv :: any)(0)["setclipboard"] or nil end,
        function() return (_G    :: any).setclipboard end,
        function() return (shared:: any).setclipboard end,
        function() return getfenv and (getfenv :: any)(0)["toclipboard"] or nil end,
        function() return (_G    :: any).toclipboard end,
    } do
        local ok, v = _pcall(src)
        if ok and type(v) == "function" then found = v; break end
    end
    _clip = found or function() end
end

-- ─── 6. String obfuscation (XOR léger) ────────────────────────────────────────
local KEY = 0x5A
local function enc(s: string): {number}
    local t = {}
    for i = 1, #s do t[i] = _bxor(_stringbyte(s, i), KEY) end
    return t
end
local function dec(t: {number}): string
    local out = {}
    for i, b in t do out[i] = _stringchar(_bxor(b, KEY)) end
    return _tableconcat(out)
end

local S = {
    on    = enc("ESP ON [T]"),
    off   = enc("ESP OFF [T]"),
    copy  = enc("Copie : @"),
}

-- ─── 7. Config ────────────────────────────────────────────────────────────────
local CFG = {
    key       = Enum.KeyCode.T,
    pollRate  = 1.25,
    maxDist   = 600,
    textSize  = 14,
    font      = 2,
    color     = Color3.fromRGB(255, 255, 255),
    outline   = true,
    onColor   = Color3.fromRGB(120, 255, 120),
    offColor  = Color3.fromRGB(255, 120, 120),
    feedColor = Color3.fromRGB(255, 220, 120),
    padding   = 8,
}

-- ─── 8. State ─────────────────────────────────────────────────────────────────
type Entry = {
    player  : Player,
    label   : any,
    visible : boolean,
    bbX     : number,
    bbY     : number,
    bbW     : number,
    bbH     : number,
}

local Cache: {[number]: Entry} = {}
local enabled = false

-- ─── 9. Feed (HUD) ────────────────────────────────────────────────────────────
local feedLabel: any = newDraw("Text")
local feedUntil = 0
if feedLabel then
    feedLabel.Center   = true
    feedLabel.Outline  = true
    feedLabel.Font     = CFG.font
    feedLabel.Size     = 16
    feedLabel.Color    = CFG.feedColor
    feedLabel.Visible  = false
end

local function showFeed(text: string, color: Color3, dur: number)
    if not feedLabel then return end
    _pcall(function()
        local vp = Camera.ViewportSize
        feedLabel.Position = Vector2.new(vp.X / 2, 40)
        feedLabel.Text     = text
        feedLabel.Color    = color
        feedLabel.Visible  = true
    end)
    feedUntil = _osclock() + dur
end

-- ─── 10. Entry mgmt ───────────────────────────────────────────────────────────
local function destroyEntry(e: Entry)
    if e.label then _pcall(function() e.label:Remove() end) end
end

local function makeEntry(plr: Player): Entry
    local lbl = newDraw("Text")
    if lbl then
        lbl.Center   = true
        lbl.Outline  = CFG.outline
        lbl.Font     = CFG.font
        lbl.Size     = CFG.textSize
        lbl.Color    = CFG.color
        lbl.Visible  = false
    end
    return {
        player = plr, label = lbl, visible = false,
        bbX = 0, bbY = 0, bbW = 0, bbH = 0,
    }
end

-- ─── 11. Poll ─────────────────────────────────────────────────────────────────
local function poll()
    local seen: {[number]: boolean} = {}
    for _, plr in Players:GetPlayers() do
        if plr ~= LP then
            seen[plr.UserId] = true
            if not Cache[plr.UserId] then
                Cache[plr.UserId] = makeEntry(plr)
            end
        end
    end
    for uid, entry in Cache do
        if not seen[uid] then
            destroyEntry(entry)
            Cache[uid] = nil
        end
    end
end

-- ─── 12. Render ───────────────────────────────────────────────────────────────
local function renderEntry(entry: Entry)
    local lbl = entry.label
    if not lbl then return end

    if not enabled then
        if entry.visible then lbl.Visible = false; entry.visible = false end
        return
    end

    local plr = entry.player
    local char = plr.Character
    if not char then lbl.Visible = false; entry.visible = false; return end
    local head = char:FindFirstChild("Head")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then lbl.Visible = false; entry.visible = false; return end

    local myChar = LP.Character
    local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myHrp then
        local d = (myHrp.Position - hrp.Position).Magnitude
        if d > CFG.maxDist then lbl.Visible = false; entry.visible = false; return end
    end

    local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.8, 0))
    if not onScreen then lbl.Visible = false; entry.visible = false; return end

    lbl.Position = Vector2.new(pos.X, pos.Y)
    lbl.Text     = "@" .. plr.Name
    lbl.Visible  = true
    entry.visible = true

    -- Bounding box pour hit-test clic
    local tb = lbl.TextBounds
    if tb then
        local w = tb.X + CFG.padding * 2
        local h = tb.Y + CFG.padding * 2
        entry.bbX = pos.X - w / 2
        entry.bbY = pos.Y - h / 2
        entry.bbW = w
        entry.bbH = h
    end
end

-- ─── 13. Copy ─────────────────────────────────────────────────────────────────
local function copyPlayer(plr: Player)
    local at = "@" .. plr.Name
    _pcall(function() _clip(at) end)
    showFeed(dec(S.copy) .. plr.Name, CFG.feedColor, 1.5)
end

-- ─── 14. Toggle ───────────────────────────────────────────────────────────────
local lastToggle = 0
local function onToggle()
    local now = _osclock()
    if now - lastToggle < 0.15 then return end
    lastToggle = now

    enabled = not enabled
    if not enabled then
        for _, entry in Cache do
            if entry.label then _pcall(function() entry.label.Visible = false end) end
            entry.visible = false
        end
    end
    showFeed(
        enabled and dec(S.on) or dec(S.off),
        enabled and CFG.onColor or CFG.offColor,
        1.5
    )
end

-- ─── 15. Input · ContextActionService (priorité haute) ───────────────────────
local ACTION_NAME = "_" .. tostring(_mathrandom(100000, 999999))
_pcall(function()
    CAS:BindActionAtPriority(
        ACTION_NAME,
        _newcc(function(_, state: Enum.UserInputState)
            if state == Enum.UserInputState.Begin then
                onToggle()
            end
            return Enum.ContextActionResult.Pass
        end),
        false,
        Enum.ContextActionPriority.High.Value,
        CFG.key
    )
end)

-- ─── 16. Input · InputBegan (fallback T + clic copie) ─────────────────────────
UIS.InputBegan:Connect(_newcc(function(input: InputObject, gp: boolean)
    if input.KeyCode == CFG.key then
        onToggle()
        return
    end

    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not enabled then return end

    local mp = UIS:GetMouseLocation()
    local mx, my = mp.X, mp.Y

    local bestEntry: Entry? = nil
    local bestDist = math.huge

    for _, entry in Cache do
        if entry.visible then
            if mx >= entry.bbX and mx <= entry.bbX + entry.bbW
            and my >= entry.bbY and my <= entry.bbY + entry.bbH then
                if entry.bbY < bestDist then
                    bestDist  = entry.bbY
                    bestEntry = entry
                end
            end
        end
    end

    if bestEntry then
        _pcall(copyPlayer, bestEntry.player)
    end
end))

-- ─── 17. Render loop ──────────────────────────────────────────────────────────
local lastPoll   = 0
local lastRender = 0
local jitter     = 0.033

local sig = (RunService :: any).PreRender or RunService.RenderStepped

sig:Connect(_newcc(function()
    local now = _osclock()

    if now - lastPoll >= CFG.pollRate then
        lastPoll = now
        _pcall(poll)
    end

    if now - lastRender >= jitter then
        lastRender = now
        jitter     = 0.028 + _mathrandom() * 0.016
        for _, entry in Cache do
            _pcall(renderEntry, entry)
        end
    end

    if feedLabel and feedLabel.Visible and now >= feedUntil then
        feedLabel.Visible = false
    end
end))

-- ─── 18. Cleanup ──────────────────────────────────────────────────────────────
local cleaned = false
local function cleanup()
    if cleaned then return end
    cleaned = true
    _pcall(function() CAS:UnbindAction(ACTION_NAME) end)
    for uid, entry in Cache do
        destroyEntry(entry)
        Cache[uid] = nil
    end
    if feedLabel then _pcall(function() feedLabel:Remove() end) end
end

LP.AncestryChanged:Connect(_newcc(function(_, p: Instance?)
    if not p then cleanup() end
end))
if script then _pcall(function() script.Destroying:Connect(cleanup) end) end

-- ─── 19. Init (OFF par défaut) ────────────────────────────────────────────────
showFeed(dec(S.off), CFG.offColor, 2)
