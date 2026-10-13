# Kortschrift (Scriptorium) — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>`. Zet open punten en de volgende stap bovenaan je sectie.
Wordt een agent onderbroken, dan moet een opvolger uit dit bestand en `git log` kunnen verderwerken.
Lees eerst `TEAM.md` (briefing) en `GDD.md` (ontwerp, interface-contract §8, tests §9, scope §10, open vragen §11).

## Lead
- [ ] lead: open vragen GDD §11 beantwoorden (17 vragen; vooral 1 titel, 2–3 Huffman-conventies, 4 spatie/`_` en de
  tekst van Oef. 104, 5 Oef. 105, 11 LZW EARLY_STAMP)
- [ ] lead: kaart in `HubRegistry` toevoegen (start: `res://games/scriptorium/scenes/title.tscn`)

## Game designer
- [x] 13/10 16:31 designer: `design/GDD.md` v1 — titelvoorstel **Kortschrift** (*Het scriptorium van Zuinigem*,
  ambachtelijke codeerpuzzel met briefwisseling en De Voorlezing door Broeder Letterlijk), pijlers, mapping per werktuig
  (codeboom/codebord, binderij, levende boom + processie, meetlat + binaire naald, leesraam + register, stempelkast,
  draaitrommel, letterplank, duiventil) met speler/automatisch/fouten → gevolgen, bediening + schermen + HUD +
  werkbanken, campagne proloog + 6 hoofdstukken + Codex (36 levels, 25 P0) + Nachtwake exact uitgewerkt,
  scoring/sterren/Kapittel + coachzinnen, juice (39) en audio, interface-contract `Sc*` (incl. `ScDec`, `ScReader`,
  `ScLevelBot`), testgevallen T01–T42, scope P0/P1/P2 + bouwvolgorde, 17 open vragen.
- Alle leveldata (Huffman-stappen en codes, [g,o]-bomen per teken, intervallen en bitstrings exact, drietallen met
  alternatieven, LZW-codes en woordenboeken, gesorteerde rekken, p, terugwegen, move-to-front-getallen, gevolgen van
  typische fouten) zijn nagerekend met een Python-referentie die de notas letterlijk volgt (staat niet in de repo). Die
  reproduceert p. 85/86, 90–93, 96–98, 99–101, 106–108, 111–114, 115–122 cijfer voor cijfer. Twijfels staan in GDD §11.

## Art & audio director
- [ ] art: `design/ART.md`, `assets/` (+ `assets/CREDITS.md`), `scenes/art_preview.tscn`

## Core engineer
- [ ] core: `scripts/core/` volgens GDD §8 + tests T01–T42 (`tests/run_tests.gd`), `tests/sc_level_bot.gd`
  (`ScLevelBot`). Volgorde: GDD §10 "Bouwvolgorde" (eerst `ScCodes`, `ScDec`, `ScReference`, `ScReader` + T01–T22)

## Gameplay / front-end engineer
- [ ] front-end: titel (Esc → hub) → getijdenboek → brief → werkbank → voorlezing → Kapittel, P0-levels + Nachtwake
  (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
(nog niets; core noteert hier elke afwijking van GDD §8)
