import * as THREE from 'three';
export function createLootFlight({scene,model,camera,keyTemplate,reduceMotion}) {
  const active=[];
  const smooth=t=>t*t*(3-2*t),clamp=t=>Math.max(0,Math.min(1,t));
  function spawn(item,now) {
    const root=new THREE.Group(),materials=new Set(),geometries=new Set();
    const material=(color,metalness,roughness)=>{const m=new THREE.MeshStandardMaterial({color,metalness,roughness,transparent:true});materials.add(m);return m;};
    function mesh(geometry,mat,x=0,y=0,z=0){geometries.add(geometry);const m=new THREE.Mesh(geometry,mat);m.position.set(x,y,z);root.add(m);return m;}
    if(item.id==='key') {
      const copy=keyTemplate.clone(true),copies=new Map();
      copy.traverse(o=>{if(o.isMesh){if(!copies.has(o.material)){const m=o.material.clone();m.opacity=1;m.depthTest=true;copies.set(o.material,m);materials.add(m);}o.material=copies.get(o.material);o.castShadow=false;}});
      copy.position.set(0,.60,0);copy.rotation.set(Math.PI/2,0,0);copy.scale.setScalar(1);copy.visible=true;root.add(copy);
    } else {
      const wooden=item.id==='wood',stone=item.id==='stone';
      const blade=material(wooden?0x9b6939:stone?0x7d909b:0xc1d0db,wooden?0:stone?.04:.86,wooden?.82:stone?.93:.25);
      const edge=material(wooden?0xc09256:stone?0xb5c0c3:0xe9f2f4,wooden?0:stone?.03:.9,wooden?.7:stone?.9:.2);
      const guard=material(wooden?0x5e3d22:stone?0x565e5e:0x8c6e3b,wooden?0:.65,.42);
      const grip=material(0x4b3023,0,.92);
      const outline=new THREE.Shape();outline.moveTo(-.105,-.22);outline.lineTo(-.105,.64);outline.lineTo(0,.91);outline.lineTo(.105,.64);outline.lineTo(.105,-.22);outline.closePath();
      const geo=new THREE.ExtrudeGeometry(outline,{depth:stone?.07:.045,bevelEnabled:true,bevelThickness:.014,bevelSize:.018,bevelSegments:2,steps:1});geo.translate(0,0,-.025);mesh(geo,blade);
      mesh(new THREE.BoxGeometry(.022,.75,.012),edge,0,.18,.039);
      const hilt=mesh(new THREE.CapsuleGeometry(.04,.44,4,12),guard,0,-.27,0);hilt.rotation.z=Math.PI/2;
      mesh(new THREE.CylinderGeometry(.043,.052,.28,12),grip,0,-.45,0);
      for(let i=0;i<5;i++) {const band=mesh(new THREE.TorusGeometry(.048,.009,6,16),guard,0,-.35-i*.045,0);band.rotation.x=Math.PI/2;}
      mesh(new THREE.SphereGeometry(.072,12,8),guard,0,-.63,0);
    }
    const origin=model.localToWorld(new THREE.Vector3(0,.45,.35));
    const hero=model.localToWorld(new THREE.Vector3(0,2.0,1.9));
    root.position.copy(origin);root.rotation.set(.1,-.4,-.16);scene.add(root);
    const curve=new THREE.CubicBezierCurve3(origin,origin.clone().add(new THREE.Vector3(0,1.6,.1)),hero.clone().add(new THREE.Vector3(-.35,.5,-.15)),hero);
    active.push({root,materials,geometries,start:now,curve,hero,id:item.id});
  }
  return {spawn,get count(){return active.length;},get objects(){return active.map(e=>e.root);},tick(now){
    const wasActive=active.length>0;
    for(let i=active.length-1;i>=0;i--){const e=active[i],t=Math.max(0,(now-e.start)/1000)*(reduceMotion?1.5:1);
      if(t>=2.9){scene.remove(e.root);for(const m of e.materials)m.dispose();for(const g of e.geometries)g.dispose();active.splice(i,1);continue;}
      if(t<.85){const k=1-Math.pow(1-t/.85,3);e.root.position.copy(e.curve.getPoint(k));e.root.rotation.y=-.4+k*Math.PI*2;}
      else if(t<1.9){e.root.position.copy(e.hero);e.root.position.y+=Math.sin((t-.85)*3)*.06;e.root.rotation.y=Math.PI*2-.4+(t-.85)*.65;}
      else {const k=smooth(clamp((t-1.9)/1));camera.updateMatrixWorld();const destination=new THREE.Vector3(.79,e.id==='key'?.7:-.74,.5).unproject(camera).sub(camera.position).normalize().multiplyScalar(8).add(camera.position);e.root.position.copy(e.hero).lerp(destination,k);e.root.rotation.z=-.16+k*.6;e.root.scale.setScalar(1-k*.83);for(const m of e.materials)m.opacity=1-smooth(clamp((k-.55)/.45));}
    }
    return wasActive;
  }};
}
