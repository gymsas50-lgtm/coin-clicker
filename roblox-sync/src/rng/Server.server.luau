local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = ReplicatedStorage:WaitForChild("AuraRNG")
local config = require(folder:WaitForChild("Config"))
local request, result = folder:WaitForChild("RollRequest"), folder:WaitForChild("RollResult")
local inventory = folder:WaitForChild("Inventory")
local random = Random.new()
local data = {}
local totalWeight = 0
for _, aura in config do totalWeight += aura.Weight end
local function equip(player)
    local state, character = data[player], player.Character
    if not state or not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not root or not head then return end
    for _, name in {"AuraParticles", "AuraLight"} do
        local old = root:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local old = head:FindFirstChild("AuraTitle")
    if old then old:Destroy() end
    if state.equipped == 0 then return end
    local aura = config[state.equipped]
    local attachment = Instance.new("Attachment")
    attachment.Name = "AuraParticles"
    attachment.Parent = root
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(aura.Color)
    particles.LightEmission = 0.75
    particles.Rate = aura.Rate
    particles.Lifetime = NumberRange.new(1.1, 1.8)
    particles.Speed = NumberRange.new(0.5, 2.0)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Acceleration = Vector3.new(0, 1.8, 0)
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.25,.22),NumberSequenceKeypoint.new(1,0)})
    particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(.7,.4),NumberSequenceKeypoint.new(1,1)})
    particles.Parent = attachment
    if state.equipped >= 3 then
        local light = Instance.new("PointLight")
        light.Name = "AuraLight"
        light.Color = aura.Color
        light.Brightness = 0.5
        light.Range = 9
        light.Parent = root
    end
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
    local value,index = random:NextInteger(1,totalWeight),#config
    for i,aura in config do
        value -= aura.Weight
        if value <= 0 then index=i;break end
    end
    state.sequence += 1
    state.pending = {index=index,token=state.sequence,readyAt=now+3}
    local packet = snapshot(state)
    packet.Index = index
    packet.Token = state.sequence
    result:FireClient(player,packet)
end)
