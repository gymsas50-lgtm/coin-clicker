import * as THREE from 'three';
import * as CANNON from 'cannon-es';
import {ConvexGeometry} from 'three/addons/geometries/ConvexGeometry.js';
export function convexShape(geometry){
 const vertices=[],faces=[],lookup=new Map(),positions=geometry.getAttribute('position');
 for(let i=0;i<positions.count;i+=3){const face=[];for(let j=0;j<3;j++){const v=new CANNON.Vec3(positions.getX(i+j),positions.getY(i+j),positions.getZ(i+j)),key=[v.x,v.y,v.z].map(n=>n.toFixed(6)).join(',');if(!lookup.has(key)){lookup.set(key,vertices.length);vertices.push(v);}face.push(lookup.get(key));}faces.push(face);}
 return new CANNON.ConvexPolyhedron({vertices,faces});
}
export function createCrystal(){
 const points=[new THREE.Vector3(0,.56,0),new THREE.Vector3(0,-.48,0)];
 for(const y of [-.22,.22])for(let i=0;i<6;i++){const angle=i*Math.PI/3;points.push(new THREE.Vector3(Math.cos(angle)*.32,y,Math.sin(angle)*.32));}
 const geometry=new ConvexGeometry(points);
 const materials=[0xc9cdd1,0xe1e4e7,0xb9bfc6,0xf0f1f3,0xc3c9cf,0xd4d9de].map(color=>new THREE.MeshStandardMaterial({color,metalness:.3,roughness:.18,flatShading:true,emissive:0xdde4ed,emissiveIntensity:.3}));
 geometry.clearGroups();for(let i=0;i<geometry.attributes.position.count;i+=3)geometry.addGroup(i,3,(i/3*7+Math.floor(i/9))%materials.length);
 const mesh=new THREE.Mesh(geometry,materials);mesh.name='Default crystal';mesh.castShadow=true;mesh.receiveShadow=true;
 const facets=new THREE.LineSegments(new THREE.EdgesGeometry(geometry,12),new THREE.LineBasicMaterial({color:0xf1f5fa,transparent:true,opacity:.23}));facets.name='Crystal facet highlights';mesh.add(facets);
 const haloCanvas=document.createElement('canvas');haloCanvas.width=haloCanvas.height=128;const ctx=haloCanvas.getContext('2d');const gradient=ctx.createRadialGradient(64,64,8,64,64,64);gradient.addColorStop(0,'rgba(230,240,255,0.28)');gradient.addColorStop(.4,'rgba(225,237,255,0.16)');gradient.addColorStop(1,'rgba(225,237,255,0)');ctx.fillStyle=gradient;ctx.fillRect(0,0,128,128);
 const haloTexture=new THREE.CanvasTexture(haloCanvas);haloTexture.colorSpace=THREE.SRGBColorSpace;
 const halo=new THREE.Sprite(new THREE.SpriteMaterial({map:haloTexture,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false}));halo.scale.set(1.65,1.65,1);halo.name='Crystal glow';halo.raycast=()=>{};mesh.add(halo);
 const light=new THREE.PointLight(0xe8f0ff,2.2,2.8,2);light.name='Crystal local light';mesh.add(light);
 return{mesh,shape:convexShape(geometry)};
}
