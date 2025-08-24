--[[
	Ultra Optimizer + White Map + Anti-Kick (Always On)
	Author: your assistant
	Scope: For your OWN experience/projects only (LocalScript in StarterPlayerScripts)
	Features:
	- Always runs at start, no menu, no toggle.
	- Anti-kick protection.
	- White map: SmoothPlastic + white color for all map parts.
	- Removes decals/textures.
	- Disables particles/beams/trails.
	- Optimizes Lighting (remove effects, fog, global shadows).
	- Flattens terrain water.
	- Excludes player characters.
]]

--===== Services =====--
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local whiteColor = Color3.new(1,1,1)

--===== Anti-Kick =====--
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
	local method = getnamecallmethod()
	if method == "Kick" or method == "kick" then
		return nil -- block kick attempts
	end
	return oldNamecall(self, ...)
end)

setreadonly(mt, true)

--===== Optimizer =====--
local function isExcluded(inst)
	if LocalPlayer.Character and inst:IsDescendantOf(LocalPlayer.Character) then
		return true
	end
	return false
end

local function applyUltra()
	-- Lighting tweaks
	Lighting.Brightness = 1
	Lighting.Ambient = whiteColor
	Lighting.OutdoorAmbient = whiteColor
	Lighting.FogStart = 1e9; Lighting.FogEnd = 1e9
	Lighting.GlobalShadows = false

	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("BloomEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
			obj.Enabled = false
		elseif obj:IsA("Atmosphere") then
			obj.Density = 0; obj.Glare = 0; obj.Haze = 0
			obj.Color = whiteColor; obj.Decay = whiteColor
		end
	end

	-- Terrain tweaks
	local t = workspace:FindFirstChildOfClass("Terrain")
	if t then
		t.WaterWaveSize = 0
		t.WaterWaveSpeed = 0
		t.WaterReflectance = 0
		t.WaterTransparency = 1
	end

	-- World parts
	for _, inst in ipairs(workspace:GetDescendants()) do
		if isExcluded(inst) then continue end
		if inst:IsA("BasePart") then
			inst.Material = Enum.Material.SmoothPlastic
			inst.Color = whiteColor
			inst.Reflectance = 0
			inst.CastShadow = false
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			inst.Transparency = 1
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
			inst.Enabled = false
		end
	end
end

-- Run once at start
task.defer(applyUltra)

-- Auto apply on new parts added
workspace.DescendantAdded:Connect(function(inst)
	task.defer(function()
		if isExcluded(inst) then return end
		if inst:IsA("BasePart") then
			inst.Material = Enum.Material.SmoothPlastic
			inst.Color = whiteColor
			inst.Reflectance = 0
			inst.CastShadow = false
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			inst.Transparency = 1
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
			inst.Enabled = false
		end
	end)
end)
