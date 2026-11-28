import * as THREE from 'three';
import * as CANNON from 'cannon-es';
try {
 const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});renderer.setPixelRatio(Math.min(devicePixelRatio||1,1.5));renderer.setSize(innerWidth,innerHeight);renderer.shadowMap.enabled=false;renderer.setClearColor(0x858585);document.body.prepend(renderer.domElement);
 const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(75,innerWidth/innerHeight,.06,80);camera.rotation.order='YXZ';scene.add(camera);
 const world=new CANNON.World({gravity:new CANNON.Vec3(0,-9.81,0)});world.broadphase=new CANNON.SAPBroadphase(world);world.solver.iterations=12;world.defaultContactMaterial.friction=.55;world.defaultContactMaterial.restitution=.08;
 const material=color=>new THREE.MeshBasicMaterial({color});
 function box(parent,size,pos,color){const m=new THREE.Mesh(new THREE.BoxGeometry(...size),typeof color==='number'?material(color):color);m.position.set(...pos);parent.add(m);return m;}
 function staticBox(size,pos,color){const m=box(scene,size,pos,color);const b=new CANNON.Body({mass:0,shape:new CANNON.Box(new CANNON.Vec3(...size.map(v=>v/2)))});b.position.set(...pos);world.addBody(b);return m;}
 staticBox([20,.3,20],[0,-.15,0],0x777777);staticBox([20,.3,20],[0,6.15,0],0x999999);
 staticBox([20,6,.3],[0,3,-10.15],0x8b8b8b);staticBox([20,6,.3],[0,3,10.15],0x858585);staticBox([.3,6,20],[-10.15,3,0],0x818181);staticBox([.3,6,20],[10.15,3,0],0x919191);
 // Unlit face colours keep depth legible without lights, shadows or post-processing.
 const cubeMaterials=[0xaaaaaa,0x969696,0xc2c2c2,0x858585,0xaeaeae,0x9d9d9d].map(material);
 const cube=box(scene,[1.2,1.2,1.2],[0,.62,0],cubeMaterials);
 const edges=new THREE.LineSegments(new THREE.EdgesGeometry(cube.geometry),new THREE.LineBasicMaterial({color:0x535353}));cube.add(edges);
 const cubeBody=new CANNON.Body({mass:12,shape:new CANNON.Box(new CANNON.Vec3(.6,.6,.6)),linearDamping:.08,angularDamping:.18,allowSleep:true,sleepSpeedLimit:.07});cubeBody.position.set(0,.62,0);cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);world.addBody(cubeBody);
 const player=new CANNON.Body({mass:75,shape:new CANNON.Box(new CANNON.Vec3(.3,.85,.3)),fixedRotation:true,linearDamping:.05,allowSleep:false});player.position.set(0,.88,6);player.updateMassProperties();world.addBody(player);
 const gun=new THREE.Group();gun.position.set(.39,-.30,-.66);gun.rotation.set(.03,-.10,0);camera.add(gun);
 const dark=material(0x34383a),steel=material(0x777c7d),orange=material(0xb9792d),glow=material(0xffb44b);
 box(gun,[.20,.17,.43],[0,0,.04],dark);box(gun,[.23,.12,.22],[0,.07,.05],steel);box(gun,[.16,.16,.18],[0,.015,-.22],orange);
 const grip=box(gun,[.09,.23,.12],[0,-.16,.15],dark);grip.rotation.x=-.25;
 box(gun,[.08,.085,.23],[0,-.25,.35],0x535759);box(gun,[.11,.10,.11],[0,-.19,.23],0x8e775f);
 function rod(a,b,r,mat){const start=new THREE.Vector3(...a),end=new THREE.Vector3(...b),d=end.clone().sub(start);const m=new THREE.Mesh(new THREE.CylinderGeometry(r,r,d.length(),8),mat);m.position.copy(start).add(end).multiplyScalar(.5);m.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),d.normalize());gun.add(m);return m;}
 for(let i=0;i<3;i++){const a=i*Math.PI*2/3+Math.PI/2,x=Math.cos(a),y=Math.sin(a);rod([x*.10,y*.10,-.23],[x*.20,y*.20,-.40],.023,steel);rod([x*.20,y*.20,-.40],[x*.13,y*.13,-.57],.022,orange);box(gun,[.045,.045,.07],[x*.13,y*.13,-.58],glow);}
 for(let i=0;i<3;i++)box(gun,[.025,.035,.09],[-.065+i*.065,.12,-.02],glow);
 const beamGeometry=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(),new THREE.Vector3()]);const beam=new THREE.Line(beamGeometry,new THREE.LineBasicMaterial({color:0xffae39,transparent:true,opacity:.85,depthTest:true}));beam.frustumCulled=false;scene.add(beam);beam.visible=false;
 const point=new THREE.Mesh(new THREE.SphereGeometry(.035,8,6),glow);scene.add(point);point.visible=false;
 const hint=document.querySelector('#hint'),crosshair=document.querySelector('#crosshair'),keys=new Set();let yaw=0,pitch=-.12,locked=false,holding=false,holdDistance=4,last=null,jump=false;
 const ray=new THREE.Raycaster(),anchor=new CANNON.Vec3(),target=new THREE.Vector3(),forward=new THREE.Vector3(),gunTip=new THREE.Vector3(),grabWorld=new CANNON.Vec3(),grabVelocity=new CANNON.Vec3(),force=new CANNON.Vec3(),relative=new CANNON.Vec3();
 function syncView(){camera.position.set(player.position.x,player.position.y+.70,player.position.z);camera.rotation.set(pitch,yaw,0);camera.updateMatrixWorld(true);}
 function release(){holding=false;beam.visible=false;point.visible=false;crosshair.classList.remove('holding');}
 function grab(){if(holding){release();return;}syncView();cube.updateMatrixWorld(true);ray.setFromCamera(new THREE.Vector2(0,0),camera);const hits=ray.intersectObject(cube,false);if(!hits.length||hits[0].distance>7)return;const p=hits[0].point;cubeBody.pointToLocalFrame(new CANNON.Vec3(p.x,p.y,p.z),anchor);holdDistance=THREE.MathUtils.clamp(hits[0].distance,1.8,6.5);holding=true;cubeBody.wakeUp();crosshair.classList.add('holding');}
 function throwCube(){if(!holding)return;camera.getWorldDirection(forward);release();cubeBody.applyImpulse(new CANNON.Vec3(forward.x*125,forward.y*125,forward.z*125));}
 function resetCube(){release();cubeBody.position.set(0,.62,0);cubeBody.quaternion.set(0,0,0,1);cubeBody.velocity.setZero();cubeBody.angularVelocity.setZero();cubeBody.force.setZero();cubeBody.torque.setZero();cubeBody.previousPosition.copy(cubeBody.position);cubeBody.interpolatedPosition.copy(cubeBody.position);cubeBody.previousQuaternion.copy(cubeBody.quaternion);cubeBody.interpolatedQuaternion.copy(cubeBody.quaternion);cubeBody.aabbNeedsUpdate=true;cubeBody.wakeUp();}
 async function enter(){try{await renderer.domElement.requestPointerLock();}catch{hint.textContent='Нажми ещё раз для захвата мыши';}}
 hint.addEventListener('click',enter);renderer.domElement.addEventListener('pointerdown',e=>{if(!locked){enter();return;}if(e.button===0)grab();if(e.button===2)throwCube();});
 document.addEventListener('pointerlockchange',()=>{locked=document.pointerLockElement===renderer.domElement;hint.classList.toggle('hidden',locked);if(!locked){keys.clear();jump=false;release();}last=null;});
 document.addEventListener('mousemove',e=>{if(!locked)return;yaw-=e.movementX*.0023;pitch=THREE.MathUtils.clamp(pitch-e.movementY*.0023,-1.48,1.48);});
 renderer.domElement.addEventListener('contextmenu',e=>e.preventDefault());renderer.domElement.addEventListener('wheel',e=>{if(!locked)return;e.preventDefault();holdDistance=THREE.MathUtils.clamp(holdDistance+e.deltaY*.004,1.8,6.5);},{passive:false});
 addEventListener('keydown',e=>{if(['KeyW','KeyA','KeyS','KeyD','Space','KeyE','KeyR'].includes(e.code)&&locked){e.preventDefault();keys.add(e.code);if(e.code==='Space'&&!e.repeat)jump=true;if(e.code==='KeyE'&&!e.repeat)grab();if(e.code==='KeyR'&&!e.repeat)resetCube();}});addEventListener('keyup',e=>keys.delete(e.code));addEventListener('blur',()=>{keys.clear();release();});
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
 function render(){syncView();const p=cubeBody.interpolatedPosition,q=cubeBody.interpolatedQuaternion;cube.position.set(p.x,p.y,p.z);cube.quaternion.set(q.x,q.y,q.z,q.w);
  if(holding){cubeBody.pointToWorldFrame(anchor,grabWorld);gunTip.set(0,0,-.52);gun.localToWorld(gunTip);const a=beamGeometry.attributes.position;a.setXYZ(0,gunTip.x,gunTip.y,gunTip.z);a.setXYZ(1,grabWorld.x,grabWorld.y,grabWorld.z);a.needsUpdate=true;beam.visible=true;point.visible=true;point.position.set(grabWorld.x,grabWorld.y,grabWorld.z);}else{beam.visible=false;point.visible=false;}
  renderer.render(scene,camera);
 }
 function frame(now){requestAnimationFrame(frame);if(document.hidden){last=null;return;}const dt=last===null?1/120:Math.min(.06,(now-last)/1000);last=now;world.step(1/120,dt,8);render();}
 addEventListener('resize',()=>{renderer.setSize(innerWidth,innerHeight);camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();});syncView();render();requestAnimationFrame(frame);
 window.sandboxGame={ready:true,world,scene,camera,renderer,cube,cubeBody,player,grab,release,throwCube,resetCube,get holding(){return holding;},get locked(){return locked;}};
}catch(e){console.error(e);document.querySelector('#error').style.display='grid';}
