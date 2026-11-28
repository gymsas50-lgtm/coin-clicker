import * as THREE from 'three';
import * as CANNON from 'cannon-es';

export function createCrashSystem({scene,world,body,car}) {
  world.broadphase=new CANNON.SAPBroadphase(world);
  body.collisionFilterGroup=2;
  const wall=new CANNON.Body({mass:0,shape:new CANNON.Box(new CANNON.Vec3(7,1.8,.55))});wall.position.set(0,1.8,-25);world.addBody(wall);
  const wallGroup=new THREE.Group();wallGroup.name='Crash-test wall';scene.add(wallGroup);
  const concrete=new THREE.MeshStandardMaterial({color:0x7e8d85,roughness:.98});
  const wallBlocks=new THREE.InstancedMesh(new THREE.BoxGeometry(.69,.59,1.1),concrete,20*6);
  const matrix=new THREE.Matrix4();let index=0;
  for(let y=0;y<6;y++)for(let x=0;x<20;x++){matrix.makeTranslation((x-9.5)*.7,.3+y*.6,-25);wallBlocks.setMatrixAt(index++,matrix);}
  wallBlocks.castShadow=true;wallBlocks.receiveShadow=true;wallGroup.add(wallBlocks);
  const orange=new THREE.MeshStandardMaterial({color:0xe29a4c,roughness:.8}),dark=new THREE.MeshStandardMaterial({color:0x263c38,roughness:.9});
  for(let i=0;i<28;i++){const stripe=new THREE.Mesh(new THREE.BoxGeometry(.48,.16,.035),i%2?dark:orange);stripe.position.set((i-13.5)*.5,.20,-24.425);wallGroup.add(stripe);}
  for(const x of [-7.1,7.1]){const post=new THREE.Mesh(new THREE.BoxGeometry(.22,3.8,1.25),dark);post.position.set(x,1.9,-25);post.castShadow=true;wallGroup.add(post);}
  const entries=[],debris=[];let lastImpact=-10,damage=0,impacts=0,clock=0;
  const tempMatrix=new THREE.Matrix4(),hidden=new THREE.Matrix4().makeScale(0,0,0),v=new THREE.Vector3(),q=new THREE.Quaternion(),scale=new THREE.Vector3();
  car.traverse(node=>{if(!node.isInstancedMesh)return;for(let i=0;i<node.count;i++){node.getMatrixAt(i,tempMatrix);tempMatrix.decompose(v,q,scale);entries.push({node,index:i,base:tempMatrix.clone(),position:v.clone(),scale:scale.clone(),removed:false});}node.instanceMatrix.setUsage(THREE.DynamicDrawUsage);});
  const cube=new THREE.BoxGeometry(1,1,1),shardMaterial=new CANNON.Material('painted fragments');
  world.addContactMaterial(new CANNON.ContactMaterial(shardMaterial,shardMaterial,{friction:.55,restitution:.15}));
  world.defaultContactMaterial.friction=.55;world.defaultContactMaterial.restitution=.12;
  function fragment(e,impactSpeed){
    const local=e.position.clone();const point=new CANNON.Vec3();body.pointToWorldFrame(new CANNON.Vec3(local.x,local.y,local.z),point);
    const visual=new THREE.Mesh(cube,e.node.material);visual.scale.copy(e.scale);visual.castShadow=true;visual.receiveShadow=true;scene.add(visual);
    const extents=new CANNON.Vec3(Math.max(.025,e.scale.x/2),Math.max(.025,e.scale.y/2),Math.max(.025,e.scale.z/2));
    const shard=new CANNON.Body({mass:Math.max(.035,e.scale.x*e.scale.y*e.scale.z*130),shape:new CANNON.Box(extents),material:shardMaterial,linearDamping:.12,angularDamping:.2,allowSleep:true,sleepSpeedLimit:.15,sleepTimeLimit:.6,collisionFilterGroup:4,collisionFilterMask:5});
    shard.position.copy(point);shard.previousPosition.copy(point);shard.interpolatedPosition.copy(point);shard.quaternion.copy(body.quaternion);shard.previousQuaternion.copy(body.quaternion);shard.interpolatedQuaternion.copy(body.quaternion);
    // Eject into the free side of the wall, rather than spawning inside concrete.
    if(Math.abs(shard.position.x)<7.2&&Math.abs(shard.position.z+25)<.72)shard.position.z=-24.23;
    shard.position.y=Math.max(shard.position.y,extents.y+.035);
    const kick=Math.min(impactSpeed*.30,7);
    const outward=Math.sign(local.x)|| (Math.random()<.5?-1:1);
    shard.velocity.set(outward*(1+Math.random()*kick),1+Math.random()*kick,1+Math.random()*kick*.7);
    shard.angularVelocity.set((Math.random()-.5)*18,(Math.random()-.5)*18,(Math.random()-.5)*18);
    world.addBody(shard);debris.push({body:shard,visual,born:clock});
  }
  body.addEventListener('collide',event=>{
    if(event.body!==wall||clock-lastImpact<.55)return;
    const speed=Math.abs(event.contact.getImpactVelocityAlongNormal());if(speed<2.5)return;
    lastImpact=clock;impacts++;
    const contact=event.contact,relative=contact.bi===body?contact.ri:contact.rj;
    const hitWorld=body.position.vadd(relative),hitLocal=new CANNON.Vec3();body.pointToLocalFrame(hitWorld,hitLocal);
    const radius=Math.min(1.75,.65+speed*.045);
    const candidates=entries.filter(e=>!e.removed).map(e=>({e,d:(e.position.x-hitLocal.x)**2+(e.position.y-hitLocal.y)**2+(e.position.z-hitLocal.z)**2})).sort((a,b)=>a.d-b.d);
    const count=Math.min(140,Math.floor(18+speed*5),240-debris.length);
    const dirty=new Set();let removed=0;
    for(const {e,d} of candidates){if(removed>=count||d>radius*radius)break;e.removed=true;e.node.setMatrixAt(e.index,hidden);dirty.add(e.node);fragment(e,speed);removed++;}
    // Crush the impacted panel inward. Missing blocks expose an actual jagged silhouette.
    for(const {e,d} of candidates){if(e.removed||d>radius*radius*1.7)continue;
      const weight=1-Math.sqrt(d)/(radius*1.31);e.node.getMatrixAt(e.index,tempMatrix);tempMatrix.decompose(v,q,scale);
      v.z+=Math.max(0,weight)*Math.min(.38,speed*.014);v.y-=Math.max(0,weight)*.07;
      tempMatrix.compose(v,q,scale);e.node.setMatrixAt(e.index,tempMatrix);dirty.add(e.node);
    }
    for(const node of dirty)node.instanceMatrix.needsUpdate=true;
    damage+=removed;
  });
  function reset(){for(const e of entries){e.node.setMatrixAt(e.index,e.base);e.node.instanceMatrix.needsUpdate=true;e.removed=false;}for(const e of debris){world.removeBody(e.body);scene.remove(e.visual);}debris.length=0;damage=0;impacts=0;lastImpact=-10;}
  return {wall,get damage(){return damage;},get impacts(){return impacts;},get debrisCount(){return debris.length;},get debris(){return debris;},reset,tick(dt){clock+=dt;for(let i=debris.length-1;i>=0;i--){const e=debris[i];if(clock-e.born>12){world.removeBody(e.body);scene.remove(e.visual);debris.splice(i,1);continue;}const p=e.body.interpolatedPosition,q=e.body.interpolatedQuaternion;e.visual.position.set(p.x,p.y,p.z);e.visual.quaternion.set(q.x,q.y,q.z,q.w);}}};
}
