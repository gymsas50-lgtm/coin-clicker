local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = ReplicatedStorage:WaitForChild("AuraRNG")
local config = require(folder:WaitForChild("Config"))
local visuals = require(folder:WaitForChild("AuraVisuals"))
local request, result = folder:WaitForChild("RollRequest"), folder:WaitForChild("RollResult")
local inventory = folder:WaitForChild("Inventory")
local random = Random.new()
local data = {}
local rarityOrder={}
local commonIndex
for index,aura in config do
    if aura.Id=="Common" then commonIndex=index else table.insert(rarityOrder,index) end
end
assert(commonIndex,"Common fallback is required")
table.sort(rarityOrder,function(a,b)
    return config[a].BaseOdds>config[b].BaseOdds
end)
local function equip(player)
    local state, character = data[player], player.Character
    if not state or not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not root or not head then return end
    local previousVisuals = character:FindFirstChild("AuraVisuals")
    if previousVisuals then previousVisuals:Destroy() end
    for _, name in {"AuraParticles", "AuraLight"} do
        local old = root:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local old = head:FindFirstChild("AuraTitle")
    if old then old:Destroy() end
    if state.equipped == 0 then return end
    local aura = config[state.equipped]
    visuals.Build(character,aura.Id,aura.Color)
    local rank=1
    for _,other in config do if other.BaseOdds<aura.BaseOdds then rank+=1 end end
    local light=Instance.new("PointLight")
    light.Name="AuraLight";light.Color=aura.Color
    light.Brightness=(1+rank*.25)*.55;light.Range=(9+rank*1.5)*.85
    light.Shadows=false;light.Parent=root
    local title = Instance.new("BillboardGui")
    title.Name = "AuraTitle"
    title.Size = UDim2.fromOffset(220,55)
    title.StudsOffsetWorldSpace = Vector3.new(0,2.2,0)
    title.MaxDistance = 70
    title.AlwaysOnTop = false
    title.Parent = head
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1,1)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextSize = 18
    text.TextColor3 = aura.Color
    text.TextStrokeTransparency = .45
    text.Text = aura.Name .. "\n" .. aura.Chance
    text.Parent = title
end
local function init(player)
    if data[player] then return end
    data[player] = {rolls=0,equipped=0,nextAt=0,owned={},sequence=0,pending=nil}
    -- Temporary visual-testing inventory. Never grant free auras in live servers.
    if game:GetService("RunService"):IsStudio() then
        for index in config do data[player].owned[index]=1 end
    end
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player
    local rolls = Instance.new("IntValue")
    rolls.Name = "Rolls"
    rolls.Parent = stats
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart",15)
        character:WaitForChild("Head",15)
        if player.Character == character then equip(player) end
    end)
end
Players.PlayerAdded:Connect(init)
for _, player in Players:GetPlayers() do init(player) end
Players.PlayerRemoving:Connect(function(player) data[player]=nil end)
local function snapshot(state)
    local counts = {}
    for i = 1, #config do counts[i] = state.owned[i] or 0 end
    return {Owned=counts, Equipped=state.equipped, Rolls=state.rolls}
end
inventory.OnServerInvoke = function(player, action, index)
    local state = data[player]
    if not state then return nil end
    if action == "Complete" then
        local pending = state.pending
        if not pending or index ~= pending.token then return snapshot(state) end
        local waitTime = pending.readyAt-os.clock()
        if waitTime > 0 then task.wait(waitTime) end
        if data[player] ~= state or state.pending ~= pending then return snapshot(state) end
        state.pending = nil
        state.owned[pending.index] = (state.owned[pending.index] or 0)+1
        state.rolls += 1
        local stats = player:FindFirstChild("leaderstats")
        if stats and stats:FindFirstChild("Rolls") then stats.Rolls.Value=state.rolls end
    elseif action == "Equip" then
        if type(index) ~= "number" or index ~= math.floor(index) or not config[index] or (state.owned[index] or 0) < 1 then return snapshot(state) end
        state.equipped = index
        equip(player)
    elseif action == "Unequip" then
        state.equipped = 0
        equip(player)
    end
    return snapshot(state)
end
request.OnServerEvent:Connect(function(player)
    local state = data[player]
    if not state then return end
    local now = os.clock()
    if state.pending and now > state.pending.readyAt+12 then state.pending=nil end
    if state.pending or now < state.nextAt then
        result:FireClient(player,{Error=true,Remaining=math.max(.15,state.nextAt-now)})
        return
    end
    state.nextAt = now+3
    -- First successful rare-to-common check wins; never normalize base odds.
    -- Common is the guaranteed fallback, not an independent final probability.
    local index=commonIndex
    for _,candidate in rarityOrder do
        if random:NextInteger(1,config[candidate].BaseOdds)==1 then
            index=candidate
            break
        end
    end
    state.sequence += 1
    state.pending = {index=index,token=state.sequence,readyAt=now+3}
    local packet = snapshot(state)
    packet.Index = index
    packet.Token = state.sequence
    result:FireClient(player,packet)
end)
