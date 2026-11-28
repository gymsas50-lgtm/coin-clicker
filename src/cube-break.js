import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createCubeBreak(scene,world){
 const pieces=[],geometry=new THREE.BoxGeometry(.134,.134,.134);
 const material=new THREE.MeshStandardMaterial({color:0xd6d6d6,roughness:.2,metalness:.3,flatShading:true});
 const dustGeometry=new THREE.BufferGeometry(),dustPositions=new Float32Array(72*3),dustVelocities=[];
 dustGeometry.setAttribute('position',new THREE.BufferAttribute(dustPositions,3));
 const dust=new THREE.Points(dustGeometry,new THREE.PointsMaterial({color:0xe8f0ff,size:.11,transparent:true,opacity:.55,depthWrite:false}));dust.visible=false;scene.add(dust);
 let age=0;
 function clear(){for(const p of pieces){scene.remove(p.mesh);world.removeBody(p.body);}pieces.length=0;dust.visible=false;age=0;}
 return{pieces,clear,burst(source){clear();
  for(let x=-2;x<=2;x++)for(let y=-2;y<=2;y++)for(let z=-2;z<=2;z++){
   const local=new CANNON.Vec3(x*.14,y*.14,z*.14),offset=source.quaternion.vmult(local);
   const body=new CANNON.Body({mass:source.mass/125,shape:new CANNON.Box(new CANNON.Vec3(.067,.067,.067)),linearDamping:.12,angularDamping:.16,allowSleep:true});
   source.position.vadd(offset,body.position);body.quaternion.copy(source.quaternion);body.velocity.copy(source.velocity);body.velocity.x+=offset.x*7+(Math.random()-.5)*1.2;body.velocity.y+=1.5+Math.random()*1.8+offset.y*4;body.velocity.z+=offset.z*7+(Math.random()-.5)*1.2;body.angularVelocity.set((Math.random()-.5)*12,(Math.random()-.5)*12,(Math.random()-.5)*12);body.collisionFilterGroup=8;body.collisionFilterMask=1|4;world.addBody(body);body.previousPosition.copy(body.position);body.interpolatedPosition.copy(body.position);body.previousQuaternion.copy(body.quaternion);body.interpolatedQuaternion.copy(body.quaternion);
   const mesh=new THREE.Mesh(geometry,material);mesh.castShadow=true;mesh.receiveShadow=true;mesh.position.copy(body.position);mesh.quaternion.copy(body.quaternion);scene.add(mesh);pieces.push({body,mesh});
  }
  dustVelocities.length=0;for(let i=0;i<72;i++){dustPositions.set([source.position.x,source.position.y,source.position.z],i*3);dustVelocities.push(new THREE.Vector3((Math.random()-.5)*3,Math.random()*2,(Math.random()-.5)*3));}dustGeometry.attributes.position.needsUpdate=true;dust.material.opacity=.55;dust.visible=true;
 },tick(dt){if(!pieces.length)return;age+=dt;for(const p of pieces){p.mesh.position.copy(p.body.interpolatedPosition);p.mesh.quaternion.copy(p.body.interpolatedQuaternion);if(age>4){p.mesh.scale.setScalar(Math.max(0,1-(age-4)/2));}}
  if(dust.visible){for(let i=0;i<72;i++){const v=dustVelocities[i];dustPositions[i*3]+=v.x*dt;dustPositions[i*3+1]+=v.y*dt;dustPositions[i*3+2]+=v.z*dt;v.multiplyScalar(Math.exp(-2*dt));}dustGeometry.attributes.position.needsUpdate=true;dust.material.opacity=.55*Math.max(0,1-age/.8);if(age>=.8)dust.visible=false;}
  if(age>=6)clear();
 }};
}
