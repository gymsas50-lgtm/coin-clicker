-- Rebalanced integer reciprocal odds, summing exactly to one.
-- 48+12+6+24+3+2+1 =96 slots; no empty outcome.
local auras = {
    {Id="Common", Name="Common", Weight=48, Color=Color3.fromRGB(192,202,216), Rate=7},
    {Id="Uncommon", Name="Uncommon", Weight=12, Color=Color3.fromRGB(111,225,150), Rate=16},
    {Id="Rare", Name="Rare", Weight=6, Color=Color3.fromRGB(86,173,255), Rate=28},
    {Id="InDev", Name="in-dev", Weight=24, Color=Color3.fromRGB(255,183,95), Rate=18},
    {Id="SuperRare", Name="SuperRare", Weight=3, Color=Color3.fromRGB(101,235,239), Rate=34},
    {Id="Epic", Name="Epic", Weight=2, Color=Color3.fromRGB(189,121,255), Rate=42},
    {Id="Lucky", Name="Lucky", Weight=1, Color=Color3.fromRGB(168,255,90), Rate=50},
}
local total = 0
for _, aura in auras do total += aura.Weight end
for _, aura in auras do
    assert(total % aura.Weight == 0, "Aura odds must be whole numbers")
    aura.Chance = "1 in " .. tostring(math.floor(total/aura.Weight))
end
return auras
