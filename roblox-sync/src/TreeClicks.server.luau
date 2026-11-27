local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local tree=workspace:WaitForChild("LittleStudTree")
local trunk=tree:WaitForChild("Trunk")
local origin=Vector3.new(trunk.Position.X,0,trunk.Position.Z)
local count,level,busy=0,1,false
local lastClick={}
local random=Random.new()
tree:SetAttribute("Clicks",0)
tree:SetAttribute("Level",level)
local function sign(parent,adornee,name,offset,size)
    local gui=Instance.new("BillboardGui");gui.Name=name;gui.Adornee=adornee
    gui.Size=size;gui.StudsOffsetWorldSpace=offset;gui.AlwaysOnTop=true;gui.MaxDistance=70;gui.Parent=parent
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
    label.Font=Enum.Font.GothamBold;label.TextSize=22;label.TextColor3=Color3.new(1,1,1)
    label.TextStrokeColor3=Color3.fromRGB(20,35,20);label.TextStrokeTransparency=.1;label.Parent=gui
    return gui,label
end
local billboard,text=sign(tree,tree:WaitForChild("CrownTop"),"TreeClickCounter",Vector3.new(0,1.6,0),UDim2.fromOffset(210,55))
local button=Instance.new("Part");button.Name="TreeUpgradeButton";button.Anchored=true
button.Size=Vector3.new(4,.6,4);button.Position=origin+Vector3.new(7,.3,0)
button.Material=Enum.Material.Plastic;button.Color=Color3.fromRGB(233,180,63)
button.TopSurface=Enum.SurfaceType.Studs;button.BottomSurface=Enum.SurfaceType.Smooth;button.Parent=workspace
local _,upgradeText=sign(button,button,"UpgradeLabel",Vector3.new(0,2.1,0),UDim2.fromOffset(230,70))
upgradeText.TextSize=18
local function refresh()
    text.Text="Clicks: "..count
    tree:SetAttribute("Clicks",count);tree:SetAttribute("Level",level)
    upgradeText.Text=busy and "BUILDING..." or (level==2 and "MAX LEVEL" or "UPGRADE TREE\n50 CLICKS")
    button.Color=level==2 and Color3.fromRGB(110,125,115) or (count>=50 and Color3.fromRGB(88,193,99) or Color3.fromRGB(233,180,63))
end
local function nearby(player,position,range)
    local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
    local humanoid=char and char:FindFirstChildOfClass("Humanoid")
    return root and humanoid and humanoid.Health>0 and (root.Position-position).Magnitude<=range
end
local function clicked(player)
    if busy or not nearby(player,origin,28) then return end
    local now=os.clock()
    if lastClick[player] and now-lastClick[player]<.08 then return end
    lastClick[player]=now;count+=1;refresh()
end
local function clickable(part)
    local detector=Instance.new("ClickDetector");detector.Name="TreeClick";detector.MaxActivationDistance=24
    detector.Parent=part;detector.MouseClick:Connect(clicked)
end
for _,part in tree:GetDescendants() do if part:IsA("BasePart") then clickable(part) end end
local function upgrade(player)
    if busy or level>=2 or count<50 or not nearby(player,button.Position,24) then return end
    busy=true;count-=50;refresh()
    local ok,err=pcall(function()
        -- Move the counter off geometry before replacing it.
        billboard.Adornee=button;billboard.StudsOffsetWorldSpace=Vector3.new(-7,10,0)
        local old={}
        for _,part in tree:GetChildren() do
            if part:IsA("BasePart") then
                table.insert(old,part)
                local tween=TweenService:Create(part,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
                    Position=part.Position+Vector3.new(random:NextNumber(-2,2),-3,random:NextNumber(-2,2)),Transparency=1,Size=part.Size*.3})
                part.CanCollide=false;tween:Play()
            end
        end
        task.wait(.42)
        for _,part in old do part:Destroy() end
        local blocks={}
        local function block(name,size,position,color)
            table.insert(blocks,{name=name,size=size,position=origin+position,color=color})
        end
        local brown=Color3.fromRGB(108,70,40)
        for y=0,5 do block("Trunk"..y,Vector3.new(1.6,1,1.6),Vector3.new(0,y+.5,0),brown) end
        for _,v in {Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)} do
            block("Root",Vector3.new(1,.5,1),v*1.1+Vector3.new(0,.25,0),brown)
        end
        -- Tiered spruce silhouette, made entirely from individual stud blocks.
        for tier=0,3 do
            local radius=3-tier*.65;local y=3.8+tier*1.6
            local green=Color3.fromRGB(42+tier*9,108+tier*16,65+tier*6)
            for x=-1,1 do for z=-1,1 do
                if not (tier==3 and math.abs(x)+math.abs(z)>1) then
                    local width=radius*2/3
                    block("SpruceFoliage",Vector3.new(width,1.1,width),Vector3.new(x*width,y,z*width),green)
                end
            end end
        end
        block("CrownTop",Vector3.new(1.3,1.3,1.3),Vector3.new(0,9.7,0),Color3.fromRGB(102,177,89))
        local top
        for i,spec in blocks do
            local part=Instance.new("Part");part.Name=spec.name;part.Anchored=true;part.CanCollide=false
            part.Material=Enum.Material.Plastic;part.Color=spec.color;part.Size=spec.size*.2;part.Transparency=.35
            part.TopSurface=Enum.SurfaceType.Studs;part.BottomSurface=Enum.SurfaceType.Inlet
            part.Position=spec.position+Vector3.new(random:NextNumber(-5,5),random:NextNumber(3,6),random:NextNumber(-5,5))
            part.Parent=tree
            local tween=TweenService:Create(part,TweenInfo.new(.65,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=spec.position,Size=spec.size,Transparency=0})
            tween:Play();clickable(part)
            if spec.name=="CrownTop" then top=part end
            task.wait(.025)
        end
        task.wait(.7)
        for _,part in tree:GetChildren() do if part:IsA("BasePart") then part.CanCollide=true end end
        billboard.Adornee=top;billboard.StudsOffsetWorldSpace=Vector3.new(0,1.6,0)
        level=2
    end)
    if not ok then
        warn("Tree upgrade failed: "..tostring(err));count+=50
    end
    busy=false;refresh()
end
local upgradeDetector=Instance.new("ClickDetector");upgradeDetector.MaxActivationDistance=20
upgradeDetector.Parent=button;upgradeDetector.MouseClick:Connect(upgrade)
Players.PlayerRemoving:Connect(function(player) lastClick[player]=nil end)
refresh()
