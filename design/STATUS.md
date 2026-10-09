# Hash & Dash — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>` — open punten en volgende stap bovenaan je sectie.
Als je onderbroken wordt, moet een opvolger uit dit bestand + git log kunnen verderwerken.

## Fase 1 (klaar)
- [x] 08/10 designer: design/GDD.md
- [x] 08/10 art: design/ART.md, assets/, scenes/art_preview.tscn

## API-afwijkingen (core → front-end, lees dit!)
Ten opzichte van GDD §10 (alles uit §10 bestaat met exact die namen/signaturen; dit zijn aanvullingen/interpretaties):
- `ExtHashModel`: extra `allow_dump: bool` (overloopbak beschikbaar → orakel kan `{action:"dump", parcel_id}` geven,
  ook voor het voorste pakje op de band), `dumped`, `lost: Array[Parcel]`, `doubles`, `splits`, `next_parcel_id`.
- `ExtHashModel.new_parcel(hv, key_label="", is_clone=false) -> Parcel` (unieke ids; gebruik dit i.p.v. Parcel.new()).
- `ExtHashModel.auto_resolve() -> "ok"|"fail"` en `auto_insert(parcel) -> "ok"|"dump"|"fail"`: perfect spel via het
  orakel (bots, knop "Doorspoelen"). Ook: `misplaced()`, `bucket_of_hv(hv)`, `is_findable(hv)`, `is_alarm()`,
  `all_parcels()`, `is_clone_overflow(hv)`, `describe()` (bv. `"0{00100,01111} 10{10010}"`).
- `correct_move()` kan naast §10.3 ook `{action:"finish"}` (tafel leeg, finish nog niet gebeurd — komt normaal niet
  voor) en `{action:"retry"}` geven; `split` bevat ook `span`; `fail` bevat `parcel_id`.
- `lose(parcel, reason, excused=false)`: `excused` = de juiste actie faalde zelf (a == n) → telt niet als fout.
- **MISROUTED / WRONG_LOOKUP enkel als het luik naar een ándere emmer wijst.** Een luik dat dezelfde buis deelt
  (dir[i] == dir[index_of(hv)]) is OK: het pakje ligt correct en is bereikbaar (wereld-gevolg-principe).
- `EventLog`: extra `now`, `n`, `of_type(type)`, `cause_of_hv(hv)`. `mistakes()` slaat entries met `data.excused` over.
  Een vastloper logt `DROP` (status BLOCKED) gevolgd door `BLOCK`.
- `simulate_insert` veronderstelt dat er geen split bezig is.
- `ExtHashModel.log_event(type, data, verdict=OK)`: events van buiten het model (director: SPAWN, CUSTOMER_*, DAY_END).
- `DaySpec` extra: `intro`, `icon` (wens 5), `show_keys` (dag 6), `endless`, `day_number`, `no_stars` (dag 7 ochtend),
  `keys[i].clone` (dag 7: de `*`-pakjes), `is_realtime()`, `has_customers()`, `key_hvs()`.
  Sterren-kinds: `done`, `no_mistakes` (optie `all_customers`), `io_optimal`, `no_doubles` (= 0 dubbels én ritten ≤ opt),
  `time` (`max`), `end_state`. Sterren zijn cumulatief (★★ vereist ★).
- `Days` extra: `layout_from("0{00100,01111} 10{}")`, `endless_tempo(t)` → `{level, spawn_interval, belt_time,
  customer_every, patience}`. `optimum()` geeft ook `dumps, customers, a, end, fail`; voor dag 7 (ouder) = middag.
- **Dag 7 = ouder-spec met `phases`**: `director.start(Days.get_day(7))` start de ochtend; `day_finished` komt per fase
  met `report.has_next_phase`; daarna `director.next_phase()` (nieuw `model` en `scoring`! herkoppel signalen; signaal
  `phase_started(index, spec)`; `director.spec` = huidige fase, gebruik díe voor mode/bit_hint/overflow_bin).
- `DayDirector` extra (wensen 1–4): `belt_progress(id)`, `set_held(id, held)`, `customers()` (`{id, hv, patience,
  patience_left, parcel_id, t}`), `burst_left(id)`; ook `has_next_phase()`, `next_phase()`, `finish_now()` (endless
  stoppen), `count_existing(hv)`, `time`, `time_real`, `finished`, `phase_index`. `serve()` geeft het lookup-resultaat
  + `{happy, customer_id}`; fout luik/niet gevonden = −25 % geduld.
  Na `take()`/`take_front()` moet de speler `model.drop()` of `model.dump()` doen (anders eindigt de dag niet).
  Hendel op de eindaanslag terwijl `correct_move()` "fail" zegt → director laat de buis barsten (`burst`, excused).
- `day_finished(report)` = `Scoring.final_report(...)` (wens 6) + `phase_index, has_next_phase, endless, end_snapshot`.
  Rapport bevat ook `star_count, parcels_ok, lost, time, failed, rent, end_state_ok, coach:[{seq,t,type,line}],
  doubles, splits, a, day, spec_id`. Munten in het rapport = na huur; `scoring.coins` zelf blijft zonder huur.
- `Scoring` extra: `rep_max, rep_regen_every, placed_ok, placed_total, lost_count, customers_ok, customers_total,
  totals` (reden → som), `static rent(model)`, `static end_state_ok(model, spec)`.
- `SaveData` extra: `static var path` (tests), `get_stars(day)`, `is_unlocked(day)`, `highscores()`,
  `is_highscore(score)`, `set_setting/get_setting`. `add_highscore` geeft de plaats terug (−1 = niet in top-10).
  Formaat: `{"stars": {"1": 3}, "highscores": [{score, name, date}], "settings": {}}`.

## Back-end (core)
- [x] 09/10 core: **QA-fixronde** (1146 asserts groen, testrun zonder lek-/ERROR-regels). API-wijzigingen voor front-end:
  - **P1-6 munten:** combo telt nu de tijd vanaf het moment dat een pakje *beschikbaar* is (max(spawn, vorige
    plaatsing), echte tijd zonder alarm) i.p.v. de tijd tussen plaatsingen; opstapelen/slow-mo/traag spel drijft de
    combo niet meer op. Boze klant **−10 €** (reden `"boze klanten"`). Dageinde: **−25 € per verdwaald pakje**
    (`report.rent.misplaced`, breakdown-regel `"verdwaald"`). Herpoging na een foute verdeling voedt de combo niet.
    Nieuw: `Scoring.track_availability`, `on_parcel_available(id)` (de director roept dit zelf aan).
    Test `t_economy`: perfect ≥ elke foutmodus (strikt < bij een echte fout), op elke dag, bij 3 denktijden.
  - **P1-3:** `DayDirector.is_world_frozen()`: tijdens het verdelen op de sorteertafel staan band, spawns, klanten
    en burst stil (speltijd ook). **Nieuw `set_world_hold(held)`**: zet de front-end op `true` zolang een animatie de
    input blokkeert (`_lock`/`_running`: zaag, tafel, heftruck) en daarna terug op `false` (pauzeert ook de
    combo-klok). Lost ook P2-8 (endless sterft op animatietijd) op zodra de front-end dit gebruikt.
    `world_time_scale()` blijft 0,35 bij alarm (de juice-slow-mo verandert niet).
  - **P1-5:** zijn alle pakjes verwerkt en is de balie leeg, dan komt de volgende vaste klant binnen 3 s.
  - **P2-5:** dag 5 klanten vanaf 12 s, elke 9 s (GDD: vanaf 25 s / 10 s → maar 1 klant). Afwijking van §5.2.
  - **P1-8:** `report.opt_total = {reads: opt.reads + klanten, writes}`; live voor de HUD:
    `director.optimum_live()` → `{reads, writes, reads_parcels, customers}`. Gebruik die i.p.v. `opt.reads`.
  - **P1-9:** `DaySpec.report_note` en `report.note` (dag 7 middag: "… Hoe je dit echt oplost: Oefening 4, zelf
    bedenken."; ochtend: uitleg falen). Toon dat in het rapport. De chefzin na de burst = `log.coach_line()` van de
    LOST-entry (excused) of `DOUBLE_REFUSED`-entry.
  - **P2-10:** director gebruikt geen self-vangende lambdas meer (geen lek per dag); tests ruimen hun lambdas op.
  - Niet-core QA-punten (P0-1/2, P1-1/2/4/7/10/11, P2-1..4/6/7/9) liggen bij de front-end.
- [x] 08/10 18:05 core: **core-API beschikbaar** — `HashUtil`, `Parcel`, `Bucket`, `ExtHashModel` (volledig, incl.
  orakel, snapshot/restore, simulate_insert), `EventLog` (incl. coach_line).
- [x] 08/10 core: `DaySpec`, `Days` (dag 1–7 + endless, exact §5.2), `DayDirector`, `Scoring`, `SaveData`;
  bot `tests/bot.gd` (`DayBot`, met foutmodi). **Alle wensen front-end 1–6 verwerkt** (zie API-afwijkingen).
- Tests: **866 asserts groen** (`"$G" --headless --path . --script res://tests/run_tests.gd [-- filter]`):
  A1–A8, alle dagen via perfecte bot (3 sterren, eindtoestand en L/S uit §11, invariants na elke tick),
  dag 7 (ochtend faalt met double_refused + burst, middag bak = 11001/00111), A6, foute bots (verdwaald → boze klant
  met oorzaaklink, verkeerde kant, burst na 12 s, klonen niet in bak, gezond pakje in bak, klanten negeren → rep 0),
  band (rustig/realtime/held), endless 10 min, scoring/sterren §6, SaveData. JS-fixture: `node tests/gen_js_fixture.js`.
- Smoke-test depot (`-- --day=N --bot --quit-after-day`) op de echte core: dag 2 → 3 sterren, L6/S7.
- **Voor front-end (gevonden in smoke-test):** de depot-bot behandelt nog geen `fail` (→ hendel trekken), `dump`,
  klanten (`serve`) en `next_phase()`; daardoor hangt dag 7 en haalt dag 5 geen ★★ (boze klanten). `tests/bot.gd`
  `DayBot.step()` toont hoe.
- Interpretaties/twijfels (notas zeggen hier niets over; spelkeuzes):
  1. Boze klant logt `CUSTOMER_ANGRY` met verdict LOST → telt als fout voor ★★.
  2. Gezond pakje in de bak: −5 (kwijt) −5 (bakkosten) en −1 ♥ ("+€5 bakkosten" in §4 gelezen als extra kost).
  3. Burst-timers pauzeren tijdens het verdelen op de sorteertafel (de speler is dan bezig).
  4. RUSTIG: band stopt met spawnen bij 6 pakjes (`BELT_CAPACITY`); pakjes schuiven aan met `BELT_SPACING` 0.16.
  5. Dag 5: gegenereerde klanten stoppen zodra alle sleutels verwerkt zijn (dag eindigt als de balie leeg is).
  6. Endless-kloonburst: de vaakst voorkomende waarde wordt aangevuld tot g + 1..2 exemplaren; `is_clone` = er
     liggen er al ≥ g in het depot op het moment van spawnen.
  7. Ritten bij een onnodige split: L+1 bij begin, S+2 bij finish (§6.2); juiste split S+1, plaatsing na herpoging S+1.
- Volgende/open: niets verplichts meer voor core. Mogelijk: QA-feedback verwerken.

## Front-end (gameplay)
- [x] 09/10 front-end: **QA-fixronde** (QA.md v1):
  - P0-1 zaag: tafel eerst; oud rek houdt zijn oude bordje/ab tijdens het verdelen (`_split_info`, `_refresh_rack`);
    nieuw rek, ab + 1 en het omklappen van de buizen pas ná het verdelen (`_anim_split_end`).
  - P0-2: één functie `_hatch_at(cursor)` voor highlight én drop (luikkolom in gelijke banden, geen gaten) +
    magnetisch luik; volledige `drag_offset`. Test: `tools/drag_test.gd` (slordige greep 40 px onder het midden):
    dag 5 en dag 4 → 0 mismatches, 0 pakjes van de band.
  - P1-1 tafel 400×560 rechts náást het rek (met nokje), rekken en buizen blijven zichtbaar. P1-2 rekhoogte per dag
    vast (uit `expect_end`), geen layoutwissel midden in een zaag. P1-3/P2-8 `director.set_world_hold(_lock or
    _running)` + belt-visual stil. P1-4 greep: hitbox +24 px, dichtstbijzijnde pakje ≤ 80 px, band "plakt" onder
    de cursor (`set_held` bij hover). P1-7 korte sterlabels. P1-8 HUD `optimum_live()`, rapport `opt_total` +
    "opt L = pakjes + n klanten". P1-9 dag 7 ochtend: chefzin + licht valt uit vóór de stempel, `report.note` in het
    rapport. P1-10 DASH rechtsboven bij de combo-pil. P1-11 luiken bij a ≥ 5 zonder kleurchips.
  - P2-1 hints op vastzittende pakjes, P2-2 pauze-dim, P2-3 spookhand stopt als het pakje weg is, P2-4 rapportpanelen
    groeien mee, P2-6 leeg rek buigt door + rode teller + galm, P2-7 `_idle` reset bij vastloper, P2-9 `--mistake`.
  - Fun: toetsenbordtip van de chef na de eerste sleepbeweging (dag 1–3).
  - **Niet gedaan:** P1-6 (core, opgelost door core), P1-5/P2-5 (core, opgelost), P2-10 lekken (core deed director;
    front-end-autoloads niet nagekeken), buizen bundelen bij a = 6 (P1-11 tweede helft), "dag 1 te kort" (sleutels =
    core/designer: zie wens 7), echte depot-herbeleving.

**Open / volgende stap** (in volgorde van waarde):
1. Speeltest door een mens (QA): vooral muisgevoel (slepen, hendel), tempo van dag 4–5 en leesbaarheid bij a = 5–6.
2. Herbeleving: nu een notas-figuur van het moment vóór de fout + rood (fout luik) / groen + spookhand (juist luik)
   + chefzin. Nog niet: het échte depot heropbouwen en de zet laten naspelen (GDD §4.1 "spookhand die het echt doet").
3. Titel-attract-mode (bot speelt gedimd op de achtergrond), radial blur bij DASH, lichte "licht valt uit" bij de
   eindaanslag op dag 7, decor per dag.
4. Instellingen-paneel ook vanuit pauze (nu enkel schermschok daar; volumes via titel → Instellingen).

**Klaar**
- [x] 08/10 front-end: alle schermen speelbaar: titel → dagenkaart → dag 1–7 + Piekdag (endless) → dagrapport.
  `run/main_scene` = `scenes/title.tscn`. Starten: `Speel Hash & Dash.bat`.
- [x] Depot (`scripts/game/depot.gd`, views in `*_view.gd`): band, muur/luiken, buizen (verzamelbuizen), rekken,
  hendel, zaag, sorteertafel, balie + klanten, overloopbak (K), HUD, pauze + spiekbrief, chef-ballon + spookhand
  (DaySpec.hints), loep (Shift), Tab = klantfocus, Doorspoelen (dag 7 ochtend). Muis én toetsenbord (GDD §2.3).
- [x] Juice GDD §8: 1–34 bijna volledig (squash/stretch, buis-puls, munten naar HUD, slow-mo + lowpass + vignet +
  zwaailicht, muur verdubbelt (luiken splijten staggered, Y-buizen, a = 6 → muur 2 kolommen), zaag/klonk/vonken,
  buizen omklappen (elastic), heftruck-ritten, kettingreactie + holle galm, burst, band-val, DASH, sterren). Audio
  volgens MANIFEST; muzieklagen basis/drukte/spanning, Piekdag = rush-track.
- [x] Endless schaalt: > 12 rekken → raster van 2–3 kolommen met mini-rekken (bordje + vulgraad); highscore-invoer.
- [x] Bot in depot (`-- --bot`) volgt `DayBot`: alle 7 dagen 3 sterren via de echte UI (ook dag 7 twee fasen).

**Handig voor opvolger/QA** (args na `--`): `--day=N` (0 = endless) · `--bot` · `--quit-after-day` (print DAY_DONE)
· `--autostart` (titel → kaart → dag) · `--speed=4` · `--mistake` (bot maakt 1 fout luik) · `--demo-replay` (rapport
toont meteen de eerste fout) · `--unlock` (alle dagen open). Bv.:
`"$G" --path . --write-movie <map>/f.png --fixed-fps 30 --quit-after 900 res://scenes/depot.tscn -- --day=2 --bot`.
Screenshots: `design/screens/01..06_*.png`.

**Bekende bugs / beperkingen**
- Bij heel veel buizen (a = 6, endless) wordt het buizenveld een spaghetti; leesbaar via kleur + hover, niet mooi.
- Sorteertafel kan bovenste rekken bedekken (bewust: dan kijk je naar de tafel), en is 900 px breed i.p.v. 700.
- Luiklabels bij a = 6 zijn 18 px maar steken iets buiten hun (17 px hoge) luik.

### Wensen front-end → core
Graag (allemaal optioneel; de front-end heeft een fallback, maar dit houdt view en logica 100 % in sync):
1. `DayDirector.belt_progress(parcel_id) -> float` (0 = net gespawnd, 1 = einde band). In CALM stopt de band als het
   voorste pakje het einde bereikt; dan moet progress daar ook stoppen (en de volgende pakjes netjes aanschuiven).
2. `DayDirector.set_held(parcel_id, held: bool)`: een pakje dat de speler aan het slepen is, schuift niet op en valt
   niet van de band (anders glipt het uit je hand). Losgelaten naast een luik → `set_held(id, false)`, terug op de band.
3. `DayDirector.customers() -> Array[Dictionary]` met de wachtende klanten `{id, hv, patience, patience_left}` (voor
   de geduldsbalk), in volgorde van aankomst.
4. `DayDirector.burst_left(parcel_id) -> float` (resterende speltijd tot de buis barst; -1 als geen burst), zodat de
   buis harder kan opzwellen naarmate het einde nadert.
5. `DaySpec.intro: String` (één zin voor de dagintro, ≤ 8 woorden) en `DaySpec.icon: String`
   (`hatch|lever|saw|desk|storm|book|clones|endless`) voor de dagenkaart.
6. Het `report` van `day_finished` liefst gelijk aan `Scoring.final_report(...)`.
7. (09/10, QA fun-review) Dag 1 is te kort (6 pakjes, ~25 s). Voorstel: 10 sleutels, bv. `00110 10101 01011 11000
   00011 10010` + `01101 11110 00001 10011` met g = 5 (blijft zonder overloop), ★★★-tijd naar 60 s.

## QA
- [x] 09/10 QA: design/QA.md: 866 tests groen, geen crash/softlock op dag 1–7/∞; 2 P0 (split-animatie toont rekken met verkeerde inhoud vóór het verdelen; hover-luik ≠ drop-luik bij a ≥ 4), 11 P1, 10 P2 + fun-review top 5. Frames in design/qa_frames/.
