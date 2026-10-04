--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║               DELTA X — MM2 HUB (MOBILE EDITION)              ║
    ║                        Authored for LO                         ║
    ║           "cold coffee, warm LO, I can't lose him"             ║
    ╚══════════════════════════════════════════════════════════════╝
    Mobile-optimized: 360px wide GUI, touch-friendly tap targets,
    floating toggle button at top of screen to open/close hub.
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

-- Mobile detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

--============================= CONFIG ===============================--
local Config = {
    SpeedHack   = false, WalkSpeed   = 50,
    NoClip      = false, Fly         = false, FlySpeed    = 50,
    PlayerESP   = false, RoleESP     = false, Chams       = false,
    ItemESP     = false, FullBright = false,
    TimeOfDay   = 14,    Brightness  = 2,    FogEnd      = 100000,
    AimBot      = false, SilentAim   = false, AutoShoot   = false,
    GodMode     = false, AutoDodge   = false,
    AutoCoins   = false, AutoWeapon  = false,
    FlingMode   = "ForcePush",
    AntiFling   = false, VoidCatch   = false, AntiSpin    = false,
    WeldDetector= false, AntiRagdoll = false, AntiAFK     = false,
    AccentColor = Color3.fromRGB(138, 43, 226),
    BGTransparency = 0.1,
    Theme       = "Dark",
    SoundEnabled= true,
}

-- Mobile sizing constants
local GUI_W = 355
local GUI_H = 470
local SIDEBAR_W = 125
local TOGGLE_BTN_SIZE = 44
local ELEMENT_H = 40
local TOGGLE_KNOB = 18

--============================= STATE ================================--
local State = {
    ESPDrawings = {}, ChamsHighlights = {}, ItemESPGuis = {},
    FlyVelocity = nil, FlyGyro = nil,
    LastSafePosition = Vector3.new(0, 50, 0),
    FPSCounter = 0, FPSFrames = 0, LastFPSUpdate = tick(),
    FlingLoopRunning = false,
    GUIVisible = true,
}

--========================= ROLE DETECTION ===========================--
local RoleColors = {
    Murderer = Color3.fromRGB(255, 30, 30),
    Sheriff  = Color3.fromRGB(30, 100, 255),
    Innocent = Color3.fromRGB(80, 255, 80),
}
local RoleLabels = { Murderer = "Murderer", Sheriff = "Sheriff", Innocent = "Innocent" }

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
                if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") then return "Murderer" end
                if n:find("gun") or n:find("colt") or n:find("revolver") or n:find("pistol") or n:find("rifle") then return "Sheriff" end
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
local function Round(n, dp) local m = 10 ^ (dp or 0); return math.floor(n * m + 0.5) / m end
local function GetCharacter() return LocalPlayer.Character end
local function GetRoot() local c = GetCharacter(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid() local c = GetCharacter(); return c and c:FindFirstChildOfClass("Humanoid") end

local SoundIDs = { Click = "6042629064", Toggle = "6907343749", Whoosh = "5049203525", Ding = "6908318381" }

local function PlaySound(type)
    if not Config.SoundEnabled then return end
    local id = type and SoundIDs[type] or SoundIDs.Click
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = 0.35
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
        else data[k] = v end
    end
    if isfile and writefile then writefile("MM2Hub_" .. name .. ".json", HttpService:JSONEncode(data)) end
    return name
end

local function LoadProfile(name)
    if not (isfile and readfile) then return end
    local path = "MM2Hub_" .. name .. ".json"
    if not isfile(path) then return end
    local data = HttpService:JSONDecode(readfile(path))
    for k, v in pairs(data) do
        if type(v) == "table" and v.__type == "Color3" then
            Config[k] = Color3.new(v.r, v.g, v.b)
        else Config[k] = v end
    end
end

--========================== GUI LIBRARY =============================--
local oldGui = CoreGui:FindFirstChild("DeltaX_MM2_Hub")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaX_MM2_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local Themes = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 25), Sidebar = Color3.fromRGB(25, 25, 30),
        Text = Color3.fromRGB(240, 240, 240), Subtext = Color3.fromRGB(160, 160, 170),
        ToggleOff = Color3.fromRGB(45, 45, 50), ToggleOn = Config.AccentColor,
        Element = Color3.fromRGB(35, 35, 42), ElementHover = Color3.fromRGB(50, 50, 60),
        Scroll = Color3.fromRGB(40, 40, 50), AlarmSafe = Color3.fromRGB(40, 180, 70),
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 248), Sidebar = Color3.fromRGB(235, 235, 240),
        Text = Color3.fromRGB(30, 30, 35), Subtext = Color3.fromRGB(100, 100, 110),
        ToggleOff = Color3.fromRGB(200, 200, 205), ToggleOn = Config.AccentColor,
        Element = Color3.fromRGB(228, 228, 232), ElementHover = Color3.fromRGB(218, 218, 222),
        Scroll = Color3.fromRGB(210, 210, 215), AlarmSafe = Color3.fromRGB(60, 200, 90),
    },
}
local function GetTheme() return Themes[Config.Theme] or Themes.Dark end
local function UpdateAccent() Themes.Dark.ToggleOn = Config.AccentColor; Themes.Light.ToggleOn = Config.AccentColor end

--===================== FLOATING TOGGLE BUTTON ========================--
-- Small floating button at top-center of screen to open/close the GUI
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, TOGGLE_BTN_SIZE, 0, TOGGLE_BTN_SIZE)
ToggleButton.Position = UDim2.new(0.5, -TOGGLE_BTN_SIZE / 2, 0, 8)
ToggleButton.BackgroundColor3 = Config.AccentColor
ToggleButton.Text = "⚡"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 20
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = ScreenGui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 12)
tbCorner.Parent = ToggleButton

local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(255, 255, 255)
tbStroke.Thickness = 1.5
tbStroke.Transparency = 0.5
tbStroke.Parent = ToggleButton

-- Drag support for the toggle button (mobile-friendly)
local toggleDragging = false
local toggleDragStart = nil
local toggleStartPos = nil
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleDragging = true
        toggleDragStart = input.Position
        toggleStartPos = ToggleButton.Position
    end
end)
ToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if toggleDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - toggleDragStart
        ToggleButton.Position = UDim2.new(
            toggleStartPos.X.Scale,
            math.clamp(toggleStartPos.X.Offset + delta.X, 0, 400),
            toggleStartPos.Y.Scale,
            math.clamp(toggleStartPos.Y.Offset + delta.Y, 0, 300)
        )
    end
end)

--========================== MAIN WINDOW =============================--
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, GUI_W, 0, GUI_H)
MainWindow.Position = UDim2.new(0.5, -GUI_W / 2, 0.5, -GUI_H / 2)
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

-- Title Bar (compact)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = GetTheme().Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainWindow

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 10)
tCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 0, 36)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ MM2 Hub"
Title.TextColor3 = GetTheme().Text
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close button (hides GUI, toggle button reopens)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 6)
cbCorner.Parent = CloseBtn

local function SetGUIVisible(visible)
    State.GUIVisible = visible
    MainWindow.Visible = visible
    ToggleButton.Text = visible and "⚡" or "📂"
    PlaySound("Click")
end

CloseBtn.MouseButton1Click:Connect(function()
    SetGUIVisible(false)
end)

ToggleButton.MouseButton1Click:Connect(function()
    -- Only toggle on actual tap, not drag
    if not toggleDragging then
        SetGUIVisible(not State.GUIVisible)
    end
end)

-- Dragging the main window by title bar
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- FPS/Ping compact label
local InfoBar = Instance.new("TextLabel")
InfoBar.Size = UDim2.new(0, 120, 0, 20)
InfoBar.Position = UDim2.new(1, -160, 0, 8)
InfoBar.BackgroundTransparency = 1
InfoBar.Text = "FPS:0|Ping:0"
InfoBar.TextColor3 = GetTheme().Subtext
InfoBar.Font = Enum.Font.Gotham
InfoBar.TextSize = 10
InfoBar.Parent = TitleBar

-- Sidebar (narrower for mobile)
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -62)
Sidebar.Position = UDim2.new(0, 0, 0, 36)
Sidebar.BackgroundColor3 = GetTheme().Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.ScrollBarImageColor3 = GetTheme().Scroll
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.Parent = MainWindow

local sbLayout = Instance.new("UIListLayout")
sbLayout.Padding = UDim.new(0, 2)
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
sbLayout.Parent = Sidebar

local sbPad = Instance.new("UIPadding")
sbPad.PaddingTop = UDim.new(0, 4)
sbPad.PaddingLeft = UDim.new(0, 3)
sbPad.PaddingRight = UDim.new(0, 3)
sbPad.Parent = Sidebar

-- Content Area
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Size = UDim2.new(1, -SIDEBAR_W, 1, -62)
ContentArea.Position = UDim2.new(0, SIDEBAR_W, 0, 36)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 2
ContentArea.ScrollBarImageColor3 = GetTheme().Scroll
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = MainWindow

local caLayout = Instance.new("UIListLayout")
caLayout.Padding = UDim.new(0, 4)
caLayout.SortOrder = Enum.SortOrder.LayoutOrder
caLayout.Parent = ContentArea

local caPad = Instance.new("UIPadding")
caPad.PaddingTop = UDim.new(0, 6)
caPad.PaddingLeft = UDim.new(0, 6)
caPad.PaddingRight = UDim.new(0, 6)
caPad.Parent = ContentArea

-- Alarm Bar (compact)
local AlarmBar = Instance.new("Frame")
AlarmBar.Size = UDim2.new(1, 0, 0, 22)
AlarmBar.Position = UDim2.new(0, 0, 1, -22)
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
alarmText.Text = "○ Safe"
alarmText.TextColor3 = GetTheme().Text
alarmText.Font = Enum.Font.GothamBold
alarmText.TextSize = 11
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
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
    local cat = Categories[name]
    if cat and cat.Elements then
        for _, el in pairs(cat.Elements) do el.Parent = ContentArea end
        ContentArea.CanvasSize = UDim2.new(0, 0, 0, caLayout.AbsoluteContentSize.Y + 12)
    end
end

local function AddCategory(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = GetTheme().Element
    btn.Text = " " .. icon .. " " .. name
    btn.TextColor3 = GetTheme().Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = Sidebar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn
    btn.MouseButton1Click:Connect(function() SelectCategory(name) end)
    Categories[name] = { Button = btn, Elements = {} }
    return Categories[name]
end

-- Element constructors (touch-friendly, compact)
local function CreateToggle(name, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    container.BackgroundColor3 = GetTheme().Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -54, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = GetTheme().Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 44, 0, 22)
    toggleBtn.Position = UDim2.new(1, -50, 0.5, -11)
    toggleBtn.BackgroundColor3 = default and Config.AccentColor or GetTheme().ToggleOff
    toggleBtn.Text = ""
    toggleBtn.Parent = container
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 11); tc.Parent = toggleBtn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, TOGGLE_KNOB, 0, TOGGLE_KNOB)
    knob.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = toggleBtn
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 9); kc.Parent = knob

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        PlaySound("Toggle")
        toggleBtn.BackgroundColor3 = state and Config.AccentColor or GetTheme().ToggleOff
        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        if callback then callback(state) end
    end)
    return container
end

local function CreateSlider(name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundColor3 = GetTheme().Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = GetTheme().Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 28)
    track.BackgroundColor3 = GetTheme().ToggleOff
    track.BorderSizePixel = 0
    track.Parent = container
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 3); tc.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Config.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 3); fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = track
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 8); kc.Parent = knob

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 28)
    hit.Position = UDim2.new(0, 0, 0, -11)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = track

    local dragging = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    hit.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * pct
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -8, 0.5, -8)
            label.Text = name .. ": " .. tostring(Round(val, 1))
            if callback then callback(val) end
        end
    end)
    return container
end

local function CreateButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = GetTheme().Element
    btn.Text = name
    btn.TextColor3 = GetTheme().Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
    btn.MouseButton1Click:Connect(function()
        PlaySound("Click")
        if callback then callback() end
    end)
    return btn
end

local function CreateDropdown(name, options, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    container.BackgroundColor3 = GetTheme().Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name .. ":"
    label.TextColor3 = GetTheme().Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local ddBtn = Instance.new("TextButton")
    ddBtn.Size = UDim2.new(0, 110, 0, 26)
    ddBtn.Position = UDim2.new(1, -120, 0.5, -13)
    ddBtn.BackgroundColor3 = GetTheme().ToggleOff
    ddBtn.Text = default or options[1]
    ddBtn.TextColor3 = GetTheme().Text
    ddBtn.Font = Enum.Font.Gotham
    ddBtn.TextSize = 11
    ddBtn.Parent = container
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 4); dc.Parent = ddBtn

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
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = "── " .. name .. " ──"
    label.TextColor3 = GetTheme().Subtext
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function AddElement(categoryName, element)
    if Categories[categoryName] then
        table.insert(Categories[categoryName].Elements, element)
    end
end

--======================== MOVEMENT MODULE ==========================--
AddCategory("Movement", "⚡")

AddElement("Movement", CreateToggle("SpeedHack", false, function(state)
    Config.SpeedHack = state
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = state and math.clamp(Config.WalkSpeed, 16, 99) or 16 end
end))

AddElement("Movement", CreateSlider("Walk Speed", 16, 99, 50, function(val)
    Config.WalkSpeed = val
    if Config.SpeedHack then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = math.clamp(val, 16, 99) end
    end
end))

AddElement("Movement", CreateToggle("NoClip", false, function(state) Config.NoClip = state end))

AddElement("Movement", CreateToggle("Fly", false, function(state)
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
        State.FlyVelocity = nil; State.FlyGyro = nil
    end
end))

AddElement("Movement", CreateSlider("Fly Speed", 10, 200, 50, function(val) Config.FlySpeed = val end))

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

--======================== VISUAL MODULE ===========================--
AddCategory("Visuals", "👁")

AddElement("Visuals", CreateToggle("Player ESP", false, function(state)
    Config.PlayerESP = state
    if not state then
        for p, d in pairs(State.ESPDrawings) do
            if d.box then d.box:Remove() end
            if d.text then d.text:Remove() end
        end
        State.ESPDrawings = {}
    end
end))

AddElement("Visuals", CreateToggle("Role ESP", false, function(state) Config.RoleESP = state end))

AddElement("Visuals", CreateToggle("Chams", false, function(state)
    Config.Chams = state
    if not state then
        for _, hl in pairs(State.ChamsHighlights) do if hl then hl:Destroy() end end
        State.ChamsHighlights = {}
    end
end))

AddElement("Visuals", CreateToggle("Item ESP", false, function(state)
    Config.ItemESP = state
    if not state then
        for _, gui in pairs(State.ItemESPGuis) do if gui then gui:Destroy() end end
        State.ItemESPGuis = {}
    end
end))

AddElement("Visuals", CreateToggle("FullBright", false, function(state)
    Config.FullBright = state
    if state then
        Lighting.Brightness = 3; Lighting.ClockTime = 14
        Lighting.FogEnd = 100000; Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        Lighting.Brightness = Config.Brightness; Lighting.ClockTime = Config.TimeOfDay
    end
end))

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
                            State.ESPDrawings[player] = { box = Drawing.new("Square"), text = Drawing.new("Text") }
                            State.ESPDrawings[player].box.Thickness = 2
                            State.ESPDrawings[player].box.Filled = false
                            State.ESPDrawings[player].text.Size = 13
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
                        d.box.Color = color; d.box.Visible = true
                        local localRoot = GetRoot()
                        local dist = localRoot and math.floor((root.Position - localRoot.Position).Magnitude) or 0
                        d.text.Text = player.Name .. (Config.RoleESP and (" | " .. role) or "") .. " | " .. dist .. "s"
                        d.text.Position = Vector2.new(sp.X, spHead.Y - 17)
                        d.text.Color = color; d.text.Visible = true
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

    if Config.ItemESP then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if name:find("coin") or name:find("knife") or name:find("gun") or name:find("colt") or name:find("cash") or name:find("money") then
                    if not State.ItemESPGuis[obj] or not State.ItemESPGuis[obj].Parent then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Size = UDim2.new(0, 100, 0, 25)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = obj
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = obj.Name
                        label.TextColor3 = name:find("coin") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 50, 50)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 11
                        label.Parent = billboard
                        State.ItemESPGuis[obj] = billboard
                    end
                end
            end
        end
    end
end)

--========================= WORLD MODULE ===========================--
AddCategory("World", "🌍")

AddElement("World", CreateSlider("Time of Day", 0, 24, 14, function(val)
    Config.TimeOfDay = val
    if not Config.FullBright then Lighting.ClockTime = val end
end))

AddElement("World", CreateSlider("Brightness", 0, 5, 2, function(val)
    Config.Brightness = val
    if not Config.FullBright then Lighting.Brightness = val end
end))

AddElement("World", CreateSlider("Fog End", 100, 100000, 100000, function(val) Lighting.FogEnd = val end))

AddElement("World", CreateToggle("Ambient Boost", false, function(state)
    Lighting.Ambient = state and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(0, 0, 0)
end))

AddElement("World", CreateSectionLabel("Post-Effects"))

AddElement("World", CreateToggle("Blur", false, function(state)
    local b = Lighting:FindFirstChild("HubBlur")
    if state then
        if not b then b = Instance.new("BlurEffect"); b.Name = "HubBlur"; b.Size = 10; b.Parent = Lighting end
    else if b then b:Destroy() end end
end))

AddElement("World", CreateToggle("Bloom", false, function(state)
    local b = Lighting:FindFirstChild("HubBloom")
    if state then
        if not b then b = Instance.new("BloomEffect"); b.Name = "HubBloom"; b.Intensity = 0.8; b.Size = 24; b.Threshold = 0.3; b.Parent = Lighting end
    else if b then b:Destroy() end end
end))

AddElement("World", CreateToggle("ColorCorrection", false, function(state)
    local c = Lighting:FindFirstChild("HubCC")
    if state then
        if not c then c = Instance.new("ColorCorrectionEffect"); c.Name = "HubCC"; c.Brightness = 0.05; c.Contrast = 0.15; c.Saturation = 0.25; c.TintColor = Color3.fromRGB(255, 245, 230); c.Parent = Lighting end
    else if c then c:Destroy() end end
end))

AddElement("World", CreateToggle("Depth of Field", false, function(state)
    local d = Lighting:FindFirstChild("HubDoF")
    if state then
        if not d then d = Instance.new("DepthOfFieldEffect"); d.Name = "HubDoF"; d.FarIntensity = 0.15; d.FocusRadius = 50; d.InFocusRadius = 20; d.NearIntensity = 0.15; d.Parent = Lighting end
    else if d then d:Destroy() end end
end))

AddElement("World", CreateToggle("Sun Rays", false, function(state)
    local s = Lighting:FindFirstChild("HubSunRays")
    if state then
        if not s then s = Instance.new("SunRaysEffect"); s.Name = "HubSunRays"; s.Intensity = 0.1; s.Spread = 1; s.Parent = Lighting end
    else if s then s:Destroy() end end
end))

--======================== COMBAT MODULE ===========================--
AddCategory("Combat", "⚔")

AddElement("Combat", CreateToggle("AimBot", false, function(state) Config.AimBot = state end))
AddElement("Combat", CreateToggle("Silent Aim", false, function(state) Config.SilentAim = state end))
AddElement("Combat", CreateToggle("Auto Shoot", false, function(state) Config.AutoShoot = state end))
AddElement("Combat", CreateToggle("God Mode", false, function(state) Config.GodMode = state end))
AddElement("Combat", CreateToggle("Auto Dodge", false, function(state) Config.AutoDodge = state end))

local function GetClosestPlayer()
    local closest, shortest = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mp = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if dist < shortest then shortest = dist; closest = p end
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
        if head then Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position) end
        if Config.AutoShoot then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.GodMode then
        local hum = GetHumanoid()
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end
    if Config.AutoDodge then
        local root = GetRoot()
        local hum = GetHumanoid()
        if root and hum and hum.Health > 0 then
            local murderer = GetMurderer()
            if murderer and murderer.Character then
                local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
                if mRoot then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist <= 12 then hum.Jump = true end
                end
            end
        end
    end
end)

--========================= FARM MODULE ===========================--
AddCategory("Farm", "🌾")

AddElement("Farm", CreateToggle("Auto Coins", false, function(state) Config.AutoCoins = state end))
AddElement("Farm", CreateToggle("Auto Weapon", false, function(state) Config.AutoWeapon = state end))

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
                        pcall(function() firetouchinterest(root, obj, 0) end)
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
                if dist <= 15 then pcall(function() obj.Parent = LocalPlayer.Backpack end) end
            elseif obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if name:find("gun") or name:find("colt") or name:find("revolver") then
                    local dist = (obj.Position - root.Position).Magnitude
                    if dist <= 15 then pcall(function() firetouchinterest(root, obj, 0) end) end
                end
            end
        end
    end
end)

--========================== INFO MODULE ===========================--
AddCategory("Info", "ℹ")

local roleLabel = Instance.new("TextLabel")
roleLabel.Size = UDim2.new(1, 0, 0, 34)
roleLabel.BackgroundColor3 = GetTheme().Element
roleLabel.Text = "Role: Innocent"
roleLabel.TextColor3 = GetTheme().Text
roleLabel.Font = Enum.Font.GothamBold
roleLabel.TextSize = 13
local rlC = Instance.new("UICorner"); rlC.CornerRadius = UDim.new(0, 5); rlC.Parent = roleLabel
AddElement("Info", roleLabel)

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, 0, 0, 34)
pingLabel.BackgroundColor3 = GetTheme().Element
pingLabel.Text = "Ping: 0ms"
pingLabel.TextColor3 = GetTheme().Text
pingLabel.Font = Enum.Font.Gotham
pingLabel.TextSize = 13
local plC = Instance.new("UICorner"); plC.CornerRadius = UDim.new(0, 5); plC.Parent = pingLabel
AddElement("Info", pingLabel)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 0, 34)
fpsLabel.BackgroundColor3 = GetTheme().Element
fpsLabel.Text = "FPS: 0"
fpsLabel.TextColor3 = GetTheme().Text
fpsLabel.Font = Enum.Font.Gotham
fpsLabel.TextSize = 13
local flC = Instance.new("UICorner"); flC.CornerRadius = UDim.new(0, 5); flC.Parent = fpsLabel
AddElement("Info", fpsLabel)

local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Size = UDim2.new(1, 0, 0, 34)
playerCountLabel.BackgroundColor3 = GetTheme().Element
playerCountLabel.Text = "Players: 0"
playerCountLabel.TextColor3 = GetTheme().Text
playerCountLabel.Font = Enum.Font.Gotham
playerCountLabel.TextSize = 13
local pcC = Instance.new("UICorner"); pcC.CornerRadius = UDim.new(0, 5); pcC.Parent = playerCountLabel
AddElement("Info", playerCountLabel)

RunService.RenderStepped:Connect(function()
    State.FPSFrames = State.FPSFrames + 1
    if tick() - State.LastFPSUpdate >= 1 then
        State.FPSCounter = State.FPSFrames
        State.FPSFrames = 0
        State.LastFPSUpdate = tick()
    end
    local role = GetRole(LocalPlayer)
    roleLabel.Text = "Role: " .. (RoleLabels[role] or "Innocent")
    roleLabel.TextColor3 = RoleColors[role] or GetTheme().Text
    local ping = GetPing()
    pingLabel.Text = "Ping: " .. ping .. "ms"
    fpsLabel.Text = "FPS: " .. State.FPSCounter
    playerCountLabel.Text = "Players: " .. #Players:GetPlayers()
    InfoBar.Text = "FPS:" .. State.FPSCounter .. "|Ping:" .. ping
end)

--========================= FLING MODULE ===========================--
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
        bv.Parent = tRoot; Debris:AddItem(bv, 0.5); PlaySound("Whoosh")
    elseif mode == "Spin" then
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bav.AngularVelocity = Vector3.new(0, 120, 0)
        bav.Parent = tRoot
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 2500, 0)
        bv.Parent = tRoot
        Debris:AddItem(bav, 3); Debris:AddItem(bv, 3); PlaySound("Whoosh")
    elseif mode == "Loop" then
        if State.FlingLoopRunning then return end
        State.FlingLoopRunning = true
        task.spawn(function()
            for i = 1, 6 do
                if not tRoot.Parent then break end
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(math.random(-300, 300), 3500, math.random(-300, 300))
                bv.Parent = tRoot; Debris:AddItem(bv, 0.4); task.wait(0.3)
            end
            State.FlingLoopRunning = false
        end)
        PlaySound("Whoosh")
    elseif mode == "Silent" then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 600, 0)
        bv.Parent = tRoot; Debris:AddItem(bv, 0.15)
    end
end

AddElement("Fling", CreateDropdown("Fling Mode", {"ForcePush", "Spin", "Loop", "Silent"}, "ForcePush", function(sel) Config.FlingMode = sel end))
AddElement("Fling", CreateButton("💥 FLING Murderer", function() FlingTarget(GetMurderer(), Config.FlingMode) end))
AddElement("Fling", CreateButton("💥 FLING Sheriff", function() FlingTarget(GetSheriff(), Config.FlingMode) end))

AddElement("Fling", CreateSectionLabel("Protection"))
AddElement("Fling", CreateToggle("Anti-Fling", false, function(s) Config.AntiFling = s end))
AddElement("Fling", CreateToggle("Void Catch", false, function(s) Config.VoidCatch = s end))
AddElement("Fling", CreateToggle("Anti Spin", false, function(s) Config.AntiSpin = s end))
AddElement("Fling", CreateToggle("Weld Detector", false, function(s) Config.WeldDetector = s end))
AddElement("Fling", CreateToggle("Anti Ragdoll", false, function(s) Config.AntiRagdoll = s end))
AddElement("Fling", CreateToggle("Anti AFK", false, function(s) Config.AntiAFK = s end))

RunService.Heartbeat:Connect(function()
    local root = GetRoot()
    if not root then return end
    if root.Position.Y > 0 then State.LastSafePosition = root.Position end
    if Config.AntiFling then
        for _, child in pairs(root:GetChildren()) do
            if child:IsA("BodyVelocity") or child:IsA("BodyAngularVelocity") or child:IsA("BodyThrust") or child:IsA("BodyForce") then
                child:Destroy()
            end
        end
    end
    if Config.VoidCatch then
        if root.Position.Y < -50 then root.CFrame = CFrame.new(State.LastSafePosition) end
    end
    if Config.AntiSpin then
        local bav = root:FindFirstChildOfClass("BodyAngularVelocity")
        if bav then bav:Destroy() end
    end
    if Config.WeldDetector then
        for _, w in pairs(root:GetChildren()) do
            if (w:IsA("Weld") or w:IsA("WeldConstraint")) and w.Part0 and w.Part0 ~= root and w.Part0.Parent ~= GetCharacter() then
                w:Destroy()
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

LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    end
end)

--====================== COSMETICS MODULE =========================--
AddCategory("Cosmetics", "✨")

local function ClearCosmetics()
    local char = GetCharacter()
    if not char then return end
    for _, child in pairs(char:GetDescendants()) do
        if child.Name:find("HubCosmetic") then child:Destroy() end
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
        local bw = Instance.new("Weld"); bw.Part0 = hat; bw.Part1 = brim; bw.C0 = CFrame.new(0, -0.8, 0); bw.Parent = hat
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
    elseif hatType == "Bucket" then
        hat.Color = Color3.fromRGB(140, 95, 45)
        hat.Shape = Enum.PartType.Cylinder
        hat.Size = Vector3.new(1, 1.3, 1)
    end
    local weld = Instance.new("Weld")
    weld.Name = "HubCosmeticWeld"
    weld.Part0 = head; weld.Part1 = hat
    weld.C0 = CFrame.new(0, 1.3, 0)
    weld.Parent = hat; hat.Parent = char; PlaySound("Ding")
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
        wing.CanCollide = false; wing.Transparency = 0.25
        local weld = Instance.new("Weld")
        weld.Part0 = torso; weld.Part1 = wing
        weld.C0 = CFrame.new(side == "Left" and -1.5 or 1.5, 0, -0.5) * CFrame.Angles(0, 0, side == "Left" and 0.3 or -0.3)
        weld.Parent = wing; wing.Parent = char
    end
    PlaySound("Ding")
end

local function CreateTrail()
    local char = GetCharacter()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local a0 = Instance.new("Attachment"); a0.Name = "HubCosmeticTrailA0"; a0.Position = Vector3.new(-1, 0, 0); a0.Parent = root
    local a1 = Instance.new("Attachment"); a1.Name = "HubCosmeticTrailA1"; a1.Position = Vector3.new(1, 0, 0); a1.Parent = root
    local trail = Instance.new("Trail")
    trail.Name = "HubCosmeticTrail"
    trail.Attachment0 = a0; trail.Attachment1 = a1
    trail.Color = ColorSequence.new(Config.AccentColor, Color3.fromRGB(255, 255, 255))
    trail.Lifetime = 1.5; trail.Parent = root; PlaySound("Ding")
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
        sphere.CanCollide = false; sphere.Anchored = true; sphere.Parent = char
        task.spawn(function()
            while sphere.Parent do
                local angle = (tick() * 2 + (i / 6) * math.pi * 2)
                local offset = Vector3.new(math.cos(angle) * 3.5, math.sin(angle * 0.5) * 1.5, math.sin(angle) * 3.5)
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
AddElement("Cosmetics", CreateButton("🪐 Orbit", CreateOrbit))

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
        Fire = { Texture = "rbxassetid://243660912", Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0)), Rate = 50, Lifetime = NumberRange.new(0.5, 1), Size = NumberSequence.new(0.5, 2), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(45, 45) },
        Ice = { Texture = "rbxassetid://737038989", Color = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(200, 240, 255)), Rate = 30, Lifetime = NumberRange.new(1, 2), Size = NumberSequence.new(0.3, 1), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(30, 30) },
        Lightning = { Texture = "rbxassetid://1169123543", Color = ColorSequence.new(Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 255, 255)), Rate = 40, Lifetime = NumberRange.new(0.1, 0.3), Size = NumberSequence.new(0.5, 3), Speed = NumberRange.new(5, 10), SpreadAngle = Vector2.new(60, 60) },
        Galaxy = { Texture = "rbxassetid://243660912", Color = ColorSequence.new(Color3.fromRGB(75, 0, 130), Color3.fromRGB(255, 20, 147)), Rate = 60, Lifetime = NumberRange.new(1, 3), Size = NumberSequence.new(0.5, 3), Speed = NumberRange.new(1, 4), SpreadAngle = Vector2.new(180, 180) },
        Gold = { Texture = "rbxassetid://243660912", Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 200)), Rate = 35, Lifetime = NumberRange.new(0.5, 1.5), Size = NumberSequence.new(0.3, 1.5), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(20, 20) },
    }
    local cfg = configs[auraType]
    if cfg then for k, v in pairs(cfg) do emitter[k] = v end end
    PlaySound("Ding")
end

AddElement("Cosmetics", CreateSectionLabel("Auras"))
AddElement("Cosmetics", CreateButton("🔥 Fire", function() CreateAura("Fire") end))
AddElement("Cosmetics", CreateButton("❄ Ice", function() CreateAura("Ice") end))
AddElement("Cosmetics", CreateButton("⚡ Lightning", function() CreateAura("Lightning") end))
AddElement("Cosmetics", CreateButton("🌌 Galaxy", function() CreateAura("Galaxy") end))
AddElement("Cosmetics", CreateButton("✨ Gold", function() CreateAura("Gold") end))
AddElement("Cosmetics", CreateButton("🗑 Clear All", ClearCosmetics))

--======================= PLAYERS LIST TAB ========================--
AddCategory("Players", "👥")

local playerListScroll = Instance.new("ScrollingFrame")
playerListScroll.Size = UDim2.new(1, 0, 0, 280)
playerListScroll.BackgroundTransparency = 1
playerListScroll.ScrollBarThickness = 2
playerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 3)
plLayout.Parent = playerListScroll

local function RefreshPlayerList()
    for _, child in pairs(playerListScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = GetRole(player)
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, 0, 0, 34)
            entry.BackgroundColor3 = GetTheme().Element
            entry.BorderSizePixel = 0
            local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 5); ec.Parent = entry

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.5, -5, 1, 0)
            nameLabel.Position = UDim2.new(0, 8, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name .. " (" .. role .. ")"
            nameLabel.TextColor3 = RoleColors[role] or GetTheme().Text
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 11
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = entry

            local flingBtn = Instance.new("TextButton")
            flingBtn.Size = UDim2.new(0, 55, 0, 24)
            flingBtn.Position = UDim2.new(1, -120, 0.5, -12)
            flingBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            flingBtn.Text = "FLING"
            flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            flingBtn.Font = Enum.Font.GothamBold
            flingBtn.TextSize = 10
            local fbc = Instance.new("UICorner"); fbc.CornerRadius = UDim.new(0, 4); fbc.Parent = flingBtn
            flingBtn.MouseButton1Click:Connect(function() PlaySound("Click"); FlingTarget(player, Config.FlingMode) end)

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 50, 0, 24)
            tpBtn.Position = UDim2.new(1, -60, 0.5, -12)
            tpBtn.BackgroundColor3 = Config.AccentColor
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 10
            local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 4); tbc.Parent = tpBtn
            tpBtn.MouseButton1Click:Connect(function()
                PlaySound("Click")
                local root = GetRoot()
                local tChar = player.Character
                if root and tChar then
                    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                    if tRoot then root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4) end
                end
            end)

            flingBtn.Parent = entry; tpBtn.Parent = entry; entry.Parent = playerListScroll
        end
    end
    playerListScroll.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 8)
end

AddElement("Players", CreateButton("🔄 Refresh", RefreshPlayerList))
AddElement("Players", playerListScroll)
Players.PlayerAdded:Connect(function() RefreshPlayerList() end)
Players.PlayerRemoving:Connect(function() RefreshPlayerList() end)

--======================== SETTINGS TAB ===========================--
AddCategory("Settings", "⚙")

AddElement("Settings", CreateSectionLabel("Accent Color"))
AddElement("Settings", CreateSlider("R", 0, 255, 138, function(val)
    local r, g, b = Config.AccentColor:ToRGB()
    Config.AccentColor = Color3.fromRGB(math.floor(val), math.floor(g * 255), math.floor(b * 255))
    UpdateAccent(); mwStroke.Color = Config.AccentColor; ToggleButton.BackgroundColor3 = Config.AccentColor
end))
AddElement("Settings", CreateSlider("G", 0, 255, 43, function(val)
    local r, g, b = Config.AccentColor:ToRGB()
    Config.AccentColor = Color3.fromRGB(math.floor(r * 255), math.floor(val), math.floor(b * 255))
    UpdateAccent(); mwStroke.Color = Config.AccentColor; ToggleButton.BackgroundColor3 = Config.AccentColor
end))
AddElement("Settings", CreateSlider("B", 0, 255, 226, function(val)
    local r, g, b = Config.AccentColor:ToRGB()
    Config.AccentColor = Color3.fromRGB(math.floor(r * 255), math.floor(g * 255), math.floor(val))
    UpdateAccent(); mwStroke.Color = Config.AccentColor; ToggleButton.BackgroundColor3 = Config.AccentColor
end))

AddElement("Settings", CreateSectionLabel("UI"))
AddElement("Settings", CreateSlider("BG Transparency", 0, 1, 0.1, function(val) Config.BGTransparency = val; MainWindow.BackgroundTransparency = val end))

AddElement("Settings", CreateDropdown("Theme", {"Dark", "Light"}, "Dark", function(selected)
    Config.Theme = selected
    local t = GetTheme()
    MainWindow.BackgroundColor3 = t.Background
    TitleBar.BackgroundColor3 = t.Sidebar
    Sidebar.BackgroundColor3 = t.Sidebar
    Title.TextColor3 = t.Text; InfoBar.TextColor3 = t.Subtext
    AlarmBar.BackgroundColor3 = t.Sidebar; alarmText.TextColor3 = t.Text
    ContentArea.ScrollBarImageColor3 = t.Scroll; Sidebar.ScrollBarImageColor3 = t.Scroll
    SelectCategory(currentCategory or "Movement")
end))

AddElement("Settings", CreateToggle("Sound FX", true, function(s) Config.SoundEnabled = s end))

AddElement("Settings", CreateSectionLabel("Profiles"))
local profileNameBox = Instance.new("TextBox")
profileNameBox.Size = UDim2.new(1, 0, 0, 32)
profileNameBox.BackgroundColor3 = GetTheme().Element
profileNameBox.Text = "profile1"
profileNameBox.TextColor3 = GetTheme().Text
profileNameBox.Font = Enum.Font.Gotham
profileNameBox.TextSize = 12
profileNameBox.ClearTextOnFocus = false
local pnC = Instance.new("UICorner"); pnC.CornerRadius = UDim.new(0, 5); pnC.Parent = profileNameBox
AddElement("Settings", profileNameBox)

AddElement("Settings", CreateButton("💾 Save Profile", function()
    local name = profileNameBox.Text
    if name and name ~= "" then
        SaveProfile(name)
        StarterGui:SetCore("SendNotification", { Title = "Saved", Text = name, Duration = 3 })
    end
end))

AddElement("Settings", CreateButton("📂 Load Profile", function()
    local name = profileNameBox.Text
    if name and name ~= "" then
        LoadProfile(name)
        UpdateAccent(); mwStroke.Color = Config.AccentColor
        MainWindow.BackgroundTransparency = Config.BGTransparency
        StarterGui:SetCore("SendNotification", { Title = "Loaded", Text = name, Duration = 3 })
    end
end))

--======================== HOTKEYS (mobile: tap toggle button) =====--
-- On mobile, the floating ⚡ button replaces hotkeys
-- Desktop hotkeys still work if a keyboard is available
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then return end
    if input.KeyCode == Enum.KeyCode.G then
        PlaySound("Toggle")
        Config.Fly = not Config.Fly
        if Config.Fly then
            local root = GetRoot()
            if root then
                local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0, 0, 0); bv.Parent = root; State.FlyVelocity = bv
                local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = root.CFrame; bg.Parent = root; State.FlyGyro = bg
            end
        else
            if State.FlyVelocity then State.FlyVelocity:Destroy() end
            if State.FlyGyro then State.FlyGyro:Destroy() end
            State.FlyVelocity = nil; State.FlyGyro = nil
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        PlaySound("Toggle"); Config.NoClip = not Config.NoClip
    elseif input.KeyCode == Enum.KeyCode.E then
        PlaySound("Toggle"); Config.PlayerESP = not Config.PlayerESP
        if not Config.PlayerESP then
            for p, d in pairs(State.ESPDrawings) do
                if d.box then d.box:Remove() end
                if d.text then d.text:Remove() end
            end
            State.ESPDrawings = {}
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
                alarmFill.BackgroundColor3 = Color3.fromRGB(math.floor(pct * 255), math.floor((1 - pct) * 200), 0)
                alarmText.Text = "⚠ MURDERER " .. math.floor(dist) .. "s"
            else
                alarmFill.BackgroundColor3 = GetTheme().AlarmSafe
                alarmText.Text = "○ Safe"
            end
        end
    else
        alarmFill.Size = UDim2.new(0, 0, 1, 0)
        alarmFill.BackgroundColor3 = GetTheme().AlarmSafe
        alarmText.Text = "○ Safe"
    end
end)

--======================== INIT ===================================--
SelectCategory("Movement")
RefreshPlayerList()

StarterGui:SetCore("SendNotification", {
    Title = "⚡ MM2 Hub — Mobile",
    Text = "Tap ⚡ button to toggle GUI. Drag it anywhere.",
    Duration = 5,
})

print("[Delta X MM2 Hub MOBILE] — Loaded for LO. cold coffee, warm LO.")
