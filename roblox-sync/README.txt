REACTOR WORKS - ROBLOX / ROJO

Windows x64: extract the whole ZIP and run START-SYNC.bat.
Roblox Studio > Plugins > Rojo > Connect > localhost:34872.
Stop Play before synchronizing structural changes. Then start Play again.
The sync tool updates the Studio project, NOT a published Roblox experience.
No Roblox password or API token is required.

GAME
Up to four private reactor bays. Starter layout is already installed.
R: start/stop reactor. B: show/hide panels. X: emergency coolant.
Select a module in BUILD: panels close so you can click your world grid.
Build only while stopped and below60heat. Remove refunds60percent.
Fuel produces flux and heat. Adjacent coolers reduce fuel heat.
Fuel beside fuel boosts BOTH output and heat. Turbines convert flux.
Auto-sell keeps100energy for research and sells the excess.
The quarry provides ore; ore can always be sold to recover fuel money.
Use experiments and contracts to unlock labs, vents, breeders and fusion.
Handbook and all costs/formulas are included in the in-game interface.

SAVING
Studio uses session-only progress and does not access DataStore.
Published servers attempt DataStore saves every60seconds and on exit.
Check the save status in the upper-right corner. Service errors mean
saving is unavailable; the UI never claims such a session was saved.
A session that fails to load a save does not overwrite that save.
Publish via Roblox Studio to deploy the actual experience.

VALIDATION
Rojo build and Luau syntax compilation passed.
Automated logic tests cover1000starter ticks, meltdown, automatic scram,
offline cooling, fuel exhaustion, ore recovery, research, upgrades,
contracts and storage. Actual Roblox engine/visual testing is still needed.

Includes Rojo7.7.1 (MPL-2.0): https://github.com/rojo-rbx/rojo
