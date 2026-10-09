# Hash & Dash — QA-rapport (playtest v1, commit ab11e51)

Eigenaar: QA-playtester. Lezers: front-end (gameplay), core, designer. Status: **v1 af** (09/10).
Frames: `design/qa_frames/` (JPEG-kopieën van `--write-movie`-opnames op 1600×900, het scherm schaalde 1920×1080 terug).

**Commando's** (vanuit de projectmap, `G = C:\Users\henri\tools\godot\Godot_v4.7.2-stable_win64_console.exe`):
- tests: `"$G" --headless --path . --script res://tests/run_tests.gd`
- headless dag: `"$G" --headless --path . res://scenes/depot.tscn -- --day=N --bot --quit-after-day --speed=4 [--mistake]`
- opname: `"$G" --path . --resolution 1920x1080 --write-movie <map>/f.png --fixed-fps 30 --quit-after <frames> res://scenes/depot.tscn -- --day=N --bot`
  (framenummers `fNNN` hieronder = `f%08d.png` uit zo'n opname bij 30 fps; ze zijn deterministisch met `--fixed-fps`)
- **menselijke input**: QA-script `human.gd` (niet in de repo; ~200 regels, staat in de QA-scratchpad). Het stuurt
  echte `InputEventMouseButton/Motion` via `Input.parse_input_event` en `InputEventKey`, met mensachtige pauzes (0,7 s
  lezen, 0,6 s slepen, 1,5 s nadenken bij een vastloper). Modus `--sloppy` pakt het pakje 40 px onder het midden vast.
  `"$G" --headless --path . --fixed-fps 30 --script <pad>/human.gd -- --day=N [--sloppy]`. Een tweede script
  (`ui_tour.gd`) loopt titel → kaart → dag → pauze → spiekbrief → Esc.

---

## 1. Samenvatting

| | |
|---|---|
| Tests | `run_tests.gd`: **866 asserts groen** (2,1 s) |
| Crashes / SCRIPT ERROR | **geen**, in alle runs (dag 1–7 en endless, bot, `--mistake`, menselijke input, UI-tour) |
| Vastlopers / softlocks | **geen**. Elke dag eindigt met `DAY_DONE`; dag 7 doorloopt beide fasen |
| Console | enkel bij afsluiten: `ObjectDB instances leaked` + `ERROR: 8–9 resources still in use at exit` (P2-10) |
| Leerstof | eindtoestanden kloppen op elke dag; Fig. 5 (dag 5) en Oef. 5 (dag 6) zijn exact goed. **Maar** de split-animatie toont ~0,5 s een toestand die niet bestaat (P0-1) |
| Muis | slepen, hendel, zaag, tafel en klant-luik werken met echte events. **Hover-licht ≠ landingsluik** vanaf a = 4 (P0-2) |
| Bugs | **P0: 2 · P1: 11 · P2: 10** |

Headless sweep (bot, `--speed=4`), `DAY_DONE`-regels:

| dag | perfect | `--mistake` |
|---|---|---|
| 1 | ★★★ L6/S6 €185 | ★★★ (bot maakt **geen** fout: vereist a ≥ 2, zie P2-9) |
| 2 | ★★★ L6/S7 €182 | ★ L6/S8 €130, 1 fout |
| 3 | ★★★ L8/S12 €268 | ★ L8/S11 €220, 1 fout |
| 4 | ★★★ L17/S17 €259 | ★ L16/S17 **€271**, 2 fouten (meer munten dan perfect, P1-6) |
| 5 | ★★★ L11/S16 €171 | ★ L11/S16 €141, 1 fout |
| 6 | ★★★ L6/S9 €172 | ★ L6/S7 €132, 1 fout |
| 7 | ★★★ L9/S14 €92 | ★ L10/S15 **€115**, 1 fout (opnieuw meer munten, P1-6) |
| ∞ | 12 speelminuten zonder fouten in de console. De bot verliest harten bij a = 6 en sluit op €2392 (P2-8) | — |

Extra core-sweep met `DayBot`-foutmodi (`misroute_first, wrong_side, double_first, ignore_customers, idle_block`) per
dag: de gevolgen kloppen met GDD §4 (★★ valt weg, huur stijgt, boze klanten, burst). `idle_block` op rustige dagen
(1, 2, 3, 6) eindigt nooit. Dat is zo ontworpen: zonder burst-timer blijft het depot wachten.

---

## 2. Buglijst

### P0: fout tegen de leerstof / oneerlijke fout

**P0-1 · Split-animatie toont rekken met verkeerd label, ab en inhoud vóór het verdelen**
- *Repro:* opname `--day=2 --bot`, f405–f420; `--day=3 --bot` f310–f320; `--day=5 --bot` f396–f416.
  Dit gebeurt bij **elke** zaag.
- *Gezien:* zodra de zaag valt, krijgen het oude en het nieuwe rek al hun nieuwe bordje (label + ab + 1) en
  verschijnt het nieuwe rek. De pakjes staan dan nog in het oude rek, en de sorteertafel opent pas daarna:
  - dag 2 f411 (`01_…`): rek **`10` ab 2 bevat `11100`**, rek `11` staat leeg met het vastzittende `11111` ervoor;
  - dag 5 f400 (`07_…`): bordje **`00` ab 2** met `01111` erin, terwijl **8 buizen** (0000–0111) nog naar dat rek
    lopen (ab 2 bij a = 4 hoort 2^(4−2) = 4 buizen te geven);
  - dag 3 f318 (`03_…`): rek `100` toont `10111`.
  Een student ziet "`11100` ligt in rek `10`". Dat is precies de verdwaald-situatie die de game elders als fout leert.
- *Verwacht:* de volgorde uit de notas (p. 7–8): (1) pakjes uit het rek naar de tafel, (2) verdelen, (3) daarna pas
  bordjes ab+1 en het nieuwe rek tonen, en de buizen omklappen (GDD juice 19–23).
- *Fix:* in `_anim_split` eerst `to_sort` naar de tafel tweenen en de rek-slots leegmaken. Zet de nieuwe labels/ab en
  maak het nieuwe rek pas aan na de pointer-omklap (juice 20). Of toon tijdens de tafel de **oude** labels en het
  nieuwe rek als "in aanbouw" (lege plaat zonder bordje). Laat `_refresh_rack` niet uit `model.layout()` lezen zolang
  `model.splitting` niet leeg is.

**P0-2 · Bij slepen licht een ander luik op dan het luik waarin het pakje valt (a ≥ 4)**
- *Repro:* `human.gd -- --day=5 --sloppy` (pakje 40 px onder het midden vastpakken; zo pakt een mens een doos
  vaak vast). Resultaat: 4 van de 4 sleepbewegingen bij a = 4 tonen
  `HOVER-licht op luik 8, drop gaat naar luik 9 (!! MISMATCH)` (ook 4→5, 9→10, 10→11).
- *Oorzaak:* `_update_hover` gebruikt `_hatch_at(drag_view.position)` (pakjescentrum, dat met lerp en de helft van
  `drag_offset` naloopt). `_on_release` gebruikt eerst `_hatch_at(pos)` met de muispositie. Bij een luikhoogte van
  ~43 px (a = 4) of 22 px (a = 5) valt dat bijna altijd in een ander luik.
- *Gevolg:* de speler mikt op het oplichtende luik en krijgt een MISROUTED-fout die hij niet gemaakt heeft. Zo leert
  hij dat zijn juiste lezing fout was. Dat ondermijnt pijler 1.
- *Fix:* bepaal het doel op **één** plek en gebruik dat voor highlight én drop (bv. `drop_target()` = hatch onder
  het pakjescentrum, of onder de muis, maar in beide gevallen hetzelfde). Laat `drag_offset` volledig doorwerken
  (niet `* 0.5`) zodat het pakje niet onder de cursor wegschuift.

### P1: storend, verwarrend of lelijk

**P1-1 · Sorteertafel bedekt het rek dat gesplitst wordt en de heftruck** (bekend, maar erger dan gedacht)
- *Repro:* `--day=2 --bot` f423 (`02_…`), dag 5 f416, dag 7 f800.
- *Gezien:* de tafel (900×300) ligt over de rekken `0`/`10`. Het rek dat je aan het verdelen bent, zie je dus niet
  vollopen. Bij a ≥ 3 schuift de tafel ook over de buizen, zodat je de pointer-omklap (het leermoment van Oef. 2)
  niet ziet.
- *Fix:* plaats de tafel in de vrije balie-/heftruckzone rechts (x 1300–1900) of boven de band. Of maak ze 700 px
  breed zoals de GDD voorschrijft, verankerd **naast** het rek met een verbindingslijn. Laat OUD/NIEUW visueel
  aansluiten op de twee rekken (pijltjes).

**P1-2 · Rekken springen zonder animatie naar de compacte layout**
- *Repro:* `--day=3 --bot` f299 → f301 (`04_…`), dag 5 f404 → f408.
- *Gezien:* als het aantal rekken over een drempel gaat, wisselen alle rekken binnen 1–2 frames van hoogte, positie
  en layout (bordje boven → bordje links, pakjes schuiven naar rechts). Dat is een teleport midden in een zaag.
- *Fix:* tween de rekhoogte en de slotposities (`_relayout(0.35)` ook bij een moduswissel), of kies de compacte
  modus al bij de dagstart als het maximaal te verwachten aantal rekken > drempel (dag 3–5, 7 bekend via `expect_end`).

**P1-3 · Een menselijke beginner verliest op dag 5 pakjes van de band zonder één algoritmefout**
- *Repro:* `human.gd -- --day=5` (0,7 s lezen + 0,6 s slepen per pakje, 1,5 s denken bij een vastloper, 0,8 s per
  pakje op de tafel). Uitkomst: 3 × `LOST reason=belt` (t = 21, 39, 46 s). Met `--sloppy`: 4 ×. ★★ is daarmee weg,
  terwijl elke beslissing juist was.
- *Oorzaak:* spawn 3,5 s, en de storm vraagt 2 dubbels + 2 zagen + 4 tafelzetten. De slow-mo vertraagt de band,
  maar de **animatie-lock** (`_lock` tijdens zaag/tafel/heftruck, ~2–3 s echte tijd per split) laat geen
  bandacties toe. De band loopt intussen (vertraagd) door.
- *Fix:* band volledig stil (`world_time_scale = 0`) zolang `model.splitting` niet leeg is of `_running`; of
  `belt_time` 14 → 18 s op dag 5; of pakjes die van de band vallen tijdens een alarm niet als fout tellen (excused).
  GDD §5.1 belooft: "wie nadenkt wordt niet gestraft".

**P1-4 · Een bewegend pakje vastpakken mislukt vaak (dag 1–2)**
- *Repro:* `human.gd -- --day=1 --sloppy` zonder bijsturen: 9 van 12 sleeppogingen
  `drop niet geregistreerd` (`press@(1383,194) drag_view=false`). Het pakje rijdt met 340 px/s
  (`CALM_SPEED`) weg tussen kijken en klikken. Hitbox = pakje + 6 px.
- *Fix:* hitbox `grow(24)`; band 150 ms "plakken" onder de cursor bij hover (`set_held` op hover, niet pas op
  press); of de band op rustige dagen trager laten aanschuiven (200 px/s). Bij een gemiste klik: laat het
  dichtstbijzijnde pakje binnen 80 px oppakken.

**P1-5 · Dag 4: ~20 s dode tijd aan het einde**
- *Repro:* `--day=4 --bot` f1800–f2460 (`12_…`).
- *Gezien:* alle 12 pakjes liggen er. De band is leeg en je wacht op de klanten van 56 s en 68 s. Er gebeurt niets,
  behalve een klant die per 12 s binnenkomt.
- *Fix:* klanten in de laatste fase sneller laten komen (geduld en interval schalen zodra de band leeg is), of
  de laatste 2 klanten vroeger inplannen (44/50 s). Algemeen: "band leeg + wachten" → klantinterval × 0,4.

**P1-6 · Munten belonen fouten: met `--mistake` haal je op dag 4 en 7 méér munten dan perfect**
- *Repro:* headless sweep hierboven: dag 4 €271 (fout) vs €259 (perfect), dag 7 €115 vs €92.
- *Oorzaak:* een fout luik kost bijna niets in munten (het pakje telt als geplaatst, +10 × combo) en verandert de
  timing, waardoor de combo langer blijft lopen. Een boze klant kost enkel ♥, geen €.
- *Fix:* verdwaald pakje = **0** munten bij plaatsing (in plaats van +10 × combo), boze klant −10 €, en de combo
  breekt al bij de fout (en niet pas zodra de speler het merkt). Voeg een core-test toe:
  `coins(perfect) > coins(elke foutmodus)` voor elke dag.

**P1-7 · Labels van de sterren in het rapport overlappen**
- *Repro:* `--day=3 --bot --mistake --demo-replay`, rapport f1200 (`08_…`).
- *Gezien:* "0 fouten0 verdubbelingen, ritten optimaal": twee labels lopen in elkaar over.
- *Fix:* sterlabels met een vaste breedte (220 px) en autowrap, of korte labels ("0 fouten", "0 dubbels + opt.").

**P1-8 · Dag 5: L-balk oranje boven "opt 10" terwijl ★★★ "ritten = optimum" zegt**
- *Repro:* `--day=5 --bot`, rapport f1700 (`09_…`).
- *Gezien:* L 11, maar de balk toont opt 10 (zonder klantrit). In het HUD staat ook `(opt 10/16)`. De speler ziet
  "boven optimum" en krijgt toch de ster "ritten = optimum". Bij dag 4 gebeurt hetzelfde (opt 12 vs L 17 in de HUD).
- *Fix:* tel het aantal bediende klanten bij opt-L (zoals §5.2 "L 10 + klanten"), in de HUD en het rapport, of
  toon "opt 10 + 1 klant".

**P1-9 · Dag 7: het rapport mist de Oef. 4-boodschap en de ochtend mist een duidelijk slot**
- *Repro:* `--day=7 --bot`, rapport f2900 (`16_…`); einde ochtend f880–f940 (`11_…`).
- *Gezien:* het rapport is een gewoon dagrapport (sterren, munten). De GDD-zin "Hoe je dit echt oplost: Oefening 4,
  zelf bedenken." ontbreekt, en zo ook de link naar "meer dan g identieke hashwaarden → methode faalt" (notas p. 8).
  Bij de eindaanslag in de ochtend zie ik in de opname geen chefballon ("Geen bits meer…"). Er volgt meteen
  "OCHTEND VOORBIJ" en de middag. Het "licht valt uit"-moment ontbreekt ook (staat als open punt in STATUS).
  Mogelijk onderdrukt `bot`/doorspoelen de hint. Dat moet geverifieerd worden met een mens.
- *Fix:* na de burst 2 s pauze + chefzin (ook in botmodus/doorspoelen); een tussenkaart "Wat ging er mis?" met de
  eindtoestand in notas-weergave (4 lege rekken zichtbaar = verspilling); de Oef. 4-regel in het rapport van dag 7.

**P1-10 · DASH!-tekst en munten vliegen over de sorteertafel en het herpogingspakje**
- *Repro:* `--day=2 --bot` f448–f466 (`06_…`).
- *Gezien:* de combo ×5 valt samen met de laatste tafelzet. "DASH!" (groot, geel) staat midden op de tafel en
  daarna over het rek, net wanneer de herpoging van `11111` het leermoment is.
- *Fix:* DASH-stinger in het HUD-gebied (rechtsboven bij de combo-pil) of uitstellen tot er geen tafel/alarm
  actief is. Tafelzetten zouden de combo ook niet mogen voeden (dat zijn geen plaatsingen).

**P1-11 · Muur bij a = 5–6: luiklabels steken buiten hun luik, buizenspaghetti** (bekend)
- *Repro:* `--day=7 --bot` f830 (`10_…`, a = 5); endless f2350 (a = 6).
- *Gezien:* bij a = 5 is elk luik ~20 px hoog en overlappen de labels de luikranden. Door de 5 kleurchips per label
  wordt de kolom een regenboogstreepjescode. Bij a = 6 zijn er 64 buizen die kruisen. Een luik is daar ~17 px hoog:
  als sleepdoel te klein (zie P0-2).
- *Fix:* bij a ≥ 5 de chips weglaten op de luiken (enkel inkt), en enkel het **gemeenschappelijke prefix van de
  buisgroep** groter tonen (bv. `101··` naast een groep van 4 luiken). Buizen per rek bundelen **vóór** ze de muur
  verlaten (één verzamelbuis per rek vanaf x = 600). Drop-tolerantie: kies het luik onder het pakje en laat het
  pakje tijdens het slepen magnetisch op het luikmidden snappen.

### P2: polish

**P2-1 · Vastzittend pakje houdt zijn oude bitmarkering na verdubbelen.** Dag 2 f411 (`01_…`): `1 1111`, één chip
terwijl a = 2. *Fix:* `apply_hint` ook op `stuck_views` aanroepen in `_refresh_all_hints`/na `_on_doubled`.

**P2-2 · Pauze dimt de achtergrond nauwelijks** (`13_…`, spiekbrief open). Het depot blijft volledig helder achter
het menu. *Fix:* controleer of de dim-tween (`ColorRect` alpha 0 → 0,75) loopt terwijl de tree gepauzeerd is
(`set_pause_mode`/`TWEEN_PAUSE_PROCESS`).

**P2-3 · Spookhand demonstreert een pakje dat al geplaatst is.** Dag 1 f105–f125 (`05_…`, botopname): het
spookpakje `10101` wordt nog naar luik 1 gesleept terwijl `10101` al in rek 1 ligt. Bij een mens is dit minder
waarschijnlijk (4 s idle), maar het kan nog altijd. *Fix:* spookanimatie annuleren als `ghost`-doelpakje de band
verlaat.

**P2-4 · Rapport: onderste regel "rekhuur" geknipt door de paneelrand** (`09_…`, dag 5 met 5 regels in de
uitsplitsing). *Fix:* paneelhoogte afhankelijk van het aantal regels.

**P2-5 · Dag 5 heeft maar 1 klant** (core-sweep `cust=1/1`; botopname 1–2). De dag is te kort (10 sleutels × 3,5 s)
voor "klanten elke 10 s vanaf 25 s". *Fix:* eerste klant op 12 s, of 3 vaste klanten die naar pakjes vragen die
door de storm verhuisd zijn (`11100`, `11111`): dat test meteen of de speler de nieuwe luiken kent.

**P2-6 · Leeg rek na de zaag is visueel stil.** Dag 5 f180 (`14_…`): rek `110` ab 3 0/2 klopt exact met Fig. 5,
maar het "galmen" (juice 25) en de stofwolk zag ik in de frames niet terug. Het leermoment hangt nu enkel aan een
zwaailicht dat ook bij elke andere vastloper draait. *Fix:* leeg rek 0,3 s laten doorbuigen + "0/2" rood laten
knipperen + kort holle-echo-icoon.

**P2-7 · Hendel-hint verschijnt op dag 5 al vóór de speler kan nadenken.** Het hendel-gloeien triggert bij
`day <= 2 or _idle > 4`, maar bij het begin van dag 5 telt de dagkaart mee als idle. In de opname gloeit de hendel
meteen na de kaart (f60–f100), terwijl de GDD wil dat de speler het aha-moment zelf vindt. *Fix:* `_idle` resetten
bij `parcel_blocked` en `still_blocked`.

**P2-8 · Endless: de perfecte bot verliest harten bij a = 6.** Endless f2350: ♥♥ over, 6 "fouten" (allemaal
`belt`) en een einde op €2392 na ~10 min. Bij dat tempo is de UI-animatieduur (lock tijdens zaag + tafel) de
bottleneck, niet de speler. Op zich oké voor endless, maar dan sterft je run op animatietijd. *Fix:* in endless de
split-animaties versnellen naarmate het level stijgt (×1,5 bij L ≥ 8), of de band stilzetten tijdens de tafel (zie P1-3).

**P2-9 · `--mistake` doet niets op dag 1** (vereist a ≥ 2) en op dag 7 valt de fout in de ochtend. Voor QA
onhandig. *Fix:* `a >= 1` toestaan, en op dag 7 de fout in de middagfase leggen.

**P2-10 · Lekken bij afsluiten.** Elke run eindigt met `WARNING: 25–42 ObjectDB instances were leaked` en
`ERROR: 8–9 resources still in use at exit` (tests: 12272 instances). Dat is onschuldig, maar het vervuilt de
`grep ERROR`-check die TEAM.md voorschrijft. *Fix:* `--verbose` draaien, de autoloads (`Sfx`-streams,
`Juice`-tweens) in `_exit_tree` vrijgeven, en in de tests de `ExtHashModel`/`EventLog`-cycli breken
(`log.model = null`).

---

## 3. Correctheid leerstof (checklist)

| controle | resultaat |
|---|---|
| luiklabels = eerste a bits (MSB) | OK op elke dag; volgorde `000…111` van boven naar onder |
| buizen per rek = 2^(a−ab) | OK in rust (dag 5 f400 ná de omklap: `0` ab 1 = 8 buizen, `10` ab 2 = 4). **Fout tijdens de split** (P0-1) |
| verdubbelen pn[i] = po[i/2] | OK: na de hendel delen `i0`/`i1` dezelfde buis (dag 2 f348–f360, dag 5 f120) |
| splitsen bit ab+1: 0 → oud (links), 1 → nieuw (rechts) | OK, tafel "OUD …0 / NIEUW …1", bit pulseert (dag 2 f434). Menselijke input met ←/→ en slepen: correct |
| dag 5 = Fig. 4 → 5 | OK: a = 3, `110` ab 3 leeg, `111{11100,11111}` ab 3, `11110` blijft vast (f180, `14_…`). Daarna a = 4, `1110{11100}`, `1111{11111,11110}` |
| dag 6 = Oef. 5 | OK: a = 4, 5 emmers, `001` ab 3 leeg, `1` ab 1 met 8 pointers (`15_…`). L6/S9 = opt |
| dag 7 ochtend faalt op a = n | OK: hendel "a = n", buis barst, a = 5, 4 lege rekken. Uitleg ontbreekt (P1-9) |
| herbeleving | OK: "00110 begint met 001. Luik 001, niet 100." + notas-figuur van vóór de zet (`08_…`) |
| klant via luik, niet via rek | OK: klik op het rek = wiebel; klik op het luik = heftruck + scan (menselijke input dag 4: 5/5 klanten) |

---

## 4. Feel & visueel (reviewer-oordeel)

- **Sterk:** de art is echt mooi: warme dozen tegen de koele nacht, buizen als metrolijnen, bitchips die je oog
  trainen. De muur die verdubbelt (luiken splijten, Y-buizen) en de buizen die omklappen bij de zaag zijn de beste
  momenten van de game. Daar *zie* je pn[i] = po[i/2] en Oef. 2. Het rapport met notas-weergave is een topvondst
  voor het examen.
- **Teleports:** compacte rek-layout (P1-2); bordjes die vóór het verdelen omspringen (P0-1); de tafel die
  verschijnt en het rek bedekt (P1-1).
- **Overlap:** tafel ↔ rekken/heftruck, DASH ↔ tafel, labels ↔ luiken bij a ≥ 5, sterlabels in het rapport.
- **Tempo:** dag 1 (6 pakjes, ~25 s) is te kort om iets te voelen en de band rijdt sneller dan je kan klikken
  (P1-4). Dag 2–3 zijn goed: elk vol rek is een puzzel. Dag 4 sleept aan het einde (P1-5). Dag 5 is het
  hoogtepunt, maar bestraft een denkende speler met bandverlies (P1-3). Dag 6 is kort en rustig, terecht. In dag 7
  middag gebeurt veel tegelijk, maar het leest prima.
- **Duidelijkheid zonder tekst:** de hendel/zaag-affordance (gloeien) werkt. Op de tafel ("bit 2" + pulserende bit)
  is meteen duidelijk wat je moet doen. "Waarom zit dit pakje vast?" krijgt geen antwoord tot de speler de buizen
  telt. De tel-animatie van dag 3 (buizen lichten een voor een op) zag ik niet in de botopname.
- **Ergonomie:** hendel (220×330 doel, 260 px trekken) is prima. Zaagicoon 60×60 is prima. Luiken bij a ≤ 3 zijn
  royaal. Vanaf a = 4 is slepen naar een 43 px luik terwijl het highlight verspringt frustrerend (P0-2). Typen
  (`0`/`1`) is daar duidelijk de betere besturing, maar dat ontdekt een beginner niet: geen enkele hint toont de
  toetsen.

## 5. Gesimuleerde menselijke beginner (dag 1–6, echte input-events)

| dag | resultaat (`human.gd`) |
|---|---|
| 1 | eindtoestand = §5.2, 0 fouten, L6/S6. Slepen en typen werken. `--sloppy`: 9/12 grepen mis op het rijdende pakje (P1-4) |
| 2 | eindtoestand = Fig. 4 + `10111`, 0 fouten, L6/S7. Zaag op 1 buis → "klonk" (geen actie, correct). Hendel slepen 260 px → a = 2. Tafel met ← en met slepen naar NIEUW: correct |
| 3 | 4 zagen, 0 dubbels, L8/S12 = opt |
| 4 | 5/5 klanten via luik-klik, L17/S17 = opt, 0 fouten |
| 5 | eindtoestand klopt **niet** met §5.2, want 3 pakjes van de band gevallen (P1-3); algoritmisch 0 fouten |
| 6 | Oef. 5 exact, L6/S9 |
| UI | titel → "Spelen" → kaart → toets `2` → dag 2 → Esc → Spiekbrief → Esc → terug naar het pauzemenu: alles werkt |

---

## 6. Fun-review: top 5 (grootste winst voor de kleinste inspanning)

1. **Stop de band tijdens de sorteertafel** (P1-3). Eén regel in `world_time_scale`. Daardoor voelt dag 5 als een
   puzzel die je kraakt in plaats van een race tegen je eigen animaties, en het aha-moment blijft intact.
2. **Volgorde van de split-animatie omdraaien** (P0-1) + tafel naast het rek (P1-1). Dan *zie* je de dozen uit het
   rek springen, verdeeld worden en in twee rekken landen terwijl de buizen omklappen. Nu is dat het meest
   bevredigende moment van de game, maar het wordt verstopt.
3. **Snap-to-hatch bij slepen** (P0-2/P1-11): het gesleepte pakje klikt magnetisch op het luik onder je cursor,
   dat luik klapt alvast open en zijn buis licht op tot in het rek. Elke drop voelt dan raak, en je ziet bij elke
   beweging welke pointer je volgt.
4. **Kortere stiltes, meer klanten** (P1-5, P2-5): klanten die vragen naar pakjes die net verhuisd zijn na een
   storm, sneller als de band leeg is. Dat maakt dag 4–5 levendig en test opzoeken na het splitsen, het mooiste
   inzicht van de les.
5. **Eén zichtbare "toetsenbord-tip" op dag 3** ("typ 1-0-1 → luik 101", met de typbuffer al in beeld) + DASH
   enkel voor getypte/gesleepte plaatsingen. Typen is de snelste en meest leerzame besturing (je rekent h(r)|a uit),
   en de combo wordt de beloning om het te leren.

**Eindoordeel.** Hash & Dash ziet er al uit als een echte indiegame en is inhoudelijk opvallend correct: de
eindtoestanden, Figuur 5 en Oefening 5 kloppen exact, en de notas-weergave is goud waard voor het examen. Het
"leuk" zit vandaag vooral in dag 2, 3 en 5. Dag 1 is te kort en de rijdende band werkt tegen je hand, dag 4 sleept
aan het einde, en dag 5 straft wie nadenkt. Met P0-1/P0-2 en de top-5 erbij wordt het een spel waar Henri
vrijwillig meerdere runs in steekt. Nu is het een heel mooie, correcte interactieve les die af en toe frustreert.
