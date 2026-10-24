#!/usr/bin/env python3
"""Dependency-free structural and data validations. Godot GDScript tests are separate."""
import json, re, sys, wave, struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]
errors=[]
def check(ok, msg):
    if not ok: errors.append(msg)

required=[
    'project.godot','export_presets.cfg','scenes/main/main.tscn',
    'scripts/ui/main.gd','scripts/combat/arena.gd','scripts/combat/orb_ball.gd',
    'scripts/combat/cannon.gd','scripts/combat/projectile.gd',
    'scripts/core/game_data.gd','scripts/save/save_system.gd',
    'tests/test_runner.gd','.github/workflows/android-debug.yml',
    'assets/icons/orbforge_icon.png','assets/audio/shot.wav','assets/audio/ambient.wav'
]
for item in required: check((root/item).is_file(),f'Missing file: {item}')

if (root/'data/weapons/weapons.json').is_file():
    weapons=json.loads((root/'data/weapons/weapons.json').read_text())['weapons']
    ids=[w['id'] for w in weapons]
    check(len(ids)==3 and len(ids)==len(set(ids)), 'Must define three unique weapons')
    check(all(w['damage']>0 and w['fire_rate']>0 and w['streams']>0 for w in weapons),'Non-positive weapon data')
    check({'classic','rapid','spread'} == set(ids),'Unknown Phase 1 weapon IDs')
if (root/'data/levels/phase1.json').is_file():
    levels=json.loads((root/'data/levels/phase1.json').read_text())['levels']
    check(len(levels)==10 and [x['id'] for x in levels]==list(range(1,11)),'Ten ordered levels required')
    seen=set()
    for lvl in levels:
        waves=lvl['waves']
        check(bool(waves),f'Empty wave configuration at level {lvl["id"]}')
        for item in waves:
            check(item['count']>=1 and item['count']<=10 and item['tier'] in (1,2,3,4) and item['hp']>0,f'Invalid spawn budget for level {lvl["id"]}')
        seen.add(tuple((q['count'],q['tier'],q['hp'],q['speed']) for q in waves))
    check(len(seen)==10,'Procedural encounters must not be duplicates')
    check(levels[0]['bonus']<levels[-1]['bonus'],'Campaign reward scaling missing')
if (root/'export_presets.cfg').is_file():
    preset=(root/'export_presets.cfg').read_text()
    check('name="Android"' in preset,'Android debug export preset missing')
    check('com.yourstudio.orbforgecannon' in preset,'Android package identifier missing')
    check('gradle_build/use_gradle_build=true' in preset,'AAB release Gradle export missing')
    check('launcher_icons/main_192x192' in preset,'Custom Android icon missing')
    check(preset.count('include_filter="*.json"')==3,'JSON data must be exported in all APK/AAB presets')
if (root/'project.godot').is_file():
    project=(root/'project.godot').read_text()
    check('renderer/rendering_method="gl_compatibility"' in project,'Mobile compatibility renderer missing')
    check(project.count('[application]')==1,'Duplicate Godot application section')
for p in root.rglob('*.gd'):
    content=p.read_text()
    for relative in re.findall(r'res://([\w./-]+\.(?:gd|tscn|wav|json|png))',content):
        check((root/relative).is_file(),f'Broken resource path: {p.relative_to(root)}: {relative}')
    check('\t' not in content,f'Tabs are disallowed by project formatting convention: {p}')
for wav in (root/'assets/audio').glob('*.wav'):
    try:
        with wave.open(str(wav),'rb') as sound:
            check(sound.getnframes()>100 and sound.getframerate()>=16000,f'Invalid WAV: {wav}')
    except (wave.Error, OSError) as ex:
        errors.append(f'Invalid audio file {wav}: {ex}')
for path in [root/'assets/icons/orbforge_icon.png',root/'assets/icons/adaptive_foreground.png',root/'assets/icons/adaptive_background.png']:
    if path.exists():
        with path.open('rb') as file:
            magic=file.read(24)
            check(magic.startswith(b'\x89PNG\r\n\x1a\n') and len(magic)==24 and struct.unpack('>II',magic[16:24])[0]>=432,f'Invalid PNG icon: {path.name}')
if errors:
    for e in errors: print('FAIL:',e)
    sys.exit(1)
print('PASS: Project files, data, config, assets and resource references checked')
print('NOTE: GDScript parse, physics tests and APK export require running Godot 4.7.2')
