# Tetris

Tetris built in Godot 4.7 (GL Compatibility). Press **F5** in the editor to play.

## Controls

| Action | Keys |
|---|---|
| Move | ← → or A D |
| Rotate clockwise | ↑, X or W |
| Rotate counter-clockwise | Z |
| Soft drop | ↓ or S |
| Hard drop | Space |
| Hold | C or Shift |
| Pause | Esc or P |
| Toggle fullscreen | F11 |

Bindings live in **Project Settings → Input Map**.

## Rules

- SRS rotation with standard wall kicks, 7-piece bag randomizer, hold once per piece, ghost piece.
- Gravity follows the guideline curve; soft drop falls 20× faster than the current level.
- Lock delay of 0.5 s that resets on movement up to 15 times.
- Scoring: 100 / 300 / 500 / 800 × level for 1–4 lines, +1 per soft-dropped row, +2 per hard-dropped row. The level rises every 10 lines.
- Settings and the best score are saved to `user://profile.cfg`.

## Sound effects

The game includes 19 original short arcade effects. **Settings → Sound** controls all effects independently of music; zero fully mutes them, and the setting is saved.

| Event | Feedback |
|---|---|
| Button hover or keyboard focus | Soft navigation tick; overlapping hover/focus is suppressed |
| Click, back, slider, toggle | Short confirmation/return tones |
| Successful move / rotation / hold | Distinct ticks and chirps; blocked actions are silent |
| Soft drop | Quiet, rate-limited tick; ordinary gravity is silent |
| Lock / hard drop | Low impact; hard drops do not also play a lock sound |
| Clear 1 / 2 / 3 / 4 lines | Four ascending rewards, triggered when the clear flash begins |
| New level / game over | Short musical cues |
| Start / pause / resume | Matching transition cues |

`Gameplay` and `MenuScreen` emit `sound_requested`; `main.gd` connects them to the reusable `SoundPlayer` scene. Its six playback voices keep menu feedback separate from movement sounds and longer clear cues. It lives outside the gameplay node so clicks and menu sounds continue while gameplay is paused. The `SFX` bus controls effects; a Master hard limiter prevents clipping when music and effects overlap.

The effects are in `assets/audio/sfx/`. They are original procedural synthesis with no external samples.

## Screen scaling

The game is designed at 960×640 and scales to any window:

- On desktop, the window opens at 85% of the screen it starts on and is centred. It can be resized freely (minimum 480×320) and F11 switches to fullscreen.
- `canvas_items` stretch with `expand` aspect keeps text sharp at any size; wider or taller windows extend the background instead of letterboxing.
- Sprites use nearest filtering so the block art stays crisp.
- Web and mobile builds skip window sizing and fill the page or screen.

## Project layout

```
assets/
  sprites/blocks/     block_[ijlostz].png, ghost_block.png
  sprites/pieces/     piece_[ijlostz].png
  sprites/board/      board.png
  sprites/effects/    clear_flash.png
  ui/buttons/         button state textures used by the theme
  ui/controls/        slider and toggle textures
  ui/panels/          dialog, confirm, HUD, keycap and dim panels
  ui/icons/           UI icons
  audio/music/        block_hop.wav
  audio/sfx/          19 sound effects
scenes/
  main.tscn           entry point
  game/               gameplay.tscn, board.tscn, blocks/, pieces/, effects/
  menus/              main, pause, settings, how to play, game over, restart
  ui/                 reusable controls/ and panels/, title_mark.tscn
  audio/              music_player.tscn, sound_player.tscn
scripts/
  main/               main.gd (menu routing), profile_store.gd, screen_scaler.gd
  game/               gameplay.gd and the rules: matrix, active_piece, tetromino_data,
                      piece_bag, score_keeper, playfield, piece_preview, clear_flash
  menus/              menu_screen.gd (shared by every menu)
  audio/              music_player.gd, sound_player.gd
resources/            ui_theme.tres, audio_bus_layout.tres
tests/                gameplay_rules.gd, audio_feedback.gd
```

## Menus

Every menu scene uses `menu_screen.gd`. Buttons declare what they do with `metadata/action`, sliders and toggles bind to a saved setting with `metadata/setting`, and each menu's `cancel_action` property decides what Esc does. `main.gd` routes the actions.

## Tests

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/gameplay_rules.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/audio_feedback.gd
```

Run `tests/audio_feedback.gd` without `--headless` to also capture the actual native audio mix and check that full-volume overlapping effects do not clip and zero Sound produces silence. It uses a temporary test profile in `user://` and deletes it afterwards. Native audio was checked on macOS; browser and mobile audio have not been tested.
