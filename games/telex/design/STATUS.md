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
  "Bouwvolgorde". **Volgende stap:** `TxShiftAnd`, `TxEditBoard` + T30/T31/T34 (mijlpaal 4).
- [x] 13/10 core: mijlpaal 1 — `TxCodes`, `TxReference` (Alg. 2–8, Def. 11/13/14, paden/bewerkingen) + testrunner
  (`tests/run_tests.gd`, filterargument) en suite `t_reference` (T01–T24, alle groen). Tests draaien:
  `$G --headless --path . --script res://games/telex/tests/run_tests.gd [-- t_reference]`.
- [x] 13/10 core: mijlpaal 2 — `TxEventLog` (coachzinnen + notasverwijzingen), `TxMachine` (basis: stroom/LIVE,
  scheur, waarheid, gemist/vals alarm met `cause_seq`/`affects`, snapshot/restore, signaalvolgorde §8.4), `TxBrute`,
  `TxKmp` (tanden, auto_zero/auto_strip, V[m]), `TxKmpTable` (def11 + spiegelrit Alg. 5), `TxLevels.make_machine`.
  Suite `t_machines` (T25–T27, T32 deels, tellers 1-1/3-1/3-2/3-3/3-4/3-5 tegen §5).
- [x] 13/10 core: mijlpaal 3 — `TxBmh` (stempelen, sleutel/handsprong, Nachtdienst zonder kaartenbak `cards:"none"`,
  `auto_jump` voor de finale) en `TxRabinKarp` (W_CALC/HORNER/ROLL/ALARM, signaalmodus 2-1, oorzaakketen van een
  foute wielstand naar het gemiste voorkomen, `true_hash(i)`, `history()`). Suite `t_machines2` (T28, T29, T33,
  tellers 2-1/2-2/2-3/4-1/4-2/4-3, T38 voor rk/bmh).

## Gameplay / front-end engineer
- [ ] front-end: titel (Esc → hub) → missiekaart → briefing → console → debrief, P0-levels + Nachtdienst (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
- `TxMachine.setup(stage, carry := {}, live := {})` en `TxLevels.make_machine(stage, carry, mode, live := {})`:
  extra optioneel argument `live = {"B": int}` (lusbak) voor LIVE-stages; in LIVE start `front` op 0.
- Naald-fx (`"needle"`) hebben extra velden `start` (en bij de Doorloper `gel`); `"bump"`-fx met `auto: true`/`burnt`
  als de Doorloper met `auto_strip` op een leeg/verbrand vakje stuit (geen klem van de speler, enkel het "tok").
- `TxKmpTable` def11: de stage eindigt automatisch zodra het laatste lege vakje geponst is (`done` blijft mogelijk om
  vroeger te stoppen = PUNCH_SHORT). Bij alg5 heeft de strook intern altijd m+1 vakjes (Algoritme 5 mag V[m] invullen);
  `output().strip` kan dus een extra vakje hebben (−1 = leeg).
- Gemist (`_check_passed`): een voorkomen is voorbij zodra het **sjabloon** (start) erover gaat. Bij de Doorloper is dat
  `start`, niet `need()` (= leeskop): de leeskop mag een begin passeren zonder dat het voorkomen verloren is.
- Brute kracht: `{"act":"next"}` wordt gelogd als type `SHIFT` (s = 1).
- Vingerafdruk: `ignore` bij een echt voorkomen markeert het meteen als MISSED (niet pas bij de volgende slide).
  In signaalmodus (2-1) is een "voorkomen" {start = end = signaalindex}. Enkel CALM (geen LIVE-wachttoestand).
- Springer: `key` klemt met `no_card` als de stage geen kaartenbak heeft (`cards:"none"`); het orakel geeft dan
  `{"act":"jump","s":V_H}`. Ook met foute kaarten geeft het orakel een handsprong (de kaart zou niet OK zijn).
