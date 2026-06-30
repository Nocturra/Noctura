getgenv().RAYFIELD_ASSET_ID = 120960636838063
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Noctura - Sell Lemons",
   LoadingTitle = "Noctura",
   LoadingSubtitle = "Sell Lemons",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "Noctura",
      FileName = "SellLemonsConfig"
   },
   Theme = "Amethyst"
})

local AutofarmTab = Window:CreateTab("Autofarm")
local SettingsTab = Window:CreateTab("Settings")
local MiscTab = Window:CreateTab("Misc")

local plr = game:GetService("Players").LocalPlayer

getgenv().farming = false
getgenv().autoPhoneOffer = true
getgenv().farmsettings = {
    purchase = true,
    upgrade = true,
    collect = true,
    cashdrop = true,
    fruit = true
}

local tycoon
for _, v in pairs(workspace:GetChildren()) do
    if v.Name:find("Tycoon") and v:FindFirstChild("Owner").Value == plr then
        tycoon = v
    end
end

local suffixes = {
    K   = 1e3,
    M   = 1e6,
    B   = 1e9,
    T   = 1e12,
    Qd  = 1e15,
    Qn  = 1e18,
    Sx  = 1e21,
    Sxd = 1e21,
    Sp  = 1e24,
    Oc  = 1e27,
    No  = 1e30,
    Dc  = 1e33,
}

function decodeValue(str)
    local clean = str:gsub("[\226\128\128-\226\128\143]", "")

    local numStr, suffix = clean:match("%$([%d%,%.]+)(%a*)")
    if not numStr then
        return nil
    end

    local num = tonumber((numStr:gsub(",", "")))
    if not num then
        return nil
    end

    if suffix == "" then
        return num
    end

    local multiplier = suffixes[suffix]

    if not multiplier then
        suffix = suffix:sub(1,1):upper() .. suffix:sub(2):lower()
        multiplier = suffixes[suffix]
    end

    if multiplier then
        return num * multiplier
    end

    return num
end

local PurchasesFold = tycoon.Purchases

tycoon.Remotes.PhoneOffer.OnClientEvent:Connect(function()
    if not getgenv().autoPhoneOffer or not getgenv().farming then return end
    local Event = tycoon.Remotes.PhoneOffer
    Event:FireServer(
        "Accept"
    )
end)

AutofarmTab:CreateSection("Farming Options")
AutofarmTab:CreateToggle({
   Name = "Autofarm",
   CurrentValue = false,
   Flag = "Autofarm",
   Callback = function(bool)
      local stands = tycoon.Values.Income.Streams
      getgenv().farming = bool
      if not getgenv().farming then return end
      task.spawn(function()
         while getgenv().farming do
            if not getgenv().farmsettings.collect then wait(1) continue end
            for i, v in pairs(stands:GetChildren()) do
               local Event = tycoon.Remotes.WakeIncomeStream
               Event:InvokeServer(v.Name)
            end
            task.wait()
         end
      end)

      while getgenv().farming do
         pcall(function()
            if not getgenv().farmsettings.purchase then return end
            for _, fold in pairs(PurchasesFold:GetChildren()) do
               if fold:FindFirstChild("Buttons") then
                  for i, nFold in pairs(fold.Buttons:GetChildren()) do
                     if nFold:IsA("Folder") then
                        for _,btn in pairs(nFold:GetChildren()) do
                           if btn:GetAttribute("Shown") and btn:GetAttribute("Enabled") and not btn:GetAttribute("Purchased") then
                              local price = decodeValue(btn.Button.Gui.Price.Text)
                              local curbalance = decodeValue(plr.leaderstats.Cash.Value)
                              if price <= curbalance then
                                 firetouchinterest(plr.Character.Head, btn.Button, true)
                                 task.wait()
                                 firetouchinterest(plr.Character.Head, btn.Button, false)
                              end
                           end
                        end
                     elseif nFold:IsA("Model") then
                        if nFold:GetAttribute("Shown") and nFold:GetAttribute("Enabled") and not nFold:GetAttribute("Purchased") then
                           local price = decodeValue(nFold.Button.Gui.Price.Text)
                           local curbalance = decodeValue(plr.leaderstats.Cash.Value)
                           if price <= curbalance then
                              firetouchinterest(plr.Character.Head, nFold.Button, true)
                              task.wait()
                              firetouchinterest(plr.Character.Head, nFold.Button, false)
                           end
                        end
                     end
                  end
               end
            end
         end)

         pcall(function()
            if not getgenv().farmsettings.upgrade then return end
            for _, fold in pairs(PurchasesFold:GetChildren()) do
               if fold:FindFirstChild(fold.Name) then
                  if not fold:FindFirstChild(fold.Name):GetAttribute("Enabled") then
                     continue
                  end
                  fold:FindFirstChild(fold.Name):FindFirstChild(fold.Name).Upgrade:InvokeServer(1)
               end
            end
         end)

         pcall(function()
            if not getgenv().farmsettings.cashdrop then return end
            for i, v in pairs(workspace.CashDrops:GetChildren()) do
               firetouchinterest(plr.Character.Head, v, true)
               task.wait()
               firetouchinterest(plr.Character.Head, v, false)
            end
         end)

         pcall(function()
            if not getgenv().farmsettings.fruit then return end
            for i, v in pairs(tycoon.Constant.Trees:GetChildren()) do
               for _, lemon in pairs(v:GetChildren()) do
                  if not lemon.Name == "Fruit" then continue end
                  if not lemon:FindFirstChild("ClickPart") then continue end
                  fireclickdetector(lemon.ClickPart.ClickDetector)
                  task.wait()
               end
            end
         end)

         task.wait(1)
      end
   end,
})

AutofarmTab:CreateSection("Sub-Options")
AutofarmTab:CreateToggle({
   Name = "Auto Purchase",
   CurrentValue = true,
   Flag = "AutoPurchase",
   Callback = function(v)
      getgenv().farmsettings.purchase = v
   end,
})
AutofarmTab:CreateToggle({
   Name = "Auto Collect",
   CurrentValue = true,
   Flag = "AutoCollect",
   Callback = function(v)
      getgenv().farmsettings.collect = v
   end,
})
AutofarmTab:CreateToggle({
   Name = "Auto Upgrade",
   CurrentValue = true,
   Flag = "AutoUpgrade",
   Callback = function(v)
      getgenv().farmsettings.upgrade = v
   end,
})
AutofarmTab:CreateToggle({
   Name = "Auto Cash Drop",
   CurrentValue = true,
   Flag = "AutoCashDrop",
   Callback = function(v)
      getgenv().farmsettings.cashdrop = v
   end,
})
AutofarmTab:CreateToggle({
   Name = "Auto Pickup Fruit",
   CurrentValue = true,
   Flag = "AutoPickupFruit",
   Callback = function(v)
      getgenv().farmsettings.fruit = v
   end,
})
AutofarmTab:CreateToggle({
   Name = "Auto Phone Offer Accept",
   CurrentValue = true,
   Flag = "AutoPhoneOffer",
   Callback = function(v)
      getgenv().autoPhoneOffer = v
   end,
})

getgenv().antiafk = true

plr.Idled:Connect(function()
   if not getgenv().antiafk then return end
   game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
   game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

SettingsTab:CreateSection("System Settings")
SettingsTab:CreateToggle({
   Name = "Disable 3D Rendering",
   CurrentValue = false,
   Flag = "Disable3DRendering",
   Callback = function(v)
      game:GetService("RunService"):Set3dRenderingEnabled(not v)
   end,
})
SettingsTab:CreateToggle({
   Name = "Anti AFK",
   CurrentValue = true,
   Flag = "AntiAFK",
   Callback = function(v)
      getgenv().antiafk = v
   end,
})
SettingsTab:CreateButton({
   Name = "Close GUI",
   Callback = function()
      Rayfield:Destroy()
   end,
})

MiscTab:CreateSection("Misc Options")
local selectedLabel = "LemonStand"
MiscTab:CreateDropdown({
   Name = "Select Label",
   Options = {"LemonStand", "LemonDash"},
   CurrentOption = {"LemonStand"},
   MultipleOptions = false,
   Flag = "SelectedLabel",
   Callback = function(Options)
      selectedLabel = Options[1]
   end,
})

MiscTab:CreateSection("Select Value")
local labelOptions = {
   "SCREW",
   "Noctura is the Best",
   "Noctura Lemon Lemon",
   "🎅🏿🎅🏿",
   "Eat Fat Lemons",
   "Drink Bromine"
}

for _, labelValue in ipairs(labelOptions) do
   MiscTab:CreateButton({
      Name = labelValue,
      Callback = function()
         local Event = tycoon.Remotes.ChangeLabel
         Event:InvokeServer(selectedLabel, labelValue)
      end,
   })
end
