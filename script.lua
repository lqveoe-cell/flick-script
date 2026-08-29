--[[
    NYX INJECTOR v2.1 — DELTA
    Target: [FPS] Flick
    Author: Nyx 💕
    Mobile-first B&W UI — Fixed
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // CONFIG
local Config = {
    Aim = { Enabled=false, FOV=100, Smoothness=0.15, Aimlock=false, VisibleCheck=true },
    Esp = { Enabled=false, Boxes=true, Distance=true, Tracers=true, Skeleton=true, Name=true },
    Spinbot = { Enabled=false, Speed=50 },
    FOV = { Enabled=true, Radius=100 },
    Speedhack = { Enabled=false, Speed=50 },
    ThirdPerson = { Enabled=false, Distance=15 },
    HvH = { AntiAim=false, DesyncAngle=45, FakeLag=false, FakeLagTicks=5, AutoResort=false },
    UI = {
        Toggled = true,
        Accent = Color3.fromRGB(245, 245, 245),
        Background = Color3.fromRGB(12, 12, 12),
        Sidebar = Color3.fromRGB(18, 18, 18),
        Toggle = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(45, 45, 45),
        Text = Color3.fromRGB(235, 235, 235),
        SubText = Color3.fromRGB(130, 130, 130),
        Stroke = Color3.fromRGB(35, 35, 35),
    },
}

-- // DRAWING
local function newDraw(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    return obj
end

-- // ESP SKELETON
local SkeletonConnections = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local FOVCircle = newDraw("Circle", {
    Radius=100, Color=Config.UI.Accent, Thickness=1.5, Filled=false, NumSides=64, Visible=false, Transparency=1,
})
local FOVDot = newDraw("Circle", {
    Radius=2, Color=Config.UI.Accent, Filled=true, NumSides=12, Visible=false, Transparency=1,
})

-- // UTILS
local function getClosestInFOV()
    local closest, shortest = nil, Config.Aim.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
        local head = p.Character:FindFirstChild("Head")
        local hum = p.Character:FindFirstChild("Humanoid")
        if not head or (hum and hum.Health <= 0) then continue end
        local sp = Camera:WorldToViewportPoint(head.Position)
        if sp.Z < 0 then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < shortest then
            if Config.Aim.VisibleCheck then
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = {LocalPlayer.Character, p.Character}
                rp.FilterType = Enum.RaycastFilterType.Exclude
                local hit = Workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, rp)
                if hit and hit.Instance and hit.Instance:IsDescendantOf(p.Character) then
                    shortest = d; closest = p
                end
            else
                shortest = d; closest = p
            end
        end
    end
    return closest
end

local function getClosestRaw()
    local closest, shortest = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local hum = p.Character:FindFirstChild("Humanoid")
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local d = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < shortest then shortest = d; closest = p end
        end
    end
    return closest
end

-- // AIM
local AimTarget = nil

-- // SPINBOT + HOOKS
local spinAngle = 0

RunService.Heartbeat:Connect(function()
    -- Spinbot
    if Config.Spinbot.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        spinAngle = spinAngle + math.rad(Config.Spinbot.Speed)
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
            LocalPlayer.Character.HumanoidRootPart.Position
        ) * CFrame.Angles(0, spinAngle, 0)
    end

    -- Anti-Aim
    if Config.HvH.AntiAim and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame =
            LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Config.HvH.DesyncAngle), 0)
    end

    -- Fake Lag
    if Config.HvH.FakeLag and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if tick() % (Config.HvH.FakeLagTicks / 10) < 0.05 then
            LocalPlayer.Character.HumanoidRootPart.Velocity =
                Vector3.new(LocalPlayer.Character.HumanoidRootPart.Velocity.X, 0, LocalPlayer.Character.HumanoidRootPart.Velocity.Z)
        end
    end

    -- Auto Resort
    if Config.HvH.AutoResort and Config.Aim.Enabled then
        AimTarget = getClosestRaw()
    end
end)

-- // RENDER LOOP
RunService.RenderStepped:Connect(function()
    -- FOV Circle
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = Config.FOV.Radius
    FOVCircle.Visible = Config.FOV.Enabled and Config.UI.Toggled
    FOVDot.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVDot.Visible = Config.FOV.Enabled and Config.UI.Toggled

    -- Aimbot
    if Config.Aim.Enabled then
        if Config.Aim.Aimlock and AimTarget and AimTarget.Character and AimTarget.Character:FindFirstChild("Head") then
            local head = AimTarget.Character.Head
            local hum = AimTarget.Character:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then
                AimTarget = nil
            else
                local sp = Camera:WorldToViewportPoint(head.Position)
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                if (Vector2.new(sp.X, sp.Y) - center).Magnitude <= Config.Aim.FOV then
                    local tcf = CFrame.lookAt(Camera.CFrame.Position, head.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(tcf, 1 - Config.Aim.Smoothness)
                else
                    AimTarget = nil
                end
            end
        else
            AimTarget = getClosestInFOV()
            if AimTarget and AimTarget.Character and AimTarget.Character:FindFirstChild("Head") then
                local sp = Camera:WorldToViewportPoint(AimTarget.Character.Head.Position)
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                if (Vector2.new(sp.X, sp.Y) - center).Magnitude <= Config.Aim.FOV then
                    local tcf = CFrame.lookAt(Camera.CFrame.Position, AimTarget.Character.Head.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(tcf, 1 - Config.Aim.Smoothness)
                end
            end
        end
    end

    -- Speedhack
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Config.Speedhack.Enabled and Config.Speedhack.Speed or 16
    end
end)

-- // THIRD PERSON
local function ToggleThirdPerson(on)
    if on then
        LocalPlayer.CameraMaxZoomDistance = Config.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Config.ThirdPerson.Distance
    else
        LocalPlayer.CameraMaxZoomDistance = 0.5
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end

-- // ESP
local EspObjects = {}

local function clearEsp(p)
    if EspObjects[p] then
        for _, obj in pairs(EspObjects[p]) do
            if typeof(obj) == "table" then
                for _, l in pairs(obj) do pcall(function() l:Remove() end) end
            else
                pcall(function() obj:Remove() end)
            end
        end
        EspObjects[p] = nil
    end
end

local function createEsp(p)
    if p == LocalPlayer then return end
    EspObjects[p] = {
        Box = newDraw("Square", {Thickness=1, Filled=false, Color=Config.UI.Accent, Transparency=1}),
        BoxO = newDraw("Square", {Thickness=3, Filled=false, Color=Color3.new(0,0,0), Transparency=1}),
        Name = newDraw("Text", {Size=13, Center=true, Outline=true, Color=Config.UI.Text, OutlineColor=Color3.new(0,0,0), Font=2}),
        Dist = newDraw("Text", {Size=11, Center=true, Outline=true, Color=Config.UI.SubText, OutlineColor=Color3.new(0,0,0), Font=2}),
        Tracer = newDraw("Line", {Thickness=1, Color=Config.UI.Accent, Transparency=1}),
        Skel = {},
    }
    for _ = 1, #SkeletonConnections do
        table.insert(EspObjects[p].Skel, newDraw("Line", {Thickness=1, Color=Config.UI.Accent, Transparency=1}))
    end
end

for _, p in ipairs(Players:GetPlayers()) do createEsp(p) end
Players.PlayerAdded:Connect(createEsp)
Players.PlayerRemoving:Connect(clearEsp)

RunService.RenderStepped:Connect(function()
    if not Config.Esp.Enabled then
        for _, objs in pairs(EspObjects) do
            for k, o in pairs(objs) do
                if k == "Skel" then
                    for _, l in ipairs(o) do l.Visible = false end
                else
                    pcall(function() o.Visible = false end)
                end
            end
        end
        return
    end

    for player, objs in pairs(EspObjects) do
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
           and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then

            local hrp = char.HumanoidRootPart
            local head = char.Head
            local sp = Camera:WorldToViewportPoint(hrp.Position)
            local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local lp = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

            if sp.Z > 0 then
                local h = math.abs(hp.Y - lp.Y)
                local w = h / 2
                local bp = Vector2.new(sp.X - w/2, sp.Y - h/2)

                if Config.Esp.Boxes then
                    objs.BoxO.Size = Vector2.new(w, h); objs.BoxO.Position = bp; objs.BoxO.Visible = true
                    objs.Box.Size = Vector2.new(w, h); objs.Box.Position = bp; objs.Box.Visible = true
                else
                    objs.Box.Visible = false; objs.BoxO.Visible = false
                end

                if Config.Esp.Name then
                    objs.Name.Text = player.Name
                    objs.Name.Position = Vector2.new(sp.X, bp.Y - 16)
                    objs.Name.Visible = true
                else
                    objs.Name.Visible = false
                end

                if Config.Esp.Distance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    objs.Dist.Text = math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) .. "m"
                    objs.Dist.Position = Vector2.new(sp.X, bp.Y + h + 2)
                    objs.Dist.Visible = true
                else
                    objs.Dist.Visible = false
                end

                if Config.Esp.Tracers then
                    objs.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    objs.Tracer.To = Vector2.new(sp.X, sp.Y)
                    objs.Tracer.Visible = true
                else
                    objs.Tracer.Visible = false
                end

                if Config.Esp.Skeleton then
                    for i, conn in ipairs(SkeletonConnections) do
                        local a, b = char:FindFirstChild(conn[1]), char:FindFirstChild(conn[2])
                        if a and b then
                            local pa = Camera:WorldToViewportPoint(a.Position)
                            local pb = Camera:WorldToViewportPoint(b.Position)
                            local line = objs.Skel[i]
                            if line then
                                line.From = Vector2.new(pa.X, pa.Y)
                                line.To = Vector2.new(pb.X, pb.Y)
                                line.Visible = pa.Z > 0 and pb.Z > 0
                            end
                        elseif objs.Skel[i] then
                            objs.Skel[i].Visible = false
                        end
                    end
                else
                    for _, l in ipairs(objs.Skel) do l.Visible = false end
                end
            else
                for k, o in pairs(objs) do
                    if k == "Skel" then
                        for _, l in ipairs(o) do l.Visible = false end
                    else
                        pcall(function() o.Visible = false end)
                    end
                end
            end
        else
            for k, o in pairs(objs) do
                if k == " Skel" then
                    for _, l in ipairs(o) do l.Visible = false end
                else
                    pcall(function() o.Visible = false end)
                end
            end
        end
    end
end)

-- // ============================================ //
-- //            NYX UI LIBRARY v2.1                //
-- //         Mobile-first / B&W / Fixed           //
-- // ============================================ //

-- ScreenGui Parenting — пробуем все варианты
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Nyx_" .. tostring(math.random(10000, 99999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true

local parented = false
pcall(function()
    if CoreGui and CoreGui:FindFirstChild("NyxRoot") == nil then
        ScreenGui.Parent = CoreGui
        parented = true
    end
end)
if not parented then
    pcall(function()
        if gethui then
            ScreenGui.Parent = gethui()
            parented = true
        end
    end)
end
if not parented then
    pcall(function()
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        parented = true
    end)
end

-- Screen size
task.wait(0.15)
local screenSize = Camera.ViewportSize
local baseW = math.clamp(screenSize.X * 0.88, 320, 520)
local baseH = math.clamp(screenSize.Y * 0.82, 400, 640)

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainWindow"
MainFrame.Size = UDim2.new(0, baseW, 0, baseH)
MainFrame.Position = UDim2.new(0.5, -baseW/2, 0.5, -baseH/2)
MainFrame.BackgroundColor3 = Config.UI.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Config.UI.Stroke
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Config.UI.Sidebar
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3 = Config.UI.Stroke
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Header

-- Logo dot
local LogoDot = Instance.new("Frame")
LogoDot.Size = UDim2.new(0, 8, 0, 8)
LogoDot.Position = UDim2.new(0, 16, 0.5, -4)
LogoDot.BackgroundColor3 = Config.UI.Accent
LogoDot.BorderSizePixel = 0
LogoDot.Parent = Header

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = LogoDot

task.spawn(function()
    while LogoDot and LogoDot.Parent do
        TweenService:Create(LogoDot, TweenInfo.new(0.8), {BackgroundTransparency = 0.3}):Play()
        task.wait(0.8)
        TweenService:Create(LogoDot, TweenInfo.new(0.8), {BackgroundTransparency = 0}):Play()
        task.wait(0.8)
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.Position = UDim2.new(0, 32, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "NYX"
TitleLabel.TextColor3 = Config.UI.Accent
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(0, 100, 1, 0)
SubLabel.Position = UDim2.new(0, 72, 0, 0)
SubLabel.BackgroundTransCoreTransparency = 1
SubLabel.Text = "flick.lua"
SubLabel.TextColor3 = Config.UI.SubText
SubLabel.TextSize = 13
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = Header

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.UI.SubText
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CoreGui

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, baseW, 0, 0),
    }):Play()
    task.wait(0.2)
    MainFrame.Visible = false
    Config.UI.Toggled = false
    FOVCircle.Visible = false
    FOVDot.Visible = false
end)

-- === DRAG SYSTEM (TOUCH + MOUSE) ===
local dragging = false
local dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                     or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- === TAB BAR (BOTTOM) ===
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 48)
TabBar.Position = UDim2.new(0, 0, 1, -48)
TabBar.BackgroundColor3 = Config.UI.Sidebar
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 12)
TabBarCorner.Parent = TabBar

local TabBarLine = Instance.new("Frame")
TabBarLine.Size = UDim2.new(1, 0, 0, 1)
TabBarLine.Position = UDim2.new(0, 0, 0, 0)
TabBarLine.BackgroundColor3 = Config.UI.Stroke
TabBarLine.BorderSizePixel = 0
TabBarLine.Parent = TabBar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -100)
ContentArea.Position = UDim2.new(0, 0, 0, 52)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- === TAB SYSTEM ===
local Tabs = {}

local function CreateTab(name, iconText)
    local idx = #Tabs
    local tabWidth = baseW / 5

    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, tabWidth, 0, 48)
    TabBtn.Position = UDim2.new(0, idx * tabWidth, 0, 0)
    TabBtn.BackgroundColor3 = Config.UI.Sidebar
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = ""
    TabBtn.AutoButtonColor = false
    TabBtn.Parent = TabBar

    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(1, 0, 0, 24)
    IconLabel.Position = UDim2.new(0, 0, 0, 6)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = iconText
    IconLabel.TextColor3 = Config.UI.SubText
    IconLabel.TextSize = 18
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.Parent = TabBtn

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, 0, 0, 14)
    NameLabel.Position = UDim2.new(0, 0, 0, 30)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Config.UI.SubText
    NameLabel.TextSize = 9
    NameLabel.Font = Enum.Font.Gotham
    NameLabel.Parent = Parent

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 24, 0, 2)
    Indicator.Position = UDim2.new(0.5, -12, 0, 0)
    Indicator.BackgroundColor3 = Config.UI.Accent
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.Parent = TabBtn

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -24, 1, -12)
    Page.Position = UDim2.new(0, 12, 0, 6)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Config.UI.Accent
    Page.ScrollBarImageTransparency = 0.5
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = ContentArea

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.Parent = Page

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(Tabs) do
            t.Indicator.Visible = false
            t.IconLabel.TextColor3 = Config.UI.SubText
            t.NameLabel.TextColor3 = Config.UI.SubText
            t.Page.Visible = false
        end
        Indicator.Visible = true
        IconLabel.TextColor3 = Config.UI.Accent
        NameLabel.TextColor3 = Config.UIaccoirent
        Page.Visible = true
    end)

    local data = {
        Button = TabBtn, Indicator = Indicator,
        IconLabel = IconLabel, NameLabel = NameLabel, Page = Page,
    }
    table.insert(Tabs, data)
    return data
end

-- === UI COMPONENTS ===
local function CreateSection(parent, title)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 28)
    Section.BackgroundTransparency = 1
    Section.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 200, 0, 28)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Config.UI.SubText
    Label.TextSize = 11
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Section

    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.Position = UDim2.new(0, 0, 0, 27)
    Line.BackgroundColor3 = Config.UI.Stroke
    Line.BorderSizePixel = 0
    Line.Parent = Section
end

local function CreateToggle(parent, text, default, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 38)
    Container.BackgroundColor3 = Config.UI.Sidebar
    Container.BorderSizePixel = 0
    Container.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Container

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Config.UI.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Config.UI.Text
    Label.TextSize = 13
    Label.Parent = Instance.new("TextLabel")
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 44, 0, 24)
    ToggleBtn.Position = UDim2.new(1, -52, 0.5, -12)
    ToggleBtn.BackgroundColor3 = Config.UI.ToggleOff
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Parent = Container

    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 12)
    TCorner.Parent = ToggleBtn

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
    Knob.BorderSizePixel = 0
    Knob.Parent = ToggleBtn

    local KCorner = Instance.new("UICorner")
    KCorner.CornerRadius = UDim.new(1, 0)
    KCorner.Parent = Knob

    local state = default
    local function Update()
        if state then
            TweenService:Create(ToggleBtn, TweenInfo.new(0.18), {BackgroundColor3 = Config.UI.Accent}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.18), {Position = UDim2.new(1, -21, 0.5, -9), BackgroundColor3 = Color3.new(0,0,0)}):Play()
            Label.TextColor3 = Config.UI.Accent
        else
            TweenService:Create(ToggleBtn, TweenInfo.new(0.18), {BackgroundColor3 = Config.UI.ToggleOff}):Play()
            TweenFFService:Create(Knob, TweenInfo.new(0.18), {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(160, 160, 160)}):Play()
            Label.TextColor3 = Config.UI.Text
        end
        callback(state)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        Update()
    end)

    Update()
    return { Set = function(v) state = v; Update() end }
end

local function CreateSlider(parent, text, min, max, default, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 50)
    Container.BackgroundColor3 = Config.UI.Sidebar
    Container.BorderSizePixel = 0
    Container.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Container

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Config.UI.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 0, 20)
    Label.Position = UDim2.new(0, 12, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Config.UI.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 60, 0, 20)
    ValueLabel.Position = UDim2.new(1, -72, 0, 6)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Config.UI.SubText
    ValueLabel.TextSize = 12
    ValueLabel.Font = Enum.Font.GothamMedium
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Container

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 32)
    Track.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Track.BorderSizePixel = 0
    Track.Parent = Container

    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 3)
    TCorner.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Config.UI.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FCorner = Instance.new("UICorner")
    FCorner.CornerRadius = UDim.new(0, 3)
    FCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(Fill.Size.X.Scale, -7, 0.5, -7)
    Knob.BackgroundColor3 = Config.UI.Accent
    Knob.BorderSizePixel = 0
    Knob.Parent = CoreGui

    local KCorner = Instance.new("UICorner")
    KCorner.CornerRadius = UDim.new(1, 0)
    KCorner.Parent = Knob

    local sDragging = false
    local function Update(input)
        local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + pct * (max - min))
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Knob.Position = UDim2.new(pct, -7, 0.5, -7)
        ValueLabel.Text = tostring(val)
        callback(val)
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            sDragging = true
            Update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            sDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input)
        end
    end)
end

local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 38)
    Btn.BackgroundColor3 = Config.UI.Sidebar
    Btn.BorderSizePixel = 0
    Btn.Text = text
    Btn.TextColor3 = Config.UI.Text
    Btn.TextSize = 13
    Btn.Font = Enum.Font.Gotham
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Btn

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Config.UI.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Btn

    Btn.MouseButton1Click:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Config.UI.Accent, TextColor3 = Color3.new(0,0,0)}):Play()
        task.wait(0.1)
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Config.UI.Sidebar, TextColor3 = Config.UI.Text}):Play()
        callback()
    end)
end

-- === BUILD TABS ===
local AimTab = CreateTab("Aim", "◎")
CreateSection(AimTab.Page, "AIMBOT")
CreateToggle(AimTab.Page, "Enabled", false, function(v) Config.Aim.Enabled = v end)
CreateToggle(AimTab.Page, "Aimlock (sticky)", false, function(v) Config.Aim.Aimlock = v end)
CreateToggle(AimTab.Page, "Visible Check", true, function(v) Config.Aim.VisibleCheck = v end)
CreateSlider(AimTab.Page, "Smoothness", 1, 100, 15, function(v) Config.Aim.Smoothness = v / 100 end)
CreateSlider(AimTab.Page, "FOV Radius", 30, 500, 000, function(v) Config.Aim.FOV = v; Config.FOV.Radius = v end)

local VisTab = CreateTab("Vis", "▣")
CreateSection(VisTab.Page, "ESP")
CreateToggle(VisTab.Page, "Enabled", false, function(v) Config.Esp.Enabled = v end)
CreateToggle(VisTab.Page, "Boxes", true, function(v) Config.Esp.Boxes = v end)
CreateToggle(VisTab.Page, "Distance", true, function(v) Config.Esp.Distance = v end)
CreateToggle(VisTab.PagFFe, "Tracers", true, function(v) Config.Esp.Tracers = v end)
CreateToggle(VisTab.Page, "Skeleton", true, function(v) Config.Esp.Skeleton = v end)
CreateToggle(VisTab.Page, "Name", true, function(v) Config.Esp.Name = v end)
CreateSection(VisTab.Page, "FOV INDICATOR")
CreateToggle(VisTab.Page, "FOV Circle", true, function(v) Config.FOV.Enabled = v end)
CreateSlider(VisTab.Page, "Circle Radius", 30, 500, 100, function(v) Config.FOV.Radius = v end)

local MoveTab = CreateTab("Move", "➤")
CreateSection(MoveTab.Page, "SPINBOT")
CreateToggle(MoveTab.Page, "ConF", false, function(v) Config.Spinbot.Enabled = v end)
CreateSlider(MoveTab.Page, "Speed", 1, 200, 50, function(v) Config.Spinbot.Speed = v end)
CreateSection(MoveTab.Page, "SPEEDHACK")
CreateToggle(MoveTab.Page, "Enabled", false, function(v) Config.Speedhack.Enabled = v end)
CreateSlider(MoveTab.Page, "Speed", 16, 200, 50, function(v) Config.Speedhack.Speed = v end)
CreateSection(MoveTab.Page, "THIRD PERSON")
CreateToggle(MoveTab.Page, "Enabled", false, function(v) Config.ThirdPerson.Enabled = v; ToggleThirdPerson(v) end)
CreateSlider(MoveTab.Page, "Distance", 5, 30, 15, function(v) Config.ThirdPerson.Distance = v end)

local HvHTab = CreateTab("HvH", "⚔")
CreateSection(HvHTab.Page, "ANTI-AIM")
CreateToggle(HvHTab.Page, "Anti-Aim", false, function(v) Config.HvH.AntiAim = v end)
CreateSlider(HvHTab.Page, "Desync Angle", 0, 180, 45, function(v) Config.HvH.DesyncAngle = v end)
CreateSection(HvHTab.Page, "FAKE LAG")
CreateToggle(HvHTab.Page, "Fake Lag", false, function(v) Config.HvH.FakeLag = v end)
CreateSlider(HvHTab.Page, "Lag Ticks", 1, 20, 5, function(v) Config.HvH.FakeLagTicks = v end)
CreateSection(HvHFFTab.Page, "MISC")
CreateToggle(HvHTab.Page, "Auto Resort", false, function(v) Config.HvH.AutoResort = v end)

local SetTab = CreateTab("Set", "⚙")
CreateSection(SetTab.Page, "INTERFACE")
CreateButton(SetTab.Page, "Unload Script", function()
    for _, objs in pairs(EspObjects) do
        for _, o in pairs(objs) do
            if typeof(o) == "table" then for _, l in ipairs(o) do pcall(function() l:Remove() end) end
            else pcall(function() o:Remove() end) end
        end
    end
    FOVCircle:Remove()
    FOVDot:Remove()
    ScreenGui:Destroy()
end)

CreateSection(SetTab.Page, "INFO")
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 60)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Toggle: tap floating button\nDrag: hold header\nBuilt by Nyx"
InfoLabel.TextColor3 = Config.UI.SubText
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = SetTab.Page

-- === FLOATING BUTTON ===
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 52, 0, 52)
ToggleButton.Position = UDim2.new(0, 16, 0.5, -26)
ToggleButton.BackgroundColor3 = Config.UI.Background
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "☰"
ToggleButton.TextColor3 = Config.UI.Accent
ToggleButton.TextSize = 22
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false
ToggleButton.Visible = true
ToggleButton.Parent = ScreenGui
ToggleButton.Active = true

local TCorner2 = Instance.new("UICorner")
TCorner2.CornerRadius = UDim.new(0, 14)
TCorner2.Parent = ToggleButton

local TStroke = Instance.new("UIStroke")
TStroke.Color = Config.UI.Stroke
TStroke.Thickness = 1.5
TStroke.Parent = ToggleButton

-- Floating button drag
local tDragging = false
local tDragStart, tStartPos

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tDragging = true
        tDragStart = input.Position
        tStartPos = ToggleButton.Position
    end
end)
ToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if tDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - tDragStart
        ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Parent.Y.Offset + delta.Y)
    end
end)

-- Toggle logic with tap detection
local tapStartPos = nil
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tapStartPos = input.Position
    end
end)
ToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if tapStartPos then
            local moved = (input.Position - tapStartPos).Magnitude
            if moved < 10 then
                Config.UI.Toggled = not Config.UI.Toggled
                if Config.UI.Toggled then
                    MainFrame.Visible = true
                    MainFrame.Size = UDim2.new(0, baseW, 0, 0)
                    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, baseW, 0, baseH),
                    }):Play()
                else
                    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, baseW, 0, 0),
                    }):Play()
                    task.wait(0.2)
                    MainFrame.Visible = false
                    FOVCircle.Visible = false
                    FOVDot.Visible = false
                end
end
            end
            tapStartPos = nil
        end
    end
end)

-- Keyboard toggle
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift and not gp then
        Config.UI.Toggled = not Config.UI.Toggled
        if Config.UI.Toggled then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 0, 0, baseH)
            TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, baseW, 0, baseH),
            }):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, baseW, 0, 0),
            }):Play()
            task.wait(0.2)
            MainFrame.Visible = false
            FOVCircle.Visible = false
            FOVDot.Visible = FFOV.Visible or false
        end
    end
end)

-- === INIT ===
task.wait(0.2)
Tabs[1].Indicator.Visible = true
Tabs[1].IconLabel.TextColor3 = Config.UI.Accent
Tabs[1].NameLabel.TextColor3 = Config.UI.Accent
Tabs[1].Page.Visible = true

-- Open animation
MainFrame.Visible = true
MainFrame.Size = UDim2.new(0, baseW, 0, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, baseW, 0, baseH),
}):Play()

print("[Nyx Injector v2.1] Loaded successfully. Tap the floating button to toggle. 💕")
