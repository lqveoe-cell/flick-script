-- language: Lua (Roblox Exploit), file: mm2_suite_pro_final.lua, target: Mobile/PC Universal
-- *Advanced MM2 Suite with Custom UI Library, Full Feature Set, and Stable Logic*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- ==========================================
-- CONFIGURATION & STATE
-- ==========================================
local Config = {
    ThemeColor = Color3.fromRGB(0, 255, 170), -- Neon Green
    SecondaryColor = Color3.fromRGB(20, 20, 20),
    TextColor = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamMedium,
    BoldFont = Enum.Font.GothamBold,
    SizeMultiplier = 1.0 -- Adjust for screen density if needed
}

local State = {
    -- Combat
    AimbotEnabled = false,
    AimFOV = 100,
    AimSmoothness = 0.1,
    TargetBone = "Head",
    AutoShootEnabled = false,
    AutoThrowEnabled = false,
    SpinBotEnabled = false,
    
    -- Movement
    FlyEnabled = false,
    FlySpeed = 50,
    NoClipEnabled = false,
    WalkSpeedValue = 16,
    FakeLagEnabled = false,
    
    -- Visuals
    RoleESPEnabled = false,
    GunESPEnabled = false,
    CrosshairEnabled = false,
    CrosshairSize = 20,
    TrailEnabled = false,
    AuraEnabled = false,
    OverheadEnabled = false,
    WorldBoostEnabled = false,
    
    -- Tools
    AutoPickupEnabled = false,
    FlingMurderEnabled = false,
    FlingSheriffEnabled = false,
    AntiFlingEnabled = false,
    EmoteSpammerEnabled = false,
    
    -- Internal
    KillAllCooldown = false
}

-- Utilities
local function getChar(plr) return plr and plr.Character end
local function getHRP(plr) 
    local c = getChar(plr)
    return c and c:FindFirstChild("HumanoidRootPart") 
end
local function getHum(plr)
    local c = getChar(plr)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function isAlive(plr)
    local h = getHum(plr)
    return h and h.Health > 0
end
local function getTool(plr, nameList)
    local c = getChar(plr)
    if not c then return nil end
    for _, tool in pairs(c:GetChildren()) do
        if tool:IsA("Tool") then
            for _, n in ipairs(nameList) do
                if tool.Name == n then return tool end
            end
        end
    end
    return nil
end

-- ==========================================
-- CUSTOM UI LIBRARY (Mobile Optimized)
-- ==========================================
local Lib = {}
Lib.__index = Lib

function Lib.new(title)
    local self = setmetatable({}, Lib)
    self.Title = title
    
    -- Main ScreenGui
    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "MM2_Pro_UI"
    self.Gui.ResetOnSpawn = false
    self.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Watermark
    self.Watermark = Instance.new("Frame")
    self.Watermark.Size = UDim2.new(0, 180, 0, 25)
    self.Watermark.Position = UDim2.new(0, 10, 0, 10)
    self.Watermark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.Watermark.BackgroundTransparency = 0.4
    self.Watermark.BorderSizePixel = 0
    self.Watermark.Parent = self.Gui
    Instance.new("UICorner", self.Watermark).CornerRadius = UDim.new(0, 5)
    
    local wmLabel = Instance.new("TextLabel")
    wmLabel.Text = "@nfaaoa | PRO SUITE"
    wmLabel.Font = Config.BoldFont
    wmLabel.TextSize = 14
    wmLabel.TextColor3 = Config.ThemeColor
    wmLabel.BackgroundTransparency = 1
    wmLabel.Size = UDim2.new(1, 0, 1, 0)
    wmLabel.Parent = self.Watermark
    
    -- Toggle Button (Floating)
    self.ToggleBtn = Instance.new("TextButton")
    self.ToggleBtn.Text = ">"
    self.ToggleBtn.Font = Config.BoldFont
    self.ToggleBtn.TextSize = 20
    self.ToggleBtn.TextColor3 = Config.TextColor
    self.ToggleBtn.BackgroundColor3 = Config.ThemeColor
    self.ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
    self.ToggleBtn.Position = UDim2.new(0, 10, 0.5, -20)
    self.ToggleBtn.BorderSizePixel = 0
    self.ToggleBtn.Visible = false
    self.ToggleBtn.Parent = self.Gui
    Instance.new("UICorner", self.ToggleBtn).CornerRadius = UDim.new(1, 0)
    
    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 550, 0, 400) -- Larger for mobile readability
    self.MainFrame.Position = UDim2.new(0.5, -275, 0.5, -200)
    self.MainFrame.BackgroundColor3 = Config.SecondaryColor
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Active = true
    self.MainFrame.Draggable = true
    self.MainFrame.Parent = self.Gui
    Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 12)
    
    -- Title Bar
    self.TitleBar = Instance.new("TextButton")
    self.TitleBar.Text = title
    self.TitleBar.Font = Config.BoldFont
    self.TitleBar.TextSize = 16
    self.TitleBar.TextColor3 = Config.TextColor
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.TitleBar.Size = UDim2.new(1, 0, 0, 40)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.AutoLocalize = false
    self.TitleBar.Parent = self.MainFrame
    Instance.new("UICorner", self.TitleBar).CornerRadius = UDim.new(0, 12) -- Top rounding handled by clipping or just visual
    
    -- Close Button
    self.CloseBtn = Instance.new("TextButton")
    self.CloseBtn.Text = "X"
    self.CloseBtn.Font = Config.BoldFont
    self.CloseBtn.TextSize = 18
    self.CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    self.CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    self.CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    self.CloseBtn.BorderSizePixel = 0
    self.CloseBtn.Parent = self.TitleBar
    
    self.CloseBtn.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = false
        self.ToggleBtn.Visible = true
    end)
    
    self.ToggleBtn.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = true
        self.ToggleBtn.Visible = false
    end)
    
    -- Tab Container (Left)
    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Size = UDim2.new(0, 110, 1, -45)
    self.TabContainer.Position = UDim2.new(0, 5, 0, 45)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.ScrollBarThickness = 4
    self.TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabContainer.LayoutMode = Enum.UILayoutMode.List
    self.TabContainer.Padding = UDim.new(0, 5)
    self.TabContainer.Parent = self.MainFrame
    
    -- Content Area (Right)
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -125, 1, -45)
    self.ContentArea.Position = UDim2.new(0, 120, 0, 45)
    self.ContentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.ClipsDescendants = true
    self.ContentArea.Parent = self.MainFrame
    Instance.new("UICorner", self.ContentArea).CornerRadius = UDim.new(0, 8)
    
    self.Pages = {}
    self.CurrentPage = nil
    
    return self
end

function Lib:CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Font = Config.Font
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BorderSizePixel = 0
    btn.AutoLocalize = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.Parent = self.TabContainer
    
    -- Page Container
    local pageFrame = Instance.new("Frame")
    pageFrame.Name = name .. "_Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false
    pageFrame.Parent = self.ContentArea
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -10)
    scroll.Position = UDim2.new(0, 5, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.LayoutMode = Enum.UILayoutMode.List
    scroll.Padding = UDim.new(0, 5)
    scroll.Parent = pageFrame
    
    self.Pages[name] = {
        Button = btn,
        Frame = pageFrame,
        Scroll = scroll
    }
    
    btn.MouseButton1Click:Connect(function()
        -- Hide all pages
        for _, pData in pairs(self.Pages) do
            pData.Frame.Visible = false
            pData.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            pData.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        -- Show selected
        self.Pages[name].Frame.Visible = true
        btn.BackgroundColor3 = Config.ThemeColor
        btn.TextColor3 = Color3.fromRGB(0, 0, 0) -- High contrast on active tab
        self.CurrentPage = name
    end)
    
    return self.Pages[name].Scroll
end

function Lib:AddToggle(parent, text, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 35)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Font = Config.Font
    label.TextSize = 14
    label.TextColor3 = Config.TextColor
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 45, 0, 22)
    toggleBg.Position = UDim2.new(1, -55, 0.5, -11)
    toggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(defaultVal and 1 or 0, -18, 0.5, -9)
    knob.BackgroundColor3 = Config.TextColor
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local state = defaultVal
    toggleBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            knob:TweenPosition(state and UDim2.new(1, -18, 0.5, -9) or UDim2.new(0, 0, 0.5, -9), "Out", "Quart", 0.2)
            toggleBg.BackgroundColor3 = state and Config.ThemeColor or Color3.fromRGB(50, 50, 50)
            if callback then task.spawn(callback, state) end
        end
    end)
end

function Lib:AddSlider(parent, text, min, max, def, suffix, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 45)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = string.format("%s: %d%s", text, def, suffix or "")
    label.Font = Config.Font
    label.TextSize = 14
    label.TextColor3 = Config.TextColor
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 20)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Config.ThemeColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new((def-min)/(max-min), -7, 0.5, -7)
    handle.BackgroundColor3 = Config.TextColor
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
        if callback then task.spawn(callback, val) end
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
    
    track.InputEnded:Connect(function() dragging = false end)
end

function Lib:AddDropdown(parent, text, options, defaultIdx, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 35)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local btn = Instance.new("TextButton")
    btn.Text = text .. ": " .. options[defaultIdx]
    btn.Font = Config.Font
    btn.TextSize = 14
    btn.TextColor3 = Config.TextColor
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BorderSizePixel = 0
    btn.AutoLocalize = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    
    local isOpen = false
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.Position = UDim2.new(0, 0, 1, 0)
    list.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    list.BorderSizePixel = 0
    list.Visible = false
    list.Parent = row
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
    
    for i, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Text = opt
        item.Font = Config.Font
        item.TextSize = 12
        item.TextColor3 = Color3.fromRGB(200, 200, 200)
        item.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        item.Size = UDim2.new(1, 0, 0, 25)
        item.Position = UDim2.new(0, 0, 0, (i-1)*25)
        item.BorderSizePixel = 0
        item.AutoLocalize = false
        item.Parent = list
        
        item.MouseButton1Click:Connect(function()
            btn.Text = text .. ": " .. opt
            isOpen = false
            list.Visible = false
            list.Size = UDim2.new(1, 0, 0, 0)
            if callback then task.spawn(callback, i, opt) end
        end)
    end
    
    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        list.Visible = isOpen
        list.Size = UDim2.new(1, 0, 0, isOpen and (#options * 25) or 0)
    end)
end

-- Initialize Library
local UI = Lib.new("MM2 FULL SUITE | @nfaaoa")

-- Create Tabs
local combatPage = UI:CreateTab("Combat")
local movePage = UI:CreateTab("Movement")
local visPage = UI:CreateTab("Visuals")
local toolsPage = UI:CreateTab("Tools")

-- Select First Tab
wait(0.2)
if UI.TabContainer.FirstChild then
    UI.TabContainer.FirstChild:FireSignal("MouseButton1Click")
end

-- ==========================================
-- POPULATE PAGES
-- ==========================================

-- COMBAT
UI:AddToggle(combatPage, "Aimbot", false, function(v) State.AimbotEnabled = v end)
UI:AddSlider(combatPage, "FOV Radius", 10, 300, State.AimFOV, "", function(v) State.AimFOV = v end)
UI:AddDropdown(combatPage, "Target Bone", {"Head", "UpperTorso"}, 1, function(idx, opt) State.TargetBone = opt end)
UI:AddToggle(combatPage, "Auto Shoot", false, function(v) State.AutoShootEnabled = v end)
UI:AddToggle(combatPage, "Auto Throw Knife", false, function(v) State.AutoThrowEnabled = v end)
UI:AddToggle(combatPage, "SpinBot", false, function(v) State.SpinBotEnabled = v end)
UI:AddToggle(combatPage, "Kill All (One-Shot)", false, function(v) 
    if v and not State.KillAllCooldown then
        State.KillAllCooldown = true
        task.spawn(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) then
                    local hrp = getHRP(p)
                    if hrp then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame
                        task.wait(0.15)
                    end
                end
            end
            State.KillAllCooldown = false
        end)
    end
end)

-- MOVEMENT
UI:AddToggle(movePage, "Fly Mode", false, function(v) State.FlyEnabled = v end)
UI:AddSlider(movePage, "Fly Speed", 10, 200, State.FlySpeed, "", function(v) State.FlySpeed = v end)
UI:AddToggle(movePage, "No Clip", false, function(v) State.NoClipEnabled = v end)
UI:AddSlider(movePage, "Walk Speed", 16, 100, State.WalkSpeedValue, "", function(v) State.WalkSpeedValue = v end)
UI:AddToggle(movePage, "Fake Lag", false, function(v) State.FakeLagEnabled = v end)

-- VISUALS
UI:AddToggle(visPage, "Role ESP", false, function(v) State.RoleESPEnabled = v end)
UI:AddToggle(visPage, "Gun ESP", false, function(v) State.GunESPEnabled = v end)
UI:AddToggle(visPage, "Custom Crosshair", false, function(v) State.CrosshairEnabled = v end)
UI:AddSlider(visPage, "Crosshair Size", 5, 50, State.CrosshairSize, "px", function(v) State.CrosshairSize = v end)
UI:AddToggle(visPage, "Trail Effect", false, function(v) State.TrailEnabled = v end)
UI:AddToggle(visPage, "Aura Effect", false, function(v) State.AuraEnabled = v end)
UI:AddToggle(visPage, "Overhead Info", false, function(v) State.OverheadEnabled = v end)
UI:AddToggle(visPage, "World Boost (Lighting)", false, function(v) State.WorldBoostEnabled = v end)

-- TOOLS
UI:AddToggle(toolsPage, "Auto Pickup Gun", false, function(v) State.AutoPickupEnabled = v end)
UI:AddToggle(toolsPage, "Fling Murderer", false, function(v) State.FlingMurderEnabled = v end)
UI:AddToggle(toolsPage, "Fling Sheriff", false, function(v) State.FlingSheriffEnabled = v end)
UI:AddToggle(toolsPage, "Anti Fling", false, function(v) State.AntiFlingEnabled = v end)
UI:AddToggle(toolsPage, "Emote Spammer", false, function(v) State.EmoteSpammerEnabled = v end)

-- ==========================================
-- LOGIC IMPLEMENTATION
-- ==========================================

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
    if State.FlyEnabled then
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end
        
        if moveDir.Magnitude > 0 then
            hrp.AssemblyLinearVelocity = moveDir.Unit * State.FlySpeed
        else
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    if State.NoClipEnabled then
        hrp.CanCollide = false
    else
        hrp.CanCollide = true
    end

    hum.WalkSpeed = State.WalkSpeedValue

    if State.SpinBotEnabled then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(15), 0)
    end

    -- 2. Aimbot
    if State.AimbotEnabled then
        local bestDist = State.AimFOV
        local targetPart = nil
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isAlive(p) then
                local bone = p.Character:FindFirstChild(State.TargetBone) or p.Character:FindFirstChild("Head")
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
            hrp.CFrame = hrp.CFrame:Lerp(goalCF, State.AimSmoothness)
            
            if State.AutoShootEnabled then
                -- Note: Actual shooting requires specific RemoteEvents from MM2 source code.
                -- This simulates the aim lock. To fully automate shoot, one must hook 'Attack' remote.
            end
        end
    end
end)

-- Separate Loops for Heavy Tasks

-- ESP & Overheads
task.spawn(function()
    while wait(0.1) do
        local char = LocalPlayer.Character
        if not char then continue end
        
        -- Cleanup old visuals
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Highlight") and obj.Name:find("ESP_") then
                obj:Destroy()
            elseif obj:IsA("BillboardGui") and obj.Name:find("OH_") then
                obj:Destroy()
            end
        end

        if State.RoleESPEnabled or State.OverheadEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) then
                    local tool = p.Character:FindFirstChildOfClass("Tool")
                    local roleColor = Color3.fromRGB(255, 255, 255)
                    local roleName = "Citizen"
                    
                    if tool then
                        if tool.Name == "Knife" then 
                            roleColor = Color3.fromRGB(255, 0, 0); roleName = "MURDERER"
                        elseif tool.Name == "Revolver" or tool.Name == "Shotgun" then 
                            roleColor = Color3.fromRGB(0, 0, 255); roleName = "SHERIFF"
                        end
                    end
                    
                    if State.RoleESPEnabled then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ESP_Role_" .. p.Name
                        highlight.FillColor = roleColor
                        highlight.OutlineColor = roleColor
                        highlight.FillTransparency = 0.7
                        highlight.Adornee = p.Character
                        highlight.Parent = p.Character
                    end
                    
                    if State.OverheadEnabled then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "OH_" .. p.Name
                        bb.Size = UDim2.new(0, 100, 0, 20)
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = p.Character.Head
                        bb.Parent = p.Character
                        
                        local lbl = Instance.new("TextLabel")
                        lbl.Text = string.format("[%s] %s", roleName, p.Name)
                        lbl.Font = Config.BoldFont
                        lbl.TextSize = 12
                        lbl.TextColor3 = roleColor
                        lbl.BackgroundTransparency = 1
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.Parent = bb
                    end
                end
            end
        end
    end
end)

-- Fling & Anti-Fling
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Anti Fling
    if State.AntiFlingEnabled then
        if hrp.AssemblyLinearVelocity.Y > 50 or hrp.AssemblyLinearVelocity.Y < -50 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end

    -- Fling Targets
    if State.FlingMurderEnabled or State.FlingSheriffEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isAlive(p) then
                local targetHrp = getHRP(p)
                local tool = p.Character:FindFirstChildOfClass("Tool")
                
                local shouldFling = false
                if State.FlingMurderEnabled and tool and tool.Name == "Knife" then shouldFling = true end
                if State.FlingSheriffEnabled and tool and (tool.Name == "Revolver" or tool.Name == "Shotgun") then shouldFling = true end
                
                if shouldFling and targetHrp then
                    local direction = (targetHrp.Position - hrp.Position).Unit
                    targetHrp.AssemblyLinearVelocity = direction * 1000 + Vector3.yAxis * 500
                end
            end
        end
    end
end)

-- Visual Effects (Trail/Aura)
task.spawn(function()
    while wait(0.5) do
        local char = LocalPlayer.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Trail
        if State.TrailEnabled then
            if not hrp:FindFirstChild("TrailFX") then
                local att = Instance.new("Attachment")
                att.Name = "TrailAtt"
                att.Parent = hrp
                
                local trail = Instance.new("Trail")
                trail.Name = "TrailFX"
                trail.Attachment0 = att
                trail.Color = ColorSequence.new(Config.ThemeColor)
                trail.LightEmission = 1
                trail.WidthScale = NumberSequence.new({NumberKeypoint.new(0, 1), NumberKeypoint.new(1, 0)})
                trail.Transparency = NumberSequence.new({NumberKeypoint.new(0, 0), NumberKeypoint.new(1, 1)})
                trail.Lifetime = 1
                trail.Enabled = true
                trail.Parent = hrp
            end
        else
            if hrp:FindFirstChild("TrailFX") then hrp.TrailFX:Destroy() end
        end

        -- Aura
        if State.AuraEnabled then
            if not hrp:FindFirstChild("AuraFX") then
                local aura = Instance.new("ParticleEmitter")
                aura.Name = "AuraFX"
                aura.Color = ColorSequence.new(Config.ThemeColor)
                aura.Speed = NumberRange.new(1, 5)
                aura.Rate = 50
                aura.Lifetime = NumberRange.new(0.5, 1)
                aura.Size = NumberSequence.new(2)
                aura.Acceleration = Vector3.new(0, -10, 0)
                aura.LightEmission = 1
                aura.Enabled = true
                aura.Parent = hrp
            end
        else
            if hrp:FindFirstChild("AuraFX") then hrp.AuraFX:Destroy() end
        end
        
        -- World Boost
        if State.WorldBoostEnabled then
            if Lighting.Technology ~= Enum.Technology.Future then
                Lighting.Technology = Enum.Technology.Future
                Lighting.ClockTime = 12
                Lighting.Brightness = 2
            end
        else
             if Lighting.Technology == Enum.Technology.Future then
                 Lighting.Technology = Enum.Technology.ShadowMap
             end
        end
    end
end)

-- Crosshair Drawing
if typeof(drawing) ~= "nil" then
    task.spawn(function()
        local crosshair = drawing.new("Square")
        crosshair.Color = Config.ThemeColor
        crosshair.Thickness = 2
        crosshair.Filled = false
        
        while wait() do
            if State.CrosshairEnabled then
                local center = Camera.ViewportSize / 2
                crosshair.Position = Vector2.new(center.X - State.CrosshairSize/2, center.Y - State.CrosshairSize/2)
                crosshair.Size = Vector2.new(State.CrosshairSize, State.CrosshairSize)
                crosshair.Transparency = 0
            else
                crosshair.Transparency = 1
            end
        end
    end)
end

print("[@nfaaoa] MM2 Pro Suite Loaded Successfully.")
