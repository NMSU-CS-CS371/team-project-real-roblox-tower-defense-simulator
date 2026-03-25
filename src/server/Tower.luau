local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local events = replicatedStorage:WaitForChild("Events")
local spawnTowerEvent = events:WaitForChild("SpawnTower")

local tower = {}--tower module



function tower.Spawn(player, name, cFrame)--spawn tower
	local towerExists = replicatedStorage.Towers:FindFirstChild(name)
	
	if towerExists then
		
		--move into workspace
			local newTower = towerExists:Clone()
			newTower.Parent = workspace.Towers
			
			-- Position the tower using PivotTo (works for models with or without HumanoidRootPart)
			newTower:PivotTo(cFrame)
			
			-- For models with HumanoidRootPart, set network owner to nil (server authoritative)
			local hrp = newTower:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp:SetNetworkOwner(nil)
			end

			--set collision group
			for i, object in ipairs(newTower:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CollisionGroup = "Tower"

				end	
			end
		
		--clone mob
	else
		warn("Tower does not exist", name)
	end
	
end

spawnTowerEvent.OnServerEvent:Connect(tower.Spawn)

return tower
