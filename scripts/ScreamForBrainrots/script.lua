--[[
    _   __           __                  
   / | / /___  _____/ /___  ___________ _
  /  |/ / __ \/ ___/ __/ / / / ___/ __ `/
 / /|  / /_/ / /__/ /_/ /_/ / /  / /_/ / 
/_/ |_/\____/\___/\__/\__,_/_/   \__,_(_)


-- Noctura. Enhance a game. Your way <3

]]

getgenv().RAYFIELD_ASSET_ID = 120960636838063 

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

local main = Window:CreateTab("Main")
local upgrades = Window:CreateTab("Upgrades")
local teleport = Window:CreateTab("Teleport")
local visualTab = Window:CreateTab("Settings")

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

main:CreateToggle({
   Name = "Add Inf Spins",
   CurrentValue = false,
   Flag = "AddingSpins",
   Callback = function(Value)
      getgenv().AddingSpins = Value
      if Value then
         task.spawn(function()
            while getgenv().AddingSpins do
               game:GetService("ReplicatedStorage").Remotes.AddSpin:FireServer()
               task.wait()
            end
         end)
      end
   end,
})
main:CreateToggle({
   Name = "Auto Spin Sleepy Mutation",
   CurrentValue = false,
   Flag = "AutoSleepy",
   Callback = function(Value)
      getgenv().AutoSleepy = Value
      if Value then
         task.spawn(function()
            while getgenv().AutoSleepy do
               game:GetService("ReplicatedStorage").Remotes.SpinEventWheel:FireServer(5)
               task.wait(0.5)
            end
         end)
      end
   end,
})
main:CreateToggle({
   Name = "Auto Spin OG",
   CurrentValue = false,
   Flag = "AutoOg",
   Callback = function(Value)
      getgenv().AutoOg = Value
      if Value then
         task.spawn(function()
            while getgenv().AutoOg do
               game:GetService("ReplicatedStorage").Remotes.SpinEventWheel:FireServer(4)
               task.wait(0.5)
            end
         end)
      end
   end,
})
main:CreateToggle({
   Name = "Auto Collect All",
   CurrentValue = false,
   Flag = "AutoCollect",
   Callback = function(Value)
      getgenv().AutoCollect = Value
      if Value then
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
   end,
})

upgrades:CreateToggle({
   Name = "Auto Upgrade Brainrot",
   CurrentValue = false,
   Flag = "AutoUpgradeBrainrot",
   Callback = function(Value)
      getgenv().AutoUpgradeBrainrot = Value
      if Value then
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
   end,
})
upgrades:CreateToggle({
   Name = "Auto Upgrade Speed",
   CurrentValue = false,
   Flag = "AutoSpeed",
   Callback = function(Value)
      getgenv().AutoSpeed = Value
      if Value then
         task.spawn(function()
            while getgenv().AutoSpeed do
               game:GetService("ReplicatedStorage").Packages.Net["RE/RequestStatsUpgrade"]:FireServer("Speed", getgenv().SpeedAmount)
               task.wait(0.1)
            end
         end)
      end
   end,
})
upgrades:CreateDropdown({
   Name = "Speed Amount",
   Options = {"1", "5", "10"},
   CurrentOption = {"1"},
   MultipleOptions = false,
   Flag = "SpeedAmount",
   Callback = function(Options)
      getgenv().SpeedAmount = tonumber(Options[1])
   end,
})
upgrades:CreateToggle({
   Name = "Auto Carry Upgrade",
   CurrentValue = false,
   Flag = "AutoCarry",
   Callback = function(Value)
      getgenv().AutoCarry = Value
      if Value then
         task.spawn(function()
            while getgenv().AutoCarry do
               game:GetService("ReplicatedStorage").Packages.Net["RE/RequestStatsUpgrade"]:FireServer("CarryMax", 1)
               task.wait(0.1)
            end
         end)
      end
   end,
})
upgrades:CreateToggle({
   Name = "Auto Upgrade Scream",
   CurrentValue = false,
   Flag = "AutoScream",
   Callback = function(Value)
      getgenv().AutoScream = Value
      if Value then
         task.spawn(function()
            while getgenv().AutoScream do
               game:GetService("ReplicatedStorage").Packages.Net["RE/RequestStatsUpgrade"]:FireServer("Scream", getgenv().ScreamAmount)
               task.wait(0.1)
            end
         end)
      end
   end,
})
upgrades:CreateDropdown({
   Name = "Scream Amount",
   Options = {"1", "5", "10", "100"},
   CurrentOption = {"1"},
   MultipleOptions = false,
   Flag = "ScreamAmount",
   Callback = function(Options)
      getgenv().ScreamAmount = tonumber(Options[1])
   end,
})

teleport:CreateDropdown({
   Name = "Select Spawner",
   Options = {"BrainrotSpawns", "BrainrotSpawns2", "BrainrotSpawns3"},
   CurrentOption = {"BrainrotSpawns"},
   MultipleOptions = false,
   Flag = "TpContainer",
   Callback = function(Options)
      getgenv().TpContainer = Options[1]
   end,
})
teleport:CreateDropdown({
   Name = "Select Mode",
   Options = {"Basic", "Best"},
   CurrentOption = {"Basic"},
   MultipleOptions = false,
   Flag = "TpType",
   Callback = function(Options)
      getgenv().TpType = Options[1]
   end,
})

local zones = {"Admin", "Celestial", "Common", "Epic", "Legendary", "Mythic", "OG", "Rare", "Secret", "Uncommon"}
for _, zone in pairs(zones) do
   teleport:CreateButton({
      Name = "Teleport to " .. zone,
      Callback = function()
         local path = workspace:FindFirstChild(getgenv().TpContainer)
         if path then
            local location = path.Locations:FindFirstChild(zone)
            if location then
               local target = location:FindFirstChild(zone .. "Floor" .. getgenv().TpType)
               if target then
                  game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame
               else
                  Rayfield:Notify({Title = "Noctura", Content = "Zone not found: " .. zone .. "Floor" .. getgenv().TpType, Duration = 3})
               end
            end
         end
      end,
   })
end

visualTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
      Rayfield:Destroy()
   end,
})
