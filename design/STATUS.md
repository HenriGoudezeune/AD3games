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

## Back-end (core)
- [x] 08/10 18:05 core: **core-API beschikbaar** — `HashUtil`, `Parcel`, `Bucket`, `ExtHashModel` (volledig, incl.
  orakel, snapshot/restore, simulate_insert), `EventLog` (incl. coach_line). Tests: 551 asserts groen
  (A1–A4, A7 tegen JS-fixture, A8, Oef. 5, identieke hv, random property tests).
- [ ] volgende: `DaySpec` + `Days` (7 dagen + endless, incl. wensen front-end 5), `Scoring`, `DayDirector`
  (incl. wensen front-end 1–4, 6), `SaveData`, bot (`tests/bot.gd`, class `DayBot`) + dagtests A5/A6 en §11-tabel.
- Tests: `"$G" --headless --path . --script res://tests/run_tests.gd [-- filter]`. JS-fixture opnieuw maken:
  `node tests/gen_js_fixture.js`.

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
