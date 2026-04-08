local ServerStorage = game:GetService("ServerStorage")

local bindables = ServerStorage:WaitForChild("Bindables")
local updateBaseHealth = bindables:WaitForChild("UpdateBaseHealth")
local gameOverEvent = bindables:WaitForChild("GameOver")


local base = {}

function base.Setup(map, health)
	base.Model = map:WaitForChild("GateNoText")
	base.CurrentHealth = health
	base.MaxHealth = health
end

function base.updateHealth(damage)
	if damage then 
		base.CurrentHealth -= damage
	end
	
	local gui = base.Model.HealthGui
	local percent = base.CurrentHealth / base.MaxHealth
	
	gui.CurrentHealth.Size = UDim2.new(percent, 0, .5, 0)
	
	if base.CurrentHealth <= 0 then
		gameOverEvent:Fire()
		gui.Title.Text = "BASE DESTROYED"
	else
		gui.Title.Text = "Base: " .. base.CurrentHealth .. "/" .. base.MaxHealth
	end
	
	
	
	
end

updateBaseHealth.Event:Connect(base.updateHealth)



return base
