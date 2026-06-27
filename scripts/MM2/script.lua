local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GhostDuckyy/UI-Libraries/refs/heads/main/Venus/source.lua", true))()
local notif = loadstring(game:HttpGet("https://raw.githubusercontent.com/insanedude59/notiflib/main/main"))()

local main = library:Load({Name = "Noctura | MM2 V6.6", Theme = "Dark", SizeX = 540, SizeY = 660})

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
    if success then notif:Notification("Saved", "Configuration saved successfully.", "GothamSemibold", "Gotham", 3)
    else warn("Failed to save config: " .. tostring(err)) end
end

local function loadConfig()
    if isfile and isfile(configName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(configName)) end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do toggles[k] = v end
            Camera.FieldOfView = toggles.FOV
            fovCircle.Radius = toggles.AimbotRadius
            notif:Notification("Loaded", "Configuration loaded successfully.", "GothamSemibold", "Gotham", 3)
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
                    notif:Notification("Warning", player.Name .. " is approaching!", "GothamSemibold", "Gotham", 4)
                    notifiedMurderers[player.Name] = true
                elseif dist > 35 then
                    notifiedMurderers[player.Name] = false
                end
                
                if toggles.AutoEvade and dist < 12 then
                    myRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, 20)
                    notif:Notification("Evasion", "Automatically evaded the murderer.", "GothamSemibold", "Gotham", 2)
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

        if shouldShow and toggles.TextESP and player.Character:FindFirstChild("Head") then
            if not textEsp then
                textEsp = Instance.new("BillboardGui", player.Character)
                textEsp.Name = "NocturaTextESP"; textEsp.Size = UDim2.new(0, 100, 0, 40)
                textEsp.StudsOffset = Vector3.new(0, 2.5, 0); textEsp.AlwaysOnTop = true
                local label = Instance.new("TextLabel", textEsp)
                label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
                label.TextScaled = true; label.Font = Enum.Font.GothamBold
            end
            textEsp.TextLabel.Text = player.Name .. "\n[" .. roleText .. "]"
            textEsp.TextLabel.TextColor3 = color
        elseif textEsp then textEsp:Destroy() end

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
            notif:Notification("Success", "Retrieved the dropped weapon.", "GothamSemibold", "Gotham", 3)
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


local espTab = main:Tab("ESP")
local combatTab = main:Tab("Combat")
local moveTab = main:Tab("Movement")
local utilTab = main:Tab("Utility")
local playerTab = main:Tab("Players")
local serverTab = main:Tab("Server")
local settingsTab = main:Tab("Settings")


local espSection = espTab:Section({Name = "Visuals", column = 1})
espSection:Toggle({Name = "Murderer ESP", Flag = "MurdESP", callback = function(bool) toggles.MurdESP = bool end})
espSection:Toggle({Name = "Sheriff ESP", Flag = "SheriffESP", callback = function(bool) toggles.SheriffESP = bool end})
espSection:Toggle({Name = "Innocent ESP", Flag = "InnocentESP", callback = function(bool) toggles.InnocentESP = bool end})
espSection:Toggle({Name = "Text ESP", Flag = "TextESP", callback = function(bool) toggles.TextESP = bool end})
espSection:Toggle({Name = "Notify Murderer Proximity", Flag = "NotifMurd", callback = function(bool) toggles.NotifyKiller = bool end})
espSection:Toggle({Name = "Map X-Ray", Flag = "XRay", callback = function(bool) toggles.XRay = bool; handleXRay() end})

local combatSection = combatTab:Section({Name = "Combat Tools", column = 1})
combatSection:Toggle({Name = "Enable Aimbot (Hold Right-Click)", Flag = "AimbotToggle", callback = function(bool) toggles.Aimbot = bool; fovCircle.Visible = bool end})
combatSection:Slider({Name = "Aimbot Target Radius", Min = 50, Max = 400, Default = 150, Callback = function(val) toggles.AimbotRadius = val; fovCircle.Radius = val end})
combatSection:Toggle({Name = "Hitbox Expander", Flag = "HitboxExpander", callback = function(bool) toggles.HitboxExpander = bool end})
combatSection:Toggle({Name = "Auto-Grab Dropped Gun", Flag = "AutoGun", callback = function(bool) toggles.AutoGrabGun = bool end})
combatSection:Toggle({Name = "Auto-Evade Proximity", Flag = "AutoEvade", callback = function(bool) toggles.AutoEvade = bool end})
combatSection:Toggle({Name = "Auto-Accuse on Round Start", Flag = "AutoLeak", callback = function(bool) toggles.AutoLeak = bool end})

combatSection:Button({Name = "Eliminate All (Requires Knife)", Callback = function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if not knife then return notif:Notification("Error", "Knife tool is required.", "GothamSemibold", "Gotham", 3) end

    char.Humanoid:EquipTool(knife)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1.5)
            task.wait(0.2)
        end
    end
end})

local moveSection = moveTab:Section({Name = "Mobility", column = 1})
moveSection:Toggle({Name = "Infinite Jump", Flag = "InfJump", callback = function(bool) toggles.InfJump = bool end})
moveSection:Toggle({Name = "Noclip", Flag = "Noclip", callback = function(bool) toggles.Noclip = bool end})
moveSection:Slider({Name = "WalkSpeed Override", Min = 16, Max = 120, Default = 16, Callback = function(val) toggles.WalkSpeed = val end})
moveSection:Slider({Name = "Field of View (FOV)", Min = 70, Max = 120, Default = 70, Callback = function(val) toggles.FOV = val; Camera.FieldOfView = val end})

local locSection = moveTab:Section({Name = "Locations", column = 2})
locSection:Button({Name = "Teleport to Safe Zone", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 800, 0)
        LocalPlayer.Character.HumanoidRootPart.Anchored = true
        notif:Notification("Teleported", "Moved to safe location. Un-anchor to resume movement.", "GothamSemibold", "Gotham", 3)
    end
end})
locSection:Button({Name = "Disable Anchor", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
end})

local utilSection = utilTab:Section({Name = "Automation & Fun", column = 1})
utilSection:Toggle({Name = "Auto-Farm Coins", Flag = "AutoCoin", callback = function(bool) toggles.AutoCoin = bool end})
utilSection:Toggle({Name = "Anti-AFK", Flag = "AntiAFK", callback = function(bool) toggles.AntiAFK = bool end})
utilSection:Toggle({Name = "Enable Chat Spammer", Flag = "ChatSpam", callback = function(bool) toggles.ChatSpam = bool end})

local srvSection = serverTab:Section({Name = "Lobby Controls", column = 1})
srvSection:Button({Name = "Rejoin Current Server", Callback = function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end})
srvSection:Button({Name = "Server Hop", Callback = function()
    notif:Notification("Hopping", "Finding a new server...", "GothamSemibold", "Gotham", 3)
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end})

local configSection = settingsTab:Section({Name = "Configuration", column = 1})
configSection:Button({Name = "Save Configuration", Callback = saveConfig})
configSection:Button({Name = "Load Configuration", Callback = loadConfig})

local playerSections = {}
local function refreshPlayerList()
    for _, section in pairs(playerSections) do if section and section.Destroy then section:Destroy() end end
    playerSections = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local ps = playerTab:Section({Name = player.Name, column = 1})
        table.insert(playerSections, ps)
        
        ps:Button({Name = "Teleport To", Callback = function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then 
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
                LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame 
            end
        end})
        
        ps:Button({Name = "Spectate", Callback = function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = player.Character.Humanoid
                notif:Notification("Spectating", "Watching " .. player.Name, "GothamSemibold", "Gotham", 2)
            end
        end})
    end
    
    local meSection = playerTab:Section({Name = "Local Controls", column = 2})
    table.insert(playerSections, meSection)
    meSection:Button({Name = "Stop Spectating", Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end})
end
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
refreshPlayerList()

notif:Notification("Noctura V6.6", "Script execution complete. Enjoy the sticky aim!", "GothamSemibold", "Gotham", 5)
