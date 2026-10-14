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
- [ ] core: property-tests (T39–T42), meta-suite, gebruiksnota afwerken — bezig
- [x] 14/10 core: mijlpaal 3 — `ScDirector` (voorlezing/ketens, hint, terugnemen, hernemen, Nachtwake), `ScScoring`,
  `ScSave`, `ScTreeLayout`, `ScLevelBot` (`tests/sc_bot.gd`) + T33–T38 (suite `t_levels`): alle 34 levels 3★ met de bot
- [x] 14/10 core: mijlpaal 2 — `ScTool` (basis), `ScEventLog`, alle werktuigen (`ScPrefixReader`, `ScCodeBoard`,
  `ScBindery`, `ScLivingTree`, `ScRuler`, `ScWindow` + `ScRegister`, `ScStampCase`, `ScDrum`, `ScShelf`, `ScDovecote`),
  `ScLevelSpec`, `ScLevels` (alle levels behalve 2-6/3-5), `ScTextGen` + T23–T32 (suite `t_tools`)
- [x] 14/10 core: mijlpaal 1 — `ScCodes`, `ScDec` (exact), `ScTree`, `ScReference`, `ScReader` + T01–T22
  (`tests/run_tests.gd`, suite `t_reference`)

## Gameplay / front-end engineer
- [ ] front-end: titel (Esc → hub) → getijdenboek → brief → werkbank → voorlezing → Kapittel, P0-levels + Nachtwake
  (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
(nog niets; core noteert hier elke afwijking van GDD §8)
