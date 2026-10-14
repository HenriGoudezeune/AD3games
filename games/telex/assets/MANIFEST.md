# Asset-manifest — TELEX (Station Zoeklicht)

Paden relatief t.o.v. `res://games/telex/assets/`. Alles is **zelf gegenereerd** (`_gen/tx_gen_textures.py`,
`_gen/tx_gen_audio.py`, eigen werk, CC0) behalve de twee fonts (OFL, zie `CREDITS.md`). Stijlregels: `design/ART.md`.
Gedeeld met de hub (niet gekopieerd): `res://assets/fonts/` (Fredoka, JetBrains Mono), `res://assets/art/icons/` (Kenney).
SFX: mono WAV 44,1 kHz 16 bit, piek −1 dBFS. Lussen (`*_loop`): naadloos, "loop" aanzetten bij import of in code.
Varianten `_1/_2/_3`: kies willekeurig + `pitch_scale` 0,94–1,06.

## Fonts (`fonts/`)
| rol | bestand |
|---|---|
| lint, sjabloon, strook, papier, Chef (`TxPal.TAPE`, `TAPE_REG`) | `CourierPrime-Bold.ttf`, `CourierPrime-Regular.ttf` |
| typeplaatjes, titels op metaal, stempels (`TxPal.STENCIL`) | `SairaStencilOne-Regular.ttf` |

## Beeld (`art/`)
| bestand | maat | gebruik |
|---|---|---|
| `bg/bunker_wall.jpg` | 1920×1080 | console, titel, debrief |
| `bg/corkboard.jpg` | 1920×1080 | missiekaart |
| `bg/coast_map.jpg` + `bg/coast_map_points.txt` | 1200×760 | kustkaart (spelden, koeriers, ploeg; pixelposities van de steden in het txt) |
| `tex/paper_tile.png` · `hammertone.png` · `brushed.png` · `bakelite.png` · `grain.png` | 256² tileable, grijs | papier, lak, staal, bakeliet, filmkorrel |
| `stamps/missie_geslaagd.png` · `codewoord_ontsnapt.png` · `vals_alarm.png` · `geheim.png` · `treffer.png` · `ster.png` · `volle_stroom.png` · `gezien.png` | wit + alfa | debrief, kaart, combo (tinten) |
| `particles/snipper.png` · `punch_dot.png` · `spark.png` · `glow.png` · `soft.png` · `dust.png` · `smoke.png` · `straw.png` · `splinter.png` · `ink_splat.png` · `beam.png` · `ring.png` | wit | zie ART.md §8 |
| `shaders/tx_overlay.gdshader` | — | vignet + korrel + flikkering (schermoverlay) |
| `shaders/tx_sheen.gdshader` | — | glansstreep over messing |

## Geluid: console en lint (`sfx/`)
| event (GDD §7.1/§8.6 fx) | bestand | duur |
|---|---|---|
| teken binnen (`front`), matrixlog-typehamer | `tak_1.wav` · `tak_2.wav` · `tak_3.wav` | 0,09 s |
| naaldtik gelijk / verschil (`needle` per stap) | `needle_eq.wav` / `needle_ne.wav` | 0,06 / 0,12 s |
| tikteller per tik / elke 10e | `counter_click.wav` / `counter_klak.wav` | 0,03 / 0,08 s |
| treffer (`hit`) | `bell.wav` + `tube_fwoop.wav` + `stamp.wav` | 2,8 / 0,47 / 0,14 s |
| klem (`bump`), leeg vakje | `bump.wav` | 0,35 s |
| tanden klikken in | `teeth_in.wav` | 0,16 s |
| terugspoelen (`head` met rewind) | `rewind.wav` | 0,5 s |
| versnipperaar (lus, zacht) | `shredder_loop.wav` | 2,0 s lus |
| gemist (`missed`) | `missed.wav` | 4,6 s |
| vals alarm (`false_alarm`) | `false_alarm.wav` | 1,95 s |
| scheur (`tear`) | `tear.wav` | 0,55 s |
| lusbak bijna vol | `heartbeat.wav` (herhalen ~1,2 s) | 0,6 s |
| strook naar de Doorloper (`strip_move`) | `strip_slide.wav` | 0,64 s |

## Geluid: machines (`sfx/`)
| event | bestand | duur |
|---|---|---|
| hashwiel: één klik per tand (`wheel`) | `wheel_tooth.wav` | 0,03 s |
| −w grijpt in / +1 | `gear_engage.wav` / `plus_one.wav` | 0,2 / 0,12 s |
| alarmlampje (`alarm`, lus 3 Hz) | `alarm_loop.wav` | 1,0 s lus |
| ponsen (`punch`, `hole`) | `punch.wav` | 0,12 s |
| stempelen (`stamp`), debrief-stempel | `stamp.wav` | 0,14 s |
| sprong (`jump`) / landing | `jump.wav` / `land.wav` | 0,42 / 0,12 s |
| hendel (`lever`) | `lever.wav` | 0,37 s |
| kaart insteken (`card`) | `card_in.wav` | 0,15 s |
| lamp aan / gloeidraad (lus) | `lamp_on.wav` / `lamp_hum_loop.wav` | 0,22 s / 2,0 s lus |
| bel lampenbord/ruisbord (pitch 1,0 / 0,84 / 0,71 per M^l) | `bell.wav` | 2,8 s |
| foutkabel (`plug`) | `plug.wav` | 0,18 s |
| relais (`cell`) | `relay.wav` | 0,11 s |
| teruglopen (`trace_step`) | `trace_step.wav` | 0,21 s |
| herstelstrook / debrief typen | `typewriter.wav`, einde regel `carriage.wav` | 0,06 / 0,9 s |
| zoeklicht (`end_pick`) | `searchlight.wav` | 1,0 s |
| kist met nieuwe machine | `crate_open.wav` + `stinger_machine.wav` | 2,8 / 4,8 s |
| combo "Volle stroom" | `combo.wav` | 2,85 s |

## Geluid: UI, titel, debrief (`sfx/`)
| event | bestand | duur |
|---|---|---|
| knop indrukken / schakelaar / hover | `ui_key.wav` / `ui_switch.wav` / `ui_hover.wav` | 0,03–0,05 s |
| titel: TELEX wordt getypt | `telex_rattle.wav` (hamers + bel) | 4,2 s |
| titel-stinger (morse T-E-L-E-X) | `morse_telex.wav` | 3,7 s |
| ster 1 / 2 / 3 (stempel + stijgende bel) | `star_1.wav` · `star_2.wav` · `star_3.wav` | 2,4 s |
| debrief-jingle naar sterren (0 = mislukt) | `jingle_0.wav` … `jingle_3.wav` | 4–5 s |
| finale: gevonden ekster (koper) | `stinger_finale.wav` | 3,4 s |
| ambiance bunker (lus, stereo) | `ambience_loop.ogg` | 31 s lus |

## Muziek (`music/`, stereo OGG, naadloze lussen)
| bestand | BPM, lengte | gebruik |
|---|---|---|
| `title_jazz_loop.ogg` | 84, 45,7 s | titel, missiekaart, briefing |
| `calm_base_loop.ogg` + `calm_think_loop.ogg` | 76, 50,5 s (synchroon) | CALM; think-laag bij alarm of > 6 s denken |
| `live_drive_loop.ogg` + `live_tension_loop.ogg` | 112, 34,3 s (synchroon) | LIVE; tension bij lusbak > 60 % |
| `rhythm_100_loop.ogg` | 100, 19,2 s | ritmesectie 5-3 |
