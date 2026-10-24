# OrbForge: Cannon Rush

**Original, offline-first Godot 4.7.2 arcade shooter — Phase 1 source project.**

Move your cannon left or right, auto-fire at numbered bouncing orbs, split orbs into smaller ones, dodge collisions, collect coins, unlock weapons, and permanently upgrade combat statistics. The repository contains *real game scripts*, a runnable scene, generated artwork and audio, ten encounter configurations, tests, and Android CI configurations. It is **not** an existing certified APK or a completed 300-level production game.

## Current Phase 1 contents

- Portrait touchscreen + desktop mouse dragging; fixed arena boundaries and a 3-HP cannon.
- Physics-body numbered balls: gravity, wall/ground collisions, health, damage, tier-dependent splitting, child velocities.
- Automatic shooting; pooled projectiles with physics raycasts; three distinctive weapons: Classic Cannon, Rapid Blaster, Tri-Shot Cannon.
- 10 wave-driven campaign levels, sequential level unlocks, scoring/combo, collectible coins, level bonus rewards.
- Main menu, level select, garage/unlocks, permanent damage and fire-rate upgrades, settings, pause, retry, victory, game over.
- Basic impact/fragment effects, generated WAV audio and ambient soundtrack; completely offline.
- Versioned save in `user://`, save rotation / backup recovery, persistent settings.
- Headless GDScript gameplay test suite and Python source-data checks.
- GitHub Actions workflows to attempt an unsigned-free, locally debug-signed APK export; manually triggered signed release APK/AAB workflow.

## Technology

| Area | Implementation |
|---|---|
| Engine | Godot 4.7.2 Stable, GDScript |
| Rendering | Compatibility / 2D CanvasItem procedural graphics |
| Layout | 720×1280 reference, portrait, viewport scaling with expand |
| Android | Debug APK; Gradle AAB in release workflow |
| Storage | `user://orbforge_save_v1.json` + backup |
| Assets | Self-generated PNG and WAV files, no paid licenses |
| Network | Not required |
| Tests | `tests/test_runner.gd`, `tools/validate_project.py` |

## Folder structure

```text
.github/workflows/            Android CI and source checks
project.godot                 Core Godot settings
export_presets.cfg            Exact "Android" debug preset + two release presets
scenes/main/main.tscn         Main entry scene
scripts/ui/main.gd            Actual menus, HUD, garage, settings, navigation
scripts/combat/               Arena, cannon, balls, projectiles, combat rules
scripts/core/game_data.gd     Runtime JSON content loading and validation
scripts/progression/          Unlock, economy, purchases, level rewards
scripts/save/                 Versioned atomic save + migration
scripts/audio/                Sound playback and ambient audio
scripts/visual/               Original procedural background and VFX
data/levels/                  Ten playable stage wave configurations
data/weapons/                 Three weapon data entries
assets/icons/                 Original Android app launcher/adaptive icons
assets/audio/                 Original generated gameplay sounds
assets/                       No third-party fonts or proprietary assets
scripts/                     No proprietary third-party code
builds/                      Empty locally; output created by CI
```

## Running in the Godot editor (Windows, Linux or macOS)

1. Download [Godot 4.7.2 Stable](https://godotengine.org/download/archive/4.7.2-stable/).
2. Open the project folder containing `project.godot` in Godot's Project Manager.
3. Wait for resources to import. Press **F6** on the main scene or **F5** to run the project.
4. Drag with mouse (desktop) or touch (Android) to move the cannon. Cannon auto-fires.
5. For first run, enter `PLAY NOW`. New levels unlock after clearing previous ones.

Run tests from a shell where `godot` is the Godot 4.7.2 **editor** binary:

```bash
python3 tools/validate_project.py
godot --headless --path . --import
godot --headless --path . --script res://tests/test_runner.gd
```

The Python check is **not** a substitute for Godot parsing/tests. CI exits on missing resources, failed GDScript tests, or export errors.

## Upload the source to GitHub

Extract the archive first. Create an empty GitHub repository, then run these commands **inside the project folder**:

```bash
git init
git add .
git commit -m "Build OrbForge Phase 1 playable foundation"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/orbforge-cannon-rush.git
git push -u origin main
```

Alternatively, copy these files to an existing repo (including the hidden `.github/workflows` folder). Do **not** upload the source ZIP and expect GitHub Actions to extract it automatically.

## Automatic debug Android APK

The workflow `.github/workflows/android-debug.yml` runs on push to `main`, pull requests targeting `main`, and manual **Actions → Android Debug APK → Run workflow**.

It downloads pinned Godot 4.7.2 + matching official export templates, sets up Temurin JDK 17 and the required Android SDK, creates a temporary debug keystore, imports project resources, checks content, runs headless tests, exports an APK, verifies package ID, and uploads a GitHub artifact.

**Expected artifact name:** `OrbForge-Android-Debug-APK`

**Expected path inside artifact:** `orbforge-debug.apk` (created from `builds/orbforge-debug.apk`)

1. Go to your repository's **Actions** tab.
2. Select the latest successful **Android Debug APK** run.
3. Under **Artifacts**, download `OrbForge-Android-Debug-APK`.
4. Unzip the artifact and move `orbforge-debug.apk` to your Android phone.
5. Allow installation of APKs from your chosen file source, and install. Your phone may require enabling trusted app installation.

**Important:** The source ZIP does *not* contain a built APK. Godot is not present in the source-authoring environment, so the APK export and device playtesting must be verified through the GitHub Actions run and a physical device.

### Android export / local command

Use Android SDK and JDK 17, install the 4.7.2 Android export templates, configure the SDK paths in Editor Settings, then run:

```bash
godot --headless --path . --import
mkdir -p builds
godot --headless --path . --export-debug "Android" builds/orbforge-debug.apk
```

## Signed release APK and AAB

The separate workflow `.github/workflows/android-release.yml` is manual and also runs on version tags (`v*`). It **fails clearly** when release-signing GitHub secrets are absent; it does not create misleading release artifacts.

1. Locally create a secure keystore (JDK 17 example):

   ```bash
   keytool -genkeypair -v -keystore orbforge-release.jks -alias orbforgerelease -keyalg RSA -keysize 4096 -validity 10000
   ```

2. Do **not** commit the keystore. Back it up in a secure place. Keep password and key alias safe.
3. Set repository **Settings → Secrets and variables → Actions** secrets:
   - `RELEASE_KEYSTORE_BASE64`: base64 encoding of the binary keystore (without newlines).
   - `RELEASE_KEY_ALIAS`: keystore key alias (e.g., `orbforgerelease`).
   - `RELEASE_KEY_PASSWORD`: key password / keystore password (same password for Godot export).
4. Base64 using `base64 -w0 orbforge-release.jks` on GNU/Linux, or `base64 orbforge-release.jks | tr -d '\n'` on macOS. On Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('orbforge-release.jks'))`.
5. Run workflow manually. It exports `builds/orbforge-release.apk` and `builds/orbforge-release.aab` using Godot's Android Gradle template. AAB requires Gradle, not the prebuilt APK-only template.

Publishing to Google Play is **not** automated. Before release, replace `com.yourstudio.orbforgecannon` with a package identifier owned by you, increase `version/code`, verify Google Play's current target API / 64-bit requirements, publish a privacy disclosure, and complete store compliance.

## Adding content

**Weapons:** Add an object to `data/weapons/weapons.json`, implement any new firing pattern in `scripts/combat/arena.gd` (Phase 1 supports single and configurable spread streams), and add its ID to save defaults/migration before exposing it. Do not add a data-only weapon that has no real combat behavior.

**Levels:** Add wave data in `data/levels/phase1.json`. The arena reads `count`, `tier`, `hp`, `speed`. Extend to a scalable level generator in Phase 2. Every spawn budget must remain bounded.

**Enemies:** Add a new behavior script to `scripts/combat/`, provide unique attributes and telegraphs, and wire it through the spawn manager when implementing subsequent enemy variants.

**Bosses:** Phase 1 has no bosses yet. Phase 2 should add dedicated state-machine scenes and phase-specific attacks; do not represent boss fights as plain health inflation.

**Upgrade prices:** Change `RunRules.upgrade_cost()`; upgrade levels and caps are implemented in `Progression.purchase_upgrade()` and `RunRules.weapon_stats()`.

**Art and audio:** Original assets are checked in. The deterministic-ish icon/audio generator is `tools/generate_assets.py`; regenerating assets requires Pillow (`python -m pip install Pillow`). Runtime never executes the generator.

## Controls and saves

- **Android:** Touch/drag left-right on playfield; weapon auto-fires.
- **Desktop:** Click or drag with left mouse button. Press `Escape` to pause/resume/back.
- **Settings:** Music, SFX, touch sensitivity, particles, visual hit feedback, tutorial reset, confirmed full save reset.
- **Save path:** Godot's OS-managed `user://` application folder. Actual Android path is application-private; users do not need storage permissions.
- **Save write:** temporary file → old-save backup → atomic rename. A backup is loaded when primary data becomes unreadable.

## Troubleshooting

- **No artifact:** Open the Actions job logs. A failure is never a produced APK.
- **Godot missing:** Check official Linux editor ZIP and export template release links, plus `tools/install_godot.sh`.
- **Missing SDK:** Verify Android SDK Build Tools 35.0.1, Platform 35, JDK 17, and editor-settings paths.
- **Missing export preset:** Ensure the entire `export_presets.cfg` is committed and the preset is named exactly `Android`.
- **Script parse failure:** See the `Import project resources` or `Run headless gameplay tests` workflow steps. Fix errors before shipping.
- **APK install failure:** Uninstall any existing package signed by a different keystore, then install your debug APK.
- **Black screen/lag on a phone:** Capture `adb logcat` and test GLES compatibility, aspect scaling, and device frame time.
- **Release AAB failure:** Check release secrets and Gradle build-template installation (`--install-android-build-template`).

## Development phases and limitations

**Current:** Phase 1 source implementation of the ten-level playable vertical slice. Game code and local structural checks are included; *Godot editor parse, Android export, touchscreen behavior, and device performance have not been executed or certified in this authoring environment.* Treat CI's first run as the authoritative build validation.

**Phase 2 next:** Additional weapon behaviors, abilities, ultimates, elite enemies, animated bosses, world-specific art, Endless/Survival modes, mission/achievement system, larger upgrade catalog.

**Phase 3 later:** 12 worlds, all 300 campaign levels, twelve distinct boss fights, 16 weapons, 12 abilities, 6 ultimates, dozens of achievements and cosmetics, and all planned modes.

**Phase 4:** Profiling and performance targets, accessibility, physical-device regression testing, secure signing and store metadata.

**Phase 5:** Optional online infrastructure *only after a genuine backend exists*. No fake player profiles, paid SDK, ads, analytics transmission, online leaderboard or cloud dependency is present.

## Licensing and credits

Original OrbForge source, artwork, icon, and synthesis-generated audio: MIT license (`LICENSE`). Engine Godot: MIT license, https://godotengine.org/license. No VOODOO game code or assets, external fonts, paid libraries, advertising or payment SDKs are used. No external user data is transmitted.
