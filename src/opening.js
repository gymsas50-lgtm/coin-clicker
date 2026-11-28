import * as THREE from 'three';
import { createHingeMotion } from './hinge.js';

export function createChestOpening({scene,model,camera,renderer,lidPivot,haspPivot,keyholeSlot,reduceMotion,economy}) {
  const canvas=renderer.domElement;
  const duration=8.88;
  let phase='closed',started=0,force=true,shadow=true,closingAngle=0;
  let manualTime=null;
  const openHinge=createHingeMotion(true);
  let closeHinge=createHingeMotion(false,1.62);
  const gold=new THREE.MeshStandardMaterial({color:0x9e783b,metalness:.82,roughness:.34,transparent:true});
  const polished=new THREE.MeshStandardMaterial({color:0xd6b778,metalness:.87,roughness:.26,transparent:true});
  const darkGold=new THREE.MeshStandardMaterial({color:0x5e4528,metalness:.76,roughness:.47,transparent:true});
  const key=new THREE.Group();key.name='Antique brass key';scene.add(key);key.visible=false;
  function mesh(geo,mat,pos) {
    const m=new THREE.Mesh(geo,mat);m.position.set(...pos);m.castShadow=false;key.add(m);return m;
  }
  function rod(radius,len,z,mat=gold) {
    const m=mesh(new THREE.CylinderGeometry(radius,radius,len,32),mat,[0,0,z]);m.rotation.x=Math.PI/2;return m;
  }
  // One straight shaft, tip at z=0, all ornament in the shaft's XZ plane.
  rod(.026,.85,.44);
  mesh(new THREE.SphereGeometry(.026,20,12),polished,[0,0,.015]);
  rod(.038,.045,.76,polished);rod(.034,.025,.81,darkGold);
  rod(.046,.055,.87,gold);rod(.036,.09,.91,polished);
  const bowStart=key.children.length;
  function oval(rx,rz,thickness,y,mat) {
    const pts=[];
    for(let i=0;i<=96;i++) {
      const angle=i/96*Math.PI*2;
      // A restrained scalloped oval, symmetric about the shaft.
      const flute=1+.035*Math.cos(angle*4);
      pts.push(new THREE.Vector3(Math.cos(angle)*rx*flute,y,1.14+Math.sin(angle)*rz*flute));
    }
    mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts,true),96,thickness,10,true),mat,[0,0,0]);
  }
  oval(.155,.205,.027,0,gold);
  oval(.143,.191,.007,-.023,polished);
  oval(.143,.191,.007,.023,polished);
  // Small, mirrored scrolls are welded to the bow, never floating beside it.
  for(const side of [-1,1]) {
    const points=[[0,1.00],[side*.070,1.045],[side*.083,1.105],[side*.045,1.13],[side*.022,1.10]]
      .map(([x,z])=>new THREE.Vector3(x,0,z));
    mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points),32,.012,8,false),gold,[0,0,0]);
  }
  const bowGroup=new THREE.Group();bowGroup.position.set(0,0,1.14);key.add(bowGroup);
  key.updateMatrixWorld(true);
  for(const part of key.children.slice(bowStart).filter(part=>part!==bowGroup))bowGroup.attach(part);
  bowGroup.rotation.z=Math.PI/2;
  // The bit points down into the narrow lower slot of the actual keyhole.
  const bit=new THREE.Shape();
  bit.moveTo(.055,-.009);bit.lineTo(.055,-.095);bit.lineTo(.10,-.095);
  bit.lineTo(.10,-.066);bit.lineTo(.137,-.066);bit.lineTo(.137,-.095);
  bit.lineTo(.205,-.095);bit.lineTo(.205,-.009);bit.closePath();
  const bitGeo=new THREE.ExtrudeGeometry(bit,{depth:.024,bevelEnabled:true,bevelThickness:.003,bevelSize:.003,bevelSegments:3,steps:1});
  // Shape horizontal coordinate maps to shaft Z, extrusion maps to X.
  bitGeo.rotateY(-Math.PI/2);bitGeo.translate(.012,0,0);
  mesh(bitGeo,gold,[0,0,0]);
  const lockRing=new THREE.Mesh(new THREE.TorusGeometry(.052,.008,12,48),gold.clone());
  lockRing.position.set(0,.19,1.337);model.add(lockRing);
  const lockCenter=new THREE.Vector3(0,.19,1.34);
  const target=new THREE.Vector3(),outside=new THREE.Vector3(),hero=new THREE.Vector3();
  let flyIn,approach;
  const qStart=new THREE.Quaternion().setFromEuler(new THREE.Euler(.75,.3,-.35));
  const qHero=new THREE.Quaternion().setFromEuler(new THREE.Euler(1.05,.12,-.20));
  const qAligned=new THREE.Quaternion();
  const up=new THREE.Vector3(),right=new THREE.Vector3();
  function screenPoint(x,y,distance) {
    camera.updateMatrixWorld();
    return new THREE.Vector3(x,y,.5).unproject(camera).sub(camera.position).normalize().multiplyScalar(distance).add(camera.position);
  }
  function paths() {
    model.updateMatrixWorld(true);model.localToWorld(target.copy(lockCenter));
    outside.copy(target).add(new THREE.Vector3(0,0,.55));
    hero.copy(screenPoint(-.08,-.16,6.4));
    up.set(0,1,0).applyQuaternion(camera.quaternion);right.set(1,0,0).applyQuaternion(camera.quaternion);
    const from=screenPoint(-.08,-1.55,6.4);
    flyIn=new THREE.CubicBezierCurve3(from,from.clone().addScaledVector(up,2.6).addScaledVector(right,.65),hero.clone().addScaledVector(right,.45).addScaledVector(up,.25),hero);
    approach=new THREE.CubicBezierCurve3(hero,hero.clone().addScaledVector(right,-.7).addScaledVector(up,.5),outside.clone().add(new THREE.Vector3(0,0,.65)),outside);
  }
  const glowCanvas=document.createElement('canvas');glowCanvas.width=glowCanvas.height=128;
  const ctx=glowCanvas.getContext('2d');const radial=ctx.createRadialGradient(64,64,3,64,64,64);
  radial.addColorStop(0,'rgba(255,226,165,.8)');radial.addColorStop(.35,'rgba(255,187,80,.22)');radial.addColorStop(1,'rgba(255,172,62,0)');
  ctx.fillStyle=radial;ctx.fillRect(0,0,128,128);
  const glowMaterial=new THREE.SpriteMaterial({map:new THREE.CanvasTexture(glowCanvas),transparent:true,opacity:0,blending:THREE.AdditiveBlending,depthWrite:false});
  const glow=new THREE.Sprite(glowMaterial);glow.position.set(0,.72,0);glow.scale.set(5,3,1);model.add(glow);glow.visible=false;
  const light=new THREE.PointLight(0xffbf73,0,6,2);light.position.set(0,.65,0);model.add(light);
  const dustCount=44,dustPositions=new Float32Array(dustCount*3),dustSeed=[];
  for(let i=0;i<dustCount;i++) dustSeed.push({x:Math.sin(i*37.7)*2.05,z:Math.cos(i*17.3)*.76,y:(i*.618)%1,phase:i*2.4});
  const dustGeo=new THREE.BufferGeometry();dustGeo.setAttribute('position',new THREE.BufferAttribute(dustPositions,3));
  const dustMat=new THREE.PointsMaterial({color:0xffdb9e,size:.027,transparent:true,opacity:0,depthWrite:false,blending:THREE.AdditiveBlending});
  const dust=new THREE.Points(dustGeo,dustMat);model.add(dust);dust.visible=false;
  const clamp=x=>Math.max(0,Math.min(1,x));
  const segment=(t,a,b)=>clamp((t-a)/(b-a));
  const smooth=x=>x*x*(3-2*x);
  const smoother=x=>x*x*x*(x*(x*6-15)+10);
  const easeOut=x=>1-Math.pow(1-x,3);
  function lightLevel(amount,t) {
    glow.visible=amount>.001;glowMaterial.opacity=amount*.48;
    light.intensity=amount*6;
    dust.visible=amount>.05;dustMat.opacity=amount*.68;
    if(dust.visible) {
      for(let i=0;i<dustCount;i++) {
        const s=dustSeed[i],h=(s.y+t*.10)%1;
        dustPositions[i*3]=s.x+Math.sin(t*.6+s.phase)*.12;
        dustPositions[i*3+1]=-.35+h*2.6;
        dustPositions[i*3+2]=s.z+Math.cos(t*.35+s.phase)*.08;
      }
      dustGeo.attributes.position.needsUpdate=true;
    }
  }
  function frameAt(t) {
    if(!flyIn) paths();
    let scale=1;
    if(t<.95) {
      const k=easeOut(segment(t,0,.95));key.position.copy(flyIn.getPoint(k));key.quaternion.copy(qStart).slerp(qHero,k);scale=1;
    } else if(t<1.35) {
      const k=segment(t,.95,1.35);key.position.copy(hero).addScaledVector(up,Math.sin(k*Math.PI)*.055);
      key.quaternion.copy(qHero);scale=1;
    } else if(t<2.65) {
      const k=smoother(segment(t,1.35,2.65));key.position.copy(approach.getPoint(k));key.quaternion.copy(qHero).slerp(qAligned,smooth(clamp(k/ .78)));scale=1;
    } else {
      const inserted=smoother(segment(t,2.65,3.2));key.position.copy(outside).lerp(target.clone().add(new THREE.Vector3(0,0,-.39)),inserted);
      const turn=smoother(segment(t,3.35,4.2));key.quaternion.setFromAxisAngle(new THREE.Vector3(0,0,1),turn*Math.PI*.5);
      keyholeSlot.rotation.z=-turn*Math.PI*.5;
      if(t>4.55) key.position.z+=smooth(segment(t,4.55,5.12))*.8;
      if(t>4.95) key.position.addScaledVector(up,-smooth(segment(t,4.95,5.55))*.7);
    }
    key.scale.setScalar(scale);
    key.visible=t<5.55;
    const opacity=1-smooth(segment(t,5.02,5.55));
    for(const mat of [gold,polished,darkGold]) {mat.opacity=opacity;mat.depthTest=true;}
    // The heavy lid moves only after the key is turned and the hasp clears the catch.
    haspPivot.rotation.x=-smooth(segment(t,4.2,4.65))*.35;
    lidPivot.rotation.x=-openHinge(Math.max(0,t-5.08));
    lightLevel(smooth(segment(t,5.35,6.7)),t);
  }
  function setPhase(next) {
    phase=next;canvas.dataset.state=phase;
    canvas.setAttribute('aria-label',phase==='open'?'Открытый сундук. Нажми, чтобы закрыть.':'Старый сундук. Нажми, чтобы открыть ключом.');
    canvas.style.cursor=(phase==='opening'||phase==='closing')?'wait':'pointer';
  }
  function activate() {
    if(phase==='opening'||phase==='closing')return;
    if(phase==='closed' && economy && !economy.consumeKey())return;
    manualTime=null;started=performance.now();force=true;
    if(phase==='closed') {paths();setPhase('opening');key.visible=true;}
    else {closingAngle=lidPivot.rotation.x;closeHinge=createHingeMotion(false,-closingAngle);key.visible=false;setPhase('closing');}
  }
  const ray=new THREE.Raycaster(),ndc=new THREE.Vector2();let press=null;
  function hit(event) {
    const rect=canvas.getBoundingClientRect();ndc.set((event.clientX-rect.left)/rect.width*2-1,-(event.clientY-rect.top)/rect.height*2+1);
    ray.setFromCamera(ndc,camera);
    return ray.intersectObject(model,true).some(h=>h.object.isMesh&&h.object.visible);
  }
  canvas.addEventListener('pointerdown',event=>{if(event.button===0)press={x:event.clientX,y:event.clientY};});
  canvas.addEventListener('pointerup',event=>{
    if(press&&Math.hypot(event.clientX-press.x,event.clientY-press.y)<12&&hit(event))activate();
    press=null;
  });
  canvas.addEventListener('pointercancel',()=>{press=null;});
  canvas.tabIndex=0;canvas.setAttribute('role','button');
  canvas.addEventListener('keydown',event=>{if((event.code==='Enter'||event.code==='Space')&&!event.repeat){event.preventDefault();activate();}});
  setPhase('closed');
  return {
    activate,
    get phase(){return phase;},get needsShadow(){return shadow;},get key(){return key;},get lid(){return lidPivot;},
    // Deterministic timeline access is useful for visual regression tests.
    seek(t){paths();manualTime=t;setPhase(t>=duration?'open':'opening');frameAt(Math.min(t,duration));force=true;},
    tick(now) {
      shadow=false;
      if(manualTime!==null){if(force){force=false;shadow=true;return true;}return false;}
      if(phase==='closed')return false;
      force=false;
      if(phase==='opening') {
        const t=(now-started)/1000*(reduceMotion?2.2:1);frameAt(Math.min(t,duration));shadow=t>=4.2;
        if(t>=duration){key.visible=false;setPhase('open');}
        return true;
      }
      if(phase==='closing') {
        const elapsed=Math.max(0,(now-started)/1000)*(reduceMotion?2.2:1);
        const angle=closeHinge(elapsed);
        lidPivot.rotation.x=-angle;
        haspPivot.rotation.x=-.35*clamp(angle/.28);
        lightLevel(smooth(clamp(angle/1.62)),elapsed);shadow=true;
        if(elapsed>=2.5){lidPivot.rotation.x=0;haspPivot.rotation.x=0;keyholeSlot.rotation.z=0;lightLevel(0,0);setPhase('closed');}
        return true;
      }
      if(phase==='open'){lightLevel(1,(now-started)/1000);return true;}
      return false;
    }
  };
}
