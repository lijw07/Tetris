"""Original, deterministic 8-bit effects. Requires NumPy; no external samples."""
from pathlib import Path
import hashlib,json,wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio/sfx';OUT.mkdir(parents=True,exist_ok=True)
SR=44100
RNG=np.random.default_rng(940)
def tone(midi,duration,shape='pulse',end=None):
 t=np.arange(round(duration*SR))/SR;freq=440*2**((midi-69)/12)
 f=np.full(len(t),freq) if end is None else np.geomspace(freq,440*2**((end-69)/12),len(t))
 phase=2*np.pi*np.cumsum(f)/SR
 if shape=='pulse':a=sum(np.sin(h*phase)/h for h in [1,3,5])*.7
 elif shape=='triangle':a=sum((-1)**((h-1)//2)*np.sin(h*phase)/h**2 for h in [1,3,5])
 else:a=np.sin(phase)
 env=np.minimum(t/.003,1)*np.minimum((duration-t)/.015,1)*np.exp(-t*(3/duration))
 return a*env
def melody(notes,step=.055,duration=.13):
 size=round(((len(notes)-1)*step+duration+.02)*SR);out=np.zeros(size)
 for i,n in enumerate(notes):
  a=tone(n,duration);start=round(i*step*SR);out[start:start+len(a)]+=a
 return out
def impact(duration,low,high,noise):
 a=tone(high,duration,'triangle',low);t=np.arange(len(a))/SR
 a+=RNG.uniform(-1,1,len(a))*np.exp(-t*65)*noise*np.minimum(t/.001,1)
 return a
sounds={
 'ui_move':tone(79,.045,'triangle'),
 'ui_confirm':melody([72,79],.045,.095),
 'ui_back':melody([76,69],.04,.095),
 'ui_adjust':tone(74,.032,'triangle'),
 'move':tone(57,.033,'triangle'),
 'soft_drop':tone(48,.03,'sine'),
 'rotate':melody([72,79],.027,.066),
 'hold':melody([79,72,76],.04,.095),
 'lock':impact(.085,35,51,.12),
 'hard_drop':impact(.16,28,57,.20),
 'clear_1':melody([72,76,79],.055,.15),
 'clear_2':melody([72,76,79,84],.055,.17),
 'clear_3':melody([72,76,79,84,88],.045,.19),
 'clear_4':melody([72,76,79,84,88,91],.04,.23),
 'level_up':melody([76,79,83,88],.1,.22),
 'game_over':melody([76,74,71,64],.14,.26),
 'game_start':melody([64,71,76],.07,.13),
 'pause':melody([76,71],.06,.11),
 'resume':melody([71,76],.06,.11),
}
records=[]
for name,a in sounds.items():
 a-=np.mean(a);a*=np.minimum(np.arange(len(a))/80,1)*np.minimum(np.arange(len(a))[::-1]/160,1)
 a*=.6/max(np.max(np.abs(a)),.001)
 pcm=(a*32767).astype('<i2');dest=OUT/(name+'.wav')
 with wave.open(str(dest),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
 records.append({'name':name,'file':dest.name,'seconds':round(len(a)/SR,4),'peak_dbfs':round(20*np.log10(np.max(abs(a))),2),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(OUT/'manifest.json').write_text(json.dumps({'origin':'Original procedural synthesis; no outside samples','sample_rate':SR,'channels':1,'pcm_bits':16,'sounds':records},indent=2)+'\n')
# A spaced audition reel is a review deliverable, never loaded by the game.
review=ROOT/'outputs/audio-review';review.mkdir(parents=True,exist_ok=True)
timeline=[];reel=[];cursor=0
for record in records:
 with wave.open(str(OUT/record['file']),'rb') as w:a=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2')
 timeline.append({'seconds':round(cursor/SR,3),'sound':record['name']})
 reel.extend([a,np.zeros(round(.38*SR),dtype='<i2')]);cursor+=len(a)+round(.38*SR)
with wave.open(str(review/'sound-effects-preview.wav'),'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(np.concatenate(reel).astype('<i2').tobytes())
(review/'preview-timeline.json').write_text(json.dumps(timeline,indent=2))
print(f'Created {len(records)} effects and a {cursor/SR:.1f}s audition reel.')
