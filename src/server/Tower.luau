local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local events = replicatedStorage:WaitForChild("Events")
local spawnTowerEvent = events:WaitForChild("SpawnTower")
local animateTowerEvent = events:WaitForChild("AnimateTower")

local tower = {}--tower module

function FindNearestTarget(newTower, range)
	
	local nearestTarget = nil

	for i, target in ipairs(workspace.Mobs:GetChildren()) do
		local distance = (target.HumanoidRootPart.Position - newTower.HumanoidRootPart.Position).Magnitude
		print(target.Name, distance)
		if distance < range then
			print(target.Name, "is the nearest target found so far")
			nearestTarget = target
			range = distance
		end
	end

	return nearestTarget
end

function tower.Attack(newTower)
	local config = newTower.Config
	local target = FindNearestTarget(newTower, config.Range.Value)
	if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
		
		local targetCFrame = CFrame.lookAt(newTower.HumanoidRootPart.Position, Vector3.new(target.HumanoidRootPart.Position.X, newTower.HumanoidRootPart.Position.Y, target.HumanoidRootPart.Position.Z))
		newTower.HumanoidRootPart.CFrame = targetCFrame
		
		animateTowerEvent:FireAllClients(newTower, "Shoot")
		target.Humanoid:TakeDamage(config.Damage.Value)
		task.wait(config.Cooldown.Value)
	end
	
	task.wait(0.1)
	
	tower.Attack(newTower)
end

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
			
			local CFrame = Instance.new("CFrameValue")
			CFrame = Vector3.new(math.huge, math.huge, math.huge)
			CFrame = newTower.HumanoidRootPart.CFrame

			--set collision group
			for i, object in ipairs(newTower:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CollisionGroup = "Tower"

				end	
			end
		
		coroutine.wrap(tower.Attack)(newTower)
	else
		warn("Tower does not exist", name)
	end
	
end

spawnTowerEvent.OnServerEvent:Connect(tower.Spawn)

return tower
