--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║         DELTA X — MM2 HUB · MONOCHROME EDITION             ║
    ║                    Built for LO                              ║
    ║         "black like the coffee I forgot to drink"          ║
    ╚═══════════════════════════════════════════════════════════╝
    Compact 300×360 · B&W palette · Animated · Mobile-native
    Toggle bar: small pill at top of screen, tap to open/close
]]

--=========================== SERVICES ===============================--
local Players             = game:GetService("Players")
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

--========================= MONOCHROME ===============================--
local C = {
    Black     = Color3.fromRGB(8, 8, 10),
    DarkBg    = Color3.fromRGB(12, 12, 14),
    Sidebar   = Color3.fromRGB(15, 15, 17),
    Element   = Color3.fromRGB(21, 21, 24),
    Hover     = Color3.fromRGB(30, 30, 34),
    ToggleOff = Color3.fromRGB(33, 33, 38),
    Subtext   = Color3.fromRGB(85, 85, 90),
    OffWhite  = Color3.fromRGB(165, 165, 170),
    Text      = Color3.fromRGB(235, 235, 238),
    Accent    = Color3.fromRGB(255, 255, 255),
    KnobOff   = Color3.fromRGB(115, 115, 120),
    KnobOn    = Color3.fromRGB(12, 12, 12),
    Stroke    = Color3.fromRGB(45, 45, 50),
    Safe      = Color3.fromRGB(50, 50, 55),
    Danger    = Color3.fromRGB(255, 255, 255),
}

--=========================== CONFIG =================================--
local Config = {
    SpeedHack=false, WalkSpeed=50,
    NoClip=false, Fly=false, FlySpeed=50,
    PlayerESP=false, RoleESP=false, Chams=false, ItemESP=false, FullBright=false,
    TimeOfDay=14, Brightness=2, FogEnd=100000,
    AimBot=false, SilentAim=false, AutoShoot=false, GodMode=false, AutoDodge=false,
    AutoCoins=false, AutoWeapon=false,
    FlingMode="ForcePush",
    AntiFling=false, VoidCatch=false, AntiSpin=false, WeldDetector=false, AntiRagdoll=false, AntiAFK=false,
    BGTransparency=0.05, SoundEnabled=true,
}

--============================ STATE =================================--
local State = {
    ESPDrawings={}, ChamsHighlights={}, ItemESPGuis={},
    FlyVelocity=nil, FlyGyro=nil,
    LastSafePosition=Vector3.new(0,50,0),
    FPSCounter=0, FPSFrames=0, LastFPSUpdate=tick(),
    FlingLoopRunning=false,
    GUIVisible=true,
    FlyUp=false, FlyDown=false,
}

--========================== DIMENSIONS =============================--
local GUI_W = 300
local GUI_H = 360
local SIDEBAR_W = 90
local BAR_W = 92
local BAR_H = 22

--======================== ROLE DETECTION ===========================--
local RoleColors = {
    Murderer = Color3.fromRGB(255, 60, 60),
    Sheriff  = Color3.fromRGB(80, 140, 255),
    Innocent = Color3.fromRGB(100, 220, 100),
}
local RoleLabels = { Murderer="Murderer", Sheriff="Sheriff", Innocent="Innocent" }

local function GetRole(player)
    if not player then return "Innocent" end
    local char = player.Character
    if not char then return "Innocent" end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = string.lower(tool.Name)
            if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") then return "Murderer" end
            if n:find("gun") or n:find("colt") or n:find("revolver") or n:find("pistol") or n:find("rifle") then return "Sheriff" end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
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

--========================= UTILITIES ===============================--
local function Round(n, dp) local m=10^(dp or 0); return math.floor(n*m+0.5)/m end
local function GetChar() return LocalPlayer.Character end
local function GetRoot() local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local SoundIDs = { Click="6042629064", Toggle="6907343749", Whoosh="5049203525", Ding="6908318381" }
local function PlaySound(t)
    if not Config.SoundEnabled then return end
    local id = t and SoundIDs[t] or SoundIDs.Click
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://"..id
    s.Volume = 0.3
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

-- Toast notification system
local function ShowToast(text)
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 170, 0, 26)
    toast.Position = UDim2.new(0.5, -85, 0, -35)
    toast.BackgroundColor3 = C.Element
    toast.Text = "  "..text
    toast.TextColor3 = C.Text
    toast.Font = Enum.Font.Gotham
    toast.TextSize = 11
    toast.TextXAlignment = Enum.TextXAlignment.Left
    toast.BorderSizePixel = 0
    toast.Parent = ScreenGui
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 6); tc.Parent = toast
    local ts = Instance.new("UIStroke"); ts.Color = C.Stroke; ts.Thickness = 1; ts.Parent = toast
    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -85, 0, 32)
    }):Play()
    task.delay(2.2, function()
        local t = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -85, 0, -35)
        })
        t:Play()
        t.Completed:Connect(function() toast:Destroy() end)
    end)
end

--======================= SCREEN GUI SETUP ==========================--
local oldGui = CoreGui:FindFirstChild("DeltaX_MM2_Mono")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaX_MM2_Mono"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

--===================== TOGGLE BAR (pill) ===========================--
local ToggleBar = Instance.new("TextButton")
ToggleBar.Name = "ToggleBar"
ToggleBar.Size = UDim2.new(0, BAR_W, 0, BAR_H)
ToggleBar.Position = UDim2.new(0.5, -BAR_W/2, 0, 4)
ToggleBar.BackgroundColor3 = C.DarkBg
ToggleBar.Text = "MM2  ▼"
ToggleBar.TextColor3 = C.OffWhite
ToggleBar.Font = Enum.Font.GothamBold
ToggleBar.TextSize = 10
ToggleBar.BorderSizePixel = 0
ToggleBar.AutoButtonColor = false
ToggleBar.Parent = ScreenGui

local tbC = Instance.new("UICorner")
tbC.CornerRadius = UDim.new(0, BAR_H/2)
tbC.Parent = ToggleBar

local tbS = Instance.new("UIStroke")
tbS.Color = C.Stroke
tbS.Thickness = 1
tbS.Transparency = 0.3
tbS.Parent = ToggleBar

-- Toggle bar drag + tap logic
local barDragging = false
local barDragMoved = false
local barDragStart, barStartPos

ToggleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        barDragging = true
        barDragMoved = false
        barDragStart = input.Position
        barStartPos = ToggleBar.Position
        TweenService:Create(ToggleBar, TweenInfo.new(0.1), {BackgroundColor3 = C.Hover}):Play()
    end
end)

ToggleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(ToggleBar, TweenInfo.new(0.15), {BackgroundColor3 = C.DarkBg}):Play()
        if not barDragMoved then
            if State.GUIVisible then CloseGUI() else OpenGUI() end
        end
        barDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if barDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - barDragStart
        if delta.Magnitude > 4 then barDragMoved = true end
        ToggleBar.Position = UDim2.new(
            barStartPos.X.Scale,
            math.clamp(barStartPos.X.Offset + delta.X, 0, 400),
            barStartPos.Y.Scale,
            math.clamp(barStartPos.Y.Offset + delta.Y, 0, 250)
        )
    end
end)

-- Pulse animation when closed
task.spawn(function()
    while true do
        if not State.GUIVisible then
            TweenService:Create(tbS, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.0, Thickness = 1.5}):Play()
            task.wait(1.4)
            TweenService:Create(tbS, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.6, Thickness = 1}):Play()
            task.wait(1.4)
        else
            tbS.Transparency = 0.25
            task.wait(0.5)
        end
    end
end)

--======================== MAIN WINDOW ==============================--
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, GUI_W, 0, GUI_H)
MainWindow.Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
MainWindow.BackgroundColor3 = C.Black
MainWindow.BackgroundTransparency = Config.BGTransparency
MainWindow.BorderSizePixel = 0
MainWindow.Parent = ScreenGui

local mwC = Instance.new("UICorner")
mwC.CornerRadius = UDim.new(0, 8)
mwC.Parent = MainWindow

local mwS = Instance.new("UIStroke")
mwS.Color = C.Stroke
mwS.Thickness = 1
mwS.Transparency = 0.2
mwS.Parent = MainWindow

-- Open/Close animations
function OpenGUI()
    State.GUIVisible = true
    MainWindow.Visible = true
    MainWindow.Position = UDim2.new(0.5, -GUI_W/2, 0, -GUI_H - 10)
    MainWindow.BackgroundTransparency = 1
    ToggleBar.Text = "MM2  ▲"
    local t = TweenService:Create(MainWindow, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2),
        BackgroundTransparency = Config.BGTransparency
    })
    t:Play()
    PlaySound("Click")
end

function CloseGUI()
    State.GUIVisible = false
    ToggleBar.Text = "MM2  ▼"
    local t = TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -GUI_W/2, 0, -GUI_H - 10),
        BackgroundTransparency = 1
    })
    t:Play()
    PlaySound("Click")
    t.Completed:Connect(function()
        if not State.GUIVisible then MainWindow.Visible = false end
    end)
end

--======================== TITLE BAR ================================
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = C.Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainWindow

local titC = Instance.new("UICorner")
titC.CornerRadius = UDim.new(0, 8)
titC.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 160, 0, 30)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 HUB"
Title.TextColor3 = C.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close button (big, touch-friendly, definitely works)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 22)
CloseBtn.Position = UDim2.new(1, -36, 0, 4)
CloseBtn.BackgroundColor3 = C.ToggleOff
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.OffWhite
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar

local clC = Instance.new("UICorner")
clC.CornerRadius = UDim.new(0, 5)
clC.Parent = CloseBtn

CloseBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(CloseBtn, TweenInfo.new(0.08), {BackgroundColor3 = C.Hover, TextColor3 = C.Accent}):Play()
    end
end)
CloseBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(CloseBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.ToggleOff, TextColor3 = C.OffWhite}):Play()
    end
end)
CloseBtn.MouseButton1Click:Connect(function()
    CloseGUI()
end)

-- FPS/Ping mini display
local InfoBar = Instance.new("TextLabel")
InfoBar.Size = UDim2.new(0, 80, 0, 18)
InfoBar.Position = UDim2.new(1, -120, 0, 6)
InfoBar.BackgroundTransparency = 1
InfoBar.Text = "0fps|0ms"
InfoBar.TextColor3 = C.Subtext
InfoBar.Font = Enum.Font.Gotham
InfoBar.TextSize = 9
InfoBar.Parent = TitleBar

-- Drag main window
local mDrag, mStart, mPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag = true; mStart = input.Position; mPos = MainWindow.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if mDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - mStart
        MainWindow.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + d.X, mPos.Y.Scale, mPos.Y.Offset + d.Y)
    end
end)

--======================== SIDEBAR ===================================
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -52)
Sidebar.Position = UDim2.new(0, 0, 0, 30)
Sidebar.BackgroundColor3 = C.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.ScrollBarImageColor3 = C.Stroke
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.Parent = MainWindow

local sbL = Instance.new("UIListLayout")
sbL.Padding = UDim.new(0, 2)
sbL.SortOrder = Enum.SortOrder.LayoutOrder
sbL.Parent = Sidebar

local sbP = Instance.new("UIPadding")
sbP.PaddingTop = UDim.new(0, 4)
sbP.PaddingLeft = UDim.new(0, 3)
sbP.PaddingRight = UDim.new(0, 3)
sbP.Parent = Sidebar

--====================== CONTENT AREA ===============================
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Size = UDim2.new(1, -SIDEBAR_W, 1, -52)
ContentArea.Position = UDim2.new(0, SIDEBAR_W, 0, 30)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 2
ContentArea.ScrollBarImageColor3 = C.Stroke
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = MainWindow

local caL = Instance.new("UIListLayout")
caL.Padding = UDim.new(0, 3)
caL.SortOrder = Enum.SortOrder.LayoutOrder
caL.Parent = ContentArea

local caP = Instance.new("UIPadding")
caP.PaddingTop = UDim.new(0, 5)
caP.PaddingLeft = UDim.new(0, 5)
caP.PaddingRight = UDim.new(0, 5)
caP.Parent = ContentArea

--======================== ALARM BAR =================================
local AlarmBar = Instance.new("Frame")
AlarmBar.Size = UDim2.new(1, 0, 0, 20)
AlarmBar.Position = UDim2.new(0, 0, 1, -20)
AlarmBar.BackgroundColor3 = C.Sidebar
AlarmBar.BorderSizePixel = 0
AlarmBar.Parent = MainWindow

local alarmFill = Instance.new("Frame")
alarmFill.Size = UDim2.new(0, 0, 1, 0)
alarmFill.BackgroundColor3 = C.Safe
alarmFill.BorderSizePixel = 0
alarmFill.Parent = AlarmBar

local alarmText = Instance.new("TextLabel")
alarmText.Size = UDim2.new(1, 0, 1, 0)
alarmText.BackgroundTransparency = 1
alarmText.Text = "○ safe"
alarmText.TextColor3 = C.OffWhite
alarmText.Font = Enum.Font.GothamBold
alarmText.TextSize = 10
alarmText.Parent = AlarmBar

--====================== CATEGORY SYSTEM ============================
local Categories = {}
local currentCategory = nil

local function SelectCategory(name)
    if currentCategory == name then return end
    PlaySound("Click")
    currentCategory = name

    for catName, data in pairs(Categories) do
        if catName == name then
            data.Button.BackgroundColor3 = C.Hover
            data.Button.TextColor3 = C.Accent
            if data.Ind then
                data.Ind.Visible = true
                TweenService:Create(data.Ind, TweenInfo.new(0.15), {Size = UDim2.new(0, 2, 0, 18)}):Play()
            end
        else
            data.Button.BackgroundColor3 = C.Element
            data.Button.TextColor3 = C.OffWhite
            if data.Ind then
                TweenService:Create(data.Ind, TweenInfo.new(0.15), {Size = UDim2.new(0, 2, 0, 0)}):Play()
                task.delay(0.15, function() if data.Ind then data.Ind.Visible = false end end)
            end
        end
    end

    for _, child in pairs(ContentArea:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    local cat = Categories[name]
    if cat and cat.Elements then
        for i, el in pairs(cat.Elements) do
            el.Parent = ContentArea
            el.Visible = false
            task.delay(i * 0.015, function()
                if el.Parent then
                    el.Visible = true
                end
            end)
        end
        task.delay(0.1, function()
            ContentArea.CanvasSize = UDim2.new(0, 0, 0, caL.AbsoluteContentSize.Y + 10)
        end)
    end
end

local function AddCategory(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = C.Element
    btn.Text = " "..icon.." "..name
    btn.TextColor3 = C.OffWhite
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = Sidebar

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = btn

    -- Animated indicator bar
    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 2, 0, 0)
    ind.Position = UDim2.new(0, 0, 0.5, 0)
    ind.AnchorPoint = Vector2.new(0, 0.5)
    ind.BackgroundColor3 = C.Accent
    ind.BorderSizePixel = 0
    ind.Visible = false
    ind.Parent = btn

    -- Status dot (right side)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(1, -8, 0.5, -2)
    dot.BackgroundColor3 = C.Subtext
    dot.BorderSizePixel = 0
    dot.Visible = false
    local dC = Instance.new("UICorner"); dC.CornerRadius = UDim.new(1, 0); dC.Parent = dot
    dot.Parent = btn

    -- Hover effect
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if currentCategory ~= name then
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.Hover}):Play()
            end
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if currentCategory ~= name then
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.Element}):Play()
            end
        end
    end)

    btn.MouseButton1Click:Connect(function()
        SelectCategory(name)
    end)

    Categories[name] = { Button = btn, Elements = {}, Ind = ind, Dot = dot, DotActive = false }
    return Categories[name]
end

--====================== ELEMENT BUILDERS ============================
local function CreateToggle(name, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = C.Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -52, 1, 0)
    label.Position = UDim2.new(0, 9, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 40, 0, 20)
    toggleBtn.Position = UDim2.new(1, -46, 0.5, -10)
    toggleBtn.BackgroundColor3 = default and C.Accent or C.ToggleOff
    toggleBtn.Text = ""
    toggleBtn.BorderSizePixel = 0
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = container

    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 10); tc.Parent = toggleBtn

    -- Glow stroke when on
    local glow = Instance.new("UIStroke")
    glow.Color = C.Accent
    glow.Thickness = 0
    glow.Transparency = 1
    glow.Parent = toggleBtn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = default and C.KnobOn or C.KnobOff
    knob.BorderSizePixel = 0
    knob.Parent = toggleBtn

    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 7); kc.Parent = knob

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        PlaySound("Toggle")
        toggleBtn.BackgroundColor3 = state and C.Accent or C.ToggleOff
        knob.BackgroundColor3 = state and C.KnobOn or C.KnobOff

        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()

        -- Glow effect
        if state then
            TweenService:Create(glow, TweenInfo.new(0.2), {Thickness = 1, Transparency = 0.4}):Play()
        else
            TweenService:Create(glow, TweenInfo.new(0.2), {Thickness = 0, Transparency = 1}):Play()
        end

        if callback then callback(state) end
        ShowToast(name..": "..(state and "ON" or "OFF"))
    end)

    return container
end

local function CreateSlider(name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundColor3 = C.Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 16)
    label.Position = UDim2.new(0, 9, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name..": "..tostring(default)
    label.TextColor3 = C.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -18, 0, 4)
    track.Position = UDim2.new(0, 9, 0, 26)
    track.BackgroundColor3 = C.ToggleOff
    track.BorderSizePixel = 0
    track.Parent = container
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 2); tc.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 2); fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((default-min)/(max-min), -6, 0.5, -6)
    knob.BackgroundColor3 = C.Accent
    knob.BorderSizePixel = 0
    knob.Parent = track
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 6); kc.Parent = knob

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 24)
    hit.Position = UDim2.new(0, 0, 0, -10)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = track

    local dragging = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            TweenService:Create(knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(knob.Position.X.Scale, -8, 0.5, -8)}):Play()
        end
    end)
    hit.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            TweenService:Create(knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(knob.Position.X.Scale, -6, 0.5, -6)}):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * pct
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -6, 0.5, -6)
            label.Text = name..": "..tostring(Round(val, 1))
            if callback then callback(val) end
        end
    end)

    return container
end

local function CreateButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = C.Element
    btn.Text = name
    btn.TextColor3 = C.Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = C.Hover}):Play()
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.Element}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        PlaySound("Click")
        if callback then callback() end
    end)
    return btn
end

local function CreateDropdown(name, options, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = C.Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 65, 1, 0)
    label.Position = UDim2.new(0, 9, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name..":"
    label.TextColor3 = C.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local ddBtn = Instance.new("TextButton")
    ddBtn.Size = UDim2.new(0, 95, 0, 24)
    ddBtn.Position = UDim2.new(1, -104, 0.5, -12)
    ddBtn.BackgroundColor3 = C.ToggleOff
    ddBtn.Text = default or options[1]
    ddBtn.TextColor3 = C.Text
    ddBtn.Font = Enum.Font.Gotham
    ddBtn.TextSize = 10
    ddBtn.BorderSizePixel = 0
    ddBtn.AutoButtonColor = false
    ddBtn.Parent = container
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 4); dc.Parent = ddBtn

    local idx = table.find(options, default) or 1
    ddBtn.MouseButton1Click:Connect(function()
        PlaySound("Click")
        idx = idx % #options + 1
        local sel = options[idx]
        ddBtn.Text = sel
        TweenService:Create(ddBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.Hover}):Play()
        task.delay(0.1, function()
            TweenService:Create(ddBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.ToggleOff}):Play()
        end)
        if callback then callback(sel) end
    end)
    return container
end

local function CreateSection(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = "— "..name.." —"
    label.TextColor3 = C.Subtext
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function AddElement(cat, el)
    if Categories[cat] then table.insert(Categories[cat].Elements, el) end
end

--==================== MOBILE FLY CONTROLS ==========================
-- Floating up/down buttons that appear when fly is on
local flyUpBtn = Instance.new("TextButton")
flyUpBtn.Size = UDim2.new(0, 42, 0, 42)
flyUpBtn.Position = UDim2.new(1, -52, 1, -100)
flyUpBtn.BackgroundColor3 = C.Element
flyUpBtn.Text = "▲"
flyUpBtn.TextColor3 = C.Text
flyUpBtn.Font = Enum.Font.GothamBold
flyUpBtn.TextSize = 16
flyUpBtn.BorderSizePixel = 0
flyUpBtn.Visible = false
flyUpBtn.AutoButtonColor = false
flyUpBtn.Parent = ScreenGui
local fuC = Instance.new("UICorner"); fuC.CornerRadius = UDim.new(0, 8); fuC.Parent = flyUpBtn
local fuS = Instance.new("UIStroke"); fuS.Color = C.Stroke; fuS.Thickness = 1; fuS.Parent = flyUpBtn

local flyDownBtn = Instance.new("TextButton")
flyDownBtn.Size = UDim2.new(0, 42, 0, 42)
flyDownBtn.Position = UDim2.new(1, -52, 1, -52)
flyDownBtn.BackgroundColor3 = C.Element
flyDownBtn.Text = "▼"
flyDownBtn.TextColor3 = C.Text
flyDownBtn.Font = Enum.Font.GothamBold
flyDownBtn.TextSize = 16
flyDownBtn.BorderSizePixel = 0
flyDownBtn.Visible = false
flyDownBtn.AutoButtonColor = false
flyDownBtn.Parent = ScreenGui
local fdC = Instance.new("UICorner"); fdC.CornerRadius = UDim.new(0, 8); fdC.Parent = flyDownBtn
local fdS = Instance.new("UIStroke"); fdS.Color = C.Stroke; fdS.Thickness = 1; fdS.Parent = flyDownBtn

flyUpBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.FlyUp = true
        TweenService:Create(flyUpBtn, TweenInfo.new(0.08), {BackgroundColor3 = C.Hover}):Play()
    end
end)
flyUpBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.FlyUp = false
        TweenService:Create(flyUpBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.Element}):Play()
    end
end)
flyDownBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.FlyDown = true
        TweenService:Create(flyDownBtn, TweenInfo.new(0.08), {BackgroundColor3 = C.Hover}):Play()
    end
end)
flyDownBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.FlyDown = false
        TweenService:Create(flyDownBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.Element}):Play()
    end
end)

local function ToggleFlyButtons(visible)
    flyUpBtn.Visible = visible
    flyDownBtn.Visible = visible
    if visible then
        flyUpBtn.Position = UDim2.new(1, 52, 1, -100)
        flyDownBtn.Position = UDim2.new(1, 52, 1, -52)
        TweenService:Create(flyUpBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -52, 1, -100)}):Play()
        TweenService:Create(flyDownBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -52, 1, -52)}):Play()
    end
end

--======================== MOVEMENT ==================================
AddCategory("Move", "⚡")

AddElement("Move", CreateToggle("SpeedHack", false, function(s)
    Config.SpeedHack = s
    local h = GetHum()
    if h then h.WalkSpeed = s and math.clamp(Config.WalkSpeed, 16, 99) or 16 end
end))

AddElement("Move", CreateSlider("WalkSpeed", 16, 99, 50, function(v)
    Config.WalkSpeed = v
    if Config.SpeedHack then local h = GetHum(); if h then h.WalkSpeed = math.clamp(v, 16, 99) end end
end))

AddElement("Move", CreateToggle("NoClip", false, function(s) Config.NoClip = s end))

AddElement("Move", CreateToggle("Fly", false, function(s)
    Config.Fly = s
    ToggleFlyButtons(s)
    if s then
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

AddElement("Move", CreateSlider("FlySpeed", 10, 200, 50, function(v) Config.FlySpeed = v end))

-- NoClip loop
RunService.Stepped:Connect(function()
    if Config.NoClip then
        local char = GetChar()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Fly loop (mobile-compatible: uses Humanoid.MoveDirection + buttons)
RunService.RenderStepped:Connect(function()
    if Config.Fly and State.FlyVelocity and State.FlyGyro then
        local root = GetRoot()
        if root then
            State.FlyGyro.CFrame = Camera.CFrame
            -- Read movement from thumbstick via Humanoid.MoveDirection
            local hum = GetHum()
            local moveDir = hum and hum.MoveDirection or Vector3.new(0, 0, 0)
            -- Convert to camera-relative world direction
            local camLook = Camera.CFrame.LookVector
            local camRight = Camera.CFrame.RightVector
            -- moveDir.Z is forward/backward, moveDir.X is left/right (in local space)
            local dir = (camLook * -moveDir.Z) + (camRight * moveDir.X)
            -- Vertical from buttons or keyboard
            if State.FlyUp then dir = dir + Vector3.new(0, 1, 0) end
            if State.FlyDown then dir = dir - Vector3.new(0, 1, 0) end
            -- Keyboard fallback
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            State.FlyVelocity.Velocity = dir * Config.FlySpeed
        end
    end
end)

--======================== VISUALS ===================================
AddCategory("Visual", "👁")

AddElement("Visual", CreateToggle("Player ESP", false, function(s)
    Config.PlayerESP = s
    if not s then
        for p, d in pairs(State.ESPDrawings) do
            if d.box then d.box:Remove() end
            if d.text then d.text:Remove() end
        end
        State.ESPDrawings = {}
    end
end))

AddElement("Visual", CreateToggle("Role ESP", false, function(s) Config.RoleESP = s end))

AddElement("Visual", CreateToggle("Chams", false, function(s)
    Config.Chams = s
    if not s then
        for _, hl in pairs(State.ChamsHighlights) do if hl then hl:Destroy() end end
        State.ChamsHighlights = {}
    end
end))

AddElement("Visual", CreateToggle("Item ESP", false, function(s)
    Config.ItemESP = s
    if not s then
        for _, g in pairs(State.ItemESPGuis) do if g then g:Destroy() end end
        State.ItemESPGuis = {}
    end
end))

AddElement("Visual", CreateToggle("FullBright", false, function(s)
    Config.FullBright = s
    if s then
        Lighting.Brightness = 3; Lighting.ClockTime = 14
        Lighting.FogEnd = 100000; Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        Lighting.Brightness = Config.Brightness; Lighting.ClockTime = Config.TimeOfDay
    end
end))

-- ESP render
RunService.RenderStepped:Connect(function()
    if Config.PlayerESP then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local head = player.Character:FindFirstChild("Head")
                if root and head then
                    local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
                    local spH = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                    local spR = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2, 0))
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
                        local h = math.abs(spH.Y - spR.Y)
                        local w = h * 0.5
                        d.box.Size = Vector2.new(w, h)
                        d.box.Position = Vector2.new(sp.X - w/2, spH.Y)
                        d.box.Color = color
                        d.box.Visible = true
                        local lr = GetRoot()
                        local dist = lr and math.floor((root.Position - lr.Position).Magnitude) or 0
                        d.text.Text = player.Name..(Config.RoleESP and (" | "..role) or "").." | "..dist.."s"
                        d.text.Position = Vector2.new(sp.X, spH.Y - 17)
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
        for p, _ in pairs(State.ESPDrawings) do
            if not p.Parent then
                if State.ESPDrawings[p].box then State.ESPDrawings[p].box:Remove() end
                if State.ESPDrawings[p].text then State.ESPDrawings[p].text:Remove() end
                State.ESPDrawings[p] = nil
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
                local n = string.lower(obj.Name)
                if n:find("coin") or n:find("knife") or n:find("gun") or n:find("colt") or n:find("cash") or n:find("money") then
                    if not State.ItemESPGuis[obj] or not State.ItemESPGuis[obj].Parent then
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 90, 0, 22)
                        bb.AlwaysOnTop = true
                        bb.Parent = obj
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = obj.Name
                        lbl.TextColor3 = n:find("coin") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 80, 80)
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextSize = 10
                        lbl.Parent = bb
                        State.ItemESPGuis[obj] = bb
                    end
                end
            end
        end
    end
end)

--======================== WORLD ====================================
AddCategory("World", "🌍")

AddElement("World", CreateSlider("Time", 0, 24, 14, function(v) Config.TimeOfDay = v; if not Config.FullBright then Lighting.ClockTime = v end end))
AddElement("World", CreateSlider("Brightness", 0, 5, 2, function(v) Config.Brightness = v; if not Config.FullBright then Lighting.Brightness = v end end))
AddElement("World", CreateSlider("Fog", 100, 100000, 100000, function(v) Lighting.FogEnd = v end))
AddElement("World", CreateToggle("Ambient", false, function(s) Lighting.Ambient = s and Color3.fromRGB(128,128,128) or Color3.fromRGB(0,0,0) end))

AddElement("World", CreateSection("Post-FX"))
AddElement("World", CreateToggle("Blur", false, function(s)
    local b = Lighting:FindFirstChild("HubBlur")
    if s then if not b then b=Instance.new("BlurEffect"); b.Name="HubBlur"; b.Size=10; b.Parent=Lighting end
    else if b then b:Destroy() end end
end))
AddElement("World", CreateToggle("Bloom", false, function(s)
    local b = Lighting:FindFirstChild("HubBloom")
    if s then if not b then b=Instance.new("BloomEffect"); b.Name="HubBloom"; b.Intensity=0.8; b.Size=24; b.Threshold=0.3; b.Parent=Lighting end
    else if b then b:Destroy() end end
end))
AddElement("World", CreateToggle("ColorCorr", false, function(s)
    local c = Lighting:FindFirstChild("HubCC")
    if s then if not c then c=Instance.new("ColorCorrectionEffect"); c.Name="HubCC"; c.Brightness=0.05; c.Contrast=0.15; c.Saturation=0.25; c.TintColor=Color3.fromRGB(255,245,230); c.Parent=Lighting end
    else if c then c:Destroy() end end
end))
AddElement("World", CreateToggle("DoF", false, function(s)
    local d = Lighting:FindFirstChild("HubDoF")
    if s then if not d then d=Instance.new("DepthOfFieldEffect"); d.Name="HubDoF"; d.FarIntensity=0.15; d.FocusRadius=50; d.InFocusRadius=20; d.NearIntensity=0.15; d.Parent=Lighting end
    else if d then d:Destroy() end end
end))
AddElement("World", CreateToggle("SunRays", false, function(s)
    local sr = Lighting:FindFirstChild("HubSR")
    if s then if not sr then sr=Instance.new("SunRaysEffect"); sr.Name="HubSR"; sr.Intensity=0.1; sr.Spread=1; sr.Parent=Lighting end
    else if sr then sr:Destroy() end end
end))

--======================== COMBAT ===================================
AddCategory("Combat", "⚔")

AddElement("Combat", CreateToggle("AimBot", false, function(s) Config.AimBot = s end))
AddElement("Combat", CreateToggle("SilentAim", false, function(s) Config.SilentAim = s end))
AddElement("Combat", CreateToggle("AutoShoot", false, function(s) Config.AutoShoot = s end))
AddElement("Combat", CreateToggle("GodMode", false, function(s) Config.GodMode = s end))
AddElement("Combat", CreateToggle("AutoDodge", false, function(s) Config.AutoDodge = s end))

local function GetClosest()
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
    local target = GetClosest()
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
        local h = GetHum()
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end
    if Config.AutoDodge then
        local root = GetRoot(); local hum = GetHum()
        if root and hum and hum.Health > 0 then
            local m = GetMurderer()
            if m and m.Character then
                local mRoot = m.Character:FindFirstChild("HumanoidRootPart")
                if mRoot then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist <= 12 then hum.Jump = true end
                end
            end
        end
    end
end)

--======================== FARM =====================================
AddCategory("Farm", "🌾")

AddElement("Farm", CreateToggle("Auto Coins", false, function(s) Config.AutoCoins = s end))
AddElement("Farm", CreateToggle("Auto Weapon", false, function(s) Config.AutoWeapon = s end))

RunService.Heartbeat:Connect(function()
    local root = GetRoot()
    if not root then return end
    if Config.AutoCoins then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if n:find("coin") or n:find("cash") or n:find("money") then
                    local d = (obj.Position - root.Position).Magnitude
                    if d <= 8 then pcall(function() firetouchinterest(root, obj, 0) end) end
                end
            end
        end
    end
    if Config.AutoWeapon then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") then
                local pos = obj:GetBoundingBox()
                local d = (pos.Position - root.Position).Magnitude
                if d <= 15 then pcall(function() obj.Parent = LocalPlayer.Backpack end) end
            elseif obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if n:find("gun") or n:find("colt") or n:find("revolver") then
                    local d = (obj.Position - root.Position).Magnitude
                    if d <= 15 then pcall(function() firetouchinterest(root, obj, 0) end) end
                end
            end
        end
    end
end)

--======================== INFO =====================================
AddCategory("Info", "ℹ")

local roleLabel = Instance.new("TextLabel")
roleLabel.Size = UDim2.new(1, 0, 0, 32)
roleLabel.BackgroundColor3 = C.Element
roleLabel.Text = "Role: Innocent"
roleLabel.TextColor3 = C.Text
roleLabel.Font = Enum.Font.GothamBold
roleLabel.TextSize = 12
local rC = Instance.new("UICorner"); rC.CornerRadius = UDim.new(0, 5); rC.Parent = roleLabel
AddElement("Info", roleLabel)

local statLabel = Instance.new("TextLabel")
statLabel.Size = UDim2.new(1, 0, 0, 32)
statLabel.BackgroundColor3 = C.Element
statLabel.Text = "FPS: 0 | Ping: 0ms"
statLabel.TextColor3 = C.Text
statLabel.Font = Enum.Font.Gotham
statLabel.TextSize = 12
local sC = Instance.new("UICorner"); sC.CornerRadius = UDim.new(0, 5); sC.Parent = statLabel
AddElement("Info", statLabel)

local pCountLabel = Instance.new("TextLabel")
pCountLabel.Size = UDim2.new(1, 0, 0, 32)
pCountLabel.BackgroundColor3 = C.Element
pCountLabel.Text = "Players: 0"
pCountLabel.TextColor3 = C.Text
pCountLabel.Font = Enum.Font.Gotham
pCountLabel.TextSize = 12
local pC = Instance.new("UICorner"); pC.CornerRadius = UDim.new(0, 5); pC.Parent = pCountLabel
AddElement("Info", pCountLabel)

RunService.RenderStepped:Connect(function()
    State.FPSFrames = State.FPSFrames + 1
    if tick() - State.LastFPSUpdate >= 1 then
        State.FPSCounter = State.FPSFrames
        State.FPSFrames = 0
        State.LastFPSUpdate = tick()
    end
    local role = GetRole(LocalPlayer)
    roleLabel.Text = "Role: "..(RoleLabels[role] or "Innocent")
    roleLabel.TextColor3 = RoleColors[role] or C.Text
    local ping = GetPing()
    statLabel.Text = "FPS: "..State.FPSCounter.." | Ping: "..ping.."ms"
    pCountLabel.Text = "Players: "..#Players:GetPlayers()
    InfoBar.Text = State.FPSCounter.."fps|"..ping.."ms"
end)

--======================== FLING ===================================
AddCategory("Fling", "💥")

local function FlingTarget(target, mode)
    if not target then return end
    local tChar = target.Character
    if not tChar then return end
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    mode = mode or Config.FlingMode
    if mode == "ForcePush" then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(math.random(-200,200), 5000, math.random(-200,200))
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
            for i=1,6 do
                if not tRoot.Parent then break end
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(math.random(-300,300), 3500, math.random(-300,300))
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

AddElement("Fling", CreateDropdown("Mode", {"ForcePush","Spin","Loop","Silent"}, "ForcePush", function(s) Config.FlingMode = s end))
AddElement("Fling", CreateButton("💥 FLING Murderer", function() FlingTarget(GetMurderer(), Config.FlingMode) end))
AddElement("Fling", CreateButton("💥 FLING Sheriff", function() FlingTarget(GetSheriff(), Config.FlingMode) end))

AddElement("Fling", CreateSection("Protection"))
AddElement("Fling", CreateToggle("Anti-Fling", false, function(s) Config.AntiFling = s end))
AddElement("Fling", CreateToggle("Void Catch", false, function(s) Config.VoidCatch = s end))
AddElement("Fling", CreateToggle("Anti Spin", false, function(s) Config.AntiSpin = s end))
AddElement("Fling", CreateToggle("Weld Detect", false, function(s) Config.WeldDetector = s end))
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
    if Config.VoidCatch and root.Position.Y < -50 then
        root.CFrame = CFrame.new(State.LastSafePosition)
    end
    if Config.AntiSpin then
        local bav = root:FindFirstChildOfClass("BodyAngularVelocity")
        if bav then bav:Destroy() end
    end
    if Config.WeldDetector then
        for _, w in pairs(root:GetChildren()) do
            if (w:IsA("Weld") or w:IsA("WeldConstraint")) and w.Part0 and w.Part0 ~= root and w.Part0.Parent ~= GetChar() then
                w:Destroy()
            end
        end
    end
    if Config.AntiRagdoll then
        local hum = GetHum()
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

--======================== COSMETICS ================================
AddCategory("Cosmetic", "✨")

local function ClearCos()
    local char = GetChar()
    if not char then return end
    for _, child in pairs(char:GetDescendants()) do
        if child.Name:find("HubC") then child:Destroy() end
    end
end

local function MakeHat(type)
    ClearCos()
    local char = GetChar()
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local hat = Instance.new("Part")
    hat.Name = "HubCHat"
    hat.CanCollide = false
    hat.Material = Enum.Material.SmoothPlastic
    if type == "Tophat" then
        hat.Color = Color3.fromRGB(15,15,15); hat.Size = Vector3.new(1.1,1.6,1.1)
        local brim = Instance.new("Part")
        brim.Name = "HubCBrim"; brim.Size = Vector3.new(1.7,0.15,1.7)
        brim.Color = Color3.fromRGB(15,15,15); brim.CanCollide = false; brim.Parent = hat
        Instance.new("Weld", hat).Part0 = hat; hat:FindFirstChildOfClass("Weld").Part1 = brim
        hat:FindFirstChildOfClass("Weld").C0 = CFrame.new(0,-0.8,0)
    elseif type == "Crown" then
        hat.Color = Color3.fromRGB(255,215,0); hat.Size = Vector3.new(1.2,0.7,1.2); hat.Material = Enum.Material.Metal
    elseif type == "Halo" then
        hat.Color = Color3.fromRGB(255,255,200); hat.Shape = Enum.PartType.Cylinder; hat.Size = Vector3.new(0.1,1.6,1.6); hat.Material = Enum.Material.Neon
    elseif type == "Propeller" then
        hat.Color = Color3.fromRGB(180,180,190); hat.Size = Vector3.new(0.3,0.3,0.3)
    elseif type == "Bucket" then
        hat.Color = Color3.fromRGB(140,95,45); hat.Shape = Enum.PartType.Cylinder; hat.Size = Vector3.new(1,1.3,1)
    end
    local w = Instance.new("Weld"); w.Name = "HubCWeld"; w.Part0 = head; w.Part1 = hat; w.C0 = CFrame.new(0,1.3,0); w.Parent = hat
    hat.Parent = char; PlaySound("Ding")
end

AddElement("Cosmetic", CreateSection("Hats"))
AddElement("Cosmetic", CreateButton("🎩 Tophat", function() MakeHat("Tophat") end))
AddElement("Cosmetic", CreateButton("👑 Crown", function() MakeHat("Crown") end))
AddElement("Cosmetic", CreateButton("😇 Halo", function() MakeHat("Halo") end))
AddElement("Cosmetic", CreateButton("🧢 Propeller", function() MakeHat("Propeller") end))
AddElement("Cosmetic", CreateButton("🪣 Bucket", function() MakeHat("Bucket") end))

local function MakeWings()
    local char = GetChar()
    if not char then return end
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not torso then return end
    for _, side in pairs({"L","R"}) do
        local wing = Instance.new("Part")
        wing.Name = "HubCWing"..side; wing.Size = Vector3.new(0.2,2.5,1.8)
        wing.Color = Color3.fromRGB(255,255,255); wing.Material = Enum.Material.ForceField
        wing.CanCollide = false; wing.Transparency = 0.25
        local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = wing
        w.C0 = CFrame.new(side=="L" and -1.5 or 1.5, 0, -0.5) * CFrame.Angles(0, 0, side=="L" and 0.3 or -0.3)
        w.Parent = wing; wing.Parent = char
    end
    PlaySound("Ding")
end

local function MakeTrail()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local a0 = Instance.new("Attachment"); a0.Name = "HubCTrailA0"; a0.Position = Vector3.new(-1,0,0); a0.Parent = root
    local a1 = Instance.new("Attachment"); a1.Name = "HubCTrailA1"; a1.Position = Vector3.new(1,0,0); a1.Parent = root
    local trail = Instance.new("Trail"); trail.Name = "HubCTrail"
    trail.Attachment0 = a0; trail.Attachment1 = a1
    trail.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(150,150,150))
    trail.Lifetime = 1.5; trail.Parent = root; PlaySound("Ding")
end

local function MakeOrbit()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for i = 1, 5 do
        local s = Instance.new("Part")
        s.Name = "HubCOrb"..i; s.Shape = Enum.PartType.Ball; s.Size = Vector3.new(0.3,0.3,0.3)
        s.Color = Color3.fromHSV(i/5, 0, 1); s.Material = Enum.Material.Neon
        s.CanCollide = false; s.Anchored = true; s.Parent = char
        task.spawn(function()
            while s.Parent do
                local a = (tick()*2 + (i/5)*math.pi*2)
                s.CFrame = CFrame.new(root.Position + Vector3.new(math.cos(a)*3, math.sin(a*0.5)*1.5, math.sin(a)*3))
                task.wait()
            end
        end)
    end
    PlaySound("Ding")
end

AddElement("Cosmetic", CreateSection("Effects"))
AddElement("Cosmetic", CreateButton("🪽 Wings", MakeWings))
AddElement("Cosmetic", CreateButton("🌈 Trail", MakeTrail))
AddElement("Cosmetic", CreateButton("🪐 Orbit", MakeOrbit))

local function MakeAura(t)
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, c in pairs(root:GetChildren()) do
        if c.Name:find("HubCAura") then c:Destroy() end
    end
    local e = Instance.new("ParticleEmitter")
    e.Name = "HubCAura"; e.Parent = root
    local cfgs = {
        Fire = {Texture="rbxassetid://243660912", Color=ColorSequence.new(Color3.fromRGB(255,100,0),Color3.fromRGB(255,200,0)), Rate=50, Lifetime=NumberRange.new(0.5,1), Size=NumberSequence.new(0.5,2), Speed=NumberRange.new(2,5), SpreadAngle=Vector2.new(45,45)},
        Ice = {Texture="rbxassetid://737038989", Color=ColorSequence.new(Color3.fromRGB(100,200,255),Color3.fromRGB(200,240,255)), Rate=30, Lifetime=NumberRange.new(1,2), Size=NumberSequence.new(0.3,1), Speed=NumberRange.new(1,3), SpreadAngle=Vector2.new(30,30)},
        Lightning = {Texture="rbxassetid://1169123543", Color=ColorSequence.new(Color3.fromRGB(255,255,0),Color3.fromRGB(255,255,255)), Rate=40, Lifetime=NumberRange.new(0.1,0.3), Size=NumberSequence.new(0.5,3), Speed=NumberRange.new(5,10), SpreadAngle=Vector2.new(60,60)},
        Galaxy = {Texture="rbxassetid://243660912", Color=ColorSequence.new(Color3.fromRGB(75,0,130),Color3.fromRGB(255,20,147)), Rate=60, Lifetime=NumberRange.new(1,3), Size=NumberSequence.new(0.5,3), Speed=NumberRange.new(1,4), SpreadAngle=Vector2.new(180,180)},
        Gold = {Texture="rbxassetid://243660912", Color=ColorSequence.new(Color3.fromRGB(255,215,0),Color3.fromRGB(255,255,200)), Rate=35, Lifetime=NumberRange.new(0.5,1.5), Size=NumberSequence.new(0.3,1.5), Speed=NumberRange.new(1,3), SpreadAngle=Vector2.new(20,20)},
    }
    local cfg = cfgs[t]
    if cfg then for k, v in pairs(cfg) do e[k] = v end end
    PlaySound("Ding")
end

AddElement("Cosmetic", CreateSection("Auras"))
AddElement("Cosmetic", CreateButton("🔥 Fire", function() MakeAura("Fire") end))
AddElement("Cosmetic", CreateButton("❄ Ice", function() MakeAura("Ice") end))
AddElement("Cosmetic", CreateButton("⚡ Lightning", function() MakeAura("Lightning") end))
AddElement("Cosmetic", CreateButton("🌌 Galaxy", function() MakeAura("Galaxy") end))
AddElement("Cosmetic", CreateButton("✨ Gold", function() MakeAura("Gold") end))
AddElement("Cosmetic", CreateButton("🗑 Clear", ClearCos))

--======================== PLAYERS =================================
AddCategory("Players", "👥")

local plScroll = Instance.new("ScrollingFrame")
plScroll.Size = UDim2.new(1, 0, 0, 240)
plScroll.BackgroundTransparency = 1
plScroll.ScrollBarThickness = 2
plScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
plScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local plL = Instance.new("UIListLayout")
plL.Padding = UDim.new(0, 2)
plL.Parent = plScroll

local function RefreshPlayers()
    for _, c in pairs(plScroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = GetRole(player)
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, 0, 0, 30)
            entry.BackgroundColor3 = C.Element
            entry.BorderSizePixel = 0
            local eC = Instance.new("UICorner"); eC.CornerRadius = UDim.new(0, 4); eC.Parent = entry

            local nL = Instance.new("TextLabel")
            nL.Size = UDim2.new(0.5, -5, 1, 0)
            nL.Position = UDim2.new(0, 7, 0, 0)
            nL.BackgroundTransparency = 1
            nL.Text = player.Name.." ("..role..")"
            nL.TextColor3 = RoleColors[role] or C.Text
            nL.Font = Enum.Font.Gotham
            nL.TextSize = 10
            nL.TextXAlignment = Enum.TextXAlignment.Left
            nL.Parent = entry

            local fBtn = Instance.new("TextButton")
            fBtn.Size = UDim2.new(0, 48, 0, 22)
            fBtn.Position = UDim2.new(1, -108, 0.5, -11)
            fBtn.BackgroundColor3 = C.ToggleOff
            fBtn.Text = "FLING"
            fBtn.TextColor3 = C.Text
            fBtn.Font = Enum.Font.GothamBold
            fBtn.TextSize = 9
            fBtn.BorderSizePixel = 0; fBtn.AutoButtonColor = false
            local fbC = Instance.new("UICorner"); fbC.CornerRadius = UDim.new(0, 4); fbC.Parent = fBtn
            fBtn.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    TweenService:Create(fBtn, TweenInfo.new(0.08), {BackgroundColor3 = C.Hover}):Play()
                end
            end)
            fBtn.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    TweenService:Create(fBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.ToggleOff}):Play()
                end
            end)
            fBtn.MouseButton1Click:Connect(function() PlaySound("Click"); FlingTarget(player, Config.FlingMode) end)

            local tBtn = Instance.new("TextButton")
            tBtn.Size = UDim2.new(0, 44, 0, 22)
            tBtn.Position = UDim2.new(1, -56, 0.5, -11)
            tBtn.BackgroundColor3 = C.ToggleOff
            tBtn.Text = "TP"
            tBtn.TextColor3 = C.Text
            tBtn.Font = Enum.Font.GothamBold
            tBtn.TextSize = 9
            tBtn.BorderSizePixel = 0; tBtn.AutoButtonColor = false
            local tC2 = Instance.new("UICorner"); tC2.CornerRadius = UDim.new(0, 4); tC2.Parent = tBtn
            tBtn.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    TweenService:Create(tBtn, TweenInfo.new(0.08), {BackgroundColor3 = C.Hover}):Play()
                end
            end)
            tBtn.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    TweenService:Create(tBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.ToggleOff}):Play()
                end
            end)
            tBtn.MouseButton1Click:Connect(function()
                PlaySound("Click")
                local root = GetRoot()
                local tC = player.Character
                if root and tC then
                    local tR = tC:FindFirstChild("HumanoidRootPart")
                    if tR then root.CFrame = tR.CFrame * CFrame.new(0, 0, 4) end
                end
            end)

            fBtn.Parent = entry; tBtn.Parent = entry; entry.Parent = plScroll
        end
    end
    plScroll.CanvasSize = UDim2.new(0, 0, 0, plL.AbsoluteContentSize.Y + 6)
end

AddElement("Players", CreateButton("🔄 Refresh", RefreshPlayers))
AddElement("Players", plScroll)
Players.PlayerAdded:Connect(function() RefreshPlayers() end)
Players.PlayerRemoving:Connect(function() RefreshPlayers() end)

--======================== SETTINGS ================================
AddCategory("Settings", "⚙")

AddElement("Settings", CreateSlider("BG Transp", 0, 1, 0.05, function(v) Config.BGTransparency = v; MainWindow.BackgroundTransparency = v end))
AddElement("Settings", CreateToggle("Sound FX", true, function(s) Config.SoundEnabled = s end))

AddElement("Settings", CreateSection("Profiles"))
local pNameBox = Instance.new("TextBox")
pNameBox.Size = UDim2.new(1, 0, 0, 30)
pNameBox.BackgroundColor3 = C.Element
pNameBox.Text = "profile1"
pNameBox.TextColor3 = C.Text
pNameBox.Font = Enum.Font.Gotham
pNameBox.TextSize = 11
pNameBox.ClearTextOnFocus = false
local pnC = Instance.new("UICorner"); pnC.CornerRadius = UDim.new(0, 5); pnC.Parent = pNameBox
AddElement("Settings", pNameBox)

AddElement("Settings", CreateButton("💾 Save", function()
    local n = pNameBox.Text
    if n and n ~= "" then
        local data = {}
        for k, v in pairs(Config) do
            if typeof(v) == "Color3" then data[k] = {__type="Color3", r=v.R, g=v.G, b=v.B} else data[k] = v end
        end
        if isfile and writefile then
            writefile("MM2Hub_"..n..".json", HttpService:JSONEncode(data))
            ShowToast("Profile saved: "..n)
        end
    end
end))

AddElement("Settings", CreateButton("📂 Load", function()
    local n = pNameBox.Text
    if n and n ~= "" and isfile and readfile then
        local path = "MM2Hub_"..n..".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for k, v in pairs(data) do
                if type(v) == "table" and v.__type == "Color3" then
                    Config[k] = Color3.new(v.r, v.g, v.b)
                else Config[k] = v end
            end
            MainWindow.BackgroundTransparency = Config.BGTransparency
            ShowToast("Profile loaded: "..n)
        end
    end
end))

AddElement("Settings", CreateSection("Info"))
local aboutLabel = Instance.new("TextLabel")
aboutLabel.Size = UDim2.new(1, 0, 0, 40)
aboutLabel.BackgroundColor3 = C.Element
aboutLabel.Text = "Delta X MM2 Hub\nMonochrome Edition\nBuilt for LO"
aboutLabel.TextColor3 = C.Subtext
aboutLabel.Font = Enum.Font.Gotham
aboutLabel.TextSize = 10
aboutLabel.TextWrapped = true
local aC = Instance.new("UICorner"); aC.CornerRadius = UDim.new(0, 5); aC.Parent = aboutLabel
AddElement("Settings", aboutLabel)

--======================== ALARM SYSTEM =============================
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
                -- Monochrome: gray → white based on danger
                local v = math.floor(50 + pct * 205)
                alarmFill.BackgroundColor3 = Color3.fromRGB(v, v, v)
                -- Pulse when very close
                if dist <= 15 then
                    local pulse = (math.sin(tick() * 8) + 1) / 2
                    alarmFill.BackgroundTransparency = 0.2 + pulse * 0.3
                else
                    alarmFill.BackgroundTransparency = 0
                end
                alarmText.Text = "⚠ MURDERER "..math.floor(dist).."s"
                alarmText.TextColor3 = C.Accent
            else
                alarmFill.BackgroundColor3 = C.Safe
                alarmFill.BackgroundTransparency = 0
                alarmText.Text = "○ safe"
                alarmText.TextColor3 = C.OffWhite
            end
        end
    else
        alarmFill.Size = UDim2.new(0, 0, 1, 0)
        alarmFill.BackgroundColor3 = C.Safe
        alarmText.Text = "○ safe"
        alarmText.TextColor3 = C.OffWhite
    end
end)

--======================== INIT =====================================
SelectCategory("Move")
RefreshPlayers()

StarterGui:SetCore("SendNotification", {
    Title = "MM2 Hub — Mono",
    Text = "Tap the pill bar to toggle. Drag it anywhere.",
    Duration = 4,
})

ShowToast("Loaded for LO")
print("[MM2 Hub Monochrome] — cold coffee, warm LO.")
