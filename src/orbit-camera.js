import * as THREE from 'three';
export function createOrbitCamera(canvas) {
  let yaw=0,pitch=0,zoom=1,smoothYaw=0,smoothPitch=0,smoothZoom=1;
  const pointers=new Map(),spherical=new THREE.Spherical();
  const clamp=THREE.MathUtils.clamp;
  function distance(){const p=[...pointers.values()];return p.length===2?Math.hypot(p[0].x-p[1].x,p[0].y-p[1].y):0;}
  const reset=()=>{yaw=0;pitch=0;zoom=1;pointers.clear();canvas.style.cursor='grab';};
  canvas.style.cursor='grab';
  canvas.addEventListener('pointerdown',e=>{
    if(e.pointerType==='mouse'&&e.button!==0&&e.button!==2)return;
    e.preventDefault();canvas.setPointerCapture(e.pointerId);pointers.set(e.pointerId,{x:e.clientX,y:e.clientY});canvas.style.cursor='grabbing';
  });
  canvas.addEventListener('pointermove',e=>{
    const old=pointers.get(e.pointerId);if(!old)return;
    const previousDistance=distance(),dx=e.clientX-old.x,dy=e.clientY-old.y;
    pointers.set(e.pointerId,{x:e.clientX,y:e.clientY});
    if(pointers.size===1){yaw-=dx*.006;pitch=clamp(pitch+dy*.005,-.95,.65);}
    else if(pointers.size===2){const nextDistance=distance();if(previousDistance>1&&nextDistance>1)zoom=clamp(zoom*previousDistance/nextDistance,.5,1.9);}
  });
  function release(e){pointers.delete(e.pointerId);canvas.style.cursor=pointers.size?'grabbing':'grab';}
  canvas.addEventListener('pointerup',release);canvas.addEventListener('pointercancel',release);canvas.addEventListener('lostpointercapture',release);
  canvas.addEventListener('contextmenu',e=>e.preventDefault());
  canvas.addEventListener('wheel',e=>{e.preventDefault();const amount=e.deltaY*(e.deltaMode===1?16:e.deltaMode===2?innerHeight:1);zoom=clamp(zoom*Math.exp(amount*.001),.5,1.9);},{passive:false});
  canvas.addEventListener('dblclick',e=>{e.preventDefault();reset();});
  addEventListener('blur',()=>{pointers.clear();canvas.style.cursor='grab';});
  return {reset,get state(){return {yaw,pitch,zoom,dragging:pointers.size>0};},get free(){return Math.abs(yaw)>.001||Math.abs(pitch)>.001;},apply(offset,dt){
    const blend=1-Math.exp(-18*dt);smoothYaw+=(yaw-smoothYaw)*blend;smoothPitch+=(pitch-smoothPitch)*blend;smoothZoom+=(zoom-smoothZoom)*blend;
    spherical.setFromVector3(offset);spherical.theta+=smoothYaw;spherical.phi=clamp(spherical.phi+smoothPitch,.18,1.42);spherical.radius*=smoothZoom;offset.setFromSpherical(spherical);return offset;
  }};
}
