import * as THREE from 'three';
import * as CANNON from 'cannon-es';

export function createCrashSystem({scene,world,body,car}) {
  world.broadphase=new CANNON.SAPBroadphase(world);body.collisionFilterGroup=2;
  const wall=new CANNON.Body({mass:0});wall.position.set(0,1.8,-25);world.addBody(wall);
  const wallGroup=new THREE.Group();wallGroup.name='Destructible voxel wall';scene.add(wallGroup);
  const concrete=new THREE.MeshStandardMaterial({color:0x87948d,roughness:.98});
  const wu=.1,nx=140,ny=36,nz=11,occupied=new Uint8Array(nx*ny).fill(1);
  const isSolid=(x,y)=>x>=0&&x<nx&&y>=0&&y<ny&&occupied[x+nx*y]===1;
  const wallBlocks=new THREE.InstancedMesh(new THREE.BoxGeometry(.099,.099,.099),concrete,nx*ny*nz);
  wallBlocks.instanceMatrix.setUsage(THREE.DynamicDrawUsage);wallBlocks.castShadow=true;wallBlocks.receiveShadow=true;wallGroup.add(wallBlocks);
  const matrix=new THREE.Matrix4(),color=new THREE.Color(),hidden=new THREE.Matrix4().makeScale(0,0,0);
  let wallVoxelCount=0,wallDamage=0;
  function rebuildWall(){
    let count=0;
    for(let y=0;y<ny;y++)for(let x=0;x<nx;x++){
      if(!isSolid(x,y))continue;
      const edge=!isSolid(x-1,y)||!isSolid(x+1,y)||!isSolid(x,y-1)||!isSolid(x,y+1);
      for(let z=0;z<nz;z++){
        if(z!==0&&z!==nz-1&&!edge)continue;
        matrix.makeTranslation((x-(nx-1)/2)*wu,(y+.5)*wu,-25+(z-(nz-1)/2)*wu);wallBlocks.setMatrixAt(count,matrix);
        const shade=((x*73+y*131+z*37)%11)/110;
        if(y<2&&z===nz-1)color.set(Math.floor(x/5)%2?0x253d38:0xe5aa58);else color.setRGB(.70+shade,.76+shade,.71+shade);
        wallBlocks.setColorAt(count++,color);
      }
    }
    wallBlocks.count=count;wallVoxelCount=count;wallBlocks.instanceMatrix.needsUpdate=true;wallBlocks.instanceColor.needsUpdate=true;wallBlocks.computeBoundingSphere();
    // Greedy vertical runs of occupied 20 cm columns. No invisible collider across a hole.
    while(wall.shapes.length)wall.removeShape(wall.shapes[wall.shapes.length-1]);
    for(let cx=0;cx<nx/2;cx++){
      let start=-1;
      for(let cy=0;cy<=ny/2;cy++){
        const solid=cy<ny/2&&isSolid(cx*2,cy*2)&&isSolid(cx*2+1,cy*2)&&isSolid(cx*2,cy*2+1)&&isSolid(cx*2+1,cy*2+1);
        if(solid&&start<0)start=cy;
        if(!solid&&start>=0){const height=(cy-start)*.2;wall.addShape(new CANNON.Box(new CANNON.Vec3(.10,height/2,.55)),new CANNON.Vec3(-7+(cx+.5)*.2,start*.2+height/2-1.8,0));start=-1;}
      }
    }
    wall.updateBoundingRadius();wall.aabbNeedsUpdate=true;world.broadphase.dirty=true;
  }
  rebuildWall();
  const entries=[],debris=[];let clock=0,lastImpact=-10,damage=0,impacts=0,pending=null,lastHit=null;
  const m=new THREE.Matrix4(),v=new THREE.Vector3(),q=new THREE.Quaternion(),s=new THREE.Vector3();
  car.traverse(node=>{if(!node.isInstancedMesh)return;for(let i=0;i<node.count;i++){node.getMatrixAt(i,m);m.decompose(v,q,s);entries.push({node,index:i,base:m.clone(),position:v.clone(),scale:s.clone(),rotation:q.clone(),removed:false});}node.instanceMatrix.setUsage(THREE.DynamicDrawUsage);});
  const cube=new THREE.BoxGeometry(1,1,1),shardMaterial=new CANNON.Material('voxel fragments');
  world.addContactMaterial(new CANNON.ContactMaterial(shardMaterial,shardMaterial,{friction:.6,restitution:.10}));
  world.defaultContactMaterial.friction=.55;world.defaultContactMaterial.restitution=.10;
  function spawn({position,rotation,scale,material,velocity,normal,speed,kind}){
    if(debris.length>=260)return;
    const visual=new THREE.Mesh(cube,material);visual.scale.copy(scale);visual.position.copy(position);visual.quaternion.copy(rotation);visual.castShadow=true;visual.receiveShadow=true;scene.add(visual);
    const shard=new CANNON.Body({mass:Math.max(.025,scale.x*scale.y*scale.z*(kind==='wall'?1800:450)),shape:new CANNON.Box(new CANNON.Vec3(Math.max(.007,scale.x*.48),Math.max(.007,scale.y*.48),Math.max(.007,scale.z*.48))),material:shardMaterial,linearDamping:.15,angularDamping:.25,allowSleep:true,sleepSpeedLimit:.13,sleepTimeLimit:.65,collisionFilterGroup:4,collisionFilterMask:4});
    shard.position.set(position.x,position.y,position.z);shard.quaternion.set(rotation.x,rotation.y,rotation.z,rotation.w);
    shard.previousPosition.copy(shard.position);shard.interpolatedPosition.copy(shard.position);shard.previousQuaternion.copy(shard.quaternion);shard.interpolatedQuaternion.copy(shard.quaternion);
    const kick=Math.min(3.2,.35+speed*.11),jitter=.8;
    shard.velocity.set(velocity.x*.25+normal.x*kick+(Math.random()-.5)*jitter,velocity.y*.20+.25+Math.random()*1.0,velocity.z*.12+normal.z*kick+(Math.random()-.5)*jitter);
    shard.angularVelocity.set((Math.random()-.5)*9,(Math.random()-.5)*9,(Math.random()-.5)*9);
    world.addBody(shard);debris.push({body:shard,visual,born:clock,kind,source:position.clone()});
  }
  function contactPoint(contact){const r=contact.bi===wall?contact.ri:contact.rj;return new CANNON.Vec3(wall.position.x+r.x,wall.position.y+r.y,wall.position.z+r.z);}
  body.addEventListener('collide',event=>{
    if(event.body!==wall||clock-lastImpact<.5||pending)return;
    const speed=Math.abs(event.contact.getImpactVelocityAlongNormal());if(speed<2.5)return;
    const contacts=world.contacts.filter(c=>(c.bi===body&&c.bj===wall)||(c.bj===body&&c.bi===wall));
    const points=(contacts.length?contacts:[event.contact]).map(contactPoint);
    const normal=event.contact.ni.clone();if(event.contact.bi!==wall)normal.negate(normal);
    pending={speed,points,normal,velocity:body.velocity.clone()};
  });
  function breakAt(hit){
    lastImpact=clock;impacts++;
    const center=new CANNON.Vec3();for(const p of hit.points)center.vadd(p,center);center.scale(1/hit.points.length,center);
    const local=new CANNON.Vec3();body.pointToLocalFrame(center,local);
    const normalLocal=new CANNON.Vec3();body.vectorToLocalFrame(hit.normal,normalLocal);
    const radius=Math.min(1.25,.42+hit.speed*.035),dirty=new Set();
    // Use CURRENT block matrices, not undeformed cached positions. Distances are to the contact patch.
    const candidates=[];
    for(const e of entries){if(e.removed)continue;e.node.getMatrixAt(e.index,m);m.decompose(v,q,s);e.position.copy(v);e.rotation.copy(q);e.scale.copy(s);
      let nearest=Infinity;
      const worldP=new CANNON.Vec3();body.pointToWorldFrame(new CANNON.Vec3(v.x,v.y,v.z),worldP);
      for(const p of hit.points)nearest=Math.min(nearest,worldP.distanceSquared(p));
      if(nearest<radius*radius)candidates.push({e,d:nearest});
    }
    candidates.sort((a,b)=>a.d-b.d);
    const limit=Math.min(130,Math.floor(18+hit.speed*4));let removed=0;
    for(const {e,d} of candidates){
      if(removed<limit&&d<radius*radius*.70){
        const p=new CANNON.Vec3(),vel=new CANNON.Vec3();body.pointToWorldFrame(new CANNON.Vec3(e.position.x,e.position.y,e.position.z),p);body.getVelocityAtWorldPoint(p,vel);
        const worldQ=new THREE.Quaternion(body.quaternion.x,body.quaternion.y,body.quaternion.z,body.quaternion.w).multiply(e.rotation);
        spawn({position:new THREE.Vector3(p.x,p.y,p.z),rotation:worldQ,scale:e.scale.clone(),material:e.node.material,velocity:vel,normal:hit.normal,speed:hit.speed,kind:'car'});
        e.removed=true;e.node.setMatrixAt(e.index,hidden);dirty.add(e.node);removed++;
      }else{
        const weight=1-Math.sqrt(d)/radius;
        v.copy(e.position).addScaledVector(new THREE.Vector3(normalLocal.x,normalLocal.y,normalLocal.z),weight*Math.min(.20,hit.speed*.007));
        m.compose(v,e.rotation,e.scale);e.node.setMatrixAt(e.index,m);dirty.add(e.node);
      }
    }
    for(const node of dirty)node.instanceMatrix.needsUpdate=true;damage+=removed;
    // Punch a through-hole in both the visible fine voxels and physical wall columns.
    const wr=Math.min(1.30,.38+hit.speed*.038),wallCandidates=[];
    for(let y=0;y<ny;y++)for(let x=0;x<nx;x++){
      if(!isSolid(x,y))continue;
      const px=(x-(nx-1)/2)*wu,py=(y+.5)*wu;
      const d=(px-center.x)**2+(py-center.y)**2;
      if(d>wr*wr)continue;
      occupied[x+nx*y]=0;wallDamage+=nz;
      for(let z=0;z<nz;z++)wallCandidates.push({x:px,y:py,z:-25+(z-(nz-1)/2)*wu,d:d+Math.abs(z-5)*.005});
    }
    wallCandidates.sort((a,b)=>a.d-b.d);
    const wallLimit=Math.min(80,260-debris.length);
    for(let i=0;i<wallLimit&&i<wallCandidates.length;i++){
      const p=wallCandidates[Math.floor(i*wallCandidates.length/wallLimit)];
      spawn({position:new THREE.Vector3(p.x,p.y,p.z),rotation:new THREE.Quaternion(),scale:new THREE.Vector3(.099,.099,.099),material:concrete,velocity:hit.velocity,normal:new CANNON.Vec3(-hit.normal.x,0,-hit.normal.z),speed:hit.speed,kind:'wall'});
    }
    if(wallCandidates.length)rebuildWall();
    lastHit={world:[center.x,center.y,center.z],local:[local.x,local.y,local.z],contacts:hit.points.length,carRemoved:removed,wallRemoved:wallCandidates.length};
  }
  function reset(){
    pending=null;for(const e of entries){e.node.setMatrixAt(e.index,e.base);e.node.instanceMatrix.needsUpdate=true;e.removed=false;}
    for(const e of debris){world.removeBody(e.body);scene.remove(e.visual);}debris.length=0;damage=0;wallDamage=0;impacts=0;lastImpact=-10;lastHit=null;occupied.fill(1);rebuildWall();
  }
  return {wall,wallGroup,get wallVoxelCount(){return wallVoxelCount;},get wallDamage(){return wallDamage;},get lastHit(){return lastHit;},get damage(){return damage;},get impacts(){return impacts;},get debrisCount(){return debris.length;},get debris(){return debris;},reset,tick(dt){
    clock+=dt;if(pending){const hit=pending;pending=null;breakAt(hit);}
    for(let i=debris.length-1;i>=0;i--){const e=debris[i],age=clock-e.born;if(age>12){world.removeBody(e.body);scene.remove(e.visual);debris.splice(i,1);continue;}
      // Let each cube leave its original surface naturally before enabling static-wall contact.
      if(age>.08&&e.body.collisionFilterMask!==5){e.body.collisionFilterMask=5;e.body.wakeUp();}
      const p=e.body.interpolatedPosition,q=e.body.interpolatedQuaternion;e.visual.position.set(p.x,p.y,p.z);e.visual.quaternion.set(q.x,q.y,q.z,q.w);
    }
  }};
}
