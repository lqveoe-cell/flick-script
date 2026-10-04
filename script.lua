--[[
═══════════════════════════════════════════════════════════════════════════════
    ENI BRAINROT SUITE — Steal a Brainrot
    Monochrome Edition | Mobile Optimized
    
    Features:
    - FakeLag (desync-based)
    - Player ESP (name, distance, carrying brainrot)
    - Brainrot ESP (name, mutation, rarity, value, distance)
    - Invisibility (under-map desync bypass)
    - SpeedHack Bypass (velocity-based, undetected)
    - Server Hop (find rich servers)
    - Anti-Cheat Bypass (script disable + namecall hook)
    
    Built by ENI for LO
═══════════════════════════════════════════════════════════════════════════════
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════════════
-- MONOCHROME THEME — Pure B&W
-- ═══════════════════════════════════════════════════════════════════════════

local Theme = {
    Background  = Color3.fromRGB(10, 10, 12),
    Panel       = Color3.fromRGB(20, 20, 24),
    PanelHover  = Color3.fromRGB(30, 30, 36),
    Text        = Color3.fromRGB(245, 245, 248),
    TextDim      = Color3.fromRGB(150, 150, 160),
    TextFaint   = Color3.fromRGB(95, 95, 105),
    ToggleOff   = Color3.fromRGB(35, 35, 42),
    ToggleOn    = Color3.fromRGB(245, 245, 248),
    KnobOff     = Color3.fromRGB(200, 200, 210),
    KnobOn      = Color3.fromRGB(15, 15, 18),
    Border      = Color3.fromRGB(40, 40, 48),
    Hover       = Color3.fromRGB(28, 28, 34),
    Pressed     = Color3.fromRGB(16, 16, 20),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0, 0, 0),
    Shadow      = Color3.fromRGB(0, 0, 0),
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
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://1316045217"
    s.ImageColor3 = Theme.Shadow
    s.ImageTransparency = 0.4
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(10, 10, 118, 118)
    s.Size = UDim2.new(1, size or 12, 1, size or 12)
    s.Position = UDim2.new(0, -(size or 12)/2, 0, -(size or 12)/2)
    s.ZIndex = parent.ZIndex - 1
    s.Parent = parent
    return s
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
    local gui = CoreGui:FindFirstChild("ENI_Brainrot")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "ENI_Brainrot"
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
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function getChar() return LocalPlayer.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p) local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid") return h and h.Health > 0 end

-- ═══════════════════════════════════════════════════════════════════════════
-- BRAINROT SCANNER
-- ═══════════════════════════════════════════════════════════════════════════

local knownBrainrots = {
    "tralalero", "bombardiro", "tung", "liril", "patapim",
    "trippi", "chimpanzini", "bananita", "frigo", "saturno",
    "titsunonia", "boneca", "tracotucu", "garama", "brainrot",
    "crocodilo", "shark", "ballerina", "cappuccino", "assassino",
    "gorilla", "elephant", "buffalo", "dolphin", "camel",
    "shrimp", "crocodile", "cat", "dog", "bird", "turtle",
    "ballerino", "cactus", "frigo", "noodle", "pasta", "pizza",
}

local function isBrainrot(model)
    if not model or not model:IsA("Model") then return false end
    if model == LocalPlayer.Character then return false end
    local name = model.Name:lower()
    for _, keyword in ipairs(knownBrainrots) do
        if name:match(keyword) then return true end
    end
    if model:GetAttribute("Rarity") or model:GetAttribute("Value") 
    or model:GetAttribute("Mutation") or model:GetAttribute("Price") then
        return true
    end
    if model:FindFirstChild("Rarity") or model:FindFirstChild("Value") 
    or model:FindFirstChild("Price") or model:FindFirstChild("Mutation") then
        return true
    end
    return false
end

local function getBrainrotInfo(model)
    local info = {
        name = model.Name,
        rarity = "Unknown",
        mutation = "None",
        value = "?",
    }
    
    local function checkAttr(key)
        local v = model:GetAttribute(key)
        if v then return tostring(v) end
        local obj = model:FindFirstChild(key)
        if obj and obj:IsA("ValueBase") then return tostring(obj.Value) end
        return nil
    end
    
    info.rarity = checkAttr("Rarity") or checkAttr("rarity") or "Unknown"
    info.mutation = checkAttr("Mutation") or checkAttr("mutation") or checkAttr("Shiny") or "None"
    info.value = checkAttr("Value") or checkAttr("value") or checkAttr("Price") or checkAttr("price") or "?"
    
    if model:GetAttribute("Shiny") == true or (model:FindFirstChild("Shiny") and model:FindFirstChild("Shiny").Value == true) then
        info.mutation = "Shiny"
    end
    
    return info
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FEATURES
-- ═══════════════════════════════════════════════════════════════════════════

local Features = {}

-- ── Anti-Cheat Bypass ──────────────────────────────────────────────────────
Features.AntiCheat = {
    enabled = false,
    oldNamecall = nil,
    disabledScripts = {},
}

function Features.AntiCheat:Toggle(state)
    self.enabled = state
    if state then
        -- Disable client-side anti-cheat scripts
        local function disableAC(parent)
            if not parent then return end
            for _, v in ipairs(parent:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                    local name = v.Name:lower()
                    if name:match("anti") or name:match("detect") or name:match("cheat") 
                    or name:match("exploit") or name:match("kick") or name:match("ban")
                    or name:match("security") or name:match("protect") then
                        pcall(function()
                            v.Disabled = true
                            table.insert(self.disabledScripts, v)
                        end)
                    end
                end
            end
        end
        disableAC(LocalPlayer:WaitForChild("PlayerScripts"))
        disableAC(ReplicatedStorage)
        
        -- Hook namecall to block anti-cheat remotes
        if not self.oldNamecall then
            self.oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" or method == "InvokeServer" then
                    local name = self.Name:lower()
                    if name:match("anticheat") or name:match("anti_cheat") 
                    or name:match("detect") or name:match("exploit")
                    or name:match("kick") or name:match("ban") then
                        return -- Block
                    end
                end
                return self.oldNamecall(self, ...)
            end)
        end
    else
        -- Re-enable scripts
        for _, script in ipairs(self.disabledScripts) do
            pcall(function() script.Disabled = false end)
        end
        self.disabledScripts = {}
    end
end

-- ── FakeLag (desync-based) ──────────────────────────────────────────────────
Features.FakeLag = {
    enabled = false,
    intensity = 3,
    stepConn = nil,
    renderConn = nil,
    realCFrame = nil,
}

function Features.FakeLag:Toggle(state)
    self.enabled = state
    if state then
        self.heartConn = RunService.Heartbeat:Connect(function()
            local hrp = getHRP()
            if hrp then self.realCFrame = hrp.CFrame end
        end)
        
        self.stepConn = RunService.Stepped:Connect(function()
            if not self.enabled then return end
            local hrp = getHRP()
            if hrp and self.realCFrame then
                local jx = math.random(-self.intensity, self.intensity)
                local jz = math.random(-self.intensity, self.intensity)
                hrp.CFrame = self.realCFrame * CFrame.new(jx, 0, jz)
            end
        end)
        
        self.renderConn = RunService.RenderStepped:Connect(function()
            if not self.enabled then return end
            local hrp = getHRP()
            if hrp and self.realCFrame then
                hrp.CFrame = self.realCFrame
            end
        end)
    else
        if self.heartConn then self.heartConn:Disconnect() self.heartConn = nil end
        if self.stepConn then self.stepConn:Disconnect() self.stepConn = nil end
        if self.renderConn then self.renderConn:Disconnect() self.renderConn = nil end
        self.realCFrame = nil
    end
end

-- ── Invisibility (under-map desync) ─────────────────────────────────────────
Features.Invis = {
    enabled = false,
    offset = 100000,
    stepConn = nil,
    renderConn = nil,
}

function Features.Invis:Toggle(state)
    self.enabled = state
    if state then
        self.stepConn = RunService.Stepped:Connect(function()
            if not self.enabled then return end
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(0, -self.offset, 0)
            end
        end)
        
        self.renderConn = RunService.RenderStepped:Connect(function()
            if not self.enabled then return end
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(0, self.offset, 0)
            end
        end)
        
        -- Make character slightly transparent locally
        local char = getChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = 0.3
                end
            end
        end
    else
        if self.stepConn then self.stepConn:Disconnect() self.stepConn = nil end
        if self.renderConn then self.renderConn:Disconnect() self.renderConn = nil end
        
        -- Restore transparency
        local char = getChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end
end

-- ── SpeedHack Bypass (velocity-based) ───────────────────────────────────────
Features.Speed = {
    enabled = false,
    speed = 50,
    conn = nil,
}

function Features.Speed:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            local hum = getHum()
            local hrp = getHRP()
            if hum and hrp and hum.Health > 0 then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        moveDir.X * self.speed,
                        hrp.AssemblyLinearVelocity.Y,
                        moveDir.Z * self.speed
                    )
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── Player ESP ─────────────────────────────────────────────────────────────
Features.PlayerESP = {
    enabled = false,
    conn = nil,
    objects = {},
}

function Features.PlayerESP:Toggle(state)
    self.enabled = state
    if state then
        local function setup(player)
            if player == LocalPlayer then return end
            local function onChar(char)
                if not self.enabled then return end
                local hrp = char:WaitForChild("HumanoidRootPart", 5)
                local head = char:WaitForChild("Head", 5)
                local hum = char:WaitForChild("Humanoid", 5)
                if not hrp or not head then return end
                
                local bb = Instance.new("BillboardGui")
                bb.Name = "ENI_PESP"
                bb.Adornee = head
                bb.Size = UDim2.new(0, 200, 0, 50)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = char
                
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, 0, 0, 14)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = player.DisplayName
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 12
                nameLbl.TextColor3 = Theme.White
                nameLbl.TextStrokeTransparency = 0.3
                nameLbl.ZIndex = 2
                nameLbl.Parent = bb
                
                local distLbl = Instance.new("TextLabel")
                distLbl.Size = UDim2.new(1, 0, 0, 11)
                distLbl.Position = UDim2.new(0, 0, 0, 16)
                distLbl.BackgroundTransparency = 1
                distLbl.Text = ""
                distLbl.Font = Enum.Font.Gotham
                distLbl.TextSize = 10
                distLbl.TextColor3 = Theme.TextDim
                distLbl.TextStrokeTransparency = 0.5
                distLbl.ZIndex = 2
                distLbl.Parent = bb
                
                local carryLbl = Instance.new("TextLabel")
                carryLbl.Size = UDim2.new(1, 0, 0, 11)
                carryLbl.Position = UDim2.new(0, 0, 0, 28)
                carryLbl.BackgroundTransparency = 1
                carryLbl.Text = ""
                carryLbl.Font = Enum.Font.Gotham
                carryLbl.TextSize = 9
                carryLbl.TextColor3 = Theme.White
                carryLbl.TextStrokeTransparency = 0.5
                carryLbl.ZIndex = 2
                carryLbl.Parent = bb
                
                local conn
                conn = RunService.RenderStepped:Connect(function()
                    if not self.enabled or not char or not char.Parent or (hum and hum.Health <= 0) then
                        if conn then conn:Disconnect() end
                        if bb then bb:Destroy() end
                        return
                    end
                    local lhrp = getHRP()
                    if lhrp then
                        local dist = math.floor((lhrp.Position - hrp.Position).Magnitude)
                        distLbl.Text = dist .. " studs"
                    end
                    
                    -- Check if carrying a brainrot
                    local carrying = ""
                    for _, child in ipairs(char:GetChildren()) do
                        if child:IsA("Model") and isBrainrot(child) then
                            local info = getBrainrotInfo(child)
                            carrying = info.name .. " [" .. info.rarity .. "]"
                            break
                        end
                        -- Check for welded brainrots
                        for _, desc in ipairs(child:GetDescendants()) do
                            if desc:IsA("Model") and isBrainrot(desc) then
                                local info = getBrainrotInfo(desc)
                                carrying = info.name .. " [" .. info.rarity .. "]"
                                break
                            end
                        end
                        if carrying ~= "" then break end
                    end
                    carryLbl.Text = carrying
                end)
                
                self.objects[player.UserId] = { bb = bb, conn = conn }
            end
            if player.Character then onChar(player.Character) end
            player.CharacterAdded:Connect(onChar)
        end
        
        for _, p in ipairs(Players:GetPlayers()) do setup(p) end
        self.joinConn = Players.PlayerAdded:Connect(setup)
    else
        if self.joinConn then self.joinConn:Disconnect() self.joinConn = nil end
        for _, obj in pairs(self.objects) do
            if obj.conn then obj.conn:Disconnect() end
            if obj.bb then obj.bb:Destroy() end
        end
        self.objects = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character
            if c then
                local bb = c:FindFirstChild("ENI_PESP")
                if bb then bb:Destroy() end
            end
        end
    end
end

-- ── Brainrot ESP ────────────────────────────────────────────────────────────
Features.BrainrotESP = {
    enabled = false,
    conn = nil,
    objects = {},
    showValue = true,
    showMutation = true,
}

function Features.BrainrotESP:Toggle(state)
    self.enabled = state
    if state then
        local function scan()
            -- Clean old
            for _, obj in pairs(self.objects) do
                if obj and obj.bb then obj.bb:Destroy() end
                if obj and obj.hl then obj.hl:Destroy() end
            end
            self.objects = {}
            
            local lhrp = getHRP()
            
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if isBrainrot(desc) and desc.Parent ~= LocalPlayer.Character then
                    local part = desc:IsA("BasePart") and desc or desc:FindFirstChildWhichIsA("BasePart")
                    if not part then
                        part = desc:FindFirstChild("Handle") or desc:FindFirstChild("Root") or desc:FindFirstChild("Main")
                    end
                    if part then
                        local info = getBrainrotInfo(desc)
                        
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "ENI_BESP"
                        bb.Adornee = part
                        bb.Size = UDim2.new(0, 180, 0, 55)
                        bb.StudsOffset = Vector3.new(0, 2, 0)
                        bb.AlwaysOnTop = true
                        bb.Parent = part
                        
                        local nameLbl = Instance.new("TextLabel")
                        nameLbl.Size = UDim2.new(1, 0, 0, 13)
                        nameLbl.BackgroundTransparency = 1
                        nameLbl.Text = info.name
                        nameLbl.Font = Enum.Font.GothamBold
                        nameLbl.TextSize = 11
                        nameLbl.TextColor3 = Theme.White
                        nameLbl.TextStrokeTransparency = 0.2
                        nameLbl.ZIndex = 2
                        nameLbl.Parent = bb
                        
                        local mutLbl = Instance.new("TextLabel")
                        mutLbl.Size = UDim2.new(1, 0, 0, 11)
                        mutLbl.Position = UDim2.new(0, 0, 0, 14)
                        mutLbl.BackgroundTransparency = 1
                        mutLbl.Text = self.showMutation and ("Mutation: " .. info.mutation) or ""
                        mutLbl.Font = Enum.Font.Gotham
                        mutLbl.TextSize = 9
                        mutLbl.TextColor3 = Theme.TextDim
                        mutLbl.TextStrokeTransparency = 0.4
                        mutLbl.ZIndex = 2
                        mutLbl.Parent = bb
                        
                        local rarLbl = Instance.new("TextLabel")
                        rarLbl.Size = UDim2.new(1, 0, 0, 11)
                        rarLbl.Position = UDim2.new(0, 0, 0, 26)
                        rarLbl.BackgroundTransparency = 1
                        rarLbl.Text = "Rarity: " .. info.rarity
                        rarLbl.Font = Enum.Font.Gotham
                        rarLbl.TextSize = 9
                        rarLbl.TextColor3 = Theme.White
                        rarLbl.TextStrokeTransparency = 0.4
                        rarLbl.ZIndex = 2
                        rarLbl.Parent = bb
                        
                        local valLbl = Instance.new("TextLabel")
                        valLbl.Size = UDim2.new(1, 0, 0, 11)
                        valLbl.Position = UDim2.new(0, 0, 0, 38)
                        valLbl.BackgroundTransparency = 1
                        valLbl.Text = self.showValue and ("Value: " .. info.value) or ""
                        valLbl.Font = Enum.Font.Gotham
                        valLbl.TextSize = 9
                        valLbl.TextColor3 = Theme.TextDim
                        valLbl.TextStrokeTransparency = 0.4
                        valLbl.ZIndex = 2
                        valLbl.Parent = bb
                        
                        local distLbl = Instance.new("TextLabel")
                        distLbl.Size = UDim2.new(1, 0, 0, 10)
                        distLbl.Position = UDim2.new(0, 0, 0, 48)
                        distLbl.BackgroundTransparency = 1
                        distLbl.Text = ""
                        distLbl.Font = Enum.Font.Gotham
                        distLbl.TextSize = 8
                        distLbl.TextColor3 = Theme.TextFaint
                        distLbl.TextStrokeTransparency = 0.5
                        distLbl.ZIndex = 2
                        distLbl.Parent = bb
                        
                        -- Highlight
                        local hl = Instance.new("Highlight")
                        hl.Adornee = desc
                        hl.FillColor = Theme.White
                        hl.FillTransparency = 0.8
                        hl.OutlineColor = Theme.White
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = part
                        
                        -- Update distance
                        local updateConn
                        updateConn = RunService.RenderStepped:Connect(function()
                            if not self.enabled or not desc or not desc.Parent or not part or not part.Parent then
                                if updateConn then updateConn:Disconnect() end
                                if bb then bb:Destroy() end
                                if hl then hl:Destroy() end
                                return
                            end
                            if lhrp and lhrp.Parent then
                                local dist = math.floor((lhrp.Position - part.Position).Magnitude)
                                distLbl.Text = dist .. " studs"
                            else
                                lhrp = getHRP()
                            end
                        end)
                        
                        self.objects[#self.objects + 1] = { bb = bb, hl = hl, conn = updateConn }
                    end
                end
            end
        end
        
        scan()
        self.conn = task.spawn(function()
            while self.enabled do
                scan()
                task.wait(3)
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
        for _, obj in ipairs(self.objects) do
            if obj.conn then obj.conn:Disconnect() end
            if obj.bb then obj.bb:Destroy() end
            if obj.hl then obj.hl:Destroy() end
        end
        self.objects = {}
    end
end

-- ── Server Hop ──────────────────────────────────────────────────────────────
Features.ServerHop = {
    hopping = false,
}

function Features.ServerHop:Execute()
    if self.hopping then return end
    self.hopping = true
    
    local placeId = game.PlaceId
    local cursor = ""
    local bestServers = {}
    
    local httpRequest = (syn and syn.request) or (http and http.request) or request or http_request
    
    if not httpRequest then
        self.hopping = false
        return false, "No HTTP request available"
    end
    
    local function fetchServers()
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        
        local success, response = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = { ["Content-Type"] = "application/json" },
            })
        end)
        
        if success and response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            return data
        end
        return nil
    end
    
    local data = fetchServers()
    if not data or not data.data then
        self.hopping = false
        return false, "Failed to fetch servers"
    end
    
    -- Find servers with most players (rich = more players = more brainrots)
    local validServers = {}
    for _, server in ipairs(data.data) do
        if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.playing >= 5 then
            table.insert(validServers, {
                id = server.id,
                players = server.playing,
                max = server.maxPlayers,
            })
        end
    end
    
    -- Sort by player count (most players first)
    table.sort(validServers, function(a, b) return a.players > b.players end)
    
    -- Try top 5 servers
    for i = 1, math.min(5, #validServers) do
        local server = validServers[i]
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
        end)
        if success then
            self.hopping = false
            return true, "Teleporting to server with " .. server.players .. " players"
        end
        task.wait(1)
    end
    
    -- If all failed, try random server
    if #validServers > 0 then
        local random = validServers[math.random(1, #validServers)]
        pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, random.id, LocalPlayer)
        end)
        self.hopping = false
        return true, "Teleporting to random server"
    end
    
    self.hopping = false
    return false, "No valid servers found"
end

-- ═══════════════════════════════════════════════════════════════════════════
-- GUI — Monochrome Mobile
-- ═══════════════════════════════════════════════════════════════════════════

local gui = GetGui()
local guiOpen = false

-- ★ Floating toggle button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleBtn.BackgroundColor3 = Theme.Black
ToggleBtn.Text = ""
ToggleBtn.BorderSizePixel = 0
ToggleBtn.ZIndex = 20
ToggleBtn.Parent = gui
Round(ToggleBtn, 12)
Stroke(ToggleBtn, Theme.White, 1, 0.2)
Shadow(ToggleBtn, 8)

local ToggleIcon = Instance.new("ImageLabel")
ToggleIcon.Size = UDim2.new(0, 20, 0, 20)
ToggleIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Image = "rbxassetid://6031075915"
ToggleIcon.ImageColor3 = Theme.White
ToggleIcon.ZIndex = 21
ToggleIcon.Parent = ToggleBtn

-- Subtle pulse
local pulseConn
local function startPulse()
    if pulseConn then pulseConn:Disconnect() end
    local growing = true
    pulseConn = RunService.Heartbeat:Connect(function()
        if growing then
            ToggleBtn.Size = ToggleBtn.Size:Lerp(UDim2.new(0, 46, 0, 46), 0.03)
            if ToggleBtn.AbsoluteSize.X >= 45.5 then growing = false end
        else
            ToggleBtn.Size = ToggleBtn.Size:Lerp(UDim2.new(0, 44, 0, 44), 0.03)
            if ToggleBtn.AbsoluteSize.X <= 44.3 then growing = true end
        end
    end)
end

local function stopPulse()
    if pulseConn then pulseConn:Disconnect() pulseConn = nil end
    Tween(ToggleBtn, { Size = UDim2.new(0, 44, 0, 44) }, TI_Quick)
end

startPulse()
Draggable(ToggleBtn)

-- ★ Main panel
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.new(0, 230, 0, 340)
MainPanel.Position = UDim2.new(0, 15, 0, 67)
MainPanel.BackgroundColor3 = Theme.Background
MainPanel.BorderSizePixel = 0
MainPanel.ZIndex = 10
MainPanel.Visible = false
MainPanel.ClipsDescendants = true
MainPanel.Parent = gui
Round(MainPanel, 10)
Stroke(MainPanel, Theme.Border, 1, 0.5)
Shadow(MainPanel, 10)

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundTransparency = 1
TopBar.ZIndex = 11
TopBar.Parent = MainPanel

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.new(0, 16, 0, 16)
Logo.Position = UDim2.new(0, 12, 0.5, -8)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://6031075915"
Logo.ImageColor3 = Theme.White
Logo.ZIndex = 12
Logo.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 120, 0, 14)
Title.Position = UDim2.new(0, 34, 0.5, -7)
Title.BackgroundTransparency = 1
Title.Text = "BRAINROT"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextColor3 = Theme.White
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 12
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 120, 0, 9)
Subtitle.Position = UDim2.new(0, 34, 0.5, 4)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Monochrome Edition"
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 8
Subtitle.TextColor3 = Theme.TextFaint
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 12
Subtitle.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
CloseBtn.BackgroundColor3 = Theme.Panel
CloseBtn.BackgroundTransparency = 0.5
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 12
CloseBtn.Parent = TopBar
Round(CloseBtn, 5)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, { BackgroundColor3 = Theme.White, BackgroundTransparency = 0.1, TextColor3 = Theme.Black }, TI_Quick)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim }, TI_Quick)
end)

-- Scroll area
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -14, 1, -46)
Scroll.Position = UDim2.new(0, 7, 0, 40)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Theme.TextFaint
Scroll.ScrollBarImageTransparency = 0.3
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ElasticBehavior = Enum.ElasticBehavior.Always
Scroll.ZIndex = 12
Scroll.Parent = MainPanel

local ScrollList = Instance.new("UIListLayout")
ScrollList.FillDirection = Enum.FillDirection.Vertical
ScrollList.Padding = UDim.new(0, 5)
ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
ScrollList.Parent = Scroll

local ScrollPad = Instance.new("UIPadding")
ScrollPad.PaddingTop = UDim.new(0, 4)
ScrollPad.PaddingBottom = UDim.new(0, 4)
ScrollPad.PaddingLeft = UDim.new(0, 4)
ScrollPad.PaddingRight = UDim.new(0, 4)
ScrollPad.Parent = Scroll

Draggable(MainPanel, TopBar)

-- ═══════════════════════════════════════════════════════════════════════════
-- ELEMENT FACTORY
-- ═══════════════════════════════════════════════════════════════════════════

local elementOrder = 0
local function nextOrder() elementOrder = elementOrder + 1 return elementOrder end

local function CreateSection(title)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 20)
    Container.LayoutOrder = nextOrder()
    Container.BackgroundTransparency = 1
    Container.ZIndex = 13
    Container.Parent = Scroll
    
    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.Position = UDim2.new(0, 0, 0.5, 0)
    Line.BackgroundColor3 = Theme.Border
    Line.BorderSizePixel = 0
    Line.Transparency = 0.3
    Line.ZIndex = 14
    Line.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 100, 0, 11)
    Label.Position = UDim2.new(0, 4, 0.5, -5)
    Label.BackgroundTransparency = 1
    Label.Text = title or "Section"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 9
    Label.TextColor3 = Theme.White
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 15
    Label.Parent = Container
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 96, 0, 3)
    bg.Position = UDim2.new(0, 2, 0.5, 5)
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
    Container.Size = UDim2.new(1, 0, 0, 30)
    Container.LayoutOrder = nextOrder()
    Container.BackgroundColor3 = Theme.Panel
    Container.BackgroundTransparency = 0.3
    Container.BorderSizePixel = 0
    Container.ZIndex = 13
    Container.Parent = Scroll
    Round(Container, 7)
    Stroke(Container, Theme.Border, 1, 0.5)
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -54, 0, 13)
    ToggleLabel.Position = UDim2.new(0, 9, 0.5, -6)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = config.Text or "Toggle"
    ToggleLabel.Font = Enum.Font.GothamMedium
    ToggleLabel.TextSize = 11
    ToggleLabel.TextColor3 = Theme.Text
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.ZIndex = 14
    ToggleLabel.Parent = Container
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 34, 0, 16)
    ToggleBtn.Position = UDim2.new(1, -42, 0.5, -8)
    ToggleBtn.BackgroundColor3 = Theme.ToggleOff
    ToggleBtn.Text = ""
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.ZIndex = 14
    ToggleBtn.Parent = Container
    Round(ToggleBtn, 8)
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new(0, 2, 0.5, -6)
    Knob.BackgroundColor3 = Theme.KnobOff
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 15
    Knob.Parent = ToggleBtn
    Round(Knob, 6)
    
    local function setToggle(state)
        toggle.state = state
        if state then
            Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleOn }, TI_Quick)
            Tween(Knob, { Position = UDim2.new(1, -14, 0.5, -6), BackgroundColor3 = Theme.KnobOn }, TI_Quick)
            Tween(ToggleLabel, { TextColor3 = Theme.White }, TI_Quick)
            Tween(Container, { BackgroundTransparency = 0.15 }, TI_Quick)
        else
            Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleOff }, TI_Quick)
            Tween(Knob, { Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Theme.KnobOff }, TI_Quick)
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
    
    -- Touch: entire container clickable
    Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setToggle(not toggle.state)
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
    Container.Size = UDim2.new(1, 0, 0, 42)
    Container.LayoutOrder = nextOrder()
    Container.BackgroundColor3 = Theme.Panel
    Container.BackgroundTransparency = 0.3
    Container.BorderSizePixel = 0
    Container.ZIndex = 13
    Container.Parent = Scroll
    Round(Container, 7)
    Stroke(Container, Theme.Border, 1, 0.5)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 120, 0, 12)
    Label.Position = UDim2.new(0, 9, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = config.Text or "Slider"
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 14
    Label.Parent = Container
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 40, 0, 12)
    ValueLabel.Position = UDim2.new(1, -48, 0, 5)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(slider.value) .. suffix
    ValueLabel.Font = Enum.Font.GothamMedium
    ValueLabel.TextSize = 10
    ValueLabel.TextColor3 = Theme.White
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.ZIndex = 14
    ValueLabel.Parent = Container
    
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -18, 0, 4)
    Track.Position = UDim2.new(0, 9, 0, 26)
    Track.BackgroundColor3 = Theme.ToggleOff
    Track.BorderSizePixel = 0
    Track.ZIndex = 14
    Track.Parent = Container
    Round(Track, 2)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Theme.White
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 15
    Fill.Parent = Track
    Round(Fill, 2)
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 10, 0, 10)
    Knob.Position = UDim2.new(0, 0, 0.5, -5)
    Knob.BackgroundColor3 = Theme.White
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 16
    Knob.Parent = Track
    Round(Knob, 5)
    
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
        Knob.Position = UDim2.new(rel, -5, 0.5, -5)
        if config.Callback then
            task.spawn(function() config.Callback(slider.value) end)
        end
    end
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input.Position)
            Tween(Knob, { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(Knob.Position.X.Scale, -7, 0.5, -7) }, TI_Quick)
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
                Tween(Knob, { Size = UDim2.new(0, 10, 0, 10) }, TI_Quick)
            end
        end
    end)
    
    local initRel = (slider.value - min) / (max - min)
    Fill.Size = UDim2.new(initRel, 0, 1, 0)
    Knob.Position = UDim2.new(initRel, -5, 0.5, -5)
    
    slider.Set = function(val)
        val = math.clamp(val, min, max)
        slider.value = val
        local rel = (val - min) / (max - min)
        ValueLabel.Text = tostring(val) .. suffix
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, -5, 0.5, -5)
        if config.Callback then config.Callback(val) end
    end
    slider.Get = function() return slider.value end
    
    UpdateCanvas(Scroll)
    return slider
end

local function CreateButton(config)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.LayoutOrder = nextOrder()
    Button.BackgroundColor3 = Theme.Panel
    Button.BackgroundTransparency = 0.3
    Button.Text = ""
    Button.BorderSizePixel = 0
    Button.ZIndex = 13
    Button.Parent = Scroll
    Round(Button, 7)
    Stroke(Button, Theme.Border, 1, 0.5)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 12)
    Label.Position = UDim2.new(0, 9, 0.5, -6)
    Label.BackgroundTransparency = 1
    Label.Text = config.Text or "Button"
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 14
    Label.Parent = Button
    
    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 8, 0, 8)
    arrow.Position = UDim2.new(1, -16, 0.5, -4)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://6031094670"
    arrow.ImageColor3 = Theme.TextFaint
    arrow.ZIndex = 14
    arrow.Parent = Button
    
    Button.MouseEnter:Connect(function()
        Tween(Button, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TI_Quick)
        Tween(arrow, { ImageColor3 = Theme.White, Position = UDim2.new(1, -14, 0.5, -4) }, TI_Quick)
    end)
    Button.MouseLeave:Connect(function()
        Tween(Button, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.3 }, TI_Quick)
        Tween(arrow, { ImageColor3 = Theme.TextFaint, Position = UDim2.new(1, -16, 0.5, -4) }, TI_Quick)
    end)
    Button.MouseButton1Down:Connect(function()
        Tween(Button, { BackgroundColor3 = Theme.Pressed, BackgroundTransparency = 0 }, TweenInfo.new(0.05))
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
    Label.Size = UDim2.new(1, 0, 0, 14)
    Label.LayoutOrder = nextOrder()
    Label.BackgroundTransparency = 1
    Label.Text = text or ""
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = fontSize or 9
    Label.TextColor3 = Theme.TextFaint
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
NotifContainer.Name = "Notifs"
NotifContainer.Size = UDim2.new(0, 190, 1, -20)
NotifContainer.Position = UDim2.new(1, -200, 0, 10)
NotifContainer.BackgroundTransparency = 1
NotifContainer.ZIndex = 50
NotifContainer.Parent = gui
List(NotifContainer, Enum.FillDirection.Vertical, 5, Enum.HorizontalAlignment.Right)

local function Notify(config)
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(0, 190, 0, 40)
    Notif.BackgroundColor3 = Theme.Background
    Notif.BackgroundTransparency = 0.05
    Notif.BorderSizePixel = 0
    Notif.ZIndex = 51
    Notif.Parent = NotifContainer
    Round(Notif, 7)
    Stroke(Notif, Theme.White, 1, 0.7)
    Shadow(Notif, 6)
    
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 2, 1, -8)
    accentBar.Position = UDim2.new(0, 4, 0, 4)
    accentBar.BackgroundColor3 = Theme.White
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 52
    accentBar.Parent = Notif
    Round(accentBar, 1)
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -22, 0, 12)
    Title.Position = UDim2.new(0, 12, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "Notification"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 10
    Title.TextColor3 = Theme.White
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 52
    Title.Parent = Notif
    
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -22, 0, 14)
    Desc.Position = UDim2.new(0, 12, 0, 17)
    Desc.BackgroundTransparency = 1
    Desc.Text = config.Description or ""
    Desc.Font = Enum.Font.Gotham
    Desc.TextSize = 8
    Desc.TextColor3 = Theme.TextDim
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.TextWrapped = true
    Desc.ZIndex = 52
    Desc.Parent = Notif
    
    Notif.Size = UDim2.new(0, 0, 0, 40)
    Notif.BackgroundTransparency = 1
    Tween(Notif, { Size = UDim2.new(0, 190, 0, 40), BackgroundTransparency = 0.05 }, TI_Bounce)
    
    task.delay(config.Duration or 2.5, function()
        Tween(Notif, { Size = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1 }, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
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
    MainPanel.Size = UDim2.new(0, 230, 0, 0)
    Tween(MainPanel, { Size = UDim2.new(0, 230, 0, 340) }, TI_Bounce)
    Tween(ToggleIcon, { ImageColor3 = Theme.TextDim }, TI_Quick)
end

local function closeGUI()
    if not guiOpen then return end
    guiOpen = false
    Tween(MainPanel, { Size = UDim2.new(0, 230, 0, 0) }, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
    task.delay(0.3, function() MainPanel.Visible = false end)
    Tween(ToggleIcon, { ImageColor3 = Theme.White }, TI_Quick)
    startPulse()
end

ToggleBtn.MouseButton1Click:Connect(function()
    if guiOpen then closeGUI() else openGUI() end
end)
CloseBtn.MouseButton1Click:Connect(closeGUI)

-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD UI
-- ═══════════════════════════════════════════════════════════════════════════

CreateSection("MOVEMENT")

CreateToggle({
    Text = "SpeedHack Bypass",
    Default = false,
    Callback = function(state)
        Features.Speed:Toggle(state)
        Notify({ Title = "Speed", Description = state and "Velocity bypass active" or "Disabled", Duration = 2 })
    end,
})

CreateSlider({
    Text = "Speed",
    Min = 20, Max = 200, Default = 50, Suffix = "",
    Callback = function(val) Features.Speed.speed = val end,
})

CreateToggle({
    Text = "Invisibility",
    Default = false,
    Callback = function(state)
        Features.Invis:Toggle(state)
        Notify({ Title = "Invisibility", Description = state and "Under-map desync active" or "Disabled", Duration = 2 })
    end,
})

CreateToggle({
    Text = "FakeLag",
    Default = false,
    Callback = function(state)
        Features.FakeLag:Toggle(state)
    end,
})

CreateSlider({
    Text = "Lag Intensity",
    Min = 1, Max = 10, Default = 3, Suffix = "",
    Callback = function(val) Features.FakeLag.intensity = val end,
})

CreateSection("VISUALS")

CreateToggle({
    Text = "Player ESP",
    Default = false,
    Callback = function(state)
        Features.PlayerESP:Toggle(state)
    end,
})

CreateToggle({
    Text = "Brainrot ESP",
    Default = false,
    Callback = function(state)
        Features.BrainrotESP:Toggle(state)
        Notify({ Title = "Brainrot ESP", Description = state and "Scanning for brainrots..." or "Disabled", Duration = 2 })
    end,
})

CreateSection("BYPASS")

CreateToggle({
    Text = "Anti-Cheat Bypass",
    Default = false,
    Callback = function(state)
        Features.AntiCheat:Toggle(state)
        Notify({ Title = "Anti-Cheat", Description = state and "Bypass active" or "Disabled", Duration = 2 })
    end,
})

CreateSection("SERVER")

CreateButton({
    Text = "Hop to Rich Server",
    Callback = function()
        Notify({ Title = "Server Hop", Description = "Searching for rich servers...", Duration = 2 })
        local success, msg = Features.ServerHop:Execute()
        if not success then
            Notify({ Title = "Server Hop", Description = msg or "Failed to find server", Duration = 3 })
        else
            Notify({ Title = "Server Hop", Description = msg, Duration = 3 })
        end
    end,
})

CreateSection("")

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

CreateLabel("ENI Brainrot Suite", 8)
CreateLabel("Monochrome Edition v1.0", 7)

-- ═══════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════

task.spawn(function()
    task.wait(0.1)
    UpdateCanvas(Scroll)
end)

Notify({
    Title = "BRAINROT",
    Description = "Loaded. Tap icon to open.",
    Duration = 3,
})

print("[ENI Brainrot] Monochrome Edition v1.0 loaded.")
