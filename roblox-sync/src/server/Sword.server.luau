local Players = game:GetService("Players")

local function createSword()
    local tool = Instance.new("Tool")
    tool.Name = "Royal Sword"
    tool.ToolTip = "Королевский меч"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.Grip = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(90), 0, 0)

    local function part(name, size, cf, color, material, className)
        local p = Instance.new(className or "Part")
        p.Name = name
        p.Size = size
        p.CFrame = cf
        p.Color = color
        p.Material = material
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Massless = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = tool
        return p
    end
    local gold = Color3.fromRGB(190, 142, 65)
    local steel = Color3.fromRGB(195, 213, 224)
    local leather = Color3.fromRGB(38, 43, 57)
    local handle = part("Handle", Vector3.new(0.27, 1.1, 0.27), CFrame.new(), leather, Enum.Material.SmoothPlastic)
    for i = -3, 3 do
        part("Grip binding", Vector3.new(0.29, 0.035, 0.29), CFrame.new(0, i * 0.135, 0), Color3.fromRGB(91, 81, 68), Enum.Material.Metal)
    end
    part("Pommel", Vector3.new(0.42, 0.32, 0.34), CFrame.new(0, -0.66, 0), gold, Enum.Material.Metal)
    local gem = part("Sapphire pommel", Vector3.new(0.23, 0.23, 0.13), CFrame.new(0, -0.66, -0.19) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(45, 142, 193), Enum.Material.Glass)
    gem.Reflectance = 0.12
    part("Crossguard", Vector3.new(1.55, 0.18, 0.35), CFrame.new(0, 0.65, 0), gold, Enum.Material.Metal)
    for _, side in {-1, 1} do
        part("Swept guard", Vector3.new(0.50, 0.16, 0.29), CFrame.new(side * 0.85, 0.55, 0) * CFrame.Angles(0, 0, side * math.rad(-24)), gold, Enum.Material.Metal)
        part("Guard end", Vector3.new(0.20, 0.24, 0.31), CFrame.new(side * 1.05, 0.44, 0), gold, Enum.Material.Metal)
    end
    part("Blade", Vector3.new(0.54, 3.35, 0.13), CFrame.new(0, 2.37, 0), steel, Enum.Material.Metal)
    part("Blade ridge", Vector3.new(0.14, 3.3, 0.17), CFrame.new(0, 2.36, 0), Color3.fromRGB(226, 236, 239), Enum.Material.Metal)
    for _, side in {-1, 1} do
        part("Polished edge", Vector3.new(0.065, 3.35, 0.08), CFrame.new(side * 0.285, 2.37, 0), Color3.fromRGB(237, 242, 245), Enum.Material.Metal)
        -- Two mirrored wedge prisms create a true pointed metal tip.
        part("Blade tip", Vector3.new(0.13, 0.31, 0.65), CFrame.new(side * 0.155, 4.37, 0) * CFrame.Angles(0, math.rad(90), side * math.rad(90)), steel, Enum.Material.Metal, "WedgePart")
    end
    part("Guard jewel", Vector3.new(0.22, 0.26, 0.12), CFrame.new(0, 0.65, -0.23) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(44, 133, 187), Enum.Material.Glass)
    for _, p in tool:GetChildren() do
        if p:IsA("BasePart") and p ~= handle then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = p
            weld.Parent = p
        end
    end
    return tool
end

local function onCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid", 15)
    local backpack = player:WaitForChild("Backpack", 15)
    if not humanoid or not backpack or player.Character ~= character then return end
    if backpack:FindFirstChild("Royal Sword") or character:FindFirstChild("Royal Sword") then return end
    local tool = createSword()
    tool.Parent = backpack
    task.defer(function()
        if player.Character == character and humanoid.Health > 0 then humanoid:EquipTool(tool) end
    end)
end
local function onPlayer(player)
    player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
    if player.Character then task.spawn(onCharacter, player, player.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do task.spawn(onPlayer, player) end
