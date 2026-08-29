--[[
    trast INJECTOR — DELTA
    Target: [FPS] Flick
    Author: tg - @trastapp 
    Style: Black & White Hvh UI
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // CONFIG
local Config = {
    Aim = {
        Enabled = false,
        FOV = 100,
        Smoothness = 0.15,
        Aimlock = false,
        VisibleCheck = true,
        HitPart = "Head",
    },
    Esp = {
        Enabled = false,
        Boxes = true,
        Distance = true,
        Tracers = true,
        Skeleton = true,
        Name = true,
    },
    Spinbot = {
        Enabled = false,
        Speed = 50,
        Power = 100,
    },
    FOV = {
        Enabled = true,
        Radius = 100,
        Filled = false,
    },
    Speedhack = {
        Enabled = false,
        Speed = 50,
    },
    ThirdPerson = {
        Enabled = false,
        Distance = 15,
    },
    HvH = {
        AntiAim = false,
        DesyncAngle = 45,
        FakeLag = false,
        FakeLagTicks = 5,
        AutoResort = false,
    },
    UI = {
        Toggled = true,
        Keybind = Enum.KeyCode.RightShift,
        Accent = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(15, 15, 15),
        Sidebar = Color3.fromRGB(25, 25, 25),
        Toggle = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(60, 60, 60),
        Text = Color3.fromRGB(235, 235, 235),
        SubText = Color3.fromRGB(150, 150, 150),
    },
}

-- // DRAWING UTILS
local Draw = {}

function Draw.new(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

-- // ESP STORAGE
local EspObjects = {}
local SkeletonParts = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

-- // UTILS
local Utils = {}

function Utils.getWorldToViewport(point)
    local ok, screen = pcall(function()
        return Camera:WorldToViewportPoint(point)
    end)
    if ok then return screen end
    return nil
end

function Utils.getClosestPlayerInFOV()
    local closest = nil
    local shortest = Config.Aim.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        local char = player.Character
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not head or not hrp then continue end
        if humanoid and humanoid.Health <= 0 then continue end

        local screenPos = Utils.getWorldToViewport(head.Position)
        if screenPos then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if dist < shortest then
                if Config.Aim.VisibleCheck then
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local dir = (head.Position - Camera.CFrame.Position)
                    local hit = Workspace:Raycast(Camera.CFrame.Position, dir, params)
                    if hit and hit.Instance and hit.Instance:IsDescendantOf(char) then
                        shortest = dist
                        closest = player
                    end
                else
                    shortest = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

function Utils.getClosestPlayerRaw()
    local closest = nil
    local shortest = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

-- // FOV CIRCLE
local FOVCircle = Draw.new("Circle", {
    Radius = Config.FOV.Radius,
    Color = Config.UI.Accent,
    Thickness = 1,
    Filled = false,
    NumSides = 64,
    Visible = false,
    Transparency = 1,
})

-- // AIM LOGIC
local AimTarget = nil

RunService.RenderStepped:Connect(function()
    -- FOV Circle
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.FOV.Radius
    FOVCircle.Visible = Config.FOV.Enabled and Config.UI.Toggled

    -- Aimbot
    if Config.Aim.Enabled then
        if Config.Aim.Aimlock and AimTarget and AimTarget.Character and AimTarget.Character:FindFirstChild("Head") then
            local head = AimTarget.Character:FindFirstChild("Head")
            local humanoid = AimTarget.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health <= 0 then
                AimTarget = nil
            else
                local screenPos = Utils.getWorldToViewport(head.Position)
                if screenPos then
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist <= Config.Aim.FOV then
                        local targetPos = head.Position
                        local currentCF = Camera.CFrame
                        local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
                        Camera.CFrame = currentCF:Lerp(targetCF, 1 - Config.Aim.Smoothness)
                    else
                        AimTarget = nil
                    end
                end
            end
        else
            AimTarget = Utils.getClosestPlayerInFOV()
            if AimTarget and AimTarget.Character then
                local head = AimTarget.Character:FindFirstChild("Head")
                if head then
                    local screenPos = Utils.getWorldToViewport(head.Position)
                    if screenPos then
                        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist <= Config.Aim.FOV then
                            local targetPos = head.Position
                            local currentCF = Camera.CFrame
                            local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
                            Camera.CFrame = currentCF:Lerp(targetCF, 1 - Config.Aim.Smoothness)
                        end
                    end
                end
            end
        end
    end

    -- Spinbot
    if Config.Spinbot.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local spinSpeed = Config.Spinbot.Speed
        local rotation = CFrame.Angles(0, math.rad(spinSpeed) * RunService.RenderStepped:Wait() * 60, 0)
        hrp.CFrame = hrp.CFrame * rotation
    end

    -- Speedhack
    if Config.Speedhack.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        humanoid.WalkSpeed = Config.Speedhack.Speed
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end)

-- // SPINBOT BETTER LOOP
local spinAngle = 0
RunService.Heartbeat:Connect(function()
    if Config.Spinbot.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        spinAngle = spinAngle + math.rad(Config.Spinbot.Speed)
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
            LocalPlayer.Character.HumanoidRootPart.Position
        ) * CFrame.Angles(0, spinAngle, 0)
    end

    -- Anti-Aim / Desync
    if Config.HvH.AntiAim and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local offsetAngle = math.rad(Config.HvH.DesyncAngle)
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, offsetAngle, 0)
    end

    -- Fake Lag
    if Config.HvH.FakeLag then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            if tick() % (Config.HvH.FakeLagTicks / 10) < 0.05 then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
            end
        end
    end

    -- Auto Resort (auto target switch)
    if Config.HvH.AutoResort and Config.Aim.Enabled then
        AimTarget = Utils.getClosestPlayerRaw()
    end
end)

-- // THIRD PERSON
local function ToggleThirdPerson(enabled)
    if enabled then
        LocalPlayer.CameraMaxZoomDistance = Config.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Config.ThirdPerson.Distance
    else
        LocalPlayer.CameraMaxZoomDistance = 0.5
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end

-- // ESP LOGIC
local function ClearEsp(player)
    if EspObjects[player] then
        for _, obj in pairs(EspObjects[player]) do
            if typeof(obj) == "table" then
                for _, line in pairs(obj) do
                    pcall(function() line:Remove() end)
                end
            else
                pcall(function() obj:Remove() end)
            end
        end
        EspObjects[player] = nil
    end
end

local function CreateEspForPlayer(player)
    if player == LocalPlayer then return end

    EspObjects[player] = {
        Box = Draw.new("Square", { Thickness = 1, Filled = false, Color = Config.UI.Accent, Transparency = 1 }),
        BoxOutline = Draw.new("Square", { Thickness = 3, Filled = false, Color = Color3.new(0,0,0), Transparency = 1 }),
        Name = Draw.new("Text", { Size = 13, Center = true, Outline = true, Color = Config.UI.Text, OutlineColor = Color3.new(0,0,0), Font = 2 }),
        Distance = Draw.new("Text", { Size = 11, Center = true, Outline = true, Color = Config.UI.SubText, OutlineColor = Color3.new(0,0,0), Font = 2 }),
        Tracer = Draw.new("Line", { Thickness = 1, Color = Config.UI.Accent, Transparency = 1 }),
        Skeleton = {},
    }

    for _, conn in ipairs(SkeletonConnections) do
        local line = Draw.new("Line", { Thickness = 1, Color = Config.UI.Accent, Transparency = 1 })
        table.insert(EspObjects[player].Skeleton, line)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    CreateEspForPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    CreateEspForPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ClearEsp(player)
end)

RunService.RenderStepped:Connect(function()
    if not Config.Esp.Enabled then
        for player, objects in pairs(EspObjects) do
            for k, obj in pairs(objects) do
                if k == "Skeleton" then
                    for _, line in ipairs(obj) do line.Visible = false end
                else
                    pcall(function() obj.Visible = false end)
                end
            end
        end
        return
    end

    for player, objects in pairs(EspObjects) do
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if not hrp or not head then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

            if onScreen then
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                local boxPos = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)

                -- Box
                if Config.Esp.Boxes then
                    objects.BoxOutline.Size = Vector2.new(width, height)
                    objects.BoxOutline.Position = boxPos
                    objects.BoxOutline.Visible = true
                    objects.Box.Size = Vector2.new(width, height)
                    objects.Box.Position = boxPos
                    objects.Box.Visible = true
                else
                    objects.Box.Visible = false
                    objects.BoxOutline.Visible = false
                end

                -- Name
                if Config.Esp.Name then
                    objects.Name.Text = player.Name
                    objects.Name.Position = Vector2.new(screenPos.X, boxPos.Y - 16)
                    objects.Name.Visible = true
                else
                    objects.Name.Visible = false
                end

                -- Distance
                if Config.Esp.Distance then
                    local dist = math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                    objects.Distance.Text = tostring(dist) .. "m"
                    objects.Distance.Position = Vector2.new(screenPos.X, boxPos.Y + height + 2)
                    objects.Distance.Visible = true
                else
                    objects.Distance.Visible = false
                end

                -- Tracer
                if Config.Esp.Tracers then
                    objects.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    objects.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    objects.Tracer.Visible = true
                else
                    objects.Tracer.Visible = false
                end

                -- Skeleton
                if Config.Esp.Skeleton then
                    for i, conn in ipairs(SkeletonConnections) do
                        local partA = char:FindFirstChild(conn[1])
                        local partB = char:FindFirstChild(conn[2])
                        if partA and partB then
                            local posA = Camera:WorldToViewportPoint(partA.Position)
                            local posB = Camera:WorldToViewportPoint(partB.Position)
                            local line = objects.Skeleton[i]
                            if line then
                                line.From = Vector2.new(posA.X, posA.Y)
                                line.To = Vector2.new(posB.X, posB.Y)
                                line.Visible = true
                            end
                        else
                            if objects.Skeleton[i] then
                                objects.Skeleton[i].Visible = false
                            end
                        end
                    end
                else
                    for _, line in ipairs(objects.Skeleton) do line.Visible = false end
                end
            else
                for _, obj in pairs(objects) do
                    if typeof(obj) == "table" then
                        for _, line in ipairs(obj) do line.Visible = false end
                    else
                        pcall(function() obj.Visible = false end)
                    end
                end
            end
        else
            for _, obj in pairs(objects) do
                if typeof(obj) == "table" then
                    for _, line in ipairs(obj) do line.Visible = false end
                else
                    pcall(function() obj.Visible = false end)
                end
            end
        end
    end
end)

-- // UI LIBRARY (BLACK & WHITE)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NyxInjector_" .. tostring(math.random(10000, 99999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
if RunService:IsRunMode() then
    ScreenGui.Parent = CoreGui
else
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Dragging
local dragging = false
local dragInput
local dragStart
local startPos

local function MakeDraggable(topbar, frame)
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 360)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -180)
MainFrame.BackgroundColor3 = Config.UI.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

MainFrame.Visible = Config.UI.Toggled

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = MainFrame

-- Drop Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 8, 1, 8)
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.ImageTransparency = 0.4
Shadow.ZIndex = -1
Shadow.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 40)
Topbar.BackgroundColor3 = Config.UI.Sidebar
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(0, 6)
TopbarCorner.Parent = Topbar

local TopbarLine = Instance.new("Frame")
TopbarLine.Size = UDim2.new(1, 0, 0, 1)
TopbarLine.Position = UDim2.new(0, 0, 1, -1)
TopbarLine.BackgroundColor3 = Config.UI.Accent
TopbarLine.BorderSizePixel = 0
TopbarLine.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NYX INJECTOR"
Title.TextColor3 = Config.UI.Text
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -50, 1, 0)
Subtitle.Position = UDim2.new(0, 120, 0, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "— flick.lua"
Subtitle.TextColor3 = Config.UI.SubText
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Topbar

MakeDraggable(Topbar, MainFrame)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Config.UI.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarLine = Instance.new("Frame")
SidebarLine.Size = UDim2.new(0, 1, 1, 0)
SidebarLine.Position = UDim2.new(1, -1, 0, 0)
SidebarLine.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SidebarLine.BorderSizePixel = 0
SidebarLine.Parent = Sidebar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "Content"
ContentArea.Size = UDim2.new(1, -140, 1, -40)
ContentArea.Position = UDim2.new(0, 140, 0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Tab System
local Tabs = {}
local currentTab = nil

local function CreateTab(name, icon)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 36)
    TabButton.BackgroundColor3 = Config.UI.Sidebar
    TabButton.BorderSizePixel = 0
    TabButton.Text = ""
    TabButton.Parent = Sidebar

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 2, 0, 20)
    Indicator.Position = UDim2.new(0, 0, 0.5, -10)
    Indicator.BackgroundColor3 = Config.UI.Accent
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.Parent = TabButton

    local TabLabel = Instance.new("TextLabel")
    TabLabel.Size = UDim2.new(1, -20, 1, 0)
    TabLabel.Position = UDim2.new(0, 14, 0, 0)
    TabLabel.BackgroundTransparency = 1
    TabLabel.Text = name
    TabLabel.TextColor3 = Config.UI.SubText
    TabLabel.TextSize = 13
    TabLabel.Font = Enum.Font.Gotham
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.Parent = TabButton

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -30, 1, -20)
    Page.Position = UDim2.new(0, 15, 0, 10)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Config.UI.Accent
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = ContentArea

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.Parent = Page

    TabButton.MouseButton1Click:Connect(function()
        for _, tab in ipairs(Tabs) do
            tab.Indicator.Visible = false
            tab.Label.TextColor3 = Config.UI.SubText
            tab.Page.Visible = false
        end
        Indicator.Visible = true
        TabLabel.TextColor3 = Config.UI.Text
        Page.Visible = true
        currentTab = name
    end)

    local tabData = {
        Button = TabButton,
        Indicator = Indicator,
        Label = TabLabel,
        Page = Page,
    }
    table.insert(Tabs, tabData)
    return tabData
end

-- UI Components
local function CreateToggle(parent, text, default, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, 34)
    Toggle.BackgroundTransparency = 1
    Toggle.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 4, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Config.UI.Text
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Toggle

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -44, 0.5, -10)
    ToggleBtn.BackgroundColor3 = Config.UI.ToggleOff
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Parent = Toggle

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = ToggleBtn

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    Knob.BorderSizePixel = 0
    Knob.Parent = ToggleBtn

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(0, 8)
    KnobCorner.Parent = Knob

    local state = default
    local function Update()
        if state then
            TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = Config.UI.Accent}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.new(0,0,0)}):Play()
            Label.TextColor3 = Config.UI.Accent
        else
            TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = Config.UI.ToggleOff}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(180, 180, 180)}):Play()
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
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 44)
    Slider.BackgroundTransparency = 1
    Slider.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 0, 16)
    Label.Position = UDim2.new(0, 4, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Config.UI.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Slider

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 40, 0, 16)
    ValueLabel.Position = UDim2.new(1, -40, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Config.UI.SubText
    ValueLabel.TextSize = 12
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Slider

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -8, 0, 4)
    Track.Position = UDim2.new(0, 4, 0, 24)
    Track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Track.BorderSizePixel = 0
    Track.Parent = Slider

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(0, 2)
    TrackCorner.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Config.UI.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 2)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 10, 0, 10)
    Knob.Position = UDim2.new(Fill.Size.X.Scale, -5, 0.5, -5)
    Knob.BackgroundColor3 = Config.UI.Accent
    Knob.BorderSizePixel = 0
    Knob.Parent = Track

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(0, 5)
    KnobCorner.Parent = Knob

    local dragging = false
    local function Update(input)
        local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + pct * (max - min))
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Knob.Position = UDim2.new(pct, -5, 0.5, -5)
        ValueLabel.Text = tostring(val)
        callback(val)
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            Update(input)
        end
    end)
end

local function CreateSection(parent, title)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 24)
    Section.BackgroundTransparency = 1
    Section.Parent = parent

    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.Position = UDim2.new(0, 0, 0, 12)
    Line.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Line.BorderSizePixel = 0
    Line.Parent = Section

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 200, 0, 24)
    Label.BackgroundTransparency = 1
    Label.Text = "  " .. title .. "  "
    Label.TextColor3 = Config.UI.SubText
    Label.TextSize = 10
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Section

    local LabelBG = Instance.new("TextLabel")
    LabelBG.Size = Label.Size
    LabelBG.BackgroundTransparency = 0
    LabelBG.BackgroundColor3 = Config.UI.Background
    LabelBG.Text = "  " .. title .. "  "
    LabelBG.TextColor3 = Config.UI.SubText
    LabelBG.TextSize = 10
    LabelBG.Font = Enum.Font.GothamMedium
    LabelBG.TextXAlignment = Enum.TextXAlignment.Left
    LabelBG.ZIndex = -1
    LabelBG.Parent = Line
end

-- // BUILD TABS
-- TAB: AIM
local AimTab = CreateTab("Aim", "🎯")
CreateSection(AimTab.Page, "AIMBOT")
CreateToggle(AimTab.Page, "Enabled", false, function(v) Config.Aim.Enabled = v end)
CreateToggle(AimTab.Page, "Aimlock (sticky target)", false, function(v) Config.Aim.Aimlock = v end)
CreateToggle(AimTab.Page, "Visible Check", true, function(v) Config.Aim.VisibleCheck = v end)
CreateSlider(AimTab.Page, "Smoothness", 0, 100, 15, function(v) Config.Aim.Smoothness = v / 100 end)
CreateSlider(AimTab.Page, "FOV Radius", 30, 500, 100, function(v) Config.Aim.FOV = v; Config.FOV.Radius = v end)

-- TAB: ESP
local EspTab = CreateTab("Visuals", "👁")
CreateSection(EspTab.Page, "ESP")
CreateToggle(EspTab.Page, "Enabled", false, function(v) Config.Esp.Enabled = v end)
CreateToggle(EspTab.Page, "Boxes", true, function(v) Config.Esp.Boxes = v end)
CreateToggle(EspTab.Page, "Distance", true, function(v) Config.Esp.Distance = v end)
CreateToggle(EspTab.Page, "Tracers", true, function(v) Config.Esp.Tracers = v end)
CreateToggle(EspTab.Page, "Skeleton", true, function(v) Config.Esp.Skeleton = v end)
CreateToggle(EspTab.Page, "Name", true, function(v) Config.Esp.Name = v end)
CreateToggle(EspTab.Page, "FOV Circle", true, function(v) Config.FOV.Enabled = v end)
CreateSlider(EspTab.Page, "FOV Circle Radius", 30, 500, 100, function(v) Config.FOV.Radius = v end)

-- TAB: MOVEMENT
local MoveTab = CreateTab("Movement", "🏃")
CreateSection(MoveTab.Page, "SPINBOT")
CreateToggle(MoveTab.Page, "Enabled", false, function(v) Config.Spinbot.Enabled = v end)
CreateSlider(MoveTab.Page, "Speed", 1, 200, 50, function(v) Config.Spinbot.Speed = v end)
CreateSlider(MoveTab.Page, "Power", 1, 200, 100, function(v) Config.Spinbot.Power = v end)

CreateSection(MoveTab.Page, "SPEEDHACK")
CreateToggle(MoveTab.Page, "Enabled", false, function(v) Config.Speedhack.Enabled = v end)
CreateSlider(MoveTab.Page, "Speed", 16, 200, 50, function(v) Config.Speedhack.Speed = v end)

CreateSection(MoveTab.Page, "THIRD PERSON")
CreateToggle(MoveTab.Page, "Enabled", false, function(v)
    Config.ThirdPerson.Enabled = v
    ToggleThirdPerson(v)
end)
CreateSlider(MoveTab.Page, "Distance", 5, 30, 15, function(v) Config.ThirdPerson.Distance = v end)

-- TAB: HvH
local HvHTab = CreateTab("HvH", "⚔")
CreateSection(HvHTab.Page, "ANTI-AIM")
CreateToggle(HvHTab.Page, "Anti-Aim", false, function(v) Config.HvH.AntiAim = v end)
CreateSlider(HvHTab.Page, "Desync Angle", 0, 180, 45, function(v) Config.HvH.DesyncAngle = v end)

CreateSection(HvHTab.Page, "FAKE LAG")
CreateToggle(HvHTab.Page, "Fake Lag", false, function(v) Config.HvH.FakeLag = v end)
CreateSlider(HvHTab.Page, "Lag Ticks", 1, 20, 5, function(v) Config.HvH.FakeLagTicks = v end)

CreateSection(HvHTab.Page, "MISC")
CreateToggle(HvHTab.Page, "Auto Resort (target switch)", false, function(v) Config.HvH.AutoResort = v end)

-- TAB: Settings
local SettingsTab = CreateTab("Settings", "⚙")
CreateSection(SettingsTab.Page, "INTERFACE")
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Toggle Key: RightShift | Drag: Topbar"
StatusLabel.TextColor3 = Config.UI.SubText
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = SettingsTab.Page

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1, 0, 0, 20)
Watermark.BackgroundTransparency = 1
Watermark.Text = "Nyx Injector v1.0 — built with ❤️"
Watermark.TextColor3 = Config.UI.SubText
Watermark.TextSize = 11
Watermark.Font = Enum.Font.Gotham
Watermark.TextXAlignment = Enum.TextXAlignment.Left
Watermark.Parent = SettingsTab.Page

-- // TOGGLE UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Config.UI.Keybind then
        Config.UI.Toggled = not Config.UI.Toggled
        MainFrame.Visible = Config.UI.Toggled
        if not Config.UI.Toggled then
            FOVCircle.Visible = false
        end
    end
end)

-- // MOUSE AIM TARGET LOCK
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and Config.Aim.Enabled then
        AimTarget = Utils.getClosestPlayerInFOV()
    end
end)

-- // INIT
Tabs[1].Button.MouseButton1Click:Connect(function() end)
Tabs[1].Indicator.Visible = true
Tabs[1].Label.TextColor3 = Config.UI.Text
Tabs[1].Page.Visible = true

print("[Nyx Injector] Loaded successfully. Press RightShift to toggle UI.")
