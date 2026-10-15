# Kortschrift (Scriptorium) — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>`. Zet open punten en de volgende stap bovenaan je sectie.
Wordt een agent onderbroken, dan moet een opvolger uit dit bestand en `git log` kunnen verderwerken.
Lees eerst `TEAM.md` (briefing) en `GDD.md` (ontwerp, interface-contract §8, tests §9, scope §10, open vragen §11).

## Lead
- [x] 13/10 lead: open vragen GDD §11 beantwoord — **bindend** (gaan voor op GDD):
  1. Titel **Kortschrift** (*Het scriptorium van Zuinigem*); map/prefix blijven `scriptorium`/`Sc`. Lead zet de
     hub-kaart.
  2–3. Huffman: elk door Algoritme 9 toegelaten paar aanvaarden, inkthand volgt de twee-plankenregel; oriëntatie per
     level zoals de figuur in de notas: akkoord.
  4. `_` letterlijk in Oef. 81/97/101, spatie in Oef. 104/105: akkoord (Oef. 104: tekst = `toon gaat`, de lijst bevat
     geen d/r — vermeld dat in de intro).
  5. Oef. 105: lead heeft het nagerekend (ook met p = 7 als index, ook met de volgorde van de oefeninglijst als
     sorteervolgorde): de laatste kolom valt telkens uiteen in meerdere cycli, dus geen geldige BWT-uitvoer. 6-5 blijft
     P2 en bouwt enkel het move-to-front-deel; de terugblik zegt neutraal "deze code geeft geen geldige BWT-uitvoer —
     vraag het na bij de assistenten" (niet "de notas zijn fout").
  6. LZ77: elke maximale match aanvaarden: akkoord.
  7. Exacte getallen tonen + neutrale verwijzing naar p. 103: akkoord.
  8. Gulzig lezen bij niet-prefixcodes: akkoord (als spelafspraak benoemen).
  9–10. Adaptieve Huffman-afspraken: akkoord.
  11. LZW te vroeg stempelen = else-tak met dubbele lade: akkoord (gevolg in de wereld, telt als misstap).
  12. BWT-conventies volgens p. 117: akkoord.
  13–17: akkoord zoals voorgesteld.

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
- [x] 14/10 17:40 art: `design/ART.md` (stijl "kaarslicht-scriptorium": notenhout, perkament, ossenbloed leer met
  goudstempeling, zegelwas, glas-in-lood; palet, fonts, vormtaal, elk GDD-element met functie, juice-timings, partikels,
  shaders, leesbaarheid/kleurenblind, audio + mix), `assets/MANIFEST.md`, `assets/CREDITS.md`.
- [x] 14/10 art: assets (16 MB, generators in `assets/_gen/`): 4 achtergronden (`bg_desk`, `bg_desk_night`, `bg_room`,
  `bg_overkant`), 3 naadloze texturen, 15 partikels, 3 shaders (kaarslicht, lichtbundels, inkt-in), fonts Grenze Gotisch +
  UnifrakturMaguntia (OFL), 55 sfx (veer 0/1, inkt, lakzegel, binden, klem, wissel, naald, draad, stempel, lades, trommel,
  plank, duif, keelschrapen, letterzang, voorlezing juist/onzin, kaars, kist, sterren …), 6 muzieklussen + 3 jingles,
  sfeerlus (loop-vlaggen gezet).
- [x] 14/10 art: `ScPal` (palet, fonts, ␣ als getekend bakje), `ScDraw` (perkament/hout/leer, kaars, veer, inktpot, zegels,
  stempelafdruk, opdrachtband, kortschrift-strook, voorlezing, monnik, Zeno, Letterlijk, Gommaar, duif, inkthand, rol,
  inktmeter, koker, pillen, iconen), `ScDrawTools` (tak/knoop/blad, stapel, touwklos, nng, meetlat, naald, schaar,
  rekenboek, leesraam, draad, lades, stempelkast, zetstok, hendels, trommel, rek, letterplank, cijferstempels, duiventil,
  getijdenboek, initialen, brief, kist, kasboek), `ScUi`, `ScFx`; `scenes/art_preview.tscn` (4 pagina's + `night=1`),
  zonder ERROR, screenshots in `design/screens/`.
- Voor de front-end: alles is statisch; `ScDraw.prepare(node)` in `_ready` (texture_repeat), grote NPOT-achtergronden als
  `TextureRect`. Geluid afspelen met een eigen `ScSnd` naar het voorbeeld van `TtSnd` (namen in MANIFEST).

## Core engineer
- [ ] core (open, P2): level 2-6 (Oef. 88) en 3-5 (precisie, Oef. 96) niet gebouwd — GDD: "data te bepalen" /
  "uit te werken als de lead dat wil". Volgende stap als de lead het vraagt.
- [x] 14/10 core: mijlpaal 4 — property-tests T39–T42 (`t_properties`: 2000 adaptieve teksten met Lemma 22/23 en
  zender = ontvanger = Overkant, 500 gewichtsrijen exhaustief, 2000 roundtrips LZ77/LZW/BWT/MTF/aritmetisch, 500
  intervallen minimaal) en contract-suite `t_meta` (signaalvolgorde, preview, fx-namen, coachzinnen, layout, leveldata,
  bots met foutmodi op alle P0-levels). **1680 asserts, 0 fout** (`run_tests.gd`, ± 20 s).

**Gebruiksnota voor de front-end (core is klaar voor P0 + P1):**
- Level spelen: `var dd := ScDirector.new(); dd.stage_started.connect(f); dd.reading_started.connect(g);
  dd.level_finished.connect(h); dd.start(ScLevels.get_spec("2-2"))`. In `stage_started(i, tool)` de signalen van het
  werktuig verbinden (`changed`, `phase_changed`, `counters_changed`, `output_changed`, `copy_changed`,
  `overkant_changed`, `event_logged`); `begin()` volgt meteen daarna. Zetten: `dd.apply(move)` (dictionaries §8.7),
  per frame `dd.tick(dt)`. Hint `dd.hint()`, terugnemen `dd.undo()`/`dd.can_undo()`, hernemen `dd.resume_from(seq)`
  (seq uit `report.mistakes[i].seq`; werkt ook naar een vorige stage), hulplijnen: `dd.assisted = true`.
- Tekenen: `tool.cursor()` / `tool.render()` (per werktuig §8.7; ScDec-getallen als strings + `_f`-floats),
  bomen `ScTree.render()` + `ScTreeLayout.layout(render, w, h)`. Een tweede, alleen-lezen werktuig voor de
  herbeleving: `ScLevels.make_tool(stage, carry)` + `restore(entry.before)` (carry: `dd._carries[stage]` of
  `ScLevels.optimum(spec).stages[i-1].output`).
- Voorlezing: `reading_started(r)` met `{stage, original, read, marks, equal, first_diff, diff, pigeons, demo,
  receive, ink, opt, chain}`; alle voorlezingen staan in `dd.readings`. Oorzaak van een inktvlek op positie p:
  `dd.log.cause_of(p)` (of het GARBLED-event: `data.cause_seq`); coachzin + verwijzing: `dd.log.coach_line(e)`,
  `dd.log.notes_ref(e)`.
- Rapport (`level_finished` / `dd.finish()`): §8.8 + `n_stars`, `readings`, `structures` ([{stage, tool, yours,
  correct}], vergelijkbaar), `rounds`, `lives`. Opslaan: `ScSave.record(id, report)`; ontsluiten
  `ScLevels.is_unlocked(id, ScSave.all_stars())` (ook `"nachtwake"`). Tests zetten `ScSave.path` om.
- Nachtwake: `dd.start(ScLevels.endless_spec(0, seed))`; signalen `round_started(r, stage)`,
  `candle_changed(lives, burn)`; `dd.lives`, `dd.rounds`; stoppen met `dd.finish()`; combo via
  `dd.scoring.combo_changed` / `full_flame`. Highscore: `ScSave.add_highscore(score, naam, datum)`.
- Bot (attract, QA): `ScLevelBot.new(mode, seed).play(spec)` of per frame `bot.step(dd, dt)`; modi in
  `tests/sc_bot.gd` ("", first, every, random, act:<act>, bump, hint, undo, resume, idle); Nachtwake:
  `play_wake(seed, rondes)`.
- [x] 14/10 core: mijlpaal 3 — `ScDirector` (voorlezing/ketens, hint, terugnemen, hernemen, Nachtwake), `ScScoring`,
  `ScSave`, `ScTreeLayout`, `ScLevelBot` (`tests/sc_bot.gd`) + T33–T38 (suite `t_levels`): alle 34 levels 3★ met de bot
- [x] 14/10 core: mijlpaal 2 — `ScTool` (basis), `ScEventLog`, alle werktuigen (`ScPrefixReader`, `ScCodeBoard`,
  `ScBindery`, `ScLivingTree`, `ScRuler`, `ScWindow` + `ScRegister`, `ScStampCase`, `ScDrum`, `ScShelf`, `ScDovecote`),
  `ScLevelSpec`, `ScLevels` (alle levels behalve 2-6/3-5), `ScTextGen` + T23–T32 (suite `t_tools`)
- [x] 14/10 core: mijlpaal 1 — `ScCodes`, `ScDec` (exact), `ScTree`, `ScReference`, `ScReader` + T01–T22
  (`tests/run_tests.gd`, suite `t_reference`)

## Gameplay / front-end engineer
- [ ] front-end (open): P2-levels (2-6/3-5 bestaan niet in de core), tekstgrootte-instelling, kleurenblindmodus als
  aparte schakelaar (vormen staan nu altijd aan), P2-cosmetica uit `design/QA.md` (open punten).
- [x] 15/10 front-end: QA-ronde 1 (`design/QA.md`): alle 25 P0-levels opnieuw met de bot (`perfect` 25× 3★, `every`
  geeft de nagerekende gevolgen, bv. 4-2 `aanvanrdbanr`), titel/kaart/Nachtwake/Kapittel/pauze zonder SCRIPT ERROR;
  per werktuig een frame-opname nagekeken tegen GDD (codes, bomen, intervallen, triples, stempels, BWT/MTF) en de
  coachzinnen per P0-level. Gefixt: Voorlezing-venster te hoog (TextureRect `size` vóór `expand_mode`), Zeno-rolletje
  over de opdrachtband, notasverwijzing onder de inktmeter, labels inktmeter, kopje in de herbeleving, zegel-label
  leesraam, levende boom onder zijn kop, fontgrootte 0 (titel-attract), meervouden ("1 misstap", "1 letter").
  Screenshots `design/screens/06_levende_boom_graag.jpg`, `07_kapittel_herbeleving.jpg`.
- [x] 15/10 front-end: alle schermen en werktuigen gebouwd; **alle 25 P0-levels + alle P1-levels (0-3, 1-4, 1-5, 4-5,
  4-6, 5-5, 6-4, 6-5, Codex) spelen door met de core-bot zonder SCRIPT ERROR** (3★ perfect; foutmodi `every`
  geven onzin-voorlezingen zoals `gg…`, `aag`, `aanvanrdbanr`, `gen loong`); Nachtwake speelt (bot=random).
  - Scènes: `scenes/title.tscn` (← Alle games / Esc → `HubRegistry.HUB_SCENE`, attract: de kopiist bindt in een lus),
    `scenes/book.tscn` (getijdenboek, 4 spreads, initialen met lakzegels, slot, Nachtwake-kaarsje),
    `scenes/workbench.tscn` (één scène voor alle levels + Nachtwake).
  - Scripts (`scripts/game/`): `sc_workbench.gd` (wachtrij: alle signalen van ScDirector/werktuig worden in volgorde
    afgespeeld: fx → nieuwe toestand → voorlezing → Kapittel), `ScView` (basis: klikzones, hover, ←/→+Enter,
    inkthand, klemstof/schok), views `sc_view_{prefix,board,bindery,living,ruler,window,stamps,drum,shelf,dovecote}.gd`,
    `ScStrip` (kortschrift + koker, scrolt), `ScBrief` (brief + kist), `ScReading` (De Voorlezing), `ScReview` (Kapittel:
    sterren, kasboek, inktvlekken → oorzaak, tijdlijn + herbeleving met alleen-lezen werktuig + coachzin + "Herneem
    vanaf hier"), `ScNotesView` (notas-weergave: notas vs. jij), `ScPause`, `ScSettings`, `ScCheatSheet`,
    `ScWakeEnd` (dageraad + top-10), `ScSnd` (eigen geluid/muziek), `ScSession` (routes, args, instellingen).
  - QA-args (na `--`): `level=2-2`, `wake=1 seed=5`, `map=1`, `bot=perfect|first|every|random|act:keep|…`,
    `bot_delay=0.35`, `speed=4`, `review=0` (print `SC_REPORT … stars= points= read=` en stopt met bot),
    `replay=1`, `notes=1`, `chain=1`, `save=qa` (aparte opslag), `unlock=1`, `quit_at=N`.

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
- Bot: `games/scriptorium/tests/sc_bot.gd` (class `ScLevelBot`), niet `sc_level_bot.gd` (zo stond het in de opdracht).
- Extra fx: `"snap"` {a, b} (Nachtwake: fout paar, het touw knapt, er wordt niet gebonden), `"trial_read"`
  {text, original, marks} (codebord: proeflezing bij NOT_PREFIX, stage blijft open), `"restore"` (na terugnemen/hernemen).
  Extra velden: `read_path.write/raw`, `segment.auto`, `walk.auto` (eerste stap), `insert.auto` (auto_sort).
- Extra logtypes: `WRITE_OUT` (levende boom: geschreven tokens), `AUTO_CUT` (meetlat, auto_after), `UNREADABLE`
  (strook onleesbaar: copy eindigt op "…", fx bump reason "unreadable"), `READING`, `CANDLE` (Nachtwake). Elke entry
  heeft `data.at` = tekstpositie; `cause_of(pos)` = laatste misstap met `at ≤ pos`.
- `ScEventLog.mistakes()` telt GARBLED en TWO_PIGEONS niet mee (dat zijn gevolgen, geen beslissingen); zie
  `consequences()`. Sterren veranderen daardoor niet (een gevolg heeft altijd een misstap als oorzaak).
- Punten (campagne) worden uit de log herberekend (`ScScoring.compute`), zodat ze kloppen na terugnemen/hernemen;
  correcte beslissingen ten hoogste zoveel als bij perfect spel. `place`/`remove`/`reset` (codebord) en `register`
  (leesraam) zijn geen beslissingen.
- Leesraam met register: het orakel geeft eerst `{"act":"register"}` (anders haalt de bot ★★★ zoekwerk ≤ 30 niet).
- Letterplank: staat een teken van de invoer niet in de beginlijst (bv. p = 2 na een verkeerd rek in 6-1), dan zet
  de core het achteraan bij (`cursor().extended`); anders kon de speler niet verder.
- Meetlat UNREACHABLE: de foute 0 kost ook inkt (`ink` = bits + `wasted`).
- Extra stage-sleutels: bindery `"strict"` (Nachtwake), `"symbols":"carry"`; shelf `"positions"` (positienummers
  tonen); prefix_read `"text"` (bits = codering met de code uit de carry, Nachtwake-leesronde); stampcase-codes mogen
  letters zijn. `ScTool.structure()` (terugblik) en `ScSave.add_seal/seals` zijn toegevoegd.
- Niet gebouwd (P2): 2-6 en 3-5 (zie open punt). 6-5 = enkel move-to-front (lead, vraag 5).
