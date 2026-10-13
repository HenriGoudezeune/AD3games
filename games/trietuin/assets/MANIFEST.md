# Asset-manifest: Trietuin

Paden zijn relatief tegenover `res://games/trietuin/assets/`. Stijlregels: `design/ART.md`. Licenties: `CREDITS.md`.
Alles hier is zelf gegenereerd (CC0, `_gen/`). Gedeelde assets van de repo (fonts, Kenney-iconen,
Kenney-UI-geluiden, enkele partikels) worden **verwezen**, niet gekopieerd. Ze staan onderaan.

## Afspelen
- In de game via **`TtSnd`** (`scripts/game/tt_snd.gd`, front-end): `TtSnd.play("fruit_plop")`,
  `TtSnd.letter(ch, letters)` (lettertik pentatonisch getransponeerd), `TtSnd.note(ch)` (parelnoten),
  `TtSnd.season_music(s)` (basis + bloei + sfeerlus), `TtSnd.bloom_layer(on)`, `TtSnd.jingle(n)` en
  `TtSnd.loop("bee", "bee_buzz_loop", on)`. Het gebruikt de bussen Music/SFX/UI van de gedeelde autoload `Sfx`.
- UI-klik/hover: `Sfx.ui("click")` / `Sfx.ui("hover", -10)` (Kenney, gedeeld met Hash & Dash). `TtUi.button` doet dit
  al.
- Herhaalde geluiden krijgen een `pitch_scale` random 0,94–1,06, max 4–5 tegelijk. De sapdruppel zakt mee met het
  niveau: `pitch_scale = 0,8 + 0,4 × niveau`.
- Lussen staan al op loop in hun `.import` (WAV `edit/loop_mode=2`, OGG `loop=true`). Na het opnieuw genereren moet je
  dat nakijken.

## Geluid: gameplay (`sfx/`, mono WAV 44,1 kHz 16-bit, piek −1 dBFS)
| GDD-event (§7.1 # / §7.2) | bestand | duur |
|---|---|---|
| zaadje landt (#1) | `sfx/seed_land.wav` | 0,16 s |
| letter volgen / typen (#2) | `sfx/letter_tick.wav` (C5; `TtSnd.letter` transponeert pentatonisch) | 0,25 s |
| knop gaat open / mini-plop per knop (#3, #4) | `sfx/bud_plop.wav` | 0,14 s |
| vrucht groeit ("plop" + glas-tingel) (#3) | `sfx/fruit_plop.wav` | 1,25 s (galm) |
| top groeit: krakend hout dat rekt (#4) | `sfx/grow_wood.wav` | 0,70 s |
| sap uitgeven (#5) | `sfx/sap_drop.wav` (toonhoogte zakt mee met het niveau) | 0,78 s |
| sap stroomt terug / compost (#18) | `sfx/sap_return.wav` | 0,78 s |
| lint rolt open (#6) | `sfx/ribbon_roll.wav` | 0,33 s |
| j geknipt in het lint (#7) | `sfx/snip.wav` | 0,18 s |
| klonk: fysiek onmogelijk (#8) | `sfx/clonk.wav` | 0,50 s |
| bij vliegt (#9), lus | `sfx/bee_buzz_loop.wav` (loop; −16 à −20 dB) | 1,0 s |
| pluk correct: ding + honingslurp (#10) | `sfx/pick_ok.wav` | 1,40 s |
| bij blij / gevonden | `sfx/bee_happy.wav` | 1,36 s |
| niet hier: neuriënd "hmm" (#11) | `sfx/bee_hmm.wav` | 0,55 s |
| lege knop bereikt: zachte bonk (#12) | `sfx/bee_bonk.wav` | 0,18 s |
| fout-zoem (zacht, geen buzzer): algemene misstap | `sfx/buzz_soft.wav` | 0,42 s |
| verkeerde honing: koningin zoemt omlaag + morst (#13) | `sfx/queen_frown.wav` | 0,80 s |
| wesp ontmaskerd: sissen + triomfstinger (#14) | `sfx/wasp_reveal.wav` | 1,91 s |
| wesp steelt: vleugels + dalend motief (#15) | `sfx/wasp_steal.wav` | 1,00 s |
| onvindbare vrucht rot (#16) | `sfx/rot.wav` | 0,90 s |
| snoeischaar (#17) | `sfx/shears.wav` | 0,47 s |
| afgeknipte tak valt (#18) | `sfx/branch_fall.wav` | 0,62 s |
| ent: bastwikkel + klik (#22) | `sfx/graft.wav` | 0,73 s |
| rank groeit: krullend strijkje (#23) | `sfx/tendril.wav` | 1,10 s |
| ASCII-storm: wind, krakend hout, glas (#25) | `sfx/storm.wav` | 2,60 s |
| slinger / parel aanrijgen (#26) | `sfx/pearl_tick.wav` | 0,35 s |
| parelnoten finale (a=C, c=E, g=G, t=A, b=D, _=hoge C) | `sfx/note_a.wav`, `note_c`, `note_g`, `note_t`, `note_b`, `note_end` (`TtSnd.note(ch)`) | 1,9 s |
| mist (#29), lus | `sfx/mist_loop.wav` (loop) | 7,5 s |
| inspecteur: voetstapjes / loep / stempel (#30) | `sfx/steps.wav` / `sfx/loupe.wav` / `sfx/stamp.wav` | 0,5 / 1,3 / 0,26 s |
| hond kwispelt / blaft (#30) | `sfx/dog_happy.wav` / `sfx/dog_bark.wav` | 0,49 / 0,42 s |
| Ukkonen: `it` (alle bladeren groeien) (#31) | `sfx/chord_it.wav` | 2,40 s |
| suffix link klikt vast (#33) | `sfx/link_twang.wav` | 0,50 s |
| Bloei: crescendo (#35) | `sfx/bloom.wav` | 3,28 s |
| Bloei: belletje per geslaagde bij (#35) | `sfx/bee_bell.wav` (pitch_scale stijgend 1, 1,12, 1,26 …) | 1,20 s |
| ster 1 / 2 / 3 (#36) | `sfx/star_1.wav` / `star_2.wav` / `star_3.wav` | 2,36 s |
| honing (+floater, korf pulst) | `sfx/honey.wav` | 0,46 s |
| seizoenswissel (windgong) | `sfx/season_change.wav` | 4,04 s |
| de Uil verschijnt (oehoe) | `sfx/owl.wav` | 1,61 s |
| paneel schuift in (rapport, notas) | `sfx/ui_whoosh.wav` | 0,28 s |

## Sfeerlussen (`sfx/`, mono OGG, 16 s, naadloos, loop aan, −14 dB)
| seizoen | bestand | inhoud |
|---|---|---|
| lente | `sfx/amb_lente_loop.ogg` | vogeltjes in de verte, zachte wind |
| zomer | `sfx/amb_zomer_loop.ogg` | krekels |
| herfst | `sfx/amb_herfst_loop.ogg` | wind + ritselende bladeren |
| winter | `sfx/amb_winter_loop.ogg` | zachte wind, sneeuwkraak, verre belletjes |

## Muziek (`music/`, stereo OGG Vorbis, naadloze lussen, loop aan)
Basis en bloei van één seizoen zijn **even lang en synchroon**: start beide tegelijk en fade enkel het volume
(basis ± −6 dB; bloei −80 → ± −6 dB bij Bloei en rapport). De basislagen zijn genormaliseerd op RMS −19 dBFS.
| gebruik | bestand | tempo / lengte |
|---|---|---|
| Lente: basis / bloei | `music/tt_lente_loop.ogg` / `music/tt_lente_bloom_loop.ogg` | 92 BPM, 16 maten, 41,7 s |
| Zomer: basis / bloei | `music/tt_zomer_loop.ogg` / `music/tt_zomer_bloom_loop.ogg` | 100 BPM, 38,4 s |
| Herfst: basis / bloei | `music/tt_herfst_loop.ogg` / `music/tt_herfst_bloom_loop.ogg` | 84 BPM, 45,7 s |
| Winter: basis / bloei | `music/tt_winter_loop.ogg` / `music/tt_winter_bloom_loop.ogg` | 76 BPM, 50,5 s |
| Titel / seizoenkaart | `music/tt_title_loop.ogg` | 84 BPM, 45,7 s |
| Finale (Ukkonen) | `music/tt_finale_loop.ogg` (C-pentatonisch, past onder de parelnoten) | 90 BPM, 42,7 s |
| Rapport-jingle 1 / 2 / 3 sterren | `music/tt_jingle_1.ogg` / `_2` / `_3` (geen lus) | 3,1–3,5 s |

## Texturen (`art/`)
| element | bestand | afmeting | gebruik |
|---|---|---|---|
| achtergrond per seizoen | `art/bg/bg_lente.jpg`, `bg_zomer.jpg`, `bg_herfst.jpg`, `bg_winter.jpg` | 1920×1080 | `TextureRect`, onderste laag (`TtPal.bg_path(s)`) |
| grasrand vooraan | `art/bg/fg_<seizoen>.png` | 1920×180 | onderaan, boven de stambasis, onder de UI (`TtPal.fg_path(s)`) |
| wolken (wit) | `art/bg/cloud_1.png` / `cloud_2.png` | 360×150 / 260×120 | `Sprite2D`, traag drijvend, 's nachts 35 % |
| blad (puntig) / rond blaadje | `art/particles/leaf.png` / `leaf_round.png` | 64² | herfst-sfeer, groei-burst |
| bloemblaadje | `art/particles/petal.png` | 48² | lente-sfeer, sterren-regen |
| sneeuwvlok | `art/particles/snowflake.png` | 64² | winter-sfeer |
| stuifmeel / zachte stip | `art/particles/pollen.png` | 32² | zomer-sfeer (add), groei, bijenspoor |
| sapdruppel | `art/particles/drop.png` | 64² | sap uitgeven / terug |
| zaadje | `art/particles/seed.png` | 48² | zaadje waait aan (windrij) |
| houtsnipper | `art/particles/chip.png` | 32² | snoeien, knippen |
| vuurvliegje-gloed | `art/particles/firefly.png` | 64² | Ukkonen-spoor, winternacht (add) |
| twinkel (4 punten) | `art/particles/twinkle.png` | 64² | vrucht rijpt, gevonden, sterren (add) |
| belletje (sap/zeep) | `art/particles/bubble.png` | 48² | sapbuis, honing |
| mist-shader | `art/shaders/tt_mist.gdshader` | – | `ColorRect` boven de slinger (level 4-4) |

Takken, knoesten, knoppen, vruchten, labels, linten, sapbuis, bijen, wesp, korf, Uil, Egel, hond, vuurvliegje,
slinger, rankknopen, potten, sterren en stempel worden **in code getekend** (`scripts/game/tt_draw.gd`). Daar zijn geen
sprites voor nodig.

## Gedeelde assets (verwijzing, niet gekopieerd)
| wat | pad | gebruik in Trietuin |
|---|---|---|
| fonts | `res://assets/fonts/JetBrainsMono-{ExtraBold,Bold,Medium}.ttf`, `Fredoka-{Bold,SemiBold,Medium}.ttf` | via `TtPal` (mono als MSDF) |
| UI-iconen (Kenney Game Icons, wit) | `res://assets/art/icons/{pause,home,return,next,gear,audioOn,musicOn,…}.png` | `TtUi.icon_button("pause")` |
| UI-geluiden (Kenney Interface Sounds) | `res://assets/sfx/kenney/ui_*.ogg` | `Sfx.ui("click")`, hover, back … |
| partikels | `res://assets/art/particles/{ring,glow,sparkle,star,puff,confetti}.png` | `TtFx.ring_wave`, `TtFx.poof`, fallback in `TtFx._tex` |

## Opnieuw genereren
```
python3 -I games/trietuin/assets/_gen/tt_gen_textures.py games/trietuin/assets
python3 -I games/trietuin/assets/_gen/tt_gen_audio.py games/trietuin/assets [namen | music | amb]
```
Vereist: Python 3 met `numpy`, `Pillow`, `scipy` en `soundfile` (`pip install numpy pillow scipy soundfile`). Alles
is deterministisch. Daarna `godot --headless --path . --import` en kijk de loop-vlaggen in de `.import`-bestanden na
(zie boven). Totale grootte van `games/trietuin/assets`: ± 13 MB.
