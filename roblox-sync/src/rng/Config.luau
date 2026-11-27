-- Exact mutually exclusive odds. All384 slots award one aura.
-- Keep stable IDs/order for session inventory references.
local auras = {
    {Id="Common", Name="Common", Weight=192, Color=Color3.fromRGB(192,202,216), Rate=7},
    {Id="Uncommon", Name="Uncommon", Weight=48, Color=Color3.fromRGB(111,225,150), Rate=16},
    {Id="Rare", Name="Rare", Weight=24, Color=Color3.fromRGB(86,173,255), Rate=28},
    {Id="InDev", Name="in-dev", Weight=96, Color=Color3.fromRGB(255,183,95), Rate=18},
    {Id="SuperRare", Name="SuperRare", Weight=12, Color=Color3.fromRGB(101,235,239), Rate=34},
    {Id="Epic", Name="Epic", Weight=6, Color=Color3.fromRGB(189,121,255), Rate=42},
    {Id="Lucky", Name="Lucky", Weight=3, Color=Color3.fromRGB(168,255,90), Rate=50},
    {Id="Legendary", Name="legendary", Weight=2, Color=Color3.fromRGB(255,191,61), Rate=60},
    {Id="Ice", Name="Ice", Weight=1, Color=Color3.fromRGB(165,235,255), Rate=70},
}
local total = 0
for _, aura in auras do total += aura.Weight end
for _, aura in auras do
    assert(total % aura.Weight == 0, "Aura odds must be whole numbers")
    aura.Chance = "1 in " .. tostring(math.floor(total/aura.Weight))
end
return auras
