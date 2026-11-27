local Color3={fromRGB=function(...) return {...} end}
local RunService={IsStudio=function() return true end}
local sent={}
local function send(player,s,message) if message then s.status=message end end
local function teleport() end
local Instance={new=function() return {Destroy=function() end} end}
local task={delay=function(_,f) f() end}
local C=(function()
local C={}
C.Size=7
C.Cell=3
C.Modules={
    {Id="Fuel",Name="FUEL CELL",Cost=60,Ore=8,Unlock=0,Color=Color3.fromRGB(111,231,151),Info="Produces 24 flux/s. Uses 0.08 fuel/s. Adjacent coolers reduce heat; adjacent fuel increases output AND heat."},
    {Id="Cooler",Name="COOLER",Cost=35,Ore=6,Unlock=0,Color=Color3.fromRGB(95,191,251),Info="Each adjacent fuel cell produces 2.2 less heat/s. Adds 0.8 cooling/s. Plan for safe continuous operation."},
    {Id="Turbine",Name="TURBINE",Cost=75,Ore=10,Unlock=0,Color=Color3.fromRGB(255,196,105),Info="Converts up to 28 flux/s into stored energy. Unused flux becomes waste heat."},
    {Id="Battery",Name="BATTERY",Cost=50,Ore=8,Unlock=0,Color=Color3.fromRGB(188,167,255),Info="Adds 250 energy capacity. Stored energy is used by research and can be sold."},
    {Id="Lab",Name="LAB",Cost=120,Ore=15,Unlock=10,Color=Color3.fromRGB(235,153,238),Info="Consumes 3 stored energy/s to produce 0.25 research/s while running. More labs accelerate research."},
    {Id="Vent",Name="ACTIVE VENT",Cost=150,Ore=18,Unlock=25,Color=Color3.fromRGB(96,230,220),Info="Consumes 2 energy/s for 4 extra cooling/s. Runs only while the reactor is online."},
    {Id="Breeder",Name="BREEDER",Cost=240,Ore=25,Unlock=60,Color=Color3.fromRGB(248,149,93),Info="While running, consumes 5 energy/s and 0.03 ore/s to create 0.1 fuel/s. Adds 1 heat/s."},
    {Id="Fusion",Name="FUSION CORE",Cost=650,Ore=65,Unlock=140,Color=Color3.fromRGB(131,204,255),Info="60 flux/s, 8 heat/s, 0.12 fuel/s. Adjacent coolers reduce heat. High-output late-game core."},
}
C.ById={}
for _,m in C.Modules do C.ById[m.Id]=m end
C.Upgrades={
    {Id="Efficiency",Name="EFFICIENT ROTORS",Base=15,Max=5,Info="+15% turbine conversion per level."},
    {Id="Cooling",Name="THERMAL ENGINEERING",Base=20,Max=5,Info="+15% passive/active cooling per level."},
    {Id="Drill",Name="AUTOMATED QUARRY",Base=12,Max=5,Info="+0.15 ore/s per level. Base quarry: 0.2 ore/s."},
    {Id="Safety",Name="AUTOMATIC SCRAM",Base=30,Max=1,Info="Shuts down at 100 heat. Without it a meltdown occurs at 140 heat."},
}
C.Quests={
    {Id="first",Name="FIRST CURRENT",Goal=100,Reward=80,RP=4,Info="Generate 100 energy total."},
    {Id="power",Name="GRID OPERATOR",Goal=1000,Reward=180,RP=8,Info="Generate 1,000 energy total."},
    {Id="industry",Name="INDUSTRIAL SCALE",Goal=6000,Reward=450,RP=18,Info="Generate 6,000 energy total."},
    {Id="master",Name="REACTOR ENGINEER",Goal=20000,Reward=1000,RP=40,Info="Generate 20,000 energy total."},
}
return C

end)()
local function key(x,z) return tostring(x)..":"..tostring(z) end
local function fresh()
    return {credits=240,ore=38,fuel=35,energy=0,heat=0,rp=0,generated=0,earned=0,online=false,autoSell=true,
        upgrades={Efficiency=0,Cooling=0,Drill=0,Safety=0},unlocked={Fuel=true,Cooler=true,Turbine=true,Battery=true},
        grid={[key(4,4)]="Fuel",[key(3,4)]="Cooler",[key(5,4)]="Cooler",[key(4,5)]="Turbine"},
        quests={},selected="Cooler",power=0,heatRate=0,capacity=250,cooldown=0,status="Starter layout ready. Press START.",saveStatus=RunService:IsStudio() and "STUDIO: SESSION ONLY" or "LOADING",lastMine=0,lastAction=0}
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
local states={}
local function payload(s) return s end
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

local player={DisplayName="Test"}
local function make()
 local s=fresh();s.ready=true;s.plot={index=1,title={},modules={},model={}}
 s.fuel=10000;states[player]=s;return s
end
local function check(value,message) assert(value,message) end
local s=make();s.online=true
for i=1,1000 do simulate(player,s) end
check(s.online,"starter should sustain")
check(s.heat==0,"starter should be thermally stable")
check(s.generated==24000,"starter output exact")
check(s.credits>5000,"auto sell earns credits")
check(s.energy<=100,"auto sell preserves research reserve")
print("PASS starter:1000ticks stable,24energy/sec,auto-sale")
s=make();s.grid={["4:4"]="Fuel",["4:5"]="Fuel",["4:6"]="Turbine"};s.online=true
local meltdown=false
for i=1,50 do simulate(player,s);if string.find(s.status,"MELTDOWN") then meltdown=true;break end end
check(meltdown and not s.online and s.energy==0,"unsafe layout must melt down")
check(s.grid["4:4"]=="Fuel","meltdown preserves layout")
print("PASS meltdown and recoverable layout")
s=make();s.grid={["4:4"]="Fuel",["4:5"]="Fuel",["4:6"]="Turbine"};s.upgrades.Safety=1;s.online=true
for i=1,50 do simulate(player,s);if not s.online then break end end
check(not s.online and s.heat<140,"safety must scram before meltdown")
print("PASS automatic scram")
s=make();s.heat=80;s.online=false
simulate(player,s);check(s.heat<80,"offline cooling")
s=make();s.fuel=0;s.online=true;simulate(player,s);check(not s.online,"fuel exhaustion")
s=make();s.credits=0;s.ore=10;s.remoteAt=-100;handle(player,"SellOre")
check(s.credits==15 and s.ore==0,"ore bailout")
s.ore=10;s.remoteAt=-100;handle(player,"SellOre");s.remoteAt=-100;handle(player,"Fuel")
check(s.fuel>10000,"recover from no credits with ore")
print("PASS cooling, fuel exhaustion, ore-to-fuel recovery")
s=make();s.energy=50;s.ore=3;s.remoteAt=-100;handle(player,"Study")
check(s.rp==2 and s.energy==0 and s.ore==0,"experiment costs")
s.rp=100;s.remoteAt=-100;handle(player,"Unlock","Lab");check(s.unlocked.Lab and s.rp==90,"unlock")
s.remoteAt=-100;handle(player,"Upgrade","Safety");check(s.upgrades.Safety==1 and s.rp==60,"upgrade")
s.generated=100;s.remoteAt=-100;handle(player,"Claim","first");local credits=s.credits
s.remoteAt=-100;handle(player,"Claim","first");check(s.credits==credits,"claim once")
print("PASS research unlock upgrade and once-only contracts")
s=make();s.grid["1:1"]="Battery";check(capacity(s)==500,"battery capacity")
s.online=true;s.autoSell=false
for i=1,30 do simulate(player,s) end
check(s.energy==500,"storage cap")
print("PASS battery and storage cap")
print("ALL REACTOR LOGIC TESTS PASSED")
