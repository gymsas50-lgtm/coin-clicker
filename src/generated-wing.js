// Rebuild the ENTIRE interior: twelve new rooms, no legacy geometry or colliders.
building.clear();propColliders.length=0;furnitureNames.length=0;roomLayouts.length=0;apartmentDoors.length=0;doorPanels.length=0;
const generatedRows=[];let generatedBackZ=7.1;const range=(a,b)=>a+Math.random()*(b-a);
function fullDoorway(z,centers,material){let start=-6.2;for(const c of centers){if(c-.7>start)buildingBox('Generated transverse wall',(start+c-.7)/2,1.7,z,c-.7-start,3.4,.2,material,true);buildingBox('Generated door header',c,2.975,z,1.4,.85,.2,material);for(const side of[-1,1])buildingBox('Generated door jamb',c+side*.7,1.275,z,.08,2.55,.3,trimMat);buildingBox('Matching doorway top jamb',c,2.55,z,1.48,.08,.3,trimMat);addApartmentDoor(z===7.1?'Entrance door':'Room door',c-.7,z,0);start=c+.7;}if(start<6.2)buildingBox('Generated transverse wall',(start+6.2)/2,1.7,z,6.2-start,3.4,.2,material,true);}
fullDoorway(7.1,[-1.5],wallA);
const generatedFurnitureChecks=[];
for(let row=0;row<6;row++){const front=generatedBackZ,depth=range(5.8,9.8),back=front-depth,split=(row===0?1:row%2===0?-1:1)*range(.65,1.2),mid=(front+back)/2;
if(row>0)fullDoorway(front,row%2===1?[-3]:[-3,3],row%2?wallA:wallB);
buildingBox('Generated floor',0,-.1,mid,12.4,.2,depth,row%2?floorA:floorB);buildingBox('Generated ceiling',0,3.5,mid,12.4,.2,depth,ceilingMat);for(const x of[-6.1,6.1])buildingBox('Generated outer wall',x,1.7,mid,.2,3.4,depth,row%2?wallA:wallB,true);
crossPartition(split,back,front,mid,wallA);buildingBox('Matching doorway top jamb',split,2.55,mid,.3,.08,1.48,trimMat);addApartmentDoor('Connecting room door',split,mid-.7,-Math.PI/2);
for(const side of[-1,1]){const minX=side<0?-6:split,maxX=side<0?split:6,inner=split+side*.95,outer=side*5.4;const room={name:'Room '+(roomLayouts.length+1),minX,maxX,minZ:back+.1,maxZ:front-.1,generated:true,area:(maxX-minX)*(depth-.2),deadEnd:side>0&&(row===0||row===5)};roomLayouts.push(room);
// Furniture only occupies reserved wall bays, never the three doorway corridors.
const before=new Set(building.children),variant=Math.floor(Math.random()*3);
if(variant===0){bed(side*4.95,mid);table(side*5.4,mid+1.75,.65,.65,.6);}else if(variant===1){desk(side*5.55,mid,side<0?-Math.PI/2:Math.PI/2);chair(side*4.1,mid,side<0?Math.PI/2:-Math.PI/2);}else{sofa(side*5.45,mid,side<0?-Math.PI/2:Math.PI/2);table(side*3.7,mid,1.05,.7,.48);}
bookcase(inner,back+.42,Math.PI);pottedPlant(outer,front-.7);
for(const o of building.children)if(!before.has(o)){o.updateMatrixWorld(true);const b=new THREE.Box3().setFromObject(o);generatedFurnitureChecks.push({name:o.name,room:room.name,min:b.min.clone(),max:b.max.clone(),inside:b.min.x>=minX+.02&&b.max.x<=maxX-.02&&b.min.z>=back+.12&&b.max.z<=front-.12});}
}
generatedRows.push({front,back,split});generatedBackZ=back;}
buildingBox('Generated back exterior wall',0,1.7,generatedBackZ,12.4,3.4,.2,wallB,true);
// Continuous matching trim: generated from actual walls, never across an opening.
for(const wall of [...building.children]){if(!wall.isMesh||!(wall.material===wallA||wall.material===wallB))continue;const p=wall.geometry.parameters;if(!p.width||p.height<3)continue;const alongX=p.width>p.depth,len=alongX?p.width:p.depth;for(const side of[-1,1]){const x=wall.position.x+(alongX?0:side*(p.width/2+.03)),z=wall.position.z+(alongX?side*(p.depth/2+.03):0);buildingBox('Generated floor trim',x,.075,z,alongX?len:.06,.15,alongX?.06:len,trimMat);buildingBox('Generated ceiling trim',x,3.315,z,alongX?len:.075,.13,alongX?.075:len,frameMat);}}
building.userData.rooms=roomLayouts;

