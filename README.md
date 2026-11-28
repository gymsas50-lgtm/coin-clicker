# Case game / Three.js

Centered, detailed 3D metal case with OrbitControls, reflective materials, procedural surface grain, studio lighting and soft contact shadows. Drag with mouse or touch to rotate. No external assets or CDN requests at runtime. A built-in SVG fallback is shown if WebGL is unavailable.

Run `node server.js` or use the existing Windows launcher. The built `index.html` also runs offline. The live-update marker and protocol are unchanged.

## Rebuild

`npm install` then `npm run build`.

Source: `src/case-three.js` and `src/page.html`. Build helper: `src/build.cjs`.
Three.js 0.180.0, MIT; license in `src/THREE-LICENSE.txt`.

Roblox is separate under `roblox-sync/` and is not modified by this browser-game update.
