import * as THREE from 'three';
import * as CANNON from 'cannon-es';
import {createDefaultCube} from './crystal.js';
import {createCubeBreak} from './cube-break.js';
export function createCubeProps({scene,world,onFreeze}){
 const specs=[{name:'Default',price:5,size:.7,x:-2},{name:'Small cube',price:8,size:.42,x:0},{name:'Big cube',price:12,size:1,x:2}];
 return specs.map(spec=>{
  const model=createDefaultCube(spec.size),mesh=model.mesh;mesh.name=spec.name;scene.add(mesh);
  const body=new CANNON.Body({mass:3*(spec.size/.7)**3,shape:model.shape,linearDamping:.035,angularDamping:.025,allowSleep:true,sleepSpeedLimit:.025,sleepTimeLimit:1.5});body.position.set(spec.x,spec.size/2+.02,0);body.previousPosition.copy(body.position);body.interpolatedPosition.copy(body.position);body.collisionFilterGroup=2;world.addBody(body);mesh.position.copy(body.position);
  const canvas=document.createElement('canvas');canvas.width=256;canvas.height=192;const ctx=canvas.getContext('2d'),texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;
  const tag=new THREE.Sprite(new THREE.SpriteMaterial({map:texture,depthWrite:false,toneMapped:false}));tag.scale.set(.68,.51,1);scene.add(tag);
  const outline=new THREE.Mesh(mesh.geometry,new THREE.MeshBasicMaterial({color:0x9bffb7,side:THREE.BackSide,depthWrite:false,toneMapped:false}));outline.scale.setScalar(1.06);outline.visible=false;outline.raycast=()=>{};mesh.add(outline);
  const effect=createCubeBreak(scene,world),frozenPosition=new CANNON.Vec3(),frozenQuaternion=new CANNON.Quaternion();
  const prop={...spec,mesh,body,tag,outline,effect,price:spec.price,broken:false,breakAt:Infinity,lastDamage:-Infinity};
  function label(){ctx.clearRect(0,0,256,192);ctx.textAlign='center';ctx.textBaseline='middle';ctx.lineJoin='round';ctx.lineWidth=3;ctx.strokeStyle='rgba(0,0,0,.8)';ctx.font='bold 60px Arial';ctx.strokeText(prop.price+'$',128,66);ctx.fillStyle=prop.price===spec.price?'#ffffff':prop.price>spec.price*.3?'#ffd578':'#ff7979';ctx.fillText(prop.price+'$',128,66);ctx.font='36px Arial';ctx.lineWidth=2;ctx.strokeText(spec.name,128,132);ctx.fillStyle='#e4e7eb';ctx.fillText(spec.name,128,132);texture.needsUpdate=true;tag.name=spec.name+' '+prop.price+'$';}
  label();
  body.addEventListener('collide',event=>{const speed=Math.abs(event.contact.getImpactVelocityAlongNormal());if(speed<4||prop.price===0||world.time-prop.lastDamage<.25)return;prop.price=Math.max(0,prop.price-Math.max(1,Math.round((speed*speed-16)/14)));prop.lastDamage=world.time;
   if(prop.price===0){prop.breakAt=world.time+.2;onFreeze(body);frozenPosition.copy(body.position);frozenQuaternion.copy(body.quaternion);body.type=CANNON.Body.STATIC;body.velocity.setZero();body.angularVelocity.setZero();body.force.setZero();body.torque.setZero();body.updateSolveMassProperties();}label();
  });
  prop.physics=()=>{if(prop.broken)return;if(prop.price===0){body.position.copy(frozenPosition);body.quaternion.copy(frozenQuaternion);body.velocity.setZero();body.angularVelocity.setZero();body.previousPosition.copy(frozenPosition);body.interpolatedPosition.copy(frozenPosition);body.previousQuaternion.copy(frozenQuaternion);body.interpolatedQuaternion.copy(frozenQuaternion);body.aabbNeedsUpdate=true;}
   if(world.time>=prop.breakAt){prop.broken=true;effect.burst(body);world.removeBody(body);mesh.visible=false;tag.visible=false;outline.visible=false;}
  };
  const point=new THREE.Vector3();
  prop.render=(dt,hovered,held)=>{effect.tick(dt);if(prop.broken)return;mesh.position.copy(body.interpolatedPosition);mesh.quaternion.copy(body.interpolatedQuaternion);mesh.updateMatrixWorld(true);outline.visible=prop.price>0&&(hovered||held);let top=-Infinity;for(const v of model.vertices){point.set(v.x,v.y,v.z).applyQuaternion(mesh.quaternion);top=Math.max(top,point.y);}tag.position.set(mesh.position.x,mesh.position.y+top+.28,mesh.position.z);};
  return prop;
 });
}
