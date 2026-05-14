local ServerStorage = game:GetService("ServerStorage")

local PhysicsService = game:GetService("PhysicsService")
local mob = {} --mob module

function mob.move(mob, map) --move mob to next waypoint
	local humanoid = mob:WaitForChild("Humanoid")
	local waypoints = map.Waypoints
	
	--MOVE MOBS TO WAYPOINT AND ONCE FINISHED DESTROY
	for waypoint = 1, #waypoints:GetChildren() do
		mob.MovingTo.Value = waypoint
		local targetPosition = waypoints[waypoint].Position
		local maxRetries = 3
		local reached = false
		
		for attempt = 1, maxRetries do
			humanoid:MoveTo(targetPosition)
			humanoid.MoveToFinished:Wait()
			
			-- Check if mob actually reached the waypoint (within 5 studs)
			local hrp = mob:FindFirstChild("HumanoidRootPart")
			if hrp then
				local distance = (hrp.Position - targetPosition).Magnitude
				if distance <= 5 then
					reached = true
					break
				end
			end
		end
		
		if not reached then
			-- Force move to waypoint if retries failed
			local hrp = mob:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(targetPosition)
			end
		end
		end
		
		-- Damage the base BEFORE destroying the mob
		local baseHumanoid = map.Base:FindFirstChild("Humanoid")
		if baseHumanoid and baseHumanoid.Health > 0 then
			baseHumanoid:TakeDamage(humanoid.MaxHealth)
		end
		
		mob:Destroy()
	end

function mob.Spawn(name, quantity, map) --spawn mob
	local mobExists = ServerStorage.Mobs:FindFirstChild(name)
	
	if mobExists then
		--move into workspace
		for i=1, quantity do
			task.wait(.5)
			local newMob = mobExists:Clone()
			newMob.HumanoidRootPart.CFrame = map.Start.CFrame
			newMob.Parent = workspace.Mobs
			newMob.HumanoidRootPart:SetNetworkOwner(nil)
			
			local movingTo = Instance.new("IntValue")
			movingTo.Name = "MovingTo"
			movingTo.Parent = newMob
			
			--set collision group
			for i, object in ipairs(newMob:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CollisionGroup = "Mob"

				end	
			end
			
			-- Kill mob after death
			newMob.Humanoid.Died:Connect(function()
				task.wait(1)
				newMob:Destroy()
			end)

			--move
			coroutine.wrap(mob.move)(newMob, map)
		end
		
		--clone mob
	else
		warn("Mob does not exist", name)
	end
	
end

return mob
