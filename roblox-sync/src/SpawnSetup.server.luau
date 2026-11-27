local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("SpawnLocation")
spawn.Anchored=true
spawn.CFrame=CFrame.new(25,.5,0)
spawn.Enabled=true
spawn.Neutral=true
local function assign(player)
    player.RespawnLocation=spawn
end
Players.PlayerAdded:Connect(assign)
for _,player in Players:GetPlayers() do assign(player) end
