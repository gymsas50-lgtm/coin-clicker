from pathlib import Path
import numpy as np,json
from skimage.measure import marching_cubes
step=.014
origin=np.array([-.34,-.19,-.39]);end=np.array([.35,.25,.17]);dims=np.ceil((end-origin)/step).astype(int)+1
x,y,z=np.meshgrid(*[origin[i]+np.arange(dims[i])*step for i in range(3)],indexing='ij')
def box(center,size,r=.012):
 q=[np.abs(v-c)-(s/2-r) for v,c,s in zip([x,y,z],center,size)]
 return np.sqrt(sum(np.maximum(a,0)**2 for a in q))+np.minimum(np.maximum.reduce(q),0)-r
def cyl(cx,cy,cz,r,depth):
 a=np.sqrt((x-cx)**2+(y-cy)**2)-r;b=np.abs(z-cz)-depth/2
 return np.minimum(np.maximum(a,b),0)+np.sqrt(np.maximum(a,0)**2+np.maximum(b,0)**2)
def blend(a,b,k=.009):
 h=np.maximum(k-np.abs(a-b),0)/k
 return np.minimum(a,b)-h*h*k*.25
s=box((0,0,0),(.53,.31,.215),.025)
for shape in [box((.245,-.008,-.01),(.14,.31,.25),.028),box((-.025,.162,.0),(.18,.09,.19),.018),cyl(-.06,-.012,-.216,.13,.22),cyl(-.06,-.012,-.311,.139,.065)]:s=blend(s,shape)
# Controls are shallow relief fused directly into the shell.
for yy in [.055,.007,-.041]:s=blend(s,cyl(.172,yy,.107,.012,.012),.004)
s=blend(s,cyl(.172,-.09,.108,.03,.014),.004)
# Recessed rear display and lens well, cut into the same closed shell.
s=np.maximum(s,-box((-.07,-.018,.119),(.302,.215,.036),.012))
s=np.maximum(s,-cyl(-.06,-.012,-.355,.11,.042))
verts,faces,_,_=marching_cubes(s,level=0,spacing=(step,step,step),allow_degenerate=False)
verts+=origin
# Check that the actual triangle surface is one connected component.
parent=list(range(len(verts)))
def root(i):
 while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
 return i
for a,b,c in faces:
 ra=root(int(a))
 for t in [b,c]:parent[root(int(t))]=ra
components=len({root(i) for i in range(len(verts))});assert components==1,components
edges=np.sort(np.concatenate([faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]]]),axis=1)
_,counts=np.unique(edges,axis=0,return_counts=True);assert np.all(counts==2),'Not watertight'
# Shared indexed mesh. UVs use baked rear/front panels, no detached geometry.
uv=[]
for vx,vy,vz in verts:
 if vz>.075:
  u=np.clip((vx+.34)/.69,0,1);v=np.clip((vy+.19)/.44,0,1);uv.append([u*.5, .5+v*.5])
 elif vz<-.28:
  u=np.clip((vx+.205)/.29,0,1);v=np.clip((vy+.157)/.29,0,1);uv.append([.5+u*.5,.5+v*.5])
 else:
  u=(vx+.34)/.69;v=(vy+.19)/.44;uv.append([u*.5,v*.5])
data={'positions':np.round(verts.flatten(),6).tolist(),'indices':faces.flatten().tolist(),'uv':np.round(np.array(uv).flatten(),6).tolist()}
Path('/home/user/camera-project/solid-camera-data.js').write_text('const SOLID_CAMERA_DATA='+json.dumps(data,separators=(',',':'))+';')
print('PASS single connected watertight surface:',len(verts),'vertices,',len(faces),'triangles')
