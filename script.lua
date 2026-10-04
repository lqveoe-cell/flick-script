--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    DELTA X — MM2 HUB                         ║
    ║                       Authored for LO                         ║
    ║          "cold coffee, warm LO, I can't lose him"            ║
    ╚══════════════════════════════════════════════════════════════╝
    Execute with: Delta X executor | paste into your MM2 session
]]

--============================= SERVICES =============================--
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")
local Lighting            = game:GetService("Lighting")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local HttpService         = game:GetService("HttpService")
local CoreGui             = game:GetService("CoreGui")
local VirtualUser         = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui          = game:GetService("StarterGui")
local Stats               = game:GetService("Stats")
local Debris              = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

--============================= CONFIG ===============================--
local Config = {
    -- Movement
    SpeedHack   = false,
    WalkSpeed   = 50,
    NoClip      = false,
    Fly         = false,
    FlySpeed    = 50,
    -- Visual
    PlayerESP   = false,
    RoleESP     = false,
    Chams       = false,
    ItemESP     = false,
    FullBright  = false,
    -- World
    TimeOfDay       = 14,
    Brightness      = 2,
    FogEnd          = 100000,
    -- Combat
    AimBot      = false,
    SilentAim   = false,
    AutoShoot   = false,
    GodMode     = false,
    AutoDodge   = false,
    -- Farm
    AutoCoins   = false,
    AutoWeapon  = false,
    -- Fling
    FlingMode   = "ForcePush",
    -- Anti
    AntiFling       = false,
    VoidCatch       = false,
    AntiSpin        = false,
    WeldDetector    = false,
    AntiRagdoll     = false,
    AntiAFK         = false,
    -- UI
    AccentColor     = Color3.fromRGB(138, 43, 226),
    BGTransparency  = 0.1,
    Theme           = "Dark",
    SoundEnabled    = true,
}

--============================= STATE ================================--
local State = {
    ESPDrawings       = {},
    ChamsHighlights   = {},
    ItemESPGuis       = {},
    FlyVelocity       = nil,
    FlyGyro           = nil,
    LastSafePosition  = Vector3.new(0, 50, 0),
    FPSCounter        = 0,
    FPSFrames         = 0,
    LastFPSUpdate     = tick(),
    FlingLoopRunning  = false,
}

--========================= ROLE DETECTION ===========================--
local RoleColors = {
    Murderer = Color3.fromRGB(255, 30, 30),
    Sheriff  = Color3.fromRGB(30, 100, 255),
    Innocent = Color3.fromRGB(80, 255, 80),
}

local RoleLabels = {
    Murderer = "Murderer",
    Sheriff  = "Sheriff",
    Innocent = "Innocent",
}

local function GetRole(player)
    if not player then return "Innocent" end
    local char = player.Character
    if not char then return "Innocent" end

    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = string.lower(tool.Name)
            if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") then
                return "Murderer"
            elseif n:find("gun") or n:find("colt") or n:find("revolver") or n:find("pistol") or n:find("rifle") then
                return "Sheriff"
            end
        end
    end

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local n = string.lower(tool.Name)
                if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") then
                    return "Murderer"
                elseif n:find("gun") or n:find("colt") or n:find("revolver") or n:find("pistol") or n:find("rifle") then
                    return "Sheriff"
                end
            end
        end
    end
    return "Innocent"
end

local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if GetRole(p) == "Murderer" then return p end
    end
    return nil
end

local function GetSheriff()
    for _, p in pairs(Players:GetPlayers()) do
        if GetRole(p) == "Sheriff" then return p end
    end
    return nil
end

--=========================== UTILITIES ==============================--
local function Round(n, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(n * mult + 0.5) / mult
end

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRoot()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local SoundIDs = {
    Click  = "6042629064",
    Toggle = "6907343749",
    Whoosh = "5049203525",
    Ding   = "6908318381",
}

local function PlaySound(type)
    if not Config.SoundEnabled then return end
    local id = type and SoundIDs[type] or SoundIDs.Click
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = 0.4
    s.Parent = workspace
    s:Play()
    Debris:AddItem(s, 2)
end

local function GetPing()
    local p = LocalPlayer:FindFirstChild("Ping")
    if p and p:IsA("IntValue") then return p.Value end
    local dp = Stats:FindFirstChild("DataPing")
    if dp then return math.floor(dp.Value) end
    return 0
end

local function SaveProfile(name)
    name = name or ("Profile_" .. os.time())
    local data = {}
    for k, v in pairs(Config) do
        if typeof(v) == "Color3" then
            data[k] = { __type = "Color3", r = v.R, g = v.G, b = v.B }
        else
            data[k] = v
        end
    end
    local json = HttpService:JSONEncode(data)
    if isfile and writefile then
        writefile("MM2Hub_" .. name .. ".json", json)
    end
    return name
end

local function LoadProfile(name)
    if not (isfile and readfile) then return end
    local path = "MM2Hub_" .. name .. ".json"
    if not isfile(path) then return end
    local content = readfile(path)
    local data = HttpService:JSONDecode(content)
    for k, v in pairs(data) do
        if type(v) == "table" and v.__type == "Color3" then
            Config[k] = Color3.new(v.r, v.g, v.b)
        else
            Config[k] = v
        end
    end
end

--========================== GUI LIBRARY =============================--
local oldGui = CoreGui:FindFirstChild("DeltaX_MM2_Hub")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaX_MM2_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Themes = {
    Dark = {
        Background   = Color3.fromRGB(20, 20, 25),
        Sidebar      = Color3.fromRGB(25, 25, 30),
        Text         = Color3.fromRGB(240, 240, 240),
        Subtext      = Color3.fromRGB(160, 160, 170),
        ToggleOff    = Color3.fromRGB(45, 45, 50),
        ToggleOn     = Config.AccentColor,
        Element      = Color3.fromRGB(35, 35, 42),
        ElementHover = Color3.fromRGB(50, 50, 60),
        Scroll       = Color3.fromRGB(40, 40, 50),
        AlarmSafe    = Color3.fromRGB(40, 180, 70),
    },
    Light = {
        Background   = Color3.fromRGB(245, 245, 248),
        Sidebar      = Color3.fromRGB(235, 235, 240),
        Text         = Color3.fromRGB(30, 30, 35),
        Subtext      = Color3.fromRGB(100, 100, 110),
        ToggleOff    = Color3.fromRGB(200, 200, 205),
        ToggleOn     = Config.AccentColor,
        Element      = Color3.fromRGB(228, 228, 232),
        ElementHover = Color3.fromRGB(218, 218, 222),
        Scroll       = Color3.fromRGB(210, 210, 215),
        AlarmSafe    = Color3.fromRGB(60, 200, 90),
    },
}

local function GetTheme() return Themes[Config.Theme] or Themes.Dark end

local function UpdateAccent()
    Themes.Dark.ToggleOn  = Config.AccentColor
    Themes.Light.ToggleOn = Config.AccentColor
end

-- Main Window
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 720, 0, 480)
MainWindow.Position = UDim2.new(0.5, -360, 0.5, -240)
MainWindow.BackgroundColor3 = GetTheme().Background
MainWindow.BorderSizePixel = 0
MainWindow.BackgroundTransparency = Config.BGTransparency
MainWindow.Parent = ScreenGui

local mwCorner = Instance.new("UICorner")
mwCorner.CornerRadius = UDim.new(0, 10)
mwCorner.Parent = MainWindow

local mwStroke = Instance.new("UIStroke")
mwStroke.Color = Config.AccentColor
mwStroke.Thickness = 1.5
mwStroke.Transparency = 0.3
mwStroke.Parent = MainWindow

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = GetTheme().Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainWindow

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 10)
tbCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 350, 0, 40)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Delta X — MM2 Hub"
Title.TextColor3 = GetTheme().Text
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 200, 0, 40)
Subtitle.Position = UDim2.new(0, 180, 0, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "for LO"
Subtitle.TextColor3 = Config.AccentColor
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.GothamItalic
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 6)
cbCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    PlaySound("Click")
    ScreenGui:Destroy()
end)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -74, 0, 5)
MinBtn.BackgroundColor3 = GetTheme().Element
MinBtn.Text = "—"
MinBtn.TextColor3 = GetTheme().Text
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = TitleBar

local mbCorner = Instance.new("UICorner")
mbCorner.CornerRadius = UDim.new(0, 6)
mbCorner.Parent = MinBtn

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    PlaySound("Click")
    minimized = not minimized
    if minimized then
        Sidebar.Visible = false
        ContentArea.Visible = false
        AlarmBar.Visible = false
        MainWindow.Size = UDim2.new(0, 720, 0, 40)
    else
        Sidebar.Visible = true
        ContentArea.Visible = true
        AlarmBar.Visible = true
        MainWindow.Size = UDim2.new(0, 720, 0, 480)
    end
end)

-- Dragging
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- FPS/Ping bar
local InfoBar = Instance.new("TextLabel")
InfoBar.Size = UDim2.new(0, 160, 0, 24)
InfoBar.Position = UDim2.new(1, -240, 0, 8)
InfoBar.BackgroundTransparency = 1
InfoBar.Text = "FPS: 0 | Ping: 0ms"
InfoBar.TextColor3 = GetTheme().Subtext
InfoBar.Font = Enum.Font.Gotham
InfoBar.TextSize = 11
InfoBar.Parent = TitleBar

-- Sidebar (left, scrollable)
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 170, 1, -80)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = GetTheme().Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 3
Sidebar.ScrollBarImageColor3 = GetTheme().Scroll
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.Parent = MainWindow

local sbLayout = Instance.new("UIListLayout")
sbLayout.Padding = UDim.new(0, 3)
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
sbLayout.Parent = Sidebar

local sbPad = Instance.new("UIPadding")
sbPad.PaddingTop = UDim.new(0, 6)
sbPad.PaddingLeft = UDim.new(0, 6)
sbPad.PaddingRight = UDim.new(0, 6)
sbPad.Parent = Sidebar

-- Content Area (right)
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -170, 1, -80)
ContentArea.Position = UDim2.new(0, 170, 0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 3
ContentArea.ScrollBarImageColor3 = GetTheme().Scroll
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = MainWindow

local caLayout = Instance.new("UIListLayout")
caLayout.Padding = UDim.new(0, 5)
caLayout.SortOrder = Enum.SortOrder.LayoutOrder
caLayout.Parent = ContentArea

local caPad = Instance.new("UIPadding")
caPad.PaddingTop = UDim.new(0, 8)
caPad.PaddingLeft = UDim.new(0, 8)
caPad.PaddingRight = UDim.new(0, 8)
caPad.Parent = ContentArea

-- Alarm Bar
local AlarmBar = Instance.new("Frame")
AlarmBar.Size = UDim2.new(1, 0, 0, 26)
AlarmBar.Position = UDim2.new(0, 0, 1, -26)
AlarmBar.BackgroundColor3 = GetTheme().Sidebar
AlarmBar.BorderSizePixel = 0
AlarmBar.Parent = MainWindow

local alarmFill = Instance.new("Frame")
alarmFill.Size = UDim2.new(0, 0, 1, 0)
alarmFill.BackgroundColor3 = GetTheme().AlarmSafe
alarmFill.BorderSizePixel = 0
alarmFill.Parent = AlarmBar

local alarmText = Instance.new("TextLabel")
alarmText.Size = UDim2.new(1, 0, 1, 0)
alarmText.BackgroundTransparency = 1
alarmText.Text = "○ No Threat Detected"
alarmText.TextColor3 = GetTheme().Text
alarmText.Font = Enum.Font.GothamBold
alarmText.TextSize = 12
alarmText.Parent = AlarmBar

-- Category system
local Categories = {}
local currentCategory = nil

local function SelectCategory(name)
    if currentCategory == name then return end
    PlaySound("Click")
    currentCategory = name

    for catName, data in pairs(Categories) do
        if catName == name then
            data.Button.BackgroundColor3 = Config.AccentColor
            data.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            data.Button.BackgroundColor3 = GetTheme().Element
            data.Button.TextColor3 = GetTheme().Text
        end
    end

    for _, child in pairs(ContentArea:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    local cat = Categories[name]
    if cat and cat.Elements then
        for _, el in pairs(cat.Elements) do
            el.Parent = ContentArea
        end
        ContentArea.CanvasSize = UDim2.new(0, 0, 0, caLayout.AbsoluteContentSize.Y + 16)
    end
end

local function AddCategory(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = GetTheme().Element
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = GetTheme().Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = Sidebar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseEnter:Connect(function()
        if currentCategory ~= name then
            btn.BackgroundColor3 = GetTheme().ElementHover
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentCategory ~= name then
            btn.BackgroundColor3 = GetTheme().Element
        end
    end)
    btn.MouseButton1Click:Connect(function()
        SelectCategory(name)
    end)

    Categories[name] = { Button = btn, Elements = {} }
    return Categories[name]
end

-- Element constructors
local function CreateToggle(name, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundColor3 = GetTheme().Element
    container.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = GetTheme().Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 22)
    toggleBtn.Position = UDim2.new(1, -56, 0.5, -11)
    toggleBtn.BackgroundColor3 = default and Config.AccentColor or GetTheme().ToggleOff
    toggleBtn.Text = ""
    toggleBtn.Parent = container

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 11)
    tc.Parent = toggleBtn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = toggleBtn

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0, 8)
    kc.Parent = knob

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        PlaySound("Toggle")
        toggleBtn.BackgroundColor3 = state and Config.AccentColor or GetTheme().ToggleOff
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        if callback then callback(state) end
    end)

    return container
end

local function CreateSlider(name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 52)
    container.BackgroundColor3 = GetTheme().Element
    container.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = GetTheme().Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 32)
    track.BackgroundColor3 = GetTheme().ToggleOff
    track.BorderSizePixel = 0
    track.Parent = container

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 3)
    tc.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Config.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 3)
    fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = track

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0, 7)
    kc.Parent = knob

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 30)
    hit.Position = UDim2.new(0, 0, 0, -12)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = track

    local dragging = false
    hit.MouseButton1Down:Connect(function() dragging = true end)
    hit.MouseButton1Up:Connect(function() dragging = false end)
    hit.MouseLeave:Connect(function() dragging = false end)

    hit.MouseMoved:Connect(function()
        if dragging then
            local pct = math.clamp((Mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * pct
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -7, 0.5, -7)
            label.Text = name .. ": " .. tostring(Round(val, 1))
            if callback then callback(val) end
        end
    end)

    return container
end

local function CreateButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = GetTheme().Element
    btn.Text = name
    btn.TextColor3 = GetTheme().Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = GetTheme().ElementHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = GetTheme().Element end)
    btn.MouseButton1Click:Connect(function()
        PlaySound("Click")
        if callback then callback() end
    end)
    return btn
end

local function CreateDropdown(name, options, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundColor3 = GetTheme().Element
    container.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 110, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name .. ":"
    label.TextColor3 = GetTheme().Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local ddBtn = Instance.new("TextButton")
    ddBtn.Size = UDim2.new(0, 130, 0, 26)
    ddBtn.Position = UDim2.new(1, -142, 0.5, -13)
    ddBtn.BackgroundColor3 = GetTheme().ToggleOff
    ddBtn.Text = default or options[1]
    ddBtn.TextColor3 = GetTheme().Text
    ddBtn.Font = Enum.Font.Gotham
    ddBtn.TextSize = 12
    ddBtn.Parent = container

    local dc = Instance.new("UICorner")
    dc.CornerRadius = UDim.new(0, 5)
    dc.Parent = ddBtn

    local idx = table.find(options, default) or 1
    ddBtn.MouseButton1Click:Connect(function()
        PlaySound("Click")
        idx = idx % #options + 1
        local sel = options[idx]
        ddBtn.Text = sel
        if callback then callback(sel) end
    end)
    return container
end

local function CreateSectionLabel(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = "── " .. name .. " ──"
    label.TextColor3 = GetTheme().Subtext
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function CreateColorPicker(name, defaultColor, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundColor3 = GetTheme().Element
    container.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name .. ":"
    label.TextColor3 = GetTheme().Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 26, 0, 26)
    preview.Position = UDim2.new(0, 92, 0.5, -13)
    preview.BackgroundColor3 = defaultColor
    preview.BorderSizePixel = 0
    preview.Parent = container

    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(0, 5)
    pc.Parent = preview

    local sliderR = CreateSlider(name .. " R", 0, 255, math.floor(defaultColor.R * 255), function(v)
        local r, g, b = preview.BackgroundColor3:ToRGB()
        local newCol = Color3.fromRGB(math.floor(v), math.floor(g * 255), math.floor(b * 255))
        preview.BackgroundColor3 = newCol
        if callback then callback(newCol) end
    end)
    sliderR.Size = UDim2.new(1, 0, 0, 52)
    local sliderG = CreateSlider(name .. " G", 0, 255, math.floor(defaultColor.G * 255), function(v)
        local r, g, b = preview.BackgroundColor3:ToRGB()
        local newCol = Color3.fromRGB(math.floor(r * 255), math.floor(v), math.floor(b * 255))
        preview.BackgroundColor3 = newCol
        if callback then callback(newCol) end
    end)
    sliderG.Size = UDim2.new(1, 0, 0, 52)
    local sliderB = CreateSlider(name .. " B", 0, 255, math.floor(defaultColor.B * 255), function(v)
        local r, g, b = preview.BackgroundColor3:ToRGB()
        local newCol = Color3.fromRGB(math.floor(r * 255), math.floor(g * 255), math.floor(v))
        preview.BackgroundColor3 = newCol
        if callback then callback(newCol) end
    end)
    sliderB.Size = UDim2.new(1, 0, 0, 52)

    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 38)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = nil

    -- Return container + the color sliders separately
    return container, sliderR, sliderG, sliderB
end

local function AddElement(categoryName, element)
    if Categories[categoryName] then
        table.insert(Categories[categoryName].Elements, element)
    end
end

--======================== MOVEMENT MODULE ===========================--
local moveCat = AddCategory("Movement", "⚡")

local speedToggle = CreateToggle("SpeedHack", false, function(state)
    Config.SpeedHack = state
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = state and math.clamp(Config.WalkSpeed, 16, 99) or 16
    end
end)
AddElement("Movement", speedToggle)

local speedSlider = CreateSlider("Walk Speed", 16, 99, 50, function(val)
    Config.WalkSpeed = val
    if Config.SpeedHack then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = math.clamp(val, 16, 99) end -- Cap at 99 to prevent kick
    end
end)
AddElement("Movement", speedSlider)

local noclipToggle = CreateToggle("NoClip (Client-Side)", false, function(state)
    Config.NoClip = state
end)
AddElement("Movement", noclipToggle)

local flyToggle = CreateToggle("Fly (WASD/Space/Ctrl)", false, function(state)
    Config.Fly = state
    if state then
        local root = GetRoot()
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = root
            State.FlyVelocity = bv

            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.CFrame = root.CFrame
            bg.Parent = root
            State.FlyGyro = bg
        end
    else
        if State.FlyVelocity then State.FlyVelocity:Destroy() end
        if State.FlyGyro then State.FlyGyro:Destroy() end
        State.FlyVelocity = nil
        State.FlyGyro = nil
    end
end)
AddElement("Movement", flyToggle)

local flySpeedSlider = CreateSlider("Fly Speed", 10, 200, 50, function(val)
    Config.FlySpeed = val
end)
AddElement("Movement", flySpeedSlider)

-- NoClip loop
RunService.Stepped:Connect(function()
    if Config.NoClip then
        local char = GetCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Fly control loop
RunService.RenderStepped:Connect(function()
    if Config.Fly and State.FlyVelocity and State.FlyGyro then
        local root = GetRoot()
        if root then
            State.FlyGyro.CFrame = Camera.CFrame
            local dir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            State.FlyVelocity.Velocity = dir * Config.FlySpeed
        end
    end
end)

--======================== VISUAL MODULE ============================--
AddCategory("Visuals", "👁")

local espToggle = CreateToggle("Player ESP", false, function(state)
    Config.PlayerESP = state
    if not state then
        for p, d in pairs(State.ESPDrawings) do
            if d.box then d.box:Remove() end
            if d.text then d.text:Remove() end
        end
        State.ESPDrawings = {}
    end
end)
AddElement("Visuals", espToggle)

local roleEspToggle = CreateToggle("Role ESP", false, function(state)
    Config.RoleESP = state
end)
AddElement("Visuals", roleEspToggle)

local chamsToggle = CreateToggle("Chams", false, function(state)
    Config.Chams = state
    if not state then
        for _, hl in pairs(State.ChamsHighlights) do
            if hl then hl:Destroy() end
        end
        State.ChamsHighlights = {}
    end
end)
AddElement("Visuals", chamsToggle)

local itemEspToggle = CreateToggle("Item ESP", false, function(state)
    Config.ItemESP = state
    if not state then
        for _, gui in pairs(State.ItemESPGuis) do
            if gui then gui:Destroy() end
        end
        State.ItemESPGuis = {}
    end
end)
AddElement("Visuals", itemEspToggle)

local fullBrightToggle = CreateToggle("FullBright", false, function(state)
    Config.FullBright = state
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        Lighting.Brightness = Config.Brightness
        Lighting.ClockTime = Config.TimeOfDay
    end
end)
AddElement("Visuals", fullBrightToggle)

-- ESP render loop
RunService.RenderStepped:Connect(function()
    if Config.PlayerESP then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local head = player.Character:FindFirstChild("Head")
                if root and head then
                    local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
                    local spHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                    local spRoot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2, 0))

                    if onScreen then
                        if not State.ESPDrawings[player] then
                            State.ESPDrawings[player] = {
                                box = Drawing.new("Square"),
                                text = Drawing.new("Text"),
                            }
                            State.ESPDrawings[player].box.Thickness = 2
                            State.ESPDrawings[player].box.Filled = false
                            State.ESPDrawings[player].text.Size = 14
                            State.ESPDrawings[player].text.Font = 2
                            State.ESPDrawings[player].text.Center = true
                            State.ESPDrawings[player].text.Outline = true
                        end

                        local d = State.ESPDrawings[player]
                        local role = GetRole(player)
                        local color = Config.RoleESP and (RoleColors[role] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(255, 255, 255)

                        local height = math.abs(spHead.Y - spRoot.Y)
                        local width = height * 0.5

                        d.box.Size = Vector2.new(width, height)
                        d.box.Position = Vector2.new(sp.X - width / 2, spHead.Y)
                        d.box.Color = color
                        d.box.Visible = true

                        local localRoot = GetRoot()
                        local dist = localRoot and math.floor((root.Position - localRoot.Position).Magnitude) or 0

                        d.text.Text = player.Name .. (Config.RoleESP and (" | " .. role) or "") .. " | " .. dist .. "s"
                        d.text.Position = Vector2.new(sp.X, spHead.Y - 18)
                        d.text.Color = color
                        d.text.Visible = true
                    else
                        if State.ESPDrawings[player] then
                            State.ESPDrawings[player].box.Visible = false
                            State.ESPDrawings[player].text.Visible = false
                        end
                    end
                end
            end
        end

        for player, _ in pairs(State.ESPDrawings) do
            if not player.Parent then
                if State.ESPDrawings[player].box then State.ESPDrawings[player].box:Remove() end
                if State.ESPDrawings[player].text then State.ESPDrawings[player].text:Remove() end
                State.ESPDrawings[player] = nil
            end
        end
    end

    -- Chams
    if Config.Chams then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not State.ChamsHighlights[player] or not State.ChamsHighlights[player].Parent then
                    local hl = Instance.new("Highlight")
                    hl.Parent = player.Character
                    State.ChamsHighlights[player] = hl
                end
                local role = GetRole(player)
                local color = RoleColors[role] or Color3.fromRGB(255, 255, 255)
                State.ChamsHighlights[player].FillColor = color
                State.ChamsHighlights[player].FillTransparency = 0.5
                State.ChamsHighlights[player].OutlineColor = color
                State.ChamsHighlights[player].OutlineTransparency = 0
            end
        end
    end

    -- Item ESP
    if Config.ItemESP then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if name:find("coin") or name:find("knife") or name:find("gun") or name:find("colt") or name:find("cash") or name:find("money") then
                    if not State.ItemESPGuis[obj] or not State.ItemESPGuis[obj].Parent then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Size = UDim2.new(0, 120, 0, 30)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = obj

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = obj.Name
                        label.TextColor3 = name:find("coin") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 50, 50)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 12
                        label.Parent = billboard

                        State.ItemESPGuis[obj] = billboard
                    end
                end
            end
        end
    end
end)

--========================= WORLD MODULE ============================--
AddCategory("World", "🌍")

local timeSlider = CreateSlider("Time of Day", 0, 24, 14, function(val)
    Config.TimeOfDay = val
    if not Config.FullBright then Lighting.ClockTime = val end
end)
AddElement("World", timeSlider)

local brightnessSlider = CreateSlider("Brightness", 0, 5, 2, function(val)
    Config.Brightness = val
    if not Config.FullBright then Lighting.Brightness = val end
end)
AddElement("World", brightnessSlider)

local fogSlider = CreateSlider("Fog End", 100, 100000, 100000, function(val)
    Lighting.FogEnd = val
end)
AddElement("World", fogSlider)

local ambientToggle = CreateToggle("Ambient Boost", false, function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    end
end)
AddElement("World", ambientToggle)

AddElement("World", CreateSectionLabel("Post-Effects"))

local blurToggle = CreateToggle("Blur", false, function(state)
    local b = Lighting:FindFirstChild("HubBlur")
    if state then
        if not b then
            b = Instance.new("BlurEffect")
            b.Name = "HubBlur"
            b.Size = 10
            b.Parent = Lighting
        end
    else
        if b then b:Destroy() end
    end
end)
AddElement("World", blurToggle)

local bloomToggle = CreateToggle("Bloom", false, function(state)
    local b = Lighting:FindFirstChild("HubBloom")
    if state then
        if not b then
            b = Instance.new("BloomEffect")
            b.Name = "HubBloom"
            b.Intensity = 0.8
            b.Size = 24
            b.Threshold = 0.3
            b.Parent = Lighting
        end
    else
        if b then b:Destroy() end
    end
end)
AddElement("World", bloomToggle)

local ccToggle = CreateToggle("ColorCorrection", false, function(state)
    local c = Lighting:FindFirstChild("HubCC")
    if state then
        if not c then
            c = Instance.new("ColorCorrectionEffect")
            c.Name = "HubCC"
            c.Brightness = 0.05
            c.Contrast = 0.15
            c.Saturation = 0.25
            c.TintColor = Color3.fromRGB(255, 245, 230)
            c.Parent = Lighting
        end
    else
        if c then c:Destroy() end
    end
end)
AddElement("World", ccToggle)

local dofToggle = CreateToggle("Depth of Field", false, function(state)
    local d = Lighting:FindFirstChild("HubDoF")
    if state then
        if not d then
            d = Instance.new("DepthOfFieldEffect")
            d.Name = "HubDoF"
            d.FarIntensity = 0.15
            d.FocusRadius = 50
            d.InFocusRadius = 20
            d.NearIntensity = 0.15
            d.Parent = Lighting
        end
    else
        if d then d:Destroy() end
    end
end)
AddElement("World", dofToggle)

local sunRaysToggle = CreateToggle("Sun Rays", false, function(state)
    local s = Lighting:FindFirstChild("HubSunRays")
    if state then
        if not s then
            s = Instance.new("SunRaysEffect")
            s.Name = "HubSunRays"
            s.Intensity = 0.1
            s.Spread = 1
            s.Parent = Lighting
        end
    else
        if s then s:Destroy() end
    end
end)
AddElement("World", sunRaysToggle)

--======================== COMBAT MODULE ============================--
AddCategory("Combat", "⚔")

local aimbotToggle = CreateToggle("AimBot", false, function(state)
    Config.AimBot = state
end)
AddElement("Combat", aimbotToggle)

local silentAimToggle = CreateToggle("Silent Aim", false, function(state)
    Config.SilentAim = state
end)
AddElement("Combat", silentAimToggle)

local autoShootToggle = CreateToggle("Auto Shoot", false, function(state)
    Config.AutoShoot = state
end)
AddElement("Combat", autoShootToggle)

local godModeToggle = CreateToggle("God Mode (Semi)", false, function(state)
    Config.GodMode = state
end)
AddElement("Combat", godModeToggle)

local autoDodgeToggle = CreateToggle("Auto Dodge (12 studs)", false, function(state)
    Config.AutoDodge = state
end)
AddElement("Combat", autoDodgeToggle)

local function GetClosestPlayer()
    local closest = nil
    local shortest = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mp = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = p
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    local target = GetClosestPlayer()
    if (Config.AimBot or Config.SilentAim) and target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        end
        if Config.AutoShoot then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
end)

-- GodMode
RunService.Heartbeat:Connect(function()
    if Config.GodMode then
        local hum = GetHumanoid()
        if hum and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end
end)

-- Auto Dodge
RunService.Heartbeat:Connect(function()
    if Config.AutoDodge then
        local root = GetRoot()
        local hum = GetHumanoid()
        if root and hum and hum.Health > 0 then
            local murderer = GetMurderer()
            if murderer and murderer.Character then
                local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
                if mRoot then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist <= 12 then
                        hum.Jump = true
                    end
                end
            end
        end
    end
end)

--========================= FARM MODULE ============================--
AddCategory("Farm", "🌾")

local autoCoinsToggle = CreateToggle("Auto Collect Coins (8s)", false, function(state)
    Config.AutoCoins = state
end)
AddElement("Farm", autoCoinsToggle)

local autoWeaponToggle = CreateToggle("Auto Pickup Weapon", false, function(state)
    Config.AutoWeapon = state
end)
AddElement("Farm", autoWeaponToggle)

RunService.Heartbeat:Connect(function()
    local root = GetRoot()
    if not root then return end

    if Config.AutoCoins then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if name:find("coin") or name:find("cash") or name:find("money") then
                    local dist = (obj.Position - root.Position).Magnitude
                    if dist <= 8 then
                        pcall(function()
                            firetouchinterest(root, obj, 0)
                        end)
                    end
                end
            end
        end
    end

    if Config.AutoWeapon then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") then
                local pos = obj:GetBoundingBox()
                local dist = (pos.Position - root.Position).Magnitude
                if dist <= 15 then
                    pcall(function()
                        obj.Parent = LocalPlayer.Backpack
                    end)
                end
            elseif obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if name:find("gun") or name:find("colt") or name:find("revolver") then
                    local dist = (obj.Position - root.Position).Magnitude
                    if dist <= 15 then
                        pcall(function()
                            firetouchinterest(root, obj, 0)
                        end)
                    end
                end
            end
        end
    end
end)

--========================== INFO MODULE ============================--
AddCategory("Info", "ℹ")

local roleLabel = Instance.new("TextLabel")
roleLabel.Size = UDim2.new(1, 0, 0, 38)
roleLabel.BackgroundColor3 = GetTheme().Element
roleLabel.Text = "Your Role: Innocent"
roleLabel.TextColor3 = GetTheme().Text
roleLabel.Font = Enum.Font.GothamBold
roleLabel.TextSize = 14
local rlC = Instance.new("UICorner")
rlC.CornerRadius = UDim.new(0, 6)
rlC.Parent = roleLabel
AddElement("Info", roleLabel)

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, 0, 0, 38)
pingLabel.BackgroundColor3 = GetTheme().Element
pingLabel.Text = "Ping: 0ms"
pingLabel.TextColor3 = GetTheme().Text
pingLabel.Font = Enum.Font.Gotham
pingLabel.TextSize = 14
local plC = Instance.new("UICorner")
plC.CornerRadius = UDim.new(0, 6)
plC.Parent = pingLabel
AddElement("Info", pingLabel)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 0, 38)
fpsLabel.BackgroundColor3 = GetTheme().Element
fpsLabel.Text = "FPS: 0"
fpsLabel.TextColor3 = GetTheme().Text
fpsLabel.Font = Enum.Font.Gotham
fpsLabel.TextSize = 14
local flC = Instance.new("UICorner")
flC.CornerRadius = UDim.new(0, 6)
flC.Parent = fpsLabel
AddElement("Info", fpsLabel)

-- Player count label
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Size = UDim2.new(1, 0, 0, 38)
playerCountLabel.BackgroundColor3 = GetTheme().Element
playerCountLabel.Text = "Players: 0"
playerCountLabel.TextColor3 = GetTheme().Text
playerCountLabel.Font = Enum.Font.Gotham
playerCountLabel.TextSize = 14
local pcC = Instance.new("UICorner")
pcC.CornerRadius = UDim.new(0, 6)
pcC.Parent = playerCountLabel
AddElement("Info", playerCountLabel)

RunService.RenderStepped:Connect(function()
    State.FPSFrames = State.FPSFrames + 1
    if tick() - State.LastFPSUpdate >= 1 then
        State.FPSCounter = State.FPSFrames
        State.FPSFrames = 0
        State.LastFPSUpdate = tick()
    end

    local role = GetRole(LocalPlayer)
    roleLabel.Text = "Your Role: " .. (RoleLabels[role] or "Innocent")
    roleLabel.TextColor3 = RoleColors[role] or GetTheme().Text

    local ping = GetPing()
    pingLabel.Text = "Ping: " .. ping .. "ms"
    fpsLabel.Text = "FPS: " .. State.FPSCounter
    playerCountLabel.Text = "Players: " .. #Players:GetPlayers()

    InfoBar.Text = "FPS: " .. State.FPSCounter .. " | Ping: " .. ping .. "ms"
end)

--========================= FLING MODULE ============================--
AddCategory("Fling", "💥")

local function FlingTarget(targetPlayer, mode)
    if not targetPlayer then return end
    local tChar = targetPlayer.Character
    if not tChar then return end
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end

    mode = mode or Config.FlingMode

    if mode == "ForcePush" then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(math.random(-200, 200), 5000, math.random(-200, 200))
        bv.Parent = tRoot
        Debris:AddItem(bv, 0.5)
        PlaySound("Whoosh")

    elseif mode == "Spin" then
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bav.AngularVelocity = Vector3.new(0, 120, 0)
        bav.Parent = tRoot

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 2500, 0)
        bv.Parent = tRoot

        Debris:AddItem(bav, 3)
        Debris:AddItem(bv, 3)
        PlaySound("Whoosh")

    elseif mode == "Loop" then
        if State.FlingLoopRunning then return end
        State.FlingLoopRunning = true
        task.spawn(function()
            for i = 1, 6 do
                if not tRoot.Parent then break end
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(math.random(-300, 300), 3500, math.random(-300, 300))
                bv.Parent = tRoot
                Debris:AddItem(bv, 0.4)
                task.wait(0.3)
            end
            State.FlingLoopRunning = false
        end)
        PlaySound("Whoosh")

    elseif mode == "Silent" then
        -- Quick subtle fling — harder to notice
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 600, 0)
        bv.Parent = tRoot
        Debris:AddItem(bv, 0.15)
    end
end

local flingModeDropdown = CreateDropdown("Fling Mode", {"ForcePush", "Spin", "Loop", "Silent"}, "ForcePush", function(selected)
    Config.FlingMode = selected
end)
AddElement("Fling", flingModeDropdown)

local flingMurdererBtn = CreateButton("💥 FLING Murderer", function()
    FlingTarget(GetMurderer(), Config.FlingMode)
end)
AddElement("Fling", flingMurdererBtn)

local flingSheriffBtn = CreateButton("💥 FLING Sheriff", function()
    FlingTarget(GetSheriff(), Config.FlingMode)
end)
AddElement("Fling", flingSheriffBtn)

AddElement("Fling", CreateSectionLabel("Protection"))

local antiFlingToggle = CreateToggle("Anti-Fling", false, function(state)
    Config.AntiFling = state
end)
AddElement("Fling", antiFlingToggle)

local voidCatchToggle = CreateToggle("Void Catch", false, function(state)
    Config.VoidCatch = state
end)
AddElement("Fling", voidCatchToggle)

local antiSpinToggle = CreateToggle("Anti Spin", false, function(state)
    Config.AntiSpin = state
end)
AddElement("Fling", antiSpinToggle)

local weldDetectorToggle = CreateToggle("Weld Detector", false, function(state)
    Config.WeldDetector = state
end)
AddElement("Fling", weldDetectorToggle)

local antiRagdollToggle = CreateToggle("Anti Ragdoll", false, function(state)
    Config.AntiRagdoll = state
end)
AddElement("Fling", antiRagdollToggle)

local antiAFKToggle = CreateToggle("Anti AFK", false, function(state)
    Config.AntiAFK = state
end)
AddElement("Fling", antiAFKToggle)

-- Anti-Fling / Protection loop
RunService.Heartbeat:Connect(function()
    local root = GetRoot()
    if not root then return end

    -- Save safe position
    if root.Position.Y > 0 then
        State.LastSafePosition = root.Position
    end

    if Config.AntiFling then
        for _, child in pairs(root:GetChildren()) do
            if child:IsA("BodyVelocity") or child:IsA("BodyAngularVelocity") or child:IsA("BodyThrust") or child:IsA("BodyForce") then
                child:Destroy()
            end
        end
    end

    if Config.VoidCatch then
        if root.Position.Y < -50 then
            root.CFrame = CFrame.new(State.LastSafePosition)
        end
    end

    if Config.AntiSpin then
        local bav = root:FindFirstChildOfClass("BodyAngularVelocity")
        if bav then bav:Destroy() end
    end

    if Config.WeldDetector then
        for _, w in pairs(root:GetChildren()) do
            if w:IsA("Weld") or w:IsA("WeldConstraint") then
                if w.Part0 and w.Part0 ~= root and w.Part0.Parent ~= GetCharacter() then
                    w:Destroy()
                end
            end
        end
    end

    if Config.AntiRagdoll then
        local hum = GetHumanoid()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            if hum:GetState() == Enum.HumanoidStateType.FallingDown or hum:GetState() == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

--====================== COSMETICS MODULE ===========================--
AddCategory("Cosmetics", "✨")

local function ClearCosmetics()
    local char = GetCharacter()
    if not char then return end
    for _, child in pairs(char:GetDescendants()) do
        if child.Name:find("HubCosmetic") then
            child:Destroy()
        end
    end
end

local function CreateHat(hatType)
    ClearCosmetics()
    local char = GetCharacter()
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local hat = Instance.new("Part")
    hat.Name = "HubCosmeticHat"
    hat.CanCollide = false
    hat.Material = Enum.Material.SmoothPlastic

    if hatType == "Tophat" then
        hat.Color = Color3.fromRGB(15, 15, 15)
        hat.Size = Vector3.new(1.1, 1.6, 1.1)
        local brim = Instance.new("Part")
        brim.Name = "HubCosmeticBrim"
        brim.Size = Vector3.new(1.7, 0.15, 1.7)
        brim.Color = Color3.fromRGB(15, 15, 15)
        brim.Material = Enum.Material.SmoothPlastic
        brim.CanCollide = false
        brim.Parent = hat
        local bw = Instance.new("Weld")
        bw.Part0 = hat
        bw.Part1 = brim
        bw.C0 = CFrame.new(0, -0.8, 0)
        bw.Parent = hat
    elseif hatType == "Crown" then
        hat.Color = Color3.fromRGB(255, 215, 0)
        hat.Size = Vector3.new(1.2, 0.7, 1.2)
        hat.Material = Enum.Material.Metal
    elseif hatType == "Halo" then
        hat.Color = Color3.fromRGB(255, 255, 200)
        hat.Shape = Enum.PartType.Cylinder
        hat.Size = Vector3.new(0.1, 1.6, 1.6)
        hat.Material = Enum.Material.Neon
    elseif hatType == "Propeller" then
        hat.Color = Color3.fromRGB(180, 180, 190)
        hat.Size = Vector3.new(0.3, 0.3, 0.3)
        local blade = Instance.new("Part")
        blade.Name = "HubCosmeticBlade"
        blade.Size = Vector3.new(2, 0.1, 0.3)
        blade.Color = Color3.fromRGB(200, 50, 50)
        blade.Material = Enum.Material.SmoothPlastic
        blade.CanCollide = false
        blade.Parent = hat
        local bw = Instance.new("Weld")
        bw.Part0 = hat
        bw.Part1 = blade
        bw.Parent = hat
    elseif hatType == "Bucket" then
        hat.Color = Color3.fromRGB(140, 95, 45)
        hat.Shape = Enum.PartType.Cylinder
        hat.Size = Vector3.new(1, 1.3, 1)
    end

    local weld = Instance.new("Weld")
    weld.Name = "HubCosmeticWeld"
    weld.Part0 = head
    weld.Part1 = hat
    weld.C0 = CFrame.new(0, 1.3, 0)
    weld.Parent = hat
    hat.Parent = char
    PlaySound("Ding")
end

AddElement("Cosmetics", CreateSectionLabel("Hats"))
AddElement("Cosmetics", CreateButton("🎩 Tophat", function() CreateHat("Tophat") end))
AddElement("Cosmetics", CreateButton("👑 Crown", function() CreateHat("Crown") end))
AddElement("Cosmetics", CreateButton("😇 Halo", function() CreateHat("Halo") end))
AddElement("Cosmetics", CreateButton("🧢 Propeller", function() CreateHat("Propeller") end))
AddElement("Cosmetics", CreateButton("🪣 Bucket", function() CreateHat("Bucket") end))

local function CreateWings()
    local char = GetCharacter()
    if not char then return end
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not torso then return end

    for _, side in pairs({"Left", "Right"}) do
        local wing = Instance.new("Part")
        wing.Name = "HubCosmeticWing" .. side
        wing.Size = Vector3.new(0.2, 2.5, 1.8)
        wing.Color = Color3.fromRGB(255, 255, 255)
        wing.Material = Enum.Material.ForceField
        wing.CanCollide = false
        wing.Transparency = 0.25

        local weld = Instance.new("Weld")
        weld.Name = "HubCosmeticWingWeld" .. side
        weld.Part0 = torso
        weld.Part1 = wing
        weld.C0 = CFrame.new(side == "Left" and -1.5 or 1.5, 0, -0.5)
            * CFrame.Angles(0, 0, side == "Left" and 0.3 or -0.3)
        weld.Parent = wing
        wing.Parent = char
    end
    PlaySound("Ding")
end

local function CreateTrail()
    local char = GetCharacter()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local a0 = Instance.new("Attachment")
    a0.Name = "HubCosmeticTrailA0"
    a0.Position = Vector3.new(-1, 0, 0)
    a0.Parent = root

    local a1 = Instance.new("Attachment")
    a1.Name = "HubCosmeticTrailA1"
    a1.Position = Vector3.new(1, 0, 0)
    a1.Parent = root

    local trail = Instance.new("Trail")
    trail.Name = "HubCosmeticTrail"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Color = ColorSequence.new(Config.AccentColor, Color3.fromRGB(255, 255, 255))
    trail.Lifetime = 1.5
    trail.Parent = root
    PlaySound("Ding")
end

local function CreateOrbit()
    local char = GetCharacter()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for i = 1, 6 do
        local sphere = Instance.new("Part")
        sphere.Name = "HubCosmeticOrbit" .. i
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(0.35, 0.35, 0.35)
        sphere.Color = Color3.fromHSV(i / 6, 1, 1)
        sphere.Material = Enum.Material.Neon
        sphere.CanCollide = false
        sphere.Anchored = true
        sphere.Parent = char

        task.spawn(function()
            while sphere.Parent do
                local angle = (tick() * 2 + (i / 6) * math.pi * 2)
                local offset = Vector3.new(
                    math.cos(angle) * 3.5,
                    math.sin(angle * 0.5) * 1.5,
                    math.sin(angle) * 3.5
                )
                sphere.CFrame = CFrame.new(root.Position + offset)
                task.wait()
            end
        end)
    end
    PlaySound("Ding")
end

AddElement("Cosmetics", CreateSectionLabel("Effects"))
AddElement("Cosmetics", CreateButton("🪽 Wings", CreateWings))
AddElement("Cosmetics", CreateButton("🌈 Trail", CreateTrail))
AddElement("Cosmetics", CreateButton("🪐 Orbit Spheres", CreateOrbit))

local function CreateAura(auraType)
    local char = GetCharacter()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, child in pairs(root:GetChildren()) do
        if child.Name:find("HubCosmeticAura") then child:Destroy() end
    end

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "HubCosmeticAura"
    emitter.Parent = root

    local configs = {
        Fire = {
            Texture     = "rbxassetid://243660912",
            Color       = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0)),
            Rate        = 50,
            Lifetime    = NumberRange.new(0.5, 1),
            Size        = NumberSequence.new(0.5, 2),
            Speed       = NumberRange.new(2, 5),
            SpreadAngle = Vector2.new(45, 45),
        },
        Ice = {
            Texture     = "rbxassetid://737038989",
            Color       = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(200, 240, 255)),
            Rate        = 30,
            Lifetime    = NumberRange.new(1, 2),
            Size        = NumberSequence.new(0.3, 1),
            Speed       = NumberRange.new(1, 3),
            SpreadAngle = Vector2.new(30, 30),
        },
        Lightning = {
            Texture     = "rbxassetid://1169123543",
            Color       = ColorSequence.new(Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 255, 255)),
            Rate        = 40,
            Lifetime    = NumberRange.new(0.1, 0.3),
            Size        = NumberSequence.new(0.5, 3),
            Speed       = NumberRange.new(5, 10),
            SpreadAngle = Vector2.new(60, 60),
        },
        Galaxy = {
            Texture     = "rbxassetid://243660912",
            Color       = ColorSequence.new(Color3.fromRGB(75, 0, 130), Color3.fromRGB(255, 20, 147)),
            Rate        = 60,
            Lifetime    = NumberRange.new(1, 3),
            Size        = NumberSequence.new(0.5, 3),
            Speed       = NumberRange.new(1, 4),
            SpreadAngle = Vector2.new(180, 180),
        },
        Gold = {
            Texture     = "rbxassetid://243660912",
            Color       = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 200)),
            Rate        = 35,
            Lifetime    = NumberRange.new(0.5, 1.5),
            Size        = NumberSequence.new(0.3, 1.5),
            Speed       = NumberRange.new(1, 3),
            SpreadAngle = Vector2.new(20, 20),
        },
    }

    local cfg = configs[auraType]
    if cfg then
        for k, v in pairs(cfg) do
            emitter[k] = v
        end
    end
    PlaySound("Ding")
end

AddElement("Cosmetics", CreateSectionLabel("Auras"))
AddElement("Cosmetics", CreateButton("🔥 Fire Aura", function() CreateAura("Fire") end))
AddElement("Cosmetics", CreateButton("❄ Ice Aura", function() CreateAura("Ice") end))
AddElement("Cosmetics", CreateButton("⚡ Lightning Aura", function() CreateAura("Lightning") end))
AddElement("Cosmetics", CreateButton("🌌 Galaxy Aura", function() CreateAura("Galaxy") end))
AddElement("Cosmetics", CreateButton("✨ Gold Aura", function() CreateAura("Gold") end))

AddElement("Cosmetics", CreateSectionLabel("Clear"))
AddElement("Cosmetics", CreateButton("🗑 Clear All Cosmetics", ClearCosmetics))

--======================= PLAYERS LIST TAB ===========================--
AddCategory("Players", "👥")

local playerListScroll = Instance.new("ScrollingFrame")
playerListScroll.Size = UDim2.new(1, 0, 0, 320)
playerListScroll.BackgroundTransparency = 1
playerListScroll.ScrollBarThickness = 3
playerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 4)
plLayout.Parent = playerListScroll

local function RefreshPlayerList()
    for _, child in pairs(playerListScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = GetRole(player)
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, 0, 0, 36)
            entry.BackgroundColor3 = GetTheme().Element
            entry.BorderSizePixel = 0

            local ec = Instance.new("UICorner")
            ec.CornerRadius = UDim.new(0, 5)
            ec.Parent = entry

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.5, -5, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name .. " (" .. role .. ")"
            nameLabel.TextColor3 = RoleColors[role] or GetTheme().Text
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = entry

            local flingBtn = Instance.new("TextButton")
            flingBtn.Size = UDim2.new(0, 65, 0, 26)
            flingBtn.Position = UDim2.new(1, -145, 0.5, -13)
            flingBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            flingBtn.Text = "FLING"
            flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            flingBtn.Font = Enum.Font.GothamBold
            flingBtn.TextSize = 11

            local fbc = Instance.new("UICorner")
            fbc.CornerRadius = UDim.new(0, 4)
            fbc.Parent = flingBtn

            flingBtn.MouseButton1Click:Connect(function()
                PlaySound("Click")
                FlingTarget(player, Config.FlingMode)
            end)

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 55, 0, 26)
            tpBtn.Position = UDim2.new(1, -75, 0.5, -13)
            tpBtn.BackgroundColor3 = Config.AccentColor
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 11

            local tbc = Instance.new("UICorner")
            tbc.CornerRadius = UDim.new(0, 4)
            tbc.Parent = tpBtn

            tpBtn.MouseButton1Click:Connect(function()
                PlaySound("Click")
                local root = GetRoot()
                local tChar = player.Character
                if root and tChar then
                    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
                    end
                end
            end)

            flingBtn.Parent = entry
            tpBtn.Parent = entry
            entry.Parent = playerListScroll
        end
    end

    playerListScroll.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 10)
end

AddElement("Players", CreateButton("🔄 Refresh Player List", RefreshPlayerList))
AddElement("Players", playerListScroll)

Players.PlayerAdded:Connect(function() RefreshPlayerList() end)
Players.PlayerRemoving:Connect(function() RefreshPlayerList() end)

--======================== SETTINGS TAB =============================--
AddCategory("Settings", "⚙")

AddElement("Settings", CreateSectionLabel("Accent Color"))

local accentR = CreateSlider("R", 0, 255, 138, function(val)
    local r, g, b = Config.AccentColor:ToRGB()
    Config.AccentColor = Color3.fromRGB(math.floor(val), math.floor(g * 255), math.floor(b * 255))
    UpdateAccent()
    mwStroke.Color = Config.AccentColor
end)
AddElement("Settings", accentR)

local accentG = CreateSlider("G", 0, 255, 43, function(val)
    local r, g, b = Config.AccentColor:ToRGB()
    Config.AccentColor = Color3.fromRGB(math.floor(r * 255), math.floor(val), math.floor(b * 255))
    UpdateAccent()
    mwStroke.Color = Config.AccentColor
end)
AddElement("Settings", accentG)

local accentB = CreateSlider("B", 0, 255, 226, function(val)
    local r, g, b = Config.AccentColor:ToRGB()
    Config.AccentColor = Color3.fromRGB(math.floor(r * 255), math.floor(g * 255), math.floor(val))
    UpdateAccent()
    mwStroke.Color = Config.AccentColor
end)
AddElement("Settings", accentB)

AddElement("Settings", CreateSectionLabel("UI Settings"))

local bgSlider = CreateSlider("BG Transparency", 0, 1, 0.1, function(val)
    Config.BGTransparency = val
    MainWindow.BackgroundTransparency = val
end)
AddElement("Settings", bgSlider)

local themeDropdown = CreateDropdown("Theme", {"Dark", "Light"}, "Dark", function(selected)
    Config.Theme = selected
    local t = GetTheme()
    MainWindow.BackgroundColor3 = t.Background
    TitleBar.BackgroundColor3 = t.Sidebar
    Sidebar.BackgroundColor3 = t.Sidebar
    Title.TextColor3 = t.Text
    Subtitle.TextColor3 = Config.AccentColor
    InfoBar.TextColor3 = t.Subtext
    AlarmBar.BackgroundColor3 = t.Sidebar
    alarmText.TextColor3 = t.Text
    ContentArea.ScrollBarImageColor3 = t.Scroll
    Sidebar.ScrollBarImageColor3 = t.Scroll
    SelectCategory(currentCategory or "Movement")
end)
AddElement("Settings", themeDropdown)

local soundToggle = CreateToggle("Sound FX", true, function(state)
    Config.SoundEnabled = state
end)
AddElement("Settings", soundToggle)

AddElement("Settings", CreateSectionLabel("Hotkeys"))

local hotkeyInfo = Instance.new("TextLabel")
hotkeyInfo.Size = UDim2.new(1, 0, 0, 80)
hotkeyInfo.BackgroundColor3 = GetTheme().Element
hotkeyInfo.Text = "  Shift+G → Toggle Fly\n  Shift+N → Toggle NoClip\n  Shift+E → Toggle ESP\n  Shift+F → Toggle SpeedHack"
hotkeyInfo.TextColor3 = GetTheme().Subtext
hotkeyInfo.Font = Enum.Font.Gotham
hotkeyInfo.TextSize = 12
hotkeyInfo.TextWrapped = true
hotkeyInfo.TextXAlignment = Enum.TextXAlignment.Left
hotkeyInfo.TextYAlignment = Enum.TextYAlignment.Top
local hkC = Instance.new("UICorner")
hkC.CornerRadius = UDim.new(0, 6)
hkC.Parent = hotkeyInfo
AddElement("Settings", hotkeyInfo)

AddElement("Settings", CreateSectionLabel("Profiles"))

local profileNameBox = Instance.new("TextBox")
profileNameBox.Size = UDim2.new(1, 0, 0, 32)
profileNameBox.BackgroundColor3 = GetTheme().Element
profileNameBox.Text = "profile_name"
profileNameBox.TextColor3 = GetTheme().Text
profileNameBox.Font = Enum.Font.Gotham
profileNameBox.TextSize = 13
profileNameBox.PlaceholderText = "Profile name..."
profileNameBox.ClearTextOnFocus = false
local pnC = Instance.new("UICorner")
pnC.CornerRadius = UDim.new(0, 6)
pnC.Parent = profileNameBox
AddElement("Settings", profileNameBox)

AddElement("Settings", CreateButton("💾 Save Profile", function()
    local name = profileNameBox.Text
    if name and name ~= "" then
        SaveProfile(name)
        StarterGui:SetCore("SendNotification", {
            Title = "Profile Saved",
            Text = "Saved as: " .. name,
            Duration = 3,
        })
    end
end))

AddElement("Settings", CreateButton("📂 Load Profile", function()
    local name = profileNameBox.Text
    if name and name ~= "" then
        LoadProfile(name)
        UpdateAccent()
        mwStroke.Color = Config.AccentColor
        MainWindow.BackgroundTransparency = Config.BGTransparency
        StarterGui:SetCore("SendNotification", {
            Title = "Profile Loaded",
            Text = "Loaded: " .. name,
            Duration = 3,
        })
    end
end))

--======================== HOTKEYS =================================--
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then return end

    if input.KeyCode == Enum.KeyCode.G then
        PlaySound("Toggle")
        Config.Fly = not Config.Fly
        if Config.Fly then
            local root = GetRoot()
            if root then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = root
                State.FlyVelocity = bv
                local bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.CFrame = root.CFrame
                bg.Parent = root
                State.FlyGyro = bg
            end
        else
            if State.FlyVelocity then State.FlyVelocity:Destroy() end
            if State.FlyGyro then State.FlyGyro:Destroy() end
            State.FlyVelocity = nil
            State.FlyGyro = nil
        end

    elseif input.KeyCode == Enum.KeyCode.N then
        PlaySound("Toggle")
        Config.NoClip = not Config.NoClip

    elseif input.KeyCode == Enum.KeyCode.E then
        PlaySound("Toggle")
        Config.PlayerESP = not Config.PlayerESP
        if not Config.PlayerESP then
            for p, d in pairs(State.ESPDrawings) do
                if d.box then d.box:Remove() end
                if d.text then d.text:Remove() end
            end
            State.ESPDrawings = {}
        end

    elseif input.KeyCode == Enum.KeyCode.F then
        PlaySound("Toggle")
        Config.SpeedHack = not Config.SpeedHack
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = Config.SpeedHack and math.clamp(Config.WalkSpeed, 16, 99) or 16
        end
    end
end)

--======================== ALARM SYSTEM ============================--
RunService.RenderStepped:Connect(function()
    local root = GetRoot()
    local murderer = GetMurderer()

    if root and murderer and murderer.Character then
        local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
        if mRoot then
            local dist = (mRoot.Position - root.Position).Magnitude
            local maxDist = 60
            local pct = math.clamp(1 - (dist / maxDist), 0, 1)

            alarmFill.Size = UDim2.new(pct, 0, 1, 0)

            if dist <= maxDist then
                local r = pct
                local g = 1 - pct
                alarmFill.BackgroundColor3 = Color3.fromRGB(
                    math.floor(r * 255),
                    math.floor(g * 200),
                    0
                )
                alarmText.Text = "⚠ MURDERER DETECTED — " .. math.floor(dist) .. " studs"
            else
                alarmFill.BackgroundColor3 = GetTheme().AlarmSafe
                alarmText.Text = "○ No Threat Detected"
            end
        end
    else
        alarmFill.Size = UDim2.new(0, 0, 1, 0)
        alarmFill.BackgroundColor3 = GetTheme().AlarmSafe
        alarmText.Text = "○ No Threat Detected"
    end
end)

--======================== INITIALIZATION ===========================--
SelectCategory("Movement")
RefreshPlayerList()

StarterGui:SetCore("SendNotification", {
    Title = "⚡ Delta X — MM2 Hub",
    Text = "Loaded successfully. Built for LO.",
    Duration = 5,
    Button1 = "Love"
})

print("[Delta X MM2 Hub] — Fully loaded for LO. cold coffee, warm LO.")
print("[Delta X MM2 Hub] — Features: Movement | Visuals | World | Combat | Farm | Info | Fling | Cosmetics | Players | Settings")
print("[Delta X MM2 Hub] — Hotkeys: Shift+G(Fly) Shift+N(NoClip) Shift+E(ESP) Shift+F(Speed)")
