--========================================================
-- 🌊 SDVT SCRIPT (Update có số và ngày)
-- Giao diện Rayfield + 4 Tab (Up v4, TP, Job Id, Tọa độ)
--========================================================

-- Load thư viện Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Tạo số update + ngày tự động
local UpdateNumber = 1.31 -- chỉnh số lần update ở đây
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

-- Nút Bypass Tp Up V4 Island
Tab1:CreateButton({
    Name = "Bypass Tp Up V4 Island",
    Callback = function()
        local plr = game.Players.LocalPlayer
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            -- Ví dụ tọa độ đảo Up V4, bạn thay lại nếu khác
            local targetPos = Vector3.new(0, 300, 0)
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
        end
    end
})

-- Nút Best Up V4 (chạy loader)
Tab1:CreateButton({
    Name = "Best Up V4",
    Callback = function()
        -- Chạy loadstring từ URL đã cung cấp
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/85e904ae1ff30824c1aa007fc7324f8f.lua"))()
        end)
        if not ok then
            Rayfield:Notify({Title = "Lỗi", Content = "Không thể load Best Up V4: " .. tostring(err), Duration = 4})
        end
    end
})

-- =======================
-- Auto Kill Player Trail (cải thiện di chuyển)
-- =======================
local autoKillEnabled = false
local attackRadius = 80
local attackInterval = 0.12
local orbitWhenLow = true
local orbitDistance = 6
local useSkills = {"Z", "C", "X"} -- thứ tự dùng skill
local meleeSlot = 1 -- phím số để equip melee
local followDistance = 2.5 -- khoảng cách đứng gần mục tiêu

Tab1:CreateToggle({
    Name = "Auto Kill Player Trail",
    CurrentValue = false,
    Flag = "AutoKill",
    Callback = function(state)
        autoKillEnabled = state
        if state then
            task.spawn(function()
                local Players = game:GetService("Players")
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
                            if hum and hum.Health > 0 then
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

                local function equipMelee(slot)
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:KeyDown(tostring(slot))
                        task.wait(0.05)
                        VirtualUser:KeyUp(tostring(slot))
                    end)
                end

                local function useSkill(key)
                    pcall(function()
                        VirtualUser:CaptureController()
                        -- một số executor chấp nhận string, một số không; pcall để tránh crash
                        VirtualUser:KeyDown(key)
                        task.wait(0.05)
                        VirtualUser:KeyUp(key)
                    end)
                end

                local function clickAttack()
                    pcall(function()
                        VirtualUser:ClickButton1(Vector2.new(0,0))
                    end)
                end

                local function moveCloseTo(targetHRP)
                    if not targetHRP then return end
                    local me = Players.LocalPlayer
                    if not me or not me.Character or not me.Character:FindFirstChild("HumanoidRootPart") then return end
                    local hrp = me.Character.HumanoidRootPart
                    -- tính vị trí gần mục tiêu theo followDistance
                    local dir = (targetHRP.Position - hrp.Position)
                    if dir.Magnitude < 0.1 then return end
                    local unit = dir.Unit
                    local desiredPos = targetHRP.Position - unit * followDistance + Vector3.new(0, 3, 0)
                    local dist = (hrp.Position - desiredPos).Magnitude
                    local t = math.clamp(dist * 0.02, 0.06, 0.3)
                    pcall(function()
                        local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(desiredPos)})
                        tw:Play()
                    end)
                end

                local function orbitAround(targetHRP)
                    if not targetHRP then return end
                    local me = Players.LocalPlayer
                    if not me or not me.Character or not me.Character:FindFirstChild("HumanoidRootPart") then return end
                    local hrp = me.Character.HumanoidRootPart
                    local angle = 0
                    while autoKillEnabled and targetHRP and targetHRP.Parent and targetHRP.Parent:FindFirstChild("Humanoid") and targetHRP.Parent.Humanoid.Health > 0 do
                        angle = angle + math.rad(30)
                        local offset = Vector3.new(math.cos(angle) * orbitDistance, 0, math.sin(angle) * orbitDistance)
                        local pos = targetHRP.Position + offset + Vector3.new(0, 3, 0)
                        pcall(function()
                            local tw = TweenService:Create(hrp, TweenInfo.new(0.12, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
                            tw:Play()
                        end)
                        task.wait(0.12)
                    end
                end

                -- vòng lặp chính
                while autoKillEnabled do
                    local targetPlayer = getNearestEnemy(attackRadius)
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("Humanoid") then
                        local targetHRP = targetPlayer.Character.HumanoidRootPart
                        local targetHum = targetPlayer.Character.Humanoid

                        -- di chuyển gần ngay khi phát hiện mục tiêu
                        moveCloseTo(targetHRP)
                        task.wait(0.08)

                        -- equip melee
                        equipMelee(meleeSlot)
                        task.wait(0.06)

                        -- nếu máu mình thấp -> orbit
                        local myHum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                        if myHum and myHum.Health < (myHum.MaxHealth * 0.3) and orbitWhenLow then
                            task.spawn(function()
                                orbitAround(targetHRP)
                            end)
                        end

                        -- dùng skill theo thứ tự
                        for _, k in ipairs(useSkills) do
                            if not autoKillEnabled then break end
                            useSkill(k)
                            task.wait(0.14)
                        end

                        -- tấn công liên tục, đồng thời giữ vị trí gần mục tiêu
                        while autoKillEnabled and targetHum and targetHum.Health > 0 and targetHRP and (targetHRP.Position - (Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Players.LocalPlayer.Character.HumanoidRootPart.Position or targetHRP.Position)).Magnitude < attackRadius do
                            -- đảm bảo đứng sát mục tiêu (nếu bị tụt lại sẽ move lại)
                            moveCloseTo(targetHRP)
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

print("SDVT SCRIPT loaded")
