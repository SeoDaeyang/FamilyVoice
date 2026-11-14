import math, random
from PIL import Image, ImageDraw, ImageFilter
CREAM=(244,236,220); BLUE=(47,93,138); AMBER=(201,133,58); GREEN=(78,140,122); PLUM=(138,111,176)
WHITE=(255,255,255); DUSTY=(110,143,168); SAND=(176,154,116)
S=2048
bg=Image.new('RGBA',(S,S),CREAM+(255,))

def bez(p0,p1,p2,p3,n=500):
    return [((1-t)**3*p0[0]+3*(1-t)**2*t*p1[0]+3*(1-t)*t*t*p2[0]+t**3*p3[0],
             (1-t)**3*p0[1]+3*(1-t)**2*t*p1[1]+3*(1-t)*t*t*p2[1]+t**3*p3[1]) for t in [i/n for i in range(n+1)]]

def dotted(draw,pts,colors,w,dash,gap):
    seg=[0]
    for i in range(1,len(pts)): seg.append(seg[-1]+math.dist(pts[i-1],pts[i]))
    L=seg[-1]
    def at(x):
        j=next((k for k in range(1,len(seg)) if seg[k]>=x), len(seg)-1)
        r=(x-seg[j-1])/max(1e-6,seg[j]-seg[j-1])
        return (pts[j-1][0]+(pts[j][0]-pts[j-1][0])*r, pts[j-1][1]+(pts[j][1]-pts[j-1][1])*r)
    d=0
    while d<L:
        a,b=d,min(d+dash,L); c=colors[min(len(colors)-1,int(a/L*len(colors)))]
        pa,pb=at(a),at(b)
        draw.line([pa,pb],fill=c,width=w)
        for p in (pa,pb): draw.ellipse([p[0]-w/2,p[1]-w/2,p[0]+w/2,p[1]+w/2],fill=c)
        d+=dash+gap

# ── 그림 카드 내용 (사람 없는 단순한 풍경)
def scene_mountain(n):
    im=Image.new('RGB',(n,n),(236,190,140)); d=ImageDraw.Draw(im)
    d.ellipse([n*0.58,n*0.18,n*0.82,n*0.42],fill=(250,226,170))
    d.polygon([(0,n*0.78),(n*0.32,n*0.40),(n*0.62,n*0.78)],fill=(160,110,80))
    d.polygon([(n*0.30,n*0.80),(n*0.66,n*0.46),(n,n*0.80)],fill=(122,92,72))
    d.rectangle([0,n*0.78,n,n],fill=(96,80,70))
    d.polygon([(n*0.44,n),(n*0.50,n*0.80),(n*0.54,n*0.80),(n*0.64,n)],fill=(70,62,58))
    return im
def scene_sea(n):
    im=Image.new('RGB',(n,n),(205,224,236)); d=ImageDraw.Draw(im)
    d.rectangle([0,n*0.48,n,n],fill=(110,150,185))
    for k,y in enumerate([0.58,0.70,0.82]):
        pts=[(x, n*y+math.sin(x/n*math.pi*4+k)*n*0.025) for x in range(0,n+1,4)]
        d.line(pts,fill=(235,243,248),width=max(3,n//40))
    d.polygon([(0,n*0.92),(n,n*0.84),(n,n),(0,n)],fill=(236,222,196))
    return im
def waveform(n,color,seed,bars=11):
    im=Image.new('RGB',(n,n),color); d=ImageDraw.Draw(im)
    random.seed(seed); gap=n*0.84/bars; bw=gap*0.50; x0=n*0.08
    for k in range(bars):
        env=math.sin(math.pi*(k+0.5)/bars); hh=n*(0.20+env*(0.42+random.random()*0.30))
        x=x0+k*gap+(gap-bw)/2
        d.rounded_rectangle([x,(n-hh)/2,x+bw,(n+hh)/2],radius=bw/2,fill=WHITE)
    return im

def polaroid(content,size):
    pad=int(size*0.065); bottom=int(size*0.24); inner=size-2*pad
    card=Image.new('RGBA',(size,pad+inner+bottom),WHITE+(255,))
    card.paste(content.resize((inner,inner),Image.LANCZOS),(pad,pad))
    return card

def place(base,card,cx,cy,angle):
    rc=card.rotate(angle,resample=Image.BICUBIC,expand=True,fillcolor=(0,0,0,0))
    a=rc.split()[3]
    sh=Image.new('RGBA',rc.size,(40,30,20,0)); sh.putalpha(a.point(lambda v: 60 if v>0 else 0))
    sh=sh.filter(ImageFilter.GaussianBlur(22))
    base.alpha_composite(sh,(int(cx-rc.width/2+12),int(cy-rc.height/2+26)))
    base.alpha_composite(rc,(int(cx-rc.width/2),int(cy-rc.height/2)))


def route_layer(pts,colors,w,dash,gap,stops=()):
    l=Image.new('RGBA',(S,S)); d=ImageDraw.Draw(l)
    dotted(d,pts,colors,w,dash,gap)
    for p in stops:
        d.ellipse([p[0]-40,p[1]-40,p[0]+40,p[1]+40],fill=WHITE+(255,)); d.ellipse([p[0]-24,p[1]-24,p[0]+24,p[1]+24],fill=BLUE+(255,))
    return l


# 1) 오늘의 길 (맨 뒤): 왼쪽 아래 → 카드 묶음 뒤로 → 오른쪽 위, 경유지마다 색 바뀜
A=(150,1680); B=(1900,330)
leg1=bez((300,2150),(320,1980),(140,1880),A)
leg2=bez(A,(-40,1250),(700,1250),(1000,900))+bez((1000,900),(1300,560),(1600,700),B)[1:]
leg3=bez(B,(2120,180),(1720,120),(1860,-80))
bg.alpha_composite(route_layer(leg1,[BLUE+(255,)],34,52,40))
bg.alpha_composite(route_layer(leg2,[AMBER+(255,)],34,52,40))
bg.alpha_composite(route_layer(leg3,[GREEN+(255,)],34,52,40,stops=[A,B]))

# 2) 카드 묶음: 같은 각도로 한 방향(왼쪽 위 → 오른쪽 아래)으로 겹겹이
cards=[scene_mountain(700), waveform(700,DUSTY,3), scene_sea(700), waveform(700,BLUE,7)]
x,y=890,890; dx,dy=92,75
for i,c in enumerate(cards):
    place(bg,polaroid(c,1040),x+i*dx,y+i*dy,-6)

bg.convert('RGB').resize((1024,1024),Image.LANCZOS).save('docs/brand/cover_polaroid_1024.png'); print('ok')
