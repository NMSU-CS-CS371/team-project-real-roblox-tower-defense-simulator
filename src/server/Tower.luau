local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local events = replicatedStorage:WaitForChild("Events")
local animateTowerEvent = events:WaitForChild("AnimateTower")
local functions = replicatedStorage:WaitForChild("Functions")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local sellTowerFunction = functions:WaitForChild("SellTower")

local maxTowers = 10
local tower = {}--tower module

function FindNearestTarget(newTower, range)
	
	local nearestTarget = nil

	for i, target in ipairs(workspace.Mobs:GetChildren()) do
		local distance = (target.HumanoidRootPart.Position - newTower.HumanoidRootPart.Position).Magnitude
		if distance < range then
			print(target.Name, "is the nearest target found so far")
			nearestTarget = target
			range = distance
		end
	end

	return nearestTarget
end

function tower.Attack(newTower, player)
	local config = newTower.Config
	local target = FindNearestTarget(newTower, config.Range.Value)
	if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
		
		local targetCFrame = CFrame.lookAt(newTower.HumanoidRootPart.Position, Vector3.new(target.HumanoidRootPart.Position.X, newTower.HumanoidRootPart.Position.Y, target.HumanoidRootPart.Position.Z))
		newTower.HumanoidRootPart.CFrame = targetCFrame
		
		animateTowerEvent:FireAllClients(newTower, "Shoot")
		target.Humanoid:TakeDamage(config.Damage.Value)
		
		if target.Humanoid.Health <= 0 then
			player.Gold.Value += target.Humanoid.MaxHealth
		end
		
		task.wait(config.Cooldown.Value)
	end
	
	task.wait(0.1)
	
	if newTower and newTower.Parent then
		tower.Attack(newTower, player)
	end
end

function tower.Sell(player, model)
	if model and model:FindFirstChild("Config") then
		if model.Config.Owner.Value == player.Name then
			player.PlacedTowers.Value -= 1
			player.Gold.Value += model.Config.Cost.Value / 1.5
			model:Destroy()
			return true
		end
	end
	
	warn("Unable to sell this tower")
	return false
end
sellTowerFunction.OnServerInvoke = tower.Sell

function tower.Spawn(player, name, cFrame, previous)--spawn tower
	local allowedToSpawn = tower.CheckSpawn(player, name)
	
	if allowedToSpawn then
		
		local newTower
		if previous then
			previous:Destroy()
			newTower = replicatedStorage.Towers.Upgrades[name]:Clone()
		else
			newTower = replicatedStorage.Towers[name]:Clone()
			player.PlacedTowers.Value += 1
		end
		
		local ownerValue = Instance.new("StringValue")
		ownerValue.Name = "Owner"
		ownerValue.Value = player.Name
		ownerValue.Parent = newTower.Config
		
		--move into workspace
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
			
			player.Gold.Value -= newTower.Config.Cost.Value
		
		coroutine.wrap(tower.Attack)(newTower, player)
		
		return newTower
	else
		warn("Tower does not exist", name)
		return false
	end
	
end


spawnTowerFunction.OnServerInvoke = tower.Spawn

function tower.CheckSpawn(player, name)
	local towerExists = replicatedStorage.Towers:FindFirstChild(name, true)

	if towerExists then
		if towerExists.Config.Cost.Value <= player.Gold.Value then
			if player.PlacedTowers.Value < maxTowers then
				return true
			else
				warn("Player has reached max tower limit")
			end
		else
			warn("Player cannot afford")
		end
	else
		warn("Tower does not exist")
	end
	
	return false
end
requestTowerFunction.OnServerInvoke = tower.CheckSpawn
return tower
