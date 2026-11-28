import * as THREE from 'three';
import * as CANNON from 'cannon-es';
import {createVoxelCar} from './voxel-car.js';

try {
  const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});
  renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));
  renderer.setSize(innerWidth,innerHeight);renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.18;
  document.body.prepend(renderer.domElement);renderer.domElement.tabIndex=0;renderer.domElement.setAttribute('aria-label','3D-игра: управление автомобилем WASD или стрелками');
  const scene=new THREE.Scene();scene.background=new THREE.Color(0xe6eae9);scene.fog=new THREE.Fog(0xe6eae9,55,230);
  const camera=new THREE.PerspectiveCamera(48,innerWidth/innerHeight,.1,350);
  scene.add(new THREE.HemisphereLight(0xf2f7ff,0x7e8b75,2.5));
  const sun=new THREE.DirectionalLight(0xfff0d7,3.2);sun.position.set(-10,16,8);sun.castShadow=true;sun.shadow.mapSize.set(1024,1024);sun.shadow.camera.left=-12;sun.shadow.camera.right=12;sun.shadow.camera.top=12;sun.shadow.camera.bottom=-12;sun.shadow.camera.near=.5;sun.shadow.camera.far=50;sun.shadow.normalBias=.035;sun.shadow.bias=-.00008;scene.add(sun,sun.target);
  const groundCanvas=document.createElement('canvas');groundCanvas.width=groundCanvas.height=32;
  const ctx=groundCanvas.getContext('2d');
  const grassColors=['#b6c4a5','#b4c2a2','#b2c0a1','#b8c6a7','#bac7a9'];
  for(let x=0;x<32;x++)for(let y=0;y<32;y++){
    const noise=((x*73856093^y*19349663)>>>0)%grassColors.length;
    ctx.fillStyle=grassColors[noise];ctx.fillRect(x,y,1,1);
  }

  const groundTexture=new THREE.CanvasTexture(groundCanvas);groundTexture.colorSpace=THREE.SRGBColorSpace;groundTexture.wrapS=groundTexture.wrapT=THREE.RepeatWrapping;groundTexture.repeat.set(8000,8000);groundTexture.magFilter=THREE.NearestFilter;groundTexture.anisotropy=Math.min(8,renderer.capabilities.getMaxAnisotropy());
  const floor=new THREE.Mesh(new THREE.PlaneGeometry(24000,24000),new THREE.MeshStandardMaterial({map:groundTexture,roughness:1,metalness:0}));floor.rotation.x=-Math.PI/2;floor.receiveShadow=true;scene.add(floor);


  const world=new CANNON.World({gravity:new CANNON.Vec3(0,-9.81,0),allowSleep:true});world.solver.iterations=12;
  const groundMat=new CANNON.Material('ground'),chassisMat=new CANNON.Material('car');
  world.addContactMaterial(new CANNON.ContactMaterial(groundMat,chassisMat,{friction:.4,restitution:.05}));
  const ground=new CANNON.Body({mass:0,material:groundMat,shape:new CANNON.Box(new CANNON.Vec3(12000,.5,12000))});ground.position.y=-.5;world.addBody(ground);
  const body=new CANNON.Body({mass:1250,material:chassisMat,linearDamping:.025,angularDamping:.4,allowSleep:false});
  body.addShape(new CANNON.Box(new CANNON.Vec3(.84,.23,1.85)),new CANNON.Vec3(0,.13,0));
  body.addShape(new CANNON.Box(new CANNON.Vec3(.65,.27,.75)),new CANNON.Vec3(0,.55,.2));
  body.position.set(0,.9,0);
  const vehicle=new CANNON.RaycastVehicle({chassisBody:body,indexRightAxis:0,indexUpAxis:1,indexForwardAxis:2});
  const wheelOptions={radius:.34,directionLocal:new CANNON.Vec3(0,-1,0),axleLocal:new CANNON.Vec3(-1,0,0),suspensionStiffness:34,suspensionRestLength:.32,frictionSlip:3.8,dampingRelaxation:3.8,dampingCompression:4.8,maxSuspensionForce:22000,rollInfluence:.035,maxSuspensionTravel:.23,customSlidingRotationalSpeed:-24,useCustomSlidingRotationalSpeed:true};
  for(const z of [-1.22,1.22])for(const x of [-.90,.90])vehicle.addWheel({...wheelOptions,chassisConnectionPointLocal:new CANNON.Vec3(x,.08,z),isFrontWheel:z<0});
  vehicle.addToWorld(world);

  const {car,wheels,brakeRed,voxelCount}=createVoxelCar(scene);

  const input={forward:false,back:false,left:false,right:false,brake:false};
  const keyMap={KeyW:'forward',ArrowUp:'forward',KeyS:'back',ArrowDown:'back',KeyA:'left',ArrowLeft:'left',KeyD:'right',ArrowRight:'right',Space:'brake'};
  const held=new Set(),touches=new Map();
  function updateInput(){for(const name of Object.keys(input))input[name]=[...held].some(code=>keyMap[code]===name)||[...touches.values()].includes(name);}
  function clearInput(){held.clear();touches.clear();updateInput();document.querySelectorAll('.active').forEach(el=>el.classList.remove('active'));}
  addEventListener('keydown',e=>{if(keyMap[e.code]){e.preventDefault();held.add(e.code);updateInput();}if(e.code==='KeyR'&&!e.repeat){e.preventDefault();reset();}});
  addEventListener('keyup',e=>{if(keyMap[e.code]){e.preventDefault();held.delete(e.code);updateInput();}});
  for(const button of document.querySelectorAll('[data-control]')){
    button.addEventListener('pointerdown',e=>{e.preventDefault();button.setPointerCapture(e.pointerId);touches.set(e.pointerId,button.dataset.control);button.classList.add('active');updateInput();});
    const release=e=>{touches.delete(e.pointerId);button.classList.remove('active');updateInput();};button.addEventListener('pointerup',release);button.addEventListener('pointercancel',release);button.addEventListener('lostpointercapture',release);
  }
  let paused=false,last=null,steer=0,simTime=0;
  const pauseLabel=document.querySelector('#pause');
  addEventListener('blur',()=>{paused=true;clearInput();pauseLabel.classList.add('show');last=null;});
  addEventListener('focus',()=>{paused=false;pauseLabel.classList.remove('show');last=null;});
  document.addEventListener('visibilitychange',()=>{paused=document.hidden;if(paused)clearInput();pauseLabel.classList.toggle('show',paused);last=null;});
  const speedEl=document.querySelector('#speed'),gearEl=document.querySelector('#gear'),fillEl=document.querySelector('#speed-fill');
  const desiredCamera=new THREE.Vector3(),lookAt=new THREE.Vector3(),carPosition=new THREE.Vector3(),carRotation=new THREE.Quaternion(),cameraOffset=new THREE.Vector3(),targetOffset=new THREE.Vector3(),sunOffset=new THREE.Vector3(-10,16,8);
  const localWheel=new THREE.Vector3(),wheelSteer=new THREE.Quaternion(),wheelSpin=new THREE.Quaternion(),upAxis=new THREE.Vector3(0,1,0),axleAxis=new THREE.Vector3(-1,0,0);
  let cameraInitialized=false;
  function reset(){clearInput();body.position.set(0,.9,0);body.quaternion.set(0,0,0,1);body.previousPosition.copy(body.position);body.interpolatedPosition.copy(body.position);body.previousQuaternion.copy(body.quaternion);body.interpolatedQuaternion.copy(body.quaternion);body.velocity.setZero();body.angularVelocity.setZero();body.force.setZero();body.torque.setZero();body.aabbNeedsUpdate=true;body.wakeUp();steer=0;for(let i=0;i<4;i++){vehicle.setSteeringValue(0,i);vehicle.applyEngineForce(0,i);vehicle.setBrake(0,i);vehicle.wheelInfos[i].rotation=0;vehicle.wheelInfos[i].deltaRotation=0;}world.accumulator=0;last=null;cameraInitialized=false;}
  document.querySelector('#reset').addEventListener('click',reset);
  const localVelocity=new CANNON.Vec3();
  function applyControls(dt){
    body.vectorToLocalFrame(body.velocity,localVelocity);
    const forwardSpeed=-localVelocity.z;
    const throttle=Number(input.forward)-Number(input.back);
    const targetSteer=(Number(input.left)-Number(input.right))*.46/(1+Math.abs(forwardSpeed)*.035);
    steer=THREE.MathUtils.damp(steer,targetSteer,9,dt);
    const reverseDirection=(throttle===1&&forwardSpeed<-.8)||(throttle===-1&&forwardSpeed>.8);
    const engine=reverseDirection||input.brake?0:throttle*(throttle<0?1700:2500);
    const limited=(throttle>0&&forwardSpeed>42)||(throttle<0&&forwardSpeed< -12);
    for(let i=0;i<4;i++){
      vehicle.setSteeringValue(i<2?steer:0,i);
      vehicle.applyEngineForce(limited?0:engine,i);
      vehicle.setBrake(input.brake?75:reverseDirection?55:throttle===0?1.1:0,i);
    }
    brakeRed.emissiveIntensity=input.brake||reverseDirection?3:.65;
    // Rolling and aerodynamic drag, independent of rendering frequency.
    if(body.velocity.lengthSquared()>.01){const speed=body.velocity.length();body.force.x-=body.velocity.x*(14+.46*speed);body.force.z-=body.velocity.z*(14+.46*speed);}
  }
  world.addEventListener('preStep',()=>applyControls(1/120));
  function simulate(dt){
    world.step(1/120,dt,12);simTime+=dt;
    if(body.position.y< -5||Math.abs(body.position.x)>9000||Math.abs(body.position.z)>9000)reset();
  }
  function render(dt){
    const p=body.interpolatedPosition,q=body.interpolatedQuaternion;car.position.set(p.x,p.y,p.z);car.quaternion.set(q.x,q.y,q.z,q.w);
    carPosition.copy(car.position);carRotation.copy(car.quaternion);
    const alpha=world.accumulator/(1/120);
    for(let i=0;i<4;i++){
      const w=vehicle.wheelInfos[i];
      localWheel.set(w.chassisConnectionPointLocal.x,w.chassisConnectionPointLocal.y-w.suspensionLength,w.chassisConnectionPointLocal.z).applyQuaternion(carRotation).add(carPosition);
      wheels[i].position.copy(localWheel);
      wheelSteer.setFromAxisAngle(upAxis,w.steering);wheelSpin.setFromAxisAngle(axleAxis,w.rotation-w.deltaRotation*(1-alpha));
      wheels[i].quaternion.copy(carRotation).multiply(wheelSteer).multiply(wheelSpin);
    }
    const speed=Math.hypot(body.velocity.x,body.velocity.z)*3.6;
    const portrait=innerWidth/innerHeight<.8;
    cameraOffset.set(portrait?4.2:4.9,portrait?3.6:3.1,(portrait?10.5:7.5)+Math.min(speed/90,1.5)).applyQuaternion(carRotation);
    desiredCamera.copy(carPosition).add(cameraOffset);desiredCamera.y=Math.max(desiredCamera.y,1.5);
    targetOffset.set(0,.45,portrait?0:-1.2).applyQuaternion(carRotation);lookAt.copy(carPosition).add(targetOffset);
    if(!cameraInitialized){camera.position.copy(desiredCamera);cameraInitialized=true;}else camera.position.lerp(desiredCamera,1-Math.exp(-5*dt));
    camera.lookAt(lookAt);
    sun.position.copy(carPosition).add(sunOffset);sun.target.position.copy(carPosition);
    const value=Math.round(speed);if(speedEl.textContent!==String(value))speedEl.textContent=String(value);
    gearEl.textContent=value<1&&!input.forward&&!input.back?'N':localVelocity.z> .5?'R':'D';fillEl.style.transform=`scaleX(${Math.min(speed/160,1)})`;
    renderer.render(scene,camera);
  }
  function frame(now){requestAnimationFrame(frame);if(document.hidden)return;const dt=last===null?1/120:Math.min(.075,Math.max(0,(now-last)/1000));last=now;if(!paused)simulate(dt);render(dt);}
  function resize(){renderer.setSize(innerWidth,innerHeight);camera.aspect=innerWidth/innerHeight;camera.fov=innerWidth/innerHeight<.8?58:48;camera.updateProjectionMatrix();}
  addEventListener('resize',resize);resize();reset();render(1/60);requestAnimationFrame(frame);
  renderer.domElement.addEventListener('webglcontextlost',e=>{e.preventDefault();paused=true;clearInput();document.querySelector('#error').classList.add('show');});
  renderer.domElement.addEventListener('webglcontextrestored',()=>location.reload());
  window.carGame={ready:true,scene,camera,renderer,car,body,world,vehicle,input,reset,voxelCount,get paused(){return paused;},get speed(){return Math.hypot(body.velocity.x,body.velocity.z)*3.6;},get simulationTime(){return simTime;}};
} catch(error){console.error(error);document.querySelector('#error').classList.add('show');}
