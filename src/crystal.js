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
 const materials=[0x299dba,0x52d9d9,0x477dd0,0x84ece1,0x347d9c,0x58baca].map(color=>new THREE.MeshStandardMaterial({color,metalness:.3,roughness:.18,flatShading:true,emissive:0x087e8e,emissiveIntensity:.18}));
 geometry.clearGroups();for(let i=0;i<geometry.attributes.position.count;i+=3)geometry.addGroup(i,3,(i/3*7+Math.floor(i/9))%materials.length);
 const mesh=new THREE.Mesh(geometry,materials);mesh.name='Azure crystal';mesh.castShadow=true;mesh.receiveShadow=true;
 const facets=new THREE.LineSegments(new THREE.EdgesGeometry(geometry,12),new THREE.LineBasicMaterial({color:0xa4f8ff,transparent:true,opacity:.23}));facets.name='Crystal facet highlights';mesh.add(facets);
 return{mesh,shape:convexShape(geometry)};
}
