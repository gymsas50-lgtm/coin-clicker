import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createOutdoors({scene,world,renderer}){
 scene.background=new THREE.Color(0xc7e3f1);scene.fog=new THREE.Fog(0xc7e3f1,170,850);
 const sky=new THREE.Mesh(new THREE.SphereGeometry(1800,24,16),new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,uniforms:{top:{value:new THREE.Color(0x5b9edc)},bottom:{value:new THREE.Color(0xd5eaf2)}},vertexShader:'varying vec3 vDirection;void main(){vDirection=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}',fragmentShader:'uniform vec3 top;uniform vec3 bottom;varying vec3 vDirection;void main(){float h=clamp(normalize(vDirection).y,0.0,1.0);gl_FragColor=vec4(mix(bottom,top,pow(h,0.65)),1.0);#include <tonemapping_fragment>\n#include <colorspace_fragment>\n}'}));
 // Shader includes must begin on a new line.
 sky.material.fragmentShader=sky.material.fragmentShader.replace(';#include',';\n#include');sky.frustumCulled=false;sky.renderOrder=-10000;sky.material.depthTest=false;scene.add(sky);
 const canvas=document.createElement('canvas');canvas.width=canvas.height=256;const ctx=canvas.getContext('2d');ctx.fillStyle='#3e5d2c';ctx.fillRect(0,0,256,256);
 let seed=7341;function random(){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;}
 const colors=['#365326','#506e36','#41612e','#5b7a40','#304d23','#476632'];
 for(let i=0;i<18000;i++){const x=random()*256,y=random()*256;ctx.strokeStyle=colors[Math.floor(random()*colors.length)];ctx.lineWidth=.6+random()*.8;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+(random()-.5)*3,y-1-random()*4);ctx.stroke();}
 const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;texture.wrapS=texture.wrapT=THREE.RepeatWrapping;texture.repeat.set(6.25,6.25);texture.anisotropy=Math.min(8,renderer.capabilities.getMaxAnisotropy());
 const ground=new THREE.Mesh(new THREE.PlaneGeometry(25,25),new THREE.MeshStandardMaterial({map:texture,roughness:1,metalness:0}));ground.rotation.x=-Math.PI/2;ground.receiveShadow=true;ground.name='Grass field';scene.add(ground);
 const floor=new CANNON.Body({mass:0,shape:new CANNON.Box(new CANNON.Vec3(12.5,.5,12.5))});floor.position.y=-.5;world.addBody(floor);
 scene.add(new THREE.HemisphereLight(0xe1efff,0x718248,1.65));
 const sun=new THREE.DirectionalLight(0xffefd3,2.8);sun.position.set(-9,15,7);sun.castShadow=true;sun.shadow.mapSize.set(1024,1024);Object.assign(sun.shadow.camera,{left:-15,right:15,top:15,bottom:-15,near:.5,far:55});sun.shadow.normalBias=.018;sun.shadow.bias=-.00015;sun.shadow.radius=3;scene.add(sun,sun.target);
 const offset=new THREE.Vector3(-9,15,7);
 return{ground,sky,floor,sun,tick(camera){sky.position.copy(camera.position);sun.position.copy(camera.position).add(offset);sun.target.position.set(camera.position.x,0,camera.position.z);}};
}
