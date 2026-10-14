# Asset-manifest: Kortschrift

Paden relatief tegenover `res://games/scriptorium/assets/`. Stijl en mix: `design/ART.md`. Licenties: `CREDITS.md`.
Alles is zelf gegenereerd (`_gen/sc_gen_textures.py`, `_gen/sc_gen_audio.py`, deterministisch) behalve de twee fonts (OFL).
Gedeelde assets van de repo (Fredoka, JetBrains Mono, Kenney-UI-geluiden via `Sfx.ui`, partikel `ring`) worden verwezen, niet gekopieerd.

Opnieuw genereren: `python -I games/scriptorium/assets/_gen/sc_gen_textures.py games/scriptorium/assets` (en `sc_gen_audio.py`);
daarna `$G --headless --path . --import` en de loop-vlaggen nakijken (OGG `loop=true` in de `.import` van de `*_loop.ogg`,
WAV `edit/loop_mode=2` voor `candle_loop.wav`).

## Beeld
| bestand | gebruik |
|---|---|
| `art/bg/bg_desk.jpg` | werkbank (1920×1080), kaars linksboven, raamlicht rechtsboven |
| `art/bg/bg_desk_night.jpg` | Nachtwake, kaars linksonder (x 210, y 930) |
| `art/bg/bg_room.jpg` | titel, getijdenboek, voorlezing-scène: scriptorium met glas-in-lood (raam x 960), kaarsen op het blad x 230 / 1690, y 905 |
| `art/bg/bg_overkant.jpg` | De Overkant (640×680): koele nis, oculus met maan en duiventil; als TextureRect op x 1280 |
| `art/tex/vellum.png`, `wood.png`, `leather.png` | naadloze grijswaarde-detailtexturen (getint via `ScDraw.tex_poly`) |
| `art/particles/*.png` | `glow_warm dust ember ink_drop wax_drop ink_splat feather scrap shaving straw gold_flake smoke flame light_pool wax_crumb` (wit) |
| `art/shaders/sc_candlelight.gdshader` | kaarslicht-vignet (`ScUi.candle_overlay`) |
| `art/shaders/sc_light_shafts.gdshader` | lichtbundels + stof (`ScUi.shafts_overlay`) |
| `art/shaders/sc_ink_reveal.gdshader` | inkt vloeit in (`progress`) |
| `fonts/GrenzeGotisch-Variable.ttf` | titels (`ScPal.TITLE`, gewicht 700/500) |
| `fonts/UnifrakturMaguntia-Book.ttf` | verluchte initialen (`ScPal.INITIAL`) |

## Geluid: gameplay (`sfx/`, mono WAV 44,1 kHz 16-bit, piek −1 dBFS, met korte galm)
| gebeurtenis (GDD §7.1 #) | bestand | duur |
|---|---|---|
| bit 0 schrijven: kort krasje (#2) | `sfx/quill_0.wav` | 0.67 s |
| bit 1 schrijven: lang krasje (#2) | `sfx/quill_1.wav` | 0.77 s |
| letter in de opdrachtband / kopie (#1, #27) | `sfx/quill_letter.wav` | 0.78 s |
| druppel in de inktpot (inktteller) | `sfx/ink_drip.wav` | 1.07 s |
| inktpot borrelt: boven het optimum (#4) | `sfx/ink_bubble.wav` | 0.60 s |
| inktvlek: anders gelezen letter (#11, #13) | `sfx/ink_blot.wav` | 1.02 s |
| lakzegel drukt: ruwe letter, brief (#3) | `sfx/wax_seal.wav` | 0.90 s |
| wassen zegel (p,l,x) (#26) | `sfx/seal_plop.wav` | 0.75 s |
| binden: touw knarst + knoop (#7) | `sfx/twine_bind.wav` | 1.17 s |
| touwklos draait (#8) | `sfx/twine_spool.wav` | 0.45 s |
| klem: houten tok + veer (#6) | `sfx/clamp.wav` | 0.97 s |
| knippen: codeboom-strook, meetlat (#5, #20) | `sfx/scissors.wav` | 0.78 s |
| wissel: voetstappen op steen (#15) | `sfx/steps.wav` | 2.34 s |
| kaartjes ritselen / wisselen (#15) | `sfx/cards.wav` | 0.30 s |
| gewicht +1 (pitch per niveau) (#16) | `sfx/weight_bell.wav` | 1.96 s |
| nng kiemt: pling + hout (#17) | `sfx/grow.wav` | 1.66 s |
| monnik struikelt "oei" (#18) | `sfx/stumble.wav` | 1.49 s |
| naaldstap (#22) | `sfx/needle_tick.wav` | 0.60 s |
| naald in het goud (#22) | `sfx/needle_gold.wav` | 2.36 s |
| speld prikt (#23) | `sfx/pin.wav` | 0.58 s |
| meetlat zoomt / zoomtunnel (#20, #21) | `sfx/ruler_zoom.wav` | 1.56 s |
| leesraam schuift (#24) | `sfx/window_slide.wav` | 1.07 s |
| draad per letter, pitch stijgend (#25) | `sfx/thread_pluck.wav` | 1.44 s |
| stempel ploft (#29) | `sfx/stamp.wav` | 1.02 s |
| lade schuift open (#28, #29) | `sfx/drawer.wav` | 1.20 s |
| nieuwe stempel snijden (#29) | `sfx/carve.wav` | 1.10 s |
| lege lade: speciaal geval (#30) | `sfx/drawer_empty.wav` | 1.96 s |
| trommel draait één rotatie (#31) | `sfx/drum_turn.wav` | 1.14 s |
| strook in het rek (#32), terugweg-pijl (#33) | `sfx/strip_slide.wav` | 0.27 s |
| letterplank: blokje naar voren (#34) | `sfx/block_slide.wav` | 0.25 s |
| cijferstempel (#34) | `sfx/number_stamp.wav` | 0.72 s |
| duif vertrekt (#10) | `sfx/pigeon_fly.wav` | 1.86 s |
| duif koert (#10, idle) | `sfx/pigeon_coo.wav` | 2.43 s |
| duif landt (duiventil #35) | `sfx/pigeon_land.wav` | 1.15 s |
| Letterlijk schraapt zijn keel (#11) | `sfx/throat.wav` | 1.30 s |
| letterzang, klinker a (pitch per letter) (#11) | `sfx/sing_a.wav` | 1.62 s |
| letterzang, klinker o | `sfx/sing_o.wav` | 1.62 s |
| letterzang, klinker e | `sfx/sing_e.wav` | 1.62 s |
| voorlezing juist: klok 3 slagen + koor (#12) | `sfx/reading_ok.wav` | 8.10 s |
| voorlezing onzin: dissonant + kan valt (#13) | `sfx/reading_bad.wav` | 2.84 s |
| kloosterklok, één slag | `sfx/bell.wav` | 5.68 s |
| kaars aansteken (Nachtwake start) | `sfx/candle_light.wav` | 1.10 s |
| kaars uitgeblazen: leven kwijt | `sfx/candle_out.wav` | 1.22 s |
| Volle vlam (#39) | `sfx/candle_flare.wav` | 2.74 s |
| kaarsgeknister, lus (Nachtwake, −14 dB) | `sfx/candle_loop.wav` | 4.00 s |
| kist opent: nieuw werktuig (#37) | `sfx/crate_open.wav` | 1.94 s |
| brief: zegel breekt | `sfx/letter_open.wav` | 1.08 s |
| codeboek / brief ontrolt (#9) | `sfx/unroll.wav` | 1.42 s |
| getijdenboek bladert, UI | `sfx/page_turn.wav` | 1.17 s |
| ster 1 (lakzegel + koor) (#36) | `sfx/star_1.wav` | 3.04 s |
| ster 2 | `sfx/star_2.wav` | 3.04 s |
| ster 3 | `sfx/star_3.wav` | 3.04 s |
| combo / koornoot (Nachtwake) | `sfx/choir_note.wav` | 2.84 s |
| houten UI-klik | `sfx/ui_wood.wav` | 0.08 s |
| paneel schuift in | `sfx/ui_whoosh.wav` | 0.30 s |
| sfeer scriptorium: geknister, wind, veer, verre duif (lus, −16 dB) | `sfx/amb_scriptorium_loop.ogg` | 23.0 s |

UI-klik/hover blijven `Sfx.ui("click")` / `Sfx.ui("hover", -10)` (Kenney, familie); `ScUi.button` doet dit al.

## Muziek (`music/`, stereo OGG Vorbis, naadloze lussen, D-dorisch)
| scherm | bestand | duur |
|---|---|---|
| titel, getijdenboek | `music/sc_title_loop.ogg` | 58.2 s |
| werkbank (basis) | `music/sc_bench_loop.ogg` | 53.3 s |
| werkbank denklaag (synchroon, na 8 s) | `music/sc_bench_pad_loop.ogg` | 53.3 s |
| Nachtwake | `music/sc_wake_loop.ogg` | 43.6 s |
| Nachtwake hartslag (synchroon, weinig kaars) | `music/sc_wake_heart_loop.ogg` | 43.6 s |
| De Codex | `music/sc_codex_loop.ogg` | 58.2 s |
| terugblik 1 ster / 0 ster | `music/sc_jingle_1.ogg` | 6.0 s |
| terugblik 2 sterren | `music/sc_jingle_2.ogg` | 6.4 s |
| terugblik 3 sterren | `music/sc_jingle_3.ogg` | 7.7 s |
