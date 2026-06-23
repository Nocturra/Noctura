local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()

local win = lib:Window("Noctura", Color3.fromRGB(44, 120, 224), Enum.KeyCode.RightControl)
local main = win:Tab("Main")
local upgrades = win:Tab("Upgrades")
local teleport = win:Tab("Teleport")
local visualTab = win:Tab("Settings")

getgenv().AddingSpins = false
getgenv().AutoSleepy = false
getgenv().AutoOg = false
getgenv().AutoCollect = false
getgenv().AutoUpgradeBrainrot = false
getgenv().AutoSpeed = false
getgenv().SpeedAmount = 1
getgenv().AutoCarry = false
getgenv().AutoScream = false
getgenv().ScreamAmount = 1
getgenv().TpContainer = "BrainrotSpawns"
getgenv().TpType = "Basic"

main:Toggle("Add Inf Spins", false, function(v)
    getgenv().AddingSpins = v
    if v then
        task.spawn(function()
            while getgenv().AddingSpins do
                game:GetService("ReplicatedStorage").Remotes.AddSpin:FireServer()
                task.wait()
            end
        end)
    end
end)

main:Toggle("Auto Spin Sleepy Mutation", false, function(v)
    getgenv().AutoSleepy = v
    if v then
        task.spawn(function()
            while getgenv().AutoSleepy do
                game:GetService("ReplicatedStorage").Remotes.SpinEventWheel:FireServer(5)
                task.wait(0.5)
            end
        end)
    end
end)

main:Toggle("Auto Spin OG", false, function(v)
    getgenv().AutoOg = v
    if v then
        task.spawn(function()
            while getgenv().AutoOg do
                game:GetService("ReplicatedStorage").Remotes.SpinEventWheel:FireServer(4)
                task.wait(0.5)
            end
        end)
    end
end)

main:Toggle("Auto Collect All", false, function(v)
    getgenv().AutoCollect = v
    if v then
        task.spawn(function()
            while getgenv().AutoCollect do
                local Event = game:GetService("ReplicatedStorage").Packages.Net["RE/UpdateCollect"]
                for i = 1, 100 do
                    task.spawn(function()
                        firesignal(Event.OnClientEvent, i) 
                    end)
                end
                task.wait(0.5)
            end
        end)
    end
end)

upgrades:Toggle("Auto Upgrade Brainrot", false, function(v)
    getgenv().AutoUpgradeBrainrot = v
    if v then
        task.spawn(function()
            while getgenv().AutoUpgradeBrainrot do
                local Event = game:GetService("ReplicatedStorage").Packages.Net["RE/UpgradeBrainrot"]
                for i = 1, 100 do
                    task.spawn(function() 
                        Event:FireServer(i) 
                    end)
                end
                task.wait(0.5)
            end
        end)
    end
end)

upgrades:Toggle("Auto Upgrade Speed", false, function(v)
    getgenv().AutoSpeed = v
    if v then
        task.spawn(function()
            while getgenv().AutoSpeed do
                game:GetService("ReplicatedStorage").Packages.Net["RE/RequestStatsUpgrade"]:FireServer("Speed", getgenv().SpeedAmount)
                task.wait(0.1)
            end
        end)
    end
end)

upgrades:Dropdown("Speed Amount", {"1", "5", "10"}, function(t) getgenv().SpeedAmount = tonumber(t) end)

upgrades:Toggle("Auto Carry Upgrade", false, function(v)
    getgenv().AutoCarry = v
    if v then
        task.spawn(function()
            while getgenv().AutoCarry do
                game:GetService("ReplicatedStorage").Packages.Net["RE/RequestStatsUpgrade"]:FireServer("CarryMax", 1)
                task.wait(0.1)
            end
        end)
    end
end)

upgrades:Toggle("Auto Upgrade Scream", false, function(v)
    getgenv().AutoScream = v
    if v then
        task.spawn(function()
            while getgenv().AutoScream do
                game:GetService("ReplicatedStorage").Packages.Net["RE/RequestStatsUpgrade"]:FireServer("Scream", getgenv().ScreamAmount)
                task.wait(0.1)
            end
        end)
    end
end)

upgrades:Dropdown("Scream Amount", {"1", "5", "10", "100"}, function(t) getgenv().ScreamAmount = tonumber(t) end)

teleport:Dropdown("Select Spawner", {"BrainrotSpawns", "BrainrotSpawns2", "BrainrotSpawns3"}, function(t) getgenv().TpContainer = t end)
teleport:Dropdown("Select Mode", {"Basic", "Best"}, function(t) getgenv().TpType = t end)

local zones = {"Admin", "Celestial", "Common", "Epic", "Legendary", "Mythic", "OG", "Rare", "Secret", "Uncommon"}
for _, zone in pairs(zones) do
    teleport:Button("Teleport to " .. zone, function()
        local path = workspace:FindFirstChild(getgenv().TpContainer)
        if path then
            local location = path.Locations:FindFirstChild(zone)
            if location then
                local target = location:FindFirstChild(zone .. "Floor" .. getgenv().TpType)
                if target then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame
                else
                    lib:Notification("Noctura", "Zone not found: " .. zone .. "Floor" .. getgenv().TpType, "Close")
                end
            end
        end
    end)
end

visualTab:Colorpicker("Change UI Color", Color3.fromRGB(44, 120, 224), function(t) lib:ChangePresetColor(t) end)
visualTab:Button("Destroy GUI", function()
    local coreGui = game:GetService("CoreGui")
    if coreGui:FindFirstChild("ui") then
        coreGui.ui:Destroy()
    end
end)
