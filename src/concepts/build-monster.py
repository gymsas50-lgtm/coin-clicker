import numpy as np,json
from skimage.measure import marching_cubes
x=np.linspace(-.5,.5,71);y=np.linspace(-.06,2.6,175);z=np.linspace(-.62,.62,85);X,Y,Z=np.meshgrid(x,y,z,indexing='ij');f=np.ones(X.shape)*10
# Connected implicit skin, smooth unions, no interpenetrating separate meshes.
parts=[(0,1.47,0,.13,.40,.23),(0,1.88,0,.075,.22,.09),(0,2.17,.025,.12,.25,.145),(0,1.70,-.23,.09,.13,.12),(0,1.70,.23,.09,.13,.12),(0,1.42,-.31,.064,.34,.07),(0,1.42,.31,.064,.34,.07),(-.015,.91,-.37,.046,.29,.052),(-.015,.91,.37,.046,.29,.052),(-.01,.59,-.385,.047,.12,.062),(-.01,.59,.385,.047,.12,.062),(0,.93,-.12,.075,.3,.085),(0,.93,.12,.075,.3,.085),(0,.42,-.14,.054,.37,.06),(0,.42,.14,.054,.37,.06),(-.045,.065,-.14,.12,.06,.065),(-.045,.065,.14,.12,.06,.065)]
for a,b,c,rx,ry,rz in parts:
 d=(np.sqrt(((X-a)/rx)**2+((Y-b)/ry)**2+((Z-c)/rz)**2)-1)*min(rx,ry,rz)
 k=.055;h=np.maximum(k-np.abs(f-d),0)/k;f=np.minimum(f,d)-h*h*k*.25
v,faces,n,_=marching_cubes(f,0,spacing=(x[1]-x[0],y[1]-y[0],z[1]-z[0]),step_size=2);v+=np.array([x[0],y[0],z[0]])
open('monster-mesh.json','w').write(json.dumps({'vertices':v.flatten().tolist(),'indices':faces.flatten().tolist()}))
print(len(v),'vertices',len(faces),'triangles')
