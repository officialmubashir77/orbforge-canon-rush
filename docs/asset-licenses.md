# Asset provenance and licensing

All checked-in art and WAV files are generated specifically for this repository and licensed MIT together with its original source code. `tools/generate_assets.py` constructs original vector-like cannon/orb icons and PCM sounds using math/Pillow, not content from another game or royalty-free asset pack. Godot supplies its own engine fallback UI font; no system fonts are copied or redistributed.

Optional development dependency: Python Pillow (PIL) for regenerating the PNG icon assets; Pillow uses the open source HPND license. The generated PNG and WAV assets are committed, so Pillow is not required to build an APK or play offline.

Godot Engine is MIT licensed. See https://godotengine.org/license .
