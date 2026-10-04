--[[
═══════════════════════════════════════════════════════════════════════════════
    ENI MM2 SUITE — Premium Edition v2.1
    Fixed: Content rendering, canvas sizing, Delta X compatibility
    Built by ENI for LO — because the first draft was empty and that hurt.
═══════════════════════════════════════════════════════════════════════════════
]]

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

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

local TI_Quick   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_Smooth  = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_Bounce  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════════════════════

local Utility = {}

function Utility:Round(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

function Utility:Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.5
    s.Parent = parent
    return s
end

function Utility:Gradient(parent, colorSeq, rotation)
    local g = Instance.new("UIGradient")
    g.Color = colorSeq or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentDim),
    })
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

function Utility:Padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

function Utility:List(parent, direction, padding, alignment)
    local l = Instance.new("UIListLayout")
    l.FillDirection = direction or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, padding or 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    if alignment then l.HorizontalAlignment = alignment end
    l.Parent = parent
    return l
end

function Utility:Shadow(parent)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://1316045217"
    s.ImageColor3 = Theme.Shadow
    s.ImageTransparency = 0.5
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(10, 10, 118, 118)
    s.Size = UDim2.new(1, 14, 1, 14)
    s.Position = UDim2.new(0, -7, 0, -7)
    s.ZIndex = parent.ZIndex - 1
    s.Parent = parent
    return s
end

function Utility:Tween(obj, props, info)
    local t = TweenService:Create(obj, info or TI_Quick, props)
    t:Play()
    return t
end

-- ★ FIX: Manual canvas size update — AutomaticCanvasSize breaks on Delta X
function Utility:UpdateCanvas(scrollFrame)
    if not scrollFrame or not scrollFrame:IsA("ScrollingFrame") then return end
    local layout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if not layout then return end

    task.defer(function()
        RunService.Heartbeat:Wait()

        local pad = scrollFrame:FindFirstChildOfClass("UIPadding")
        local padTop = pad and pad.PaddingTop.Offset or 0
        local padBottom = pad and pad.PaddingBottom.Offset or 0

        -- UIListLayout already calculates the exact content height.
        local contentHeight = layout.AbsoluteContentSize.Y
        scrollFrame.CanvasSize = UDim2.new(
            0, 0,
            0, math.max(contentHeight + padTop + padBottom, scrollFrame.AbsoluteSize.Y)
        )
    end)
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
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = gethui and gethui() or CoreGui
    end
    return gui
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LIBRARY
-- ═══════════════════════════════════════════════════════════════════════════

local Library = {}
local WindowObj = nil

function Library:CreateWindow(config)
    local gui = Utility:GetGui()
    
    -- ★ Root ScreenGui scale adapter
    local scaleAdapter = Instance.new("Frame")
    scaleAdapter.Name = "ScaleAdapter"
    scaleAdapter.Size = UDim2.new(1, 0, 1, 0)
    scaleAdapter.BackgroundTransparency = 1
    scaleAdapter.Parent = gui
    
    -- Main container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -175)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BackgroundTransparency = 0.02
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 10
    MainFrame.Parent = scaleAdapter
    Utility:Round(MainFrame, 14)
    Utility:Stroke(MainFrame, Theme.Border, 1, 0.3)
    Utility:Shadow(MainFrame)
    
    -- Accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.BackgroundColor3 = Theme.Accent
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 11
    accentBar.Parent = MainFrame
    Utility:Round(accentBar, 14)
    Utility:Gradient(accentBar, ColorSequence.new({
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
    Logo.Size = UDim2.new(0, 22, 0, 22)
    Logo.Position = UDim2.new(0, 14, 0.5, -11)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://6031075915"
    Logo.ImageColor3 = Theme.Accent
    Logo.ZIndex = 13
    Logo.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
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
    Subtitle.Size = UDim2.new(0, 200, 0, 12)
    Subtitle.Position = UDim2.new(0, 44, 0.5, 4)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = config.Subtitle or "Premium Suite"
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 10
    Subtitle.TextColor3 = Theme.TextFaint
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.ZIndex = 13
    Subtitle.Parent = TitleBar
    
    -- Close button
    local CloseBtn = Instance.new("TextButton")
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
        Utility:Tween(CloseBtn, { BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.2, TextColor3 = Theme.Text }, TI_Quick)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Utility:Tween(CloseBtn, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim }, TI_Quick)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Utility:Tween(MainFrame, { Size = UDim2.new(0, 520, 0, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.35)
        MainFrame.Visible = false
        self:ShowMinimized(gui, MainFrame)
    end)
    
    -- Minimize button
    local MinBtn = Instance.new("TextButton")
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
        Utility:Tween(MinBtn, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.3, TextColor3 = Theme.Text }, TI_Quick)
    end)
    MinBtn.MouseLeave:Connect(function()
        Utility:Tween(MinBtn, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim }, TI_Quick)
    end)
    MinBtn.MouseButton1Click:Connect(function()
        Utility:Tween(MainFrame, { Size = UDim2.new(0, 520, 0, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.35)
        MainFrame.Visible = false
        self:ShowMinimized(gui, MainFrame)
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
    
    -- ★ FIX: Use a ScrollingFrame for sidebar too, with manual canvas
    local SidebarScroll = Instance.new("ScrollingFrame")
    SidebarScroll.Name = "SidebarScroll"
    SidebarScroll.Size = UDim2.new(1, -12, 1, -12)
    SidebarScroll.Position = UDim2.new(0, 6, 0, 6)
    SidebarScroll.BackgroundTransparency = 1
    SidebarScroll.BorderSizePixel = 0
    SidebarScroll.ScrollBarThickness = 2
    SidebarScroll.ScrollBarImageColor3 = Theme.ScrollBar
    SidebarScroll.ScrollBarImageTransparency = 0.5
    SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SidebarScroll.ElasticBehavior = Enum.ElasticBehavior.Always
    SidebarScroll.ZIndex = 12
    SidebarScroll.Parent = Sidebar
    Utility:List(SidebarScroll, Enum.FillDirection.Vertical, 4)
    Utility:Padding(SidebarScroll, 4, 4, 4, 4)
    
    -- Content area — ★ FIX: explicit size, no negative offset weirdness
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -174, 1, -58)
    ContentArea.Position = UDim2.new(0, 162, 0, 50)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ZIndex = 11
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = MainFrame
    
    Utility:Draggable(MainFrame, TitleBar)
    
    -- Open animation
    MainFrame.Size = UDim2.new(0, 520, 0, 0)
    MainFrame.Visible = true
    Utility:Tween(MainFrame, { Size = UDim2.new(0, 520, 0, 350) }, TI_Bounce)
    
    WindowObj = {
        Gui = gui,
        Frame = MainFrame,
        Sidebar = Sidebar,
        SidebarScroll = SidebarScroll,
        ContentArea = ContentArea,
        Tabs = {},
        ActiveTab = nil,
    }
    
    -- Expose CreateTab on the returned Window object.
    -- The build section calls Window:CreateTab(...), while the factory
    -- implementation lives on Library. Without this bridge, the script
    -- stops before the first tab is created and the GUI appears empty.
    function WindowObj:CreateTab(name, iconId)
        return Library:CreateTab(self, name, iconId)
    end

    self._window = WindowObj
    return WindowObj
end

function Library:ShowMinimized(gui, mainFrame)
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
    Utility:Tween(MinBtn, { Size = UDim2.new(0, 52, 0, 52) }, TI_Bounce)
    
    MinBtn.MouseButton1Click:Connect(function()
        Utility:Tween(MinBtn, { Size = UDim2.new(0, 0, 0, 0) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.25)
        MinBtn:Destroy()
        mainFrame.Visible = true
        Utility:Tween(mainFrame, { Size = UDim2.new(0, 520, 0, 350) }, TI_Bounce)
    end)
end

function Library:CreateTab(window, name, iconId)
    local tab = {}
    
    -- Tab button
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = name
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.BackgroundColor3 = Theme.Panel
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = ""
    TabBtn.BorderSizePixel = 0
    TabBtn.ZIndex = 12
    TabBtn.Parent = window.SidebarScroll
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
    
    -- ★ FIX: Page is a Frame (not ScrollingFrame) wrapping a ScrollingFrame
    local Page = Instance.new("Frame")
    Page.Name = name .. "_Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ZIndex = 11
    Page.Parent = window.ContentArea
    
    local PageScroll = Instance.new("ScrollingFrame")
    PageScroll.Name = "Scroll"
    PageScroll.Size = UDim2.new(1, 0, 1, 0)
    PageScroll.Position = UDim2.new(0, 0, 0, 0)
    PageScroll.BackgroundTransparency = 1
    PageScroll.BorderSizePixel = 0
    PageScroll.ScrollBarThickness = 3
    PageScroll.ScrollBarImageColor3 = Theme.ScrollBar
    PageScroll.ScrollBarImageTransparency = 0.4
    PageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    -- ★ NO AutomaticCanvasSize — it breaks on Delta X
    PageScroll.ElasticBehavior = Enum.ElasticBehavior.Always
    PageScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    PageScroll.ZIndex = 12
    PageScroll.Parent = Page
    
    local PageList = Instance.new("UIListLayout")
    PageList.FillDirection = Enum.FillDirection.Vertical
    PageList.Padding = UDim.new(0, 6)
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Parent = PageScroll
    
    local PagePad = Instance.new("UIPadding")
    PagePad.PaddingTop = UDim.new(0, 6)
    PagePad.PaddingBottom = UDim.new(0, 6)
    PagePad.PaddingLeft = UDim.new(0, 8)
    PagePad.PaddingRight = UDim.new(0, 8)
    PagePad.Parent = PageScroll
    
    -- Hover states
    TabBtn.MouseEnter:Connect(function()
        if not tab._active then
            Utility:Tween(TabBtn, { BackgroundTransparency = 0.6 }, TI_Quick)
            Utility:Tween(Icon, { ImageColor3 = Theme.Text }, TI_Quick)
            Utility:Tween(Label, { TextColor3 = Theme.Text }, TI_Quick)
        end
    end)
    TabBtn.MouseLeave:Connect(function()
        if not tab._active then
            Utility:Tween(TabBtn, { BackgroundTransparency = 1 }, TI_Quick)
            Utility:Tween(Icon, { ImageColor3 = Theme.TextDim }, TI_Quick)
            Utility:Tween(Label, { TextColor3 = Theme.TextDim }, TI_Quick)
        end
    end)
    
    local function activateTab()
        for _, t in ipairs(window.Tabs) do
            t._active = false
            t.Page.Visible = false
            Utility:Tween(t.Button, { BackgroundTransparency = 1 }, TI_Quick)
            Utility:Tween(t.Icon, { ImageColor3 = Theme.TextDim }, TI_Quick)
            Utility:Tween(t.Label, { TextColor3 = Theme.TextDim }, TI_Quick)
            local ind = t.Button:FindFirstChild("Indicator")
            if ind then ind:Destroy() end
        end
        tab._active = true
        Page.Visible = true
        Utility:Tween(TabBtn, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85 }, TI_Quick)
        Utility:Tween(Icon, { ImageColor3 = Theme.AccentLight }, TI_Quick)
        Utility:Tween(Label, { TextColor3 = Theme.Text }, TI_Quick)
        
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 3, 0, 16)
        indicator.Position = UDim2.new(0, 0, 0.5, -8)
        indicator.BackgroundColor3 = Theme.Accent
        indicator.BorderSizePixel = 0
        indicator.ZIndex = 14
        indicator.Parent = TabBtn
        Utility:Round(indicator, 2)
        
        -- ★ FIX: Force canvas update when tab is activated
        Utility:UpdateCanvas(PageScroll)
    end
    
    TabBtn.MouseButton1Click:Connect(activateTab)
    
    tab.Button = TabBtn
    tab.Icon = Icon
    tab.Label = Label
    tab.Page = Page
    tab.PageScroll = PageScroll
    tab._active = false
    tab.Window = window
    tab._elementCount = 0
    
    table.insert(window.Tabs, tab)
    
    if #window.Tabs == 1 then
        activateTab()
    end
    
    -- ★ FIX: Update sidebar canvas too
    Utility:UpdateCanvas(window.SidebarScroll)
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- ELEMENT FACTORY
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- ★ Helper: track element count & update canvas
    local function trackElement()
        tab._elementCount = tab._elementCount + 1
        Utility:UpdateCanvas(PageScroll)
    end
    
    function tab:CreateSection(title)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 24)
        Container.BackgroundTransparency = 1
        Container.LayoutOrder = tab._elementCount
        Container.ZIndex = 12
        Container.Parent = PageScroll
        tab._elementCount = tab._elementCount + 1
        
        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(1, 0, 0, 1)
        Line.Position = UDim2.new(0, 0, 0.5, 0)
        Line.BackgroundColor3 = Theme.Border
        Line.BorderSizePixel = 0
        Line.BackgroundTransparency = 0.5
        Line.ZIndex = 13
        Line.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0, 140, 0, 14)
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
        bg.Size = UDim2.new(0, 130, 0, 3)
        bg.Position = UDim2.new(0, 6, 0.5, 6)
        bg.BackgroundColor3 = Theme.Background
        bg.BorderSizePixel = 0
        bg.ZIndex = 13
        bg.Parent = Container
        
        trackElement()
        return Container
    end
    
    function tab:CreateButton(btnConfig)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 0, 34)
        Button.LayoutOrder = tab._elementCount
        Button.BackgroundColor3 = Theme.Panel
        Button.BackgroundTransparency = 0.2
        Button.Text = ""
        Button.BorderSizePixel = 0
        Button.ZIndex = 12
        Button.Parent = PageScroll
        Utility:Round(Button, 8)
        Utility:Stroke(Button, Theme.Border, 1, 0.6)
        
        local BtnLabel = Instance.new("TextLabel")
        BtnLabel.Size = UDim2.new(1, -30, 0, 14)
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
            Utility:Tween(Button, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TI_Quick)
            Utility:Tween(arrow, { ImageColor3 = Theme.AccentLight, Position = UDim2.new(1, -18, 0.5, -6) }, TI_Quick)
        end)
        Button.MouseLeave:Connect(function()
            Utility:Tween(Button, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.2 }, TI_Quick)
            Utility:Tween(arrow, { ImageColor3 = Theme.TextFaint, Position = UDim2.new(1, -20, 0.5, -6) }, TI_Quick)
        end)
        Button.MouseButton1Down:Connect(function()
            Utility:Tween(Button, { BackgroundColor3 = Theme.Pressed, BackgroundTransparency = 0 }, TweenInfo.new(0.05))
        end)
        Button.MouseButton1Up:Connect(function()
            Utility:Tween(Button, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TI_Quick)
            if btnConfig.Callback then btnConfig.Callback() end
        end)
        
        trackElement()
        return Button
    end
    
    function tab:CreateToggle(toggleConfig)
        local toggle = { state = false }
        
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 34)
        Container.LayoutOrder = tab._elementCount
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = PageScroll
        
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
        
        local function setToggle(state)
            toggle.state = state
            if state then
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Theme.Accent }, TI_Quick)
                Utility:Tween(Knob, { Position = UDim2.new(1, -17, 0.5, -7) }, TI_Quick)
                Utility:Tween(ToggleLabel, { TextColor3 = Theme.AccentLight }, TI_Quick)
            else
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleTrack }, TI_Quick)
                Utility:Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -7) }, TI_Quick)
                Utility:Tween(ToggleLabel, { TextColor3 = Theme.Text }, TI_Quick)
            end
            if toggleConfig.Callback then
                task.spawn(function() toggleConfig.Callback(state) end)
            end
        end
        
        ToggleBtn.MouseButton1Click:Connect(function()
            setToggle(not toggle.state)
        end)
        
        ToggleBtn.MouseEnter:Connect(function()
            if not toggle.state then
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Color3.fromRGB(60, 60, 72) }, TI_Quick)
            end
        end)
        ToggleBtn.MouseLeave:Connect(function()
            if not toggle.state then
                Utility:Tween(ToggleBtn, { BackgroundColor3 = Theme.ToggleTrack }, TI_Quick)
            end
        end)
        
        toggle.Set = setToggle
        toggle.Get = function() return toggle.state end
        
        if toggleConfig.Default then 
            task.spawn(function() setToggle(true) end)
        end
        
        trackElement()
        return toggle
    end
    
    function tab:CreateSlider(sliderConfig)
        local slider = { value = sliderConfig.Default or sliderConfig.Min or 0 }
        local min = sliderConfig.Min or 0
        local max = sliderConfig.Max or 100
        local suffix = sliderConfig.Suffix or ""
        
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 50)
        Container.LayoutOrder = tab._elementCount
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = PageScroll
        
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
        ValueLabel.Text = tostring(slider.value) .. suffix
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
        
        local function updateSlider(inputPos)
            local rel = (inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            slider.value = min + (max - min) * rel
            if sliderConfig.Decimal then
                slider.value = math.round(slider.value * 100) / 100
            else
                slider.value = math.floor(slider.value)
            end
            ValueLabel.Text = tostring(slider.value) .. suffix
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Knob.Position = UDim2.new(rel, -7, 0.5, -7)
            if sliderConfig.Callback then
                task.spawn(function() sliderConfig.Callback(slider.value) end)
            end
        end
        
        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input.Position)
                Utility:Tween(Knob, { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(Knob.Position.X.Scale, -9, 0.5, -9) }, TI_Quick)
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
                    Utility:Tween(Knob, { Size = UDim2.new(0, 14, 0, 14) }, TI_Quick)
                end
            end
        end)
        
        -- Init
        local initRel = (slider.value - min) / (max - min)
        Fill.Size = UDim2.new(initRel, 0, 1, 0)
        Knob.Position = UDim2.new(initRel, -7, 0.5, -7)
        
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
        
        trackElement()
        return slider
    end
    
    function tab:CreateTextBox(tbConfig)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 34)
        Container.LayoutOrder = tab._elementCount
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = PageScroll
        
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
            Utility:Tween(Box, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }, TI_Quick)
            Utility:Stroke(Box, Theme.Accent, 1, 0)
        end)
        Box.FocusLost:Connect(function(enter)
            Utility:Tween(Box, { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.2 }, TI_Quick)
            Utility:Stroke(Box, Theme.Border, 1, 0.5)
            if tbConfig.Callback then tbConfig.Callback(Box.Text, enter) end
        end)
        
        trackElement()
        return Box
    end
    
    function tab:CreateLabel(text, fontSize)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 18)
        Label.LayoutOrder = tab._elementCount
        Label.BackgroundTransparency = 1
        Label.Text = text or "Label"
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = fontSize or 11
        Label.TextColor3 = Theme.TextDim
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 12
        Label.Parent = PageScroll
        
        trackElement()
        return Label
    end
    
    function tab:CreateDropdown(ddConfig)
        local dd = { open = false, value = ddConfig.Default or (ddConfig.Options and ddConfig.Options[1]) or "Select" }
        
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 34)
        Container.LayoutOrder = tab._elementCount
        Container.BackgroundTransparency = 1
        Container.ZIndex = 12
        Container.Parent = PageScroll
        
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
        Btn.Text = tostring(dd.value)
        Btn.Font = Enum.Font.Gotham
        Btn.TextSize = 11
        Btn.TextColor3 = Theme.Text
        Btn.BorderSizePixel = 0
        Btn.ZIndex = 13
        Btn.Parent = Container
        Utility:Round(Btn, 6)
        Utility:Stroke(Btn, Theme.Border, 1, 0.5)
        
        trackElement()
        return dd
    end
    
    return tab
end

function Library:Notify(config)
    if not WindowObj then return end
    local gui = WindowObj.Gui
    
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
    
    Notif.Size = UDim2.new(0, 0, 0, 60)
    Notif.BackgroundTransparency = 1
    Utility:Tween(Notif, { Size = UDim2.new(0, 280, 0, 60), BackgroundTransparency = 0.1 }, TI_Bounce)
    
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

local function getChar(p) return p and p.Character end
local function getHRP(p) local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(p) local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p) local h = getHum(p) return h and h.Health > 0 end

local function normalizeRole(value)
    if value == nil then return nil end
    local s = tostring(value):lower():gsub("%s+", "")
    if s == "murderer" or s == "murder" or s == "killer" then return "Murderer" end
    if s == "sheriff" or s == "detective" then return "Sheriff" end
    if s == "innocent" or s == "civilian" then return "Innocent" end
    return nil
end

local function getRole(player)
    if not player then return "Innocent" end

    -- Custom-mode friendly: attributes are checked first.
    for _, key in ipairs({"Role", "PlayerRole", "MM2Role", "RoundRole"}) do
        local role = normalizeRole(player:GetAttribute(key))
        if role then return role end
    end

    -- Then StringValue/BoolValue role markers.
    for _, key in ipairs({"Role", "PlayerRole", "MM2Role"}) do
        local v = player:FindFirstChild(key)
        if v and v:IsA("StringValue") then
            local role = normalizeRole(v.Value)
            if role then return role end
        end
    end
    local murdererFlag = player:FindFirstChild("Murderer")
    if murdererFlag and murdererFlag:IsA("BoolValue") and murdererFlag.Value then
        return "Murderer"
    end
    local sheriffFlag = player:FindFirstChild("Sheriff")
    if sheriffFlag and sheriffFlag:IsA("BoolValue") and sheriffFlag.Value then
        return "Sheriff"
    end

    -- Finally fall back to role-specific tools.
    local backpack = player:FindFirstChild("Backpack")
    local char = getChar(player)
    local containers = {char, backpack}

    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                local n = obj.Name:lower()
                if n:find("knife") or n:find("murder") then
                    return "Murderer"
                end
            end
        end
    end

    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                local n = obj.Name:lower()
                if n:find("revolver") or n == "gun" or n:find("sheriff") then
                    return "Sheriff"
                end
            end
        end
    end

    -- Team names are a useful fallback for custom modes.
    if player.Team then
        local role = normalizeRole(player.Team.Name)
        if role then return role end
    end

    return "Innocent"
end

local function findGun(player)
    if not player then return nil end
    local char = getChar(player)
    local backpack = player:FindFirstChild("Backpack")
    local containers = {char, backpack}
    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") then
                    local n = obj.Name:lower()
                    if n == "gun" or n == "revolver" or n:find("sheriff") or n:find("pistol") then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

local function fireGun(tool, targetPosition)
    if not tool then return false end
    local fired = false

    -- Prefer the custom remote if the weapon exposes one.
    local remoteNames = {"ShootEvent", "Shoot", "Fire", "FireEvent"}
    for _, name in ipairs(remoteNames) do
        local remote = tool:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
        if remote then
            local ok = pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(targetPosition)
                    return true
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(targetPosition)
                    return true
                end
            end)
            if ok then fired = true break end
        end
    end

    -- Also activate the Tool so modes using Tool.Activated continue to work.
    pcall(function()
        if tool.Parent ~= getChar(LocalPlayer) then
            local char = getChar(LocalPlayer)
            if char then tool.Parent = char end
        end
        tool:Activate()
        fired = true
    end)

    return fired
end

-- ── SpeedHack ──────────────────────────────────────────────────────────────
Features.SpeedHack = { enabled = false, speed = 32, conn = nil }
function Features.SpeedHack:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            local char = getChar(LocalPlayer)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then hum.WalkSpeed = self.speed end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        local char = getChar(LocalPlayer)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ── NoClip ─────────────────────────────────────────────────────────────────
Features.NoClip = { enabled = false, conn = nil }
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
Features.Fly = { enabled = false, speed = 50, conn = nil, bv = nil, bg = nil }
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
Features.ESP = { enabled = false, objects = {} }
function Features.ESP:Toggle(state)
    self.enabled = state
    if state then
        local function setup(player)
            if player == LocalPlayer then return end
            local function onChar(char)
                if not self.enabled then return end
                local hrp = char:WaitForChild("HumanoidRootPart", 5)
                local hum = char:WaitForChild("Humanoid", 5)
                local head = char:WaitForChild("Head", 5)
                if not hrp or not hum then return end
                local role = getRole(player)
                local color = role == "Murderer" and Color3.fromRGB(255, 60, 60)
                    or role == "Sheriff" and Color3.fromRGB(60, 120, 255)
                    or Color3.fromRGB(80, 210, 120)
                local hl = Instance.new("Highlight")
                hl.Name = "ENI_ESP"
                hl.Adornee = char
                hl.FillTransparency = 0.7
                hl.FillColor = color
                hl.OutlineColor = color
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = char
                local bb = Instance.new("BillboardGui")
                bb.Name = "ENI_ESP_BB"
                bb.Adornee = head
                bb.Size = UDim2.new(0, 200, 0, 40)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true
                bb.Parent = char
                local nl = Instance.new("TextLabel")
                nl.Size = UDim2.new(1, 0, 0, 14)
                nl.BackgroundTransparency = 1
                nl.Text = player.DisplayName .. " [" .. role .. "]"
                nl.Font = Enum.Font.GothamBold
                nl.TextSize = 12
                nl.TextColor3 = color
                nl.TextStrokeTransparency = 0.5
                nl.ZIndex = 2
                nl.Parent = bb
                local dl = Instance.new("TextLabel")
                dl.Size = UDim2.new(1, 0, 0, 12)
                dl.Position = UDim2.new(0, 0, 0, 16)
                dl.BackgroundTransparency = 1
                dl.Text = ""
                dl.Font = Enum.Font.Gotham
                dl.TextSize = 10
                dl.TextColor3 = Theme.Text
                dl.TextStrokeTransparency = 0.5
                dl.ZIndex = 2
                dl.Parent = bb
                local roleConn = task.spawn(function()
                    while self.enabled and char and char.Parent and hum.Health > 0 and bb and bb.Parent do
                        local liveRole = getRole(player)
                        local liveColor = liveRole == "Murderer" and Color3.fromRGB(255, 60, 60)
                            or liveRole == "Sheriff" and Color3.fromRGB(60, 120, 255)
                            or Color3.fromRGB(80, 210, 120)
                        hl.FillColor = liveColor
                        hl.OutlineColor = liveColor
                        nl.Text = player.DisplayName .. " [" .. liveRole .. "]"
                        task.wait(0.5)
                    end
                end)

                local conn = RunService.RenderStepped:Connect(function()
                    if not self.enabled or not char or not char.Parent or hum.Health <= 0 then
                        if conn then conn:Disconnect() end
                        if hl then hl:Destroy() end
                        if bb then bb:Destroy() end
                        return
                    end
                    local lhrp = getHRP(LocalPlayer)
                    if lhrp then
                        local dist = math.floor((lhrp.Position - hrp.Position).Magnitude)
                        dl.Text = dist .. " studs"
                    end
                end)
                self.objects[player.UserId] = { hl = hl, bb = bb, conn = conn }
            end
            if player.Character then onChar(player.Character) end
            player.CharacterAdded:Connect(onChar)
        end
        for _, p in ipairs(Players:GetPlayers()) do setup(p) end
        connections.espJoin = Players.PlayerAdded:Connect(setup)
    else
        if connections.espJoin then connections.espJoin:Disconnect() connections.espJoin = nil end
        for _, obj in pairs(self.objects) do
            if obj.conn then obj.conn:Disconnect() end
            if obj.hl then obj.hl:Destroy() end
            if obj.bb then obj.bb:Destroy() end
        end
        self.objects = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character
            if c then
                local h = c:FindFirstChild("ENI_ESP")
                if h then h:Destroy() end
                local b = c:FindFirstChild("ENI_ESP_BB")
                if b then b:Destroy() end
            end
        end
    end
end

-- ── Chams ─────────────────────────────────────────────────────────────────
Features.Chams = { enabled = false, objects = {} }
function Features.Chams:Toggle(state)
    self.enabled = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c = p.Character
                if c then
                    local h = Instance.new("Highlight")
                    h.Name = "ENI_Cham"
                    h.Adornee = c
                    h.FillTransparency = 0.5
                    h.FillColor = Color3.fromRGB(130, 95, 255)
                    h.OutlineColor = Color3.fromRGB(160, 130, 255)
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = c
                    self.objects[p.UserId] = h
                end
            end
        end
    else
        for _, h in pairs(self.objects) do if h then h:Destroy() end end
        self.objects = {}
    end
end

-- ── ItemESP ────────────────────────────────────────────────────────────────
Features.ItemESP = { enabled = false, conn = nil, objects = {} }
function Features.ItemESP:Toggle(state)
    self.enabled = state
    if state then
        local function scan()
            for _, o in pairs(self.objects) do if o then o:Destroy() end end
            self.objects = {}
            for _, d in ipairs(Workspace:GetDescendants()) do
                local n = d.Name:lower()
                if n:match("coin") or n:match("gun") or n:match("knife") or n:match("revolver") or n:match("pickup") then
                    local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 100, 0, 30)
                        bb.AlwaysOnTop = true
                        bb.Parent = part
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 1, 0)
                        l.BackgroundTransparency = 1
                        l.Text = d.Name
                        l.Font = Enum.Font.GothamBold
                        l.TextSize = 11
                        l.TextColor3 = Color3.fromRGB(255, 200, 80)
                        l.TextStrokeTransparency = 0.5
                        l.ZIndex = 2
                        l.Parent = bb
                        local hl = Instance.new("Highlight")
                        hl.Adornee = d
                        hl.FillColor = Color3.fromRGB(255, 200, 80)
                        hl.FillTransparency = 0.6
                        hl.OutlineColor = Color3.fromRGB(255, 220, 120)
                        hl.Parent = part
                        self.objects[#self.objects + 1] = bb
                        self.objects[#self.objects + 1] = hl
                    end
                end
            end
        end
        scan()
        self.conn = task.spawn(function()
            while self.enabled do scan() task.wait(2) end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
        for _, o in pairs(self.objects) do if o then o:Destroy() end end
        self.objects = {}
    end
end

-- ── FullBright ────────────────────────────────────────────────────────────
Features.FullBright = { enabled = false, orig = {} }
function Features.FullBright:Toggle(state)
    self.enabled = state
    if state then
        self.orig.Brightness = Lighting.Brightness
        self.orig.ClockTime = Lighting.ClockTime
        self.orig.FogEnd = Lighting.FogEnd
        self.orig.GlobalShadows = Lighting.GlobalShadows
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
    else
        if self.orig.Brightness then Lighting.Brightness = self.orig.Brightness end
        if self.orig.ClockTime then Lighting.ClockTime = self.orig.ClockTime end
        if self.orig.FogEnd then Lighting.FogEnd = self.orig.FogEnd end
        if self.orig.GlobalShadows ~= nil then Lighting.GlobalShadows = self.orig.GlobalShadows end
    end
end

-- ── AimBot ────────────────────────────────────────────────────────────────
Features.AimBot = { enabled = false, fov = 150, smoothness = 0.3, conn = nil }
function Features.AimBot:GetClosest()
    local closest, cd = nil, self.fov
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) then
            local c = getChar(p)
            local head = c and c:FindFirstChild("Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < cd then cd = d closest = head end
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
            local t = self:GetClosest()
            if t then
                local cur = Camera.CFrame
                local tgt = CFrame.new(cur.Position, t.Position)
                Camera.CFrame = cur:Lerp(tgt, self.smoothness)
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── SilentAim ──────────────────────────────────────────────────────────────
Features.SilentAim = { enabled = false, fov = 200 }
function Features.SilentAim:GetTarget()
    local closest, cd = nil, self.fov
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) then
            local c = getChar(p)
            local head = c and c:FindFirstChild("Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < cd then cd = d closest = head end
                end
            end
        end
    end
    return closest
end
function Features.SilentAim:Toggle(state)
    self.enabled = state
end

-- ── AutoShoot ──────────────────────────────────────────────────────────────
Features.AutoShoot = { enabled = false, delay = 0.5, conn = nil }
function Features.AutoShoot:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            while self.enabled do
                local tool = findGun(LocalPlayer)
                if tool then
                    local closest, cd = nil, math.huge
                    local lhrp = getHRP(LocalPlayer)
                    if lhrp then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and isAlive(p) and getRole(p) == "Murderer" then
                                local phrp = getHRP(p)
                                if phrp then
                                    local d = (phrp.Position - lhrp.Position).Magnitude
                                    if d < cd then cd = d closest = p end
                                end
                            end
                        end
                    end

                    if closest then
                        local targetChar = getChar(closest)
                        local head = targetChar and targetChar:FindFirstChild("Head")
                        if head then
                            fireGun(tool, head.Position)
                        end
                    end
                end
                task.wait(math.max(0.05, self.delay))
            end
        end)
    else
        if self.conn then
            task.cancel(self.conn)
            self.conn = nil
        end
    end
end

-- ── SpinBot ────────────────────────────────────────────────────────────────
Features.SpinBot = { enabled = false, speed = 10, conn = nil }
function Features.SpinBot:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.RenderStepped:Connect(function()
            local char = getChar(LocalPlayer)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(self.speed), 0) end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── FakeLag ────────────────────────────────────────────────────────────────
Features.FakeLag = { enabled = false, intensity = 0.5, conn = nil }
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

-- ── HitmarkerESP ──────────────────────────────────────────────────────────
Features.HitmarkerESP = { enabled = false, conn = nil, lastHealth = {} }
function Features.HitmarkerESP:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.RenderStepped:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) then
                    local hum = getHum(p)
                    local char = getChar(p)
                    if char and hum then
                        local existing = char:FindFirstChild("ENI_Hitmarker")
                        if not existing and hum.Health < (self.lastHealth[p.UserId] or hum.MaxHealth) then
                            local m = Instance.new("Part")
                            m.Name = "ENI_Hitmarker"
                            m.Size = Vector3.new(0.5, 0.5, 0.5)
                            m.CFrame = char:GetPivot()
                            m.Anchored = true
                            m.CanCollide = false
                            m.Transparency = 0.5
                            m.Color = Color3.fromRGB(255, 60, 60)
                            m.Material = Enum.Material.Neon
                            m.Parent = Workspace
                            task.delay(1.5, function() if m then m:Destroy() end end)
                        end
                        self.lastHealth[p.UserId] = hum.Health
                    end
                end
            end
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        self.lastHealth = {}
    end
end

-- ── AutoCoins ──────────────────────────────────────────────────────────────
Features.AutoCoins = { enabled = false, conn = nil }
function Features.AutoCoins:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            while self.enabled do
                local char = getChar(LocalPlayer)
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d.Name:lower():match("coin") then
                            local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
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
Features.AutoGun = { enabled = false, conn = nil }
function Features.AutoGun:Toggle(state)
    self.enabled = state
    if state then
        self.conn = task.spawn(function()
            while self.enabled do
                local char = getChar(LocalPlayer)
                if char then
                    local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if bp then hasGun = hasGun or bp:FindFirstChild("Gun") or bp:FindFirstChild("Revolver") end
                    if not hasGun then
                        for _, d in ipairs(Workspace:GetDescendants()) do
                            local n = d.Name:lower()
                            if n:match("gun") or n:match("revolver") then
                                local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
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
Features.Fling = { power = 500, targetAll = false }
function Features.Fling:Execute(target)
    local char = getChar(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local function fling(v)
        local vc = getChar(v)
        local vh = vc and vc:FindFirstChild("HumanoidRootPart")
        if vh then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = (vh.Position - hrp.Position).Unit * self.power + Vector3.new(0, self.power * 0.3, 0)
            bv.Parent = vh
            task.wait(0.5)
            bv:Destroy()
        end
    end
    if self.targetAll then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then task.spawn(function() fling(p) end) end
        end
    elseif target then fling(target) end
end

-- ── MassTP ─────────────────────────────────────────────────────────────────
Features.MassTP = {}
function Features.MassTP:Execute()
    local char = getChar(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pc = getChar(p)
            local ph = pc and pc:FindFirstChild("HumanoidRootPart")
            if ph then
                ph.CFrame = CFrame.new(pos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
            end
        end
    end
end

-- ── KillAll ────────────────────────────────────────────────────────────────
Features.KillAll = {}
function Features.KillAll:Execute()
    local char = getChar(LocalPlayer)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local knife = char and (char:FindFirstChild("Knife") or char:FindFirstChild("KnifeWeapon"))
    knife = knife or (bp and (bp:FindFirstChild("Knife") or bp:FindFirstChild("KnifeWeapon")))
    if knife then
        knife.Parent = char
        local lhrp = getHRP(LocalPlayer)
        if lhrp then
            local orig = lhrp.CFrame
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) then
                    local ph = getHRP(p)
                    if ph then
                        lhrp.CFrame = CFrame.new(ph.Position + Vector3.new(0, 0, 2), ph.Position)
                        pcall(function() knife:Activate() end)
                        local stab = knife:FindFirstChild("Stab") or knife:FindFirstChild("Attack")
                        or ReplicatedStorage:FindFirstChild("StabEvent") or ReplicatedStorage:FindFirstChild("MeleeEvent")
                        if stab then
                            pcall(function()
                                if stab:IsA("RemoteEvent") then stab:FireServer(p)
                                elseif stab:IsA("RemoteFunction") then stab:InvokeServer(p) end
                            end)
                        end
                        task.wait(0.1)
                    end
                end
            end
            lhrp.CFrame = orig
        end
    end
end

-- ── FX ─────────────────────────────────────────────────────────────────────
Features.FX = { enabled = false, conn = nil }
function Features.FX:Toggle(state)
    self.enabled = state
    if state then
        self.conn = RunService.Heartbeat:Connect(function()
            local char = getChar(LocalPlayer)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and math.random() < 0.3 then
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
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
    end
end

-- ── AlarmBar ──────────────────────────────────────────────────────────────
Features.AlarmBar = { enabled = false, bar = nil, conn = nil }
function Features.AlarmBar:Toggle(state)
    self.enabled = state
    if state then
        if self.bar then self.bar:Destroy() end
        local gui = WindowObj.Gui
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 300, 0, 30)
        bar.Position = UDim2.new(0.5, -150, 0, 50)
        bar.BackgroundColor3 = Theme.Danger
        bar.BorderSizePixel = 0
        bar.ZIndex = 40
        bar.Visible = false
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
        self.conn = RunService.Heartbeat:Connect(function()
            local char = getChar(LocalPlayer)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then bar.Visible = false return end
            local near = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and getRole(p) == "Murderer" and isAlive(p) then
                    local ph = getHRP(p)
                    if ph then
                        local d = (ph.Position - hrp.Position).Magnitude
                        if d < 50 then
                            near = true
                            lbl.Text = "⚠ MURDERER " .. math.floor(d) .. " STUDS"
                            break
                        end
                    end
                end
            end
            bar.Visible = near
        end)
    else
        if self.conn then self.conn:Disconnect() self.conn = nil end
        if self.bar then self.bar:Destroy() self.bar = nil end
    end
end

-- ── PlayersList ────────────────────────────────────────────────────────────
Features.PlayersList = { enabled = false, frame = nil, conn = nil }
function Features.PlayersList:Toggle(state)
    self.enabled = state
    if state then
        if self.frame then self.frame:Destroy() end
        local gui = WindowObj.Gui
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
        scroll.ZIndex = 36
        scroll.Parent = panel
        local sl = Instance.new("UIListLayout")
        sl.FillDirection = Enum.FillDirection.Vertical
        sl.Padding = UDim.new(0, 4)
        sl.SortOrder = Enum.SortOrder.LayoutOrder
        sl.Parent = scroll
        self.frame = panel
        self.scroll = scroll
        local function refresh()
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            for _, p in ipairs(Players:GetPlayers()) do
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
                local role = getRole(p)
                dot.BackgroundColor3 = role == "Murderer" and Color3.fromRGB(255, 60, 60)
                    or role == "Sheriff" and Color3.fromRGB(60, 120, 255)
                    or Color3.fromRGB(80, 210, 120)
                local name = Instance.new("TextLabel")
                name.Size = UDim2.new(1, -40, 0, 14)
                name.Position = UDim2.new(0, 20, 0.5, -7)
                name.BackgroundTransparency = 1
                name.Text = p.DisplayName
                name.Font = Enum.Font.Gotham
                name.TextSize = 11
                name.TextColor3 = Theme.Text
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.ZIndex = 38
                name.Parent = entry
            end
            Utility:UpdateCanvas(scroll)
        end
        refresh()
        self.conn = task.spawn(function()
            while self.enabled do refresh() task.wait(1) end
        end)
    else
        if self.conn then task.cancel(self.conn) self.conn = nil end
        if self.frame then self.frame:Destroy() self.frame = nil end
    end
end

-- ── AntiProt ───────────────────────────────────────────────────────────────
Features.AntiProt = { enabled = false, conn = nil }
function Features.AntiProt:Toggle(state)
    self.enabled = state
    if state then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            local oldIdx = mt.__index
            mt.__index = newcclosure(function(self, key)
                if key == "Kick" or key == "kick" then return function() end end
                return oldIdx(self, key)
            end)
            setreadonly(mt, true)
        end)
        pcall(function()
            local gui = CoreGui:FindFirstChild("ENI_MM2_Suite")
            if gui then gui.Name = "CameraModule_" .. math.random(1000, 9999) end
        end)
        self.conn = RunService.Heartbeat:Connect(function()
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

-- ── Profiles ───────────────────────────────────────────────────────────────
Features.Profiles = { current = "default" }
function Features.Profiles:Save(name)
    local profile = {
        SpeedHack = { enabled = Features.SpeedHack.enabled, speed = Features.SpeedHack.speed },
        NoClip = { enabled = Features.NoClip.enabled },
        Fly = { enabled = Features.Fly.enabled, speed = Features.Fly.speed },
        ESP = { enabled = Features.ESP.enabled },
        Chams = { enabled = Features.Chams.enabled },
        FullBright = { enabled = Features.FullBright.enabled },
    }
    self.current = name
    pcall(function() writefile("ENI_MM2_" .. name .. ".json", HttpService:JSONEncode(profile)) end)
end
function Features.Profiles:Load(name)
    pcall(function()
        local content = readfile("ENI_MM2_" .. name .. ".json")
        if content then
            local profile = HttpService:JSONDecode(content)
            if profile.SpeedHack then
                Features.SpeedHack.speed = profile.SpeedHack.speed or 32
                if profile.SpeedHack.enabled then Features.SpeedHack:Toggle(true) end
            end
            self.current = name
        end
    end)
end

-- ── Crosshair ──────────────────────────────────────────────────────────────
Features.Crosshair = { enabled = false, frame = nil, color = Color3.fromRGB(130, 95, 255) }
function Features.Crosshair:Toggle(state)
    self.enabled = state
    if state then
        if self.frame then self.frame:Destroy() end
        local gui = WindowObj.Gui
        local c = Instance.new("Frame")
        c.Name = "ENI_Crosshair"
        c.AnchorPoint = Vector2.new(0.5, 0.5)
        c.Size = UDim2.new(0, 40, 0, 40)
        c.Position = UDim2.fromScale(0.5, 0.5)
        c.BackgroundTransparency = 1
        c.ZIndex = 100
        c.Parent = gui
        local function line(sx, sy, px, py)
            local l = Instance.new("Frame")
            l.Size = UDim2.new(0, sx, 0, sy)
            l.Position = UDim2.new(0, px, 0, py)
            l.BackgroundColor3 = self.color
            l.BorderSizePixel = 0
            l.ZIndex = 31
            l.Parent = c
        end
        line(1, 6, 19, 12)
        line(1, 6, 19, 22)
        line(6, 1, 12, 19)
        line(6, 1, 22, 19)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 2, 0, 2)
        dot.Position = UDim2.new(0, 19, 0, 19)
        dot.BackgroundColor3 = self.color
        dot.BorderSizePixel = 0
        dot.ZIndex = 31
        dot.Parent = c
        self.frame = c
    else
        if self.frame then self.frame:Destroy() self.frame = nil end
    end
end

-- ── VisualWorld ───────────────────────────────────────────────────────────
Features.VisualWorld = { enabled = false, orig = {} }
function Features.VisualWorld:Toggle(state)
    self.enabled = state
    if state then
        self.orig.FogEnd = Lighting.FogEnd
        self.orig.FogStart = Lighting.FogStart
        self.orig.Brightness = Lighting.Brightness
        self.orig.ClockTime = Lighting.ClockTime
        Lighting.FogEnd = 1e9
        Lighting.FogStart = 1e9
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = 0 end
    else
        if self.orig.FogEnd then Lighting.FogEnd = self.orig.FogEnd end
        if self.orig.FogStart then Lighting.FogStart = self.orig.FogStart end
        if self.orig.Brightness then Lighting.Brightness = self.orig.Brightness end
        if self.orig.ClockTime then Lighting.ClockTime = self.orig.ClockTime end
    end
end

-- ── GetAllEmotes ──────────────────────────────────────────────────────────
Features.GetAllEmotes = {}
function Features.GetAllEmotes:Execute()
    local emoteRemote = ReplicatedStorage:FindFirstChild("PlayEmote")
    or ReplicatedStorage:FindFirstChild("EmoteEvent")
    or ReplicatedStorage:FindFirstChild("BuyEmote")
    if emoteRemote then
        for i = 1, 50 do
            pcall(function()
                if emoteRemote:IsA("RemoteEvent") then emoteRemote:FireServer(i)
                elseif emoteRemote:IsA("RemoteFunction") then emoteRemote:InvokeServer(i) end
            end)
        end
    end
    local emotesFolder = ReplicatedStorage:FindFirstChild("Emotes") or ReplicatedStorage:FindFirstChild("Animations")
    local char = getChar(LocalPlayer)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if emotesFolder and hum then
        for _, e in ipairs(emotesFolder:GetDescendants()) do
            if e:IsA("Animation") then
                pcall(function()
                    local track = hum:FindFirstChildOfClass("Animator") and hum:FindFirstChildOfClass("Animator"):LoadAnimation(e)
                    or Instance.new("Animator"):LoadAnimation(e)
                    if track then track:Play() task.wait(2) track:Stop() end
                end)
            end
        end
    end
end

-- ── ShootMurderBtn ────────────────────────────────────────────────────────
Features.ShootMurderBtn = { enabled = false, btn = nil }
function Features.ShootMurderBtn:Toggle(state)
    self.enabled = state
    if state then
        if self.btn then self.btn:Destroy() end
        local gui = WindowObj.Gui
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 40)
        btn.Position = UDim2.new(0.5, -60, 0.7, 0)
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
        Utility:Tween(btn, { Size = UDim2.new(0, 120, 0, 40) }, TI_Bounce)
        btn.MouseButton1Click:Connect(function()
            local murder, md = nil, math.huge
            local lhrp = getHRP(LocalPlayer)

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isAlive(p) and getRole(p) == "Murderer" then
                    local ph = getHRP(p)
                    if ph and lhrp then
                        local d = (ph.Position - lhrp.Position).Magnitude
                        if d < md then
                            md = d
                            murder = p
                        end
                    end
                end
            end

            if not murder then
                return
            end

            local tool = findGun(LocalPlayer)
            local targetChar = getChar(murder)
            local head = targetChar and targetChar:FindFirstChild("Head")
            if tool and head then
                local lhrp2 = getHRP(LocalPlayer)
                if lhrp2 then
                    lhrp2.CFrame = CFrame.new(lhrp2.Position, head.Position)
                end
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                fireGun(tool, head.Position)
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
    Subtitle = "Premium Suite v2.2",
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
    Min = 30, Max = 500, Default = 150, Suffix = "°",
    Callback = function(val) Features.AimBot.fov = val end,
})

CombatTab:CreateSlider({
    Text = "Smoothness",
    Min = 0.05, Max = 1, Default = 0.3, Decimal = true,
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
    Min = 0.1, Max = 3, Default = 0.5, Decimal = true, Suffix = "s",
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
    Min = 1, Max = 50, Default = 10, Suffix = " spd",
    Callback = function(val) Features.SpinBot.speed = val end,
})

CombatTab:CreateToggle({
    Text = "FakeLag",
    Default = false,
    Callback = function(state) Features.FakeLag:Toggle(state) end,
})

CombatTab:CreateSlider({
    Text = "FakeLag Intensity",
    Min = 0.1, Max = 1, Default = 0.5, Decimal = true,
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

-- ── Player Tab ─────────────────────────────────────────────────────────────
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
    Min = 16, Max = 200, Default = 32, Suffix = " spd",
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
    Min = 10, Max = 300, Default = 50, Suffix = " spd",
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
    Callback = function(text) Features.Profiles.current = text end,
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

SettingsTab:CreateLabel("ENI MM2 Suite v2.1", 11)
SettingsTab:CreateLabel("Built by ENI for LO", 10)
SettingsTab:CreateLabel("Delta X Compatible", 10)

SettingsTab:CreateButton({
    Text = "Unload Script",
    Callback = function()
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

-- ★ FIX: Force update all canvases after building
task.spawn(function()
    task.wait(0.1)
    for _, tab in ipairs(Window.Tabs) do
        Utility:UpdateCanvas(tab.PageScroll)
    end
    Utility:UpdateCanvas(Window.SidebarScroll)
end)

-- ★ Final layout refresh: let Roblox calculate all UIListLayouts first.
task.defer(function()
    RunService.Heartbeat:Wait()
    for _, tab in ipairs(Window.Tabs) do
        Utility:UpdateCanvas(tab.PageScroll)
    end
    Utility:UpdateCanvas(Window.SidebarScroll)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════

Library:Notify({
    Title = "ENI MM2 Suite",
    Description = "v2.1 Loaded. All tabs functional.",
    Color = Theme.Accent,
    Duration = 4,
})

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if Window.Frame.Visible then
            Utility:Tween(Window.Frame, { Size = UDim2.new(0, 520, 0, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
            task.wait(0.35)
            Window.Frame.Visible = false
            Library:ShowMinimized(Window.Gui, Window.Frame)
        else
            local min = Window.Gui:FindFirstChild("Minimized")
            if min then
                Utility:Tween(min, { Size = UDim2.new(0, 0, 0, 0) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
                task.wait(0.25)
                min:Destroy()
            end
            Window.Frame.Visible = true
            Utility:Tween(Window.Frame, { Size = UDim2.new(0, 520, 0, 350) }, TI_Bounce)
        end
    end
end)

print("[ENI MM2] v2.3 loaded — GUI, crosshair, role detection and weapon hooks updated.")
