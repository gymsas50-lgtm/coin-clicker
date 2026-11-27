local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local folder=ReplicatedStorage:WaitForChild("Reactor")
local C=require(folder:WaitForChild("Config"))
local action=folder:WaitForChild("Action")
local update=folder:WaitForChild("Update")
local world=workspace:WaitForChild("ReactorWorld")
world:ClearAllChildren() -- Remove previous runtime bays if Studio restarts the script.
local states,plots={},{}
local store
if not RunService:IsStudio() then
    local ok,value=pcall(function() return DataStoreService:GetDataStore("ReactorWorks_v1") end)
    if ok then store=value end
end
local function part(parent,name,size,cf,color,material)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color
    p.Anchored=true;p.Material=material or Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs
    p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local colors={dark=Color3.fromRGB(32,40,47),steel=Color3.fromRGB(79,93,106),white=Color3.fromRGB(220,233,240),cyan=Color3.fromRGB(94,219,221)}
local function sign(parent,adornee,value,offset,width,height)
    local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(width or 230,height or 60)
    gui.StudsOffsetWorldSpace=offset or Vector3.new(0,3,0);gui.MaxDistance=100;gui.AlwaysOnTop=false
    gui.Adornee=adornee;gui.Parent=parent
    local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1
    l.Text=value;l.Font=Enum.Font.GothamBold;l.TextSize=17;l.TextColor3=colors.white
    l.TextStrokeTransparency=.35;l.Parent=gui;return l
end
local function prompt(p,label,key,callback)
    local pr=Instance.new("ProximityPrompt");pr.ActionText=label;pr.ObjectText=key
    pr.HoldDuration=.25;pr.MaxActivationDistance=12;pr.RequiresLineOfSight=false;pr.Parent=p
    pr.Triggered:Connect(callback);return pr
end
local function cellPosition(plot,x,z) return plot.center+Vector3.new((x-4)*C.Cell,.9,(z-4)*C.Cell) end
local function key(x,z) return tostring(x)..":"..tostring(z) end
local paintTile
local function modelFor(plot,x,z,id,animate)
    local m=Instance.new("Model");m.Name="Module_"..key(x,z);m.Parent=plot.modules
    local def=C.ById[id];local at=cellPosition(plot,x,z)
    local function b(name,size,offset,color,material)
        return part(m,name,size,CFrame.new(at+offset),color,material)
    end
    b("Footing",Vector3.new(2.5,.3,2.5),Vector3.new(0,.2,0),colors.steel)
    b("Trim",Vector3.new(2.25,.12,2.25),Vector3.new(0,.4,0),def.Color)
    if id=="Fuel" or id=="Fusion" then
        local count=id=="Fuel" and 3 or 5
        for i=1,count do
            local a=i*math.pi*2/count;local r=id=="Fuel" and .6 or .72
            b("Containment",Vector3.new(.48,1.45,.48),Vector3.new(math.cos(a)*r,1.15,math.sin(a)*r),colors.dark)
            b("Luminous rod",Vector3.new(.20,1.1,.20),Vector3.new(math.cos(a)*r,1.25,math.sin(a)*r),def.Color,Enum.Material.Neon)
        end
        b("Top plate",Vector3.new(2,.22,2),Vector3.new(0,2,0),colors.steel)
        if id=="Fusion" then b("Fusion heart",Vector3.new(.6,1.8,.6),Vector3.new(0,1.35,0),colors.white,Enum.Material.Neon) end
    elseif id=="Cooler" or id=="Vent" then
        b("Tank",Vector3.new(1.65,.8,1.65),Vector3.new(0,.95,0),colors.dark)
        for i=-2,2 do b("Radiator fin",Vector3.new(.14,.75,1.9),Vector3.new(i*.36,1.4,0),def.Color) end
        if id=="Vent" then
            b("Chimney",Vector3.new(.6,1,.6),Vector3.new(.5,1.8,.4),colors.steel)
            b("Vent cap",Vector3.new(.8,.12,.8),Vector3.new(.5,2.35,.4),colors.white)
        end
    elseif id=="Turbine" then
        b("Housing",Vector3.new(1.65,.6,1.65),Vector3.new(0,.85,0),colors.dark)
        local rotor=b("Rotor",Vector3.new(1.9,.14,.25),Vector3.new(0,1.35,0),def.Color)
        local rotor2=b("RotorCross",Vector3.new(.25,.14,1.9),Vector3.new(0,1.35,0),def.Color)
        rotor:SetAttribute("ReactorRotor",true);rotor2:SetAttribute("ReactorRotor",true)
        b("Hub",Vector3.new(.45,.28,.45),Vector3.new(0,1.45,0),colors.white)
    elseif id=="Battery" then
        for i=-1,1 do
            b("Power bank",Vector3.new(.55,1.35,1.35),Vector3.new(i*.65,1.1,0),colors.dark)
            b("Charge stripe",Vector3.new(.3,.8,.08),Vector3.new(i*.65,1.15,.72),def.Color,Enum.Material.Neon)
        end
    elseif id=="Lab" then
        b("Console",Vector3.new(1.9,.9,1.3),Vector3.new(0,.95,0),colors.dark)
        b("Screen",Vector3.new(1.3,.7,.1),Vector3.new(0,1.7,0),def.Color,Enum.Material.Neon)
        for i=-1,1 do b("Sample",Vector3.new(.25,.65,.25),Vector3.new(i*.65,1.5,.55),colors.white) end
    elseif id=="Breeder" then
        b("Machine",Vector3.new(1.8,1.4,1.8),Vector3.new(0,1.2,0),colors.dark)
        for i=-1,1 do b("Refining tube",Vector3.new(.4,1.2,.4),Vector3.new(i*.55,1.5,0),def.Color,Enum.Material.Neon) end
        b("Pipe",Vector3.new(1.7,.25,.25),Vector3.new(0,2.2,0),colors.white)
    end
    for _,p in m:GetChildren() do
        if p:IsA("BasePart") then
            p:SetAttribute("PlotIndex",plot.index);p:SetAttribute("GridX",x);p:SetAttribute("GridZ",z)
            local cd=Instance.new("ClickDetector");cd.MaxActivationDistance=45;cd.Parent=p
            cd.MouseClick:Connect(function(player) if plot.owner==player then paintTile(player,x,z) end end)
        end
    end
    if animate then
        for _,p in m:GetChildren() do
            if p:IsA("BasePart") then
                local target=p.CFrame;p.CFrame=target+Vector3.new(0,1.2,0);p.Transparency=.7
                TweenService:Create(p,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=target,Transparency=0}):Play()
            end
        end
    end
end
local function fresh()
    return {credits=240,ore=38,fuel=35,energy=0,heat=0,rp=0,generated=0,earned=0,online=false,autoSell=true,
        upgrades={Efficiency=0,Cooling=0,Drill=0,Safety=0},unlocked={Fuel=true,Cooler=true,Turbine=true,Battery=true},
        grid={[key(4,4)]="Fuel",[key(3,4)]="Cooler",[key(5,4)]="Cooler",[key(4,5)]="Turbine"},
        quests={},selected="Cooler",power=0,heatRate=0,capacity=250,cooldown=0,status="Starter layout ready. Press START.",saveStatus=RunService:IsStudio() and "STUDIO: SESSION ONLY" or "LOADING",lastMine=0,lastAction=0}
end
local function payload(s)
    return {Credits=s.credits,Ore=s.ore,Fuel=s.fuel,Energy=s.energy,Heat=s.heat,RP=s.rp,Generated=s.generated,
        Online=s.online,AutoSell=s.autoSell,Upgrades=s.upgrades,Unlocked=s.unlocked,Grid=s.grid,Quests=s.quests,
        Selected=s.selected,Power=s.power,HeatRate=s.heatRate,Capacity=s.capacity,Status=s.status,SaveStatus=s.saveStatus,
        Cooldown=s.cooldown,Plot=s.plot.index}
end
local function send(player,s,message)
    if message then s.status=message end
    if player.Parent then update:FireClient(player,payload(s)) end
end
local function save(player,s)
    if not store or s.saving or not s.loaded then return end
    s.saving=true
    local data={credits=s.credits,ore=s.ore,fuel=s.fuel,energy=s.energy,rp=s.rp,generated=s.generated,earned=s.earned,
        upgrades=table.clone(s.upgrades),unlocked=table.clone(s.unlocked),grid=table.clone(s.grid),quests=table.clone(s.quests),version=1}
    local ok=pcall(function() store:SetAsync("u"..player.UserId,data) end)
    s.saving=false;s.saveStatus=ok and "SAVED" or "SAVE UNAVAILABLE";send(player,s)
end
local function load(player,s)
    if not store then s.loaded=true;return end
    local ok,data=pcall(function() return store:GetAsync("u"..player.UserId) end)
    if ok and type(data)=="table" and data.version==1 then
        for _,field in {"credits","ore","fuel","energy","rp","generated","earned"} do
            if type(data[field])=="number" and data[field]>=0 and data[field]<1e15 then s[field]=data[field] end
        end
        for id in s.upgrades do
            local value=data.upgrades and data.upgrades[id]
            if type(value)=="number" then
                local max=5;if id=="Safety" then max=1 end
                s.upgrades[id]=math.clamp(math.floor(value),0,max)
            end
        end
        if type(data.unlocked)=="table" then for id in C.ById do if data.unlocked[id]==true then s.unlocked[id]=true end end end
        if type(data.quests)=="table" then for _,q in C.Quests do if data.quests[q.Id]==true then s.quests[q.Id]=true end end end
        if type(data.grid)=="table" then
            s.grid={}
            for x=1,7 do for z=1,7 do local k=key(x,z);local id=data.grid[k];if C.ById[id] and s.unlocked[id] then s.grid[k]=id end end end
        end
    end
    s.loaded=true;s.saveStatus=ok and "AUTOSAVE ON" or "SAVE UNAVAILABLE"
    if not ok then s.status="Save service unavailable. This session will not overwrite your save.";s.loaded=false end
end
local function capacity(s)
    local value=250
    for _,id in s.grid do if id=="Battery" then value+=250 end end
    return value
end
local function neighbors(s,x,z,id)
    local count=0
    for _,d in {{1,0},{-1,0},{0,1},{0,-1}} do if s.grid[key(x+d[1],z+d[2])]==id then count+=1 end end
    return count
end
paintTile=function(player,x,z)
    local s=states[player];if not s or not s.ready then return end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position-s.plot.center).Magnitude>55 then return end
    if os.clock()-s.lastAction<.08 then return end;s.lastAction=os.clock()
    if s.online then send(player,s,"STOP reactor before changing the layout.");return end
    if s.heat>60 then send(player,s,"Wait until heat is below 60 before building.");return end
    local k=key(x,z);local existing=s.grid[k]
    if s.selected=="Remove" then
        if not existing then return end
        local def=C.ById[existing];s.credits+=math.floor(def.Cost*.6);s.ore+=math.floor(def.Ore*.6);s.grid[k]=nil
        local old=s.plot.modules:FindFirstChild("Module_"..k);if old then old:Destroy() end
        s.energy=math.min(s.energy,capacity(s));send(player,s,"Dismantled: 60% resources recovered.");return
    end
    local def=C.ById[s.selected]
    if not def or not s.unlocked[def.Id] then return end
    if existing then send(player,s,"Tile occupied. Select REMOVE first.");return end
    if s.credits<def.Cost or s.ore<def.Ore then send(player,s,"Not enough credits or ore.");return end
    s.credits-=def.Cost;s.ore-=def.Ore;s.grid[k]=def.Id
    modelFor(s.plot,x,z,def.Id,true);s.capacity=capacity(s);send(player,s,"Built "..def.Name)
end
local function createPlot(index,center)
    local model=Instance.new("Model");model.Name="ReactorPlot"..index;model.Parent=world
    local base=part(model,"Plot deck",Vector3.new(29,.5,34),CFrame.new(center+Vector3.new(0,.25,1.5)),colors.dark)
    local modules=Instance.new("Folder");modules.Name="Modules";modules.Parent=model
    local plot={index=index,center=center,model=model,modules=modules,owner=nil,tiles={}}
    plot.title=sign(model,base,"BAY "..index.." / AVAILABLE",Vector3.new(0,7,-14),270,55)
    for x=1,7 do for z=1,7 do
        local p=part(model,"Tile_"..key(x,z),Vector3.new(2.85,.22,2.85),CFrame.new(cellPosition(plot,x,z)),(x+z)%2==0 and Color3.fromRGB(58,72,80) or Color3.fromRGB(48,61,70))
        p:SetAttribute("PlotIndex",index);p:SetAttribute("GridX",x);p:SetAttribute("GridZ",z)
        local cd=Instance.new("ClickDetector");cd.MaxActivationDistance=45;cd.Parent=p
        cd.MouseClick:Connect(function(player) if plot.owner==player then paintTile(player,x,z) end end)
        plot.tiles[key(x,z)]=p
    end end
    for _,dx in {-13,13} do
        part(model,"Deck rail",Vector3.new(.3,1,31),CFrame.new(center+Vector3.new(dx,1,1.5)),colors.steel)
        for _,z in {-12,15} do part(model,"Beacon",Vector3.new(.4,.25,1.8),CFrame.new(center+Vector3.new(dx,1.7,z)),colors.cyan,Enum.Material.Neon) end
    end
    local quarry=part(model,"Ore terminal",Vector3.new(3,2,2.5),CFrame.new(center+Vector3.new(-8,1.5,15)),Color3.fromRGB(109,130,144))
    sign(model,quarry,"QUARRY\n+3 ORE",Vector3.new(0,2.6,0),150,55)
    prompt(quarry,"Mine +3 ore","QUARRY",function(player)
        local s=states[player];if plot.owner~=player or not s or not s.ready then return end
        if os.clock()-s.lastMine<1 then return end;s.lastMine=os.clock();s.ore+=3;send(player,s,"Collected 3 ore.")
    end)
    plots[index]=plot
end
for i,v in {Vector3.new(-25,0,-25),Vector3.new(25,0,-25),Vector3.new(-25,0,25),Vector3.new(25,0,25)} do createPlot(i,v) end
local function teleport(player,s)
    local char=player.Character
    if char then char:PivotTo(CFrame.new(s.plot.center+Vector3.new(0,4,14))*CFrame.Angles(0,0,0)) end
end
local function addPlayer(player)
    if states[player] then return end
    local plot
    for _,p in plots do if not p.owner then plot=p;break end end
    if not plot then player:Kick("All four reactor bays are occupied. Please join another server.");return end
    plot.owner=player;plot.title.Text=player.DisplayName.." / BAY "..plot.index
    local s=fresh();s.plot=plot;states[player]=s
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart",10)
        if states[player]==s then teleport(player,s) end
    end)
    load(player,s)
    if states[player]~=s then return end
    for k,id in s.grid do local x,z=k:match("^(%d+):(%d+)$");modelFor(plot,tonumber(x),tonumber(z),id,false) end
    s.capacity=capacity(s);s.ready=true
    if player.Character then teleport(player,s) end
    send(player,s)
end
local function startStop(player,s)
    if s.online then s.online=false;send(player,s,"Reactor stopped. Cooling continues.");return end
    if s.cooldown>0 or s.heat>70 then send(player,s,"Cool down below 70 heat before restarting.");return end
    if s.fuel<.2 then send(player,s,"No fuel. Buy 20 fuel for 20 credits.");return end
    local hasFuel=false;local hasTurbine=false
    for _,id in s.grid do if id=="Fuel" or id=="Fusion" then hasFuel=true end;if id=="Turbine" then hasTurbine=true end end
    if not hasFuel or not hasTurbine then send(player,s,"You need a fuel cell AND a turbine.");return end
    s.online=true;send(player,s,"Reactor online. Watch the heat trend.")
end
local function handle(player,kind,arg)
    local s=states[player];if not s or not s.ready then return {Loading=true} end
    if kind=="Get" then return payload(s) end
    if type(kind)~="string" then return payload(s) end
    if os.clock()-(s.remoteAt or 0)<.12 then return payload(s) end;s.remoteAt=os.clock()
    if kind=="Select" then
        if arg=="Remove" or (type(arg)=="string" and C.ById[arg] and s.unlocked[arg]) then s.selected=arg;s.status="Selected "..arg..". Click a grid tile in your bay." end
    elseif kind=="Toggle" then startStop(player,s)
    elseif kind=="Sell" then
        local amount=math.min(100,s.energy)
        if amount<1 then s.status="No energy stored." else s.energy-=amount;s.credits+=amount*.25;s.status="Sold energy for credits." end
    elseif kind=="AutoSell" then s.autoSell=not s.autoSell;s.status=s.autoSell and "Auto-sell ON. Keeps 100 energy for research." or "Auto-sell OFF. Energy accumulates in storage."
    elseif kind=="Fuel" then
        if s.credits>=20 then s.credits-=20;s.fuel+=20;s.status="Purchased 20 fuel." else s.status="Fuel costs 20 credits." end
    elseif kind=="Mine" then
        if os.clock()-s.lastMine>=1 then s.lastMine=os.clock();s.ore+=3;s.status="Quarry: +3 ore." end
    elseif kind=="SellOre" then
        if s.ore>=10 then s.ore-=10;s.credits+=15;s.status="Sold 10 ore for 15 credits." else s.status="Need 10 ore to sell." end
    elseif kind=="Study" then
        if s.energy>=50 and s.ore>=3 then s.energy-=50;s.ore-=3;s.rp+=2;s.status="Experiment complete: +2 research." else s.status="Experiment needs 50 energy and 3 ore." end
    elseif kind=="Unlock" then
        local def=type(arg)=="string" and C.ById[arg]
        if def and not s.unlocked[arg] then
            if s.rp>=def.Unlock then s.rp-=def.Unlock;s.unlocked[arg]=true;s.status="Unlocked "..def.Name else s.status="Not enough research." end
        end
    elseif kind=="Upgrade" then
        for _,u in C.Upgrades do if u.Id==arg then
            local level=s.upgrades[u.Id];local cost=u.Base*(level+1)
            if level>=u.Max then s.status="Upgrade already maxed." elseif s.rp>=cost then s.rp-=cost;s.upgrades[u.Id]+=1;s.status="Upgraded "..u.Name else s.status="Not enough research." end
        end end
    elseif kind=="Vent" then
        if s.ore>=3 then s.ore-=3;s.heat=math.max(0,s.heat-25);s.status="Emergency coolant: -25 heat." else s.status="Emergency vent needs 3 ore." end
    elseif kind=="Home" then teleport(player,s)
    elseif kind=="Claim" then
        for _,q in C.Quests do if q.Id==arg and not s.quests[q.Id] and s.generated>=q.Goal then
            s.quests[q.Id]=true;s.credits+=q.Reward;s.rp+=q.RP;s.status="Contract completed: +"..q.Reward.." credits, +"..q.RP.." research."
        end end
    end
    send(player,s);return payload(s)
end
action.OnServerInvoke=handle
local function simulate(player,s)
    s.cooldown=math.max(0,s.cooldown-1)
    s.ore+=.2+s.upgrades.Drill*.15
    s.capacity=capacity(s)
    local flux,heat,cooling,turbines,labs,vents,breeders,demand=0,0,0,0,0,0,0,0
    for x=1,7 do for z=1,7 do
        local id=s.grid[key(x,z)]
        if id=="Fuel" or id=="Fusion" then
            local adj=neighbors(s,x,z,"Fuel")+neighbors(s,x,z,"Fusion")
            flux+=(id=="Fusion" and 60 or 24)*(1+adj*.20)
            heat+=math.max(.2,(id=="Fusion" and 8 or 6)*(1+adj*.5)-neighbors(s,x,z,"Cooler")*2.2)
            demand+=id=="Fusion" and .12 or .08
        elseif id=="Cooler" then cooling+=.8
        elseif id=="Turbine" then turbines+=1
        elseif id=="Lab" then labs+=1
        elseif id=="Vent" then vents+=1
        elseif id=="Breeder" then breeders+=1 end
    end end
    cooling=(1.2+cooling)*(1+s.upgrades.Cooling*.15)
    s.power=0
    if s.online then
        if s.fuel<demand or demand==0 then s.online=false;s.status="Fuel depleted. Reactor stopped."
        else
            s.fuel-=demand
            local converted=math.min(flux,turbines*28)
            local output=converted*(1+s.upgrades.Efficiency*.15)
            heat+=math.max(0,flux-converted)*.08
            s.generated+=output;s.energy+=output;s.power=output
            for _=1,labs do if s.energy>=3 then s.energy-=3;s.rp+=.25 end end
            for _=1,vents do if s.energy>=2 then s.energy-=2;cooling+=4*(1+s.upgrades.Cooling*.15) end end
            for _=1,breeders do if s.energy>=5 and s.ore>=.03 then s.energy-=5;s.ore-=.03;s.fuel+=.1;heat+=1 end end
        end
    end
    if not s.online then heat=0 end
    s.heatRate=heat-cooling;s.heat=math.max(0,s.heat+s.heatRate)
    if s.heat>=100 and s.online and s.upgrades.Safety>0 then
        s.online=false;s.cooldown=10;s.status="AUTO SCRAM: temperature exceeded 100. Layout preserved."
    elseif s.heat>=140 then
        s.online=false;s.heat=85;s.cooldown=20;s.fuel=math.max(0,s.fuel-8);s.energy=0
        s.status="MELTDOWN! Lost stored energy and 8 fuel. Layout preserved. Improve cooling."
        local flash=Instance.new("Highlight");flash.FillColor=Color3.fromRGB(255,92,51);flash.FillTransparency=.55
        flash.OutlineTransparency=1;flash.Adornee=s.plot.model;flash.Parent=s.plot.model
        task.delay(.7,function() flash:Destroy() end)
    end
    if s.energy>s.capacity then
        if s.autoSell then local sold=s.energy-s.capacity;s.credits+=sold*.25;s.earned+=sold*.25 else s.heat+=math.min(2,(s.energy-s.capacity)*.02) end
        s.energy=s.capacity
    end
    if s.autoSell and s.energy>100 then local sold=s.energy-100;s.energy=100;s.credits+=sold*.25;s.earned+=sold*.25 end
    if s.online and s.heat<65 then s.rp+=.025 end
    s.plot.title.Text=player.DisplayName.." / BAY "..s.plot.index.."\n"..(s.online and "ONLINE" or "OFFLINE").." | "..math.floor(s.heat).." HEAT"
    send(player,s)
end
Players.PlayerAdded:Connect(function(player) task.spawn(addPlayer,player) end)
Players.PlayerRemoving:Connect(function(player)
    local s=states[player];if not s then return end
    states[player]=nil
    local plot=s.plot;plot.modules:ClearAllChildren();plot.owner=nil;plot.title.Text="BAY "..plot.index.." / AVAILABLE"
    save(player,s)
end)
for _,player in Players:GetPlayers() do task.spawn(addPlayer,player) end
task.spawn(function()
    local ticks=0
    while task.wait(1) do
        ticks+=1
        for player,s in states do if s.ready then
            local ok,err=pcall(simulate,player,s);if not ok then warn("Reactor tick: "..tostring(err)) end
            if ticks%60==0 then task.spawn(save,player,s) end
        end end
    end
end)
game:BindToClose(function()
    local pending=0
    for player,s in states do pending+=1;task.spawn(function() save(player,s);pending-=1 end) end
    local deadline=os.clock()+20
    while pending>0 and os.clock()<deadline do task.wait(.1) end
end)
