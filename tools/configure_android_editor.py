#!/usr/bin/env python3
"""Configure Godot 4 EditorSettings for headless Android exports on GitHub Actions."""
from pathlib import Path
import os, sys
sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
java = os.environ.get('JAVA_HOME')
if not sdk or not java:
    sys.exit('Missing ANDROID_HOME / JAVA_HOME environment variables')
if not (Path(sdk)/'platform-tools'/'adb').is_file():
    sys.exit(f'Invalid Android SDK: {sdk}')
if not (Path(java)/'bin'/'java').is_file():
    sys.exit(f'Invalid Java JDK: {java}')
file = Path.home()/'.config/godot/editor_settings-4.tres'
file.parent.mkdir(parents=True,exist_ok=True)
# Godot loads EditorSettings from this resource on headless editor boot.
content = file.read_text() if file.is_file() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
if '[resource]' not in content:
    sys.exit('Unexpected editor settings file; cannot configure Android paths')
for key, value in [
    ('export/android/android_sdk_path', sdk),
    ('export/android/java_sdk_path', java),
]:
    import re
    entry=f'{key} = "{value}"'
    pattern=r'^'+re.escape(key)+r'\s*=.*$'
    if re.search(pattern, content, re.MULTILINE):
        content=re.sub(pattern,lambda _:entry,content,flags=re.MULTILINE)
    else:
        content += '\n'+entry
file.write_text(content)
print('Updated Godot Android SDK and Java SDK editor settings:', file)
