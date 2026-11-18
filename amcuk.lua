-- RUON: COMBINED FULL PANEL (BÖLMELİ, TAŞMA YOK, ÖZELLİKLER KORUNDU)
-- Tek dosya — yapıştırıp çalıştır
print("yüklendii")
-- Services & basic refs (kept names similar to original)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Workspace = workspace
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================
-- Utility: safe mouse clicks (pcall wrappers)
-- =========================
local function safe_mouse1press()
    pcall(function() mouse1press() end)
end
local function safe_mouse1release()
    pcall(function() mouse1release() end)
end
local function safe_mouse1click()
    pcall(function() mouse1click() end)
end

-- =========================
-- STATE & DEVICE VARS
-- =========================
local deviceMode = "PC"    -- default
local isBrookHaven = false -- Added for safety thib
local rainbowEnabled = false
local rainbowHue = 0

local flySpeed = 50
local flying = false
local noclip = false
local BV, BG -- BodyVelocity / BodyGyro

local aimModes = { "Kapalı", "Düşmanlar", "Herkes" }; local aimIndex = 1
local espModes = { "Kapalı", "Düşmanlar", "Herkes" }; local espIndex = 1

local triggerEnabled = false
local triggerModes = { "Düşmanlar", "Herkes" }; local triggerIndex = 1
local HoldClick = true
local CurrentlyPressed = false

local activeSkinName = "Normal"
local activeSkinAction = nil
local autoApplyGlobal = false

local flying2 = false
local BV2, BG2

local infiniteJump = false
local mobileUp = false
local mobileDown = false

local tracers = false

local infiniteOxygen = false
local espNames = false
local espDistance = false
local aimFOV = 100
local showFOV = false
local aimSmoothing = 1

local espActive = false
local enemyFilter = true
local teamFilter = false

local enemyColor = Color3.fromRGB(255, 50, 50)
local teamColor = Color3.fromRGB(50, 255, 50)

local clickTP = false
local targetWalkSpeed = 16
local targetJumpPower = 50
local highlightChams = false
highlightCustomColor = nil
highlightNeonEnabled = false
highlightRainbowColor = false
rainEnabled = false
snowEnabled = false
local cframeSpeedEnabled = false
local cframeSpeedValue = 1
local desyncSpin = false
local healthBars = false
local godModeEnabled = false
local cameraFOV = 70
local maxZoomValue = 400
local infZoomEnabled = false
local freeVipEnabled = false
local instantPromptEnabled = false
local targetPlayer = nil
local isFollowing = false

local spectateTarget = nil
local hitboxEnabled = false
local hitboxSize = 5
local rainbowGunEnabled = false
local neonRainbowEnabled = false
local wallCheckEnabled = true
local reachEnabled = false
local reachValue = 10
local triggerCPS = 60

local hitmarkerEnabled = false
local hitmarkerConstant = false
local hitmarkerRainbow = false
local hitmarkerColor = Color3.fromRGB(255, 255, 255)
local hitmarkerSize = 15
local hitmarkerThickness = 2
local hitmarkerSpeed = 8

local mouseUnlockKey = Enum.KeyCode.T
local flyToggleKey = Enum.KeyCode.H
local isAssigningKey = false
local mouseUnlockEnabled = false

-- Forward declare for Touch Fling loop (defined later, used in MM2 toggle callback)
local touchFlingLoop

-- =========================
-- MM2 STATE VARIABLES
-- =========================
local mm2_active = true
local mm2_silentAim = false
local mm2_killAura = false
local mm2_roleESP = false
local mm2_touchFling = false
local mm2_flingPower = 10000
local mm2_autoFlingMurderer = false


local fovColor = Color3.fromRGB(255, 255, 255)
local fovThickness = 2

-- =========================
-- CROSSHAIR STATE VARIABLES
-- =========================
local crosshairEnabled = false
local crosshairRotateSpeed = 100
local crosshairPulseSpeed = 2
local crosshairColorSpeed = 1
local crosshairSize = 10
local crosshairThickness = 2
local crosshairGap = 5

-- =========================
-- GLOBAL UTILITIES
-- =========================
local function isGlobalVisible(part)
    if not part or not part.Position then return false end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    params.FilterType = Enum.RaycastFilterType.Exclude -- Blacklist is old
    local hit = workspace:Raycast(origin, dir, params)
    return hit and hit.Instance and hit.Instance:IsDescendantOf(part.Parent)
end

-- ==========================================
-- NATIVE UI FOV CIRCLE (Bypasses Drawing API bugs)
-- ==========================================
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "RuonFOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
pcall(function() fovGui.Parent = game:GetService("CoreGui") end)
if not fovGui.Parent then
    fovGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    -- If placed in PlayerGui, it might get deleted on death. Force it to reinstantiate.
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if not fovGui.Parent and LocalPlayer:FindFirstChild("PlayerGui") then
            fovGui.Parent = LocalPlayer.PlayerGui
        end
    end)
end

local fovFrame = Instance.new("Frame")
fovFrame.Name = "FOVFrame"
fovFrame.BackgroundTransparency = 1
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Size = UDim2.new(0, aimFOV * 2, 0, aimFOV * 2)
fovFrame.Visible = showFOV
fovFrame.Parent = fovGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = fovColor
fovStroke.Thickness = fovThickness
fovStroke.Transparency = 0
fovStroke.Parent = fovFrame

-- ==========================================
-- ROTATING CROSSHAIR (Native UI)
-- ==========================================
local crosshairFrame = Instance.new("Frame")
crosshairFrame.Name = "CrosshairFrame"
crosshairFrame.BackgroundTransparency = 1
crosshairFrame.Size = UDim2.new(0, 100, 0, 100)
crosshairFrame.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairFrame.Visible = false
crosshairFrame.Parent = fovGui

local function createCrosshairLine(name)
    local line = Instance.new("Frame")
    line.Name = name
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Parent = crosshairFrame
    return line
end

local cL1 = createCrosshairLine("Top")
local cL2 = createCrosshairLine("Bottom")
local cL3 = createCrosshairLine("Left")
local cL4 = createCrosshairLine("Right")

-- ==========================================
-- ORBITAL RAINBOW HITMARKER UI
-- ==========================================
local hitmarkerFrame = Instance.new("Frame")
hitmarkerFrame.Name = "HitmarkerFrame"
hitmarkerFrame.BackgroundTransparency = 1
hitmarkerFrame.Size = UDim2.new(0, 200, 0, 200)
hitmarkerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
hitmarkerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
hitmarkerFrame.Visible = true
hitmarkerFrame.Parent = fovGui

-- Yörünge merkezi (görünmez referans nokta)
local orbitCenter = Instance.new("Frame")
orbitCenter.Name = "OrbitCenter"
orbitCenter.BackgroundTransparency = 1
orbitCenter.Size = UDim2.new(0, 4, 0, 4)
orbitCenter.AnchorPoint = Vector2.new(0.5, 0.5)
orbitCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
orbitCenter.Parent = hitmarkerFrame

local function createHitmarkerLine(name)
    local line = Instance.new("Frame")
    line.Name = name
    line.Size = UDim2.new(0, hitmarkerThickness, 0, hitmarkerSize)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(0.5, 0, 0.5, 0)
    line.BackgroundColor3 = hitmarkerColor
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 1
    line.Parent = hitmarkerFrame
    return line
end

local h1 = createHitmarkerLine("L1")
local h2 = createHitmarkerLine("L2")
local h3 = createHitmarkerLine("L3")
local h4 = createHitmarkerLine("L4")

local TweenService = game:GetService("TweenService")

-- Yörünge parametreleri (her gezegenin başlangıç fazı)
local orbitPhases = { 0, math.pi * 0.5, math.pi, math.pi * 1.5 }
local orbitLines = { h1, h2, h3, h4 }

-- Hit anındaki hız patlaması için
local hitBurst = 0 -- 0..1 arası, hit anında 1 olur, zamanla söner

local function updateHitmarkerOffsets()
    -- Orbital modda pozisyonlar döngü tarafından yönetilir
end
updateHitmarkerOffsets()

local function showHitmarker()
    if not hitmarkerEnabled then return end
    hitBurst = 1 -- Hız patlaması tetikle
end

-- ==========================================
-- CROSSHAIR ANIMATION LOOP
-- ==========================================
task.spawn(function()
    local crosshairRot = 0
    while true do
        if crosshairEnabled then
            local dt = task.wait()
            crosshairRot = (crosshairRot + (dt * crosshairRotateSpeed)) % 360
            crosshairFrame.Rotation = crosshairRot

            -- Pulse (Size) logic
            local pulse = math.sin(tick() * crosshairPulseSpeed) * 0.5 + 0.5 -- 0 to 1
            local currentSize = crosshairSize + (pulse * 5)
            local currentGap = crosshairGap + (pulse * 3)

            -- Color (Rainbow) logic
            local color = Color3.fromHSV((tick() * crosshairColorSpeed * 0.2) % 1, 0.8, 1)

            local lines = { cL1, cL2, cL3, cL4 }
            for _, l in ipairs(lines) do
                l.BackgroundColor3 = color
            end

            -- Position lines
            cL1.Size = UDim2.new(0, crosshairThickness, 0, currentSize)
            cL1.Position = UDim2.new(0.5, 0, 0.5, -(currentGap + currentSize / 2))

            cL2.Size = UDim2.new(0, crosshairThickness, 0, currentSize)
            cL2.Position = UDim2.new(0.5, 0, 0.5, (currentGap + currentSize / 2))

            cL3.Size = UDim2.new(0, currentSize, 0, crosshairThickness)
            cL3.Position = UDim2.new(0.5, -(currentGap + currentSize / 2), 0.5, 0)

            cL4.Size = UDim2.new(0, currentSize, 0, crosshairThickness)
            cL4.Position = UDim2.new(0.5, (currentGap + currentSize / 2), 0.5, 0)

            crosshairFrame.Visible = true
        else
            crosshairFrame.Visible = false
            task.wait(0.5)
        end
    end
end)

-- ==========================================
-- ORBITAL RAINBOW HITMARKER ANIMATION LOOP
-- Gezegenler güneş etrafında döner gibi
-- ==========================================
task.spawn(function()
    local orbitAngle = 0 -- Ana yörünge açısı (tüm sistem)
    while true do
        local dt = task.wait()

        if hitmarkerEnabled then
            -- Hit burst zamanla azalsın
            hitBurst = math.max(0, hitBurst - dt * 2.5)

            -- Constant ya da hit burst aktifse göster
            local shouldShow = hitmarkerConstant or hitBurst > 0.01

            if shouldShow then
                -- Temel yörünge hızı + hit burst hızlanması
                local baseSpeed   = hitmarkerSpeed * 55
                local burstBoost  = hitBurst * hitmarkerSpeed * 300
                orbitAngle        = orbitAngle + dt * (baseSpeed + burstBoost)

                -- Yörünge yarıçapı: hit burst anında büyüsün, sonra normalleşsin
                local baseRadius  = hitmarkerSize * 0.9
                local burstRadius = hitBurst * hitmarkerSize * 1.6
                local orbitRadius = baseRadius + burstRadius

                -- Her "gezegen" çizgiyi yerleştir
                for i, line in ipairs(orbitLines) do
                    local phase = orbitPhases[i]
                    local angle = math.rad(orbitAngle) + phase

                    -- Yörünge pozisyonu (merkeze göre)
                    local px = math.cos(angle) * orbitRadius
                    local py = math.sin(angle) * orbitRadius

                    line.Position = UDim2.new(0.5, px, 0.5, py)

                    -- Çizginin kendi rotasyonu: yörünge açısına + 45 derece eğik
                    line.Rotation = orbitAngle + (i * 90)

                    -- Boyut: hit burst anında büyüsün
                    local sizeBoost = 1 + hitBurst * 1.2
                    line.Size = UDim2.new(0, hitmarkerThickness, 0, hitmarkerSize * sizeBoost)

                    -- Saydamlık: hit burst anında parlasın
                    local alpha = hitmarkerConstant and 0.15 or 0
                    line.BackgroundTransparency = alpha + (hitBurst > 0.01 and (1 - hitBurst) * 0.25 or 0)

                    -- Renk: rainbow ya da sabit
                    if hitmarkerRainbow then
                        -- Her gezegen biraz farklı hue offset ile kayan rainbow
                        local hueOffset = (i - 1) * 0.25
                        local hue = ((tick() * hitmarkerSpeed * 0.18) + hueOffset) % 1
                        line.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    else
                        line.BackgroundColor3 = hitmarkerColor
                    end
                end
            else
                -- Hitmarker kapalı veya burst bitti — gizle
                for _, line in ipairs(orbitLines) do
                    line.BackgroundTransparency = 1
                end
            end
        else
            -- Hitmarker feature kapalı
            for _, line in ipairs(orbitLines) do
                line.BackgroundTransparency = 1
            end
            task.wait(0.2)
        end
    end
end)
-- HEALTH TRACKING FOR HIT EFFECTS
-- ==========================================
local function getTrueScreenCenter()
    local res = workspace.CurrentCamera.ViewportSize
    if res.X > 1 and res.Y > 1 then
        return Vector2.new(res.X / 2, res.Y / 2)
    end

    -- Fallbacks for executors breaking ViewportSize
    local success, guiSize = pcall(function()
        local sg = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChildOfClass("ScreenGui")
        if sg then return sg.AbsoluteSize end
        return nil
    end)

    if success and guiSize and guiSize.X > 1 then
        local inset = game:GetService("GuiService"):GetGuiInset()
        return Vector2.new((guiSize.X + inset.X) / 2, (guiSize.Y + inset.Y) / 2)
    end

    return Vector2.new(1920 / 2, 1080 / 2)
end

local function getGlobalClosestTarget(ignoreAimMode)
    local bestHead, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            -- Aim Modes check (Enemy only or Everyone)
            local pass = ignoreAimMode or (aimIndex == 3 or (aimIndex == 2 and p.Team ~= LocalPlayer.Team))
            if pass then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local sp, onScreen = Camera:WorldToScreenPoint(head.Position)
                    local visible = not wallCheckEnabled or isGlobalVisible(head)
                    if onScreen and visible then
                        local d = (Vector2.new(sp.X, sp.Y) - getTrueScreenCenter()).Magnitude
                        if d < aimFOV and d < bestDist then
                            bestDist = d
                            bestHead = head
                        end
                    end
                end
            end
        end
    end
    return bestHead
end

-- Note: Removed native Drawing API circle setup, using purely Native UI now.

local mobFlyUI = nil

local Mouse = LocalPlayer:GetMouse()

-- =========================
-- GUI BASE
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RuonHackGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui
screenGui.Enabled = true        -- Enabled to show selection screen
screenGui.IgnoreGuiInset = true -- Better centering
local main, left, right, selectFrame, mainStroke, subtitle, title

-- applyBrookhavenTheme removed

-- Hidden Modal Button for Mouse Unlock
local mouseModalBtn = Instance.new("TextButton")
mouseModalBtn.Size = UDim2.new(0, 1, 0, 1)
mouseModalBtn.Position = UDim2.new(0, -10, 0, -10) -- Off-screen
mouseModalBtn.BackgroundTransparency = 1
mouseModalBtn.Text = ""
mouseModalBtn.Modal = false
mouseModalBtn.Visible = true
mouseModalBtn.Parent = screenGui

-- applyBrookhavenTheme removed


-- =========================
-- UTILITY FUNCTIONS
-- =========================
local function showNotify(txt)
    local notify = Instance.new("TextLabel", screenGui)
    notify.Size = UDim2.new(0, 300, 0, 30)
    notify.Position = UDim2.new(0.5, -150, 0, 50)
    notify.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    notify.TextColor3 = Color3.fromRGB(100, 255, 100)
    notify.Text = txt
    notify.Font = Enum.Font.GothamBold
    notify.TextSize = 14
    notify.BorderSizePixel = 0
    Instance.new("UICorner", notify).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", notify); stroke.Color = Color3.fromRGB(100, 255, 100); stroke.Thickness = 1

    task.spawn(function()
        task.wait(3)
        for i = 0, 1, 0.1 do
            notify.BackgroundTransparency = i
            notify.TextTransparency = i
            stroke.Transparency = i
            task.wait(0.05)
        end
        notify:Destroy()
    end)
end

-- =========================
-- MM2 HELPERS
-- =========================
local function getRole(p)
    if not p or not p.Character then return "Innocent" end
    if p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife") then return "Murderer" end
    if p.Backpack:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Hero") or p.Character:FindFirstChild("Hero") then
        return
        "Sheriff"
    end
    return "Innocent"
end

local function getMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if getRole(p) == "Murderer" then return p end
    end
    return nil
end


local function mkToggle(parent, name, defaultVar, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.95, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = name .. ": " .. (defaultVar and "Açık" or "Kapalı")
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = defaultVar and Color3.fromRGB(100, 255, 100) or
        Color3.fromRGB(255, 100, 100); stroke.Thickness = 1

    btn.MouseButton1Click:Connect(function()
        local newState = callback()
        btn.Text = name .. ": " .. (newState and "Açık" or "Kapalı")
        stroke.Color = newState and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    end)
    return btn
end

local function mkSlider(parent, name, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.95, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sliderBtn = Instance.new("TextButton", frame)
    sliderBtn.Size = UDim2.new(1, -20, 0, 6)
    sliderBtn.Position = UDim2.new(0, 10, 0, 32)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    sliderBtn.Text = ""
    sliderBtn.AutoButtonColor = false
    Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", sliderBtn)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBtn.AbsolutePosition.X) / sliderBtn.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pos))
        fill.Size = UDim2.new(pos, 0, 1, 0)
        lbl.Text = name .. ": " .. val
        callback(val)
    end

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
end

local function mkKeybind(parent, name, currentKey, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.95, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = name .. ": " .. currentKey.Name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 1

    local connection
    btn.MouseButton1Click:Connect(function()
        if isAssigningKey then return end
        isAssigningKey = true
        btn.Text = "Tuş Bekleniyor..."
        stroke.Color = Color3.fromRGB(255, 255, 100)

        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                isAssigningKey = false
                callback(input.KeyCode)
                btn.Text = name .. ": " .. input.KeyCode.Name
                stroke.Color = Color3.fromRGB(150, 150, 150)
                connection:Disconnect()
            end
        end)
    end)
    return btn
end

local function addMoveControl(parent, name, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundTransparency = 1

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(0.4, 0, 1, 0)
    textLabel.Text = name
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 16
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.BackgroundTransparency = 1

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0.5, 0, 0.8, 0)
    box.Position = UDim2.new(0.45, 0, 0.1, 0)
    box.Text = tostring(default)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.Font = Enum.Font.Gotham
    box.TextSize = 16
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then callback(val) end
    end)
end

local function addColorSection(parent, title, targetVar, setter)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.Text = "  " .. title
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.BackgroundTransparency = 1

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundTransparency = 1

    local grid = Instance.new("UIGridLayout", frame)
    grid.CellSize = UDim2.new(0, 36, 0, 36)
    grid.CellPadding = UDim2.new(0, 6, 0, 6)
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local colors = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 255, 255), Color3.fromRGB(50, 50, 50)
    }

    for _, col in ipairs(colors) do
        local b = Instance.new("TextButton", frame)
        b.Text = ""
        b.BackgroundColor3 = col
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", b); s.Thickness = 1; s.Color = Color3.fromRGB(255, 255, 255); s.Transparency = 1

        b.MouseButton1Click:Connect(function()
            setter(col)
        end)
    end
end



local function updateMobFlyUI()
    if deviceMode ~= "Mobil" then return end
    if (flying or flying2) then
        if not mobFlyUI then
            mobFlyUI = Instance.new("Frame", screenGui)
            mobFlyUI.Size = UDim2.new(0, 80, 0, 180)
            mobFlyUI.Position = UDim2.new(1, -100, 0.5, -90)
            mobFlyUI.BackgroundTransparency = 1

            local upBtn = Instance.new("TextButton", mobFlyUI)
            upBtn.Size = UDim2.new(1, 0, 0, 80)
            upBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            upBtn.Text = "⬆"
            upBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
            upBtn.Font = Enum.Font.GothamBold
            upBtn.TextSize = 30
            pcall(function() Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 12) end)
            pcall(function() Instance.new("UIStroke", upBtn).Color = Color3.fromRGB(100, 100, 120) end)

            local downBtn = Instance.new("TextButton", mobFlyUI)
            downBtn.Size = UDim2.new(1, 0, 0, 80)
            downBtn.Position = UDim2.new(0, 0, 0, 100)
            downBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            downBtn.Text = "⬇"
            downBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
            downBtn.Font = Enum.Font.GothamBold
            downBtn.TextSize = 30
            pcall(function() Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 12) end)
            pcall(function() Instance.new("UIStroke", downBtn).Color = Color3.fromRGB(100, 100, 120) end)

            upBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mobileUp = true
                    upBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                end
            end)
            upBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mobileUp = false
                    upBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                end
            end)

            downBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mobileDown = true
                    downBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                end
            end)
            downBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mobileDown = false
                    downBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                end
            end)
        end
        mobFlyUI.Visible = true
    else
        if mobFlyUI then mobFlyUI.Visible = false end
        mobileUp = false
        mobileDown = false
    end
end

-- Fly Helpers
local function stopFly()
    flying = false
    if BV then
        BV:Destroy()
        BV = nil
    end
    if BG then
        BG:Destroy()
        BG = nil
    end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    updateMobFlyUI()
    showNotify("✈️ FLY: KAPALI")
end

local function stopFly2()
    flying2 = false
    if BV2 then
        BV2:Destroy()
        BV2 = nil
    end
    if BG2 then
        BG2:Destroy()
        BG2 = nil
    end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    updateMobFlyUI()
    showNotify("✈️ FLY 2: KAPALI")
end

-- main container (compact)
main = Instance.new("Frame", screenGui)
main.Name = "MainPanel"
main.Visible = false                  -- Hidden until selection is done
main.Size = UDim2.new(0, 560, 0, 400) -- Increased height to 400
main.Position = UDim2.fromOffset(20, 20)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BackgroundTransparency = 0.12
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- subtle stroke
mainStroke = Instance.new("UIStroke", main)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.6
mainStroke.Color = Color3.fromRGB(90, 90, 110)

-- title
local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 48)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundTransparency = 1
title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Text = "NEGRO studio"
title.TextXAlignment = Enum.TextXAlignment.Left

-- minimize button
local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0, 36, 0, 36)
minimizeBtn.Position = UDim2.new(1, -52, 0, 6)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 22
minimizeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        minimizeBtn.Text = "+"
        left.Visible = false
        right.Visible = false
        main:TweenSize(UDim2.new(0, 200, 0, 48), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    else
        minimizeBtn.Text = "-"
        main:TweenSize(UDim2.new(0, 560, 0, 400), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true, function()
            left.Visible = true
            right.Visible = true
        end)
    end
end)

-- rgb animated outline (subtle)
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 0.06) % 1
    if main and mainStroke then
        if rainbowEnabled then
            rainbowHue = (rainbowHue + 0.005) % 1
            main.BackgroundColor3 = Color3.fromHSV(rainbowHue, 0.7, 0.95)
        elseif not isBrookHaven then
            mainStroke.Color = Color3.fromHSV(hue, 0.12, 0.85)
        end
    end
end)

-- layout: left menu / right content
left = Instance.new("ScrollingFrame", main)
left.Size = UDim2.new(0, 140, 1, -60)
left.Position = UDim2.new(0, 12, 0, 56)
left.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
left.BackgroundTransparency = 0.05
left.CanvasSize = UDim2.new(0, 0, 0, 0)
left.AutomaticCanvasSize = Enum.AutomaticSize.Y
left.ScrollBarThickness = 2
left.BorderSizePixel = 0
Instance.new("UICorner", left).CornerRadius = UDim.new(0, 12)
local leftLayout = Instance.new("UIListLayout", left)
leftLayout.Padding = UDim.new(0, 8)
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local leftPad = Instance.new("UIPadding", left)
leftPad.PaddingTop = UDim.new(0, 8)
leftPad.PaddingBottom = UDim.new(0, 8)

right = Instance.new("Frame", main)
right.Size = UDim2.new(1, -172, 1, -60)
right.Position = UDim2.new(0, 164, 0, 56)
right.BackgroundTransparency = 1

-- small subtitle on top-left of right
subtitle = Instance.new("TextLabel", main)
subtitle.Size = UDim2.new(0, 300, 0, 18)
subtitle.Position = UDim2.new(0, 164, 0, 34)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromRGB(190, 190, 200)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "powerd by ru0n"

-- menu button factory (compact)
local function mkMenuBtn(parent, txt)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.92, 0, 0, 36)
    b.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
    b.TextColor3 = Color3.fromRGB(240, 240, 240)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.Text = txt
    b.AutoButtonColor = false
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0, 8)
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.3 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 0.6 end)
    b.TextSize = 16
    return b
end

local btnFly = mkMenuBtn(left, "Fly")
local btnMovement = mkMenuBtn(left, "Movement")
local btnESP = mkMenuBtn(left, "ESP")
local btnAim = mkMenuBtn(left, "Aimlock")
local btnTrigger = mkMenuBtn(left, "TriggerBot")
local btnWorld = mkMenuBtn(left, "World")
local btnHitmarker = mkMenuBtn(left, "Hitmarker")
local btnTeleport = mkMenuBtn(left, "Teleport")
local btnThemes = mkMenuBtn(left, "Themes")
local btnMisc = mkMenuBtn(left, "Misc")
local btnVisuals = mkMenuBtn(left, "Görsel")
-- btnBang removed
local btnMM2 = mkMenuBtn(left, "MM2")
local btnProfile = mkMenuBtn(left, "Profil")
-- btnBrook removed


-- pages
local pages = {}
local function newPage(name)
    local p = Instance.new("Frame", right)
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    pages[name] = p
    return p
end

pageFly = newPage("Fly")
pageMovement = newPage("Movement")
pageESP = newPage("ESP")
pageAim = newPage("Aim")
pageTrigger = newPage("Trigger")
pageWorld = newPage("World")
pageHitmarker = newPage("Hitmarker")
pageTeleport = newPage("Teleport")
pageThemes = newPage("Themes")
pageMisc = newPage("Misc")
pageVisuals = newPage("Visuals")
-- pageBang removed
pageMM2 = newPage("MM2")
pageProfile = newPage("Profile")
-- pageBrook removed


local function showPage(name)
    for k, v in pairs(pages) do v.Visible = false end
    if pages[name] then pages[name].Visible = true end
end

-- default
showPage("Fly")

btnFly.MouseButton1Click:Connect(function() showPage("Fly") end)
btnMovement.MouseButton1Click:Connect(function() showPage("Movement") end)
btnESP.MouseButton1Click:Connect(function() showPage("ESP") end)
btnAim.MouseButton1Click:Connect(function() showPage("Aim") end)
btnTrigger.MouseButton1Click:Connect(function() showPage("Trigger") end)
btnWorld.MouseButton1Click:Connect(function() showPage("World") end)
btnHitmarker.MouseButton1Click:Connect(function() showPage("Hitmarker") end)
btnTeleport.MouseButton1Click:Connect(function() showPage("Teleport") end)
btnThemes.MouseButton1Click:Connect(function() showPage("Themes") end)
btnMisc.MouseButton1Click:Connect(function() showPage("Misc") end)
btnVisuals.MouseButton1Click:Connect(function() showPage("Visuals") end)
-- btnBang click removed
btnMM2.MouseButton1Click:Connect(function() showPage("MM2") end)
btnProfile.MouseButton1Click:Connect(function() showPage("Profile") end)
-- btnBrook click removed



-- Selection logic removed (merged into RuonStartup)

-- =========================
-- Populate Profile page
-- =========================
do
    local scroll = Instance.new("ScrollingFrame", pageProfile)
    scroll.Size = UDim2.new(1, 0, 1, -10)
    scroll.Position = UDim2.new(0, 0, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)

    -- Profile Card
    local card = Instance.new("Frame", scroll)
    card.Size = UDim2.new(0.95, 0, 0, 280)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = Color3.fromRGB(80, 80, 120)
    cardStroke.Thickness = 1

    -- Avatar image
    local avatarFrame = Instance.new("Frame", card)
    avatarFrame.Size = UDim2.new(0, 90, 0, 90)
    avatarFrame.Position = UDim2.new(0.5, -45, 0, 15)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
    local avatarStroke = Instance.new("UIStroke", avatarFrame)
    avatarStroke.Color = Color3.fromRGB(100, 100, 255)
    avatarStroke.Thickness = 2

    local avatarImg = Instance.new("ImageLabel", avatarFrame)
    avatarImg.Size = UDim2.new(1, 0, 1, 0)
    avatarImg.BackgroundTransparency = 1
    avatarImg.ScaleType = Enum.ScaleType.Fit
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

    -- Avatar yukle
    pcall(function()
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size150x150
        local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbType, thumbSize)
        avatarImg.Image = content
    end)

    -- Display Name
    local displayLbl = Instance.new("TextLabel", card)
    displayLbl.Size = UDim2.new(1, -20, 0, 26)
    displayLbl.Position = UDim2.new(0, 10, 0, 115)
    displayLbl.BackgroundTransparency = 1
    displayLbl.Font = Enum.Font.GothamBold
    displayLbl.TextSize = 20
    displayLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    displayLbl.Text = LocalPlayer.DisplayName
    displayLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- Username
    local userLbl = Instance.new("TextLabel", card)
    userLbl.Size = UDim2.new(1, -20, 0, 20)
    userLbl.Position = UDim2.new(0, 10, 0, 142)
    userLbl.BackgroundTransparency = 1
    userLbl.Font = Enum.Font.Gotham
    userLbl.TextSize = 14
    userLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
    userLbl.Text = "@" .. LocalPlayer.Name
    userLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- Ayirici cizgi
    local sep = Instance.new("Frame", card)
    sep.Size = UDim2.new(0.85, 0, 0, 1)
    sep.Position = UDim2.new(0.075, 0, 0, 172)
    sep.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sep.BorderSizePixel = 0

    -- Bilgi satirlari
    local function addInfoRow(parent, yPos, label, value)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(0.9, 0, 0, 22)
        row.Position = UDim2.new(0.05, 0, 0, yPos)
        row.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.45, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextColor3 = Color3.fromRGB(140, 140, 160)
        lbl.Text = label
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local val = Instance.new("TextLabel", row)
        val.Size = UDim2.new(0.55, 0, 1, 0)
        val.Position = UDim2.new(0.45, 0, 0, 0)
        val.BackgroundTransparency = 1
        val.Font = Enum.Font.Gotham
        val.TextSize = 13
        val.TextColor3 = Color3.fromRGB(220, 220, 240)
        val.Text = tostring(value)
        val.TextXAlignment = Enum.TextXAlignment.Right

        return val
    end

    addInfoRow(card, 182, "User ID:", LocalPlayer.UserId)
    addInfoRow(card, 206, "Hesap Yasi:", tostring(LocalPlayer.AccountAge) .. " gun")

    local gameNameVal = "Bilinmiyor"
    pcall(function()
        gameNameVal = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    addInfoRow(card, 230, "Oyun:", gameNameVal)
    addInfoRow(card, 254, "Place ID:", game.PlaceId)

    -- Script bilgi karti
    local infoCard = Instance.new("Frame", scroll)
    infoCard.Size = UDim2.new(0.95, 0, 0, 70)
    infoCard.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 10)
    local infoStroke = Instance.new("UIStroke", infoCard)
    infoStroke.Color = Color3.fromRGB(60, 80, 120)
    infoStroke.Thickness = 1

    local scriptLbl = Instance.new("TextLabel", infoCard)
    scriptLbl.Size = UDim2.new(1, -20, 0, 24)
    scriptLbl.Position = UDim2.new(0, 10, 0, 10)
    scriptLbl.BackgroundTransparency = 1
    scriptLbl.Font = Enum.Font.GothamBold
    scriptLbl.TextSize = 16
    scriptLbl.TextColor3 = Color3.fromRGB(100, 180, 255)
    scriptLbl.Text = "NEGRO studio"
    scriptLbl.TextXAlignment = Enum.TextXAlignment.Center

    local creditLbl = Instance.new("TextLabel", infoCard)
    creditLbl.Size = UDim2.new(1, -20, 0, 20)
    creditLbl.Position = UDim2.new(0, 10, 0, 38)
    creditLbl.BackgroundTransparency = 1
    creditLbl.Font = Enum.Font.Gotham
    creditLbl.TextSize = 12
    creditLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
    creditLbl.Text = "powered by ru0n"
    creditLbl.TextXAlignment = Enum.TextXAlignment.Center
end

-- =========================

-- =========================
-- Populate Fly page (controls kept)
-- =========================
do
    local lbl = Instance.new("TextLabel", pageFly)
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.Text = "Fly • H ile aç/kapa"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local flyBtn = Instance.new("TextButton", pageFly)
    flyBtn.Size = UDim2.new(0, 160, 0, 36)
    flyBtn.Position = UDim2.new(0, 0, 0, 40)
    flyBtn.Text = "Fly: Kapalı"
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextSize = 16
    flyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 8)

    local fly2Btn = Instance.new("TextButton", pageFly)
    fly2Btn.Size = UDim2.new(0, 240, 0, 36) -- Wider button
    fly2Btn.Position = UDim2.new(0, 0, 0, 80)
    fly2Btn.Text = "Fly 2 (Anti-Cheat): Kapalı"
    fly2Btn.Font = Enum.Font.GothamBold
    fly2Btn.TextSize = 16
    fly2Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", fly2Btn).CornerRadius = UDim.new(0, 8)

    local noclipBtn = Instance.new("TextButton", pageFly)
    noclipBtn.Size = UDim2.new(0, 140, 0, 36)
    noclipBtn.Position = UDim2.new(0, 250, 0, 40)
    noclipBtn.Text = "Noclip: " .. (noclip and "Açık" or "Kapalı")
    noclipBtn.Font = Enum.Font.GothamBold
    noclipBtn.TextSize = 16
    noclipBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", noclipBtn).CornerRadius = UDim.new(0, 8)

    local flyKeyBtn = mkKeybind(pageFly, "Uçuş Tuşu", flyToggleKey, function(k)
        flyToggleKey = k
    end)
    flyKeyBtn.Position = UDim2.new(0, 0, 0, 120)
    flyKeyBtn.Size = UDim2.new(0, 150, 0, 36)

    local speedLabel = Instance.new("TextLabel", pageFly)
    speedLabel.Position = UDim2.new(0, 0, 0, 160) -- Pushed down
    speedLabel.Size = UDim2.new(0, 220, 0, 24)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 13
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedLabel.Text = "Uçuş Hızı: " .. flySpeed

    local speedBox = Instance.new("TextBox", pageFly)
    speedBox.Position = UDim2.new(0, 0, 0, 190) -- Pushed down
    speedBox.Size = UDim2.new(0, 120, 0, 28)
    speedBox.Text = tostring(flySpeed)
    speedBox.Font = Enum.Font.Gotham
    speedBox.TextSize = 16
    speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    speedBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

    speedBox.FocusLost:Connect(function()
        local v = tonumber(speedBox.Text)
        if v and v > 0 then
            flySpeed = v; speedLabel.Text = "Uçuş Hızı: " .. flySpeed
        else
            speedBox.Text = tostring(flySpeed)
        end
    end)

    flyBtn.MouseButton1Click:Connect(function()
        if flying then
            stopFly()
        else
            flying = true
            showNotify("✈️ FLY: AÇIK")
        end
        flyBtn.Text = "Fly: " .. (flying and "Açık" or "Kapalı")
    end)

    noclipBtn.MouseButton1Click:Connect(function()
        noclip = not noclip
        noclipBtn.Text = "Noclip: " .. (noclip and "Açık" or "Kapalı")
    end)

    fly2Btn.MouseButton1Click:Connect(function()
        if flying2 then
            stopFly2()
        else
            flying2 = true
        end
        fly2Btn.Text = "Fly 2 (Anti-Cheat): " .. (flying2 and "Açık" or "Kapalı")
    end)

    -- Custom hotkey toggle
    UserInputService.InputBegan:Connect(function(input, gp)
        if isAssigningKey then return end
        if input.KeyCode == flyToggleKey then
            if flying2 then
            stopFly2()
        else
            flying2 = true
        end
        fly2Btn.Text = "Fly 2 (Anti-Cheat): " .. (flying2 and "Açık" or "Kapalı")
        end
    end)
end
-- =========================
-- ESP Toggle + Enemy/Team Filter + Charm + Duvar Arkası Renkleri
-- =========================
do
    local scroll = Instance.new("ScrollingFrame", pageESP)
    scroll.Size = UDim2.new(1, 0, 1, -10)
    scroll.Position = UDim2.new(0, 0, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local espToggleBtn = Instance.new("TextButton", scroll)
    espToggleBtn.Size = UDim2.new(0.95, 0, 0, 38)
    espToggleBtn.Text = "ESP: Kapalı"
    espToggleBtn.Font = Enum.Font.GothamBold
    espToggleBtn.TextSize = 16
    espToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", espToggleBtn).CornerRadius = UDim.new(0, 8)

    local enemyFilterBtn = Instance.new("TextButton", scroll)
    enemyFilterBtn.Size = UDim2.new(0.95, 0, 0, 38)
    enemyFilterBtn.Text = "only enemy: Açık"
    enemyFilterBtn.Font = Enum.Font.GothamBold
    enemyFilterBtn.TextSize = 16
    enemyFilterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", enemyFilterBtn).CornerRadius = UDim.new(0, 8)

    local teamFilterBtn = Instance.new("TextButton", scroll)
    teamFilterBtn.Size = UDim2.new(0.95, 0, 0, 38)
    teamFilterBtn.Text = "only team: Kapalı"
    teamFilterBtn.Font = Enum.Font.GothamBold
    teamFilterBtn.TextSize = 16
    teamFilterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", teamFilterBtn).CornerRadius = UDim.new(0, 8)

    local espBoxes = {}

    local function clearESP()
        for _, box in pairs(espBoxes) do box:Destroy() end
        espBoxes = {}
    end

    local function isVisible(part)
        local origin = workspace.CurrentCamera.CFrame.Position
        local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
        local ray = Ray.new(origin, direction)
        local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, { LocalPlayer.Character })
        return hitPart == part or hitPart == nil
    end

    local function updateESP()
        clearESP()
        if not espActive then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isEnemy = plr.Team ~= LocalPlayer.Team
                local isTeam = plr.Team == LocalPlayer.Team
                if (enemyFilter and isEnemy) or (teamFilter and isTeam) then
                    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Adornee = hrp
                        box.Size = Vector3.new(4, 7, 2)
                        box.Transparency = 0.4
                        box.AlwaysOnTop = true
                        box.ZIndex = 10
                        -- Renk: Duvar arkası seçili renk, görünür olduğunda parlak
                        box.Color3 = enemyColor
                        if plr.Team == LocalPlayer.Team then box.Color3 = teamColor end

                        box.Parent = workspace
                        table.insert(espBoxes, box)
                    end
                end
            end
        end
    end

    espToggleBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espToggleBtn.Text = "ESP: " .. (espActive and "Açık" or "Kapalı")
        updateESP()
    end)

    enemyFilterBtn.MouseButton1Click:Connect(function()
        enemyFilter = not enemyFilter
        enemyFilterBtn.Text = "only enemy: " .. (enemyFilter and "Açık" or "Kapalı")
        updateESP()
    end)

    teamFilterBtn.MouseButton1Click:Connect(function()
        teamFilter = not teamFilter
        teamFilterBtn.Text = "only team: " .. (teamFilter and "Açık" or "Kapalı")
        updateESP()
    end)

    mkToggle(scroll, "ESP Isimleri", espNames, function()
        espNames = not espNames; return espNames
    end)
    mkToggle(scroll, "ESP Mesafe", espDistance, function()
        espDistance = not espDistance; return espDistance
    end)

    -- Color Selection UI
    addColorSection(scroll, "Düşman ESP Rengi", enemyColor, function(c)
        enemyColor = c; updateESP()
    end)
    addColorSection(scroll, "Takım ESP Rengi", teamColor, function(c)
        teamColor = c; updateESP()
    end)

    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function() task.wait(0.3) end)
    end)
end

-- =========================
-- Populate Aim page (aimlock)
-- =========================
do
    local scroll = Instance.new("ScrollingFrame", pageAim)
    scroll.Size = UDim2.new(1, 0, 1, -10)
    scroll.Position = UDim2.new(0, 0, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local aimBtn = Instance.new("TextButton", scroll)
    aimBtn.Size = UDim2.new(0, 220, 0, 36)
    aimBtn.Text = "Aimlock: " .. aimModes[aimIndex]
    aimBtn.Font = Enum.Font.GothamBold
    aimBtn.TextSize = 16
    aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(0, 8)

    aimBtn.MouseButton1Click:Connect(function()
        aimIndex = aimIndex % #aimModes + 1
        aimBtn.Text = "Aimlock: " .. aimModes[aimIndex]
    end)

    RunService.RenderStepped:Connect(function()
        if aimIndex ~= 1 then
            local targetHead = getGlobalClosestTarget()
            if targetHead then
                local currentCF = Camera.CFrame
                local targetCF = CFrame.new(currentCF.Position, targetHead.Position)
                Camera.CFrame = currentCF:Lerp(targetCF, 1 / aimSmoothing)
            end
        end
    end)

    mkToggle(scroll, "Aim FOV Goster", showFOV, function()
        showFOV = not showFOV
        if fovFrame then fovFrame.Visible = showFOV end
        return showFOV
    end)

    mkToggle(scroll, "Duvar Kontrol (Wall Check)", wallCheckEnabled, function()
        wallCheckEnabled = not wallCheckEnabled
        return wallCheckEnabled
    end)

    addMoveControl(scroll, "Aim FOV Boyutu", 100, function(v)
        aimFOV = v
        if fovFrame then fovFrame.Size = UDim2.new(0, aimFOV * 2, 0, aimFOV * 2) end
    end)

    addMoveControl(scroll, "Aim FOV Kalınlık", 2, function(v)
        fovThickness = v
        if fovStroke then fovStroke.Thickness = v end
    end)

    local fovColors = {
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255)
    }
    local colorFrame = Instance.new("Frame", scroll)
    colorFrame.Size = UDim2.new(1, 0, 0, 32)
    colorFrame.BackgroundTransparency = 1
    local cGrid = Instance.new("UIGridLayout", colorFrame)
    cGrid.CellSize = UDim2.new(0, 30, 0, 30)
    cGrid.CellPadding = UDim2.new(0, 5, 0, 5)
    cGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

    for _, c in ipairs(fovColors) do
        local b = Instance.new("TextButton", colorFrame)
        b.Text = ""
        b.BackgroundColor3 = c
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(function()
            fovColor = c
            if fovStroke then fovStroke.Color = c end
        end)
    end

    addMoveControl(scroll, "Aim Yumusaklik", 1, function(v) aimSmoothing = v end)

    -- (Removed Hitbox Expander Controls)

    -- NEW FEATURES
    mkToggle(scroll, "🌈 Rainbow Gun", rainbowGunEnabled, function()
        rainbowGunEnabled = not rainbowGunEnabled
        return rainbowGunEnabled
    end)

    mkToggle(scroll, "✨ Neon Rainbow Gun", neonRainbowEnabled, function()
        neonRainbowEnabled = not neonRainbowEnabled
        return neonRainbowEnabled
    end)
end

-- =========================
-- TriggerBot page
-- =========================
do
    local lbl = Instance.new("TextLabel", pageTrigger)
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.Text = "TriggerBot"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local trigBtn = Instance.new("TextButton", pageTrigger)
    trigBtn.Size = UDim2.new(0, 220, 0, 36)
    trigBtn.Position = UDim2.new(0, 0, 0, 40)
    trigBtn.Text = "TriggerBot: Kapalı"
    trigBtn.Font = Enum.Font.GothamBold
    trigBtn.TextSize = 16
    trigBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", trigBtn).CornerRadius = UDim.new(0, 8)

    local trigModeBtn = Instance.new("TextButton", pageTrigger)
    trigModeBtn.Size = UDim2.new(0, 220, 0, 36)
    trigModeBtn.Position = UDim2.new(0, 0, 0, 80)
    trigModeBtn.Text = "Hedef: " .. triggerModes[triggerIndex]
    trigModeBtn.Font = Enum.Font.GothamBold
    trigModeBtn.TextSize = 16
    trigModeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", trigModeBtn).CornerRadius = UDim.new(0, 8)

    trigBtn.MouseButton1Click:Connect(function()
        triggerEnabled = not triggerEnabled
        trigBtn.Text = "TriggerBot: " .. (triggerEnabled and "Açık" or "Kapalı")
    end)

    trigModeBtn.MouseButton1Click:Connect(function()
        triggerIndex = triggerIndex % #triggerModes + 1
        trigModeBtn.Text = "Hedef: " .. triggerModes[triggerIndex]
    end)

    mkSlider(pageTrigger, "Trigger Hızı (CPS)", 1, 200, triggerCPS, function(v)
        triggerCPS = v
    end)

    task.spawn(function()
        while true do
            if triggerEnabled then
                local targetPart = Mouse.Target
                local char = targetPart and targetPart.Parent
                local hum = char and char:FindFirstChild('Humanoid')
                local valid = false
                if hum and hum.Health > 0 then
                    local player = Players:GetPlayerFromCharacter(char)
                    if player then
                        if triggerIndex == 1 then
                            if player.Team ~= LocalPlayer.Team then valid = true end
                        else
                            valid = true
                        end
                    else
                        valid = true
                    end
                end

                if valid then
                    -- High CPS logic
                    local clicksPerLoop = math.clamp(math.ceil(triggerCPS / 60), 1, 10)
                    for i = 1, clicksPerLoop do
                        if HoldClick then
                            if not CurrentlyPressed then
                                CurrentlyPressed = true
                                safe_mouse1press()
                            end
                            safe_mouse1release()
                            CurrentlyPressed = false
                        else
                            safe_mouse1click()
                        end
                    end
                end
            end
            task.wait(1 / 60)
        end
    end)
end

-- =========================
-- World page (lighting quick choices)
-- =========================
do
    local lbl = Instance.new("TextLabel", pageWorld)
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.Text = "World / Lighting"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local scroll = Instance.new("ScrollingFrame", pageWorld)
    scroll.Size = UDim2.new(1, 0, 1, -40)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    -- Main List Layout for the page
    local listLayout = Instance.new("UIListLayout", scroll)
    listLayout.Padding = UDim.new(0, 12)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 5)

    -- CONTAINER FOR COLOR GRID
    local colorContainer = Instance.new("Frame", scroll)
    colorContainer.Size = UDim2.new(1, -10, 0, 150) -- Adjusted height to fit grid
    colorContainer.BackgroundTransparency = 1
    colorContainer.LayoutOrder = 1

    local grid = Instance.new("UIGridLayout", colorContainer)
    grid.CellSize = UDim2.new(0, 105, 0, 34)
    grid.CellPadding = UDim2.new(0, 8, 0, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local colors = {
        { Name = "Mavi",    Col = Color3.fromRGB(0, 120, 255) },
        { Name = "Kırmızı", Col = Color3.fromRGB(255, 60, 60) },
        { Name = "Yeşil",   Col = Color3.fromRGB(60, 255, 100) },
        { Name = "Turuncu", Col = Color3.fromRGB(255, 120, 0) },
        { Name = "Mor",     Col = Color3.fromRGB(180, 0, 255) },
        { Name = "Pembe",   Col = Color3.fromRGB(255, 100, 200) },
        { Name = "Sarı",    Col = Color3.fromRGB(255, 255, 0) },
        { Name = "Turkuaz", Col = Color3.fromRGB(0, 255, 255) },
        { Name = "Beyaz",   Col = Color3.fromRGB(255, 255, 255) },
        { Name = "Siyah",   Col = Color3.fromRGB(0, 0, 0) },
    }

    for _, data in ipairs(colors) do
        local btn = Instance.new("TextButton", colorContainer)
        btn.Text = data.Name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        btn.MouseButton1Click:Connect(function()
            Lighting.Ambient = data.Col
            Lighting.OutdoorAmbient = data.Col
            Lighting.ColorShift_Top = data.Col
            Lighting.ColorShift_Bottom = data.Col
        end)
    end

    -- OTHER CONTROLS (Vertical Stack)

    -- FPS Boost (Optimized)
    mkToggle(scroll, "FPS Boost (Doku Sil)", false, function()
        task.spawn(function()
            local count = 0
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("Texture") or v:IsA("Decal") then
                    v:Destroy()
                end
                count = count + 1
                if count % 500 == 0 then task.wait() end -- Prevent crash
            end
            showNotify("FPS Boost Tamamlandı")
        end)
        return true
    end)

    -- (Removed FOV and Rainbow Gun from World Menu)

    -- Skybox Control Section
    local skyFrame = Instance.new("Frame", scroll)
    skyFrame.Size = UDim2.new(1, -10, 0, 65)
    skyFrame.BackgroundTransparency = 1
    skyFrame.LayoutOrder = 10

    local skyLb = Instance.new("TextLabel", skyFrame)
    skyLb.Size = UDim2.new(1, 0, 0, 24)
    skyLb.Text = "Custom Skybox (Image ID)"
    skyLb.TextColor3 = Color3.fromRGB(200, 200, 200)
    skyLb.BackgroundTransparency = 1
    skyLb.Font = Enum.Font.GothamBold
    skyLb.TextSize = 14
    skyLb.TextXAlignment = Enum.TextXAlignment.Left

    local skyBox = Instance.new("TextBox", skyFrame)
    skyBox.Size = UDim2.new(1, 0, 0, 36)
    skyBox.Position = UDim2.new(0, 0, 0, 26)
    skyBox.PlaceholderText = "Resim ID girin..."
    skyBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    skyBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    skyBox.Font = Enum.Font.Gotham
    skyBox.TextSize = 14
    Instance.new("UICorner", skyBox).CornerRadius = UDim.new(0, 6)

    skyBox.FocusLost:Connect(function()
        local text = skyBox.Text
        local id = text
        if text ~= "" then
            task.spawn(function()
                -- Check for Base64 Data URI
                if text:find("data:image") and text:find("base64") then
                    local success, err = pcall(function()
                        local data = text:match("base64,(.+)")
                        if not data then return end

                        -- Attempt to find a base64 decoder in common executor environments
                        local decode = nil
                        if typeof(crypt) == "table" and crypt.base64decode then
                            decode = crypt.base64decode
                        elseif typeof(crypt) == "table" and crypt.base64 and crypt.base64.decode then
                            decode = crypt.base64.decode
                        elseif typeof(base64) == "table" and base64.decode then
                            decode = base64.decode
                        end

                        -- If no decoder found, try standard 'DEC_B64' or similar if defined, else warn
                        if not decode then
                            showNotify("Base64 Decoder bulunamadı (Executor desteklemiyor)")
                            return
                        end

                        local raw = decode(data)
                        local fname = "ruon_sky_temp.jpg" -- default to jpg
                        if text:find("image/png") then fname = "ruon_sky_temp.png" end

                        if writefile and getcustomasset then
                            writefile(fname, raw)
                            id = getcustomasset(fname)
                        else
                            showNotify("writefile/getcustomasset bulunamadı")
                        end
                    end)
                elseif tonumber(text) then
                    id = "rbxassetid://" .. text
                end

                local s = Lighting:FindFirstChildOfClass("Sky")
                if not s then
                    s = Instance.new("Sky", Lighting)
                end
                s.SkyboxBk = id
                s.SkyboxDn = id
                s.SkyboxFt = id
                s.SkyboxLf = id
                s.SkyboxRt = id
                s.SkyboxUp = id
                showNotify("Skybox Güncellendi!")
            end)
        end
    end)

    -- (Removed Atmosphere Presets)

    local fbEnabled = false
    mkToggle(scroll, "💡 Fullbright", false, function()
        fbEnabled = not fbEnabled
        if fbEnabled then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
        else
            Lighting.Ambient = Color3.fromRGB(150, 150, 150)
            Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
        end
        return fbEnabled
    end)

    -- (Removed Gravity from World Menu)

    local camLbl = Instance.new("TextLabel", scroll)
    camLbl.Size = UDim2.new(1, 0, 0, 28)
    camLbl.BackgroundTransparency = 1
    camLbl.Font = Enum.Font.GothamBold
    camLbl.TextSize = 14
    camLbl.Text = "📷 Kamera Ayarları"
    camLbl.TextColor3 = Color3.fromRGB(200, 200, 200)

    mkToggle(scroll, "♾️ Sınırsız Zoom (O Tuşu)", infZoomEnabled, function()
        infZoomEnabled = not infZoomEnabled
        if not infZoomEnabled then
            LocalPlayer.CameraMaxZoomDistance = 400
        end
        return infZoomEnabled
    end)

    addMoveControl(scroll, "🔍 Max Zoom Mesafesi", maxZoomValue, function(v)
        maxZoomValue = v
    end)

    addMoveControl(scroll, "👁️ Kamera FOV", cameraFOV, function(v)
        cameraFOV = v
    end)
end

-- =========================
-- Misc page (rainbow toggle, player list teleport)
-- =========================
do
    local lbl = Instance.new("TextLabel", pageMisc)
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.Text = "Misc / Diğer"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local scroll = Instance.new("ScrollingFrame", pageMisc)
    scroll.Size = UDim2.new(1, 0, 1, -40)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local listLayout = Instance.new("UIListLayout", scroll)
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 5)

    local rainbowBtn = Instance.new("TextButton", scroll)
    rainbowBtn.Size = UDim2.new(0.95, 0, 0, 36)
    rainbowBtn.Text = "Rainbow GUI: Kapalı"
    rainbowBtn.Font = Enum.Font.Gotham
    rainbowBtn.TextSize = 16
    rainbowBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", rainbowBtn).CornerRadius = UDim.new(0, 8)

    rainbowBtn.MouseButton1Click:Connect(function()
        rainbowEnabled = not rainbowEnabled
        rainbowBtn.Text = "Rainbow GUI: " .. (rainbowEnabled and "Açık" or "Kapalı")
        if not rainbowEnabled then
            main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        end
    end)

    mkToggle(scroll, "🖱️ Click TP (Ctrl+LClick)", clickTP, function()
        clickTP = not clickTP; return clickTP
    end)

    -- (Removed Auto Clicker UI)

    mkToggle(scroll, "🌟 Free VIP", freeVipEnabled, function()
        freeVipEnabled = not freeVipEnabled
        if freeVipEnabled then
            pcall(function()
                LocalPlayer.MembershipType = Enum.MembershipType.Premium
            end)
            showNotify("Free VIP Aktif edildi!")
        else
            pcall(function()
                LocalPlayer.MembershipType = Enum.MembershipType.None
            end)
            showNotify("Free VIP Kapatıldı")
        end
        return freeVipEnabled
    end)

    mkToggle(scroll, "⚡ Instant Prompt (Hızlı Al)", instantPromptEnabled, function()
        instantPromptEnabled = not instantPromptEnabled
        if instantPromptEnabled then
            showNotify("Hızlı Toplama Aktif!")
        else
            showNotify("Hızlı Toplama Kapatıldı")
        end
        return instantPromptEnabled
    end)

    -- FLING THINGS & PEOPLE GÜÇLENDIRICISI
    local flingLabel = Instance.new("TextLabel", scroll)
    flingLabel.Size = UDim2.new(0.95, 0, 0, 28)
    flingLabel.BackgroundTransparency = 1
    flingLabel.Text = "  Fling Things & People"
    flingLabel.TextColor3 = Color3.fromRGB(255, 140, 50)
    flingLabel.Font = Enum.Font.GothamBold
    flingLabel.TextSize = 14
    flingLabel.TextXAlignment = Enum.TextXAlignment.Left

    local flingBoostEnabled = false
    local flingBoostMult = 10

    mkToggle(scroll, "Fling Güç Artir", false, function()
        flingBoostEnabled = not flingBoostEnabled
        showNotify(flingBoostEnabled and ("Fling Guc: x" .. flingBoostMult .. " AKTIF!") or "Fling Guc Kapatildi")
        return flingBoostEnabled
    end)

    mkSlider(scroll, "Fling Guc Carpani", 1, 100, flingBoostMult, function(v)
        flingBoostMult = v
    end)

    -- FLING BOOST RUNTIME (3 katmanli, garantili)
    task.spawn(function()
        -- Yardimci: herhangi bir Part icin HRP bul
        local function findHRP(part)
            if not part then return nil end
            local m = part.Parent
            if not m then return nil end
            -- Direkt model
            local h = m:FindFirstChild("HumanoidRootPart")
            if h then return h end
            -- 1 ust model
            if m.Parent then
                h = m.Parent:FindFirstChild("HumanoidRootPart")
                if h then return h end
            end
            return nil
        end

        -- Yardimci: BasePart'a guc uygula (BodyVelocity + LinearVelocity)
        local function applyForce(part, velocity)
            if not part or not part:IsA("BasePart") then return end
            pcall(function()
                -- Modern API (yeni Roblox)
                local lv = part:FindFirstChildOfClass("LinearVelocity")
                if not lv then
                    lv = Instance.new("LinearVelocity")
                    lv.Attachment0 = part:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", part)
                    lv.MaxForce = math.huge
                    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
                    lv.Parent = part
                end
                lv.VectorVelocity = velocity
                -- Eski API (daha iyi replike edilir)
                local bv = part:FindFirstChildWhichIsA("BodyVelocity")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Parent = part
                end
                bv.Velocity = velocity
                part.AssemblyLinearVelocity = velocity
            end)
            -- 0.15 sn sonra temizle (sadece 1 ani patlama istiyoruz)
            task.delay(0.15, function()
                pcall(function()
                    local bv = part:FindFirstChildWhichIsA("BodyVelocity")
                    if bv then bv:Destroy() end
                    local lv2 = part:FindFirstChildOfClass("LinearVelocity")
                    if lv2 then lv2:Destroy() end
                end)
            end)
        end

        -- FE Fling: kendi HRP'yi hedefin icine CFrame'le → fizik carpisma flirlatiyor
        local function feFling(myHRP, targetHRP, power)
            if not myHRP or not targetHRP then return end
            local savedCF = myHRP.CFrame
            -- Cok kisa sure hedefin tam icine gir
            pcall(function() myHRP.CFrame = targetHRP.CFrame end)
            task.wait()
            pcall(function() myHRP.CFrame = savedCF end)
        end

        -- Sol tik basili tutulunca her 0.1 saniyede fling uygula
        while true do
            task.wait(0.1)
            if not flingBoostEnabled then continue end
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then continue end

            local char = LocalPlayer.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end

            local target = Mouse.Target
            if not target then continue end

            local targetHRP = findHRP(target)
            local power = flingBoostMult * 120

            if targetHRP then
                -- Oyuncuya guc uygula
                local dir = (targetHRP.Position - myHRP.Position).Unit
                local vel = dir * power + Vector3.new(0, flingBoostMult * 30, 0)
                applyForce(targetHRP, vel)
                -- FE fling de ekle (double hit)
                task.spawn(function() feFling(myHRP, targetHRP, power) end)
            elseif target:IsA("BasePart") and not target.Anchored then
                -- Nesne fling
                local dir = (target.Position - myHRP.Position).Unit
                applyForce(target, dir * power * 0.8 + Vector3.new(0, flingBoostMult * 20, 0))
            end
        end
    end)
end

-- Brook Haven Page Logic Removed

-- =========================
-- Movement Page
-- =========================
do
    local lbl = Instance.new("TextLabel", pageMovement)
    lbl.Size = UDim2.new(1, 0, 0, 32)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.Text = "Movement Controls"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local scroll = Instance.new("ScrollingFrame", pageMovement)
    scroll.Size = UDim2.new(1, 0, 1, -40)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)


    addMoveControl(scroll, "Yürüme Hızı", 16, function(v)
        targetWalkSpeed = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end)

    addMoveControl(scroll, "Zıplama Gücü", 50, function(v)
        targetJumpPower = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = v
            LocalPlayer.Character.Humanoid.UseJumpPower = true
        end
    end)

    mkToggle(scroll, "Anti-Ragdoll", antiRagdoll, function()
        antiRagdoll = not antiRagdoll; return antiRagdoll
    end)
    mkToggle(scroll, "BunnyHop", bunnyHop, function()
        bunnyHop = not bunnyHop; return bunnyHop
    end)

    addMoveControl(scroll, "Yerçekimi", workspace.Gravity, function(v)
        workspace.Gravity = v
    end)

    mkToggle(scroll, "Reach (Menzil Uzatma)", reachEnabled, function()
        reachEnabled = not reachEnabled
        return reachEnabled
    end)

    mkSlider(scroll, "Reach Mesafesi", 1, 100, reachValue, function(v)
        reachValue = v
    end)

    local infJumpBtn = Instance.new("TextButton", scroll)
    infJumpBtn.Size = UDim2.new(1, -10, 0, 36)
    infJumpBtn.Text = "Sonsuz Zıplama: Kapalı"
    infJumpBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    infJumpBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    infJumpBtn.Font = Enum.Font.GothamBold
    infJumpBtn.TextSize = 15
    Instance.new("UICorner", infJumpBtn).CornerRadius = UDim.new(0, 6)

    infJumpBtn.MouseButton1Click:Connect(function()
        infiniteJump = not infiniteJump
        infJumpBtn.Text = "Sonsuz Zıplama: " .. (infiniteJump and "Açık" or "Kapalı")
    end)

    mkToggle(scroll, "⚡ CFrame Speed", cframeSpeedEnabled, function()
        cframeSpeedEnabled = not cframeSpeedEnabled
        return cframeSpeedEnabled
    end)

    addMoveControl(scroll, "Hız Çarpanı", 1, function(v)
        cframeSpeedValue = v
    end)

    mkToggle(scroll, "Fare Kilidi Aç/Kapa", false, function()
        mouseUnlockEnabled = not mouseUnlockEnabled
        if not mouseUnlockEnabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
        return mouseUnlockEnabled
    end)

    mkKeybind(scroll, "Kilit Açma Tuşu", mouseUnlockKey, function(k)
        mouseUnlockKey = k
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if isAssigningKey then return end
        if input.KeyCode == mouseUnlockKey or input.KeyCode == Enum.KeyCode.RightControl then
            mouseUnlockEnabled = not mouseUnlockEnabled
            mouseModalBtn.Modal = mouseUnlockEnabled

            if mouseUnlockEnabled then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                showNotify("Fare Serbest (Mouse Unlocked)")
            else
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                showNotify("Fare Kilitlendi (Mouse Locked)")
            end
        end
    end)

    -- Persistent loop to prevent game from re-locking mouse
    task.spawn(function()
        while true do
            task.wait(0.1)
            if mouseUnlockEnabled then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            end
        end
    end)
end

-- =========================
-- Teleport Page
-- =========================
do
    local lbl = Instance.new("TextLabel", pageTeleport)
    lbl.Size = UDim2.new(1, 0, 0, 32)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.Text = "Player Teleport"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local scroll = Instance.new("ScrollingFrame", pageTeleport)
    scroll.Size = UDim2.new(1, 0, 1, -45)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function updateList()
        for _, child in pairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local frame = Instance.new("Frame", scroll)
                frame.Size = UDim2.new(0.95, 0, 0, 40)
                frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

                local nameLabel = Instance.new("TextLabel", frame)
                nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
                nameLabel.Position = UDim2.new(0.05, 0, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = plr.Name
                nameLabel.TextColor3 = plr.TeamColor.Color
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 14
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left

                local tpBtn = Instance.new("TextButton", frame)
                tpBtn.Size = UDim2.new(0, 55, 0, 28)
                tpBtn.Position = UDim2.new(1, -60, 0.5, -14)
                tpBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                tpBtn.Text = "TP 📍"
                tpBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.TextSize = 10
                Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

                local spectateBtn = Instance.new("TextButton", frame)
                spectateBtn.Size = UDim2.new(0, 55, 0, 28)
                spectateBtn.Position = UDim2.new(1, -120, 0.5, -14)
                spectateBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                spectateBtn.Text = "İzle 👁️"
                spectateBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
                spectateBtn.Font = Enum.Font.GothamBold
                spectateBtn.TextSize = 10
                Instance.new("UICorner", spectateBtn).CornerRadius = UDim.new(0, 6)

                local targetBtn = Instance.new("TextButton", frame)
                targetBtn.Size = UDim2.new(0, 55, 0, 28)
                targetBtn.Position = UDim2.new(1, -180, 0.5, -14)
                targetBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                targetBtn.Text = "Target 🎯"
                targetBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
                targetBtn.Font = Enum.Font.GothamBold
                targetBtn.TextSize = 10
                Instance.new("UICorner", targetBtn).CornerRadius = UDim.new(0, 6)

                Instance.new("UICorner", targetBtn).CornerRadius = UDim.new(0, 6)
                -- bangBtn removed from teleport page

                tpBtn.MouseButton1Click:Connect(function()
                    local char = LocalPlayer.Character
                    local targetChar = plr.Character
                    if char and targetChar then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
                        if hrp and targetHrp then
                            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 3, 0)
                            showNotify(plr.Name .. " Kişisine Işınlanıldı!")
                        end
                    end
                end)

                spectateBtn.MouseButton1Click:Connect(function()
                    if spectateTarget == plr then
                        spectateTarget = nil
                        Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
                        spectateBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                        showNotify("İzleme Kapatıldı")
                    else
                        spectateTarget = plr
                        local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
                        if hum then
                            Camera.CameraSubject = hum
                            spectateBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                            showNotify(plr.Name .. " İzleniyor! 👁️")
                        end
                    end
                end)

                targetBtn.MouseButton1Click:Connect(function()
                    if targetPlayer == plr then
                        targetPlayer = nil
                        showNotify(plr.Name .. " Takip Ediliyor!")
                    end
                end)
                -- bangBtn logic removed
            end
        end
    end

    Players.PlayerAdded:Connect(updateList)
    Players.PlayerRemoving:Connect(updateList)
    updateList() -- Initial population
end

-- =========================
-- Themes Page
-- =========================
do
    local lbl = Instance.new("TextLabel", pageThemes)
    lbl.Size = UDim2.new(1, 0, 0, 32)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.Text = "Theme Changer"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local themes = {
        { Name = "Karanlık",    Main = Color3.fromRGB(25, 25, 25),    Left = Color3.fromRGB(18, 18, 20),    Stroke = Color3.fromRGB(90, 90, 110) },
        { Name = "Aydınlık",    Main = Color3.fromRGB(240, 240, 240), Left = Color3.fromRGB(220, 220, 225), Stroke = Color3.fromRGB(150, 150, 160), Text = Color3.fromRGB(20, 20, 30) },
        { Name = "Okyanus",     Main = Color3.fromRGB(10, 30, 50),    Left = Color3.fromRGB(5, 20, 40),     Stroke = Color3.fromRGB(0, 100, 200) },
        { Name = "Yakut",       Main = Color3.fromRGB(40, 10, 10),    Left = Color3.fromRGB(30, 5, 5),      Stroke = Color3.fromRGB(200, 0, 0) },
        { Name = "Orman",       Main = Color3.fromRGB(10, 30, 15),    Left = Color3.fromRGB(5, 25, 10),     Stroke = Color3.fromRGB(0, 150, 50) },
        { Name = "Gece Yarısı", Main = Color3.fromRGB(5, 5, 10),      Left = Color3.fromRGB(2, 2, 5),       Stroke = Color3.fromRGB(60, 60, 80) }
    }

    local grid = Instance.new("UIGridLayout", pageThemes)
    grid.CellSize = UDim2.new(0, 130, 0, 40)
    grid.CellPadding = UDim2.new(0, 10, 0, 10)

    local pad = Instance.new("UIPadding", pageThemes)
    pad.PaddingTop = UDim.new(0, 50)

    for _, t in ipairs(themes) do
        local b = Instance.new("TextButton", pageThemes)
        b.Text = t.Name
        b.BackgroundColor3 = t.Main
        b.TextColor3 = t.Text or Color3.fromRGB(240, 240, 240)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 16
        local corn = Instance.new("UICorner", b); corn.CornerRadius = UDim.new(0, 8)
        local str = Instance.new("UIStroke", b); str.Color = t.Stroke; str.Thickness = 1

        b.MouseButton1Click:Connect(function()
            main.BackgroundColor3 = t.Main
            left.BackgroundColor3 = t.Left
            mainStroke.Color = t.Stroke
            subtitle.TextColor3 = t.Text or Color3.fromRGB(190, 190, 200)
            title.TextColor3 = t.Text or Color3.fromRGB(240, 240, 240)
        end)
    end
end
-- =========================
-- Global listeners
-- =========================
UserInputService.JumpRequest:Connect(function()
    if infiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Players.LocalPlayer.CharacterAdded:Connect(function(char)
    if godModeEnabled then
        task.wait(0.5)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Name = "1"
            local cl = hum:Clone()
            cl.Name = "Humanoid"
            cl.Parent = char
        end
    end
end)

-- Optimized Free VIP & Purchase Blocker
task.spawn(function()
    local StarterGui = game:GetService("StarterGui")
    local CoreGui = game:GetService("CoreGui")
    local GuiService = game:GetService("GuiService")
    local mps = game:GetService("MarketplaceService")

    -- Robust Hooking & Method Overriding
    local function applyHooks()
        pcall(function()
            -- hookfunction (Advanced executors)
            local methods = { "PromptGamePassPurchase", "PromptProductPurchase", "PromptPurchase", "PromptBundlePurchase",
                "PromptPremiumPurchase" }
            for _, method in ipairs(methods) do
                local old; old = hookfunction(mps[method], function(self, ...)
                    if freeVipEnabled then return end
                    return old(self, ...)
                end)
            end
            -- hookmetamethod (Catch __namecall)
            local oldNC; oldNC = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if self == mps and freeVipEnabled and method:find("Prompt") then return end
                return oldNC(self, ...)
            end)
        end)
        -- Standard Overriding (Fallback for simple executors)
        pcall(function()
            local oldGP = mps.PromptGamePassPurchase
            mps.PromptGamePassPurchase = function(self, ...)
                if freeVipEnabled then return end
                return oldGP(self, ...)
            end
            local oldPP = mps.PromptProductPurchase
            mps.PromptProductPurchase = function(self, ...)
                if freeVipEnabled then return end
                return oldPP(self, ...)
            end
            local oldP = mps.PromptPurchase
            mps.PromptPurchase = function(self, ...)
                if freeVipEnabled then return end
                return oldP(self, ...)
            end
        end)
    end
    applyHooks()

    -- Real-time UI Blocking & Prompt Auto-Close (Nuclear Mode)
    local function nuclearKill()
        if not freeVipEnabled then return end
        pcall(function()
            StarterGui:SetCore("PurchasePromptGuiEnabled", false)
            -- Search ALL CoreGui and PlayerGui descendants for any purchase-related UI
            local targets = { CoreGui, LocalPlayer.PlayerGui }
            for _, p in ipairs(targets) do
                for _, v in ipairs(p:GetDescendants()) do
                    if v:IsA("GuiObject") and v.Visible then
                        local n = v.Name:lower()
                        if n:find("purchaseprompt") or n:find("productpurchase") or n:find("premiummodal") then
                            v.Visible = false
                            if v:IsA("Frame") or v:IsA("CanvasGroup") then v:Destroy() end
                        end
                    end
                end
            end
        end)
    end

    RunService.Heartbeat:Connect(nuclearKill)

    -- VIP Gate Bypass (Physical & Interaction)
    while true do
        if freeVipEnabled then
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local name = obj.Name:lower()
                        if name:find("vip") or name:find("premium") or name:find("gamepass") or name:find("door") then
                            -- Bypass Physical (Nuclear: Size 0 + Move)
                            obj.CanCollide = false
                            obj.Transparency = 0.5
                            obj.Size = Vector3.new(0, 0, 0)                  -- Zero size stops all triggers
                            obj.CFrame = obj.CFrame * CFrame.new(0, 1000, 0) -- Move it up locally

                            -- Disable Touched connections
                            if getconnections then
                                for _, con in ipairs(getconnections(obj.Touched)) do
                                    con:Disable()
                                end
                            end

                            -- Remove ALL interactive prompts (Touch, Click, Proximity)
                            for _, v in ipairs(obj:GetDescendants()) do
                                if v:IsA("TouchTransmitter") or v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then
                                    v:Destroy()
                                end
                            end
                            -- Catch top-level interests
                            local t = obj:FindFirstChildWhichIsA("TouchTransmitter") or
                                obj:FindFirstChild("TouchInterest")
                            if t then t:Destroy() end
                        end
                    end
                end
            end)
        else
            pcall(function() StarterGui:SetCore("PurchasePromptGuiEnabled", true) end)
        end
        task.wait(5)
    end
end)

-- Instant Proximity Prompt Logic
task.spawn(function()
    local function makeInstant(prompt)
        if prompt:IsA("ProximityPrompt") then
            if instantPromptEnabled then
                prompt.HoldDuration = 0
            end
        end
    end

    workspace.DescendantAdded:Connect(makeInstant)

    while true do
        if instantPromptEnabled then
            pcall(function()
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then
                        v.HoldDuration = 0
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- Follow & Animations Logic
task.spawn(function()
    local savedC0 = nil
    local currentJoint = nil

    local function getRightShoulder(char)
        if not char then return nil end
        -- R6
        local torso = char:FindFirstChild("Torso")
        if torso and torso:FindFirstChild("Right Shoulder") then
            return torso["Right Shoulder"]
        end
        -- R15
        local rua = char:FindFirstChild("RightUpperArm")
        if rua and rua:FindFirstChild("RightShoulder") then
            return rua["RightShoulder"]
        end
        return nil
    end

    local function getTorsoJoint(char)
        if not char then return nil end
        -- R6: No waist joint, use Shoulder
        -- R15: Waist
        local ut = char:FindFirstChild("UpperTorso")
        if ut and ut:FindFirstChild("Waist") then
            return ut["Waist"]
        end
        return nil
    end

    local function getNeckJoint(char)
        if not char then return nil end
        -- R6: Torso -> Neck
        -- R15: Head -> Neck
        local head = char:FindFirstChild("Head")
        if head and head:FindFirstChild("Neck") then
            return head["Neck"]
        end
        local torso = char:FindFirstChild("Torso")
        if torso and torso:FindFirstChild("Neck") then
            return torso["Neck"]
        end
        return nil
    end

    local function getRootJoint(char)
        if not char then return nil end
        -- R6
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if rootPart and rootPart:FindFirstChild("RootJoint") then
            return rootPart["RootJoint"]
        end
        -- R15
        local lowerTorso = char:FindFirstChild("LowerTorso")
        if lowerTorso and lowerTorso:FindFirstChild("Root") then
            return lowerTorso["Root"]
        end
        return nil
    end

    -- Follow & Bang Positioning Logic (Heartbeat)
    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hrp and targetPlayer and targetPlayer.Character) then return end

        local targetChar = targetPlayer.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return end

        if isFollowing or isBanging then
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        elseif isFollowing then
            -- STANDALONE FOLLOW POSITIONING
            local targetPos = targetHrp.CFrame * CFrame.new(0, -0.7, 1.1)
            hrp.CFrame = targetPos
        end
    end)

    -- Hitbox Expander Loop (Heartbeat)
    RunService.Heartbeat:Connect(function()
        if hitboxEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        hrp.Transparency = 0.7
                        hrp.CanCollide = false -- Prevent physics issues with huge hitboxes
                    end
                end
            end
        end
    end)

    -- Animation & Replication Logic (Stepped - Happens before replication)
    local savedRootC0 = nil
    local currentRootJoint = nil

    local savedWaistC0 = nil
    local currentWaistJoint = nil

    local savedNeckC0 = nil
    local currentNeckJoint = nil

    RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end


        -- "Intense Pleasure" Bang Animation Logic
        local rootJoint = getRootJoint(char)
        local waistJoint = getTorsoJoint(char)
        local neckJoint = getNeckJoint(char)

        -- Use global speed if updated via slider, else default
        local speed = _G.BangSpeed or 30

        -- Simplified Animation Logic (No Bang)
    end)
end)


-- =========================
-- Shared runtime: Fly movement, noclip, rainbow background, aim/esp updates
-- =========================
-- Reuse parts of original RenderStepped logic
RunService.RenderStepped:Connect(function()
    -- Movement Persistence
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        if hum.WalkSpeed ~= targetWalkSpeed then hum.WalkSpeed = targetWalkSpeed end
        if hum.JumpPower ~= targetJumpPower then
            hum.JumpPower = targetJumpPower
            hum.UseJumpPower = true
        end
    end

    -- Camera Persistence
    if infZoomEnabled then
        LocalPlayer.CameraMaxZoomDistance = maxZoomValue
    end
    if Camera.FieldOfView ~= cameraFOV then
        Camera.FieldOfView = cameraFOV
    end

    -- rainbow gui background (if enabled)
    -- Removed as requested

    -- Rainbow Gun Logic
    if rainbowGunEnabled or neonRainbowEnabled then
        local hue = (tick() * 0.5) % 1
        local color = Color3.fromHSV(hue, 0.8, 1)
        local mat = neonRainbowEnabled and Enum.Material.Neon or nil

        -- Target: Character items (Tools)
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.Parent:IsA("Tool") then
                    v.Color = color
                    if mat then v.Material = mat end
                end
            end
        end

        -- Target: Camera items (Viewmodels in Arsenal/FPS)
        for _, v in ipairs(Camera:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Color = color
                if mat then v.Material = mat end
            end
        end
    end

    -- flying (Fly 1)
    if flying then
        if not BV or not BG then
            pcall(function()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    BV = Instance.new("BodyVelocity")
                    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    BV.Velocity = Vector3.new(0, 0, 0)
                    BV.Parent = hrp
                    BG = Instance.new("BodyGyro")
                    BG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    BG.CFrame = hrp.CFrame
                    BG.Parent = hrp
                    if hum then hum.PlatformStand = true end
                end
            end)
        end

        if BV and BG then
            local move = Vector3.zero
            local look = Camera.CFrame.LookVector
            local right = Camera.CFrame.RightVector
            local isTyping = UserInputService:GetFocusedTextBox() ~= nil

            if not isTyping then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + look end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - look end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileUp then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or mobileDown then
                    move = move -
                        Vector3.new(0, 1, 0)
                end
            end

            local s = flySpeed
            if not isTyping and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then s = s * 2 end
            if move.Magnitude > 0 then BV.Velocity = move.Unit * s else BV.Velocity = Vector3.zero end

            -- FPS Compatibility: Keep upright, face horizontal look direction
            local look = Camera.CFrame.LookVector
            BG.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(look.X, 0, look.Z))
        end
    end

    -- advanced flying (Fly 2)
    if flying2 then
        if not BV2 or not BG2 then
            pcall(function()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    BV2 = Instance.new("BodyVelocity")
                    BV2.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    BV2.Velocity = Vector3.new(0, 0, 0)
                    BV2.Parent = hrp
                    BG2 = Instance.new("BodyGyro")
                    BG2.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    BG2.CFrame = hrp.CFrame
                    BG2.Parent = hrp
                    if hum then
                        hum.PlatformStand = false
                        hum:ChangeState(Enum.HumanoidStateType.Physics)
                    end
                end
            end)
        end

        if BV2 and BG2 then
            local move = Vector3.zero
            local look = Camera.CFrame.LookVector
            local right = Camera.CFrame.RightVector
            local isTyping = UserInputService:GetFocusedTextBox() ~= nil

            if not isTyping then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + look end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - look end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileUp then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or mobileDown then
                    move = move -
                        Vector3.new(0, 1, 0)
                end
            end

            local s = flySpeed * 2 -- Admin fly is usually faster
            if not isTyping and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then s = s * 2 end
            if move.Magnitude > 0 then BV2.Velocity = move.Unit * s else BV2.Velocity = Vector3.zero end

            -- Admin Fly: Character tilts with camera exactly
            BG2.CFrame = Camera.CFrame
        end
    end

    -- Reach Logic
    if reachEnabled then
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("BasePart") and (v.Name == "Handle" or v:IsA("MeshPart")) then
                    if not v:GetAttribute("OriginalSize") then
                        v:SetAttribute("OriginalSize", v.Size)
                    end
                    v.Size = Vector3.new(reachValue, reachValue, reachValue)
                    v.Massless = true
                    v.CanCollide = false

                    local sb = v:FindFirstChild("RuonReachVis")
                    if not sb then
                        sb = Instance.new("SelectionBox", v)
                        sb.Name = "RuonReachVis"
                        sb.Adornee = v
                        sb.Color3 = Color3.fromRGB(100, 255, 100)
                        sb.LineThickness = 0.05
                    end
                    sb.Visible = true
                end
            end
        end
    else
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("BasePart") and v:GetAttribute("OriginalSize") then
                    v.Size = v:GetAttribute("OriginalSize")
                    v:SetAttribute("OriginalSize", nil)
                    if v:FindFirstChild("RuonReachVis") then
                        v.RuonReachVis.Visible = false
                    end
                end
            end
        end
    end




    -- noclip
    -- noclip
    -- (Bang Positioning moved to Heartbeat loop for better sync)

    if noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end

    -- CFrame Speed
    if cframeSpeedEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (cframeSpeedValue / 10))
        end
    end

    -- Highlight Chams Logic (Enhanced: Custom Color + Rainbow + Neon)
    if highlightChams then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                -- Takim kontrolu: takimdakileri atlat
                if p.Team == LocalPlayer.Team then
                    if p.Character:FindFirstChild("RuonHighlight") then
                        p.Character.RuonHighlight:Destroy()
                    end
                    continue
                end

                local highlight = p.Character:FindFirstChild("RuonHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight", p.Character)
                    highlight.Name = "RuonHighlight"
                end

                -- Renk belirleme
                local fillCol
                if highlightRainbowColor then
                    -- Rainbow: her frame farkli renk
                    fillCol = Color3.fromHSV((tick() * 0.5) % 1, 1, 1)
                elseif highlightCustomColor then
                    fillCol = highlightCustomColor
                else
                    fillCol = (p.Team == LocalPlayer.Team) and teamColor or enemyColor
                end

                highlight.FillColor = fillCol

                if highlightNeonEnabled then
                    -- Neon efekti: parlak, nabiz atan outline
                    local pulse = math.sin(tick() * 4) * 0.15 + 0.15
                    highlight.FillTransparency = pulse
                    highlight.OutlineColor = fillCol
                    highlight.OutlineTransparency = 0
                else
                    highlight.OutlineColor = Color3.new(1, 1, 1)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                end

                highlight.Enabled = true
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("RuonHighlight") then
                p.Character.RuonHighlight:Destroy()
            end
        end
    end

    -- GOD MODE FEATURES RUNTIME
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")



    -- (Removed Water/Air Walk Logic)


    -- (Removed Auto Clicker)


    -- BHOP
    if bunnyHop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not UserInputService:GetFocusedTextBox() then
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end
    end

    -- Anti-Ragdoll (Enhanced Fix)
    if antiRagdoll and hum and not (flying or flying2) then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    elseif hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
    end

    -- Infinite Oxygen
    if infiniteOxygen and hum then
        LocalPlayer.Character:SetAttribute("Oxygen", 100)
    end

    -- Spinbot
    if spinBot and hrp then
        if desyncSpin then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(math.random(1, 360)), 0)
        else
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(20), 0)
        end
    end

    -- Native UI handles FOV positioning via AnchorPoint automatically, no RenderStepped needed for position.
    -- Just update color/size just in case variables drift, though not strictly necessary.
    if fovFrame and fovStroke then
        fovFrame.Visible = showFOV
        fovFrame.Size = UDim2.new(0, aimFOV * 2, 0, aimFOV * 2)
        fovStroke.Thickness = fovThickness
        fovStroke.Color = fovColor
    end

    -- Real-time ESP (Names/Dist)
    if espActive then
        local espFolder = Workspace:FindFirstChild("RuonESP") or Instance.new("Folder", Workspace)
        espFolder.Name = "RuonESP"

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local char = p.Character
                local hrp_p = char.HumanoidRootPart
                local head = char:FindFirstChild("Head")

                local name = p.Name
                local dist = math.floor((hrp.Position - hrp_p.Position).Magnitude)

                local tag = char:FindFirstChild("RuonTag") or Instance.new("BillboardGui", char)
                tag.Name = "RuonTag"
                tag.Size = UDim2.new(0, 100, 0, 50)
                tag.Adornee = head
                tag.AlwaysOnTop = true
                tag.ExtentsOffset = Vector3.new(0, 3, 0)

                local lbl = tag:FindFirstChild("TextLabel") or Instance.new("TextLabel", tag)
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = (p.Team ~= LocalPlayer.Team) and Color3.fromRGB(255, 50, 50) or
                    Color3.fromRGB(50, 255, 50)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 12

                local text = ""
                if espNames then text = text .. name .. " " end
                if espDistance then text = text .. "[" .. dist .. "m]" end
                lbl.Text = text

                local isEnemy = p.Team ~= LocalPlayer.Team
                local isTeam = p.Team == LocalPlayer.Team
                local filterPass = (enemyFilter and isEnemy) or (teamFilter and isTeam)

                lbl.TextColor3 = isEnemy and enemyColor or teamColor
                lbl.Visible = (espNames or espDistance) and filterPass
            end
        end
    else
        local espFolder = Workspace:FindFirstChild("RuonESP")
        if espFolder then espFolder:Destroy() end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("RuonTag") then
                p.Character.RuonTag:Destroy()
            end
        end
    end

    -- Tracers (Drawing API)
    if tracers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    -- We use a simple LineHandleAdornment approach since managing Drawing objects in this loop structure is complex without a pool
                    -- Alternatively, check if line exists
                    local line = p.Character:FindFirstChild("RuonTracer")
                    if not line then
                        line = Instance.new("LineHandleAdornment", p.Character)
                        line.Name = "RuonTracer"
                        line.Adornee = workspace.Terrain
                        line.ZIndex = 0
                        line.AlwaysOnTop = true
                        line.Transparency = 0.3
                        line.Thickness = 2
                    end

                    line.Color3 = (p.Team == LocalPlayer.Team) and teamColor or enemyColor
                    line.Length = (hrp.Position - Camera.CFrame.Position).Magnitude
                    line.CFrame = CFrame.lookAt(Camera.CFrame.Position, hrp.Position)
                    line.Visible = true
                elseif p.Character:FindFirstChild("RuonTracer") then
                    p.Character.RuonTracer.Visible = false
                end
            elseif p.Character and p.Character:FindFirstChild("RuonTracer") then
                p.Character.RuonTracer.Visible = false
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("RuonTracer") then
                p.Character.RuonTracer:Destroy()
            end
        end
    end
end)

-- Hitmarker Health Tracking
task.spawn(function()
    local lastHealths = {}
    while true do
        if hitmarkerEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hum = p.Character:FindFirstChild("Humanoid")
                    if hum then
                        local oldHealth = lastHealths[p] or hum.Health
                        if hum.Health < oldHealth then
                            -- Only show if they were recently damaged by us (simplified: check if aimed or just show on any damage)
                            -- Realistically, most scripts show it for ANY damage in the screen vicinity.
                            local _, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                            if onScreen then
                                showHitmarker()
                            end
                        end
                        lastHealths[p] = hum.Health
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Click TP
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if clickTP and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and Mouse.Target then
            hrp.CFrame = CFrame.new(Mouse.Hit.p) * CFrame.new(0, 3, 0)
        end
    end
end)



-- =========================
-- GUI toggle & dragging (kept but fixed)
-- =========================
-- =========================
-- DEVICE SELECTION SCRIPT
-- =========================
local GUI_ACTION = "Ruon_Toggle_GUI"
local toggleCooldown = false

local function toggleGUI(actionName, inputState, inputObj)
    if inputState == Enum.UserInputState.Begin and not toggleCooldown then
        toggleCooldown = true
        screenGui.Enabled = not screenGui.Enabled
        task.delay(0.15, function() toggleCooldown = false end)
    end
end

-- dragging (fixed)
do
    local dragging = false
    local dragStart, startPos
    main.Active = true
    main.Draggable = false

    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale,
                startPos.Y.Offset + delta.Y)
        end
    end)
end

-- minimize behavior (kept but compact)
local minimized = false
local originalSize = main.Size
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        for _, child in pairs(main:GetChildren()) do
            if child ~= topBar and child ~= subtitle and child ~= mainStroke and child ~= minimizeBtn then
                child.Visible = false
            end
        end
        main.Size = UDim2.new(0, 240, 0, 56)
        minimizeBtn.Text = "+"
    else
        for _, child in pairs(main:GetChildren()) do
            child.Visible = true
        end
        main.Size = originalSize
        minimizeBtn.Text = "-"
    end
end)

-- ensure original features (boost etc.) still available via quick binds:
-- boost: camera forward velocity (kept)
local function doBoost()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Velocity = Camera.CFrame.LookVector * (flySpeed * 6) end
end

-- Add a small quick-boost button in topBar
local boostQuick = Instance.new("TextButton", topBar)
boostQuick.Size = UDim2.new(0, 36, 0, 36)
boostQuick.Position = UDim2.new(1, -102, 0, 6)
boostQuick.Text = "B"
boostQuick.Font = Enum.Font.GothamBold
boostQuick.TextSize = 18
boostQuick.TextColor3 = Color3.fromRGB(240, 240, 240)
boostQuick.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", boostQuick).CornerRadius = UDim.new(0, 8)
boostQuick.MouseButton1Click:Connect(doBoost)

-- Startup logic moved to bottom


-- =========================
-- Visuals Page (Advanced Drawing ESP)
-- =========================
do
    local scroll = Instance.new("ScrollingFrame", pageVisuals)
    scroll.Size = UDim2.new(1, 0, 1, -10)
    scroll.Position = UDim2.new(0, 0, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Visual Settings
    local vis = {
        Box = false,
        BoxColor = Color3.fromRGB(255, 50, 50),
        Name = false,
        NameColor = Color3.fromRGB(255, 255, 255),
        Health = false,
        Tracer = false,
        TracerColor = Color3.fromRGB(255, 50, 50),
        TeamCheck = true
    }

    -- Cache for drawings
    local espCache = {}

    local function createDrawing(Type, Props)
        local d = Drawing.new(Type)
        for k, v in pairs(Props) do d[k] = v end
        return d
    end

    local function cleanESP()
        for _, c in pairs(espCache) do
            for _, d in pairs(c) do d:Remove() end
        end
        espCache = {}
    end

    mkToggle(scroll, "Kutu (Box)", vis.Box,
        function()
            vis.Box = not vis.Box; if not vis.Box then cleanESP() end
            return vis.Box
        end)
    mkToggle(scroll, "İsim (Name)", vis.Name, function()
        vis.Name = not vis.Name; return vis.Name
    end)
    mkToggle(scroll, "Can Çubuğu (Health)", healthBars, function()
        healthBars = not healthBars; return healthBars
    end)
    mkToggle(scroll, "Çizgi (Tracer)", vis.Tracer, function()
        vis.Tracer = not vis.Tracer; return vis.Tracer
    end)
    mkToggle(scroll, "✨ Highlight Chams", highlightChams,
        function()
            highlightChams = not highlightChams; return highlightChams
        end)

    -- HIGHLIGHT RENK SEÇİCİ
    local hlColorLabel = Instance.new("TextLabel", scroll)
    hlColorLabel.Size = UDim2.new(1, 0, 0, 24)
    hlColorLabel.BackgroundTransparency = 1
    hlColorLabel.Text = "  Highlight Rengi"
    hlColorLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    hlColorLabel.Font = Enum.Font.GothamBold
    hlColorLabel.TextSize = 13
    hlColorLabel.TextXAlignment = Enum.TextXAlignment.Left

    local hlColorFrame = Instance.new("Frame", scroll)
    hlColorFrame.Size = UDim2.new(1, -10, 0, 45)
    hlColorFrame.BackgroundTransparency = 1

    local hlGrid = Instance.new("UIGridLayout", hlColorFrame)
    hlGrid.CellSize = UDim2.new(0, 32, 0, 32)
    hlGrid.CellPadding = UDim2.new(0, 5, 0, 5)
    hlGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local hlColors = {
        Color3.fromRGB(255, 50, 50), Color3.fromRGB(50, 255, 50), Color3.fromRGB(50, 50, 255),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 100, 200)
    }

    for _, col in ipairs(hlColors) do
        local b = Instance.new("TextButton", hlColorFrame)
        b.Text = ""
        b.BackgroundColor3 = col
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", b); s.Thickness = 1; s.Color = Color3.fromRGB(255, 255, 255); s.Transparency = 0.7
        b.MouseButton1Click:Connect(function()
            highlightCustomColor = col
            highlightRainbowColor = false
            showNotify("Highlight Rengi Degistirildi!")
        end)
    end

    -- Takım rengine dön butonu
    local hlResetBtn = Instance.new("TextButton", scroll)
    hlResetBtn.Size = UDim2.new(0.95, 0, 0, 30)
    hlResetBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    hlResetBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    hlResetBtn.Font = Enum.Font.GothamBold
    hlResetBtn.TextSize = 12
    hlResetBtn.Text = "Takim Rengine Don"
    Instance.new("UICorner", hlResetBtn).CornerRadius = UDim.new(0, 6)
    hlResetBtn.MouseButton1Click:Connect(function()
        highlightCustomColor = nil
        showNotify("Takim Rengine Donuldu!")
    end)

    mkToggle(scroll, "Neon Highlight", highlightNeonEnabled, function()
        highlightNeonEnabled = not highlightNeonEnabled
        return highlightNeonEnabled
    end)

    mkToggle(scroll, "Rainbow Highlight (Renk Degisim)", highlightRainbowColor, function()
        highlightRainbowColor = not highlightRainbowColor
        return highlightRainbowColor
    end)

    -- HAVA EFEKTLERI BÖLÜMÜ
    local weatherLabel = Instance.new("TextLabel", scroll)
    weatherLabel.Size = UDim2.new(1, 0, 0, 28)
    weatherLabel.BackgroundTransparency = 1
    weatherLabel.Text = "  Hava Efektleri"
    weatherLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    weatherLabel.Font = Enum.Font.GothamBold
    weatherLabel.TextSize = 14
    weatherLabel.TextXAlignment = Enum.TextXAlignment.Left

    mkToggle(scroll, "Yagmur Efekti", rainEnabled, function()
        rainEnabled = not rainEnabled
        return rainEnabled
    end)

    mkToggle(scroll, "Kar Efekti", snowEnabled, function()
        snowEnabled = not snowEnabled
        return snowEnabled
    end)

    mkToggle(scroll, "Takım Kontrolü", vis.TeamCheck,
        function()
            vis.TeamCheck = not vis.TeamCheck; return vis.TeamCheck
        end)

    -- CROSSHAIR CONTROLS
    local crossLabel = Instance.new("TextLabel", scroll)
    crossLabel.Size = UDim2.new(1, 0, 0, 30)
    crossLabel.BackgroundTransparency = 1
    crossLabel.Text = "  Dönen Crosshair (Cros)"
    crossLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    crossLabel.Font = Enum.Font.GothamBold
    crossLabel.TextSize = 14
    crossLabel.TextXAlignment = Enum.TextXAlignment.Left

    mkToggle(scroll, "Rotating Crosshair", crosshairEnabled, function()
        crosshairEnabled = not crosshairEnabled
        return crosshairEnabled
    end)

    mkSlider(scroll, "Dönüş Hızı", 0, 500, crosshairRotateSpeed, function(v)
        crosshairRotateSpeed = v
    end)

    mkSlider(scroll, "Büyüme Hızı (Pulsing)", 0, 10, crosshairPulseSpeed, function(v)
        crosshairPulseSpeed = v
    end)

    mkSlider(scroll, "Renk Hızı (Rainbow)", 0, 5, crosshairColorSpeed, function(v)
        crosshairColorSpeed = v
    end)

    mkSlider(scroll, "Crosshair Boyutu", 2, 50, crosshairSize, function(v)
        crosshairSize = v
    end)

    -- Main ESP Loop
    RunService.RenderStepped:Connect(function()
        if not (vis.Box or vis.Name or vis.Health or vis.Tracer) then
            -- Clean if everything off (and cache not empty)
            if next(espCache) then cleanESP() end
            return
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                -- Initial checks
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")

                -- Team Check
                local isTeam = plr.Team == LocalPlayer.Team
                if vis.TeamCheck and isTeam then
                    -- If filtering team, hide drawings for this player
                    if espCache[plr] then
                        for _, d in pairs(espCache[plr]) do d.Visible = false end
                    end
                    continue
                end

                if hrp and hum and hum.Health > 0 then
                    local vec, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    -- Cache init
                    if not espCache[plr] then
                        espCache[plr] = {
                            Box = createDrawing("Square", { Thickness = 1, Filled = false }),
                            BoxOutline = createDrawing("Square",
                                {
                                    Thickness = 3,
                                    Filled = false,
                                    Color = Color3.new(0, 0,
                                        0)
                                }),
                            Name = createDrawing("Text", { Center = true, Size = 13, Outline = true }),
                            HealthBar = createDrawing("Square", { Filled = true, Thickness = 1 }),
                            HealthOutline = createDrawing("Square", {
                                Filled = true,
                                Thickness = 1,
                                Color = Color3.new(0,
                                    0, 0)
                            }),
                            Tracer = createDrawing("Line", { Thickness = 1 })
                        }
                    end

                    local c = espCache[plr]

                    if onScreen then
                        local size = Vector2.new(2000 / vec.Z, 2500 / vec.Z)
                        local pos = Vector2.new(vec.X - size.X / 2, vec.Y - size.Y / 2)

                        -- BOX
                        if vis.Box then
                            c.BoxOutline.Size = size
                            c.BoxOutline.Position = pos
                            c.BoxOutline.Visible = true

                            c.Box.Size = size
                            c.Box.Position = pos
                            c.Box.Color = isTeam and Color3.fromRGB(50, 255, 50) or vis.BoxColor
                            c.Box.Visible = true
                        else
                            c.Box.Visible = false
                            c.BoxOutline.Visible = false
                        end

                        -- NAME
                        if vis.Name then
                            c.Name.Text = plr.Name
                            c.Name.Position = Vector2.new(vec.X, pos.Y - 16)
                            c.Name.Color = vis.NameColor
                            c.Name.Visible = true
                        else
                            c.Name.Visible = false
                        end

                        -- HEALTH
                        if healthBars or vis.Health then
                            local healthPct = hum.Health / hum.MaxHealth
                            local barHeight = size.Y * healthPct

                            c.HealthOutline.Size = Vector2.new(4, size.Y + 2)
                            c.HealthOutline.Position = Vector2.new(pos.X - 6, pos.Y - 1)
                            c.HealthOutline.Visible = true

                            c.HealthBar.Size = Vector2.new(2, barHeight)
                            c.HealthBar.Position = Vector2.new(pos.X - 5, pos.Y + size.Y - barHeight)
                            c.HealthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1) -- Red to Green
                            c.HealthBar.Visible = true
                        else
                            c.HealthBar.Visible = false
                            c.HealthOutline.Visible = false
                        end

                        -- TRACER
                        if vis.Tracer then
                            c.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            c.Tracer.To = Vector2.new(vec.X, vec.Y)
                            c.Tracer.Color = isTeam and Color3.fromRGB(50, 255, 50) or vis.TracerColor
                            c.Tracer.Visible = true
                        else
                            c.Tracer.Visible = false
                        end
                    else
                        -- Offscreen
                        for _, d in pairs(c) do d.Visible = false end
                    end
                else
                    -- No Character/Dead
                    if espCache[plr] then
                        for _, d in pairs(espCache[plr]) do d.Visible = false end
                    end
                end
            else
                -- Player left or nil
                if espCache[plr] then
                    for _, d in pairs(espCache[plr]) do d:Remove() end
                    espCache[plr] = nil
                end
            end
        end

        -- Cleanup invalid players
        for plr, _ in pairs(espCache) do
            if not plr.Parent then
                for _, d in pairs(espCache[plr]) do d:Remove() end
                espCache[plr] = nil
            end
        end
    end)
end

-- pageBang population block removed

-- =========================
-- MM2 Page
-- =========================
do
    local lbl = Instance.new("TextLabel", pageMM2)
    lbl.Size = UDim2.new(1, 0, 0, 32)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.Text = "Murder Mystery 2 🔪"
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local scroll = Instance.new("ScrollingFrame", pageMM2)
    scroll.Size = UDim2.new(1, 0, 1, -40)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    mkToggle(scroll, "Silent Aim", mm2_silentAim, function()
        mm2_silentAim = not mm2_silentAim
        return mm2_silentAim
    end)

    mkToggle(scroll, "Kill Aura", mm2_killAura, function()
        mm2_killAura = not mm2_killAura
        return mm2_killAura
    end)

    mkToggle(scroll, "Role ESP", mm2_roleESP, function()
        mm2_roleESP = not mm2_roleESP
        return mm2_roleESP
    end)

    mkToggle(scroll, "Touch Flight (Fling)", mm2_touchFling, function()
        mm2_touchFling = not mm2_touchFling
        if mm2_touchFling then
            task.spawn(touchFlingLoop)
        end
        return mm2_touchFling
    end)

    mkSlider(scroll, "Fling Power", 1000, 50000, mm2_flingPower, function(v)
        mm2_flingPower = v
    end)

    mkToggle(scroll, "Auto Fling Katil 🔪", mm2_autoFlingMurderer, function()
        mm2_autoFlingMurderer = not mm2_autoFlingMurderer
        return mm2_autoFlingMurderer
    end)
end


-- =========================
-- MM2 LOOPS (Silent Aim, Kill Aura, Role ESP, Touch Fling, Auto Fling)
-- =========================

-- Yardimci: MM2 karakter rolunu al
local function mm2_getRole(p)
    if not p or not p.Character then return "Innocent" end
    if p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife") then return "Murderer" end
    if p.Backpack:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun")
        or p.Backpack:FindFirstChild("Hero") or p.Character:FindFirstChild("Hero") then
        return "Sheriff"
    end
    return "Innocent"
end

local function mm2_getMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if mm2_getRole(p) == "Murderer" then return p end
    end
end

-- ==========================================
-- ROLE ESP (RenderStepped → anlik guncelleme)
-- ==========================================
RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local h = p.Character:FindFirstChild("MM2_ESP")
        if mm2_roleESP then
            if not h then
                h = Instance.new("Highlight", p.Character)
                h.Name = "MM2_ESP"
            end
            local role            = mm2_getRole(p)
            local col             = role == "Murderer" and Color3.fromRGB(255, 30, 30)
                or role == "Sheriff" and Color3.fromRGB(30, 120, 255)
                or Color3.fromRGB(100, 255, 100)
            h.FillColor           = col
            h.OutlineColor        = col
            h.FillTransparency    = 0.45
            h.OutlineTransparency = 0
            h.Enabled             = true
        else
            if h then h:Destroy() end
        end
    end
end)

-- ==========================================
-- SILENT AIM  (hookmetamethod ile FireServer yakala)
-- En guvenilir yontem: remote adini bilmeden calisir
-- ==========================================
local mm2_silentAimHook = nil

local function mm2_applyHook()
    if mm2_silentAimHook then return end
    pcall(function()
        mm2_silentAimHook = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if mm2_silentAim and method == "FireServer" then
                local char = LocalPlayer.Character
                local role = mm2_getRole(LocalPlayer)
                -- Sadece Sheriff ateslendiginde (silah varken) katili hedefle
                if role == "Sheriff" and char and (char:FindFirstChild("Gun") or char:FindFirstChild("Hero")) then
                    local murderer = mm2_getMurderer()
                    if murderer and murderer.Character then
                        local mHead = murderer.Character:FindFirstChild("Head")
                        local mHRP  = murderer.Character:FindFirstChild("HumanoidRootPart")
                        if mHead then
                            return mm2_silentAimHook(self, mHead.Position, ...)
                        elseif mHRP then
                            return mm2_silentAimHook(self, mHRP.Position, ...)
                        end
                    end
                end
            end
            return mm2_silentAimHook(self, ...)
        end)
    end)
end
task.spawn(mm2_applyHook)

-- ==========================================
-- KILL AURA  (katil isen yakin masumlara hasar)
-- ==========================================
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if not mm2_killAura or not mm2_active then continue end

        local char   = LocalPlayer.Character
        local hrp    = char and char:FindFirstChild("HumanoidRootPart")
        local myRole = mm2_getRole(LocalPlayer)

        if not hrp or myRole ~= "Murderer" then continue end

        local knife = char:FindFirstChild("Knife")
        if not knife then continue end

        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character then continue end
            local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
            local pHum = p.Character:FindFirstChild("Humanoid")
            if not pHRP or not pHum or pHum.Health <= 0 then continue end

            local dist = (hrp.Position - pHRP.Position).Magnitude
            if dist < 20 then
                -- Bıçağı hedefin üstüne an'lık CFrame'le taşı (replicasyon için)
                pcall(function()
                    local knifeHandle = knife:FindFirstChild("Handle") or knife:FindFirstChildOfClass("BasePart")
                    if knifeHandle then
                        knifeHandle.CFrame = pHRP.CFrame
                    end
                end)
                -- Direkt hasar (sadece sunucu kabul etmezse çalışır, yine de dene)
                pcall(function() pHum:TakeDamage(100) end)
            end
        end
    end
end)

-- ==========================================
-- TOUCH FLING (Velocity manipülasyonu)
-- ==========================================
touchFlingLoop = function()
    local movel = 0.1
    while mm2_touchFling do
        RunService.Heartbeat:Wait()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local vel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
        RunService.RenderStepped:Wait()
        hrp.AssemblyLinearVelocity = vel
        RunService.Stepped:Wait()
        hrp.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0)
        movel = -movel
    end
end

-- ==========================================
-- AUTO FLING MURDERER (direkt BodyVelocity)
-- ==========================================
local autoFlingSpinner = nil

local function destroyFlingSpinner()
    if autoFlingSpinner and autoFlingSpinner.Parent then
        pcall(function() autoFlingSpinner:Destroy() end)
    end
    autoFlingSpinner = nil
end

local function setMyCollision(char, enabled)
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = enabled end
    end
end

task.spawn(function()
    local lastFling = 0
    while true do
        task.wait(0.15)
        if not mm2_autoFlingMurderer then
            destroyFlingSpinner(); continue
        end

        local char  = LocalPlayer.Character
        local myHRP = char and char:FindFirstChild("HumanoidRootPart")
        local myHum = char and char:FindFirstChild("Humanoid")
        if not myHRP or not myHum or myHum.Health <= 0 then
            destroyFlingSpinner(); continue
        end

        local murderer = mm2_getMurderer()
        if not murderer or not murderer.Character then
            destroyFlingSpinner(); continue
        end
        local mHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
        if not mHRP then continue end

        -- Mesafe kontrolu: cok uzaktaysa atla
        if (myHRP.Position - mHRP.Position).Magnitude > 80 then continue end

        local now = tick()
        if (now - lastFling) < 2 then continue end
        lastFling = now

        -- Collision kapat ve TP
        local savedCF = myHRP.CFrame
        setMyCollision(char, false)
        destroyFlingSpinner()

        -- Spinner katil'in ustune
        local spinner        = Instance.new("Part")
        spinner.Name         = "FlingSpinner"
        spinner.Size         = Vector3.new(16, 1, 2)
        spinner.Transparency = 1
        spinner.CanCollide   = true
        spinner.CastShadow   = false
        spinner.Anchored     = false
        spinner.CFrame       = mHRP.CFrame + Vector3.new(0, 1, 0)
        spinner.Parent       = workspace
        autoFlingSpinner     = spinner

        -- Yuksek açisal hiz
        local bav            = Instance.new("BodyAngularVelocity", spinner)
        bav.MaxTorque        = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity  = Vector3.new(0, mm2_flingPower * 0.5, 0)

        local bv             = Instance.new("BodyVelocity", spinner)
        bv.MaxForce          = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity          = Vector3.new(0, 150, 0)

        pcall(function() myHRP.CFrame = mHRP.CFrame * CFrame.new(0, 0, 2) end)
        task.wait(0.4)

        destroyFlingSpinner()
        pcall(function() myHRP.CFrame = savedCF end)
        task.wait(0.05)
        setMyCollision(char, true)
        showNotify("Katil Ucuruldu: " .. murderer.Name)
    end
end)

-- Karakter yenilenince temizle
LocalPlayer.CharacterAdded:Connect(function(newChar)
    destroyFlingSpinner()
    task.wait(1)
    setMyCollision(newChar, true)
end)


-- =========================
-- STARTUP EXECUTION (Placed at bottom for full initialization)
-- =========================
local function RuonStartup()
    local startup = Instance.new("ScreenGui", PlayerGui)
    startup.Name = "RuonStartup"
    startup.DisplayOrder = 9999

    -- Force unlock on startup & keep it unlocked until finalize
    task.spawn(function()
        while startup and startup.Parent do
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
            task.wait(0.1)
        end
    end)

    -- Startup Mouse Unlock (RightControl)
    local startupConnection
    startupConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.RightControl then
            mouseUnlockEnabled = not mouseUnlockEnabled
            if mouseUnlockEnabled then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                showNotify("Başlangıç Fare Kilidi: AÇIK")
            else
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                showNotify("Başlangıç Fare Kilidi: KAPALI")
            end
        end
    end)

    local bg = Instance.new("Frame", startup)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    bg.BorderSizePixel = 0

    local center = Instance.new("Frame", bg)
    center.Size = UDim2.new(0, 400, 0, 250)
    center.Position = UDim2.new(0.5, -200, 0.5, -125)
    center.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    pcall(function() Instance.new("UICorner", center).CornerRadius = UDim.new(0, 16) end)
    pcall(function() Instance.new("UIStroke", center).Color = Color3.fromRGB(60, 60, 80) end)

    local topText = Instance.new("TextLabel", center)
    topText.Size = UDim2.new(1, 0, 0, 60)
    topText.Text = "CİHAZINIZI SEÇİN"
    topText.Font = Enum.Font.GothamBold
    topText.TextSize = 24
    topText.TextColor3 = Color3.fromRGB(255, 255, 255)
    topText.BackgroundTransparency = 1

    local btnPC = Instance.new("TextButton", center)
    btnPC.Size = UDim2.new(0, 160, 0, 80)
    btnPC.Position = UDim2.new(0.1, 0, 0.4, 0)
    btnPC.Text = "💻 PC"
    btnPC.Font = Enum.Font.GothamBold
    btnPC.TextSize = 20
    btnPC.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btnPC.TextColor3 = Color3.fromRGB(240, 240, 240)
    btnPC.Modal = true -- FORCES MOUSE TO UNLOCK
    pcall(function() Instance.new("UICorner", btnPC).CornerRadius = UDim.new(0, 12) end)

    local btnMob = Instance.new("TextButton", center)
    btnMob.Size = UDim2.new(0, 160, 0, 80)
    btnMob.Position = UDim2.new(0.55, 0, 0.4, 0)
    btnMob.Text = "📱 MOBİL"
    btnMob.Font = Enum.Font.GothamBold
    btnMob.TextSize = 20
    btnMob.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btnMob.TextColor3 = Color3.fromRGB(240, 240, 240)
    btnMob.Modal = true -- FORCES MOUSE TO UNLOCK
    pcall(function() Instance.new("UICorner", btnMob).CornerRadius = UDim.new(0, 12) end)

    local function finalize(mode)
        pcall(function()
            if startupConnection then startupConnection:Disconnect() end
            deviceMode = mode
            startup:Destroy()
            screenGui.Enabled = true
            main.Visible = true

            if deviceMode == "PC" then
                ContextActionService:BindAction(GUI_ACTION, toggleGUI, false, Enum.KeyCode.Insert)
                ContextActionService:BindAction(GUI_ACTION .. "_Home", toggleGUI, false, Enum.KeyCode.Home)
            else
                main.Size = UDim2.new(0, 650, 0, 420)
                left.Size = UDim2.new(0, 160, 1, -60)
                right.Position = UDim2.new(0, 184, 0, 56)

                local toggleMob = Instance.new("TextButton", screenGui)
                toggleMob.Size = UDim2.new(0, 60, 0, 60)
                toggleMob.Position = UDim2.new(0, 10, 0.5, -30)
                toggleMob.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                toggleMob.Text = "RUON"
                toggleMob.Font = Enum.Font.GothamBold
                toggleMob.TextSize = 14
                toggleMob.TextColor3 = Color3.fromRGB(240, 240, 240)
                pcall(function() Instance.new("UICorner", toggleMob).CornerRadius = UDim.new(1, 0) end)
                pcall(function()
                    local str = Instance.new("UIStroke", toggleMob)
                    str.Color = Color3.fromRGB(100, 100, 120)
                    str.Thickness = 2
                end)

                toggleMob.MouseButton1Click:Connect(function()
                    main.Visible = not main.Visible
                end)
            end
            showNotify("NEGRO studio Yüklendi!")
        end)
    end

    btnPC.MouseButton1Click:Connect(function() finalize("PC") end)
    btnMob.MouseButton1Click:Connect(function() finalize("Mobil") end)
end

-- =========================
-- Hitmarker page
-- =========================
do
    local scroll = Instance.new("ScrollingFrame", pageHitmarker)
    scroll.Size = UDim2.new(1, 0, 1, -10)
    scroll.Position = UDim2.new(0, 0, 0, 5)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 2
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    mkToggle(scroll, "Hitmarker: Açık", hitmarkerEnabled, function()
        hitmarkerEnabled = not hitmarkerEnabled
        return hitmarkerEnabled
    end)

    mkToggle(scroll, "🔄 Sürekli Animasyon", hitmarkerConstant, function()
        hitmarkerConstant = not hitmarkerConstant
        return hitmarkerConstant
    end)

    mkToggle(scroll, "🌈 Rainbow Hitmarker", hitmarkerRainbow, function()
        hitmarkerRainbow = not hitmarkerRainbow
        return hitmarkerRainbow
    end)

    mkSlider(scroll, "Hitmarker Boyutu", 5, 100, hitmarkerSize, function(v)
        hitmarkerSize = v
        updateHitmarkerOffsets()
    end)

    mkSlider(scroll, "Hitmarker Kalınlığı", 1, 10, hitmarkerThickness, function(v)
        hitmarkerThickness = v
        updateHitmarkerOffsets()
    end)

    mkSlider(scroll, "Hitmarker Dönüş Hızı", 1, 20, hitmarkerSpeed, function(v)
        hitmarkerSpeed = v
    end)

    addColorSection(scroll, "Hitmarker Rengi", hitmarkerColor, function(c)
        hitmarkerColor = c
        updateHitmarkerOffsets()
        showNotify("Hitmarker Rengi Güncellendi")
    end)
end

-- =========================
-- YAGMUR & KAR PARCACIK EFEKT SISTEMI
-- =========================
do
    local weatherGui = Instance.new("ScreenGui")
    weatherGui.Name = "RuonWeather"
    weatherGui.ResetOnSpawn = false
    weatherGui.IgnoreGuiInset = true
    weatherGui.DisplayOrder = 999
    pcall(function() weatherGui.Parent = game:GetService("CoreGui") end)
    if not weatherGui.Parent then weatherGui.Parent = PlayerGui end

    local particles = {}
    local MAX_PARTICLES = 120

    task.spawn(function()
        while true do
            local dt = task.wait()
            local viewSize = Camera.ViewportSize

            -- Yeni parcacik uret
            if rainEnabled or snowEnabled then
                local spawnCount = rainEnabled and 4 or 2
                for i = 1, spawnCount do
                    if #particles < MAX_PARTICLES then
                        local p = Instance.new("Frame", weatherGui)
                        p.BorderSizePixel = 0
                        p.AnchorPoint = Vector2.new(0.5, 0)

                        local data = {}
                        data.frame = p
                        data.x = math.random(0, math.floor(viewSize.X))
                        data.y = -math.random(5, 40)

                        if rainEnabled then
                            -- Yagmur: ince mavi cizgi, hizli duser
                            p.Size = UDim2.new(0, math.random(1, 2), 0, math.random(12, 25))
                            p.BackgroundColor3 = Color3.fromRGB(
                                math.random(100, 160),
                                math.random(160, 220),
                                255
                            )
                            p.BackgroundTransparency = math.random(20, 50) / 100
                            p.Rotation = math.random(-8, 8)
                            data.speed = math.random(600, 1100)
                            data.drift = 0
                            data.type = "rain"
                        else
                            -- Kar: yuvarlak beyaz nokta, yavas duser
                            local sz = math.random(3, 7)
                            p.Size = UDim2.new(0, sz, 0, sz)
                            p.BackgroundColor3 = Color3.fromRGB(
                                math.random(220, 255),
                                math.random(230, 255),
                                255
                            )
                            p.BackgroundTransparency = math.random(10, 40) / 100
                            Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
                            data.speed = math.random(60, 180)
                            data.drift = math.random(-30, 30)
                            data.wobblePhase = math.random() * math.pi * 2
                            data.wobbleSpeed = math.random(2, 5)
                            data.type = "snow"
                        end

                        p.Position = UDim2.new(0, data.x, 0, data.y)
                        table.insert(particles, data)
                    end
                end
            end

            -- Parcaciklari hareket ettir
            local toRemove = {}
            for i, data in ipairs(particles) do
                data.y = data.y + data.speed * dt

                if data.type == "snow" then
                    data.wobblePhase = data.wobblePhase + data.wobbleSpeed * dt
                    data.x = data.x + math.sin(data.wobblePhase) * 25 * dt + data.drift * dt
                else
                    data.x = data.x + data.drift * dt
                end

                if data.y > viewSize.Y + 30 then
                    table.insert(toRemove, i)
                else
                    data.frame.Position = UDim2.new(0, data.x, 0, data.y)
                end
            end

            -- Ekran disi parcaciklari temizle
            for j = #toRemove, 1, -1 do
                local idx = toRemove[j]
                particles[idx].frame:Destroy()
                table.remove(particles, idx)
            end

            -- Efekt kapatildiginda temizle
            if not rainEnabled and not snowEnabled then
                for _, data in ipairs(particles) do
                    data.frame:Destroy()
                end
                particles = {}
                task.wait(0.3) -- Kapali iken bekleme suresi uzat
            end
        end
    end)
end

pcall(RuonStartup)
