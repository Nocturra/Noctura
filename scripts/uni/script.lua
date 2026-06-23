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

local repos = {
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/",
    "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/",
    "https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/"
}

local Library, ThemeManager, SaveManager
local loadedRepo = nil

for _, checkRepo in ipairs(repos) do
    local success, lib = pcall(function()
        return loadstring(game:HttpGet(checkRepo .. 'Library.lua'))()
    end)
    if success and lib then
        local success2, theme = pcall(function()
            return loadstring(game:HttpGet(checkRepo .. 'addons/ThemeManager.lua'))()
        end)
        local success3, save = pcall(function()
            return loadstring(game:HttpGet(checkRepo .. 'addons/SaveManager.lua'))()
        end)

        if success2 and theme and success3 and save then
            Library = lib
            ThemeManager = theme
            SaveManager = save
            loadedRepo = checkRepo
            break
        end
    end
end

if not Library then
    notify("error: failed to load linoria ui. check connection.")
    error("noctura: failed to load linoria library from all mirrors.")
    return
end

local Window = Library:CreateWindow({
    Title = 'noctura',
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab('aimbot'),
    Rage = Window:AddTab('rage'),
    ESP = Window:AddTab('visuals/esp'),
    Character = Window:AddTab('character'),
    Players = Window:AddTab('players'),
    ['UI Settings'] = Window:AddTab('settings')
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

local AimbotLeftGroup = Tabs.Main:AddLeftGroupbox('aimbot settings')

AimbotLeftGroup:AddToggle('AimbotEnabled', { Text = 'enabled', Default = false })
Toggles.AimbotEnabled:OnChanged(function() aimbotSettings.enabled = Toggles.AimbotEnabled.Value end)

AimbotLeftGroup:AddLabel('aimbind'):AddKeyPicker('AimbotKey', { Default = 'MB2', SyncToggleState = false, Mode = 'Hold', Text = 'aimbot keybind', NoUI = false })

AimbotLeftGroup:AddDropdown('AimPart', { Values = { 'Head', 'HumanoidRootPart' }, Default = 1, Multi = false, Text = 'aim part' })
Options.AimPart:OnChanged(function() aimbotSettings.aimPart = Options.AimPart.Value end)

AimbotLeftGroup:AddSlider('AimbotSmoothness', { Text = 'smoothness', Default = 5, Min = 1, Max = 20, Rounding = 0, Compact = false })
Options.AimbotSmoothness:OnChanged(function() aimbotSettings.smoothness = Options.AimbotSmoothness.Value end)

AimbotLeftGroup:AddToggle('AimbotTeamCheck', { Text = 'team check', Default = true })
Toggles.AimbotTeamCheck:OnChanged(function() aimbotSettings.teamCheck = Toggles.AimbotTeamCheck.Value end)

AimbotLeftGroup:AddToggle('AimbotWallCheck', { Text = 'wall check', Default = true })
Toggles.AimbotWallCheck:OnChanged(function() aimbotSettings.wallCheck = Toggles.AimbotWallCheck.Value end)

AimbotLeftGroup:AddToggle('AimbotStickyAim', { Text = 'sticky aim', Default = false })
Toggles.AimbotStickyAim:OnChanged(function() aimbotSettings.stickyAim = Toggles.AimbotStickyAim.Value end)

local AimbotRightGroup = Tabs.Main:AddRightGroupbox('fov settings')

AimbotRightGroup:AddToggle('AimbotFOVEnabled', { Text = 'show fov circle', Default = false })
Toggles.AimbotFOVEnabled:OnChanged(function() aimbotSettings.fovEnabled = Toggles.AimbotFOVEnabled.Value end)

AimbotRightGroup:AddSlider('AimbotFOVRadius', { Text = 'fov radius', Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = false })
Options.AimbotFOVRadius:OnChanged(function() aimbotSettings.fovRadius = Options.AimbotFOVRadius.Value end)

AimbotRightGroup:AddSlider('AimbotFOVThickness', { Text = 'fov thickness', Default = 2.5, Min = 1, Max = 10, Rounding = 1, Compact = false })
Options.AimbotFOVThickness:OnChanged(function() aimbotSettings.fovThickness = Options.AimbotFOVThickness.Value end)

AimbotRightGroup:AddLabel('fov color'):AddColorPicker('AimbotFOVColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'fov circle color' })
Options.AimbotFOVColor:OnChanged(function() aimbotSettings.fovColor = Options.AimbotFOVColor.Value end)

local AutoClickerGroup = Tabs.Main:AddRightGroupbox('auto clicker settings')

AutoClickerGroup:AddToggle('AutoClickerEnabled', { Text = 'enabled', Default = false })
Toggles.AutoClickerEnabled:OnChanged(function() autoClickSettings.enabled = Toggles.AutoClickerEnabled.Value end)

AutoClickerGroup:AddSlider('AutoClickerCPS', { Text = 'clicks per second (cps)', Default = 10, Min = 1, Max = 50, Rounding = 0, Compact = false })
Options.AutoClickerCPS:OnChanged(function() autoClickSettings.cps = Options.AutoClickerCPS.Value end)

local RageLeftGroup = Tabs.Rage:AddLeftGroupbox('ragebot settings')

RageLeftGroup:AddToggle('RageEnabled', { Text = 'enable tp behind (rage)', Default = false })
Toggles.RageEnabled:OnChanged(function() rageSettings.enabled = Toggles.RageEnabled.Value end)

RageLeftGroup:AddSlider('RageDistance', { Text = 'tp distance', Default = 3, Min = 1, Max = 10, Rounding = 1, Compact = false })
Options.RageDistance:OnChanged(function() rageSettings.distance = Options.RageDistance.Value end)

RageLeftGroup:AddToggle('RageAutoShoot', { Text = 'auto shoot', Default = false })
Toggles.RageAutoShoot:OnChanged(function() rageSettings.autoShoot = Toggles.RageAutoShoot.Value end)

local RageRightGroup = Tabs.Rage:AddRightGroupbox('anti-aim & fun')

RageRightGroup:AddToggle('SpinBot', { Text = 'spinbot', Default = false })
Toggles.SpinBot:OnChanged(function() rageSettings.spinBot = Toggles.SpinBot.Value end)

RageRightGroup:AddSlider('SpinSpeed', { Text = 'spin speed', Default = 50, Min = 10, Max = 100, Rounding = 0, Compact = false })
Options.SpinSpeed:OnChanged(function() rageSettings.spinSpeed = Options.SpinSpeed.Value end)

RageRightGroup:AddDivider()

RageRightGroup:AddToggle('AutoToxic', { Text = 'auto toxicity (kill say)', Default = false })
Toggles.AutoToxic:OnChanged(function() autoToxicSettings.enabled = Toggles.AutoToxic.Value end)

local SpamGroup = Tabs.Rage:AddRightGroupbox('chat spammer')

SpamGroup:AddToggle('ChatSpammerEnabled', { Text = 'enable chat spammer', Default = false })
Toggles.ChatSpammerEnabled:OnChanged(function() chatSpamSettings.enabled = Toggles.ChatSpammerEnabled.Value end)

SpamGroup:AddInput('ChatSpamMessage', {
    Default = 'Noctura runs you',
    Numeric = false,
    Finished = true,
    Text = 'spam message'
})
Options.ChatSpamMessage:OnChanged(function() chatSpamSettings.message = Options.ChatSpamMessage.Value end)

SpamGroup:AddSlider('ChatSpammerDelay', { Text = 'delay (seconds)', Default = 3, Min = 1, Max = 10, Rounding = 1, Compact = false })
Options.ChatSpammerDelay:OnChanged(function() chatSpamSettings.delay = Options.ChatSpammerDelay.Value end)

local ESPMainGroup = Tabs.ESP:AddLeftGroupbox('esp settings')
local ESPVisualsGroup = Tabs.ESP:AddRightGroupbox('visual customisations')

local function updateESPSettings()
    if not uiInitialized or not Sense then return end
    local masterEnabled = Toggles.ESPEnabled.Value
    local enemyEnabled = Toggles.EnemyESPEnabled.Value
    local friendlyEnabled = Toggles.FriendlyESPEnabled.Value
    Sense.teamSettings.enemy.enabled = masterEnabled and enemyEnabled
    Sense.teamSettings.friendly.enabled = masterEnabled and friendlyEnabled
    for _, team in ipairs({"enemy", "friendly"}) do
        local cfg = Sense.teamSettings[team]
        cfg.box = Toggles.BoxESP.Value
        cfg.boxOutline = Toggles.BoxOutline.Value
        cfg.boxFill = Toggles.BoxFill.Value
        cfg.name = Toggles.NameESP.Value
        cfg.distance = Toggles.DistanceESP.Value
        cfg.healthBar = Toggles.HealthBarESP.Value
        cfg.healthText = Toggles.HealthTextESP.Value
        cfg.tracer = Toggles.TracerESP.Value
        cfg.tracerOrigin = Options.TracerOrigin.Value
        cfg.offScreenArrow = Toggles.OffscreenArrowESP.Value
        cfg.offScreenArrowRadius = Options.OffscreenArrowRadius.Value
        cfg.chams = Toggles.ChamsESP.Value
        cfg.chamsVisibleOnly = Toggles.ChamsVisibleOnly.Value
    end
end

local function updateESPColors()
    if not uiInitialized or not Sense then return end
    local enemyCfg = Sense.teamSettings.enemy
    enemyCfg.boxColor = { Options.EnemyBoxColor.Value, 1 - Options.EnemyBoxColor.Transparency }
    enemyCfg.boxFillColor = { Options.EnemyBoxFillColor.Value, 1 - Options.EnemyBoxFillColor.Transparency }
    enemyCfg.nameColor = { Options.EnemyNameColor.Value, 1 - Options.EnemyNameColor.Transparency }
    enemyCfg.distanceColor = { Options.EnemyDistanceColor.Value, 1 - Options.EnemyDistanceColor.Transparency }
    enemyCfg.healthTextColor = { Options.EnemyHealthTextColor.Value, 1 - Options.EnemyHealthTextColor.Transparency }
    enemyCfg.tracerColor = { Options.EnemyTracerColor.Value, 1 - Options.EnemyTracerColor.Transparency }
    enemyCfg.offScreenArrowColor = { Options.EnemyArrowColor.Value, 1 - Options.EnemyArrowColor.Transparency }
    enemyCfg.chamsFillColor = { Options.EnemyChamsFillColor.Value, 1 - Options.EnemyChamsFillColor.Transparency }
    enemyCfg.chamsOutlineColor = { Options.EnemyChamsOutlineColor.Value, 1 - Options.EnemyChamsOutlineColor.Transparency }
    local friendlyCfg = Sense.teamSettings.friendly
    friendlyCfg.boxColor = { Options.FriendlyBoxColor.Value, 1 - Options.FriendlyBoxColor.Transparency }
    friendlyCfg.boxFillColor = { Options.FriendlyBoxFillColor.Value, 1 - Options.FriendlyBoxFillColor.Transparency }
    friendlyCfg.nameColor = { Options.FriendlyNameColor.Value, 1 - Options.FriendlyNameColor.Transparency }
    friendlyCfg.distanceColor = { Options.FriendlyDistanceColor.Value, 1 - Options.FriendlyDistanceColor.Transparency }
    friendlyCfg.healthTextColor = { Options.FriendlyHealthTextColor.Value, 1 - Options.FriendlyHealthTextColor.Transparency }
    friendlyCfg.tracerColor = { Options.FriendlyTracerColor.Value, 1 - Options.FriendlyTracerColor.Transparency }
    friendlyCfg.offScreenArrowColor = { Options.FriendlyArrowColor.Value, 1 - Options.FriendlyArrowColor.Transparency }
    friendlyCfg.chamsFillColor = { Options.FriendlyChamsFillColor.Value, 1 - Options.FriendlyChamsFillColor.Transparency }
    friendlyCfg.chamsOutlineColor = { Options.FriendlyChamsOutlineColor.Value, 1 - Options.FriendlyChamsOutlineColor.Transparency }
end

local function updateSharedSettings()
    if not uiInitialized or not Sense then return end
    Sense.sharedSettings.textSize = Options.ESPTextSize.Value
    Sense.sharedSettings.limitDistance = Toggles.ESPLimitDistance.Value
    Sense.sharedSettings.maxDistance = Options.ESPMaxDistance.Value
    Sense.sharedSettings.useTeamColor = Toggles.ESPUseTeamColor.Value
end

ESPMainGroup:AddToggle('ESPEnabled', { Text = 'master esp enabled', Default = false })
Toggles.ESPEnabled:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('EnemyESPEnabled', { Text = 'draw enemies', Default = true })
Toggles.EnemyESPEnabled:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('FriendlyESPEnabled', { Text = 'draw teammates', Default = false })
Toggles.FriendlyESPEnabled:OnChanged(updateESPSettings)

ESPMainGroup:AddDivider()

ESPMainGroup:AddToggle('BoxESP', { Text = 'bounding boxes', Default = false })
Toggles.BoxESP:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('BoxOutline', { Text = 'box outlines', Default = true })
Toggles.BoxOutline:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('BoxFill', { Text = 'fill bounding boxes', Default = false })
Toggles.BoxFill:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('NameESP', { Text = 'player names', Default = false })
Toggles.NameESP:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('DistanceESP', { Text = 'distance text', Default = false })
Toggles.DistanceESP:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('HealthBarESP', { Text = 'health bars', Default = false })
Toggles.HealthBarESP:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('HealthTextESP', { Text = 'health values', Default = false })
Toggles.HealthTextESP:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('TracerESP', { Text = 'tracers', Default = false })
Toggles.TracerESP:OnChanged(updateESPSettings)

ESPMainGroup:AddDropdown('TracerOrigin', { Values = { 'Bottom', 'Center', 'Top' }, Default = 1, Multi = false, Text = 'tracer origin' })
Options.TracerOrigin:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('ChamsESP', { Text = 'player chams', Default = false })
Toggles.ChamsESP:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('ChamsVisibleOnly', { Text = 'chams visible only', Default = false })
Toggles.ChamsVisibleOnly:OnChanged(updateESPSettings)

ESPMainGroup:AddToggle('OffscreenArrowESP', { Text = 'offscreen directional arrows', Default = false })
Toggles.OffscreenArrowESP:OnChanged(updateESPSettings)

ESPMainGroup:AddSlider('OffscreenArrowRadius', { Text = 'arrow radius', Default = 150, Min = 50, Max = 400, Rounding = 0, Compact = false })
Options.OffscreenArrowRadius:OnChanged(updateESPSettings)

ESPVisualsGroup:AddLabel('enemy box color'):AddColorPicker('EnemyBoxColor', { Default = Color3.fromRGB(255, 60, 60) })
ESPVisualsGroup:AddLabel('friendly box color'):AddColorPicker('FriendlyBoxColor', { Default = Color3.fromRGB(60, 255, 60) })
ESPVisualsGroup:AddLabel('enemy box fill color'):AddColorPicker('EnemyBoxFillColor', { Default = Color3.fromRGB(255, 60, 60), Transparency = 0.5 })
ESPVisualsGroup:AddLabel('friendly box fill color'):AddColorPicker('FriendlyBoxFillColor', { Default = Color3.fromRGB(60, 255, 60), Transparency = 0.5 })
ESPVisualsGroup:AddLabel('enemy name color'):AddColorPicker('EnemyNameColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('friendly name color'):AddColorPicker('FriendlyNameColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('enemy distance color'):AddColorPicker('EnemyDistanceColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('friendly distance color'):AddColorPicker('FriendlyDistanceColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('enemy health text color'):AddColorPicker('EnemyHealthTextColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('friendly health text color'):AddColorPicker('FriendlyHealthTextColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('enemy tracer color'):AddColorPicker('EnemyTracerColor', { Default = Color3.fromRGB(255, 60, 60) })
ESPVisualsGroup:AddLabel('friendly tracer color'):AddColorPicker('FriendlyTracerColor', { Default = Color3.fromRGB(60, 255, 60) })
ESPVisualsGroup:AddLabel('enemy chams fill color'):AddColorPicker('EnemyChamsFillColor', { Default = Color3.fromRGB(255, 60, 60), Transparency = 0.5 })
ESPVisualsGroup:AddLabel('friendly chams fill color'):AddColorPicker('FriendlyChamsFillColor', { Default = Color3.fromRGB(60, 255, 60), Transparency = 0.5 })
ESPVisualsGroup:AddLabel('enemy chams outline color'):AddColorPicker('EnemyChamsOutlineColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('friendly chams outline color'):AddColorPicker('FriendlyChamsOutlineColor', { Default = Color3.fromRGB(255, 255, 255) })
ESPVisualsGroup:AddLabel('enemy offscreen arrow color'):AddColorPicker('EnemyArrowColor', { Default = Color3.fromRGB(255, 60, 60) })
ESPVisualsGroup:AddLabel('friendly offscreen arrow color'):AddColorPicker('FriendlyArrowColor', { Default = Color3.fromRGB(60, 255, 60) })

Options.EnemyBoxColor:OnChanged(updateESPColors)
Options.FriendlyBoxColor:OnChanged(updateESPColors)
Options.EnemyBoxFillColor:OnChanged(updateESPColors)
Options.FriendlyBoxFillColor:OnChanged(updateESPColors)
Options.EnemyNameColor:OnChanged(updateESPColors)
Options.FriendlyNameColor:OnChanged(updateESPColors)
Options.EnemyDistanceColor:OnChanged(updateESPColors)
Options.FriendlyDistanceColor:OnChanged(updateESPColors)
Options.EnemyHealthTextColor:OnChanged(updateESPColors)
Options.FriendlyHealthTextColor:OnChanged(updateESPColors)
Options.EnemyTracerColor:OnChanged(updateESPColors)
Options.FriendlyTracerColor:OnChanged(updateESPColors)
Options.EnemyChamsFillColor:OnChanged(updateESPColors)
Options.FriendlyChamsFillColor:OnChanged(updateESPColors)
Options.EnemyChamsOutlineColor:OnChanged(updateESPColors)
Options.FriendlyChamsOutlineColor:OnChanged(updateESPColors)
Options.EnemyArrowColor:OnChanged(updateESPColors)
Options.FriendlyArrowColor:OnChanged(updateESPColors)

local ESPRenderGroup = Tabs.ESP:AddRightGroupbox('lighting & camera')

ESPRenderGroup:AddToggle('FullbrightToggle', { Text = 'fullbright', Default = false })
Toggles.FullbrightToggle:OnChanged(function()
    renderSettings.fullbright = Toggles.FullbrightToggle.Value
    if not renderSettings.fullbright then

        local lighting = game:GetService("Lighting")
        lighting.Ambient = renderSettings.originalLighting.Ambient
        lighting.ColorShift_Top = renderSettings.originalLighting.ColorShift_Top
        lighting.ColorShift_Bottom = renderSettings.originalLighting.ColorShift_Bottom
        lighting.Brightness = renderSettings.originalLighting.Brightness
        lighting.ClockTime = renderSettings.originalLighting.ClockTime
        lighting.OutdoorAmbient = renderSettings.originalLighting.OutdoorAmbient
    end
end)

ESPRenderGroup:AddToggle('FOVChangerToggle', { Text = 'enable fov changer', Default = false })
Toggles.FOVChangerToggle:OnChanged(function()
    renderSettings.fovEnabled = Toggles.FOVChangerToggle.Value
    if not renderSettings.fovEnabled then
        camera.FieldOfView = 70
    end
end)

ESPRenderGroup:AddSlider('CameraFOVValue', { Text = 'field of view', Default = 70, Min = 30, Max = 120, Rounding = 0, Compact = false })
Options.CameraFOVValue:OnChanged(function() renderSettings.fov = Options.CameraFOVValue.Value end)

ESPVisualsGroup:AddDivider()

ESPVisualsGroup:AddSlider('ESPTextSize', { Text = 'global text size', Default = 13, Min = 8, Max = 24, Rounding = 0, Compact = false })
Options.ESPTextSize:OnChanged(updateSharedSettings)

ESPVisualsGroup:AddToggle('ESPLimitDistance', { Text = 'limit esp distance', Default = false })
Toggles.ESPLimitDistance:OnChanged(updateSharedSettings)

ESPVisualsGroup:AddSlider('ESPMaxDistance', { Text = 'max esp distance', Default = 150, Min = 10, Max = 1000, Rounding = 0, Compact = false })
Options.ESPMaxDistance:OnChanged(updateSharedSettings)

ESPVisualsGroup:AddToggle('ESPUseTeamColor', { Text = 'override with roblox team colors', Default = false })
Toggles.ESPUseTeamColor:OnChanged(updateSharedSettings)

local MovementGroup = Tabs.Character:AddLeftGroupbox('movement settings')
local PhysicsTPGroup = Tabs.Character:AddRightGroupbox('physics & teleports')

MovementGroup:AddToggle('WalkSpeedEnabled', { Text = 'enable walkspeed modifier', Default = false })
Toggles.WalkSpeedEnabled:OnChanged(function()
    characterSettings.walkSpeedEnabled = Toggles.WalkSpeedEnabled.Value
    if not characterSettings.walkSpeedEnabled then
        local char = localPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = defaultWalkSpeed
        end
    end
end)

MovementGroup:AddSlider('WalkSpeedValue', { Text = 'walkspeed', Default = 16, Min = 16, Max = 250, Rounding = 0, Compact = false })
Options.WalkSpeedValue:OnChanged(function() characterSettings.walkSpeed = Options.WalkSpeedValue.Value end)

MovementGroup:AddDivider()

MovementGroup:AddToggle('JumpPowerEnabled', { Text = 'enable jumppower modifier', Default = false })
Toggles.JumpPowerEnabled:OnChanged(function()
    characterSettings.jumpPowerEnabled = Toggles.JumpPowerEnabled.Value
    if not characterSettings.jumpPowerEnabled then
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
end)

MovementGroup:AddSlider('JumpPowerValue', { Text = 'jumppower/height', Default = 50, Min = 50, Max = 500, Rounding = 0, Compact = false })
Options.JumpPowerValue:OnChanged(function() characterSettings.jumpPower = Options.JumpPowerValue.Value end)

MovementGroup:AddDivider()

MovementGroup:AddToggle('InfiniteJumpEnabled', { Text = 'infinite jump', Default = false })
Toggles.InfiniteJumpEnabled:OnChanged(function() characterSettings.infiniteJump = Toggles.InfiniteJumpEnabled.Value end)

MovementGroup:AddToggle('NoclipEnabled', { Text = 'noclip', Default = false })
Toggles.NoclipEnabled:OnChanged(function() characterSettings.noclip = Toggles.NoclipEnabled.Value end)

MovementGroup:AddToggle('FlyEnabled', { Text = 'fly', Default = false })
Toggles.FlyEnabled:OnChanged(function()
    characterSettings.flyEnabled = Toggles.FlyEnabled.Value
    if not characterSettings.flyEnabled then
        stopFlying()
    end
end)

MovementGroup:AddSlider('FlySpeedValue', { Text = 'fly speed', Default = 50, Min = 10, Max = 300, Rounding = 0, Compact = false })
Options.FlySpeedValue:OnChanged(function() characterSettings.flySpeed = Options.FlySpeedValue.Value end)

PhysicsTPGroup:AddToggle('GravityEnabled', { Text = 'override gravity', Default = false })
Toggles.GravityEnabled:OnChanged(function()
    characterSettings.gravityEnabled = Toggles.GravityEnabled.Value
    updateGravity()
end)

PhysicsTPGroup:AddSlider('GravityValue', { Text = 'gravity', Default = 196.2, Min = 0, Max = 500, Rounding = 1, Compact = false })
Options.GravityValue:OnChanged(function()
    characterSettings.gravityValue = Options.GravityValue.Value
    updateGravity()
end)

PhysicsTPGroup:AddDivider()

PhysicsTPGroup:AddToggle('ClickTPEnabled', { Text = 'click tp', Default = false })
Toggles.ClickTPEnabled:OnChanged(function() characterSettings.clickTPEnabled = Toggles.ClickTPEnabled.Value end)

PhysicsTPGroup:AddDropdown('ClickTPKey', { Values = { 'LeftControl', 'LeftAlt', 'LeftShift', 'None' }, Default = 1, Multi = false, Text = 'click tp modifier key' })
Options.ClickTPKey:OnChanged(function() characterSettings.clickTPKey = Options.ClickTPKey.Value end)

PhysicsTPGroup:AddDivider()

local playerDropdown = PhysicsTPGroup:AddDropdown('PlayerTPDropdown', { Values = {}, Default = nil, AllowNull = true, Multi = false, Text = 'select player' })

PhysicsTPGroup:AddButton('teleport to player', function()
    local targetName = Options.PlayerTPDropdown.Value
    if targetName then
        local targetPlayer = players:FindFirstChild(targetName)
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
    else
        notify("please select a player from the dropdown.")
    end
end)

PhysicsTPGroup:AddButton('refresh player list', updatePlayerDropdowns)

addConnection(players.PlayerAdded:Connect(updatePlayerDropdowns), "PlayerAddedDropdownUpdate")
addConnection(players.PlayerRemoving:Connect(updatePlayerDropdowns), "PlayerRemovingDropdownUpdate")

task.spawn(function()
    task.wait(1)
    updatePlayerDropdowns()
end)

local WaypointGroup = Tabs.Character:AddRightGroupbox('waypoint manager')

WaypointGroup:AddInput('WaypointNameInput', {
    Default = '',
    Numeric = false,
    Finished = true,
    Text = 'waypoint name',
    Tooltip = 'enter waypoint name to save',
    Placeholder = 'base / spawn / secret'
})

WaypointGroup:AddButton('save waypoint', function()
    local name = Options.WaypointNameInput.Value
    if name and name ~= "" then
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            waypoints[name] = hrp.CFrame
            saveWaypointsToFile()
            updateWaypointsDropdown()
            notify("saved waypoint: " .. name)
        else
            notify("error: character root part not found.")
        end
    else
        notify("please enter a valid waypoint name.")
    end
end)

local waypointDropdown = WaypointGroup:AddDropdown('WaypointDropdown', {
    Values = {},
    Default = nil,
    AllowNull = true,
    Multi = false,
    Text = 'select waypoint'
})

WaypointGroup:AddButton('teleport to waypoint', function()
    local name = Options.WaypointDropdown.Value
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
        notify("please select a waypoint.")
    end
end)

WaypointGroup:AddButton('delete waypoint', function()
    local name = Options.WaypointDropdown.Value
    if name then
        waypoints[name] = nil
        saveWaypointsToFile()
        updateWaypointsDropdown()
        notify("deleted waypoint: " .. name)
    else
        notify("please select a waypoint to delete.")
    end
end)

task.spawn(function()
    loadWaypointsFromFile()
    updateWaypointsDropdown()
end)

local PlayersLeftGroup = Tabs.Players:AddLeftGroupbox('player selector & info')
local PlayersRightGroup = Tabs.Players:AddRightGroupbox('player interactions')

local selectedPlayerDropdown = PlayersLeftGroup:AddDropdown('SelectedPlayerDropdown', {
    Values = {},
    Default = nil,
    AllowNull = true,
    Multi = false,
    Text = 'select player'
})

Options.SelectedPlayerDropdown:OnChanged(function()
    local targetName = Options.SelectedPlayerDropdown.Value
    if targetName then
        playerListSettings.selectedPlayer = players:FindFirstChild(targetName)
    else
        playerListSettings.selectedPlayer = nil
    end
    updatePlayerStatsUI()
    if Toggles.HighlightPlayerToggle and Toggles.HighlightPlayerToggle.Value then
        if playerListSettings.selectedPlayer then
            applyHighlight(playerListSettings.selectedPlayer)
        else
            clearHighlight()
        end
    end
    updateSpectate()
end)

PlayersLeftGroup:AddButton('refresh list', updatePlayerDropdowns)

playerUsernameLabel = PlayersLeftGroup:AddLabel('username: n/a')
playerDisplayNameLabel = PlayersLeftGroup:AddLabel('display name: n/a')
playerTeamLabel = PlayersLeftGroup:AddLabel('team: n/a')
playerHealthLabel = PlayersLeftGroup:AddLabel('health: n/a')
playerDistanceLabel = PlayersLeftGroup:AddLabel('distance: n/a')
playerAgeLabel = PlayersLeftGroup:AddLabel('account age: n/a')

PlayersLeftGroup:AddDivider()

PlayersLeftGroup:AddToggle('HighlightPlayerToggle', { Text = 'highlight player (esp)', Default = false })
Toggles.HighlightPlayerToggle:OnChanged(function()
    if Toggles.HighlightPlayerToggle.Value then
        if playerListSettings.selectedPlayer then
            applyHighlight(playerListSettings.selectedPlayer)
        else
            notify("please select a player to highlight.")
            Toggles.HighlightPlayerToggle:SetValue(false)
        end
    else
        clearHighlight()
    end
end)

PlayersLeftGroup:AddToggle('SpectatePlayerToggle', { Text = 'spectate player', Default = false })
Toggles.SpectatePlayerToggle:OnChanged(function()
    if Toggles.SpectatePlayerToggle.Value then
        if playerListSettings.selectedPlayer then
            playerListSettings.spectating = true
            updateSpectate()
        else
            notify("please select a player to spectate.")
            Toggles.SpectatePlayerToggle:SetValue(false)
        end
    else
        playerListSettings.spectating = false
        updateSpectate()
    end
end)

PlayersRightGroup:AddButton('teleport to player', function()
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
end)

PlayersRightGroup:AddButton('teleport behind player', function()
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
end)

PlayersRightGroup:AddToggle('AttachToPlayerToggle', { Text = 'attach / bring player', Default = false })
Toggles.AttachToPlayerToggle:OnChanged(function()
    if Toggles.AttachToPlayerToggle.Value then
        if playerListSettings.selectedPlayer then
            playerListSettings.attaching = true
            playerListSettings.following = false
            if Toggles.FollowPlayerToggle then
                Toggles.FollowPlayerToggle:SetValue(false)
            end
        else
            notify("please select a player to attach to.")
            Toggles.AttachToPlayerToggle:SetValue(false)
        end
    else
        playerListSettings.attaching = false
    end
end)

PlayersRightGroup:AddToggle('FollowPlayerToggle', { Text = 'follow player', Default = false })
Toggles.FollowPlayerToggle:OnChanged(function()
    if Toggles.FollowPlayerToggle.Value then
        if playerListSettings.selectedPlayer then
            playerListSettings.following = true
            playerListSettings.attaching = false
            if Toggles.AttachToPlayerToggle then
                Toggles.AttachToPlayerToggle:SetValue(false)
            end
        else
            notify("please select a player to follow.")
            Toggles.FollowPlayerToggle:SetValue(false)
        end
    else
        playerListSettings.following = false
    end
end)

PlayersRightGroup:AddDivider()

PlayersRightGroup:AddInput('SpamTargetInput', {
    Default = 'Hey {name}, Noctura runs you!',
    Numeric = false,
    Finished = true,
    Text = 'custom spam message',
    Tooltip = 'use {name} to insert the player\'s display name'
})

PlayersRightGroup:AddButton('send chat message', function()
    local target = playerListSettings.selectedPlayer
    if target then
        local msg = Options.SpamTargetInput.Value
        msg = string.gsub(msg, "{name}", target.DisplayName)
        sendChatMessage(msg)
    else
        notify("please select a player first.")
    end
end)

uiInitialized = true

if Sense then
    pcall(function()
        updateESPSettings()
        updateESPColors()
        updateSharedSettings()
        Sense.Load()
    end)
end

local MenuSettingsGroup = Tabs['UI Settings']:AddLeftGroupbox('menu options')

local function unloadScript()
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
    pcall(function() Library:Unload() end)
    notify("noctura fully unloaded.")
end
getgenv().NocturaUnload = unloadScript

MenuSettingsGroup:AddButton('unload script', unloadScript)
MenuSettingsGroup:AddLabel('menu bind'):AddKeyPicker('MenuKeybind', { Default = 'F10', NoUI = true, Text = 'menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind
Library:SetWatermarkVisibility(true)
Library:SetWatermark('noctura | ' .. localPlayer.Name)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('Noctura')
SaveManager:SetFolder('Noctura/configs')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

notify("noctura initialized!")
notify("press f10 to show/hide the menu.")
