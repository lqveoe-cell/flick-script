-- [[ FLICK [FPS] - Undetected B&W HvH Script ]] --
-- Совместимость: Delta (Mobile & PC) | Без перехвата __namecall

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Настройки
local Settings = {
    Aim = { Enabled = false },
    FOV = { Enabled = false, Radius = 120, Visible = false },
    ESP = { Boxes = false, Tracers = false, Chams = false },
    Spinbot = { Enabled = false, Speed = 35 },
    Speedhack = { Enabled = false, Speed = 45 },
    Fly = { Enabled = false, Speed = 40 },
    ThirdPerson = { Enabled = false, Distance = 10 },
    HvH = { AntiAim = false, BHop = false, TargetStrafe = false }
}

-- Создание FOV круга через Drawing (без вмешательства в метатаблицы)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Radius = Settings.FOV.Radius
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Очистка старого GUI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BW_Safe_Gui") then
    playerGui.BW_Safe_Gui:Destroy()
end

-- Интерфейс
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BW_Safe_Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Кнопка для мобильных устройств
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 90, 0, 30)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "MENU [K]"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ScreenGui

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.BorderColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "  FLICK | SAFE B&W HvH"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.Code
Title.TextSize = 13
Title.Parent = MainFrame

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
UIListLayout.Padding = UDim.new(0, 4)

local function CreateToggle(name, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 28)
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

-- Переключатели
CreateToggle("AIMBOT (Head Lock)", function(v) Settings.Aim.Enabled = v end)
CreateToggle("SHOW FOV CIRCLE", function(v) Settings.FOV.Visible = v end)
CreateToggle("ESP BOXES", function(v) Settings.ESP.Boxes = v end)
CreateToggle("ESP TRACERS", function(v) Settings.ESP.Tracers = v end)
CreateToggle("ESP CHAMS", function(v) Settings.ESP.Chams = v end)
CreateToggle("SPINBOT", function(v) Settings.Spinbot.Enabled = v end)
CreateToggle("SPEEDHACK (Safe CFrame)", function(v) Settings.Speedhack.Enabled = v end)
CreateToggle("FLY HACK", function(v) Settings.Fly.Enabled = v end)
CreateToggle("THIRD PERSON", function(v) Settings.ThirdPerson.Enabled = v end)
CreateToggle("[HvH] JITTER ANTI-AIM", function(v) Settings.HvH.AntiAim = v end)
CreateToggle("[HvH] AUTO BHOP", function(v) Settings.HvH.BHop = v end)
CreateToggle("[HvH] TARGET STRAFE", function(v) Settings.HvH.TargetStrafe = v end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.K) then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Нахождение цели для Aim / Strafe
local function GetClosestTarget()
    local target = nil
    local shortest = Settings.FOV.Radius
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if vis then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortest then
                    shortest = dist
                    target = p.Character.Head
                end
            end
        end
    end
    return target
end

-- Безопасный Chams
local function ApplyChams(player)
    if player.Character then
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") and not part:FindFirstChild("SafeChams") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "SafeChams"
                box.Size = part.Size
                box.Color3 = Color3.fromRGB(255, 255, 255)
                box.AlwaysOnTop = true
                box.ZIndex = 5
                box.Adornee = part
                box.Transparency = 0.5
                box.Parent = part
            end
        end
    end
end

-- Главный поток выполнения
RunService.RenderStepped:Connect(function()
    -- Обновление FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Visible = Settings.FOV.Visible

    local targetHead = GetClosestTarget()

    -- Aimbot (прямая корректировка CFrame камеры)
    if Settings.Aim.Enabled and targetHead then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
    end

    -- Spinbot
    if Settings.Spinbot.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.Spinbot.Speed), 0)
    end

    -- Speedhack
    if Settings.Speedhack.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local moveDir = LocalPlayer.Character.Humanoid.MoveDirection
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + (moveDir * (Settings.Speedhack.Speed / 50))
    end

    -- Fly Hack
    if Settings.Fly.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local camCF = Camera.CFrame
        local flyVec = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then flyVec = flyVec + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then flyVec = flyVec - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then flyVec = flyVec - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then flyVec = flyVec + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyVec = flyVec + Vector3.new(0, 1, 0) end
        
        hrp.Velocity = Vector3.zero
        hrp.CFrame = hrp.CFrame + (flyVec * (Settings.Fly.Speed / 50))
    end

    -- BHop
    if Settings.HvH.BHop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    -- Target Strafe
    if Settings.HvH.TargetStrafe and targetHead and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local angle = tick() * 6
        local offset = Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8)
        hrp.CFrame = CFrame.new(targetHead.Position + offset, targetHead.Position)
    end

    -- Anti-Aim
    if Settings.HvH.AntiAim and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
    end

    -- Third Person
    if Settings.ThirdPerson.Enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPerson.Distance
    end

    -- Chams
    if Settings.ESP.Chams then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ApplyChams(p) end
        end
    end
end)

-- Безопасный ESP (Boxes & Tracers)
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
                if Settings.ESP.Boxes then
                    local sizeY = math.clamp(1000 / pos.Z, 10, 300)
                    local sizeX = sizeY / 1.5
                    drawings.Box.Size = Vector2.new(sizeX, sizeY)
                    drawings.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    drawings.Box.Visible = true
                else
                    drawings.Box.Visible = false
                end

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
