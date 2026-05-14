local ReplicatedStorage = game:GetService("ReplicatedStorage")
local towers = require(ReplicatedStorage:WaitForChild("TowerShop"))

local getDataFunction = ReplicatedStorage:WaitForChild("GetData")
local IteractItemFunction = ReplicatedStorage:WaitForChild("InteractItem")

local gui = script.Parent
local exit = gui.Container.Exit
local gold = gui.Container.Gold
local limit = gui.Container.Limit
local itemsFrame = gui.Container.ItemsFrame

local playerData = {}

local function getItemStatus(itemName)
	if table.find(playerData.SelectedTowers, itemName) then
		return "Equipped"
	elseif table.find(playerData.OwnedTowers, itemName) then
		return "Owned"
	else
		return "For Sale"
	end
end

local function interactItem(itemName)
	local data = IteractItemFunction:InvokeServer(itemName)
	if data then
		playerData = data
		updateItems()
	end
end

function updateItems()
	gold.Text = "🪙" .. playerData.Gold
	limit.Text = #playerData.SelectedTowers .. "/5"
		for i, tower in pairs(towers) do
			
		local oldButton = itemsFrame:FindFirstChild(tower.Name)
		if oldButton then
			oldButton:Destroy()
		end


		--Creating new button
		local newButton = itemsFrame.TemplateButton:Clone()
		newButton.Name = tower.Name
		newButton.TowerName.Text = tower.Name
		newButton.Image = tower.ImageAsset
		newButton.Visible = true
		newButton.LayoutOrder = tower.Price
		newButton.Parent = itemsFrame
		
		local status = getItemStatus(tower.Name)
		if status == "For Sale" then
			newButton.Status.Text = "🪙" .. tower.Price
		elseif status == "Equipped" then
			newButton.Status.Text = "Equipped"
			newButton.Status.TextColor3 = Color3.new(0,0,0)
			newButton.BackgroundColor3 = Color3.new(0,0,0)
		else
			newButton.Status.Text = ""
		end
	
		newButton.Activated:Connect(function()
			interactItem(tower.Name)
		end)
	end
end

local function toggleShop()
	gui.Container.Visible = not gui.Container.Visible
	if gui.Container.Visible then
		playerData = getDataFunction:InvokeServer()
		updateItems()
	end
end

local function setupShop()
	local prompt = Instance.new("ProximityPrompt")
	prompt.RequiresLineOfSight = false
	prompt.ActionText = "Shop"
	prompt.Parent = workspace:WaitForChild("ShopPart")
	
	prompt.Triggered:Connect(toggleShop)
	exit.Activated:Connect(toggleShop)
end

setupShop()