local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local waveModule = require(script.Wave)

local tower = require(script.Tower)
local mob = require(script.Mob)

local minPlayers = 1

Players.PlayerAdded:Connect(function(player)
	local currentPlayers = #Players:GetPlayers()
	
	if currentPlayers >= minPlayers then
		waveModule.StartGame()
	else
		workspace.Info.Message.Value = "Waiting for " .. (minPlayers - currentPlayers) .. " more player(s)"
	end
end)

