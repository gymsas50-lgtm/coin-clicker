local TweenService=game:GetService("TweenService")
local Visuals={}
local function animate(value,duration,target,style)
    local tween=TweenService:Create(value,TweenInfo.new(duration,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),target)
    tween:Play();tween.Completed:Wait()
end
function Visuals.Open(kind,index)
    local chest=workspace:WaitForChild("TreeChest")
    local lid=chest:WaitForChild("LidAssembly")
    local closed=lid:GetPivot()
    local hinge=CFrame.new(42,2.5,-5.9)
    local relative=hinge:ToObjectSpace(closed)
    local angle=Instance.new("NumberValue")
    local connection=angle.Changed:Connect(function(a)
        lid:PivotTo(hinge*CFrame.Angles(math.rad(a),0,0)*relative)
    end)
    local mini
    local motion,moveConnection
    local ok,err=pcall(function()
        animate(angle,.5,{Value=-105},Enum.EasingStyle.Back)
        mini=Instance.new("Model");mini.Name="RolledTreePreview"
        local function block(name,size,pos,color)
            local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
            p.Size=size;p.Position=pos;p.Color=color;p.Material=Enum.Material.Plastic
            p.TopSurface=Enum.SurfaceType.Studs;p.BottomSurface=Enum.SurfaceType.Inlet;p.Parent=mini
        end
        block("MiniTrunk",Vector3.new(.3,1.1,.3),Vector3.new(0,.55,0),kind.wood)
        if index==2 then
            for i=1,3 do block("Bark",Vector3.new(.31,.045,.31),Vector3.new(0,i*.25,0),Color3.fromRGB(60,65,60)) end
        end
        for tier=0,2 do
            local width=(index==2 and .95 or 1.2)-tier*.22
            for x=-1,1 do for z=-1,1 do
                block("Leaf",Vector3.new(width/3,.32,width/3),Vector3.new(x*width/3,1+tier*.28,z*width/3),kind.leaf:Lerp(Color3.new(1,1,1),tier*.07))
            end end
        end
        if index==3 then
            for i=1,4 do local a=i*math.pi/2;block("Crystal",Vector3.new(.17,.6,.17),Vector3.new(math.cos(a)*.5,1.6,math.sin(a)*.5),Color3.fromRGB(205,232,255)) end
        end
        mini.WorldPivot=CFrame.identity
        mini:PivotTo(CFrame.new(42,1,-4));mini.Parent=workspace
        motion=Instance.new("CFrameValue");motion.Value=mini:GetPivot()
        moveConnection=motion.Changed:Connect(function(cf) if mini.Parent then mini:PivotTo(cf) end end)
        animate(motion,.6,{Value=CFrame.new(42,5,-2.8)*CFrame.Angles(0,math.pi*.75,0)},Enum.EasingStyle.Quint)
        animate(motion,.65,{Value=CFrame.new(42,.65,1.6)*CFrame.Angles(0,math.pi,0)},Enum.EasingStyle.Bounce)
        task.wait(.8)
        animate(angle,.4,{Value=0})
    end)
    connection:Disconnect();angle:Destroy();lid:PivotTo(closed)
    if moveConnection then moveConnection:Disconnect() end
    if motion then motion:Destroy() end
    if mini then mini:Destroy() end
    if not ok then error(err) end
end
return Visuals
