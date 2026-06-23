local Luminosity = loadstring(game:HttpGet("https://raw.githubusercontent.com/iHavoc101/Genesis-Studios/main/UserInterface/Luminosity.lua", true))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Toggles = {
    StudUpgrade = false,
    Currency = false,
    Xp = false,
    Points = false,
    TierUp = false,
    Blocks = false,
    Rebirth = false
}

local function RunLoop(key, event, value)
    task.spawn(function()
        while Toggles[key] do
            if value ~= nil then event:FireServer(value) else event:FireServer() end
            task.wait()
        end
    end)
end

local Window = Luminosity.new("Noctura", "Gooby this, Gooby that.", 4370345701)

local MainTab = Window.Tab("Main", 6026568198)
local Area3Tab = Window.Tab("Area 3", 6026568198)
local TitlesTab = Window.Tab("Titles", 6026568198)
local SettingsTab = Window.Tab("Settings", 6026568198)
local StudFolder = MainTab.Folder("Studs", "Stud upgrade automation")

StudFolder.Toggle("Auto Stud Upgrade", function(state)
    Toggles.StudUpgrade = state
    if state then
        task.spawn(function()
            while Toggles.StudUpgrade do
                pcall(function()
                    ReplicatedStorage.Area1.StudUpgradeWall:FireServer(1)
                end)
                task.wait()
            end
        end)
    end
end)

StudFolder.Button("Upgrade Once", "Run", function()
    ReplicatedStorage.Area1.StudUpgradeWall:FireServer(1)
end)

local CurrencyFolder = MainTab.Folder("Currency", "Auto currency farming")

local SelectedCurrency = "Stud"

CurrencyFolder.Dropdown("Select Currency", {"Stud", "GoldStud", "DiamondStud", "EmeraldStud", "RubyStud"}, function(val)
    SelectedCurrency = val
end)

CurrencyFolder.Toggle("Auto Currency", function(state)
    Toggles.Currency = state
    if state then RunLoop("Currency", ReplicatedStorage.Area1.CurrencyGain, SelectedCurrency) end
end)

local XpFolder = MainTab.Folder("XP & Rebirth", "XP and rebirth automation")

XpFolder.Toggle("Auto XP", function(state)
    Toggles.Xp = state
    if state then RunLoop("Xp", ReplicatedStorage.AddXpEvent) end
end)

XpFolder.Toggle("Auto Rebirth", function(state)
    Toggles.Rebirth = state
    if state then
        task.spawn(function()
            while Toggles.Rebirth do
                pcall(function()
                    ReplicatedStorage.Area1.Rebirth:FireServer(2)
                end)
                task.wait(0.1)
            end
        end)
    end
end)

local Area2Folder = MainTab.Folder("Area 2", "Area 2 automation")

Area2Folder.Toggle("Auto Points", function(state)
    Toggles.Points = state
    if state then RunLoop("Points", ReplicatedStorage.Area2.PointsGain, 1) end
end)

Area2Folder.Toggle("Auto Tier Up", function(state)
    Toggles.TierUp = state
    if state then RunLoop("TierUp", ReplicatedStorage.Area2.TierUp, 1) end
end)

-- Area 3 Tab
local BlocksFolder = Area3Tab.Folder("Blocks", "Area 3 block farming")

BlocksFolder.Toggle("Auto Blocks", function(state)
    Toggles.Blocks = state
    if state then RunLoop("Blocks", ReplicatedStorage.Area3.BlocksGain) end
end)

local TitlesFolder = TitlesTab.Folder("Titles", "Set your title")

local SelectedTitle = "VIP"

TitlesFolder.Dropdown("Select Title", {"VIP", "MEMBER", "SUPPORTER", "RICH PLAYER", "CRAZY SPENDER", "WHALE", "POCKET CHANGE", "MILLIONAIRE", "TRILLIONAIRE", "SEPTILLIONAIRE", "DECILLIONAIRE", "TREDECILLIONAIRE", "NOVICE", "EXPERIENCED", "MASTER", "GRINDER", "HOURS", "DAYS", "WEEKS", "TESTER", "ADMIN", "DEVELOPER", "OWNER"}, function(val)
    SelectedTitle = val
end)

TitlesFolder.Button("Apply Title", "Set", function()
    ReplicatedStorage.UpdateTitle:FireServer(SelectedTitle)
end)

local SettingsFolder = SettingsTab.Folder("Settings", "General settings")

SettingsFolder.Button("Destroy GUI", "Bye", function()
    for key in pairs(Toggles) do
        Toggles[key] = false
    end
    Window:Toggle(false)
end)

game:GetService("UserInputService").InputBegan:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.F then
        Window:Toggle()
    end
end)
