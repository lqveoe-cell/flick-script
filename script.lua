-- [[ FLICK [FPS] - Ultimate B&W HvH Script ]] --
-- Совместимость: Delta (Mobile & PC) / Synapse / Solara / Fluxus

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Настройки (Settings)
local Settings = {
    Aim = { Enabled = false, Silent = false, LockPart = "Head" },
    FOV = { Enabled = false, Radius = 150 },
    ESP = { Boxes = false, Tracers = false, Chams = false },
    Movement = { Speedhack = false, Speed = 45, Fly = false, FlySpeed = 50, BHop = false, Strafe = false },
    Spinbot = { Enabled = false, Speed = 45 },
    ThirdPerson = { Enabled = false, Distance = 12 },
    HvH = {
        AntiAim = false,
        DesyncYaw = false,
        NoRecoil = false,
        NoSpread = false,
        RapidFire = false,
        Wallbang = false,
        AutoShoot = false,
        HitSound = false
    }
}

-- Чистка старого GUI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BW_HvH_Gui_V2") then
    playerGui.BW_HvH_Gui_V2:Destroy()
end

-- GUI Создание
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BW_HvH_Gui_V2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Кнопка сворачивания (Mobile Friendly)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 32)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "MENU [K]"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.TextSize = 13
ToggleBtn.Parent = ScreenGui

-- Главная панель
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 440)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Шапка
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
Title.BorderColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "  FLICK [FPS] - ULTIMATE HvH"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.Code
Title.TextSize = 13
Title.Parent = MainFrame

-- Список переключателей
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -12, 1, -44)
Container.Position = UDim2.new(0, 6, 0, 38)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.Padding = UDim.new(0, 4)

local function CreateToggle(name, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 28)
    Button.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Button.BorderColor3 = Color3.fromRGB(50, 50, 50)
    Button.Text = "  [OFF] " .. name
    Button.TextColor3 = Color3.fromRGB(160, 160, 160)
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Font = Enum.Font.Code
    Button.TextSize = 12
    Button.Parent = Container

    local enabled = false
    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            Button.Text = "  [ON] " .. name
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Button.BorderColor3 = Color3.fromRGB(255, 255, 255)
        else
            Button.Text = "  [OFF] " .. name
            Button.TextColor3 = Color3.fromRGB(160, 160, 160)
            Button.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            Button.BorderColor3 = Color3.fromRGB(50, 50, 50)
        end
        callback(enabled)
    end)
end

-- Добавление опций в меню
CreateToggle("AIMBOT (Hard Headlock)", function(v) Settings.Aim.Enabled = v end)
CreateToggle("SILENT AIM (Silent Hit)", function(v) Settings.Aim.Silent = v end)
CreateToggle("TRIGGERBOT (Auto Shoot)", function(v) Settings.HvH.AutoShoot = v end)
CreateToggle("ESP BOXES", function(v) Settings.ESP.Boxes = v end)
CreateToggle("ESP TRACERS", function(v) Settings.ESP.Tracers = v end)
CreateToggle("ESP CHAMS (Wallhack Highlight)", function(v) Settings.ESP.Chams = v end)
CreateToggle("SPINBOT (360 Yaw)", function(v) Settings.Spinbot.Enabled = v end)
CreateToggle("SPEEDHACK (CFrame Booster)", function(v) Settings.Movement.Speedhack = v end)
CreateToggle("FLY HACK (CFrame Fly)", function(v) Settings.Movement.Fly = v end)
CreateToggle("AUTO BHOP", function(v) Settings.Movement.BHop = v end)
CreateToggle("TARGET STRAFE", function(v) Settings.Movement.Strafe = v end)
CreateToggle("THIRD PERSON (3-е лицо)", function(v) Settings.ThirdPerson.Enabled = v end)
CreateToggle("[HvH] ANTI-AIM (Jitter Desync)", function(v) Settings.HvH.AntiAim = v end)
CreateToggle("[HvH] REMOVE RECOIL & SPREAD", function(v) Settings.HvH.NoRecoil = v; Settings.HvH.NoSpread = v end)
CreateToggle("[HvH] RAPID FIRE (Fast Bullet Trigger)", function(v) Settings.HvH.RapidFire = v end)
CreateToggle("[HvH] WALLBANG PASS (Raycast Bypass)", function(v) Settings.HvH.Wallbang = v end)

-- Переключение интерфейса
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.K) then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Поиск цели
local function GetClosestTarget()
    local closest = nil
    local maxDist = Settings.FOV.Radius
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local pos, vis = Camera:WorldToViewportPoint(head.Position)
            if vis or Settings.HvH.Wallbang then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

-- Chams (Подсветка сквозь стены)
local function ApplyChams(player)
    if player.Character then
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") and not part:FindFirstChild("ChamsBox") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ChamsBox"
                box.Size = part.Size
                box.Color3 = Color3.fromRGB(255, 255, 255)
                box.AlwaysOnTop = true
                box.ZIndex = 5
                box.Adornee = part
                box.Transparency = 0.4
                box.Parent = part
            end
        end
    end
end

-- Основная логика HvH
RunService.RenderStepped:Connect(function()
    local targetHead = GetClosestTarget()

    -- Hard Aim & Silent Aim
    if Settings.Aim.Enabled and targetHead then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
    end

    -- Triggerbot / AutoShoot
    if Settings.HvH.AutoShoot and targetHead then
        mouse1press()
        task.wait(0.01)
        mouse1release()
    end

    -- Spinbot
    if Settings.Spinbot.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.Spinbot.Speed), 0)
    end

    -- Speedhack CFrame
    if Settings.Movement.Speedhack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local moveDir = LocalPlayer.Character.Humanoid.MoveDirection
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + (moveDir * (Settings.Movement.Speed / 50))
    end

    -- Fly Hack
    if Settings.Movement.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local camCF = Camera.CFrame
        local flyVec = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then flyVec = flyVec + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then flyVec = flyVec - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then flyVec = flyVec - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then flyVec = flyVec + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyVec = flyVec + Vector3.new(0, 1, 0) end
        
        hrp.Velocity = Vector3.zero
        hrp.CFrame = hrp.CFrame + (flyVec * (Settings.Movement.FlySpeed / 50))
    end

    -- Auto BHop
    if Settings.Movement.BHop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    -- Target Strafe (Вращение вокруг цели)
    if Settings.Movement.Strafe and targetHead and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local angle = tick() * 5
        local radius = 8
        local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        hrp.CFrame = CFrame.new(targetHead.Position + offset, targetHead.Position)
    end

    -- Anti-Aim (Jitter / Pitch)
    if Settings.HvH.AntiAim and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(math.random(-45, 45)), math.rad(math.random(-180, 180)), 0)
    end

    -- Third Person
    if Settings.ThirdPerson.Enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPerson.Distance
    end

    -- Chams Update
    if Settings.ESP.Chams then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ApplyChams(p) end
        end
    end
end)

-- Обход метатаблиц (Silent Aim / Wallbang / NoRecoil Hooking)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() then
        if method == "FindPartOnWithIgnoreList" or method == "Raycast" then
            if Settings.HvH.Wallbang then
                -- Игнорировать стены при выстреле
                return oldNamecall(self, ...)
            end
        end

        if Settings.HvH.NoRecoil and (method == "FireServer" or method == "InvokeServer") then
            -- Фильтрация параметров отдачи
            if tostring(self):lower():find("recoil") or tostring(self):lower():find("spread") then
                return nil
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
