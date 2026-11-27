local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local button, ui = script.Parent, script.Parent.Parent
local cooldown = ui:WaitForChild("Cooldown")
local folder = ReplicatedStorage:WaitForChild("AuraRNG")
local config = require(folder:WaitForChild("Config"))
local request, result = folder:WaitForChild("RollRequest"), folder:WaitForChild("RollResult")
local busy, auto, started = false, false, 0
local white = Color3.fromRGB(232,237,249)
local function label(parent,name,text,pos,size,fontSize,color)
    local t=Instance.new("TextLabel")
    t.Name=name;t.BackgroundTransparency=1;t.Position=pos;t.Size=size
    t.Text=text;t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize;t.TextColor3=color or white
    t.Parent=parent;return t
end
local function panel(name,pos,size)
    local f=Instance.new("Frame");f.Name=name;f.Position=pos;f.Size=size
    f.BackgroundColor3=Color3.fromRGB(17,22,34);f.BackgroundTransparency=.12;f.BorderSizePixel=0;f.Parent=ui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=f
    local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(71,88,124);stroke.Transparency=.45;stroke.Parent=f
    return f
end
local stats=panel("SessionStats",UDim2.fromOffset(18,18),UDim2.fromOffset(240,108))
label(stats,"Heading","A U R A  /  R N G",UDim2.fromOffset(16,10),UDim2.fromOffset(208,24),16)
local counter=label(stats,"RollCount","Роллы  ·  0",UDim2.fromOffset(16,40),UDim2.fromOffset(208,22),14,Color3.fromRGB(165,181,211))
local best=label(stats,"Best","Лучшая  ·  —",UDim2.fromOffset(12,70),UDim2.fromOffset(216,22),13)
local card=panel("RollResult",UDim2.new(.5,0,.35,0),UDim2.fromOffset(330,156));card.AnchorPoint=Vector2.new(.5,.5);card.Visible=false
local cap=label(card,"Caption","ТВОЯ АУРА",UDim2.fromOffset(10,13),UDim2.new(1,-20,0,22),11,Color3.fromRGB(156,174,204))
local name=label(card,"AuraName","",UDim2.fromOffset(10,42),UDim2.new(1,-20,0,40),28)
local chance=label(card,"Chance","",UDim2.fromOffset(10,89),UDim2.new(1,-20,0,22),16)
local note=label(card,"Note","",UDim2.fromOffset(10,121),UDim2.new(1,-20,0,20),11,Color3.fromRGB(151,168,193))
button.BackgroundColor3=Color3.fromRGB(65,91,153)
button.Size=UDim2.fromOffset(140,52)
local autoButton=Instance.new("TextButton");autoButton.Name="AutoRoll";autoButton.AnchorPoint=Vector2.new(.5,1)
autoButton.Position=UDim2.new(.5,-118,1,-24);autoButton.Size=UDim2.fromOffset(76,52)
autoButton.BackgroundColor3=Color3.fromRGB(25,32,47);autoButton.BorderSizePixel=0
autoButton.Text="AUTO: OFF";autoButton.TextSize=11;autoButton.Font=Enum.Font.GothamBold;autoButton.TextColor3=white;autoButton.Parent=ui
local ac=Instance.new("UICorner");ac.CornerRadius=UDim.new(0,12);ac.Parent=autoButton
local hint=label(ui,"Hint","Лучшая аура экипируется автоматически · прогресс только в этой сессии",UDim2.new(.5,0,1,-125),UDim2.new(.92,0,0,20),11,Color3.fromRGB(173,187,209));hint.AnchorPoint=Vector2.new(.5,1);hint.TextWrapped=true
local roll
local function finish()
    busy=false;button.Active=true;button.AutoButtonColor=true;button.Text="ROLL"
    cooldown.Visible=false
    if auto then task.delay(.08,function() if auto then roll() end end) end
end
roll=function()
    if busy then return end
    busy=true;started=os.clock();button.Active=false;button.AutoButtonColor=false;button.Text="…"
    cooldown.Visible=true;cooldown.Text="1"
    request:FireServer()
    local token=started
    task.delay(10,function() if busy and started==token then note.Text="Нет ответа сервера. Попробуй ещё раз.";auto=false;autoButton.Text="AUTO: OFF";finish() end end)
end
button.Activated:Connect(roll)
autoButton.Activated:Connect(function()
    auto=not auto;autoButton.Text=auto and "AUTO: ON" or "AUTO: OFF"
    autoButton.BackgroundColor3=auto and Color3.fromRGB(39,93,75) or Color3.fromRGB(25,32,47)
    if auto and not busy then roll() end
end)
RunService.RenderStepped:Connect(function()
    if busy then
        local remaining=math.max(0,1-(os.clock()-started))
        cooldown.Text=remaining>.95 and "1" or string.format("%.1f",math.ceil(remaining*10)/10)
    end
end)
result.OnClientEvent:Connect(function(data)
    if data.Error then
        task.delay(math.max(.05,data.Remaining or .1),finish)
        return
    end
    if not busy then busy=true;started=os.clock() end
    card.Visible=true;note.Text="";cap.Text="ОПРЕДЕЛЯЕМ АУРУ"
    for i=1,9 do
        local preview=config[math.random(1,#config)]
        name.Text=preview.Name;name.TextColor3=preview.Color;chance.Text="· · ·"
        task.wait(.045+i*.003)
    end
    local aura=config[data.Index]
    cap.Text=data.NewBest and "НОВАЯ ЛУЧШАЯ АУРА" or "РЕЗУЛЬТАТ РОЛЛА"
    name.Text=aura.Name;name.TextColor3=aura.Color;chance.Text="Шанс  ·  "..aura.Chance
    counter.Text="Роллы  ·  "..tostring(data.Rolls)
    best.Text="Лучшая  ·  "..config[data.Best].Name;best.TextColor3=config[data.Best].Color
    note.Text=data.NewBest and "Аура экипирована на персонажа" or "Лучшая аура сохранена на персонаже"
    card.BackgroundColor3=aura.Color:Lerp(Color3.fromRGB(17,22,34),.83)
    TweenService:Create(card,TweenInfo.new(.25),{BackgroundColor3=Color3.fromRGB(17,22,34)}):Play()
    local remaining=1-(os.clock()-started)
    if remaining>0 then task.wait(remaining) end
    finish()
end)
