local ServerStorage = game:GetService("ServerStorage")
local mob = {}

function mob.move(mob, map)
	local humanoid = mob:WaitForChild("Humanoid")
	local waypoints = map.Waypoints
	
	for waypoint = 1, #waypoints:GetChildren() do
		humanoid:MoveTo(waypoints[waypoint].Position)
		humanoid.MoveToFinished:Wait()
	end
	
	mob:Destroy()
end

function mob.Spawn(name, quantity, map)
	local mobExists = ServerStorage.Mobs:FindFirstChild(name)
	
	if mobExists then
		--move into workspace
		for i=1, quantity do
			task.wait(.5)
			local newMob = mobExists:Clone()
			newMob.HumanoidRootPart.CFrame = map.Start.CFrame
			newMob.Parent = map.Mob

			--move
			coroutine.wrap(mob.move)(newMob, map)
		end
		
		--clone mob
	else
		warn("Mob does not exist", name)
	end
	
end

return mob
