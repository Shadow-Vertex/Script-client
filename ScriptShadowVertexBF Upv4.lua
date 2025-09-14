--========================================================
-- 🌊 SDVT SCRIPT # Update 1 | 14/09/2025 (Đã chỉnh: equip phím 1 trước khi attack, chỉ dùng Z và C)
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

-- Auto Kill Player Trail (super-attack style)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Cấu hình: ("stud click" khoảng cách tấn công = 40 studs, click siêu nhanh)
local autoKill = false
local attackConnection
local currentTarget = nil
local attackRadius = 200 -- khoảng cách (studs) để tấn công (mở rộng thành 200 theo yêu cầu)
local attackInterval = 0.02 -- thời gian giữa mỗi lượt spam (siêu nhanh)
local clicksPerCycle = 3 -- số lần click mỗi vòng
local useSkills = {"Z","C"} -- chỉ xài Z và C
local equipKey = "1" -- phím để equip melee (sẽ nhấn trước khi spam)

local function getClosestPlayer(maxDist)
    local closest, dist = nil, maxDist or 10000000000000000
    if not (LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                if d < dist then
                    closest, dist = plr, d
                end
            end
        end
    end
    if dist <= maxDist then return closest end
    return nil
end

local function stopAllAttack()
    currentTarget = nil
end

local function spamClickOnce()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0,0))
    end)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0)
        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
    end)
end

local function pressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

local function equipMeleeOnce()
    -- Nhấn phím equipKey 1 lần trước khi bắt đầu spam
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:KeyDown(equipKey)
        task.wait(0.05)
        VirtualUser:KeyUp(equipKey)
    end)
    -- fallback với VirtualInputManager
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, equipKey, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, equipKey, false, game)
    end)
end

local function attackTarget(target)
    -- Ghi nhận target hiện tại để có thể dừng ngay khi toggle off
    currentTarget = target
    task.spawn(function()
        -- equip melee 1 lần trước khi bắt đầu
        equipMeleeOnce()
        while autoKill and currentTarget == target and target and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 do
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local thrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or not thrp then break end

            -- Dán sát (đặt CFrame sát phía sau target)
            pcall(function()
                hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, -1.6)
            end)

            -- Spam clicks nhanh nhiều lần mỗi chu kỳ
            for i=1, clicksPerCycle do
                if not autoKill or currentTarget ~= target then break end
                spamClickOnce()
                task.wait(attackInterval)
            end

            -- Thêm spam skill ngắt quãng (chỉ Z và C)
            for _, k in ipairs(useSkills) do
                if not autoKill or currentTarget ~= target then break end
                pressKey(k)
                task.wait(0.02)
            end

            task.wait(0.01)
        end
        -- nếu thoát vòng while (target chết hoặc autoKill false) -> clear currentTarget
        if currentTarget == target then currentTarget = nil end
    end)
end

Tab1:CreateToggle({
    Name = "Auto Kill Player Trail (Super)",
    CurrentValue = false,
    Flag = "AutoKillPlayerTrail",
    Callback = function(state)
        autoKill = state
        if not state then
            -- khi tắt thì đảm bảo dừng ngay
            stopAllAttack()
            if attackConnection then attackConnection:Disconnect() attackConnection = nil end
            return
        end

        -- khi bật
        attackConnection = RunService.Heartbeat:Connect(function()
            if not autoKill then return end
            local target = getClosestPlayer(attackRadius)
            if target and target ~= currentTarget then
                -- nếu có target mới thì attack
                attackTarget(target)
            end
        end)
    end
})

----------------------------------------------------------
-- Tab 2: TP
----------------------------------------------------------
local Tab2 = Window:CreateTab("TP")

local tween
local function tweenTo(targetPos, speed)
    local plr = Players.LocalPlayer
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = plr.Character.HumanoidRootPart
        local distance = (hrp.Position - targetPos).Magnitude
        local travelTime = math.max(distance / speed, 0.3)
        local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
        tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
        tween:Play()
    end
end

-- Nhanh
Tab2:CreateButton({
    Name = "Tp Green Tree (Nhanh)",
    Callback = function()
        tweenTo(Vector3.new(3029.78, 2280.25, -7314.13), 1200)
    end
})

-- Vừa phải
Tab2:CreateButton({
    Name = "Tp Green Tree (Vừa phải)",
    Callback = function()
        tweenTo(Vector3.new(3029.78, 2280.25, -7314.13), 400)
    end
})

-- Stop Tween
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

print("SDVT SCRIPT loaded (super-attack enabled).")
