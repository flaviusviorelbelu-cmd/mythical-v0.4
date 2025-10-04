-- RemoteEventHandler Script
-- Place this in ServerScriptService as a regular Script

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvents if they don't exist
local function createRemoteEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	return event
end

local function createBindableEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("BindableEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	return event
end

-- RemoteEvents
local UpdatePlayerData = createRemoteEvent("UpdatePlayerData")
local PlantSeed        = createRemoteEvent("PlantSeed")
local BuySeed          = createRemoteEvent("BuySeed")
local SellHarvest      = createRemoteEvent("SellHarvest")
local PlotDataChanged  = createBindableEvent("PlotDataChanged")

-- Require modules
local DataManager            = require(game.ServerScriptService.DataManager)
local PlayerGardenManager    = require(game.ServerScriptService.PlayerGardenManager)
local ShopManager            = require(game.ServerScriptService.ShopManager)

-- Handle planting seeds
PlantSeed.OnServerEvent:Connect(function(player, plotId, seedType)
	local success, message = PlayerGardenManager.PlantSeed(player, plotId, seedType)
	if success then
		UpdatePlayerData:FireClient(player, DataManager.GetPlayerData(player))
		PlotDataChanged:Fire(player.UserId, plotId)
	else
		warn("[PlantSeed] Failed:", message)
	end
end)

-- Handle buying seeds
BuySeed.OnServerEvent:Connect(function(player, seedType)
	local success, message = ShopManager.BuySeed(player, seedType)
	if success then
		UpdatePlayerData:FireClient(player, DataManager.GetPlayerData(player))
	else
		warn("[BuySeed] Failed:", message)
	end
end)

-- Handle selling harvested crops
SellHarvest.OnServerEvent:Connect(function(player, cropType, quantity)
	local success, message = ShopManager.SellHarvest(player, cropType, quantity)
	if success then
		UpdatePlayerData:FireClient(player, DataManager.GetPlayerData(player))
	else
		warn("[SellHarvest] Failed:", message)
	end
end)

-- Initialize player data and garden on join
Players.PlayerAdded:Connect(function(player)
	-- Initialize data
	local data = DataManager.InitializePlayer(player)
	-- Assign garden
	PlayerGardenManager.AssignGarden(player)
	-- Send initial data
	wait(1)
	UpdatePlayerData:FireClient(player, data)
end)

print("RemoteEventHandler loaded successfully!")