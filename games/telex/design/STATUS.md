# Telex — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>`. Zet open punten en de volgende stap bovenaan je sectie.
Wordt een agent onderbroken, dan moet een opvolger uit dit bestand en `git log` kunnen verderwerken.
Lees eerst `TEAM.md` (briefing) en `GDD.md` (ontwerp, interface-contract §8, tests §9, scope §10, open vragen §11).

## Lead
- [ ] lead: open vragen GDD §11 beantwoorden (15 vragen), hubkaart "TELEX" in `HubRegistry`

## Game designer
- [x] 13/10 15:41 designer: `design/GDD.md` v1 — titel **TELEX** (Station Zoeklicht, analoge operator-thriller), pijlers,
  mapping per algoritme (Alg. 2–8, Def. 11/13/14/15) met speler/automatisch/fouten→gevolgen, stroommodel (lusbak,
  versnipperaar, scheur), bediening + schermen + HUD + machinepanelen, campagne 8 dossiers (27 levels, 19 P0) + finale
  + Nachtdienst exact uitgewerkt, scoring/sterren/debrief + coachzinnen, juice (38) en audio, interface-contract `Tx*`,
  testgevallen T01–T40, scope P0/P1/P2 + bouwvolgorde, 15 open vragen.
- Alle leveldata (V[], Algoritme 5-stappen, KMP/BMH-sporen, hashwaarden, C_x/kolommen, M⁰/M¹, editeertabellen, Alg. 8-
  minima en paden, tegenzet-optima, rivaal-scheuren) zijn nagerekend met een Python-referentie die de pseudocode van de
  notas letterlijk volgt (staat niet in de repo). Twijfels staan in GDD §11.

## Art & audio director
- [ ] art: `design/ART.md`, `assets/` (+ `assets/CREDITS.md`), `scenes/art_preview.tscn`

## Core engineer
- [ ] core: `scripts/core/` volgens GDD §8 + tests T01–T40 (`tests/run_tests.gd`), `tests/tx_bot.gd`. Volgorde: GDD §10
  "Bouwvolgorde" (eerst `TxReference` + T01–T24)

## Gameplay / front-end engineer
- [ ] front-end: titel (Esc → hub) → missiekaart → briefing → console → debrief, P0-levels + Nachtdienst (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
(nog niets; core noteert hier elke afwijking van GDD §8)
