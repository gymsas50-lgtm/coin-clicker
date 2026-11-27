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
        weld:SetAttribute("BaseOffset",offset)
        weld:SetAttribute("Speed",speed or 0)
        weld:SetAttribute("Axis",axis or "Y")
        weld:SetAttribute("Bob",name=="Crown wings" and .08 or .06)
        weld:SetAttribute("Sway",name=="Crown wings" and .055 or .015)
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
        local n=48
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
    -- New sculpted collection: each tier has a distinct silhouette.
    local function polygon(parent,radius,y,n,tint,width,phase)
        phase=phase or 0
        for i=1,n do
            local a=(i-1)*math.pi*2/n+phase;local b=i*math.pi*2/n+phase
            line(parent,Vector3.new(math.cos(a)*radius,y,math.sin(a)*radius),Vector3.new(math.cos(b)*radius,y,math.sin(b)*radius),width or .05,tint,.22)
        end
    end
    local function diamond(parent,cf,size,tint)
        local points={Vector3.new(0,size,0),Vector3.new(size*.45,0,0),Vector3.new(0,0,size*.45),Vector3.new(-size*.45,0,0),Vector3.new(0,0,-size*.45),Vector3.new(0,-size,0)}
        for i=2,5 do
            local j=i==5 and 2 or i+1
            line(parent,cf:PointToWorldSpace(points[1]),cf:PointToWorldSpace(points[i]),.045,tint,.15)
            line(parent,cf:PointToWorldSpace(points[6]),cf:PointToWorldSpace(points[i]),.045,tint,.15)
            line(parent,cf:PointToWorldSpace(points[i]),cf:PointToWorldSpace(points[j]),.035,tint,.3)
        end
        piece(parent,"Crystal heart",Vector3.new(size*.24,size*.8,size*.24),cf*CFrame.Angles(0,math.pi/4,0),tint,.35)
    end
    if id=="Common" then
        -- Four separated floating silver corner brackets, no full ring.
        local base=pivot("Silver brackets",CFrame.new(0,-2.4,0),.16)
        for i=1,4 do
            local a=i*math.pi/2+math.pi/4
            local center=Vector3.new(math.cos(a)*1.65,0,math.sin(a)*1.65)
            local tangent=Vector3.new(-math.sin(a),0,math.cos(a))
            line(base,center-tangent*.30,center+tangent*.30,.065,color,.3)
            line(base,center,center+Vector3.new(0,.25,0),.05,white,.4)
        end
    elseif id=="InDev" then
        -- Open amber gyroscope made of broken rectangular frames.
        for i=1,2 do
            local frame=pivot("Amber broken frame",CFrame.new(0,0,0)*CFrame.Angles(.35*i,0,(i==1 and .6 or -.6)),i==1 and .24 or -.2)
            local r=1.7+i*.16
            for _,side in {-1,1} do
                line(frame,Vector3.new(side*r,-1.2,0),Vector3.new(side*r,1.2,0),.055,color,.27)
                line(frame,Vector3.new(side*r,1.2,0),Vector3.new(side*.55,1.2,0),.055,white,.4)
                line(frame,Vector3.new(side*r,-1.2,0),Vector3.new(side*.55,-1.2,0),.055,color,.3)
            end
        end
    elseif id=="Uncommon" then
        -- A growing emerald double vine wrapping upward, with sculpted leaves.
        local vine=pivot("Emerald vines",CFrame.identity,.19)
        for branch=0,1 do
            for j=1,20 do
                local a=(j-1)/20*math.pi*2+branch*math.pi
                local b=j/20*math.pi*2+branch*math.pi
                local y=-2.4+(j-1)*.19
                local v=Vector3.new(math.cos(a)*1.7,y,math.sin(a)*1.7)
                local nextV=Vector3.new(math.cos(b)*1.7,y+.19,math.sin(b)*1.7)
                line(vine,v,nextV,.045,color,.3)
                if j%5==0 then
                    piece(vine,"Emerald leaf",Vector3.new(.13,.55,.27),CFrame.new(v)*CFrame.Angles(.4,a,.65),color,.22)
                end
            end
        end
    elseif id=="Rare" then
        -- A blue compass astrolabe behind the shoulders and four satellite needles.
        local compass=pivot("Azure compass",CFrame.new(0,.55,1)*CFrame.Angles(math.pi/2,0,0),.20)
        polygon(compass,1.85,0,8,color,.055)
        polygon(compass,1.58,0,8,white,.025,math.pi/8)
        for i=1,4 do
            local a=i*math.pi/2
            diamond(compass,CFrame.new(math.cos(a)*2.1,0,math.sin(a)*2.1)*CFrame.Angles(0,0,math.pi/2),.35,color)
        end
    elseif id=="SuperRare" then
        -- Cyan floating obelisks above a triangular energy seal.
        local temple=pivot("Cyan obelisks",CFrame.new(0,-.6,0),-.22)
        for i=1,3 do
            local a=i*math.pi*2/3
            diamond(temple,CFrame.new(math.cos(a)*2.05,math.sin(a)*.2,math.sin(a)*2.05),.9,color)
        end
        local seal=pivot("Triangular seal",CFrame.new(0,-2.55,0),.18)
        polygon(seal,2.5,0,3,color,.065)
        polygon(seal,2.1,.05,3,white,.03,math.pi)
    elseif id=="Epic" then
        -- A violet crescent throne: sweeping ribs, not feather/pole wings.
        local throne=pivot("Amethyst crescent",CFrame.new(0,.1,1.05),0)
        for _,side in {-1,1} do
            for rib=1,3 do
                local radius=1.55+rib*.38
                local previous
                for j=0,16 do
                    local a=-.75+j/16*2.1
                    local v=Vector3.new(side*(.25+math.cos(a)*radius),math.sin(a)*radius*.95,.15+rib*.1)
                    if previous then line(throne,previous,v,rib==3 and .075 or .035,rib==2 and white or color,.24) end
                    previous=v
                end
            end
            diamond(throne,CFrame.new(side*2.3,1.5,.4),.45,color)
        end
        local sigil=pivot("Amethyst star seal",CFrame.new(0,-2.5,0),-.15)
        polygon(sigil,2.45,0,3,color,.045)
        polygon(sigil,2.45,0,3,color,.045,math.pi)
    elseif id=="Lucky" then
        -- Four sculpted clover hearts orbit an emerald/gold coin constellation.
        local luck=pivot("Fortune constellation",CFrame.new(0,.2,0),.27)
        for i=1,4 do
            local a=i*math.pi/2
            local center=Vector3.new(math.cos(a)*2.25,math.sin(a)*.35,math.sin(a)*2.25)
            for petal=1,4 do
                local t=petal*math.pi/2
                piece(luck,"Clover petal",Vector3.new(.3,.3,.13),CFrame.new(center+Vector3.new(math.cos(t)*.20,math.sin(t)*.20,0)),color,.15,Enum.PartType.Ball)
            end
            line(luck,center,center+Vector3.new(-.15,-.65,0),.04,gold,.18)
            diamond(luck,CFrame.new(center+Vector3.new(0,.8,0)),.2,gold)
        end
        local seal=pivot("Fortune square",CFrame.new(0,-2.5,0),-.18)
        polygon(seal,2.5,0,4,gold,.055,math.pi/4)
        polygon(seal,2.1,.06,4,color,.045)
    elseif id=="Legendary" then
        -- A layered solar cathedral with tapering rays and suspended gold prisms.
        local sun=pivot("Solar cathedral",CFrame.new(0,.65,1.2)*CFrame.Angles(math.pi/2,0,0),.10)
        polygon(sun,2.05,0,12,gold,.065)
        polygon(sun,1.7,0,12,white,.025,math.pi/12)
        for i=1,12 do
            local a=i*math.pi/6
            local dir=Vector3.new(math.cos(a),0,math.sin(a));local tangent=Vector3.new(-dir.Z,0,dir.X)
            local start=dir*2.05;local tip=dir*(i%2==0 and 3.0 or 2.6)
            line(sun,start-tangent*.13,tip,.045,gold,.2)
            line(sun,start+tangent*.13,tip,.045,gold,.2)
        end
        local gems=pivot("Royal prisms",CFrame.new(0,-.6,0),-.20)
        for i=1,4 do local a=i*math.pi/2;diamond(gems,CFrame.new(math.cos(a)*2.4,0,math.sin(a)*2.4),.65,gold) end
        local floor=pivot("Royal seal",CFrame.new(0,-2.55,0),.12)
        polygon(floor,2.9,0,6,gold,.06);polygon(floor,2.55,.05,6,white,.03,math.pi/6)
    elseif id=="Ice" then
        -- Six branching frost antlers, a suspended snow jewel and a snowflake seal.
        local frost=pivot("Frost antlers",CFrame.new(0,.35,1.15),0)
        for _,side in {-1,1} do
            for k=1,3 do
                local base=Vector3.new(side*.65,-.45,.1*k)
                local tip=Vector3.new(side*(1.3+k*.55),1.3+k*.4,.15*k)
                line(frost,base,tip,.06,color,.23)
                local delta=tip-base
                for j=1,3 do
                    local v=base+delta*(.25+j*.16)
                    line(frost,v,v+Vector3.new(side*.4,.25,0),.035,white,.25)
                    line(frost,v,v+Vector3.new(-side*.16,.45,0),.035,color,.25)
                end
            end
        end
        local jewel=pivot("Frozen heart",CFrame.new(0,2.8,0),.23)
        diamond(jewel,CFrame.identity,.7,white)
        local snow=pivot("Snowflake seal",CFrame.new(0,-2.55,0),-.12)
        for i=1,6 do
            local a=i*math.pi/3;local dir=Vector3.new(math.cos(a),0,math.sin(a));local side=Vector3.new(-dir.Z,0,dir.X)
            line(snow,dir*.3,dir*2.9,.055,color,.25)
            for j=1,2 do local v=dir*(1+j*.65);line(snow,v,v-dir*.4+side*.4,.035,white,.3);line(snow,v,v-dir*.4-side*.4,.035,white,.3) end
        end
    end
    -- Secondary detail layer complements the existing silhouettes.
    local ranks={Common=1,InDev=2,Uncommon=3,Rare=4,SuperRare=5,Epic=6,Lucky=7,Legendary=8,Ice=9}
    local rank=ranks[id] or 1
    local accents={Common=white,InDev=white,Uncommon=Color3.fromRGB(203,255,168),Rare=white,SuperRare=white,Epic=Color3.fromRGB(235,182,255),Lucky=gold,Legendary=white,Ice=white}
    local accent=accents[id] or white
    if rank>=2 then
        local detail=pivot("Floating detail gems",CFrame.new(0,-1.5,0),-.12-rank*.008)
        local count=rank>=6 and 8 or 4
        for i=1,count do
            local a=i*math.pi*2/count
            local pos=Vector3.new(math.cos(a)*(1.8+rank*.07),math.sin(a*2)*.18,math.sin(a)*(1.8+rank*.07))
            diamond(detail,CFrame.new(pos),.10+rank*.008,i%2==0 and accent or color)
        end
    end
    -- Add tiny end caps to a distributed selection of strokes, not every edge.
    local strokes={}
    for _,part in model:GetChildren() do
        if part:IsA("BasePart") and part.Name=="Light stroke" then table.insert(strokes,part) end
    end
    local capCount=math.min(#strokes,4+rank*2)
    for i=1,capCount do
        local part=strokes[math.floor((i-1)*#strokes/capCount)+1]
        piece(part,"Luminous inlay",Vector3.new(.09,.09,.09),CFrame.new(0,0,part.Size.Z*.5),accent,.18,Enum.PartType.Ball)
    end
    local function motes(parent,rate,size,body)
        local e=Instance.new("ParticleEmitter");e.Name=body and "BodyMotes" or "ObjectMotes"
        e.Texture="rbxasset://textures/particles/sparkles_main.dds"
        e.Color=ColorSequence.new(accent,color);e.LightEmission=.8;e.LightInfluence=0;e.Brightness=1.1
        e.Rate=rate*1.5;e.Lifetime=NumberRange.new(.9,1.6)
        e.Speed=body and NumberRange.new(.15,.4) or NumberRange.new(.025,.12)
        e.Acceleration=Vector3.new(0,body and .18 or .07,0)
        e.SpreadAngle=Vector2.new(40,40);e.LockedToPart=not body
        e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-15,15)
        e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.2,size,size*.25),NumberSequenceKeypoint.new(.7,size*.6),NumberSequenceKeypoint.new(1,0)})
        e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.35),NumberSequenceKeypoint.new(.7,.65),NumberSequenceKeypoint.new(1,1)})
        e:SetAttribute("WarmCount",math.ceil(rate*1.5));e.Parent=parent
        -- Additional small soft motes: same tint, different silhouette, no large smoke clouds.
        local soft=e:Clone();soft.Name="SoftLightDots"
        soft.Texture="rbxasset://textures/particles/sparkles_main.dds"
        soft.Rate=rate*.85
        soft.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.2,size*.85,size*.2),NumberSequenceKeypoint.new(.65,size*.6),NumberSequenceKeypoint.new(1,0)})
        soft.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.25),NumberSequenceKeypoint.new(.7,.6),NumberSequenceKeypoint.new(1,1)})
        soft:SetAttribute("WarmCount",math.ceil(rate*.85));soft.Parent=parent
        local large=e:Clone();large.Name="LargerGlints";large.Rate=rate*.25
        large.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.25,size*1.8,size*.3),NumberSequenceKeypoint.new(.7,size),NumberSequenceKeypoint.new(1,0)})
        large.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.5),NumberSequenceKeypoint.new(.75,.7),NumberSequenceKeypoint.new(1,1)})
        large:SetAttribute("WarmCount",math.ceil(rate*.25));large.Parent=parent
    end
    -- Visible emission from the complete object silhouette, including leaves/gems.
    local objects={}
    for _,part in model:GetChildren() do
        if part:IsA("BasePart") and part.Transparency<.95 then table.insert(objects,part) end
    end
    -- Cover every visible part; Box/Surface distributes emission over its full size.
    local totalArea=0
    for _,part in objects do
        local v=part.Size
        totalArea+=2*(v.X*v.Y+v.Y*v.Z+v.X*v.Z)
    end
    local objectBudget=420+rank*65
    for _,part in objects do
        local v=part.Size
        local area=2*(v.X*v.Y+v.Y*v.Z+v.X*v.Z)
        local rate=math.max(1.2,objectBudget*area/math.max(.01,totalArea)/2.6)
        motes(part,rate,.13,false)
        for _,emitter in part:GetChildren() do
            if emitter:IsA("ParticleEmitter") then
                emitter.Shape=Enum.ParticleEmitterShape.Box
                emitter.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
                emitter.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
                emitter.LockedToPart=false
                emitter.Speed=NumberRange.new(.12,.32)
                emitter.Acceleration=Vector3.new(0,.12,0)
                emitter.SpreadAngle=Vector2.new(180,180)
                emitter.LightEmission=1;emitter.Brightness=1.7
            end
        end
    end
    local body=pivot("Body particle envelope",CFrame.new(0,-.5,0),0)
    body.Size=Vector3.new(2.8,3.5,2)
    motes(body,22+rank*4,.095,true)
    local e=body:FindFirstChildOfClass("ParticleEmitter")
    e.Shape=Enum.ParticleEmitterShape.Ellipsoid
    e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
    return model
end
return Visuals
