from pathlib import Path
import json, wave, math
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
COLORS={'I':'#60c5ce','O':'#e7ca63','T':'#aa8bd1','S':'#83bc7b','Z':'#d97679','J':'#739dd2','L':'#dea06a'}
SHAPES={'I':[(0,0),(1,0),(2,0),(3,0)],'O':[(0,0),(1,0),(0,1),(1,1)],'T':[(1,0),(0,1),(1,1),(2,1)],'S':[(1,0),(2,0),(0,1),(1,1)],'Z':[(0,0),(1,0),(1,1),(2,1)],'J':[(0,0),(0,1),(1,1),(2,1)],'L':[(2,0),(0,1),(1,1),(2,1)]}
BG='#25292e';PANEL='#1b1e22';LINE='#52585e';INK='#eeeeea';MUTED='#9ba1a4'
inventory=[]
def rect(x,y,w,h,c,stroke='none',more=''):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" stroke="{stroke}" {more}/>'
def text(x,y,s,size=15,color=INK):return f'<text x="{x}" y="{y}" font-family="Menlo,monospace" font-size="{size}" fill="{color}">{s}</text>'
def tile(x,y,c,s=24):return rect(x+1,y+1,s-2,s-2,c)
def piece(k,x,y,s=24):return ''.join(tile(x+a*s,y+b*s,COLORS[k],s) for a,b in SHAPES[k])
def panel(x,y,w,h):return rect(x+.5,y+.5,w-1,h-1,PANEL,LINE)
def button(x,y,label,w=140,focus=False):return rect(x+.5,y+.5,w-1,35,INK if focus else BG,INK if focus else LINE)+text(x+14,y+23,label,13,BG if focus else INK)
def save(name,w,h,body,kind):
 (ROOT/name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>')
 inventory.append({'file':name,'width':w,'height':h,'type':kind})
for k,c in COLORS.items():
 save(f'assets/block-{k}.svg',24,24,tile(0,0,c),'tile')
 save(f'assets/piece-{k}.svg',96,48,piece(k,0,0),'piece')
save('assets/ghost.svg',24,24,rect(2,2,20,20,'none',MUTED),'tile')
save('assets/panel.svg',140,100,panel(0,0,140,100),'panel')
save('assets/button.svg',140,36,button(0,0,''),'button')
save('assets/button-focus.svg',140,36,button(0,0,'',focus=True),'button')
save('assets/pause.svg',24,24,rect(6,5,4,14,INK)+rect(14,5,4,14,INK),'icon')
save('assets/sound.svg',24,24,'<path d="M4 9H8L13 5V19L8 15H4Z" fill="#eeeeea"/><path d="M17 7Q24 12 17 17" fill="none" stroke="#eeeeea" stroke-width="2"/>','icon')
flash=''.join(rect(i*24,0,24,24,INK,more=f'opacity="{a}"') for i,a in enumerate([.85,.55,.25,0]))
save('assets/clear-flash.svg',96,24,flash,'4-frame effect; 16 fps, once')

board=panel(0,0,248,488)+rect(4,4,240,480,'#131619')
for x in range(1,10):board+=rect(4+x*24,4,1,480,'#202428')
for y in range(1,20):board+=rect(4,4+y*24,240,1,'#202428')
save('assets/board.svg',248,488,board,'10x20 board; 24px cells; 4px inset')

def scene():
 b=rect(0,0,960,640,BG)+text(356,47,'FALLING BLOCKS',24)
 b+=f'<g transform="translate(356 76)">{board}</g>'
 b+=piece('T',432,200)
 rows=['J.........','JJ.....L..','SJ.....L..','SSZ...LL..','OZZT..S.JJ','OOZTT.SS.J','IIIITOOS.J']
 for y,row in enumerate(rows,13):
  for x,k in enumerate(row):
   if k!='.':b+=tile(360+x*24,80+y*24,COLORS[k])
 for a,bb in SHAPES['T']:b+=rect(434+a*24,442+bb*24,20,20,'none',MUTED)
 b+=text(198,101,'HOLD',13,MUTED)+panel(196,118,128,92)+piece('O',235,140)
 for y,label,value in [(101,'SCORE','024800'),(182,'LEVEL','06'),(259,'LINES','048')]:
  b+=text(636,y,label,13,MUTED)+text(636,y+35,value,26)
 b+=text(636,354,'NEXT',13,MUTED)+panel(636,372,128,92)+piece('I',652,403)
 b+=button(636,492,'PAUSE',128)
 b+=text(276,598,'← →  MOVE   ↑  ROTATE   SPACE  DROP   C  HOLD',12,MUTED)
 return b
save('simple-scene.svg',960,640,scene(),'scene')

sheet=rect(0,0,960,660,BG)+text(42,55,'THE SIMPLE SET',24)+text(42,84,'Flat blocks. Plain UI. One quiet loop.',14,MUTED)
sheet+=text(42,138,'PIECES',12,MUTED)
for i,k in enumerate(COLORS):sheet+=piece(k,42+i*127,164)+text(42+i*127,235,k,13,MUTED)
sheet+=text(42,293,'BLOCK / GHOST / CLEAR',12,MUTED)+tile(42,320,COLORS['I'])+rect(82,322,20,20,'none',MUTED)
for i,a in enumerate([.85,.55,.25,.08]):sheet+=rect(130+i*29,321,22,22,INK,more=f'opacity="{a}"')
sheet+=text(350,293,'PANELS',12,MUTED)+panel(350,315,155,96)+text(364,338,'HOLD',11,MUTED)+piece('O',413,350,20)
sheet+=panel(525,315,180,96)+text(540,339,'SCORE',11,MUTED)+text(540,382,'024800',27)
sheet+=text(42,452,'BUTTONS',12,MUTED)+button(42,475,'PLAY')+button(202,475,'PLAY',focus=True)+button(362,475,'RESUME')+button(522,475,'RETRY')
sheet+=text(42,573,'MUSIC',12,MUTED)+text(42,603,'A short melody + a soft bass. 96 BPM. 20-second loop.',14)
save('simple-asset-layout.svg',960,660,sheet,'overview')

# Two voices only: a rounded triangle-like lead and a quiet sine bass.
# All voices end at silence. The loop ends on a brief rest.
sr=44100;beat=60/96;length=round(32*beat*sr);mix=np.zeros(length,dtype=np.float64)
def note(midi,duration,lead):
 t=np.arange(round(duration*sr))/sr;f=440*2**((midi-69)/12)
 a=np.sin(2*np.pi*f*t)
 if lead:a-=np.sin(2*np.pi*3*f*t)/9;a+=np.sin(2*np.pi*5*f*t)/25
 env=np.minimum(t/.018,1)*np.minimum((duration-t)/.06,1)*np.exp(-t*(2.2 if lead else 1.5))
 return a*env
def add(midi,start,duration,gain,lead):
 a=note(midi,duration,lead)*gain;i=round(start*beat*sr);mix[i:i+len(a)]+=a[:len(mix)-i]
melodies=[[(0,72),(1,76),(2,79)],[(0,76),(2,74)],[(0,69),(1,72),(2,76)],[(0,74),(2,72)],[(0,72),(1,76),(2,81)],[(0,79),(2,76)],[(0,74),(1,71),(2,67)],[(0,71),(1,74),(2,72)]]
for bar,notes in enumerate(melodies):
 for pos,midi in notes:add(midi,bar*4+pos,beat*.72,.22,True)
 bass=[48,48,45,41,48,45,43,48][bar]
 for pos in [0,2]:add(bass,bar*4+pos,beat*1.5,.10,False)
mix*=.34/max(np.max(np.abs(mix)),.001)
with wave.open(str(ROOT/'audio/simple-loop.wav'),'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes((mix*32767).astype('<i2').tobytes())
manifest={'direction':'Simple flat 2D artwork, no bevel, glow, texture or background decoration','status':'Review only; not integrated into Godot','palette':COLORS,'assets':inventory,'music':{'file':'audio/simple-loop.wav','original_composition':True,'external_samples':False,'voices':2,'drums':False,'bpm':96,'seconds':20,'sample_rate':sr,'loop_start_sample':0,'loop_end_sample':length,'peak_dbfs':round(20*np.log10(max(abs(mix))),2)},'effects':{'file':'assets/clear-flash.svg','frames':4,'frame_size':[24,24],'fps':16,'loop':False},'font':'System Menlo or monospace fallback; PNGs preserve appearance'}
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(f'Created {len(inventory)} simple SVGs and a 20-second two-voice loop.')
