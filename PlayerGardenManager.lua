-- PlayerGardenManager Module
-- Place this as a ModuleScript in ServerScriptService

local PlayerGardenManager = {}

-- Services
local Players = game:GetService("Players")

-- Require DataManager
local DataManager = require(game.ServerScriptService.DataManager)

-- Garden management
local playerGardens = {}
local availableGardens = {1, 2, 3, 4, 5, 6, 7, 8} -- Max 8 players

-- Assign garden to player
function PlayerGardenManager.AssignGarden(player)
	if #availableGardens == 0 then
		player:Kick("Server is full! Please try again later.")
		return nil
	end

	local gardenId = table.remove(availableGardens, 1)
	playerGardens[player.UserId] = gardenId

	-- Update player data
	local playerData = DataManager.GetPlayerData(player)
	if playerData then
		playerData.gardenId = gardenId
		DataManager.SavePlayerData(player, playerData)
	end

	print("Assigned garden", gardenId, "to", player.Name)
	return gardenId
end

-- Plant seed function
function PlayerGardenManager.PlantSeed(player, plotId, seedType)
	local playerData = DataManager.GetPlayerData(player)

	if not playerData then
		return false, "Player data not found"
	end

	-- Check if player has seeds
	if not playerData.seeds[seedType] or playerData.seeds[seedType] <= 0 then
		return false, "No " .. seedType .. " seeds available"
	end

	-- Check if plot is empty
	if playerData.plants[tostring(plotId)] then
		return false, "Plot " .. plotId .. " is already occupied"
	end

	-- Plant the seed
	playerData.seeds[seedType] = playerData.seeds[seedType] - 1
	playerData.plants[tostring(plotId)] = {
		type = seedType,
		plantedAt = os.time(),
		stage = "planted"
	}

	-- Save data
	DataManager.SavePlayerData(player, playerData)

	return true, "Successfully planted " .. seedType
end

-- Harvest plant function
function PlayerGardenManager.HarvestPlant(player, plotId)
	local playerData = DataManager.GetPlayerData(player)

	if not playerData then
		return false, "Player data not found"
	end

	local plant = playerData.plants[tostring(plotId)]
	if not plant then
		return false, "No plant on plot " .. plotId
	end

	-- Check if plant is ready (for now, always ready)
	local harvestAmount = math.random(1, 3)

	-- Add to inventory
	if not playerData.harvest then
		playerData.harvest = {}
	end
	playerData.harvest[plant.type] = (playerData.harvest[plant.type] or 0) + harvestAmount

	-- Remove plant
	playerData.plants[tostring(plotId)] = nil

	-- Save data
	DataManager.SavePlayerData(player, playerData)

	return true, "Harvested " .. harvestAmount .. " " .. plant.type
end

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	local gardenId = playerGardens[player.UserId]
	if gardenId then
		table.insert(availableGardens, gardenId)
		playerGardens[player.UserId] = nil
		print("Released garden", gardenId, "from", player.Name)
	end
end)

return PlayerGardenManager