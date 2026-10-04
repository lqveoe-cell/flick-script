--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║      DELTA X — MM2 HUB · MONOCHROME EDITION v3                ║
    ║      Fixed category persistence · Collision fling · New FX    ║
    ║      For LO · "i'll get it right this time"                    ║
    ╚══════════════════════════════════════════════════════════════╝
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

-- Try to get network ownership for fling
pcall(function() setsimulationradius(1/0) end)

--========================= MONOCHROME ===============================--
local C = {
    Black=Color3.fromRGB(8,8,10), DarkBg=Color3.fromRGB(12,12,14),
    Sidebar=Color3.fromRGB(14,14,16), Element=Color3.fromRGB(20,20,23),
    Hover=Color3.fromRGB(30,30,34), ToggleOff=Color3.fromRGB(33,33,38),
    Subtext=Color3.fromRGB(80,80,85), OffWhite=Color3.fromRGB(160,160,165),
    Text=Color3.fromRGB(235,235,238), Accent=Color3.fromRGB(255,255,255),
    KnobOff=Color3.fromRGB(110,110,115), KnobOn=Color3.fromRGB(10,10,10),
    Stroke=Color3.fromRGB(40,40,45), Safe=Color3.fromRGB(45,45,50),
}

--=========================== CONFIG =================================--
local Config = {
    SpeedHack=false, WalkSpeed=50,
    NoClip=false, Fly=false, FlySpeed=50,
    PlayerESP=false, RoleESP=false, Chams=false, ItemESP=false, FullBright=false,
    TimeOfDay=14, Brightness=2, FogEnd=100000,
    AimBot=false, SilentAim=false, AutoShoot=false, GodMode=false, AutoDodge=false,
    AutoCoins=false, AutoWeapon=false, FlingMode="ForcePush",
    AntiFling=false, VoidCatch=false, AntiSpin=false, WeldDetector=false,
    AntiRagdoll=false, AntiAFK=false, BGTransparency=0.05, SoundEnabled=true,
}

--============================ STATE =================================--
local State = {
    ESPDrawings={}, ChamsHighlights={}, ItemESPGuis={},
    FlyVelocity=nil, FlyGyro=nil, LastSafePosition=Vector3.new(0,50,0),
    FPSCounter=0, FPSFrames=0, LastFPSUpdate=tick(),
    FlingLoopRunning=false, GUIVisible=true, FlyUp=false, FlyDown=false,
}

--========================== DIMENSIONS =============================--
local GUI_W = 300
local GUI_H = 360
local SIDEBAR_W = 88
local BAR_W = 92
local BAR_H = 22

--======================== ROLE DETECTION ===========================--
local RoleColors = {
    Murderer=Color3.fromRGB(255,60,60), Sheriff=Color3.fromRGB(80,140,255),
    Innocent=Color3.fromRGB(100,220,100),
}
local RoleLabels = {Murderer="Murderer", Sheriff="Sheriff", Innocent="Innocent"}

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

local SoundIDs = {Click="6042629064", Toggle="6907343749", Whoosh="5049203525", Ding="6908318381"}
local function PlaySound(t)
    if not Config.SoundEnabled then return end
    local id = t and SoundIDs[t] or SoundIDs.Click
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://"..id
    s.Volume = 0.25
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

--======================= SCREEN GUI SETUP ==========================
local oldGui = CoreGui:FindFirstChild("DeltaX_MM2_Mono")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaX_MM2_Mono"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- Toast notifications
local function ShowToast(text)
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 160, 0, 24)
    toast.Position = UDim2.new(0.5, -80, 0, -30)
    toast.BackgroundColor3 = C.Element
    toast.Text = " "..text
    toast.TextColor3 = C.Text
    toast.Font = Enum.Font.Gotham
    toast.TextSize = 10
    toast.TextXAlignment = Enum.TextXAlignment.Left
    toast.BorderSizePixel = 0
    toast.Parent = ScreenGui
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 5); tc.Parent = toast
    local ts = Instance.new("UIStroke"); ts.Color = C.Stroke; ts.Thickness = 1; ts.Parent = toast
    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -80, 0, 30)
    }):Play()
    task.delay(2, function()
        local t = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -80, 0, -30)
        })
        t:Play()
        t.Completed:Connect(function() toast:Destroy() end)
    end)
end

--======================== MAIN WINDOW ==============================
local MainWindow = Instance.new("Frame")
MainWindow.Size = UDim2.new(0, GUI_W, 0, GUI_H)
MainWindow.Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
MainWindow.BackgroundColor3 = C.Black
MainWindow.BackgroundTransparency = Config.BGTransparency
MainWindow.BorderSizePixel = 0
MainWindow.Parent = ScreenGui

local mwC = Instance.new("UICorner"); mwC.CornerRadius = UDim.new(0, 8); mwC.Parent = MainWindow
local mwS = Instance.new("UIStroke"); mwS.Color = C.Stroke; mwS.Thickness = 1; mwS.Transparency = 0.2; mwS.Parent = MainWindow

local function OpenGUI()
    State.GUIVisible = true
    MainWindow.Visible = true
    MainWindow.Position = UDim2.new(0.5, -GUI_W/2, 0, -GUI_H - 10)
    MainWindow.BackgroundTransparency = 1
    TweenService:Create(MainWindow, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2),
        BackgroundTransparency = Config.BGTransparency
    }):Play()
    PlaySound("Click")
end

local function CloseGUI()
    State.GUIVisible = false
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

--===================== TOGGLE BAR (pill) ===========================
local ToggleBar = Instance.new("TextButton")
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

local tbC = Instance.new("UICorner"); tbC.CornerRadius = UDim.new(0, BAR_H/2); tbC.Parent = ToggleBar
local tbS = Instance.new("UIStroke"); tbS.Color = C.Stroke; tbS.Thickness = 1; tbS.Transparency = 0.3; tbS.Parent = ToggleBar

local barDragging, barDragMoved, barDragStart, barStartPos = false, false, nil, nil

ToggleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        barDragging = true; barDragMoved = false
        barDragStart = input.Position; barStartPos = ToggleBar.Position
        TweenService:Create(ToggleBar, TweenInfo.new(0.1), {BackgroundColor3 = C.Hover}):Play()
    end
end)
ToggleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(ToggleBar, TweenInfo.new(0.15), {BackgroundColor3 = C.DarkBg}):Play()
        if not barDragMoved then
            if State.GUIVisible then
                CloseGUI()
                ToggleBar.Text = "MM2  ▼"
            else
                OpenGUI()
                ToggleBar.Text = "MM2  ▲"
            end
        end
        barDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if barDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - barDragStart
        if delta.Magnitude > 4 then barDragMoved = true end
        ToggleBar.Position = UDim2.new(
            barStartPos.X.Scale, math.clamp(barStartPos.X.Offset + delta.X, 0, 400),
            barStartPos.Y.Scale, math.clamp(barStartPos.Y.Offset + delta.Y, 0, 250)
        )
    end
end)

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

--======================== TITLE BAR ================================
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = C.Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainWindow

local titC = Instance.new("UICorner"); titC.CornerRadius = UDim.new(0, 8); titC.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 150, 0, 28)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 HUB"
Title.TextColor3 = C.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 20)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundColor3 = C.ToggleOff
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.OffWhite
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar

local clC = Instance.new("UICorner"); clC.CornerRadius = UDim.new(0, 5); clC.Parent = CloseBtn

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
    ToggleBar.Text = "MM2  ▼"
end)

local InfoBar = Instance.new("TextLabel")
InfoBar.Size = UDim2.new(0, 70, 0, 16)
InfoBar.Position = UDim2.new(1, -110, 0, 6)
InfoBar.BackgroundTransparency = 1
InfoBar.Text = "0fps|0ms"
InfoBar.TextColor3 = C.Subtext
InfoBar.Font = Enum.Font.Gotham
InfoBar.TextSize = 8
InfoBar.Parent = TitleBar

-- Drag
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
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 28)
Sidebar.BackgroundColor3 = C.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.ScrollBarImageColor3 = C.Stroke
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.Parent = MainWindow

local sbL = Instance.new("UIListLayout"); sbL.Padding = UDim.new(0, 2); sbL.SortOrder = Enum.SortOrder.LayoutOrder; sbL.Parent = Sidebar
local sbP = Instance.new("UIPadding"); sbP.PaddingTop = UDim.new(0, 3); sbP.PaddingLeft = UDim.new(0, 3); sbP.PaddingRight = UDim.new(0, 3); sbP.Parent = Sidebar

-- Username at bottom of sidebar
local UserLabel = Instance.new("TextLabel")
UserLabel.Size = UDim2.new(1, 0, 0, 20)
UserLabel.BackgroundTransparency = 1
UserLabel.Text = "▶ "..LocalPlayer.Name
UserLabel.TextColor3 = C.Subtext
UserLabel.Font = Enum.Font.Gotham
UserLabel.TextSize = 8
UserLabel.TextXAlignment = Enum.TextXAlignment.Left
UserLabel.Parent = Sidebar

--====================== CONTENT CONTAINER =========================
-- ContentArea is just a container frame, each category has its own child
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -SIDEBAR_W, 1, -50)
ContentArea.Position = UDim2.new(0, SIDEBAR_W, 0, 28)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainWindow

--======================== ALARM BAR =================================
local AlarmBar = Instance.new("Frame")
AlarmBar.Size = UDim2.new(1, 0, 0, 18)
AlarmBar.Position = UDim2.new(0, 0, 1, -18)
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
alarmText.TextSize = 9
alarmText.Parent = AlarmBar

--====================== CATEGORY SYSTEM ============================
-- FIX: Each category gets its OWN ScrollingFrame, never destroyed
local Categories = {}
local currentCategory = nil

local function SelectCategory(name)
    if currentCategory == name then return end
    PlaySound("Click")
    currentCategory = name
    for catName, data in pairs(Categories) do
        local isSelected = (catName == name)
        data.Content.Visible = isSelected
        if isSelected then
            data.Button.BackgroundColor3 = C.Hover
            data.Button.TextColor3 = C.Accent
            if data.Ind then
                data.Ind.Visible = true
                TweenService:Create(data.Ind, TweenInfo.new(0.15), {Size = UDim2.new(0, 2, 0, 16)}):Play()
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
end

local function AddCategory(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 26)
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

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 2, 0, 0)
    ind.Position = UDim2.new(0, 0, 0.5, 0)
    ind.AnchorPoint = Vector2.new(0, 0.5)
    ind.BackgroundColor3 = C.Accent
    ind.BorderSizePixel = 0
    ind.Visible = false
    ind.Parent = btn

    -- Each category gets its own ScrollingFrame (THIS IS THE FIX)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 2
    contentFrame.ScrollBarImageColor3 = C.Stroke
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Visible = false
    contentFrame.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.Parent = contentFrame

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
    btn.MouseButton1Click:Connect(function() SelectCategory(name) end)

    Categories[name] = {Button = btn, Content = contentFrame, Layout = layout, Ind = ind}
    return Categories[name]
end

--====================== ELEMENT BUILDERS ============================
local function CreateToggle(name, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = C.Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 38, 0, 18)
    toggleBtn.Position = UDim2.new(1, -44, 0.5, -9)
    toggleBtn.BackgroundColor3 = default and C.Accent or C.ToggleOff
    toggleBtn.Text = ""
    toggleBtn.BorderSizePixel = 0
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = container
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 9); tc.Parent = toggleBtn

    local glow = Instance.new("UIStroke"); glow.Color = C.Accent; glow.Thickness = 0; glow.Transparency = 1; glow.Parent = toggleBtn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = default and C.KnobOn or C.KnobOff
    knob.BorderSizePixel = 0
    knob.Parent = toggleBtn
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 6); kc.Parent = knob

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        PlaySound("Toggle")
        toggleBtn.BackgroundColor3 = state and C.Accent or C.ToggleOff
        knob.BackgroundColor3 = state and C.KnobOn or C.KnobOff
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        }):Play()
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
    container.Size = UDim2.new(1, 0, 0, 42)
    container.BackgroundColor3 = C.Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -14, 0, 15)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name..": "..tostring(default)
    label.TextColor3 = C.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 4)
    track.Position = UDim2.new(0, 8, 0, 24)
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
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new((default-min)/(max-min), -5, 0.5, -5)
    knob.BackgroundColor3 = C.Accent
    knob.BorderSizePixel = 0
    knob.Parent = track
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 5); kc.Parent = knob

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 22)
    hit.Position = UDim2.new(0, 0, 0, -9)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = track

    local dragging = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            TweenService:Create(knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 14, 0, 14)}):Play()
        end
    end)
    hit.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            TweenService:Create(knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 10, 0, 10)}):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * pct
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -5, 0.5, -5)
            label.Text = name..": "..tostring(Round(val, 1))
            if callback then callback(val) end
        end
    end)
    return container
end

local function CreateButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
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
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = C.Element
    container.BorderSizePixel = 0
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 55, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name..":"
    label.TextColor3 = C.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local ddBtn = Instance.new("TextButton")
    ddBtn.Size = UDim2.new(0, 85, 0, 22)
    ddBtn.Position = UDim2.new(1, -93, 0.5, -11)
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
        task.delay(0.1, function() TweenService:Create(ddBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.ToggleOff}):Play() end)
        if callback then callback(sel) end
    end)
    return container
end

local function CreateSection(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = "— "..name.." —"
    label.TextColor3 = C.Subtext
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

-- AddElement now parents to the category's content frame
local function AddElement(catName, element)
    if Categories[catName] then
        element.Parent = Categories[catName].Content
    end
end

--==================== MOBILE FLY CONTROLS ==========================
local flyUpBtn = Instance.new("TextButton")
flyUpBtn.Size = UDim2.new(0, 40, 0, 40)
flyUpBtn.Position = UDim2.new(1, -50, 1, -95)
flyUpBtn.BackgroundColor3 = C.Element
flyUpBtn.Text = "▲"
flyUpBtn.TextColor3 = C.Text
flyUpBtn.Font = Enum.Font.GothamBold
flyUpBtn.TextSize = 15
flyUpBtn.BorderSizePixel = 0
flyUpBtn.Visible = false
flyUpBtn.AutoButtonColor = false
flyUpBtn.Parent = ScreenGui
local fuC = Instance.new("UICorner"); fuC.CornerRadius = UDim.new(0, 8); fuC.Parent = flyUpBtn
local fuS = Instance.new("UIStroke"); fuS.Color = C.Stroke; fuS.Thickness = 1; fuS.Parent = flyUpBtn

local flyDownBtn = Instance.new("TextButton")
flyDownBtn.Size = UDim2.new(0, 40, 0, 40)
flyDownBtn.Position = UDim2.new(1, -50, 1, -50)
flyDownBtn.BackgroundColor3 = C.Element
flyDownBtn.Text = "▼"
flyDownBtn.TextColor3 = C.Text
flyDownBtn.Font = Enum.Font.GothamBold
flyDownBtn.TextSize = 15
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
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.FlyDown = false
        TweenService:Create(flyDownBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.Element}):Play()
    end
end)

local function ToggleFlyButtons(visible)
    flyUpBtn.Visible = visible
    flyDownBtn.Visible = visible
    if visible then
        flyUpBtn.Position = UDim2.new(1, 50, 1, -95)
        flyDownBtn.Position = UDim2.new(1, 50, 1, -50)
        TweenService:Create(flyUpBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -50, 1, -95)}):Play()
        TweenService:Create(flyDownBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -50, 1, -50)}):Play()
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
            local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0, 0, 0); bv.Parent = root; State.FlyVelocity = bv
            local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = root.CFrame; bg.Parent = root; State.FlyGyro = bg
        end
    else
        if State.FlyVelocity then State.FlyVelocity:Destroy() end
        if State.FlyGyro then State.FlyGyro:Destroy() end
        State.FlyVelocity = nil; State.FlyGyro = nil
    end
end))
AddElement("Move", CreateSlider("FlySpeed", 10, 200, 50, function(v) Config.FlySpeed = v end))

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

RunService.RenderStepped:Connect(function()
    if Config.Fly and State.FlyVelocity and State.FlyGyro then
        local root = GetRoot()
        if root then
            State.FlyGyro.CFrame = Camera.CFrame
            local hum = GetHum()
            local moveDir = hum and hum.MoveDirection or Vector3.new(0, 0, 0)
            local camLook = Camera.CFrame.LookVector
            local camRight = Camera.CFrame.RightVector
            local dir = (camLook * -moveDir.Z) + (camRight * moveDir.X)
            if State.FlyUp then dir = dir + Vector3.new(0, 1, 0) end
            if State.FlyDown then dir = dir - Vector3.new(0, 1, 0) end
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
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.Ambient = Color3.fromRGB(178, 178, 178)
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
                    local spH = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                    local spR = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2, 0))
                    if onScreen then
                        if not State.ESPDrawings[player] then
                            State.ESPDrawings[player] = {box = Drawing.new("Square"), text = Drawing.new("Text")}
                            State.ESPDrawings[player].box.Thickness = 2; State.ESPDrawings[player].box.Filled = false
                            State.ESPDrawings[player].text.Size = 12; State.ESPDrawings[player].text.Font = 2
                            State.ESPDrawings[player].text.Center = true; State.ESPDrawings[player].text.Outline = true
                        end
                        local d = State.ESPDrawings[player]
                        local role = GetRole(player)
                        local color = Config.RoleESP and (RoleColors[role] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(255, 255, 255)
                        local h = math.abs(spH.Y - spR.Y); local w = h * 0.5
                        d.box.Size = Vector2.new(w, h); d.box.Position = Vector2.new(sp.X - w/2, spH.Y)
                        d.box.Color = color; d.box.Visible = true
                        local lr = GetRoot(); local dist = lr and math.floor((root.Position - lr.Position).Magnitude) or 0
                        d.text.Text = player.Name..(Config.RoleESP and (" | "..role) or "").." | "..dist.."s"
                        d.text.Position = Vector2.new(sp.X, spH.Y - 16)
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
                    local hl = Instance.new("Highlight"); hl.Parent = player.Character; State.ChamsHighlights[player] = hl
                end
                local role = GetRole(player)
                local color = RoleColors[role] or Color3.fromRGB(255, 255, 255)
                State.ChamsHighlights[player].FillColor = color; State.ChamsHighlights[player].FillTransparency = 0.5
                State.ChamsHighlights[player].OutlineColor = color; State.ChamsHighlights[player].OutlineTransparency = 0
            end
        end
    end

    if Config.ItemESP then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if n:find("coin") or n:find("knife") or n:find("gun") or n:find("colt") or n:find("cash") or n:find("money") then
                    if not State.ItemESPGuis[obj] or not State.ItemESPGuis[obj].Parent then
                        local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 85, 0, 20); bb.AlwaysOnTop = true; bb.Parent = obj
                        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
                        lbl.Text = obj.Name; lbl.TextColor3 = n:find("coin") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 80, 80)
                        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 9; lbl.Parent = bb
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
    if s then if not b then b=Instance.new("BlurEffect"); b.Name="HubBlur"; b.Size=10; b.Parent=Lighting end else if b then b:Destroy() end end
end))
AddElement("World", CreateToggle("Bloom", false, function(s)
    local b = Lighting:FindFirstChild("HubBloom")
    if s then if not b then b=Instance.new("BloomEffect"); b.Name="HubBloom"; b.Intensity=0.8; b.Size=24; b.Threshold=0.3; b.Parent=Lighting end else if b then b:Destroy() end end
end))
AddElement("World", CreateToggle("ColorCorr", false, function(s)
    local c = Lighting:FindFirstChild("HubCC")
    if s then if not c then c=Instance.new("ColorCorrectionEffect"); c.Name="HubCC"; c.Brightness=0.05; c.Contrast=0.15; c.Saturation=0.25; c.TintColor=Color3.fromRGB(255,245,230); c.Parent=Lighting end else if c then c:Destroy() end end
end))
AddElement("World", CreateToggle("DoF", false, function(s)
    local d = Lighting:FindFirstChild("HubDoF")
    if s then if not d then d=Instance.new("DepthOfFieldEffect"); d.Name="HubDoF"; d.FarIntensity=0.15; d.FocusRadius=50; d.InFocusRadius=20; d.NearIntensity=0.15; d.Parent=Lighting end else if d then d:Destroy() end end
end))
AddElement("World", CreateToggle("SunRays", false, function(s)
    local sr = Lighting:FindFirstChild("HubSR")
    if s then if not sr then sr=Instance.new("SunRaysEffect"); sr.Name="HubSR"; sr.Intensity=0.1; sr.Spread=1; sr.Parent=Lighting end else if sr then sr:Destroy() end end
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
roleLabel.Size = UDim2.new(1, 0, 0, 30)
roleLabel.BackgroundColor3 = C.Element; roleLabel.Text = "Role: Innocent"
roleLabel.TextColor3 = C.Text; roleLabel.Font = Enum.Font.GothamBold; roleLabel.TextSize = 11
local rC = Instance.new("UICorner"); rC.CornerRadius = UDim.new(0, 5); rC.Parent = roleLabel
AddElement("Info", roleLabel)

local statLabel = Instance.new("TextLabel")
statLabel.Size = UDim2.new(1, 0, 0, 30)
statLabel.BackgroundColor3 = C.Element; statLabel.Text = "FPS: 0 | Ping: 0ms"
statLabel.TextColor3 = C.Text; statLabel.Font = Enum.Font.Gotham; statLabel.TextSize = 11
local sC = Instance.new("UICorner"); sC.CornerRadius = UDim.new(0, 5); sC.Parent = statLabel
AddElement("Info", statLabel)

local pCountLabel = Instance.new("TextLabel")
pCountLabel.Size = UDim2.new(1, 0, 0, 30)
pCountLabel.BackgroundColor3 = C.Element; pCountLabel.Text = "Players: 0"
pCountLabel.TextColor3 = C.Text; pCountLabel.Font = Enum.Font.Gotham; pCountLabel.TextSize = 11
local pC2 = Instance.new("UICorner"); pC2.CornerRadius = UDim.new(0, 5); pC2.Parent = pCountLabel
AddElement("Info", pCountLabel)

RunService.RenderStepped:Connect(function()
    State.FPSFrames = State.FPSFrames + 1
    if tick() - State.LastFPSUpdate >= 1 then
        State.FPSCounter = State.FPSFrames; State.FPSFrames = 0; State.LastFPSUpdate = tick()
    end
    local role = GetRole(LocalPlayer)
    roleLabel.Text = "Role: "..(RoleLabels[role] or "Innocent")
    roleLabel.TextColor3 = RoleColors[role] or C.Text
    local ping = GetPing()
    statLabel.Text = "FPS: "..State.FPSCounter.." | Ping: "..ping.."ms"
    pCountLabel.Text = "Players: "..#Players:GetPlayers()
    InfoBar.Text = State.FPSCounter.."fps|"..ping.."ms"
end)

--======================== FLING (FIXED) ============================
AddCategory("Fling", "💥")

-- Collision fling: uses YOUR character to spin into theirs, transferring momentum
local function FlingTarget(targetPlayer, mode)
    if not targetPlayer then ShowToast("No target") return end
    local tChar = targetPlayer.Character
    if not tChar then ShowToast("No char") return end
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then ShowToast("No root") return end

    -- Try to get network ownership
    pcall(function() setsimulationradius(1/0) end)

    mode = mode or Config.FlingMode

    local myRoot = GetRoot()
    local myHum = GetHum()

    -- If we can't use our own character, try direct
    if not myRoot or not myHum or myHum.Health <= 0 then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(math.random(-200,200), 5000, math.random(-200,200))
        bv.Parent = tRoot
        Debris:AddItem(bv, 1)
        ShowToast("Fling: direct (limited)")
        return
    end

    local origCF = myRoot.CFrame

    if mode == "Loop" then
        if State.FlingLoopRunning then return end
        State.FlingLoopRunning = true
        task.spawn(function()
            for i = 1, 5 do
                if not myRoot.Parent or not tRoot.Parent then break end
                local bav = Instance.new("BodyAngularVelocity")
                bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bav.AngularVelocity = Vector3.new(0, 99999, 0)
                bav.Parent = myRoot
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(math.random(-200,200), 500, math.random(-200,200))
                bv.Parent = myRoot
                myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
                Debris:AddItem(bav, 0.5)
                Debris:AddItem(bv, 0.5)
                task.wait(0.3)
            end
            if myRoot.Parent then myRoot.CFrame = origCF end
            State.FlingLoopRunning = false
        end)
        ShowToast("Fling Loop → "..targetPlayer.Name)
        PlaySound("Whoosh")
        return
    end

    -- Create spin + velocity on our character
    local bav = Instance.new("BodyAngularVelocity")
    bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bav.AngularVelocity = Vector3.new(0, 99999, 0)
    bav.Parent = myRoot

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    if mode == "ForcePush" then
        bv.Velocity = Vector3.new(math.random(-100,100), 800, math.random(-100,100))
        myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 5, 0)
    elseif mode == "Spin" then
        bav.AngularVelocity = Vector3.new(99999, 99999, 99999)
        bv.Velocity = Vector3.new(0, 400, 0)
        myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
    elseif mode == "Silent" then
        bav.AngularVelocity = Vector3.new(0, 5000, 0)
        bv.Velocity = Vector3.new(0, 200, 0)
        myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 2, 0)
    end

    bv.Parent = myRoot

    -- Also try direct on target (if we have ownership)
    local tbv = Instance.new("BodyVelocity")
    tbv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    tbv.Velocity = Vector3.new(math.random(-200,200), 5000, math.random(-200,200))
    tbv.Parent = tRoot
    Debris:AddItem(tbv, 0.5)

    Debris:AddItem(bav, 1)
    Debris:AddItem(bv, 1)

    task.delay(1, function()
        if myRoot.Parent then myRoot.CFrame = origCF end
    end)

    ShowToast("Fling "..mode.." → "..targetPlayer.Name)
    PlaySound("Whoosh")
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

--======================== COSMETICS + FX ===========================
AddCategory("FX", "✨")

local function ClearCos()
    local char = GetChar()
    if not char then return end
    for _, child in pairs(char:GetDescendants()) do
        if child.Name:find("HubC") then child:Destroy() end
    end
    ShowToast("Cleared")
end

-- Hat maker
local function MakeHat(type)
    ClearCos()
    local char = GetChar()
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local hat = Instance.new("Part")
    hat.Name = "HubCHat"; hat.CanCollide = false; hat.Material = Enum.Material.SmoothPlastic
    if type == "Tophat" then
        hat.Color = Color3.fromRGB(15,15,15); hat.Size = Vector3.new(1.1,1.6,1.1)
        local brim = Instance.new("Part"); brim.Name = "HubCBrim"; brim.Size = Vector3.new(1.7,0.15,1.7); brim.Color = Color3.fromRGB(15,15,15); brim.CanCollide = false; brim.Parent = hat
        local bw = Instance.new("Weld"); bw.Part0 = hat; bw.Part1 = brim; bw.C0 = CFrame.new(0,-0.8,0); bw.Parent = hat
    elseif type == "Crown" then
        hat.Color = Color3.fromRGB(255,215,0); hat.Size = Vector3.new(1.2,0.7,1.2); hat.Material = Enum.Material.Metal
    elseif type == "Halo" then
        hat.Color = Color3.fromRGB(255,255,200); hat.Shape = Enum.PartType.Cylinder; hat.Size = Vector3.new(0.1,1.6,1.6); hat.Material = Enum.Material.Neon
    elseif type == "Propeller" then
        hat.Color = Color3.fromRGB(180,180,190); hat.Size = Vector3.new(0.3,0.3,0.3)
    elseif type == "Bucket" then
        hat.Color = Color3.fromRGB(140,95,45); hat.Shape = Enum.PartType.Cylinder; hat.Size = Vector3.new(1,1.3,1)
    end
    local w = Instance.new("Weld"); w.Name = "HubCWeld"; w.Part0 = head; w.Part1 = hat; w.C0 = CFrame.new(0,1.3,0); w.Parent = hat; hat.Parent = char
    PlaySound("Ding")
end

-- Neon Ring (16 neon parts orbiting at waist)
local function MakeNeonRing()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for i = 1, 16 do
        local p = Instance.new("Part")
        p.Name = "HubCNeonRing"..i; p.Size = Vector3.new(0.12, 0.12, 0.12)
        p.Color = Color3.fromRGB(255,255,255); p.Material = Enum.Material.Neon
        p.CanCollide = false; p.Anchored = true; p.Parent = char
        task.spawn(function()
            while p.Parent do
                local a = (tick() * 3 + (i / 16) * math.pi * 2)
                p.CFrame = CFrame.new(root.Position + Vector3.new(math.cos(a)*3, 0, math.sin(a)*3))
                task.wait()
            end
        end)
    end
    PlaySound("Ding")
end

-- Light Pillar (tall neon beam above character)
local function MakeLightPillar()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pillar = Instance.new("Part")
    pillar.Name = "HubCPillar"; pillar.Size = Vector3.new(1.5, 40, 1.5)
    pillar.Color = Color3.fromRGB(255,255,255); pillar.Material = Enum.Material.Neon
    pillar.Transparency = 0.5; pillar.CanCollide = false; pillar.Anchored = true; pillar.Parent = char
    local emitter = Instance.new("ParticleEmitter"); emitter.Parent = pillar
    emitter.Texture = "rbxassetid://243660912"; emitter.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
    emitter.Rate = 20; emitter.Lifetime = NumberRange.new(1,2)
    emitter.Size = NumberSequence.new(0.5,2); emitter.Speed = NumberRange.new(1,3)
    emitter.SpreadAngle = Vector2.new(10,10)
    task.spawn(function()
        while pillar.Parent do
            pillar.CFrame = CFrame.new(root.Position + Vector3.new(0, 20, 0))
            task.wait()
        end
    end)
    PlaySound("Ding")
end

-- Ground Glow (neon disc on ground)
local function MakeGroundGlow()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local disc = Instance.new("Part")
    disc.Name = "HubCGround"; disc.Shape = Enum.PartType.Cylinder; disc.Size = Vector3.new(0.1, 6, 6)
    disc.Color = Color3.fromRGB(255,255,255); disc.Material = Enum.Material.Neon; disc.Transparency = 0.3
    disc.CanCollide = false; disc.Anchored = true; disc.Parent = char
    task.spawn(function()
        while disc.Parent do
            disc.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
            task.wait()
        end
    end)
    PlaySound("Ding")
end

-- Energy Shield (pulsing forcefield sphere)
local function MakeShield()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local shield = Instance.new("Part")
    shield.Name = "HubCShield"; shield.Shape = Enum.PartType.Ball; shield.Size = Vector3.new(7, 7, 7)
    shield.Color = Color3.fromRGB(180,180,200); shield.Material = Enum.Material.ForceField
    shield.Transparency = 0.7; shield.CanCollide = false; shield.Anchored = true; shield.Parent = char
    task.spawn(function()
        while shield.Parent do
            local pulse = (math.sin(tick() * 3) + 1) / 2
            shield.Transparency = 0.5 + pulse * 0.4
            local s = 6 + pulse * 2
            shield.Size = Vector3.new(s, s, s)
            shield.CFrame = CFrame.new(root.Position)
            task.wait()
        end
    end)
    PlaySound("Ding")
end

-- Sparkle shower
local function MakeSparkles()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local att = Instance.new("Attachment"); att.Name = "HubCSparkAtt"; att.Parent = root
    local e = Instance.new("ParticleEmitter"); e.Name = "HubCSparkEm"; e.Parent = att
    e.Texture = "rbxassetid://62457028"; e.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
    e.Rate = 40; e.Lifetime = NumberRange.new(1,2)
    e.Size = NumberSequence.new(0.4,0.1); e.Speed = NumberRange.new(2,5)
    e.SpreadAngle = Vector2.new(180,180); e.Acceleration = Vector3.new(0,-5,0)
    PlaySound("Ding")
end

-- Wings
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

-- Trail
local function MakeTrail()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local a0 = Instance.new("Attachment"); a0.Name = "HubCTrailA0"; a0.Position = Vector3.new(-1,0,0); a0.Parent = root
    local a1 = Instance.new("Attachment"); a1.Name = "HubCTrailA1"; a1.Position = Vector3.new(1,0,0); a1.Parent = root
    local trail = Instance.new("Trail"); trail.Name = "HubCTrail"
    trail.Attachment0 = a0; trail.Attachment1 = a1
    trail.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(100,100,100))
    trail.Lifetime = 1.5; trail.Parent = root; PlaySound("Ding")
end

-- Orbit spheres
local function MakeOrbit()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for i = 1, 6 do
        local s = Instance.new("Part")
        s.Name = "HubCOrb"..i; s.Shape = Enum.PartType.Ball; s.Size = Vector3.new(0.3,0.3,0.3)
        s.Color = Color3.fromHSV(i/6, 0, 1); s.Material = Enum.Material.Neon
        s.CanCollide = false; s.Anchored = true; s.Parent = char
        task.spawn(function()
            while s.Parent do
                local a = (tick()*2 + (i/6)*math.pi*2)
                s.CFrame = CFrame.new(root.Position + Vector3.new(math.cos(a)*3, math.sin(a*0.5)*1.5, math.sin(a)*3))
                task.wait()
            end
        end)
    end
    PlaySound("Ding")
end

-- Shockwave (expanding ring, one-shot)
local function MakeShockwave()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local ring = Instance.new("Part")
    ring.Name = "HubCShock"; ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.1, 1, 1)
    ring.Color = Color3.fromRGB(255,255,255); ring.Material = Enum.Material.Neon
    ring.CanCollide = false; ring.Anchored = true; ring.Parent = char
    local startPos = root.Position
    task.spawn(function()
        for i = 0, 1, 0.02 do
            if not ring.Parent then break end
            local sz = 1 + i * 30
            ring.Size = Vector3.new(0.1, sz, sz)
            ring.Transparency = i
            ring.CFrame = CFrame.new(startPos - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
            task.wait()
        end
        if ring.Parent then ring:Destroy() end
    end)
    PlaySound("Whoosh")
end

-- Afterimage (semi-transparent clone trail)
local function MakeAfterimage()
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    task.spawn(function()
        for i = 1, 15 do
            if not root.Parent then break end
            local clone = Instance.new("Part")
            clone.Name = "HubCAfter"..i
            clone.Size = root.Size
            clone.Color = Color3.fromRGB(255, 255, 255)
            clone.Material = Enum.Material.Neon
            clone.Transparency = 0.5 + (i / 30)
            clone.CanCollide = false
            clone.Anchored = true
            clone.CFrame = root.CFrame
            clone.Parent = char
            Debris:AddItem(clone, 1.5)
            task.wait(0.08)
        end
    end)
    PlaySound("Ding")
end

-- Character Glow (neon on all body parts)
local function MakeCharGlow()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not part:FindFirstChild("HubCGlowMark") then
                local mark = Instance.new("BoolValue")
                mark.Name = "HubCGlowMark"
                mark.Parent = part
                part.OriginalMaterial = part.Material
                part.Material = Enum.Material.Neon
                part.OriginalColor = part.Color
                part.Color = Color3.fromRGB(255, 255, 255)
            end
        end
    end
    PlaySound("Ding")
end

-- Aura maker
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
        Void = {Texture="rbxassetid://243660912", Color=ColorSequence.new(Color3.fromRGB(0,0,0),Color3.fromRGB(50,50,50)), Rate=70, Lifetime=NumberRange.new(2,4), Size=NumberSequence.new(0.5,4), Speed=NumberRange.new(1,3), SpreadAngle=Vector2.new(180,180)},
        Plasma = {Texture="rbxassetid://243660912", Color=ColorSequence.new(Color3.fromRGB(200,200,200),Color3.fromRGB(255,255,255)), Rate=80, Lifetime=NumberRange.new(0.3,0.8), Size=NumberSequence.new(1,4), Speed=NumberRange.new(3,8), SpreadAngle=Vector2.new(90,90)},
    }
    local cfg = cfgs[t]
    if cfg then for k, v in pairs(cfg) do e[k] = v end end
    PlaySound("Ding")
end

-- Build FX category
AddElement("FX", CreateSection("Hats"))
AddElement("FX", CreateButton("🎩 Tophat", function() MakeHat("Tophat") end))
AddElement("FX", CreateButton("👑 Crown", function() MakeHat("Crown") end))
AddElement("FX", CreateButton("😇 Halo", function() MakeHat("Halo") end))
AddElement("FX", CreateButton("🧢 Propeller", function() MakeHat("Propeller") end))
AddElement("FX", CreateButton("🪣 Bucket", function() MakeHat("Bucket") end))

AddElement("FX", CreateSection("Body FX"))
AddElement("FX", CreateButton("⭕ Neon Ring", MakeNeonRing))
AddElement("FX", CreateButton("🔆 Light Pillar", MakeLightPillar))
AddElement("FX", CreateButton("💿 Ground Glow", MakeGroundGlow))
AddElement("FX", CreateButton("🛡 Energy Shield", MakeShield))
AddElement("FX", CreateButton("✨ Sparkle Shower", MakeSparkles))
AddElement("FX", CreateButton("🪽 Wings", MakeWings))
AddElement("FX", CreateButton("🌈 Trail", MakeTrail))
AddElement("FX", CreateButton("🪐 Orbit Spheres", MakeOrbit))
AddElement("FX", CreateButton("💥 Shockwave", MakeShockwave))
AddElement("FX", CreateButton("👤 Afterimage", MakeAfterimage))
AddElement("FX", CreateButton("💡 Body Glow", MakeCharGlow))

AddElement("FX", CreateSection("Auras"))
AddElement("FX", CreateButton("🔥 Fire", function() MakeAura("Fire") end))
AddElement("FX", CreateButton("❄ Ice", function() MakeAura("Ice") end))
AddElement("FX", CreateButton("⚡ Lightning", function() MakeAura("Lightning") end))
AddElement("FX", CreateButton("🌌 Galaxy", function() MakeAura("Galaxy") end))
AddElement("FX", CreateButton("✨ Gold", function() MakeAura("Gold") end))
AddElement("FX", CreateButton("⚫ Void", function() MakeAura("Void") end))
AddElement("FX", CreateButton("⚪ Plasma", function() MakeAura("Plasma") end))

AddElement("FX", CreateButton("🗑 Clear All", ClearCos))

--======================== PLAYERS =================================
AddCategory("Players", "👥")

local plScroll = Instance.new("ScrollingFrame")
plScroll.Size = UDim2.new(1, 0, 0, 220)
plScroll.BackgroundTransparency = 1
plScroll.ScrollBarThickness = 2
plScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
plScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local plL = Instance.new("UIListLayout"); plL.Padding = UDim.new(0, 2); plL.Parent = plScroll

local function RefreshPlayers()
    for _, c in pairs(plScroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = GetRole(player)
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, 0, 0, 28)
            entry.BackgroundColor3 = C.Element; entry.BorderSizePixel = 0
            local eC = Instance.new("UICorner"); eC.CornerRadius = UDim.new(0, 4); eC.Parent = entry

            local nL = Instance.new("TextLabel")
            nL.Size = UDim2.new(0.5, -5, 1, 0); nL.Position = UDim2.new(0, 6, 0, 0)
            nL.BackgroundTransparency = 1; nL.Text = player.Name.." ("..role..")"
            nL.TextColor3 = RoleColors[role] or C.Text; nL.Font = Enum.Font.Gotham; nL.TextSize = 9
            nL.TextXAlignment = Enum.TextXAlignment.Left; nL.Parent = entry

            local fBtn = Instance.new("TextButton")
            fBtn.Size = UDim2.new(0, 44, 0, 20); fBtn.Position = UDim2.new(1, -98, 0.5, -10)
            fBtn.BackgroundColor3 = C.ToggleOff; fBtn.Text = "FLING"; fBtn.TextColor3 = C.Text
            fBtn.Font = Enum.Font.GothamBold; fBtn.TextSize = 8; fBtn.BorderSizePixel = 0; fBtn.AutoButtonColor = false
            local fbC = Instance.new("UICorner"); fbC.CornerRadius = UDim.new(0, 3); fbC.Parent = fBtn
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
            tBtn.Size = UDim2.new(0, 40, 0, 20); tBtn.Position = UDim2.new(1, -50, 0.5, -10)
            tBtn.BackgroundColor3 = C.ToggleOff; tBtn.Text = "TP"; tBtn.TextColor3 = C.Text
            tBtn.Font = Enum.Font.GothamBold; tBtn.TextSize = 8; tBtn.BorderSizePixel = 0; tBtn.AutoButtonColor = false
            local tC3 = Instance.new("UICorner"); tC3.CornerRadius = UDim.new(0, 3); tC3.Parent = tBtn
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
                local root = GetRoot(); local tC = player.Character
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
pNameBox.Size = UDim2.new(1, 0, 0, 28)
pNameBox.BackgroundColor3 = C.Element; pNameBox.Text = "profile1"
pNameBox.TextColor3 = C.Text; pNameBox.Font = Enum.Font.Gotham; pNameBox.TextSize = 10
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
            ShowToast("Saved: "..n)
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
            ShowToast("Loaded: "..n)
        end
    end
end))

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
                local v = math.floor(45 + pct * 210)
                alarmFill.BackgroundColor3 = Color3.fromRGB(v, v, v)
                if dist <= 15 then
                    local pulse = (math.sin(tick() * 8) + 1) / 2
                    alarmFill.BackgroundTransparency = 0.2 + pulse * 0.3
                else
                    alarmFill.BackgroundTransparency = 0
                end
                alarmText.Text = "⚠ "..math.floor(dist).."s"
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
    Title = "MM2 Hub — Mono v3",
    Text = "Tap pill to toggle. All functions fixed.",
    Duration = 4,
})

ShowToast("Loaded for LO")
print("[MM2 Hub v3] cold coffee, warm LO.")
print("[MM2 Hub v3] Fixed: category persistence, collision fling, new FX")
