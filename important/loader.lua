local Mercury = loadstring(game:HttpGet("https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"))()
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
    end
end


local function destroyGUI()
    if GUI then
        GUI:Destroy()
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
    GUI = Mercury:Create{
        Name = "Noctura",
        Size = UDim2.fromOffset(500, 300),
        Theme = Mercury.Themes.Dark,
        Link = "https://github.com/Nocturra/Noctura"
    }
    
    local Tab = GUI:Tab{
        Name = "Home",
        Icon = "rbxassetid://8569322835"
    }
    
    Tab:Button{
        Name = "Load",
        Description = "Welcome to Noctura. Would you like to load " .. matchingScript.name .. "?",
        Callback = function()
            loadstring(matchingScript.script)()
        end
    }
    
    local SettingsTab = GUI:Tab{
        Name = "Settings",
        Icon = "rbxassetid://8569321952"
    }
    
    SettingsTab:Toggle{
        Name = "Anonymize",
        StartingState = false,
        Description = "Spoof your username and profile picture",
        Callback = function(state)
            if state then
                anonymizePlayer()
            end
        end
    }
    
    SettingsTab:Button{
        Name = "Close",
        Description = "Destroy the GUI",
        Callback = function()
            destroyGUI()
        end
    }
else
    GUI = Mercury:Create{
        Name = "Noctura",
        Size = UDim2.fromOffset(500, 300),
        Theme = Mercury.Themes.Dark,
        Link = "https://github.com/Nocturra/Noctura"
    }
    
    local Tab = GUI:Tab{
        Name = "Home",
        Icon = "rbxassetid://8569322835"
    }
    
    Tab:Button{
        Name = "Load Universal",
        Description = "This game isn't supported :( Use Universal!",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Nocturra/Noctura/refs/heads/main/scripts/uni/script.lua"))()
        end
    }
    
    local SettingsTab = GUI:Tab{
        Name = "Settings",
        Icon = "rbxassetid://8569321952"
    }
    
    SettingsTab:Button{
        Name = "Close",
        Description = "Destroy the GUI",
        Callback = function()
            destroyGUI()
        end
    }
end
