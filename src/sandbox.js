import * as THREE from 'three';
import * as CANNON from 'cannon-es';
import {createGravityGun} from './gravity-gun.js';
import {createGravityBeam} from './gravity-beam.js';
try {
 const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));renderer.setSize(innerWidth,innerHeight);renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.25;renderer.setClearColor(0x858585);document.body.prepend(renderer.domElement);
 const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(75,innerWidth/innerHeight,.06,80);camera.rotation.order='YXZ';scene.add(camera);
 const world=new CANNON.World({gravity:new CANNON.Vec3(0,-9.81,0)});world.broadphase=new CANNON.SAPBroadphase(world);world.solver.iterations=20;world.solver.tolerance=.0001;world.defaultContactMaterial.friction=.55;world.defaultContactMaterial.restitution=.08;
 const material=color=>new THREE.MeshStandardMaterial({color,roughness:.85,metalness:.04});
 function box(parent,size,pos,color){const m=new THREE.Mesh(new THREE.BoxGeometry(...size),typeof color==='number'?material(color):color);m.position.set(...pos);m.receiveShadow=true;m.castShadow=parent!==scene;parent.add(m);return m;}
 const roomMeshes=[];
 function staticBox(size,pos,color){const m=box(scene,size,pos,color);const b=new CANNON.Body({mass:0,shape:new CANNON.Box(new CANNON.Vec3(...size.map(v=>v/2)))});b.position.set(...pos);world.addBody(b);roomMeshes.push(m);return m;}
 staticBox([20,.3,20],[0,-.15,0],0x777777);staticBox([20,.3,20],[0,6.15,0],0x999999);
 staticBox([20,6,.3],[0,3,-10.15],0x8b8b8b);staticBox([20,6,.3],[0,3,10.15],0x858585);staticBox([.3,6,20],[-10.15,3,0],0x818181);staticBox([.3,6,20],[10.15,3,0],0x919191);
 // Recessed ceiling luminaires, with one shadow-casting light for predictable performance.
 scene.add(new THREE.HemisphereLight(0xdce8ff,0x6f6458,.8));
 for(const z of [-3,3]){
  box(scene,[2.65,.10,1.35],[0,5.91,z],0x333c44);
  box(scene,[2.43,.025,1.13],[0,5.845,z],new THREE.MeshBasicMaterial({color:0xe8f2ff,toneMapped:false}));
  const fill=new THREE.PointLight(0xd9e8ff,30,17,2);fill.position.set(0,5.65,z);scene.add(fill);
 }
 const overhead=new THREE.SpotLight(0xe7efff,145,25,1.20,.65,2);overhead.position.set(-1,5.65,1);overhead.target.position.set(0,0,0);overhead.castShadow=true;overhead.shadow.mapSize.set(1024,1024);overhead.shadow.camera.near=.3;overhead.shadow.camera.far=26;overhead.shadow.bias=-.0002;overhead.shadow.normalBias=.015;overhead.shadow.radius=3;scene.add(overhead,overhead.target);
 const cubeMaterials=[0xaaaaaa,0x969696,0xc2c2c2,0x858585,0xaeaeae,0x9d9d9d].map(material);
 const cube=box(scene,[1.2,1.2,1.2],[0,.62,0],cubeMaterials);cube.castShadow=true;
 const edges=new THREE.LineSegments(new THREE.EdgesGeometry(cube.geometry),new THREE.LineBasicMaterial({color:0x535353}));cube.add(edges);
 const cubeBody=new CANNON.Body({mass:12,shape:new CANNON.Box(new CANNON.Vec3(.6,.6,.6)),linearDamping:.035,angularDamping:.10,allowSleep:true,sleepSpeedLimit:.07});cubeBody.position.set(0,.62,0);cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);cubeBody.collisionFilterGroup=2;world.addBody(cubeBody);
 const player=new CANNON.Body({mass:75,shape:new CANNON.Box(new CANNON.Vec3(.3,.85,.3)),fixedRotation:true,linearDamping:.05,allowSleep:false});player.position.set(0,.88,6);player.updateMassProperties();player.collisionFilterGroup=4;world.addBody(player);
 const weapon=createGravityGun(camera),gun=weapon.gun;
 const energyBeam=createGravityBeam(scene);
 const gunLight=new THREE.PointLight(0xa3dfff,1.0,2.7,2);gunLight.position.set(.3,.12,-.32);camera.add(gunLight);
 const hint=document.querySelector('#hint'),crosshair=document.querySelector('#crosshair'),keys=new Set();let yaw=0,pitch=-.12,locked=false,holding=false,holdDistance=4,last=null,jump=false;
 const grabNormal=new THREE.Vector3(0,0,1),beamNormal=new THREE.Vector3(),muzzleDirection=new THREE.Vector3();
 const holdTarget=new THREE.Vector3(),previousHoldTarget=new THREE.Vector3(),targetVelocity=new THREE.Vector3(),goalDelta=new THREE.Vector3();
 const roomHit=new CANNON.RaycastResult(),roomFrom=new CANNON.Vec3(),roomTo=new CANNON.Vec3(),errorDirection=new CANNON.Vec3(),crossR=new CANNON.Vec3(),inertiaCross=new CANNON.Vec3();
 const ray=new THREE.Raycaster(),anchor=new CANNON.Vec3(),target=new THREE.Vector3(),forward=new THREE.Vector3(),gunTip=new THREE.Vector3(),grabWorld=new CANNON.Vec3(),grabVelocity=new CANNON.Vec3(),force=new CANNON.Vec3(),relative=new CANNON.Vec3();
 function syncView(){camera.position.set(player.position.x,player.position.y+.70,player.position.z);camera.rotation.set(pitch,yaw,0);camera.updateMatrixWorld(true);}
 function release(){holding=false;energyBeam.hide();crosshair.classList.remove('holding');}
 function grab(){if(holding)return;syncView();cube.updateMatrixWorld(true);ray.setFromCamera(new THREE.Vector2(0,0),camera);const hits=ray.intersectObject(cube,false);if(!hits.length||hits[0].distance>7)return;const p=hits[0].point;cubeBody.pointToLocalFrame(new CANNON.Vec3(p.x,p.y,p.z),anchor);holdDistance=THREE.MathUtils.clamp(hits[0].distance,1.8,6.5);grabNormal.copy(hits[0].face.normal);holdTarget.copy(p);previousHoldTarget.copy(p);holding=true;cubeBody.wakeUp();crosshair.classList.add('holding');}
 function throwCube(){if(!holding)return;weapon.kick();camera.getWorldDirection(forward);cubeBody.vectorToWorldFrame(anchor,relative);release();cubeBody.applyImpulse(new CANNON.Vec3(forward.x*125,forward.y*125,forward.z*125),relative);}
 function resetCube(){release();cubeBody.position.set(0,.62,0);cubeBody.quaternion.set(0,0,0,1);cubeBody.velocity.setZero();cubeBody.angularVelocity.setZero();cubeBody.force.setZero();cubeBody.torque.setZero();cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);cubeBody.previousQuaternion.copy(cubeBody.quaternion);cubeBody.interpolatedQuaternion.copy(cubeBody.quaternion);cubeBody.aabbNeedsUpdate=true;cubeBody.wakeUp();}
 async function enter(){try{await renderer.domElement.requestPointerLock();}catch{hint.textContent='Нажми ещё раз для захвата мыши';}}
 hint.addEventListener('click',enter);renderer.domElement.addEventListener('pointerdown',e=>{if(!locked){enter();return;}if(e.button===0)grab();if(e.button===2)throwCube();});
 addEventListener('pointerup',e=>{if(e.button===0)release();});addEventListener('pointercancel',release);
 document.addEventListener('pointerlockchange',()=>{locked=document.pointerLockElement===renderer.domElement;hint.classList.toggle('hidden',locked);if(!locked){keys.clear();jump=false;release();}last=null;});
 document.addEventListener('mousemove',e=>{if(!locked)return;yaw-=e.movementX*.0023;pitch=THREE.MathUtils.clamp(pitch-e.movementY*.0023,-1.48,1.48);});
 renderer.domElement.addEventListener('contextmenu',e=>e.preventDefault());renderer.domElement.addEventListener('wheel',e=>{if(!locked)return;e.preventDefault();const awayFromPlayer=Math.sign(-e.deltaY);holdDistance=THREE.MathUtils.clamp(holdDistance+awayFromPlayer*.35,1.8,6.5);},{passive:false});
 addEventListener('keydown',e=>{if(e.code==='Escape'&&locked){document.exitPointerLock();return;}if(['KeyW','KeyA','KeyS','KeyD','Space','KeyR'].includes(e.code)&&locked){e.preventDefault();keys.add(e.code);if(e.code==='Space'&&!e.repeat)jump=true;if(e.code==='KeyR'&&!e.repeat)resetCube();}});addEventListener('keyup',e=>keys.delete(e.code));addEventListener('blur',()=>{keys.clear();release();});
 world.addEventListener('preStep',()=>{
  const x=Number(keys.has('KeyD'))-Number(keys.has('KeyA')),z=Number(keys.has('KeyS'))-Number(keys.has('KeyW')),n=Math.hypot(x,z)||1;
  const grounded=world.contacts.some(c=>{
   if(c.bi===player)return c.ni.y<-.6;
   if(c.bj===player)return c.ni.y>.6;
   return false;
  });
  player.velocity.x=(Math.cos(yaw)*x+Math.sin(yaw)*z)/n*4.5;
  player.velocity.z=(-Math.sin(yaw)*x+Math.cos(yaw)*z)/n*4.5;
  if(jump&&grounded)player.velocity.y=5;jump=false;
  if(holding){
   syncView();camera.getWorldDirection(forward);target.copy(camera.position).addScaledVector(forward,holdDistance);
   roomFrom.set(camera.position.x,camera.position.y,camera.position.z);roomTo.set(target.x,target.y,target.z);roomHit.reset();
   world.raycastClosest(roomFrom,roomTo,{collisionFilterMask:1},roomHit);
   if(roomHit.hasHit)target.copy(camera.position).addScaledVector(forward,Math.max(.4,roomHit.distance-.72));
   target.x=THREE.MathUtils.clamp(target.x,-9.25,9.25);target.y=THREE.MathUtils.clamp(target.y,.65,5.25);target.z=THREE.MathUtils.clamp(target.z,-9.25,9.25);
   previousHoldTarget.copy(holdTarget);goalDelta.subVectors(target,holdTarget).clampLength(0,7/120);holdTarget.add(goalDelta);targetVelocity.subVectors(holdTarget,previousHoldTarget).multiplyScalar(120);
   cubeBody.pointToWorldFrame(anchor,grabWorld);cubeBody.getVelocityAtWorldPoint(grabWorld,grabVelocity);grabWorld.vsub(cubeBody.position,relative);
   errorDirection.set(holdTarget.x-grabWorld.x,holdTarget.y-grabWorld.y,holdTarget.z-grabWorld.z);
   const error=errorDirection.length();if(error>4){release();return;}if(error>.001)errorDirection.scale(1/error,errorDirection);else errorDirection.set(0,1,0);
   relative.cross(errorDirection,crossR);cubeBody.invInertiaWorld.vmult(crossR,inertiaCross);
   const effectiveMass=1/(cubeBody.invMass+crossR.dot(inertiaCross));
   const stiffness=effectiveMass*196,damping=effectiveMass*26.6;
   force.set((holdTarget.x-grabWorld.x)*stiffness+(targetVelocity.x-grabVelocity.x)*damping,(holdTarget.y-grabWorld.y)*stiffness+(targetVelocity.y-grabVelocity.y)*damping,(holdTarget.z-grabWorld.z)*stiffness+(targetVelocity.z-grabVelocity.z)*damping);
   const magnitude=force.length();if(magnitude>1500)force.scale(1500/magnitude,force);
   cubeBody.applyForce(force,relative);cubeBody.wakeUp();
  }

 });
 // Additional swept-boundary guard: even fast thrown objects cannot tunnel out of the room.
 function contain(b){b.updateAABB();for(const axis of ['x','y','z']){
   const lower=axis==='y'?0:-10,upper=axis==='y'?6:10;
   if(b.aabb.lowerBound[axis]<lower){b.position[axis]+=lower-b.aabb.lowerBound[axis];if(b.velocity[axis]<0)b.velocity[axis]*=-.08;b.aabbNeedsUpdate=true;}
   if(b.aabb.upperBound[axis]>upper){b.position[axis]-=b.aabb.upperBound[axis]-upper;if(b.velocity[axis]>0)b.velocity[axis]*=-.08;b.aabbNeedsUpdate=true;}
 }}
 world.addEventListener('postStep',()=>{contain(player);contain(cubeBody);});
 const wallRay=new THREE.Raycaster(),obstructionDirection=new THREE.Vector3();wallRay.far=1.4;
 function render(dt=1/60){syncView();const p=cubeBody.interpolatedPosition,q=cubeBody.interpolatedQuaternion;cube.position.set(p.x,p.y,p.z);cube.quaternion.set(q.x,q.y,q.z,q.w);
  obstructionDirection.set(.43,-.27,-1.1).applyMatrix4(camera.matrixWorld).sub(camera.position).normalize();wallRay.set(camera.position,obstructionDirection);
  const obstruction=wallRay.intersectObjects(roomMeshes,false)[0];const blocked=obstruction?THREE.MathUtils.clamp((1.25-obstruction.distance)/.9,0,1):0;
  weapon.update(dt,blocked,holding);
  if(holding){cubeBody.pointToWorldFrame(anchor,grabWorld);weapon.muzzle(gunTip);target.copy(grabNormal).applyQuaternion(cube.quaternion).normalize();beamNormal.copy(target);muzzleDirection.set(0,0,-1).transformDirection(gun.matrixWorld);target.copy(anchor).applyQuaternion(cube.quaternion).add(cube.position);energyBeam.update(gunTip,target,dt,{direction:muzzleDirection,normal:beamNormal});}else energyBeam.hide();
  renderer.render(scene,camera);
 }
 function frame(now){requestAnimationFrame(frame);if(document.hidden){last=null;return;}const dt=last===null?1/120:Math.min(.06,(now-last)/1000);last=now;world.step(1/120,dt,8);render(dt);}
 addEventListener('resize',()=>{renderer.setSize(innerWidth,innerHeight);camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();});syncView();render();requestAnimationFrame(frame);
 window.sandboxGame={ready:true,world,scene,camera,renderer,cube,cubeBody,player,weapon,energyBeam,grab,release,throwCube,resetCube,get holdDistance(){return holdDistance;},get holding(){return holding;},get locked(){return locked;}};
}catch(e){console.error(e);document.querySelector('#error').style.display='grid';}
