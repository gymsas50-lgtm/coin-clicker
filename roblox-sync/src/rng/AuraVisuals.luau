local CollectionService=game:GetService("CollectionService")
local Visuals={}
local styles={
    Common={level=1,speed=.28,radius=1.2},
    InDev={level=2,speed=.38,radius=1.4},
    Uncommon={level=3,speed=.32,radius=1.55},
    Rare={level=4,speed=.45,radius=1.7},
    SuperRare={level=5,speed=.52,radius=1.85},
    Epic={level=6,speed=.42,radius=2.0},
    Lucky={level=7,speed=.58,radius=2.05},
    Legendary={level=8,speed=.38,radius=2.2},
    Ice={level=9,speed=.30,radius=2.3},
}
function Visuals.Build(character,id,color)
    local root=character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local model=Instance.new("Model");model.Name="AuraVisuals";model.Parent=character
    local style=styles[id] or styles.Common
    local level=style.level
    local pale=color:Lerp(Color3.new(1,1,1),.38)
    local function anchor(name,size,offset,speed)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Transparency=1
        p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.CastShadow=false
        p.CFrame=root.CFrame*offset;p.Parent=model
        local motor=Instance.new("Motor6D");motor.Part0=root;motor.Part1=p;motor.C0=offset
        motor:SetAttribute("BaseOffset",offset);motor:SetAttribute("Speed",speed or 0)
        motor:SetAttribute("Bob",.12);motor:SetAttribute("Sway",.035)
        motor.Parent=p;CollectionService:AddTag(motor,"AuraOrbit")
        return p
    end
    local function particles(parent,name,rate,size,lifetime,locked)
        local e=Instance.new("ParticleEmitter");e.Name=name
        e.Texture="rbxasset://textures/particles/sparkles_main.dds"
        e.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,pale),ColorSequenceKeypoint.new(.4,color),ColorSequenceKeypoint.new(1,color:Lerp(pale,.25))})
        e.LightEmission=1;e.LightInfluence=0;e.Brightness=1.6
        e.Rate=rate;e.Lifetime=NumberRange.new(lifetime*.75,lifetime)
        e.LockedToPart=locked;e.VelocityInheritance=0
        e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-18,18)
        e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*.2),NumberSequenceKeypoint.new(.2,size,size*.3),NumberSequenceKeypoint.new(.65,size*.7,size*.2),NumberSequenceKeypoint.new(1,0)})
        e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,.25),NumberSequenceKeypoint.new(.6,.45),NumberSequenceKeypoint.new(1,1)})
        e.Speed=NumberRange.new(.15,.45);e.SpreadAngle=Vector2.new(30,30)
        e.Acceleration=Vector3.new(0,.35,0);e.Drag=.5
        e:SetAttribute("WarmCount",math.ceil(rate*lifetime*.6))
        e.Parent=parent;return e
    end
    -- Deliberate symmetric accents: a readable silhouette beneath the motes.
    local function rod(parent,a,b,width,tint)
        local p=Instance.new("Part");p.Name="Luminous accent"
        p.Size=Vector3.new(width,width,(b-a).Magnitude)
        p.Material=Enum.Material.Neon;p.Color=tint;p.Transparency=.28
        p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.CastShadow=false
        p.CFrame=parent.CFrame*CFrame.lookAt((a+b)*.5,b);p.Parent=model
        local w=Instance.new("WeldConstraint");w.Part0=parent;w.Part1=p;w.Parent=p
    end
    local function arc(parent,radius,startAngle,endAngle,height,tint)
        local segments=12
        for j=1,segments do
            local a=startAngle+(endAngle-startAngle)*(j-1)/segments
            local b=startAngle+(endAngle-startAngle)*j/segments
            rod(parent,Vector3.new(math.cos(a)*radius,height,math.sin(a)*radius),Vector3.new(math.cos(b)*radius,height,math.sin(b)*radius),.035,tint)
        end
    end
    local accents=anchor("Sculpted accents",Vector3.new(.1,.1,.1),CFrame.new(0,-1.9,0),style.speed*.35)
    for i=0,2 do
        local start=i*math.pi*2/3
        arc(accents,style.radius+.15,start,start+math.pi*.43,0,color)
    end
    if level>=3 then
        local satellites=anchor("Crystal orbit",Vector3.new(.1,.1,.1),CFrame.new(0,.1,0),-style.speed*.45)
        local count=level>=7 and 6 or 4
        for i=1,count do
            local a=i*math.pi*2/count
            local center=Vector3.new(math.cos(a)*(style.radius+.25),math.sin(a*2)*.25,math.sin(a)*(style.radius+.25))
            local h=.20+level*.025
            local x=Vector3.new(.13,0,0);local y=Vector3.new(0,h,0)
            rod(satellites,center+y,center+x,.045,pale)
            rod(satellites,center+x,center-y,.045,color)
            rod(satellites,center-y,center-x,.045,color)
            rod(satellites,center-x,center+y,.045,pale)
        end
    end
    if level>=6 then
        -- A compact fan behind the shoulders, with graduated lengths and clear gaps.
        local back=anchor("Radiant fan",Vector3.new(.1,.1,.1),CFrame.new(0,.2,1),0)
        for _,side in {-1,1} do
            for j=1,4 do
                local base=Vector3.new(side*(.75+j*.28),-.3+j*.10,.1+j*.10)
                local tip=base+Vector3.new(side*(.25+j*.10),.65+j*.25,.12)
                rod(back,base,tip,.045+j*.005,j%2==0 and pale or color)
            end
        end
        local crown=anchor("Crown arcs",Vector3.new(.1,.1,.1),CFrame.new(0,2.55,0),style.speed*.3)
        for i=0,2 do
            local a=i*math.pi*2/3
            arc(crown,.65,a,a+1.4,0,pale)
        end
    end
    -- A soft moving volume around the avatar, never a dotted wireframe.
    local core=anchor("Living energy",Vector3.new(3.4,4.2,2.8),CFrame.new(0,-.4,0),0)
    local dust=particles(core,"Fine energy",65+level*9,.075,1.8,true)
    dust.Shape=Enum.ParticleEmitterShape.Ellipsoid;dust.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
    dust.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
    dust.Speed=NumberRange.new(.08,.24)
    dust.Acceleration=Vector3.new(0,.22,0)
    local sparks=particles(core,"Bright accents",10+level*2,.17,1.3,true)
    sparks.Shape=Enum.ParticleEmitterShape.Ellipsoid
    sparks.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
    sparks.Speed=NumberRange.new(.08,.25)
    sparks.Color=ColorSequence.new(pale,color)
    sparks.Rate=8+level
    sparks.Lifetime=NumberRange.new(1.1,1.7)
    -- Larger, sparse luminous flecks add depth without hiding the avatar.
    local flecks=particles(core,"Floating highlights",5+level,.23,2.2,true)
    flecks.Shape=Enum.ParticleEmitterShape.Ellipsoid
    flecks.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
    flecks.Speed=NumberRange.new(.04,.14)
    flecks.Acceleration=Vector3.new(0,.12,0)
    flecks.Brightness=1.2
    flecks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.3,.20,.06),NumberSequenceKeypoint.new(.7,.14,.04),NumberSequenceKeypoint.new(1,0)})
    flecks.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.55),NumberSequenceKeypoint.new(.7,.65),NumberSequenceKeypoint.new(1,1)})
    -- Continuous arcing streams: hidden rotating parents carry offset emission points.
    local streams=2+math.floor(level/3)
    for i=1,streams do
        local direction=i%2==0 and -1 or 1
        local tilt=CFrame.Angles((i%3-1)*.32,0,(i%2==0 and .25 or -.25))
        local height=-1.65+(i-1)*(.95)
        local orbit=anchor("Energy current",Vector3.new(.1,.1,.1),CFrame.new(0,height,0)*tilt,style.speed*direction)
        local attachment=Instance.new("Attachment");attachment.Position=Vector3.new(style.radius,0,0);attachment.Parent=orbit
        local e=particles(attachment,"Flowing arc",45+level*4,.12,1.1,false)
        e.Speed=NumberRange.new(.06,.18);e.Acceleration=Vector3.new(0,.18,0)
        e.SpreadAngle=Vector2.new(180,180)
        if id=="Lucky" then e.Color=ColorSequence.new(color,Color3.fromRGB(255,218,110)) end
        if id=="Ice" then e.Color=ColorSequence.new(Color3.fromRGB(225,250,255),color) end
    end
    -- Restrained floating afterglow at the feet, not a solid drawn circle.
    local ground=anchor("Ground motes",Vector3.new(3.3+level*.08,.15,3.3+level*.08),CFrame.new(0,-2.5,0),-.12)
    local haze=particles(ground,"Rising motes",24+level*4,.11,2,false)
    haze.Shape=Enum.ParticleEmitterShape.Box;haze.Speed=NumberRange.new(.15,.45)
    haze.Acceleration=Vector3.new(0,.2,0)
    -- Short body trail follows motion naturally without leaving long stale clouds.
    if level>=4 then
        local trail=particles(core,"Motion glints",16+level*2,.09,.7,false)
        trail.Speed=NumberRange.new(0,.1);trail.Acceleration=Vector3.zero
    end
    return model
end
return Visuals
