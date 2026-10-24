#!/usr/bin/env python3
"""Generate original OrbForge icon and sound assets. Requires Pillow only for PNG art."""
from pathlib import Path
import math, random, wave, struct
from PIL import Image, ImageDraw, ImageFilter
ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / 'assets/icons'
AUDIO = ROOT / 'assets/audio'
ICON.mkdir(parents=True, exist_ok=True)
AUDIO.mkdir(parents=True, exist_ok=True)
S = 512
random.seed(4702)

def make_gradient():
    im = Image.new('RGB', (S, S))
    p = im.load()
    for y in range(S):
        for x in range(S):
            dx=(x-256)/S; dy=(y-220)/S
            glow=max(0,1-math.sqrt(dx*dx+dy*dy)*1.9)
            p[x,y]=(int(10+20*glow+17*y/S),int(25+52*glow+15*y/S),int(67+77*glow+22*y/S))
    return im.convert('RGBA')

def draw_cannon(im):
    shadow=Image.new('RGBA', im.size)
    ds=ImageDraw.Draw(shadow)
    ds.ellipse((112,340,422,447), fill=(0,0,0,165))
    shadow=shadow.filter(ImageFilter.GaussianBlur(17))
    im.alpha_composite(shadow)
    d=ImageDraw.Draw(im)
    d.line((254,327,255,203), fill='#11223f', width=98)
    d.line((254,327,255,203), fill='#3b7398', width=72)
    d.line((242,304,243,201), fill='#71edff', width=14)
    d.rounded_rectangle((188,174,322,218), radius=18, fill='#dffbff', outline='#1c4669', width=9)
    d.ellipse((125,337,221,434), fill='#102b4d',outline='#7c9dba',width=12)
    d.ellipse((292,337,388,434), fill='#102b4d',outline='#7c9dba',width=12)
    d.ellipse((174,300,340,446), fill='#1f436d',outline='#b0d5ef',width=12)
    d.ellipse((200,315,316,428), fill='#1478a0')
    d.ellipse((205,319,287,401), fill='#49e5eb')
    d.ellipse((223,330,254,363), fill=(255,255,255,180))
    return im

def draw_orb(im):
    d=ImageDraw.Draw(im)
    d.ellipse((295,53,433,187),fill='#213b7b',outline='#c3edff',width=9)
    d.ellipse((308,61,423,176),fill='#9b76f1')
    d.arc((319,69,411,159),190,339,fill='#e4d9ff',width=12)
    d.ellipse((327,82,359,115),fill=(255,255,255,140))
    d.ellipse((70,123,198,251),fill='#143b65',outline='#c4edff',width=8)
    d.ellipse((82,135,186,239),fill='#4bcdb8')
    d.ellipse((99,146,130,174),fill=(255,255,255,140))
    return im

main=draw_cannon(draw_orb(make_gradient()))
main.save(ICON / 'orbforge_icon.png', optimize=True)
main.save(ICON / 'adaptive_background.png', optimize=True)
fg=Image.new('RGBA',(512,512),(0,0,0,0))
draw_orb(fg)
draw_cannon(fg)
fg.save(ICON / 'adaptive_foreground.png', optimize=True)

RATE=22050

def tone(name, dur, root, slide=0, noise=0.0, volume=0.46):
    n=int(RATE*dur)
    pcm=[]
    for i in range(n):
        t=i/RATE
        phase=2*math.pi*(root*t+slide*t*t*0.5)
        env=(min(1.0,t/0.015) * math.exp(-4.8*t/max(0.08,dur)))
        v=math.sin(phase)*0.75+math.sin(phase*1.98)*0.16
        v+=(random.random()*2-1)*noise
        v=max(-1.0,min(1.0,volume*env*v))
        pcm.append(int(v*32767))
    path=AUDIO/(name+'.wav')
    with wave.open(str(path),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE)
        w.writeframes(struct.pack('<%dh'%len(pcm),*pcm))

tone('shot', .14, 520, -2200, .07, .36)
tone('impact', .12, 280, -400, .18, .32)
tone('split', .36, 180, -120, .3, .46)
tone('coin', .26, 640, 1600, .02, .36)
tone('hurt', .4, 260, -340, .16, .44)
tone('win', .9, 550, 540, .02, .38)
tone('button', .13, 660, 60, 0, .25)
tone('upgrade', .53, 460, 540, .02, .42)

# Eight-second ambient soundtrack: generated synth triad, soft pulse, no external samples.
n=int(RATE*8)
notes=[110.0, 138.59, 164.81, 220.0]
pcm=[]
for i in range(n):
    t=i/RATE
    attack=min(1.0,t/.35)
    decay=min(1.0,(8-t)/.4)
    envelope=attack*decay
    sound=sum(math.sin(2*math.pi*freq*t+math.sin(t*.25)*0.2) for freq in notes)*0.08
    pluck=(t*2)%1
    f=[440,493.88,659.25,554.37,440,392,330,493.88][int(t)%8]
    sound+=math.sin(2*math.pi*f*t)*max(0,1-pluck)**4*0.12
    sound+=math.sin(2*math.pi*55*t)*0.04
    sound=max(-1,min(1,sound*envelope))
    pcm.append(int(sound*32767))
with wave.open(str(AUDIO/'ambient.wav'),'wb') as w:
    w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE)
    w.writeframes(struct.pack('<%dh'%len(pcm),*pcm))
print('Generated original icons + 9 PCM WAV clips')
