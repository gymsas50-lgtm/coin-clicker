import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function convexShape(geometry){
 const vertices=[],faces=[],lookup=new Map(),positions=geometry.getAttribute('position');
 for(let i=0;i<positions.count;i+=3){const face=[];for(let j=0;j<3;j++){const v=new CANNON.Vec3(positions.getX(i+j),positions.getY(i+j),positions.getZ(i+j)),key=[v.x,v.y,v.z].map(n=>n.toFixed(6)).join(',');if(!lookup.has(key)){lookup.set(key,vertices.length);vertices.push(v);}face.push(lookup.get(key));}faces.push(face);}
 return new CANNON.ConvexPolyhedron({vertices,faces});
}
export function createDefaultCube(){
 const geometry=new THREE.BoxGeometry(.7,.7,.7);
 const material=new THREE.MeshStandardMaterial({color:0xd6d6d6,metalness:.08,roughness:.55,emissive:0xffffff,emissiveIntensity:.22});
 const mesh=new THREE.Mesh(geometry,material);mesh.name='Default cube';mesh.castShadow=true;mesh.receiveShadow=true;
 const light=new THREE.PointLight(0xffffff,1.5,2.3,2);light.name='Faint white light';mesh.add(light);
 const canvas=document.createElement('canvas');canvas.width=canvas.height=128;const ctx=canvas.getContext('2d'),gradient=ctx.createRadialGradient(64,64,12,64,64,64);gradient.addColorStop(0,'rgba(255,255,255,.4)');gradient.addColorStop(.45,'rgba(255,255,255,.18)');gradient.addColorStop(1,'rgba(255,255,255,0)');ctx.fillStyle=gradient;ctx.fillRect(0,0,128,128);
 const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;
 const glow=new THREE.Sprite(new THREE.SpriteMaterial({map:texture,blending:THREE.AdditiveBlending,depthTest:false,depthWrite:false,toneMapped:false}));glow.name='Soft white glow';glow.renderOrder=1000;glow.scale.set(1.2,1.2,1);glow.material.opacity=.75;glow.raycast=()=>{};mesh.add(glow);
 const vertices=[];for(const x of [-.35,.35])for(const y of [-.35,.35])for(const z of [-.35,.35])vertices.push(new CANNON.Vec3(x,y,z));
 return{mesh,vertices,shape:new CANNON.Box(new CANNON.Vec3(.35,.35,.35))};
}
