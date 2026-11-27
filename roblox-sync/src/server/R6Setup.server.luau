-- Build a real six-part StarterCharacter before automatic character spawning.
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
Players.CharacterAutoLoads = false
local description = Instance.new("HumanoidDescription")
local character
for attempt = 1, 3 do
    local ok, result = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6)
    end)
    if ok then
        character = result
        break
    end
    warn("R6 character setup retry:", result)
    task.wait(1)
end
description:Destroy()
if character then
    local previous = StarterPlayer:FindFirstChild("StarterCharacter")
    if previous then previous:Destroy() end
    character.Name = "StarterCharacter"
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
    character.Parent = StarterPlayer
else
    warn("R6 template could not load. Check Roblox network access and restart Play.")
end
Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
    task.spawn(function()
        if player.Parent == Players then
            local ok, message = pcall(function() player:LoadCharacterAsync() end)
            if not ok then warn(message) end
        end
    end)
end
