import * as THREE from 'three';

export function createVoxelCar(scene) {
  const car=new THREE.Group();car.name='VOXEL / Aster GT';scene.add(car);
  const mat=(color,metalness=.05,roughness=.7,extra={})=>new THREE.MeshStandardMaterial({color,metalness,roughness,...extra});
  const palette={
    jade:mat(0x168c82,.32,.38),shade:mat(0x10665f,.2,.48),light:mat(0x31a69a,.23,.42),
    cream:mat(0xf0e8cc,.12,.48),dark:mat(0x182b30,.12,.63),glass:mat(0x244951,.45,.22),
    reflection:mat(0x56858b,.4,.28),metal:mat(0x9ab0ab,.72,.36),rubber:mat(0x202a2d,.02,.95),tread:mat(0x303b3b,.02,.9),
    bronze:mat(0xb59557,.65,.38),bronzeLight:mat(0xddbc7d,.63,.33),
    head:mat(0xffe4a2,.1,.3,{emissive:0xffca6d,emissiveIntensity:1.35}),
    amber:mat(0xef9c3c,.1,.45,{emissive:0xff8d26,emissiveIntensity:.5}),
    brake:mat(0xda4237,.1,.4,{emissive:0xf83227,emissiveIntensity:.65})
  };
  const cube=new THREE.BoxGeometry(1,1,1),matrix=new THREE.Matrix4(),position=new THREE.Vector3(),rotation=new THREE.Quaternion(),scale=new THREE.Vector3();
  let visibleVoxels=0;
  function instances(parent,entries,unit){
    const groups=new Map();for(const e of entries){if(!groups.has(e.m))groups.set(e.m,[]);groups.get(e.m).push(e);}
    for(const [id,blocks] of groups){const inst=new THREE.InstancedMesh(cube,palette[id],blocks.length);inst.name='Voxels / '+id;inst.castShadow=true;inst.receiveShadow=true;
      for(let i=0;i<blocks.length;i++){const b=blocks[i];position.set(b.x,b.y,b.z);scale.set(b.sx??unit,b.sy??unit,b.sz??unit);matrix.compose(position,rotation,scale);inst.setMatrixAt(i,matrix);}
      inst.computeBoundingSphere();parent.add(inst);visibleVoxels+=blocks.length;
    }
  }
  const unit=.07,cells=new Map(),id=(x,y,z)=>`${x},${y},${z}`;
  function put(x,y,z,m){cells.set(id(x,y,z),{x,y,z,m});}
  function stripe(x){return Math.abs(Math.abs(x)-.175)<.055;}
  // Sculpt the coupe on a real voxel lattice, including open wheel arches.
  for(let ix=-13;ix<=13;ix++)for(let iz=-29;iz<=29;iz++)for(let iy=-3;iy<=14;iy++){
    const x=ix*unit,y=iy*unit,z=iz*unit,ax=Math.abs(x),az=Math.abs(z);
    let width=az>1.89?.77:az>1.68?.84:.91;
    const deck=z<-.85?.28+(z+2.03)*.06:.35;
    let m=null;
    if(y>=-.21&&y<=deck&&ax<=width){
      const arch=[-1.22,1.22].some(wz=>(z-wz)**2+(y+.16)**2<.405**2);
      if(!(ax>.59&&arch))m=y<-.1?'shade':iy===4?'light':'jade';
      if(m&&y<-.13)m='dark';
      if(m&&stripe(x)&&y>.20)m='cream';
    }
    // Glasshouse narrows toward the roof; both windscreens are stair-stepped.
    if(y>.35&&y<=.91){
      const h=(y-.35)/.56,front=-.91+h*.54,back=1.18-h*.42;
      const cabinWidth=.735-h*.105;
      if(z>=front&&z<=back&&ax<=cabinWidth){
        m='glass';
        const pillar=ax>cabinWidth-.07&&(Math.abs(z-.21)<.055||z<front+.075||z>back-.075);
        if(pillar)m='shade';
        if(y>.84)m=stripe(x)?'cream':'jade';
        else if(ax<cabinWidth-.12&&z<front+.09&&ix%6===0)m='reflection';
        else if(ax>cabinWidth-.06&&z<.10&&z>-.45&&iy===10)m='reflection';
      }
    }
    if(m)put(ix,iy,iz,m);
  }
  const surface=[];
  for(const b of cells.values()){
    if([[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]].every(([x,y,z])=>cells.has(id(b.x+x,b.y+y,b.z+z))))continue;
    surface.push({x:b.x*unit,y:b.y*unit,z:b.z*unit,m:b.m});
  }
  instances(car,surface,unit);
  const details=[];
  const add=(x,y,z,sx,sy,sz,m)=>details.push({x,y,z,sx,sy,sz,m});
  // Layered bumpers, pixel matrix lamps and recessed grilles.
  add(0,-.10,-2.09,1.62,.105,.10,'dark');add(0,-.10,2.09,1.62,.105,.10,'dark');
  add(0,-.015,-2.105,.67,.14,.04,'dark');
  for(let i=-3;i<=3;i++)add(i*.085,-.015,-2.13,.035,.07,.015,'metal');
  for(const side of [-1,1]){
    add(side*.60,.15,-2.09,.36,.22,.065,'dark');
    for(let x=0;x<4;x++)for(let y=0;y<2;y++)add(side*.60+(x-1.5)*.075,.10+y*.09,-2.13,.061,.070,.03,'head');
    add(side*.83,.04,-1.93,.045,.07,.14,'amber');
    add(side*.56,.15,2.075,.49,.15,.065,'dark');
    for(let x=0;x<6;x++)add(side*.56+(x-2.5)*.07,.15,2.12,.057,.075,.022,'brake');
    add(side*.79,-.035,2.12,.075,.055,.02,'amber');
    add(side*.925,.40,-.58,.08,.07,.09,'dark');add(side*1.00,.44,-.58,.16,.11,.21,'jade');add(side*1.005,.45,-.46,.11,.055,.015,'reflection');
    add(side*.945,.245,.57,.022,.035,.17,'metal');
    add(side*.944,-.05,.02,.04,.08,1.15,'dark');
    // Door outline, side intake and small pixel GT insignia.
    add(side*.948,.10,.92,.012,.28,.018,'shade');
    for(let n=0;n<3;n++)add(side*.956,.09, .64+n*.075,.024,.08,.027,'dark');
    add(side*.95,.17,-.55,.025,.055,.12,'cream');
    add(side*.57,.43,1.73,.075,.22,.085,'dark');
    add(side*.54,-.17,2.145,.14,.09,.14,'metal');add(side*.54,-.17,2.22,.09,.045,.015,'dark');
  }
  // A low ducktail spoiler and twin racing stripes continue over the deck.
  add(0,.57,1.75,1.70,.085,.20,'jade');
  add(0,.615,1.75,1.65,.015,.17,'light');
  for(const side of [-1,1])add(side*.175,.628,1.75,.10,.014,.18,'cream');
  add(0,.10,2.13,.35,.105,.025,'cream');
  for(let i=-2;i<=2;i++)add(i*.045,.10,2.15,.023,.04,.008,'dark');
  // Roof edge and hood air vents read as pixels rather than flat painted decals.
  for(const side of [-1,1])for(let n=0;n<4;n++)add(side*.48,.36,-.74-n*.10,.18,.014,.035,'dark');
  instances(car,details,unit);
  const wheels=[];
  for(let i=0;i<4;i++){
    const wheel=new THREE.Group();wheel.name='Voxel wheel '+i;scene.add(wheel);wheels.push(wheel);
    const blocks=[],u=.052;
    for(let ix=-2;ix<=2;ix++)for(let iy=-6;iy<=6;iy++)for(let iz=-6;iz<=6;iz++){
      const y=iy*u,z=iz*u,r=Math.hypot(y,z);if(r>.343)continue;
      const face=Math.abs(ix)===2;
      let m='rubber';
      if(r>.285)m=(iy+iz)%3===0?'tread':'rubber';
      if(face&&r<.242){m='dark';const a=Math.atan2(z,y),spoke=Math.abs(Math.sin(a*3));if(r<.076||r>.207||spoke<.42)m=r>.20?'bronzeLight':'bronze';if(r<.034)m='metal';}
      // Surface-only wheel voxels, shared geometry and instanced per material.
      if(!face&&r<.272)continue;
      blocks.push({x:ix*u,y,z,m});
    }
    instances(wheel,blocks,u);
  }
  car.userData.voxelCount=visibleVoxels;car.userData.style='voxel';
  return {car,wheels,brakeRed:palette.brake,voxelCount:visibleVoxels};
}
