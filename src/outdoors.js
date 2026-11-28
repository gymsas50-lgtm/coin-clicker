import * as THREE from 'three';
import * as CANNON from 'cannon-es';
export function createOutdoors({scene,world,renderer}){
 scene.background=new THREE.Color(0xc7e3f1);scene.fog=new THREE.Fog(0xc7e3f1,170,850);
 const sky=new THREE.Mesh(new THREE.SphereGeometry(1800,32,24),new THREE.ShaderMaterial({
  side:THREE.BackSide,depthWrite:false,depthTest:false,toneMapped:false,
  uniforms:{zenith:{value:new THREE.Color(0x2867c5)},upperSky:{value:new THREE.Color(0x589fe4)},lowerSky:{value:new THREE.Color(0xa2d7ef)},horizon:{value:new THREE.Color(0xf3dfce)},sunDirection:{value:new THREE.Vector3(-9,15,7).normalize()}},
  vertexShader:`varying vec3 vDirection;
   void main(){vDirection=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}`,
  fragmentShader:`uniform vec3 zenith;uniform vec3 upperSky;uniform vec3 lowerSky;uniform vec3 horizon;uniform vec3 sunDirection;varying vec3 vDirection;
   void main(){
    vec3 direction=normalize(vDirection);float h=max(direction.y,0.0);
    vec3 color=mix(horizon,lowerSky,smoothstep(0.0,0.16,h));
    color=mix(color,upperSky,smoothstep(0.10,0.55,h));
    color=mix(color,zenith,smoothstep(0.40,1.0,h));
    float facing=max(dot(direction,sunDirection),0.0);
    float halo=pow(facing,18.0)*0.20+pow(facing,100.0)*0.13;
    color=mix(color,vec3(1.0,0.88,0.68),halo);
    float disc=smoothstep(0.99965,0.99985,facing);
    color=mix(color,vec3(1.0,0.96,0.83),disc*0.92);
    // Tiny screen-space dither avoids visible bands across the smooth gradient.
    float noise=fract(sin(dot(gl_FragCoord.xy,vec2(12.9898,78.233)))*43758.5453)-0.5;
    gl_FragColor=vec4(color+noise/512.0,1.0);
    #include <colorspace_fragment>
   }`
 }));
 sky.name='Gradient sky';sky.frustumCulled=false;sky.renderOrder=-10000;scene.add(sky);
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
