local C={}
C.Size=7
C.Cell=3
C.Modules={
    {Id="Fuel",Name="FUEL CELL",Cost=60,Ore=8,Unlock=0,Color=Color3.fromRGB(111,231,151),Info="Produces 24 flux/s. Uses 0.08 fuel/s. Adjacent coolers reduce heat; adjacent fuel increases output AND heat."},
    {Id="Cooler",Name="COOLER",Cost=35,Ore=6,Unlock=0,Color=Color3.fromRGB(95,191,251),Info="Each adjacent fuel cell produces 2.2 less heat/s. Adds 0.8 cooling/s. Plan for safe continuous operation."},
    {Id="Turbine",Name="TURBINE",Cost=75,Ore=10,Unlock=0,Color=Color3.fromRGB(255,196,105),Info="Converts up to 28 flux/s into stored energy. Unused flux becomes waste heat."},
    {Id="Battery",Name="BATTERY",Cost=50,Ore=8,Unlock=0,Color=Color3.fromRGB(188,167,255),Info="Adds 250 energy capacity. Stored energy is used by research and can be sold."},
    {Id="Lab",Name="LAB",Cost=120,Ore=15,Unlock=10,Color=Color3.fromRGB(235,153,238),Info="Consumes 3 stored energy/s to produce 0.25 research/s while running. More labs accelerate research."},
    {Id="Vent",Name="ACTIVE VENT",Cost=150,Ore=18,Unlock=25,Color=Color3.fromRGB(96,230,220),Info="Consumes 2 energy/s for 4 extra cooling/s. Runs only while the reactor is online."},
    {Id="Breeder",Name="BREEDER",Cost=240,Ore=25,Unlock=60,Color=Color3.fromRGB(248,149,93),Info="While running, consumes 5 energy/s and 0.03 ore/s to create 0.1 fuel/s. Adds 1 heat/s."},
    {Id="Fusion",Name="FUSION CORE",Cost=650,Ore=65,Unlock=140,Color=Color3.fromRGB(131,204,255),Info="60 flux/s, 8 heat/s, 0.12 fuel/s. Adjacent coolers reduce heat. High-output late-game core."},
}
C.ById={}
for _,m in C.Modules do C.ById[m.Id]=m end
C.Upgrades={
    {Id="Efficiency",Name="EFFICIENT ROTORS",Base=15,Max=5,Info="+15% turbine conversion per level."},
    {Id="Cooling",Name="THERMAL ENGINEERING",Base=20,Max=5,Info="+15% passive/active cooling per level."},
    {Id="Drill",Name="AUTOMATED QUARRY",Base=12,Max=5,Info="+0.15 ore/s per level. Base quarry: 0.2 ore/s."},
    {Id="Safety",Name="AUTOMATIC SCRAM",Base=30,Max=1,Info="Shuts down at 100 heat. Without it a meltdown occurs at 140 heat."},
}
C.Quests={
    {Id="first",Name="FIRST CURRENT",Goal=100,Reward=80,RP=4,Info="Generate 100 energy total."},
    {Id="power",Name="GRID OPERATOR",Goal=1000,Reward=180,RP=8,Info="Generate 1,000 energy total."},
    {Id="industry",Name="INDUSTRIAL SCALE",Goal=6000,Reward=450,RP=18,Info="Generate 6,000 energy total."},
    {Id="master",Name="REACTOR ENGINEER",Goal=20000,Reward=1000,RP=40,Info="Generate 20,000 energy total."},
}
return C
