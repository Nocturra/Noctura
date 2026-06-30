getgenv().RAYFIELD_ASSET_ID = 120960636838063
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Window = Rayfield:CreateWindow({
   Name = "Noctura - Stud Incremental",
   LoadingTitle = "Noctura",
   LoadingSubtitle = "Gooby this, Gooby that.",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "Noctura",
      FileName = "StudIncrementalConfig"
   },
   Theme = "AmberGlow"
})

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

local MainTab = Window:CreateTab("Main")
local Area3Tab = Window:CreateTab("Area 3")
local TitlesTab = Window:CreateTab("Titles")
local SettingsTab = Window:CreateTab("Settings")

MainTab:CreateSection("Studs")
MainTab:CreateToggle({
   Name = "Auto Stud Upgrade",
   CurrentValue = false,
   Flag = "StudUpgrade",
   Callback = function(state)
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
   end,
})
MainTab:CreateButton({
   Name = "Upgrade Once",
   Callback = function()
      ReplicatedStorage.Area1.StudUpgradeWall:FireServer(1)
   end,
})

MainTab:CreateSection("Currency")
local SelectedCurrency = "Stud"
MainTab:CreateDropdown({
   Name = "Select Currency",
   Options = {"Stud", "GoldStud", "DiamondStud", "EmeraldStud", "RubyStud"},
   CurrentOption = {"Stud"},
   MultipleOptions = false,
   Flag = "SelectedCurrency",
   Callback = function(Options)
      SelectedCurrency = Options[1]
   end,
})
MainTab:CreateToggle({
   Name = "Auto Currency",
   CurrentValue = false,
   Flag = "Currency",
   Callback = function(state)
      Toggles.Currency = state
      if state then RunLoop("Currency", ReplicatedStorage.Area1.CurrencyGain, SelectedCurrency) end
   end,
})

MainTab:CreateSection("XP & Rebirth")
MainTab:CreateToggle({
   Name = "Auto XP",
   CurrentValue = false,
   Flag = "Xp",
   Callback = function(state)
      Toggles.Xp = state
      if state then RunLoop("Xp", ReplicatedStorage.AddXpEvent) end
   end,
})
MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "Rebirth",
   Callback = function(state)
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
   end,
})

MainTab:CreateSection("Area 2")
MainTab:CreateToggle({
   Name = "Auto Points",
   CurrentValue = false,
   Flag = "Points",
   Callback = function(state)
      Toggles.Points = state
      if state then RunLoop("Points", ReplicatedStorage.Area2.PointsGain, 1) end
   end,
})
MainTab:CreateToggle({
   Name = "Auto Tier Up",
   CurrentValue = false,
   Flag = "TierUp",
   Callback = function(state)
      Toggles.TierUp = state
      if state then RunLoop("TierUp", ReplicatedStorage.Area2.TierUp, 1) end
   end,
})

Area3Tab:CreateSection("Blocks")
Area3Tab:CreateToggle({
   Name = "Auto Blocks",
   CurrentValue = false,
   Flag = "Blocks",
   Callback = function(state)
      Toggles.Blocks = state
      if state then RunLoop("Blocks", ReplicatedStorage.Area3.BlocksGain) end
   end,
})

TitlesTab:CreateSection("Titles")
local SelectedTitle = "VIP"
TitlesTab:CreateDropdown({
   Name = "Select Title",
   Options = {"VIP", "MEMBER", "SUPPORTER", "RICH PLAYER", "CRAZY SPENDER", "WHALE", "POCKET CHANGE", "MILLIONAIRE", "TRILLIONAIRE", "SEPTILLIONAIRE", "DECILLIONAIRE", "TREDECILLIONAIRE", "NOVICE", "EXPERIENCED", "MASTER", "GRINDER", "HOURS", "DAYS", "WEEKS", "TESTER", "ADMIN", "DEVELOPER", "OWNER"},
   CurrentOption = {"VIP"},
   MultipleOptions = false,
   Flag = "SelectedTitle",
   Callback = function(Options)
      SelectedTitle = Options[1]
   end,
})
TitlesTab:CreateButton({
   Name = "Apply Title",
   Callback = function()
      ReplicatedStorage.UpdateTitle:FireServer(SelectedTitle)
   end,
})

SettingsTab:CreateSection("Settings")
SettingsTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
      for key in pairs(Toggles) do
         Toggles[key] = false
      end
      Rayfield:Destroy()
   end,
})
