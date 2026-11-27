-- Relative weights preserve the requested 1/2,1/4,1/8,1/3,1/10,1/16,1/24 ratios.
-- Their sum is normalized: exactly one aura per roll, with no empty outcome.
local auras = {
    {Id="Common", Name="Common", Weight=120, Color=Color3.fromRGB(192,202,216), Rate=7},
    {Id="Uncommon", Name="Uncommon", Weight=60, Color=Color3.fromRGB(111,225,150), Rate=16},
    {Id="Rare", Name="Rare", Weight=30, Color=Color3.fromRGB(86,173,255), Rate=28},
    {Id="InDev", Name="in-dev", Weight=80, Color=Color3.fromRGB(255,183,95), Rate=18},
    {Id="SuperRare", Name="SuperRare", Weight=24, Color=Color3.fromRGB(101,235,239), Rate=34},
    {Id="Epic", Name="Epic", Weight=15, Color=Color3.fromRGB(189,121,255), Rate=42},
    {Id="Lucky", Name="Lucky", Weight=10, Color=Color3.fromRGB(168,255,90), Rate=50},
}
local total = 0
for _, aura in auras do total += aura.Weight end
for _, aura in auras do
    local denominator = string.format("%.4f", total/aura.Weight):gsub("0+$", ""):gsub("%.$", "")
    aura.Chance = "1 in " .. denominator
end
return auras
