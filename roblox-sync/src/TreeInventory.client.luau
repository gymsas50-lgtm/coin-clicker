local remote=game:GetService("ReplicatedStorage"):WaitForChild("TreeInventory")
local ui=script.Parent
local panel=Instance.new("Frame");panel.Name="Inventory"
panel.AnchorPoint=Vector2.new(.5,1);panel.Position=UDim2.new(.5,0,1,-18)
panel.Size=UDim2.new(.9,0,0,164);panel.BackgroundColor3=Color3.fromRGB(27,37,30)
panel.BackgroundTransparency=.12;panel.BorderSizePixel=0;panel.Parent=ui
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(540,164);limit.Parent=panel
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=panel
local function label(parent,text,pos,size,font)
    local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=text;l.Position=pos;l.Size=size
    l.Font=Enum.Font.GothamBold;l.TextSize=font;l.TextColor3=Color3.fromRGB(240,248,237);l.Parent=parent;return l
end
local header=label(panel,"TREES",UDim2.fromOffset(12,7),UDim2.new(1,-24,0,22),15)
local colors={Color3.fromRGB(100,174,84),Color3.fromRGB(203,202,116),Color3.fromRGB(151,210,251)}
local rows={}
local inFlight=false
local apply
for i=1,3 do
    local card=Instance.new("Frame");card.Position=UDim2.new((i-1)/3,10,0,37)
    card.Size=UDim2.new(1/3,-15,0,116);card.BackgroundColor3=Color3.fromRGB(43,56,45)
    card.BorderSizePixel=0;card.Parent=panel
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=card
    local name=label(card,"...",UDim2.fromOffset(2,6),UDim2.new(1,-4,0,24),17);name.TextColor3=colors[i]
    local info=label(card,"",UDim2.fromOffset(2,34),UDim2.new(1,-4,0,30),12)
    local button=Instance.new("TextButton");button.Position=UDim2.new(0,8,1,-39);button.Size=UDim2.new(1,-16,0,31)
    button.Font=Enum.Font.GothamBold;button.TextSize=12;button.BorderSizePixel=0;button.Parent=card
    local b=Instance.new("UICorner");b.CornerRadius=UDim.new(0,6);b.Parent=button
    rows[i]={name=name,info=info,button=button,owned=false,equipped=false}
    button.Activated:Connect(function()
        local row=rows[i]
        if inFlight or not row.owned then return end
        inFlight=true
        local ok,data=pcall(function() return remote:InvokeServer(row.equipped and "Unequip" or "Equip",i) end)
        if ok then apply(data) end
        inFlight=false
    end)
end
apply=function(data)
    if type(data)~="table" or not data.Entries then return end
    header.Text="TREES  |  Clicks: "..string.format("%.0f",data.Balance)
    for i,entry in data.Entries do
        local row=rows[i];row.owned=entry.Owned>0;row.equipped=entry.Equipped
        row.name.Text=entry.Name
        row.info.Text=row.owned and ("x"..entry.Owned.." | Lv. "..entry.Level.."\n+"..string.format("%.0f",entry.Power).." / sec nearby") or "Not owned"
        row.button.Text=not row.owned and "LOCKED" or (entry.Equipped and "UNEQUIP" or "EQUIP")
        row.button.BackgroundColor3=not row.owned and Color3.fromRGB(65,68,64) or (entry.Equipped and Color3.fromRGB(102,139,102) or colors[i])
        row.button.TextColor3=Color3.fromRGB(20,30,22);row.button.Active=row.owned and not data.Busy
    end
end
task.spawn(function()
    while ui.Parent do
        if not inFlight then
            inFlight=true
            local ok,data=pcall(function() return remote:InvokeServer("Get") end)
            if ok then apply(data) end
            inFlight=false
        end
        task.wait(.6)
    end
end)
