from pathlib import Path
import json,html,re
R=Path(__file__).resolve().parents[1]
BG='#25292e';PANEL='#1b1e22';LINE='#52585e';INK='#eeeeea';MUTED='#9ba1a4';ACCENT='#aa8bd1'
assets=[]
def rect(x,y,w,h,c,stroke='none',extra=''):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" stroke="{stroke}" {extra}/>'
def text(x,y,s,size=16,c=INK,anchor='start'):return f'<text x="{x}" y="{y}" font-family="Menlo,monospace" font-size="{size}" fill="{c}" text-anchor="{anchor}">{html.escape(str(s))}</text>'
def panel(x,y,w,h):return rect(x+.5,y+.5,w-1,h-1,PANEL,LINE)
def save(name,w,h,s,kind='asset'):
 (R/name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{s}</svg>')
 assets.append({'file':name,'width':w,'height':h,'type':kind})
def button(x,y,label,w=280,state='normal'):
 styles={'normal':(BG,LINE,INK),'hover':('#373d43','#9ba1a4',INK),'focus':(INK,INK,BG),'pressed':('#bebfbb','#bebfbb',BG),'disabled':('#22262b','#373d43','#666d73')}
 fill,border,fg=styles[state]
 return rect(x+.5,y+.5,w-1,43,fill,border)+text(x+w/2,y+28,label,15,fg,'middle')
def toggle(x,y,on):return rect(x+.5,y+.5,43,23,INK if on else PANEL,LINE)+rect(x+25 if on else x+4,y+4,15,16,BG if on else MUTED)
def slider(x,y,value,w=240):return rect(x,y+10,w,4,LINE)+rect(x,y+10,w*value,4,INK)+rect(x+w*value-5,y+3,10,18,INK)
def mark(x,y):return ''.join(rect(x+a*16,y+b*16,14,14,ACCENT) for a,b in [(1,0),(0,1),(1,1),(2,1)])
icons={
 'pause':rect(6,5,4,14,INK)+rect(14,5,4,14,INK),
 'play':'<path d="M7 4L20 12 7 20Z" fill="currentColor"/>',
 'sound':'<path d="M3 9H7L12 5V19L7 15H3ZM16 7Q23 12 16 17"/>',
 'mute':'<path d="M3 9H7L12 5V19L7 15H3ZM16 9L22 15M22 9L16 15"/>',
 'back':'<path d="M11 5L4 12 11 19M4 12H21"/>',
 'close':'<path d="M6 6L18 18M18 6L6 18"/>',
 'restart':'<path d="M5 9A8 8 0 1 1 5 16M5 3V9H11"/>',
 'settings':'<path d="M3 7H21M3 17H21M8 3V11M16 13V21"/>',
 'home':'<path d="M3 11L12 3 21 11M6 9V21H18V9M10 21V15H14V21"/>'}
def icon(name,x=0,y=0):return f'<g transform="translate({x} {y})" color="{INK}" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="miter">{icons[name]}</g>'
for state in ['normal','hover','focus','pressed','disabled']:save(f'assets/button-{state}.svg',280,44,button(0,0,'',state=state),'button state; labels stay dynamic')
for name in icons:save(f'assets/icon-{name}.svg',24,24,icon(name),'icon')
for on in [True,False]:save(f'assets/toggle-{str(on).lower()}.svg',44,24,toggle(0,0,on),'toggle')
save('assets/slider-track.svg',240,24,rect(0,10,240,4,LINE),'slider track')
save('assets/slider-fill.svg',240,24,rect(0,10,240,4,INK),'slider fill; clip to value')
save('assets/slider-thumb.svg',10,24,rect(0,3,10,18,INK),'slider thumb')
save('assets/dialog-panel.svg',360,440,panel(0,0,360,440),'panel; 2px nine-slice margin')
save('assets/confirm-panel.svg',440,280,panel(0,0,440,280),'panel; 2px nine-slice margin')
save('assets/hud-panel.svg',128,92,panel(0,0,128,92),'panel; 2px nine-slice margin')
save('assets/dim-overlay.svg',960,640,rect(0,0,960,640,'#000',extra='opacity=".58"'),'overlay')
save('assets/keycap.svg',44,32,rect(.5,.5,43,31,BG,LINE),'keycap')
save('assets/t-mark.svg',48,32,mark(0,0),'menu motif')
game=(R/'source/gameplay-reference.txt').read_text()
game=re.sub(r'^<svg[^>]*>','',game).removesuffix('</svg>')
def base(title,subtitle=None,over=False):
 b=(game+rect(0,0,960,640,'#000',extra='opacity=".65"')) if over else rect(0,0,960,640,BG)
 b+=panel(300,104,360,448)+text(480,155,title,24,anchor='middle')
 if subtitle:b+=text(480,186,subtitle,12,MUTED,'middle')
 return b
screens={}
b=rect(0,0,960,640,BG)+mark(456,103)+text(480,198,'FALLING BLOCKS',30,anchor='middle')+text(480,229,'A LITTLE ROOM TO THINK.',12,MUTED,'middle')
for i,(label,state) in enumerate([('PLAY','focus'),('HOW TO PLAY','normal'),('SETTINGS','normal'),('QUIT','normal')]):b+=button(340,275+i*58,label,state=state)
b+=text(480,586,'BEST  031200',13,MUTED,'middle');screens['main-menu']=b
b=base('PAUSED','Take your time.',True)
for i,(label,state) in enumerate([('RESUME','focus'),('SETTINGS','normal'),('RESTART','normal'),('MAIN MENU','normal')]):b+=button(340,222+i*66,label,state=state)
b+=text(480,523,'ESC TO RESUME',11,MUTED,'middle');screens['pause']=b
b=base('SETTINGS')
for y,label,v in [(213,'MUSIC',.5),(289,'SOUND',.8)]:b+=text(340,y,label,13,MUTED)+text(620,y,str(round(v*100))+'%',13,INK,'end')+slider(340,y+12,v,280)
b+=text(340,386,'GHOST PIECE',13)+toggle(576,367,True)+button(340,461,'DONE',state='focus');screens['settings']=b
b=base('GAME OVER','Nice run.',True)+text(480,242,'SCORE',12,MUTED,'middle')+text(480,290,'024800',42,anchor='middle')+text(480,329,'LEVEL 06   LINES 048',13,MUTED,'middle')
b+=button(340,383,'PLAY AGAIN',state='focus')+button(340,445,'MAIN MENU');screens['game-over']=b
b=base('HOW TO PLAY','Fill a row to clear it.')
for i,(key,label) in enumerate([('← / →','Move'),('↑','Rotate'),('↓','Soft drop'),('SPACE','Hard drop'),('C','Hold'),('ESC','Pause')]):
 y=213+i*38;b+=rect(340,y-20,100,28,BG,LINE)+text(390,y,key,12,anchor='middle')+text(462,y,label,14)
b+=button(340,475,'GOT IT',state='focus');screens['how-to-play']=b
b=game+rect(0,0,960,640,'#000',extra='opacity=".65"')+panel(260,180,440,280)+text(480,234,'START AGAIN?',24,anchor='middle')+text(480,277,'Your current run will end.',14,MUTED,'middle')
b+=button(300,324,'KEEP PLAYING',360,'focus')+button(300,382,'RESTART',360);screens['restart-confirm']=b
for name,body in screens.items():save(f'screens/{name}.svg',960,640,body,'screen composition')

sheet=rect(0,0,1280,1500,BG)+text(40,51,'THE SIMPLE UI',26)+text(40,80,'Same flat blocks. Matching menus and controls.',14,MUTED)
for i,(name,body) in enumerate(screens.items()):
 x=40+(i%2)*620;y=125+(i//2)*445
 sheet+=text(x,y,name.replace('-',' ').upper(),13,MUTED)+f'<g transform="translate({x} {y+16}) scale(.625)">{body}</g>'
save('ui-screens.svg',1280,1500,sheet,'review layout')

sheet=rect(0,0,1000,760,BG)+text(40,54,'UI PIECES',26)+text(40,86,'Flat fills / thin borders / square corners',14,MUTED)
for i,state in enumerate(['normal','hover','focus','pressed','disabled']):
 y=140+i*58;sheet+=button(40,y,'PLAY',state=state)+text(344,y+28,state.upper(),12,MUTED)
sheet+=text(580,138,'ICONS',12,MUTED)
for i,name in enumerate(icons):
 x=580+i%5*68;y=158+i//5*64
 sheet+=rect(x,y,40,40,PANEL,LINE)+icon(name,x+8,y+8)
sheet+=text(580,324,'SLIDER',12,MUTED)+slider(580,343,.6,300)
sheet+=text(580,403,'ON / OFF',12,MUTED)+toggle(580,422,True)+toggle(648,422,False)
sheet+=text(40,496,'PANELS & KEYCAPS',12,MUTED)+panel(40,518,240,176)+text(160,557,'PAUSED',20,anchor='middle')+button(60,581,'RESUME',200,'focus')+button(60,639,'MAIN MENU',200)
sheet+=panel(314,518,210,96)+text(333,549,'SCORE',12,MUTED)+text(333,589,'024800',29)
for i,key in enumerate(['←','→','↑','C']):sheet+=rect(580+i*60,520,44,32,BG,LINE)+text(602+i*60,542,key,14,anchor='middle')
sheet+=text(580,594,'Text stays editable.',13,MUTED)+text(580,619,'24px icons · 44px buttons',13,MUTED)+text(580,644,'SVG sources + PNG exports',13,MUTED)
save('ui-pieces.svg',1000,760,sheet,'component layout')
(R/'manifest.json').write_text(json.dumps({'status':'UI artwork for review; not integrated into Godot','style':'Approved flat simple-v2 palette and shapes','assets':assets,'font':'Menlo / monospace system fallback; not bundled','music':'Previous track rejected; no music bundled'},indent=2))
print(f'Created {len(assets)} UI artwork files.')
