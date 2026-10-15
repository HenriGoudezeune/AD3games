# Trietuin — QA-rapport (playtest v1)

Eigenaar: QA-playtester (en fixer). Lezers: lead, front-end, core. Status: **in uitvoering**.

**Commando's** (vanuit de repo-root, `G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64`):
- core-tests: `$G --headless --path . --script res://games/trietuin/tests/run_tests.gd`
- **headless level-run** (nieuw, `tests/qa_run.gd`): speelt één level in de echte tuin-scène met de front-end-bot en
  drukt `QA_RESULT` (sterren, honing, misstappen, Bloei) + elke coachzin/notasverwijzing + elke mislukte Bloei-bij af:
  `$G --headless --path . --audio-driver Dummy --script res://games/trietuin/tests/qa_run.gd -- level=2-2 bot=errors speed=8`
  (± 5 s per level). Met `shot=<pad.png>` (+ xvfb/opengl3) maakt hij een schermafdruk van het rapport; `qa_replay=1`
  opent eerst de eerste misstap.
- frames: `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --audio-driver Dummy
  --resolution 1920x1080 res://games/trietuin/scenes/garden.tscn -- level=X bot=perfect shots=<map> shot_every=4 quit_at=60`

---

## 1. Samenvatting

| | |
|---|---|
| Core-tests | 1229 asserts groen (ook na de fixes hieronder) |
| Headless sweep | 21 levels (20 + vrije tuin) × `perfect`/`errors`/`random`: **geen SCRIPT ERROR / ERROR**, geen vastloper. Perfect = ★★★ en Bloei 100 % op elk level |
| Leerstof | figuren 13–19, Algoritme 1, ternary-volgorde, (b,e)-labels, Ukkonen-eindbomen en paginaverwijzingen nagekeken tegen de notas |

## 2. Bevindingen

### P0 — fout tegen de leerstof

**P0-1 · Coachzin "Na `t` volgt `niets`" terwijl er wél takken vertrekken** — *gefixt*
- *Repro:* `qa_run -- level=4-4 bot=errors`: vraag "Komt `ttt` voor?" → loep op de wortel/`t` → coachzin
  "Na `t` volgt `niets`, niet `t`". Ook Ukkonen (`5-2`/`5-3 bot=random`): "Na `∅` komt in de boom `niets`, niet `g`",
  terwijl de wortel takken `a`, `c` heeft.
- *Fout:* in een top volgt niet "niets": er vertrekken takken, alleen geen met dat teken (notas p. 38 geval (ii): "er
  is geen tak die met s_{i+1} begint").
- *Fix:* core geeft bij een top `at_node` + de beginletters van de takken mee (`tt_suffix_tree._do_locate`,
  `tt_ukkonen._do_rule`); coachzinnen: "Na `t` beginnen de takken met `c/g`, geen met `t`." en
  "Na `b`: takken `a/b`, geen `c`. Uitbreiden (ii)." / "Na `∅` vertrekt nog geen tak: uitbreiden (ii)."

**P0-2 · Paginaverwijzing Figuur 19 fout (p. 33 i.p.v. p. 34)** — *gefixt*
- 4-2 "Figuur 19 · notas p. 33, 48" en 5-3 "… notas p. 33, 38–43" (kaart-tooltip, HUD, rapport). Figuur 19 staat op
  p. 34 (pdf-pagina = gedrukte pagina). Nu "p. 34, 48" en "p. 33–34, 38–43".

**P0-3 · Ukkonen: de vraag verklapte de beslissing "springen of niet"** — *gefixt*
- In fase U_CANON stond er "x̄ = 2 ≥ booglengte: spring naar de top aan het eind (klik)" met een groene Spring-knop;
  in fase U_RULE een andere vraag en een grijze Spring-knop. Je hoefde dus nooit zelf x̄ met de booglengte te
  vergelijken (notas p. 41–42), terwijl dat net de les is (en de foutmodus WRONG_HOP bestaat).
- *Fix:* beide fasen tonen nu dezelfde vraag ("x̄ = 2 · volgt na het vuurvliegje al `b`?") en dezelfde knoppen
  (Spring / Zit er al / Groei!). Extra: Spring op een top (x̄ = 0) gaf de coachzin "x̄ = 0 ≥ lengte 0: spring" →
  nu "het vuurvliegje staat al op een top, er valt niets te springen".

### P1 — storend, verwarrend of ontbrekend

**P1-1 · Levelweetjes (bindende lead-beslissingen 1, 3, 10, 13) verschenen nergens** — *gefixt*
- `spec.extra` (`did_you_know` 4-2/5-3, `oef28a` 4-4, `link_order` 5-1, `rule` 3-1, `report` 1-1/1-3/2-3/3-4) werd door
  geen enkele front-end-code gelezen. De terugblik toont nu rechtsonder een papieren kader "Wist je dat? / Ontdekking /
  Volgorde / Afspraak / Uil" (`tt_report._draw_weetje`).
- Teksten gecorrigeerd: 1-1 beweerde vast "Jouw boom: 4 toppen" (fout bij elke andere boom) → nu "Figuur 13 (6
  toppen) … de figuur hangt `TA_` en `TGCGAAA_` een top dieper dan nodig"; 1-3 idem ("In deze boom vertakken 8 van de
  13 toppen niet"); 4-4 sprak van "fase/extensie" (Gusfield) → notas-termen "iteratie i, suffix j".

**P1-2 · Mislukte Bloei-bij in de suffixboom zonder oorzaak (`cause_seq=-1`)** — *gefixt*
- *Repro:* `4-1 bot=errors` (verkeerd afwijkpunt) en `4-2 bot=errors` (verkeerde b): de bij van het getroffen suffix
  faalt, maar de terugblik linkt ze aan geen misstap. Fout aanhechtpunt zette geen `affects`; een fout label van
  suffix j laat ook suffix j' falen.
- *Fix:* `ATTACH` met WRONG_POINT zet `affects`; `TtBloom` valt voor suffixbomen terug op de laatste
  boomveranderende misstap (ATTACH/LABEL).

**P1-3 · Overlays hadden grootte 0×0: intro-kaart niet wegklikbaar, pauze blokkeerde de tuin niet** — *gefixt*
- *Repro:* `tests/qa_tour.gd` (echte muisklikken via `push_input`, onder xvfb): klik op de intro-kaart → blijft staan
  (sluit pas na 5,5 s vanzelf). `get_global_rect()` van `TtIntroCard` = `(0,0,0,0)`.
- *Oorzaak:* `set_anchors_preset(PRESET_FULL_RECT)` op een Control onder een `CanvasLayer` zet enkel de ankers; de
  offsets blijven staan en de Control krijgt geen grootte. Daardoor vingen intro-kaart, rapport (klik op een amber stip
  in de tijdlijn), pauzemenu-dimlaag, instellingen, spiekbriefje en ASCII-storm geen klikken op; klikken in de pauze
  gingen naar de boom eronder.
- *Fix:* overal `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` (14 bestanden onder `scripts/game/`; de
  HUD/werkbank/Uil/… blijven `MOUSE_FILTER_IGNORE`, dus de boom blijft klikbaar).

**P1-4 · Brede suffixbomen (4-4, 4-5) onleesbaar: (b,e)-borden overlappen elkaar en de vruchten** — *gefixt*
- *Repro:* `garden.tscn -- level=4-5 bot=perfect shots=…`: de camera zoomt tot ≈ 0,45; borden van 20 px worden ±9 px
  hoog en liggen op elkaar (`5,19` over `#14`, `11,1|6|#3`, `13,19⋯`/`6,19⋯`/`5,5` in één kluwen). 4-4 idem
  (`15,16` onder `6,16`, `4,5` over `16,16`).
- *Fix (`TtTreeView`):* (1) `label_scale` — de tuin zet dit elke frame op ≈ 0,8 / zoom (1,0–1,7, in stappen van 0,1):
  borden, vruchtlabels `#j`, l_t-ringen en telbadges blijven op het scherm ≈ 16 px hoog; (2) `_place_tags` plaatst
  elk bord zonder overlap: kandidaatposities langs de eigen tak (links/rechts), vruchten, vruchtlabels, knoesten
  (incl. ringen/badges) en eerder geplaatste borden zijn obstakels; korte bogen eerst. De hover-zone (`be_rect`) volgt
  de geplaatste rechthoek. Herberekend ± 8×/s.

**P1-5 · Afsluittekens van 4-5 als losse cijfers op de slinger** — *gefixt*
- De parels toonden `₁ ₂ ₃` (lijkt op "1 2 3"); de notas schrijven `_1, _2, _3` (p. 49). De slinger tekent nu `_₁`.

**P1-6 · Herbeleving van een brede boom (4-4/4-5) was een postzegel** — *gefixt*
- De herbeleving paste de hele boom in 880×520 (zoom ≈ 0,3, borden ±6 px). Nu zoomt ze bij een te brede boom in op
  de plek van de misstap (zoom ≥ 0,55) en groeien de borden mee (`label_scale`).

### P2 — kleinigheden

- **P2-1** Sterlabel "level uitgespeeld, Bloei ≥ 70 %" brak af als "… ≥" / "70 %" of liet "%" alleen staan → vaste
  spaties. *gefixt*
- **P2-2** Coachzin "sla 1 letters over" → "1 letter". *gefixt*
- **P2-3** Notasverwijzing bij "vrucht bereikt ≠ gevonden" in een gewone trie verwees naar "Algoritme 1, p. 29"
  (Patricia) → "p. 27 · in het blad de hele string vergelijken (ook Alg. 1, p. 29)". *gefixt*
- **P2-4** Coachzin bij een fout afwijkpunt aan de wortel: "volgt de boom tot `∅` en wijkt daar pas af" →
  "wijkt al bij de wortel af: daar komt een nieuwe tak". *gefixt*
- **P2-5** 4-5: afsluitteken in coachzinnen als ruwe `3` i.p.v. `_₃`. *gefixt* (display_word)
- **P2-6** Notas-weergave suffixboom: (b,e)-labels van de vlakke wortelbogen (`6,8 7,8 8,8`) liepen in elkaar → labels
  dichter bij het kind. *gefixt*
- **P2-8** Seizoenkaart: een klik zonder voorafgaande muisbeweging (touch/pen, of klik na Alt-Tab) opende geen pot:
  de pot kwam enkel uit de hover van `_process`. Nu bepaalt de klikpositie zelf de pot. *gefixt*
- **P2-7** QA-bot `errors` maakte in 4-1 en 3-4 geen enkele fout (eerste aanhechten is de wortel = juist; bedkeuze
  had geen foutvariant) → bot markeert een zettype pas als "gezien" na een echte fout; foute bedkeuze toegevoegd. *gefixt*

## 3. Leerstof-controle (tegen `lesnotas_AD3_2026.pdf`, p. 25–50)

Onafhankelijk nagerekend met een eigen Python-suffixboom (naïef invoegen, label b = j + l, splitsen behoudt b) en
door de figuren te bekijken (pdftoppm):

| onderdeel | bron | resultaat |
|---|---|---|
| F13 / F14, Oef. 17 (1-2) | Fig. 13 p. 26, Fig. 14 p. 28 | klopt (TA_ en TGCGAAA_ hangen in de figuur een top dieper dan nodig: dat zegt de terugblik nu ook) |
| F15 gewoon + Patricia (2-1/2-3) | Fig. 15 p. 30 | klopt: skips 0 / 2 / 0 / 0 / 1, leesposities Algoritme 1 (GGCGG_: 0, 1, 3; CA_: 1 + 2 > 2 → te kort) |
| Algoritme 1 (2-2), wespen | p. 29 | klopt (BBBB…_ bereikt AAAAABAAAAABC_ via posities 5, 11) |
| F17 → Patricia (2-4, Oef. 19a) | Fig. 17 p. 32 | klopt: `{0\|C{1\|A{1\|…} …} G{1\|…}}`; in het spel gecontroleerd: ringen "1 pos 2", "1 pos 4", "0 pos 3" |
| F16 ternary (3-1) | Fig. 16 p. 31 | klopt (G-wortel met C/T, kleiner/gelijk/groter) |
| Oef. 20 (3-4) | p. 32 | 5 pointers vs. 2 × 3: klopt |
| F18 / F19 (4-1/4-2) | p. 33–34 | eindboom = Python; Fig. 19 met (0,1) als binnenboog van `ac`/`cac` correct als "andere geldige keuze" vermeld (beslissing lead 1) |
| 4-3 / 4-4 antwoorden | §3.3 p. 48–49 | `cac`→1, `ac`→3, `acg`→4, `caca`→1; `cat` eerst 1, `gcat` 3×, `atg` 7, `tcg` 2×, `cga` 13, `catc` 1 en 10: klopt |
| MIST-boom 4-4 | — | = Python-suffixboom van `gcatcgcatgcatcga_` |
| 4-5 eigenaars | p. 49 | `gatt` Merel, `tcgg` Muis, `cga` Mol+Merel, `atc` Mol+Muis, `ggg` niemand, `cgat` Merel: klopt |
| Ukkonen 5-1 / 5-2 eindbomen | p. 43–48, Oef. 27 | = Python (1-gebaseerd); stappen in GDD §5.6 nagelopen met de tekst p. 44–48 |
| coachzinnen + verwijzingen | p. 27–49 | alle 25 verdicts gelezen; fouten: P0-1, P0-3, P2-2…P2-4 |
| spiekbriefje | — | klopt (snoeien: skip kind += skip + 1; Ukkonen: x̄ := x + 1 bij (a)/(b); p = wortel → x − 1) |
