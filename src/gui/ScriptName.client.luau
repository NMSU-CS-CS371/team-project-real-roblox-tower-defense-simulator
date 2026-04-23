local players = game:GetService("Players")
local physicsService = game:GetService("PhysicsService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

local modules = replicatedStorage:WaitForChild("Modules")
local health = require(modules:WaitForChild("Health"))

local gold = players.LocalPlayer:WaitForChild("Gold")
local functions = replicatedStorage:WaitForChild("Functions")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local towers = replicatedStorage:WaitForChild("Towers")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local sellTowerFunction = functions:WaitForChild("SellTower")

local towerToSpawn = nil
local canPlace = false
local rotation = 0
local placedTowers = 0
local maxTowers = 10


local camera = workspace.CurrentCamera
local item= nil
local gui = script.Parent
local map = workspace:WaitForChild("Grassland")
local base = map:WaitForChild("Base")
local info = workspace:WaitForChild("Info")

local hoveredInstance = nil
local selectedTower = nil

local function SetupGUI()
	health.Setup(base, gui.Info.Health)

	workspace.Mobs.ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)

	info.Message.Changed:Connect(function(change)
		gui.Info.Message.Text = change
		if change == "" then
			gui.Info.Message.Visible = false
		else
			gui.Info.Message.Visible = true
		end
	end)

	info.Wave.Changed:Connect(function(change)
		gui.Info.Stats.Wave.Text = "Wave: " .. change
	end)

	gold.Changed:Connect(function(change)
		gui.Info.Stats.Gold.Text = "$" .. gold.Value
	end)
	gui.Info.Stats.Gold.Text = "$" .. gold.Value
end

SetupGUI()

	local function MouseRayCast(blacklist)
		local mousePosition = userInputService:GetMouseLocation()
		local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
		local raycastParams = RaycastParams.new()
		
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = blacklist
		
		local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
		
		return raycastResult
	end	
	
local function CreateRangeCircle(tower, placeHolder)
	local range = tower.Config.Range.Value
	local height = (tower.PrimaryPart.Size.Y/2) + tower.Humanoid.HipHeight
	local offset = CFrame.new(0, -height, 0)
	
	local p = Instance.new("Part")
	p.Name = "Range"
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Neon
	p.Transparency = 0.9
	p.Size = Vector3.new(2, range * 2, range * 2)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = tower.PrimaryPart.CFrame * offset * CFrame.Angles(0,0,math.rad(90))
	p.CanCollide = false
	p.Anchored = true
	p.Parent = workspace.Camera
	
	if placeHolder then
		p.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = tower.PrimaryPart
		weld.Parent = p
		p.Parent = tower
	else
		p.Anchored = true
		p.Parent = workspace.Camera	
	end
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
		
		CreateRangeCircle(towerToSpawn, true)
		
		for i, object in ipairs(towerToSpawn:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Tower"
				if object.Name ~= "Range" then
					object.Material = Enum.Material.ForceField
					object.Transparency = 0.3
				end
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

gui.Towers.Title.Text = "Towers: " .. placedTowers .. "/" .. maxTowers
	
for i, tower in pairs(towers:GetChildren()) do
	if tower:IsA("Model") then
		local button = gui.Towers.Template:Clone()
		local config = tower:WaitForChild("Config")
		button.Name = tower.Name
		button.Image = config.Image.Texture
		button.Visible = true
		button.Price.Text = config.Cost.Value
		button.LayoutOrder = config.Cost.Value
		button.Parent = gui.Towers

		button.Activated:Connect(function()	
			local allowedToSpawn = requestTowerFunction:InvokeServer(tower.Name)
			if allowedToSpawn then
				AddPlaceholderTower(tower.Name)
			end
		end)
	end
end

local function ToggleTowerInfo()
	workspace.Camera:ClearAllChildren()
	gui.Towers.Title.Text = "Towers: " .. placedTowers .. "/" .. maxTowers

	
	if selectedTower then
		CreateRangeCircle(selectedTower)
		gui.Selection.Visible = true
		local config = selectedTower.Config
		gui.Selection.Stats.Damage.Value.Text = config.Damage.Value
		gui.Selection.Stats.Range.Value.Text = config.Range.Value
		gui.Selection.Stats.Cooldown.Value.Text = config.Cooldown.Value
		gui.Selection.Title.TowerName.Text = selectedTower.Name
		gui.Selection.Title.TowerImage.Image = config.Image.Texture
		gui.Selection.Title.OwnerName.Text = config.Owner.Value .. "'s Tower"
		
		if config.Owner.Value == players.LocalPlayer.Name then
			gui.Selection.Action.Visible = true
			
			local upgradeTower = config:FindFirstChild("Upgrade")
			if upgradeTower then
				gui.Selection.Action.Upgrade.Visible = true
				gui.Selection.Action.Upgrade.Title.Text = "Upgrade (" .. upgradeTower.Value.Config.Cost.Value .. ")"
			else
				gui.Selection.Action.Upgrade.Visible = false
			end
		else
			gui.Selection.Action.Visible = false
		end
	else
		gui.Selection.Visible = false		
	end
end


gui.Selection.Action.Upgrade.Activated:Connect(function()
	if selectedTower then
		local upgradeTower = selectedTower.Config.Upgrade.Value
		local allowedToUpgrade = requestTowerFunction:InvokeServer(upgradeTower.Name)

		if allowedToUpgrade then
			selectedTower = spawnTowerFunction:InvokeServer(upgradeTower.Name, selectedTower:GetPivot(), selectedTower)
			ToggleTowerInfo()
		end
	end
end)

gui.Selection.Action.Sell.Activated:Connect(function()
	if selectedTower then
		local soldTower = sellTowerFunction:InvokeServer(selectedTower)
		
		if soldTower then
			selectedTower = nil
			placedTowers -= 1
			ToggleTowerInfo()
		end
	end
end)
	
	userInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		
		if towerToSpawn then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if canPlace then
					local placedTower = spawnTowerFunction:InvokeServer(towerToSpawn.Name, towerToSpawn:GetPivot())
					if placedTower then 
					placedTowers += 1
					RemovePlaceholderTower()
					ToggleTowerInfo()
					end
				end
			elseif input.KeyCode == Enum.KeyCode.R then
				rotation += 90
			end
		elseif hoveredInstance and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local model = hoveredInstance:FindFirstAncestorOfClass("Model")
			
			if model and model.Parent == workspace.Towers then
				selectedTower = model
			else
				selectedTower = nil
			end
			
		ToggleTowerInfo()
		end
	end)
	
runService.RenderStepped:Connect(function()
	local result = MouseRayCast({towerToSpawn})
	
	if result and result.Instance then
		if towerToSpawn then
			hoveredInstance = nil
			
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
		else
			hoveredInstance = result.Instance
		end	
	else
		hoveredInstance = nil
	end
end)