import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createCubeBreak(scene,world){
 const pieces=[],geometry=new THREE.BoxGeometry(1,1,1);
 const material=new THREE.MeshStandardMaterial({color:0xf0f0f0,roughness:.2,metalness:.3,flatShading:true});
 const dustGeometry=new THREE.BufferGeometry(),dustPositions=new Float32Array(72*3),dustVelocities=[];
 dustGeometry.setAttribute('position',new THREE.BufferAttribute(dustPositions,3));
 const dust=new THREE.Points(dustGeometry,new THREE.PointsMaterial({color:0xe8f0ff,size:.11,transparent:true,opacity:.55,depthWrite:false}));dust.visible=false;scene.add(dust);
 let age=0;
 function clear(){for(const p of pieces){scene.remove(p.mesh);world.removeBody(p.body);}pieces.length=0;dust.visible=false;age=0;}
 return{pieces,clear,dispose(){clear();scene.remove(dust);geometry.dispose();material.dispose();dustGeometry.dispose();dust.material.dispose();},burst(source){clear();
  // Split the original volume into 50 irregular rectangular chunks without overlap.
  const side=source.shapes[0].halfExtents.x*2;
  const chunks=[{center:[0,0,0],size:[side,side,side]}];
  const volume=c=>c.size[0]*c.size[1]*c.size[2];
  while(chunks.length<50){
   let index=0;for(let i=1;i<chunks.length;i++)if(volume(chunks[i])>volume(chunks[index]))index=i;
   const chunk=chunks.splice(index,1)[0],axis=chunk.size.indexOf(Math.max(...chunk.size)),ratio=.28+Math.random()*.44;
   const left={center:[...chunk.center],size:[...chunk.size]},right={center:[...chunk.center],size:[...chunk.size]};
   left.size[axis]*=ratio;right.size[axis]*=1-ratio;left.center[axis]-=right.size[axis]/2;right.center[axis]+=left.size[axis]/2;chunks.push(left,right);
  }
  for(const chunk of chunks){
   const local=new CANNON.Vec3(...chunk.center),offset=source.quaternion.vmult(local),size=new THREE.Vector3(...chunk.size).multiplyScalar(.94);
   const body=new CANNON.Body({mass:source.mass*volume(chunk)/(side**3),shape:new CANNON.Box(new CANNON.Vec3(size.x/2,size.y/2,size.z/2)),linearDamping:.12,angularDamping:.16,allowSleep:true});
   source.position.vadd(offset,body.position);body.quaternion.copy(source.quaternion);body.velocity.copy(source.velocity);body.velocity.x+=offset.x*7+(Math.random()-.5)*1.2;body.velocity.y+=1.5+Math.random()*1.8+offset.y*4;body.velocity.z+=offset.z*7+(Math.random()-.5)*1.2;body.angularVelocity.set((Math.random()-.5)*12,(Math.random()-.5)*12,(Math.random()-.5)*12);body.collisionFilterGroup=8;body.collisionFilterMask=1|4;world.addBody(body);body.previousPosition.copy(body.position);body.interpolatedPosition.copy(body.position);body.previousQuaternion.copy(body.quaternion);body.interpolatedQuaternion.copy(body.quaternion);
   const mesh=new THREE.Mesh(geometry,material);mesh.scale.copy(size);mesh.castShadow=true;mesh.receiveShadow=true;mesh.position.copy(body.position);mesh.quaternion.copy(body.quaternion);scene.add(mesh);pieces.push({body,mesh,baseScale:size});
  }
  dustVelocities.length=0;for(let i=0;i<72;i++){dustPositions.set([source.position.x,source.position.y,source.position.z],i*3);dustVelocities.push(new THREE.Vector3((Math.random()-.5)*3,Math.random()*2,(Math.random()-.5)*3));}dustGeometry.attributes.position.needsUpdate=true;dust.material.opacity=.55;dust.visible=true;
 },tick(dt){if(!pieces.length)return;age+=dt;for(const p of pieces){p.mesh.position.copy(p.body.interpolatedPosition);p.mesh.quaternion.copy(p.body.interpolatedQuaternion);if(age>4){p.mesh.scale.copy(p.baseScale).multiplyScalar(Math.max(0,1-(age-4)/2));}}
  if(dust.visible){for(let i=0;i<72;i++){const v=dustVelocities[i];dustPositions[i*3]+=v.x*dt;dustPositions[i*3+1]+=v.y*dt;dustPositions[i*3+2]+=v.z*dt;v.multiplyScalar(Math.exp(-2*dt));}dustGeometry.attributes.position.needsUpdate=true;dust.material.opacity=.55*Math.max(0,1-age/.8);if(age>=.8)dust.visible=false;}
  if(age>=6)clear();
 }};
}
