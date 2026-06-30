--[[
    _   __           __                  
   / | / /___  _____/ /___  ___________ _
  /  |/ / __ \/ ___/ __/ / / / ___/ __ `/
 / /|  / /_/ / /__/ /_/ /_/ / /  / /_/ / 
/_/ |_/\____/\___/\__/\__,_/_/   \__,_(_)


-- Noctura. Enhance a game. Your way <3

]]

local selectedLuckyBlock
local excludedRarities = {}
local rarities = {"Brainrot God", "Common", "Divine", "Epic", "Legendary", "Mythic", "OG", "Rare", "Secret", "Transcendent", "Water", "Ghost", "Lava", "Taco", "67", "Rainbow"}


getgenv().RAYFIELD_ASSET_ID = 120960636838063 

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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



local Window = Rayfield:CreateWindow({
    Name = "Noctura",
    Icon = "moon",
    LoadingTitle = "Noctura | Loading",
    LoadingSubtitle = "hi mane",
    Theme = "Amethyst",
    DisableRayfieldPrompts = true,
    Discord = {
        Enabled = true,
        Invite = "bnmQTFs7QV",
        RememberJoins = true
    },
})

-- Rainbow Accent
local rainbowActive = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

-- ========== ABOUT TAB ==========
local Tab = Window:CreateTab("About")
Tab:CreateSection("Noctura")
Tab:CreateLabel("Welcome " .. player.Name .. "!")
Tab:CreateLabel("Your Display Name is " .. player.DisplayName .. "!")
Tab:CreateLabel("")

if isSupported then
	Tab:CreateLabel("Game: " .. gameName)
	Tab:CreateLabel("")
	Tab:CreateLabel("Fun Fact:")

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
	Tab:CreateLabel("📌 " .. randomFact)
else
	Tab:CreateLabel("Game: " .. gameName)
	Tab:CreateLabel("")
	Tab:CreateLabel("⚠️ This game is not supported yet!")
	Tab:CreateLabel("")
	Tab:CreateLabel("Supported Games:")
	for _, game_name in ipairs(supportedGames) do
		Tab:CreateLabel("📌 " .. game_name)
	end
end

Tab:CreateLabel("")
Tab:CreateButton({
	Name = "Join the Discord",
	Callback = function()
		firesignal(ReplicatedStorage.SharedModules.Network.Remotes["Send Notification"].OnClientEvent, "Noctura doesnt have an Official Discord Yet!", "Divine", 6)
	end,
})

-- ========== PLAYER TAB ==========
if isSupported then
	local PlayerTab = Window:CreateTab("Player")

	-- Flight
	PlayerTab:CreateSection("Flight")
	local flyActive = false
	local flySpeed = 100

	PlayerTab:CreateToggle({
		Name = "Fly",
		CurrentValue = false,
		Flag = "Fly",
		Callback = function(v)
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
		end,
	})

	PlayerTab:CreateSlider({
		Name = "Fly Speed",
		Range = {10, 2000},
		Increment = 10,
		Suffix = "",
		CurrentValue = 100,
		Flag = "FlySpeed",
		Callback = function(v)
			flySpeed = v
		end,
	})

	PlayerTab:CreateLabel("Controls: WASD to move")
	PlayerTab:CreateLabel("Space to go up, Ctrl to go down")

	-- Noclip
	PlayerTab:CreateSection("Noclip")
	local noclipActive = false

	PlayerTab:CreateToggle({
		Name = "Noclip",
		CurrentValue = false,
		Flag = "Noclip",
		Callback = function(v)
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
		end,
	})

	-- Speed Hack
	PlayerTab:CreateSection("Speed Hack")
	local walkSpeedActive = false
	local walkSpeedValue = 100

	PlayerTab:CreateToggle({
		Name = "Speed Hack",
		CurrentValue = false,
		Flag = "SpeedHack",
		Callback = function(v)
			walkSpeedActive = v
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:WaitForChild("Humanoid")
			if v then
				humanoid.WalkSpeed = walkSpeedValue
			else
				humanoid.WalkSpeed = 16
			end
		end,
	})

	PlayerTab:CreateSlider({
		Name = "Walk Speed",
		Range = {16, 500},
		Increment = 1,
		Suffix = "",
		CurrentValue = 100,
		Flag = "WalkSpeed",
		Callback = function(v)
			walkSpeedValue = v
			if walkSpeedActive then
				local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
				if humanoid then humanoid.WalkSpeed = v end
			end
		end,
	})

	-- Jump
	PlayerTab:CreateSection("Jump")
	local jumpPowerValue = 50

	PlayerTab:CreateToggle({
		Name = "High Jump",
		CurrentValue = false,
		Flag = "HighJump",
		Callback = function(v)
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.JumpPower = v and jumpPowerValue or 50
		end,
	})

	PlayerTab:CreateSlider({
		Name = "Jump Power",
		Range = {50, 500},
		Increment = 1,
		Suffix = "",
		CurrentValue = 150,
		Flag = "JumpPower",
		Callback = function(v)
			jumpPowerValue = v
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid then humanoid.JumpPower = v end
		end,
	})

	-- ========== MAIN TAB ==========
	local MainTab = Window:CreateTab("Main")
	MainTab:CreateSection("Auto Farm")

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
	local upgradingBoost = false
	local upgradingCarry = false
	local autoSelling = false
	local autoRebirthing = false

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

	MainTab:CreateToggle({
		Name = "Burst Collect 1-100",
		CurrentValue = false,
		Flag = "BurstCollect",
		Callback = function(v)
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
		end,
	})

	MainTab:CreateButton({
		Name = "Collect Once (All)",
		Callback = function()
			for i = 1, 100 do
				collectEvent:FireServer(tostring(i))
				task.wait(0.01)
			end
		end,
	})

	local autoGrabbingLuckyBlocks = false
	local grabbedBlocks = {}

	MainTab:CreateToggle({
		Name = "Auto Grab Lucky Blocks",
		CurrentValue = false,
		Flag = "AutoGrabLuckyBlocks",
		Callback = function(v)
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
		end,
	})

	-- ========== UPGRADES TAB ==========
	local UpgradesTab = Window:CreateTab("Upgrades")
	UpgradesTab:CreateSection("Upgrades")

	UpgradesTab:CreateToggle({
		Name = "Burst Upgrade Friend 1-100",
		CurrentValue = false,
		Flag = "BurstUpgradeFriend",
		Callback = function(v)
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
		end,
	})

	UpgradesTab:CreateButton({
		Name = "Upgrade Friend Once (Plot 3)",
		Callback = function()
			upgradeFriend:FireServer("3")
		end,
	})

	UpgradesTab:CreateToggle({
		Name = "Auto Upgrade Speed",
		CurrentValue = false,
		Flag = "AutoUpgradeSpeed",
		Callback = function(v)
			upgradingSpeed = v
			if v then
				task.spawn(function()
					while upgradingSpeed do
						upgradeSpeed:FireServer()
						task.wait(0.05)
					end
				end)
			end
		end,
	})

	UpgradesTab:CreateToggle({
		Name = "Auto Upgrade Speed 5x",
		CurrentValue = false,
		Flag = "AutoUpgradeSpeed5x",
		Callback = function(v)
			upgradingSpeed = v
			if v then
				task.spawn(function()
					while upgradingSpeed do
						upgradeSpeed5:FireServer()
						task.wait(0.05)
					end
				end)
			end
		end,
	})

	UpgradesTab:CreateButton({
		Name = "Upgrade Speed Once",
		Callback = function()
			upgradeSpeed:FireServer()
		end,
	})

	UpgradesTab:CreateButton({
		Name = "Upgrade Speed 5x Once",
		Callback = function()
			upgradeSpeed5:FireServer()
		end,
	})

	UpgradesTab:CreateToggle({
		Name = "Auto Upgrade Boost",
		CurrentValue = false,
		Flag = "AutoUpgradeBoost",
		Callback = function(v)
			upgradingBoost = v
			if v then
				task.spawn(function()
					while upgradingBoost do
						upgradeBoost:FireServer()
						task.wait(0.05)
					end
				end)
			end
		end,
	})

	UpgradesTab:CreateToggle({
		Name = "Auto Upgrade Carry Limit",
		CurrentValue = false,
		Flag = "AutoUpgradeCarry",
		Callback = function(v)
			upgradingCarry = v
			if v then
				task.spawn(function()
					while upgradingCarry do
						upgradeCarry:FireServer()
						task.wait(0.05)
					end
				end)
			end
		end,
	})

	UpgradesTab:CreateButton({
		Name = "Upgrade Carry Limit Once",
		Callback = function()
			upgradeCarry:FireServer()
		end,
	})

	UpgradesTab:CreateButton({
		Name = "Upgrade Boost Once",
		Callback = function()
			upgradeBoost:FireServer()
		end,
	})

	-- ========== ACTIONS TAB ==========
	local ActionsTab = Window:CreateTab("Actions")
	ActionsTab:CreateSection("Quick Actions")

	ActionsTab:CreateLabel("You must have a Brainrot in your inventory to use Sell All.")
	ActionsTab:CreateLabel("Auto Sell All is not recommended.")

	ActionsTab:CreateToggle({
		Name = "Auto Sell All",
		CurrentValue = false,
		Flag = "AutoSellAll",
		Callback = function(v)
			autoSelling = v
			if v then
				task.spawn(function()
					while autoSelling do
						sellAll:FireServer()
						task.wait(0.05)
					end
				end)
			end
		end,
	})

	ActionsTab:CreateButton({
		Name = "Sell All Friends",
		Callback = function()
			sellAll:FireServer()
		end,
	})

	ActionsTab:CreateLabel("You must have enough speed to Rebirth.")

	ActionsTab:CreateToggle({
		Name = "Auto Rebirth",
		CurrentValue = false,
		Flag = "AutoRebirth",
		Callback = function(v)
			autoRebirthing = v
			if v then
				task.spawn(function()
					while autoRebirthing do
						rebirthEvent:FireServer()
						task.wait(0.05)
					end
				end)
			end
		end,
	})

	ActionsTab:CreateButton({
		Name = "Rebirth",
		Callback = function()
			rebirthEvent:FireServer()
		end,
	})

	-- ========== UTILITIES TAB ==========
	local UtilitiesTab = Window:CreateTab("Utilities")
	UtilitiesTab:CreateSection("Utilities")

	UtilitiesTab:CreateButton({
		Name = "Teleport to Base",
		Callback = function()
			teleportToBase()
		end,
	})

	local selectedZone = "Transcendent"
	UtilitiesTab:CreateDropdown({
		Name = "Select Zone",
		Options = {"Brainrot God", "Common", "Divine", "Epic", "Legendary", "Mythic", "OG", "Rare", "Secret", "Transcendent"},
		CurrentOption = {"Transcendent"},
		MultipleOptions = false,
		Flag = "SelectedZone",
		Callback = function(Options)
			selectedZone = Options[1]
		end,
	})

	UtilitiesTab:CreateButton({
		Name = "Teleport to Zone",
		Callback = function()
			local character = player.Character or player.CharacterAdded:Wait()
			local hrp = character:WaitForChild("HumanoidRootPart")
			local target = workspace:WaitForChild("Map"):WaitForChild("GuardianSpawns"):WaitForChild(selectedZone)
			hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0)
		end,
	})

	local luckyBlocks = getLuckyBlocks()
	UtilitiesTab:CreateDropdown({
		Name = "Select Lucky Block",
		Options = luckyBlocks,
		CurrentOption = luckyBlocks[1] and {luckyBlocks[1]} or {},
		MultipleOptions = false,
		Flag = "SelectedLuckyBlock",
		Callback = function(Options)
			selectedLuckyBlock = Options[1]
		end,
	})

	UtilitiesTab:CreateButton({
		Name = "Refresh Lucky Blocks",
		Callback = function()
			local blocks = getLuckyBlocks()
			if #blocks > 0 then
				selectedLuckyBlock = blocks[1]
			end
			print("Found: " .. table.concat(blocks, ", "))
		end,
	})

	UtilitiesTab:CreateButton({
		Name = "Teleport to Lucky Block",
		Callback = function()
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
		end,
	})

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

	UtilitiesTab:CreateToggle({
		Name = "Lucky Block ESP",
		CurrentValue = false,
		Flag = "LuckyBlockESP",
		Callback = function(v)
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
		end,
	})

	UtilitiesTab:CreateToggle({
		Name = "Instant Proximity Prompts",
		CurrentValue = false,
		Flag = "InstantProximity",
		Callback = function(v)
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
		end,
	})

	-- Exclude Rarities
	UtilitiesTab:CreateLabel("Toggle to exclude from Auto Grab & Teleport")
	for _, rarity in ipairs(rarities) do
		UtilitiesTab:CreateToggle({
			Name = "Exclude " .. rarity,
			CurrentValue = false,
			Flag = "Exclude" .. rarity,
			Callback = function(v)
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
			end,
		})
	end

	-- ========== MENU TAB ==========
	local MenuTab = Window:CreateTab("Menu")
	MenuTab:CreateSection("Settings")
	MenuTab:CreateSection("Appearance")
	MenuTab:CreateSection("Config")

	MenuTab:CreateButton({
		Name = "Destroy GUI",
		Callback = function()
			if Window then
				pcall(function() Window:Destroy() end)
			end
			for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
				if v.Name:lower():find("rayfield") or v.Name:lower():find("hub") then
					v:Destroy()
				end
			end
		end,
	})

else
	-- Unsupported fallback tabs
	local Tab2 = Window:CreateTab("Main")
	Tab2:CreateSection("Auto Farm")
	Tab2:CreateLabel("This game is not supported.")

	local UtilitiesTab2 = Window:CreateTab("Utilities")
	UtilitiesTab2:CreateSection("Teleport")
	UtilitiesTab2:CreateLabel("This game is not supported.")

	local UpgradesTab2 = Window:CreateTab("Upgrades")
	UpgradesTab2:CreateSection("Friend Upgrades")
	UpgradesTab2:CreateLabel("This game is not supported.")
	UpgradesTab2:CreateSection("Speed Upgrades")
	UpgradesTab2:CreateLabel("This game is not supported.")
	UpgradesTab2:CreateSection("Other Upgrades")
	UpgradesTab2:CreateLabel("This game is not supported.")

	local ActionsTab2 = Window:CreateTab("Actions")
	ActionsTab2:CreateSection("Quick Actions")
	ActionsTab2:CreateLabel("This game is not supported.")

	local MenuTab2 = Window:CreateTab("Menu")
	MenuTab2:CreateSection("Settings")
	MenuTab2:CreateSection("Appearance")

	MenuTab2:CreateButton({
		Name = "Destroy GUI",
		Callback = function()
			if Window then
				pcall(function() Window:Destroy() end)
			end
			for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
				if v.Name:lower():find("rayfield") or v.Name:lower():find("hub") then
					v:Destroy()
				end
			end
		end,
	})
end
