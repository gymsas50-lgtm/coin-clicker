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
local white = Color3.fromRGB(232,237,249)
local muted = Color3.fromRGB(151,168,193)
local function rounded(object,radius)
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,radius or 12);c.Parent=object
end
local function label(parent,name,text,pos,size,fontSize,color)
    local t=Instance.new("TextLabel");t.Name=name;t.BackgroundTransparency=1;t.Position=pos;t.Size=size
    t.Text=text;t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize;t.TextColor3=color or white;t.Parent=parent;return t
end
local function panel(name,pos,size)
    local f=Instance.new("Frame");f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=Color3.fromRGB(17,22,34)
    f.BackgroundTransparency=.08;f.BorderSizePixel=0;f.Parent=ui;rounded(f,14)
    local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(71,88,124);stroke.Transparency=.4;stroke.Parent=f;return f
end
local stats=panel("SessionStats",UDim2.fromOffset(18,18),UDim2.fromOffset(48,48))
local counter={Text=""}
local equippedText={Text="",TextColor3=white}
local inventoryButton=Instance.new("TextButton");inventoryButton.Name="InventoryButton"
inventoryButton.Position=UDim2.fromOffset(0,0);inventoryButton.Size=UDim2.fromOffset(48,48)
inventoryButton.BackgroundColor3=Color3.fromRGB(25,32,47);inventoryButton.BorderSizePixel=0
inventoryButton.Text="";inventoryButton.Parent=stats;rounded(inventoryButton,9)
-- Draw a small inventory grid with UI primitives: no text or external image.
for row=0,1 do
    for column=0,1 do
        local cell=Instance.new("Frame");cell.Name="IconCell"
        cell.Size=UDim2.fromOffset(9,9);cell.Position=UDim2.fromOffset(13+column*13,13+row*13)
        cell.BackgroundColor3=Color3.fromRGB(218,229,247);cell.BorderSizePixel=0;cell.Parent=inventoryButton;rounded(cell,2)
    end
end
local card=panel("RollResult",UDim2.new(.5,0,.35,0),UDim2.fromOffset(320,150));card.AnchorPoint=Vector2.new(.5,.5);card.Visible=false
card.BackgroundTransparency=1
for _, child in card:GetChildren() do if child:IsA("UIStroke") then child.Enabled=false end end
local auraName=label(card,"AuraName","",UDim2.fromOffset(10,43),UDim2.new(1,-20,0,38),28)
local chance=label(card,"Chance","",UDim2.fromOffset(10,86),UDim2.new(1,-20,0,22),16)
local note={Text=""}
auraName.TextStrokeTransparency=.55;chance.TextStrokeTransparency=.65
local resultToken=0
local resultTweens={}
local function revealResult()
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
        task.delay(.65,function() if token==resultToken then card.Visible=false end end)
    end)
end
local inv=panel("InventoryPanel",UDim2.fromScale(.5,.45),UDim2.new(.92,0,0,325));inv.AnchorPoint=Vector2.new(.5,.5);inv.Visible=false
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(420,325);limit.Parent=inv
label(inv,"Title","AURA INVENTORY",UDim2.fromOffset(18,13),UDim2.new(1,-75,0,30),18)

local close=Instance.new("TextButton");close.Size=UDim2.fromOffset(32,32);close.Position=UDim2.new(1,-44,0,12);close.Text="X";close.Font=Enum.Font.GothamBold;close.TextSize=15;close.TextColor3=white;close.BackgroundTransparency=1;close.Parent=inv
local rows={}
for i,aura in config do
    local row=Instance.new("Frame");row.Name=aura.Id;row.Size=UDim2.new(1,-28,0,66);row.Position=UDim2.fromOffset(14,78+(i-1)*75)
    row.BackgroundColor3=Color3.fromRGB(29,36,52);row.BorderSizePixel=0;row.Parent=inv;rounded(row,9)
    local title=label(row,"Name",aura.Name,UDim2.fromOffset(12,8),UDim2.new(1,-116,0,24),17,aura.Color);title.TextXAlignment=Enum.TextXAlignment.Left
    local count=label(row,"Count",aura.Chance.."  |  Owned: 0",UDim2.fromOffset(12,35),UDim2.new(1,-116,0,22),11,muted);count.TextXAlignment=Enum.TextXAlignment.Left
    local action=Instance.new("TextButton");action.Name="Equip";action.Size=UDim2.fromOffset(90,34);action.Position=UDim2.new(1,-101,.5,-17)
    action.BorderSizePixel=0;action.Font=Enum.Font.GothamBold;action.TextSize=11;action.TextColor3=white;action.Parent=row;rounded(action,7)
    rows[i]={count=count,action=action}
end

local function apply(data)
    if not data then return end
    owned=data.Owned or owned;equipped=data.Equipped or 0
    counter.Text="Rolls  :  "..tostring(data.Rolls or 0)
    equippedText.Text="Equipped  :  "..(config[equipped] and config[equipped].Name or "None")
    equippedText.TextColor3=config[equipped] and config[equipped].Color or white
    for i,row in rows do
        local count=owned[i] or 0
        row.count.Text=config[i].Chance.."  |  Owned: "..count
        row.action.Text=count==0 and "LOCKED" or (equipped==i and "UNEQUIP" or "EQUIP")
        row.action.BackgroundColor3=count==0 and Color3.fromRGB(42,46,57) or (equipped==i and Color3.fromRGB(96,65,55) or Color3.fromRGB(52,79,119))
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
button.Size=UDim2.fromOffset(140,52);button.BackgroundColor3=Color3.fromRGB(65,91,153)
local autoButton=Instance.new("TextButton");autoButton.AnchorPoint=Vector2.new(.5,1);autoButton.Position=UDim2.new(.5,-118,1,-24);autoButton.Size=UDim2.fromOffset(76,52)
autoButton.BackgroundColor3=Color3.fromRGB(25,32,47);autoButton.BorderSizePixel=0;autoButton.Text="AUTO: OFF";autoButton.TextSize=11;autoButton.Font=Enum.Font.GothamBold;autoButton.TextColor3=white;autoButton.Parent=ui;rounded(autoButton)

local roll
local function finish()
    busy=false;button.Active=true;button.AutoButtonColor=true;button.Text="ROLL";cooldown.Visible=false
    if auto then task.delay(.08,function() if auto then roll() end end) end
end
roll=function()
    if busy then return end
    inv.Visible=false;busy=true;started=os.clock();button.Active=false;button.AutoButtonColor=false;button.Text="...";cooldown.Visible=true;cooldown.Text="1"
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
        auto=false;autoButton.Text="AUTO: OFF";card.Visible=false
        task.spawn(function() local ok,data=pcall(function() return inventoryRemote:InvokeServer("Get") end);if ok then apply(data) end end)
    end
end)
close.Activated:Connect(function() inv.Visible=false end)
RunService.RenderStepped:Connect(function()
    if busy then local remaining=math.max(0,1-(os.clock()-started));cooldown.Text=remaining>.95 and "1" or string.format("%.1f",math.ceil(remaining*10)/10) end
end)
result.OnClientEvent:Connect(function(data)
    if data.Error then task.delay(math.max(.05,data.Remaining or .1),finish);return end
    if not busy then busy=true;started=os.clock() end
    apply(data);local token=revealResult();card.Visible=not inv.Visible;note.Text=""
    for i=1,9 do
        local preview=config[math.random(1,#config)];auraName.Text=preview.Name;auraName.TextColor3=preview.Color;chance.Text="...";task.wait(.045+i*.003)
    end
    local aura=config[data.Index]
    auraName.Text=aura and aura.Name or "NO AURA";auraName.TextColor3=aura and aura.Color or muted
    chance.Text=aura and aura.Chance or "No drop"
    note.Text=aura and ("Added to inventory  |  Owned: "..tostring(data.Count)) or "Your inventory is unchanged."
    fadeResult(token)
    local remaining=1-(os.clock()-started);if remaining>0 then task.wait(remaining) end
    finish()
end)
apply({Owned={},Equipped=0,Rolls=0})
task.spawn(function() local ok,data=pcall(function() return inventoryRemote:InvokeServer("Get") end);if ok then apply(data) end end)
