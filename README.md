# Camera simulator prototype

Two connected daylight rooms with windows, ceilings, wall collision and a walkable doorway. Road and roadside objects removed from the active map. Static room geometry batched by material.

One active photo point spawns randomly on accessible floor in either room. Approach within3meters, aim and photograph it; walls block completion. After1.2seconds a new random point spawns at least3meters from the old one. The sequence continues indefinitely.

Right-side single-surface camera, live display and developing instant photographs. No file downloads or text HUD.

480p low-poly retro look without vertex jitter, dithering, shutter flashes or camera sway.

Click to capture mouse; WASD move; Shift faster; Escape cursor.

Node22 server, LAN access, Windows auto-updater. npm start or START.bat, default port3000.
