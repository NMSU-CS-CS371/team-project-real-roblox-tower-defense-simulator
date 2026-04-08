local ServerStorage = game:GetService("ServerStorage")

local bindables = ServerStorage:WaitForChild("Bindables")
local gameOverEvent = bindables:WaitForChild("GameOver")

local base = require(script.Base)
local tower = require(script.Tower)
local mob = require(script.Mob)
local map = workspace.Grassland

local gameOver = false

gameOverEvent.Event:Connect(function()
	gameOver = true
end)

base.Setup(map, 500)



--SPAWN IN MOBS TO START WAVES
for wave=1, 5 do
	print("WAVE STARTING", wave)
	if wave < 5 then
		mob.Spawn("Metal", 2*wave, map)
		mob.Spawn("Ice", 3*wave, map)
	elseif wave == 5 then
		mob.Spawn("Ice Boss (real)", 1, map)
		mob.Spawn("Rig", 100, map)
	end
	
	repeat
		task.wait(1)
	until	#workspace.Mobs:GetChildren() == 0 or gameOver
	
	if gameOver then
		print("GAME OVER")
		break
	end
	
	print("WAVE ENDED")
	task.wait(1)
end
