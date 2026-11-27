local CollectionService=game:GetService("CollectionService")
local Visuals={}
function Visuals.Build(character,id,color)
    local root=character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local model=Instance.new("Model");model.Name="AuraVisuals";model.Parent=character
    local pale=color:Lerp(Color3.new(1,1,1),.35)
    local function source(name,size,offset,speed)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Transparency=1
        p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.CastShadow=false
        p.CFrame=root.CFrame*offset;p.Parent=model
        local m=Instance.new("Motor6D");m.Part0=root;m.Part1=p;m.C0=offset
        m:SetAttribute("BaseOffset",offset);m:SetAttribute("Speed",speed or 0)
        m:SetAttribute("Bob",.04);m:SetAttribute("Sway",0)
        m.Parent=p;CollectionService:AddTag(m,"AuraOrbit")
        return p
    end
    local function emit(parent,rate,size,life,velocity,acceleration,locked)
        local e=Instance.new("ParticleEmitter");e.Name="AuraParticles"
        e.Texture="rbxasset://textures/particles/sparkles_main.dds"
        e.Color=ColorSequence.new(pale,color);e.LightEmission=1;e.LightInfluence=0;e.Brightness=1.5
        e.Rate=rate;e.Lifetime=NumberRange.new(life*.8,life)
        e.Speed=NumberRange.new(velocity*.6,velocity);e.Acceleration=acceleration or Vector3.zero
        e.LockedToPart=locked or false;e.VelocityInheritance=0
        e.SpreadAngle=Vector2.new(20,20);e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-12,12)
        e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.18,size,size*.25),NumberSequenceKeypoint.new(.7,size*.65),NumberSequenceKeypoint.new(1,0)})
        e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,.25),NumberSequenceKeypoint.new(.7,.45),NumberSequenceKeypoint.new(1,1)})
        e:SetAttribute("WarmCount",math.ceil(rate*life*.5));e.Parent=parent
        return e
    end
    local function orbit(name,height,radius,speed,tilt,rate,size)
        local p=source(name,Vector3.new(.1,.1,.1),CFrame.new(0,height,0)*(tilt or CFrame.identity),speed)
        local a=Instance.new("Attachment");a.Position=Vector3.new(radius,0,0);a.Parent=p
        emit(a,rate,size,1.2,.04,Vector3.zero,false)
    end
    if id=="Common" then
        -- Quiet silver dust rising close to the avatar.
        local p=source("Silver dust",Vector3.new(2.5,3.4,1.8),CFrame.new(0,-.4,0))
        emit(p,95,.09,1.8,.35,Vector3.new(0,.15,0),true)
    elseif id=="InDev" then
        -- Amber horizontal scan bands, drifting in opposite directions.
        for i=1,3 do
            local p=source("Amber scan",Vector3.new(3.5,.12,2.2),CFrame.new(0,-1.8+i*.9,0),i%2==0 and .32 or -.32)
            local e=emit(p,55,.13,1.1,.18,Vector3.zero,true)
            e.EmissionDirection=Enum.NormalId.Right;e.SpreadAngle=Vector2.new(5,5)
        end
    elseif id=="Uncommon" then
        -- Green rising wisps in a broad soft shell.
        local p=source("Living green",Vector3.new(3.8,3,3),CFrame.new(0,-.8,0))
        local e=emit(p,155,.16,2.1,.65,Vector3.new(0,.25,0),true)
        e.Shape=Enum.ParticleEmitterShape.Ellipsoid;e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
        e.RotSpeed=NumberRange.new(-45,45)
    elseif id=="Rare" then
        -- Two intersecting blue orbital streams.
        orbit("Blue ascending arc",0,2,.85,CFrame.Angles(.8,0,0),115,.13)
        orbit("Blue crossing arc",0,2,-.85,CFrame.Angles(-.8,0,0),115,.13)
    elseif id=="SuperRare" then
        -- Cyan double helix, with moving emitters at staggered heights.
        for i=1,6 do
            orbit("Cyan helix",-2+(i-1)*.75,1.65,.7,CFrame.Angles(0,i*1.1,0),42,.12)
        end
    elseif id=="Epic" then
        -- A broad violet particle curtain behind the shoulders, no rods or wings.
        for _,side in {-1,1} do
            local p=source("Violet veil",Vector3.new(1.4,2.6,.45),CFrame.new(side*1.45,.45,1)*CFrame.Angles(0,0,-side*.4))
            local e=emit(p,130,.18,1.8,.4,Vector3.new(side*.12,.18,0),true)
            e.SpreadAngle=Vector2.new(35,35)
        end
    elseif id=="Lucky" then
        -- Green fountain with sparse gold flecks, not another orbit.
        local p=source("Lucky fountain",Vector3.new(2.8,.15,2.8),CFrame.new(0,-2.4,0))
        local e=emit(p,185,.12,2,2.3,Vector3.new(0,-1.5,0),false)
        e.SpreadAngle=Vector2.new(35,35)
        local gold=emit(p,42,.23,1.8,1.6,Vector3.new(0,-.9,0),false)
        gold.Color=ColorSequence.new(Color3.fromRGB(255,237,160),Color3.fromRGB(255,190,65))
    elseif id=="Legendary" then
        -- Radial golden sunburst behind the avatar.
        local p=source("Solar radiance",Vector3.new(.5,.5,.2),CFrame.new(0,.5,1.1),.2)
        for i=1,10 do
            local a=Instance.new("Attachment");local angle=i*math.pi*2/10
            a.CFrame=CFrame.new(math.cos(angle)*.8,math.sin(angle)*.8,0)*CFrame.Angles(0,0,angle-math.pi/2)
            a.Parent=p
            local e=emit(a,27,.16,1.4,1.35,Vector3.zero,true)
            e.SpreadAngle=Vector2.new(7,7)
        end
    elseif id=="Ice" then
        -- Snowfall from above, slow and cool, with a low counter-rotating frost current.
        local p=source("Snow canopy",Vector3.new(5,.2,4),CFrame.new(0,3,0))
        local e=emit(p,210,.15,3.2,.45,Vector3.new(0,-.25,0),false)
        e.EmissionDirection=Enum.NormalId.Bottom;e.SpreadAngle=Vector2.new(10,10)
        e.Color=ColorSequence.new(Color3.fromRGB(235,252,255),color)
        e.RotSpeed=NumberRange.new(-45,45)
        orbit("Ground frost",-2.2,2,-.38,nil,65,.1)
    end
    return model
end
return Visuals
