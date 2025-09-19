-- 🌌 Boss Finder GUI + Webhook Notify (Blox Fruits)
-- Tìm Rip_Indra True Form, Dough King, Cake Prince
-- Hiển thị menu trong Roblox + gửi Webhook Discord

if game.PlaceId ~= 7449423635 then
    warn("❌ Script chỉ hoạt động trong Blox Fruits (ID: 7449423635)")
    return
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Webhook của bạn
local WEBHOOK_URL = "https://discord.com/api/webhooks/1411881180030042192/rYCE5UFe6odtlFqa92eUPHUmfRQdO_Y4YiHAWOicOKBjIrAJrfYnMuMiFRAM5lBFyeIY"

-- Boss cần tìm
local BossList = {
    ["rip_indra True Form"] = true,
    ["Dough King"] = true,
    ["Cake Prince"] = true,
}

-- 🌐 Hàm gửi Webhook đẹp
local function sendWebhook(bossName, jobId, playerCount)
    local data = {
        ["username"] = "Boss Notify",
        ["avatar_url"] = "https://i.imgur.com/fYV4hXy.png", 
        ["embeds"] = {{
            ["title"] = "⚔️ Boss Spawn Detected!",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "👹 Boss Name", ["value"] = bossName, ["inline"] = true},
                {["name"] = "👥 Players", ["value"] = tostring(playerCount).."/12", ["inline"] = true},
                {["name"] = "🆔 JobId", ["value"] = "`"..jobId.."`"}
            },
            ["footer"] = {
                ["text"] = "Boss Finder | Blox Fruits",
                ["icon_url"] = "https://i.imgur.com/z6pRskh.png"
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }
    local jsonData = HttpService:JSONEncode(data)

    local success, err = pcall(function()
        if syn and syn.request then
            syn.request({Url=WEBHOOK_URL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=jsonData})
        elseif request then
            request({Url=WEBHOOK_URL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=jsonData})
        elseif http_request then
            http_request({Url=WEBHOOK_URL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=jsonData})
        end
    end)
    if not success then warn("Webhook Error:", err) end
end

-- 🎨 Tạo GUI
local ScreenGui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
ScreenGui.Name = "BossNotifyGUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 450, 0, 250)
Frame.Position = UDim2.new(0.02, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 2
Frame.BackgroundTransparency = 0.1

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
Title.Text = "🔥 Boss Notify - Log"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1, -10, 1, -45)
Scroll.Position = UDim2.new(0, 5, 0, 40)
Scroll.CanvasSize = UDim2.new(0,0,20,0)
Scroll.BackgroundTransparency = 0.3
Scroll.ScrollBarThickness = 6

-- Hàm thêm thông báo vào menu trong game
local function addLog(bossName, jobId, playerCount)
    local Log = Instance.new("TextLabel", Scroll)
    Log.Size = UDim2.new(1, -5, 0, 30)
    Log.Position = UDim2.new(0, 5, 0, #Scroll:GetChildren()*35)
    Log.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Log.TextColor3 = Color3.fromRGB(255, 200, 200)
    Log.Font = Enum.Font.SourceSansBold
    Log.TextSize = 18
    Log.TextXAlignment = Enum.TextXAlignment.Left
    Log.Text = "[Boss Notify] "..bossName.." | "..playerCount.."/12 | JobId: "..string.sub(jobId,1,8).."..."
end

-- ✅ Check boss trong server
local function checkServer(serverData)
    local jobId = serverData.id
    local playerCount = serverData.playing
    -- Ở đây giả sử quét boss trong workspace.Enemies
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, mob in pairs(enemies:GetChildren()) do
            if BossList[mob.Name] then
                -- Gửi Discord + Thêm log Roblox
                addLog(mob.Name, jobId, playerCount)
                sendWebhook(mob.Name, jobId, playerCount)
            end
        end
    end
end

-- 🌍 Quét server siêu nhanh
local function fetchServers(cursor)
    local url = "https://games.roblox.com/v1/games/7449423635/servers/Public?sortOrder=Desc&limit=100"
    if cursor then url = url.."&cursor="..cursor end
    local response = HttpService:JSONDecode(game:HttpGet(url))
    for _, server in pairs(response.data) do
        if server.playing < server.maxPlayers then
            task.spawn(function()
                checkServer(server)
            end)
        end
    end
    if response.nextPageCursor then
        task.spawn(function() fetchServers(response.nextPageCursor) end)
    end
end

-- 🚀 Chạy scan
task.spawn(function()
    fetchServers()
    game.StarterGui:SetCore("SendNotification",{
        Title = "Boss Notify",
        Text = "Đang quét server, log sẽ hiện trên màn hình.",
        Duration = 5
    })
end)
