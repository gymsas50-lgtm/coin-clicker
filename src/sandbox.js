import * as THREE from 'three';
import * as CANNON from 'cannon-es';
import {createGravityGun} from './gravity-gun.js';
try {
 const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));renderer.setSize(innerWidth,innerHeight);renderer.shadowMap.enabled=false;renderer.setClearColor(0x858585);document.body.prepend(renderer.domElement);
 const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(75,innerWidth/innerHeight,.06,80);camera.rotation.order='YXZ';scene.add(camera);
 const world=new CANNON.World({gravity:new CANNON.Vec3(0,-9.81,0)});world.broadphase=new CANNON.SAPBroadphase(world);world.solver.iterations=12;world.defaultContactMaterial.friction=.55;world.defaultContactMaterial.restitution=.08;
 const material=color=>new THREE.MeshBasicMaterial({color});
 function box(parent,size,pos,color){const m=new THREE.Mesh(new THREE.BoxGeometry(...size),typeof color==='number'?material(color):color);m.position.set(...pos);parent.add(m);return m;}
 const roomMeshes=[];
 function staticBox(size,pos,color){const m=box(scene,size,pos,color);const b=new CANNON.Body({mass:0,shape:new CANNON.Box(new CANNON.Vec3(...size.map(v=>v/2)))});b.position.set(...pos);world.addBody(b);roomMeshes.push(m);return m;}
 staticBox([20,.3,20],[0,-.15,0],0x777777);staticBox([20,.3,20],[0,6.15,0],0x999999);
 staticBox([20,6,.3],[0,3,-10.15],0x8b8b8b);staticBox([20,6,.3],[0,3,10.15],0x858585);staticBox([.3,6,20],[-10.15,3,0],0x818181);staticBox([.3,6,20],[10.15,3,0],0x919191);
 // Unlit face colours keep depth legible without lights, shadows or post-processing.
 const cubeMaterials=[0xaaaaaa,0x969696,0xc2c2c2,0x858585,0xaeaeae,0x9d9d9d].map(material);
 const cube=box(scene,[1.2,1.2,1.2],[0,.62,0],cubeMaterials);
 const edges=new THREE.LineSegments(new THREE.EdgesGeometry(cube.geometry),new THREE.LineBasicMaterial({color:0x535353}));cube.add(edges);
 const cubeBody=new CANNON.Body({mass:12,shape:new CANNON.Box(new CANNON.Vec3(.6,.6,.6)),linearDamping:.08,angularDamping:.18,allowSleep:true,sleepSpeedLimit:.07});cubeBody.position.set(0,.62,0);cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);world.addBody(cubeBody);
 const player=new CANNON.Body({mass:75,shape:new CANNON.Box(new CANNON.Vec3(.3,.85,.3)),fixedRotation:true,linearDamping:.05,allowSleep:false});player.position.set(0,.88,6);player.updateMassProperties();world.addBody(player);
 const weapon=createGravityGun(camera),gun=weapon.gun,glow=new THREE.MeshBasicMaterial({color:0xffba57});
 const beamGeometry=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(),new THREE.Vector3()]);const beam=new THREE.Line(beamGeometry,new THREE.LineBasicMaterial({color:0xffae39,transparent:true,opacity:.85,depthTest:true}));beam.frustumCulled=false;scene.add(beam);beam.visible=false;
 const point=new THREE.Mesh(new THREE.SphereGeometry(.035,8,6),glow);scene.add(point);point.visible=false;
 const hint=document.querySelector('#hint'),crosshair=document.querySelector('#crosshair'),keys=new Set();let yaw=0,pitch=-.12,locked=false,holding=false,holdDistance=4,last=null,jump=false;
 const ray=new THREE.Raycaster(),anchor=new CANNON.Vec3(),target=new THREE.Vector3(),forward=new THREE.Vector3(),gunTip=new THREE.Vector3(),grabWorld=new CANNON.Vec3(),grabVelocity=new CANNON.Vec3(),force=new CANNON.Vec3(),relative=new CANNON.Vec3();
 function syncView(){camera.position.set(player.position.x,player.position.y+.70,player.position.z);camera.rotation.set(pitch,yaw,0);camera.updateMatrixWorld(true);}
 function release(){holding=false;beam.visible=false;point.visible=false;crosshair.classList.remove('holding');}
 function grab(){if(holding)return;syncView();cube.updateMatrixWorld(true);ray.setFromCamera(new THREE.Vector2(0,0),camera);const hits=ray.intersectObject(cube,false);if(!hits.length||hits[0].distance>7)return;const p=hits[0].point;cubeBody.pointToLocalFrame(new CANNON.Vec3(p.x,p.y,p.z),anchor);holdDistance=THREE.MathUtils.clamp(hits[0].distance,1.8,6.5);holding=true;cubeBody.wakeUp();crosshair.classList.add('holding');}
 function throwCube(){if(!holding)return;weapon.kick();camera.getWorldDirection(forward);release();cubeBody.applyImpulse(new CANNON.Vec3(forward.x*125,forward.y*125,forward.z*125));}
 function resetCube(){release();cubeBody.position.set(0,.62,0);cubeBody.quaternion.set(0,0,0,1);cubeBody.velocity.setZero();cubeBody.angularVelocity.setZero();cubeBody.force.setZero();cubeBody.torque.setZero();cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);cubeBody.previousQuaternion.copy(cubeBody.quaternion);cubeBody.interpolatedQuaternion.copy(cubeBody.quaternion);cubeBody.aabbNeedsUpdate=true;cubeBody.wakeUp();}
 async function enter(){try{await renderer.domElement.requestPointerLock();}catch{hint.textContent='Нажми ещё раз для захвата мыши';}}
 hint.addEventListener('click',enter);renderer.domElement.addEventListener('pointerdown',e=>{if(!locked){enter();return;}if(e.button===0)grab();if(e.button===2)throwCube();});
 addEventListener('pointerup',e=>{if(e.button===0)release();});addEventListener('pointercancel',release);
 document.addEventListener('pointerlockchange',()=>{locked=document.pointerLockElement===renderer.domElement;hint.classList.toggle('hidden',locked);if(!locked){keys.clear();jump=false;release();}last=null;});
 document.addEventListener('mousemove',e=>{if(!locked)return;yaw-=e.movementX*.0023;pitch=THREE.MathUtils.clamp(pitch-e.movementY*.0023,-1.48,1.48);});
 renderer.domElement.addEventListener('contextmenu',e=>e.preventDefault());renderer.domElement.addEventListener('wheel',e=>{if(!locked)return;e.preventDefault();const towardPlayer=Math.sign(-e.deltaY);holdDistance=THREE.MathUtils.clamp(holdDistance-towardPlayer*.35,1.8,6.5);},{passive:false});
 addEventListener('keydown',e=>{if(e.code==='Escape'&&locked){document.exitPointerLock();return;}if(['KeyW','KeyA','KeyS','KeyD','Space','KeyR'].includes(e.code)&&locked){e.preventDefault();keys.add(e.code);if(e.code==='Space'&&!e.repeat)jump=true;if(e.code==='KeyR'&&!e.repeat)resetCube();}});addEventListener('keyup',e=>keys.delete(e.code));addEventListener('blur',()=>{keys.clear();release();});
 world.addEventListener('preStep',()=>{
  const x=Number(keys.has('KeyD'))-Number(keys.has('KeyA')),z=Number(keys.has('KeyS'))-Number(keys.has('KeyW')),n=Math.hypot(x,z)||1;
  player.velocity.x=(Math.cos(yaw)*x+Math.sin(yaw)*z)/n*4.5;player.velocity.z=(-Math.sin(yaw)*x+Math.cos(yaw)*z)/n*4.5;
  const grounded=world.contacts.some(c=>(c.bi===player||c.bj===player)&&Math.abs(c.ni.y)>.6);if(jump&&grounded)player.velocity.y=5; jump=false;
  if(holding){syncView();camera.getWorldDirection(forward);target.copy(camera.position).addScaledVector(forward,holdDistance);target.x=THREE.MathUtils.clamp(target.x,-9.3,9.3);target.y=THREE.MathUtils.clamp(target.y,.65,5.3);target.z=THREE.MathUtils.clamp(target.z,-9.3,9.3);
   cubeBody.pointToWorldFrame(anchor,grabWorld);cubeBody.getVelocityAtWorldPoint(grabWorld,grabVelocity);
   force.set((target.x-grabWorld.x)*850-grabVelocity.x*130,(target.y-grabWorld.y)*850-grabVelocity.y*130+cubeBody.mass*9.81,(target.z-grabWorld.z)*850-grabVelocity.z*130);
   const magnitude=force.length();if(magnitude>2200)force.scale(2200/magnitude,force);grabWorld.vsub(cubeBody.position,relative);cubeBody.applyForce(force,relative);cubeBody.angularVelocity.scale(.985,cubeBody.angularVelocity);cubeBody.wakeUp();
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
  if(holding){cubeBody.pointToWorldFrame(anchor,grabWorld);weapon.muzzle(gunTip);const a=beamGeometry.attributes.position;a.setXYZ(0,gunTip.x,gunTip.y,gunTip.z);a.setXYZ(1,grabWorld.x,grabWorld.y,grabWorld.z);a.needsUpdate=true;beam.visible=true;point.visible=true;point.position.set(grabWorld.x,grabWorld.y,grabWorld.z);}else{beam.visible=false;point.visible=false;}
  renderer.render(scene,camera);
 }
 function frame(now){requestAnimationFrame(frame);if(document.hidden){last=null;return;}const dt=last===null?1/120:Math.min(.06,(now-last)/1000);last=now;world.step(1/120,dt,8);render(dt);}
 addEventListener('resize',()=>{renderer.setSize(innerWidth,innerHeight);camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();});syncView();render();requestAnimationFrame(frame);
 window.sandboxGame={ready:true,world,scene,camera,renderer,cube,cubeBody,player,weapon,grab,release,throwCube,resetCube,get holdDistance(){return holdDistance;},get holding(){return holding;},get locked(){return locked;}};
}catch(e){console.error(e);document.querySelector('#error').style.display='grid';}
