local physicsService = game:GetService("PhysicsService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

local events = replicatedStorage:WaitForChild("Events")
local towers = replicatedStorage:WaitForChild("Towers")
local spawnTowerEvent = events:WaitForChild("SpawnTower")

local towerToSpawn = nil
local canPlace = false
local rotation = 0

local camera = workspace.CurrentCamera
local item= nil
local gui = script.Parent



	local function MouseRayCast(blacklist)
		local mousePosition = userInputService:GetMouseLocation()
		local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
		local raycastParams = RaycastParams.new()
		
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = blacklist
		
		local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
		
		return raycastResult
	end	

local function RemovePlaceholderTower()
	if towerToSpawn then
		towerToSpawn:Destroy()
		towerToSpawn = nil
		rotation = 0
	end
end

local function AddPlaceholderTower(name)
	local towerExists = towers:FindFirstChild(name)
	if towerExists then
		towerToSpawn = towerExists:Clone()
		towerToSpawn.Parent = workspace
		
		for i, object in ipairs(towerToSpawn:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Tower"
				object.Material = Enum.Material.ForceField
			end	
		end
	end
end

local function ColorPlaceHolderTower(color)
	for i, object in ipairs(towerToSpawn:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Color = color
		end	
	end
end
	
for i, tower in pairs(towers:GetChildren()) do
	local button = gui.Towers.Template:Clone()
	local config = tower:WaitForChild("Config")
	button.Name = tower.Name
	button.Image = config.Image.Texture
	button.Visible = true
	button.Parent = gui.Towers
	
	button.Activated:Connect(function()
		AddPlaceholderTower(tower.Name)
	end)
end
	
	userInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		
		if towerToSpawn then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if canPlace then
					spawnTowerEvent:FireServer(towerToSpawn.Name, towerToSpawn:GetPivot())
					RemovePlaceholderTower()
				end
			elseif input.KeyCode == Enum.KeyCode.R then
				rotation += 90
			end
		end
	end)
	
runService.RenderStepped:Connect(function()
	if towerToSpawn then
		local result = MouseRayCast({towerToSpawn})
		if result and result.Instance then
			if result.Instance.Parent.Name == "TowerArea" then
				canPlace = true
				ColorPlaceHolderTower(Color3.new(0,1,0))
			else
				canPlace = false
				ColorPlaceHolderTower(Color3.new(1,0,0))
			end
			local x = result.Position.X
			local z = result.Position.Z
			
			-- Calculate Y position: use Humanoid.HipHeight if available, otherwise calculate from PrimaryPart
			local y = result.Position.Y
			local humanoid = towerToSpawn:FindFirstChildOfClass("Humanoid")
			if humanoid then
				y = y + humanoid.HipHeight + (towerToSpawn.PrimaryPart.Size.Y / 2)
			else
				-- For models without Humanoid, account for pivot offset and place bottom on surface
				local pivot = towerToSpawn:GetPivot()
				local pp = towerToSpawn.PrimaryPart
				local pivotToPPCenter = pp.Position.Y - pivot.Position.Y
				y = y + (pp.Size.Y / 2) - pivotToPPCenter
			end
			
			local cFrame = CFrame.new(x,y,z) * CFrame.Angles(0, math.rad(rotation), 0)
			towerToSpawn:PivotTo(cFrame)
		end
	end
end)