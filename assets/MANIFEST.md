# Asset-manifest — Hash & Dash

Paden relatief t.o.v. `res://assets/`. "gen" = zelf gegenereerd (`_gen/gen_audio.py`, `_gen/gen_textures.py`),
"K" = Kenney (CC0). Zie `CREDITS.md`. Stijlregels: `design/ART.md`.
Varianten `_1/_2/_3`: kies random + `pitch_scale` 0,92–1,08.

## Fonts (`fonts/`)
| rol | bestand |
|---|---|
| bitlabels, cijfers, timers | `fonts/JetBrainsMono-ExtraBold.ttf` (ook `-Bold`, `-Medium`) |
| titels, HUD, knoppen | `fonts/Fredoka-Bold.ttf` |
| UI-tekst | `fonts/Fredoka-SemiBold.ttf`, `fonts/Fredoka-Medium.ttf` |

## Geluid: gameplay (`sfx/`, mono WAV 44,1 kHz, piek −1 dBFS)
| event (GDD §8/§9) | bestand | duur | bron |
|---|---|---|---|
| pakje landt op band | `sfx/band_land.wav` · alt. `sfx/kenney/drop_box_1..3.ogg` | 0,12 s | gen / K |
| pakje oppakken | `sfx/pickup.wav` (+ evt. `sfx/kenney/paper_slide.ogg` zacht eronder) | 0,12 s | gen / K |
| pakje loslaten (niet op luik) | `sfx/drop_soft.wav` · `sfx/kenney/drop_box_1..3.ogg` | 0,12 s | gen / K |
| bit getypt (positie 1..6, stijgende toon) | `sfx/key_bit_1.wav` … `sfx/key_bit_6.wav` | 0,09 s | gen |
| luik klapt open | `sfx/kenney/hatch_flap.ogg` | 0,25 s | K |
| in luik vallen + buis + plof (alles-in-één) | `sfx/hatch_drop.wav` | 0,48 s | gen |
| buis-puls ("fwoemp", pan volgt buis) | `sfx/tube_whoosh.wav` | 0,45 s | gen |
| aankomst in rek (houten tok) | `sfx/kenney/rack_place_1..3.ogg` · alt. `sfx/rack_place.wav` | 0,27 s | K / gen |
| rek vol / vastloper (bzzt-bzzt + klank) | `sfx/rack_full.wav` | 0,50 s | gen |
| alarm/sirene (lus) | `sfx/alarm_loop.wav` (loop aan) | 1,0 s | gen |
| slow-mo in / uit | `sfx/tape_stop.wav` / `sfx/tape_start.wav` | 0,6 s | gen |
| hendel (ratel + zware klik) | `sfx/lever.wav` | 0,67 s | gen |
| **muur verbreden** (motor, ratel, hydrauliek, klap, bel) | `sfx/wall_expand.wav` | 4,35 s (klap op 1,8 s) | gen + K-laag |
| eindaanslag (a = n) | `sfx/end_stop.wav` | 1,8 s | gen + K-laag |
| zaag (rek bijbouwen) | `sfx/saw.wav` | 0,45 s | gen |
| rek gesplitst ("nieuw rek!", ratel + 2 noten) | `sfx/split.wav` | 1,9 s | gen |
| zaag op één buis ("klonk" + boing) | `sfx/saw_clonk.wav` | 0,58 s | gen |
| buizen omzetten (één klik per buis) | `sfx/pipe_click.wav` | 0,08 s | gen |
| verdelen naar 0 / 1 | `sfx/sort_0.wav` (lage zwiep) / `sfx/sort_1.wav` (hoge zwiep) | 0,18 s | gen |
| heftruck-rit (= schijftoegang L/S) | `sfx/warehouse_trip.wav` | 0,9 s | gen |
| leeg rek na zaag (holle galm) | `sfx/hollow_echo.wav` | 3,3 s | gen |
| verdwaald / verkeerd luik (dof piepje) | `sfx/mistake.wav` | 0,3 s | gen |
| burst / pakje kwijt | `sfx/burst.wav` + `sfx/package_lost.wav` | 0,45 / 0,95 s | gen |
| hart breekt (reputatie −1) | `sfx/heart_break.wav` | 0,68 s | gen |
| klant komt (deurbel) | `sfx/customer_arrive.wav` | 2,6 s (galm) | gen |
| scanner gevonden / niet gevonden | `sfx/scan_ok.wav` / `sfx/scan_fail.wav` | 0,25 s | gen |
| klant blij | `sfx/customer_happy.wav` (+ `sfx/coin.wav`) | 1,4 s | gen |
| klant boos (zucht/grom) | `sfx/customer_angry.wav` | 0,6 s | gen |
| munt (+10) | `sfx/coin.wav` | 0,38 s | gen |
| veel munten (rapport, fooi) | `sfx/kenney/coins_payout.ogg` | 0,37 s | K |
| combo-stap ×1..×5 | `sfx/combo_1.wav` … `sfx/combo_5.wav` | 1,7 s | gen |
| combo ×5 "DASH!" | `sfx/dash.wav` | 2,4 s | gen |
| klok laatste 10 s | `sfx/timer_tick.wav` | 0,04 s | gen |
| band-gezoem (lus, pitch ∝ snelheid) | `sfx/conveyor_loop.wav` (loop aan) | 1,95 s | gen |
| dag gehaald (fanfare) | `sfx/day_complete.wav` · kort: `music/kenney/stinger_success.ogg` | 3,6 / 0,9 s | gen / K |
| dag gefaald (wah-wah) | `sfx/day_failed.wav` · kort: `music/kenney/stinger_fail.ogg` | 2,9 / 1,3 s | gen / K |
| dag start | `music/kenney/stinger_day_start.ogg` | 0,8 s | K |
| ster 1 / 2 / 3 in rapport (stijgend) | `sfx/star_1.wav` / `star_2.wav` / `star_3.wav` | 2,2 s | gen |
| zware metalen klap (los, voor eigen combinaties) | `sfx/kenney/metal_heavy.ogg` | 0,12 s | K |

## Geluid: UI (`sfx/kenney/`, OGG)
| event | bestand |
|---|---|
| klik / bevestigen | `ui_click.ogg` / `ui_confirm.ogg` |
| hover | `ui_hover.ogg` |
| terug / sluiten / openen paneel | `ui_back.ogg` / `ui_close.ogg` / `ui_open.ogg` |
| toggle (instellingen) | `ui_toggle.ogg` |
| niet toegestaan (bv. slot op Eindeloos) | `ui_error.ogg` |
| paneel schuift in (dagrapport, sorteertafel) | `sfx/ui_whoosh.wav` (gen) |

## Muziek (`music/`, stereo OGG, alle lussen naadloos, loop staat aan in .import)
| gebruik | bestand | tempo / lengte |
|---|---|---|
| in-game laag **basis** (altijd) | `music/layer_base_loop.ogg` | 100 BPM, 16 maten, 38,4 s |
| in-game laag **drukte** | `music/layer_busy_loop.ogg` | idem, synchroon starten |
| in-game laag **spanning** (alarm) | `music/layer_tension_loop.ogg` | idem |
| titel / dagkaart (rustig) | `music/depot_calm_loop.ogg` | 96 BPM, 40 s |
| endless "Piekdag" | `music/depot_rush_loop.ogg` | 128 BPM, 30 s |

## Texturen (`art/`)
| element | bestand | afmeting |
|---|---|---|
| zachte cirkel / gloed | `art/particles/soft_circle.png` / `glow.png` | 64² / 128² |
| stip / ring | `art/particles/dot.png` / `ring.png` | 64² |
| ster (afgerond) | `art/particles/star.png` | 128² |
| glinster (4 punten) | `art/particles/sparkle.png` | 64² |
| confetti / kartonsnipper | `art/particles/confetti.png` | 32² |
| stofwolkje | `art/particles/puff.png` | 96² |
| zachte schaduw-ellips | `art/particles/shadow_blob.png` | 128×64 |
| rook (muur verbreden) | `art/particles/k_smoke_04.png` (K) | 128² |
| lichtflits / vonk | `art/particles/k_light_02.png` (K) | 128² |
| ster-flare | `art/particles/k_star_06.png` (K) | 128² |
| swoosh (DASH) | `art/particles/k_twirl_02.png` (K) | 128² |
| UI-iconen (wit, tint via modulate) | `art/icons/{pause,home,return,next,gear,audioOn,audioOff,musicOn,musicOff,checkmark,cross,warning,exclamation,information,question,locked,unlocked,fastForward,star,trophy,medal1,wrench}.png` (K) | 100² |

Pakjes, luiken, rekken, buizen, band, hendel, klanten, munten, hartjes, heftruck: **in code getekend**
(zie `scripts/game/art_preview.gd`). Daar zijn geen sprites voor nodig.

## Opnieuw genereren
```
python -I assets/_gen/gen_audio.py <map met uitgepakte Kenney-packs> assets <map met python-pakket soundfile> [namen...]
python -I assets/_gen/gen_textures.py assets
```
Na het opnieuw genereren van lussen: controleer of `loop=true` (OGG) of `edit/loop_mode=2` (WAV) nog in hun
`.import` staat.
