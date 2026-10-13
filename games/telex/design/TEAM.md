# Telex — teambriefing (lees dit eerst)

## Context
Henri (bachelor informatica, UGent) leert AD3 (prof. Brinkmann) door games te spelen. De repo `AD3games` is een
**verzameling games met één gedeeld startscherm (hub, `scenes/hub.tscn`, registry `scripts/hub/hub_registry.gd`)**.
Bestaande games (kwaliteitsreferentie, NIET wijzigen): **Hash & Dash** (extendible hashing; `scenes/`, `scripts/core`,
`scripts/game`, `design/`, `tests/`) en **Trietuin** (tries/suffixbomen; `games/trietuin/`, wordt parallel gebouwd).
Lees hun design-documenten (GDD, ART, QA, STATUS) om te zien hoe een goed ontwerp en een goede werkwijze eruitzien.

Henri's harde eisen (gelden voor álle games):
- Een **echte, volledige, professionele game** — geen quiz in een spelletjesjasje. Topanimaties en -feel (juice),
  goede audio, duidelijke UI, een campagne met progressie, sterren, een rapport/terugblik na elk level.
- **Kernprincipe: de spelregels ZIJN het algoritme.** De speler voert zelf de stappen uit. Fouten worden niet
  afgestraft met "❌ fout" maar hebben **gevolgen in de spelwereld**. Na het level legt een terugblik uit wat er
  misliep, met verwijzing naar de lesnotas.
- **Correct volgens de lesnotas** (die gaan altijd voor): dezelfde definities, notatie en conventies (z[] = zoekstring
  met lengte m, t[] = tekst met lengte n, posities vanaf 0, verschuivingstabel V[], matrices M[i][j], C_x-bitvectoren,
  editeerafstand d[i][j] ...).
- Taal in de game: **Nederlands**. Elke game moet **anders aanvoelen** dan de vorige (ander genre, andere wereld,
  andere kernhandeling) — niet weer "sorteer dingen in bakjes".

## Leerstof: lesnotas AD3 2026, §3.4 Exact string matching en §3.5 Benaderend string matching
- PDF: `lesnotas_AD3_2026.pdf` in de repo-root. Tekst (layout behouden): `/tmp/claude-0/lesnotas_layout.txt`.
  Figuren: `pdftoppm -f N -l N -r 110 -png lesnotas_AD3_2026.pdf <scratch>/p` en de PNG lezen met de Read-tool.
- §3.4 (r. 2628–3655, gedrukt p. 50–69): brute kracht (Algoritme 2, Oef. 32 Θ(n²)-voorbeeld, wildcards Oef. 33),
  Rabin-Karp (Algoritme 3, hashwaarde mod q, rollend berekenen, valse treffers, Oef. 34 z=00101 q=13),
  Knuth-Morris-Pratt (Definitie 11 verschuivingstabel V[], Algoritme 4, Algoritme 5 V[] berekenen, Stelling 12 O(n),
  Oef. 39/40), Boyer-Moore-Horspool (van rechts naar links vergelijken, verschuiving volgens laatste teken, Oef. 48,
  beste/slechtste geval Oef. 50), shift-AND (Definitie 13 matrix M, C_x-bitvectoren, Algoritme 6, Oef. 54 z=zoeken).
- §3.5 (r. 3656–~4185, p. 70–81): shift-AND met k mismatches (Definitie 14, M^k, Oef. 60 z=dank t=een_dansfeest k=1),
  editeerafstand (Definitie 15, Levenshtein, Algoritme 7 DP, Oef. 62), kleinste editeerafstand van een deelstring
  (Algoritme 8, Oef. 70 z=zoeken, Oef. 71 z=test).
- Buiten scope: hoofdstuk 4 (compressie) en verder.

## Concept-richting van de lead (de designer werkt het uit, mag verbeteren of een beter idee voorstellen, met motivatie)
Werktitel **Telex**: een spannende **inlichtingendienst / telegraafkantoor** (jaren '50-'60, retro-futuristisch,
papieren telexlinten, lampjes, schakelaars, buizen, codeboeken). Een **lint met tekst t stroomt binnen**; jij moet
de codewoorden z erin vinden voor het lint voorbij is. Elk algoritme is een **machine/werktuig dat je vrijspeelt en
zelf bedient**, met zijn eigen fysieke handeling die de stappen van het algoritme afdwingt:
- brute kracht: een loep/stencil die je per positie verschuift en teken per teken vergelijkt (traag, vermoeiend: de
  "vergelijkingsteller" toont waarom Θ((n−m+1)·m));
- Rabin-Karp: een vingerafdruk-rekenmachine die de hash mod q rollend bijwerkt; valse alarmen (hashbotsing) kosten tijd;
- KMP: eerst zelf de verschuivingstabel V[] "ponsen" (Algoritme 5), daarna leest de machine het lint **zonder ooit
  terug te spoelen** (ideaal voor streams), de speler kiest bij mismatch de verschuiving;
- Boyer-Moore-Horspool: vergelijkt van rechts naar links, grote sprongen via de tabel op het laatste teken;
- shift-AND: een **lampenbord** met m lampjes (de kolom M[][j]) dat per binnenkomend teken shift + AND met C_x doet —
  de speler zet schakelaars/ponskaarten C_x en ziet het licht doorschuiven; laatste lamp aan = treffer;
- §3.5: **ruis op de lijn**: berichten met storingen. M^k-lampenborden (meerdere rijen voor 0..k fouten); de
  editeerafstand als een **DP-schakelbord** (d[i][j] invullen, het goedkoopste pad = de reeks bewerkingen terugvinden
  om een verminkt bericht te herstellen); Algoritme 8 om een verminkt codewoord ergens in een lang lint te vinden.
Campagne als "dossiers"/missies met een verhaal, kosten = tijd/vergelijkingen/energie, sterren voor efficiëntie
(o.a. minder vergelijkingen dan brute kracht, geen gemiste treffers, geen vals alarm), oefeningen uit de notas als
herkenbare missies, en een eindeloze modus.

## Techniek
- **Godot 4.7.2**, GDScript, 2D, renderer *GL Compatibility*, viewport 1920×1080, stretch `canvas_items`/`expand`
  (zelfde `project.godot` als Hash & Dash; één Godot-project voor alle games).
- Godot-binary in deze cloud-container: `G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64`.
  - importeren: `$G --headless --path . --import`
  - tests: `$G --headless --path . --script res://games/telex/tests/run_tests.gd` (script `extends SceneTree`, `quit(code)`)
  - scène draaien + frames opnemen (screenshots/animatie bekijken, werkt via virtuele display):
    `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --write-movie <map>/f.png
    --fixed-fps 30 --quit-after <frames> res://games/telex/scenes/X.tscn` → PNG per frame, bekijk met de Read-tool.
    Scripted input/bots voor QA: zie `tools/drag_test.gd` en `tests/bot.gd` van Hash & Dash.
  - Controleer altijd de uitvoer op `SCRIPT ERROR` / `ERROR:` / `Parse Error` — Godot faalt vaak stil.
- Henri speelt op **Windows** (dubbelklik op een `.bat` die de Godot-editor-exe met `--path` start). Alles moet daar
  ook werken: geen Linux-specifieke paden in de game.
- **Mappen voor deze game (alles onder `games/telex/`):** `design/` (documenten), `scripts/core/` (pure logica,
  geen nodes), `scripts/game/` (gameplay/UI), `scenes/`, `assets/{art,sfx,music}/`, `tests/`. Gedeelde fonts:
  `res://assets/fonts/` (Fredoka, JetBrains Mono) mag je hergebruiken.
- **`class_name` is globaal in Godot**: Hash & Dash gebruikt al o.a. `Scoring`, `SaveData`, `DaySpec`, `Days`,
  `DayDirector`, `EventLog`, `Parcel`, `Bucket`, `Pal`, `UiKit`, `HashUtil`, `ExtHashModel`. **Prefix al jouw
  class_names met `Tx`** (bv. `TxKmp`, `TxScoring`, `TxSave`). Geen nieuwe autoloads tenzij nodig; als het moet:
  prefix `Tx` en vermeld het in STATUS. Je mag de bestaande autoloads `Sfx`, `Juice`, `Transition` gebruiken
  (lees ze eerst), maar niet wijzigen. Opslag: `user://telex_save.json`.
- **Bouw scènes bij voorkeur in code** (nodes aanmaken in `_ready`); houd `.tscn`-bestanden minimaal.
- Geen betaalde/niet-vrije assets: enkel CC0 (bv. Kenney.nl, al deels in `assets/`) of zelf gegenereerd (code,
  shaders, procedureel, Python-scripts zoals `assets/_gen/`). Bronnen + licentie in `games/telex/assets/CREDITS.md`.
  Netwerk werkt via een proxy; GitHub-downloads lukken, andere sites mogelijk niet.
- **Hub:** `scenes/hub.tscn` bestaat al; de lead voegt de kaart toe in `HubRegistry`. Telex start via
  `res://games/telex/scenes/title.tscn`; Esc/"terug" op het titelscherm gaat naar `res://scenes/hub.tscn`.

## Team en volgorde
1. **Game designer** → `games/telex/design/GDD.md` (volledig spelontwerp, levels exact uitgewerkt met teksten en zoekwoorden,
   verwachte uitkomsten (treffers, tabellen, matrices), scoring/balans, UI/UX, juice-lijst, interface-contract core ↔ front-end).
   **Art & audio director** (parallel) → `games/telex/design/ART.md` + assets + `scenes/art_preview.tscn`.
2. **Core engineer** (modellen van alle algoritmen stap voor stap, orakel "juiste volgende zet", levels,
   scoring, opslag, uitgebreide tests incl. tests tegen de figuren/oefeningen uit de notas) ∥ **Gameplay/front-end
   engineer** (scènes, input, animaties, UI, juice, rapport).
3. **QA-playtester** speelt via frame-opnames en scripted bots, rapporteert in `design/QA.md`; engineers fixen.
Communiceer via de bestanden in `games/telex/design/` (vooral `STATUS.md`: formaat
`- [x]/[ ] DD/MM HH:MM <rol>: <wat>`; een opvolger moet uit STATUS + git log kunnen verderwerken).
Schrijf niet in andermans bestanden zonder dat je opdracht het zegt.
**Git:** werk op branch `claude/vibrant-turing-mfec2j`. Commit je eigen bestanden regelmatig met een duidelijke
boodschap (prefix `telex <rol>:`), `git pull --rebase` vóór je pusht, push met `git push -u origin
claude/vibrant-turing-mfec2j`. Voeg nooit `lesnotas_AD3_2026.pdf`-afgeleiden (tekstextracten, paginarenders) toe
aan de repo.
