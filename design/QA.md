# Hash & Dash — QA-rapport (playtest v1, commit ab11e51)

Eigenaar: QA-playtester. Lezers: front-end (gameplay), core, designer.
Status: **tussentijds** (wordt aangevuld). Frames: `design/qa_frames/` (JPEG-kopieën van `--write-movie`-opnames, 1600×900).

Commando's (alle vanuit de projectmap, `G = C:\Users\henri\tools\godot\Godot_v4.7.2-stable_win64_console.exe`):
- tests: `"$G" --headless --path . --script res://tests/run_tests.gd`
- headless dag: `"$G" --headless --path . res://scenes/depot.tscn -- --day=N --bot --quit-after-day --speed=4 [--mistake]`
- opname: `"$G" --path . --resolution 1920x1080 --write-movie <map>/f.png --fixed-fps 30 --quit-after <frames> res://scenes/depot.tscn -- --day=N --bot`
  (framenummers hieronder = `f%08d.png` uit zo'n opname, 30 fps)
- menselijke input: QA-script `human.gd` (zie §5), stuurt echte `InputEventMouseButton/Motion` en `InputEventKey`.

## 1. Functioneel (samenvatting)
- `tests/run_tests.gd`: **866 asserts groen** (2,1 s). Bij afsluiten: `WARNING: 12272 ObjectDB instances were leaked` +
  `ERROR: 9 resources still in use at exit` (zie P2-x).
- Dag 1–7 headless met bot, met en zonder `--mistake`: **geen crash, geen SCRIPT ERROR, geen vastloper**; elke run
  eindigt met `DAY_DONE`. Perfecte bot: overal ★★★ en L/S = optimum. Enige console-`ERROR` = lekken bij afsluiten.
- Endless (`--day=0 --bot --speed=4`, 5400 frames ≈ 12 speelminuten): geen fouten in de console.

(buglijst volgt)
