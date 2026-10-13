# Trietuin — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>`. Zet open punten en de volgende stap bovenaan je sectie.
Wordt een agent onderbroken, dan moet een opvolger uit dit bestand en `git log` kunnen verderwerken.
Lees eerst `TEAM.md` (briefing) en `GDD.md` (ontwerp, interface-contract §8, tests §9, scope §10, open vragen §11).

## Lead
- [ ] 13/10 lead: open vragen in GDD §11 beantwoorden (vooral 1: Fig. 19-labels (0,1) vs. Ukkonen (2,3); 2: positiebasis per level; 11: Ukkonen-fouten weigeren)

## Game designer
- [x] 13/10 14:57 designer: `design/GDD.md` v1 (pitch/pijlers, mapping per structuur met speler/automatisch/fouten, bediening + schermen + HUD, campagne 20 levels + vrije tuin exact uitgewerkt, scoring/sap/sterren/terugblik + coachzinnen, juice/audio, interface-contract `Tt*`, testgevallen T01–T36, scope P0/P1/P2, 13 open vragen)
- Alle leveldata zijn nagerekend met een Python-referentiesimulator (staat niet in de repo). Twijfels staan in GDD §11.

## Art & audio director
- [ ] art: `design/ART.md`, `assets/`, `scenes/art_preview.tscn`

## Core engineer
- [ ] core: `scripts/core/` volgens GDD §8 + tests T01–T36 (`tests/run_tests.gd`). Volgorde: §10 "Bouwvolgorde"

## Gameplay / front-end engineer
- [ ] front-end: titel → seizoenkaart → tuin → Bloei → terugblik, P0-levels (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
(nog niets; core noteert hier elke afwijking van GDD §8)
