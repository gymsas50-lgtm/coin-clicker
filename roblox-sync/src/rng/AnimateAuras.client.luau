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
