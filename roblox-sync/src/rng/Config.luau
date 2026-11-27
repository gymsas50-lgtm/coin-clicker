-- Rebalanced integer reciprocal odds, summing exactly to one.
-- 44+22+12+33+11+6+4 =132 slots; no empty outcome.
local auras = {
    {Id="Common", Name="Common", Weight=44, Color=Color3.fromRGB(192,202,216), Rate=7},
    {Id="Uncommon", Name="Uncommon", Weight=22, Color=Color3.fromRGB(111,225,150), Rate=16},
    {Id="Rare", Name="Rare", Weight=12, Color=Color3.fromRGB(86,173,255), Rate=28},
    {Id="InDev", Name="in-dev", Weight=33, Color=Color3.fromRGB(255,183,95), Rate=18},
    {Id="SuperRare", Name="SuperRare", Weight=11, Color=Color3.fromRGB(101,235,239), Rate=34},
    {Id="Epic", Name="Epic", Weight=6, Color=Color3.fromRGB(189,121,255), Rate=42},
    {Id="Lucky", Name="Lucky", Weight=4, Color=Color3.fromRGB(168,255,90), Rate=50},
}
local total = 0
for _, aura in auras do total += aura.Weight end
for _, aura in auras do
    assert(total % aura.Weight == 0, "Aura odds must be whole numbers")
    aura.Chance = "1 in " .. tostring(math.floor(total/aura.Weight))
end
return auras
