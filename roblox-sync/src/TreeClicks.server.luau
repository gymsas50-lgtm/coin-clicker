local Players=game:GetService("Players")
local tree=workspace:WaitForChild("LittleStudTree")
local top=tree:WaitForChild("CrownTop")
local count=0
local lastClick={}
tree:SetAttribute("Clicks",0)

local billboard=Instance.new("BillboardGui")
billboard.Name="TreeClickCounter"
billboard.Adornee=top
billboard.Size=UDim2.fromOffset(180,52)
billboard.StudsOffsetWorldSpace=Vector3.new(0,1.6,0)
billboard.AlwaysOnTop=true
billboard.MaxDistance=90
billboard.Parent=top
local text=Instance.new("TextLabel")
text.Name="Count"
text.Size=UDim2.fromScale(1,1)
text.BackgroundTransparency=1
text.Font=Enum.Font.GothamBold
text.TextSize=25
text.TextColor3=Color3.fromRGB(255,255,255)
text.TextStrokeColor3=Color3.fromRGB(25,45,25)
text.TextStrokeTransparency=.15
text.Text="Clicks: 0"
text.Parent=billboard

local function clicked(player)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return end
    if (root.Position-tree.Trunk.Position).Magnitude>28 then return end
    local now=os.clock()
    if lastClick[player] and now-lastClick[player]<.08 then return end
    lastClick[player]=now
    count+=1
    tree:SetAttribute("Clicks",count)
    text.Text="Clicks: "..tostring(count)
end
for _,part in tree:GetDescendants() do
    if part:IsA("BasePart") then
        local detector=Instance.new("ClickDetector")
        detector.Name="TreeClick"
        detector.MaxActivationDistance=24
        detector.Parent=part
        detector.MouseClick:Connect(clicked)
    end
end
Players.PlayerRemoving:Connect(function(player) lastClick[player]=nil end)
