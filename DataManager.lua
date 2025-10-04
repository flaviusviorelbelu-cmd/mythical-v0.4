-- Enhanced DataManager Module with Pet Support
-- Place this as a ModuleScript in ServerScriptService
-- Updated to include pet and egg data

local DataManager = {}

-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerData_v2") -- Updated version for pets

-- Player data cache
local playerDataCache = {}

-- Enhanced default player data with pet system
local defaultPlayerData = {
	coins = 200,
	gems = 0, -- New premium currency
	gardenId = nil,
	seeds = {
		carrot = 5,
		potato = 3,
		wheat = 2,
		-- Add lunar plant seeds as starter
		moonberry = 1,
		stardust = 1
	},
	plants = {},
	harvest = {},
	level = 1,
	experience = 0,
	lastLogin = 0,

	-- Pet system data
	eggs = {}, -- {eggId = {type, purchaseTime, hatchTime, hatched}}
	pets = {}, -- {petId = {id, name, emoji, rarity, ability, value, description, level, experience, equipped, hatchTime}}
	equippedPets = {}, -- Array of equipped pet IDs (max 3)

	-- Items and resources
	items = {
		petFood = 10, -- Starting pet food
		fertilizer = 0,
		gems = 0
	},

	-- Pet statistics
	petStats = {
		totalHatched = 0,
		legendaryHatched = 0,
		petsOwned = 0,
		totalPetsSold = 0
	}
}

-- Deep copy function
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Initialize player data
function DataManager.InitializePlayer(player)
	local success, savedData = pcall(function()
		return playerDataStore:GetAsync(player.UserId)
	end)

	local playerData
	if success and savedData then
		-- Merge saved data with default data to ensure all fields exist
		playerData = deepCopy(defaultPlayerData)

		-- Recursive merge function to handle nested tables
		local function mergeData(default, saved)
			for key, value in pairs(saved) do
				if type(value) == "table" and type(default[key]) == "table" then
					mergeData(default[key], value)
				else
					default[key] = value
				end
			end
		end

		mergeData(playerData, savedData)
		print("Loaded enhanced data for", player.Name)
	else
		-- Use default data for new players
		playerData = deepCopy(defaultPlayerData)
		print("Created new enhanced data for", player.Name)
		if not success then
			warn("Failed to load data for", player.Name, ":", savedData)
		end
	end

	-- Update last login
	playerData.lastLogin = os.time()

	-- Ensure pet-related tables exist
	if not playerData.eggs then playerData.eggs = {} end
	if not playerData.pets then playerData.pets = {} end
	if not playerData.items then playerData.items = {petFood = 10, fertilizer = 0, gems = 0} end
	if not playerData.petStats then 
		playerData.petStats = {
			totalHatched = 0,
			legendaryHatched = 0,
			petsOwned = 0,
			totalPetsSold = 0
		}
	end

	-- Cache the data
	playerDataCache[player.UserId] = playerData

	-- Save the data
	DataManager.SavePlayerData(player, playerData)

	return playerData
end

-- Get player data
function DataManager.GetPlayerData(player)
	return playerDataCache[player.UserId]
end

-- Save player data
function DataManager.SavePlayerData(player, data)
	if not data then
		data = playerDataCache[player.UserId]
	end

	if not data then
		warn("No data to save for", player.Name)
		return false
	end

	-- Update cache
	playerDataCache[player.UserId] = data

	-- Save to DataStore
	local success, errorMessage = pcall(function()
		playerDataStore:SetAsync(player.UserId, data)
	end)

	if success then
		-- Only print saves every few minutes to reduce spam
		if not player:GetAttribute("lastSaveLog") or os.time() - player:GetAttribute("lastSaveLog") > 300 then
			print("Saved enhanced data for", player.Name)
			player:SetAttribute("lastSaveLog", os.time())
		end
		return true
	else
		warn("Failed to save data for", player.Name, ":", errorMessage)
		return false
	end
end

-- Update pet statistics
function DataManager.UpdatePetStats(player, statType, increment)
	local playerData = DataManager.GetPlayerData(player)
	if not playerData or not playerData.petStats then return end

	increment = increment or 1
	playerData.petStats[statType] = (playerData.petStats[statType] or 0) + increment

	DataManager.SavePlayerData(player, playerData)
end

-- Get pet statistics
function DataManager.GetPetStats(player)
	local playerData = DataManager.GetPlayerData(player)
	if not playerData or not playerData.petStats then
		return {totalHatched = 0, legendaryHatched = 0, petsOwned = 0, totalPetsSold = 0}
	end

	return playerData.petStats
end

-- Give daily rewards (including pet food)
function DataManager.GiveDailyReward(player)
	local playerData = DataManager.GetPlayerData(player)
	if not playerData then return false end

	local lastReward = playerData.lastDailyReward or 0
	local currentTime = os.time()
	local oneDay = 24 * 60 * 60

	if currentTime - lastReward >= oneDay then
		-- Give daily rewards
		playerData.coins = playerData.coins + 100
		playerData.gems = (playerData.gems or 0) + 5
		playerData.items.petFood = (playerData.items.petFood or 0) + 5
		playerData.lastDailyReward = currentTime

		DataManager.SavePlayerData(player, playerData)

		return true, "Daily reward received: 100 coins, 5 gems, 5 pet food!"
	end

	local timeLeft = oneDay - (currentTime - lastReward)
	local hoursLeft = math.floor(timeLeft / 3600)
	return false, "Next daily reward in " .. hoursLeft .. " hours"
end

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	-- Final save before player leaves
	local playerData = playerDataCache[player.UserId]
	if playerData then
		local success, errorMessage = pcall(function()
			playerDataStore:SetAsync(player.UserId, playerData)
		end)

		if success then
			print("Final enhanced save completed for", player.Name)
		else
			warn("Final enhanced save failed for", player.Name, ":", errorMessage)
		end

		-- Remove from cache
		playerDataCache[player.UserId] = nil
	end
end)

-- Enhanced periodic autosave (every 5 minutes)
spawn(function()
	while true do
		wait(300) -- Save every 5 minutes

		for userId, data in pairs(playerDataCache) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				DataManager.SavePlayerData(player, data)
			end
		end
	end
end)

return DataManager