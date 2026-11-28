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
  renderer.domElement.setAttribute('aria-label', 'Объёмный металлический кейс. Потяни, чтобы повернуть.');
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
  const shell = new THREE.MeshStandardMaterial({ color: 0x313a43, metalness: 0.65, roughness: 0.42, roughnessMap: grain, bumpMap: grain, bumpScale: 0.009 });
  const panel = new THREE.MeshStandardMaterial({ color: 0x252d35, metalness: 0.55, roughness: 0.5, roughnessMap: grain });
  const aluminum = new THREE.MeshStandardMaterial({ color: 0xaebdc8, metalness: 0.94, roughness: 0.25 });
  const steel = new THREE.MeshStandardMaterial({ color: 0x54626e, metalness: 0.9, roughness: 0.32 });
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
  // Separate lid and body, with a genuine dark gasket between them.
  box(model, [5.5, 1.92, 2.32], [0, -0.05, 0], shell, 0.14);
  box(model, [5.40, 0.075, 2.25], [0, 0.95, 0], dark, 0.035);
  box(model, [5.52, 0.62, 2.34], [0, 1.30, 0], shell, 0.13);
  box(model, [5.28, 0.033, 2.13], [0, 0.986, 0], aluminum, 0.015);
  // Recessed, finely ribbed front and rear panels.
  for (const side of [-1, 1]) {
    box(model, [4.72, 1.38, 0.065], [0, -0.11, side * 1.17], panel, 0.095);
    for (const x of [-1.48, -1.20, 1.20, 1.48]) {
      box(model, [0.095, 1.04, 0.085], [x, -0.12, side * 1.213], shell, 0.035);
    }
    box(model, [4.61, 0.028, 0.016], [0, -0.73, side * 1.212], steel, 0.007);
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
  // Two deep mechanical latches on the front.
  for (const x of [-1.85, 1.85]) {
    box(model, [0.42, 0.64, 0.11], [x, 0.88, 1.23], aluminum, 0.04);
    box(model, [0.29, 0.33, 0.075], [x, 0.84, 1.31], dark, 0.025);
    box(model, [0.25, 0.24, 0.10], [x, 0.85, 1.355], steel, 0.03);
    cylinder(model, 0.07, 0.38, [x, 0.98, 1.36], aluminum, 'x');
    box(model, [0.22, 0.035, 0.018], [x, 0.79, 1.413], aluminum, 0.008);
    screw(x, 1.14, 1.30); screw(x, 0.59, 1.30);
    // Recessed band along the top of the lid.
    box(model, [0.22, 0.035, 2.04], [x, 1.615, 0], steel, 0.015);
  }
  // Hinge barrels and back plates are visible when the player rotates the case.
  for (const x of [-1.8, 1.8]) {
    box(model, [0.65, 0.48, 0.09], [x, 0.96, -1.21], steel, 0.035);
    for (let i = -1; i <= 1; i++) cylinder(model, 0.09, 0.18, [x + i * 0.20, 0.98, -1.31], i === 0 ? steel : aluminum, 'x');
    screw(x - 0.2, 1.13, -1.27, false); screw(x + 0.2, 0.79, -1.27, false);
  }
  // A solid carry handle with an actual opening and a ribbed rubber grip.
  for (const x of [-0.8, 0.8]) box(model, [0.35, 0.13, 0.5], [x, 1.66, 0], aluminum, 0.045);
  function roundedPath(path, x, y, w, h, r) {
    path.moveTo(x + r, y); path.lineTo(x + w - r, y); path.quadraticCurveTo(x + w, y, x + w, y + r);
    path.lineTo(x + w, y + h - r); path.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    path.lineTo(x + r, y + h); path.quadraticCurveTo(x, y + h, x, y + h - r);
    path.lineTo(x, y + r); path.quadraticCurveTo(x, y, x + r, y);
  }
  const handleShape = new THREE.Shape(); roundedPath(handleShape, -0.95, 0, 1.9, 0.69, 0.20);
  const hole = new THREE.Path(); roundedPath(hole, -0.72, 0.12, 1.44, 0.35, 0.10); handleShape.holes.push(hole);
  // The opening stays clear above the top plate; a dark grip caps the metal arch.
  const handleGeo = new THREE.ExtrudeGeometry(handleShape, { depth: 0.16, bevelEnabled: true, bevelSize: 0.03, bevelThickness: 0.025, bevelSegments: 3, curveSegments: 16 });
  const handle = new THREE.Mesh(handleGeo, aluminum); handle.position.set(0, 1.70, -0.08); handle.castShadow = true; model.add(handle);
  box(model, [1.24, 0.24, 0.25], [0, 2.29, 0], rubber, 0.07);
  for (let i = -5; i <= 5; i++) box(model, [0.035, 0.245, 0.255], [i * 0.094, 2.29, 0], dark, 0.009);
  // Center badge, status light, side vents and non-slip feet.
  box(model, [0.91, 0.37, 0.035], [0, 0.15, 1.225], steel, 0.045);
  box(model, [0.52, 0.047, 0.018], [-0.04, 0.20, 1.251], aluminum, 0.012);
  box(model, [0.31, 0.028, 0.018], [-0.145, 0.09, 1.251], aluminum, 0.009);
  box(model, [0.055, 0.055, 0.025], [0.30, 0.145, 1.26], indicator, 0.015);
  for (const side of [-1, 1]) {
    box(model, [0.035, 1.0, 1.43], [side * 2.763, -0.1, 0], panel, 0.015);
    for (let i = -2; i <= 2; i++) box(model, [0.025, 0.055, 0.90], [side * 2.79, -0.1 + i * 0.14, 0], dark, 0.012);
    for (const z of [-0.77, 0.77]) box(model, [0.77, 0.24, 0.48], [side * 1.93, -1.10, z], rubber, 0.07);
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
  controls.target.set(0, 1.88, 0); controls.enableDamping = true; controls.dampingFactor = 0.07;
  controls.enablePan = false; controls.enableZoom = false;
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
