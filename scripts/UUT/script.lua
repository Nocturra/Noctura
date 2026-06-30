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

local Tab = Window:CreateTab("Main", "zap")
local PrestigeTab = Window:CreateTab("Prestige", "refresh-cw")
local CreditsTab = Window:CreateTab("Credits", "paperclip")
local SettingsTab = Window:CreateTab("Settings", "settings")

getgenv().AutoClick = false
getgenv().AutoUpgrade = false
getgenv().AutoRoll = false
getgenv().AutoEvil = false
getgenv().AutoPrestige = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local VirtualUser = game:GetService("VirtualUser")

local function Click()
    if Remotes:FindFirstChild("Clicker") then
        Remotes.Clicker:FireServer()
    end
end

local function BuyUpgrade(id)
    if Remotes:FindFirstChild("BuyUpg") then
        Remotes.BuyUpg:FireServer(id)
    end
end

Tab:CreateButton({
    Name = "Buy All Upgrades (1-1000)",
    Callback = function()
        for i = 1, 1000 do
            BuyUpgrade(i)
            task.wait()
        end
    end,
})

Tab:CreateToggle({
    Name = "Auto Clicker",
    Callback = function(Value)
        getgenv().AutoClick = Value
        task.spawn(function()
            while getgenv().AutoClick do
                Click()
                task.wait(0.05)
            end
        end)
    end,
})

Tab:CreateToggle({
    Name = "Auto Buy Upgrades",
    Callback = function(Value)
        getgenv().AutoUpgrade = Value
        task.spawn(function()
            while getgenv().AutoUpgrade do
                for i = 1, 500 do 
                    if not getgenv().AutoUpgrade then break end
                    BuyUpgrade(i)
                    task.wait(0.01)
                end
                task.wait(0.5)
            end
        end)
    end,
})

Tab:CreateButton({
    Name = "Unlock All Worlds & Rejoin",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").Remotes.ChangeWorld
        Event:FireServer("Space")
        
        task.wait(2)
        local TeleportService = game:GetService("TeleportService")
        local Player = game:GetService("Players").LocalPlayer
        TeleportService:Teleport(game.PlaceId, Player)
    end,
})

Tab:CreateToggle({
    Name = "Auto Roll",
    Callback = function(Value)
        getgenv().AutoRoll = Value
        task.spawn(function()
            while getgenv().AutoRoll do
                if Remotes:FindFirstChild("Roll") then
                    Remotes.Roll:InvokeServer()
                end
                task.wait(0.5)
            end
        end)
    end,
})

Tab:CreateToggle({
    Name = "Auto Evil",
    Callback = function(Value)
        getgenv().AutoEvil = Value
        task.spawn(function()
            while getgenv().AutoEvil do
                if Remotes:FindFirstChild("Evil") then
                    Remotes.Evil:FireServer()
                end
                task.wait(1)
            end
        end)
    end,
})

PrestigeTab:CreateToggle({
    Name = "Auto Prestige",
    Callback = function(Value)
        getgenv().AutoPrestige = Value
        task.spawn(function()
            while getgenv().AutoPrestige do
                if Remotes:FindFirstChild("Prestige") then
                    Remotes.Prestige:FireServer()
                end
                task.wait(3)
            end
        end)
    end,
})

SettingsTab:CreateToggle({
    Name = "Anti AFK",
    Callback = function(Value)
        if Value then
            game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end,
})

SettingsTab:CreateToggle({
    Name = "Disable 3D Rendering",
    Callback = function(Value)
        game:GetService("RunService"):Set3dRenderingEnabled(not Value)
    end,
})

CreditsTab:CreateParagraph({
    Title = "Credits <3",
    Content = [[

@mechanicalize:
Developing Noctura.

@mechanicalize:
Developing the Website

@mechanicalize:
Making the Github

@mechanicalize:
Making the Discord
]]
})

Rayfield:Notify({
   Title = "Noctura has been loaded.",
   Content = "Fun Fact: Noctura is made by a bored teenager.",
   Duration = 6.5,
   Image = "moon",
})
