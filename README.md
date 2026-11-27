# Camera simulator prototype

Daylight road with31static roadside props and collisions. Streetlamp fixtures retained, lights off in daytime.

PS1-inspired look:480p, low-poly models, small textures and5bit colors. No dithering, vertex jitter, camera sway or shutter flashes. MSAA, mip filtering and cached soft daylight shadows reduce shimmer.

Right-side camera has live display. Left click prints an instant photo that develops without downloads. Exactly one photo objective spawns at a random accessible roadside location on each load, excluding large prop collision bounds. Approach within3meters and aim to complete it; no replacement spawns until reload.

Click to capture mouse; WASD move; Shift faster; Escape cursor. No HUD text or hands.

Node22 server, LAN and Windows auto-updater. npm start or START.bat, port3000.
