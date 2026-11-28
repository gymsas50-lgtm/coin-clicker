import * as THREE from 'three';
import {RoundedBoxGeometry} from 'three/addons/geometries/RoundedBoxGeometry.js';
export function createGravityGun(camera){
 const gun=new THREE.Group();gun.name='Gravity manipulator';camera.add(gun);
 gun.position.set(.29,-.25,-.60);gun.rotation.set(.01,-.08,-.035);gun.scale.setScalar(.60);
 const mat=c=>new THREE.MeshBasicMaterial({color:c});
 const dark=mat(0x252b30),black=mat(0x151b20),steel=mat(0x7c8990),edge=mat(0xa8b1b2),orange=mat(0xa66a30),copper=mat(0xc69150),glow=mat(0xffba57),white=mat(0xffe5a1),grip=mat(0x41454a);
 function part(geometry,material,position){const m=new THREE.Mesh(geometry,material);m.position.set(...position);gun.add(m);return m;}
 const box=(size,pos,m,r=.015)=>part(new RoundedBoxGeometry(...size,2,r),m,pos);
 function tube(radius,length,pos,m,r2=radius){const o=part(new THREE.CylinderGeometry(radius,r2,length,24),m,pos);o.rotation.x=Math.PI/2;return o;}
 function ring(radius,thick,z,m){return part(new THREE.TorusGeometry(radius,thick,8,40),m,[0,.025,z]);}
 function rod(a,b,r,m){const p=new THREE.Vector3(...a),q=new THREE.Vector3(...b),d=q.clone().sub(p);const o=part(new THREE.CylinderGeometry(r,r,d.length(),10),m,p.clone().add(q).multiplyScalar(.5).toArray());o.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),d.normalize());return o;}
 function cable(points,r,m){part(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points.map(p=>new THREE.Vector3(...p))),28,r,7,false),m,[0,0,0]);}
 box([.26,.19,.46],[0,0,.12],dark,.035);box([.29,.085,.30],[0,.105,.17],steel,.018);
 box([.22,.11,.18],[0,-.075,.35],black,.025);tube(.088,.12,[0,.015,.39],steel);
 for(const side of [-1,1]){
  box([.018,.12,.24],[side*.137,.005,.15],orange,.008);
  for(let n=0;n<4;n++)box([.012,.045,.015],[side*.15,.018,.09+n*.043],black,.003);
  for(const z of [.025,.265])part(new THREE.SphereGeometry(.014,10,6),edge,[side*.151,.044,z]);
  rod([side*.16,.02,-.05],[side*.21,.04,-.35],.019,steel);
  cable([[side*.12,-.02,.30],[side*.22,-.11,.13],[side*.20,-.09,-.15],[side*.12,.01,-.32]],.015,black);
  cable([[side*.14,.08,.14],[side*.20,.16,.02],[side*.19,.14,-.23],[side*.13,.06,-.35]],.009,copper);
 }
 tube(.12,.25,[0,.025,-.17],black);
 for(let i=0;i<9;i++)ring(.109,.010,-.065-i*.025,i%2?copper:glow);
 tube(.15,.065,[0,.025,-.34],steel);ring(.15,.014,-.375,black);ring(.119,.012,-.386,glow);
 tube(.074,.035,[0,.025,-.40],orange);tube(.047,.04,[0,.025,-.425],white);
 const prongs=[];
 for(let i=0;i<3;i++){
  const angle=i*Math.PI*2/3+Math.PI/2,c=Math.cos(angle),s=Math.sin(angle),cy=.025;
  const p=new THREE.Group();gun.add(p);prongs.push(p);
  const a=[c*.135,cy+s*.135,-.31],b=[c*.24,cy+s*.24,-.51],d=[c*.18,cy+s*.18,-.76];
  rod(a,b,.033,dark);rod(a.map((v,j)=>j===2?v-.008:v),b,.018,edge);
  rod(b,d,.027,steel);part(new THREE.SphereGeometry(.043,12,8),orange,b);
  rod([c*.18,cy+s*.18,-.71],[c*.12,cy+s*.12,-.80],.025,copper);
  part(new THREE.SphereGeometry(.028,12,8),glow,[c*.12,cy+s*.12,-.805]);
 }
 const handle=box([.105,.24,.13],[0,-.195,.20],grip,.02);handle.rotation.x=-.26;
 for(let i=0;i<5;i++){const band=box([.11,.012,.11],[0,-.13-i*.033,.21-i*.008],black,.003);band.rotation.x=-.26;}
 box([.07,.14,.065],[0,-.14,.065],black,.01);box([.08,.035,.17],[0,-.21,.10],steel,.012);
 // A compact display and protected indicator, all unlit to preserve the simple room rendering.
 const display=box([.09,.015,.09],[0,.155,.18],black,.007);display.rotation.x=-.10;
 for(let i=0;i<3;i++)box([.018,.008,.05],[-.025+i*.025,.165,.18],glow,.002);
 box([.09,.08,.23],[.015,-.34,.43],grip,.025);box([.13,.095,.14],[.01,-.27,.31],mat(0x8a7765),.025);
 let recoil=0,retract=0;
 return {gun,kick(){recoil=.08;},update(dt,blocked,holding){recoil*=Math.exp(-13*dt);retract=THREE.MathUtils.damp(retract,blocked,13,dt);gun.position.set(.29,-.25-retract*.14,-.60+retract*.70+recoil);gun.rotation.x=.01-retract*.70;white.color.setHex(holding?0xffefd0:0xffdfa1);},muzzle(target){gun.updateWorldMatrix(true,false);return target.set(0,.025,-.81).applyMatrix4(gun.matrixWorld);}};
}
