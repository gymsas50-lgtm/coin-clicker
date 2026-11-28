import * as THREE from 'three';
import * as CANNON from 'cannon-es';
import {createGravityGun} from './gravity-gun.js';
import {createGravityBeam} from './gravity-beam.js';
import {createOutdoors} from './outdoors.js';
try {
 const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));renderer.setSize(innerWidth,innerHeight);renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.25;renderer.setClearColor(0x858585);document.body.prepend(renderer.domElement);
 const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(75,innerWidth/innerHeight,.06,2200);camera.rotation.order='YXZ';scene.add(camera);
 const world=new CANNON.World({gravity:new CANNON.Vec3(0,-9.81,0)});world.broadphase=new CANNON.SAPBroadphase(world);world.solver.iterations=20;world.solver.tolerance=.0001;world.defaultContactMaterial.friction=.55;world.defaultContactMaterial.restitution=.08;
 const material=color=>new THREE.MeshStandardMaterial({color,roughness:.85,metalness:.04});
 function box(parent,size,pos,color){const m=new THREE.Mesh(new THREE.BoxGeometry(...size),typeof color==='number'?material(color):color);m.position.set(...pos);m.receiveShadow=true;m.castShadow=parent!==scene;parent.add(m);return m;}
 const outdoors=createOutdoors({scene,world,renderer});
 const roomMeshes=[outdoors.ground];
 const cubeMaterials=[0xaaaaaa,0x969696,0xc2c2c2,0x858585,0xaeaeae,0x9d9d9d].map(material);
 const cube=box(scene,[.7,.7,.7],[0,.37,0],cubeMaterials);cube.castShadow=true;
 const edges=new THREE.LineSegments(new THREE.EdgesGeometry(cube.geometry),new THREE.LineBasicMaterial({color:0x535353}));cube.add(edges);
 const cubeBody=new CANNON.Body({mass:3,shape:new CANNON.Box(new CANNON.Vec3(.35,.35,.35)),linearDamping:.035,angularDamping:.10,allowSleep:true,sleepSpeedLimit:.07});cubeBody.position.set(0,.37,0);cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);cubeBody.collisionFilterGroup=2;world.addBody(cubeBody);
 const player=new CANNON.Body({mass:75,shape:new CANNON.Box(new CANNON.Vec3(.3,.85,.3)),fixedRotation:true,linearDamping:.05,allowSleep:false});player.position.set(0,.88,6);player.updateMassProperties();player.collisionFilterGroup=4;world.addBody(player);
 const props=[{mesh:cube,body:cubeBody}];
 let activeBody=cubeBody,activeMesh=cube;
 const weapon=createGravityGun(camera),gun=weapon.gun;
 const energyBeam=createGravityBeam(scene);
 const gunLight=new THREE.PointLight(0x88ffb0,1.0,2.7,2);gunLight.position.set(.3,.12,-.32);camera.add(gunLight);
 const hint=document.querySelector('#hint'),crosshair=document.querySelector('#crosshair'),keys=new Set();let yaw=0,pitch=-.12,locked=false,holding=false,holdDistance=2.5,last=null,jump=false;
 const orbRay=new THREE.Raycaster(),orbDirection=new THREE.Vector3();
 const grabNormal=new THREE.Vector3(0,0,1),beamNormal=new THREE.Vector3(),muzzleDirection=new THREE.Vector3();
 const holdTarget=new THREE.Vector3(),previousHoldTarget=new THREE.Vector3(),targetVelocity=new THREE.Vector3(),goalDelta=new THREE.Vector3();
 const roomHit=new CANNON.RaycastResult(),roomFrom=new CANNON.Vec3(),roomTo=new CANNON.Vec3(),errorDirection=new CANNON.Vec3(),crossR=new CANNON.Vec3(),inertiaCross=new CANNON.Vec3();
 const ray=new THREE.Raycaster(),anchor=new CANNON.Vec3(),target=new THREE.Vector3(),forward=new THREE.Vector3(),gunTip=new THREE.Vector3(),grabWorld=new CANNON.Vec3(),grabVelocity=new CANNON.Vec3(),force=new CANNON.Vec3(),relative=new CANNON.Vec3();
 function syncView(){camera.position.set(player.position.x,player.position.y+.70,player.position.z);camera.rotation.set(pitch,yaw,0);camera.updateMatrixWorld(true);}
 function release(){holding=false;energyBeam.hide();crosshair.classList.remove('holding');}
 function grab(){
  if(holding)return;syncView();for(const prop of props)prop.mesh.updateMatrixWorld(true);ray.setFromCamera(new THREE.Vector2(0,0),camera);
  const hits=ray.intersectObjects(props.map(p=>p.mesh),true).filter(h=>h.object.isMesh&&h.face);if(!hits.length||hits[0].distance>3)return;
  const hit=hits[0];let node=hit.object,prop;while(node&&!prop){prop=props.find(p=>p.mesh===node);node=node.parent;}
  if(!prop)return;if(prop.detach)prop.detach();activeBody=prop.body;activeMesh=prop.mesh;
  const p=hit.point;activeBody.pointToLocalFrame(new CANNON.Vec3(p.x,p.y,p.z),anchor);holdDistance=THREE.MathUtils.clamp(hit.distance,1.2,3);
  grabNormal.copy(hit.face.normal).transformDirection(hit.object.matrixWorld).applyQuaternion(activeMesh.getWorldQuaternion(new THREE.Quaternion()).invert()).normalize();
  holdTarget.copy(p);previousHoldTarget.copy(p);holding=true;activeBody.wakeUp();crosshair.classList.add('holding');
 }

 function resetCube(){release();activeBody=cubeBody;activeMesh=cube;cubeBody.position.set(THREE.MathUtils.clamp(player.position.x-Math.sin(yaw)*2,-12.1,12.1),.37,THREE.MathUtils.clamp(player.position.z-Math.cos(yaw)*2,-12.1,12.1));cubeBody.quaternion.set(0,0,0,1);cubeBody.velocity.setZero();cubeBody.angularVelocity.setZero();cubeBody.force.setZero();cubeBody.torque.setZero();cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);cubeBody.previousQuaternion.copy(cubeBody.quaternion);cubeBody.interpolatedQuaternion.copy(cubeBody.quaternion);cubeBody.aabbNeedsUpdate=true;cubeBody.wakeUp();}
 async function enter(){try{await renderer.domElement.requestPointerLock();}catch{hint.textContent='Нажми ещё раз для захвата мыши';}}
 hint.addEventListener('click',enter);renderer.domElement.addEventListener('pointerdown',e=>{if(!locked){enter();return;}if(e.button===0)grab();});
 addEventListener('pointerup',e=>{if(e.button===0)release();});addEventListener('pointercancel',release);
 document.addEventListener('pointerlockchange',()=>{locked=document.pointerLockElement===renderer.domElement;hint.classList.toggle('hidden',locked);if(!locked){keys.clear();jump=false;release();}last=null;});
 document.addEventListener('mousemove',e=>{if(!locked)return;yaw-=e.movementX*.0023;pitch=THREE.MathUtils.clamp(pitch-e.movementY*.0023,-1.48,1.48);});
 renderer.domElement.addEventListener('contextmenu',e=>e.preventDefault());renderer.domElement.addEventListener('wheel',e=>{if(!locked)return;e.preventDefault();const awayFromPlayer=Math.sign(-e.deltaY);holdDistance=THREE.MathUtils.clamp(holdDistance+awayFromPlayer*.25,1.2,3);},{passive:false});
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
   if(roomHit.hasHit)target.copy(camera.position).addScaledVector(forward,Math.max(.4,roomHit.distance-.42));
   target.x=THREE.MathUtils.clamp(target.x,-12.1,12.1);target.y=Math.max(.4,target.y);target.z=THREE.MathUtils.clamp(target.z,-12.1,12.1);
   previousHoldTarget.copy(holdTarget);goalDelta.subVectors(target,holdTarget).clampLength(0,7/120);holdTarget.add(goalDelta);targetVelocity.subVectors(holdTarget,previousHoldTarget).multiplyScalar(120);
   activeBody.pointToWorldFrame(anchor,grabWorld);activeBody.getVelocityAtWorldPoint(grabWorld,grabVelocity);grabWorld.vsub(activeBody.position,relative);
   errorDirection.set(holdTarget.x-grabWorld.x,holdTarget.y-grabWorld.y,holdTarget.z-grabWorld.z);
   const error=errorDirection.length();if(error>4){release();return;}if(error>.001)errorDirection.scale(1/error,errorDirection);else errorDirection.set(0,1,0);
   relative.cross(errorDirection,crossR);activeBody.invInertiaWorld.vmult(crossR,inertiaCross);
   const effectiveMass=1/(activeBody.invMass+crossR.dot(inertiaCross));
   const stiffness=effectiveMass*196,damping=effectiveMass*26.6;
   force.set((holdTarget.x-grabWorld.x)*stiffness+(targetVelocity.x-grabVelocity.x)*damping,(holdTarget.y-grabWorld.y)*stiffness+(targetVelocity.y-grabVelocity.y)*damping,(holdTarget.z-grabWorld.z)*stiffness+(targetVelocity.z-grabVelocity.z)*damping);
   const magnitude=force.length();if(magnitude>1500)force.scale(1500/magnitude,force);
   activeBody.applyForce(force,relative);activeBody.wakeUp();
  }

 });
 // Invisible map boundary, no ceiling: keep all bodies on the 25 x 25 m field.
 function contain(b){b.updateAABB();for(const axis of ['x','y','z']){
  const lower=axis==='y'?0:-12.5,upper=axis==='y'?Infinity:12.5;
  if(b.aabb.lowerBound[axis]<lower){b.position[axis]+=lower-b.aabb.lowerBound[axis];if(b.velocity[axis]<0)b.velocity[axis]*=-.08;b.aabbNeedsUpdate=true;}
  if(b.aabb.upperBound[axis]>upper){b.position[axis]-=b.aabb.upperBound[axis]-upper;if(b.velocity[axis]>0)b.velocity[axis]*=-.08;b.aabbNeedsUpdate=true;}
 }}
 world.addEventListener('postStep',()=>{contain(player);contain(cubeBody);});
 const wallRay=new THREE.Raycaster(),obstructionDirection=new THREE.Vector3();wallRay.far=1.4;
 function render(dt=1/60){syncView();outdoors.tick(camera);const p=cubeBody.interpolatedPosition,q=cubeBody.interpolatedQuaternion;cube.position.set(p.x,p.y,p.z);cube.quaternion.set(q.x,q.y,q.z,q.w);
  obstructionDirection.set(.43,-.27,-1.1).applyMatrix4(camera.matrixWorld).sub(camera.position).normalize();wallRay.set(camera.position,obstructionDirection);
  const obstruction=wallRay.intersectObjects(roomMeshes,false)[0];const blocked=obstruction?THREE.MathUtils.clamp((1.25-obstruction.distance)/.9,0,1):0;
  weapon.update(dt,blocked,holding);
  if(holding){activeBody.pointToWorldFrame(anchor,grabWorld);weapon.muzzle(gunTip);target.copy(grabNormal).applyQuaternion(activeMesh.quaternion).normalize();beamNormal.copy(target);muzzleDirection.set(0,0,-1).transformDirection(gun.matrixWorld);target.copy(anchor).applyQuaternion(activeMesh.quaternion).add(activeMesh.position);activeMesh.updateMatrixWorld(true);orbDirection.subVectors(target,camera.position);const orbDistance=orbDirection.length();orbDirection.normalize();orbRay.set(camera.position,orbDirection);orbRay.far=orbDistance;
   const orbBlock=orbRay.intersectObject(activeMesh,true).find(h=>h.object.isMesh);const contactVisible=!orbBlock||orbBlock.distance>=orbDistance-.045;
   energyBeam.update(gunTip,target,dt,{direction:muzzleDirection,normal:beamNormal,contactVisible});}else energyBeam.hide();
  renderer.render(scene,camera);
 }
 function frame(now){requestAnimationFrame(frame);if(document.hidden){last=null;return;}const dt=last===null?1/120:Math.min(.06,(now-last)/1000);last=now;world.step(1/120,dt,8);render(dt);}
 addEventListener('resize',()=>{renderer.setSize(innerWidth,innerHeight);camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();});syncView();render();requestAnimationFrame(frame);
 window.sandboxGame={ready:true,world,scene,camera,renderer,cube,cubeBody,player,weapon,energyBeam,outdoors,get heldBody(){return holding?activeBody:null;},grab,release,resetCube,get holdDistance(){return holdDistance;},get holding(){return holding;},get locked(){return locked;}};
}catch(e){console.error(e);document.querySelector('#error').style.display='grid';}
