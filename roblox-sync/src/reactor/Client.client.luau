local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local folder=ReplicatedStorage:WaitForChild("Reactor")
local C=require(folder:WaitForChild("Config"))
local remote=folder:WaitForChild("Action")
local event=folder:WaitForChild("Update")
local ui=script.Parent
local P={bg=Color3.fromRGB(16,22,28),panel=Color3.fromRGB(23,32,40),card=Color3.fromRGB(32,44,54),line=Color3.fromRGB(66,86,98),text=Color3.fromRGB(229,239,244),muted=Color3.fromRGB(142,164,177),cyan=Color3.fromRGB(92,224,210),orange=Color3.fromRGB(255,178,99),red=Color3.fromRGB(255,108,106)}
local root=Instance.new("Frame");root.Name="Dashboard";root.Size=UDim2.fromOffset(1280,800);root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5);root.BackgroundTransparency=1;root.Parent=ui
local scale=Instance.new("UIScale");scale.Parent=root
local function resize()
    local camera=workspace.CurrentCamera;if camera then local v=camera.ViewportSize;scale.Scale=math.min(v.X/1280,v.Y/800) end
end
resize()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() resize();if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
local function corner(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 10);c.Parent=p end
local function stroke(p,transparency) local s=Instance.new("UIStroke");s.Color=P.line;s.Transparency=transparency or .45;s.Thickness=1;s.Parent=p;return s end
local function box(parent,pos,size,color,alpha)
    local f=Instance.new("Frame");f.Position=pos;f.Size=size;f.BackgroundColor3=color or P.panel;f.BackgroundTransparency=alpha or .08;f.BorderSizePixel=0;f.Parent=parent;corner(f);return f
end
local function text(parent,value,pos,size,fontSize,color,font)
    local l=Instance.new("TextLabel");l.Position=pos;l.Size=size;l.Text=value;l.TextColor3=color or P.text;l.Font=font or Enum.Font.GothamMedium
    l.TextSize=fontSize or 14;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.BackgroundTransparency=1;l.Parent=parent;return l
end
local function button(parent,value,pos,size,callback,accent)
    local b=Instance.new("TextButton");b.Position=pos;b.Size=size;b.Text=value;b.Font=Enum.Font.GothamBold;b.TextSize=13
    b.BackgroundColor3=accent or P.card;b.TextColor3=P.text;b.BorderSizePixel=0;b.AutoButtonColor=true;b.Parent=parent;corner(b,7)
    b.Activated:Connect(callback);return b
end
local state,apply
local focusBuild
local sending=false
local function request(kind,arg)
    if sending then return end;sending=true
    task.spawn(function()
        local ok,data=pcall(function() return remote:InvokeServer(kind,arg) end)
        if ok and data and not data.Loading then
            apply(data)
            if kind=="Select" and data.Selected==arg and focusBuild then focusBuild() end
        end
        sending=false
    end)
end
local brand=text(root,"REACTOR / WORKS",UDim2.fromOffset(28,24),UDim2.fromOffset(450,34),29,P.text,Enum.Font.GothamBlack)
text(root,"BUILD A SYSTEM. NOT JUST A BIGGER NUMBER.",UDim2.fromOffset(29,60),UDim2.fromOffset(600,18),11,P.muted)
local saving=text(root,"CONNECTING...",UDim2.fromOffset(880,30),UDim2.fromOffset(370,24),12,P.muted);saving.TextXAlignment=Enum.TextXAlignment.Right
local minimize=button(root,"HIDE PANELS",UDim2.fromOffset(1092,58),UDim2.fromOffset(160,25),function() end)
local resourceNames={"CREDITS","ORE","FUEL","STORED ENERGY","RESEARCH","TOTAL GENERATED"}
local resourceLabels={}
for i,name in resourceNames do
    local card=box(root,UDim2.fromOffset(28+(i-1)*206,90),UDim2.fromOffset(194,62),P.panel,.12);stroke(card,.6)
    text(card,name,UDim2.fromOffset(12,8),UDim2.fromOffset(175,15),10,P.muted)
    resourceLabels[i]=text(card,"--",UDim2.fromOffset(12,28),UDim2.fromOffset(180,27),22,i==1 and P.cyan or P.text,Enum.Font.GothamBold)
end
local toast=text(root,"Loading your reactor bay...",UDim2.fromOffset(30,158),UDim2.fromOffset(1220,22),13,P.orange)
local left=box(root,UDim2.fromOffset(28,190),UDim2.fromOffset(340,572),P.panel,.10);stroke(left)
text(left,"REACTOR CONTROL",UDim2.fromOffset(18,15),UDim2.fromOffset(300,26),17,P.text,Enum.Font.GothamBold)
local status=text(left,"OFFLINE",UDim2.fromOffset(18,49),UDim2.fromOffset(300,24),14,P.muted,Enum.Font.GothamBold)
local heatTitle=text(left,"CORE TEMPERATURE",UDim2.fromOffset(18,83),UDim2.fromOffset(300,20),11,P.muted)
local heatTrack=box(left,UDim2.fromOffset(18,111),UDim2.fromOffset(304,12),P.bg,0)
local heatFill=box(heatTrack,UDim2.fromScale(0,0),UDim2.fromScale(0,1),P.cyan,0)
local heatInfo=text(left,"0 / 140",UDim2.fromOffset(18,131),UDim2.fromOffset(300,22),16,P.text,Enum.Font.GothamBold)
local trend=text(left,"TREND  --",UDim2.fromOffset(18,157),UDim2.fromOffset(300,20),12,P.muted)
local output=text(left,"OUTPUT  --",UDim2.fromOffset(18,183),UDim2.fromOffset(300,20),12,P.cyan)
local start=button(left,"START REACTOR",UDim2.fromOffset(18,223),UDim2.fromOffset(304,44),function() request("Toggle") end,Color3.fromRGB(39,112,101))
local auto=button(left,"AUTO-SELL: ON",UDim2.fromOffset(18,277),UDim2.fromOffset(304,34),function() request("AutoSell") end)
button(left,"BUY 20 FUEL / $20",UDim2.fromOffset(18,321),UDim2.fromOffset(148,35),function() request("Fuel") end)
button(left,"SELL 100 ENERGY",UDim2.fromOffset(174,321),UDim2.fromOffset(148,35),function() request("Sell") end)
button(left,"MINE +3 ORE",UDim2.fromOffset(18,364),UDim2.fromOffset(148,35),function() request("Mine") end)
button(left,"SELL 10 ORE / $15",UDim2.fromOffset(174,364),UDim2.fromOffset(148,35),function() request("SellOre") end)
button(left,"EMERGENCY VENT / 3 ORE",UDim2.fromOffset(18,407),UDim2.fromOffset(304,35),function() request("Vent") end,Color3.fromRGB(104,61,48))
button(left,"RETURN TO MY BAY",UDim2.fromOffset(18,450),UDim2.fromOffset(304,33),function() request("Home") end)
local hint=text(left,"Cooling works while stopped.\nBuild only while OFFLINE and below 60 heat.\nAll construction happens on your own grid.",UDim2.fromOffset(18,495),UDim2.fromOffset(304,62),12,P.muted);hint.TextWrapped=true
local right=box(root,UDim2.fromOffset(386,190),UDim2.fromOffset(866,572),P.panel,.1);stroke(right)
local pages,tabs={},{}
local names={"BUILD","RESEARCH","CONTRACTS","HANDBOOK"}
local activePage="BUILD"
local function showPage(name)
    activePage=name
    for k,p in pages do p.Visible=k==name;tabs[k].BackgroundColor3=k==name and Color3.fromRGB(52,81,86) or P.card end
end
for i,name in names do
    tabs[name]=button(right,name,UDim2.fromOffset(14+(i-1)*209,12),UDim2.fromOffset(199,34),function() showPage(name) end)
    local page=Instance.new("ScrollingFrame");page.Position=UDim2.fromOffset(14,58);page.Size=UDim2.new(1,-28,1,-72)
    page.BackgroundTransparency=1;page.BorderSizePixel=0;page.ScrollBarThickness=4;page.AutomaticCanvasSize=Enum.AutomaticSize.Y;page.CanvasSize=UDim2.new();page.Visible=false;page.Parent=right;pages[name]=page
end
local moduleRows={}
text(pages.BUILD,"01  Select a module  /  02  Click a tile in the world",UDim2.fromOffset(4,0),UDim2.fromOffset(810,24),13,P.muted)
local selected=text(pages.BUILD,"SELECTED: COOLER",UDim2.fromOffset(4,30),UDim2.fromOffset(575,25),14,P.cyan,Enum.Font.GothamBold)
local remove=button(pages.BUILD,"REMOVE / 60% REFUND",UDim2.fromOffset(589,26),UDim2.fromOffset(222,30),function() request("Select","Remove") end)
for i,def in C.Modules do
    local col=(i-1)%2;local row=math.floor((i-1)/2)
    local card=box(pages.BUILD,UDim2.fromOffset(col*414+3,70+row*151),UDim2.fromOffset(402,140),P.card,.1)
    local edge=stroke(card,.65)
    box(card,UDim2.fromOffset(0,12),UDim2.fromOffset(3,27),def.Color,0)
    text(card,def.Name,UDim2.fromOffset(13,10),UDim2.fromOffset(260,22),14,def.Color,Enum.Font.GothamBold)
    local cost=text(card,"$"..def.Cost.." + "..def.Ore.." ore",UDim2.fromOffset(13,36),UDim2.fromOffset(370,17),12,P.muted)
    local description=text(card,def.Info,UDim2.fromOffset(13,58),UDim2.fromOffset(375,43),12,P.text);description.TextWrapped=true;description.TextYAlignment=Enum.TextYAlignment.Top
    local pick=button(card,"SELECT",UDim2.fromOffset(13,106),UDim2.fromOffset(376,26),function()
        if state and state.Unlocked[def.Id] then request("Select",def.Id) else request("Unlock",def.Id) end
    end)
    moduleRows[def.Id]={button=pick,border=edge,cost=cost}
end
text(pages.RESEARCH,"EXPERIMENTS & TECHNOLOGY",UDim2.fromOffset(3,0),UDim2.fromOffset(800,28),17,P.text,Enum.Font.GothamBold)
text(pages.RESEARCH,"Keep energy in storage. Research changes the engineering rules.",UDim2.fromOffset(3,32),UDim2.fromOffset(810,22),12,P.muted)
button(pages.RESEARCH,"RUN EXPERIMENT  /  50 ENERGY + 3 ORE  /  +2 RESEARCH",UDim2.fromOffset(3,67),UDim2.fromOffset(811,40),function() request("Study") end,Color3.fromRGB(58,72,107))
local upgradeRows={}
for i,def in C.Upgrades do
    local card=box(pages.RESEARCH,UDim2.fromOffset(3,122+(i-1)*105),UDim2.fromOffset(811,95),P.card,.1)
    text(card,def.Name,UDim2.fromOffset(12,10),UDim2.fromOffset(560,23),15,P.text,Enum.Font.GothamBold)
    text(card,def.Info,UDim2.fromOffset(12,40),UDim2.fromOffset(560,40),12,P.muted).TextWrapped=true
    local b=button(card,"",UDim2.fromOffset(582,16),UDim2.fromOffset(215,61),function() request("Upgrade",def.Id) end)
    upgradeRows[def.Id]=b
end
text(pages.CONTRACTS,"PRODUCTION CONTRACTS",UDim2.fromOffset(3,0),UDim2.fromOffset(800,28),17,P.text,Enum.Font.GothamBold)
text(pages.CONTRACTS,"Lifetime production counts even after you sell energy. Claim each reward once.",UDim2.fromOffset(3,33),UDim2.fromOffset(810,25),12,P.muted)
local questRows={}
for i,q in C.Quests do
    local card=box(pages.CONTRACTS,UDim2.fromOffset(3,72+(i-1)*111),UDim2.fromOffset(811,100),P.card,.1)
    text(card,q.Name,UDim2.fromOffset(13,10),UDim2.fromOffset(560,24),15,P.text,Enum.Font.GothamBold)
    local info=text(card,q.Info.."\nReward: $"..q.Reward.." + "..q.RP.." research",UDim2.fromOffset(13,40),UDim2.fromOffset(560,48),12,P.muted)
    local b=button(card,"",UDim2.fromOffset(592,18),UDim2.fromOffset(205,62),function() request("Claim",q.Id) end)
    questRows[q.Id]=b
end
local sections={
    {"01 / YOUR FIRST REACTOR","Your bay starts with one fuel cell, two adjacent coolers and a turbine. Press START. Credits appear automatically once storage exceeds 100 energy. Buy fuel before it runs out."},
    {"02 / BUILDING A LAYOUT","STOP the reactor, select a module in BUILD, then click a grid tile. Use REMOVE to dismantle for a 60% refund. Four-direction adjacency matters, not diagonals. Construction requires heat below 60."},
    {"03 / HEAT IS A DESIGN PROBLEM","Fuel next to fuel gives +20% flux per neighbor but +50% heat. A cooler next to fuel reduces its heat. Unconverted flux becomes waste heat. Cooling continues while stopped. At 140 heat a meltdown empties energy and consumes 8 fuel; your layout survives."},
    {"04 / GETTING UNSTUCK","The quarry produces ore automatically. MINE gives +3 ore once per second. Sell 10 ore for $15 if you need fuel money. You can always dismantle modules. Never spend your last credits without a fuel reserve."},
    {"05 / RESEARCH & INDUSTRY","Experiments consume 50 energy + 3 ore for 2 research. Claim production contracts for extra research. Unlock LAB first for passive research, VENT for active cooling, BREEDER for fuel recycling, then FUSION for high output."},
    {"06 / STORAGE & THE GRID","Auto-sell keeps 100 energy and sells the excess at 4 energy = $1. Switch it off to fill batteries. Full storage without selling causes extra heat. Labs and vents need stored energy to work."},
    {"07 / SAFETY & PROGRESSION","Automatic SCRAM shuts down at 100 heat. Upgrade cooling and turbine conversion, optimize fuel adjacency, and build towards 20,000 total energy. Each player owns a separate bay. Other players cannot edit yours."},
    {"08 / SAVING","The published game attempts to save your resources, layout, unlocks and contracts every 60 seconds and on exit. Studio is session-only. Check the save indicator: unavailable services do not mean progress has been saved."},
}
for i,section in sections do
    local card=box(pages.HANDBOOK,UDim2.fromOffset(3,(i-1)*137),UDim2.fromOffset(811,126),P.card,.1)
    text(card,section[1],UDim2.fromOffset(13,9),UDim2.fromOffset(780,23),15,P.cyan,Enum.Font.GothamBold)
    local body=text(card,section[2],UDim2.fromOffset(13,39),UDim2.fromOffset(780,78),13,P.text)
    body.TextWrapped=true;body.TextYAlignment=Enum.TextYAlignment.Top
end
local hidden=false
focusBuild=function()
    hidden=true;left.Visible=false;right.Visible=false;minimize.Text="SHOW PANELS"
end
local function togglePanels()
    hidden=not hidden;left.Visible=not hidden;right.Visible=not hidden;minimize.Text=hidden and "SHOW PANELS" or "HIDE PANELS"
end
minimize.Activated:Connect(togglePanels)
text(root,"B / PANELS     R / START-STOP     X / EMERGENCY VENT",UDim2.fromOffset(390,772),UDim2.fromOffset(700,18),10,P.muted)
game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.B then togglePanels()
    elseif input.KeyCode==Enum.KeyCode.R then request("Toggle")
    elseif input.KeyCode==Enum.KeyCode.X then request("Vent") end
end)
local function fmt(n)
    if n>=1e6 then return string.format("%.2fM",n/1e6) elseif n>=1e4 then return string.format("%.1fk",n/1000) else return string.format("%.1f",n) end
end
apply=function(data)
    if data.Loading then return end
    state=data
    resourceLabels[1].Text="$"..fmt(data.Credits);resourceLabels[2].Text=fmt(data.Ore)
    resourceLabels[3].Text=fmt(data.Fuel);resourceLabels[4].Text=fmt(data.Energy).." / "..data.Capacity
    resourceLabels[5].Text=fmt(data.RP);resourceLabels[6].Text=fmt(data.Generated)
    saving.Text="BAY "..data.Plot.."  /  "..data.SaveStatus
    toast.Text=data.Status
    status.Text=data.Online and "ONLINE / REACTOR ACTIVE" or "OFFLINE / PASSIVE COOLING"
    status.TextColor3=data.Online and P.cyan or P.muted
    start.Text=data.Online and "STOP REACTOR" or "START REACTOR"
    start.BackgroundColor3=data.Online and Color3.fromRGB(107,63,53) or Color3.fromRGB(39,112,101)
    auto.Text="AUTO-SELL: "..(data.AutoSell and "ON" or "OFF")
    heatInfo.Text=string.format("%.1f / 140",data.Heat)..(data.Heat>=100 and "  DANGER" or "")
    heatFill.BackgroundColor3=data.Heat>95 and P.red or (data.Heat>65 and P.orange or P.cyan)
    TweenService:Create(heatFill,TweenInfo.new(.35),{Size=UDim2.fromScale(math.clamp(data.Heat/140,0,1),1)}):Play()
    trend.Text=string.format("TREND  %+.2f heat / sec",data.HeatRate)
    trend.TextColor3=data.HeatRate>0 and P.orange or P.cyan
    output.Text=string.format("OUTPUT  %.1f energy / sec",data.Power)
    selected.Text="SELECTED: "..string.upper(data.Selected).."   |   BAY "..data.Plot
    for id,row in moduleRows do
        local def=C.ById[id];local unlocked=data.Unlocked[id]
        row.button.Text=unlocked and (data.Selected==id and "SELECTED - CLICK A GRID TILE" or "SELECT / $"..def.Cost.." + "..def.Ore.." ORE") or ("UNLOCK / "..def.Unlock.." RESEARCH")
        row.button.BackgroundColor3=data.Selected==id and Color3.fromRGB(45,95,89) or P.bg
        row.border.Transparency=data.Selected==id and .05 or .65
    end
    for _,u in C.Upgrades do
        local lv=data.Upgrades[u.Id]
        upgradeRows[u.Id].Text=lv>=u.Max and "MAXED" or ("Lv. "..lv.." / "..u.Max.."\n"..u.Base*(lv+1).." RESEARCH")
    end
    for _,q in C.Quests do
        questRows[q.Id].Text=data.Quests[q.Id] and "CLAIMED" or (data.Generated>=q.Goal and "CLAIM REWARD" or (math.floor(data.Generated).." / "..q.Goal))
        questRows[q.Id].BackgroundColor3=not data.Quests[q.Id] and data.Generated>=q.Goal and Color3.fromRGB(45,95,89) or P.bg
    end
end
event.OnClientEvent:Connect(apply)
showPage("BUILD")
task.spawn(function()
    while not state do request("Get");task.wait(1) end
end)
-- Local-only tile hover and turbine rotation; no per-frame network traffic.
local mouse=player:GetMouse()
local hover=Instance.new("Highlight");hover.FillTransparency=.88;hover.OutlineTransparency=.15
hover.FillColor=P.cyan;hover.OutlineColor=P.cyan;hover.DepthMode=Enum.HighlightDepthMode.Occluded;hover.Parent=workspace
local rotors={}
local function track(p)
    if p:IsA("BasePart") and p:GetAttribute("ReactorRotor") then rotors[p]=p.CFrame end
end
for _,p in workspace:GetDescendants() do track(p) end
workspace.DescendantAdded:Connect(function(p) task.defer(track,p) end)
local clock=0
RunService.RenderStepped:Connect(function(dt)
    clock+=dt
    local target=mouse.Target
    hover.Adornee=state and target and target:GetAttribute("PlotIndex")==state.Plot and target or nil
    for p,base in rotors do
        if not p.Parent then rotors[p]=nil else p.CFrame=base*CFrame.Angles(0,clock*1.6,0) end
    end
end)
