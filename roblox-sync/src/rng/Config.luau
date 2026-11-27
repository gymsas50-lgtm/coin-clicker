-- Exact integer draw slots; Common takes the remainder.
-- Keep stable IDs/order for session inventory references.
local auras = {
    {Id="Common", Name="Common", Weight=13785, Color=Color3.fromRGB(192,202,216), Rate=7},
    {Id="Uncommon", Name="Uncommon", Weight=4200, Color=Color3.fromRGB(111,225,150), Rate=16},
    {Id="Rare", Name="Rare", Weight=2100, Color=Color3.fromRGB(86,173,255), Rate=28},
    {Id="InDev", Name="in-dev", Weight=8400, Color=Color3.fromRGB(255,183,95), Rate=18},
    {Id="SuperRare", Name="SuperRare", Weight=1400, Color=Color3.fromRGB(101,235,239), Rate=34},
    {Id="Epic", Name="Epic", Weight=1050, Color=Color3.fromRGB(189,121,255), Rate=42},
    {Id="Lucky", Name="Lucky", Weight=700, Color=Color3.fromRGB(168,255,90), Rate=50},
    {Id="Legendary", Name="legendary", Weight=600, Color=Color3.fromRGB(255,191,61), Rate=60},
    {Id="Ice", Name="Ice", Weight=525, Color=Color3.fromRGB(165,235,255), Rate=70},
    {Id="Rubic", Name="Rubic", Weight=336, Color=Color3.fromRGB(255,99,99), Rate=75},
    {Id="UltraLegendary", Name="Ultra-legendary", Weight=112, Color=Color3.fromRGB(255,215,105), Rate=100},
    {Id="Romb", Name="Romb", Weight=224, Color=Color3.fromRGB(255,105,210), Rate=80},
    {Id="Sleeping", Name="sleeping", Weight=168, Color=Color3.fromRGB(148,153,255), Rate=90},
}
local total = 0
for _, aura in auras do total += aura.Weight end
for _, aura in auras do
    if aura.Id == "Common" then
        aura.Chance = "~" .. string.format("%.2f%%",100*aura.Weight/total)
    else
        assert(total % aura.Weight == 0, "Rare aura odds must be exact")
        aura.Chance = "1 in " .. tostring(math.floor(total/aura.Weight))
    end
end
return auras
