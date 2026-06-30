if getgenv().NocturaLoaded then
    pcall(function()
        getgenv().NocturaUnload()
    end)
end
getgenv().NocturaLoaded = true

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local globalTask = task
local task = {}
if globalTask then
    for k, v in pairs(globalTask) do
        task[k] = v
    end
end
task.spawn = task.spawn or spawn
task.wait = task.wait or wait
task.delay = task.delay or delay
task.defer = task.defer or spawn

local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local connections = {}
local function addConnection(connection, name)
    connections[name or #connections + 1] = connection
end

local autoClickSettings = {
    enabled = false,
    cps = 10
}

local characterSettings = {
    walkSpeedEnabled = false,
    walkSpeed = 16,
    jumpPowerEnabled = false,
    jumpPower = 50,
    infiniteJump = false,
    noclip = false,
    flyEnabled = false,
    flySpeed = 50,
    gravityEnabled = false,
    gravityValue = 196.2,
    clickTPEnabled = false,
    clickTPKey = "LeftControl"
}

local originalGravity = workspace.Gravity
local flyVelocity = nil
local flyGyro = nil

local waypoints = {}
local waypointSettings = {
    selectedWaypoint = nil
}

local playerListSettings = {
    selectedPlayer = nil,
    highlightedPlayer = nil,
    highlightInstance = nil,
    spectating = false,
    attaching = false,
    following = false
}

local renderSettings = {
    fov = 70,
    fovEnabled = false,
    fullbright = false,
    originalLighting = {
        Ambient = game:GetService("Lighting").Ambient,
        ColorShift_Top = game:GetService("Lighting").ColorShift_Top,
        ColorShift_Bottom = game:GetService("Lighting").ColorShift_Bottom,
        Brightness = game:GetService("Lighting").Brightness,
        ClockTime = game:GetService("Lighting").ClockTime,
        OutdoorAmbient = game:GetService("Lighting").OutdoorAmbient
    }
}

local chatSpamSettings = {
    enabled = false,
    message = "Noctura runs you",
    delay = 3,
    lastSpam = 0
}

local playerUsernameLabel, playerDisplayNameLabel, playerTeamLabel, playerHealthLabel, playerDistanceLabel, playerAgeLabel

local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultJumpHeight = 7.2

local function onCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if humanoid then
        task.wait(0.2)
        if not characterSettings.walkSpeedEnabled then
            defaultWalkSpeed = humanoid.WalkSpeed
        end
        if not characterSettings.jumpPowerEnabled then
            if humanoid.UseJumpPower then
                defaultJumpPower = humanoid.JumpPower
            else
                defaultJumpHeight = humanoid.JumpHeight
            end
        end
    end
end

addConnection(localPlayer.CharacterAdded:Connect(onCharacterAdded), "LocalCharAddedDefaults")
if localPlayer.Character then
    task.spawn(onCharacterAdded, localPlayer.Character)
end

local function saveWaypointsToFile()
    pcall(function()
        if writefile then
            local data = {}
            for name, cf in pairs(waypoints) do
                data[name] = {cf:GetComponents()}
            end
            writefile("Noctura/waypoints.json", HttpService:JSONEncode(data))
        end
    end)
end

local function loadWaypointsFromFile()
    pcall(function()
        if isfile and isfile("Noctura/waypoints.json") and readfile then
            local raw = readfile("Noctura/waypoints.json")
            local data = HttpService:JSONDecode(raw)
            waypoints = {}
            for name, comps in pairs(data) do
                waypoints[name] = CFrame.new(unpack(comps))
            end
        end
    end)
end

local function getWaypointNames()
    local names = {}
    for name, _ in pairs(waypoints) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function updateWaypointsDropdown()
    if Options and Options.WaypointDropdown then
        Options.WaypointDropdown:SetValues(getWaypointNames())
    end
end

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= localPlayer then
            table.insert(names, p.Name)
        end
    end
    table.sort(names)
    return names
end

local function updatePlayerDropdowns()
    local names = getPlayerNames()
    if Options and Options.PlayerTPDropdown then
        Options.PlayerTPDropdown:SetValues(names)
    end
    if Options and Options.SelectedPlayerDropdown then
        Options.SelectedPlayerDropdown:SetValues(names)
    end
end

local function clearHighlight()
    if playerListSettings.highlightInstance then
        pcall(function() playerListSettings.highlightInstance:Destroy() end)
        playerListSettings.highlightInstance = nil
    end
    playerListSettings.highlightedPlayer = nil
end

local function applyHighlight(player)
    clearHighlight()
    if not player or not player.Character then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Noctura_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 120)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = player.Character
    highlight.Parent = player.Character

    playerListSettings.highlightInstance = highlight
    playerListSettings.highlightedPlayer = player
end

local function updateSpectate()
    if playerListSettings.spectating and playerListSettings.selectedPlayer then
        local char = playerListSettings.selectedPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        else
            camera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    else
        camera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
end

local function updatePlayerStatsUI()
    if not playerListSettings.selectedPlayer then
        if playerUsernameLabel then playerUsernameLabel:SetText("username: n/a") end
        if playerDisplayNameLabel then playerDisplayNameLabel:SetText("display name: n/a") end
        if playerTeamLabel then playerTeamLabel:SetText("team: n/a") end
        if playerHealthLabel then playerHealthLabel:SetText("health: n/a") end
        if playerDistanceLabel then playerDistanceLabel:SetText("distance: n/a") end
        if playerAgeLabel then playerAgeLabel:SetText("account age: n/a") end
        return
    end

    local p = playerListSettings.selectedPlayer
    if playerUsernameLabel then playerUsernameLabel:SetText("username: " .. p.Name) end
    if playerDisplayNameLabel then playerDisplayNameLabel:SetText("display name: " .. p.DisplayName) end
    if playerTeamLabel then playerTeamLabel:SetText("team: " .. (p.Team and p.Team.Name or "Neutral")) end

    local healthText = "Health: N/A"
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        healthText = string.format("Health: %.0f/%.0f", hum.Health, hum.MaxHealth)
    end
    if playerHealthLabel then playerHealthLabel:SetText(healthText) end

    local distText = "Distance: N/A"
    local localChar = localPlayer.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local targetHrp = char and char:FindFirstChild("HumanoidRootPart")
    if localHrp and targetHrp then
        distText = string.format("Distance: %.1f studs", (localHrp.Position - targetHrp.Position).Magnitude)
    end
    if playerDistanceLabel then playerDistanceLabel:SetText(distText) end

    local ageText = "Account Age: " .. tostring(p.AccountAge) .. " days"
    if playerAgeLabel then playerAgeLabel:SetText(ageText) end
end

local aimbotSettings = {
    enabled = false,
    aimPart = "Head",
    smoothness = 5,
    teamCheck = true,
    wallCheck = true,
    fovEnabled = false,
    fovRadius = 150,
    fovColor = Color3.fromRGB(255, 255, 255),
    fovThickness = 2.5,
    stickyAim = false
}

local rageSettings = {
    enabled = false,
    distance = 3,
    autoShoot = false,
    spinBot = false,
    spinSpeed = 50
}

local autoToxicSettings = {
    enabled = false,
    messages = {
        "Noctura DESTROYED you, {name}.",
        "Get packed by Noctura, {name}.",
        "Noctura runs this game, {name} is just living in it.",
        "Imagine dying to Noctura like {name} just did.",
        "{name} caught slipping by Noctura.",
        "Noctura on top, sit down {name}."
    }
}

local currentTargetPart = nil
local recentTargets = {}
local uiInitialized = false

local function cleanupConnections()
    for name, conn in pairs(connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(connections)
end

local function showFallbackNotification(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

local notifications
local hasNotifications = false
local xaxasLoaded, xaxasLib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/laagginq/ui-libraries/main/xaxas-notification/src.lua"))()
end)

if xaxasLoaded and xaxasLib then
    pcall(function()
        notifications = xaxasLib.new({
            NotificationLifetime = 4,
            NotificationPosition = "Middle",
            TextColor = Color3.fromRGB(255, 255, 255),
            TextSize = 16,
            TextStrokeTransparency = 0,
            TextStrokeColor = Color3.fromRGB(0, 0, 0),
            TextFont = Enum.Font.Code
        })
        notifications:BuildNotificationUI()
        hasNotifications = true
    end)
end

local function notify(text)
    if hasNotifications and notifications then
        pcall(function() notifications:Notify(text) end)
    else
        showFallbackNotification("Noctura", text, 4)
    end
end

local function sendChatMessage(msg)
    pcall(function()
        local textChatService = game:GetService("TextChatService")
        if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            textChatService.TextChannels.RBXGeneral:SendAsync(msg)
        else
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end

local function trackPlayerDeaths(player, character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        addConnection(humanoid.Died:Connect(function()
            if autoToxicSettings.enabled then
                local lastTargeted = recentTargets[player]

                if lastTargeted and (tick() - lastTargeted) < 2 then
                    local msg = autoToxicSettings.messages[math.random(1, #autoToxicSettings.messages)]
                    msg = string.gsub(msg, "{name}", player.DisplayName)
                    sendChatMessage(msg)
                    recentTargets[player] = nil
                end
            end
        end), "Died_"..player.Name)
    end
end

for _, player in ipairs(players:GetPlayers()) do
    if player ~= localPlayer then
        if player.Character then
            task.spawn(trackPlayerDeaths, player, player.Character)
        end
        addConnection(player.CharacterAdded:Connect(function(char)
            trackPlayerDeaths(player, char)
        end), "CharAdded_"..player.Name)
    end
end

addConnection(players.PlayerAdded:Connect(function(player)
    addConnection(player.CharacterAdded:Connect(function(char)
        trackPlayerDeaths(player, char)
    end), "CharAdded_"..player.Name)
end), "PlayerAdded")

notify("initializing noctura...")

local Sense
local senseLoaded, senseLib = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/sense'))()
end)

if senseLoaded and senseLib then
    Sense = senseLib
    notify("sirius sense esp loaded successfully.")
else
    notify("failed to load sirius sense esp. esp features disabled.")
end

getgenv().RAYFIELD_ASSET_ID = 120960636838063
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Noctura",
   LoadingTitle = "Noctura",
   LoadingSubtitle = "Universal Script",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "Noctura",
      FileName = "UniConfig"
   },
   Theme = "AmberGlow"
})

local Tabs = {
    Main = Window:CreateTab('Aimbot'),
    Rage = Window:CreateTab('Rage'),
    ESP = Window:CreateTab('Visuals'),
    Character = Window:CreateTab('Character'),
    Players = Window:CreateTab('Players'),
    Settings = Window:CreateTab('Settings')
}

local fovCircle = (Drawing and Drawing.new) and Drawing.new("Circle") or nil
if fovCircle then
    fovCircle.Thickness = aimbotSettings.fovThickness
    fovCircle.NumSides = 64
    fovCircle.Radius = aimbotSettings.fovRadius
    fovCircle.Filled = false
    fovCircle.Visible = false
    fovCircle.Color = aimbotSettings.fovColor
end

addConnection(runService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Visible = aimbotSettings.enabled and aimbotSettings.fovEnabled
        fovCircle.Radius = aimbotSettings.fovRadius
        fovCircle.Color = aimbotSettings.fovColor
        fovCircle.Thickness = aimbotSettings.fovThickness
    end
end), "FOVUpdate")

local function getClosestPlayer()
    local closestPlayerPart = nil
    local shortestDistance = math.huge
    local mouse = localPlayer:GetMouse()
    local mousePos = Vector2.new(mouse.X, mouse.Y)

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
            local differentTeam = true
            if aimbotSettings.teamCheck then
                if player.Team == localPlayer.Team and player.Team ~= nil then
                    differentTeam = false
                end
            end

            if differentTeam then
                local character = player.Character
                if character then
                    local targetPart = character:FindFirstChild(aimbotSettings.aimPart)
                    local humanoid = character:FindFirstChildOfClass("Humanoid")

                    if targetPart and humanoid and humanoid.Health > 0 then
                        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                            local distanceToMouse = (screenPos2D - mousePos).Magnitude

                            if not aimbotSettings.fovEnabled or distanceToMouse <= aimbotSettings.fovRadius then
                                local isVisible = true
                                if aimbotSettings.wallCheck then
                                    local origin = camera.CFrame.Position
                                    local direction = targetPart.Position - origin
                                    local raycastParams = RaycastParams.new()
                                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                    raycastParams.FilterDescendantsInstances = {localPlayer.Character, character, camera}
                                    raycastParams.IgnoreWater = true

                                    local result = workspace:Raycast(origin, direction, raycastParams)
                                    if result then
                                        isVisible = false
                                    end
                                end

                                if isVisible and distanceToMouse < shortestDistance then
                                    shortestDistance = distanceToMouse
                                    closestPlayerPart = targetPart
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayerPart
end

local function aimbotUpdate()
    if aimbotSettings.enabled then
        if UserInputService:GetFocusedTextBox() then return end

        local isAiming = false
        if Options and Options.AimbotKey then
            isAiming = Options.AimbotKey:GetState()
        else
            isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end

        if isAiming then
            local targetPart = nil
            if aimbotSettings.stickyAim then
                if currentTargetPart and currentTargetPart.Parent then
                    local character = currentTargetPart.Parent
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local player = players:GetPlayerFromCharacter(character)

                    if humanoid and humanoid.Health > 0 and player then
                        local differentTeam = true
                        if aimbotSettings.teamCheck then
                            if player.Team == localPlayer.Team and player.Team ~= nil then
                                differentTeam = false
                            end
                        end

                        if differentTeam then
                            local screenPos, onScreen = camera:WorldToViewportPoint(currentTargetPart.Position)
                            if onScreen then
                                local mouse = localPlayer:GetMouse()
                                local mousePos = Vector2.new(mouse.X, mouse.Y)
                                local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                                local distanceToMouse = (screenPos2D - mousePos).Magnitude

                                if not aimbotSettings.fovEnabled or distanceToMouse <= aimbotSettings.fovRadius then
                                    local isVisible = true
                                    if aimbotSettings.wallCheck then
                                        local origin = camera.CFrame.Position
                                        local direction = currentTargetPart.Position - origin
                                        local raycastParams = RaycastParams.new()
                                        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                        raycastParams.FilterDescendantsInstances = {localPlayer.Character, character, camera}
                                        raycastParams.IgnoreWater = true

                                        local result = workspace:Raycast(origin, direction, raycastParams)
                                        if result then
                                            isVisible = false
                                        end
                                    end

                                    if isVisible then
                                        targetPart = currentTargetPart
                                    end
                                end
                            end
                        end
                    end
                end

                if not targetPart then
                    targetPart = getClosestPlayer()
                end
            else
                targetPart = getClosestPlayer()
            end

            if targetPart and targetPart ~= currentTargetPart then
                local character = targetPart.Parent
                local player = players:GetPlayerFromCharacter(character)
                if player then
                    notify("locked on: " .. player.Name .. " (" .. player.DisplayName .. ")")
                end
            end

            currentTargetPart = targetPart

            if targetPart then

                local targetedPlayer = players:GetPlayerFromCharacter(targetPart.Parent)
                if targetedPlayer then
                    recentTargets[targetedPlayer] = tick()
                end

                local targetCFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
                if aimbotSettings.smoothness > 1 then
                    camera.CFrame = camera.CFrame:Lerp(targetCFrame, 1 / aimbotSettings.smoothness)
                else
                    camera.CFrame = targetCFrame
                end

                if rageSettings.enabled then
                    local localChar = localPlayer.Character
                    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
                    local targetHrp = targetPart.Parent:FindFirstChild("HumanoidRootPart")
                    if localHrp and targetHrp then
                        localHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, rageSettings.distance)
                    end
                    if rageSettings.autoShoot and mouse1click then
                        mouse1click()
                    end
                end
            end
        else
            currentTargetPart = nil
        end
    else
        currentTargetPart = nil
    end

    if rageSettings.spinBot then
        local localChar = localPlayer.Character
        local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
        if localHrp then
            localHrp.CFrame = localHrp.CFrame * CFrame.Angles(0, math.rad(rageSettings.spinSpeed), 0)
        end
    end
end

runService:BindToRenderStep("NocturaAimbot", Enum.RenderPriority.Camera.Value + 1, aimbotUpdate)

local function startFlying()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if flyVelocity then pcall(function() flyVelocity:Destroy() end) end
        if flyGyro then pcall(function() flyGyro:Destroy() end) end

        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyVelocity.MaxForce = Vector3.new(1, 1, 1) * math.huge
        flyVelocity.Parent = hrp

        flyGyro = Instance.new("BodyGyro")
        flyGyro.CFrame = hrp.CFrame
        flyGyro.MaxTorque = Vector3.new(1, 1, 1) * math.huge
        flyGyro.P = 9000
        flyGyro.Parent = hrp
    end
end

local function stopFlying()
    local wasFlying = (flyVelocity ~= nil or flyGyro ~= nil)
    if flyVelocity then
        pcall(function() flyVelocity:Destroy() end)
        flyVelocity = nil
    end
    if flyGyro then
        pcall(function() flyGyro:Destroy() end)
        flyGyro = nil
    end
    if wasFlying then
        local char = localPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end
end

local function characterUpdate()
    local char = localPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if humanoid then
        if characterSettings.walkSpeedEnabled then
            humanoid.WalkSpeed = characterSettings.walkSpeed
        end
        if characterSettings.jumpPowerEnabled then
            if humanoid.UseJumpPower then
                humanoid.JumpPower = characterSettings.jumpPower
            else
                humanoid.JumpHeight = characterSettings.jumpPower
            end
        end
    end

    if characterSettings.flyEnabled and hrp and humanoid then
        if not flyVelocity or flyVelocity.Parent ~= hrp then
            stopFlying()
            startFlying()
        end

        if flyVelocity and flyGyro then
            local direction = Vector3.new(0, 0, 0)
            local camCFrame = camera.CFrame

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + camCFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - camCFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - camCFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + camCFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                direction = direction - Vector3.new(0, 1, 0)
            end

            if direction.Magnitude > 0 then
                flyVelocity.Velocity = direction.Unit * characterSettings.flySpeed
            else
                flyVelocity.Velocity = Vector3.new(0, 0, 0)
            end

            flyGyro.CFrame = camCFrame
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    else
        if flyVelocity or flyGyro then
            stopFlying()
        end
    end
end

local function updateGravity()
    if characterSettings.gravityEnabled then
        workspace.Gravity = characterSettings.gravityValue
    else
        workspace.Gravity = originalGravity
    end
end

addConnection(runService.RenderStepped:Connect(characterUpdate), "CharacterUpdate")

addConnection(runService.Stepped:Connect(function()
    if characterSettings.noclip then
        local char = localPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end), "NoclipUpdate")

addConnection(UserInputService.JumpRequest:Connect(function()
    if characterSettings.infiniteJump then
        local char = localPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end), "InfiniteJump")

addConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if characterSettings.clickTPEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local isKeyPressed = false
        local key = characterSettings.clickTPKey
        if key == "LeftControl" then
            isKeyPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        elseif key == "LeftAlt" then
            isKeyPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
        elseif key == "LeftShift" then
            isKeyPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        elseif key == "None" then
            isKeyPressed = true
        end

        if isKeyPressed then
            local mouse = localPlayer:GetMouse()
            local targetPos = mouse.Hit.Position
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                notify("teleported to click position")
            end
        end
    end
end), "ClickTP")

task.spawn(function()
    while getgenv().NocturaLoaded do
        local delayTime = 1 / math.max(autoClickSettings.cps, 1)
        task.wait(delayTime)
        if autoClickSettings.enabled and not UserInputService:GetFocusedTextBox() then
            if mouse1click then
                pcall(mouse1click)
            end
        end
    end
end)

addConnection(runService.RenderStepped:Connect(function()
    if renderSettings.fovEnabled then
        camera.FieldOfView = renderSettings.fov
    end
end), "FOVChangerUpdate")

local lighting = game:GetService("Lighting")
addConnection(runService.RenderStepped:Connect(function()
    if renderSettings.fullbright then
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        lighting.Brightness = 2
    end
end), "FullbrightUpdate")

addConnection(runService.RenderStepped:Connect(function()
    if playerListSettings.highlightedPlayer and playerListSettings.highlightInstance then
        local char = playerListSettings.highlightedPlayer.Character
        if char and playerListSettings.highlightInstance.Parent ~= char then
            playerListSettings.highlightInstance.Adornee = char
            playerListSettings.highlightInstance.Parent = char
        end
    end
end), "HighlightPersistence")

addConnection(runService.RenderStepped:Connect(function()
    if playerListSettings.spectating and playerListSettings.selectedPlayer then
        local char = playerListSettings.selectedPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
end), "SpectateUpdate")

addConnection(runService.Heartbeat:Connect(function()
    if playerListSettings.selectedPlayer then
        local targetChar = playerListSettings.selectedPlayer.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local localChar = localPlayer.Character
        local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

        if localHrp and targetHrp then
            if playerListSettings.attaching then
                localHrp.Velocity = Vector3.new(0, 0, 0)
                localHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
            elseif playerListSettings.following then
                local targetPos = targetHrp.Position
                local currentPos = localHrp.Position
                local direction = (targetPos - currentPos)
                if direction.Magnitude > 5 then
                    localHrp.CFrame = CFrame.new(currentPos + direction.Unit * 3, targetPos)
                end
            end
        end
    end
end), "PlayerInteractLoop")

task.spawn(function()
    while getgenv().NocturaLoaded do
        task.wait(0.5)
        if chatSpamSettings.enabled then
            local now = tick()
            if now - chatSpamSettings.lastSpam >= chatSpamSettings.delay then
                sendChatMessage(chatSpamSettings.message)
                chatSpamSettings.lastSpam = now
            end
        end
    end
end)

task.spawn(function()
    while getgenv().NocturaLoaded do
        task.wait(0.5)
        pcall(updatePlayerStatsUI)
    end
end)

Tabs.Main:CreateSection("Aimbot Settings")
Tabs.Main:CreateToggle({
   Name = "Enabled",
   CurrentValue = false,
   Flag = "AimbotEnabled",
   Callback = function(Value)
      aimbotSettings.enabled = Value
   end,
})
Tabs.Main:CreateLabel("Aimbind: Hold Right Click")
Tabs.Main:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "AimPart",
   Callback = function(Options)
      aimbotSettings.aimPart = Options[1]
   end,
})
Tabs.Main:CreateSlider({
   Name = "Smoothness",
   Range = {1, 20},
   Increment = 1,
   Suffix = "",
   CurrentValue = 5,
   Flag = "AimbotSmoothness",
   Callback = function(Value)
      aimbotSettings.smoothness = Value
   end,
})
Tabs.Main:CreateToggle({
   Name = "Team Check",
   CurrentValue = true,
   Flag = "AimbotTeamCheck",
   Callback = function(Value)
      aimbotSettings.teamCheck = Value
   end,
})
Tabs.Main:CreateToggle({
   Name = "Wall Check",
   CurrentValue = true,
   Flag = "AimbotWallCheck",
   Callback = function(Value)
      aimbotSettings.wallCheck = Value
   end,
})
Tabs.Main:CreateToggle({
   Name = "Sticky Aim",
   CurrentValue = false,
   Flag = "AimbotStickyAim",
   Callback = function(Value)
      aimbotSettings.stickyAim = Value
   end,
})

Tabs.Main:CreateSection("FOV Settings")
Tabs.Main:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Flag = "AimbotFOVEnabled",
   Callback = function(Value)
      aimbotSettings.fovEnabled = Value
   end,
})
Tabs.Main:CreateSlider({
   Name = "FOV Radius",
   Range = {10, 800},
   Increment = 10,
   Suffix = "",
   CurrentValue = 150,
   Flag = "AimbotFOVRadius",
   Callback = function(Value)
      aimbotSettings.fovRadius = Value
   end,
})
Tabs.Main:CreateSlider({
   Name = "FOV Thickness",
   Range = {1, 10},
   Increment = 0.5,
   Suffix = "",
   CurrentValue = 2.5,
   Flag = "AimbotFOVThickness",
   Callback = function(Value)
      aimbotSettings.fovThickness = Value
   end,
})

Tabs.Main:CreateSection("Auto Clicker Settings")
Tabs.Main:CreateToggle({
   Name = "Enabled",
   CurrentValue = false,
   Flag = "AutoClickerEnabled",
   Callback = function(Value)
      autoClickSettings.enabled = Value
   end,
})
Tabs.Main:CreateSlider({
   Name = "Clicks Per Second (CPS)",
   Range = {1, 50},
   Increment = 1,
   Suffix = "",
   CurrentValue = 10,
   Flag = "AutoClickerCPS",
   Callback = function(Value)
      autoClickSettings.cps = Value
   end,
})

Tabs.Rage:CreateSection("Ragebot Settings")
Tabs.Rage:CreateToggle({
   Name = "Enable TP Behind (Rage)",
   CurrentValue = false,
   Flag = "RageEnabled",
   Callback = function(Value)
      rageSettings.enabled = Value
   end,
})
Tabs.Rage:CreateSlider({
   Name = "TP Distance",
   Range = {1, 10},
   Increment = 0.5,
   Suffix = "",
   CurrentValue = 3,
   Flag = "RageDistance",
   Callback = function(Value)
      rageSettings.distance = Value
   end,
})
Tabs.Rage:CreateToggle({
   Name = "Auto Shoot",
   CurrentValue = false,
   Flag = "RageAutoShoot",
   Callback = function(Value)
      rageSettings.autoShoot = Value
   end,
})

Tabs.Rage:CreateSection("Anti-Aim & Fun")
Tabs.Rage:CreateToggle({
   Name = "Spinbot",
   CurrentValue = false,
   Flag = "SpinBot",
   Callback = function(Value)
      rageSettings.spinBot = Value
   end,
})
Tabs.Rage:CreateSlider({
   Name = "Spin Speed",
   Range = {10, 100},
   Increment = 1,
   Suffix = "",
   CurrentValue = 50,
   Flag = "SpinSpeed",
   Callback = function(Value)
      rageSettings.spinSpeed = Value
   end,
})
Tabs.Rage:CreateToggle({
   Name = "Auto Toxicity (Kill Say)",
   CurrentValue = false,
   Flag = "AutoToxic",
   Callback = function(Value)
      autoToxicSettings.enabled = Value
   end,
})

Tabs.Rage:CreateSection("Chat Spammer")
Tabs.Rage:CreateToggle({
   Name = "Enable Chat Spammer",
   CurrentValue = false,
   Flag = "ChatSpammerEnabled",
   Callback = function(Value)
      chatSpamSettings.enabled = Value
   end,
})
Tabs.Rage:CreateInput({
   Name = "Spam Message",
   PlaceholderText = "Noctura runs you",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      chatSpamSettings.message = Text
   end,
})
Tabs.Rage:CreateSlider({
   Name = "Delay (Seconds)",
   Range = {1, 10},
   Increment = 1,
   Suffix = "",
   CurrentValue = 3,
   Flag = "ChatSpammerDelay",
   Callback = function(Value)
      chatSpamSettings.delay = Value
   end,
})

Tabs.ESP:CreateSection("ESP Settings")
Tabs.ESP:CreateToggle({
   Name = "Master ESP Enabled",
   CurrentValue = false,
   Flag = "ESPEnabled",
   Callback = function(Value)
      if uiInitialized and Sense then
         local enemyEnabled = Rayfield:GetFlag("EnemyESPEnabled")
         local friendlyEnabled = Rayfield:GetFlag("FriendlyESPEnabled")
         Sense.teamSettings.enemy.enabled = Value and enemyEnabled
         Sense.teamSettings.friendly.enabled = Value and friendlyEnabled
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Draw Enemies",
   CurrentValue = true,
   Flag = "EnemyESPEnabled",
   Callback = function(Value)
      if uiInitialized and Sense then
         local masterEnabled = Rayfield:GetFlag("ESPEnabled")
         Sense.teamSettings.enemy.enabled = masterEnabled and Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Draw Teammates",
   CurrentValue = false,
   Flag = "FriendlyESPEnabled",
   Callback = function(Value)
      if uiInitialized and Sense then
         local masterEnabled = Rayfield:GetFlag("ESPEnabled")
         Sense.teamSettings.friendly.enabled = masterEnabled and Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Bounding Boxes",
   CurrentValue = false,
   Flag = "BoxESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.box = Value
         Sense.teamSettings.friendly.box = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Box Outlines",
   CurrentValue = true,
   Flag = "BoxOutline",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.boxOutline = Value
         Sense.teamSettings.friendly.boxOutline = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Fill Bounding Boxes",
   CurrentValue = false,
   Flag = "BoxFill",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.boxFill = Value
         Sense.teamSettings.friendly.boxFill = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Player Names",
   CurrentValue = false,
   Flag = "NameESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.name = Value
         Sense.teamSettings.friendly.name = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Distance Text",
   CurrentValue = false,
   Flag = "DistanceESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.distance = Value
         Sense.teamSettings.friendly.distance = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Health Bars",
   CurrentValue = false,
   Flag = "HealthBarESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.healthBar = Value
         Sense.teamSettings.friendly.healthBar = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Health Values",
   CurrentValue = false,
   Flag = "HealthTextESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.healthText = Value
         Sense.teamSettings.friendly.healthText = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Tracers",
   CurrentValue = false,
   Flag = "TracerESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.tracer = Value
         Sense.teamSettings.friendly.tracer = Value
      end
   end,
})
Tabs.ESP:CreateDropdown({
   Name = "Tracer Origin",
   Options = {"Bottom", "Center", "Top"},
   CurrentOption = {"Bottom"},
   MultipleOptions = false,
   Flag = "TracerOrigin",
   Callback = function(Options)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.tracerOrigin = Options[1]
         Sense.teamSettings.friendly.tracerOrigin = Options[1]
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Player Chams",
   CurrentValue = false,
   Flag = "ChamsESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.chams = Value
         Sense.teamSettings.friendly.chams = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Chams Visible Only",
   CurrentValue = false,
   Flag = "ChamsVisibleOnly",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.chamsVisibleOnly = Value
         Sense.teamSettings.friendly.chamsVisibleOnly = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Offscreen Directional Arrows",
   CurrentValue = false,
   Flag = "OffscreenArrowESP",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.offScreenArrow = Value
         Sense.teamSettings.friendly.offScreenArrow = Value
      end
   end,
})
Tabs.ESP:CreateSlider({
   Name = "Arrow Radius",
   Range = {50, 400},
   Increment = 10,
   Suffix = "",
   CurrentValue = 150,
   Flag = "OffscreenArrowRadius",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.teamSettings.enemy.offScreenArrowRadius = Value
         Sense.teamSettings.friendly.offScreenArrowRadius = Value
      end
   end,
})

Tabs.ESP:CreateSection("Lighting & Camera")
Tabs.ESP:CreateToggle({
   Name = "Fullbright",
   CurrentValue = false,
   Flag = "FullbrightToggle",
   Callback = function(Value)
      renderSettings.fullbright = Value
      if not Value then
         local lighting = game:GetService("Lighting")
         lighting.Ambient = renderSettings.originalLighting.Ambient
         lighting.ColorShift_Top = renderSettings.originalLighting.ColorShift_Top
         lighting.ColorShift_Bottom = renderSettings.originalLighting.ColorShift_Bottom
         lighting.Brightness = renderSettings.originalLighting.Brightness
         lighting.ClockTime = renderSettings.originalLighting.ClockTime
         lighting.OutdoorAmbient = renderSettings.originalLighting.OutdoorAmbient
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Enable FOV Changer",
   CurrentValue = false,
   Flag = "FOVChangerToggle",
   Callback = function(Value)
      renderSettings.fovEnabled = Value
      if not Value then
         camera.FieldOfView = 70
      end
   end,
})
Tabs.ESP:CreateSlider({
   Name = "Field of View",
   Range = {30, 120},
   Increment = 1,
   Suffix = "",
   CurrentValue = 70,
   Flag = "CameraFOVValue",
   Callback = function(Value)
      renderSettings.fov = Value
   end,
})

Tabs.ESP:CreateSection("Visual Customizations")
Tabs.ESP:CreateSlider({
   Name = "Global Text Size",
   Range = {8, 24},
   Increment = 1,
   Suffix = "",
   CurrentValue = 13,
   Flag = "ESPTextSize",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.sharedSettings.textSize = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Limit ESP Distance",
   CurrentValue = false,
   Flag = "ESPLimitDistance",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.sharedSettings.limitDistance = Value
      end
   end,
})
Tabs.ESP:CreateSlider({
   Name = "Max ESP Distance",
   Range = {10, 1000},
   Increment = 10,
   Suffix = "",
   CurrentValue = 150,
   Flag = "ESPMaxDistance",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.sharedSettings.maxDistance = Value
      end
   end,
})
Tabs.ESP:CreateToggle({
   Name = "Override with Roblox Team Colors",
   CurrentValue = false,
   Flag = "ESPUseTeamColor",
   Callback = function(Value)
      if uiInitialized and Sense then
         Sense.sharedSettings.useTeamColor = Value
      end
   end,
})

Tabs.Character:CreateSection("Movement Settings")
Tabs.Character:CreateToggle({
   Name = "Enable Walkspeed Modifier",
   CurrentValue = false,
   Flag = "WalkSpeedEnabled",
   Callback = function(Value)
      characterSettings.walkSpeedEnabled = Value
      if not Value then
         local char = localPlayer.Character
         local humanoid = char and char:FindFirstChildOfClass("Humanoid")
         if humanoid then
            humanoid.WalkSpeed = defaultWalkSpeed
         end
      end
   end,
})
Tabs.Character:CreateSlider({
   Name = "Walkspeed",
   Range = {16, 250},
   Increment = 1,
   Suffix = "",
   CurrentValue = 16,
   Flag = "WalkSpeedValue",
   Callback = function(Value)
      characterSettings.walkSpeed = Value
   end,
})
Tabs.Character:CreateToggle({
   Name = "Enable Jumppower Modifier",
   CurrentValue = false,
   Flag = "JumpPowerEnabled",
   Callback = function(Value)
      characterSettings.jumpPowerEnabled = Value
      if not Value then
         local char = localPlayer.Character
         local humanoid = char and char:FindFirstChildOfClass("Humanoid")
         if humanoid then
            if humanoid.UseJumpPower then
               humanoid.JumpPower = defaultJumpPower
            else
               humanoid.JumpHeight = defaultJumpHeight
            end
         end
      end
   end,
})
Tabs.Character:CreateSlider({
   Name = "Jumppower/Height",
   Range = {50, 500},
   Increment = 1,
   Suffix = "",
   CurrentValue = 50,
   Flag = "JumpPowerValue",
   Callback = function(Value)
      characterSettings.jumpPower = Value
   end,
})
Tabs.Character:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfiniteJumpEnabled",
   Callback = function(Value)
      characterSettings.infiniteJump = Value
   end,
})
Tabs.Character:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipEnabled",
   Callback = function(Value)
      characterSettings.noclip = Value
   end,
})
Tabs.Character:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "FlyEnabled",
   Callback = function(Value)
      characterSettings.flyEnabled = Value
      if not Value then
         stopFlying()
      end
   end,
})
Tabs.Character:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 1,
   Suffix = "",
   CurrentValue = 50,
   Flag = "FlySpeedValue",
   Callback = function(Value)
      characterSettings.flySpeed = Value
   end,
})

Tabs.Character:CreateSection("Physics & Teleports")
Tabs.Character:CreateToggle({
   Name = "Override Gravity",
   CurrentValue = false,
   Flag = "GravityEnabled",
   Callback = function(Value)
      characterSettings.gravityEnabled = Value
      updateGravity()
   end,
})
Tabs.Character:CreateSlider({
   Name = "Gravity",
   Range = {0, 500},
   Increment = 1,
   Suffix = "",
   CurrentValue = 196.2,
   Flag = "GravityValue",
   Callback = function(Value)
      characterSettings.gravityValue = Value
      updateGravity()
   end,
})
Tabs.Character:CreateToggle({
   Name = "Click TP",
   CurrentValue = false,
   Flag = "ClickTPEnabled",
   Callback = function(Value)
      characterSettings.clickTPEnabled = Value
   end,
})
Tabs.Character:CreateDropdown({
   Name = "Click TP Modifier Key",
   Options = {"LeftControl", "LeftAlt", "LeftShift", "None"},
   CurrentOption = {"LeftControl"},
   MultipleOptions = false,
   Flag = "ClickTPKey",
   Callback = function(Options)
      characterSettings.clickTPKey = Options[1]
   end,
})

local playerList = {}
for _, player in ipairs(players:GetPlayers()) do
   if player ~= localPlayer then
      table.insert(playerList, player.Name)
   end
end
Tabs.Character:CreateDropdown({
   Name = "Select Player",
   Options = playerList,
   CurrentOption = {},
   MultipleOptions = false,
   Flag = "PlayerTPDropdown",
   Callback = function(Options)
      if Options[1] then
         local targetPlayer = players:FindFirstChild(Options[1])
         local targetChar = targetPlayer and targetPlayer.Character
         local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
         local localChar = localPlayer.Character
         local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

         if localHrp and targetHrp then
            localHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
            notify("teleported to " .. targetPlayer.DisplayName)
         else
            notify("error: target character or player not found.")
         end
      end
   end,
})

Tabs.Character:CreateSection("Waypoint Manager")
Tabs.Character:CreateInput({
   Name = "Waypoint Name",
   PlaceholderText = "Enter waypoint name to save",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      waypointSettings.selectedWaypoint = Text
   end,
})
Tabs.Character:CreateButton({
   Name = "Save Waypoint",
   Callback = function()
      local name = waypointSettings.selectedWaypoint
      if name and name ~= "" then
         local char = localPlayer.Character
         local hrp = char and char:FindFirstChild("HumanoidRootPart")
         if hrp then
            waypoints[name] = hrp.CFrame
            saveWaypointsToFile()
            notify("saved waypoint: " .. name)
         else
            notify("error: character root part not found.")
         end
      else
         notify("please enter a valid waypoint name.")
      end
   end,
})
Tabs.Character:CreateButton({
   Name = "Teleport to Waypoint",
   Callback = function()
      local name = waypointSettings.selectedWaypoint
      if name then
         local cf = waypoints[name]
         local char = localPlayer.Character
         local hrp = char and char:FindFirstChild("HumanoidRootPart")
         if hrp and cf then
            hrp.CFrame = cf
            notify("teleported to waypoint: " .. name)
         else
            notify("error: teleport failed.")
         end
      else
         notify("please enter a waypoint name.")
      end
   end,
})
Tabs.Character:CreateButton({
   Name = "Delete Waypoint",
   Callback = function()
      local name = waypointSettings.selectedWaypoint
      if name then
         waypoints[name] = nil
         saveWaypointsToFile()
         notify("deleted waypoint: " .. name)
      else
         notify("please enter a waypoint name to delete.")
      end
   end,
})

Tabs.Players:CreateSection("Player Selector & Info")
local playerList = {}
for _, player in ipairs(players:GetPlayers()) do
   if player ~= localPlayer then
      table.insert(playerList, player.Name)
   end
end
Tabs.Players:CreateDropdown({
   Name = "Select Player",
   Options = playerList,
   CurrentOption = {},
   MultipleOptions = false,
   Flag = "SelectedPlayerDropdown",
   Callback = function(Options)
      if Options[1] then
         playerListSettings.selectedPlayer = players:FindFirstChild(Options[1])
      else
         playerListSettings.selectedPlayer = nil
      end
   end,
})
Tabs.Players:CreateLabel("Username: N/A")
Tabs.Players:CreateLabel("Display Name: N/A")
Tabs.Players:CreateLabel("Team: N/A")
Tabs.Players:CreateLabel("Health: N/A")
Tabs.Players:CreateLabel("Distance: N/A")
Tabs.Players:CreateLabel("Account Age: N/A")
Tabs.Players:CreateToggle({
   Name = "Highlight Player (ESP)",
   CurrentValue = false,
   Flag = "HighlightPlayerToggle",
   Callback = function(Value)
      if Value then
         if playerListSettings.selectedPlayer then
            applyHighlight(playerListSettings.selectedPlayer)
         else
            notify("please select a player to highlight.")
         end
      else
         clearHighlight()
      end
   end,
})
Tabs.Players:CreateToggle({
   Name = "Spectate Player",
   CurrentValue = false,
   Flag = "SpectatePlayerToggle",
   Callback = function(Value)
      if Value then
         if playerListSettings.selectedPlayer then
            playerListSettings.spectating = true
            updateSpectate()
         else
            notify("please select a player to spectate.")
         end
      else
         playerListSettings.spectating = false
         updateSpectate()
      end
   end,
})

Tabs.Players:CreateSection("Player Interactions")
Tabs.Players:CreateButton({
   Name = "Teleport to Player",
   Callback = function()
      local target = playerListSettings.selectedPlayer
      local targetChar = target and target.Character
      local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
      local localChar = localPlayer.Character
      local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

      if localHrp and targetHrp then
         localHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
         notify("teleported to " .. target.DisplayName)
      else
         notify("error: target character or player not found.")
      end
   end,
})
Tabs.Players:CreateButton({
   Name = "Teleport Behind Player",
   Callback = function()
      local target = playerListSettings.selectedPlayer
      local targetChar = target and target.Character
      local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
      local localChar = localPlayer.Character
      local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

      if localHrp and targetHrp then
         localHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -3)
         notify("teleported behind " .. target.DisplayName)
      else
         notify("error: target character or player not found.")
      end
   end,
})
Tabs.Players:CreateToggle({
   Name = "Attach / Bring Player",
   CurrentValue = false,
   Flag = "AttachToPlayerToggle",
   Callback = function(Value)
      if Value then
         if playerListSettings.selectedPlayer then
            playerListSettings.attaching = true
            playerListSettings.following = false
         else
            notify("please select a player to attach to.")
         end
      else
         playerListSettings.attaching = false
      end
   end,
})
Tabs.Players:CreateToggle({
   Name = "Follow Player",
   CurrentValue = false,
   Flag = "FollowPlayerToggle",
   Callback = function(Value)
      if Value then
         if playerListSettings.selectedPlayer then
            playerListSettings.following = true
            playerListSettings.attaching = false
         else
            notify("please select a player to follow.")
         end
      else
         playerListSettings.following = false
      end
   end,
})
Tabs.Players:CreateInput({
   Name = "Custom Spam Message",
   PlaceholderText = "Hey {name}, Noctura runs you!",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      -- Store for use
   end,
})
Tabs.Players:CreateButton({
   Name = "Send Chat Message",
   Callback = function()
      local target = playerListSettings.selectedPlayer
      if target then
         sendChatMessage("Hey " .. target.DisplayName .. ", Noctura runs you!")
      else
         notify("please select a player first.")
      end
   end,
})

Tabs.Settings:CreateSection("Menu Options")
Tabs.Settings:CreateButton({
   Name = "Unload Script",
   Callback = function()
      notify("unloading noctura...")
      getgenv().NocturaLoaded = nil
      currentTargetPart = nil
      pcall(stopFlying)
      pcall(function() workspace.Gravity = originalGravity end)

      pcall(function()
         local lighting = game:GetService("Lighting")
         lighting.Ambient = renderSettings.originalLighting.Ambient
         lighting.ColorShift_Top = renderSettings.originalLighting.ColorShift_Top
         lighting.ColorShift_Bottom = renderSettings.originalLighting.ColorShift_Bottom
         lighting.Brightness = renderSettings.originalLighting.Brightness
         lighting.ClockTime = renderSettings.originalLighting.ClockTime
         lighting.OutdoorAmbient = renderSettings.originalLighting.OutdoorAmbient

         camera.FieldOfView = 70

         local char = localPlayer.Character
         local humanoid = char and char:FindFirstChildOfClass("Humanoid")
         if humanoid then
            camera.CameraSubject = humanoid
         end
      end)

      clearHighlight()
      playerListSettings.attaching = false
      playerListSettings.following = false
      playerListSettings.spectating = false

      cleanupConnections()
      pcall(function() runService:UnbindFromRenderStep("NocturaAimbot") end)
      if Sense then
         pcall(function() Sense.Unload() end)
      end
      if fovCircle then
         pcall(function() fovCircle:Destroy() end)
      end
      Rayfield:Destroy()
      notify("noctura fully unloaded.")
   end,
})

uiInitialized = true

if Sense then
   pcall(function()
      Sense.Load()
   end)
end

notify("noctura initialized!")
