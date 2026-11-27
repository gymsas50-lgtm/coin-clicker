# Game source

`scene.js` is the authoritative complete game runtime. Root `index.html` embeds this runtime, Three.js and camera model data for offline use.

Other JS files are development modules and historical construction helpers; some have been superseded. Do not concatenate or rerun them blindly. `generated-wing.js` describes the current full twelve-room generator.

The root Windows ZIP includes the self-contained game and existing updater. No source assets need downloading at runtime.
