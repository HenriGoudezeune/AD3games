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
- [ ] 08/10 front-end: gestart. Fundamenten (palet/teken-helpers, sfx, juice, overgangen) → depot-scène dag 1–3.

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

## QA
