-- ╔══════════════════════════════════════════════════════════════╗
-- ║  MM2 SUITE v2.2  |  Delta  |  by ENI for LO                   ║
-- ║  fix: клик по кнопке + прямоугольный nameless                ║
-- ╚══════════════════════════════════════════════════════════════╝

local function boot()
    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local UIS               = game:GetService("UserInputService")
    local TweenService      = game:GetService("TweenService")
    local Lighting          = game:GetService("Lighting")
    local Workspace         = game:GetService("Workspace")
    local Debris            = game:GetService("Debris")

    local LP = Players.LocalPlayer
    local CAM = Workspace.CurrentCamera

    local parentGui
    if gethui then pcall(function() parentGui = gethui() end) end
    if not parentGui then pcall(function() parentGui = game:GetService("CoreGui") end) end
    if not parentGui then parentGui = LP:WaitForChild("PlayerGui") end

    for _, name in ipairs({"MM2_Suite", "MM2_Orb"}) do
        local old = parentGui:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local S = {
        speedEnabled = false, speedValue = 60,
        noclip = false,
        fly = false, flySpeed = 80,
        playerESP = false, roleESP = false, itemESP = false,
        chams = false, fullbright = false,
        aimbot = false, silentAim = false, autoShoot = false,
        aimKey = Enum.UserInputType.MouseButton2,
        autoCoins = false, autoPickup = false, godMode = false,
        coinVacuum = false, autoEquipGun = false, autoDodge = false,
        muteAll = false,
        roleDetector = false, playerList = false,
        pingDisplay = false, roundTimer = false,
        flingMurder = false, flingSheriff = false,
        flingMode = "ForcePush",
        antiFling = true, voidCatch = true,
        antiSpin = true, weldDetect = true,
        antiAFK = true, antiRagdoll = true,
        worldTime = false, worldTimeVal = 14,
        worldBrightness = false, worldBrightVal = 2,
        worldFog = false, worldFogColor = Color3.fromRGB(120,120,150),
        worldAmbient = false, worldAmbientColor = Color3.fromRGB(180,180,200),
        worldBlur = false, worldBloom = false,
        worldColorCorrection = false, worldCCColor = Color3.fromRGB(255,240,220),
        worldDepthOfField = false,
        worldSunRays = false,
        cosHat = "None", cosWings = false, cosAura = "None",
        cosTrail = false, cosOrbit = false,
    }

    local flyBV, flyBG
    local espCache = {}
    local lastValidPos = nil
    local cosParts = {}
    local fpsTick, fpsCount = tick(), 0
    local fpsValue = 0

    local Root = Instance.new("ScreenGui")
    Root.Name = "MM2_Suite"
    Root.ResetOnSpawn = false
    Root.IgnoreGuiInset = true
    Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Root.DisplayOrder = 999
    Root.Parent = parentGui

    -- ═══════════════════════════════════════════════════════════
    --  ПРЯМОУГОЛЬНАЯ КНОПКА "nameless"
    -- ═══════════════════════════════════════════════════════════
    local Btn = Instance.new("TextButton")
    Btn.Name = "MM2_Orb"
    Btn.Size = UDim2.new(0, 128, 0, 38)
    Btn.Position = UDim2.new(0, 60, 0, 260)
    Btn.BackgroundColor3 = Color3.fromRGB(22, 18, 30)
    Btn.BorderSizePixel = 0
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.Active = true
    Btn.Parent = Root

    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1.6
    BtnStroke.Color = Color3.fromRGB(180, 120, 255)
    BtnStroke.Transparency = 0.15
    BtnStroke.Parent = Btn

    local BtnGrad = Instance.new("UIGradient")
    BtnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 90, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 180)),
    })
    BtnGrad.Rotation = 45
    BtnGrad.Parent = BtnStroke

    -- акцентная полоска слева
    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(0, 3, 0, 22)
    Accent.Position = UDim2.new(0, 10, 0.5, -11)
    Accent.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
    Accent.BorderSizePixel = 0
    Accent.Parent = Btn
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(1, 0)

    -- текст "nameless"
    local BtnLabel = Instance.new("TextLabel")
    BtnLabel.Size = UDim2.new(1, -40, 1, 0)
    BtnLabel.Position = UDim2.new(0, 22, 0, 0)
    BtnLabel.BackgroundTransparency = 1
    BtnLabel.Text = "nameless"
    BtnLabel.TextColor3 = Color3.fromRGB(240, 230, 255)
    BtnLabel.Font = Enum.Font.GothamBold
    BtnLabel.TextSize = 15
    BtnLabel.TextXAlignment = Enum.TextXAlignment.Left
    BtnLabel.Active = false
    BtnLabel.Parent = Btn

    -- пульсирующая точка справа (живой индикатор)
    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 6, 0, 6)
    Dot.Position = UDim2.new(1, -16, 0.5, -3)
    Dot.BackgroundColor3 = Color3.fromRGB(140, 220, 160)
    Dot.BorderSizePixel = 0
    Dot.Active = false
    Dot.Parent = Btn
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    TweenService:Create(Dot, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundTransparency = 0.75,
    }):Play()

    -- пульсация обводки
    TweenService:Create(BtnStroke, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Transparency = 0.55,
    }):Play()
    -- медленное вращение градиента
    TweenService:Create(BtnGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {
        Rotation = 405,
    }):Play()

    -- hover-эффект
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(34, 28, 46),
        }):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(22, 18, 30),
        }):Play()
    end)

    -- ═══════════════════════════════════════════════════════════
    --  ОКНО
    -- ═══════════════════════════════════════════════════════════
    local Win = Instance.new("Frame")
    Win.Name = "Win"
    Win.Size = UDim2.new(0, 420, 0, 340)
    Win.Position = UDim2.new(0.5, -210, 0.5, -170)
    Win.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
    Win.BorderSizePixel = 0
    Win.ClipsDescendants = true
    Win.Visible = false
    Win.Active = true
    Win.Parent = Root

    Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 12)

    local winStroke = Instance.new("UIStroke")
    winStroke.Thickness = 1.5
    winStroke.Color = Color3.fromRGB(120, 90, 200)
    winStroke.Transparency = 0.35
    winStroke.Parent = Win

    local Head = Instance.new("Frame")
    Head.Name = "Head"
    Head.Size = UDim2.new(1, 0, 0, 38)
    Head.BackgroundTransparency = 1
    Head.Parent = Win

    local HeadAccent = Instance.new("Frame")
    HeadAccent.Size = UDim2.new(1, 0, 0, 2)
    HeadAccent.Position = UDim2.new(0, 0, 1, -2)
    HeadAccent.BackgroundColor3 = Color3.fromRGB(160, 90, 255)
    HeadAccent.BorderSizePixel = 0
    HeadAccent.Parent = Head

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -110, 1, 0)
    Title.Position = UDim2.new(0, 14, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "nameless · MM2"
    Title.TextColor3 = Color3.fromRGB(235, 225, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Head

    local FPSLbl = Instance.new("TextLabel")
    FPSLbl.Size = UDim2.new(0, 60, 1, 0)
    FPSLbl.Position = UDim2.new(1, -100, 0, 0)
    FPSLbl.BackgroundTransparency = 1
    FPSLbl.Text = "60 fps"
    FPSLbl.TextColor3 = Color3.fromRGB(140, 220, 160)
    FPSLbl.Font = Enum.Font.Gotham
    FPSLbl.TextSize = 11
    FPSLbl.TextXAlignment = Enum.TextXAlignment.Right
    FPSLbl.Parent = Head

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -34, 0, 6)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 24, 32)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 190, 190)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Head
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, -16, 0, 28)
    TabBar.Position = UDim2.new(0, 8, 0, 42)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Win

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.Parent = TabBar

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = "Scroll"
    Scroll.Size = UDim2.new(1, -16, 1, -86)
    Scroll.Position = UDim2.new(0, 8, 0, 76)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(140, 90, 220)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.Parent = Win

    local PageContainer = Instance.new("Frame")
    PageContainer.Name = "Pages"
    PageContainer.Size = UDim2.new(1, -6, 0, 0)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = Scroll

    local Stack = Instance.new("UIListLayout")
    Stack.Padding = UDim.new(0, 6)
    Stack.SortOrder = Enum.SortOrder.LayoutOrder
    Stack.Parent = PageContainer

    Stack:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        PageContainer.Size = UDim2.new(1, -6, 0, Stack.AbsoluteContentSize.Y)
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Stack.AbsoluteContentSize.Y + 10)
    end)

    local Resize = Instance.new("TextButton")
    Resize.Size = UDim2.new(0, 16, 0, 16)
    Resize.Position = UDim2.new(1, -18, 1, -18)
    Resize.BackgroundColor3 = Color3.fromRGB(160, 90, 255)
    Resize.BackgroundTransparency = 0.4
    Resize.Text = ""
    Resize.BorderSizePixel = 0
    Resize.Parent = Win
    Instance.new("UICorner", Resize).CornerRadius = UDim.new(0, 4)

    -- ── BUILDERS ────────────────────────────────────────────────
    local function tSection(page, text)
        local sec = Instance.new("TextLabel")
        sec.Size = UDim2.new(1, 0, 0, 20)
        sec.BackgroundTransparency = 1
        sec.Text = "  " .. text:upper()
        sec.TextColor3 = Color3.fromRGB(180, 130, 255)
        sec.Font = Enum.Font.GothamBold
        sec.TextSize = 11
        sec.TextXAlignment = Enum.TextXAlignment.Left
        sec.Parent = page
        return sec
    end

    local function tToggle(page, label, key, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
        row.BorderSizePixel = 0
        row.Parent = page
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 34, 0, 16)
        ind.Position = UDim2.new(1, -44, 0.5, -8)
        ind.BackgroundColor3 = Color3.fromRGB(50, 44, 62)
        ind.BorderSizePixel = 0
        ind.Parent = row
        Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(200, 195, 215)
        knob.BorderSizePixel = 0
        knob.Parent = ind
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = row

        local state = S[key]
        local function render()
            TweenService:Create(ind, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Color3.fromRGB(120, 80, 200) or Color3.fromRGB(50, 44, 62)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18), {
                Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
                BackgroundColor3 = state and Color3.fromRGB(240, 230, 255) or Color3.fromRGB(200, 195, 215)
            }):Play()
        end
        render()
        btn.MouseButton1Click:Connect(function()
            state = not state
            S[key] = state
            render()
            if cb then cb(state) end
        end)
        return row
    end

    local function tSlider(page, label, key, min, max, step, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 46)
        row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
        row.BorderSizePixel = 0
        row.Parent = page
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = label .. ": " .. tostring(S[key])
        lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 8)
        track.Position = UDim2.new(0, 10, 0, 30)
        track.BackgroundColor3 = Color3.fromRGB(48, 42, 60)
        track.BorderSizePixel = 0
        track.Parent = row
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((S[key]-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(160, 90, 255)
        fill.BorderSizePixel = 0
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor((min + (max-min)*rel) / step + 0.5) * step
            S[key] = val
            lbl.Text = label .. ": " .. tostring(val)
            fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
            if cb then cb(val) end
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFromX(i.Position.X) end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        return row
    end

    local function tDropdown(page, label, key, options, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 56)
        row.BackgroundColor3 = Color3.fromRGB(30, 26, 42)
        row.BorderSizePixel = 0
        row.ClipsDescendants = true
        row.Parent = page
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(220, 215, 235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local box = Instance.new("TextButton")
        box.Size = UDim2.new(1, -20, 0, 24)
        box.Position = UDim2.new(0, 10, 0, 26)
        box.BackgroundColor3 = Color3.fromRGB(46, 40, 60)
        box.Text = "  " .. tostring(S[key]) .. "  v"
        box.TextColor3 = Color3.fromRGB(235, 225, 255)
        box.Font = Enum.Font.Gotham
        box.TextSize = 12
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.BorderSizePixel = 0
        box.Parent = row
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, -20, 0, 0)
        list.Position = UDim2.new(0, 10, 0, 54)
        list.BackgroundColor3 = Color3.fromRGB(36, 30, 48)
        list.BorderSizePixel = 0
        list.Visible = false
        list.Parent = row
        Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
        local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 2); ll.Parent = list

        local open = false
        for _, opt in ipairs(options) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 22)
            b.BackgroundColor3 = Color3.fromRGB(36, 30, 48)
            b.Text = "  " .. opt
            b.TextColor3 = Color3.fromRGB(220, 215, 235)
            b.Font = Enum.Font.Gotham
            b.TextSize = 12
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.BorderSizePixel = 0
            b.Parent = list
            b.MouseButton1Click:Connect(function()
                S[key] = opt
                box.Text = "  " .. opt .. "  v"
                if cb then cb(opt) end
                open = false
                TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 0)}):Play()
                task.delay(0.2, function() list.Visible = false end)
                TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 56)}):Play()
            end)
        end
        local h = #options * 24 + 4
        list.Size = UDim2.new(1, -20, 0, h)

        box.MouseButton1Click:Connect(function()
            open = not open
            if open then
                list.Visible = true
                local hh = #options * 24 + 4
                TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, hh)}):Play()
                TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 56 + hh + 4)}):Play()
            else
                TweenService:Create(list, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 0)}):Play()
                TweenService:Create(row, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 56)}):Play()
                task.delay(0.2, function() list.Visible = false end)
            end
        end)
        return row
    end

    -- ── ТАБЫ ────────────────────────────────────────────────────
    local TABS = {}
    local TabButtons = {}
    local TAB_ORDER = {"Движ","Визуал","Мир","Бой","Фарм","Инфо","Флинг","Косметика"}

    local function registerTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 70, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(34, 28, 46)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(220, 210, 240)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.Parent = TabBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = PageContainer

        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 6)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Parent = page

        TABS[name] = page
        TabButtons[name] = btn

        btn.MouseButton1Click:Connect(function()
            for n, pg in pairs(TABS) do pg.Visible = (n == name) end
            for n, b in pairs(TabButtons) do
                TweenService:Create(b, TweenInfo.new(0.15), {
                    BackgroundColor3 = (n == name) and Color3.fromRGB(90, 60, 160) or Color3.fromRGB(34, 28, 46)
                }):Play()
            end
        end)
        return page
    end

    for _, n in ipairs(TAB_ORDER) do registerTab(n) end

    -- ── ЗАПОЛНЕНИЕ ──────────────────────────────────────────────
    do
        local p = TABS["Движ"]
        tSection(p, "Движение")
        tToggle(p, "SpeedHack", "speedEnabled")
        tSlider(p, "Speed", "speedValue", 16, 250, 2)
        tToggle(p, "NoClip", "noclip")
        tToggle(p, "Fly", "fly")
        tSlider(p, "Fly Speed", "flySpeed", 20, 300, 5)
    end
    do
        local p = TABS["Визуал"]
        tSection(p, "Игроки")
        tToggle(p, "Player ESP", "playerESP")
        tToggle(p, "Role ESP", "roleESP")
        tToggle(p, "Chams", "chams")
        tSection(p, "Объекты")
        tToggle(p, "Item ESP", "itemESP")
        tToggle(p, "FullBright", "fullbright")
    end
    do
        local p = TABS["Мир"]
        tSection(p, "Время и свет")
        tToggle(p, "Set Time", "worldTime")
        tSlider(p, "Hour", "worldTimeVal", 0, 24, 1)
        tToggle(p, "Brightness", "worldBrightness")
        tSlider(p, "Level", "worldBrightVal", 0, 5, 1)
        tSection(p, "Атмосфера")
        tToggle(p, "Fog", "worldFog")
        tToggle(p, "Ambient", "worldAmbient")
        tSection(p, "Шейдеры")
        tToggle(p, "Blur", "worldBlur")
        tToggle(p, "Bloom", "worldBloom")
        tToggle(p, "ColorCorrection", "worldColorCorrection")
        tToggle(p, "Depth of Field", "worldDepthOfField")
        tToggle(p, "Sun Rays", "worldSunRays")
    end
    do
        local p = TABS["Бой"]
        tSection(p, "Прицел")
        tToggle(p, "AimBot (ПКМ)", "aimbot")
        tToggle(p, "SilentAim", "silentAim")
        tToggle(p, "AutoShoot", "autoShoot")
        tSection(p, "Выживание")
        tToggle(p, "GodMode (клиент)", "godMode")
        tToggle(p, "Auto-Dodge убийцы", "autoDodge")
        tToggle(p, "Auto-Equip Gun", "autoEquipGun")
    end
    do
        local p = TABS["Фарм"]
        tSection(p, "Сбор")
        tToggle(p, "Auto Collect Coins", "autoCoins")
        tToggle(p, "Coin Vacuum", "coinVacuum")
        tToggle(p, "Auto Pickup Weapon", "autoPickup")
        tSection(p, "Прочее")
        tToggle(p, "Mute All", "muteAll")
    end
    do
        local p = TABS["Инфо"]
        tSection(p, "Отображение")
        tToggle(p, "Role Detector", "roleDetector")
        tToggle(p, "Player List (в чат)", "playerList")
        tToggle(p, "Ping Display", "pingDisplay")
        tToggle(p, "Round Timer", "roundTimer")
    end
    do
        local p = TABS["Флинг"]
        tSection(p, "Цели")
        tToggle(p, "FLING Murderer", "flingMurder")
        tToggle(p, "FLING Sheriff", "flingSheriff")
        tDropdown(p, "Режим", "flingMode", {"ForcePush","Spin","Loop","Silent"})
        tSection(p, "Защита")
        tToggle(p, "Anti-Fling", "antiFling")
        tToggle(p, "Void Catch", "voidCatch")
        tToggle(p, "Anti Spin", "antiSpin")
        tToggle(p, "Weld Detector", "weldDetect")
        tToggle(p, "Anti-Ragdoll", "antiRagdoll")
        tToggle(p, "Anti-AFK", "antiAFK")
    end
    do
        local p = TABS["Косметика"]
        tSection(p, "Шляпы")
        tDropdown(p, "Шляпа", "cosHat", {"None","Tophat","Crown","Halo","Propeller","Bucket"})
        tSection(p, "Крылья и эффекты")
        tToggle(p, "Крылья", "cosWings")
        tDropdown(p, "Аура", "cosAura", {"None","Fire","Ice","Lightning","Galaxy","Gold"})
        tToggle(p, "Трейл", "cosTrail")
        tToggle(p, "Орбита сфер", "cosOrbit")
    end

    TABS["Движ"].Visible = true
    TabButtons["Движ"].BackgroundColor3 = Color3.fromRGB(90, 60, 160)

    -- ═══════════════════════════════════════════════════════════
    --  ОТКРЫТИЕ/ЗАКРЫТИЕ + ДРАГ + КЛИК
    -- ═══════════════════════════════════════════════════════════
    local function openWin()
        Win.Visible = true
        Win.Size = UDim2.new(0, 360, 0, 280)
        TweenService:Create(Win, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 420, 0, 340)
        }):Play()
    end
    local function closeWin()
        TweenService:Create(Win, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 360, 0, 280)
        }):Play()
        task.delay(0.18, function() Win.Visible = false end)
    end

    -- КЛИК: ловим через InputEnded, но проверяем, что мышь почти не двигалась
    -- (это спасает от того, что Draggable иногда глушит MouseButton1Click)
    do
        local pressPos = nil
        Btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                pressPos = i.Position
            end
        end)
        Btn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                if pressPos then
                    local moved = (i.Position - pressPos).Magnitude
                    if moved < 10 then
                        if Win.Visible then closeWin() else openWin() end
                    end
                    pressPos = nil
                end
            end
        end)
    end

    CloseBtn.MouseButton1Click:Connect(closeWin)

    -- Драг кнопки: считаем дельту мыши, двигаем вручную (чтобы не конфликтовать с кликом)
    do
        local dragging, start, startPos = false, nil, nil
        Btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; start = i.Position; startPos = Btn.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - start
                if d.Magnitude > 4 then
                    Btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- Драг окна за хедер
    do
        local dragging, start, startPos = false, nil, nil
        Head.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; start = i.Position; startPos = Win.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - start
                Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    -- Ресайз окна
    do
        local rDrag, rStart, rSize = false, nil, nil
        Resize.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                rDrag = true; rStart = i.Position; rSize = Win.Size
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if rDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - rStart
                Win.Size = UDim2.new(0, math.max(320, rSize.X.Offset + d.X), 0, math.max(240, rSize.Y.Offset + d.Y))
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then rDrag = false end
        end)
    end

    -- ── РОЛИ ────────────────────────────────────────────────────
    local ROLE_COLORS = {
        Murderer = Color3.fromRGB(220, 20, 60),
        Sheriff  = Color3.fromRGB(255, 200, 40),
        Innocent = Color3.fromRGB(80, 200, 120),
        Hero     = Color3.fromRGB(120, 180, 255),
        Unknown  = Color3.fromRGB(180, 180, 180),
    }
    local function getRole(plr)
        for _, t in ipairs(plr:GetChildren()) do
            if t:IsA("StringValue") or t:IsA("ObjectValue") then
                local n = t.Name:lower(); local v = tostring(t.Value):lower()
                if n:find("role") or n:find("team") then
                    if v:find("murder") then return "Murderer" end
                    if v:find("sheriff") then return "Sheriff" end
                    if v:find("hero") then return "Hero" end
                    if v:find("innoc") then return "Innocent" end
                end
            end
        end
        local a = plr:GetAttribute("Role") or plr:GetAttribute("role")
        if a then
            local s = tostring(a):lower()
            if s:find("murder") then return "Murderer" end
            if s:find("sheriff") then return "Sheriff" end
            if s:find("hero") then return "Hero" end
            if s:find("innoc") then return "Innocent" end
        end
        return "Unknown"
    end
    local function getCharParts(plr)
        local c = plr.Character
        if not c then return nil end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return nil end
        return hrp, hum, c
    end

    -- ESP
    local function ensureEsp(plr)
        if plr == LP then return end
        if espCache[plr] then return espCache[plr] end
        local box = Drawing.new("Square")
        box.Thickness = 1; box.Filled = false; box.Transparency = 1; box.Visible = false
        local name = Drawing.new("Text")
        name.Size = 13; name.Center = true; name.Outline = true; name.Visible = false
        local info = Drawing.new("Text")
        info.Size = 12; info.Center = true; info.Outline = true; info.Visible = false
        espCache[plr] = {box=box, name=name, info=info}
        return espCache[plr]
    end
    for _, p in ipairs(Players:GetPlayers()) do ensureEsp(p) end
    Players.PlayerAdded:Connect(ensureEsp)
    Players.PlayerRemoving:Connect(function(p)
        local e = espCache[p]
        if e then for _, d in pairs(e) do d:Remove() end; espCache[p] = nil end
    end)

    local function applyChams(char, color)
        if char:FindFirstChild("__cham") then
            char.__cham.FillColor = color; char.__cham.OutlineColor = color; return
        end
        local hl = Instance.new("Highlight")
        hl.Name = "__cham"; hl.FillColor = color; hl.FillTransparency = 0.55
        hl.OutlineColor = color; hl.Parent = char
    end
    local function clearChams(char)
        local h = char:FindFirstChild("__cham"); if h then h:Destroy() end
    end

    local itemDrawings = {}
    local function clearItemEsp()
        for _, d in pairs(itemDrawings) do
            if typeof(d) == "Instance" and d.Remove then d:Remove() end
        end
        itemDrawings = {}
    end
    local ITEM_NAMES = {"Knife", "Gun", "Coin", "Revolver", "Pistol"}

    -- FLY
    local function startFly()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(9e9,9e9,9e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9); flyBG.P = 1000; flyBG.Parent = hrp
    end
    local function stopFly()
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end

    -- FLING
    local function flingTarget(targetChar, mode)
        if not targetChar then return end
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if mode == "ForcePush" then
            local v = Instance.new("BodyVelocity"); v.MaxForce = Vector3.new(9e9,9e9,9e9)
            v.Velocity = Vector3.new(math.random(-1,1)*400, 300, math.random(-1,1)*400); v.Parent = hrp
            task.delay(0.15, function() v:Destroy() end)
        elseif mode == "Spin" then
            for _ = 1, 4 do
                hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), math.rad(90), 0)
                hrp.Velocity = Vector3.new(0, 500, 0); task.wait(0.03)
            end
        elseif mode == "Loop" then
            for _ = 1, 6 do
                if hrp.Parent then hrp.Velocity = Vector3.new(math.random(-350,350), 250, math.random(-350,350)) end
                task.wait(0.1)
            end
        elseif mode == "Silent" then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = hrp; weld.Part1 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if weld.Part1 then
                weld.Parent = hrp
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.1, 0)
                task.wait(0.05); weld:Destroy()
                hrp.Velocity = Vector3.new(300, 400, 300)
            end
        end
    end

    -- ANTI-FLING
    local savedCFrame = nil
    RunService.Heartbeat:Connect(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if S.voidCatch and hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 20, 0); hrp.Velocity = Vector3.zero end
        if S.antiFling then
            if hrp.Velocity.Magnitude > 300 and (hrp.Position - (lastValidPos or hrp.Position)).Magnitude < 5 then
                hrp.Velocity = Vector3.zero
            end
            lastValidPos = hrp.Position
        end
        if S.antiSpin then
            savedCFrame = savedCFrame or hrp.CFrame
            local _, ry = hrp.CFrame:ToOrientation()
            local delta = math.abs(math.deg(ry) - math.deg(select(2, savedCFrame:ToOrientation())))
            if delta > 60 and delta < 300 then
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, select(2, savedCFrame:ToOrientation()), 0)
            else savedCFrame = hrp.CFrame end
        end
        if S.weldDetect then
            for _, c in ipairs(hrp:GetChildren()) do
                if c:IsA("WeldConstraint") or c:IsA("Weld") then
                    local ok = false
                    for _, p in ipairs(char:GetDescendants()) do
                        if c.Part0 == p or c.Part1 == p then ok = true; break end
                    end
                    if not ok then c:Destroy() end
                end
            end
        end
        if S.antiRagdoll then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)

    -- ANTI-AFK
    task.spawn(function()
        while task.wait(60) do
            if S.antiAFK then
                local vu = LP:FindFirstChild("VirtualUser") or Instance.new("VirtualUser", LP)
                pcall(function() vu:Button1Down(Vector2.zero) end)
            end
        end
    end)

    -- КОСМЕТИКА
    local function clearCosmetics()
        for _, p in pairs(cosParts) do if typeof(p) == "Instance" and p.Parent then p:Destroy() end end
        cosParts = {}
    end
    local function weldPart(part, target, offset)
        part.CFrame = target.CFrame * offset
        part.Anchored = false; part.CanCollide = false; part.Parent = target.Parent
        local w = Instance.new("WeldConstraint"); w.Part0 = part; w.Part1 = target; w.Parent = part
        return w
    end
    local function buildHat(kind, head)
        if kind == "None" then return end
        if kind == "Tophat" then
            local brim = Instance.new("Part"); brim.Name="__cos"; brim.Size=Vector3.new(1.4,0.1,1.4); brim.Color=Color3.fromRGB(20,20,20)
            local top = Instance.new("Part"); top.Name="__cos"; top.Size=Vector3.new(0.9,0.9,0.9); top.Color=Color3.fromRGB(20,20,20)
            weldPart(brim, head, CFrame.new(0,0.55,0)); weldPart(top, brim, CFrame.new(0,0.5,0))
            table.insert(cosParts, brim); table.insert(cosParts, top)
        elseif kind == "Crown" then
            local base = Instance.new("Part"); base.Name="__cos"; base.Size=Vector3.new(1.2,0.35,1.2); base.Color=Color3.fromRGB(255,215,60); base.Material=Enum.Material.Neon
            weldPart(base, head, CFrame.new(0,0.6,0)); table.insert(cosParts, base)
            for i = 1, 5 do
                local spike = Instance.new("Part"); spike.Name="__cos"; spike.Size=Vector3.new(0.15,0.4,0.15); spike.Color=Color3.fromRGB(255,235,120); spike.Material=Enum.Material.Neon
                local ang = (i-1)*(math.pi*2/5)
                weldPart(spike, base, CFrame.new(math.cos(ang)*0.5, 0.3, math.sin(ang)*0.5)); table.insert(cosParts, spike)
            end
        elseif kind == "Halo" then
            local halo = Instance.new("Part"); halo.Name="__cos"; halo.Shape=Enum.PartType.Cylinder; halo.Size=Vector3.new(0.15,1.4,1.4); halo.Color=Color3.fromRGB(255,240,160); halo.Material=Enum.Material.Neon
            weldPart(halo, head, CFrame.new(0,1.2,0)); table.insert(cosParts, halo)
        elseif kind == "Propeller" then
            local cap = Instance.new("Part"); cap.Name="__cos"; cap.Size=Vector3.new(0.9,0.3,0.9); cap.Color=Color3.fromRGB(30,120,220)
            weldPart(cap, head, CFrame.new(0,0.55,0)); table.insert(cosParts, cap)
            local blade = Instance.new("Part"); blade.Name="__cos"; blade.Size=Vector3.new(1.4,0.1,0.2); blade.Color=Color3.fromRGB(220,60,60)
            weldPart(blade, cap, CFrame.new(0,0.25,0)); table.insert(cosParts, blade)
            RunService.Heartbeat:Connect(function()
                if blade and blade.Parent then blade.CFrame = blade.CFrame * CFrame.Angles(0, math.rad(18), 0) end
            end)
        elseif kind == "Bucket" then
            local bucket = Instance.new("Part"); bucket.Name="__cos"; bucket.Shape=Enum.PartType.Cylinder; bucket.Size=Vector3.new(0.9,1.0,1.0); bucket.Color=Color3.fromRGB(140,140,150); bucket.Material=Enum.Material.Metal
            weldPart(bucket, head, CFrame.new(0,1.0,0) * CFrame.Angles(0,0,math.rad(90))); table.insert(cosParts, bucket)
        end
    end
    local function buildWings(back)
        local function wp(off, rot)
            local p = Instance.new("Part"); p.Name="__cos"; p.Size=Vector3.new(1.4,0.1,0.6); p.Color=Color3.fromRGB(240,240,255); p.Material=Enum.Material.Neon; p.Transparency=0.15
            weldPart(p, back, off * rot); table.insert(cosParts, p)
        end
        wp(CFrame.new(-0.9,0.2,0.3), CFrame.Angles(0,0,math.rad(25)))
        wp(CFrame.new( 0.9,0.2,0.3), CFrame.Angles(0,0,math.rad(-25)))
        wp(CFrame.new(-1.6,-0.2,0.5), CFrame.Angles(0,0,math.rad(45)))
        wp(CFrame.new( 1.6,-0.2,0.5), CFrame.Angles(0,0,math.rad(-45)))
    end
    local AURA = {Fire=Color3.fromRGB(255,110,40),Ice=Color3.fromRGB(120,200,255),Lightning=Color3.fromRGB(255,240,120),Galaxy=Color3.fromRGB(180,100,255),Gold=Color3.fromRGB(255,210,80)}
    local function applyAura(kind, hrp)
        if kind == "None" or not AURA[kind] then return end
        local att = Instance.new("Attachment", hrp); att.Name="__cos"
        local em = Instance.new("ParticleEmitter")
        em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        em.Rate = 18; em.Lifetime = NumberRange.new(1.2, 2.0); em.Speed = NumberRange.new(4, 10)
        em.SpreadAngle = Vector2.new(180, 180)
        em.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.5,0.6),NumberSequenceKeypoint.new(1,0)})
        em.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)})
        em.Color = ColorSequence.new(AURA[kind]); em.Parent = att
        table.insert(cosParts, att)
    end
    local function applyTrail(hrp)
        local a0 = Instance.new("Attachment", hrp); a0.Name="__cos"; a0.Position=Vector3.new(-0.5,0,0)
        local a1 = Instance.new("Attachment", hrp); a1.Name="__cos"; a1.Position=Vector3.new(0.5,0,0)
        local tr = Instance.new("Trail"); tr.Attachment0=a0; tr.Attachment1=a1; tr.Lifetime=1.2
        tr.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(180,90,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,90,180))})
        tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)})
        tr.Parent = hrp
        table.insert(cosParts, a0); table.insert(cosParts, a1); table.insert(cosParts, tr)
    end
    local function applyOrbit(hrp)
        for i = 1, 6 do
            local s = Instance.new("Part"); s.Name="__cos_orbit"; s.Shape=Enum.PartType.Ball
            s.Size=Vector3.new(0.25,0.25,0.25); s.Color=Color3.fromRGB(255,200,120); s.Material=Enum.Material.Neon
            s.CanCollide=false; s.Anchored=true; s.Parent=Workspace
            table.insert(cosParts, s)
        end
        local t = 0
        RunService.Heartbeat:Connect(function(dt)
            t += dt
            local n = 0
            for _, p in ipairs(cosParts) do
                if p.Name == "__cos_orbit" and p.Parent then
                    n += 1
                    local ang = t*2 + (n-1)*(math.pi*2/6)
                    p.CFrame = hrp.CFrame * CFrame.new(math.cos(ang)*2.2, math.sin(t*3)*0.4, math.sin(ang)*2.2)
                end
            end
        end)
    end
    local function rebuildCosmetics()
        clearCosmetics()
        local char = LP.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        local back = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if head then buildHat(S.cosHat, head) end
        if back and S.cosWings then buildWings(back) end
        if hrp then
            if S.cosAura ~= "None" then applyAura(S.cosAura, hrp) end
            if S.cosTrail then applyTrail(hrp) end
            if S.cosOrbit then applyOrbit(hrp) end
        end
    end
    local lastCosKey = ""
    task.spawn(function()
        while task.wait(0.5) do
            local key = tostring(S.cosHat)..tostring(S.cosWings)..tostring(S.cosAura)..tostring(S.cosTrail)..tostring(S.cosOrbit)..tostring(LP.Character)
            if key ~= lastCosKey then lastCosKey = key; rebuildCosmetics() end
        end
    end)

    -- МИР
    local function ensureFx(name, class)
        local e = Lighting:FindFirstChild(name)
        if not e then e = Instance.new(class); e.Name = name; e.Parent = Lighting end
        return e
    end
    local Blur    = ensureFx("__mm2_blur", "BlurEffect"); Blur.Size = 6
    local Bloom   = ensureFx("__mm2_bloom", "BloomEffect"); Bloom.Intensity=1.2; Bloom.Size=20; Bloom.Threshold=1.4
    local CC      = ensureFx("__mm2_cc", "ColorCorrectionEffect"); CC.Brightness=0.05; CC.Contrast=0.1; CC.Saturation=0.15
    local DoF     = ensureFx("__mm2_dof", "DepthOfFieldEffect"); DoF.FarIntensity=0.15; DoF.FocusDistance=30; DoF.InFocusRadius=20
    local SunRays = ensureFx("__mm2_sun", "SunRaysEffect"); SunRays.Intensity=0.15; SunRays.Spread=1

    local function updateWorld()
        if S.worldTime then Lighting.TimeOfDay = string.format("%02d:00:00", S.worldTimeVal) end
        Lighting.Brightness = S.worldBrightness and S.worldBrightVal or 2
        Lighting.FogEnd = S.worldFog and 80 or 1e6
        Lighting.FogColor = S.worldFog and S.worldFogColor or Color3.fromRGB(200,200,200)
        Lighting.Ambient = S.worldAmbient and S.worldAmbientColor or Color3.fromRGB(70,70,70)
        Blur.Enabled = S.worldBlur
        Bloom.Enabled = S.worldBloom
        CC.Enabled = S.worldColorCorrection
        DoF.Enabled = S.worldDepthOfField
        SunRays.Enabled = S.worldSunRays
    end

    -- MAIN LOOP
    task.spawn(function()
        while task.wait() do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            fpsCount += 1
            if tick() - fpsTick >= 1 then
                fpsValue = fpsCount; fpsCount = 0; fpsTick = tick()
                FPSLbl.Text = tostring(fpsValue) .. " fps"
                FPSLbl.TextColor3 = fpsValue >= 50 and Color3.fromRGB(140,220,160)
                    or fpsValue >= 30 and Color3.fromRGB(230,220,120)
                    or Color3.fromRGB(230,120,120)
            end

            if hum then hum.WalkSpeed = S.speedEnabled and S.speedValue or 16 end
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = not S.noclip end
                end
            end

            if S.fly and not flyBV then startFly()
            elseif not S.fly and flyBV then stopFly() end
            if S.fly and flyBV and hrp then
                local dir = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir += CAM.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= CAM.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= CAM.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir += CAM.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
                flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * S.flySpeed or Vector3.zero
                flyBG.CFrame = CAM.CFrame
            end

            if S.fullbright then
                Lighting.Brightness = math.max(Lighting.Brightness, 3)
                Lighting.Ambient = Color3.fromRGB(200,200,200)
            end
            updateWorld()

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local parts = getCharParts(plr)
                    local esp = espCache[plr]
                    if parts and esp then
                        local hrp2, hum2, char2 = parts
                        local head = char2:FindFirstChild("Head")
                        local role = getRole(plr)
                        local color = ROLE_COLORS[role]
                        if S.playerESP or S.roleESP then
                            local headPos = head and (head.Position + Vector3.new(0,0.7,0)) or (hrp2.Position + Vector3.new(0,2.5,0))
                            local bottomPos = hrp2.Position - Vector3.new(0, 2.6, 0)
                            local top, tOn = CAM:WorldToViewportPoint(headPos)
                            local bot, bOn = CAM:WorldToViewportPoint(bottomPos)
                            if tOn and bOn then
                                local h = math.abs(bot.Y - top.Y); local w = h/2
                                esp.box.Size = Vector2.new(w, h); esp.box.Position = Vector2.new(top.X - w/2, top.Y)
                                esp.box.Color = color; esp.box.Visible = true
                                local dist = hrp and (hrp2.Position - hrp.Position).Magnitude or 0
                                esp.name.Text = plr.Name .. "  [" .. math.floor(dist) .. "m]"
                                esp.name.Position = Vector2.new(top.X, top.Y - 28); esp.name.Color = color; esp.name.Visible = true
                                esp.info.Text = S.roleESP and role or ""
                                esp.info.Position = Vector2.new(top.X, top.Y - 14); esp.info.Color = color; esp.info.Visible = S.roleESP
                            else
                                esp.box.Visible = false; esp.name.Visible = false; esp.info.Visible = false
                            end
                        else
                            esp.box.Visible = false; esp.name.Visible = false; esp.info.Visible = false
                        end
                        if S.chams then applyChams(char2, color) else clearChams(char2) end
                    elseif esp then
                        esp.box.Visible = false; esp.name.Visible = false; esp.info.Visible = false
                    end
                end
            end

            if S.itemESP then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        for _, nm in ipairs(ITEM_NAMES) do
                            if obj.Name:lower():find(nm:lower()) then
                                if not itemDrawings[obj] then
                                    local d = Drawing.new("Text")
                                    d.Size = 12; d.Center = true; d.Outline = true
                                    d.Color = Color3.fromRGB(255, 230, 100); d.Text = nm
                                    itemDrawings[obj] = d
                                end
                                local d = itemDrawings[obj]
                                local sp, on = CAM:WorldToViewportPoint(obj.Position)
                                d.Position = Vector2.new(sp.X, sp.Y); d.Visible = on
                            end
                        end
                    end
                end
            elseif next(itemDrawings) then clearItemEsp() end

            if S.aimbot or S.silentAim then
                local closest, cd = nil, math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP then
                        local parts = getCharParts(plr)
                        if parts then
                            local head = parts[3]:FindFirstChild("Head")
                            if head then
                                local sp, on = CAM:WorldToViewportPoint(head.Position)
                                if on then
                                    local d = (Vector2.new(sp.X, sp.Y) - UIS:GetMouseLocation()).Magnitude
                                    if d < cd then cd = d; closest = head end
                                end
                            end
                        end
                    end
                end
                if closest then
                    if S.aimbot and UIS:IsMouseButtonPressed(S.aimKey) then
                        CAM.CFrame = CFrame.new(CAM.CFrame.Position, closest.Position)
                    end
                    if S.silentAim then CAM.CFrame = CFrame.new(CAM.CFrame.Position, closest.Position) end
                    if S.autoShoot then
                        pcall(function() game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,true,game,0) end)
                    end
                end
            end

            if S.autoDodge and hrp then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP and getRole(plr) == "Murderer" then
                        local parts = getCharParts(plr)
                        if parts and (parts[1].Position - hrp.Position).Magnitude < 12 then
                            hrp.Velocity = (hrp.Position - parts[1].Position).Unit * 90 + Vector3.new(0, 25, 0)
                        end
                    end
                end
            end

            if S.autoCoins or S.coinVacuum or S.autoPickup then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Parent and hrp then
                        local n = obj.Name:lower()
                        local isCoin = n:find("coin")
                        local isWep  = n:find("knife") or n:find("gun")
                        if (S.coinVacuum and isCoin)
                        or (S.autoCoins and isCoin and (obj.Position - hrp.Position).Magnitude < 8)
                        or (S.autoPickup and isWep and (obj.Position - hrp.Position).Magnitude < 8) then
                            obj.CFrame = CFrame.new(hrp.Position + Vector3.new(0, -2, 0))
                        end
                    end
                end
            end

            if S.autoEquipGun and char then
                if not char:FindFirstChildOfClass("Tool") then
                    local backpack = LP:FindFirstChild("Backpack")
                    if backpack then
                        for _, t in ipairs(backpack:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("gun") or t.Name:lower():find("revolver")) then
                                pcall(function() t.Parent = char end)
                            end
                        end
                    end
                end
            end

            if S.flingMurder or S.flingSheriff then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP then
                        local role = getRole(plr)
                        local parts = getCharParts(plr)
                        if parts and hrp and (parts[1].Position - hrp.Position).Magnitude < 12 then
                            if S.flingMurder and role == "Murderer" then flingTarget(parts[3], S.flingMode) end
                            if S.flingSheriff and role == "Sheriff" then flingTarget(parts[3], S.flingMode) end
                        end
                    end
                end
            end
        end
    end)

    -- INFO PANEL
    local InfoPanel = Instance.new("Frame")
    InfoPanel.Size = UDim2.new(0, 210, 0, 26)
    InfoPanel.Position = UDim2.new(0, 60, 0, 340)
    InfoPanel.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
    InfoPanel.BackgroundTransparency = 0.25
    InfoPanel.BorderSizePixel = 0
    InfoPanel.Visible = false
    InfoPanel.Parent = Root
    Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 8)

    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.fromScale(1,1)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.TextColor3 = Color3.fromRGB(220, 215, 240)
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextSize = 12
    InfoLabel.Parent = InfoPanel

    task.spawn(function()
        while task.wait(0.3) do
            local lines = {}
            if S.pingDisplay then
                local ok, ping = pcall(function() return LP:GetNetworkPing() * 1000 end)
                lines[#lines+1] = string.format("Ping: %d ms", ok and ping or 0)
            end
            if S.roundTimer then
                local t = Workspace:GetAttribute("RoundTime") or "—"
                lines[#lines+1] = "Round: " .. tostring(t)
            end
            if S.playerList then lines[#lines+1] = "Игроки: " .. tostring(#Players:GetPlayers()) end
            InfoLabel.Text = table.concat(lines, "  ·  ")
            InfoPanel.Visible = #lines > 0
            InfoPanel.Size = UDim2.new(0, 120 + #InfoLabel.Text * 5, 0, 26)
        end
    end)

    print("[nameless MM2 v2.2] OK. Кнопка 'nameless' слева. Клик — открыть.")
end

local ok, err = pcall(boot)
if not ok then
    warn("[nameless MM2 v2.2] Ошибка: " .. tostring(err))
end
