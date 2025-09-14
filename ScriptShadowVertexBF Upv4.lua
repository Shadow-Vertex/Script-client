--========================================================
-- 🌊 SDVT SCRIPT (Update có số và ngày)
-- Giao diện Rayfield + 4 Tab (Up v4, TP, Job Id, Tọa độ)
--========================================================

-- Load thư viện Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Tạo số update + ngày tự động
local UpdateNumber = 1 -- chỉnh số lần update ở đây
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

Tab1:CreateButton({
    Name = "Best Up V4",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/85e904ae1ff30824c1aa007fc7324f8f.lua"))()
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
