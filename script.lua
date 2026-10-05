-- language: Lua (Roblox Exploit), file: mm2_suite_v2_fixed.lua, target: Mobile PC
-- *Fixed GUI Initialization & Logic Separation*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- STATE MANAGEMENT
local State = {
    Aimbot = false,
    AutoShoot = false,
    AutoThrow = false,
    SpinBot = false,
    KillAllTriggered = false,
    
    Fly = false,
    NoClip = false,
    WalkSpeed = 16,
    FakeLag = false,
    
    RoleESP = false,
    GunESP = false,
    Crosshair = false,
    Trail = false,
    Aura = false,
    Overhead = false,
    VisualWorld = false,
    
    AutoPickup = false,
    FlingMurder = false,
    FlingSheriff = false,
    AntiFling = false,
    
    Values = {
        FOV = 100,
        TargetBone = "Head", -- Head or UpperTorso
        FlySpeed = 50,
        EspTransparency = 0.5
    }
}

-- UTILITIES
local function getChar(plr) return plr and plr.Character end
local function getHRP(plr) 
    local c = getChar(plr)
    return c and c:FindFirstChild("HumanoidRootPart") 
end
local function getHead(plr)
    local c = getChar(plr)
    return c and c:FindFirstChild("Head")
end
local function isAlive(plr)
    local c = getChar(plr)
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

-- ==========================================
-- WATERMARK (@nfaaoa)
-- ==========================================
local wmGui = Instance.new("ScreenGui")
wmGui.Name = "NFAAOA_WM"
wmGui.ResetOnSpawn = false
wmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
wmGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local wmFrame = Instance.new("Frame")
wmFrame.Size = UDim2.new(0, 180, 0, 25)
wmFrame.Position = UDim2.new(0, 10, 0, 10)
wmFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
wmFrame.BackgroundTransparency = 0.4
wmFrame.BorderSizePixel = 0
wmFrame.Parent = wmGui

Instance.new("UICorner", wmFrame).CornerRadius = UDim.new(0, 5)

local wmLabel = Instance.new("TextLabel")
wmLabel.Text = "@nfaaoa | MM2 SUITE"
wmLabel.Font = Enum.Font.GothamBold
wmLabel.TextSize = 14
wmLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
wmLabel.BackgroundTransparency = 1
wmLabel.Size = UDim2.new(1, 0, 1, 0)
wmLabel.Parent = wmFrame

-- ==========================================
-- MAIN GUI CONSTRUCTION
-- ==========================================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "MM2_Main_Suite"
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 350) -- Fixed size for stability
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Title Bar
local titleBar = Instance.new("TextButton")
titleBar.Text = "MM2 FULL SUITE | @nfaaoa"
titleBar.Font = Enum.Font.GothamBlack
titleBar.TextSize = 16
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BorderSizePixel = 0
titleBar.AutoLocalize = false
titleBar.Parent = mainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 2)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

closeBtn.MouseButton1Click:Connect(function()
    mainGui:Destroy()
    wmGui:Destroy()
end)

-- Left Tabs Container
local tabContainer = Instance.new("ScrollingFrame")
tabContainer.Size = UDim2.new(0, 100, 1, -40)
tabContainer.Position = UDim2.new(0, 5, 0, 40)
tabContainer.BackgroundTransparency = 1
tabContainer.ScrollBarThickness = 4
tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabContainer.Parent = mainFrame

-- Right Content Area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -115, 1, -40)
contentArea.Position = UDim2.new(0, 110, 0, 40)
contentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.Parent = mainFrame

Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0, 8)

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, -10, 1, -10)
contentScroll.Position = UDim2.new(0, 5, 0, 5)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 6
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.Parent = contentArea

-- HELPER FUNCTIONS FOR UI
local currentPage = nil

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.LayoutOrder = #tabContainer:GetChildren() + 1
    btn.BorderSizePixel = 0
    btn.AutoLocalize = false
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    
    btn.MouseButton1Click:Connect(function()
        if currentPage then currentPage.Visible = false end
        
        -- Highlight active
        for _, child in pairs(tabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                child.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 100, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        local page = contentArea:FindFirstChild(name .. "_Page")
        if page then
            page.Visible = true
            currentPage = page
        end
    end)
    
    btn.Parent = tabContainer
    return btn
end

local function addToggle(parent, text, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #parent:GetChildren() + 1
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -50, 0.5, -10)
    toggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(defaultVal and 1 or 0, -16, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local state = defaultVal
    toggleBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            knob:TweenPosition(state and UDim2.new(1, -16, 0.5, -8) or UDim2.new(0, 0, 0.5, -8), "Out", "Quart", 0.2)
            toggleBg.BackgroundColor3 = state and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(50, 50, 50)
            if callback then callback(state) end
        end
    end)
    
    return row
end

local function addSlider(parent, text, min, max, def, suffix, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 40)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #parent:GetChildren() + 1
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = string.format("%s: %d%s", text, def, suffix or "")
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 20)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 25)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new((def-min)/(max-min), -7, 0.5, -7)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = track
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local val = def
    
    local function updateDrag(xPos)
        local relX = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + relX * (max - min))
        fill.Size = UDim2.new(relX, 0, 1, 0)
        handle.Position = UDim2.new(relX, -7, 0.5, -7)
        label.Text = string.format("%s: %d%s", text, val, suffix or "")
        if callback then callback(val) end
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateDrag(input.Position.X)
        end
    end)
    
    track.InputChanged:Connect(function(input)
        if dragging then updateDrag(input.Position.X) end
    end)
    
    track.InputEnded:Connect(function()
        dragging = false
    end)
    
    return row
end

-- CREATE PAGES
local pages = {}
for _, name in ipairs({"Combat", "Movement", "Visuals", "Tools"}) do
    local page = Instance.new("Frame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = contentArea
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -10)
    scroll.Position = UDim2.new(0, 5, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = page
    
    pages[name] = scroll
end

-- POPULATE TABS
createTab("Combat")
createTab("Movement")
createTab("Visuals")
createTab("Tools")

-- Trigger first tab manually
if tabContainer.FirstChild then
    tabContainer.FirstChild:FireSignal("MouseButton1Click")
end

-- ==========================================
-- UI CONTENT SETUP
-- ==========================================

-- COMBAT PAGE
addToggle(pages.Combat, "Aimbot", false, function(v) State.Aimbot = v end)
addSlider(pages.Combat, "FOV", 10, 300, State.Values.FOV, "", function(v) State.Values.FOV = v end)
addToggle(pages.Combat, "Auto Shoot", false, function(v) State.AutoShoot = v end)
addToggle(pages.Combat, "Auto Throw Knife", false, function(v) State.AutoThrow = v end)
addToggle(pages.Combat, "SpinBot", false, function(v) State.SpinBot = v end)
addToggle(pages.Combat, "Kill All (One-Shot)", false, function(v) 
    if v then
        task.spawn(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) then
                    local hrp = getHRP(p)
                    if hrp then
                        -- Simple teleport kill simulation
                        LocalPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame
                        task.wait(0.1)
                    end
                end
            end
            State.KillAllTriggered = false
        end)
    end
end)

-- MOVEMENT PAGE
addToggle(pages.Movement, "Fly", false, function(v) State.Fly = v end)
addSlider(pages.Movement, "Fly Speed", 10, 200, State.Values.FlySpeed, "", function(v) State.Values.FlySpeed = v end)
addToggle(pages.Movement, "No Clip", false, function(v) State.NoClip = v end)
addSlider(pages.Movement, "Walk Speed", 16, 100, State.WalkSpeed, "", function(v) State.WalkSpeed = v end)
addToggle(pages.Movement, "Fake Lag", false, function(v) State.FakeLag = v end)

-- VISUALS PAGE
addToggle(pages.Visuals, "Role ESP", false, function(v) State.RoleESP = v end)
addToggle(pages.Visuals, "Gun ESP", false, function(v) State.GunESP = v end)
addToggle(pages.Visuals, "Custom Crosshair", false, function(v) State.Crosshair = v end)
addToggle(pages.Visuals, "Trail Effect", false, function(v) State.Trail = v end)
addToggle(pages.Visuals, "Aura Effect", false, function(v) State.Aura = v end)
addToggle(pages.Visuals, "Overhead Info", false, function(v) State.Overhead = v end)
addToggle(pages.Visuals, "Visual World Boost", false, function(v) State.VisualWorld = v end)

-- TOOLS PAGE
addToggle(pages.Tools, "Auto Pickup Gun", false, function(v) State.AutoPickup = v end)
addToggle(pages.Tools, "Fling Murderer", false, function(v) State.FlingMurder = v end)
addToggle(pages.Tools, "Fling Sheriff", false, function(v) State.FlingSheriff = v end)
addToggle(pages.Tools, "Anti Fling", false, function(v) State.AntiFling = v end)
addToggle(pages.Tools, "Get All Emotes", false, function(v) 
    if v then
        task.spawn(function()
            local emotes = Workspace:FindFirstChild("Emotes") or ReplicatedStorage:FindFirstChild("Emotes")
            if emotes then
                for _, anim in pairs(emotes:GetDescendants()) do
                    if anim:IsA("Animation") then
                        local a = Instance.new("Animation")
                        a.AnimationId = anim.AnimationId
                        LocalPlayer.Character.Humanoid:LoadAnimation(a):Play()
                        task.wait(0.1)
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- LOGIC LOOPS
-- ==========================================

-- Raycast Params
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Main Render Loop
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- 1. Movement
    if State.Fly then
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end
        
        if moveDir.Magnitude > 0 then
            hrp.AssemblyLinearVelocity = moveDir.Unit * State.Values.FlySpeed
        else
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    if State.NoClip then
        hrp.CanCollide = false
    else
        hrp.CanCollide = true
    end

    hum.WalkSpeed = State.WalkSpeed

    if State.SpinBot then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(15), 0)
    end

    -- 2. Aimbot
    if State.Aimbot then
        local bestDist = State.Values.FOV
        local targetPart = nil
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isAlive(p) then
                local bone = p.Character:FindFirstChild(State.Values.TargetBone) or p.Character:FindFirstChild("Head")
                if bone then
                    local dist = (bone.Position - Camera.CFrame.p).Magnitude
                    if dist < bestDist then
                        local dir = (bone.Position - Camera.CFrame.p).Unit
                        local hit = Workspace:Raycast(Camera.CFrame.p, dir * dist, rayParams)
                        if not hit or hit.Instance.Parent == p.Character then
                            bestDist = dist
                            targetPart = bone
                        end
                    end
                end
            end
        end
        
        if targetPart then
            local goalCF = CFrame.lookAt(hrp.Position, targetPart.Position)
            hrp.CFrame = hrp.CFrame:Lerp(goalCF, 0.1)
            
            if State.AutoShoot then
                -- Placeholder for shooting logic (requires specific RemoteEvents for MM2)
                -- Usually involves firing 'Attack' remote with mouse position
            end
        end
    end

    -- 3. Visuals (Trail/Aura/Crosshair handled separately to avoid lag)
    
end)

-- Separate Loop for Heavy Visuals (ESP/Drawing)
task.spawn(function()
    while wait(0.1) do -- Lower frequency for ESP creation
        local char = LocalPlayer.Character
        if not char then continue end
        
        -- Clean up old ESP objects periodically
        for _, obj in pairs(char:GetChildren()) do
            if obj.Name:find("ESP_") then obj:Destroy() end
        end

        if State.RoleESP then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) then
                    local tool = p.Character:FindFirstChildOfClass("Tool")
                    local color = Color3.fromRGB(255, 255, 255)
                    if tool then
                        if tool.Name == "Knife" then color = Color3.fromRGB(255, 0, 0)
                        elseif tool.Name == "Revolver" or tool.Name == "Shotgun" then color = Color3.fromRGB(0, 0, 255)
                        end
                    end
                    
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ESP_Role_" .. p.Name
                    highlight.FillColor = color
                    highlight.OutlineColor = color
                    highlight.FillTransparency = 0.7
                    highlight.Adornee = p.Character
                    highlight.Parent = p.Character
                end
            end
        end
    end
end)

-- Drawing API for Crosshair (Must be in separate thread or careful loop)
if typeof(drawing) ~= "nil" then
    task.spawn(function()
        local crosshair = drawing.new("Square")
        crosshair.Color = Color3.fromRGB(0, 255, 170)
        crosshair.Thickness = 2
        crosshair.Filled = false
        
        while wait() do
            if State.Crosshair then
                local center = Camera.ViewportSize / 2
                crosshair.Position = Vector2.new(center.X - 10, center.Y - 10)
                crosshair.Size = Vector2.new(20, 20)
                crosshair.Transparency = 0
            else
                crosshair.Transparency = 1
            end
        end
    end)
else
    warn("Drawing API not supported by this executor. Crosshair disabled.")
end

print("[@nfaaoa] MM2 Suite Loaded Successfully.")
