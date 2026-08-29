-- [[ FLICK [FPS] - Black & White HvH Script ]] --
-- Совместимость: Delta / Synapse X / Solara / Fluxus

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Настройки (Settings)
local Settings = {
    Aim = { Enabled = false, Smoothness = 1, LockPart = "Head" },
    FOV = { Enabled = false, Radius = 120, Visible = false },
    ESP = { Boxes = false, Distance = false, Skeletons = false, Tracers = false, Names = false },
    Spinbot = { Enabled = false, Speed = 30 },
    Speedhack = { Enabled = false, Speed = 50 },
    ThirdPerson = { Enabled = false, Distance = 10 },
    HvH = { AntiAim = false, BunnyHop = false, NoRecoil = false }
}

-- Создание FOV круга
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Radius = Settings.FOV.Radius
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Создание GUI (Чёрно-белый стиль)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BW_HvH_Gui"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 360)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.BorderColor3 = Color3.fromRGB(255, 255, 255)
Title.BorderSizePixel = 1
Title.Text = "  FLICK.EXE | HvH MENU"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.Parent = MainFrame

-- Контейнер для кнопок
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -45)
Container.Position = UDim2.new(0, 10, 0, 35)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.ScrollBarThickness = 4
Container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)

-- Функция создания переключателей (Toggle)
local function CreateToggle(name, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Button.BorderColor3 = Color3.fromRGB(60, 60, 60)
    Button.BorderSizePixel = 1
    Button.Text = "  [OFF] " .. name
    Button.TextColor3 = Color3.fromRGB(180, 180, 180)
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Font = Enum.Font.Code
    Button.TextSize = 13
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
            Button.TextColor3 = Color3.fromRGB(180, 180, 180)
            Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            Button.BorderColor3 = Color3.fromRGB(60, 60, 60)
        end
        callback(enabled)
    end)
end

-- Элементы меню
CreateToggle("AIMBOT (Head Lock)", function(v) Settings.Aim.Enabled = v end)
CreateToggle("SHOW FOV CIRCLE", function(v) Settings.FOV.Enabled = v; Settings.FOV.Visible = v end)
CreateToggle("ESP BOXES & NAMES", function(v) Settings.ESP.Boxes = v; Settings.ESP.Names = v end)
CreateToggle("ESP TRACERS", function(v) Settings.ESP.Tracers = v end)
CreateToggle("SPINBOT", function(v) Settings.Spinbot.Enabled = v end)
CreateToggle("SPEEDHACK", function(v) Settings.Speedhack.Enabled = v end)
CreateToggle("THIRD PERSON (3-е лицо)", function(v) Settings.ThirdPerson.Enabled = v end)
CreateToggle("[HvH] ANTI-AIM (Yaw Desync)", function(v) Settings.HvH.AntiAim = v end)
CreateToggle("[HvH] AUTO BHOP", function(v) Settings.HvH.BunnyHop = v end)
CreateToggle("[HvH] REMOVE RECOIL", function(v) Settings.HvH.NoRecoil = v end)

-- Открытие / Закрытие GUI на Insert или K
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and (input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.K) then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Вспомогательная функция поиска ближайшей головы в FOV
local function GetClosestHead()
    local target = nil
    local shortestDist = Settings.FOV.Radius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    target = head
                end
            end
        end
    end
    return target
end

-- Основной цикл программы
RunService.RenderStepped:Connect(function()
    -- Обновление FOV круга
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Visible = Settings.FOV.Visible

    -- Aimbot
    if Settings.Aim.Enabled then
        local targetHead = GetClosestHead()
        if targetHead then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
        end
    end

    -- Spinbot
    if Settings.Spinbot.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.Spinbot.Speed), 0)
    end

    -- Speedhack
    if Settings.Speedhack.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Speedhack.Speed
    end

    -- Third Person
    if Settings.ThirdPerson.Enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPerson.Distance
    end

    -- HvH Anti-Aim (Jitter / Desync)
    if Settings.HvH.AntiAim and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
    end

    -- HvH Auto BHop
    if Settings.HvH.BunnyHop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Простой ESP обработчик
local ESPDrawings = {}

local function AddESP(player)
    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Thickness = 1
    box.Filled = false
    box.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Color = Color3.fromRGB(255, 255, 255)
    tracer.Thickness = 1
    tracer.Visible = false

    ESPDrawings[player] = { Box = box, Tracer = tracer }
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then AddESP(p) end
end
Players.PlayerAdded:Connect(AddESP)

RunService.RenderStepped:Connect(function()
    for player, drawings in pairs(ESPDrawings) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                -- ESP Box
                if Settings.ESP.Boxes then
                    local sizeY = math.clamp(1000 / pos.Z, 10, 300)
                    local sizeX = sizeY / 1.5
                    drawings.Box.Size = Vector2.new(sizeX, sizeY)
                    drawings.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    drawings.Box.Visible = true
                else
                    drawings.Box.Visible = false
                end

                -- ESP Tracers
                if Settings.ESP.Tracers then
                    drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
                    drawings.Tracer.Visible = true
                else
                    drawings.Tracer.Visible = false
                end
            else
                drawings.Box.Visible = false
                drawings.Tracer.Visible = false
            end
        else
            drawings.Box.Visible = false
            drawings.Tracer.Visible = false
        end
    end
end)
