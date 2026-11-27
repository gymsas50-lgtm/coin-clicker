local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local tracked = {}
local function track(motor)
    if not motor:IsA("Motor6D") then return end
    local offset = motor:GetAttribute("BaseOffset")
    local speed = motor:GetAttribute("Speed")
    if typeof(offset) == "CFrame" and type(speed) == "number" then
        tracked[motor] = {offset=offset,speed=speed,axis=motor:GetAttribute("Axis") or "Y"}
    end
end
for _, motor in CollectionService:GetTagged("AuraOrbit") do track(motor) end
CollectionService:GetInstanceAddedSignal("AuraOrbit"):Connect(track)
CollectionService:GetInstanceRemovedSignal("AuraOrbit"):Connect(function(motor) tracked[motor]=nil end)
RunService.RenderStepped:Connect(function()
    local now = workspace:GetServerTimeNow()
    for motor, data in tracked do
        if not motor.Parent then
            tracked[motor]=nil
        else
            local angle=(now*data.speed)%(math.pi*2)
            local rotation = data.axis=="X" and CFrame.Angles(angle,0,0) or (data.axis=="Z" and CFrame.Angles(0,0,angle) or CFrame.Angles(0,angle,0))
            motor.C0=data.offset*rotation
        end
    end
end)
