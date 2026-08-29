-- [[ FLICK [FPS] - Universal B&W HvH Script ]] --
-- Оптимизировано под Delta (Mobile & PC)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Настройки
local Settings = {
    Aim = { Enabled = false },
    FOV = { Enabled = false, Radius = 120, Visible = false },
    ESP = { Boxes = false, Tracers = false },
    Spinbot = { Enabled = false, Speed = 30 },
    Speedhack = { Enabled = false, Speed = 50 },
    ThirdPerson = { Enabled = false, Distance = 10 },
    HvH = { AntiAim = false, BunnyHop = false }
}

-- Безопасное удаление старого GUI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BW_HvH_Gui") then
    playerGui.BW_HvH_Gui:Destroy()
end

-- Создание ScreenGui в PlayerGui (для обхода ограничений CoreGui)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BW_HvH_Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Кнопка открытия/закрытия для мобильных устройств
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 90, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "MENU [K]"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ScreenGui

-- Основная рамка (Main Menu)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -190)
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
Title.Text = "  FLICK.EXE | B&W MENU"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.Code
Title.TextSize = 13
Title.Parent = MainFrame

-- Список функций
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -10, 1, -40)
Container.Position = UDim2.new(0, 5, 0, 35)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.Padding = UDim.new(0, 5)

-- Функция клика на кнопку
local function CreateToggle(name, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Button.BorderColor3 = Color3.fromRGB(60, 60, 60)
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
            Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Button.BorderColor3 = Color3.fromRGB(255, 255, 255)
        else
            Button.Text = "  [OFF] " .. name
            Button.TextColor3 = Color3.fromRGB(160, 160, 160)
            Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            Button.BorderColor3 = Color3.fromRGB(60, 60, 60)
        end
        callback(enabled)
    end)
end

-- Обработка сворачивания
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.K) then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Переключатели
CreateToggle("AIMBOT (Head Lock)", function(v) Settings.Aim.Enabled = v end)
CreateToggle("ESP BOXES", function(v) Settings.ESP.Boxes = v end)
CreateToggle("ESP TRACERS", function(v) Settings.ESP.Tracers = v end)
CreateToggle("SPINBOT", function(v) Settings.Spinbot.Enabled = v end)
CreateToggle("SPEEDHACK", function(v) Settings.Speedhack.Enabled = v end)
CreateToggle("THIRD PERSON", function(v) Settings.ThirdPerson.Enabled = v end)
CreateToggle("[HvH] ANTI-AIM", function(v) Settings.HvH.AntiAim = v end)
CreateToggle("[HvH] AUTO BHOP", function(v) Settings.HvH.BunnyHop = v end)

-- Основной поток (Логика)
RunService.RenderStepped:Connect(function()
    -- Aim
    if Settings.Aim.Enabled then
        local target = nil
        local dist = Settings.FOV.Radius
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if vis then
                    local mDist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if mDist < dist then
                        dist = mDist
                        target = p.Character.Head
                    end
                end
            end
        end
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end

    -- Spinbot
    if Settings.Spinbot.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.Spinbot.Speed), 0)
    end

    -- Speed
    if Settings.Speedhack.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Speedhack.Speed
    end

    -- 3rd Person
    if Settings.ThirdPerson.Enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPerson.Distance
    end

    -- AntiAim
    if Settings.HvH.AntiAim and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
    end

    -- BHop
    if Settings.HvH.BunnyHop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
