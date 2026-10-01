from pathlib import Path
import numpy as np
import json,wave
R=Path(__file__).resolve().parents[1];SR=44100;BPM=150;BEAT=60/BPM
N=round(16*4*BEAT*SR);mix=np.zeros((N,2));rng=np.random.default_rng(330)
def voice(midi,duration,kind):
 t=np.arange(round(duration*SR))/SR;freq=440*2**((midi-69)/12);phase=2*np.pi*freq*t
 if kind=='pulse':
  duty=.25
  a=sum(2*np.sin(np.pi*h*duty)/(np.pi*h)*np.cos(h*phase-np.pi*h*duty) for h in range(1,min(18,int(SR/2/freq))))
  env=np.minimum(t/.003,1)*np.minimum((duration-t)/.012,1)*(.65+.35*np.exp(-t*16))
 elif kind=='arp':
  a=sum(np.sin(h*phase)/h for h in [1,3,5]);env=np.minimum(t/.002,1)*np.minimum((duration-t)/.014,1)*np.exp(-t*13)
 else:
  a=sum((-1)**((h-1)//2)*np.sin(h*phase)/h**2 for h in [1,3,5,7]);env=np.minimum(t/.004,1)*np.minimum((duration-t)/.018,1)*(.6+.4*np.exp(-t*8))
 return a*env
def drum(kind):
 duration={'kick':.13,'snare':.12,'hat':.035}[kind];t=np.arange(round(duration*SR))/SR
 if kind=='kick':a=np.sin(2*np.pi*(48*t+60*.016*(1-np.exp(-t/.016))))*np.exp(-t*30)
 else:
  noise=rng.uniform(-1,1,len(t));noise=np.r_[noise[0],np.diff(noise)]*.5
  a=noise*np.exp(-t*(38 if kind=='snare' else 95))
  if kind=='snare':a+=.16*np.sin(2*np.pi*170*t)*np.exp(-t*32)
 return a*np.minimum(t/.001,1)*np.minimum((duration-t)/.008,1)
def add(a,beat,gain,pan=0):
 idx=(np.arange(len(a))+round(beat*BEAT*SR))%N
 mix[idx,0]+=a*gain*np.sqrt((1-pan)/2);mix[idx,1]+=a*gain*np.sqrt((1+pan)/2)

# Original call-and-response hook, in E minor; values are sixteenth-note starts.
# Repeat the main phrase, then lift it into a higher answering phrase.
melodies=[
 [(0,76,2),(3,79,1),(4,83,2),(7,79,1),(8,81,2),(11,79,1),(12,76,3)],
 [(0,74,2),(3,76,1),(4,79,3),(8,76,2),(12,74,2),(14,71,1)],
 [(0,76,2),(3,79,1),(4,84,2),(7,79,1),(8,83,2),(11,79,1),(12,76,3)],
 [(0,74,2),(4,72,2),(7,76,1),(8,79,3),(12,76,2),(14,74,1)],
 [(0,74,2),(3,79,1),(4,83,2),(7,79,1),(8,81,2),(11,79,1),(12,74,3)],
 [(0,71,2),(3,74,1),(4,79,3),(8,83,2),(11,81,1),(12,79,3)],
 [(0,78,2),(3,76,1),(4,74,3),(8,78,2),(11,81,1),(12,78,3)],
 [(0,75,2),(3,78,1),(4,83,3),(8,78,2),(12,75,2),(14,78,1)],
 [(0,83,2),(3,81,1),(4,79,2),(7,76,1),(8,79,2),(11,83,1),(12,88,3)],
 [(0,86,2),(3,83,1),(4,81,3),(8,79,2),(12,76,3)],
 [(0,84,2),(3,83,1),(4,79,2),(7,76,1),(8,79,2),(11,84,1),(12,88,3)],
 [(0,86,2),(4,84,2),(7,83,1),(8,79,3),(12,76,3)],
 [(0,83,2),(3,81,1),(4,79,3),(8,74,2),(11,79,1),(12,83,3)],
 [(0,81,2),(3,79,1),(4,74,3),(8,71,2),(12,74,2),(14,76,1)],
 [(0,78,2),(3,81,1),(4,86,3),(8,81,2),(11,78,1),(12,74,3)],
 [(0,75,2),(3,78,1),(4,83,2),(7,78,1),(8,75,2),(12,71,2),(14,75,1)]]
chords=[(40,[64,67,71]),(40,[64,67,71]),(36,[60,64,67]),(36,[60,64,67]),(43,[62,67,71]),(43,[62,67,71]),(38,[62,66,69]),(35,[63,66,71])]
for bar,phrase in enumerate(melodies):
 root,notes=chords[bar%8]
 for start,n,length in phrase:add(voice(n,length*.25*BEAT*.82,'pulse'),bar*4+start/4,.22,-.08)
 for step in range(8):
  n=root+([0,12,7,12,0,12,7,12][step])
  add(voice(n,BEAT*.37,'bass'),bar*4+step*.5,.19)
 # Sparse arpeggio replies, keeping the hook in front.
 for step in ([1,3,5,7] if bar<8 else [1,2,3,5,6,7]):
  add(voice(notes[step%3]+12,BEAT*.21,'arp'),bar*4+step*.5,.033,.32)
 for pos in [0,2]:add(drum('kick'),bar*4+pos,.24)
 for pos in [1,3]:add(drum('snare'),bar*4+pos,.13,.08)
 for step in range(8):add(drum('hat'),bar*4+step*.5,.033,-.25)
 # A tiny last-bar snare pickup leads back into the hook.
 if bar==15:
  for pos in [3.5,3.75]:add(drum('snare'),bar*4+pos,.055)

mix=np.tanh(mix*1.3);mix*=.65/np.max(np.abs(mix))
with wave.open(str(R/'audio/block-hop.wav'),'wb') as w:
 w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes((mix*32767).astype('<i2').tobytes())
spec={'title':'Block Hop','file':'audio/block-hop.wav','style':'Classic 8-bit arcade','composition':'Original melody; no external samples or quoted game tune','bpm':BPM,'key':'E minor','bars':16,'seconds':N/SR,'sample_rate':SR,'channels':2,'bit_depth':16,'loop_start_sample':0,'loop_end_sample':N,'peak_dbfs':round(20*np.log10(np.max(np.abs(mix))),2),'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(mix**2))),2),'boundary_step':float(np.max(np.abs(mix[-1]-mix[0]))),'arrangement':'Pulse lead, triangle bass, sparse pulse arpeggio and synthesized percussion; no pads or reverb'}
(R/'audio/music-spec.json').write_text(json.dumps(spec,indent=2))
manifest=json.loads((R/'manifest.json').read_text());manifest['music']=spec;(R/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(spec,indent=2))
