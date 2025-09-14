--========================================================
-- 🌊 SDVT SCRIPT (Update có số và ngày)
-- Giao diện Rayfield + 4 Tab (Up v4, TP, Job Id, Tọa độ)
--========================================================

-- Load thư viện Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Tạo số update + ngày tự động
local UpdateNumber = 1.1 -- chỉnh số lần update ở đây
local Date = os.date("%d/%m/%Y")

-- Tạo cửa sổ chính
local Window = Rayfield:CreateWindow({
    Name = "SDVT SCRIPT # Update " .. UpdateNumber .. " - " .. Date,
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

-- =======================
-- Tab 1: Up v4
-- =======================
local Tab1 = Window:CreateTab("Up v4")

-- Auto Kill Player Trail: tìm người chơi gần, dùng melee/skill theo thứ tự và click liên tục
local autoKillEnabled = false
local attackRadius = 80 -- khoảng cách tìm mục tiêu
local attackInterval = 0.15 -- thời gian giữa các đòn click
local orbitWhenLow = true -- nếu HP mục tiêu/hoặc mình yếu thì bay vòng quanh
local orbitDistance = 6 -- bán kính bay vòng quanh mục tiêu
local useSkills = {"Z", "C", "X"} -- trình tự dùng skill
local meleeSlot = 1 -- slot melee để dùng

Tab1:CreateToggle({
    Name = "Auto Kill Player Trail",
    CurrentValue = false,
    Flag = "AutoKill",
    Callback = function(state)
        autoKillEnabled = state
        if state then
            task.spawn(function()
                local Players = game:GetService("Players")
                local RunService = game:GetService("RunService")
                local VirtualUser = game:GetService("VirtualUser")
                local TweenService = game:GetService("TweenService")

                local function getNearestEnemy(radius)
                    local me = Players.LocalPlayer
                    if not me or not me.Character or not me.Character:FindFirstChild("HumanoidRootPart") then return nil end
                    local myPos = me.Character.HumanoidRootPart.Position
                    local nearest, nd = nil, math.huge
                    for _, pl in pairs(Players:GetPlayers()) do
                        if pl ~= me and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid") then
                            local hum = pl.Character:FindFirstChild("Humanoid")
                            if hum.Health > 0 then
                                local d = (pl.Character.HumanoidRootPart.Position - myPos).Magnitude
                                if d < radius and d < nd then
                                    nd = d
                                    nearest = pl
                                end
                            end
                        end
                    end
                    return nearest
                end

                local function useSkill(key)
                    -- Ưu tiên gọi remote nếu biết tên, nếu không thì giả lập phím
                    local success, err = pcall(function()
                        local ks = key:upper()
                        -- giả lập nhấn phím
                        VirtualUser:CaptureController()
                        VirtualUser:KeyDown(ks)
                        task.wait(0.05)
                        VirtualUser:KeyUp(ks)
                    end)
                    if not success then
                        -- fallback: nothing
                    end
                end

                local function clickAttack()
                    local ok, e = pcall(function()
                        VirtualUser:ClickButton1(Vector2.new(0,0))
                    end)
                    if not ok then warn("clickAttack error", e) end
                end

                local function equipMelee(slot)
                    -- Thử gọi remote đổi vũ khí (tên remote tùy game) — đây là fallback: simulate số
                    local ok, e = pcall(function()
                        VirtualUser:KeyDown(tostring(slot))
                        task.wait(0.05)
                        VirtualUser:KeyUp(tostring(slot))
                    end)
                end

                local function orbitAround(targetHumanoidRootPart)
                    if not targetHumanoidRootPart then return end
                    local me = Players.LocalPlayer
                    if not me or not me.Character or not me.Character:FindFirstChild("HumanoidRootPart") then return end
                    local hrp = me.Character.HumanoidRootPart
                    local angle = 0
                    while autoKillEnabled and targetHumanoidRootPart and targetHumanoidRootPart.Parent and targetHumanoidRootPart.Parent:FindFirstChild("Humanoid") and targetHumanoidRootPart.Parent.Humanoid.Health > 0 do
                        angle = angle + math.rad(20)
                        local offset = Vector3.new(math.cos(angle) * orbitDistance, 0, math.sin(angle) * orbitDistance)
                        local pos = targetHumanoidRootPart.Position + offset + Vector3.new(0,3,0)
                        local tween = TweenService:Create(hrp, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
                        tween:Play()
                        task.wait(0.15)
                    end
                end

                while autoKillEnabled do
                    local targetPlayer = getNearestEnemy(attackRadius)
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("Humanoid") then
                        local targetHRP = targetPlayer.Character.HumanoidRootPart
                        local targetHum = targetPlayer.Character.Humanoid
                        -- equip melee
                        equipMelee(meleeSlot)
                        -- nếu máu mình thấp hoặc mục tiêu có lượng lớn máu, có thể orbit
                        local myHum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                        if myHum and myHum.Health < (myHum.MaxHealth * 0.3) and orbitWhenLow then
                            task.spawn(function() orbitAround(targetHRP) end)
                        end

                        -- attack loop: dùng skill theo thứ tự rồi click
                        for _, k in ipairs(useSkills) do
                            if not autoKillEnabled then break end
                            useSkill(k)
                            task.wait(0.12)
                        end

                        -- tấn công bằng click liên tục cho đến khi mục tiêu chết hoặc rời khỏi range
                        while autoKillEnabled and targetHum.Health > 0 and (targetHRP.Position - (Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Players.LocalPlayer.Character.HumanoidRootPart.Position or targetHRP.Position)).Magnitude < attackRadius do
                            clickAttack()
                            task.wait(attackInterval)
                        end
                    else
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
})

-- Các nút khác giữ nguyên

-- =======================
-- Tab 2: TP
-- =======================
local Tab2 = Window:CreateTab("TP")

local TweenService = game:GetService("TweenService")
local tween

Tab2:CreateButton({
    Name = "Tp Green Tree (Nhanh)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local targetPos = Vector3.new(3029.78, 2280.25, -7314.13)
            local distance = (hrp.Position - targetPos).Magnitude
            -- Bay nhanh (0.002 giây mỗi stud)
            local travelTime = math.max(distance * 0.002, 0.5)
            local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
            tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
            tween:Play()
        end
    end
})

Tab2:CreateButton({
    Name = "Tp Green Tree (Vừa phải)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local targetPos = Vector3.new(3029.78, 2280.25, -7314.13)
            local distance = (hrp.Position - targetPos).Magnitude
            -- Bay tốc độ vừa phải (0.005 giây mỗi stud)
            local travelTime = math.max(distance * 0.005, 1)
            local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
            tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
            tween:Play()
        end
    end
})

Tab2:CreateButton({
    Name = "Stop Tween",
    Callback = function()
        if tween then
            tween:Cancel()
            tween = nil
        end
    end
})

-- =======================
-- Tab 3: Job Id
-- =======================
local Tab3 = Window:CreateTab("Job Id")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local jobIdBox = Tab3:CreateInput({
    Name = "Nhập Job Id",
    PlaceholderText = "Dán Job Id vào đây",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        if text and text ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, text, LocalPlayer)
        end
    end
})

Tab3:CreateButton({
    Name = "Clear Job Id",
    Callback = function()
        jobIdBox:Set("")
    end
})

-- =======================
-- Tab 4: Tọa độ
-- =======================
local Tab4 = Window:CreateTab("Tọa độ")

-- Label hiển thị tọa độ đã copy
local coordLabel = Tab4:CreateLabel("Tọa độ: chưa copy")

-- Nút copy tọa độ hiện tại
Tab4:CreateButton({
    Name = "Copy Tọa độ hiện tại",
    Callback = function()
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = hrp.Position
            local coord = string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.X, pos.Y, pos.Z)
            if setclipboard then
                setclipboard(coord)
            end
            coordLabel:Set("Tọa độ đã copy: " .. coord)
        else
            coordLabel:Set("Không tìm thấy HumanoidRootPart")
        end
    end
})
