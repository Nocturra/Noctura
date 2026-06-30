getgenv().RAYFIELD_ASSET_ID = 120960636838063
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Noctura | MM2 V6.6",
   LoadingTitle = "Noctura",
   LoadingSubtitle = "by Noctura",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "Noctura",
      FileName = "MM2Config"
   },
   Theme = "Amethyst"
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local configName = "NocturaMM2.json"
local toggles = {
    MurdESP = false, SheriffESP = false, InnocentESP = false, TextESP = false,
    NotifyKiller = false, Noclip = false, AutoLeak = false, AutoGrabGun = false,
    HitboxExpander = false, InfJump = false, AutoCoin = false, AntiAFK = true,
    AutoEvade = false, WalkSpeed = 16, FOV = 70, Aimbot = false, AimbotRadius = 150,
    XRay = false, ChatSpam = false, SpamMessage = "Noctura on top! Stay mad."
}

local notifiedMurderers = {}
local roundActive = false
local originalMaterials = {}
local currentAimbotTarget = nil

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 60
fovCircle.Radius = toggles.AimbotRadius
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)

local function saveConfig()
    local success, err = pcall(function() writefile(configName, HttpService:JSONEncode(toggles)) end)
    if success then Rayfield:Notify({Title = "Saved", Content = "Configuration saved successfully.", Duration = 3})
    else warn("Failed to save config: " .. tostring(err)) end
end

local function loadConfig()
    if isfile and isfile(configName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(configName)) end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do toggles[k] = v end
            Camera.FieldOfView = toggles.FOV
            fovCircle.Radius = toggles.AimbotRadius
            Rayfield:Notify({Title = "Loaded", Content = "Configuration loaded successfully.", Duration = 3})
        end
    end
end

local function getRole(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    local function hasItem(name) return (backpack and backpack:FindFirstChild(name)) or (character and character:FindFirstChild(name)) end

    if hasItem("Knife") then return "Murderer" end
    if hasItem("Gun") or hasItem("Revolver") then return "Sheriff" end
    return "Innocent"
end

local function sendChat(msg)
    local textChannel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if textChannel then textChannel:SendAsync(msg)
    elseif ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All") end
end

local function triggerLeak()
    local murd, sher = "Nobody", "Nobody"
    local innocents = {}

    for _, p in pairs(Players:GetPlayers()) do
        local role = getRole(p)
        if role == "Murderer" then murd = p.Name
        elseif role == "Sheriff" then sher = p.Name
        elseif role == "Innocent" and p ~= LocalPlayer then table.insert(innocents, p.Name) end
    end

    local msg = ""
    if murd == LocalPlayer.Name then
        local scapegoat = innocents[math.random(1, #innocents)] or "Someone"
        msg = scapegoat .. " is acting suspicious. They might be the murderer."
    else
        msg = "Murderer: " .. murd .. " | Sheriff: " .. sher
    end
    sendChat(msg)
end

local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = toggles.AimbotRadius
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Make sure they aren't dead
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDistance then
                        closestPlayer = p
                        shortestDistance = dist
                    end
                end
            end
        end
    end
    return closestPlayer
end
task.spawn(function()
    while task.wait(3) do
        if toggles.ChatSpam then
            sendChat(toggles.SpamMessage)
        end
    end
end)
task.spawn(function()
    while task.wait(0.1) do
        if toggles.AutoCoin and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local coinFolder = workspace:FindFirstChild("Workplace") and workspace.Workplace:FindFirstChild("CoinContainer")
            
            if coinFolder then
                for _, obj in pairs(coinFolder:GetChildren()) do
                    -- Bail out immediately if you toggle it off mid-farm
                    if not toggles.AutoCoin then break end 
                    
                    if obj.Name == "Coin_Server" or obj.Name == "Coin" then
                        -- Position ~3.5 studs under the coin so you're chilling under the floor
                        local targetCFrame = obj.CFrame * CFrame.new(0, -3.5, 0)
                        
                        -- Math to keep the speed consistent no matter the distance
                        local distance = (hrp.Position - targetCFrame.Position).Magnitude
                        local speed = 45 -- Studs per second. Tweak this if it's too fast or slow
                        local timeToMove = distance / speed
                        
                        -- Smooth slide using TweenService
                        local tweenInfo = TweenInfo.new(timeToMove, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                        
                        -- Anchor so gravity doesn't drag you to the void
                        hrp.Anchored = true 
                        
                        tween:Play()
                        tween.Completed:Wait() -- Wait until the tween actually reaches the coin
                        
                        -- Tiny pause so the server registers you touching the hitbox
                        task.wait(0.15) 
                    end
                end
                
                -- Unanchor once the loop finishes or stops finding coins
                if hrp then 
                    hrp.Anchored = false 
                end
            end
        end
    end
end)
local function handleXRay()
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Parent:FindFirstChild("Humanoid") then
            if toggles.XRay then
                if not originalMaterials[part] then
                    originalMaterials[part] = {Transparency = part.Transparency, Material = part.Material}
                end
                part.Transparency = 0.65
                part.Material = Enum.Material.ForceField
            elseif originalMaterials[part] then
                part.Transparency = originalMaterials[part].Transparency
                part.Material = originalMaterials[part].Material
                originalMaterials[part] = nil
            end
        end
    end
end

LocalPlayer.Idled:Connect(function()
    if toggles.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if toggles.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local function createTextESP(player)
    local textEsp = player.Character:FindFirstChild("NocturaTextESP")
    if not textEsp and player.Character:FindFirstChild("Head") then
        textEsp = Instance.new("BillboardGui", player.Character)
        textEsp.Name = "NocturaTextESP"; textEsp.Size = UDim2.new(0, 100, 0, 40)
        textEsp.StudsOffset = Vector3.new(0, 2.5, 0); textEsp.AlwaysOnTop = true
        textEsp.Adornee = player.Character.Head
        local label = Instance.new("TextLabel", textEsp)
        label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
        label.TextScaled = true; label.Font = Enum.Font.GothamBold
        label.Name = "TextLabel"
    end
    return textEsp
end

local function removeTextESP(player)
    local textEsp = player.Character:FindFirstChild("NocturaTextESP")
    if textEsp then textEsp:Destroy() end
end

RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local someoneIsMurderer = false

    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = mousePos
    fovCircle.Visible = toggles.Aimbot

    if toggles.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentAimbotTarget then
            currentAimbotTarget = getClosestPlayerToCursor()
        end
        
        if currentAimbotTarget and currentAimbotTarget.Character and currentAimbotTarget.Character:FindFirstChild("HumanoidRootPart") then
            local targetHum = currentAimbotTarget.Character:FindFirstChild("Humanoid")
            if targetHum and targetHum.Health > 0 then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentAimbotTarget.Character.HumanoidRootPart.Position)
            else
                currentAimbotTarget = nil
            end
        else
            currentAimbotTarget = nil
        end
    else
        currentAimbotTarget = nil
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end

        local role = getRole(player)
        local highlight = player.Character:FindFirstChild("NocturaHighlight")
        local textEsp = player.Character:FindFirstChild("NocturaTextESP")
        local shouldShow = false
        local color = Color3.fromRGB(0, 255, 0)
        local roleText = "Innocent"
        
        local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")

        if role == "Murderer" then
            someoneIsMurderer = true
            roleText = "MURDERER"
            if toggles.MurdESP then shouldShow = true; color = Color3.fromRGB(255, 0, 0) end
            
            if myRoot and enemyRoot then
                local dist = (myRoot.Position - enemyRoot.Position).Magnitude
                
                if toggles.NotifyKiller and dist < 25 and not notifiedMurderers[player.Name] then
                    Rayfield:Notify({Title = "Warning", Content = player.Name .. " is approaching!", Duration = 4})
                    notifiedMurderers[player.Name] = true
                elseif dist > 35 then
                    notifiedMurderers[player.Name] = false
                end
                
                if toggles.AutoEvade and dist < 12 then
                    myRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, 20)
                    Rayfield:Notify({Title = "Evasion", Content = "Automatically evaded the murderer.", Duration = 2})
                end
            end
        elseif role == "Sheriff" then
            roleText = "SHERIFF"
            if toggles.SheriffESP then shouldShow = true; color = Color3.fromRGB(0, 0, 255) end
        elseif role == "Innocent" then
            if toggles.InnocentESP then shouldShow = true; color = Color3.fromRGB(0, 255, 0) end
        end

        if shouldShow then
            if not highlight then
                highlight = Instance.new("Highlight", player.Character)
                highlight.Name = "NocturaHighlight"
            end
            highlight.FillColor = color; highlight.OutlineColor = color
            highlight.FillTransparency = 0.7; highlight.OutlineTransparency = 0
        elseif highlight then highlight:Destroy() end

        if toggles.TextESP then
            textEsp = createTextESP(player)
            if textEsp and textEsp:FindFirstChild("TextLabel") then
                textEsp.TextLabel.Text = player.Name .. "\n[" .. roleText .. "]"
                textEsp.TextLabel.TextColor3 = color
                textEsp.Enabled = shouldShow
            end
        elseif textEsp then
            removeTextESP(player)
        end

        if toggles.HitboxExpander and enemyRoot then
            enemyRoot.Size = Vector3.new(12, 12, 12)
            enemyRoot.Transparency = 0.8
            enemyRoot.CanCollide = false
        elseif enemyRoot and not toggles.HitboxExpander then
            enemyRoot.Size = Vector3.new(2, 2, 1)
            enemyRoot.Transparency = 1
        end
    end

    if someoneIsMurderer and not roundActive then
        roundActive = true
        if toggles.AutoLeak then task.wait(1.5) triggerLeak() end
    elseif not someoneIsMurderer and roundActive then
        roundActive = false
    end

    if toggles.AutoGrabGun and myRoot and getRole(LocalPlayer) == "Innocent" then
        local gunDrop = workspace:FindFirstChild("GunDrop") or workspace:FindFirstChild("GunDrop", true)
        if gunDrop then
            myRoot.CFrame = gunDrop.CFrame
            toggles.AutoGrabGun = false
            Rayfield:Notify({Title = "Success", Content = "Retrieved the dropped weapon.", Duration = 3})
        end
    end

    if myChar and myChar:FindFirstChild("Humanoid") and myChar.Humanoid.WalkSpeed ~= toggles.WalkSpeed then
        myChar.Humanoid.WalkSpeed = toggles.WalkSpeed
    end
end)

RunService.Stepped:Connect(function()
    if toggles.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)


local ESPTab = Window:CreateTab("ESP")
local CombatTab = Window:CreateTab("Combat")
local MovementTab = Window:CreateTab("Movement")
local UtilityTab = Window:CreateTab("Utility")
local PlayersTab = Window:CreateTab("Players")
local ServerTab = Window:CreateTab("Server")
local SettingsTab = Window:CreateTab("Settings")

local ESPSection = ESPTab:CreateSection("Visuals")
ESPTab:CreateToggle({
   Name = "Murderer ESP",
   CurrentValue = false,
   Flag = "MurdESP",
   Callback = function(Value)
      toggles.MurdESP = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Sheriff ESP",
   CurrentValue = false,
   Flag = "SheriffESP",
   Callback = function(Value)
      toggles.SheriffESP = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Innocent ESP",
   CurrentValue = false,
   Flag = "InnocentESP",
   Callback = function(Value)
      toggles.InnocentESP = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Text ESP",
   CurrentValue = false,
   Flag = "TextESP",
   Callback = function(Value)
      toggles.TextESP = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Notify Murderer Proximity",
   CurrentValue = false,
   Flag = "NotifMurd",
   Callback = function(Value)
      toggles.NotifyKiller = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Map X-Ray",
   CurrentValue = false,
   Flag = "XRay",
   Callback = function(Value)
      toggles.XRay = Value
      handleXRay()
   end,
})

local CombatSection = CombatTab:CreateSection("Combat Tools")
CombatTab:CreateToggle({
   Name = "Enable Aimbot (Hold Right-Click)",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
      toggles.Aimbot = Value
      fovCircle.Visible = Value
   end,
})
CombatTab:CreateSlider({
   Name = "Aimbot Target Radius",
   Range = {50, 400},
   Increment = 1,
   Suffix = "",
   CurrentValue = 150,
   Flag = "AimbotRadius",
   Callback = function(Value)
      toggles.AimbotRadius = Value
      fovCircle.Radius = Value
   end,
})
CombatTab:CreateToggle({
   Name = "Hitbox Expander",
   CurrentValue = false,
   Flag = "HitboxExpander",
   Callback = function(Value)
      toggles.HitboxExpander = Value
   end,
})
CombatTab:CreateToggle({
   Name = "Auto-Grab Dropped Gun",
   CurrentValue = false,
   Flag = "AutoGun",
   Callback = function(Value)
      toggles.AutoGrabGun = Value
   end,
})
CombatTab:CreateToggle({
   Name = "Auto-Evade Proximity",
   CurrentValue = false,
   Flag = "AutoEvade",
   Callback = function(Value)
      toggles.AutoEvade = Value
   end,
})
CombatTab:CreateToggle({
   Name = "Auto-Accuse on Round Start",
   CurrentValue = false,
   Flag = "AutoLeak",
   Callback = function(Value)
      toggles.AutoLeak = Value
   end,
})

CombatTab:CreateButton({
   Name = "Eliminate All (Requires Knife)",
   Callback = function()
      local char = LocalPlayer.Character
      if not char or not char:FindFirstChild("HumanoidRootPart") then return end
      local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
      if not knife then return Rayfield:Notify({Title = "Error", Content = "Knife tool is required.", Duration = 3}) end

      char.Humanoid:EquipTool(knife)
      for _, p in pairs(Players:GetPlayers()) do
         if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1.5)
            task.wait(0.2)
         end
      end
   end,
})

local MovementSection = MovementTab:CreateSection("Mobility")
MovementTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJump",
   Callback = function(Value)
      toggles.InfJump = Value
   end,
})
MovementTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
      toggles.Noclip = Value
   end,
})
MovementTab:CreateSlider({
   Name = "WalkSpeed Override",
   Range = {16, 120},
   Increment = 1,
   Suffix = "",
   CurrentValue = 16,
   Flag = "WalkSpeed",
   Callback = function(Value)
      toggles.WalkSpeed = Value
   end,
})
MovementTab:CreateSlider({
   Name = "Field of View (FOV)",
   Range = {70, 120},
   Increment = 1,
   Suffix = "",
   CurrentValue = 70,
   Flag = "FOV",
   Callback = function(Value)
      toggles.FOV = Value
      Camera.FieldOfView = Value
   end,
})

MovementTab:CreateSection("Locations")
MovementTab:CreateButton({
   Name = "Teleport to Safe Zone",
   Callback = function()
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 800, 0)
         LocalPlayer.Character.HumanoidRootPart.Anchored = true
         Rayfield:Notify({Title = "Teleported", Content = "Moved to safe location. Un-anchor to resume movement.", Duration = 3})
      end
   end,
})
MovementTab:CreateButton({
   Name = "Disable Anchor",
   Callback = function()
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         LocalPlayer.Character.HumanoidRootPart.Anchored = false
      end
   end,
})

local UtilitySection = UtilityTab:CreateSection("Automation & Fun")
UtilityTab:CreateToggle({
   Name = "Auto-Farm Coins",
   CurrentValue = false,
   Flag = "AutoCoin",
   Callback = function(Value)
      toggles.AutoCoin = Value
   end,
})
UtilityTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = true,
   Flag = "AntiAFK",
   Callback = function(Value)
      toggles.AntiAFK = Value
   end,
})
UtilityTab:CreateToggle({
   Name = "Enable Chat Spammer",
   CurrentValue = false,
   Flag = "ChatSpam",
   Callback = function(Value)
      toggles.ChatSpam = Value
   end,
})

local ServerSection = ServerTab:CreateSection("Lobby Controls")
ServerTab:CreateButton({
   Name = "Rejoin Current Server",
   Callback = function()
      TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
   end,
})
ServerTab:CreateButton({
   Name = "Server Hop",
   Callback = function()
      Rayfield:Notify({Title = "Hopping", Content = "Finding a new server...", Duration = 3})
      TeleportService:Teleport(game.PlaceId, LocalPlayer)
   end,
})

local ConfigSection = SettingsTab:CreateSection("Configuration")
SettingsTab:CreateButton({
   Name = "Save Configuration",
   Callback = saveConfig
})
SettingsTab:CreateButton({
   Name = "Load Configuration",
   Callback = loadConfig
})

local playerSections = {}
local function refreshPlayerList()
    for _, section in pairs(playerSections) do if section and section.Destroy then section:Destroy() end end
    playerSections = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        PlayersTab:CreateSection(player.Name)
        PlayersTab:CreateButton({
            Name = "Teleport To " .. player.Name,
            Callback = function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                    LocalPlayer.Character.HumanoidRootPart.Anchored = false
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end,
        })
        PlayersTab:CreateButton({
            Name = "Spectate " .. player.Name,
            Callback = function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    Camera.CameraSubject = player.Character.Humanoid
                    Rayfield:Notify({Title = "Spectating", Content = "Watching " .. player.Name, Duration = 2})
                end
            end,
        })
    end

    PlayersTab:CreateSection("Local Controls")
    PlayersTab:CreateButton({
        Name = "Stop Spectating",
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
            end
        end,
    })
end
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
refreshPlayerList()
