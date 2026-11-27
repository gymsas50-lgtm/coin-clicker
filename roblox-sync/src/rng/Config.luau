-- Sequential rarity checks, rarest first. Displayed odds are base checks, not final frequencies.
-- Keep stable IDs/order for session inventory references.
local auras = {
    {Id="Common", Name="Common", BaseOdds=2, Color=Color3.fromRGB(192,202,216), Rate=7},
    {Id="Uncommon", Name="Uncommon", BaseOdds=8, Color=Color3.fromRGB(111,225,150), Rate=16},
    {Id="Rare", Name="Rare", BaseOdds=16, Color=Color3.fromRGB(86,173,255), Rate=28},
    {Id="InDev", Name="in-dev", BaseOdds=4, Color=Color3.fromRGB(255,183,95), Rate=18},
    {Id="SuperRare", Name="SuperRare", BaseOdds=24, Color=Color3.fromRGB(101,235,239), Rate=34},
    {Id="Epic", Name="Epic", BaseOdds=32, Color=Color3.fromRGB(189,121,255), Rate=42},
    {Id="Lucky", Name="Lucky", BaseOdds=48, Color=Color3.fromRGB(168,255,90), Rate=50},
    {Id="Legendary", Name="legendary", BaseOdds=56, Color=Color3.fromRGB(255,191,61), Rate=60},
    {Id="Ice", Name="Ice", BaseOdds=64, Color=Color3.fromRGB(165,235,255), Rate=70},
    {Id="Rubic", Name="Rubic", BaseOdds=100, Color=Color3.fromRGB(255,99,99), Rate=75},
    {Id="UltraLegendary", Name="Ultra-legendary", BaseOdds=300, Color=Color3.fromRGB(255,215,105), Rate=100},
    {Id="Romb", Name="Romb", BaseOdds=150, Color=Color3.fromRGB(255,105,210), Rate=80},
    {Id="Sleeping", Name="sleeping", BaseOdds=200, Color=Color3.fromRGB(148,153,255), Rate=90},
}
for _, aura in auras do
    aura.Chance = "1 in " .. tostring(aura.BaseOdds)
end
return auras
