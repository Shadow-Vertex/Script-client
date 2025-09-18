--========================================================
-- 🌊 SDVT SCRIPT # Update 1 | 14/09/2025 (ĐÃ SỬA: AURA ONLY - CHỈ DÙNG MELEE 1)
-- Giao diện Rayfield + 4 Tab (Up v4, TP, Job Id, Tọa độ)
--========================================================

-- Load thư viện Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Tạo cửa sổ chính
local Window = Rayfield:CreateWindow({
    Name = "SDVT SCRIPT # Update 1 | 14/09/2025",
    LoadingTitle = "SDVT Hub",
    LoadingSubtitle = "by ChatGPT",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SDVT",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

----------------------------------------------------------
-- Tab 1: Up v4
----------------------------------------------------------
local Tab1 = Window:CreateTab("Up v4")

-- Best Up V4
Tab1:CreateButton({
    Name = "Best Up V4",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/85e904ae1ff30824c1aa007fc7324f8f.lua"))()
    end
})

-- AUTO KILL AURA ONLY (MELEE 1) — KHÔNG DÙNG CLICK, KHÔNG DÙNG Z/C
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Cấu hình AURA ONLY
local autoKillAura = false
local attackRadius = 200 -- Tấn công tất cả trong 200 studs
local equipKey = "1" -- PHÍM DUY NHẤT DÙNG: EQUIP MELEE 1
local equipInterval = 0.5 -- delay spam equip
local maxTargetDistance = 5 -- Khoảng cách tối đa để "dán sát" target

-- Lấy danh sách tất cả player trong bán kính
local function getPlayersInRadius(maxDist)
    if not (LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then return {} end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local targets = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                if d <= maxDist then
                    table.insert(targets, plr)
                end
            end
        end
    end
    return targets
end

-- Nhấn phím equipKey
local function pressEquip()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, equipKey, false, game)
        task.wait(0.003)
        VirtualInputManager:SendKeyEvent(false, equipKey, false, game)
    end)
end

-- Di chuyển đến vị trí sát target
local function moveClosestTo(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local thrp = target.Character.HumanoidRootPart
    if not hrp or not thrp then return end
    local direction = (hrp.Position - thrp.Position).Unit * 1.6
    local newPos = thrp.Position + direction
    pcall(function()
        hrp.CFrame = CFrame.new(newPos, thrp.Position)
    end)
end

-- Hàm tấn công AURA
local function attackAllTargets(targets)
    if #targets == 0 then return end
    local closestTarget = targets[1]
    for _, plr in ipairs(targets) do
        local d = (plr.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if d < (closestTarget and (closestTarget.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or 999) then
            closestTarget = plr
        end
    end
    while autoKillAura do
        moveClosestTo(closestTarget)
        pressEquip()
        local aliveTargets = {}
        for _, plr in ipairs(targets) do
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(aliveTargets, plr)
                end
            end
        end
        if #aliveTargets == 0 then break end
        if #aliveTargets > 0 then
            closestTarget = aliveTargets[1]
            for _, plr in ipairs(aliveTargets) do
                local d = (plr.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if d < (closestTarget and (closestTarget.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or 999) then
                    closestTarget = plr
                end
            end
        end
        task.wait(equipInterval)
    end
end

-- Toggle Auto Kill Aura
Tab1:CreateToggle({
    Name = "Auto Kill AURA (MELEE 1 ONLY)",
    CurrentValue = false,
    Flag = "AutoKillAuraOnly",
    Callback = function(state)
        autoKillAura = state
        if not state then return end
        while autoKillAura do
            local targets = getPlayersInRadius(attackRadius)
            if #targets > 0 then
                task.spawn(attackAllTargets, targets)
            end
            task.wait(0.1)
        end
    end
})

----------------------------------------------------------
-- Tab 2: TP
----------------------------------------------------------
local Tab2 = Window:CreateTab("TP")

local TweenService = game:GetService("TweenService")
local tween
local function tweenTo(targetPos, speed)
    local plr = Players.LocalPlayer
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = plr.Character.HumanoidRootPart
        local distance = (hrp.Position - targetPos).Magnitude
        local travelTime = math.max(distance / speed, 0.3)
        local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
        if tween then tween:Cancel() end
        tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
        tween:Play()
    end
end

Tab2:CreateButton({
    Name = "Tp Green Tree (Nhanh)",
    Callback = function()
        tweenTo(Vector3.new(3029.78, 2280.25, -7314.13), 1200)
    end
})

Tab2:CreateButton({
    Name = "Tp Green Tree (Vừa phải)",
    Callback = function()
        tweenTo(Vector3.new(3029.78, 2280.25, -7314.13), 400)
    end
})

Tab2:CreateButton({
    Name = "Stop Tween",
    Callback = function()
        if tween then tween:Cancel() tween = nil end
    end
})

----------------------------------------------------------
-- Tab 3: Job Id
----------------------------------------------------------
local Tab3 = Window:CreateTab("Job Id")
local jobInput
local TeleportService = game:GetService("TeleportService")

jobInput = Tab3:CreateInput({
    Name = "Nhập Job Id",
    PlaceholderText = "Dán Job Id vào đây...",
    RemoveTextAfterFocusLost = false,
    Callback = function(JobId)
        if JobId and JobId ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, JobId, LocalPlayer)
        end
    end
})

Tab3:CreateButton({
    Name = "Clear Job Id",
    Callback = function()
        jobInput:Set("")
    end
})

Tab3:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

----------------------------------------------------------
-- Tab 4: Tọa độ
----------------------------------------------------------
local Tab4 = Window:CreateTab("Tọa độ")
local coordLabel = Tab4:CreateLabel("Tọa độ: chưa copy")

Tab4:CreateButton({
    Name = "Copy Tọa độ hiện tại",
    Callback = function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = hrp.Position
            local coord = string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.X, pos.Y, pos.Z)
            if setclipboard then setclipboard(coord) end
            coordLabel:Set("Tọa độ đã copy: " .. coord)
        else
            coordLabel:Set("Không tìm thấy HumanoidRootPart")
        end
    end
})

print("✅ SDVT SCRIPT loaded (AURA KILL ONLY - MELEE 1 ENABLED).")
