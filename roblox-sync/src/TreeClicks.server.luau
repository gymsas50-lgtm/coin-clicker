local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local tree=workspace:WaitForChild("LittleStudTree")
local trunk=tree:WaitForChild("Trunk")
local origin=Vector3.new(trunk.Position.X,0,trunk.Position.Z)
local chest=workspace:WaitForChild("TreeChest")
local caseButton=chest:WaitForChild("Floor")
local random=Random.new()
local inventory=game:GetService("ReplicatedStorage"):WaitForChild("TreeInventory")
local caseVisuals=require(game:GetService("ReplicatedStorage"):WaitForChild("CaseVisuals"))
local owned={1,0,0}
local equipped=true
local types={
    {name="Oak",weight=70,power=1,leaf=Color3.fromRGB(69,144,65),wood=Color3.fromRGB(108,70,40)},
    {name="Birch",weight=25,power=2,leaf=Color3.fromRGB(159,185,65),wood=Color3.fromRGB(226,222,205)},
    {name="Crystal",weight=5,power=4,leaf=Color3.fromRGB(126,194,235),wood=Color3.fromRGB(106,116,155)},
}
local progress={{level=1,xp=0},{level=1,xp=0},{level=1,xp=0}}
local current,balance,busy=1,0,false
local currentItem=1
local items={{kind=1,state=progress[1]}}
local cooldown={}
local function power() return types[current].power*2^(progress[current].level-1) end
local function required() return 25*2^(progress[current].level-1) end
local outline=tree:FindFirstChild("TreeOutline") or Instance.new("Highlight")
outline.Name="TreeOutline";outline.Adornee=tree;outline.FillTransparency=1;outline.OutlineTransparency=0
outline.OutlineColor=Color3.fromRGB(240,255,220);outline.Parent=tree
local anchor=Instance.new("Part");anchor.Name="TreeCounterAnchor";anchor.Size=Vector3.new(.1,.1,.1)
anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Parent=workspace
local function label(parent,pos,size,fontSize)
    local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=pos;l.Size=size
    l.Font=Enum.Font.GothamBold;l.TextSize=fontSize;l.TextColor3=Color3.new(1,1,1)
    l.TextStrokeTransparency=.15;l.TextStrokeColor3=Color3.fromRGB(20,35,20);l.Parent=parent;return l
end
local gui=Instance.new("BillboardGui");gui.Name="TreeStats";gui.Adornee=anchor
 gui.Size=UDim2.fromOffset(260,105);gui.AlwaysOnTop=true;gui.MaxDistance=130;gui.Parent=anchor
local title=label(gui,UDim2.fromOffset(0,0),UDim2.new(1,0,0,28),20)
local clicks=label(gui,UDim2.fromOffset(0,28),UDim2.new(1,0,0,27),21)
local track=Instance.new("Frame");track.Position=UDim2.fromOffset(18,62);track.Size=UDim2.new(1,-36,0,20)
track.BackgroundColor3=Color3.fromRGB(29,41,32);track.BorderSizePixel=0;track.ClipsDescendants=true;track.Parent=gui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,6);corner.Parent=track
local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=Color3.fromRGB(111,223,112);fill.BorderSizePixel=0;fill.Parent=track
local xpText=label(track,UDim2.fromScale(0,0),UDim2.fromScale(1,1),12);xpText.ZIndex=3
local caseGui=Instance.new("BillboardGui");caseGui.Name="CaseLabel";caseGui.Adornee=caseButton
caseGui.Size=UDim2.fromOffset(270,125);caseGui.StudsOffsetWorldSpace=Vector3.new(0,5,0);caseGui.AlwaysOnTop=true;caseGui.MaxDistance=80;caseGui.Parent=caseButton
local caseText=label(caseGui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),16)
local fillTween
local function refresh()
    local state=progress[current]
    title.Text=equipped and (types[current].name.." | Lv. "..state.level) or "No tree equipped"
    clicks.Text="Clicks: "..string.format("%.0f",balance).." | +"..string.format("%.0f",power()).." / sec"
    xpText.Text="XP "..state.xp.." / "..string.format("%.0f",required())
    if fillTween then fillTween:Cancel() end
    fillTween=TweenService:Create(fill,TweenInfo.new(.18),{Size=UDim2.fromScale(math.clamp(state.xp/required(),0,1),1)});fillTween:Play()
    caseText.Text=busy and "OPENING..." or "TREE CASE - 50 CLICKS\nCHANCES\nOak 70%  |  Birch 25%\nCrystal 5%"
    tree:SetAttribute("Clicks",balance);tree:SetAttribute("Level",state.level)
    tree:SetAttribute("XP",state.xp);tree:SetAttribute("ClickPower",power());tree:SetAttribute("TreeType",types[current].name)
end
local function nearby(player,target,range)
    local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
    local h=char and char:FindFirstChildOfClass("Humanoid")
    return root and h and h.Health>0 and (root.Position-target).Magnitude<=range
end
local function clicked(player)
    if busy or not equipped then return end
    local now=os.clock();if cooldown[player] and now-cooldown[player]<.08 then return end
    cooldown[player]=now;balance+=power()
    local state=progress[current];state.xp+=1
    while state.xp>=required() do state.xp-=required();state.level+=1 end
    refresh()
end
local function clickable(part) end -- Passive income replaces manual clicking.
for _,part in tree:GetDescendants() do if part:IsA("BasePart") then clickable(part) end end
local top=tree:WaitForChild("CrownTop")
anchor.Position=Vector3.new(origin.X,top.Position.Y+top.Size.Y/2+1.8,origin.Z)
local function rebuild(index,instant)
    local specs={};local kind=types[index]
    local function block(name,size,offset,color)
        -- Three separate studded pieces per original block, without increasing footprint.
        for section=1,3 do
            local axis=name=="Trunk" and Vector3.new(0,1,0) or Vector3.new(1,0,0)
            local span=name=="Trunk" and size.Y or size.X
            local pieceSize=name=="Trunk" and Vector3.new(size.X,size.Y/3,size.Z) or Vector3.new(size.X/3,size.Y,size.Z)
            local tint=color:Lerp(Color3.new(1,1,1),(section-1)*.025)
            table.insert(specs,{name=name,size=pieceSize,pos=origin+offset+axis*((section-2)*span/3),color=tint})
        end
    end
    block("Trunk",Vector3.new(.95,3.5,.95),Vector3.new(0,1.75,0),kind.wood)
    if index==1 then
        for tier=0,2 do
            local width=3.7-tier*.8
            block("Leaves",Vector3.new(width,1,width),Vector3.new(-tier*.1,3.5+tier*.9,0),kind.leaf:Lerp(Color3.fromRGB(145,198,88),tier*.18))
        end
        block("CrownTop",Vector3.new(1.5,.7,1.5),Vector3.new(-.2,6,0),kind.leaf)
    elseif index==2 then
        for i=1,5 do block("BarkMark",Vector3.new(1,.12,.98),Vector3.new(0,.4+i*.5,0),Color3.fromRGB(67,69,64)) end
        for tier=0,3 do
            local width=3.5-tier*.55
            block("Leaves",Vector3.new(width,.85,width*.8),Vector3.new(tier%2*.22,3.8+tier*.7,0),kind.leaf:Lerp(Color3.fromRGB(215,224,111),tier*.15))
        end
        block("CrownTop",Vector3.new(1.2,.6,1.2),Vector3.new(0,6.5,0),kind.leaf)
    else
        for i=1,6 do
            local a=i*math.pi/3
            block("Crystal",Vector3.new(.7,1.5+(i%2)*.6,.7),Vector3.new(math.cos(a)*1.15,4.2,math.sin(a)*1.15),i%2==0 and kind.leaf or Color3.fromRGB(179,153,247))
        end
        block("CrystalCore",Vector3.new(1.9,1.9,1.9),Vector3.new(0,4.9,0),kind.leaf)
        block("CrownTop",Vector3.new(.9,1.4,.9),Vector3.new(0,6.2,0),Color3.fromRGB(200,239,255))
    end
    for side=1,4 do
        local a=side*math.pi/2
        block("Root",Vector3.new(.8,.3,.8),Vector3.new(math.cos(a)*.7,.15,math.sin(a)*.7),kind.wood)
        block("Branch",Vector3.new(1.2,.3,.4),Vector3.new(math.cos(a)*.65,2.7+side*.12,math.sin(a)*.65),kind.wood)
    end
    for i=1,6 do
        local a=i*math.pi/3
        local tint=index==3 and Color3.fromRGB(211,238,255) or (index==2 and Color3.fromRGB(221,195,79) or Color3.fromRGB(203,77,50))
        block(index==3 and "SmallCrystal" or "Fruit",Vector3.new(.24,.32,.24),Vector3.new(math.cos(a)*1.5,3.8+i%2*.5,math.sin(a)*1.5),tint)
    end
    for _,part in tree:GetChildren() do if part:IsA("BasePart") then part:Destroy() end end
    for _,spec in specs do
        local part=Instance.new("Part");part.Name=spec.name;part.Anchored=true;part.CanCollide=false
        part.Size=instant and spec.size or spec.size*.3;part.Position=instant and spec.pos or spec.pos+Vector3.new(random:NextNumber(-3,3),3,random:NextNumber(-3,3))
        part.Color=spec.color;part.Material=Enum.Material.Plastic
        part.TopSurface=Enum.SurfaceType.Studs;part.BottomSurface=Enum.SurfaceType.Inlet;part.Parent=tree
        if not instant then TweenService:Create(part,TweenInfo.new(.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=spec.pos,Size=spec.size}):Play() end
        clickable(part)
        if spec.name=="CrownTop" then anchor.Position=spec.pos+Vector3.new(0,spec.size.Y/2+1.8,0) end
        if not instant then task.wait(.006) end
    end
    if not instant then task.wait(.55) end
    for _,part in tree:GetChildren() do if part:IsA("BasePart") then part.CanCollide=true end end
end
local prompt=Instance.new("ProximityPrompt")
prompt.Name="OpenTreeCase";prompt.ActionText="Open - 50 clicks";prompt.ObjectText="Tree Chest"
prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.HoldDuration=.5
prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false
prompt.Parent=chest:WaitForChild("Lock")
local nextOpenAt=0
local function openCase(player)
    if busy or os.clock()<nextOpenAt or balance<50 or not nearby(player,caseButton.Position,15) then return end
    prompt.Enabled=false
    busy=true;balance-=50;refresh()
    local roll=random:NextInteger(1,100)
    local chosen=roll<=70 and 1 or (roll<=95 and 2 or 3)
    local old=current
    local ok,err=pcall(function()
        caseVisuals.Open(types[chosen],chosen)
        if owned[chosen]>0 then
            caseText.Text="ROLLED: "..types[chosen].name.."\nALREADY OWNED - NO REWARD"
        else
            owned[chosen]=1
            table.insert(items,{kind=chosen,state={level=1,xp=0}})
            caseText.Text="ROLLED: "..types[chosen].name.."\nADDED TO INVENTORY"
        end
        task.wait(1.3)
    end)
    if not ok then balance+=50;warn("Tree case failed: "..tostring(err)) end
    nextOpenAt=os.clock()+.5
    busy=false;refresh()
    task.delay(.5,function() prompt.Enabled=true end)
end
prompt.Triggered:Connect(openCase)
Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil end)
refresh()

local function snapshot()
    local entries={}
    for kindIndex,kind in types do
        local itemId,item
        for id,candidate in items do
            if candidate.kind==kindIndex then itemId=id;item=candidate;break end
        end
        if item then
            local state=item.state
            table.insert(entries,{Id=kindIndex,ItemId=itemId,Owned=true,Name=kind.name,Level=state.level,XP=state.xp,Required=25*2^(state.level-1),Power=kind.power*2^(state.level-1),Equipped=equipped and currentItem==itemId})
        else
            table.insert(entries,{Id=kindIndex,Owned=false})
        end
    end
    return {Balance=balance,Entries=entries,Busy=busy}
end
inventory.OnServerInvoke=function(player,action,id)
    if action=="Get" then return snapshot() end
    if type(id)~="number" or id%1~=0 or not items[id] then return snapshot() end
    if action=="Unequip" and equipped and id==currentItem then
        equipped=false
        for _,part in tree:GetChildren() do if part:IsA("BasePart") then part:Destroy() end end
        refresh()
    elseif action=="Equip" and not (equipped and id==currentItem) then
        local item=items[id]
        local ok,err=pcall(function()
            if not equipped or current~=item.kind then rebuild(item.kind,true) end
        end)
        if ok then
            current=item.kind;currentItem=id
            progress[current]=item.state;equipped=true
        else warn(err) end
        refresh()
    end
    return snapshot()
end
-- One shared tick, regardless of player location or character state.
task.spawn(function()
    while task.wait(1) do
        if equipped and not busy then
            local player=Players:GetPlayers()[1]
            if player then clicked(player) end
        end
    end
end)
-- Apply the detailed starting design on launch as well.
busy=true
rebuild(current,true)
busy=false;refresh()
