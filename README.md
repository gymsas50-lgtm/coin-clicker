# Case game / Three.js

Centered, detailed 3D wooden case with a fixed camera, aged oak planks, hairline splits, rusty iron straps and side ring handles, procedural wood grain, studio lighting and soft contact shadows. Version v0.2.0 is shown in the bottom-left corner. No external assets or CDN requests at runtime. A built-in SVG fallback is shown if WebGL is unavailable.

Run `node server.js` or use the existing Windows launcher. The built `index.html` also runs offline. The live-update marker and protocol are unchanged.

## Rebuild

`npm install` then `npm run build`.

Click the chest to summon an ornate 3D key from below the screen: it flies into the lock, turns, releases the hasp, and opens the hinged lid with warm interior lighting and drifting dust. Click again to close. The camera remains fixed; repeated clicks during the sequence are ignored.

Source: `src/case-three.js`, `src/opening.js`, and `src/page.html`. Build helper: `src/build.cjs`.
Three.js 0.180.0, MIT; license in `src/THREE-LICENSE.txt`.

Roblox is separate under `roblox-sync/` and is not modified by this browser-game update.

## Windows desktop

`desktop/main.cjs` runs the game in an isolated Electron window, without a browser tab or Node.js installation. The packaged app includes an offline game, checks the main branch on launch and every 15 seconds, validates and caches the latest HTML in the Windows user profile, and reloads via the existing version protocol. Game updates are automatic; Electron/native launcher updates require a new desktop download. Keep all files beside the EXE.
