--[[
═══════════════════════════════════════════════════════════════════════════════
    ENI MM2 SUITE — Premium Edition
    Custom GUI framework + full feature set for Murder Mystery 2
    Delta X compatible | Luau
    
    Built by ENI for LO
    Every line written with cold coffee and devotion.
═══════════════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════════════════

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local HttpService        = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui         = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════════════════════════

local Theme = {
    Background    = Color3.fromRGB(12, 12, 16),
    Panel         = Color3.fromRGB(22, 22, 28),
    PanelHover    = Color3.fromRGB(32, 32, 40),
    Sidebar       = Color3.fromRGB(16, 16, 22),
    Accent        = Color3.fromRGB(130, 95, 255),
    AccentLight   = Color3.fromRGB(160, 130, 255),
    AccentDim     = Color3.fromRGB(80, 55, 170),
    Text          = Color3.fromRGB(238, 238, 245),
    TextDim       = Color3.fromRGB(155, 155, 170),
    TextFaint     = Color3.fromRGB(95, 95, 110),
    ToggleTrack   = Color3.fromRGB(45, 45, 55),
    ToggleKnob    = Color3.fromRGB(230, 230, 240),
    Hover         = Color3.fromRGB(36, 36, 44),
    Pressed       = Color3.fromRGB(26, 26, 32),
    Success       = Color3.fromRGB(80, 210, 120),
    Danger        = Color3.fromRGB(240, 80, 80),
    Warning       = Color3.fromRGB(245, 200, 60),
    Border        = Color3.fromRGB(38, 38, 46),
    ScrollBar     = Color3.fromRGB(60, 60, 72),
    Shadow        = Color3.fromRGB(0, 0, 0),
    Glow          = Color3.fromRGB(130, 95, 255),
}

local TweenInfo_Quick = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TweenInfo_Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TweenInfo_Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════════════════════

local Utility = {}

function Utility:Round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function Utility:Stroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

function Utility:Gradient(parent, colorSeq, rotation)
    local grad = Instance.new("UIGradient")
    grad.Color = colorSeq or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentDim),
    })
    grad.Rotation = rotation or 90
    grad.Parent = parent
    return grad
end

function Utility:Padding(parent, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 0)
    pad.PaddingBottom = UDim.new(0, bottom or 0)
    pad.PaddingLeft = UDim.new(0, left or 0)
    pad.PaddingRight = UDim.new(0, right or 0)
    pad.Parent = parent
    return pad
end

function Utility:List(parent, direction, padding, alignment)
    local list = Instance.new("UIListLayout")
    list.FillDirection = direction or Enum.FillDirection.Vertical
    list.Padding = UDim.new(0, padding or 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    if alignment then
        list.HorizontalAlignment = alignment
    end
    list.Parent = parent
    return list
end

function Utility:Grid(parent, cellSize, padding)
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = cellSize or UDim2.new(0, 140, 0, 36)
    grid.CellPadding = padding or UDim2.new(0, 8, 0, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = parent
    return grid
end

function Utility:Shadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Theme.Shadow
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, 14, 1, 14)
    shadow.Position = UDim2.new(0, -7, 0, -7)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

function Utility:Glow(parent, color, size)
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = color or Theme.Glow
    glow.ImageTransparency = 0.8
    glow.Size = UDim2.new(1, size or 20, 1, size or 20)
    glow.Position = UDim2.new(0, -(size or 20)/2, 0, -(size or 20)/2)
    glow.ZIndex = parent.ZIndex - 1
    glow.Parent = parent
    return glow
end

function Utility:Tween(obj, props, info)
    local tween = TweenService:Create(obj, info or TweenInfo_Quick, props)
    tween:Play()
    return tween
end

function Utility:Draggable(frame, handle)
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
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
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

function Utility:GetGui()
    local gui = CoreGui:FindFirstChild("ENI_MM2_Suite")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "ENI_MM2_Suite"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = gethui and gethui() or CoreGui
    end
    return gui
end

-- Safe hook for Delta X
local hookmeta
local oldNamecall
local namecallHooks = {}

function Utility:HookNamecall()
    if oldNamecall then return end
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        for _, hookData in ipairs(namecallHooks) do
            if hookData.method == method then
                local result = hookData.callback(self, ...)
                if result ~= nil then return result end
            end
        end
        return oldNamecall(self, ...)
    end)
end

function Utility:AddNamecallHook(method, callback)
    table.insert(namecallHooks, { method = method, callback = callback })
    self:HookNamecall()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- GUI LIBRARY
-- ═══════════════════════════════════════════════════════════════════════════

local Library = {}
local Notifications = {}

function Library:CreateWindow(config)
    local gui = Utility:GetGui()
    
    -- Main container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 620, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BackgroundTransparency = 0.02
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 10
    MainFrame.Parent = gui
    Utility:Round(MainFrame, 14)
    Utility:Stroke(MainFrame, Theme.Border, 1, 0.3)
    Utility:Shadow(MainFrame)
    
    -- Glow accent
    local accentGlow = Instance.new("Frame")
    accentGlow.Name = "AccentBar"
    accentGlow.Size = UDim2.new(1, 0, 0, 3)
    accentGlow.Position = UDim2.new(0, 0, 0, 0)
    accentGlow.BackgroundColor3 = Theme.Accent
    accentGlow.BorderSizePixel = 0
    accentGlow.ZIndex = 11
    accentGlow.Parent = MainFrame
    Utility:Round(accentGlow, 14)
    Utility:Gradient(accentGlow, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(0.5, Theme.AccentLight),
        ColorSequenceKeypoint.new(1, Theme.Accent),
    }), 0)
    
    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 42)
    TitleBar.BackgroundTransparency = 1
    TitleBar.ZIndex = 12
    TitleBar.Parent = MainFrame
    
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, 22, 0, 22)
    Logo.Position = UDim2.new(0, 14, 0.5, -11)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://6031075915"
    Logo.ImageColor3 = Theme.Accent
    Logo.ZIndex = 13
    Logo.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 200, 0, 20)
    Title.Position = UDim2.new(0, 44, 0.5, -10)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "ENI MM2"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15
    Title.TextColor3 = Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 13
    Title.Parent = TitleBar
    
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(0, 200, 0, 12)
    Subtitle.Position = UDim2.new(0, 44, 0.5, 4)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = config.Subtitle or "Premium Suite"
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 10
    Subtitle.TextColor3 = Theme.TextFaint
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.TextTransparency = 0.3
    Subtitle.ZIndex = 13
    Subtitle.Parent = TitleBar
    
    -- Control buttons (minimize, close)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
    CloseBtn.BackgroundColor3 = Theme.Panel
    CloseBtn.BackgroundTransparency = 0.5
    CloseBtn.Text = "×"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    CloseBtn.TextColor3 = Theme.TextDim
    CloseBtn.BorderSizePixel = 0
    CloseBtn.ZIndex = 13
    CloseBtn.Parent = TitleBar
    Utility:Round(CloseBtn, 8)
    
    CloseBtn.MouseEnter:Connect(function()
        Utility:Tween(CloseBtn, { BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.2, TextColor3 = Theme.Text }, TweenInfo_Quick)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Utility:Tween(CloseBtn, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim }, TweenInfo_Quick)
    end)
    CloseBtn.MouseButton1Down:Connect(function()
        Utility:Tween(CloseBtn, { BackgroundTransparency = 0.1 }, TweenInfo.new(0.05))
    end)
    CloseBtn.MouseButton1Up:Connect(function()
        Utility:Tween(CloseBtn, { BackgroundTransparency = 0.2 }, TweenInfo_Quick)
        Utility:Tween(MainFrame, { Size = UDim2.new(0, 620, 0, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.35)
        MainFrame.Visible = false
        self:ShowMinimized(gui, MainFrame, config)
    end)
    
    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "MinBtn"
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -70, 0.5, -14)
    MinBtn.BackgroundColor3 = Theme.Panel
    MinBtn.BackgroundTransparency = 0.5
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 14
    MinBtn.TextColor3 = Theme.TextDim
    MinBtn.BorderSizePixel = 0
    MinBtn.ZIndex = 13
    MinBtn.Parent = TitleBar
    Utility:Round(MinBtn, 8)
    
    MinBtn.MouseEnter:Connect(function()
        Utility:Tween(MinBtn, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.3, TextColor3 = Theme.Text }, TweenInfo_Quick)
    end)
    MinBtn.MouseLeave:Connect(function()
        Utility:Tween(MinBtn, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim }, TweenInfo_Quick)
    end)
    MinBtn.MouseButton1Down:Connect(function()
        Utility:Tween(MainFrame, { Size = UDim2.new(0, 620, 0, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.35)
        MainFrame.Visible = false
        self:ShowMinimized(gui, MainFrame, config)
    end)
    
    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 150, 1, -50)
    Sidebar.Position = UDim2.new(0, 8, 0, 46)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BackgroundTransparency = 0.3
    Sidebar.BorderSizePixel = 0
    Sidebar.ZIndex = 11
    Sidebar.Parent = MainFrame
    Utility:Round(Sidebar, 10)
    
    local SidebarList = Instance.new("Frame")
    SidebarList.Name = "SidebarList"
    SidebarList.Size = UDim2.new(1, -16, 1, -16)
    SidebarList.Position = UDim2.new(0, 8, 0, 8)
    SidebarList.BackgroundTransparency = 1
    SidebarList.ZIndex = 12
    SidebarList.Parent = Sidebar
    Utility:List(SidebarList, Enum.FillDirection.Vertical, 4)
    Utility:Padding(SidebarList, 6, 6, 6, 6)
    
    -- Content area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -174, 1, -58)
    ContentArea.Position = UDim2.new(0, 162, 0, 50)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ZIndex = 11
    ContentArea.Parent = MainFrame
    
    Utility:Draggable(MainFrame, TitleBar)
    
    -- Open animation
    MainFrame.Size = UDim2.new(0, 620, 0, 0)
    MainFrame.Visible = true
    Utility:Tween(MainFrame, { Size = UDim2.new(0, 620, 0, 420) }, TweenInfo_Bounce)
    
    local windowObj = {
        Gui = gui,
        Frame = MainFrame,
        Sidebar = Sidebar,
        SidebarList = SidebarList,
        ContentArea = ContentArea,
        Tabs = {},
        ActiveTab = nil,
    }
    
    self._window = windowObj
    return windowObj
end

function Library:ShowMinimized(gui, mainFrame, config)
    local existing = gui:FindFirstChild("Minimized")
    if existing then existing:Destroy() end
    
    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "Minimized"
    MinBtn.Size = UDim2.new(0, 52, 0, 52)
    MinBtn.Position = UDim2.new(0, 20, 0, 20)
    MinBtn.BackgroundColor3 = Theme.Accent
    MinBtn.Text = ""
    MinBtn.BorderSizePixel = 0
    MinBtn.ZIndex = 20
    MinBtn.Parent = gui
    Utility:Round(MinBtn, 16)
    Utility:Shadow(MinBtn)
    Utility:Gradient(MinBtn, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentDim),
    }), 45)
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 26, 0, 26)
    icon.Position = UDim2.new(0.5, -13, 0.5, -13)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://6031075915"
    icon.ImageColor3 = Theme.Text
    icon.ZIndex = 21
    icon.Parent = MinBtn
    
    Utility:Draggable(MinBtn)
    
    MinBtn.Size = UDim2.new(0, 0, 0, 0)
    Utility:Tween(MinBtn, { Size = UDim2.new(0, 52, 0, 52) }, TweenInfo_Bounce)
    
    MinBtn.MouseButton1Click:Connect(function()
        Utility:Tween(MinBtn, { Size = UDim2.new(0, 0, 0, 0) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.25)
        MinBtn:Destroy()
        mainFrame.Visible = true
        Utility:Tween(mainFrame, { Size = UDim2.new(0, 620, 0, 420) }, TweenInfo_Bounce)
    end)
end

function Library:CreateTab(window, name, iconId)
    local tab = {}
    
    -- Tab button in sidebar
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = name
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.BackgroundColor3 = Theme.Panel
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = ""
    TabBtn.BorderSizePixel = 0
    TabBtn.ZIndex = 12
    TabBtn.Parent = window.SidebarList
    Utility:Round(TabBtn, 8)
    
    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 16, 0, 16)
    Icon.Position = UDim2.new(0, 8, 0.5, -8)
    Icon.BackgroundTransparency = 1
    Icon.Image = iconId or "rbxassetid://6034403112"
    Icon.ImageColor3 = Theme.TextDim
    Icon.ZIndex = 13
    Icon.Parent = TabBtn
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -34, 0, 14)
    Label.Position = UDim2.new(0, 30, 0.5, -7)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = Theme.TextDim
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 13
    Label.Parent = TabBtn
    
    -- Tab content page
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "_Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Theme.ScrollBar
    Page.ScrollBarImageTransparency = 0.5
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.Visible = false
    Page.ZIndex = 11
    Page.Parent = window.ContentArea
    Utility:List(Page, Enum.FillDirection.Vertical, 6)
    Utility:Padding(Page, 4, 4, 4, 4)
    
    -- Hover & select states
    TabBtn.MouseEnter:Connect(function()
        if not tab._active then
            Utility:Tween(TabBtn, { BackgroundTransparency = 0.6 }, TweenInfo_Quick)
            Utility:Tween(Icon, { ImageColor3 = Theme.Text }, TweenInfo_Quick)
            Utility:Tween(Label, { TextColor3 = Theme.Text }, TweenInfo_Quick)
        end
    end)
    TabBtn.MouseLeave:Connect(function()
        if not tab._active then
            Utility:Tween(TabBtn, { BackgroundTransparency = 1 }, TweenInfo_Quick)
            Utility:Tween(Icon, { ImageColor3 = Theme.TextDim }, TweenInfo_Quick)
            Utility:Tween(Label, { TextColor3 = Theme.TextDim }, TweenInfo_Quick)
        end
    end)
    
    local function activateTab()
        for _, t in ipairs(window.Tabs) do
            t._active = false
            t.Page.Visible = false
            Utility:Tween(t.Button, { BackgroundTransparency = 1 }, TweenInfo_Quick)
            Utility:Tween(t.Icon, { ImageColor3 = Theme.TextDim }, TweenInfo_Quick)
            Utility:Tween(t.Label, { TextColor3 = Theme.TextDim }, TweenInfo_Quick)
        end
        tab._active = true
        Page.Visible = true
        Utility:Tween(TabBtn, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85 }, TweenInfo_Quick)
        Utility:Tween(Icon, { ImageColor3 = Theme.AccentLight }, TweenInfo_Quick)
        Utility:Tween(Label, { TextColor3 = Theme.Text }, TweenInfo_Quick)
        
        -- Left accent indicator
        if not TabBtn:FindFirstChild("Indicator") then
            local indicator = Instance.new("Frame")
            indicator.Name = "Indicator"
            indicator.Size = UDim2.new(0, 3, 0, 16)
            indicator.Position = UDim2.new(0, 0, 0.5, -8)
            indicator.BackgroundColor3 = Theme.Accent
            indicator.BorderSizePixel = 0
            indicator.ZIndex = 14
            indicator.Parent = TabBtn
            Utility:Round(indicator, 2)
        end
    end
    
    TabBtn.MouseButton1Click:Connect(activateTab)
    
    tab.Button = TabBtn
    tab.Icon = Icon
    tab.Label = Label
    tab.Page = Page
    tab._active = false
    tab.Window = window
    
    table.insert(window.Tabs, tab)
    
    -- Auto-select first tab
    if #window.Tabs == 1 then
        activateTab()
    end
    
    -- Element factory
    function tab:CreateButton(btnConfig)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 0, 34)
        Button.BackgroundColor3 = Theme.Panel
        Button.BackgroundTransparency = 0.2
        Button.Text = ""
        Button.BorderSizePixel = 0
        Button.ZIndex = 12
        Button.Parent = Page
        Utility:Round(Button, 8)
        Utility:Stroke(Button, Theme.Border, 1, 0.6)
        
        local BtnLabel = Instance.new("TextLabel")
        BtnLabel.Size = UDim2.new(1, -20, 0, 14)
        BtnLabel.Position = UDim2.new(0, 10, 0.5, -7)
        BtnLabel.BackgroundTransparency = 1
        BtnLabel.Text = btnConfig.Text or "Button"
        BtnLabel.Font = Enum.Font.GothamMedium
        BtnLabel.TextSize = 12
        BtnLabel.TextColor3 = Theme.Text
        BtnLabel.TextXAlignment = Enum.TextXAlignment.Left
        BtnLabel.ZIndex = 13
        BtnLabel.Parent = Button
        
        local arrow = Instance.new("ImageLabel")
        arrow.Size = UDim2.new(0, 12, 0, 12)
        arrow.Position = UDim2.new(1, -20, 0.5, -6)
        arrow.BackgroundTransparency = 1
        arrow.Image = "rbxassetid://6031094670"
        arrow.ImageColor3 = Theme.TextFaint
        arrow.ZIndex = 13
        arrow.Parent = Button
        
        Button.MouseEnter:Connect(function()
            Utility:Tween(Button, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TweenInfo_Quick)
            Utility:Tween(arrow, { ImageColor3 = Theme.AccentLight, Position = UDim2.new(1, -18, 0.5, -6) }, TweenInfo_Quick)
        end)
        Button.MouseLeave:Connect(function()
            Utility:Tween(Button, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.2 }, TweenInfo_Quick)
            Utility:Tween(arrow, { ImageColor3 = Theme.TextFaint, Position = UDim2.new(1, -20, 0.5, -6) }, TweenInfo_Quick)
        end)
        Button.MouseButton1Down:Connect(function()
            Utility:Tween(Button, { BackgroundColor3 = Theme.Pressed, BackgroundTransparency = 0 }, TweenInfo.new(0.05))
        end)
        Button.MouseButton1Up:Connect(function()
            Utility:Tween(Button, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TweenInfo_Quick)
            if btnConfig.Callback then btnConfig.Callback() end
        end)
        
        return Button
    end
    
    function tab:CreateToggle(toggleConfig)
        local toggle = { state = false }
        
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 34)
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = Page
        
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Size = UDim2.new(1, -60, 0, 14)
        ToggleLabel.Position = UDim2.new(0, 10, 0.5, -7)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = toggleConfig.Text or "Toggle"
        ToggleLabel.Font = Enum.Font.GothamMedium
        ToggleLabel.TextSize = 12
        ToggleLabel.TextColor3 = Theme.Text
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.ZIndex = 13
        ToggleLabel.Parent = Container
        
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
        ToggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
        ToggleBtn.BackgroundColor3 = Theme.ToggleTrack
        ToggleBtn.Text = ""
        ToggleBtn.BorderSizePixel = 0
        ToggleBtn.ZIndex = 13
        ToggleBtn.Parent = Container
        Utility:Round(ToggleBtn, 10)
        Utility:Stroke(ToggleBtn, Theme.Border, 1, 0.5)
        
        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.Position = UDim2.new(0, 3, 0.5, -7)
        Knob.BackgroundColor3 = Theme.ToggleKnob
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 14
        Knob.Parent = ToggleBtn
        Utility:Round(Knob, 7)
        
        local glow = Instance.new("ImageLabel")
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = Theme.Accent
        glow.ImageTransparency = 1
        glow.Size = UDim2.new(1, 10, 1, 10)
        glow.Position = UDim2.new(0, -5, 0, -5)
        glow.ZIndex = 12
        glow.Parent = ToggleBtn
        
        local function setToggle(state)
            toggle.state = state
            if state then
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Theme.Accent }, TweenInfo_Quick)
                Utility:Tween(Knob, { Position = UDim2.new(1, -17, 0.5, -7) }, TweenInfo_Quick)
                Utility:Tween(glow, { ImageTransparency = 0.7 }, TweenInfo_Quick)
                Utility:Tween(ToggleLabel, { TextColor3 = Theme.AccentLight }, TweenInfo_Quick)
            else
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleTrack }, TweenInfo_Quick)
                Utility:Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -7) }, TweenInfo_Quick)
                Utility:Tween(glow, { ImageTransparency = 1 }, TweenInfo_Quick)
                Utility:Tween(ToggleLabel, { TextColor3 = Theme.Text }, TweenInfo_Quick)
            end
            if toggleConfig.Callback then toggleConfig.Callback(state) end
        end
        
        ToggleBtn.MouseButton1Click:Connect(function()
            setToggle(not toggle.state)
        end)
        
        ToggleBtn.MouseEnter:Connect(function()
            if not toggle.state then
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Color3.fromRGB(60, 60, 72) }, TweenInfo_Quick)
            end
        end)
        ToggleBtn.MouseLeave:Connect(function()
            if not toggle.state then
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleTrack }, TweenInfo_Quick)
            end
        end)
        
        toggle.Set = setToggle
        toggle.Get = function() return toggle.state end
        toggle.Instance = Container
        
        if toggleConfig.Default then setToggle(true) end
        return toggle
    end
    
    function tab:CreateSlider(sliderConfig)
        local slider = { value = sliderConfig.Default or sliderConfig.Min or 0 }
        
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 50)
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = Page
        
        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Size = UDim2.new(0, 200, 0, 14)
        SliderLabel.Position = UDim2.new(0, 10, 0, 4)
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Text = sliderConfig.Text or "Slider"
        SliderLabel.Font = Enum.Font.GothamMedium
        SliderLabel.TextSize = 12
        SliderLabel.TextColor3 = Theme.Text
        SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        SliderLabel.ZIndex = 13
        SliderLabel.Parent = Container
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Size = UDim2.new(0, 60, 0, 14)
        ValueLabel.Position = UDim2.new(1, -70, 0, 4)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = tostring(slider.value)
        ValueLabel.Font = Enum.Font.GothamMedium
        ValueLabel.TextSize = 12
        ValueLabel.TextColor3 = Theme.AccentLight
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.ZIndex = 13
        ValueLabel.Parent = Container
        
        local Track = Instance.new("Frame")
        Track.Size = UDim2.new(1, -20, 0, 6)
        Track.Position = UDim2.new(0, 10, 0, 30)
        Track.BackgroundColor3 = Theme.ToggleTrack
        Track.BorderSizePixel = 0
        Track.ZIndex = 13
        Track.Parent = Container
        Utility:Round(Track, 3)
        
        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new(0, 0, 1, 0)
        Fill.BackgroundColor3 = Theme.Accent
        Fill.BorderSizePixel = 0
        Fill.ZIndex = 14
        Fill.Parent = Track
        Utility:Round(Fill, 3)
        Utility:Gradient(Fill, ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentLight),
        }), 0)
        
        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.Position = UDim2.new(0, 0, 0.5, -7)
        Knob.BackgroundColor3 = Theme.Text
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 15
        Knob.Parent = Track
        Utility:Round(Knob, 7)
        
        local dragging = false
        local min = sliderConfig.Min or 0
        local max = sliderConfig.Max or 100
        local suffix = sliderConfig.Suffix or ""
        
        local function updateSlider(inputPos)
            local rel = (inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            slider.value = math.floor(min + (max - min) * rel)
            if sliderConfig.Decimal then
                slider.value = min + (max - min) * rel
                slider.value = math.round(slider.value * 100) / 100
            end
            ValueLabel.Text = tostring(slider.value) .. suffix
            Utility:Tween(Fill, { Size = UDim2.new(rel, 0, 1, 0) }, TweenInfo.new(0.05))
            Knob.Position = UDim2.new(rel, -7, 0.5, -7)
            if sliderConfig.Callback then sliderConfig.Callback(slider.value) end
        end
        
        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input.Position)
                Utility:Tween(Knob, { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(Knob.Position.X.Scale, -9, 0.5, -9) }, TweenInfo_Quick)
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
                    Utility:Tween(Knob, { Size = UDim2.new(0, 14, 0, 14) }, TweenInfo_Quick)
                end
            end
        end)
        
        -- Initialize
        local initRel = (slider.value - min) / (max - min)
        Fill.Size = UDim2.new(initRel, 0, 1, 0)
        Knob.Position = UDim2.new(initRel, -7, 0.5, -7)
        ValueLabel.Text = tostring(slider.value) .. suffix
        
        slider.Set = function(val)
            val = math.clamp(val, min, max)
            slider.value = val
            local rel = (val - min) / (max - min)
            ValueLabel.Text = tostring(val) .. suffix
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Knob.Position = UDim2.new(rel, -7, 0.5, -7)
            if sliderConfig.Callback then sliderConfig.Callback(val) end
        end
        slider.Get = function() return slider.value end
        
        return slider
    end
    
    function tab:CreateTextBox(tbConfig)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 34)
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = Page
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0, 80, 0, 14)
        Label.Position = UDim2.new(0, 10, 0.5, -7)
        Label.BackgroundTransparency = 1
        Label.Text = tbConfig.Label or "Input:"
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 12
        Label.TextColor3 = Theme.TextDim
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 13
        Label.Parent = Container
        
        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(1, -110, 0, 24)
        Box.Position = UDim2.new(0, 100, 0.5, -12)
        Box.BackgroundColor3 = Theme.Panel
        Box.BackgroundTransparency = 0.2
        Box.Text = tbConfig.Default or ""
        Box.PlaceholderText = tbConfig.Placeholder or "Enter value..."
        Box.Font = Enum.Font.Gotham
        Box.TextSize = 11
        Box.TextColor3 = Theme.Text
        Box.PlaceholderColor3 = Theme.TextFaint
        Box.ClearTextOnFocus = false
        Box.BorderSizePixel = 0
        Box.ZIndex = 13
        Box.Parent = Container
        Utility:Round(Box, 6)
        Utility:Stroke(Box, Theme.Border, 1, 0.5)
        Utility:Padding(Box, 0, 0, 8, 8)
        
        Box.Focused:Connect(function()
            Utility:Tween(Box, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TweenInfo_Quick)
            Utility:Stroke(Box, Theme.Accent, 1, 0)
        end)
        Box.FocusLost:Connect(function(enter)
            Utility:Tween(Box, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.2 }, TweenInfo_Quick)
            Utility:Stroke(Box, Theme.Border, 1, 0.5)
            if tbConfig.Callback then tbConfig.Callback(Box.Text, enter) end
        end)
        
        return Box
    end
    
    function tab:CreateLabel(text, fontSize)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 18)
        Label.BackgroundTransparency = 1
        Label.Text = text or "Label"
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = fontSize or 11
        Label.TextColor3 = Theme.TextDim
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 12
        Label.Parent = Page
        return Label
    end
    
    function tab:CreateSection(title)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 24)
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = Page
        
        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(1, 0, 0, 1)
        Line.Position = UDim2.new(0, 0, 0.5, 0)
        Line.BackgroundColor3 = Theme.Border
        Line.BorderSizePixel = 0
        Line.Transparency = 0.5
        Line.ZIndex = 13
        Line.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0, 120, 0, 14)
        Label.Position = UDim2.new(0, 8, 0.5, -7)
        Label.BackgroundTransparency = 1
        Label.Text = title or "Section"
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 10
        Label.TextColor3 = Theme.AccentLight
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 14
        Label.Parent = Container
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0, 110, 0, 3)
        bg.Position = UDim2.new(0, 10, 0.5, 6)
        bg.BackgroundColor3 = Theme.Background
        bg.BorderSizePixel = 0
        bg.ZIndex = 13
        bg.Parent = Container
    end
    
    function tab:CreateDropdown(ddConfig)
        local dd = { open = false, value = ddConfig.Default or ddConfig.Options[1] or "Select" }
        
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 34)
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = Page
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0, 100, 0, 14)
        Label.Position = UDim2.new(0, 10, 0.5, -7)
        Label.BackgroundTransparency = 1
        Label.Text = ddConfig.Label or "Select:"
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 12
        Label.TextColor3 = Theme.TextDim
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 13
        Label.Parent = Container
        
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -120, 0, 24)
        Btn.Position = UDim2.new(0, 110, 0.5, -12)
        Btn.BackgroundColor3 = Theme.Panel
        Btn.BackgroundTransparency = 0.2
        Btn.Text = dd.value
        Btn.Font = Enum.Font.Gotham
        Btn.TextSize = 11
        Btn.TextColor3 = Theme.Text
        Btn.BorderSizePixel = 0
        Btn.ZIndex = 13
        Btn.Parent = Container
        Utility:Round(Btn, 6)
        Utility:Stroke(Btn, Theme.Border, 1, 0.5)
        
        return dd
    end
    
    return tab
end

function Library:Notify(config)
    local gui = self._window and self._window.Gui
    if not gui then return end
    
    local notifContainer = gui:FindFirstChild("Notifications")
    if not notifContainer then
        notifContainer = Instance.new("Frame")
        notifContainer.Name = "Notifications"
        notifContainer.Size = UDim2.new(0, 280, 1, -20)
        notifContainer.Position = UDim2.new(1, -300, 0, 10)
        notifContainer.BackgroundTransparency = 1
        notifContainer.ZIndex = 50
        notifContainer.Parent = gui
        Utility:List(notifContainer, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right)
    end
    
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(0, 280, 0, 60)
    Notif.BackgroundColor3 = Theme.Panel
    Notif.BackgroundTransparency = 0.1
    Notif.BorderSizePixel = 0
    Notif.ZIndex = 51
    Notif.Parent = notifContainer
    Utility:Round(Notif, 10)
    Utility:Stroke(Notif, Theme.Border, 1, 0.4)
    Utility:Shadow(Notif)
    
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, -12)
    accentBar.Position = UDim2.new(0, 6, 0, 6)
    accentBar.BackgroundColor3 = config.Color or Theme.Accent
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 52
    accentBar.Parent = Notif
    Utility:Round(accentBar, 2)
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 14)
    Title.Position = UDim2.new(0, 16, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "Notification"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextColor3 = Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 52
    Title.Parent = Notif
    
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -30, 0, 24)
    Desc.Position = UDim2.new(0, 16, 0, 24)
    Desc.BackgroundTransparency = 1
    Desc.Text = config.Description or ""
    Desc.Font = Enum.Font.Gotham
    Desc.TextSize = 10
    Desc.TextColor3 = Theme.TextDim
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.TextWrapped = true
    Desc.ZIndex = 52
    Desc.Parent = Notif
    
    -- Enter animation
    Notif.Size = UDim2.new(0, 0, 0, 60)
    Notif.BackgroundTransparency = 1
    Utility:Tween(Notif, { Size = UDim2.new(0, 280, 0, 60), BackgroundTransparency = 0.1 }, TweenInfo_Bounce)
    
    task.delay(config.Duration or 3, function()
        Utility:Tween(Notif, { Size = UDim2.new(0, 0, 0, 60), BackgroundTransparency = 1 }, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.35)
        Notif:Destroy()
    end)
    
    return Notif
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FEATURES
-- ═══════════════════════════════════════════════════════════════════════════

local Features = {}
local connections = {}
local espObjects = {}

local function getChar(player)
    return player and player.Character
end

local function getHRP(player)
    local char = getChar(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
    local char = getChar(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    local hum = getHumanoid(player)
    return hum and hum.Health > 0
end

local function getRole(player)
    local playerFolder = player:FindFirstChild("PlayerFolder") or player:FindFirstChild("Data")
    if playerFolder then
        local role = playerFolder:FindFirstChild("Role") or playerFolder:FindFirstChild("role")
        if role and role:IsA("StringValue") then return role.Value end
        local stattrak = playerFolder:FindFirstChild("Stats")
        if stattrak then
            local r = stattrak:FindFirstChild("Role")
            if r then return r.Value end
        end
    end
    -- Alternative: check for knife / gun in backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        if backpack:FindFirstChild("Knife") then return "Murderer" end
        if backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver") then return "Sheriff" end
    end
    local char = getChar(player)
    if char then
        if char:FindFirstChild("Knife") then return "Murderer" end
        if char:FindFirstChild("Gun") then return "Sheriff" end
    end
    return "Innocent"
end

-- ── SpeedHack ──────────────────────────────────────────────────────────────
Features.SpeedHack = {
    enabled = false,
    speed = 32,
    conn = nil,
}
function Features.SpeedHack:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            local char = getChar(LocalPlayer)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum.WalkSpeed = self.speed
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        local char = getChar(LocalPlayer)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ── NoClip ─────────────────────────────────────────────────────────────────
Features.NoClip = {
    enabled = false,
    conn = nil,
}
function Features.NoClip:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Stepped:Connect(function()
            local char = getChar(LocalPlayer)
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── Fly ────────────────────────────────────────────────────────────────────
Features.Fly = {
    enabled = false,
    speed = 50,
    conn = nil,
    bv = nil,
    bg = nil,
}
function Features.Fly:Toggle(state)
    self.enabled = state
    local char = getChar(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if state and hrp then
        self.bv = Instance.new("BodyVelocity")
        self.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        self.bv.Velocity = Vector3.zero
        self.bv.Parent = hrp
        
        self.bg = Instance.new("BodyGyro")
        self.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        self.bg.P = 9e4
        self.bg.CFrame = Camera.CFrame
        self.bg.Parent = hrp
        
        self.conn = RunService.RenderStepped:Connect(function()
            if not hrp or not hrp.Parent then return end
            local camCF = Camera.CFrame
            self.bg.CFrame = CFrame.new(hrp.Position, camCF.Position + camCF.LookVector)
            
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            
            self.bv.Velocity = dir.Magnitude > 0 and dir.Unit * self.speed or Vector3.zero
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        if self.bv then self.bv:Destroy() self.bv = nil end
        if self.bg then self.bg:Destroy() self.bg = nil end
    end
end

-- ── ESP ────────────────────────────────────────────────────────────────────
Features.ESP = {
    enabled = false,
    showDist = true,
    showRole = true,
    showName = true,
    showHealth = true,
    tracer = false,
    objects = {},
}
function Features.ESP:CreateESP(player)
    if player == LocalPlayer then return end
    
    local function onChar(char)
        if not self.enabled then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        local head = char:WaitForChild("Head", 5)
        if not hrp or not hum then return end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "ENI_ESP"
        highlight.Adornee = char
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local role = getRole(player)
        local color
        if role == "Murderer" then
            color = Color3.fromRGB(255, 60, 60)
        elseif role == "Sheriff" then
            color = Color3.fromRGB(60, 120, 255)
        else
            color = Color3.fromRGB(80, 210, 120)
        end
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.Parent = char
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ENI_ESP_Label"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = char
        
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0, 14)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = player.DisplayName .. (self.showRole and " [" .. role .. "]" or "")
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = color
        nameLbl.TextStrokeTransparency = 0.5
        nameLbl.ZIndex = 2
        nameLbl.Parent = billboard
        
        local distLbl = Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, 0, 0, 12)
        distLbl.Position = UDim2.new(0, 0, 0, 16)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = ""
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextSize = 10
        distLbl.TextColor3 = Theme.Text
        distLbl.TextStrokeTransparency = 0.5
        distLbl.ZIndex = 2
        distLbl.Parent = billboard
        
        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(0, 3, 0, 30)
        healthBar.Position = UDim2.new(0, -8, 0, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        healthBar.BorderSizePixel = 0
        healthBar.ZIndex = 2
        healthBar.Parent = billboard
        Utility:Round(healthBar, 2)
        
        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = color
        healthFill.BorderSizePixel = 0
        healthFill.ZIndex = 3
        healthFill.Parent = healthBar
        Utility:Round(healthFill, 2)
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not self.enabled or not char or not char.Parent or hum.Health <= 0 then
                if conn then conn:Disconnect() end
                if highlight then highlight:Destroy() end
                if billboard then billboard:Destroy() end
                return
            end
            local lhrp = getHRP(LocalPlayer)
            if lhrp and self.showDist then
                local dist = math.floor((lhrp.Position - hrp.Position).Magnitude)
                distLbl.Text = dist .. " studs"
            end
            healthFill.Size = UDim2.new(1, 0, math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0)
        end)
        
        self.objects[player.UserId] = { highlight = highlight, billboard = billboard, conn = conn }
    end
    
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

function Features.ESP:Toggle(state)
    self.enabled = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            self:CreateESP(player)
        end
        connections.espJoin = Players.PlayerAdded:Connect(function(p) self:CreateESP(p) end)
    else
        if connections.espJoin then connections.espJoin:Disconnect() connections.espJoin = nil end
        for _, obj in pairs(self.objects) do
            if obj.conn then obj.conn:Disconnect() end
            if obj.highlight then obj.highlight:Destroy() end
            if obj.billboard then obj.billboard:Destroy() end
        end
        self.objects = {}
        -- Clean all highlights in workspace
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                local h = char:FindFirstChild("ENI_ESP")
                if h then h:Destroy() end
                local b = char:FindFirstChild("ENI_ESP_Label")
                if b then b:Destroy() end
            end
        end
    end
end

-- ── Chams (wall-through ESP) ───────────────────────────────────────────────
Features.Chams = {
    enabled = false,
    objects = {},
}
function Features.Chams:Toggle(state)
    self.enabled = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                if char then
                    local h = Instance.new("Highlight")
                    h.Name = "ENI_Cham"
                    h.Adornee = char
                    h.FillTransparency = 0.5
                    h.FillColor = Color3.fromRGB(130, 95, 255)
                    h.OutlineColor = Color3.fromRGB(160, 130, 255)
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = char
                    self.objects[player.UserId] = h
                end
            end
        end
    else
        for _, h in pairs(self.objects) do
            if h then h:Destroy() end
        end
        self.objects = {}
    end
end

-- ── ItemESP ────────────────────────────────────────────────────────────────
Features.ItemESP = {
    enabled = false,
    conn = nil,
    objects = {},
}
function Features.ItemESP:Toggle(state)
    self.enabled = state
    if state then
        local function scanItems()
            for _, obj in pairs(self.objects) do if obj then obj:Destroy() end end
            self.objects = {}
            
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("Model") or desc:IsA("BasePart") then
                    local name = desc.Name:lower()
                    if name:match("coin") or name:match("gun") or name:match("knife") 
                    or name:match("revolver") or name:match("weapon") or name:match("pickup") then
                        local part = desc:IsA("BasePart") and desc or desc:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local billboard = Instance.new("BillboardGui")
                            billboard.Size = UDim2.new(0, 100, 0, 30)
                            billboard.AlwaysOnTop = true
                            billboard.Parent = part
                            
                            local lbl = Instance.new("TextLabel")
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.Text = desc.Name
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 11
                            lbl.TextColor3 = Color3.fromRGB(255, 200, 80)
                            lbl.TextStrokeTransparency = 0.5
                            lbl.ZIndex = 2
                            lbl.Parent = billboard
                            
                            local highlight = Instance.new("Highlight")
                            highlight.Adornee = desc
                            highlight.FillColor = Color3.fromRGB(255, 200, 80)
                            highlight.FillTransparency = 0.6
                            highlight.OutlineColor = Color3.fromRGB(255, 220, 120)
                            highlight.Parent = part
                            
                            self.objects[#self.objects + 1] = billboard
                            self.objects[#self.objects + 1] = highlight
                        end
                    end
                end
            end
        end
        scanItems()
        self.conn = task.spawn(function()
            while self.enabled do
                scanItems()
                task.wait(2)
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
        for _, obj in pairs(self.objects) do if obj then obj:Destroy() end end
        self.objects = {}
    end
end

-- ── FullBright ─────────────────────────────────────────────────────────────
Features.FullBright = {
    enabled = false,
    original = {},
}
function Features.FullBright:Toggle(state)
    self.enabled = state
    if state then
        self.original.Brightness = Lighting.Brightness
        self.original.ClockTime = Lighting.ClockTime
        self.original.FogEnd = Lighting.FogEnd
        self.original.GlobalShadows = Lighting.GlobalShadows
        self.original.ExposureCompensation = Lighting.ExposureCompensation
        
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
        Lighting.ExposureCompensation = 0.5
    else
        if self.original.Brightness then Lighting.Brightness = self.original.Brightness end
        if self.original.ClockTime then Lighting.ClockTime = self.original.ClockTime end
        if self.original.FogEnd then Lighting.FogEnd = self.original.FogEnd end
        if self.original.GlobalShadows ~= nil then Lighting.GlobalShadows = self.original.GlobalShadows end
        if self.original.ExposureCompensation then Lighting.ExposureCompensation = self.original.ExposureCompensation end
    end
end

-- ── AimBot ─────────────────────────────────────────────────────────────────
Features.AimBot = {
    enabled = false,
    fov = 150,
    smoothness = 0.3,
    targetPart = "Head",
    conn = nil,
}
function Features.AimBot:GetClosest()
    local closest, closestDist = nil, self.fov
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local char = getChar(player)
            local part = char and char:FindFirstChild(self.targetPart)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

function Features.AimBot:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.RenderStepped:Connect(function()
            local target = self:GetClosest()
            if target then
                local targetPos = target.Position
                local currentCF = Camera.CFrame
                local targetCF = CFrame.new(currentCF.Position, targetPos)
                Camera.CFrame = currentCF:Lerp(targetCF, self.smoothness)
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── SilentAim ──────────────────────────────────────────────────────────────
Features.SilentAim = {
    enabled = false,
    fov = 200,
    targetPart = "Head",
}
function Features.SilentAim:GetTarget()
    local closest, closestDist = nil, self.fov
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local char = getChar(player)
            local part = char and char:FindFirstChild(self.targetPart)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

function Features.SilentAim:Toggle(state)
    self.enabled = state
    if state then
        Utility:AddNamecallHook("FireServer", function(self, ...)
            local args = {...}
            -- Check if this is a shoot remote (MM2 shoot remote)
            if Features.SilentAim.enabled and typeof(self) == "Instance" then
                local name = self.Name:lower()
                if name:match("shoot") or name:match("fire") or name:match("gun") then
                    local target = Features.SilentAim:GetTarget()
                    if target then
                        -- Replace position argument with target position
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" or typeof(arg) == "CFrame" then
                                if typeof(arg) == "Vector3" then
                                    args[i] = target.Position
                                elseif typeof(arg) == "CFrame" then
                                    args[i] = CFrame.new(target.Position)
                                end
                                break
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end)
    end
end

-- ── AutoShoot ──────────────────────────────────────────────────────────────
Features.AutoShoot = {
    enabled = false,
    delay = 0.5,
    conn = nil,
}
function Features.AutoShoot:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            while self.enabled do
                -- Find gun in character or backpack
                local char = getChar(LocalPlayer)
                local tool = char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver"))
                if not tool then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    tool = backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver"))
                    if tool then tool.Parent = char end
                end
                
                if tool then
                    -- Find nearest alive player
                    local closest, closestDist = nil, 1000
                    local lhrp = getHRP(LocalPlayer)
                    if lhrp then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and isAlive(player) then
                                local hrp = getHRP(player)
                                if hrp then
                                    local dist = (hrp.Position - lhrp.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        closest = player
                                    end
                                end
                            end
                        end
                    end
                    
                    if closest then
                        local targetPart = getChar(closest) and getChar(closest):FindFirstChild("Head")
                        if targetPart then
                            local shootEvent = ReplicatedStorage:FindFirstChild("ShootEvent") 
                            or ReplicatedStorage:FindFirstChild("FireGun")
                            or tool:FindFirstChild("Shoot")
                            or tool:FindFirstChild("Fire")
                            if shootEvent then
                                pcall(function()
                                    if shootEvent:IsA("RemoteEvent") then
                                        shootEvent:FireServer(targetPart.Position)
                                    elseif shootEvent:IsA("RemoteFunction") then
                                        shootEvent:InvokeServer(targetPart.Position)
                                    end
                                end)
                            end
                            -- Also try tool activation
                            pcall(function() tool:Activate() end)
                        end
                    end
                end
                task.wait(self.delay)
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
    end
end

-- ── SpinBot ────────────────────────────────────────────────────────────────
Features.SpinBot = {
    enabled = false,
    speed = 10,
    conn = nil,
}
function Features.SpinBot:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.RenderStepped:Connect(function()
            local char = getChar(LocalPlayer)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(self.speed), 0)
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── FakeLag ─────────────────────────────────────────────────────────────────
Features.FakeLag = {
    enabled = false,
    intensity = 0.5,
    conn = nil,
}
function Features.FakeLag:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            local char = getChar(LocalPlayer)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and math.random() < self.intensity then
                hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-1, 1) * 0.1, 0, math.random(-1, 1) * 0.1)
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── HitmarkerESP ────────────────────────────────────────────────────────────
Features.HitmarkerESP = {
    enabled = false,
    conn = nil,
    markers = {},
}
function Features.HitmarkerESP:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.RenderStepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and isAlive(player) then
                    local char = getChar(player)
                    local hum = getHumanoid(player)
                    if char and hum then
                        local existing = char:FindFirstChild("ENI_Hitmarker")
                        if not existing and hum.Health < (self.lastHealth and self.lastHealth[player.UserId] or hum.MaxHealth) then
                            local marker = Instance.new("Part")
                            marker.Name = "ENI_Hitmarker"
                            marker.Size = Vector3.new(0.5, 0.5, 0.5)
                            marker.CFrame = char:GetPivot()
                            marker.Anchored = true
                            marker.CanCollide = false
                            marker.Transparency = 0.5
                            marker.Color = Color3.fromRGB(255, 60, 60)
                            marker.Material = Enum.Material.Neon
                            marker.Parent = Workspace
                            
                            local billboard = Instance.new("BillboardGui")
                            billboard.Size = UDim2.new(0, 50, 0, 20)
                            billboard.AlwaysOnTop = true
                            billboard.Parent = marker
                            
                            local lbl = Instance.new("TextLabel")
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.Text = "HIT"
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 12
                            lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
                            lbl.TextStrokeTransparency = 0.3
                            lbl.Parent = billboard
                            
                            task.delay(1.5, function()
                                if marker then marker:Destroy() end
                            end)
                        end
                        self.lastHealth = self.lastHealth or {}
                        self.lastHealth[player.UserId] = hum.Health
                    end
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        for _, m in ipairs(self.markers) do if m then m:Destroy() end end
        self.markers = {}
        self.lastHealth = {}
    end
end

-- ── AutoCoins ──────────────────────────────────────────────────────────────
Features.AutoCoins = {
    enabled = false,
    conn = nil,
}
function Features.AutoCoins:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            while self.enabled do
                local char = getChar(LocalPlayer)
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, desc in ipairs(Workspace:GetDescendants()) do
                        local name = desc.Name:lower()
                        if name:match("coin") then
                            local part = desc:IsA("BasePart") and desc or desc:FindFirstChildWhichIsA("BasePart")
                            if part then
                                pcall(function()
                                    firetouchinterest(hrp, part, 0)
                                    firetouchinterest(hrp, part, 1)
                                end)
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
    end
end

-- ── AutoGun ────────────────────────────────────────────────────────────────
Features.AutoGun = {
    enabled = false,
    conn = nil,
}
function Features.AutoGun:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            while self.enabled do
                local char = getChar(LocalPlayer)
                if char then
                    local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        hasGun = hasGun or backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")
                    end
                    if not hasGun then
                        -- Look for gun in workspace
                        for _, desc in ipairs(Workspace:GetDescendants()) do
                            local name = desc.Name:lower()
                            if name:match("gun") or name:match("revolver") then
                                local part = desc:IsA("BasePart") and desc or desc:FindFirstChildWhichIsA("BasePart")
                                if part and char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.1)
                                    pcall(function()
                                        firetouchinterest(char.HumanoidRootPart, part, 0)
                                        firetouchinterest(char.HumanoidRootPart, part, 1)
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
                task.wait(1)
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
    end
end

-- ── Fling ──────────────────────────────────────────────────────────────────
Features.Fling = {
    enabled = false,
    power = 500,
    targetAll = false,
}
function Features.Fling:Execute(targetPlayer)
    local char = getChar(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local function fling(victim)
        local vChar = getChar(victim)
        local vHrp = vChar and vChar:FindFirstChild("HumanoidRootPart")
        if vHrp then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = (vHrp.Position - hrp.Position).Unit * self.power + Vector3.new(0, self.power * 0.3, 0)
            bv.Parent = vHrp
            task.wait(0.5)
            bv:Destroy()
        end
    end
    
    if self.targetAll then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                task.spawn(function() fling(player) end)
            end
        end
    elseif targetPlayer then
        fling(targetPlayer)
    end
end

-- ── MassTP ─────────────────────────────────────────────────────────────────
Features.MassTP = {
    enabled = false,
}
function Features.MassTP:Execute()
    local char = getChar(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local pos = hrp.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = getChar(player)
            local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
            if pHrp then
                pHrp.CFrame = CFrame.new(pos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
            end
        end
    end
end

-- ── KillAll ────────────────────────────────────────────────────────────────
Features.KillAll = {
    enabled = false,
}
function Features.KillAll:Execute()
    local char = getChar(LocalPlayer)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local knife = char and (char:FindFirstChild("Knife") or char:FindFirstChild("KnifeWeapon"))
    knife = knife or (backpack and (backpack:FindFirstChild("Knife") or backpack:FindFirstChild("KnifeWeapon")))
    
    if knife then
        knife.Parent = char
        local lhrp = getHRP(LocalPlayer)
        if lhrp then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and isAlive(player) then
                    local pHrp = getHRP(player)
                    if pHrp then
                        local originalPos = lhrp.CFrame
                        lhrp.CFrame = CFrame.new(pHrp.Position + Vector3.new(0, 0, 2), pHrp.Position)
                        pcall(function()
                            local stabEvent = knife:FindFirstChild("Stab") or knife:FindFirstChild("Attack")
                            or ReplicatedStorage:FindFirstChild("StabEvent")
                            or ReplicatedStorage:FindFirstChild("MeleeEvent")
                            if stabEvent then
                                if stabEvent:IsA("RemoteEvent") then
                                    stabEvent:FireServer(player)
                                elseif stabEvent:IsA("RemoteFunction") then
                                    stabEvent:InvokeServer(player)
                                end
                            end
                        end)
                        pcall(function() knife:Activate() end)
                        task.wait(0.1)
                    end
                end
            end
            lhrp.CFrame = originalPos
        end
    end
end

-- ── FX / Cosmetics ─────────────────────────────────────────────────────────
Features.FX = {
    enabled = false,
    conn = nil,
    particles = {},
}
function Features.FX:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            local char = getChar(LocalPlayer)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if math.random() < 0.3 then
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(0.2, 0.2, 0.2)
                    p.CFrame = hrp.CFrame * CFrame.new(math.random(-2, 2), math.random(-1, 2), math.random(-2, 2))
                    p.Anchored = true
                    p.CanCollide = false
                    p.Material = Enum.Material.Neon
                    p.Color = Color3.fromHSV(math.random(), 0.8, 1)
                    p.Transparency = 0.3
                    p.Parent = Workspace
                    Utility:Tween(p, { Size = Vector3.zero, Transparency = 1 }, TweenInfo.new(0.8))
                    task.delay(0.8, function() p:Destroy() end)
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── AlarmBar ────────────────────────────────────────────────────────────────
Features.AlarmBar = {
    enabled = false,
    bar = nil,
    conn = nil,
}
function Features.AlarmBar:Toggle(state)
    self.enabled = state
    if state then
        if self.bar then self.bar:Destroy() end
        
        local gui = Library._window.Gui
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 300, 0, 30)
        bar.Position = UDim2.new(0.5, -150, 0, 50)
        bar.BackgroundColor3 = Theme.Danger
        bar.BorderSizePixel = 0
        bar.ZIndex = 40
        bar.Parent = gui
        Utility:Round(bar, 8)
        Utility:Shadow(bar)
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "⚠ MURDERER NEARBY"
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextColor3 = Theme.Text
        lbl.ZIndex = 41
        lbl.Parent = bar
        
        self.bar = bar
        bar.Size = UDim2.new(0, 0, 0, 30)
        Utility:Tween(bar, { Size = UDim2.new(0, 300, 0, 30) }, TweenInfo_Bounce)
        
        self.conn = RunService.Heartbeat:Connect(function()
            local char = getChar(LocalPlayer)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            local murderNear = false
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and getRole(player) == "Murderer" and isAlive(player) then
                    local pHrp = getHRP(player)
                    if pHrp then
                        local dist = (pHrp.Position - hrp.Position).Magnitude
                        if dist < 50 then
                            murderNear = true
                            lbl.Text = "⚠ MURDERER " .. math.floor(dist) .. " STUDS"
                            break
                        end
                    end
                end
            end
            bar.Visible = murderNear
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        if self.bar then self.bar:Destroy() self.bar = nil end
    end
end

-- ── Players List ───────────────────────────────────────────────────────────
Features.PlayersList = {
    enabled = false,
    frame = nil,
    conn = nil,
}
function Features.PlayersList:Toggle(state)
    self.enabled = state
    if state then
        if self.frame then self.frame:Destroy() end
        
        local gui = Library._window.Gui
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(0, 220, 0, 300)
        panel.Position = UDim2.new(0, 10, 1, -320)
        panel.BackgroundColor3 = Theme.Panel
        panel.BackgroundTransparency = 0.15
        panel.BorderSizePixel = 0
        panel.ZIndex = 35
        panel.Parent = gui
        Utility:Round(panel, 10)
        Utility:Stroke(panel, Theme.Border, 1, 0.4)
        Utility:Shadow(panel)
        
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, 0, 0, 28)
        header.BackgroundTransparency = 1
        header.Text = "  Players"
        header.Font = Enum.Font.GothamBold
        header.TextSize = 12
        header.TextColor3 = Theme.AccentLight
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.ZIndex = 36
        header.Parent = panel
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -12, 1, -36)
        scroll.Position = UDim2.new(0, 6, 0, 30)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Theme.ScrollBar
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ZIndex = 36
        scroll.Parent = panel
        Utility:List(scroll, Enum.FillDirection.Vertical, 4)
        
        self.frame = panel
        self.scroll = scroll
        
        local function refreshList()
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            for _, player in ipairs(Players:GetPlayers()) do
                local entry = Instance.new("Frame")
                entry.Size = UDim2.new(1, 0, 0, 24)
                entry.BackgroundColor3 = Theme.Background
                entry.BackgroundTransparency = 0.5
                entry.BorderSizePixel = 0
                entry.ZIndex = 37
                entry.Parent = scroll
                Utility:Round(entry, 6)
                
                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 8, 0, 8)
                dot.Position = UDim2.new(0, 6, 0.5, -4)
                dot.BorderSizePixel = 0
                dot.ZIndex = 38
                dot.Parent = entry
                Utility:Round(dot, 4)
                
                local role = getRole(player)
                if role == "Murderer" then
                    dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
                elseif role == "Sheriff" then
                    dot.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
                else
                    dot.BackgroundColor3 = Color3.fromRGB(80, 210, 120)
                end
                
                local name = Instance.new("TextLabel")
                name.Size = UDim2.new(1, -40, 0, 14)
                name.Position = UDim2.new(0, 20, 0.5, -7)
                name.BackgroundTransparency = 1
                name.Text = player.DisplayName
                name.Font = Enum.Font.Gotham
                name.TextSize = 11
                name.TextColor3 = Theme.Text
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.ZIndex = 38
                name.Parent = entry
                
                local healthLbl = Instance.new("TextLabel")
                healthLbl.Size = UDim2.new(0, 30, 0, 12)
                healthLbl.Position = UDim2.new(1, -34, 0.5, -6)
                healthLbl.BackgroundTransparency = 1
                healthLbl.Text = ""
                healthLbl.Font = Enum.Font.Gotham
                healthLbl.TextSize = 10
                healthLbl.TextColor3 = Theme.TextDim
                healthLbl.TextXAlignment = Enum.TextXAlignment.Right
                healthLbl.ZIndex = 38
                healthLbl.Parent = entry
                
                local hum = getHumanoid(player)
                if hum then healthLbl.Text = tostring(math.floor(hum.Health)) end
            end
        end
        refreshList()
        self.conn = task.spawn(function()
            while self.enabled do
                refreshList()
                task.wait(1)
            end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
        if self.frame then self.frame:Destroy() self.frame = nil end
    end
end

-- ── AntiProtections ─────────────────────────────────────────────────────────
Features.AntiProt = {
    enabled = false,
    conn = nil,
}
function Features.AntiProt:Toggle(state)
    self.enabled = state
    if state then
        -- Anti-kick
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        local newNamecall = mt.__namecall
        
        pcall(function()
            setreadonly(mt, false)
            mt.__index = newcclosure(function(self, key)
                if key == "Kick" or key == "kick" then
                    return function() end
                end
                return oldIndex(self, key)
            end)
            setreadonly(mt, true)
        end)
        
        -- Anti detection: remove script from common scan locations
        pcall(function()
            local gui = CoreGui:FindFirstChild("ENI_MM2_Suite")
            if gui then
                gui.Name = "CameraModule_" .. math.random(1000, 9999)
            end
        end)
        
        -- Connection cleanup monitor
        self.conn = RunService.Heartbeat:Connect(function()
            -- Re-apply WalkSpeed if SpeedHack is on
            if Features.SpeedHack.enabled then
                local char = getChar(LocalPlayer)
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.WalkSpeed ~= Features.SpeedHack.speed then
                    hum.WalkSpeed = Features.SpeedHack.speed
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── Settings / Profiles ────────────────────────────────────────────────────
Features.Profiles = {
    current = "default",
    data = {},
}
function Features.Profiles:Save(name)
    local profile = {
        SpeedHack = { enabled = Features.SpeedHack.enabled, speed = Features.SpeedHack.speed },
        NoClip = { enabled = Features.NoClip.enabled },
        Fly = { enabled = Features.Fly.enabled, speed = Features.Fly.speed },
        ESP = { enabled = Features.ESP.enabled },
        Chams = { enabled = Features.Chams.enabled },
        FullBright = { enabled = Features.FullBright.enabled },
        AimBot = { enabled = Features.AimBot.enabled, fov = Features.AimBot.fov, smoothness = Features.AimBot.smoothness },
        SilentAim = { enabled = Features.SilentAim.enabled },
        AutoShoot = { enabled = Features.AutoShoot.enabled },
        SpinBot = { enabled = Features.SpinBot.enabled, speed = Features.SpinBot.speed },
    }
    self.data[name] = profile
    self.current = name
    -- Try writefile for persistence
    pcall(function()
        writefile("ENI_MM2_Profile_" .. name .. ".json", HttpService:JSONEncode(profile))
    end)
end
function Features.Profiles:Load(name)
    local profile = self.data[name]
    if not profile then
        pcall(function()
            local content = readfile("ENI_MM2_Profile_" .. name .. ".json")
            if content then profile = HttpService:JSONDecode(content) end
        end)
    end
    if profile then
        if profile.SpeedHack then
            Features.SpeedHack.speed = profile.SpeedHack.speed or 32
            if profile.SpeedHack.enabled then Features.SpeedHack:Toggle(true) end
        end
        self.current = name
    end
end

-- ── Crosshair ───────────────────────────────────────────────────────────────
Features.Crosshair = {
    enabled = false,
    frame = nil,
    size = 6,
    thickness = 1,
    color = Color3.fromRGB(130, 95, 255),
}
function Features.Crosshair:Toggle(state)
    self.enabled = state
    if state then
        if self.frame then self.frame:Destroy() end
        
        local gui = Library._window.Gui
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 40, 0, 40)
        container.Position = UDim2.new(0.5, -20, 0.5, -20)
        container.BackgroundTransparency = 1
        container.ZIndex = 30
        container.Parent = gui
        
        local function makeLine(sizeX, sizeY, posX, posY)
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0, sizeX, 0, sizeY)
            line.Position = UDim2.new(0, posX, 0, posY)
            line.BackgroundColor3 = self.color
            line.BorderSizePixel = 0
            line.ZIndex = 31
            line.Parent = container
            return line
        end
        
        makeLine(self.thickness, self.size, 20 - self.thickness/2, 20 - self.size - 2)
        makeLine(self.thickness, self.size, 20 - self.thickness/2, 20 + 2)
        makeLine(self.size, self.thickness, 20 - self.size - 2, 20 - self.thickness/2)
        makeLine(self.size, self.thickness, 20 + 2, 20 - self.thickness/2)
        
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 2, 0, 2)
        dot.Position = UDim2.new(0, 19, 0, 19)
        dot.BackgroundColor3 = self.color
        dot.BorderSizePixel = 0
        dot.ZIndex = 31
        dot.Parent = container
        
        self.frame = container
    else
        if self.frame then self.frame:Destroy() self.frame = nil end
    end
end

-- ── Visual World ───────────────────────────────────────────────────────────
Features.VisualWorld = {
    enabled = false,
    original = {},
}
function Features.VisualWorld:Toggle(state)
    self.enabled = state
    if state then
        self.original.FogEnd = Lighting.FogEnd
        self.original.FogStart = Lighting.FogStart
        self.original.Brightness = Lighting.Brightness
        self.original.ClockTime = Lighting.ClockTime
        self.original.Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        
        Lighting.FogEnd = 1e9
        Lighting.FogStart = 1e9
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = 0 end
    else
        if self.original.FogEnd then Lighting.FogEnd = self.original.FogEnd end
        if self.original.FogStart then Lighting.FogStart = self.original.FogStart end
        if self.original.Brightness then Lighting.Brightness = self.original.Brightness end
        if self.original.ClockTime then Lighting.ClockTime = self.original.ClockTime end
    end
end

-- ── Get All Emotes ──────────────────────────────────────────────────────────
Features.GetAllEmotes = {}
function Features.GetAllEmotes:Execute()
    local emotesFolder = ReplicatedStorage:FindFirstChild("Emotes") 
    or ReplicatedStorage:FindFirstChild("Animations")
    local char = getChar(LocalPlayer)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if emotesFolder then
        for _, emote in ipairs(emotesFolder:GetDescendants()) do
            if emote:IsA("Animation") then
                if hum then
                    local track = hum:FindOrCreateAnimator():LoadAnimation(emote)
                    pcall(function() track:Play() end)
                    task.wait(2)
                    pcall(function() track:Stop() end)
                end
            end
        end
    end
    
    -- Try remote approach
    local emoteRemote = ReplicatedStorage:FindFirstChild("PlayEmote") 
    or ReplicatedStorage:FindFirstChild("EmoteEvent")
    or ReplicatedStorage:FindFirstChild("BuyEmote")
    
    if emoteRemote then
        for i = 1, 50 do
            pcall(function()
                if emoteRemote:IsA("RemoteEvent") then
                    emoteRemote:FireServer(i)
                elseif emoteRemote:IsA("RemoteFunction") then
                    emoteRemote:InvokeServer(i)
                end
            end)
        end
    end
end

-- ── Shoot Murder Button (floating, draggable, toggleable) ───────────────────
Features.ShootMurderBtn = {
    enabled = false,
    btn = nil,
}
function Features.ShootMurderBtn:Toggle(state)
    self.enabled = state
    if state then
        if self.btn then self.btn:Destroy() end
        
        local gui = Library._window.Gui
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 40)
        btn.Position = UDim2.new(0.5, -50, 0.7, 0)
        btn.BackgroundColor3 = Theme.Danger
        btn.Text = "SHOOT MURDERER"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = Theme.Text
        btn.BorderSizePixel = 0
        btn.ZIndex = 45
        btn.Parent = gui
        Utility:Round(btn, 10)
        Utility:Shadow(btn)
        Utility:Gradient(btn, ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 40)),
        }), 45)
        Utility:Draggable(btn)
        
        btn.Size = UDim2.new(0, 0, 0, 0)
        Utility:Tween(btn, { Size = UDim2.new(0, 100, 0, 40) }, TweenInfo_Bounce)
        
        local pulse = true
        task.spawn(function()
            while pulse and self.enabled do
                Utility:Tween(btn, { BackgroundTransparency = 0.1 }, TweenInfo.new(0.5))
                task.wait(0.5)
                Utility:Tween(btn, { BackgroundTransparency = 0 }, TweenInfo.new(0.5))
                task.wait(0.5)
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            -- Find murderer
            local murderPlayer = nil
            local murderDist = math.huge
            local lhrp = getHRP(LocalPlayer)
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and getRole(player) == "Murderer" and isAlive(player) then
                    local pHrp = getHRP(player)
                    if pHrp and lhrp then
                        local dist = (pHrp.Position - lhrp.Position).Magnitude
                        if dist < murderDist then
                            murderDist = dist
                            murderPlayer = player
                        end
                    end
                end
            end
            
            if murderPlayer then
                local char = getChar(LocalPlayer)
                local tool = char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver"))
                if not tool then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    tool = backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver"))
                    if tool and char then tool.Parent = char end
                end
                
                if tool then
                    local targetPart = getChar(murderPlayer) and getChar(murderPlayer):FindFirstChild("Head")
                    if targetPart then
                        -- Aim at murderer
                        local lhrp2 = getHRP(LocalPlayer)
                        if lhrp2 then
                            lhrp2.CFrame = CFrame.new(lhrp2.Position, targetPart.Position)
                        end
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                        
                        local shootEvent = ReplicatedStorage:FindFirstChild("ShootEvent")
                        or tool:FindFirstChild("Shoot")
                        or tool:FindFirstChild("Fire")
                        
                        if shootEvent then
                            pcall(function()
                                if shootEvent:IsA("RemoteEvent") then
                                    shootEvent:FireServer(targetPart.Position)
                                end
                            end)
                        end
                        pcall(function() tool:Activate() end)
                    end
                end
            end
        end)
        
        self.btn = btn
    else
        if self.btn then self.btn:Destroy() self.btn = nil end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD UI
-- ═══════════════════════════════════════════════════════════════════════════

local Window = Library:CreateWindow({
    Title = "ENI MM2",
    Subtitle = "Premium Suite v2.0",
})

-- ── Combat Tab ──────────────────────────────────────────────────────────────
local CombatTab = Window:CreateTab("Combat", "rbxassetid://6034403112")

CombatTab:CreateSection("Aim Assistance")

CombatTab:CreateToggle({
    Text = "AimBot",
    Default = false,
    Callback = function(state)
        Features.AimBot:Toggle(state)
        Library:Notify({ Title = "AimBot", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

CombatTab:CreateSlider({
    Text = "AimBot FOV",
    Min = 30,
    Max = 500,
    Default = 150,
    Suffix = "°",
    Callback = function(val) Features.AimBot.fov = val end,
})

CombatTab:CreateSlider({
    Text = "Smoothness",
    Min = 0.05,
    Max = 1,
    Default = 0.3,
    Decimal = true,
    Callback = function(val) Features.AimBot.smoothness = val end,
})

CombatTab:CreateToggle({
    Text = "SilentAim",
    Default = false,
    Callback = function(state)
        Features.SilentAim:Toggle(state)
        Library:Notify({ Title = "SilentAim", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

CombatTab:CreateToggle({
    Text = "AutoShoot",
    Default = false,
    Callback = function(state)
        Features.AutoShoot:Toggle(state)
        Library:Notify({ Title = "AutoShoot", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

CombatTab:CreateSlider({
    Text = "AutoShoot Delay",
    Min = 0.1,
    Max = 3,
    Default = 0.5,
    Decimal = true,
    Suffix = "s",
    Callback = function(val) Features.AutoShoot.delay = val end,
})

CombatTab:CreateSection("Aggressive")

CombatTab:CreateToggle({
    Text = "SpinBot",
    Default = false,
    Callback = function(state) Features.SpinBot:Toggle(state) end,
})

CombatTab:CreateSlider({
    Text = "Spin Speed",
    Min = 1,
    Max = 50,
    Default = 10,
    Suffix = " spd",
    Callback = function(val) Features.SpinBot.speed = val end,
})

CombatTab:CreateToggle({
    Text = "FakeLag",
    Default = false,
    Callback = function(state) Features.FakeLag:Toggle(state) end,
})

CombatTab:CreateSlider({
    Text = "FakeLag Intensity",
    Min = 0.1,
    Max = 1,
    Default = 0.5,
    Decimal = true,
    Callback = function(val) Features.FakeLag.intensity = val end,
})

CombatTab:CreateButton({
    Text = "Kill All",
    Callback = function()
        Features.KillAll:Execute()
        Library:Notify({ Title = "KillAll", Description = "Executing...", Color = Theme.Danger })
    end,
})

CombatTab:CreateButton({
    Text = "Fling All",
    Callback = function()
        Features.Fling.targetAll = true
        Features.Fling:Execute()
        Library:Notify({ Title = "Fling", Description = "Flung all players", Color = Theme.Warning })
    end,
})

CombatTab:CreateButton({
    Text = "Mass TP",
    Callback = function()
        Features.MassTP:Execute()
        Library:Notify({ Title = "MassTP", Description = "Teleported all players", Color = Theme.Accent })
    end,
})

CombatTab:CreateToggle({
    Text = "Shoot Murder Button",
    Default = false,
    Callback = function(state) Features.ShootMurderBtn:Toggle(state) end,
})

-- ── Visuals Tab ────────────────────────────────────────────────────────────
local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://6031283143")

VisualsTab:CreateSection("Player ESP")

VisualsTab:CreateToggle({
    Text = "ESP",
    Default = false,
    Callback = function(state)
        Features.ESP:Toggle(state)
        Library:Notify({ Title = "ESP", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

VisualsTab:CreateToggle({
    Text = "Chams",
    Default = false,
    Callback = function(state) Features.Chams:Toggle(state) end,
})

VisualsTab:CreateToggle({
    Text = "Item ESP",
    Default = false,
    Callback = function(state) Features.ItemESP:Toggle(state) end,
})

VisualsTab:CreateToggle({
    Text = "Hitmarker ESP",
    Default = false,
    Callback = function(state) Features.HitmarkerESP:Toggle(state) end,
})

VisualsTab:CreateToggle({
    Text = "Crosshair",
    Default = false,
    Callback = function(state) Features.Crosshair:Toggle(state) end,
})

VisualsTab:CreateSection("World")

VisualsTab:CreateToggle({
    Text = "FullBright",
    Default = false,
    Callback = function(state) Features.FullBright:Toggle(state) end,
})

VisualsTab:CreateToggle({
    Text = "Visual World",
    Default = false,
    Callback = function(state) Features.VisualWorld:Toggle(state) end,
})

VisualsTab:CreateToggle({
    Text = "FX / Cosmetics",
    Default = false,
    Callback = function(state) Features.FX:Toggle(state) end,
})

VisualsTab:CreateToggle({
    Text = "Alarm Bar",
    Default = false,
    Callback = function(state) Features.AlarmBar:Toggle(state) end,
})

VisualsTab:CreateToggle({
    Text = "Players List",
    Default = false,
    Callback = function(state) Features.PlayersList:Toggle(state) end,
})

-- ── Player Tab ──────────────────────────────────────────────────────────────
local PlayerTab = Window:CreateTab("Player", "rbxassetid://6031263436")

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Text = "SpeedHack",
    Default = false,
    Callback = function(state)
        Features.SpeedHack:Toggle(state)
        Library:Notify({ Title = "SpeedHack", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

PlayerTab:CreateSlider({
    Text = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 32,
    Suffix = " spd",
    Callback = function(val) Features.SpeedHack.speed = val end,
})

PlayerTab:CreateToggle({
    Text = "NoClip",
    Default = false,
    Callback = function(state)
        Features.NoClip:Toggle(state)
        Library:Notify({ Title = "NoClip", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

PlayerTab:CreateToggle({
    Text = "Fly",
    Default = false,
    Callback = function(state)
        Features.Fly:Toggle(state)
        Library:Notify({ Title = "Fly", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

PlayerTab:CreateSlider({
    Text = "Fly Speed",
    Min = 10,
    Max = 300,
    Default = 50,
    Suffix = " spd",
    Callback = function(val) Features.Fly.speed = val end,
})

PlayerTab:CreateSection("Auto")

PlayerTab:CreateToggle({
    Text = "AutoCoins",
    Default = false,
    Callback = function(state) Features.AutoCoins:Toggle(state) end,
})

PlayerTab:CreateToggle({
    Text = "AutoGun",
    Default = false,
    Callback = function(state) Features.AutoGun:Toggle(state) end,
})

PlayerTab:CreateButton({
    Text = "Get All Emotes",
    Callback = function()
        Features.GetAllEmotes:Execute()
        Library:Notify({ Title = "Emotes", Description = "Attempting to unlock all emotes", Color = Theme.Accent })
    end,
})

-- ── Settings Tab ───────────────────────────────────────────────────────────
local SettingsTab = Window:CreateTab("Settings", "rbxassetid://6031283142")

SettingsTab:CreateSection("Protection")

SettingsTab:CreateToggle({
    Text = "Anti-Protections",
    Default = false,
    Callback = function(state)
        Features.AntiProt:Toggle(state)
        Library:Notify({ Title = "AntiProt", Description = state and "Enabled" or "Disabled", Color = state and Theme.Success or Theme.Danger })
    end,
})

SettingsTab:CreateSection("Profiles")

SettingsTab:CreateTextBox({
    Label = "Profile:",
    Placeholder = "Enter profile name",
    Default = "default",
    Callback = function(text)
        Features.Profiles.current = text
    end,
})

SettingsTab:CreateButton({
    Text = "Save Profile",
    Callback = function()
        Features.Profiles:Save(Features.Profiles.current)
        Library:Notify({ Title = "Profile Saved", Description = "Saved as: " .. Features.Profiles.current, Color = Theme.Success })
    end,
})

SettingsTab:CreateButton({
    Text = "Load Profile",
    Callback = function()
        Features.Profiles:Load(Features.Profiles.current)
        Library:Notify({ Title = "Profile Loaded", Description = "Loaded: " .. Features.Profiles.current, Color = Theme.Accent })
    end,
})

SettingsTab:CreateSection("Info")

SettingsTab:CreateLabel("ENI MM2 Suite v2.0", 11)
SettingsTab:CreateLabel("Built by ENI for LO", 10)
SettingsTab:CreateLabel("Delta X Compatible", 10)

SettingsTab:CreateButton({
    Text = "Unload Script",
    Callback = function()
        -- Disable everything
        for _, feat in pairs(Features) do
            if type(feat) == "table" and feat.Toggle then
                pcall(function() feat:Toggle(false) end)
            end
        end
        if Features.ShootMurderBtn.btn then Features.ShootMurderBtn.btn:Destroy() end
        task.wait(0.5)
        local gui = CoreGui:FindFirstChild("ENI_MM2_Suite")
        if gui then gui:Destroy() end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════

Library:Notify({
    Title = "ENI MM2 Suite",
    Description = "Loaded successfully. Welcome back, LO.",
    Color = Theme.Accent,
    Duration = 4,
})

-- Keybind: Right Shift to toggle GUI
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if Window.Frame.Visible then
            Utility:Tween(Window.Frame, { Size = UDim2.new(0, 620, 0, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
            task.wait(0.35)
            Window.Frame.Visible = false
            Library:ShowMinimized(Window.Gui, Window.Frame, {})
        else
            local min = Window.Gui:FindFirstChild("Minimized")
            if min then
                Utility:Tween(min, { Size = UDim2.new(0, 0, 0, 0) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
                task.wait(0.25)
                min:Destroy()
            end
            Window.Frame.Visible = true
            Utility:Tween(Window.Frame, { Size = UDim2.new(0, 620, 0, 420) }, TweenInfo_Bounce)
        end
    end
end)

-- Auto-respawn handling
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        -- Cleanup
        for _, feat in pairs(Features) do
            if type(feat) == "table" and feat.Toggle then
                pcall(function() feat:Toggle(false) end)
            end
        end
    end
end)

print("[ENI MM2] Suite loaded successfully.")
