import * as THREE from 'three';
export function createGravityBeam(scene){
 const group=new THREE.Group();group.visible=false;scene.add(group);
 const segments=36,radial=6,axis=new THREE.Vector3(),side=new THREE.Vector3(),up=new THREE.Vector3(),p=new THREE.Vector3(),normal=new THREE.Vector3(0,1,0);
 function strand(radius,color,opacity,twist){
  const positions=new Float32Array((segments+1)*(radial+1)*3),indices=[];
  for(let i=0;i<segments;i++)for(let j=0;j<radial;j++){const a=i*(radial+1)+j,b=a+radial+1;indices.push(a,b,a+1,b,b+1,a+1);}
  const geo=new THREE.BufferGeometry();geo.setAttribute('position',new THREE.BufferAttribute(positions,3).setUsage(THREE.DynamicDrawUsage));geo.setIndex(indices);
  const mat=new THREE.MeshBasicMaterial({color,transparent:true,opacity,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false,side:THREE.DoubleSide});
  const mesh=new THREE.Mesh(geo,mat);mesh.frustumCulled=false;group.add(mesh);return{mesh,geo,radius,twist};
 }
 const strands=[strand(.005,0xd9ffdc,.92,0),strand(.018,0x34ff72,.18,0)];
 const canvas=document.createElement('canvas');canvas.width=canvas.height=64;const c=canvas.getContext('2d'),gradient=c.createRadialGradient(32,32,0,32,32,32);gradient.addColorStop(0,'rgba(225,255,230,1)');gradient.addColorStop(.15,'rgba(100,255,145,.9)');gradient.addColorStop(.4,'rgba(35,255,100,.25)');gradient.addColorStop(1,'rgba(25,255,85,0)');c.fillStyle=gradient;c.fillRect(0,0,64,64);
 const spriteMat=new THREE.SpriteMaterial({map:new THREE.CanvasTexture(canvas),transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false});
 const contactMat=spriteMat.clone();contactMat.depthTest=false;
 const contact=new THREE.Sprite(contactMat);contact.renderOrder=9999;contact.scale.setScalar(.34);group.add(contact);
 const startGlow=new THREE.Sprite(spriteMat);startGlow.scale.setScalar(.12);group.add(startGlow);
 const pulses=[];for(let i=0;i<7;i++){const s=new THREE.Sprite(spriteMat);s.scale.setScalar(.038);group.add(s);pulses.push(s);}
 const light=new THREE.PointLight(0x45ff83,0,3,2);group.add(light);
 let time=0;
 const xAxis=new THREE.Vector3(1,0,0);
 // The physical prop provides the lag: the beam itself stays straight and attached.
 function curvePoint(from,to,t,length,out){return out.copy(from).lerp(to,t);}
 return {group,hide(){group.visible=false;light.intensity=0;},update(from,to,dt){
  dt=Math.max(.001,Math.min(dt,.05));time+=dt;group.visible=true;axis.subVectors(to,from);const length=axis.length();axis.normalize();
  side.crossVectors(axis,Math.abs(axis.y)>.94?xAxis:normal).normalize();up.crossVectors(side,axis).normalize();
  for(const s of strands){const a=s.geo.attributes.position;for(let i=0;i<=segments;i++){const t=i/segments,envelope=Math.sin(Math.PI*t),phase=t*length*7-time*6;
    curvePoint(from,to,t,length,p);
    for(let j=0;j<=radial;j++){const angle=j/radial*Math.PI*2,index=i*(radial+1)+j;a.setXYZ(index,p.x+(side.x*Math.cos(angle)+up.x*Math.sin(angle))*s.radius,p.y+(side.y*Math.cos(angle)+up.y*Math.sin(angle))*s.radius,p.z+(side.z*Math.cos(angle)+up.z*Math.sin(angle))*s.radius);}
   }a.needsUpdate=true;}
  contact.position.copy(to);contact.scale.setScalar(.22+Math.sin(time*12)*.012);startGlow.position.copy(from);light.position.copy(to);light.intensity=1.2;
  for(let i=0;i<pulses.length;i++){const t=(time*1.3+i/pulses.length)%1;curvePoint(from,to,t,length,pulses[i].position);}
 }};
}
