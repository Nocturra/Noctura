local selectedLuckyBlock
local excludedRarities = {}
local rarities = {"Brainrot God", "Common", "Divine", "Epic", "Legendary", "Mythic", "OG", "Rare", "Secret", "Transcendent", "Water", "Ghost", "Lava", "Taco", "67", "Rainbow"}

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/UI-Libraries/main/Vynixius/Source.lua"))()

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local supportedGames = {
	"Surf for Lucky Blocks"
}

local isSupported = false
for _, game_name in ipairs(supportedGames) do
	if gameName == game_name then
		isSupported = true
		break
	end
end

local Window = Library:AddWindow({
	title = {"🌑 Noctura", gameName},
	theme = {
		Accent = Color3.fromRGB(145, 57, 227)
	},
	key = Enum.KeyCode.RightControl,
	default = true
})

-- Rainbow Accent
local rainbowActive = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

-- ========== CONFIG SYSTEM ==========
local configPath = Library.Settings.ConfigPath or "Noctura/Configs"

local function ensureConfigFolder()
	pcall(function()
		if not isfolder(configPath) then
			makefolder(configPath)
		end
	end)
end

local function getConfigList()
	ensureConfigFolder()
	local list = {}
	pcall(function()
		for _, file in ipairs(listfiles(configPath)) do
			local name = file:match("([^/\\]+)%.json$") or file:match("([^/\\]+)%.txt$")
			if name then
				table.insert(list, name)
			end
		end
	end)
	return list
end

local function saveConfig(name)
	ensureConfigFolder()
	local filePath = configPath .. "/" .. name .. ".json"

	local config = {
		Flags = {},
		Sliders = {},
		Accent = nil,
		RainbowAccent = rainbowActive,
	}

	-- Gather all toggle flags and slider values from all tabs
	for _, tab in ipairs(Window.Tabs) do
		for flag, value in pairs(tab.Flags) do
			config.Flags[flag] = value
		end
		for _, section in ipairs(tab.Sections) do
			for _, item in ipairs(section.List) do
				if item.Type == "Slider" then
					config.Sliders[item.Flag or item.Name] = item.Value
				end
			end
		end
	end

	-- Save current accent color
	local r, g, b = Library.Theme.Accent.R, Library.Theme.Accent.G, Library.Theme.Accent.B
	config.Accent = { r = r, g = g, b = b }

	pcall(function()
		writefile(filePath, HttpService:JSONEncode(config))
	end)
end

local function loadConfig(name)
	ensureConfigFolder()
	local filePath = configPath .. "/" .. name .. ".json"

	pcall(function()
		if not isfile(filePath) then return end

		local raw = readfile(filePath)
		local config = HttpService:JSONDecode(raw)

		if not config then return end

		-- Apply toggle flags
		if config.Flags then
			for _, tab in ipairs(Window.Tabs) do
				for _, section in ipairs(tab.Sections) do
					for _, item in ipairs(section.List) do
						local flag = item.Flag or item.Name
						if item.Type == "Toggle" and config.Flags[flag] ~= nil then
							item:Set(config.Flags[flag], false)
						end
					end
				end
			end
		end

		-- Apply slider values
		if config.Sliders then
			for _, tab in ipairs(Window.Tabs) do
				for _, section in ipairs(tab.Sections) do
					for _, item in ipairs(section.List) do
						local flag = item.Flag or item.Name
						if item.Type == "Slider" and config.Sliders[flag] ~= nil then
							item:Set(config.Sliders[flag])
						end
					end
				end
			end
		end

		-- Apply accent color
		if config.RainbowAccent then
			rainbowActive = true
			Window:SetAccent("rainbow")
		elseif config.Accent then
			rainbowActive = false
			Window:SetAccent(Color3.new(config.Accent.r, config.Accent.g, config.Accent.b))
		end
	end)
end

local function deleteConfig(name)
	ensureConfigFolder()
	local filePath = configPath .. "/" .. name .. ".json"
	pcall(function()
		if isfile(filePath) then
			delfile(filePath)
		end
	end)
end

-- ========== ABOUT TAB ==========
local Tab = Window:AddTab("About", {default = true})
local AboutSection = Tab:AddSection("Noctura")

AboutSection:AddLabel("Welcome " .. player.Name .. "!")
AboutSection:AddLabel("Your Display Name is " .. player.DisplayName .. "!")
AboutSection:AddLabel("")

if isSupported then
	AboutSection:AddLabel("Game: " .. gameName)
	AboutSection:AddLabel("")
	AboutSection:AddLabel("Fun Fact:")

	local funFacts = {
		"Roblox was founded in 2006!",
		"Lua was created in 1993 at PUC-Rio University in Brazil!",
		"Roblox uses Lua as its scripting language!",
		"Over 200 million users play Roblox monthly!",
		"The first game on Roblox was launched in 2005!",
		"Lua is used in many games like World of Warcraft!",
		"'Lua' means 'Moon' in Portuguese!",
		"Roblox Studio has millions of developers!",
		"Roblox Robux is the in-game currency!",
		"DevEx allows developers to cash out their Robux!",
		"Lua is a lightweight and fast scripting language!",
		"Roblox was created by David Baszucki and Erik Cassel!"
	}

	local randomFact = funFacts[math.random(1, #funFacts)]
	AboutSection:AddLabel("📌 " .. randomFact)
else
	AboutSection:AddLabel("Game: " .. gameName)
	AboutSection:AddLabel("")
	AboutSection:AddLabel("⚠️ This game is not supported yet!")
	AboutSection:AddLabel("")
	AboutSection:AddLabel("Supported Games:")
	for _, game_name in ipairs(supportedGames) do
		AboutSection:AddLabel("📌 " .. game_name)
	end
end

AboutSection:AddLabel("")
AboutSection:AddButton("Join the Discord", function()
	firesignal(ReplicatedStorage.SharedModules.Network.Remotes["Send Notification"].OnClientEvent, "Noctura doesnt have an Official Discord Yet!", "Divine", 6)
end)

-- ========== PLAYER TAB ==========
if isSupported then
	local PlayerTab = Window:AddTab("Player")

	-- Flight
	local FlySection = PlayerTab:AddSection("Flight")
	local flyActive = false
	local flySpeed = 100

	FlySection:AddToggle("Fly", {default = false}, function(v)
		flyActive = v

		if v then
			local character = player.Character or player.CharacterAdded:Wait()
			local hrp = character:WaitForChild("HumanoidRootPart")

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Parent = hrp

			local bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			bodyGyro.D = 500
			bodyGyro.Parent = hrp

			_G.bodyVelocity = bodyVelocity
			_G.bodyGyro = bodyGyro

			local UserInputService = game:GetService("UserInputService")
			local camera = workspace.CurrentCamera

			local flyConnection
			flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
				if not flyActive or not character.Parent then
					flyConnection:Disconnect()
					if bodyVelocity then bodyVelocity:Destroy() end
					if bodyGyro then bodyGyro:Destroy() end
					return
				end

				local moveDirection = Vector3.new(0, 0, 0)

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDirection = moveDirection + (camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDirection = moveDirection - (camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDirection = moveDirection - camera.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDirection = moveDirection + camera.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDirection = moveDirection + Vector3.new(0, 1, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					moveDirection = moveDirection - Vector3.new(0, 1, 0)
				end

				if moveDirection.Magnitude > 0 then
					moveDirection = moveDirection.Unit
				end

				bodyVelocity.Velocity = moveDirection * flySpeed
				bodyGyro.CFrame = camera.CFrame
			end)

			_G.flyConnection = flyConnection
		else
			if _G.flyConnection then _G.flyConnection:Disconnect() end
			if _G.bodyVelocity then _G.bodyVelocity:Destroy() end
			if _G.bodyGyro then _G.bodyGyro:Destroy() end
		end
	end)

	FlySection:AddSlider("Fly Speed", 10, 2000, 100, {}, function(v)
		flySpeed = v
	end)

	FlySection:AddLabel("Controls: WASD to move")
	FlySection:AddLabel("Space to go up, Ctrl to go down")

	-- Noclip
	local NoclipSection = PlayerTab:AddSection("Noclip")
	local noclipActive = false

	NoclipSection:AddToggle("Noclip", {default = false}, function(v)
		noclipActive = v

		if v then
			local noclipConnection
			noclipConnection = game:GetService("RunService").Stepped:Connect(function()
				if not noclipActive then
					noclipConnection:Disconnect()
					return
				end
				local character = player.Character
				if character then
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end
			end)
			_G.noclipConnection = noclipConnection
		else
			if _G.noclipConnection then
				_G.noclipConnection:Disconnect()
			end
			local character = player.Character
			if character then
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end
	end)

	-- Speed Hack
	local SpeedSection = PlayerTab:AddSection("Speed Hack")
	local walkSpeedActive = false
	local walkSpeedValue = 100

	SpeedSection:AddToggle("Speed Hack", {default = false}, function(v)
		walkSpeedActive = v
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")
		if v then
			humanoid.WalkSpeed = walkSpeedValue
		else
			humanoid.WalkSpeed = 16
		end
	end)

	SpeedSection:AddSlider("Walk Speed", 16, 500, 100, {}, function(v)
		walkSpeedValue = v
		if walkSpeedActive then
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid then humanoid.WalkSpeed = v end
		end
	end)

	-- Jump
	local JumpSection = PlayerTab:AddSection("Jump")
	local jumpPowerValue = 50

	JumpSection:AddToggle("High Jump", {default = false}, function(v)
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.JumpPower = v and jumpPowerValue or 50
	end)

	JumpSection:AddSlider("Jump Power", 50, 500, 150, {}, function(v)
		jumpPowerValue = v
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then humanoid.JumpPower = v end
	end)

	-- ========== MAIN TAB ==========
	local MainTab = Window:AddTab("Main")
	local FarmSection = MainTab:AddSection("Auto Farm")

	local collectEvent = ReplicatedStorage.SharedModules.Network.Remotes["Collect Earnings"]
	local upgradeFriend = ReplicatedStorage.SharedModules.Network.Remotes["Upgrade Friend"]
	local upgradeSpeed = ReplicatedStorage.SharedModules.Network.Remotes["Upgrade Speed"]
	local upgradeSpeed5 = ReplicatedStorage.SharedModules.Network.Remotes["Upgrade Speed 5"]
	local sellAll = ReplicatedStorage.SharedModules.Network.Remotes["Sell All Friends"]
	local rebirthEvent = ReplicatedStorage.SharedModules.Network.Remotes.Rebirth
	local upgradeCarry = ReplicatedStorage.SharedModules.Network.Remotes["Upgrade Carry Limit"]
	local upgradeBoost = ReplicatedStorage.SharedModules.Network.Remotes["Upgrade Boost"]
	local buyBoard = ReplicatedStorage.SharedModules.Network.Remotes["Buy Board Upgrade"]

	local collecting = false
	local upgradingFriend = false
	local upgradingSpeed = false

	local function getLuckyBlocks()
		local blocks = {}
		local seenBlocks = {}
		local friendsFolder = workspace:FindFirstChild("Live")

		if friendsFolder then
			friendsFolder = friendsFolder:FindFirstChild("Friends")

			if friendsFolder then
				for _, model in ipairs(friendsFolder:GetChildren()) do
					if model:IsA("Model") and not seenBlocks[model.Name] then
						local excluded = false
						for _, rarity in ipairs(excludedRarities) do
							if model.Name:lower():find(rarity:lower()) then
								excluded = true
								break
							end
						end

						if not excluded then
							table.insert(blocks, model.Name)
							seenBlocks[model.Name] = true
						end
					end
				end
			end
		end

		return blocks
	end

	local function teleportToBase()
		local playerName = player.Name
		for i = 1, 5 do
			local basePos = workspace:FindFirstChild("Plots")
			if basePos then
				basePos = basePos:FindFirstChild("BasePos" .. i)
				if basePos then
					local owner = basePos:GetAttribute("owner") or (basePos:FindFirstChild("owner") and basePos.owner.Value)
					if owner == playerName then
						local base = basePos:FindFirstChild("Base")
						if base then
							player.Character:MoveTo(base.Position + Vector3.new(0, 3, 0))
							task.wait(0.3)
							break
						end
					end
				end
			end
		end
	end

	local function grabLuckyBlock(blockName)
		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")

		local friendsFolder = workspace:FindFirstChild("Live")
		if friendsFolder then
			friendsFolder = friendsFolder:FindFirstChild("Friends")
			if friendsFolder then
				local block = friendsFolder:FindFirstChild(blockName)
				if block then
					local targetCFrame = block.PrimaryPart and block.PrimaryPart.CFrame or block:FindFirstChildOfClass("Part").CFrame
					hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
					task.wait(0.2)

					for _, prompt in ipairs(block:GetDescendants()) do
						if prompt:IsA("ProximityPrompt") then
							prompt.HoldDuration = 0
							prompt.MaxActivationDistance = 100
							fireproximityprompt(prompt)
							task.wait(0.1)
							break
						end
					end

					task.wait(0.2)
					return true
				end
			end
		end
		return false
	end

	FarmSection:AddToggle("Burst Collect 1-100", {default = false}, function(v)
		collecting = v
		if v then
			task.spawn(function()
				while collecting do
					for i = 1, 100 do
						task.spawn(function()
							if not collecting then return end
							collectEvent:FireServer(tostring(i))
						end)
					end
					task.wait(0.2)
				end
			end)
		end
	end)

	FarmSection:AddButton("Collect Once (All)", function()
		for i = 1, 100 do
			collectEvent:FireServer(tostring(i))
			task.wait(0.01)
		end
	end)

	local autoGrabbingLuckyBlocks = false
	local grabbedBlocks = {}

	FarmSection:AddToggle("Auto Grab Lucky Blocks", {default = false}, function(v)
		autoGrabbingLuckyBlocks = v

		if v then
			grabbedBlocks = {}
			task.spawn(function()
				while autoGrabbingLuckyBlocks do
					local blocks = getLuckyBlocks()

					for _, blockName in ipairs(blocks) do
						if not autoGrabbingLuckyBlocks then break end

						if not grabbedBlocks[blockName] then
							if grabLuckyBlock(blockName) then
								grabbedBlocks[blockName] = true
								print("Grabbed: " .. blockName)
							end

							if autoGrabbingLuckyBlocks then
								teleportToBase()
							end
							break
						end
					end

				end
			end)
		else
			autoGrabbingLuckyBlocks = false
			grabbedBlocks = {}
		end
	end)

	-- ========== UPGRADES TAB ==========
	local UpgradesTab = Window:AddTab("Upgrades")
	local FriendUpgradesSection = UpgradesTab:AddSection("Friend Upgrades")
	local SpeedUpgradesSection = UpgradesTab:AddSection("Speed Upgrades")
	local OtherUpgradesSection = UpgradesTab:AddSection("Other Upgrades")

	FriendUpgradesSection:AddToggle("Burst Upgrade Friend 1-100", {default = false}, function(v)
		upgradingFriend = v
		if v then
			task.spawn(function()
				while upgradingFriend do
					for i = 1, 100 do
						task.spawn(function()
							if not upgradingFriend then return end
							upgradeFriend:FireServer(tostring(i))
						end)
					end
					task.wait(0.2)
				end
			end)
		end
	end)

	FriendUpgradesSection:AddButton("Upgrade Friend Once (Plot 3)", function()
		upgradeFriend:FireServer("3")
	end)

	SpeedUpgradesSection:AddToggle("Auto Upgrade Speed", {default = false}, function(v)
		upgradingSpeed = v
		if v then
			task.spawn(function()
				while upgradingSpeed do
					upgradeSpeed:FireServer()
					task.wait(0.05)
				end
			end)
		end
	end)

	SpeedUpgradesSection:AddToggle("Auto Upgrade Speed 5x", {default = false}, function(v)
		upgradingSpeed = v
		if v then
			task.spawn(function()
				while upgradingSpeed do
					upgradeSpeed5:FireServer()
					task.wait(0.05)
				end
			end)
		end
	end)

	SpeedUpgradesSection:AddButton("Upgrade Speed Once", function()
		upgradeSpeed:FireServer()
	end)

	SpeedUpgradesSection:AddButton("Upgrade Speed 5x Once", function()
		upgradeSpeed5:FireServer()
	end)

	OtherUpgradesSection:AddToggle("Auto Upgrade Boost", {default = false}, function(v)
		upgradingSpeed = v
		if v then
			task.spawn(function()
				while upgradingSpeed do
					upgradeBoost:FireServer()
					task.wait(0.05)
				end
			end)
		end
	end)

	OtherUpgradesSection:AddToggle("Auto Upgrade Carry Limit", {default = false}, function(v)
		upgradingSpeed = v
		if v then
			task.spawn(function()
				while upgradingSpeed do
					upgradeCarry:FireServer()
					task.wait(0.05)
				end
			end)
		end
	end)

	OtherUpgradesSection:AddButton("Upgrade Carry Limit Once", function()
		upgradeCarry:FireServer()
	end)

	OtherUpgradesSection:AddButton("Upgrade Boost Once", function()
		upgradeBoost:FireServer()
	end)

	-- ========== ACTIONS TAB ==========
	local ActionsTab = Window:AddTab("Actions")
	local ActionsSection = ActionsTab:AddSection("Quick Actions")

	ActionsSection:AddLabel("You must have a Brainrot in your inventory to use Sell All.")
	ActionsSection:AddLabel("Auto Sell All is not recommended.")

	ActionsSection:AddToggle("Auto Sell All", {default = false}, function(v)
		upgradingSpeed = v
		if v then
			task.spawn(function()
				while upgradingSpeed do
					sellAll:FireServer()
					task.wait(0.05)
				end
			end)
		end
	end)

	ActionsSection:AddButton("Sell All Friends", function()
		sellAll:FireServer()
	end)

	ActionsSection:AddLabel("You must have enough speed to Rebirth.")

	ActionsSection:AddToggle("Auto Rebirth", {default = false}, function(v)
		upgradingSpeed = v
		if v then
			task.spawn(function()
				while upgradingSpeed do
					rebirthEvent:FireServer()
					task.wait(0.05)
				end
			end)
		end
	end)

	ActionsSection:AddButton("Rebirth", function()
		rebirthEvent:FireServer()
	end)

	-- ========== UTILITIES TAB ==========
	local UtilitiesTab = Window:AddTab("Utilities")
	local UtilitiesSection = UtilitiesTab:AddSection("Teleport")
	local ESPSection = UtilitiesTab:AddSection("ESP")
	local ExcludeSection = UtilitiesTab:AddSection("Exclude Rarities")

	UtilitiesSection:AddButton("Teleport to Base", function()
		teleportToBase()
	end)

	local selectedZone = "Transcendent"

	UtilitiesSection:AddDropdown("Select Zone", {"Brainrot God", "Common", "Divine", "Epic", "Legendary", "Mythic", "OG", "Rare", "Secret", "Transcendent"}, {default = 10}, function(zone)
		selectedZone = zone
	end)

	UtilitiesSection:AddButton("Teleport to Zone", function()
		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")
		local target = workspace:WaitForChild("Map"):WaitForChild("GuardianSpawns"):WaitForChild(selectedZone)
		hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0)
	end)

	local luckyBlocks = getLuckyBlocks()
	UtilitiesSection:AddDropdown("Select Lucky Block", luckyBlocks, {default = 1}, function(block)
		selectedLuckyBlock = block
	end)

	UtilitiesSection:AddButton("Refresh Lucky Blocks", function()
		local blocks = getLuckyBlocks()
		if #blocks > 0 then
			selectedLuckyBlock = blocks[1]
		end
		print("Found: " .. table.concat(blocks, ", "))
	end)

	UtilitiesSection:AddButton("Teleport to Lucky Block", function()
		luckyBlocks = getLuckyBlocks()

		if not selectedLuckyBlock or selectedLuckyBlock == "" then
			selectedLuckyBlock = luckyBlocks[1]
		end

		local blockExists = false
		for _, block in ipairs(luckyBlocks) do
			if block == selectedLuckyBlock then
				blockExists = true
				break
			end
		end

		if not blockExists then
			print("Selected block no longer exists!")
			return
		end

		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")

		local friendsFolder = workspace:FindFirstChild("Live")
		if friendsFolder then
			friendsFolder = friendsFolder:FindFirstChild("Friends")
			if friendsFolder then
				local block = friendsFolder:FindFirstChild(selectedLuckyBlock)
				if block then
					local targetCFrame = block.PrimaryPart and block.PrimaryPart.CFrame or block:FindFirstChildOfClass("Part").CFrame
					hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
				end
			end
		end
	end)

	-- ESP
	local espActive = false
	local luckyBlockHighlights = {}

	local function addHighlightToBlock(block)
		if not luckyBlockHighlights[block] and block:IsA("Model") then
			local highlight = Instance.new("Highlight")
			highlight.Parent = block
			highlight.FillColor = Color3.fromRGB(0, 255, 0)
			highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			luckyBlockHighlights[block] = highlight
		end
	end

	local function removeHighlightFromBlock(block)
		if luckyBlockHighlights[block] then
			luckyBlockHighlights[block]:Destroy()
			luckyBlockHighlights[block] = nil
		end
	end

	local function refreshAllHighlights()
		local friendsFolder = workspace:FindFirstChild("Live")
		if friendsFolder then
			friendsFolder = friendsFolder:FindFirstChild("Friends")
			if friendsFolder then
				for _, model in ipairs(friendsFolder:GetChildren()) do
					if espActive and model:IsA("Model") then
						addHighlightToBlock(model)
					end
				end
			end
		end
	end

	local espConnection, childAddConnection

	ESPSection:AddToggle("Lucky Block ESP", {default = false}, function(v)
		espActive = v

		if v then
			refreshAllHighlights()

			local friendsFolder = workspace:FindFirstChild("Live")
			if friendsFolder then
				friendsFolder = friendsFolder:FindFirstChild("Friends")
				if friendsFolder then
					childAddConnection = friendsFolder.ChildAdded:Connect(function(child)
						if espActive and child:IsA("Model") then
							addHighlightToBlock(child)
						end
					end)

					espConnection = friendsFolder.ChildRemoved:Connect(function(child)
						removeHighlightFromBlock(child)
					end)
				end
			end
		else
			for block, _ in pairs(luckyBlockHighlights) do
				removeHighlightFromBlock(block)
			end
			luckyBlockHighlights = {}

			if espConnection then espConnection:Disconnect() end
			if childAddConnection then childAddConnection:Disconnect() end
		end
	end)

	ESPSection:AddToggle("Instant Proximity Prompts", {default = false}, function(v)
		if v then
			for _, prompt in ipairs(game:GetDescendants()) do
				if prompt:IsA("ProximityPrompt") then
					prompt.HoldDuration = 0
				end
			end

			local connection
			connection = game.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("ProximityPrompt") then
					descendant.HoldDuration = 0
				end
			end)

			_G.proximityConnection = connection
		else
			if _G.proximityConnection then
				_G.proximityConnection:Disconnect()
				_G.proximityConnection = nil
			end
		end
	end)

	-- Exclude Rarities
	ExcludeSection:AddLabel("Toggle to exclude from Auto Grab & Teleport")
	for _, rarity in ipairs(rarities) do
		ExcludeSection:AddToggle("Exclude " .. rarity, {default = false}, function(v)
			if v then
				table.insert(excludedRarities, rarity)
			else
				for i, r in ipairs(excludedRarities) do
					if r == rarity then
						table.remove(excludedRarities, i)
						break
					end
				end
			end
		end)
	end

	-- ========== MENU TAB ==========
	local MenuTab = Window:AddTab("Menu")
	local MenuSection = MenuTab:AddSection("Settings")
	local AppearanceSection = MenuTab:AddSection("Appearance")
	local ConfigSection = MenuTab:AddSection("Config")

	-- Appearance
	AppearanceSection:AddToggle("Rainbow Accent", {default = false}, function(v)
		rainbowActive = v
		if v then
			Window:SetAccent("rainbow")
		else
			Window:SetAccent(Color3.fromRGB(145, 57, 227))
		end
	end)

	AppearanceSection:AddButton("Purple Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(145, 57, 227))
	end)

	AppearanceSection:AddButton("Pink Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(255, 45, 120))
	end)

	AppearanceSection:AddButton("Blue Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(45, 120, 255))
	end)

	AppearanceSection:AddButton("Green Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(45, 255, 120))
	end)

	-- Config System UI
	local selectedConfig = nil
	local configDropdown = nil

	local function refreshConfigDropdown()
		if configDropdown then
			local list = getConfigList()
			configDropdown:SetList(list)
			if #list > 0 then
				selectedConfig = list[1]
				configDropdown:Select(list[1])
			else
				selectedConfig = nil
			end
		end
	end

	ConfigSection:AddLabel("Configs save to: " .. configPath)
	ConfigSection:AddLabel("")

	-- Config name input
	local configNameBox = ConfigSection:AddBox("Config Name", {clearonfocus = false, fireonempty = false}, function(text)
		-- just tracks value via Box.Box.Text
	end)

	-- Config selector dropdown (starts empty, populated after creation)
	configDropdown = ConfigSection:AddDropdown("Select Config", {}, {}, function(name)
		selectedConfig = name
	end)

	-- Save button
	ConfigSection:AddButton("Save Config", function()
		local name = configNameBox.Box.Text
		if not name or name == "" then
			name = "default"
		end
		-- strip illegal chars
		name = name:gsub('[/\\":*?<>|]', "")
		saveConfig(name)
		refreshConfigDropdown()
		-- show notification if available
		pcall(function()
			firesignal(ReplicatedStorage.SharedModules.Network.Remotes["Send Notification"].OnClientEvent, "Config saved: " .. name, "Divine", 4)
		end)
	end)

	-- Load button
	ConfigSection:AddButton("Load Config", function()
		if not selectedConfig or selectedConfig == "" then
			pcall(function()
				firesignal(ReplicatedStorage.SharedModules.Network.Remotes["Send Notification"].OnClientEvent, "No config selected!", "Rare", 4)
			end)
			return
		end
		loadConfig(selectedConfig)
		pcall(function()
			firesignal(ReplicatedStorage.SharedModules.Network.Remotes["Send Notification"].OnClientEvent, "Config loaded: " .. selectedConfig, "Divine", 4)
		end)
	end)

	-- Delete button
	ConfigSection:AddButton("Delete Config", function()
		if not selectedConfig or selectedConfig == "" then
			pcall(function()
				firesignal(ReplicatedStorage.SharedModules.Network.Remotes["Send Notification"].OnClientEvent, "No config selected!", "Rare", 4)
			end)
			return
		end
		local deleted = selectedConfig
		deleteConfig(selectedConfig)
		refreshConfigDropdown()
		pcall(function()
			firesignal(ReplicatedStorage.SharedModules.Network.Remotes["Send Notification"].OnClientEvent, "Config deleted: " .. deleted, "Rare", 4)
		end)
	end)

	-- Refresh list button
	ConfigSection:AddButton("Refresh Config List", function()
		refreshConfigDropdown()
	end)

	-- Settings
	MenuSection:AddButton("Destroy GUI", function()
		if Window then
			pcall(function() Window:Destroy() end)
		end
		for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
			if v.Name:lower():find("vynix") or v.Name:lower():find("hub") then
				v:Destroy()
			end
		end
	end)

	-- Initial config list populate
	task.defer(function()
		task.wait(1)
		refreshConfigDropdown()
	end)

else
	-- Unsupported fallback tabs
	local Tab2 = Window:AddTab("Main")
	Tab2:AddSection("Auto Farm"):AddLabel("This game is not supported.")

	local UtilitiesTab2 = Window:AddTab("Utilities")
	UtilitiesTab2:AddSection("Teleport"):AddLabel("This game is not supported.")

	local UpgradesTab2 = Window:AddTab("Upgrades")
	UpgradesTab2:AddSection("Friend Upgrades"):AddLabel("This game is not supported.")
	UpgradesTab2:AddSection("Speed Upgrades"):AddLabel("This game is not supported.")
	UpgradesTab2:AddSection("Other Upgrades"):AddLabel("This game is not supported.")

	local ActionsTab2 = Window:AddTab("Actions")
	ActionsTab2:AddSection("Quick Actions"):AddLabel("This game is not supported.")

	local MenuTab2 = Window:AddTab("Menu")
	local MenuSection2 = MenuTab2:AddSection("Settings")
	local AppearanceSection2 = MenuTab2:AddSection("Appearance")

	AppearanceSection2:AddToggle("Rainbow Accent", {default = false}, function(v)
		rainbowActive = v
		if not v then
			Window:SetAccent(Color3.fromRGB(145, 57, 227))
		end
	end)

	AppearanceSection2:AddButton("Purple Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(145, 57, 227))
	end)

	AppearanceSection2:AddButton("Pink Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(255, 45, 120))
	end)

	AppearanceSection2:AddButton("Blue Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(45, 120, 255))
	end)

	AppearanceSection2:AddButton("Green Accent", function()
		rainbowActive = false
		Window:SetAccent(Color3.fromRGB(45, 255, 120))
	end)

	MenuSection2:AddButton("Destroy GUI", function()
		if Window then
			pcall(function() Window:Destroy() end)
		end
		for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
			if v.Name:lower():find("vynix") or v.Name:lower():find("hub") then
				v:Destroy()
			end
		end
	end)
end
