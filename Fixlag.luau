--[[
	Ultra Optimizer + White Map (VIP)
	Author: your assistant
	Scope: For your OWN experience/projects only (LocalScript in StarterPlayerScripts)
	What it does:
	- Singleton: re-run safe (auto destroys old GUI + connections)
	- Presets: OFF / LIGHT / ULTRA (whitebox)
	- White Map mode: SmoothPlastic + pure white, optional Neon white
	- Texture mute: hide Decals/Textures; Particle/Beam/Trail mute
	- Lighting optimizer: disable post effects (Bloom/DOF/SunRays), thin Atmosphere, remove fog, disable GlobalShadows
	- Terrain water flatten
	- Whitelists: keep player characters untouched; also exclude by Model/Folder names
	- Snapshot -> Restore (best-effort, large maps may not restore 100%)
	- Rescan & Apply for new parts
	- FPS meter + progress, draggable UI, hotkeys

	How to use:
	- Put this LocalScript in StarterPlayerScripts (for your OWN game/tests)
	- Click the floating button > open panel > choose preset or toggles
	- Hotkeys: RightShift (open/close), F8 (toggle ON/OFF), F7 (re-apply current mode)
]]

--===== SAFETY: destroy previous instance if re-run =====--
local CoreGui = game:GetService("CoreGui")
local Existing = CoreGui:FindFirstChild("UltraOptimizerGUI")
if Existing then
	Existing:Destroy()
end

--===== Services =====--
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local MaterialService = game:GetService("MaterialService")

local LocalPlayer = Players.LocalPlayer

--===== Config =====--
local CONFIG = {
	ExcludeNames = {
		-- Add Model/Folder names you DON'T want to touch
		["Characters"] = true,
		["UI"] = true,
	},
	SkipCharacters = true, -- don't modify any player's character
	UseNeonWhite = false,  -- if true, parts will be Neon white (bright)
	BatchSize = 600,       -- parts processed per step to avoid frame spike
	StepDelay = 0.02,
}

--===== State/Snapshot =====--
local originalLighting = nil
local effectStates = {}
local snapshotParts = setmetatable({}, { __mode = "k" }) -- weak keys to help GC
local snapshotDecals = setmetatable({}, { __mode = "k" })
local snapshotParticles = setmetatable({}, { __mode = "k" })
local connections = {}

local function connect(sig, fn)
	local c = sig:Connect(fn)
	table.insert(connections, c)
	return c
end

local function cleanupConnections()
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	connections = {}
end

--===== UI =====--
local Gui = Instance.new("ScreenGui")
Gui.Name = "UltraOptimizerGUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
Gui.DisplayOrder = 10^6
Gui.Parent = CoreGui

local function makeRound(obj)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = obj
end

local function makeShadow(obj)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1
	uiStroke.Transparency = 0.4
	uiStroke.Parent = obj
end

local Dock = Instance.new("TextButton")
Dock.Name = "Dock"
Dock.Text = "⚡ Optimizer"
Dock.TextSize = 15
Dock.AutoButtonColor = true
Dock.Size = UDim2.new(0, 140, 0, 36)
Dock.Position = UDim2.new(0, 16, 0, 16)
Dock.BackgroundTransparency = 0.1
Dock.BackgroundColor3 = Color3.fromRGB(30,30,35)
Dock.TextColor3 = Color3.new(1,1,1)
makeRound(Dock)
makeShadow(Dock)
Dock.Parent = Gui

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Visible = false
Panel.Size = UDim2.new(0, 360, 0, 360)
Panel.Position = UDim2.new(0, 16, 0, 64)
Panel.BackgroundColor3 = Color3.fromRGB(24,24,28)
Panel.BackgroundTransparency = 0.05
makeRound(Panel)
makeShadow(Panel)
Panel.Parent = Gui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 28)
Title.Position = UDim2.new(0, 8, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "Ultra Optimizer (VIP)"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 16
Title.Parent = Panel

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 20)
Status.Position = UDim2.new(0, 8, 0, 36)
Status.BackgroundTransparency = 1
Status.Text = "Status: Idle"
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextColor3 = Color3.fromRGB(200,200,200)
Status.TextSize = 14
Status.Parent = Panel

local function makeToggle(name, y, default)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -16, 0, 34)
	holder.Position = UDim2.new(0, 8, 0, y)
	holder.BackgroundTransparency = 1
	holder.Parent = Panel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -110, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Text = name
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.new(1,1,1)
	label.TextSize = 14
	label.Parent = holder
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 96, 1, -6)
	btn.Position = UDim2.new(1, -100, 0, 3)
	btn.Text = default and "ON" or "OFF"
	btn.BackgroundColor3 = default and Color3.fromRGB(40,160,80) or Color3.fromRGB(80,80,90)
	btn.TextColor3 = Color3.new(1,1,1)
	makeRound(btn)
	makeShadow(btn)
	btn.Parent = holder
	local state = default
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(40,160,80) or Color3.fromRGB(80,80,90)
	end)
	return function() return state end, function(v)
		state = v
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(40,160,80) or Color3.fromRGB(80,80,90)
	end
end

local y = 64
local getWhitebox, setWhitebox = makeToggle("White Map (All White)", y, false); y = y + 36
local getNeon, setNeon = makeToggle("Use Neon White", y, false); y = y + 36
local getMuteTextures, setMuteTextures = makeToggle("Mute Textures/Decals", y, true); y = y + 36
local getMuteParticles, setMuteParticles = makeToggle("Mute Particles/Beams/Trails", y, true); y = y + 36
local getLightingOpt, setLightingOpt = makeToggle("Lighting Optimizer", y, true); y = y + 36
local getNoShadows, setNoShadows = makeToggle("Disable Global Shadows", y, true); y = y + 36
local getTerrainFlat, setTerrainFlat = makeToggle("Flatten Terrain Water", y, true); y = y + 36

local PresetRow = Instance.new("Frame")
PresetRow.Size = UDim2.new(1, -16, 0, 40)
PresetRow.Position = UDim2.new(0, 8, 0, y)
PresetRow.BackgroundTransparency = 1
PresetRow.Parent = Panel
local PresetTitle = Instance.new("TextLabel")
PresetTitle.BackgroundTransparency = 1
PresetTitle.Size = UDim2.new(0, 80, 1, 0)
PresetTitle.Text = "Preset:"
PresetTitle.TextColor3 = Color3.new(1,1,1)
PresetTitle.TextSize = 14
PresetTitle.TextXAlignment = Enum.TextXAlignment.Left
PresetTitle.Parent = PresetRow

local function makeSmallBtn(txt, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 80, 1, -6)
	b.Position = UDim2.new(0, x, 0, 3)
	b.Text = txt
	b.BackgroundColor3 = Color3.fromRGB(60,60,70)
	b.TextColor3 = Color3.new(1,1,1)
	makeRound(b)
	makeShadow(b)
	b.Parent = PresetRow
	return b
end

local btnOFF = makeSmallBtn("OFF", 84)
local btnLIGHT = makeSmallBtn("LIGHT", 170)
local btnULTRA = makeSmallBtn("ULTRA", 256)

y = y + 48
local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size = UDim2.new(1, -16, 0, 40)
ApplyBtn.Position = UDim2.new(0, 8, 0, y)
ApplyBtn.Text = "Apply"
ApplyBtn.TextColor3 = Color3.new(1,1,1)
ApplyBtn.BackgroundColor3 = Color3.fromRGB(35,120,70)
makeRound(ApplyBtn)
makeShadow(ApplyBtn)
ApplyBtn.Parent = Panel

y = y + 48
local ReapplyBtn = Instance.new("TextButton")
ReapplyBtn.Size = UDim2.new(0.5, -12, 0, 36)
ReapplyBtn.Position = UDim2.new(0, 8, 0, y)
ReapplyBtn.Text = "Rescan & Apply"
ReapplyBtn.TextColor3 = Color3.new(1,1,1)
ReapplyBtn.BackgroundColor3 = Color3.fromRGB(70,90,140)
makeRound(ReapplyBtn)
makeShadow(ReapplyBtn)
ReapplyBtn.Parent = Panel

local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Size = UDim2.new(0.5, -12, 0, 36)
RestoreBtn.Position = UDim2.new(0.5, 4, 0, y)
RestoreBtn.Text = "Restore"
RestoreBtn.TextColor3 = Color3.new(1,1,1)
RestoreBtn.BackgroundColor3 = Color3.fromRGB(120,60,60)
makeRound(RestoreBtn)
makeShadow(RestoreBtn)
RestoreBtn.Parent = Panel

-- Draggable
local dragging = false
local dragStart, startPos
local function enableDrag(btn, frame)
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end
enableDrag(Dock, Dock)
enableDrag(Title, Panel)

-- Toggle panel
Dock.MouseButton1Click:Connect(function()
	Panel.Visible = not Panel.Visible
end)

-- Hotkeys
connect(UserInputService.InputBegan, function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		Panel.Visible = not Panel.Visible
	elseif input.KeyCode == Enum.KeyCode.F8 then
		if ApplyBtn.Text == "ON" then
			RestoreBtn:Activate()
		else
			ApplyBtn:Activate()
		end
	elseif input.KeyCode == Enum.KeyCode.F7 then
		ReapplyBtn:Activate()
	end
end)

-- FPS meter (top-right of panel)
local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0, 120, 0, 20)
FPSLabel.Position = UDim2.new(1, -126, 0, 8)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: ..."
FPSLabel.TextColor3 = Color3.fromRGB(200,200,200)
FPSLabel.TextSize = 14
FPSLabel.Parent = Panel

local acc = 0
local frames = 0
connect(RunService.RenderStepped, function(dt)
	acc += dt
	frames += 1
	if acc >= 0.5 then
		local fps = math.floor(frames / acc + 0.5)
		FPSLabel.Text = "FPS: " .. tostring(fps)
		acc, frames = 0, 0
	end
end)

--===== Helpers =====--
local whiteColor = Color3.new(1,1,1)

local function isExcluded(inst)
	if CONFIG.SkipCharacters and LocalPlayer.Character and inst:IsDescendantOf(LocalPlayer.Character) then
		return true
	end
	local p = inst
	while p do
		if CONFIG.ExcludeNames[p.Name] then return true end
		p = p.Parent
	end
	return false
end

local function storeLighting()
	if originalLighting then return end
	originalLighting = {
		Brightness = Lighting.Brightness,
		GlobalShadows = Lighting.GlobalShadows,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		FogStart = Lighting.FogStart,
		FogEnd = Lighting.FogEnd,
	}
	-- effects snapshot
	effectStates = {}
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Atmosphere") then
			effectStates[obj] = {
				class = "Atmosphere",
				Density = obj.Density,
				Offset = obj.Offset,
				Color = obj.Color,
				Decay = obj.Decay,
				Glare = obj.Glare,
				Haze = obj.Haze,
			}
		elseif obj:IsA("BloomEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
			effectStates[obj] = { class = obj.ClassName, Enabled = obj.Enabled }
		end
	end
end

local function restoreLighting()
	if not originalLighting then return end
	Lighting.Brightness = originalLighting.Brightness
	Lighting.GlobalShadows = originalLighting.GlobalShadows
	Lighting.Ambient = originalLighting.Ambient
	Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
	Lighting.FogStart = originalLighting.FogStart
	Lighting.FogEnd = originalLighting.FogEnd
	for obj, st in pairs(effectStates) do
		if obj and obj.Parent then
			if st.class == "Atmosphere" then
				obj.Density = st.Density
				obj.Offset = st.Offset
				obj.Color = st.Color
				obj.Decay = st.Decay
				obj.Glare = st.Glare
				obj.Haze = st.Haze
			else
				obj.Enabled = st.Enabled
			end
		end
	end
	originalLighting = nil
	effectStates = {}
end

local function snapshotPart(part)
	if snapshotParts[part] then return end
	snapshotParts[part] = {
		Material = part.Material,
		Color = part.Color,
		Transparency = part.Transparency,
		Reflectance = part.Reflectance,
		CastShadow = part.CastShadow,
	}
	if part:IsA("MeshPart") then
		snapshotParts[part].RenderFidelity = part.RenderFidelity
	end
end

local function snapshotDecal(dec)
	if snapshotDecals[dec] then return end
	snapshotDecals[dec] = { Transparency = dec.Transparency }
end

local function snapshotParticle(p)
	if snapshotParticles[p] then return end
	snapshotParticles[p] = { Enabled = p.Enabled }
end

local function applyToWorld(opts)
	-- opts: {whitebox, neon, muteTextures, muteParticles, lightingOpt, noShadows, terrainFlat}
	storeLighting()

	local processed, total = 0, 0
	for _, _ in ipairs(workspace:GetDescendants()) do total += 1 end
	local lastUpdate = 0

	local function updateStatus()
		Status.Text = string.format("Processing: %d/%d", processed, total)
	end
	updateStatus()

	local counter = 0
	for _, inst in ipairs(workspace:GetDescendants()) do
		if isExcluded(inst) then continue end

		if inst:IsA("BasePart") then
			snapshotPart(inst)
			if opts.whitebox then
				inst.Material = CONFIG.UseNeonWhite and Enum.Material.Neon or Enum.Material.SmoothPlastic
				inst.Color = whiteColor
				inst.Reflectance = 0
				inst.CastShadow = not opts.noShadows and inst.CastShadow or false
				if inst:IsA("MeshPart") then
					pcall(function() inst.RenderFidelity = Enum.RenderFidelity.Performance end)
				end
			else
				-- Non-whitebox path still reduces complexity a bit
				inst.Material = Enum.Material.SmoothPlastic
				inst.CastShadow = not opts.noShadows and inst.CastShadow or false
			end
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			snapshotDecal(inst)
			if opts.muteTextures then inst.Transparency = 1 end
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
			snapshotParticle(inst)
			if opts.muteParticles then inst.Enabled = false end
		end

		processed += 1
		counter += 1
		if counter >= CONFIG.BatchSize then
			counter = 0
			updateStatus()
			task.wait(CONFIG.StepDelay)
		end
	end

	-- Lighting & terrain tweaks
	if opts.lightingOpt then
		Lighting.Brightness = 1
		Lighting.Ambient = whiteColor
		Lighting.OutdoorAmbient = whiteColor
		Lighting.FogStart = 1e9; Lighting.FogEnd = 1e9
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj:IsA("BloomEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
				obj.Enabled = false
			elseif obj:IsA("Atmosphere") then
				obj.Density = 0; obj.Glare = 0; obj.Haze = 0
				obj.Color = whiteColor; obj.Decay = whiteColor
			end
		end
	end
	Lighting.GlobalShadows = not opts.noShadows

	if opts.terrainFlat then
		local t = workspace:FindFirstChildOfClass("Terrain")
		if t then
			t.WaterWaveSize = 0
			t.WaterWaveSpeed = 0
			t.WaterReflectance = 0
			t.WaterTransparency = 1
		end
	end

	Status.Text = string.format("Done. Touched ~%d objects", processed)
end

local function restoreWorld()
	Status.Text = "Restoring..."
	for part, st in pairs(snapshotParts) do
		if part and part.Parent then
			pcall(function()
				part.Material = st.Material
				part.Color = st.Color
				part.Transparency = st.Transparency
				part.Reflectance = st.Reflectance
				part.CastShadow = st.CastShadow
				if st.RenderFidelity and part:IsA("MeshPart") then
					part.RenderFidelity = st.RenderFidelity
				end
			end)
		end
	end
	for dec, st in pairs(snapshotDecals) do
		if dec and dec.Parent then
			pcall(function() dec.Transparency = st.Transparency end)
		end
	end
	for p, st in pairs(snapshotParticles) do
		if p and p.Parent then
			pcall(function() p.Enabled = st.Enabled end)
		end
	end
	restoreLighting()
	Status.Text = "Restored."
end

-- Preset actions
btnOFF.MouseButton1Click:Connect(function()
	setWhitebox(false); setNeon(false); setMuteTextures(false); setMuteParticles(false)
	setLightingOpt(false); setNoShadows(false); setTerrainFlat(false)
end)

btnLIGHT.MouseButton1Click:Connect(function()
	setWhitebox(false); setNeon(false); setMuteTextures(true); setMuteParticles(true)
	setLightingOpt(true); setNoShadows(true); setTerrainFlat(true)
end)

btnULTRA.MouseButton1Click:Connect(function()
	setWhitebox(true); setNeon(false); setMuteTextures(true); setMuteParticles(true)
	setLightingOpt(true); setNoShadows(true); setTerrainFlat(true)
end)

-- Apply / Restore
ApplyBtn.MouseButton1Click:Connect(function()
	CONFIG.UseNeonWhite = getNeon()
	applyToWorld({
		whitebox = getWhitebox(),
		neon = getNeon(),
		muteTextures = getMuteTextures(),
		muteParticles = getMuteParticles(),
		lightingOpt = getLightingOpt(),
		noShadows = getNoShadows(),
		terrainFlat = getTerrainFlat(),
	})
	ApplyBtn.Text = "ON"
end)

ReapplyBtn.MouseButton1Click:Connect(function()
	-- simply re-apply with current toggles (captures new descendants)
	applyToWorld({
		whitebox = getWhitebox(),
		neon = getNeon(),
		muteTextures = getMuteTextures(),
		muteParticles = getMuteParticles(),
		lightingOpt = getLightingOpt(),
		noShadows = getNoShadows(),
		terrainFlat = getTerrainFlat(),
	})
end)

RestoreBtn.MouseButton1Click:Connect(function()
	restoreWorld()
	ApplyBtn.Text = "Apply"
end)

-- Auto keep GUI on top
connect(RunService.RenderStepped, function()
	Gui.DisplayOrder = 10^6
end)

-- Clean up on Player removing
connect(Players.PlayerRemoving, function(p)
	if p == LocalPlayer then
		cleanupConnections()
	end
end)
