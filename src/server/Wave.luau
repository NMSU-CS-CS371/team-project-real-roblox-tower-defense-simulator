local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local events = ReplicatedStorage:WaitForChild("Events")

local mob = require(script.Parent.Mob)
local TerrainSaveLoad = require(ServerStorage.TerrainSaveLoad)
local info = workspace.Info

local wave = {}
local votes = {}

function wave.StartGame()
	local map = wave.LoadMap()

	info.GameRunning.Value = true

	for i = 3, 0, -1 do
		info.Message.Value = "Game starting in... " .. i
		task.wait(1)
	end



	--SPAWN IN MOBS TO START WAVES
	for waveNum = 1, 5 do
		info.Wave.Value = waveNum
		info.Message.Value = ""

		wave.GetWave(waveNum, map)

		repeat
			task.wait(1)
		until	#workspace.Mobs:GetChildren() == 0 or not info.GameRunning.Value

		if info.GameRunning.Value and waveNum == 5 then
			info.Message.Value = "VICTORY"
		elseif info.GameRunning.Value then
			local reward = 50 * waveNum
			for i, player in ipairs(Players:GetPlayers()) do
				player.Gold.Value += 50 * waveNum
			end
			info.Message.Value = "Wave Reward: $" .. reward
			task.wait(2)

			for i = 5, 0, -1 do
				info.Message.Value = "Next wave starting in... " .. i
				task.wait(1)
			end
		else
			break
		end
	end
end

function wave.LoadMap()
	local votedMap = wave.ToggleVoting()
	local mapFolder = ServerStorage.Maps:FindFirstChild(votedMap)
	if not mapFolder then
		mapFolder = ServerStorage.Maps["IceLand"]
	end
	
	-- Clear existing terrain before loading new map
	workspace.Terrain:Clear()
	
	local newMap = mapFolder:Clone()
	newMap.Parent = workspace.Map
	
	-- Load terrain if the map has SavedTerrain
	local savedTerrain = newMap:FindFirstChild("SavedTerrain")
	if savedTerrain and savedTerrain:IsA("TerrainRegion") then
		TerrainSaveLoad.Load(savedTerrain)
	end

	workspace.Spawn.Floor:Destroy()
	
	newMap.Base.Humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			info.GameRunning.Value = false
			info.Message.Value = "GAME OVER"
		end
	end)
	
	return newMap
end

function wave.ToggleVoting()
	local maps = ServerStorage.Maps:GetChildren()
	for i, map in ipairs(maps) do
		votes[map.Name] = {}
	end
	
	info.Voting.Value = true
	
	for i=10, 1, -1 do
		info.Message.Value = "Map voting (" .. i .. ")"
		task.wait(1)
	end
	
	local winVote = nil
	local winScore = 0
	
	for name, map in pairs(votes) do
		if #map > winScore then
			winScore = #map
			winVote = name
		end
	end
	
	if not winVote then
		local index = math.random(1, #maps)
		winVote = maps[index].Name
	end
	
	info.Voting.Value = false
	
	return winVote
end

function wave.ProcessVote(player, vote)
	
	for name, mapVotes in pairs(votes) do
		local oldVote = table.find(mapVotes, player.UserId)
		if oldVote then
			table.remove(mapVotes, oldVote)
			break
		end
	end
	
	table.insert(votes[vote], player.UserId)
	
	events:WaitForChild("UpdateVoteCount"):FireAllClients(votes)
end
events:WaitForChild("VoteForMap").OnServerEvent:Connect(wave.ProcessVote)

function wave.GetWave(waveNum, map)
	if waveNum < 5 then
		mob.Spawn("Metal", 2*waveNum, map)
		mob.Spawn("Ice", 3*waveNum, map)
	elseif waveNum == 5 then
		mob.Spawn("Ice Boss (real) ", 1, map)
		mob.Spawn("Rig", 1, map)
	end
end

return wave
