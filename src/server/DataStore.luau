local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local database = DataStoreService:GetDataStore("database")
local functions = ReplicatedStorage:WaitForChild("Functions")
local events = ReplicatedStorage:WaitForChild("Events")
local getDataFunction = functions:WaitForChild("GetData")
local exitEvent = events:WaitForChild("ExitGame")

local MAX_SELECTED_TOWERS = 5

local data = {}

-- Load Player Data
local function loadData(player)
	local success = nil
	local playerData = nil
	local attempt = 1
	
	-- In Studio, skip DataStore and use default data
	if RunService:IsStudio() then
		print("Studio mode: Using default data")
		data[player.UserId] = {
			["Gold"] = 300,
			["SelectedTowers"] = {"Cowboy"},
			["OwnedTowers"] = {"Cowboy"},
		}
		return
	end
	
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
		
		local info = workspace.Info
		local coins = info.Wave.Value
		if info.Message.Value == "VICTORY" then
			coins = 1000
		end
		
		data[player.UserId].Gold += coins

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

exitEvent.OnServerEvent:Connect(function(player)
	saveData(player)
	data[player.UserId] = nil
end)

game:BindToClose(function()
	if not RunService:IsStudio() then
		for index, player in pairs(Players:GetPlayers()) do
			task.spawn(function()
				saveData(player)
			end)
		end
	else
		print("Shutting down inside studio")
	end
end)


getDataFunction.OnServerInvoke = function(player)
	return data[player.UserId]
end
