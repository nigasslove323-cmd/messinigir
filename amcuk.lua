local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "script",
    LoadingTitle = "pro script",
    LoadingSubtitle = "by ruon",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RuonScripts",
        FileName = "YeniScriptConfig"
    },
    KeySystem = false,
})

-- ===================== GLOBALS =====================

_G.AimlockEnabled   = false
_G.AimlockFov       = 150
_G.AimlockWallcheck = false
_G.AimTarget        = "HumanoidRootPart"
_G.ShowFov          = false

_G.WalkSpeedValue   = 16
_G.SpeedHackEnabled = false
_G.SpeedHackValue   = 100
_G.SpeedHackBV      = nil

_G.EspEnabled       = false
_G.BoxEspEnabled    = false
_G.TracersEnabled   = false

-- ===================== HELPER FUNCTIONS =====================

local function IsVisible(part)
    local cam = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    if not char or not part then return false end

    local filterList = {char}
    if part.Parent then filterList[2] = part.Parent end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = filterList
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local origin = cam.CFrame.Position
    local target = part.Position

    for _ = 1, 5 do
        local result = workspace:Raycast(origin, target - origin, params)
        if not result then return true end
        local inst = result.Instance
        if (inst.Transparency >= 0.75 or not inst.CanCollide)
            and not inst:IsDescendantOf(part.Parent) then
            filterList[#filterList + 1] = inst
            params.FilterDescendantsInstances = filterList
            origin = result.Position + ((target - origin).Unit * 0.05)
        else
            return false
        end
    end
    return false
end

local function GetClosestPlayer()
    local target, closest = nil, _G.AimlockFov
    local cam = workspace.CurrentCamera
    local mouse = game:GetService("UserInputService"):GetMouseLocation()

    for _, v in pairs(game.Players:GetPlayers()) do
        if v == game.Players.LocalPlayer then continue end
        local char = v.Character
        if not char then continue end
        local part = char:FindFirstChild(_G.AimTarget)
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not part or not hum or hum.Health <= 0 then continue end

        local pos, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
        if dist >= closest then continue end

        if _G.AimlockWallcheck and not IsVisible(part) then continue end

        target  = v
        closest = dist
    end
    return target
end

-- ===================== TABS =====================

local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local SpeedTab  = Window:CreateTab("Hız",    4483362458)
local EspTab    = Window:CreateTab("ESP",     4483362458)

-- ===================== AIMBOT UI =====================

AimbotTab:CreateSection("Aimbot Ayarları")

AimbotTab:CreateToggle({
    Name = "Aimbot Etkin",
    CurrentValue = false,
    Flag = "Aimlock1",
    Callback = function(v) _G.AimlockEnabled = v end,
})

AimbotTab:CreateSlider({
    Name = "FOV",
    Range = { 10, 800 },
    Increment = 1,
    Suffix = "px",
    CurrentValue = 150,
    Flag = "AimlockFov1",
    Callback = function(v) _G.AimlockFov = v end,
})

AimbotTab:CreateToggle({
    Name = "FOV Çemberi Göster",
    CurrentValue = false,
    Flag = "ShowFov1",
    Callback = function(v) _G.ShowFov = v end,
})

AimbotTab:CreateToggle({
    Name = "Wallcheck (Duvar Kontrolü)",
    CurrentValue = false,
    Flag = "Wallcheck1",
    Callback = function(v) _G.AimlockWallcheck = v end,
})

AimbotTab:CreateDropdown({
    Name = "Hedef Bölge",
    Options = { "Gövde", "Kafa" },
    CurrentOption = { "Gövde" },
    MultipleOptions = false,
    Flag = "AimTarget1",
    Callback = function(opt)
        _G.AimTarget = (opt[1] == "Kafa") and "Head" or "HumanoidRootPart"
    end,
})

-- ===================== HIZ UI =====================

SpeedTab:CreateSection("Yürüme Hızı")

SpeedTab:CreateSlider({
    Name = "WalkSpeed",
    Range = { 16, 250 },
    Increment = 1,
    Suffix = "Hız",
    CurrentValue = 16,
    Flag = "Speed1",
    Callback = function(v)
        _G.WalkSpeedValue = v
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

SpeedTab:CreateSection("Speed Hack (BodyVelocity)")

SpeedTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack1",
    Callback = function(v)
        _G.SpeedHackEnabled = v
        if not v and _G.SpeedHackBV then
            _G.SpeedHackBV:Destroy()
            _G.SpeedHackBV = nil
        end
    end,
})

SpeedTab:CreateSlider({
    Name = "Speed Hack Değeri",
    Range = { 16, 500 },
    Increment = 1,
    Suffix = "Hız",
    CurrentValue = 100,
    Flag = "SpeedHackVal1",
    Callback = function(v) _G.SpeedHackValue = v end,
})

-- ===================== ESP UI =====================

EspTab:CreateSection("ESP Ayarları")

EspTab:CreateToggle({
    Name = "Highlight ESP",
    CurrentValue = false,
    Flag = "Esp1",
    Callback = function(v)
        _G.EspEnabled = v
        if not v then
            for _, p in pairs(game.Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("RuonHL") then
                    p.Character.RuonHL:Destroy()
                end
            end
        end
    end,
})

EspTab:CreateToggle({
    Name = "Kutu ESP (Box)",
    CurrentValue = false,
    Flag = "BoxEsp1",
    Callback = function(v) _G.BoxEspEnabled = v end,
})

EspTab:CreateToggle({
    Name = "Çizgi ESP (Tracers)",
    CurrentValue = false,
    Flag = "Tracers1",
    Callback = function(v) _G.TracersEnabled = v end,
})

-- ===================== FOV CIRCLE =====================

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness  = 1.5
FOVCircle.NumSides   = 100
FOVCircle.Filled     = false
FOVCircle.Color      = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible    = false

-- ===================== DRAWING ESP =====================

local function CreateDrawings(player)
    local Box     = Drawing.new("Square")
    local Tracer  = Drawing.new("Line")
    local NameLbl = Drawing.new("Text")
    local DistLbl = Drawing.new("Text")
    local HpBg    = Drawing.new("Square")
    local HpFill  = Drawing.new("Square")

    NameLbl.Size         = 13
    NameLbl.Center       = true
    NameLbl.Outline      = true
    NameLbl.OutlineColor = Color3.fromRGB(0, 0, 0)
    DistLbl.Size         = 11
    DistLbl.Center       = true
    DistLbl.Outline      = true
    DistLbl.OutlineColor = Color3.fromRGB(0, 0, 0)
    DistLbl.Color        = Color3.fromRGB(200, 200, 200)

    local cam = workspace.CurrentCamera

    local conn
    conn = game:GetService("RunService").RenderStepped:Connect(function()
        local char = player and player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")

        local alive = root and hum and hum.Health > 0

        if alive then
            local pos,     onScreen  = cam:WorldToViewportPoint(root.Position)
            local headPos, headOnScr = cam:WorldToViewportPoint((head or root).Position)
            local dist = (cam.CFrame.Position - root.Position).Magnitude

            local boxH  = math.clamp(math.abs(headPos.Y - pos.Y) * 2.2, 10, 600)
            local boxW  = boxH * 0.55
            local boxX  = pos.X - boxW / 2
            local boxY  = headPos.Y - 4

            -- Box
            if onScreen and _G.BoxEspEnabled then
                Box.Visible   = true
                Box.Size      = Vector2.new(boxW, boxH)
                Box.Position  = Vector2.new(boxX, boxY)
                Box.Color     = Color3.fromRGB(255, 255, 255)
                Box.Thickness = 1.5
                Box.Filled    = false
            else
                Box.Visible = false
            end

            -- Tracer
            if onScreen and _G.TracersEnabled then
                Tracer.Visible   = true
                Tracer.From      = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                Tracer.To        = Vector2.new(pos.X, pos.Y)
                Tracer.Color     = Color3.fromRGB(255, 255, 255)
                Tracer.Thickness = 1
            else
                Tracer.Visible = false
            end

            -- İsim + Mesafe
            if onScreen and _G.EspEnabled then
                NameLbl.Visible  = true
                NameLbl.Text     = player.Name
                NameLbl.Position = Vector2.new(pos.X, boxY - 16)
                NameLbl.Color    = Color3.fromRGB(255, 255, 255)

                DistLbl.Visible  = true
                DistLbl.Text     = string.format("[%.0fm]", dist)
                DistLbl.Position = Vector2.new(pos.X, boxY + boxH + 2)
            else
                NameLbl.Visible = false
                DistLbl.Visible = false
            end

            -- HP Bar
            if onScreen and _G.BoxEspEnabled then
                local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local bW, bX, bY = 4, boxX - 6, boxY

                HpBg.Visible  = true
                HpBg.Size     = Vector2.new(bW, boxH)
                HpBg.Position = Vector2.new(bX, bY)
                HpBg.Color    = Color3.fromRGB(0, 0, 0)
                HpBg.Filled   = true
                HpBg.Thickness = 1

                HpFill.Visible  = true
                HpFill.Size     = Vector2.new(bW, boxH * ratio)
                HpFill.Position = Vector2.new(bX, bY + boxH * (1 - ratio))
                HpFill.Color    = Color3.fromRGB(math.floor(255*(1-ratio)), math.floor(255*ratio), 0)
                HpFill.Filled   = true
                HpFill.Thickness = 1
            else
                HpBg.Visible   = false
                HpFill.Visible = false
            end

            -- Highlight
            if _G.EspEnabled then
                local hl = char:FindFirstChild("RuonHL")
                if not hl then
                    hl = Instance.new("Highlight", char)
                    hl.Name = "RuonHL"
                    hl.FillTransparency   = 0.5
                    hl.OutlineTransparency = 0
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
                hl.FillColor = Color3.fromRGB(255, 0, 0)
            else
                local hl = char:FindFirstChild("RuonHL")
                if hl then hl:Destroy() end
            end
        else
            Box.Visible    = false
            Tracer.Visible = false
            NameLbl.Visible = false
            DistLbl.Visible = false
            HpBg.Visible   = false
            HpFill.Visible = false

            if not player or not player.Parent then
                Box:Remove(); Tracer:Remove()
                NameLbl:Remove(); DistLbl:Remove()
                HpBg:Remove(); HpFill:Remove()
                conn:Disconnect()
            end
        end
    end)
end

for _, v in pairs(game.Players:GetPlayers()) do
    if v ~= game.Players.LocalPlayer then CreateDrawings(v) end
end
game.Players.PlayerAdded:Connect(CreateDrawings)

-- ===================== RENDER LOOP (Aimbot + FOV) =====================

game:GetService("RunService").RenderStepped:Connect(function()
    -- FOV Circle
    FOVCircle.Visible  = _G.ShowFov
    FOVCircle.Radius   = _G.AimlockFov
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()

    -- Aimbot
    if _G.AimlockEnabled then
        local t = GetClosestPlayer()
        if t and t.Character then
            local part = t.Character:FindFirstChild(_G.AimTarget)
            local hum  = t.Character:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                local cam = workspace.CurrentCamera
                cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
            end
        end
    end
end)

-- ===================== HEARTBEAT LOOP (Speed Hack) =====================

game:GetService("RunService").Heartbeat:Connect(function()
    if not _G.SpeedHackEnabled then return end
    local char = game.Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if not _G.SpeedHackBV or not _G.SpeedHackBV.Parent then
        _G.SpeedHackBV = Instance.new("BodyVelocity")
        _G.SpeedHackBV.MaxForce = Vector3.new(1e5, 0, 1e5)
        _G.SpeedHackBV.Parent  = root
    end

    local dir = hum.MoveDirection
    _G.SpeedHackBV.Velocity = dir.Magnitude > 0.1
        and dir * _G.SpeedHackValue
        or Vector3.zero
end)

-- ===================== WALKSPEED PERSISTENCE =====================

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local hum = game.Players.LocalPlayer.Character
                and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= _G.WalkSpeedValue then
                hum.WalkSpeed = _G.WalkSpeedValue
            end
        end)
    end
end)

-- ===================== NOTIFY =====================

Rayfield:Notify({
    Title = "Script Yüklendi!",
    Content = "Aimbot / Hız / ESP",
    Duration = 4,
    Image = 4483362458,
})
