local PhysicsService = game:GetService("PhysicsService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local events = replicatedStorage:WaitForChild("Events")
local animateTowerEvent = events:WaitForChild("AnimateTower")
local functions = replicatedStorage:WaitForChild("Functions")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local sellTowerFunction = functions:WaitForChild("SellTower")
local changeModeFunction = functions:WaitForChild("ChangeTowerMode")

local maxTowers = 10
local tower = {}--tower module


function tower.FindTarget(newTower, range, mode)
	local bestTarget = nil
	local bestWaypoint = nil
	local bestDistance = nil
	local bestHealth = nil
	local map = workspace.Map:FindFirstChildOfClass("Folder")
	
	for i, mob in ipairs(workspace.Mobs:GetChildren()) do
		local distanceToMob = (mob.HumanoidRootPart.Position - newTower.HumanoidRootPart.Position).Magnitude
		local distanceToWaypoint = (mob.HumanoidRootPart.Position - map.Waypoints[mob.MovingTo.Value].Position).Magnitude
		
		if distanceToMob <= range then
			if mode == "Near" then
				range = distanceToMob
				bestTarget = mob
				
			elseif mode == "First" then
				if not bestWaypoint or mob.MovingTo.Value >= bestWaypoint then
					
					bestWaypoint = mob.MovingTo.Value
					
					if not bestDistance or distanceToWaypoint < bestDistance then
						bestDistance = distanceToWaypoint
						bestTarget = mob
					end
				end
				
			elseif mode == "Last" then
				if not bestWaypoint or mob.MovingTo.Value <= bestWaypoint then
					
					bestWaypoint = mob.MovingTo.Value

					if not bestDistance or distanceToWaypoint > bestDistance then
						bestDistance = distanceToWaypoint
						bestTarget = mob
					end
				end
				
			elseif mode == "Strong" then
				if not bestHealth or mob.Humanoid.Health > bestHealth then
					bestHealth = mob.Humanoid.Health
					bestTarget = mob
				end
			
			elseif mode == "Weak" then
				if not bestHealth or mob.Humanoid.Health < bestHealth then
					bestHealth = mob.Humanoid.Health
					bestTarget = mob
				end
			end
		end
	end
	
	return bestTarget
end

function tower.Attack(newTower, player)
	local config = newTower.Config
	local target = tower.FindTarget(newTower, config.Range.Value, config.TargetMode.Value)
	if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
		
		local targetCFrame = CFrame.lookAt(newTower.HumanoidRootPart.Position, Vector3.new(target.HumanoidRootPart.Position.X, newTower.HumanoidRootPart.Position.Y, target.HumanoidRootPart.Position.Z))
		newTower.HumanoidRootPart.CFrame = targetCFrame
		
		animateTowerEvent:FireAllClients(newTower, "Shoot", target)
		target.Humanoid:TakeDamage(config.Damage.Value)
		
		if target.Humanoid.Health <= 0 then
			player.Gold.Value += target.Humanoid.MaxHealth
			player.Kills.Value += 1
		end
		
		task.wait(config.Cooldown.Value)
	end
	
	task.wait(0.1)
	
	if newTower and newTower.Parent then
		tower.Attack(newTower, player)
	end
end

function tower.ChangeMode(player, model)
	if model and model:FindFirstChild("Config") then
		local targetMode = model.Config.TargetMode
		local modes = {"First", "Last", "Near", "Strong", "Weak"}
		local modeIndex = table.find(modes, targetMode.Value)
		
		if modeIndex < #modes then
			targetMode.Value = modes[modeIndex + 1]
		else
			targetMode.Value = modes[1]
		end
		
		return true
	else
		warn("Unable to change tower mode")
		return false
	end
end

changeModeFunction.OnServerInvoke = tower.ChangeMode

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
	local allowedToSpawn = tower.CheckSpawn(player, name, previous)
	
	if allowedToSpawn then
		
		local newTower
		local oldMode = nil
		
		if previous then
			oldMode = previous.Config.TargetMode.Value

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
		
		local targetMode = Instance.new("StringValue")
		targetMode.Name = "TargetMode"
		
	
		targetMode.Value = oldMode or "First"
		
		targetMode.Parent = newTower.Config
		
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

function tower.CheckSpawn(player, name, previous)
	local towerExists = replicatedStorage.Towers:FindFirstChild(name, true)

	if towerExists then
		if towerExists.Config.Cost.Value <= player.Gold.Value then
			if previous or player.PlacedTowers.Value < maxTowers then
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
