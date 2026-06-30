getgenv().RAYFIELD_ASSET_ID = 120960636838063
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Noctura - Money Incremental",
   LoadingTitle = "Noctura",
   LoadingSubtitle = "Become rich. Why not.",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "Noctura",
      FileName = "MoneyIncrementalConfig"
   },
   Theme = "AmberGlow"
})

getgenv().AutoClickMoney = false
getgenv().AutoClickGem = false
getgenv().AutoDailyReward = false
getgenv().AutoCollectMainAchievement = false
getgenv().AutoGemUpgrade = false
getgenv().AutoOpenCrate = false
getgenv().AutoPrestige = false
getgenv().AutoUpgrade = false
getgenv().AutoAll = false

local MainTab = Window:CreateTab("Auto Functions")
local SingleFunctionsTab = Window:CreateTab("Single Functions")
local ConfigsTab = Window:CreateTab("Configs")
local SettingsTab = Window:CreateTab("Settings")

MainTab:CreateSection("Autofarm Toggles")
MainTab:CreateToggle({
   Name = "Auto All",
   CurrentValue = false,
   Flag = "AutoAll",
   Callback = function(Value)
      getgenv().AutoAll = Value
      getgenv().AutoClickMoney = Value
      getgenv().AutoClickGem = Value
      getgenv().AutoDailyReward = Value
      getgenv().AutoCollectMainAchievement = Value
      getgenv().AutoGemUpgrade = Value
      getgenv().AutoOpenCrate = Value
      getgenv().AutoPrestige = Value
      getgenv().AutoUpgrade = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Click Money",
   CurrentValue = false,
   Flag = "AutoClickMoney",
   Callback = function(Value)
      getgenv().AutoClickMoney = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Click Gem",
   CurrentValue = false,
   Flag = "AutoClickGem",
   Callback = function(Value)
      getgenv().AutoClickGem = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Daily Reward",
   CurrentValue = false,
   Flag = "AutoDailyReward",
   Callback = function(Value)
      getgenv().AutoDailyReward = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Collect Main Achievement",
   CurrentValue = false,
   Flag = "AutoCollectMainAchievement",
   Callback = function(Value)
      getgenv().AutoCollectMainAchievement = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Gem Upgrade",
   CurrentValue = false,
   Flag = "AutoGemUpgrade",
   Callback = function(Value)
      getgenv().AutoGemUpgrade = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Open Crate",
   CurrentValue = false,
   Flag = "AutoOpenCrate",
   Callback = function(Value)
      getgenv().AutoOpenCrate = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Prestige",
   CurrentValue = false,
   Flag = "AutoPrestige",
   Callback = function(Value)
      getgenv().AutoPrestige = Value
   end,
})
MainTab:CreateToggle({
   Name = "Auto Upgrade",
   CurrentValue = false,
   Flag = "AutoUpgrade",
   Callback = function(Value)
      getgenv().AutoUpgrade = Value
   end,
})

SingleFunctionsTab:CreateSection("Single Functions")
SingleFunctionsTab:CreateButton({
   Name = "Execute All Once",
   Callback = function()
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.ClickMoney
         Event:FireServer()
      end)
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.ClickMoney.ClickGem
         Event:FireServer()
      end)
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.ClaimDailyReward
         Event:FireServer()
      end)
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.CollectMainAchievement
         Event:FireServer()
      end)
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.GemUpgrade
         Event:FireServer()
      end)
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.OpenCrate
         Event:FireServer()
      end)
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.Prestige
         Event:FireServer()
      end)
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.Upgrade
         Event:FireServer()
      end)
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Click Money",
   Callback = function()
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.ClickMoney
         Event:FireServer()
      end)
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Click Gem",
   Callback = function()
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.ClickMoney.ClickGem
         Event:FireServer()
      end)
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Daily Reward",
   Callback = function()
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.ClaimDailyReward
         Event:FireServer()
      end)
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Collect Main Achievement",
   Callback = function()
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.CollectMainAchievement
         Event:FireServer()
      end)
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Gem Upgrade",
   Callback = function()
      for i = 1, 100 do
         task.spawn(function()
            pcall(function()
               local Event = game:GetService("ReplicatedStorage").Events.GemUpgrade
               Event:FireServer(i)
            end)
         end)
      end
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Open Crate",
   Callback = function()
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.OpenCrate
         Event:FireServer()
      end)
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Prestige",
   Callback = function()
      pcall(function()
         local Event = game:GetService("ReplicatedStorage").Events.Prestige
         Event:FireServer()
      end)
   end,
})
SingleFunctionsTab:CreateButton({
   Name = "Upgrade",
   Callback = function()
      for i = 1, 100 do
         task.spawn(function()
            pcall(function()
               local Event = game:GetService("ReplicatedStorage").Events.Upgrade
               Event:FireServer(i)
            end)
         end)
      end
   end,
})

SettingsTab:CreateSection("Danger Zone")
SettingsTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
      Rayfield:Destroy()
   end,
})

task.spawn(function()
    while true do
        if getgenv().AutoClickMoney then
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.ClickMoney
                Event:FireServer()
            end)
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoClickGem then
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.ClickMoney.ClickGem
                Event:FireServer()
            end)
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoDailyReward then
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.ClaimDailyReward
                Event:FireServer()
            end)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoCollectMainAchievement then
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.CollectMainAchievement
                Event:FireServer()
            end)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoGemUpgrade then
            for i = 1, 100 do
                task.spawn(function()
                    pcall(function()
                        local Event = game:GetService("ReplicatedStorage").Events.GemUpgrade
                        Event:FireServer(i)
                    end)
                end)
            end
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoOpenCrate then
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.OpenCrate
                Event:FireServer()
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoPrestige then
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.Prestige
                Event:FireServer()
            end)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if getgenv().AutoUpgrade then
            for i = 1, 100 do
                if not getgenv().AutoUpgrade then break end

                pcall(function()
                    local Event = game:GetService("ReplicatedStorage").Events.Upgrade
                    Event:FireServer(i)
                end)
            end
        end
        task.wait(0.01)
    end
end)
