import * as THREE from 'three';

export function createChestOpening({scene,model,camera,renderer,lidPivot,haspPivot,keyholeSlot,reduceMotion}) {
  const canvas=renderer.domElement;
  const duration=6.9;
  let phase='closed',started=0,lastDraw=-Infinity,force=true,shadow=true,closingAngle=0;
  let manualTime=null;
  const gold=new THREE.MeshStandardMaterial({color:0xc99a49,metalness:.88,roughness:.27,transparent:true});
  const polished=new THREE.MeshStandardMaterial({color:0xf1cd82,metalness:.95,roughness:.21,transparent:true});
  const darkGold=new THREE.MeshStandardMaterial({color:0x6f4a21,metalness:.72,roughness:.42,transparent:true});
  const key=new THREE.Group();key.name='Animated skeleton key';scene.add(key);key.visible=false;
  function mesh(geo,mat,pos) {
    const m=new THREE.Mesh(geo,mat);m.position.set(...pos);m.castShadow=true;m.renderOrder=40;key.add(m);return m;
  }
  function rod(radius,len,z,mat=gold) {
    const m=mesh(new THREE.CylinderGeometry(radius,radius,len,24),mat,[0,0,z]);m.rotation.x=Math.PI/2;return m;
  }
  // The origin is the very tip: insertion and shaft rotation stay physically aligned.
  rod(.037,.94,.47);
  rod(.061,.07,.83,polished);rod(.052,.04,.90,darkGold);
  const bow=mesh(new THREE.TorusGeometry(.235,.048,12,48),gold,[0,0,1.16]);bow.scale.set(1,.9,1);
  const inner=mesh(new THREE.TorusGeometry(.147,.012,8,40),polished,[0,0,1.16]);inner.scale.y=.9;
  for(const x of [-1,1]) {
    const flourish=mesh(new THREE.TorusGeometry(.079,.019,8,24,Math.PI*1.45),gold,[x*.15,.115,1.16]);
    flourish.rotation.z=x<0?.3:1.8;
  }
  mesh(new THREE.SphereGeometry(.065,16,12),polished,[0,0,.94]);
  for(const [z,w] of [[.09,.13],[.23,.105],[.33,.15]]) {
    const tooth=mesh(new THREE.BoxGeometry(w,.07,.065),gold,[w*.40,0,z]);
    mesh(new THREE.BoxGeometry(.035,.078,.035),polished,[w-.03,0,z]);
  }
  const glint=mesh(new THREE.SphereGeometry(.018,12,8),polished,[-.12,.13,1.20]);
  const lockRing=new THREE.Mesh(new THREE.TorusGeometry(.075,.012,8,32),gold.clone());
  lockRing.position.set(0,.19,1.324);model.add(lockRing);
  const lockCenter=new THREE.Vector3(0,.19,1.33);
  const target=new THREE.Vector3(),outside=new THREE.Vector3(),hero=new THREE.Vector3();
  let flyIn,approach;
  const qStart=new THREE.Quaternion().setFromEuler(new THREE.Euler(.5,-.9,-.4));
  const qHero=new THREE.Quaternion().setFromEuler(new THREE.Euler(.15,.24,-.18));
  const qAligned=new THREE.Quaternion();
  const up=new THREE.Vector3(),right=new THREE.Vector3();
  function screenPoint(x,y,distance) {
    camera.updateMatrixWorld();
    return new THREE.Vector3(x,y,.5).unproject(camera).sub(camera.position).normalize().multiplyScalar(distance).add(camera.position);
  }
  function paths() {
    model.updateMatrixWorld(true);model.localToWorld(target.copy(lockCenter));
    outside.copy(target).add(new THREE.Vector3(0,0,1.13));
    hero.copy(screenPoint(.12,-.05,7.5));
    up.set(0,1,0).applyQuaternion(camera.quaternion);right.set(1,0,0).applyQuaternion(camera.quaternion);
    const from=screenPoint(.15,-1.65,7.5);
    flyIn=new THREE.CubicBezierCurve3(from,from.clone().addScaledVector(up,2.6).addScaledVector(right,.65),hero.clone().addScaledVector(right,.45).addScaledVector(up,.25),hero);
    approach=new THREE.CubicBezierCurve3(hero,hero.clone().addScaledVector(right,-.7).addScaledVector(up,.5),outside.clone().add(new THREE.Vector3(.55,.45,.7)),outside);
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
      const k=easeOut(segment(t,0,.95));key.position.copy(flyIn.getPoint(k));key.quaternion.copy(qStart).slerp(qHero,k);scale=1.45;
    } else if(t<1.35) {
      const k=segment(t,.95,1.35);key.position.copy(hero).addScaledVector(up,Math.sin(k*Math.PI)*.055);
      key.quaternion.copy(qHero);scale=1.45;
    } else if(t<2.65) {
      const k=smoother(segment(t,1.35,2.65));key.position.copy(approach.getPoint(k));key.quaternion.copy(qHero).slerp(qAligned,k);scale=THREE.MathUtils.lerp(1.45,1,k);
    } else {
      const inserted=smoother(segment(t,2.65,3.2));key.position.copy(outside).lerp(target.clone().add(new THREE.Vector3(0,0,-.17)),inserted);
      const turn=smoother(segment(t,3.35,4.2));key.quaternion.setFromAxisAngle(new THREE.Vector3(0,0,1),turn*Math.PI*.5);
      keyholeSlot.rotation.z=-turn*Math.PI*.5;
      if(t>4.55) key.position.z+=smooth(segment(t,4.55,5.12))*.8;
      if(t>4.95) key.position.addScaledVector(up,-smooth(segment(t,4.95,5.55))*.7);
    }
    key.scale.setScalar(scale);
    key.visible=t<5.55;
    const opacity=1-smooth(segment(t,5.02,5.55));
    for(const mat of [gold,polished,darkGold]) {mat.opacity=opacity;mat.depthTest=t>=2.65;}
    // The heavy lid moves only after the key is turned and the hasp clears the catch.
    haspPivot.rotation.x=-smooth(segment(t,4.2,4.65))*.35;
    const opening=smoother(segment(t,5.08,6.85));
    lidPivot.rotation.x=-opening*1.62;
    lightLevel(smooth(segment(t,5.35,6.7)),t);
  }
  function setPhase(next) {
    phase=next;canvas.dataset.state=phase;
    canvas.setAttribute('aria-label',phase==='open'?'Открытый сундук. Нажми, чтобы закрыть.':'Старый сундук. Нажми, чтобы открыть ключом.');
    canvas.style.cursor=(phase==='opening'||phase==='closing')?'wait':'pointer';
  }
  function activate() {
    if(phase==='opening'||phase==='closing')return;
    manualTime=null;started=performance.now();lastDraw=-Infinity;force=true;
    if(phase==='closed') {paths();setPhase('opening');key.visible=true;}
    else {closingAngle=lidPivot.rotation.x;key.visible=false;setPhase('closing');}
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
      if(now-lastDraw<1000/30&&!force)return false;
      force=false;lastDraw=now;
      if(phase==='opening') {
        const t=(now-started)/1000*(reduceMotion?2.2:1);frameAt(Math.min(t,duration));shadow=true;
        if(t>=duration){key.visible=false;setPhase('open');}
        return true;
      }
      if(phase==='closing') {
        const t=clamp((now-started)/(reduceMotion?350:1100));
        lidPivot.rotation.x=THREE.MathUtils.lerp(closingAngle,0,smoother(t));
        haspPivot.rotation.x=-.35*(1-smooth(segment(t,.55,1)));
        lightLevel(1-smooth(t),(now-started)/1000);shadow=true;
        if(t>=1){lidPivot.rotation.x=0;haspPivot.rotation.x=0;keyholeSlot.rotation.z=0;lightLevel(0,0);setPhase('closed');}
        return true;
      }
      if(phase==='open'){lightLevel(1,(now-started)/1000);return true;}
      return false;
    }
  };
}
