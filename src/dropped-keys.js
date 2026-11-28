import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createDroppedKeys(scene) {
  const world=new CANNON.World({gravity:new CANNON.Vec3(0,-9.81,0),allowSleep:true});
  world.solver.iterations=16;
  const brass=new CANNON.Material('brass'),groundMat=new CANNON.Material('floor');
  world.addContactMaterial(new CANNON.ContactMaterial(brass,groundMat,{friction:.6,restitution:.19}));
  world.addContactMaterial(new CANNON.ContactMaterial(brass,brass,{friction:.48,restitution:.16}));
  const floor=new CANNON.Body({mass:0,material:groundMat,shape:new CANNON.Plane()});
  floor.quaternion.setFromEuler(-Math.PI/2,0,0);floor.position.y=.20;world.addBody(floor);
  const chest=new CANNON.Body({mass:0,material:groundMat,shape:new CANNON.Box(new CANNON.Vec3(2.84,1.15,1.25))});chest.collisionFilterGroup=2;chest.position.set(0,1.7,0);world.addBody(chest);
  const items=[];let previous=null;
  const center=new THREE.Vector3(0,0,.65),offset=new THREE.Vector3();
  function drop(source,now) {
    const visual=source.clone(true),materials=new Map();
    visual.traverse(o=>{if(o.isMesh){if(!materials.has(o.material)){const m=o.material.clone();m.opacity=1;m.depthTest=true;materials.set(o.material,m);}o.material=materials.get(o.material);o.castShadow=true;}});
    visual.visible=true;scene.add(visual);
    const body=new CANNON.Body({mass:.16,material:brass,linearDamping:.09,angularDamping:.14,sleepSpeedLimit:.08,sleepTimeLimit:.7});
    body.addShape(new CANNON.Box(new CANNON.Vec3(.027,.027,.43)),new CANNON.Vec3(0,0,-.21));
    body.addShape(new CANNON.Box(new CANNON.Vec3(.016,.052,.078)),new CANNON.Vec3(0,-.047,-.52));
    // Compound ring collider retains the opening; keys can catch on one another.
    for(let i=0;i<16;i++){const a=i*Math.PI/8;body.addShape(new CANNON.Sphere(.032),new CANNON.Vec3(0,Math.cos(a)*.155,.49+Math.sin(a)*.205));}
    offset.copy(center).applyQuaternion(source.quaternion);
    body.position.set(source.position.x+offset.x,source.position.y+offset.y,source.position.z+offset.z);
    body.quaternion.set(source.quaternion.x,source.quaternion.y,source.quaternion.z,source.quaternion.w);
    body.velocity.set((Math.random()-.5)*.12,-.10,.12);body.angularVelocity.set(.7,.2,(Math.random()-.5)*.8);
    const entry={body,visual,born:now,landed:null,materials};
    body.addEventListener('collide',event=>{if(entry.landed===null&&event.body!==chest)entry.landed=performance.now();});
    world.addBody(body);items.push(entry);
  }
  return {drop,world,brass,get count(){return items.length;},get items(){return items;},tick(now){
    const dt=previous===null?0:Math.min(.1,Math.max(0,(now-previous)/1000));previous=now;
    if(!items.length&&world.bodies.length<=2)return false;
    world.step(1/120,dt,12);
    for(let i=items.length-1;i>=0;i--){const e=items[i];
      if(now-(e.landed??e.born)> (e.landed===null?14000:10000)){
        world.removeBody(e.body);scene.remove(e.visual);for(const m of e.materials.values())m.dispose();items.splice(i,1);continue;
      }
      const q=e.body.interpolatedQuaternion,p=e.body.interpolatedPosition;
      e.visual.quaternion.set(q.x,q.y,q.z,q.w);
      offset.copy(center).applyQuaternion(e.visual.quaternion);
      e.visual.position.set(p.x-offset.x,p.y-offset.y,p.z-offset.z);
    }
    return true;
  }};
}
