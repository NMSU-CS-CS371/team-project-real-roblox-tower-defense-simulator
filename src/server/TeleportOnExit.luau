local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local SafeTeleport = require(ServerScriptService.SafeTeleport)

local events = ReplicatedStorage:WaitForChild("Events")
local exitEvent = events:WaitForChild("ExitGame")

local function Teleport(player)
	local placeId = 121299218064398
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({
		["Gold"] = player.Gold.Value
	})
	SafeTeleport(placeId, {player}, options)
end

exitEvent.OnServerEvent:Connect(Teleport)