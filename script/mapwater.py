import sys
import math
from staticmap import StaticMap

#この関数は半分くらいは正しい場所を開いてくれる感じだけど100%ではなさそう
def latlon_to_tile(lat, lon, zoom):
    lat_rad = math.radians(lat)
    n = 2.0 ** zoom
    x_tile = int((lon + 180.0) / 360.0 * n)
    y_tile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
    return str(x_tile)+"/"+str(y_tile)

#baser=[150,129,142,135,123]
#baseg=[200,170,189,179,162]
#baseb=[219,182,205,193,172]
baser=[191,189,160,209]
baseg=[217,214,200,226]
baseb=[242,234,240,241]
#map = StaticMap(50, 50) #, url_template='http://a.tile.openstreetmap.org/{z}/{x}/{y}.png')
#map = StaticMap(50, 50, url_template='https://tile.openstreetmap.org/{z}/{x}/{y}.png')
server='https://tile.openstreetmap.jp'
map = StaticMap(50, 50, url_template=server+'/{z}/{x}/{y}.png')
img = map.render(zoom=17, center=[float(sys.argv[1]), float(sys.argv[2])]) #lat, long
img.save("/tmp/x"+sys.argv[1]+"y"+sys.argv[2]+".png")

pixelSizeTuple = img.size
water = 0
minsum = 255*255*3
minr=0
ming=0
minb=0
for i in range(pixelSizeTuple[0]):
 if water == 1:
  break
 for j in range(pixelSizeTuple[1]):
  if water == 1:
   break
  r,g,b = img.getpixel((i,j))
  for k in range(len(baser)):
   tempsum = (r-baser[k])*(r-baser[k])+(g-baseg[k])*(g-baseg[k])+(b-baseb[k])*(b-baseb[k])
   if (tempsum == 0):
    water = 1
    minr=r
    ming=g
    minb=b
    minsum=0
    break
   elif tempsum < minsum:
    minsum = tempsum
    minr=r
    ming=g
    minb=b

#デバッグする場合、SRRXXX:7.25719 80.56480    0 1846 248,244,240 https://tile.openstreetmap.jp/17/68178/13495.pngなどと出るので
#まずはgoogle mapに7.25719 80.56480を張り付ける。そうすると、7°15'25.9"N 80°33'53.3"Eなどに返変換されるから、https://www.openstreetmap.org/ に張り付けてみる
#このスクリプトで見ているサーバとは違うから厳密に同じではない可能性があるけど、google mapよりは近いものが見れていると思う
if water == 1 or minsum < 13:
 print(str(1)+" "+str(minsum)+" "+str(minr)+","+str(ming)+","+str(minb)+" "+server+"/17/"+latlon_to_tile(float(sys.argv[1]), float(sys.argv[2]), 17)+".png")
else:
 print(str(water)+" "+str(minsum)+" "+str(minr)+","+str(ming)+","+str(minb)+" "+server+"/17/"+latlon_to_tile(float(sys.argv[1]), float(sys.argv[2]), 17)+".png")
