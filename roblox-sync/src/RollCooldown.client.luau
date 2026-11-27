local RunService = game:GetService("RunService")
local button = script.Parent
local label = button.Parent:WaitForChild("Cooldown")
local running = false
button.Activated:Connect(function()
    if running then return end
    running = true
    button.Active = false
    button.AutoButtonColor = false
    label.Text = "1"
    label.Visible = true
    local finish = os.clock() + 1
    while label.Parent do
        local remaining = finish - os.clock()
        if remaining <= 0 then break end
        local tenths = math.clamp(math.ceil(remaining * 10), 1, 10)
        label.Text = tenths == 10 and "1" or string.format("0.%d", tenths)
        RunService.RenderStepped:Wait()
    end
    label.Text = ""
    label.Visible = false
    button.Active = true
    button.AutoButtonColor = true
    running = false
end)
