# Hash & Dash — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>` — open punten en volgende stap bovenaan je sectie.
Als je onderbroken wordt, moet een opvolger uit dit bestand + git log kunnen verderwerken.

## Fase 1 (klaar)
- [x] 08/10 designer: design/GDD.md
- [x] 08/10 art: design/ART.md, assets/, scenes/art_preview.tscn

## Back-end (core)

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
