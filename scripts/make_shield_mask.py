import struct
from pathlib import Path
S=256
p=[(.15,.16),(.27,.13),(.5,.10),(.73,.13),(.85,.16),(.80,.67),(.68,.78),(.5,.90),(.32,.78),(.20,.67)]
def inside(x,y):
 c=False
 for i in range(len(p)):
  a,b=p[i],p[i-1]
  if (a[1]>y)!=(b[1]>y) and x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]: c=not c
 return c
out=bytearray(struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,S,S,32,40))
for y in range(S):
 for x in range(S):
  a=sum(inside((x+(i+.5)/4)/S,(y+(j+.5)/4)/S) for i in range(4) for j in range(4))
  out.extend((255,255,255,round(a*255/16)))
(Path(__file__).resolve().parent.parent / 'Media' / 'ShieldInsetMask.tga').write_bytes(out)
