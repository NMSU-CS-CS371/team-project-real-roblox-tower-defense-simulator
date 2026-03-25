local tower = require(script.Tower)
local mob = require(script.Mob)
local map = workspace.Grassland


--SPAWN IN MOBS TO START WAVES
for wave=1, 5 do
	print("WAVE STARTING", wave)
	if wave < 5 then
		mob.Spawn("Metal", 3, map)
		mob.Spawn("Ice", 2, map)
	elseif wave == 5 then
		mob.Spawn("Rig", 100, map)
	end
	
	repeat
		task.wait(1)
	until	#workspace.Mobs:GetChildren() == 0
	print("WAVE ENDED")
	task.wait(1)
end
