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

- [x] 13/10 lead: finale F-2 — het Zoeklicht met de hand 204 cellen laten vullen is te zwaar. Als de speler in F-2 het
  Zoeklicht kiest, vult de machine de tabel automatisch (animatie, telt als machinetijd) en kiest de speler enkel het
  minimum onderaan + de terugloop. Front-end bouwt dat zo; core past het aan als het niet al kan via `budget`/auto.
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
  "Bouwvolgorde". **Volgende stap:** wensen van de front-end/QA (zie hun secties) en eventueel P2 (Nachtdienst-Doorloper).
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
- [x] 13/10 core: mijlpaal 4 — `TxShiftAnd` (lampenbord + ruisbord M⁰..M^k, kaarten ponsen, foutkabel met 4 stekkers,
  hendel/kaart, NO_SHIFT/WRONG_CARD/LATE, bel per kolom, CHOOSE voor 6-2) en `TxEditBoard` (Algoritme 7 + 8: relais
  per cel met spelerswaarden, warm bij WRONG_MIN, PICK_END, teruglopen met klem `no_current`, herstelstrook,
  meerdere reeksen/matches, `want`). Suite `t_machines2` uitgebreid (T30, T31, T34, 5-1/5-2/6-1/6-2/7-1/7-2/8-x).
- [x] 13/10 core: mijlpaal 5 — `TxSabotage` (tegenzet), `TxLevelSpec`/`TxLevels` (alle 27 levels met data uit §5 +
  Nachtdienst-spec, ontgrendeling, `optimum()`), `TxDirector` (stages/carry, LIVE-klok + waarschuwing, ritme 5-3,
  rivaal 3-5, finale met machinekeuze + automatische doorloop + budget, Nachtdienst met lampjes, hint, terugnemen),
  `TxScoring` (punten §6.3, combo, sterren, eindrapport), `TxSave`, `TxTextGen`, bot `tests/tx_bot.gd` (`TxBot`).
  Suite `t_levels`: T32 (rivaal), T35–T40, foutmodi. **Alle levels halen met de bot 3 sterren en de tellers van §5.**
  Front-end: zie "API-afwijkingen" hieronder voor alles wat bovenop GDD §8 kwam.
- [x] 13/10 core: mijlpaal 6 — suites `t_properties` (600 willekeurige z/t: alle matchers = naïef, tikken =
  pseudocode; 300 Rabin-Karp-runs; spiegelrit = Alg. 5 = Def. 11 voor 1008 woorden (lead-beslissing 4); M^k = Def. 14
  cel per cel; editeerafstand-DP = recursie; terugloop = geldige stijgende reeks van d bewerkingen; D = min over l;
  robuustheid met willekeurige fouten/klemmen) en `t_meta` (zuiverheid, unieke class_names, coachzin + notasverwijzing
  voor elk verdict, klemredenen ⊆ contract, signaalvolgorde, klem verandert niets). **953 asserts, alles groen (~30 s).**
  Algoritme 8: `pick_end` aanvaardt ook kolom 0 (de lus van de notas loopt van 0 t.e.m. |t|).
- [x] 13/10 core: Nachtdienst-variant Doorloper (P1): `TxLevels.endless_spec(k, seed, "kmp")` (strook met 2 verbrande
  vakjes); KMP-stage met strook uit de carry stuurt eerst `{"fx":"strip_move"}`.
- **Gebruik (front-end), kort:** `var dd := TxDirector.new(); dd.stage_started.connect(_on_stage); dd.level_finished
  .connect(_on_end); dd.start(TxLevels.get_spec("3-1"))` · in `_on_stage(i, mc)`: verbind `mc.changed/phase_changed/
  counters_changed/reported/consequence/event_logged` en lees `mc.cursor()`/`mc.render()` · per frame `dd.tick(dt)` ·
  speler: `dd.apply({"act":"shift","s":3})`, slepen/tanden: `mc.preview(move)` · `dd.hint()`, `dd.undo()` · einde:
  `TxSave.record(id, report)`, debrief uit `report` (+ `dd.log` voor de herbeleving: `entry.before` → tweede machine
  via `TxLevels.make_machine(stage, carry)` + `restore`) · `dd.dispose()` bij het verlaten. Attract/QA: `TxBot`
  (`tests/tx_bot.gd`) met `step(dd, dt)`.

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
- Lampenbord: carry heet `{"c":{…}, "wiring":{l:src}, "seqs":{"cards":seq,"wire":seq}}`; `seqs` bewaart het
  logvolgnummer van een foute `cards_done`/`wire_done` zodat een gemist voorkomen in de doorloop-stage daarnaar wijst
  (gedeelde log van de director). Een bel met start < 0 meldt start = 0 en real = false. Bij een foute keuze in
  CHOOSE: verdict WRONG_PICK + consequence false_alarm (geen tweede FALSE_ALARM-logentry).
- Schakelbord: stage-veld `want` (aantal verschillende reeksen/matches dat het orakel zoekt, −1 = alle). Algoritme 7
  meldt geen "hit" (enkel `print_ops`); Algoritme 8 meldt de match {start, end = laatste index, level = waarde}.
  `finish` zonder één echte match markeert alle beste matches als MISSED.
- **Director (extra t.o.v. §8.8):** signalen `choice_needed(index, options, stage)` (finale: kies een machine met
  `apply({"act":"pick_machine","machine":"kmp"|"shift_and"|"shift_and_k"|"bmh"|"brute"|"edit"})`), `tape_started(index,
  spec)` en `lives_changed(lives)` (Nachtdienst). Methodes `correct_move()`, `wrong_moves()`, `impossible_moves()` (op
  levelniveau; `{"act":"none"}` als de klok/automaat aan zet is), `can_undo()`, `run_autoplay()`, `dispose()` (altijd
  oproepen bij het verlaten: verbreekt signaalcycli), velden `completed`, `machines` (alle stage-machines), `tempo`
  (live-tempo 0,8) + `assisted` (telt als hulp), `front_f`. `stage_started` komt vóór `machine.begin()`: verbind daar
  de signalen van de machine. Het level eindigt automatisch na de laatste stage (`level_finished`); `finish()` geeft het
  rapport (en stopt de Nachtdienst). Opslaan: `TxSave.record(id, report)`.
- LIVE: de director laat `front` ook ná het einde van het lint doorlopen (`set_front(f)` met f > n): de versnipperaar
  draait verder, dus wie blijft twijfelen, scheurt ook op het einde.
- Ritme (5-3): de director trekt de hendel op elke tel (`beat(j)`) en steekt na de tel blanco in (LATE als t[j] in z).
  `correct_move()` van de director is `none` zolang de tel aan zet is of de juiste kaart blanco is.
- Undo herstelt ook de punten. Punten voor correcte beslissingen zijn begrensd op het aantal beslissingen bij perfect
  spel, en de bonus "bespaarde tikken" op die van perfect spel: zo is perfect spel altijd ≥ elke foutmodus.
  Tegenzet `bmh_min` (minimaliseren) geeft 10 × (n − beste) in plaats van 10 × metriek.
- Finale: keuzestages (`"machine":"choice"`) worden bij de keuze uitgeklapt (`TxLevels.choice_stages`): voorbereiding
  door de speler, doorloop met `"autoplay":true` (de director speelt, met de tabellen van de speler; `budget` stopt de
  machine via `TxMachine.abort("budget")` → rest gemist). F-2 gebruikt `"truth"` + `"match_end"` (de twee verminkte
  codewoorden; een melding telt als het einde klopt), zodat exacte machines ze missen.
- Extra stage-velden: `want` (edit), `auto_jump` (bmh, finale), `v_hint` (kmp, tutorial), `tutorial` (shift_and:
  `expected_card` in de cursor), `choose` (6-2: stage D zit in stage C), `autoplay`, `budget`, `calm`, `tape`, `truth`,
  `match_end`. 6-1/6-2 stage A ponst de kaarten met `k: 0`.
- Extra fx: `"restore"` (na undo: alles hertekenen), `"abort"`, `"choose"`, `"column"` met `reset` (scheur op het
  lampenbord), `"notch"` ook bij een voorgezette h(z). Extra logtypes: `PICK_MACHINE`, `ABORT`, `FINISH`.
- Extra machine-API: `tables()` (jouw tabel vs juist, voor de debrief), `machine_time()`, `found_count()`,
  `open_truth()`, `abort(reason)`; `TxRabinKarp.true_hash(i)/history()`, `TxEditBoard.distinct_sequences()/
  matches_found()/true_table()`, `TxShiftAnd.expected_card()/exact_starts()`, `TxKmp.clash(s)`.
- Rapport (`final_report`) heeft extra velden: `n_stars`, `found`, `strak`, `completed`, `machine_time`, `choices`,
  `tapes`, `lives`, `rival`, `id`; `mistakes[]` bevat meteen `coach` + `ref` (coachzin + notasverwijzing).
- Nachtdienst: −1 lampje per gemist codewoord, +1 (max 3) na een foutloos lint, game over bij 0; per lint
  `2 × (brute kracht − tikken)` bonus.
- Springer: `key` klemt met `no_card` als de stage geen kaartenbak heeft (`cards:"none"`); het orakel geeft dan
  `{"act":"jump","s":V_H}`. Ook met foute kaarten geeft het orakel een handsprong (de kaart zou niet OK zijn).
