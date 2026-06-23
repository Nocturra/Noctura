local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/VisualRoblox/Roblox/main/UI-Libraries/Visual%20UI%20Library/Source.lua'))()

local Window = Library:CreateWindow('Noctura', 'Become rich. Why not.', 'Noctura', 'rbxassetid://10618928818', false, 'NocturaMoneyClickerConfigs', 'Purple')

getgenv().AutoClickMoney = false
getgenv().AutoClickGem = false
getgenv().AutoDailyReward = false
getgenv().AutoCollectMainAchievement = false
getgenv().AutoGemUpgrade = false
getgenv().AutoOpenCrate = false
getgenv().AutoPrestige = false
getgenv().AutoUpgrade = false
getgenv().AutoAll = false

local MainTab = Window:CreateTab('Auto Functions', true, 'rbxassetid://3926305904', Vector2.new(524, 44), Vector2.new(36, 36))

local SingleFunctionsTab = Window:CreateTab('Single Functions', false, 'rbxassetid://3926305904', Vector2.new(524, 44), Vector2.new(36, 36))

local ConfigsTab = Window:CreateTab('Configs', false, 'rbxassetid://3926305904', Vector2.new(964, 284), Vector2.new(36, 36))

local SettingsTab = Window:CreateTab('Settings', false, 'rbxassetid://3926305904', Vector2.new(964, 284), Vector2.new(36, 36))

local ThemeSection = SettingsTab:CreateSection('Theme')

ThemeSection:CreateDropdown('Theme', {'Default', 'Lighter', 'Light', 'Light+', 'Discord', 'Red And Black', 'Nordic Dark', 'Nordic Light', 'Purple', 'Sentinel', 'Synapse X', 'Krnl', 'Script-Ware', 'Kiriot'}, 'Default', 0.25, function(Value)
    pcall(function()
        Library:ChangeTheme(Value)
    end)
end)

local SaveSection = ConfigsTab:CreateSection('Save Config')

local ConfigNameInput = SaveSection:CreateTextbox('Config Name', 'Enter config name', function() end)

SaveSection:CreateButton('Save Config', function()
    Library:SaveConfig('Default')
    Library:CreateNotification('Config Saved', 'Your config has been saved!', 3)
end)

local LoadSection = ConfigsTab:CreateSection('Load Config')

LoadSection:CreateButton('Load Config', function()
    Library:LoadConfig('Default')
    Library:CreateNotification('Config Loaded', 'Your config has been loaded!', 3)
end)

local DeleteSection = ConfigsTab:CreateSection('Delete Config')

DeleteSection:CreateButton('Delete Config', function()
    Library:DeleteConfig('Default')
    Library:CreateNotification('Config Deleted', 'Your config has been deleted!', 3)
end)

local Section = MainTab:CreateSection('Autofarm Toggles')

Section:CreateToggle('Auto All', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoAll = Value
    getgenv().AutoClickMoney = Value
    getgenv().AutoClickGem = Value
    getgenv().AutoDailyReward = Value
    getgenv().AutoCollectMainAchievement = Value
    getgenv().AutoGemUpgrade = Value
    getgenv().AutoOpenCrate = Value
    getgenv().AutoPrestige = Value
    getgenv().AutoUpgrade = Value
end)

Section:CreateToggle('Auto Click Money', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoClickMoney = Value
end)

Section:CreateToggle('Auto Click Gem', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoClickGem = Value
end)

Section:CreateToggle('Auto Daily Reward', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoDailyReward = Value
end)

Section:CreateToggle('Auto Collect Main Achievement', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoCollectMainAchievement = Value
end)

Section:CreateToggle('Auto Gem Upgrade', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoGemUpgrade = Value
end)

Section:CreateToggle('Auto Open Crate', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoOpenCrate = Value
end)

Section:CreateToggle('Auto Prestige', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoPrestige = Value
end)

Section:CreateToggle('Auto Upgrade', false, Color3.fromRGB(0, 125, 255), 0.25, function(Value)
    getgenv().AutoUpgrade = Value
end)

local SingleFunctionSection = SingleFunctionsTab:CreateSection('Single Functions')

SingleFunctionSection:CreateButton('Execute All Once', function()
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
end)

SingleFunctionSection:CreateButton('Click Money', function()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage").Events.ClickMoney
        Event:FireServer()
    end)
end)

SingleFunctionSection:CreateButton('Click Gem', function()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage").Events.ClickMoney.ClickGem
        Event:FireServer()
    end)
end)

SingleFunctionSection:CreateButton('Daily Reward', function()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage").Events.ClaimDailyReward
        Event:FireServer()
    end)
end)

SingleFunctionSection:CreateButton('Collect Main Achievement', function()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage").Events.CollectMainAchievement
        Event:FireServer()
    end)
end)

SingleFunctionSection:CreateButton('Gem Upgrade', function()
    for i = 1, 100 do
        task.spawn(function()
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.GemUpgrade
                Event:FireServer(i)
            end)
        end)
    end
end)

SingleFunctionSection:CreateButton('Open Crate', function()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage").Events.OpenCrate
        Event:FireServer()
    end)
end)

SingleFunctionSection:CreateButton('Prestige', function()
    pcall(function()
        local Event = game:GetService("ReplicatedStorage").Events.Prestige
        Event:FireServer()
    end)
end)

SingleFunctionSection:CreateButton('Upgrade', function()
    for i = 1, 100 do
        task.spawn(function()
            pcall(function()
                local Event = game:GetService("ReplicatedStorage").Events.Upgrade
                Event:FireServer(i)
            end)
        end)
    end
end)

local DestroySection = SettingsTab:CreateSection('Danger Zone')

DestroySection:CreateButton('Destroy GUI', function()
    pcall(function()
        Library:Destroy()
    end)
end)

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
