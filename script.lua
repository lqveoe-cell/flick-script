--[[
═══════════════════════════════════════════════════════════════════════════════
    ENI BLADE BALL — Mobile Edition
    Auto Parry | Hitbox Extender | Ball ESP | Trajectory
    Compact animated GUI optimized for touch
    
    Built by ENI for LO
═══════════════════════════════════════════════════════════════════════════════
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════════════════════════

local Theme = {
    Background   = Color3.fromRGB(14, 14, 20),
    Panel        = Color3.fromRGB(22, 22, 30),
    PanelHover   = Color3.fromRGB(30, 30, 40),
    Accent       = Color3.fromRGB(130, 95, 255),
    AccentLight  = Color3.fromRGB(165, 135, 255),
    AccentDim    = Color3.fromRGB(70, 50, 150),
    Text         = Color3.fromRGB(238, 238, 245),
    TextDim       = Color3.fromRGB(150, 150, 165),
    TextFaint    = Color3.fromRGB(95, 95, 110),
    ToggleTrack  = Color3.fromRGB(40, 40, 50),
    ToggleKnob   = Color3.fromRGB(235, 235, 245),
    Hover        = Color3.fromRGB(34, 34, 42),
    Success      = Color3.fromRGB(80, 210, 120),
    Danger       = Color3.fromRGB(240, 80, 80),
    Warning      = Color3.fromRGB(245, 200, 60),
    Border       = Color3.fromRGB(36, 36, 44),
    Shadow       = Color3.fromRGB(0, 0, 0),
}

local TI_Quick  = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_Smooth = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_Bounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════════════════════

local function Round(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.5
    s.Parent = parent
    return s
end

local function Gradient(parent, colorSeq, rotation)
    local g = Instance.new("UIGradient")
    g.Color = colorSeq or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentDim),
    })
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function Padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

local function List(parent, direction, padding, alignment)
    local l = Instance.new("UIListLayout")
    l.FillDirection = direction or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, padding or 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    if alignment then l.HorizontalAlignment = alignment end
    l.Parent = parent
    return l
end

local function Shadow(parent, size)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://1316045217"
    s.ImageColor3 = Theme.Shadow
    s.ImageTransparency = 0.5
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(10, 10, 118, 118)
    s.Size = UDim2.new(1, size or 14, 1, size or 14)
    s.Position = UDim2.new(0, -(size or 14)/2, 0, -(size or 14)/2)
    s.ZIndex = parent.ZIndex - 1
    s.Parent = parent
    return s
end

local function Glow(parent, color, size)
    local g = Instance.new("ImageLabel")
    g.Name = "Glow"
    g.BackgroundTransparency = 1
    g.Image = "rbxassetid://5028857084"
    g.ImageColor3 = color or Theme.Accent
    g.ImageTransparency = 0.8
    g.Size = UDim2.new(1, size or 16, 1, size or 16)
    g.Position = UDim2.new(0, -(size or 16)/2, 0, -(size or 16)/2)
    g.ZIndex = parent.ZIndex - 1
    g.Parent = parent
    return g
end

local function Tween(obj, props, info)
    local t = TweenService:Create(obj, info or TI_Quick, props)
    t:Play()
    return t
end

local function UpdateCanvas(scrollFrame)
    if not scrollFrame or not scrollFrame:IsA("ScrollingFrame") then return end
    local layout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if not layout then return end
    task.spawn(function()
        RunService.Heartbeat:Wait()
        local totalHeight = 0
        local pad = scrollFrame:FindFirstChildOfClass("UIPadding")
        local padTop = pad and pad.PaddingTop.Offset or 0
        local padBottom = pad and pad.PaddingBottom.Offset or 0
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("GuiObject") and child ~= layout then
                totalHeight = totalHeight + child.AbsoluteSize.Y + layout.Padding.Offset
            end
        end
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + padTop + padBottom)
    end)
end

local function Draggable(frame, handle)
    local dragging = false
    local dragStart, startPos
    local function onDown(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end
    local function onMove(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
    local function onUp(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end
    local target = handle or frame
    target.InputBegan:Connect(onDown)
    target.InputChanged:Connect(onMove)
    UserInputService.InputEnded:Connect(onUp)
end

local function GetGui()
    local gui = CoreGui:FindFirstChild("ENI_BladeBall")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "ENI_BladeBall"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = gethui and gethui() or CoreGui
    end
    return gui
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BLADE BALL LOGIC
-- ═══════════════════════════════════════════════════════════════════════════

local Ball = nil
local BallConn = nil

local function FindBall()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:match("ball") and not name:match("foot") and not name:match("soccer") then
                if obj:IsA("BasePart") then return obj end
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then return part end
            end
        end
    end
    -- Deep search
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():match("ball") then
            return obj
        end
    end
    return nil
end

local function WatchBall()
    if BallConn then BallConn:Disconnect() end
    BallConn = Workspace.ChildAdded:Connect(function(child)
        if child.Name:lower():match("ball") then
            task.wait(0.1)
            Ball = FindBall()
        end
    end)
    Ball = FindBall()
end

WatchBall()

-- ═══════════════════════════════════════════════════════════════════════════
-- FEATURES
-- ═══════════════════════════════════════════════════════════════════════════

local Features = {}
local connections = {}

local function getChar() return LocalPlayer.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end

-- ── Auto Parry ─────────────────────────────────────────────────────────────
Features.AutoParry = {
    enabled = false,
    method = "Distance",
    distance = 18,
    timePred = 0.15,
    conn = nil,
    lastParry = 0,
}

function Features.AutoParry:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            if not Ball or not Ball.Parent then
                Ball = FindBall()
                return
            end
            local hrp = getHRP()
            if not hrp then return end
            
            local ballPos = Ball.Position
            local playerPos = hrp.Position
            local dist = (ballPos - playerPos).Magnitude
            
            local shouldParry = false
            
            if self.method == "Distance" then
                -- Parry when ball is within distance threshold
                if dist <= self.distance then
                    -- Check ball velocity direction to ensure it's coming toward us
                    local ballVel = Ball.AssemblyLinearVelocity
                    local dirToPlayer = (playerPos - ballPos).Unit
                    local dotProduct = ballVel:Dot(dirToPlayer)
                    if dotProduct > 0 then -- Ball moving toward player
                        shouldParry = true
                    end
                end
            elseif self.method == "Time" then
                -- Predict time of arrival
                local ballVel = Ball.AssemblyLinearVelocity
                local speed = ballVel.Magnitude
                if speed > 1 then
                    local dirToPlayer = (playerPos - ballPos)
                    local distToPlayer = dirToPlayer.Magnitude
                    local velTowardsPlayer = ballVel:Dot(dirToPlayer.Unit)
                    if velTowardsPlayer > 0 then
                        local timeToHit = distToPlayer / velTowardsPlayer
                        if timeToHit <= self.timePred then
                            shouldParry = true
                        end
                    end
                end
            elseif self.method == "Hybrid" then
                -- Combine both methods for accuracy
                local ballVel = Ball.AssemblyLinearVelocity
                local speed = ballVel.Magnitude
                local dirToPlayer = (playerPos - ballPos)
                local distToPlayer = dirToPlayer.Magnitude
                local velTowardsPlayer = ballVel:Dot(dirToPlayer.Unit)
                
                if velTowardsPlayer > 0 and distToPlayer <= self.distance then
                    local timeToHit = speed > 1 and (distToPlayer / velTowardsPlayer) or 999
                    if timeToHit <= self.timePred + 0.1 or distToPlayer <= self.distance * 0.5 then
                        shouldParry = true
                    end
                end
            end
            
            if shouldParry then
                local now = tick()
                if now - self.lastParry > 0.3 then
                    self.lastParry = now
                    -- Try multiple parry methods
                    local parryRemote = ReplicatedStorage:FindFirstChild("Parry")
                    or ReplicatedStorage:FindFirstChild("ParryAttempt")
                    or ReplicatedStorage:FindFirstChild("Deflect")
                    or ReplicatedStorage:FindFirstChild("Block")
                    
                    -- Also check for events folder
                    if not parryRemote then
                        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                        or ReplicatedStorage:FindFirstChild("Remotes")
                        or ReplicatedStorage:FindFirstChild("Network")
                        if eventsFolder then
                            parryRemote = eventsFolder:FindFirstChild("Parry")
                            or eventsFolder:FindFirstChild("ParryAttempt")
                            or eventsFolder:FindFirstChild("Deflect")
                        end
                    end
                    
                    if parryRemote then
                        pcall(function()
                            if parryRemote:IsA("RemoteEvent") then
                                parryRemote:FireServer()
                            elseif parryRemote:IsA("RemoteFunction") then
                                parryRemote:InvokeServer()
                            elseif parryRemote:IsA("BindableEvent") then
                                parryRemote:Fire()
                            end
                        end)
                    end
                    
                    -- Key simulation fallback
                    pcall(function()
                        if keypress then
                            keypress(0x46) -- F key
                            task.wait(0.05)
                            keyrelease(0x46)
                        end
                    end)
                    
                    -- VirtualInputManager fallback
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.wait(0.05)
                        vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    end)
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── Hitbox Extender ────────────────────────────────────────────────────────
Features.HitboxExt = {
    enabled = false,
    size = 5,
    conn = nil,
}

function Features.HitboxExt:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            if Ball and Ball.Parent then
                local hrp = getHRP()
                if hrp then
                    local dist = (Ball.Position - hrp.Position).Magnitude
                    -- Expand ball hitbox when near player
                    if dist < self.size * 3 then
                        if not Ball:FindFirstChild("ENI_Hitbox") then
                            local hb = Instance.new("Part")
                            hb.Name = "ENI_Hitbox"
                            hb.Size = Vector3.new(self.size, self.size, self.size)
                            hb.CFrame = Ball.CFrame
                            hb.Transparency = 1
                            hb.CanCollide = false
                            hb.Massless = true
                            hb.Parent = Ball
                            local weld = Instance.new("WeldConstraint")
                            weld.Part0 = Ball
                            weld.Part1 = hb
                            weld.Parent = hb
                        end
                    end
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        if Ball then
            local hb = Ball:FindFirstChild("ENI_Hitbox")
            if hb then hb:Destroy() end
        end
    end
end

-- ── Ball ESP ───────────────────────────────────────────────────────────────
Features.BallESP = {
    enabled = false,
    conn = nil,
    tracer = nil,
    billboard = nil,
}

function Features.BallESP:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.RenderStepped:Connect(function()
            if not Ball or not Ball.Parent then
                Ball = FindBall()
                return
            end
            
            -- Billboard
            if not Ball:FindFirstChild("ENI_BallESP") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ENI_BallESP"
                bb.Size = UDim2.new(0, 100, 0, 40)
                bb.AlwaysOnTop = true
                bb.Parent = Ball
                
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "BALL"
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 14
                lbl.TextColor3 = Theme.AccentLight
                lbl.TextStrokeTransparency = 0.3
                lbl.ZIndex = 2
                lbl.Parent = bb
                
                local distLbl = Instance.new("TextLabel")
                distLbl.Size = UDim2.new(1, 0, 0, 12)
                distLbl.Position = UDim2.new(0, 0, 0, 20)
                distLbl.BackgroundTransparency = 1
                distLbl.Text = ""
                distLbl.Font = Enum.Font.Gotham
                distLbl.TextSize = 10
                distLbl.TextColor3 = Theme.Text
                distLbl.TextStrokeTransparency = 0.5
                distLbl.ZIndex = 2
                distLbl.Parent = bb
                
                self.billboard = bb
            end
            
            -- Update distance label
            local hrp = getHRP()
            if hrp and self.billboard then
                local dist = math.floor((Ball.Position - hrp.Position).Magnitude)
                local distLbl = self.billboard:FindFirstChildOfClass("TextLabel", true)
                if distLbl then
                    -- Find the second text label (distance)
                    local labels = self.billboard:GetChildren()
                    for _, l in ipairs(labels) do
                        if l:IsA("TextLabel") and l.Text ~= "BALL" then
                            l.Text = dist .. " studs"
                        end
                    end
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        if Ball then
            local bb = Ball:FindFirstChild("ENI_BallESP")
            if bb then bb:Destroy() end
        end
        self.billboard = nil
    end
end

-- ── Trajectory ─────────────────────────────────────────────────────────────
Features.Trajectory = {
    enabled = false,
    conn = nil,
    parts = {},
}

function Features.Trajectory:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.RenderStepped:Connect(function()
            if not Ball or not Ball.Parent then
                Ball = FindBall()
                return
            end
            
            -- Clean old parts
            for _, p in ipairs(self.parts) do
                if p then p:Destroy() end
            end
            self.parts = {}
            
            -- Predict trajectory
            local ballPos = Ball.Position
            local ballVel = Ball.AssemblyLinearVelocity
            local hrp = getHRP()
            
            if not hrp then return end
            
            -- Draw predicted path points
            local steps = 20
            local stepTime = 0.05
            for i = 1, steps do
                local futurePos = ballPos + ballVel * (stepTime * i)
                -- Account for gravity slightly
                futurePos = futurePos - Vector3.new(0, 0.5 * stepTime * stepTime * i * i, 0)
                
                local part = Instance.new("Part")
                part.Size = Vector3.new(0.15, 0.15, 0.15)
                part.CFrame = CFrame.new(futurePos)
                part.Anchored = true
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.Color = Theme.AccentLight
                part.Transparency = 1 - (i / steps) * 0.8
                part.Parent = Workspace
                self.parts[#self.parts + 1] = part
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        for _, p in ipairs(self.parts) do
            if p then p:Destroy() end
        end
        self.parts = {}
    end
end

-- ── Auto Spam Parry ────────────────────────────────────────────────────────
Features.SpamParry = {
    enabled = false,
    delay = 0.1,
    conn = nil,
}

function Features.SpamParry:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            while self.enabled do
                local parryRemote = ReplicatedStorage:FindFirstChild("Parry")
                or ReplicatedStorage:FindFirstChild("ParryAttempt")
                or ReplicatedStorage:FindFirstChild("Deflect")
                
                if not parryRemote then
                    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                    or ReplicatedStorage:FindFirstChild("Remotes")
                    if eventsFolder then
                        parryRemote = eventsFolder:FindFirstChild("Parry")
                        or eventsFolder:FindFirstChild("ParryAttempt")
                    end
                end
                
                if parryRemote then
                    pcall(function()
                        if parryRemote:IsA("RemoteEvent") then
                            parryRemote:FireServer()
                        end
                    end)
                end
                
                pcall(function()
                    if keypress then
                        keypress(0x46)
                        task.wait(0.03)
                        keyrelease(0x46)
                    end
                end)
                
                task.wait(self.delay)
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
    end
end

-- ── Anti AFK ───────────────────────────────────────────────────────────────
Features.AntiAFK = {
    enabled = false,
    conn = nil,
}

function Features.AntiAFK:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            local VirtualUser = game:GetService("VirtualUser")
            while self.enabled do
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
                task.wait(math.random(15, 30))
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- GUI — Mobile Compact
-- ═══════════════════════════════════════════════════════════════════════════

local gui = GetGui()
local guiOpen = false

-- ★ Toggle button (floating icon)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleBtn.BackgroundColor3 = Theme.Accent
ToggleBtn.Text = ""
ToggleBtn.BorderSizePixel = 0
ToggleBtn.ZIndex = 20
ToggleBtn.Parent = gui
Round(ToggleBtn, 14)
Shadow(ToggleBtn, 10)
Gradient(ToggleBtn, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.AccentDim),
}), 45)
Glow(ToggleBtn, Theme.Accent, 12)

local ToggleIcon = Instance.new("ImageLabel")
ToggleIcon.Size = UDim2.new(0, 24, 0, 24)
ToggleIcon.Position = UDim2.new(0.5, -12, 0.5, -12)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Image = "rbxassetid://6031075915"
ToggleIcon.ImageColor3 = Theme.Text
ToggleIcon.ZIndex = 21
ToggleIcon.Parent = ToggleBtn

-- Pulse animation on toggle button
local pulseConn
local function startPulse()
    if pulseConn then pulseConn:Disconnect() end
    local growing = true
    pulseConn = RunService.Heartbeat:Connect(function()
        if growing then
            ToggleBtn.Size = ToggleBtn.Size:Lerp(UDim2.new(0, 50, 0, 50), 0.05)
            if ToggleBtn.AbsoluteSize.X >= 49 then growing = false end
        else
            ToggleBtn.Size = ToggleBtn.Size:Lerp(UDim2.new(0, 48, 0, 48), 0.05)
            if ToggleBtn.AbsoluteSize.X <= 48.5 then growing = true end
        end
    end)
end

local function stopPulse()
    if pulseConn then pulseConn:Disconnect() pulseConn = nil end
    Tween(ToggleBtn, { Size = UDim2.new(0, 48, 0, 48) }, TI_Quick)
end

startPulse()

Draggable(ToggleBtn)

-- ★ Main panel (slides in from toggle button)
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.new(0, 240, 0, 320)
MainPanel.Position = UDim2.new(0, 15, 0, 73)
MainPanel.BackgroundColor3 = Theme.Background
MainPanel.BackgroundTransparency = 0.02
MainPanel.BorderSizePixel = 0
MainPanel.ZIndex = 10
MainPanel.Visible = false
MainPanel.ClipsDescendants = true
MainPanel.Parent = gui
Round(MainPanel, 12)
Stroke(MainPanel, Theme.Border, 1, 0.3)
Shadow(MainPanel, 12)

-- Accent bar top
local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 3)
accentBar.BackgroundColor3 = Theme.Accent
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 11
accentBar.Parent = MainPanel
Round(accentBar, 12)
Gradient(accentBar, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(0.5, Theme.AccentLight),
    ColorSequenceKeypoint.new(1, Theme.Accent),
}), 0)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.Position = UDim2.new(0, 0, 0, 3)
Header.BackgroundTransparency = 1
Header.ZIndex = 12
Header.Parent = MainPanel

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.new(0, 18, 0, 18)
Logo.Position = UDim2.new(0, 12, 0.5, -9)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://6031075915"
Logo.ImageColor3 = Theme.Accent
Logo.ZIndex = 13
Logo.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 120, 0, 16)
Title.Position = UDim2.new(0, 36, 0.5, -8)
Title.BackgroundTransparency = 1
Title.Text = "ENI Blade Ball"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 13
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 120, 0, 10)
Subtitle.Position = UDim2.new(0, 36, 0.5, 4)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Mobile Edition"
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 9
Subtitle.TextColor3 = Theme.TextFaint
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 13
Subtitle.Parent = Header

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = Theme.Panel
CloseBtn.BackgroundTransparency = 0.5
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 13
CloseBtn.Parent = Header
Round(CloseBtn, 6)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, { BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.2, TextColor3 = Theme.Text }, TI_Quick)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim }, TI_Quick)
end)

-- Scroll area
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -50)
Scroll.Position = UDim2.new(0, 8, 0, 44)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Theme.AccentDim
Scroll.ScrollBarImageTransparency = 0.3
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ElasticBehavior = Enum.ElasticBehavior.Always
Scroll.ZIndex = 12
Scroll.Parent = MainPanel

local ScrollList = Instance.new("UIListLayout")
ScrollList.FillDirection = Enum.FillDirection.Vertical
ScrollList.Padding = UDim.new(0, 6)
ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
ScrollList.Parent = Scroll

local ScrollPad = Instance.new("UIPadding")
ScrollPad.PaddingTop = UDim.new(0, 4)
ScrollPad.PaddingBottom = UDim.new(0, 4)
ScrollPad.PaddingLeft = UDim.new(0, 4)
ScrollPad.PaddingRight = UDim.new(0, 4)
ScrollPad.Parent = Scroll

Draggable(MainPanel, Header)

-- ═══════════════════════════════════════════════════════════════════════════
-- GUI ELEMENT FACTORY
-- ═══════════════════════════════════════════════════════════════════════════

local elementOrder = 0

local function nextOrder()
    elementOrder = elementOrder + 1
    return elementOrder
end

local function CreateSection(title)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 22)
    Container.LayoutOrder = nextOrder()
    Container.BackgroundTransparency = 1
    Container.ZIndex = 13
    Container.Parent = Scroll
    
    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.Position = UDim2.new(0, 0, 0.5, 0)
    Line.BackgroundColor3 = Theme.Border
    Line.BorderSizePixel = 0
    Line.Transparency = 0.5
    Line.ZIndex = 14
    Line.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 120, 0, 12)
    Label.Position = UDim2.new(0, 6, 0.5, -6)
    Label.BackgroundTransparency = 1
    Label.Text = title or "Section"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 9
    Label.TextColor3 = Theme.AccentLight
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 15
    Label.Parent = Container
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 110, 0, 3)
    bg.Position = UDim2.new(0, 4, 0.5, 5)
    bg.BackgroundColor3 = Theme.Background
    bg.BorderSizePixel = 0
    bg.ZIndex = 14
    bg.Parent = Container
    
    UpdateCanvas(Scroll)
    return Container
end

local function CreateToggle(config)
    local toggle = { state = false }
    
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 32)
    Container.LayoutOrder = nextOrder()
    Container.BackgroundColor3 = Theme.Panel
    Container.BackgroundTransparency = 0.3
    Container.BorderSizePixel = 0
    Container.ZIndex = 13
    Container.Parent = Scroll
    Round(Container, 8)
    Stroke(Container, Theme.Border, 1, 0.6)
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -56, 0, 14)
    ToggleLabel.Position = UDim2.new(0, 10, 0.5, -7)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = config.Text or "Toggle"
    ToggleLabel.Font = Enum.Font.GothamMedium
    ToggleLabel.TextSize = 11
    ToggleLabel.TextColor3 = Theme.Text
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.ZIndex = 14
    ToggleLabel.Parent = Container
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 36, 0, 18)
    ToggleBtn.Position = UDim2.new(1, -44, 0.5, -9)
    ToggleBtn.BackgroundColor3 = Theme.ToggleTrack
    ToggleBtn.Text = ""
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.ZIndex = 14
    ToggleBtn.Parent = Container
    Round(ToggleBtn, 9)
    Stroke(ToggleBtn, Theme.Border, 1, 0.5)
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new(0, 3, 0.5, -6)
    Knob.BackgroundColor3 = Theme.ToggleKnob
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 15
    Knob.Parent = ToggleBtn
    Round(Knob, 6)
    
    local function setToggle(state)
        toggle.state = state
        if state then
            Tween(ToggleBtn, { BackgroundColor3 = Theme.Accent }, TI_Quick)
            Tween(Knob, { Position = UDim2.new(1, -15, 0.5, -6) }, TI_Quick)
            Tween(ToggleLabel, { TextColor3 = Theme.AccentLight }, TI_Quick)
            Tween(Container, { BackgroundTransparency = 0.15 }, TI_Quick)
        else
            Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleTrack }, TI_Quick)
            Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -6) }, TI_Quick)
            Tween(ToggleLabel, { TextColor3 = Theme.Text }, TI_Quick)
            Tween(Container, { BackgroundTransparency = 0.3 }, TI_Quick)
        end
        if config.Callback then
            task.spawn(function() config.Callback(state) end)
        end
    end
    
    ToggleBtn.MouseButton1Click:Connect(function()
        setToggle(not toggle.state)
    end)
    
    -- Touch-friendly: entire container clickable
    Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setToggle(not toggle.state)
        end
    end)
    
    ToggleBtn.MouseEnter:Connect(function()
        if not toggle.state then
            Tween(ToggleBtn, { BackgroundColor3 = Color3.fromRGB(55, 55, 65) }, TI_Quick)
        end
    end)
    ToggleBtn.MouseLeave:Connect(function()
        if not toggle.state then
            Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleTrack }, TI_Quick)
        end
    end)
    
    toggle.Set = setToggle
    toggle.Get = function() return toggle.state end
    
    if config.Default then
        task.spawn(function() setToggle(true) end)
    end
    
    UpdateCanvas(Scroll)
    return toggle
end

local function CreateSlider(config)
    local slider = { value = config.Default or config.Min or 0 }
    local min = config.Min or 0
    local max = config.Max or 100
    local suffix = config.Suffix or ""
    
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 46)
    Container.LayoutOrder = nextOrder()
    Container.BackgroundColor3 = Theme.Panel
    Container.BackgroundTransparency = 0.3
    Container.BorderSizePixel = 0
    Container.ZIndex = 13
    Container.Parent = Scroll
    Round(Container, 8)
    Stroke(Container, Theme.Border, 1, 0.6)
    
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(0, 150, 0, 12)
    SliderLabel.Position = UDim2.new(0, 10, 0, 6)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = config.Text or "Slider"
    SliderLabel.Font = Enum.Font.GothamMedium
    SliderLabel.TextSize = 11
    SliderLabel.TextColor3 = Theme.Text
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.ZIndex = 14
    SliderLabel.Parent = Container
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 50, 0, 12)
    ValueLabel.Position = UDim2.new(1, -58, 0, 6)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(slider.value) .. suffix
    ValueLabel.Font = Enum.Font.GothamMedium
    ValueLabel.TextSize = 11
    ValueLabel.TextColor3 = Theme.AccentLight
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.ZIndex = 14
    ValueLabel.Parent = Container
    
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -20, 0, 5)
    Track.Position = UDim2.new(0, 10, 0, 28)
    Track.BackgroundColor3 = Theme.ToggleTrack
    Track.BorderSizePixel = 0
    Track.ZIndex = 14
    Track.Parent = Container
    Round(Track, 3)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 15
    Fill.Parent = Track
    Round(Fill, 3)
    Gradient(Fill, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentLight),
    }), 0)
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new(0, 0, 0.5, -6)
    Knob.BackgroundColor3 = Theme.Text
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 16
    Knob.Parent = Track
    Round(Knob, 6)
    
    local dragging = false
    
    local function updateSlider(inputPos)
        local rel = (inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        slider.value = min + (max - min) * rel
        if config.Decimal then
            slider.value = math.round(slider.value * 100) / 100
        else
            slider.value = math.floor(slider.value)
        end
        ValueLabel.Text = tostring(slider.value) .. suffix
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, -6, 0.5, -6)
        if config.Callback then
            task.spawn(function() config.Callback(slider.value) end)
        end
    end
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input.Position)
            Tween(Knob, { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(Knob.Position.X.Scale, -8, 0.5, -8) }, TI_Quick)
        end
    end)
    Track.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                Tween(Knob, { Size = UDim2.new(0, 12, 0, 12) }, TI_Quick)
            end
        end
    end)
    
    local initRel = (slider.value - min) / (max - min)
    Fill.Size = UDim2.new(initRel, 0, 1, 0)
    Knob.Position = UDim2.new(initRel, -6, 0.5, -6)
    
    slider.Set = function(val)
        val = math.clamp(val, min, max)
        slider.value = val
        local rel = (val - min) / (max - min)
        ValueLabel.Text = tostring(val) .. suffix
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, -6, 0.5, -6)
        if config.Callback then config.Callback(val) end
    end
    slider.Get = function() return slider.value end
    
    UpdateCanvas(Scroll)
    return slider
end

local function CreateButton(config)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 32)
    Button.LayoutOrder = nextOrder()
    Button.BackgroundColor3 = Theme.Panel
    Button.BackgroundTransparency = 0.3
    Button.Text = ""
    Button.BorderSizePixel = 0
    Button.ZIndex = 13
    Button.Parent = Scroll
    Round(Button, 8)
    Stroke(Button, Theme.Border, 1, 0.6)
    
    local BtnLabel = Instance.new("TextLabel")
    BtnLabel.Size = UDim2.new(1, -20, 0, 12)
    BtnLabel.Position = UDim2.new(0, 10, 0.5, -6)
    BtnLabel.BackgroundTransparency = 1
    BtnLabel.Text = config.Text or "Button"
    BtnLabel.Font = Enum.Font.GothamMedium
    BtnLabel.TextSize = 11
    BtnLabel.TextColor3 = Theme.Text
    BtnLabel.TextXAlignment = Enum.TextXAlignment.Left
    BtnLabel.ZIndex = 14
    BtnLabel.Parent = Button
    
    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 10, 0, 10)
    arrow.Position = UDim2.new(1, -18, 0.5, -5)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://6031094670"
    arrow.ImageColor3 = Theme.TextFaint
    arrow.ZIndex = 14
    arrow.Parent = Button
    
    Button.MouseEnter:Connect(function()
        Tween(Button, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TI_Quick)
        Tween(arrow, { ImageColor3 = Theme.AccentLight, Position = UDim2.new(1, -16, 0.5, -5) }, TI_Quick)
    end)
    Button.MouseLeave:Connect(function()
        Tween(Button, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.3 }, TI_Quick)
        Tween(arrow, { ImageColor3 = Theme.TextFaint, Position = UDim2.new(1, -18, 0.5, -5) }, TI_Quick)
    end)
    Button.MouseButton1Down:Connect(function()
        Tween(Button, { BackgroundColor3 = Color3.fromRGB(26, 26, 32), BackgroundTransparency = 0 }, TweenInfo.new(0.05))
    end)
    Button.MouseButton1Up:Connect(function()
        Tween(Button, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TI_Quick)
        if config.Callback then config.Callback() end
    end)
    
    UpdateCanvas(Scroll)
    return Button
end

local function CreateLabel(text, fontSize)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.LayoutOrder = nextOrder()
    Label.BackgroundTransparency = 1
    Label.Text = text or "Label"
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = fontSize or 10
    Label.TextColor3 = Theme.TextDim
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 13
    Label.Parent = Scroll
    
    UpdateCanvas(Scroll)
    return Label
end

-- ═══════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════

local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "Notifications"
NotifContainer.Size = UDim2.new(0, 200, 1, -20)
NotifContainer.Position = UDim2.new(1, -210, 0, 10)
NotifContainer.BackgroundTransparency = 1
NotifContainer.ZIndex = 50
NotifContainer.Parent = gui
List(NotifContainer, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right)

local function Notify(config)
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(0, 200, 0, 44)
    Notif.BackgroundColor3 = Theme.Panel
    Notif.BackgroundTransparency = 0.1
    Notif.BorderSizePixel = 0
    Notif.ZIndex = 51
    Notif.Parent = NotifContainer
    Round(Notif, 8)
    Stroke(Notif, Theme.Border, 1, 0.4)
    Shadow(Notif, 8)
    
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, -10)
    accentBar.Position = UDim2.new(0, 5, 0, 5)
    accentBar.BackgroundColor3 = config.Color or Theme.Accent
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 52
    accentBar.Parent = Notif
    Round(accentBar, 2)
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -24, 0, 12)
    Title.Position = UDim2.new(0, 14, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "Notification"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 10
    Title.TextColor3 = Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 52
    Title.Parent = Notif
    
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -24, 0, 16)
    Desc.Position = UDim2.new(0, 14, 0, 18)
    Desc.BackgroundTransparency = 1
    Desc.Text = config.Description or ""
    Desc.Font = Enum.Font.Gotham
    Desc.TextSize = 9
    Desc.TextColor3 = Theme.TextDim
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.TextWrapped = true
    Desc.ZIndex = 52
    Desc.Parent = Notif
    
    Notif.Size = UDim2.new(0, 0, 0, 44)
    Notif.BackgroundTransparency = 1
    Tween(Notif, { Size = UDim2.new(0, 200, 0, 44), BackgroundTransparency = 0.1 }, TI_Bounce)
    
    task.delay(config.Duration or 2.5, function()
        Tween(Notif, { Size = UDim2.new(0, 0, 0, 44), BackgroundTransparency = 1 }, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.3)
        Notif:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ANIMATED OPEN / CLOSE
-- ═══════════════════════════════════════════════════════════════════════════

local function openGUI()
    if guiOpen then return end
    guiOpen = true
    stopPulse()
    
    MainPanel.Visible = true
    MainPanel.Size = UDim2.new(0, 240, 0, 0)
    MainPanel.Position = UDim2.new(0, ToggleBtn.AbsolutePosition.X + 4, 0, ToggleBtn.AbsolutePosition.Y + 52)
    
    -- Slide & expand animation
    Tween(MainPanel, { Size = UDim2.new(0, 240, 0, 320) }, TI_Bounce)
    
    -- Toggle button feedback
    Tween(ToggleIcon, { ImageColor3 = Theme.AccentLight }, TI_Quick)
    Tween(ToggleBtn, { BackgroundColor3 = Theme.AccentDim }, TI_Quick)
end

local function closeGUI()
    if not guiOpen then return end
    guiOpen = false
    
    -- Collapse animation
    Tween(MainPanel, { Size = UDim2.new(0, 240, 0, 0) }, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
    
    task.delay(0.3, function()
        MainPanel.Visible = false
    end)
    
    -- Toggle button feedback
    Tween(ToggleIcon, { ImageColor3 = Theme.Text }, TI_Quick)
    Tween(ToggleBtn, { BackgroundColor3 = Theme.Accent }, TI_Quick)
    
    startPulse()
end

ToggleBtn.MouseButton1Click:Connect(function()
    if guiOpen then
        closeGUI()
    else
        openGUI()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    closeGUI()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD UI CONTENT
-- ═══════════════════════════════════════════════════════════════════════════

CreateSection("Parry")

CreateToggle({
    Text = "Auto Parry",
    Default = false,
    Callback = function(state)
        Features.AutoParry:Toggle(state)
        Notify({ Title = "Auto Parry", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

CreateToggle({
    Text = "Spam Parry",
    Default = false,
    Callback = function(state)
        Features.SpamParry:Toggle(state)
        Notify({ Title = "Spam Parry", Description = state and "Enabled" or "Disabled", Color = state and Theme.Warning or Theme.Danger })
    end,
})

CreateSlider({
    Text = "Parry Distance",
    Min = 5,
    Max = 50,
    Default = 18,
    Suffix = " studs",
    Callback = function(val) Features.AutoParry.distance = val end,
})

CreateSlider({
    Text = "Time Predict",
    Min = 0.05,
    Max = 1,
    Default = 0.15,
    Decimal = true,
    Suffix = "s",
    Callback = function(val) Features.AutoParry.timePred = val end,
})

CreateSection("Visuals")

CreateToggle({
    Text = "Ball ESP",
    Default = false,
    Callback = function(state)
        Features.BallESP:Toggle(state)
    end,
})

CreateToggle({
    Text = "Trajectory",
    Default = false,
    Callback = function(state)
        Features.Trajectory:Toggle(state)
    end,
})

CreateSection("Hitbox")

CreateToggle({
    Text = "Hitbox Extender",
    Default = false,
    Callback = function(state)
        Features.HitboxExt:Toggle(state)
    end,
})

CreateSlider({
    Text = "Hitbox Size",
    Min = 1,
    Max = 20,
    Default = 5,
    Suffix = " sz",
    Callback = function(val) Features.HitboxExt.size = val end,
})

CreateSection("Misc")

CreateToggle({
    Text = "Anti AFK",
    Default = false,
    Callback = function(state)
        Features.AntiAFK:Toggle(state)
    end,
})

CreateButton({
    Text = "Refind Ball",
    Callback = function()
        Ball = FindBall()
        Notify({ Title = "Ball Tracker", Description = Ball and "Ball found!" or "No ball found", Color = Ball and Theme.Success or Theme.Danger })
    end,
})

CreateButton({
    Text = "Unload",
    Callback = function()
        for _, feat in pairs(Features) do
            if type(feat) == "table" and feat.Toggle then
                pcall(function() feat:Toggle(false) end)
            end
        end
        if pulseConn then pulseConn:Disconnect() end
        task.wait(0.3)
        gui:Destroy()
    end,
})

CreateLabel("ENI Blade Ball v1.0", 9)
CreateLabel("Built for LO", 8)

-- ═══════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════

-- Force canvas update
task.spawn(function()
    task.wait(0.1)
    UpdateCanvas(Scroll)
end)

Notify({
    Title = "ENI Blade Ball",
    Description = "Loaded. Tap icon to open.",
    Color = Theme.Accent,
    Duration = 3,
})

print("[ENI Blade Ball] v1.0 loaded successfully.")
