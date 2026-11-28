import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createContainer({scene,world}){
 const mesh=new THREE.Group();mesh.name='Cargo container';scene.add(mesh);
 const body=new CANNON.Body({mass:18,fixedRotation:true,linearDamping:.65,angularDamping:.3,allowSleep:true,sleepSpeedLimit:.03,sleepTimeLimit:1.5});body.position.set(4,.425,3);body.linearFactor.set(1,0,1);body.collisionFilterGroup=16;body.isCargoContainer=true;
 const steel=new THREE.MeshStandardMaterial({color:0x465f67,metalness:.52,roughness:.48}),rim=new THREE.MeshStandardMaterial({color:0x879b9d,metalness:.65,roughness:.36}),inside=new THREE.MeshStandardMaterial({color:0x34464b,metalness:.3,roughness:.7}),stripe=new THREE.MeshStandardMaterial({color:0xd6ad53,roughness:.6});
 const outlines=[];
 function part(size,pos,material,physical=false){size=[size[0],size[1]*.5,size[2]];pos=[pos[0],pos[1]*.5,pos[2]];const m=new THREE.Mesh(new THREE.BoxGeometry(...size),material);m.position.set(...pos);m.castShadow=true;m.receiveShadow=true;mesh.add(m);if(physical)body.addShape(new CANNON.Box(new CANNON.Vec3(...size.map(n=>n/2))),new CANNON.Vec3(...pos));const outline=new THREE.Mesh(m.geometry,new THREE.MeshBasicMaterial({color:0x9bffb7,side:THREE.BackSide,depthWrite:false,toneMapped:false}));outline.scale.setScalar(1.035);outline.visible=false;outline.raycast=()=>{};m.add(outline);outlines.push(outline);return m;}
 // Five collision boxes leave the top and the entire storage cavity open.
 part([3.4,.18,2.8],[0,-.76,0],inside,true);
 for(const x of [-1.61,1.61])part([.18,1.52,2.8],[x,.09,0],steel,true);
 for(const z of [-1.31,1.31])part([3.04,1.52,.18],[0,.09,z],steel,true);
 for(const x of [-1.61,1.61])part([.23,.1,2.86],[x,.85,0],rim);
 for(const z of [-1.31,1.31])part([3.44,.1,.23],[0,.85,z],rim);
 for(const z of [-1.415,1.415]){
  for(let i=-3;i<=3;i++)part([.055,1.2,.035],[i*.42,.07,z],rim);
  for(const x of [-1.35,1.35])part([.22,.18,.04],[x,.53,z],stripe);
 }
 body.material=new CANNON.Material('Container slide');world.addContactMaterial(new CANNON.ContactMaterial(body.material,world.defaultMaterial,{friction:0,restitution:.02}));
 body.updateMassProperties();world.addBody(body);body.previousPosition.copy(body.position);body.interpolatedPosition.copy(body.position);mesh.position.copy(body.position);
 const local=new CANNON.Vec3();
 const prop={mesh,body,price:Infinity,broken:false,size:3.4,
  physics(){body.position.y=.425;body.velocity.y=0;body.angularVelocity.setZero();body.quaternion.set(0,0,0,1);body.aabbNeedsUpdate=true;},
  contains(cubeBody){body.pointToLocalFrame(cubeBody.position,local);return Math.abs(local.x)<1.52&&Math.abs(local.z)<1.22&&local.y>-.38&&local.y<.43;},
  blocksSpawn(x,z,size){body.pointToLocalFrame(new CANNON.Vec3(x,body.position.y,z),local);return Math.abs(local.x)<1.9+size/2&&Math.abs(local.z)<1.6+size/2;},
  setHighlight(visible){outlines.forEach(o=>o.visible=visible);},
  render(dt,hovered,held){mesh.position.copy(body.interpolatedPosition);mesh.quaternion.copy(body.interpolatedQuaternion);mesh.updateMatrixWorld(true);this.setHighlight(hovered||held);}
 };
 return prop;
}
