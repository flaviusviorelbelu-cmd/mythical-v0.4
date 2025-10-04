-- Enhanced Tabbed Lunar Garden UI LocalScript
-- Place this in StarterPlayer > StarterPlayerScripts

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local PlantSeed    = ReplicatedStorage:WaitForChild("PlantSeed")
local BuySeed      = ReplicatedStorage:WaitForChild("BuySeed")
local SellHarvest  = ReplicatedStorage:WaitForChild("SellHarvest")
local UpdateData   = ReplicatedStorage:WaitForChild("UpdatePlayerData")

-- Player data
local playerData = { coins = 0, seeds = {}, plants = {}, harvest = {}, experience = 0 }

-- Plant definitions
local PLANT_DATA = {
	{ type="carrot",    price=5,  sell=8,  emoji="🥕", cat="basic" },
	{ type="potato",    price=7,  sell=12, emoji="🥔", cat="basic" },
	{ type="wheat",     price=3,  sell=6,  emoji="🌾", cat="basic" },
	{ type="moonberry", price=12, sell=20, emoji="🌙", cat="lunar" },
	{ type="stardust",  price=8,  sell=14, emoji="✨", cat="lunar" },
	{ type="nebula",    price=15, sell=25, emoji="🌌", cat="lunar" },
	{ type="cosmic",    price=10, sell=18, emoji="⭐", cat="lunar" },
	{ type="asteroid",  price=20, sell=35, emoji="☄️", cat="lunar" },
	{ type="solar",     price=6,  sell=11, emoji="☀️", cat="lunar" },
}

-- Tabs
local TABS = {
	{ name="Garden",  icon="🌱", color=Color3.fromRGB(46,204,113) },
	{ name="Seeds",   icon="🌰", color=Color3.fromRGB(52,152,219) },
	{ name="Shop",    icon="🛒", color=Color3.fromRGB(155,89,182) },
	{ name="Harvest", icon="🧺", color=Color3.fromRGB(230,126,34) },
	{ name="Stats",   icon="📊", color=Color3.fromRGB(231,76,60) },
}

-- UI references
local screenGui, mainFrame, closeBtn, toggleBtn
local tabButtons, tabFrames = {}, {}
local plotButtons, seedButtons = {}, {}
local coinsLabel, experienceLabel
local currentTab, selectedSeed = "Garden", "carrot"
local guiVisible = true

-- Refresh Garden tab
local function refreshGarden()
	for i, btn in ipairs(plotButtons) do
		local pd = playerData.plants[tostring(i)]
		if pd then
			btn.Text = pd.type:upper()
			btn.BackgroundColor3 = Color3.fromRGB(0,150,0)
		else
			btn.Text = "Empty"
			btn.BackgroundColor3 = Color3.fromRGB(101,67,33)
		end
	end
end

-- Switch tabs
local function switchTab(name)
	currentTab = name
	for tabName, frame in pairs(tabFrames) do
		frame.Visible = (tabName == name)
	end
	for _, info in ipairs(TABS) do
		local btn = tabButtons[info.name]
		btn.BackgroundColor3 = (info.name == name and Color3.fromRGB(0,200,100) or info.color)
	end

	if name == "Garden" then
		refreshGarden()
	elseif name == "Seeds" then
		for _, p in ipairs(PLANT_DATA) do
			local b = seedButtons[p.type]
			b.Text = p.emoji.." "..p.type:upper().." ("..(playerData.seeds[p.type] or 0)..")"
		end
	elseif name == "Shop" then
		local sf = tabFrames.Shop
		sf:ClearAllChildren()
		local y = 10
		for _, p in ipairs(PLANT_DATA) do
			local b = Instance.new("TextButton", sf)
			b.Size = UDim2.new(0.9,0,0,40)
			b.Position = UDim2.new(0.05,0,0,y)
			b.Text = p.emoji.." BUY "..p.type:upper().." - "..p.price.."🪙"
			b.TextScaled = true; b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.new(1,1,1)
			b.BackgroundColor3 = (p.cat=="lunar" and Color3.fromRGB(155,89,182) or Color3.fromRGB(46,204,113))
			b.BorderSizePixel = 0; b.AutoButtonColor = false
			b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundTransparency=0.5}):Play() end)
			b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundTransparency=0}):Play() end)
			b.MouseButton1Click:Connect(function() BuySeed:FireServer(p.type) end)
			y = y + 50
		end
		sf.CanvasSize = UDim2.new(0,0,0,y)
	elseif name == "Harvest" then
		local hf = tabFrames.Harvest
		hf:ClearAllChildren()
		local y = 10
		for _, p in ipairs(PLANT_DATA) do
			local cnt = playerData.harvest[p.type] or 0
			local b = Instance.new("TextButton", hf)
			b.Size = UDim2.new(0.95,0,0,40)
			b.Position = UDim2.new(0.025,0,0,y)
			b.Text = p.emoji.." "..p.type:upper().." ("..cnt..") - SELL "..p.sell.."🪙"
			b.TextScaled = true; b.Font = Enum.Font.GothamBold
			b.BackgroundColor3 = (cnt>0 and Color3.fromRGB(230,126,34) or Color3.fromRGB(100,100,100))
			b.BorderSizePixel = 0
			if cnt>0 then
				b.MouseButton1Click:Connect(function() SellHarvest:FireServer(p.type,cnt) end)
			end
			y = y + 50
		end
		hf.CanvasSize = UDim2.new(0,0,0,y)
	elseif name == "Stats" then
		coinsLabel.Text = "🪙 "..(playerData.coins or 0)
		experienceLabel.Text = "⭐ XP: "..(playerData.experience or 0)
	end
end

-- Create Garden tab
local function createGardenTab(parent)
	local frame = Instance.new("Frame", parent)
	frame.Name = "Garden"
	frame.Size = UDim2.new(1,0,1,0)
	frame.BackgroundTransparency = 1
	tabFrames.Garden = frame

	for i = 1, 9 do
		local btn = Instance.new("TextButton", frame)
		btn.Name = "Plot"..i
		btn.Size = UDim2.new(0.3,-8,0.25,-8)
		btn.Position = UDim2.new(((i-1)%3)*0.33+0.02,0,math.floor((i-1)/3)*0.3+0.02,0)
		btn.Text = "Empty"
		btn.TextScaled = true
		btn.Font = Enum.Font.SourceSansBold
		btn.TextColor3 = Color3.new(1,1,1)
		btn.BackgroundColor3 = Color3.fromRGB(101,67,33)
		btn.BorderSizePixel = 0
		btn.MouseButton1Click:Connect(function()
			PlantSeed:FireServer(i, selectedSeed)
		end)
		plotButtons[i] = btn
	end
end

-- Create Seeds tab
local function createSeedTab(parent)
	local sf = Instance.new("ScrollingFrame", parent)
	sf.Name = "Seeds"
	sf.Size = UDim2.new(1,0,1,0)
	sf.ScrollBarThickness = 6
	sf.BackgroundTransparency = 1
	sf.Visible = false
	tabFrames.Seeds = sf

	local grid = Instance.new("UIGridLayout", sf)
	grid.CellSize = UDim2.new(0,120,0,120)
	grid.CellPadding = UDim2.new(0,10,0,10)
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.SortOrder = Enum.SortOrder.LayoutOrder

	for _, p in ipairs(PLANT_DATA) do
		local b = Instance.new("TextButton", sf)
		b.Name = p.type
		b.Text = p.emoji.." "..p.type:upper().." ("..(playerData.seeds[p.type] or 0)..")"
		b.TextScaled = true
		b.Font = Enum.Font.SourceSansBold
		b.TextColor3 = Color3.new(1,1,1)
		b.BackgroundColor3 = (p.cat=="lunar" and Color3.fromRGB(155,89,182) or Color3.fromRGB(46,204,113))
		b.BorderSizePixel = 0
		seedButtons[p.type] = b
		b.MouseButton1Click:Connect(function()
			selectedSeed = p.type
			switchTab("Seeds")
		end)
	end

	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sf.CanvasSize = UDim2.new(0,0,0,grid.AbsoluteContentSize.Y)
	end)
end

-- Create Shop tab
local function createShopTab(parent)
	local sf = Instance.new("ScrollingFrame", parent)
	sf.Name = "Shop"
	sf.Size = UDim2.new(1,0,1,0)
	sf.BackgroundTransparency = 1
	sf.Visible = false
	sf.ScrollBarThickness = 6
	tabFrames.Shop = sf
end

-- Create Harvest tab
local function createHarvestTab(parent)
	local hf = Instance.new("ScrollingFrame", parent)
	hf.Name = "Harvest"
	hf.Size = UDim2.new(1,0,1,0)
	hf.BackgroundTransparency = 1
	hf.Visible = false
	hf.ScrollBarThickness = 6
	tabFrames.Harvest = hf
end

-- Create Stats tab
local function createStatsTab(parent)
	local st = Instance.new("Frame", parent)
	st.Name = "Stats"
	st.Size = UDim2.new(1,0,1,0)
	st.BackgroundTransparency = 1
	st.Visible = false
	tabFrames.Stats = st

	coinsLabel = Instance.new("TextLabel", st)
	coinsLabel.Size = UDim2.new(0.8,0,0.1,0)
	coinsLabel.Position = UDim2.new(0.1,0,0.1,0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.SourceSansBold
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.TextColor3 = Color3.fromRGB(255,215,0)

	experienceLabel = Instance.new("TextLabel", st)
	experienceLabel.Size = UDim2.new(0.8,0,0.1,0)
	experienceLabel.Position = UDim2.new(0.1,0,0.25,0)
	experienceLabel.TextScaled = true
	experienceLabel.Font = Enum.Font.SourceSansBold
	experienceLabel.BackgroundTransparency = 1
	experienceLabel.TextColor3 = Color3.fromRGB(144,238,144)
end

-- Build the full UI
local function createUI()
	screenGui = Instance.new("ScreenGui", playerGui)
	screenGui.ResetOnSpawn = false

	mainFrame = Instance.new("Frame", screenGui)
	mainFrame.Size = UDim2.new(0.95,0,0.9,0)
	mainFrame.Position = UDim2.new(0.025,0,0.05,0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,35)
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,15)

	closeBtn = Instance.new("TextButton", mainFrame)
	closeBtn.Size = UDim2.new(0,35,0,35)
	closeBtn.Position = UDim2.new(1,-40,0,5)
	closeBtn.Text = "✖"
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.SourceSansBold
	closeBtn.BackgroundColor3 = Color3.fromRGB(220,20,60)
	closeBtn.BorderSizePixel = 0
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.5,0)
	closeBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		toggleBtn.Visible = true
	end)

	local title = Instance.new("TextLabel", mainFrame)
	title.Size = UDim2.new(0.7,0,0.08,0)
	title.Position = UDim2.new(0.05,0,0.02,0)
	title.Text = "🌙 LUNAR GARDEN 🌙"
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.TextColor3 = Color3.fromRGB(180,180,255)
	title.BackgroundTransparency = 1

	local bar = Instance.new("Frame", mainFrame)
	bar.Size = UDim2.new(1,0,0.1,0)
	bar.Position = UDim2.new(0,0,0.1,0)
	bar.BackgroundColor3 = Color3.fromRGB(40,40,60)
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0,8)

	for i, info in ipairs(TABS) do
		local b = Instance.new("TextButton", bar)
		b.Name = info.name
		b.Size = UDim2.new(1/#TABS,-4,0.7,0)
		b.Position = UDim2.new((i-1)/#TABS,2,0.15,0)
		b.Text = info.icon.."\n"..info.name
		b.TextScaled = true
		b.Font = Enum.Font.SourceSansBold
		b.TextColor3 = Color3.new(1,1,1)
		b.BackgroundColor3 = info.color
		b.BorderSizePixel = 0
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		tabButtons[info.name] = b
		b.MouseButton1Click:Connect(function()
			switchTab(info.name)
		end)
	end

	local content = Instance.new("Frame", mainFrame)
	content.Size = UDim2.new(1,0,0.76,0)
	content.Position = UDim2.new(0,0,0.24,0)
	content.BackgroundTransparency = 1

	createGardenTab(content)
	createS
Tab(content)
	createShopTab(content)
	createHarvestTab(content)
	createStatsTab(content)

	toggleBtn = Instance.new("TextButton", screenGui)
	toggleBtn.Size = UDim2.new(0,60,0,60)
	toggleBtn.Position = UDim2.new(0,20,0,20)
	toggleBtn.Text = "🌱"
	toggleBtn.TextScaled = true
	toggleBtn.Font = Enum.Font.SourceSansBold
	toggleBtn.TextColor3 = Color3.new(1,1,1)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(75,0,130)
	toggleBtn.BorderSizePixel = 0
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,15)
	toggleBtn.MouseButton1Click:Connect(function()
		guiVisible = not guiVisible
		mainFrame.Visible = guiVisible
		toggleBtn.Visible = not guiVisible
	end)

	switchTab("Garden")
end

-- Update UI on data change
UpdateData.OnClientEvent:Connect(function(data)
	playerData = data
	if currentTab == "Garden" then
		refreshGarden()
	end
	switchTab(currentTab)
end)

-- Keyboard toggle
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G then
		guiVisible = not guiVisible
		mainFrame.Visible = guiVisible
		toggleBtn.Visible = not guiVisible
	elseif input.KeyCode == Enum.KeyCode.Escape and guiVisible then
		guiVisible = false
		mainFrame.Visible = false
		toggleBtn.Visible = true
	end
end)

-- Initialize
createUI()