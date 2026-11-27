local CollectionService = game:GetService("CollectionService")
local Visuals = {}

function Visuals.Build(character, id, color)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local model = Instance.new("Model")
    model.Name = "AuraVisuals"
    model.Parent = character
    local white = Color3.fromRGB(229,245,255)
    local gold = Color3.fromRGB(255,201,86)
    local function pivot(name, offset, speed, axis)
        local p=Instance.new("Part");p.Name=name;p.Size=Vector3.new(.1,.1,.1)
        p.Transparency=1;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.CastShadow=false
        p.CFrame=root.CFrame*offset;p.Parent=model
        local weld=Instance.new("Motor6D");weld.Name="AuraOrbit";weld.Part0=root;weld.Part1=p
        weld.C0=offset;weld.Parent=p
        -- Tag every pivot, including wings: all visuals have idle motion.
        -- Set attributes before parenting/tagging; clients also retry streamed attributes.
        weld:SetAttribute("BaseOffset",offset)
        weld:SetAttribute("Speed",speed or 0)
        weld:SetAttribute("Axis",axis or "Y")
        weld:SetAttribute("Bob",name=="Crown wings" and .10 or .16)
        weld:SetAttribute("Sway",name=="Crown wings" and .09 or .025)
        CollectionService:AddTag(weld,"AuraOrbit")
        return p
    end
    local function piece(parent, name, size, cf, tint, transparency, shape, material)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=tint or color
        p.Material=material or Enum.Material.Neon;p.Transparency=transparency or .2
        p.Shape=shape or Enum.PartType.Block;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        p.CastShadow=false;p.Massless=true;p.CFrame=parent.CFrame*cf;p.Parent=model
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
        local w=Instance.new("WeldConstraint");w.Part0=parent;w.Part1=p;w.Parent=p
        return p
    end
    local function line(parent,a,b,width,tint,alpha)
        return piece(parent,"Light stroke",Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),tint,alpha)
    end
    local function ring(radius,height,tint,speed,tilt,thickness,alpha)
        local base=pivot("Orbit ring",CFrame.new(0,height,0)*(tilt or CFrame.identity),speed)
        local n=28
        for i=0,n-1 do
            local a=i*math.pi*2/n;local b=(i+1)*math.pi*2/n
            line(base,Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius),Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius),thickness or .045,tint,alpha or .25)
        end
        return base
    end
    local function shard(parent,cf,length,width,tint,alpha)
        return piece(parent,"Faceted shard",Vector3.new(width,length,width),cf*CFrame.Angles(0,math.pi/4,math.pi/8),tint,alpha)
    end
    local function orbiters(parent,radius,count,height,tint,size)
        for i=1,count do
            local a=i*math.pi*2/count
            piece(parent,"Orbiting gem",Vector3.new(size,size,size),CFrame.new(math.cos(a)*radius,height,math.sin(a)*radius)*CFrame.Angles(.4,a,.6),tint,.12)
        end
    end
    local function wings(tint,ice)
        local back=pivot("Crown wings",CFrame.new(0,.25,.65),0)
        for _,side in {-1,1} do
            for i=1,6 do
                local x=side*(.65+i*.44);local y=.35+i*.32
                local cf=CFrame.new(x,y,.15+i*.08)*CFrame.Angles(0,0,-side*(.38+i*.035))
                shard(back,cf,1.0+i*.30,.14+i*.012,tint,.18+(i%2)*.12)
                if ice then
                    shard(back,cf*CFrame.new(side*.18,-.32,.13),.8+i*.18,.09,white,.32)
                end
            end
        end
    end
    if id=="Common" then
        local circle=ring(1.65,-2.65,color,.2,nil,.035,.5)
        orbiters(circle,1.65,4,.08,color,.10)
    elseif id=="InDev" then
        local cube=pivot("Amber wireframe",CFrame.new(0,0,0),.35)
        local s=1.45
        for _,a in {-1,1} do for _,b in {-1,1} do
            line(cube,Vector3.new(-s,a*s,b*s),Vector3.new(s,a*s,b*s),.035,color,.4)
            line(cube,Vector3.new(a*s,-s,b*s),Vector3.new(a*s,s,b*s),.035,color,.4)
            line(cube,Vector3.new(a*s,b*s,-s),Vector3.new(a*s,b*s,s),.035,color,.4)
        end end
        ring(1.9,-2.6,color,-.25,nil,.04,.4)
    elseif id=="Uncommon" then
        local base=ring(2,-2.65,color,.35,nil,.045,.35)
        orbiters(base,2,6,.2,color,.15)
        local leaves=pivot("Leaf orbit",CFrame.new(0,-.7,0),-.5)
        for i=1,5 do
            local a=i*math.pi*2/5
            piece(leaves,"Leaf",Vector3.new(.17,.55,.13),CFrame.new(math.cos(a)*1.6,math.sin(a*2)*.45,math.sin(a)*1.6)*CFrame.Angles(.3,a,.7),color,.3)
        end
    elseif id=="Rare" then
        ring(2.25,-2.65,color,.35,nil,.06,.2)
        local outer=ring(2.1,0,color,-.5,CFrame.Angles(.4,0,.25),.045,.35)
        orbiters(outer,2.1,4,0,white,.18)
        local halo=ring(.8,2.35,white,.45,nil,.045,.25)
        orbiters(halo,.8,3,0,color,.12)
    elseif id=="SuperRare" then
        local one=ring(2.45,-.15,color,.55,CFrame.Angles(.8,0,.3),.055,.3)
        ring(2.45,-.15,white,-.45,CFrame.Angles(-.8,0,-.3),.035,.45)
        orbiters(one,2.45,6,0,color,.22)
        ring(2.6,-2.65,color,.2,nil,.07,.3)
    elseif id=="Epic" then
        wings(color,false)
        local base=ring(2.7,-2.65,color,.3,nil,.065,.2)
        orbiters(base,2.7,8,.1,color,.17)
        local crown=ring(.8,2.5,color,-.5,nil,.055,.2)
        for i=1,5 do local a=i*math.pi*2/5;shard(crown,CFrame.new(math.cos(a)*.8,.3,math.sin(a)*.8),.55,.11,white,.25) end
    elseif id=="Lucky" then
        local floor=ring(2.8,-2.65,color,.35,nil,.065,.22)
        orbiters(floor,2.8,8,.15,gold,.21)
        ring(2.45,-2.55,gold,-.3,nil,.035,.4)
        local charms=pivot("Lucky charms",CFrame.new(0,.45,0),.55)
        for i=1,4 do
            local a=i*math.pi/2;local cf=CFrame.new(math.cos(a)*2.15,math.sin(a*2)*.25,math.sin(a)*2.15)
            for _,v in {Vector3.new(.14,.13,0),Vector3.new(-.14,.13,0),Vector3.new(.14,-.13,0),Vector3.new(-.14,-.13,0)} do
                piece(charms,"Clover leaf",Vector3.new(.30,.30,.14),cf*CFrame.new(v),color,.22,Enum.PartType.Ball)
            end
            piece(charms,"Gold diamond",Vector3.new(.17,.17,.17),cf*CFrame.new(0,.65,0)*CFrame.Angles(0,0,math.pi/4),gold,.1)
        end
        ring(.95,2.6,gold,-.45,nil,.06,.25)
    elseif id=="Legendary" then
        wings(gold,false)
        local sun=pivot("Solar crown",CFrame.new(0,1.1,1.0)*CFrame.Angles(math.pi/2,0,0),.15)
        for i=1,16 do
            local a=i*math.pi*2/16;local radius=2.0
            local v=Vector3.new(math.cos(a),0,math.sin(a))
            line(sun,v*radius,v*(radius+(i%2==0 and .8 or .4)),.085,gold,.18)
        end
        ring(3,-2.65,gold,.3,nil,.07,.2)
        local halo=ring(1,2.85,gold,-.5,nil,.065,.12)
        orbiters(halo,1,8,.1,white,.14)
        ring(2.65,-2.54,white,-.25,nil,.035,.5)
    elseif id=="Ice" then
        wings(color,true)
        local base=ring(3.1,-2.65,color,.2,nil,.065,.3)
        for i=1,6 do
            local a=i*math.pi/3;local direction=Vector3.new(math.cos(a),0,math.sin(a))
            line(base,direction*.4,direction*2.8,.06,white,.35)
            local tip=direction*1.9;local side=Vector3.new(-direction.Z,0,direction.X)
            line(base,tip,tip-direction*.5+side*.4,.045,color,.25)
            line(base,tip,tip-direction*.5-side*.4,.045,color,.25)
        end
        local ice=pivot("Ice satellites",CFrame.new(0,0,0),-.35)
        for i=1,7 do local a=i*math.pi*2/7;shard(ice,CFrame.new(math.cos(a)*2.6,math.sin(a*2)*.55,math.sin(a)*2.6),.8,.18,color,.22) end
        local crown=ring(.9,2.8,color,.4,nil,.06,.18)
        for i=1,6 do local a=i*math.pi/3;shard(crown,CFrame.new(math.cos(a)*.9,.35,math.sin(a)*.9),.7,.11,white,.2) end
    end
    -- All contour points share one fixed rate budget; body effects are secondary.
    -- No stacked multipliers or cloned texture layers.
    local levels={Common=1,InDev=2,Uncommon=3,Rare=4,SuperRare=5,Epic=6,Lucky=7,Legendary=8,Ice=9}
    local level=levels[id] or 1
    local surfaces={}
    for _,part in model:GetChildren() do
        if part:IsA("BasePart") then
            if part.Transparency<.95 then table.insert(surfaces,part) end
            part.Transparency=1;part.CastShadow=false
        end
    end
    local function emitter(parent,rate,size,body)
        local e=Instance.new("ParticleEmitter");e.Name=body and "BodyRadiance" or "AuraShape"
        e.Texture="rbxasset://textures/particles/sparkles_main.dds"
        e.Color=ColorSequence.new(color,color:Lerp(white,.2))
        e.Enabled=true;e.Rate=rate;e.Lifetime=NumberRange.new(1.5,2)
        e.LightEmission=.1;e.LightInfluence=0
        e.Speed=body and NumberRange.new(.08,.22) or NumberRange.new(0)
        e.Acceleration=body and Vector3.new(0,.08,0) or Vector3.zero
        e.LockedToPart=true;e.SpreadAngle=Vector2.new(10,10)
        e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-8,8)
        e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*.3),NumberSequenceKeypoint.new(.15,size),NumberSequenceKeypoint.new(.8,size),NumberSequenceKeypoint.new(1,0)})
        e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.35),NumberSequenceKeypoint.new(.8,.35),NumberSequenceKeypoint.new(1,1)})
        e:SetAttribute("WarmCount",math.ceil(rate*1.5))
        e.Parent=parent
    end
    local count=#surfaces
    local budget=300+level*45
    for i=1,count do
        local part=surfaces[math.floor((i-1)*#surfaces/count)+1]
        -- Keep each particle source on the designed contour, not across a box volume.
        local attachment=Instance.new("Attachment")
        attachment.Name="ContourPoint";attachment.Parent=part
        emitter(attachment,budget/count,({.10,.13,.16})[(i-1)%3+1],false)
    end
    local limbs={}
    for _,name in {"Torso","UpperTorso","Left Arm","Right Arm","Left Leg","Right Leg","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"} do
        local limb=character:FindFirstChild(name)
        if limb and limb:IsA("BasePart") then table.insert(limbs,limb) end
    end
    for i,limb in limbs do
        local holder=Instance.new("Part");holder.Name="BodyParticleAnchor"
        holder.Size=limb.Size;holder.Transparency=1;holder.CanCollide=false
        holder.CanTouch=false;holder.CanQuery=false;holder.Massless=true;holder.CastShadow=false
        holder.CFrame=limb.CFrame;holder.Parent=model
        local weld=Instance.new("WeldConstraint");weld.Part0=limb;weld.Part1=holder;weld.Parent=holder
        emitter(holder,(25+level*4)/math.max(1,#limbs),i%2==0 and .12 or .2,true)
    end
    return model
end
return Visuals
