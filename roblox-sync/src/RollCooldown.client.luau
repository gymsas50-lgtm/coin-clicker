local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local button, ui = script.Parent, script.Parent.Parent
local cooldown = ui:WaitForChild("Cooldown")
local folder = ReplicatedStorage:WaitForChild("AuraRNG")
local config = require(folder:WaitForChild("Config"))
local request, result = folder:WaitForChild("RollRequest"), folder:WaitForChild("RollResult")
local inventoryRemote = folder:WaitForChild("Inventory")
local busy, auto, started, inventoryBusy = false, false, 0, false
local owned, equipped = {}, 0
local white = Color3.fromRGB(237,237,237)
local muted = Color3.fromRGB(166,166,166)
local function rounded(object,radius)
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,radius or 12);c.Parent=object
end
local function label(parent,name,text,pos,size,fontSize,color)
    local t=Instance.new("TextLabel");t.Name=name;t.BackgroundTransparency=1;t.Position=pos;t.Size=size
    t.Text=text;t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize;t.TextColor3=color or white;t.Parent=parent;return t
end
local function panel(name,pos,size)
    local f=Instance.new("Frame");f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=Color3.fromRGB(22,22,22)
    f.BackgroundTransparency=.35;f.BorderSizePixel=0;f.Parent=ui;rounded(f,14)
    local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(87,87,87);stroke.Transparency=.4;stroke.Parent=f;return f
end
local stats=panel("SessionStats",UDim2.new(0,18,.5,0),UDim2.fromOffset(48,48))
stats.AnchorPoint=Vector2.new(0,.5)
stats.BackgroundTransparency=1
for _, child in stats:GetChildren() do if child:IsA("UIStroke") then child.Enabled=false end end
local counter={Text=""}
local equippedText={Text="",TextColor3=white}
local inventoryButton=Instance.new("TextButton");inventoryButton.Name="InventoryButton"
inventoryButton.Position=UDim2.fromOffset(0,0);inventoryButton.Size=UDim2.fromOffset(48,48)
inventoryButton.BackgroundColor3=Color3.fromRGB(32,32,32);inventoryButton.BackgroundTransparency=.35;inventoryButton.BorderSizePixel=0
inventoryButton.Text="";inventoryButton.Parent=stats;rounded(inventoryButton,9)
-- Draw a small inventory grid with UI primitives: no text or external image.
for row=0,1 do
    for column=0,1 do
        local cell=Instance.new("Frame");cell.Name="IconCell"
        cell.Size=UDim2.fromOffset(9,9);cell.Position=UDim2.fromOffset(13+column*13,13+row*13)
        cell.BackgroundColor3=Color3.fromRGB(228,228,228);cell.BorderSizePixel=0;cell.Parent=inventoryButton;rounded(cell,2)
    end
end
local card=panel("RollResult",UDim2.new(.5,0,.35,0),UDim2.fromOffset(320,150));card.AnchorPoint=Vector2.new(.5,.5);card.Visible=false
card.BackgroundTransparency=1
for _, child in card:GetChildren() do if child:IsA("UIStroke") then child.Enabled=false end end
local auraName=label(card,"AuraName","",UDim2.fromOffset(10,43),UDim2.new(1,-20,0,38),28)
local chance=label(card,"Chance","",UDim2.fromOffset(10,86),UDim2.new(1,-20,0,22),16)
local reel=Instance.new("Frame");reel.Name="RollingReel";reel.Position=UDim2.fromOffset(10,29)
reel.Size=UDim2.new(1,-20,0,64);reel.BackgroundTransparency=1;reel.ClipsDescendants=true;reel.Visible=false;reel.Parent=card
local strip=Instance.new("Frame");strip.Name="Names";strip.BackgroundTransparency=1;strip.Size=UDim2.new(1,0,0,1200);strip.Parent=reel
local note={Text=""}
auraName.TextStrokeTransparency=.55;chance.TextStrokeTransparency=.65
local resultToken=0
local presentationActive=false
local resultTweens={}
local function revealResult()
    presentationActive=true
    resultToken+=1
    for _, tween in resultTweens do tween:Cancel() end
    table.clear(resultTweens)
    auraName.TextTransparency=0;chance.TextTransparency=0
    auraName.TextStrokeTransparency=.55;chance.TextStrokeTransparency=.65
    return resultToken
end
local function fadeResult(token)
    task.delay(.65,function()
        if token~=resultToken then return end
        for _, text in {auraName,chance} do
            local tween=TweenService:Create(text,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=1,TextStrokeTransparency=1})
            table.insert(resultTweens,tween);tween:Play()
        end
        task.delay(.65,function() if token==resultToken then presentationActive=false;card.Visible=false end end)
    end)
end
local inv=panel("InventoryPanel",UDim2.fromScale(.5,.45),UDim2.new(.92,0,.68,0));inv.AnchorPoint=Vector2.new(.5,.5);inv.Visible=false
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(560,520);limit.Parent=inv
label(inv,"Title","AURA INVENTORY",UDim2.fromOffset(18,13),UDim2.new(1,-75,0,30),18)

local close=Instance.new("TextButton");close.Size=UDim2.fromOffset(32,32);close.Position=UDim2.new(1,-44,0,12);close.Text="X";close.Font=Enum.Font.GothamBold;close.TextSize=15;close.TextColor3=white;close.BackgroundTransparency=1;close.Parent=inv
local list=Instance.new("ScrollingFrame")
list.Name="AuraSlots";list.Position=UDim2.fromOffset(10,60);list.Size=UDim2.new(1,-20,1,-72)
list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=4
list.ScrollBarImageColor3=Color3.fromRGB(119,119,119);list.ScrollingDirection=Enum.ScrollingDirection.Y
list.CanvasSize=UDim2.fromOffset(0,0);list.Parent=inv
local grid=Instance.new("UIGridLayout");grid.SortOrder=Enum.SortOrder.LayoutOrder
 grid.CellPadding=UDim2.fromOffset(10,10);grid.Parent=list
local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,4);padding.PaddingTop=UDim.new(0,4);padding.Parent=list
local function resizeGrid()
    local width=math.max(1,list.AbsoluteSize.X-18)
    local columns=width>=380 and 3 or 2
    local size=math.max(70,math.floor((width-(columns-1)*10)/columns))
    grid.CellSize=UDim2.fromOffset(size,size)
    grid.FillDirectionMaxCells=columns
    list.CanvasSize=UDim2.fromOffset(0,grid.AbsoluteContentSize.Y+12)
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)
grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize=UDim2.fromOffset(0,grid.AbsoluteContentSize.Y+12) end)
local rows={}
for i,aura in config do
    local slot=Instance.new("Frame");slot.Name="Slot"..i;slot.LayoutOrder=i
    slot.BackgroundColor3=Color3.fromRGB(36,36,36);slot.BackgroundTransparency=.45;slot.BorderSizePixel=0;slot.Parent=list;rounded(slot,10)
    local border=Instance.new("UIStroke");border.Thickness=1;border.Color=Color3.fromRGB(65,65,65);border.Parent=slot
    local icon=Instance.new("Frame");icon.Name="AuraIcon";icon.AnchorPoint=Vector2.new(.5,.5)
    icon.Position=UDim2.fromScale(.5,.18);icon.Size=UDim2.fromScale(.13,.13);icon.Rotation=45
    icon.BorderSizePixel=0;icon.BackgroundColor3=muted;icon.Parent=slot;rounded(icon,2)
    local title=label(slot,"Name","??? ??????",UDim2.new(0,5,.33,0),UDim2.new(1,-10,.18,0),16,muted)
    title.TextScaled=true
    local textLimit=Instance.new("UITextSizeConstraint");textLimit.MinTextSize=10;textLimit.MaxTextSize=17;textLimit.Parent=title
    local count=label(slot,"Count","??? ??",UDim2.new(0,4,.53,0),UDim2.new(1,-8,.19,0),11,muted)
    count.TextWrapped=true
    local action=Instance.new("TextButton");action.Name="Equip";action.AnchorPoint=Vector2.new(.5,1)
    action.Size=UDim2.new(1,-16,0,26);action.Position=UDim2.new(.5,0,1,-7)
    action.BackgroundTransparency=.35;action.BorderSizePixel=0;action.Font=Enum.Font.GothamBold;action.TextSize=10;action.TextColor3=white;action.Parent=slot;rounded(action,6)
    rows[i]={frame=slot,title=title,count=count,action=action,icon=icon,border=border}
end
resizeGrid()

local rarityOrder={}
for i=1,#config do table.insert(rarityOrder,i) end
table.sort(rarityOrder,function(a,b) return config[a].Weight>config[b].Weight end)
local rarityRank={}
for rank,index in rarityOrder do rarityRank[index]=rank end
local function apply(data)
    if not data then return end
    owned=data.Owned or owned;equipped=data.Equipped or 0
    counter.Text="Rolls  :  "..tostring(data.Rolls or 0)
    equippedText.Text="Equipped  :  "..(config[equipped] and config[equipped].Name or "None")
    equippedText.TextColor3=white
    for i,row in rows do
        local count=owned[i] or 0
        row.frame.LayoutOrder=rarityRank[i]
        row.title.Text=count>0 and config[i].Name or "??? ??????"
        row.title.TextColor3=count>0 and config[i].Color or muted
        row.count.Text=count>0 and (config[i].Chance.."  |  x"..count) or "??? ??"
        row.icon.BackgroundColor3=count>0 and config[i].Color or Color3.fromRGB(88,88,88)
        row.border.Color=equipped==i and config[i].Color or Color3.fromRGB(65,65,65)
        row.border.Thickness=equipped==i and 2 or 1
        row.action.Visible=count>0
        row.action.Text=count==0 and "LOCKED" or (equipped==i and "UNEQUIP" or "EQUIP")
        row.action.BackgroundColor3=count==0 and Color3.fromRGB(38,38,38) or (equipped==i and Color3.fromRGB(65,65,65) or Color3.fromRGB(232,232,232))
        row.action.TextColor3=equipped==i and white or Color3.fromRGB(15,15,15)
        row.action.AutoButtonColor=count>0
    end
end
for i,row in rows do
    row.action.Activated:Connect(function()
        if inventoryBusy or (owned[i] or 0)<1 then return end
        inventoryBusy=true
        local ok,data=pcall(function() return inventoryRemote:InvokeServer(equipped==i and "Unequip" or "Equip",i) end)
        if ok then apply(data) end
        inventoryBusy=false
    end)
end
button.Size=UDim2.fromOffset(140,52);button.BackgroundColor3=Color3.fromRGB(20,20,20);button.BackgroundTransparency=.35;button.TextColor3=white
button.TextTransparency=1
local rollCaption=label(button,"Caption",button.Text,UDim2.fromScale(0,0),UDim2.fromScale(1,1),22,white)
rollCaption.Font=Enum.Font.GothamBold;rollCaption.TextStrokeTransparency=.55;rollCaption.ZIndex=button.ZIndex+3
button:GetPropertyChangedSignal("Text"):Connect(function() rollCaption.Text=button.Text end)
local rollOutline=button:FindFirstChildOfClass("UIStroke")
if not rollOutline then rollOutline=Instance.new("UIStroke");rollOutline.Parent=button end
rollOutline.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;rollOutline.Thickness=2
rollOutline.Color=Color3.fromRGB(240,240,240);rollOutline.Transparency=.25
local progressTrack=Instance.new("Frame");progressTrack.Name="RollProgress"
progressTrack.Position=UDim2.fromScale(0,0);progressTrack.Size=UDim2.fromScale(1,1)
progressTrack.BackgroundTransparency=1;progressTrack.BorderSizePixel=0;progressTrack.ZIndex=button.ZIndex+1
progressTrack.Visible=false;progressTrack.ClipsDescendants=true;progressTrack.Parent=button;rounded(progressTrack,12)
local progressFill=Instance.new("Frame");progressFill.Name="Remaining"
progressFill.Size=UDim2.fromScale(1,1);progressFill.BackgroundColor3=Color3.fromRGB(240,240,240);progressFill.BackgroundTransparency=.72;progressFill.ZIndex=button.ZIndex+1
progressFill.BorderSizePixel=0;progressFill.Parent=progressTrack;rounded(progressFill,12)
local progressTween
local function resetProgress()
    if progressTween then progressTween:Cancel();progressTween=nil end
    progressTrack.Visible=false;progressFill.Size=UDim2.fromScale(1,1)
end
local function startProgress()
    if progressTween then progressTween:Cancel() end
    progressTrack.Visible=true;progressFill.Size=UDim2.fromScale(1,1)
    progressTween=TweenService:Create(progressFill,TweenInfo.new(3,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(0,1)})
    progressTween:Play()
end
local autoButton=Instance.new("TextButton");autoButton.AnchorPoint=Vector2.new(.5,1);autoButton.Position=UDim2.new(.5,-118,1,-24);autoButton.Size=UDim2.fromOffset(76,52)
autoButton.BackgroundColor3=Color3.fromRGB(32,32,32);autoButton.BackgroundTransparency=.35;autoButton.BorderSizePixel=0;autoButton.Text="AUTO: OFF";autoButton.TextSize=11;autoButton.Font=Enum.Font.GothamBold;autoButton.TextColor3=white;autoButton.Parent=ui;rounded(autoButton)

local roll
local function finish()
    resetProgress()
    busy=false;button.Active=true;button.AutoButtonColor=true;button.Text="ROLL";cooldown.Visible=false
    if auto then task.delay(.08,function() if auto then roll() end end) end
end
roll=function()
    if busy then return end
    busy=true;started=os.clock();button.Active=false;button.AutoButtonColor=false;button.Text="ROLL";cooldown.Visible=false
    progressTrack.Visible=true;progressFill.Size=UDim2.fromScale(1,1)
    request:FireServer()
    local token=started
    task.delay(10,function() if busy and started==token then auto=false;autoButton.Text="AUTO: OFF";note.Text="Server unavailable. Try again.";finish() end end)
end
button.Activated:Connect(roll)
autoButton.Activated:Connect(function()
    auto=not auto;autoButton.Text=auto and "AUTO: ON" or "AUTO: OFF"
    if auto and not busy then roll() end
end)
inventoryButton.Activated:Connect(function()
    inv.Visible=not inv.Visible
    if inv.Visible then
        card.Visible=false
        task.spawn(function() local ok,data=pcall(function() return inventoryRemote:InvokeServer("Get") end);if ok then apply(data) end end)
    else
        card.Visible=presentationActive
    end
end)
close.Activated:Connect(function()
    inv.Visible=false
    card.Visible=presentationActive
end)
result.OnClientEvent:Connect(function(data)
    if data.Error then task.delay(math.max(.05,data.Remaining or .1),finish);return end
    if not busy then busy=true;started=os.clock() end
    apply(data);local token=revealResult();card.Visible=not inv.Visible;note.Text=""
    local aura=config[data.Index]
    if not aura then finish();return end
    auraName.Visible=false;chance.Text="";reel.Visible=true
    strip:ClearAllChildren();strip.Position=UDim2.fromOffset(0,8)
    local stopIndex=19
    for i=0,stopIndex+1 do
        local item=i==stopIndex and aura or config[math.random(1,#config)]
        local text=label(strip,"ReelName",item.Name,UDim2.fromOffset(0,i*48),UDim2.new(1,0,0,48),28,item.Color)
        text.TextStrokeTransparency=.55
    end
    local spin=TweenService:Create(strip,TweenInfo.new(3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(0,8-stopIndex*48)})
    startProgress()
    spin:Play();spin.Completed:Wait()
    reel.Visible=false;auraName.Visible=true
    auraName.Text=aura.Name;auraName.TextColor3=aura.Color
    chance.Text=aura.Chance
    note.Text=""
    fadeResult(token)
    local ok,updated=pcall(function() return inventoryRemote:InvokeServer("Complete",data.Token) end)
    if ok then apply(updated) end
    finish()
end)
apply({Owned={},Equipped=0,Rolls=0})
task.spawn(function() local ok,data=pcall(function() return inventoryRemote:InvokeServer("Get") end);if ok then apply(data) end end)
