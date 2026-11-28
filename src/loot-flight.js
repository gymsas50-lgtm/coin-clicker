import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createLootFlight({scene,model,camera,keyTemplate,reduceMotion,physics}) {
  const active=[];
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
    const origin=model.localToWorld(new THREE.Vector3(0,.65,.45));
    root.position.copy(origin);root.rotation.set(.1,-.4,-.16);scene.add(root);
    const body=new CANNON.Body({mass:item.id==='key'?.16:item.id==='wood'?.45:item.id==='stone'?1.2:.9,material:physics.brass,linearDamping:.06,angularDamping:.09,allowSleep:true,sleepSpeedLimit:.09,sleepTimeLimit:.8});
    if(item.id==='key') {
      body.addShape(new CANNON.Box(new CANNON.Vec3(.027,.43,.027)),new CANNON.Vec3(0,.16,0));
      for(let i=0;i<16;i++){const a=i*Math.PI/8;body.addShape(new CANNON.Sphere(.032),new CANNON.Vec3(0,-.54+Math.sin(a)*.205,Math.cos(a)*.155));}
    } else {
      body.addShape(new CANNON.Box(new CANNON.Vec3(.11,.49,.045)),new CANNON.Vec3(0,.28,0));
      body.addShape(new CANNON.Box(new CANNON.Vec3(.27,.045,.045)),new CANNON.Vec3(0,-.27,0));
      body.addShape(new CANNON.Box(new CANNON.Vec3(.05,.18,.05)),new CANNON.Vec3(0,-.47,0));
    }
    body.position.set(origin.x,origin.y,origin.z);body.quaternion.set(root.quaternion.x,root.quaternion.y,root.quaternion.z,root.quaternion.w);
    body.velocity.set((Math.random()-.5)*.65,6.2,2.25);body.angularVelocity.set(1.3,2.1,-.8);
    // Ignore the body's simplified solid chest collider until the item clears the opening.
    body.collisionFilterMask=1;
    const entry={root,materials,geometries,start:now,body,landed:null};
    body.addEventListener('collide',event=>{if(entry.landed===null&&event.body.collisionFilterGroup!==2)entry.landed=performance.now();});
    physics.world.addBody(body);active.push(entry);
  }
  return {spawn,get count(){return active.length;},get objects(){return active.map(e=>e.root);},tick(now){
    const wasActive=active.length>0;
    for(let i=active.length-1;i>=0;i--){const e=active[i],age=now-e.start;
      if(age>400)e.body.collisionFilterMask=-1;
      if(now-(e.landed??e.start)>(e.landed===null?15000:10000)){
        physics.world.removeBody(e.body);scene.remove(e.root);for(const m of e.materials)m.dispose();for(const g of e.geometries)g.dispose();active.splice(i,1);continue;
      }
      const p=e.body.interpolatedPosition,q=e.body.interpolatedQuaternion;
      e.root.position.set(p.x,p.y,p.z);e.root.quaternion.set(q.x,q.y,q.z,q.w);
    }
    return wasActive;
  }};
}
