local ReplicatedStorage = game:GetService("ReplicatedStorage")

local movingEvent = ReplicatedStorage:WaitForChild("MovingElevator")
local elevatorEvent = ReplicatedStorage:WaitForChild("Elevator")
local gui = script.Parent
local exitButton = gui.Exit
local camera = workspace.CurrentCamera

movingEvent.OnClientEvent:Connect(function()
	exitButton.Visible = false
end)

elevatorEvent.OnClientEvent:Connect(function(elevator)
	exitButton.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = elevator.Camera.CFrame
end)

exitButton.Activated:Connect(function()
	local player = game.Players.LocalPlayer
	
	exitButton.Visible = false
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = player.Character.Humanoid
	
	elevatorEvent:FireServer()
end)