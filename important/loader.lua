getgenv().RAYFIELD_ASSET_ID = 120960636838063
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local HttpService = game:GetService("HttpService")

local currentPlaceId = game.PlaceId
local matchingScript = nil
local GUI = nil
local isAnonymized = false

local function generateRandomUsername()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, 10 do
        result = result .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return result
end

local function anonymizePlayer()
    local player = game.Players.LocalPlayer
    if player then
        player.Character.Head.face.Texture = "rbxasset://textures/face.png"
        local newName = generateRandomUsername()
        player.Name = newName
        isAnonymized = true
        print("Anonymized as: " .. newName)
        Rayfield:Notify({Title = "Anonymized", Content = "Username spoofed to: " .. newName, Duration = 3})
    end
end

local function destroyGUI()
    if GUI then
        Rayfield:Destroy()
        GUI = nil
    end
end

local success, result = pcall(function()
    local response = game:HttpGet("https://raw.githubusercontent.com/Nocturra/Noctura/refs/heads/main/important/scripts.json")
    return HttpService:JSONDecode(response)
end)

if not success then
    print("Failed to fetch Noctura scripts: " .. tostring(result))
    return
end

local scripts = result

print("Current Place ID: " .. tostring(currentPlaceId))
print("Available scripts:")
for _, script in ipairs(scripts.scripts) do
    print("  - " .. script.name .. " (ID: " .. tostring(script.gameId) .. ")")
end

for _, script in ipairs(scripts.scripts) do
    if tonumber(script.gameId) == currentPlaceId then
        matchingScript = script
        print("Found matching script: " .. script.name)
        break
    end
end

if matchingScript then
    GUI = Rayfield:CreateWindow({
        Name = "Noctura | Happy 5 Games Supported! 💕",
        LoadingTitle = "Noctura",
        LoadingSubtitle = "Loading...",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = "Noctura",
            FileName = "LoaderConfig"
        },
        Theme = "Amethyst"
    })

    local Tab = GUI:CreateTab("Home")
    local SettingsTab = GUI:CreateTab("Settings")

    Tab:CreateButton({
        Name = "Load " .. matchingScript.name,
        Callback = function()
            loadstring(matchingScript.script)()
            Rayfield:Notify({Title = "Loaded", Content = "Successfully loaded " .. matchingScript.name, Duration = 3})
        end,
    })

    SettingsTab:CreateToggle({
        Name = "Anonymize",
        CurrentValue = false,
        Flag = "Anonymize",
        Callback = function(Value)
            if Value then
                anonymizePlayer()
            end
        end,
    })

    SettingsTab:CreateButton({
        Name = "Close",
        Callback = function()
            destroyGUI()
        end,
    })
else
    GUI = Rayfield:CreateWindow({
        Name = "Noctura",
        LoadingTitle = "Noctura",
        LoadingSubtitle = "Universal Loader",
        ConfigurationSaving = {
            Enabled = false,
            FolderName = "Noctura",
            FileName = "LoaderConfig"
        },
        Theme = "AmberGlow"
    })

    local Tab = GUI:CreateTab("Home")
    local SettingsTab = GUI:CreateTab("Settings")

    Tab:CreateButton({
        Name = "Load Universal",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Nocturra/Noctura/refs/heads/main/scripts/uni/script.lua"))()
            Rayfield:Notify({Title = "Loaded", Content = "Loaded Universal Script", Duration = 3})
        end,
    })

    SettingsTab:CreateButton({
        Name = "Close",
        Callback = function()
            destroyGUI()
        end,
    })
end
