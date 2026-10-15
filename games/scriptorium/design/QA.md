# Kortschrift (Scriptorium) — QA

Formaat: `[P0/P1/P2] [gefixt/open] waar — bevinding`. P0 = blokkeert spelen/leerstof fout, P1 = verwarrend of slecht
leesbaar, P2 = cosmetisch.

## Ronde 1 — 15/10 (front-end, steekproef per werktuig)

**Methode.** Core-tests (`run_tests.gd`, 1680 asserts, groen). Alle 25 P0-levels headless met `ScLevelBot` in de modi
`perfect` (overal 3★, juiste voorlezing) en `every` (fouten in elke stage); titel, getijdenboek (`map=1`), Nachtwake
(`wake=1 bot=random`), Kapittel (`replay=1`), pauze/spiekbrief/instellingen (`pause=1 sheet=1 settings=1`): geen
`SCRIPT ERROR` of `Parse Error` (enkel de gewone Godot-melding over resources bij het afsluiten). Per werktuig één
frame-opname (xvfb + `--write-movie`, 1600×900) en de getoonde waarden vergeleken met GDD §5/§9.

### Leerstof (getoonde waarden tegen GDD/core)
- [ok] codeboom 0-1: Fig. 25 o 00 · u 010 · d 011 · f 10 · t 11; strook `100001011` → `fout`.
- [ok] codebord 0-2: e = 0, n = 1, b = 10; strook `100100`… met knipreeksen, "nodig 2, alle 4".
- [ok] binderij 1-1: `boosdoeer` → `0001010001010101111011` (22 bits = optimum, gewoon 72), = p. 85.
- [ok] levende boom 2-2 `graag`: [gewicht, nummer] en processie 0·1 · 1·2 · 1·3 · 1·4 · 1·5 · 2·6 · 3·7 (stijgend);
  strook `g 0 r 00 a 101`; de boom van Letterlijk is gelijk.
- [ok] meetlat 3-2 `cag`: grenzen 0,33 … 0,354, strook `01011` (5 bits), = GDD/T11.
- [ok] leesraam 4-2: zegels `(0,0,a) (0,1,n) (0,0,v) (0,2,r) (0,0,d) (0,0,b) (1,3,EOF)` → `aanvaardbaar`; foutmodus
  geeft `aanvanrdbanr` = het nagerekende gevolg in de GDD.
- [ok] stempelkast 5-1 `banaanaanval`: 98 97 110 97 257 259, lades 256 ba · 257 an · 258 na · 259 aa · 260 ana;
  Letterlijk loopt (terecht) één lade achter.
- [ok] draaitrommel 6-1: rek `␣loongeen`, `een␣loong`, `en␣loonge`, `geen␣loon`, … (spatie het kleinst, = p. 116).
- [ok] letterplank 6-1: `1 1 7 7 6 2 3 2 8 0 9` (= p. 121).
- [ok] coachzinnen (eerste misstap per P0-level, bot `first`): verwijzingen Algoritme 9 p. 84, p. 92/94–95,
  Algoritme 11 p. 95, Algoritme 12 p. 101, p. 99, Algoritme 14 p. 105, p. 106, LZW p. 111/113, p. 116, p. 121 —
  passen bij het werktuig; intervallen in de zinnen kloppen (c = [0,3; 0,5), g bevat 0,5).

### Bevindingen
- [P1] [gefixt] Voorlezing — het venster van De Overkant werd 680 px hoog (minimumgrootte van de textuur, `size` vóór
  `expand_mode`) en schoof onder de kaart "origineel / Letterlijk leest". Nu 540 px, Letterlijk staat erin.
- [P1] [gefixt] Werkbank — Zeno's spreekrolletje bedekte een lange opdrachtband (1-3 `zaken_nemen_geen_keer`) en de
  notitie naast de band (0-2 "de abt schreef dit; …"). Het rolletje gaat nu rechts van Zeno als de band eronder loopt;
  de notitie wijkt zolang Zeno spreekt.
- [P1] [gefixt] Kopbalk — bij lange titels liep de notasverwijzing onder het inktpotje (1-3). Nu ingekort tot
  "notas p. …" of weggelaten (staat ook op de brief).
- [P2] [gefixt] Inktmeter — labels "optimum 33" en "gewoon 40" overlapten als beide dicht bij elkaar liggen (2-2).
- [P2] [gefixt] Levende boom — de wortel [n,m] stond over de kop "De levende boom …"; boom 45 px lager.
- [P2] [gefixt] Titel (attract) — af en toe "p_size <= 0" van de text server (tekst geschaald tot 0); tekenhulpen
  slaan grootte ≤ 0 nu over.
- [P1] [gefixt] Kapittel/herbeleving — het kopje van het alleen-lezen werktuig lag onder het label "De juiste zet";
  het kopje wordt in de herbeleving niet meer getekend.
- [P2] [gefixt] Leesraam (ontvangen) — label "binnengekomen zegel" overlapte het zegel; zegel 60 px naar rechts.
- [P2] [gefixt] Kapittel — "1 misstappen" → "1 misstap" (ook beslissing/klem).
- [P2] [gefixt] Coachzin LZ77: "loopt de match 1 letters ver" → "1 letter".
- [P2] [open] Inktmeter — als optimum en gewoon heel dicht liggen, loopt de optimumstreep door het label "gewoon".
- [P2] [open] Binderij 1-3 — de kleine 0/1-schijfjes van de deelbomen boven de stapels raken elkaar.
- [P2] [open] Zeno staat bij een band van 20 tekens net over de laatste index (19).
- [P2] [open] Afsluiten met de bot: Godot meldt "resources still in use at exit" (geen gevolg voor spelen).
