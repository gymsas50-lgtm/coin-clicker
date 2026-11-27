local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local tracked = {}
local function track(motor)
    if motor:IsA("Motor6D") then tracked[motor]=true end
end
for _, motor in CollectionService:GetTagged("AuraOrbit") do track(motor) end
CollectionService:GetInstanceAddedSignal("AuraOrbit"):Connect(track)
CollectionService:GetInstanceRemovedSignal("AuraOrbit"):Connect(function(motor) tracked[motor]=nil end)
-- PreSimulation runs after Animator updates and before joint transforms are applied.
-- Retry missing attributes: streamed/tagged instances may arrive before their data.
RunService.PreSimulation:Connect(function()
    local now = workspace:GetServerTimeNow()
    for motor in tracked do
        if not motor.Parent then
            tracked[motor]=nil
        elseif motor.Part0 and motor.Part1 then
            local offset=motor:GetAttribute("BaseOffset")
            local speed=motor:GetAttribute("Speed")
            if typeof(offset)=="CFrame" and type(speed)=="number" then
                local angle=(now*speed*.8)%(math.pi*2)
                local axis=motor:GetAttribute("Axis") or "Y"
                local rotation=axis=="X" and CFrame.Angles(angle,0,0) or (axis=="Z" and CFrame.Angles(0,0,angle) or CFrame.Angles(0,angle,0))
                local phase=offset.Position.Y*.7+offset.Position.Z
                local bob=math.sin(now*1.8+phase)*(motor:GetAttribute("Bob") or .12)
                local sway=math.sin(now*1.35+phase)*(motor:GetAttribute("Sway") or .025)
                motor.Transform=CFrame.identity
                motor.C0=offset*CFrame.new(0,bob,0)*rotation*CFrame.Angles(0,0,sway)
            end
        end
    end
end)

-- Prime freshly replicated aura emitters locally; regular Rate sustains them.
local warmed=setmetatable({}, {__mode="k"})
local function warm(instance)
    if not instance:IsA("ParticleEmitter") or warmed[instance] then return end
    if not instance:FindFirstAncestor("AuraVisuals") then return end
    task.defer(function()
        if not instance.Parent or warmed[instance] then return end
        local count=instance:GetAttribute("WarmCount")
        if type(count)=="number" then
            warmed[instance]=true
            instance:Emit(math.clamp(count,1,80))
        end
    end)
end
workspace.DescendantAdded:Connect(warm)
for _,instance in workspace:GetDescendants() do warm(instance) end

-- Gentle bloom provides a luminous halo without increasing world-light brightness.
local Lighting=game:GetService("Lighting")
local bloom=Lighting:FindFirstChild("AuraStarGlow")
if not bloom then
    bloom=Instance.new("BloomEffect")
    bloom.Name="AuraStarGlow"
    bloom.Intensity=.28
    bloom.Size=16
    bloom.Threshold=1.1
    bloom.Parent=Lighting
end
