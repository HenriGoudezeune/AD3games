# Scriptorium — teambriefing (lees dit eerst)

## Context
Henri (bachelor informatica, UGent) leert AD3 (prof. Brinkmann) door games te spelen. De repo `AD3games` is een
**verzameling games met één gedeeld startscherm (hub, `scenes/hub.tscn`, registry `scripts/hub/hub_registry.gd`)**.
Andere games (kwaliteitsreferentie, NIET wijzigen): **Hash & Dash** (extendible hashing; `scenes/`, `scripts/`,
`design/`, `tests/`), **Trietuin** (tries/suffixbomen; `games/trietuin/`) en **TELEX** (string matching;
`games/telex/`), die laatste twee worden parallel gebouwd. Lees hun design-documenten (GDD, ART, STATUS) om te zien
hoe een goed ontwerp, interface-contract en werkwijze eruitzien.

Henri's harde eisen (gelden voor álle games):
- Een **echte, volledige, professionele game** — geen quiz in een spelletjesjasje. Topanimaties en -feel (juice),
  goede audio, duidelijke UI, een campagne met progressie, sterren, een rapport/terugblik na elk level.
- **Kernprincipe: de spelregels ZIJN het algoritme.** De speler voert zelf de stappen uit. Fouten worden niet
  afgestraft met "❌ fout" maar hebben **gevolgen in de spelwereld**. Na het level legt een terugblik uit wat er
  misliep, met verwijzing naar de lesnotas.
- **Correct volgens de lesnotas** (die gaan altijd voor): dezelfde definities, notatie, tie-breaking en conventies.
- Taal in de game: **Nederlands**. Elke game moet **anders aanvoelen** dan de vorige (ander genre, andere wereld,
  andere kernhandeling): Hash & Dash = management-arcade (pakjesdepot), Trietuin = organische bouw-en-test-tuin,
  TELEX = analoge spionage-console met machines en linten.

## Leerstof: lesnotas AD3 2026, hoofdstuk 4 "Compressiealgoritmen" (r. ~4178–6329, gedrukt p. 81–122)
- PDF: `lesnotas_AD3_2026.pdf` in de repo-root. Tekst (layout behouden): `/tmp/claude-0/lesnotas_layout.txt`.
  Figuren: `pdftoppm -f N -l N -r 110 -png lesnotas_AD3_2026.pdf <scratch>/p` en de PNG lezen met de Read-tool.
- Inleiding (p. 81–84): compressie zonder verlies, geen algoritme comprimeert alles (Oef. 76–78), entropie/prefixcodes.
- §4.1 Huffman (r. 4360–, p. 84–89) en §4.1.1 adaptieve (dynamische) Huffman (p. 89–98: nng-top, sibling property,
  Algoritme 9/10 ...). §4.2 aritmetisch coderen (p. 98–104, intervallen, precisie). §4.3 LZ77 (p. 104–109, venster,
  (offset, lengte, teken)-triples) en §4.3.1 LZ77 met deelstringbomen (p. 109–110). §4.4 LZW (p. 110–115, groeiend
  woordenboek, ook decoderen en het speciale geval). §4.5 Burrows-Wheeler (p. 115–122, rotaties sorteren, laatste
  kolom, terugtransformatie, move-to-front/run-length als ze in de notas staan).
- Buiten scope: hoofdstuk 5 en verder.

## Concept-richting van de lead (de designer werkt het uit, mag verbeteren of een beter idee voorstellen, met motivatie)
Werktitel **Scriptorium**: een gezellig-spannende **middeleeuwse kopiistenwerkplaats** (abdij, perkament, inkt, zegels,
kaarslicht). Perkament en inkt zijn duur: elke letter/bit kost. De broeders moeten boeken en boodschappen zo kort
mogelijk bewaren en verzenden (per duif/koerier met beperkt gewicht), maar **zonder iets te verliezen**: een
ontvangende abdij moet alles exact kunnen terugschrijven (decoderen is even belangrijk als coderen). Elk algoritme is
een **ambacht/werktuig** dat je leert:
- Huffman: een "steno-boom" (codeboek) bouwen door telkens de twee lichtste stapels perkament samen te binden;
  frequente letters krijgen korte tekens. Fouten: een code die geen prefixcode is → de ontvanger leest onzin.
- Adaptieve Huffman: een levende boom die zich herschikt terwijl de tekst binnenkomt (nng-top, gewichten, wisselen
  volgens de notas) — beide abdijen moeten dezelfde boom bijhouden.
- Aritmetisch coderen: een liniaal/meetlat waarop je het interval telkens verder inknipt.
- LZ77: "zoals hierboven" — terugverwijzen naar een stuk dat al geschreven is binnen het leesvenster (een schuivend
  raam/leeslint), triples (offset, lengte, volgend teken); met deelstringbomen sneller zoeken.
- LZW: een stempelkast die zich vult met nieuwe stempels (woordenboek) tijdens het schrijven; de ontvanger bouwt
  dezelfde kast op (inclusief het lastige speciale geval).
- Burrows-Wheeler: een draaitrommel/rol met alle rotaties, sorteren, de laatste kolom overschrijven — en de magische
  terugweg.
Campagne als hoofdstukken van het kloosterjaar of opdrachten van verschillende abdijen; kosten = perkament/inkt/
gewicht; sterren voor compressie dicht bij het optimum en foutloze decodering; de oefeningen uit de notas als
herkenbare opdrachten; en een eindeloze modus. De designer mag een origineler genre kiezen (bv. puzzel, roguelite,
ritme), zolang het anders aanvoelt dan de andere drie games.

## Techniek
- **Godot 4.7.2**, GDScript, 2D, renderer *GL Compatibility*, viewport 1920×1080, stretch `canvas_items`/`expand`
  (zelfde `project.godot` als Hash & Dash; één Godot-project voor alle games).
- Godot-binary in deze cloud-container: `G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64`.
  - importeren: `$G --headless --path . --import`
  - tests: `$G --headless --path . --script res://games/scriptorium/tests/run_tests.gd` (script `extends SceneTree`, `quit(code)`)
  - scène draaien + frames opnemen (screenshots/animatie bekijken, werkt via virtuele display):
    `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --write-movie <map>/f.png
    --fixed-fps 30 --quit-after <frames> res://games/scriptorium/scenes/X.tscn` → PNG per frame, bekijk met de Read-tool.
    Scripted input/bots voor QA: zie `tools/drag_test.gd` en `tests/bot.gd` van Hash & Dash.
  - Controleer altijd de uitvoer op `SCRIPT ERROR` / `ERROR:` / `Parse Error` — Godot faalt vaak stil.
- Henri speelt op **Windows** (dubbelklik op een `.bat` die de Godot-editor-exe met `--path` start). Alles moet daar
  ook werken: geen Linux-specifieke paden in de game.
- **Mappen voor deze game (alles onder `games/scriptorium/`):** `design/` (documenten), `scripts/core/` (pure logica,
  geen nodes), `scripts/game/` (gameplay/UI), `scenes/`, `assets/{art,sfx,music}/`, `tests/`. Gedeelde fonts:
  `res://assets/fonts/` (Fredoka, JetBrains Mono) mag je hergebruiken.
- **`class_name` is globaal in Godot**: Hash & Dash gebruikt al o.a. `Scoring`, `SaveData`, `DaySpec`, `Days`,
  `DayDirector`, `EventLog`, `Parcel`, `Bucket`, `Pal`, `UiKit`, `HashUtil`, `ExtHashModel`. **Prefix al jouw
  class_names met `Sc`** (bv. `ScHuffman`, `ScScoring`, `ScSave`). Geen nieuwe autoloads tenzij nodig; als het moet:
  prefix `Sc` en vermeld het in STATUS. Je mag de bestaande autoloads `Sfx`, `Juice`, `Transition` gebruiken
  (lees ze eerst), maar niet wijzigen. Opslag: `user://scriptorium_save.json`.
- **Bouw scènes bij voorkeur in code** (nodes aanmaken in `_ready`); houd `.tscn`-bestanden minimaal.
- Geen betaalde/niet-vrije assets: enkel CC0 (bv. Kenney.nl, al deels in `assets/`) of zelf gegenereerd (code,
  shaders, procedureel, Python-scripts zoals `assets/_gen/`). Bronnen + licentie in `games/scriptorium/assets/CREDITS.md`.
  Netwerk werkt via een proxy; GitHub-downloads lukken, andere sites mogelijk niet.
- **Hub:** `scenes/hub.tscn` bestaat al; de lead voegt de kaart toe in `HubRegistry`. Scriptorium start via
  `res://games/scriptorium/scenes/title.tscn`; Esc/"terug" op het titelscherm gaat naar `res://scenes/hub.tscn`.

## Team en volgorde
1. **Game designer** → `games/scriptorium/design/GDD.md` (volledig spelontwerp, levels exact uitgewerkt met teksten en zoekwoorden,
   verwachte uitkomsten (treffers, tabellen, matrices), scoring/balans, UI/UX, juice-lijst, interface-contract core ↔ front-end).
   **Art & audio director** (parallel) → `games/scriptorium/design/ART.md` + assets + `scenes/art_preview.tscn`.
2. **Core engineer** (modellen van alle algoritmen stap voor stap, coderen én decoderen, orakel "juiste volgende zet", levels,
   scoring, opslag, uitgebreide tests incl. tests tegen de figuren/oefeningen uit de notas) ∥ **Gameplay/front-end
   engineer** (scènes, input, animaties, UI, juice, rapport).
3. **QA-playtester** speelt via frame-opnames en scripted bots, rapporteert in `design/QA.md`; engineers fixen.
Communiceer via de bestanden in `games/scriptorium/design/` (vooral `STATUS.md`: formaat
`- [x]/[ ] DD/MM HH:MM <rol>: <wat>`; een opvolger moet uit STATUS + git log kunnen verderwerken).
Schrijf niet in andermans bestanden zonder dat je opdracht het zegt.
**Git:** werk op branch `claude/vibrant-turing-mfec2j`. Commit je eigen bestanden regelmatig met een duidelijke
boodschap (prefix `scriptorium <rol>:`), `git pull --rebase` vóór je pusht, push met `git push -u origin
claude/vibrant-turing-mfec2j`. Voeg nooit `lesnotas_AD3_2026.pdf`-afgeleiden (tekstextracten, paginarenders) toe
aan de repo.
