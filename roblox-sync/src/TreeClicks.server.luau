local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local tree=workspace:WaitForChild("LittleStudTree")
local trunk=tree:WaitForChild("Trunk")
local origin=Vector3.new(trunk.Position.X,0,trunk.Position.Z)
local caseButton=workspace:WaitForChild("TreeCaseButton")
local random=Random.new()
local types={
    {name="Oak",weight=70,power=1,leaf=Color3.fromRGB(69,144,65),wood=Color3.fromRGB(108,70,40)},
    {name="Birch",weight=25,power=2,leaf=Color3.fromRGB(159,185,65),wood=Color3.fromRGB(226,222,205)},
    {name="Crystal",weight=5,power=4,leaf=Color3.fromRGB(126,194,235),wood=Color3.fromRGB(106,116,155)},
}
local progress={{level=1,xp=0},{level=1,xp=0},{level=1,xp=0}}
local current,balance,busy=1,0,false
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
caseGui.Size=UDim2.fromOffset(260,100);caseGui.StudsOffsetWorldSpace=Vector3.new(0,2.5,0);caseGui.AlwaysOnTop=true;caseGui.MaxDistance=80;caseGui.Parent=caseButton
local caseText=label(caseGui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),16)
local fillTween
local function refresh()
    local state=progress[current]
    title.Text=types[current].name.." | Lv. "..state.level
    clicks.Text="Clicks: "..string.format("%.0f",balance).." | +"..string.format("%.0f",power())
    xpText.Text="XP "..state.xp.." / "..string.format("%.0f",required())
    if fillTween then fillTween:Cancel() end
    fillTween=TweenService:Create(fill,TweenInfo.new(.18),{Size=UDim2.fromScale(math.clamp(state.xp/required(),0,1),1)});fillTween:Play()
    caseText.Text=busy and "OPENING..." or "TREE CASE - 50 CLICKS\nOak 70% | Birch 25%\nCrystal 5%"
    caseButton.Color=balance>=50 and Color3.fromRGB(85,184,108) or Color3.fromRGB(218,170,64)
    tree:SetAttribute("Clicks",balance);tree:SetAttribute("Level",state.level)
    tree:SetAttribute("XP",state.xp);tree:SetAttribute("ClickPower",power());tree:SetAttribute("TreeType",types[current].name)
end
local function nearby(player,target,range)
    local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
    local h=char and char:FindFirstChildOfClass("Humanoid")
    return root and h and h.Health>0 and (root.Position-target).Magnitude<=range
end
local function clicked(player)
    if busy or not nearby(player,origin,26) then return end
    local now=os.clock();if cooldown[player] and now-cooldown[player]<.08 then return end
    cooldown[player]=now;balance+=power()
    local state=progress[current];state.xp+=1
    while state.xp>=required() do state.xp-=required();state.level+=1 end
    refresh()
end
local function clickable(part)
    local detector=Instance.new("ClickDetector");detector.MaxActivationDistance=24;detector.Parent=part
    detector.MouseClick:Connect(clicked)
end
for _,part in tree:GetDescendants() do if part:IsA("BasePart") then clickable(part) end end
local top=tree:WaitForChild("CrownTop")
anchor.Position=Vector3.new(origin.X,top.Position.Y+top.Size.Y/2+1.8,origin.Z)
local function rebuild(index)
    local specs={};local kind=types[index]
    local function block(name,size,offset,color)
        table.insert(specs,{name=name,size=size,pos=origin+offset,color=color})
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
    for _,part in tree:GetChildren() do if part:IsA("BasePart") then part:Destroy() end end
    for _,spec in specs do
        local part=Instance.new("Part");part.Name=spec.name;part.Anchored=true;part.CanCollide=false
        part.Size=spec.size*.3;part.Position=spec.pos+Vector3.new(random:NextNumber(-3,3),3,random:NextNumber(-3,3))
        part.Color=spec.color;part.Material=Enum.Material.Plastic
        part.TopSurface=Enum.SurfaceType.Studs;part.BottomSurface=Enum.SurfaceType.Inlet;part.Parent=tree
        TweenService:Create(part,TweenInfo.new(.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=spec.pos,Size=spec.size}):Play()
        clickable(part)
        if spec.name=="CrownTop" then anchor.Position=spec.pos+Vector3.new(0,spec.size.Y/2+1.8,0) end
        task.wait(.035)
    end
    task.wait(.55)
    for _,part in tree:GetChildren() do if part:IsA("BasePart") then part.CanCollide=true end end
end
local caseDetector=Instance.new("ClickDetector");caseDetector.MaxActivationDistance=20;caseDetector.Parent=caseButton
caseDetector.MouseClick:Connect(function(player)
    if busy or balance<50 or not nearby(player,caseButton.Position,24) then return end
    busy=true;balance-=50;refresh()
    local roll=random:NextInteger(1,100)
    local chosen=roll<=70 and 1 or (roll<=95 and 2 or 3)
    local old=current
    local ok,err=pcall(function()
        task.wait(.4)
        if chosen~=current then rebuild(chosen) end
        current=chosen
        caseText.Text="ROLLED: "..types[chosen].name..(chosen==old and "\nDUPLICATE - XP KEPT" or "")
        task.wait(1.3)
    end)
    if not ok then balance+=50;warn("Tree case failed: "..tostring(err)) end
    busy=false;refresh()
end)
Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil end)
refresh()
