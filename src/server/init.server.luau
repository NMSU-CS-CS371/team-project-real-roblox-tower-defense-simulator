local ServerStorage = game:GetService("ServerStorage")

local bindables = ServerStorage:WaitForChild("Bindables")
local gameOverEvent = bindables:WaitForChild("GameOver")

local tower = require(script.Tower)
local mob = require(script.Mob)
local map = workspace.Grassland

local info = workspace.Info
local gameOver = false

map.Base.Humanoid.HealthChanged:Connect(function(health)
	if health <= 0 then
		gameOver = true
	end
end)


for i = 3, 0, -1 do
	info.Message.Value = "Game starting in... " .. i
	task.wait(1)
end



--SPAWN IN MOBS TO START WAVES
for wave=1, 5 do
	info.Wave.Value = wave
	info.Message.Value = ""
	
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
		info.Message.Value = "Game Over"
		break
	end
	
	for i = 5, 0, -1 do
		info.Message.Value = "Next wave starting in... " .. i
		task.wait(1)
	end
end
