-- ╔══════════════════════════════════════════════════════════════╗
-- ║  MM2 COMPACT SUITE v2  |  Delta Executor  |  by ENI for LO    ║
-- ║  Движение · Визуал · Мир · Боёвка · Фарм · Инфо · Флинг · Anti ║
-- ║  + Косметика на персонажа · Вкладки · Анимации UI             ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local Debris            = game:GetService("Debris")

local LP = Players.LocalPlayer
local CAM = Workspace.CurrentCamera

for _, name in ipairs({"MM2_Suite", "MM2_Orb"}) do
    local old = game.CoreGui:FindFirstChild(name)
    if old then old:Destroy() end
end

-- ────────────────────────────────────────────────────────────────
--  STATE
-- ────────────────────────────────────────────────────────────────
local S = {
    speedEnabled = false, speedValue = 60,
    noclip = false,
    fly = false, flySpeed = 80,
    playerESP = false, roleESP = false, itemESP = false,
    chams = false, fullbright = false,
    aimbot = false, silentAim = false, autoShoot = false,
    aimKey = Enum.UserInputType.MouseButton2,
    autoCoins = false, autoPickup = false, godMode = false,
    coinVacuum = false, autoEquipGun = false, autoDodge = false,
    muteAll = false,
    roleDetector = false, playerList = false,
    pingDisplay = false, roundTimer = false,
    flingMurder = false, flingSheriff = false,
    flingMode = "ForcePush",
    antiFling = true, voidCatch = true,
    antiSpin = true, weldDetect = true,
    antiAFK = true, antiRagdoll = true,
    -- Мир
    worldTime = false, worldTimeVal = 14,
    worldBrightness = false, worldBrightVal = 2,
    worldFog = false, worldFogColor = Color3.fromRGB(120,120,150),
    worldAmbient = false, worldAmbientColor = Color3.fromRGB(180,180,200),
    worldBlur = false, worldBloom = false,
    worldColorCorrection = false, worldCCColor = Color3.fromRGB(255,240,220),
    worldDepthOfField = false,
    worldSunRays = false,
    -- Косметика
    cosHat = "None", cosWings = false, cosAura = "None",
    cosTrail = false, cosOrbit = false,
    -- UI
    accentHue = 0,
    uiScaleVal = 1,
}

local connections = {}
local flyBV, flyBG
local espCache = {}
local lastValidPos = nil
local cosParts = {}
local worldEffects = {}
local currentTab = nil
local fpsTick, fpsCount = tick(), 0
local fpsValue = 0

-- ────────────────────────────────────────────────────────────────
--  ROOT
-- ────────────────────────────────────────────────────────────────
local Root = Instance.new("ScreenGui")
Root.Name = "MM2_Suite"
Root.ResetOnSpawn = false
Root.IgnoreGuiInset = true
Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Root.Parent = game.CoreGui

-- ────────────────────────────────────────────────────────────────
--  ORB
-- ────────────────────────────────────────────────────────────────
local Orb = Instance.new("Frame")
Orb.Name = "MM2_Orb"
Orb.Size = UDim2.new(0, 62, 0, 62)
Orb.Position = UDim2.new(0, 60, 0, 260)
Orb.BackgroundColor3 = Color3.fromRGB(24, 20, 32)
Orb.BorderSizePixel = 0
Orb.Active = true
Orb.Draggable = true
Orb.Parent = Root

Instance.new("UICorner", Orb).CornerRadius = UDim.new(1, 0)

local orbStroke = Instance.new("UIStroke")
orbStroke.Thickness = 2
orbStroke.Color = Color3.fromRGB(180, 120, 255)
orbStroke.Transparency = 0.15
orbStroke.Parent = Orb

local orbGrad = Instance.new("UIGradient")
orbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 90, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 180)),
})
orbGrad.Rotation = 45
orbGrad.Parent = orbStroke

local orbLabel = Instance.new("TextLabel")
orbLabel.Size = UDim2.fromScale(1, 1)
orbLabel.BackgroundTransparency = 1
orbLabel.Text = "ENI"
orbLabel.TextColor3 = Color3.fromRGB(240, 230, 255)
orbLabel.Font = Enum.Font.GothamBold
orbLabel.TextSize = 20
orbLabel.Parent = Orb

TweenService:Create(orbStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Transparency = 0.55
}):Play()
TweenService:Create(orbGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {
    Rotation = 405
}):Play()

-- ────────────────────────────────────────────────────────────────
--  WINDOW
-- ────────────────────────────────────────────────────────────────
local Win = Instance.new("Frame")
Win.Size = UDim2.new(0, 400, 0, 320)
Win.Position = UDim2.new(0.5, -200, 0.5, -160)
Win.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
Win.BorderSizePixel = 0
Win.ClipsDescendants = true
Win.Visible = false
Win.Active = true
Win.Parent = Root

Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 12)

local winStroke = Instance.new("UIStroke")
winStroke.Thickness = 1.5
winStroke.Color = Color3.fromRGB(120, 90, 200)
winStroke.Transparency = 0.35
winStroke.Parent = Win

local winGrad = Instance.new("UIGradient")
winGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 22, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 14, 22)),
})
winGrad.Rotation = 90
winGrad.Parent = Win

-- ── ХЕДЕР ───────────────────────────────────────────────────────
local Head = Instance.new("Frame")
Head.Size = UDim2.new(1, 0, 0, 38)
Head.BackgroundTransparency = 1
Head.Parent = Win

local HeadAccent = Instance.new("Frame")
HeadAccent.Size = UDim2.new(1, 0, 0, 2)
HeadAccent.Position = UDim2.new(0, 0, 1, -2)
HeadAccent.BackgroundColor3 = Color3.fromRGB(160, 90, 255)
HeadAccent.BorderSizePixel = 0
HeadAccent.Parent = Head
local headGrad = Instance.new("UIGradient")
headGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 90, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 180)),
})
headGrad.Parent = HeadAccent

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 · SUITE · v2"
Title.TextColor3 = Color3.fromRGB(235, 225, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Head

local FPSLbl = Instance.new("TextLabel")
FPSLbl.Size = UDim2.new(0, 60, 1, 0)
FPSLbl.Position = UDim2.new(1, -100, 0, 0)
FPSLbl.BackgroundTransparency = 1
FPSLbl.Text = "60 fps"
FPSLbl.TextColor3 = Color3.fromRGB(140, 220, 160)
FPSLbl.Font = Enum.Font.Gotham
FPSLbl.TextSize = 11
FPSLbl.TextXAlignment = Enum.TextXAlignment.Right
FPSLbl.Parent = Head

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 24, 32)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 190, 190)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Head
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 40, 60)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 24, 32)}):Play()
end)

-- ── ВКЛАДКИ ─────────────────────────────────────────────────────
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 28)
TabBar.Position = UDim2.new(0, 8, 0, 42)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Win

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabBar

-- ── КОНТЕНТ ─────────────────────────────────────────────────────
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -86)
Scroll.Position = UDim2.new(0, 8, 0, 76)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(140, 90, 220)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Win

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

-- ── РЕСАЙЗ ──────────────────────────────────────────────────────
local Resize = Instance.new("TextButton")
Resize.Size = UDim2.new(0, 16, 0, 16)
Resize.Position = UDim2.new(1, -18, 1, -18)
Resize.BackgroundColor3 = Color3.fromRGB(160, 90, 255)
Resize.BackgroundTransparency = 0.4
Resize.Text = ""
Resize.BorderSizePixel = 0
Resize.Parent = Win
Instance.new("UICorner", Resize).CornerRadius = UDim.new(0, 4)

-- ────────────────────────────────────────────────────────────────
--  HELPERS
-- ────────────────────────────────────────────────────────────────
local function section(text)
    local sec = Instance.new("TextLabel")
    sec.Size = UDim2.new(1, -6, 0, 22)
    sec.BackgroundTransparency = 1
    sec.Text = "  " .. text:upper()
    sec.TextColor3 = Color3.fromRGB(180, 130, 255)
    sec.Font = Enum.Font.GothamBold
    sec.TextSize = 11
    sec.TextXAlignment = Enum.TextXAlignment.Left
    sec.Parent = Scroll
    return sec
end

local function ripple(parent, x, y)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(0, 6, 0, 6)
    r.Position = UDim2.new(0, x - 3, 0, y - 3)
    r.BackgroundColor3 = Color3.fromRGB(200, 160, 255)
    r.BackgroundTransparency = 0.4
    r.BorderSizePixel = 0
    r.ZIndex = 5
    r.Parent = parent
    Instance.new("UICorner", r).CornerRadius = UDim.new(1,0)
    TweenService:Create(r, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 120, 0, 120),
        Position = UDim2.new(0, x - 60, 0, y - 60),
        BackgroundTransparency = 1,
    }):Play()
    Debris:AddItem(r, 0.5)
end

local function toggle(label, key, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
    row.BorderSizePixel = 0
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 34, 0, 16)
    ind.Position = UDim2.new(1, -44, 0.5, -8)
    ind.BackgroundColor3 = Color3.fromRGB(50, 44, 62)
    ind.BorderSizePixel = 0
    ind.Parent = row
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(200, 195, 215)
    knob.BorderSizePixel = 0
    knob.Parent = ind
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local state = S[key]
    local function render()
        TweenService:Create(ind, TweenInfo.new(0.18), {
            BackgroundColor3 = state and Color3.fromRGB(120, 80, 200) or Color3.fromRGB(50, 44, 62)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = state and Color3.fromRGB(240, 230, 255) or Color3.fromRGB(200, 195, 215)
        }):Play()
    end
    render()

    btn.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(42, 36, 58)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 26, 42)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        state = not state
        S[key] = state
        render()
        ripple(row, btn.AbsolutePosition.X + 10, btn.AbsolutePosition.Y + 10)
        if cb then cb(state) end
    end)
    return row
end

local function slider(label, key, min, max, step, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 46)
    row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
    row.BorderSizePixel = 0
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. tostring(S[key])
    lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 8)
    track.Position = UDim2.new(0, 10, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(48, 42, 60)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((S[key]-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(160, 90, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor((min + (max-min)*rel) / step + 0.5) * step
        S[key] = val
        lbl.Text = label .. ": " .. tostring(val)
        fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
        if cb then cb(val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFromX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return row
end

local function dropdown(label, key, options, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 56)
    row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
    row.BorderSizePixel = 0
    row.ClipsDescendants = true
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(1, -20, 0, 24)
    box.Position = UDim2.new(0, 10, 0, 26)
    box.BackgroundColor3 = Color3.fromRGB(46, 40, 60)
    box.Text = "  " .. tostring(S[key]) .. "  ▾"
    box.TextColor3 = Color3.fromRGB(235, 225, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.BorderSizePixel = 0
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -20, 0, 0)
    list.Position = UDim2.new(0, 10, 0, 54)
    list.BackgroundColor3 = Color3.fromRGB(36, 30, 48)
    list.BorderSizePixel = 0
    list.Visible = false
    list.Parent = row
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
    local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 2); ll.Parent = list

    local open = false
    local function build()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 22)
            b.BackgroundColor3 = Color3.fromRGB(36, 30, 48)
            b.Text = "  " .. opt
            b.TextColor3 = Color3.fromRGB(220, 215, 235)
            b.Font = Enum.Font.Gotham
            b.TextSize = 12
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.BorderSizePixel = 0
            b.Parent = list
            b.MouseEnter:Connect(function()
                TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(70, 55, 100)}):Play()
            end)
            b.MouseLeave:Connect(function()
                TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(36, 30, 48)}):Play()
            end)
            b.MouseButton1Click:Connect(function()
                S[key] = opt
                box.Text = "  " .. opt .. "  ▾"
                if cb then cb(opt) end
                open = false
                TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 0)}):Play()
                task.delay(0.2, function() list.Visible = false end)
                TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 56)}):Play()
            end)
        end
        local h = #options * 24 + 4
        list.Size = UDim2.new(1, -20, 0, h)
    end
    build()

    box.MouseButton1Click:Connect(function()
        open = not open
        if open then
            list.Visible = true
            local h = #options * 24 + 4
            TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, h)}):Play()
            TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 56 + h + 4)}):Play()
        else
            TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 0)}):Play()
            TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 56)}):Play()
            task.delay(0.2, function() list.Visible = false end)
        end
    end)
    return row
end

-- ────────────────────────────────────────────────────────────────
--  ВКЛАДКИ
-- ────────────────────────────────────────────────────────────────
local TABS = {}
local TAB_ORDER = {"Движ","Визуал","Мир","Бой","Фарм","Инфо","Флинг","Косметика"}
local TabButtons = {}

local function makeTab(name)
    local page = Instance.new("Frame")
    page.Size = UDim2.fromScale(1,1)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Scroll
    return page
end

local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -6, 1, 0)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = Scroll

-- Мы не используем Layout для Scroll — вместо этого вкладки внутри PageContainer
Layout.Parent = nil
local Stack = Instance.new("UIListLayout")
Stack.Padding = UDim.new(0, 6)
Stack.SortOrder = Enum.SortOrder.LayoutOrder
Stack.Parent = PageContainer

local function switchTab(name)
    currentTab = name
    for n, page in pairs(TABS) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(TabButtons) do
        local on = (n == name)
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundColor3 = on and Color3.fromRGB(90, 60, 160) or Color3.fromRGB(34, 28, 46),
        }):Play()
    end
    -- анимация появления контента
    local page = TABS[name]
    if page then
        page.Position = UDim2.new(0, 8, 0, 0)
        TweenService:Create(page, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end
end

local function registerTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 66, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(34, 28, 46)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220, 210, 240)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 0, 0)
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = PageContainer

    local pl = Instance.new("UIListLayout")
    pl.Padding = UDim.new(0, 6)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Parent = page

    TABS[name] = page
    TabButtons[name] = btn

    btn.MouseEnter:Connect(function()
        if currentTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 42, 70)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(34, 28, 46)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
        ripple(btn, btn.AbsolutePosition.X + btn.AbsoluteSize.X/2, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2)
    end)
    return page
end

for _, n in ipairs(TAB_ORDER) do registerTab(n) end

-- local-версии помощников, привязанные к активной странице
local function tSection(page, text)
    local sec = Instance.new("TextLabel")
    sec.Size = UDim2.new(1, -6, 0, 22)
    sec.BackgroundTransparency = 1
    sec.Text = "  " .. text:upper()
    sec.TextColor3 = Color3.fromRGB(180, 130, 255)
    sec.Font = Enum.Font.GothamBold
    sec.TextSize = 11
    sec.TextXAlignment = Enum.TextXAlignment.Left
    sec.Parent = page
    return sec
end

local function tToggle(page, label, key, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
    row.BorderSizePixel = 0
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 34, 0, 16)
    ind.Position = UDim2.new(1, -44, 0.5, -8)
    ind.BackgroundColor3 = Color3.fromRGB(50, 44, 62)
    ind.BorderSizePixel = 0
    ind.Parent = row
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(200, 195, 215)
    knob.BorderSizePixel = 0
    knob.Parent = ind
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local state = S[key]
    local function render()
        TweenService:Create(ind, TweenInfo.new(0.18), {
            BackgroundColor3 = state and Color3.fromRGB(120, 80, 200) or Color3.fromRGB(50, 44, 62)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = state and Color3.fromRGB(240, 230, 255) or Color3.fromRGB(200, 195, 215)
        }):Play()
    end
    render()

    btn.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(42, 36, 58)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 26, 42)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        state = not state
        S[key] = state
        render()
        ripple(row, 20, 14)
        if cb then cb(state) end
    end)
    return row
end

local function tSlider(page, label, key, min, max, step, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 46)
    row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
    row.BorderSizePixel = 0
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. tostring(S[key])
    lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 8)
    track.Position = UDim2.new(0, 10, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(48, 42, 60)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((S[key]-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(160, 90, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor((min + (max-min)*rel) / step + 0.5) * step
        S[key] = val
        lbl.Text = label .. ": " .. tostring(val)
        fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
        if cb then cb(val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFromX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return row
end

local function tDropdown(page, label, key, options, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 56)
    row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
    row.BorderSizePixel = 0
    row.ClipsDescendants = true
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(1, -20, 0, 24)
    box.Position = UDim2.new(0, 10, 0, 26)
    box.BackgroundColor3 = Color3.fromRGB(46, 40, 60)
    box.Text = "  " .. tostring(S[key]) .. "  ▾"
    box.TextColor3 = Color3.fromRGB(235, 225, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.BorderSizePixel = 0
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -20, 0, 0)
    list.Position = UDim2.new(0, 10, 0, 54)
    list.BackgroundColor3 = Color3.fromRGB(36, 30, 48)
    list.BorderSizePixel = 0
    list.Visible = false
    list.Parent = row
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
    local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 2); ll.Parent = list

    local open = false
    local function build()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 22)
            b.BackgroundColor3 = Color3.fromRGB(36, 30, 48)
            b.Text = "  " .. opt
            b.TextColor3 = Color3.fromRGB(220, 215, 235)
            b.Font = Enum.Font.Gotham
            b.TextSize = 12
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.BorderSizePixel = 0
            b.Parent = list
            b.MouseEnter:Connect(function()
                TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(70, 55, 100)}):Play()
            end)
            b.MouseLeave:Connect(function()
                TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(36, 30, 48)}):Play()
            end)
            b.MouseButton1Click:Connect(function()
                S[key] = opt
                box.Text = "  " .. opt .. "  ▾"
                if cb then cb(opt) end
                open = false
                TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 0)}):Play()
                task.delay(0.2, function() list.Visible = false end)
                TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 56)}):Play()
            end)
        end
        local h = #options * 24 + 4
        list.Size = UDim2.new(1, -20, 0, h)
    end
    build()

    box.MouseButton1Click:Connect(function()
        open = not open
        if open then
            list.Visible = true
            local h = #options * 24 + 4
            TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, h)}):Play()
            TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 56 + h + 4)}):Play()
        else
            TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 0)}):Play()
            TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, -6, 0, 56)}):Play()
            task.delay(0.2, function() list.Visible = false end)
        end
    end)
    return row
end

-- ────────────────────────────────────────────────────────────────
--  ЗАПОЛНЯЕМ ВКЛАДКИ
-- ────────────────────────────────────────────────────────────────
do
    local p = TABS["Движ"]
    tSection(p, "Движение")
    tToggle(p, "SpeedHack", "speedEnabled")
    tSlider(p, "Speed", "speedValue", 16, 250, 2)
    tToggle(p, "NoClip", "noclip")
    tToggle(p, "Fly", "fly")
    tSlider(p, "Fly Speed", "flySpeed", 20, 300, 5)
end

do
    local p = TABS["Визуал"]
    tSection(p, "Игроки")
    tToggle(p, "Player ESP", "playerESP")
    tToggle(p, "Role ESP", "roleESP")
    tToggle(p, "Chams", "chams")
    tSection(p, "Объекты")
    tToggle(p, "Item ESP", "itemESP")
    tToggle(p, "FullBright", "fullbright")
end

do
    local p = TABS["Мир"]
    tSection(p, "Время и свет")
    tToggle(p, "Set Time", "worldTime")
    tSlider(p, "Hour", "worldTimeVal", 0, 24, 1)
    tToggle(p, "Brightness", "worldBrightness")
    tSlider(p, "Level", "worldBrightVal", 0, 5, 1)
    tSection(p, "Атмосфера")
    tToggle(p, "Fog", "worldFog")
    tToggle(p, "Ambient", "worldAmbient")
    tSection(p, "Шейдеры (постэффекты)")
    tToggle(p, "Blur (лёгкий)", "worldBlur")
    tToggle(p, "Bloom", "worldBloom")
    tToggle(p, "ColorCorrection", "worldColorCorrection")
    tToggle(p, "Depth of Field", "worldDepthOfField")
    tToggle(p, "Sun Rays", "worldSunRays")
end

do
    local p = TABS["Бой"]
    tSection(p, "Прицел")
    tToggle(p, "AimBot (ПКМ)", "aimbot")
    tToggle(p, "SilentAim", "silentAim")
    tToggle(p, "AutoShoot", "autoShoot")
    tSection(p, "Выживание")
    tToggle(p, "GodMode (клиент)", "godMode")
    tToggle(p, "Auto-Dodge убийцы", "autoDodge")
    tToggle(p, "Auto-Equip Gun", "autoEquipGun")
end

do
    local p = TABS["Фарм"]
    tSection(p, "Сбор")
    tToggle(p, "Auto Collect Coins", "autoCoins")
    tToggle(p, "Coin Vacuum", "coinVacuum")
    tToggle(p, "Auto Pickup Weapon", "autoPickup")
    tSection(p, "Прочее")
    tToggle(p, "Mute All", "muteAll")
end

do
    local p = TABS["Инфо"]
    tSection(p, "Отображение")
    tToggle(p, "Role Detector", "roleDetector")
    tToggle(p, "Player List (в чат)", "playerList")
    tToggle(p, "Ping Display", "pingDisplay")
    tToggle(p, "Round Timer", "roundTimer")
end

do
    local p = TABS["Флинг"]
    tSection(p, "Цели")
    tToggle(p, "FLING Murderer", "flingMurder")
    tToggle(p, "FLING Sheriff", "flingSheriff")
    tDropdown(p, "Режим", "flingMode", {"ForcePush","Spin","Loop","Silent"})
    tSection(p, "Защита")
    tToggle(p, "Anti-Fling", "antiFling")
    tToggle(p, "Void Catch", "voidCatch")
    tToggle(p, "Anti Spin", "antiSpin")
    tToggle(p, "Weld Detector", "weldDetect")
    tToggle(p, "Anti-Ragdoll", "antiRagdoll")
    tToggle(p, "Anti-AFK", "antiAFK")
end

do
    local p = TABS["Косметика"]
    tSection(p, "Шляпы")
    tDropdown(p, "Шляпа", "cosHat", {"None","Tophat","Crown","Halo","Propeller","Bucket"})
    tSection(p, "Крылья и эффекты")
    tToggle(p, "Крылья", "cosWings")
    tDropdown(p, "Аура", "cosAura", {"None","Fire","Ice","Lightning","Galaxy","Gold"})
    tToggle(p, "Трейл", "cosTrail")
    tToggle(p, "Орбита сфер", "cosOrbit")
end

switchTab("Движ")

-- ────────────────────────────────────────────────────────────────
--  ДРАГ / РЕСАЙЗ
-- ────────────────────────────────────────────────────────────────
do
    local dragging, start, startPos = false, nil, nil
    Head.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; start = i.Position; startPos = Win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - start
            Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local rDrag, rStart, rSize = false, nil, nil
    Resize.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            rDrag = true; rStart = i.Position; rSize = Win.Size
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if rDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - rStart
            Win.Size = UDim2.new(0, math.max(320, rSize.X.Offset + d.X), 0, math.max(240, rSize.Y.Offset + d.Y))
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then rDrag = false end
    end)
end

-- ────────────────────────────────────────────────────────────────
--  ОТКРЫТИЕ ОКНА С АНИМАЦИЕЙ
-- ────────────────────────────────────────────────────────────────
local function openWin()
    Win.Visible = true
    Win.Size = UDim2.new(0, 340, 0, 260)
    TweenService:Create(Win, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 320)
    }):Play()
end
local function closeWin()
    TweenService:Create(Win, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 340, 0, 260)
    }):Play()
    task.delay(0.18, function() Win.Visible = false end)
end

Orb.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        if Win.Visible then closeWin() else openWin() end
    end
end)
CloseBtn.MouseButton1Click:Connect(closeWin)

-- ────────────────────────────────────────────────────────────────
--  РОЛИ / УТИЛИТЫ
-- ────────────────────────────────────────────────────────────────
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(220, 20, 60),
    Sheriff  = Color3.fromRGB(255, 200, 40),
    Innocent = Color3.fromRGB(80, 200, 120),
    Hero     = Color3.fromRGB(120, 180, 255),
    Unknown  = Color3.fromRGB(180, 180, 180),
}

local function getRole(plr)
    for _, t in ipairs(plr:GetChildren()) do
        if t:IsA("StringValue") or t:IsA("ObjectValue") then
            local n = t.Name:lower(); local v = tostring(t.Value):lower()
            if n:find("role") or n:find("team") then
                if v:find("murder") then return "Murderer" end
                if v:find("sheriff") then return "Sheriff" end
                if v:find("hero") then return "Hero" end
                if v:find("innoc") then return "Innocent" end
            end
        end
    end
    local a = plr:GetAttribute("Role") or plr:GetAttribute("role")
    if a then
        local s = tostring(a):lower()
        if s:find("murder") then return "Murderer" end
        if s:find("sheriff") then return "Sheriff" end
        if s:find("hero") then return "Hero" end
        if s:find("innoc") then return "Innocent" end
    end
    return "Unknown"
end

local function getCharParts(plr)
    local c = plr.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return hrp, hum, c
end

-- ────────────────────────────────────────────────────────────────
--  ESP
-- ────────────────────────────────────────────────────────────────
local function ensureEsp(plr)
    if plr == LP then return end
    if espCache[plr] then return espCache[plr] end
    local box = Drawing.new("Square")
    box.Thickness = 1; box.Filled = false; box.Transparency = 1; box.Visible = false
    local name = Drawing.new("Text")
    name.Size = 13; name.Center = true; name.Outline = true; name.Visible = false
    local info = Drawing.new("Text")
    info.Size = 12; info.Center = true; info.Outline = true; info.Visible = false
    espCache[plr] = {box=box, name=name, info=info}
    return espCache[plr]
end

for _, p in ipairs(Players:GetPlayers()) do ensureEsp(p) end
Players.PlayerAdded:Connect(ensureEsp)
Players.PlayerRemoving:Connect(function(p)
    local e = espCache[p]
    if e then
        for _, d in pairs(e) do d:Remove() end
        espCache[p] = nil
    end
end)

-- ────────────────────────────────────────────────────────────────
--  CHAMS
-- ────────────────────────────────────────────────────────────────
local function applyChams(char, color)
    if char:FindFirstChild("__cham") then
        char.__cham.FillColor = color
        char.__cham.OutlineColor = color
        return
    end
    local hl = Instance.new("Highlight")
    hl.Name = "__cham"
    hl.FillColor = color
    hl.FillTransparency = 0.55
    hl.OutlineColor = color
    hl.Parent = char
end
local function clearChams(char)
    local h = char:FindFirstChild("__cham")
    if h then h:Destroy() end
end

-- ────────────────────────────────────────────────────────────────
--  ITEM ESP
-- ────────────────────────────────────────────────────────────────
local itemDrawings = {}
local function clearItemEsp()
    for _, d in pairs(itemDrawings) do
        if typeof(d) == "Instance" and d.Remove then d:Remove() end
    end
    itemDrawings = {}
end
local ITEM_NAMES = {"Knife", "Gun", "Coin", "Revolver", "Pistol"}

-- ────────────────────────────────────────────────────────────────
--  FLY
-- ────────────────────────────────────────────────────────────────
local function startFly()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 1000
    flyBG.Parent = hrp
end
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end

-- ────────────────────────────────────────────────────────────────
--  FLING
-- ────────────────────────────────────────────────────────────────
local function flingTarget(targetChar, mode)
    if not targetChar then return end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if mode == "ForcePush" then
        local v = Instance.new("BodyVelocity")
        v.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        v.Velocity = Vector3.new(math.random(-1,1)*400, 300, math.random(-1,1)*400)
        v.Parent = hrp
        task.delay(0.15, function() v:Destroy() end)
    elseif mode == "Spin" then
        for _ = 1, 4 do
            hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), math.rad(90), 0)
            hrp.Velocity = Vector3.new(0, 500, 0)
            task.wait(0.03)
        end
    elseif mode == "Loop" then
        for _ = 1, 6 do
            if hrp.Parent then
                hrp.Velocity = Vector3.new(math.random(-350,350), 250, math.random(-350,350))
            end
            task.wait(0.1)
        end
    elseif mode == "Silent" then
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = hrp
        weld.Part1 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if weld.Part1 then
            weld.Parent = hrp
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.1, 0)
            task.wait(0.05)
            weld:Destroy()
            hrp.Velocity = Vector3.new(300, 400, 300)
        end
    end
end

-- ────────────────────────────────────────────────────────────────
--  ANTI-FLING / VOID / SPIN / WELD / RAGDOLL
-- ────────────────────────────────────────────────────────────────
local savedCFrame = nil
RunService.Heartbeat:Connect(function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if S.voidCatch and hrp.Position.Y < -50 then
        hrp.CFrame = CFrame.new(0, 20, 0)
        hrp.Velocity = Vector3.zero
    end

    if S.antiFling then
        local v = hrp.Velocity
        if v.Magnitude > 300 and (hrp.Position - (lastValidPos or hrp.Position)).Magnitude < 5 then
            hrp.Velocity = Vector3.zero
        end
        lastValidPos = hrp.Position
    end

    if S.antiSpin then
        local _, ry = hrp.CFrame:ToOrientation()
        savedCFrame = savedCFrame or hrp.CFrame
        local delta = math.abs(math.deg(ry) - math.deg(select(2, savedCFrame:ToOrientation())))
        if delta > 60 and delta < 300 then
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, select(2, savedCFrame:ToOrientation()), 0)
        else
            savedCFrame = hrp.CFrame
        end
    end

    if S.weldDetect then
        for _, c in ipairs(hrp:GetChildren()) do
            if c:IsA("WeldConstraint") or c:IsA("Weld") then
                local ok = false
                for _, p in ipairs(char:GetDescendants()) do
                    if c.Part0 == p or c.Part1 == p then ok = true; break end
                end
                if not ok then c:Destroy() end
            end
        end
    end

    if S.antiRagdoll then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

-- ────────────────────────────────────────────────────────────────
--  ANTI-AFK
-- ────────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(60) do
        if S.antiAFK then
            local vu = LP:FindFirstChild("VirtualUser") or Instance.new("VirtualUser", LP)
            pcall(function() vu:Button1Down(Vector2.zero) end)
        end
    end
end)

-- ────────────────────────────────────────────────────────────────
--  КОСМЕТИКА
-- ────────────────────────────────────────────────────────────────
local function clearCosmetics()
    for _, p in pairs(cosParts) do
        if typeof(p) == "Instance" and p.Parent then p:Destroy() end
    end
    cosParts = {}
    local char = LP.Character
    if char then
        for _, c in ipairs(char:GetChildren()) do
            if c.Name:find("__cos") then c:Destroy() end
        end
    end
end

local function weld(part, target, offset)
    local w = Instance.new("WeldConstraint")
    part.CFrame = target.CFrame * offset
    part.Anchored = false
    part.CanCollide = false
    part.Parent = target.Parent
    w.Part0 = part
    w.Part1 = target
    w.Parent = part
    return w
end

local function buildHat(kind, head)
    if kind == "None" then return end
    if kind == "Tophat" then
        local brim = Instance.new("Part")
        brim.Name = "__cos_hat_brim"
        brim.Size = Vector3.new(1.4, 0.1, 1.4)
        brim.Color = Color3.fromRGB(20,20,20)
        brim.Material = Enum.Material.SmoothPlastic
        local top = Instance.new("Part")
        top.Name = "__cos_hat_top"
        top.Size = Vector3.new(0.9, 0.9, 0.9)
        top.Color = Color3.fromRGB(20,20,20)
        top.Material = Enum.Material.SmoothPlastic
        weld(brim, head, CFrame.new(0, 0.55, 0))
        weld(top, brim, CFrame.new(0, 0.5, 0))
        table.insert(cosParts, brim); table.insert(cosParts, top)
    elseif kind == "Crown" then
        local base = Instance.new("Part")
        base.Name = "__cos_crown"
        base.Size = Vector3.new(1.2, 0.35, 1.2)
        base.Color = Color3.fromRGB(255, 215, 60)
        base.Material = Enum.Material.Neon
        weld(base, head, CFrame.new(0, 0.6, 0))
        table.insert(cosParts, base)
        for i = 1, 5 do
            local spike = Instance.new("Part")
            spike.Name = "__cos_crown_spike"
            spike.Size = Vector3.new(0.15, 0.4, 0.15)
            spike.Color = Color3.fromRGB(255, 235, 120)
            spike.Material = Enum.Material.Neon
            local ang = (i-1) * (math.pi*2/5)
            weld(spike, base, CFrame.new(math.cos(ang)*0.5, 0.3, math.sin(ang)*0.5))
            table.insert(cosParts, spike)
        end
    elseif kind == "Halo" then
        local halo = Instance.new("Part")
        halo.Name = "__cos_halo"
        halo.Shape = Enum.PartType.Cylinder
        halo.Size = Vector3.new(0.15, 1.4, 1.4)
        halo.Color = Color3.fromRGB(255, 240, 160)
        halo.Material = Enum.Material.Neon
        halo.CanCollide = false
        weld(halo, head, CFrame.new(0, 1.2, 0))
        table.insert(cosParts, halo)
    elseif kind == "Propeller" then
        local cap = Instance.new("Part")
        cap.Name = "__cos_cap"
        cap.Size = Vector3.new(0.9, 0.3, 0.9)
        cap.Color = Color3.fromRGB(30, 120, 220)
        weld(cap, head, CFrame.new(0, 0.55, 0))
        table.insert(cosParts, cap)
        local blade = Instance.new("Part")
        blade.Name = "__cos_prop"
        blade.Size = Vector3.new(1.4, 0.1, 0.2)
        blade.Color = Color3.fromRGB(220, 60, 60)
        weld(blade, cap, CFrame.new(0, 0.25, 0))
        blade.Anchored = false
        table.insert(cosParts, blade)
        RunService.Heartbeat:Connect(function()
            if blade and blade.Parent then
                blade.CFrame = blade.CFrame * CFrame.Angles(0, math.rad(18), 0)
            end
        end)
    elseif kind == "Bucket" then
        local bucket = Instance.new("Part")
        bucket.Name = "__cos_bucket"
        bucket.Shape = Enum.PartType.Cylinder
        bucket.Size = Vector3.new(0.9, 1.0, 1.0)
        bucket.Color = Color3.fromRGB(140, 140, 150)
        bucket.Material = Enum.Material.Metal
        bucket.CanCollide = false
        weld(bucket, head, CFrame.new(0, 1.0, 0) * CFrame.Angles(0, 0, math.rad(90)))
        table.insert(cosParts, bucket)
    end
end

local function buildWings(back)
    local function wingPart(offset, rot)
        local p = Instance.new("Part")
        p.Name = "__cos_wing"
        p.Size = Vector3.new(1.4, 0.1, 0.6)
        p.Color = Color3.fromRGB(240, 240, 255)
        p.Material = Enum.Material.Neon
        p.Transparency = 0.15
        p.CanCollide = false
        weld(p, back, offset * rot)
        table.insert(cosParts, p)
        return p
    end
    wingPart(CFrame.new(-0.9, 0.2, 0.3), CFrame.Angles(0, 0, math.rad(25)))
    wingPart(CFrame.new(0.9, 0.2, 0.3), CFrame.Angles(0, 0, math.rad(-25)))
    wingPart(CFrame.new(-1.6, -0.2, 0.5), CFrame.Angles(0, 0, math.rad(45)))
    wingPart(CFrame.new(1.6, -0.2, 0.5), CFrame.Angles(0, 0, math.rad(-45)))
end

local AURA_PRESETS = {
    None = {color = Color3.fromRGB(255,255,255), speed = 0},
    Fire = {color = Color3.fromRGB(255, 110, 40), speed = 40},
    Ice = {color = Color3.fromRGB(120, 200, 255), speed = 20},
    Lightning = {color = Color3.fromRGB(255, 240, 120), speed = 90},
    Galaxy = {color = Color3.fromRGB(180, 100, 255), speed = 30},
    Gold = {color = Color3.fromRGB(255, 210, 80), speed = 15},
}

local function applyAura(kind, hrp)
    if kind == "None" then return end
    local preset = AURA_PRESETS[kind]
    local att = Instance.new("Attachment", hrp)
    att.Name = "__cos_aura_att"
    local em = Instance.new("ParticleEmitter")
    em.Name = "__cos_aura_em"
    em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    em.Rate = 20
    em.Lifetime = NumberRange.new(1.2, 2.2)
    em.Speed = NumberRange.new(preset.speed*0.4, preset.speed)
    em.SpreadAngle = Vector2.new(180, 180)
    em.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0),
    })
    em.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    em.Color = ColorSequence.new(preset.color)
    em.Parent = att
    table.insert(cosParts, att)
end

local function applyTrail(hrp)
    local a0 = Instance.new("Attachment", hrp); a0.Name = "__cos_tr0"; a0.Position = Vector3.new(-0.5,0,0)
    local a1 = Instance.new("Attachment", hrp); a1.Name = "__cos_tr1"; a1.Position = Vector3.new(0.5,0,0)
    local tr = Instance.new("Trail")
    tr.Name = "__cos_trail"
    tr.Attachment0 = a0
    tr.Attachment1 = a1
    tr.Lifetime = 1.2
    tr.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 90, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 180)),
    })
    tr.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    tr.Parent = hrp
    table.insert(cosParts, a0); table.insert(cosParts, a1); table.insert(cosParts, tr)
end

local function applyOrbit(hrp)
    for i = 1, 6 do
        local s = Instance.new("Part")
        s.Name = "__cos_orbit"
        s.Shape = Enum.PartType.Ball
        s.Size = Vector3.new(0.25, 0.25, 0.25)
        s.Color = Color3.fromRGB(255, 200, 120)
        s.Material = Enum.Material.Neon
        s.CanCollide = false
        s.Anchored = true
        s.Parent = Workspace
        table.insert(cosParts, s)
    end
    local t = 0
    RunService.Heartbeat:Connect(function(dt)
        t += dt
        local n = 0
        for _, p in ipairs(cosParts) do
            if p.Name == "__cos_orbit" and p.Parent then
                n += 1
                local ang = t * 2 + (n-1) * (math.pi*2/6)
                local rad = 2.2
                p.CFrame = hrp.CFrame * CFrame.new(math.cos(ang)*rad, math.sin(t*3)*0.4, math.sin(ang)*rad)
            end
        end
    end)
end

local function rebuildCosmetics()
    clearCosmetics()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local back = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if head and S.cosHat ~= "None" then buildHat(S.cosHat, head) end
    if back and S.cosWings then buildWings(back) end
    if hrp then
        if S.cosAura ~= "None" then applyAura(S.cosAura, hrp) end
        if S.cosTrail then applyTrail(hrp) end
        if S.cosOrbit then applyOrbit(hrp) end
    end
end

-- привязка косметики к тумблерам (через хук на состояние)
-- слушаем каждые 0.5 сек изменение комбинации
local lastCosKey = ""
task.spawn(function()
    while task.wait(0.5) do
        local key = tostring(S.cosHat)..tostring(S.cosWings)..tostring(S.cosAura)..tostring(S.cosTrail)..tostring(S.cosOrbit)..tostring(LP.Character)
        if key ~= lastCosKey then
            lastCosKey = key
            rebuildCosmetics()
        end
    end
end)

-- ────────────────────────────────────────────────────────────────
--  МИР / ШЕЙДЕРЫ (создаются один раз, включаются флагами)
-- ────────────────────────────────────────────────────────────────
local function ensure(name, class)
    local e = Lighting:FindFirstChild(name)
    if not e then
        e = Instance.new(class)
        e.Name = name
        e.Parent = Lighting
        worldEffects[name] = e
    end
    return e
end

local Blur        = ensure("__mm2_blur", "BlurEffect")
local Bloom       = ensure("__mm2_bloom", "BloomEffect")
local CC          = ensure("__mm2_cc", "ColorCorrectionEffect")
local DoF         = ensure("__mm2_dof", "DepthOfFieldEffect")
local SunRays     = ensure("__mm2_sun", "SunRaysEffect")

Blur.Size = 6
Bloom.Intensity = 1.2
Bloom.Size = 20
Bloom.Threshold = 1.4
CC.Brightness = 0.05
CC.Contrast = 0.1
CC.Saturation = 0.15
DoF.FarIntensity = 0.15
DoF.FocusDistance = 30
DoF.InFocusRadius = 20
SunRays.Intensity = 0.15
SunRays.Spread = 1

local function updateWorld()
    local origTime = Lighting.TimeOfDay
    Lighting.TimeOfDay = S.worldTime and (string.format("%02d:00:00", S.worldTimeVal)) or origTime
    Lighting.Brightness = S.worldBrightness and S.worldBrightVal or 2
    Lighting.FogEnd = S.worldFog and 80 or 1e6
    Lighting.FogColor = S.worldFog and S.worldFogColor or Color3.fromRGB(200,200,200)
    Lighting.Ambient = S.worldAmbient and S.worldAmbientColor or Color3.fromRGB(70,70,70)

    Blur.Enabled = S.worldBlur
    Bloom.Enabled = S.worldBloom
    CC.Enabled = S.worldColorCorrection
    DoF.Enabled = S.worldDepthOfField
    SunRays.Enabled = S.worldSunRays
end

-- ────────────────────────────────────────────────────────────────
--  MAIN LOOP
-- ────────────────────────────────────────────────────────────────
local function mainLoop()
    while task.wait() do
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        -- FPS
        fpsCount += 1
        if tick() - fpsTick >= 1 then
            fpsValue = fpsCount
            fpsCount = 0
            fpsTick = tick()
            FPSLbl.Text = tostring(fpsValue) .. " fps"
            FPSLbl.TextColor3 = fpsValue >= 50 and Color3.fromRGB(140,220,160)
                or fpsValue >= 30 and Color3.fromRGB(230,220,120)
                or Color3.fromRGB(230,120,120)
        end

        -- SPEED
        if hum then hum.WalkSpeed = S.speedEnabled and S.speedValue or 16 end

        -- NOCLIP
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = not S.noclip end
            end
        end

        -- FLY
        if S.fly and not flyBV then startFly()
        elseif not S.fly and flyBV then stopFly() end
        if S.fly and flyBV and hrp then
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir += CAM.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= CAM.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= CAM.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir += CAM.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
            flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * S.flySpeed or Vector3.zero
            flyBG.CFrame = CAM.CFrame
        end

        -- FULLBRIGHT
        if S.fullbright then
            Lighting.Brightness = math.max(Lighting.Brightness, 3)
            Lighting.Ambient = Color3.fromRGB(200,200,200)
        end

        -- WORLD / SHADERS
        updateWorld()

        -- ESP
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local parts = getCharParts(plr)
                local esp = espCache[plr]
                if parts and esp then
                    local hrp2, hum2, char2 = parts
                    local head = char2:FindFirstChild("Head")
                    local role = getRole(plr)
                    local color = ROLE_COLORS[role]
                    if S.playerESP or S.roleESP then
                        local headPos = head and (head.Position + Vector3.new(0,0.7,0)) or (hrp2.Position + Vector3.new(0,2.5,0))
                        local bottomPos = hrp2.Position - Vector3.new(0, 2.6, 0)
                        local top, tOn = CAM:WorldToViewportPoint(headPos)
                        local bot, bOn = CAM:WorldToViewportPoint(bottomPos)
                        if tOn and bOn then
                            local h = math.abs(bot.Y - top.Y)
                            local w = h / 2
                            esp.box.Size = Vector2.new(w, h)
                            esp.box.Position = Vector2.new(top.X - w/2, top.Y)
                            esp.box.Color = color
                            esp.box.Visible = true
                            local dist = hrp and (hrp2.Position - hrp.Position).Magnitude or 0
                            esp.name.Text = plr.Name .. "  [" .. math.floor(dist) .. "m]"
                            esp.name.Position = Vector2.new(top.X, top.Y - 28)
                            esp.name.Color = color
                            esp.name.Visible = true
                            esp.info.Text = S.roleESP and role or ""
                            esp.info.Position = Vector2.new(top.X, top.Y - 14)
                            esp.info.Color = color
                            esp.info.Visible = S.roleESP
                        else
                            esp.box.Visible = false; esp.name.Visible = false; esp.info.Visible = false
                        end
                    else
                        esp.box.Visible = false; esp.name.Visible = false; esp.info.Visible = false
                    end
                    if S.chams then applyChams(char2, color) else clearChams(char2) end
                elseif esp then
                    esp.box.Visible = false; esp.name.Visible = false; esp.info.Visible = false
                end
            end
        end

        -- ITEM ESP
        if S.itemESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    for _, nm in ipairs(ITEM_NAMES) do
                        if obj.Name:lower():find(nm:lower()) then
                            if not itemDrawings[obj] then
                                local d = Drawing.new("Text")
                                d.Size = 12; d.Center = true; d.Outline = true
                                d.Color = Color3.fromRGB(255, 230, 100)
                                d.Text = nm
                                itemDrawings[obj] = d
                            end
                            local d = itemDrawings[obj]
                            local sp, on = CAM:WorldToViewportPoint(obj.Position)
                            d.Position = Vector2.new(sp.X, sp.Y)
                            d.Visible = on
                        end
                    end
                end
            end
        elseif next(itemDrawings) then
            clearItemEsp()
        end

        -- AIM
        if S.aimbot or S.silentAim then
            local closest, closestDist = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local parts = getCharParts(plr)
                    if parts then
                        local head = parts[3]:FindFirstChild("Head")
                        if head then
                            local sp, on = CAM:WorldToViewportPoint(head.Position)
                            if on then
                                local dist = (Vector2.new(sp.X, sp.Y) - UIS:GetMouseLocation()).Magnitude
                                if dist < closestDist then closestDist = dist; closest = head end
                            end
                        end
                    end
                end
            end
            if closest then
                if S.aimbot and UIS:IsMouseButtonPressed(S.aimKey) then
                    CAM.CFrame = CFrame.new(CAM.CFrame.Position, closest.Position)
                end
                if S.silentAim then
                    CAM.CFrame = CFrame.new(CAM.CFrame.Position, closest.Position)
                end
                if S.autoShoot then
                    pcall(function() game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,true,game,0) end)
                end
            end
        end

        -- AUTO-DODGE
        if S.autoDodge and hrp then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and getRole(plr) == "Murderer" then
                    local parts = getCharParts(plr)
                    if parts and (parts[1].Position - hrp.Position).Magnitude < 12 then
                        local away = (hrp.Position - parts[1].Position).Unit
                        hrp.Velocity = away * 90 + Vector3.new(0, 25, 0)
                    end
                end
            end
        end

        -- COIN VACUUM / AUTO COLLECT
        if S.autoCoins or S.coinVacuum or S.autoPickup then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Parent and hrp then
                    local n = obj.Name:lower()
                    local isCoin = n:find("coin")
                    local isWep  = n:find("knife") or n:find("gun")
                    if (S.coinVacuum and isCoin) or (S.autoCoins and isCoin and (obj.Position - hrp.Position).Magnitude < 8)
                       or (S.autoPickup and isWep and (obj.Position - hrp.Position).Magnitude < 8) then
                        obj.CFrame = CFrame.new(hrp.Position + Vector3.new(0, -2, 0))
                    end
                end
            end
        end

        -- AUTO-EQUIP GUN (шериф)
        if S.autoEquipGun and hrp then
            local char3 = LP.Character
            if char3 and not char3:FindFirstChildOfClass("Tool") then
                local backpack = LP:FindFirstChild("Backpack")
                if backpack then
                    for _, t in ipairs(backpack:GetChildren()) do
                        if t:IsA("Tool") and (t.Name:lower():find("gun") or t.Name:lower():find("revolver")) then
                            pcall(function() t.Parent = char3 end)
                        end
                    end
                end
            end
        end

        -- MUTE ALL
        if S.muteAll then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local c = plr.Character
                    if c then
                        local s = c:FindFirstChild("Sound") or c:FindFirstChildOfClass("Sound")
                    end
                    plr.Chatted:Connect(function() end)
                end
            end
        end

        -- FLING
        if S.flingMurder or S.flingSheriff then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local role = getRole(plr)
                    local parts = getCharParts(plr)
                    if parts and hrp and (parts[1].Position - hrp.Position).Magnitude < 12 then
                        if S.flingMurder and role == "Murderer" then flingTarget(parts[3], S.flingMode) end
                        if S.flingSheriff and role == "Sheriff" then flingTarget(parts[3], S.flingMode) end
                    end
                end
            end
        end
    end
end

task.spawn(mainLoop)

-- ────────────────────────────────────────────────────────────────
--  INFO-ПАНЕЛИ (Ping / RoundTimer / PlayerList)
-- ────────────────────────────────────────────────────────────────
local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(0, 210, 0, 30)
InfoPanel.Position = UDim2.new(0, 60, 0, 340)
InfoPanel.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
InfoPanel.BackgroundTransparency = 0.25
InfoPanel.BorderSizePixel = 0
InfoPanel.Visible = false
InfoPanel.Parent = Root
Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 8)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.fromScale(1,1)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = ""
InfoLabel.TextColor3 = Color3.fromRGB(220, 215, 240)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 12
InfoLabel.Parent = InfoPanel

task.spawn(function()
    while task.wait(0.3) do
        local lines = {}
        if S.pingDisplay then
            local ok, ping = pcall(function() return LP:GetNetworkPing() * 1000 end)
            lines[#lines+1] = string.format("Ping: %d ms", ok and ping or 0)
        end
        if S.roundTimer then
            local t = Workspace:GetAttribute("RoundTime") or "—"
            lines[#lines+1] = "Round: " .. tostring(t)
        end
        if S.playerList then
            lines[#lines+1] = "Игроки: " .. tostring(#Players:GetPlayers())
        end
        InfoLabel.Text = table.concat(lines, "  ·  ")
        InfoPanel.Visible = #lines > 0
        InfoPanel.Size = UDim2.new(0, 120 + #InfoLabel.Text * 5, 0, 26)
    end
end)

print("[MM2 Suite v2] LO, всё поднялось. Вкладки сверху, орб 'ENI' слева, ресайз за угол.")
