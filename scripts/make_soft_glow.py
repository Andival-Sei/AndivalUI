"""Original analytic soft glow for AndivalUI; no third-party pixels."""
import math
import struct
from pathlib import Path
W,H=128,64
out=bytearray(struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,W,H,32,40))
alphas=[]
for y in range(H):
    ny=2*y/(H-1)-1
    for x in range(W):
        nx=2*x/(W-1)-1
        # Compact smooth bell, with exactly zero alpha and zero slope at each edge.
        alpha=round(255*(max(0,1-nx*nx)**3)*(max(0,1-ny*ny)**3))
        alphas.append(alpha)
        out.extend((255,255,255,alpha))
assert max(alphas)>250
assert all(alphas[x]==0 and alphas[(H-1)*W+x]==0 for x in range(W))
assert all(alphas[y*W]==0 and alphas[y*W+W-1]==0 for y in range(H))
(Path(__file__).resolve().parent.parent/'Media'/'SoftGlow.tga').write_bytes(out)
print('SoftGlow: zero-alpha boundaries verified')
