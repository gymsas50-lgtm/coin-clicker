local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = ReplicatedStorage:WaitForChild("AuraRNG")
local config = require(folder:WaitForChild("Config"))
local request, result = folder:WaitForChild("RollRequest"), folder:WaitForChild("RollResult")
local random = Random.new()
local data = {}
local function equip(player)
    local state, character = data[player], player.Character
    if not state or not character or state.best == 0 then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not root or not head then return end
    for _, name in {"AuraParticles", "AuraLight"} do
        local old = root:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local old = head:FindFirstChild("AuraTitle")
    if old then old:Destroy() end
    local aura = config[state.best]
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
    if state.best >= 3 then
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
    data[player] = {rolls=0,best=0,nextAt=0,owned={}}
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
request.OnServerEvent:Connect(function(player)
    local state = data[player]
    if not state then return end
    local now = os.clock()
    if now < state.nextAt then
        result:FireClient(player,{Error=true,Remaining=state.nextAt-now})
        return
    end
    state.nextAt = now+1
    local value,index = random:NextInteger(1,10000),1
    for i,aura in config do
        value -= aura.Weight
        if value <= 0 then index=i;break end
    end
    state.rolls += 1
    state.owned[index] = (state.owned[index] or 0)+1
    local previous = state.best
    state.best = math.max(state.best,index)
    local stats = player:FindFirstChild("leaderstats")
    if stats and stats:FindFirstChild("Rolls") then stats.Rolls.Value=state.rolls end
    if state.best ~= previous then equip(player) end
    result:FireClient(player,{Index=index,Rolls=state.rolls,Best=state.best,NewBest=state.best>previous,Count=state.owned[index]})
end)
