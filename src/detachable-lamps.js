import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createDetachableLamps({scene,world}) {
 const lamps=[],bursts=[];
 const metal=new THREE.MeshStandardMaterial({color:0x333c44,metalness:.6,roughness:.4});
 function burst(position){
  const count=36,data=new Float32Array(count*6),velocity=[];
  for(let i=0;i<count;i++)velocity.push(new THREE.Vector3((Math.random()-.5)*4,-.4-Math.random()*2.8,(Math.random()-.5)*4));
  const geo=new THREE.BufferGeometry();geo.setAttribute('position',new THREE.BufferAttribute(data,3).setUsage(THREE.DynamicDrawUsage));
  const lines=new THREE.LineSegments(geo,new THREE.LineBasicMaterial({color:0xffcf72,transparent:true,opacity:1,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false}));lines.frustumCulled=false;scene.add(lines);
  const flash=new THREE.PointLight(0xffc272,5,5,2);flash.position.copy(position);scene.add(flash);
  bursts.push({lines,geo,flash,position:position.clone(),velocity,time:0});
 }
 for(const z of [-3,3]){
  const mesh=new THREE.Group();mesh.position.set(0,5.88,z);mesh.name='Detachable ceiling lamp';scene.add(mesh);
  const housing=new THREE.Mesh(new THREE.BoxGeometry(2.65,.10,1.35),metal);housing.castShadow=true;housing.receiveShadow=true;mesh.add(housing);
  const screenMaterial=new THREE.MeshBasicMaterial({color:0xe8f2ff,toneMapped:false});const screen=new THREE.Mesh(new THREE.BoxGeometry(2.43,.025,1.13),screenMaterial);screen.position.y=-.063;mesh.add(screen);
  const socket=new THREE.Mesh(new THREE.BoxGeometry(.42,.035,.22),metal);socket.position.set(0,5.982,z);scene.add(socket);
  const wire=new THREE.Mesh(new THREE.CylinderGeometry(.011,.011,.13,6),new THREE.MeshStandardMaterial({color:0x171b1e}));wire.position.set(0,5.91,z);wire.visible=false;scene.add(wire);
  const fill=new THREE.PointLight(0xd9e8ff,24,17,2);fill.position.set(0,5.62,z);scene.add(fill);
  const spot=new THREE.SpotLight(0xe7efff,100,23,1.16,.65,2);spot.position.set(0,5.64,z);spot.target.position.set(0,0,z);spot.castShadow=true;spot.shadow.mapSize.set(768,768);spot.shadow.camera.near=.3;spot.shadow.camera.far=25;spot.shadow.bias=-.0002;spot.shadow.normalBias=.015;spot.shadow.radius=3;scene.add(spot,spot.target);
  const body=new CANNON.Body({mass:0,shape:new CANNON.Box(new CANNON.Vec3(1.325,.075,.675)),linearDamping:.04,angularDamping:.13,allowSleep:true});body.position.set(0,5.88,z);body.previousPosition.copy(body.position);body.interpolatedPosition.copy(body.position);body.collisionFilterGroup=2;world.addBody(body);
  const lamp={mesh,body,fill,spot,screen,detached:false,detach(){if(this.detached)return;this.detached=true;fill.intensity=0;spot.intensity=0;spot.visible=false;screenMaterial.color.setHex(0x33383d);screenMaterial.toneMapped=true;screenMaterial.needsUpdate=true;wire.visible=true;
    body.mass=8;body.type=CANNON.Body.DYNAMIC;body.updateMassProperties();body.aabbNeedsUpdate=true;body.wakeUp();world.broadphase.dirty=true;burst(new THREE.Vector3(0,5.96,z));
   },reset(){this.detached=false;body.mass=0;body.type=CANNON.Body.STATIC;body.position.set(0,5.88,z);body.quaternion.set(0,0,0,1);body.previousPosition.copy(body.position);body.interpolatedPosition.copy(body.position);body.previousQuaternion.copy(body.quaternion);body.interpolatedQuaternion.copy(body.quaternion);body.velocity.setZero();body.angularVelocity.setZero();body.force.setZero();body.torque.setZero();body.updateMassProperties();body.aabbNeedsUpdate=true;fill.intensity=24;spot.intensity=100;spot.visible=true;screenMaterial.color.setHex(0xe8f2ff);screenMaterial.toneMapped=false;screenMaterial.needsUpdate=true;wire.visible=false;world.broadphase.dirty=true;}};
  lamps.push(lamp);
 }
 function removeBurst(e){scene.remove(e.lines,e.flash);e.geo.dispose();e.lines.material.dispose();}
 return {lamps,get sparks(){return bursts.length;},reset(){for(const l of lamps)l.reset();for(const e of bursts)removeBurst(e);bursts.length=0;},tick(dt){
  for(const l of lamps){const p=l.body.interpolatedPosition,q=l.body.interpolatedQuaternion;l.mesh.position.set(p.x,p.y,p.z);l.mesh.quaternion.set(q.x,q.y,q.z,q.w);}
  for(let n=bursts.length-1;n>=0;n--){const e=bursts[n];e.time+=dt;const t=e.time;if(t>1.1){removeBurst(e);bursts.splice(n,1);continue;}e.flash.intensity=Math.max(0,1-t/.15)*5;e.lines.material.opacity=Math.max(0,1-t/1.1);const a=e.geo.attributes.position;
    for(let i=0;i<e.velocity.length;i++){const v=e.velocity[i],x=e.position.x+v.x*t,y=e.position.y+v.y*t-4.905*t*t,z=e.position.z+v.z*t;a.setXYZ(i*2,x,Math.max(.02,y),z);a.setXYZ(i*2+1,x-v.x*.022,Math.max(.02,y-(v.y-9.81*t)*.022),z-v.z*.022);}a.needsUpdate=true;
  }
 }};
}
