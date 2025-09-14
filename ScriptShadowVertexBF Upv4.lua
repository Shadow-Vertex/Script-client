--========================================================
-- 🌊 SDVT SCRIPT # Update 1 - Ngày 14/09/2025
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

-- Auto Kill Player Trail (simple follow + spam attack)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local autoKill = false
local attackConnection

local function getClosestPlayer(maxDist)
    local closest, dist = nil, maxDist or 100
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then
                closest, dist = plr, d
            end
        end
    end
    return closest
end

local function attackTarget(target)
    task.spawn(function()
        while autoKill and target and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 do
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local thrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and thrp then
                -- Dán sát đối thủ
                hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, -2)

                -- Click đánh
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new())
                end)

                -- Skill Z, X, C (nếu có)
                pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true, "Z", false, game) end)
                task.wait(0.05)
                pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(false, "Z", false, game) end)
                task.wait(0.1)
                pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true, "X", false, game) end)
                task.wait(0.05)
                pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(false, "X", false, game) end)
                task.wait(0.1)
                pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true, "C", false, game) end)
                task.wait(0.05)
                pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(false, "C", false, game) end)
            end
            task.wait(0.25)
        end
    end)
end

Tab1:CreateToggle({
    Name = "Auto Kill Player Trail",
    CurrentValue = false,
    Flag = "AutoKillPlayerTrail",
    Callback = function(state)
        autoKill = state
        if state then
            attackConnection = RunService.Heartbeat:Connect(function()
                local target = getClosestPlayer(80)
                if target then
                    attackTarget(target)
                end
            end)
        else
            if attackConnection then attackConnection:Disconnect() end
        end
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
        local travelTime = math.max(distance / speed, 0.5)
        local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
        tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
        tween:Play()
    end
end

-- Nhanh
Tab2:CreateButton({
    Name = "Tp Green Tree (Nhanh)",
    Callback = function()
        tweenTo(Vector3.new(3029.78, 2280.25, -7314.13), 600)
    end
})

-- Vừa phải
Tab2:CreateButton({
    Name = "Tp Green Tree (Vừa phải)",
    Callback = function()
        tweenTo(Vector3.new(3029.78, 2280.25, -7314.13), 300)
    end
})

-- Stop Tween
Tab2:CreateButton({
    Name = "Stop Tween",
    Callback = function()
        if tween then
            tween:Cancel()
            tween = nil
        end
    end
})

----------------------------------------------------------
-- Tab 3: Job Id
----------------------------------------------------------
local Tab3 = Window:CreateTab("Job Id")
local jobInput

jobInput = Tab3:CreateInput({
    Name = "Nhập Job Id",
    PlaceholderText = "Dán Job Id vào đây...",
    RemoveTextAfterFocusLost = false,
    Callback = function(JobId)
        local TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, JobId, LocalPlayer)
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
        local TeleportService = game:GetService("TeleportService")
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
            if setclipboard then
                setclipboard(coord)
            end
            coordLabel:Set("Tọa độ đã copy: " .. coord)
        else
            coordLabel:Set("Không tìm thấy HumanoidRootPart")
        end
    end
})
