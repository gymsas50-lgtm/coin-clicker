# Case game / Three.js

Centered, detailed 3D wooden case with a fixed camera, aged oak planks, hairline splits, rusty iron straps and side ring handles, procedural wood grain, studio lighting and soft contact shadows. Version v0.4.1 is shown in the bottom-left corner. No external assets or CDN requests at runtime. A built-in SVG fallback is shown if WebGL is unavailable.

Run `node server.js` or use the existing Windows launcher. The built `index.html` also runs offline. The live-update marker and protocol are unchanged.

## Rebuild

`npm install` then `npm run build`.

Click the chest to summon an ornate 3D key from below the screen: it flies into the lock, turns, releases the hasp, and opens the hinged lid with warm interior lighting and drifting dust. Click again to close. The camera remains fixed; repeated clicks during the sequence are ignored.

Source: `src/case-three.js`, `src/opening.js`, and `src/page.html`. Build helper: `src/build.cjs`.
Three.js 0.180.0, MIT; license in `src/THREE-LICENSE.txt`.

Roblox is separate under `roblox-sync/` and is not modified by this browser-game update.

## Windows desktop

`desktop/main.cjs` runs the game in an isolated Electron window, without a browser tab or Node.js installation. The packaged app includes an offline game, checks the main branch on launch and every 15 seconds, validates and caches the latest HTML in the Windows user profile, and reloads via the existing version protocol. Game updates are automatic; Electron/native launcher updates require a new desktop download. Keep all files beside the EXE.

Version 0.2.1 refines the key into a symmetric antique brass design with an in-plane bow, a straight shaft and a slot-sized bit. The approach aligns before a fixed-axis insertion; the key no longer scales or bypasses depth testing.

Version 0.2.2 rotates the key bow 90 degrees about the shaft. Animation renders on every requestAnimationFrame without a 30 FPS cap; all motion uses elapsed time, not frame counts. Airborne key shadow passes are avoided. Actual FPS depends on GPU and resolution.

Version 0.3.0 replaces the flat lid with a hollow barrel-vault lid: ten curved wooden staves, arched end panels and continuous riveted iron bands. The entire curved assembly opens on the existing rear hinge.

Version 0.3.1 separates wood and metal shell surfaces, removes overlapping stave bevels, leaves explicit stave/end-panel seams, and moves corner/handle plates clear of the wooden faces to prevent depth fighting.

Version 0.4.0 adds a top-right money/key HUD, +15 money per elapsed second while running, a 100-money key purchase, and one-key-per-opening consumption. Balances use localStorage when available (scoped to the browser origin); this is client-side currency, not a server-authoritative economy.

Version 0.4.1 changes key price to 1,000 money and models lid motion with a fixed-step angular torque simulation: spring-assisted opening, gravity, friction and damped rebounds at mechanical stops. Closing falls under gravity with a small closing torque; results are independent of display refresh rate.
