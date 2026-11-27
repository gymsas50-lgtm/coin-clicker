local remote=game:GetService("ReplicatedStorage"):WaitForChild("TreeInventory")
local ui=script.Parent
local function round(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 10);c.Parent=p end
local function text(parent,value,pos,size,font)
    local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Text=value;t.Position=pos;t.Size=size
    t.Font=Enum.Font.GothamBold;t.TextSize=font;t.TextColor3=Color3.fromRGB(238,248,236);t.Parent=parent;return t
end
local toggle=Instance.new("TextButton");toggle.AnchorPoint=Vector2.new(.5,1)
toggle.Position=UDim2.new(.5,0,1,-18);toggle.Size=UDim2.fromOffset(52,52)
toggle.Text="";toggle.BackgroundTransparency=.4;toggle.TextSize=14;toggle.Font=Enum.Font.GothamBold
toggle.BackgroundColor3=Color3.fromRGB(46,77,48);toggle.TextColor3=Color3.new(1,1,1);toggle.BorderSizePixel=0;toggle.Parent=ui;round(toggle)
-- A simple four-slot inventory icon, no external image dependency.
for x=0,1 do for y=0,1 do
    local square=Instance.new("Frame");square.Size=UDim2.fromOffset(10,10)
    square.Position=UDim2.fromOffset(14+x*14,14+y*14)
    square.BackgroundColor3=Color3.fromRGB(239,248,237);square.BorderSizePixel=0;square.Parent=toggle;round(square,2)
end end
local panel=Instance.new("Frame");panel.Name="InventoryWindow";panel.AnchorPoint=Vector2.new(.5,.5)
panel.Position=UDim2.fromScale(.5,.48);panel.Size=UDim2.new(.9,0,.65,0)
panel.BackgroundColor3=Color3.fromRGB(25,37,28);panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=ui;round(panel,14)
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(640,520);limit.Parent=panel
local header=text(panel,"TREE INVENTORY",UDim2.fromOffset(16,12),UDim2.new(1,-80,0,24),18);header.TextXAlignment=Enum.TextXAlignment.Left
local subtitle=text(panel,"",UDim2.fromOffset(16,40),UDim2.new(1,-32,0,20),12);subtitle.TextXAlignment=Enum.TextXAlignment.Left
local close=Instance.new("TextButton");close.Text="X";close.Font=Enum.Font.GothamBold;close.TextSize=17
close.Size=UDim2.fromOffset(34,34);close.Position=UDim2.new(1,-46,0,10);close.BackgroundColor3=Color3.fromRGB(61,79,62)
close.TextColor3=Color3.new(1,1,1);close.BorderSizePixel=0;close.Parent=panel;round(close,7)
local list=Instance.new("ScrollingFrame");list.Position=UDim2.fromOffset(12,72);list.Size=UDim2.new(1,-24,1,-84)
list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=4;list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.Parent=panel
local grid=Instance.new("UIGridLayout");grid.CellPadding=UDim2.fromOffset(10,10);grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.Parent=list
local function resize()
    local columns=list.AbsoluteSize.X<420 and 2 or 3
    local side=math.floor((list.AbsoluteSize.X-8-(columns-1)*10)/columns)
    grid.CellSize=UDim2.fromOffset(side,side)
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
local rows={};local inFlight=false;local apply
local function makeRow(id)
    local card=Instance.new("Frame");card.LayoutOrder=id;card.BackgroundColor3=Color3.fromRGB(43,60,46);card.BorderSizePixel=0;card.Parent=list;round(card,9)
    local name=text(card,"",UDim2.new(0,5,0,7),UDim2.new(1,-10,.2,0),17)
    local info=text(card,"",UDim2.new(0,4,.28,0),UDim2.new(1,-8,.18,0),12)
    local track=Instance.new("Frame");track.Position=UDim2.new(0,10,.54,0);track.Size=UDim2.new(1,-20,0,15);track.BackgroundColor3=Color3.fromRGB(22,35,25);track.BorderSizePixel=0;track.Parent=card;round(track,4)
    local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=Color3.fromRGB(112,194,114);fill.BorderSizePixel=0;fill.Parent=track;round(fill,4)
    local xp=text(track,"",UDim2.fromScale(0,0),UDim2.fromScale(1,1),10);xp.ZIndex=3
    local button=Instance.new("TextButton");button.Position=UDim2.new(0,8,1,-39);button.Size=UDim2.new(1,-16,0,31)
    button.Font=Enum.Font.GothamBold;button.TextSize=12;button.BorderSizePixel=0;button.Parent=card;round(button,6)
    local row={name=name,info=info,track=track,fill=fill,xp=xp,button=button,equipped=false,owned=false,itemId=nil};rows[id]=row
    button.Activated:Connect(function()
        if inFlight or not row.owned or not row.itemId then return end
        inFlight=true
        local ok,data=pcall(function() return remote:InvokeServer(row.equipped and "Unequip" or "Equip",row.itemId) end)
        if ok then apply(data) end
        inFlight=false
    end)
    return row
end
local palette={Oak=Color3.fromRGB(131,202,101),Birch=Color3.fromRGB(226,224,141),Crystal=Color3.fromRGB(157,218,255)}
apply=function(data)
    if type(data)~="table" or not data.Entries then return end
    local found=0
    for _,entry in data.Entries do if entry.Owned then found+=1 end end
    subtitle.Text=found.." / "..#data.Entries.." trees | Clicks: "..string.format("%.0f",data.Balance)
    for _,entry in data.Entries do
        local row=rows[entry.Id] or makeRow(entry.Id)
        row.owned=entry.Owned;row.itemId=entry.ItemId;row.equipped=entry.Equipped
        row.track.Visible=entry.Owned
        if entry.Owned then
            row.name.Text=entry.Name;row.name.TextColor3=palette[entry.Name]
            row.info.Text="Lv. "..entry.Level.." | +"..string.format("%.0f",entry.Power).." / sec"
            row.fill.Size=UDim2.fromScale(math.clamp(entry.XP/entry.Required,0,1),1)
            row.xp.Text="XP "..entry.XP.." / "..string.format("%.0f",entry.Required)
            row.button.Text=entry.Equipped and "UNEQUIP" or "EQUIP"
            row.button.BackgroundColor3=entry.Equipped and Color3.fromRGB(91,137,94) or palette[entry.Name]
        else
            row.name.Text="???";row.name.TextColor3=Color3.fromRGB(155,165,155)
            row.info.Text="?";row.button.Text="LOCKED"
            row.button.BackgroundColor3=Color3.fromRGB(70,78,71)
        end
        row.button.TextColor3=Color3.fromRGB(18,30,21)
        row.button.Active=entry.Owned and not data.Busy
        row.button.AutoButtonColor=entry.Owned

    end
end
toggle.Activated:Connect(function() panel.Visible=not panel.Visible end)
close.Activated:Connect(function() panel.Visible=false end)
task.spawn(function()
    while ui.Parent do
        if panel.Visible and not inFlight then
            inFlight=true
            local ok,data=pcall(function() return remote:InvokeServer("Get") end)
            if ok then apply(data) end
            inFlight=false
        end
        task.wait(.5)
    end
end)
