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
 const strands=[strand(.005,0xfff2cb,.95,0),strand(.018,0xffa23a,.12,0),strand(.003,0x65e8ff,.8,1),strand(.003,0xffba51,.85,-1)];
 const canvas=document.createElement('canvas');canvas.width=canvas.height=64;const c=canvas.getContext('2d'),gradient=c.createRadialGradient(32,32,0,32,32,32);gradient.addColorStop(0,'rgba(255,248,220,1)');gradient.addColorStop(.15,'rgba(255,198,93,.9)');gradient.addColorStop(.4,'rgba(255,155,45,.25)');gradient.addColorStop(1,'rgba(255,150,40,0)');c.fillStyle=gradient;c.fillRect(0,0,64,64);
 const spriteMat=new THREE.SpriteMaterial({map:new THREE.CanvasTexture(canvas),transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false});
 const contact=new THREE.Sprite(spriteMat);contact.scale.setScalar(.34);group.add(contact);
 const startGlow=new THREE.Sprite(spriteMat);startGlow.scale.setScalar(.12);group.add(startGlow);
 const pulses=[];for(let i=0;i<7;i++){const s=new THREE.Sprite(spriteMat);s.scale.setScalar(.038);group.add(s);pulses.push(s);}
 const light=new THREE.PointLight(0xffbb66,0,3,2);group.add(light);
 let time=0,initialized=false;
 const controlA=new THREE.Vector3(),controlB=new THREE.Vector3(),previousFrom=new THREE.Vector3(),lag=new THREE.Vector3(),motion=new THREE.Vector3(),muzzleDirection=new THREE.Vector3(),surfaceNormal=new THREE.Vector3(),tangent=new THREE.Vector3(),localSide=new THREE.Vector3(),localUp=new THREE.Vector3(),deltaAB=new THREE.Vector3(),deltaBC=new THREE.Vector3(),xAxis=new THREE.Vector3(1,0,0);
 function curvePoint(from,to,t,length,out){
  const u=1-t;out.copy(from).multiplyScalar(u*u*u).addScaledVector(controlA,3*u*u*t).addScaledVector(controlB,3*u*t*t).addScaledVector(to,t*t*t);return out;
 }
 return {group,hide(){group.visible=false;light.intensity=0;initialized=false;lag.set(0,0,0);},update(from,to,dt,options={}){
  dt=Math.max(.001,Math.min(dt,.05));time+=dt;group.visible=true;axis.subVectors(to,from);const length=axis.length();axis.normalize();
  muzzleDirection.copy(options.direction||axis).normalize();
  // Both endpoint tangents face along the beam, never through the prop's back face.
  surfaceNormal.copy(options.normal||axis).normalize();if(surfaceNormal.dot(axis)>0)surfaceNormal.negate();
  if(initialized){motion.subVectors(from,previousFrom).multiplyScalar(-.022/dt).clampLength(0,.14);lag.lerp(motion,1-Math.exp(-9*dt));}else{initialized=true;lag.set(0,0,0);}
  previousFrom.copy(from);
  const handle=Math.min(.75,length*.23);
  controlA.copy(from).addScaledVector(muzzleDirection,handle).addScaledVector(lag,.55);
  controlB.copy(to).addScaledVector(surfaceNormal,Math.min(.55,length*.18)).add(lag);
  side.crossVectors(axis,Math.abs(axis.y)>.94?xAxis:normal).normalize();up.crossVectors(side,axis).normalize();
  deltaAB.subVectors(controlB,controlA);deltaBC.subVectors(to,controlB);
  for(const s of strands){const a=s.geo.attributes.position;for(let i=0;i<=segments;i++){const t=i/segments,envelope=Math.sin(Math.PI*t),phase=t*length*7-time*6;
    curvePoint(from,to,t,length,p);
    const u=1-t;tangent.copy(controlA).sub(from).multiplyScalar(3*u*u).addScaledVector(deltaAB,6*u*t).addScaledVector(deltaBC,3*t*t).normalize();
    localSide.crossVectors(tangent,Math.abs(tangent.y)>.94?xAxis:normal).normalize();localUp.crossVectors(localSide,tangent).normalize();
    if(s.twist){p.addScaledVector(localSide,Math.cos(phase*s.twist)*.010*envelope);p.addScaledVector(localUp,Math.sin(phase*s.twist)*.010*envelope);}
    for(let j=0;j<=radial;j++){const angle=j/radial*Math.PI*2,index=i*(radial+1)+j;a.setXYZ(index,p.x+(localSide.x*Math.cos(angle)+localUp.x*Math.sin(angle))*s.radius,p.y+(localSide.y*Math.cos(angle)+localUp.y*Math.sin(angle))*s.radius,p.z+(localSide.z*Math.cos(angle)+localUp.z*Math.sin(angle))*s.radius);}
   }a.needsUpdate=true;}
  contact.position.copy(to);contact.scale.setScalar(.22+Math.sin(time*12)*.012);startGlow.position.copy(from);light.position.copy(to);light.intensity=1.2;
  for(let i=0;i<pulses.length;i++){const t=(time*1.3+i/pulses.length)%1;curvePoint(from,to,t,length,pulses[i].position);}
 }};
}
