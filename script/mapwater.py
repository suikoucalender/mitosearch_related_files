import sys
from staticmap import StaticMap
baser=[150,129,142,135,123]
baseg=[200,170,189,179,162]
baseb=[219,182,205,193,172]
map = StaticMap(50, 50) #, url_template='http://a.tile.openstreetmap.org/{z}/{x}/{y}.png')
img = map.render(zoom=17, center=[float(sys.argv[1]), float(sys.argv[2])])
pixelSizeTuple = img.size
water = 0
minsum = 255*255*3
minr=0
ming=0
minb=0
for i in range(pixelSizeTuple[0]):
 for j in range(pixelSizeTuple[1]):
  r,g,b = img.getpixel((i,j))
  for k in range(len(baser)):
   tempsum = (r-baser[k])*(r-baser[k])+(g-baseg[k])*(g-baseg[k])+(b-baseb[k])*(b-baseb[k])
   if (tempsum == 0):
    water = 1
   elif tempsum < minsum:
    minsum = tempsum
    minr=r
    ming=g
    minb=b

if water == 1:
 print(water)
else:
 print(str(water)+" "+str(minsum)+" "+str(minr)+","+str(ming)+","+str(minb))

#img.save('img_'+sys.argv[2]+'_'+sys.argv[1]+'.png')

