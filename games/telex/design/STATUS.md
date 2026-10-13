# Telex — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>`. Zet open punten en de volgende stap bovenaan je sectie.
Wordt een agent onderbroken, dan moet een opvolger uit dit bestand en `git log` kunnen verderwerken.
Lees eerst `TEAM.md` (briefing) en `GDD.md` (ontwerp, interface-contract §8, tests §9, scope §10, open vragen §11).

## Lead
- [x] 13/10 lead: open vragen GDD §11 beantwoord — **bindend** (gaan voor op GDD):
  1. V[m] via Definitie 11 uitgebreid tot j = m voor ALL-levels: akkoord. Terugblik van 3-4 toont dit als antwoord op
     Oef. 41 en vermeldt dat Algoritme 4 zelf bij de eerste treffer stopt.
  2. Tik = één tekenvergelijking; hash-/lamp-/celbewerkingen apart: akkoord.
  3. Te kleine KMP-verschuiving klemt (geweigerd, geteld als misstap): akkoord.
  4. Spiegelrit-procedure: akkoord, op voorwaarde dat de core test dat de geponste tabel na een foutloze rit
     identiek is aan Algoritme 5 én Definitie 11 voor alle levelwoorden + 1000 willekeurige woorden.
  5. Rabin-Karp (a)–(d): akkoord. "Meld meteen" moet in de terugblik expliciet uitleggen dat Algoritme 3 na gelijke
     hash nog `strings_gelijk` doet (valse treffer, p. 52–53).
  6. Shift-AND-start: akkoord.
  7. Ruisbord-stekkers: akkoord.
  8. Stijgende volgorde (Lemma 17): akkoord, maar toon in de terugblik van 7-1 ook de reeks in de volgorde van de notas
     (p. 72) naast die van het spel, zodat Henri de notas herkent.
  9. Elke optimale match aanvaarden, "alle" = ★★★: akkoord.
  10. Oef. 32 zonder formeel bewijs: akkoord; Notas-spiekbriefje verwijst naar de oefening voor het bewijs.
  11. Nachtdienst = Springer: akkoord.
  12. Machinetijd-eenheden in de finale: akkoord (terugblik zegt dat het een spelvereenvoudiging is).
  13. ASCII-apostrof: akkoord.
  14. Spoelmeter: akkoord (als visualisatie benoemen, niet als begrip uit de notas).
  15. Rivaal in 3-5: akkoord.

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
  "Bouwvolgorde". **Volgende stap:** `TxMachine` + `TxBrute`/`TxKmp`/`TxKmpTable` (mijlpaal 2).
- [x] 13/10 core: mijlpaal 1 — `TxCodes`, `TxReference` (Alg. 2–8, Def. 11/13/14, paden/bewerkingen) + testrunner
  (`tests/run_tests.gd`, filterargument) en suite `t_reference` (T01–T24, alle groen). Tests draaien:
  `$G --headless --path . --script res://games/telex/tests/run_tests.gd [-- t_reference]`.

## Gameplay / front-end engineer
- [ ] front-end: titel (Esc → hub) → missiekaart → briefing → console → debrief, P0-levels + Nachtdienst (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
(nog niets; core noteert hier elke afwijking van GDD §8)
