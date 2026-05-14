local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local database = DataStoreService:GetDataStore("database")
local towers = require(ReplicatedStorage:WaitForChild("TowerShop"))

local MAX_SELECTED_TOWERS = 5

local data = {}

-- Load Player Data
local function loadData(player)
	local success = nil
	local playerData = nil
	local attempt = 1
	
	repeat
		success, playerData = pcall(function()
			return database:GetAsync(player.UserId)
		end)
		
		attempt += 1
		if not success then
			warn(playerData)
			task.wait()
		end
	until success or attempt == 3
	
		if success then
			print("Data Retrieved")
			if not playerData then
				print("New player, giving default data")
				playerData = {
					["Gold"] = 300,
					["SelectedTowers"] = {"Cowboy"},
					["OwnedTowers"] = {"Cowboy"},
				}
			end
			
			data[player.UserId] = playerData
		else
			warn("Unable to get data for player", player.UserId)
			player:Kick("There was an error getting your data")
		end
end
Players.PlayerAdded:Connect(loadData)

-- Save Player Data
local function saveData(player)
	if data[player.UserId] then
		local success = nil
		local playerData = nil
		local attempt = 1

		repeat
			success, playerData = pcall(function()
				return database:UpdateAsync(player.UserId, function()
					return data[player.UserId]
				end)
			end)

			attempt += 1
			if not success then
				warn(playerData)
				task.wait()
			end
		until success or attempt == 3

		if success then
			print("Data Saved Successfully")
		else
			warn("Unable to sava data for player", player.UserId)
		end
	else
		warn("No session data for ", player.UserId)
	end
end
Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	data[player.UserId] = nil
end)

game:BindToClose(function()
	-- Save for all players (including in Studio for testing)
	for index, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			saveData(player)
		end)
	end
	if RunService:IsStudio() then
		-- Wait briefly in Studio to ensure saves complete
		task.wait(2)
	end
end)

local function getItemStatus(player, itemName)
	local playerData = data[player.UserId]
	
	if table.find(playerData.SelectedTowers, itemName) then
		return "Equipped"
	elseif table.find(playerData.OwnedTowers, itemName) then
		return "Owned"
	else
		return "For Sale"
	end
end

ReplicatedStorage.InteractItem.OnServerInvoke = function(player, itemName)
	local shopItem = towers[itemName]
	local playerData = data[player.UserId]
	if shopItem and playerData then
		local status = getItemStatus(player, itemName)
		
		if status == "For Sale" and shopItem.Price <= playerData.Gold then
			-- Purchase
			playerData.Gold -= shopItem.Price
			table.insert(playerData.OwnedTowers, shopItem.Name)
		elseif status == "Owned" then
			-- Equip
			table.insert(playerData.SelectedTowers, shopItem.Name)
			if #playerData.SelectedTowers > MAX_SELECTED_TOWERS then
				table.remove(playerData.SelectedTowers, 1)
			end
		elseif status == "Equipped" then
			-- Unequip
			if #playerData.SelectedTowers > 1 then
				local towerToRemove = table.find(playerData.SelectedTowers, itemName)
				table.remove(playerData.SelectedTowers, towerToRemove)
			end
		end
		
		return playerData
	else
		warn("Tower/Player data not found!")
	end
	
	return false
end

ReplicatedStorage.GetData.OnServerInvoke = function(player)
	return data[player.UserId]
end

-- TESTING: Admin command to set Gold (remove after demo)
local function setGold(playerName, amount)
	local targetPlayer = Players:FindFirstChild(playerName)
	if targetPlayer and data[targetPlayer.UserId] then
		data[targetPlayer.UserId].Gold = amount
		print("Set " .. playerName .. "'s Gold to " .. amount)
		-- Save immediately so data persists across places
		saveData(targetPlayer)
		return true
	end
	return false
end

-- Expose for command bar access
_G.SetGold = setGold

print("=== DEMO MODE: Use _G.SetGold('PlayerName', amount) to set Gold ===")
