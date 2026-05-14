local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

local SafeTeleport = require(ServerScriptService.SafeTeleport)

local movingEvent = ReplicatedStorage:WaitForChild("MovingElevator")
local elevatorEvent = ReplicatedStorage:WaitForChild("Elevator")
local elevator = script.Parent
local prismatic = elevator.Shaft.PrismaticConstraint
local gui = elevator.Screen.SurfaceGui
local config = elevator.Config
local playersWaiting = {}
local countdownRunning = false
local moving = false

local function Setup()
	playersWaiting = {}
	moving = false
	gui.Title.Text = #playersWaiting .. "/" .. config.MaxPlayers.Value .. " Players"
	gui.Status.Text = "Waiting for players..."
end

local function TeleportPlayers()
	local placeId = 131454317354908
	local server = TeleportService:ReserveServerAsync(placeId)
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = server
	SafeTeleport(placeId, playersWaiting, options)
end

local function MoveElevator()
	moving = true
	for i, player in pairs(playersWaiting) do
		movingEvent:FireClient(player)
	end
	gui.Status.Text = "Teleporting players..."
	prismatic.TargetPosition = -20
	TeleportPlayers()
	task.wait(10)
	prismatic.TargetPosition = 0
	task.wait(8)
	Setup()
end

local function RunCountdown()
	countdownRunning = true
	for i = 10, 1, -1 do
		gui.Status.Text = "Starting in: " .. i
		task.wait(1)
		if #playersWaiting == 0 then
			countdownRunning = false
			Setup()
			return
		end
	end
	MoveElevator()
	countdownRunning = false
end

elevator.Entrance.Touched:Connect(function(part)
	local player = Players:GetPlayerFromCharacter(part.Parent)
	local isWaiting = table.find(playersWaiting, player)
	
	if player and not isWaiting and #playersWaiting < config.MaxPlayers.Value and not moving then
		table.insert(playersWaiting, player)
		gui.Title.Text = #playersWaiting .. "/" .. config.MaxPlayers.Value .. " Players"
		player.Character.PrimaryPart.CFrame = elevator.TeleportIn.CFrame
		elevatorEvent:FireClient(player, elevator)
		if not countdownRunning then
			RunCountdown()
		end
	end
end)

elevatorEvent.OnServerEvent:Connect(function(player)
	local isWaiting = table.find(playersWaiting, player)
	
	if isWaiting then
		table.remove(playersWaiting, isWaiting)
	end
	
	gui.Title.Text = #playersWaiting .. "/" .. config.MaxPlayers.Value .. " Players"
	
	if player.Character then
		player.Character.PrimaryPart.CFrame = elevator.TeleportOut.CFrame
	end
end)