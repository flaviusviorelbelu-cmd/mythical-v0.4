-- ShopManager Module
-- Place this as a ModuleScript in ServerScriptService

local ShopManager = {}

-- Require DataManager
local DataManager = require(game.ServerScriptService.DataManager)

-- Shop configuration - EXPANDED WITH LUNAR PLANTS
local SEED_PRICES = {
	-- Original plants
	carrot = 5,
	potato = 7,
	wheat = 3,
	-- New lunar plants
	moonberry = 12,
	stardust = 8,
	nebula = 15,
	cosmic = 10,
	asteroid = 20,
	solar = 6
}

local PLANT_SELL_PRICES = {
	-- Original plants
	carrot = 8,
	potato = 12,
	wheat = 6,
	-- New lunar plants  
	moonberry = 20,
	stardust = 14,
	nebula = 25,
	cosmic = 18,
	asteroid = 35,
	solar = 11
}

-- Buy seed function (unchanged)
function ShopManager.BuySeed(player, seedType)
	local playerData = DataManager.GetPlayerData(player)

	if not playerData then
		return false, "Player data not found"
	end

	local price = SEED_PRICES[seedType]
	if not price then
		return false, "Invalid seed type: " .. tostring(seedType)
	end

	-- Check if player has enough coins
	if playerData.coins < price then
		return false, "Not enough coins. Need " .. price .. ", have " .. playerData.coins
	end

	-- Process purchase
	playerData.coins = playerData.coins - price

	-- Initialize seeds table if it doesn't exist
	if not playerData.seeds then
		playerData.seeds = {}
	end

	playerData.seeds[seedType] = (playerData.seeds[seedType] or 0) + 1

	-- Save data
	DataManager.SavePlayerData(player, playerData)

	print(player.Name, "bought", seedType, "seed for", price, "coins")
	return true, "Successfully bought " .. seedType .. " seed"
end

-- Sell harvest function (renamed from SellPlant to SellHarvest)
function ShopManager.SellHarvest(player, plantType, quantity)
	local playerData = DataManager.GetPlayerData(player)

	if not playerData then
		return false, "Player data not found"
	end

	if not playerData.harvest then
		playerData.harvest = {}
	end

	local owned = playerData.harvest[plantType] or 0
	if owned < quantity then
		return false, "Not enough " .. plantType .. ". Have " .. owned .. ", trying to sell " .. quantity
	end

	local sellPrice = PLANT_SELL_PRICES[plantType]
	if not sellPrice then
		return false, "Cannot sell " .. plantType
	end

	local totalPrice = sellPrice * quantity

	-- Process sale
	playerData.harvest[plantType] = owned - quantity
	playerData.coins = playerData.coins + totalPrice

	-- Save data
	DataManager.SavePlayerData(player, playerData)

	print(player.Name, "sold", quantity, plantType, "for", totalPrice, "coins")
	return true, "Sold " .. quantity .. " " .. plantType .. " for " .. totalPrice .. " coins"
end

-- Keep the old SellPlant function for backwards compatibility
function ShopManager.SellPlant(player, plantType, quantity)
	return ShopManager.SellHarvest(player, plantType, quantity)
end

-- Get shop prices (for UI)
function ShopManager.GetSeedPrices()
	return SEED_PRICES
end

function ShopManager.GetPlantSellPrices()
	return PLANT_SELL_PRICES
end

-- Shop data for UI
function ShopManager.GetShopData(shopType)
	if shopType == "SeedShop" then
		return {
			{ id = "carrot",     name = "🥕 Carrot Seeds",      price = 5,  desc = "Fast growing orange vegetables" },
			{ id = "potato",     name = "🥔 Potato Seeds",      price = 7,  desc = "Hearty root vegetables"   },
			{ id = "wheat",      name = "🌾 Wheat Seeds",       price = 3,  desc = "Basic grain crop"         },
			{ id = "moonberry",  name = "🌙 Moonberry Seeds",   price = 12, desc = "Sweet berries under moonlight" },
			{ id = "stardust",   name = "✨ Stardust Seeds",     price = 8,  desc = "Seeds infused with cosmic dust" },
			{ id = "nebula",     name = "🌌 Nebula Seeds",      price = 15, desc = "Swirling nebular energy"   },
			{ id = "cosmic",     name = "⭐ Cosmic Seeds",      price = 10, desc = "Mystical seeds charged by the cosmos" },
			{ id = "asteroid",   name = "☄️ Asteroid Seeds",    price = 20, desc = "Forged in asteroid impacts" },
			{ id = "solar",      name = "☀️ Solar Seeds",       price = 6,  desc = "Radiant seeds warmed by solar flares" },
		}
	else
		return {}
	end
end

return ShopManager