import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { RectAreaLightUniformsLib } from 'three/addons/lights/RectAreaLightUniformsLib.js';

const mount = document.querySelector('#scene');
const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
try {
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 1.75));
  renderer.setClearColor(0x090b0f);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.shadowMap.autoUpdate = false;
  renderer.shadowMap.needsUpdate = true;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.25;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  mount.appendChild(renderer.domElement);
  renderer.domElement.setAttribute('aria-label', 'Деревянный сундук с металлическими креплениями.');
  renderer.domElement.setAttribute('role', 'img');
  RectAreaLightUniformsLib.init();
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x090b0f);
  scene.fog = new THREE.FogExp2(0x090b0f, 0.024);
  const camera = new THREE.PerspectiveCamera(33, 1, 0.1, 80);
  const pmrem = new THREE.PMREMGenerator(renderer);
  const room = new RoomEnvironment();
  const environment = pmrem.fromScene(room, 0.045);
  scene.environment = environment.texture;
  scene.environmentIntensity = 0.9;
  room.dispose(); pmrem.dispose();

  // A subtle, locally generated surface texture: no images or CDN at runtime.
  const grainCanvas = document.createElement('canvas');
  grainCanvas.width = grainCanvas.height = 128;
  const grainContext = grainCanvas.getContext('2d');
  const image = grainContext.createImageData(128, 128);
  let seed = 481;
  for (let i = 0; i < image.data.length; i += 4) {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    const v = 175 + (seed % 60);
    image.data[i] = image.data[i + 1] = image.data[i + 2] = v; image.data[i + 3] = 255;
  }
  grainContext.putImageData(image, 0, 0);
  const grain = new THREE.CanvasTexture(grainCanvas);
  grain.wrapS = grain.wrapT = THREE.RepeatWrapping; grain.repeat.set(5, 3);
  // Procedural oak grain with long fibers, pores and natural dark growth lines.
  const woodCanvas = document.createElement('canvas'); woodCanvas.width = woodCanvas.height = 512;
  const wc = woodCanvas.getContext('2d');
  const woodImage = wc.createImageData(512, 512);
  let noiseSeed = 9121;
  for (let y = 0; y < 512; y++) for (let x = 0; x < 512; x++) {
    noiseSeed = (Math.imul(noiseSeed, 1664525) + 1013904223) >>> 0;
    const warp = y + Math.sin(x * .012) * 7 + Math.sin(x * .031 + y * .013) * 2;
    const line = Math.sin(warp * .65) * 5 + Math.sin(warp * 2.2) * 2;
    const broad = Math.sin(warp * .046) * 9 + Math.sin(x * .006 + y * .02) * 3;
    const noise = (noiseSeed % 17) - 8;
    const i = (y * 512 + x) * 4;
    woodImage.data[i] = 100 + broad + line + noise;
    woodImage.data[i+1] = 78 + broad*.65 + line*.7 + noise*.6;
    woodImage.data[i+2] = 51 + broad*.38 + line*.45 + noise*.4;
    woodImage.data[i+3] = 255;
  }
  wc.putImageData(woodImage, 0, 0);
  for (const [x,y] of [[110,180],[370,390]]) {
    for (let r=2; r<22; r+=3) {
      wc.strokeStyle='rgba(45,23,10,'+(0.22-r*.004)+')';wc.lineWidth=.8;
      wc.beginPath();wc.ellipse(x,y,r*2.8,r*.38,.03,0,Math.PI*2);wc.stroke();
    }
  }
  // Fine splinters and long faded scratches embedded in the wood itself.
  for (let i=0;i<110;i++) {
    noiseSeed=(Math.imul(noiseSeed,1664525)+1013904223)>>>0;
    const x=noiseSeed%512,y=(noiseSeed>>>10)%512,len=8+(noiseSeed>>>18)%100;
    wc.strokeStyle=i%3===0?'rgba(198,178,139,.19)':'rgba(34,26,17,.3)';wc.lineWidth=i%7===0?1.5:.55;
    wc.beginPath();wc.moveTo(x,y);wc.lineTo(x+len*.65,y-.8);wc.lineTo(x+len,y+.4);wc.stroke();
  }
  const wood = new THREE.CanvasTexture(woodCanvas); wood.colorSpace = THREE.SRGBColorSpace;
  wood.wrapS = wood.wrapT = THREE.RepeatWrapping; wood.anisotropy = Math.min(8,renderer.capabilities.getMaxAnisotropy());
  const shell = new THREE.MeshStandardMaterial({ color: 0xbeb59d, map:wood, metalness: 0, roughness: .96, bumpMap: wood, bumpScale: .045 });
  const panel = new THREE.MeshStandardMaterial({ color: 0xa49a80, map:wood, metalness: 0, roughness: .98, bumpMap: wood, bumpScale: .03 });
  const rustCanvas=document.createElement('canvas');rustCanvas.width=rustCanvas.height=128;
  const rc=rustCanvas.getContext('2d');rc.fillStyle='#3e3b33';rc.fillRect(0,0,128,128);
  for(let i=0;i<1700;i++){
    noiseSeed=(Math.imul(noiseSeed,1664525)+1013904223)>>>0;
    const x=noiseSeed%128,y=(noiseSeed>>>8)%128;
    rc.fillStyle=i%3===0?'rgba(128,70,32,.45)':'rgba(26,29,26,.38)';
    rc.fillRect(x,y,1+(i%4),1+(i%3));
  }
  const rust=new THREE.CanvasTexture(rustCanvas);rust.colorSpace=THREE.SRGBColorSpace;
  rust.wrapS=rust.wrapT=THREE.RepeatWrapping;
  const aluminum = new THREE.MeshStandardMaterial({ color: 0xa49b84,map:rust,metalness:.52,roughness:.88,bumpMap:rust,bumpScale:.015 });
  const steel = new THREE.MeshStandardMaterial({ color: 0x777666,map:rust,metalness:.45,roughness:.94 });
  const rubber = new THREE.MeshStandardMaterial({ color: 0x11161c, metalness: 0.03, roughness: 0.82 });
  const dark = new THREE.MeshStandardMaterial({ color: 0x080d12, metalness: 0.4, roughness: 0.45 });
  const indicator = new THREE.MeshStandardMaterial({ color: 0x93ccc3, metalness: 0.55, roughness: 0.3, emissive: 0x366c62, emissiveIntensity: 0.35 });
  const model = new THREE.Group(); model.position.y = 1.45; scene.add(model);
  const geometryCache = new Map();
  function box(parent, size, pos, material, radius = 0.035) {
    const key = [...size, radius].join(':');
    let geo = geometryCache.get(key);
    if (!geo) { geo = new RoundedBoxGeometry(...size, 3, radius); geometryCache.set(key, geo); }
    const mesh = new THREE.Mesh(geo, material);
    mesh.position.set(...pos); mesh.castShadow = true; mesh.receiveShadow = true; parent.add(mesh); return mesh;
  }
  function cylinder(parent, radius, length, pos, material, axis = 'z') {
    const geo = new THREE.CylinderGeometry(radius, radius, length, 24);
    const mesh = new THREE.Mesh(geo, material); mesh.position.set(...pos);
    if (axis === 'z') mesh.rotation.x = Math.PI / 2;
    if (axis === 'x') mesh.rotation.z = Math.PI / 2;
    mesh.castShadow = true; mesh.receiveShadow = true; parent.add(mesh); return mesh;
  }
  function screw(x, y, z, front = true) {
    cylinder(model, 0.043, 0.025, [x, y, z], steel);
    const slot = box(model, [0.043, 0.009, 0.007], [x, y, z + (front ? 0.015 : -0.015)], dark, 0.002);
    slot.rotation.z = (x + y) * 2;
  }
  // Separate wooden lid and body, with a dark seam between them.
  box(model, [5.5, 1.92, 2.32], [0, -0.05, 0], shell, 0.14);
  box(model, [5.40, 0.075, 2.25], [0, 0.95, 0], dark, 0.035);
  box(model, [5.52, 0.62, 2.34], [0, 1.30, 0], shell, 0.13);
  box(model, [5.28, 0.033, 2.13], [0, 0.986, 0], aluminum, 0.015);
  // Four separate wooden boards on the front and back.
  for (const side of [-1, 1]) {
    box(model, [4.80, 1.42, 0.07], [0, -0.11, side * 1.17], dark, 0.03);
    for (let board=0; board<4; board++) {
      const plank = box(model, [4.72, .318+(board%2)*.008, .075], [board%2 ? .018 : -.012, -.64 + board*.35, side * 1.214], board%2 ? shell : panel, .012);
      plank.rotation.z=(board%2 ? 1 : -1)*.002;
    }
    // Recessed nails, not futuristic panel ribs.
    for (const x of [-2.18,2.18]) for (const y of [-.62,-.27,.08,.43]) screw(x,y,side*1.265,side>0);
  }
  // Reinforced corner shoes hug both faces rather than floating on the shell.
  for (const x of [-1, 1]) for (const z of [-1, 1]) {
    box(model, [0.53, 0.48, 0.11], [x * 2.465, -0.76, z * 1.18], aluminum, 0.06);
    box(model, [0.11, 0.48, 0.54], [x * 2.74, -0.76, z * 0.96], aluminum, 0.04);
    box(model, [0.48, 0.13, 0.52], [x * 2.49, -0.985, z * 0.94], aluminum, 0.04);
    box(model, [0.47, 0.35, 0.105], [x * 2.48, 1.405, z * 1.19], aluminum, 0.045);
    box(model, [0.105, 0.35, 0.48], [x * 2.75, 1.405, z * 0.97], aluminum, 0.04);
    screw(x * 2.49, -0.76, z * 1.25, z > 0);
    screw(x * 2.48, 1.42, z * 1.25, z > 0);
  }
  // Old forged iron straps: heavy rivets instead of modern suitcase latches.
  for(const x of [-1.85,1.85]) {
    box(model,[.26,1.8,.09],[x,-.03,1.285],aluminum,.012);
    box(model,[.26,.55,.09],[x,1.31,1.245],aluminum,.012);
    box(model,[.27,.07,2.15],[x,1.70,0],aluminum,.012);
    for(const y of [-.74,-.36,.15,.63,1.35]) cylinder(model,.05,.04,[x,y,1.35],steel);
  }
  box(model,[.32,.65,.10],[0,.81,1.29],aluminum,.025);
  cylinder(model,.065,.15,[0,.62,1.39],steel);
  // Hinge barrels and back plates are visible when the player rotates the case.
  for (const x of [-1.8, 1.8]) {
    box(model, [0.65, 0.48, 0.09], [x, 0.96, -1.21], steel, 0.035);
    for (let i = -1; i <= 1; i++) cylinder(model, 0.09, 0.18, [x + i * 0.20, 0.98, -1.31], i === 0 ? steel : aluminum, 'x');
    screw(x - 0.2, 1.13, -1.27, false); screw(x + 0.2, 0.79, -1.27, false);
  }
  // A worn plank lid and simple old iron side handles.
  for(let i=0;i<4;i++) {
    const board=box(model,[5.14,.075,.49],[0,1.63,-.78+i*.52],i%2?shell:panel,.018);
    board.rotation.z=(i%2?1:-1)*.002;
  }
  for(const side of [-1,1]) {
    box(model,[.09,.47,.60],[side*2.85,.2,0],aluminum,.035);
    for(const z of [-.2,.2]) cylinder(model,.065,.09,[side*2.94,.24,z],steel,'x');
    const ring=new THREE.Mesh(new THREE.TorusGeometry(.29,.045,8,32),aluminum);
    ring.rotation.y=Math.PI/2;ring.scale.y=.8;ring.position.set(side*2.97,-.04,0);ring.castShadow=true;model.add(ring);
  }
  const split=new THREE.MeshStandardMaterial({color:0x30291e,roughness:1});
  // A handful of visible hairline splits, following rather than crossing the grain.
  for(const [x,y,len] of [[-1.4,-.52,.70],[.5,.1,.95],[-.2,.48,.6],[1.6,-.25,.55]]) {
    const points=[new THREE.Vector3(x,y,1.257),new THREE.Vector3(x+len*.35,y+.018,1.259),new THREE.Vector3(x+len*.7,y-.008,1.259),new THREE.Vector3(x+len,y+.006,1.257)];
    const crack=new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points),12,.007,4,false),split);model.add(crack);
  }
  // Center badge, status light, side vents and non-slip feet.
  box(model, [0.40, 0.38, 0.055], [0, 0.15, 1.284], steel, 0.045);
  cylinder(model,.045,.012,[0,.19,1.32],dark);
  box(model,[.045,.10,.012],[0,.13,1.33],dark,.007);
  for (const side of [-1, 1]) {
    box(model, [.04, 1.42, 1.65], [side*2.77,-.11,0], dark,.02);
    for (let i=0;i<4;i++) box(model,[.065,.324,1.57],[side*2.80,-.64+i*.35,0],i%2 ? shell : panel,.015);
    for (const z of [-.77,.77]) box(model,[.77,.24,.48],[side*1.93,-1.10,z],panel,.07);
  }
  // Studio-style lighting with actual material reflections and grounded shadows.
  const key = new THREE.SpotLight(0xfff4e5, 95, 40, 0.65, 0.75, 2);
  key.position.set(-4, 9, 7); key.target.position.set(0, 1, 0); key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024); key.shadow.bias = -0.00015; key.shadow.normalBias = 0.025;
  scene.add(key, key.target);
  const rim = new THREE.RectAreaLight(0xb6d4f1, 5, 6, 4); rim.position.set(5, 5, -4); rim.lookAt(0, 1.7, 0); scene.add(rim);
  const fillLight = new THREE.RectAreaLight(0xf5f7ff, 3, 7, 4); fillLight.position.set(-5, 3, 3); fillLight.lookAt(0, 1.5, 0); scene.add(fillLight);
  scene.add(new THREE.HemisphereLight(0xc5d7e8, 0x15191e, 0.4));
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(160, 160), new THREE.MeshStandardMaterial({ color: 0x101318, roughness: 0.91, metalness: 0.12 }));
  floor.rotation.x = -Math.PI / 2; floor.position.y = 0.20; floor.receiveShadow = true; scene.add(floor);
  const shadowCanvas = document.createElement('canvas'); shadowCanvas.width = shadowCanvas.height = 128;
  const sc = shadowCanvas.getContext('2d'); const shade = sc.createRadialGradient(64, 64, 12, 64, 64, 62);
  shade.addColorStop(0, 'rgba(0,0,0,.65)'); shade.addColorStop(1, 'rgba(0,0,0,0)'); sc.fillStyle = shade; sc.fillRect(0, 0, 128, 128);
  const contact = new THREE.Mesh(new THREE.PlaneGeometry(8, 4.8), new THREE.MeshBasicMaterial({ map: new THREE.CanvasTexture(shadowCanvas), transparent: true, depthWrite: false, opacity: 0.75 }));
  contact.rotation.x = -Math.PI / 2; contact.position.y = 0.208; scene.add(contact);
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.target.set(0, 1.65, 0); controls.enableDamping = true; controls.dampingFactor = 0.07;
  controls.enablePan = false; controls.enableZoom = false; controls.enableRotate = false; controls.enabled = false;
  controls.minPolarAngle = Math.PI * 0.27; controls.maxPolarAngle = Math.PI * 0.49;
  let interacting = false, dirty = true;
  controls.addEventListener('change', () => { dirty = true; });
  controls.addEventListener('start', () => { interacting = true; mount.classList.add('dragging'); });
  controls.addEventListener('end', () => mount.classList.remove('dragging'));
  function resize() {
    const w = innerWidth, h = innerHeight;
    renderer.setSize(w, h); camera.aspect = w / h;
    const distance = w / h < 0.85 ? 18.5 : 13.8;
    if (!interacting) camera.position.set(distance * 0.48, distance * 0.30 + 1.6, distance * 0.81);
    else camera.position.copy(controls.target).add(camera.position.clone().sub(controls.target).normalize().multiplyScalar(distance));
    camera.fov = w / h < 0.65 ? 42 : 33; camera.updateProjectionMatrix(); controls.update(); dirty = true;
  }
  addEventListener('resize', resize); resize();
  mount.classList.add('ready');
  let frame = 0, start = performance.now();
  function draw(now) {
    frame = requestAnimationFrame(draw);
    if (document.hidden) return;
    controls.update();
    if (dirty) { renderer.render(scene, camera); dirty = false; }
  }
  requestAnimationFrame(draw);
  renderer.domElement.addEventListener('webglcontextlost', event => { event.preventDefault(); cancelAnimationFrame(frame); mount.classList.remove('ready'); });
  renderer.domElement.addEventListener('webglcontextrestored', () => location.reload());
  window.caseScene = { scene, model, renderer, camera, controls, get ready() { return mount.classList.contains('ready'); } };
} catch (error) {
  console.error('3D case:', error);
  mount.classList.remove('ready');
}
