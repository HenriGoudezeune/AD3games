# Trietuin — teambriefing (lees dit eerst)

## Context
Henri (bachelor informatica, UGent) leert AD3 (prof. Brinkmann) door games te spelen. De repo `AD3games` wordt
een **verzameling games met één gedeeld startscherm (hub)**. De eerste game, **Hash & Dash** (extendible hashing,
§2.1.1), staat al in de repo en werkt (`scenes/`, `scripts/core`, `scripts/game`, `design/`, `tests/`). Kijk ernaar
als referentie voor kwaliteitsniveau, juice, UI-kit, teststijl en werkwijze (`design/GDD.md`, `design/ART.md`,
`design/QA.md`, `design/STATUS.md`, `design/TEAM.md`). **Wijzig de bestanden van Hash & Dash niet** (behalve de
hub-integratie, zie onder, en enkel als je opdracht dat zegt).

Henri's harde eisen (gelden voor álle games):
- Een **echte, volledige, professionele game** — geen quiz in een spelletjesjasje. Topanimaties en -feel (juice),
  goede audio, duidelijke UI, een campagne met progressie, sterren, een rapport/terugblik na elk level.
- **Kernprincipe: de spelregels ZIJN het algoritme.** De speler voert zelf de stappen van de datastructuur uit.
  Fouten worden niet afgestraft met "❌ fout" maar hebben **gevolgen in de spelwereld**. Je leert de regels omdat je
  anders verliest. Na het level legt een terugblik uit wat er misliep, met verwijzing naar de lesnotas.
- **Correct volgens de lesnotas** (die gaan altijd voor op Wikipedia/Gusfield/eigen kennis). Gebruik dezelfde
  definities, notatie en conventies (bv. afsluitteken `_`, kind k_a per letter, `skip` bij Patricia, kleiner/gelijk/
  groter bij ternary, boogpaar (begin, einde) met posities in de tekst bij suffixbomen).
- Taal in de game: **Nederlands**.

## Leerstof: lesnotas AD3 2026, hoofdstuk 3 "Algoritmen voor strings" — de datastructuren
- PDF (met figuren): `lesnotas_AD3_2026.pdf` in de repo-root (155 p.). Tekst (layout behouden, met regelnummers te
  doorzoeken): `/tmp/claude-0/lesnotas_layout.txt`. Figuren bekijken: `pdftoppm -f N -l N -r 110 -png
  lesnotas_AD3_2026.pdf <scratch>/p` en de PNG lezen met de Read-tool (pdf-paginanummer ≠ gedrukt nummer; zoek even).
- Relevante delen (regelnummers in het tekstbestand, gedrukte paginanummers):
  - §3.1 Tries (r. 1234–1412, p. 25–28): Definitie 1, opzoeken/toevoegen/verwijderen, Figuur 13–14, Oef. 17–18
    (geheugen: vertakken volgens A vs. {0,1}; dunne tries; NULL-pointers).
  - §3.1.1 Patricia (r. 1413–1524, p. 28–30): `skip`, Algoritme 1 (zoek_Patricia), het AAAAABAAAAABC_/BBBB…-voorbeeld
    (mismatch pas in het blad gemerkt), toevoegen is lastig (overgeslagen tekens reconstrueren via een blad), Figuur 15.
  - §3.1.2 Ternary (r. 1525–1629, p. 30–32): elke trie-top als klein zoekboompje met kleiner/gelijk/groter,
    Figuur 16–17, Oef. 19–20 (wanneer array vs. ternary).
  - §3.2 Suffixbomen (r. 1630–1725, p. 32–34): alle suffixen van t_ in een Patricia-achtige trie, ≤ 2n−1 toppen,
    labels als (begin, einde)-pointers in de tekst (Figuur 18–19).
  - §3.2.1 Ukkonen (r. 1726–2513, p. 34–48): deelstringboom S(1,i), uitbreidingsregels, actief punt, suffix links,
    "eens blad, altijd blad", Oef. 27.
  - §3.3 Toepassingen (r. 2514–2627, p. 48–50): zoeken in O(m), positie via b − l_t, Oef. 28–29 (alle posities /
    aantal voorkomens = bladeren onder het punt), veralgemeende suffixboom (meerdere teksten, afsluittekens _1, _2, …;
    DNA-databank-voorbeeld: "van wie is dit stukje DNA?"), suffix arrays (Oef. 31).
- **Buiten scope voor deze game:** §3.4 exact string matching (KMP, BMH, Rabin-Karp, shift-AND) en §3.5 benaderend
  matching / editeerafstand. Dat wordt later een aparte game. Verwijderen uit een trie mag (staat in de notas), is
  optioneel.

## Concept (bedacht door de lead; de designer werkt het uit en mag details verbeteren, met motivatie)
**Trietuin** — een organische bouw-en-test-game in een betoverde tuin. *Poly Bridge / Mini Metro-gevoel, maar dan
met een boom die je zelf laat groeien.* De trie is letterlijk een boom.

| in het spel | leerstof |
|---|---|
| de boom groeit uit één kiem (de wortel = lege string) | trie, wortel stelt ∅ voor |
| een **tak** met een letter erop; elke knoop heeft **knoppen** (één per letter van het alfabet) | kind k_a per letter a ∈ A (array van pointers) |
| een **vrucht** aan het eind van een tak, met het woord erop (bv. `ACGT_`) | blad met label s |
| **zaadjes** (woorden) komen binnen en moeten geplant worden | toevoegen |
| **bijen** vliegen met een gevraagd woord van de wortel langs de letters naar een vrucht | opzoeken |
| **sap** = groeibudget; elke knop kost sap, ook een lege (een array-top met |A| pointers) | geheugen, NULL-pointers |
| alfabet groeit per seizoen: DNA {A,C,G,T,_} → letters → "alle ASCII" | Oef. 18/20: wanneer is een array-top verspilling |
| **snoeischaar/enten** — lange takken zonder vertakking samenvoegen tot één tak met een **skip-label** | Patricia, `skip` |
| bij een Patricia-boom **kijkt de bij niet** naar overgeslagen letters; pas bij de vrucht wordt gecontroleerd → een bij met `BBBB…_` komt bij de vrucht `AAAAABAAAAABC_` en wordt weggejaagd | Algoritme 1, mismatch pas in het blad |
| **rankknoop** (klein draaiorgeltje/klimrank) met drie uitgangen: kleiner / gelijk / groter | ternary trie-top (pointerboompje) |
| één lange **slinger/klimplant** (de tekst, bv. `acacacgt_`) en een boom die al zijn suffixen draagt; takken dragen labels (b,e) die naar posities in de slinger wijzen | suffixboom, Θ(n)-opslag via indices |
| een speurneus/inspecteur komt vragen: "komt `cac` voor? hoe vaak? waar?" | §3.3: zoeken in O(m), aantal = bladeren onder het punt, positie b − l_t |
| meerdere slingers (DNA van verdachten) in één boom → "van wie is dit spoor?" | veralgemeende suffixboom, _1, _2, … |
| (finale, als het correct en speelbaar kan) de slinger groeit letter per letter en de boom groeit mee | Ukkonen: S(1,i), actief punt, suffix links, eens blad altijd blad |

Kernlus per level (designer verfijnt): **groeien** (zaadjes planten = de speler voert zelf toevoegen uit: tak per
letter volgen, bij een vrucht de eerste verschilpositie j zoeken, pad maken, twee vruchten hangen) → **bloei/test**
(bijen vliegen opzoekingen; wat fout gebouwd is, faalt zichtbaar: bij verdwaalt, vrucht onvindbaar, sap op) →
**terugblik** (rapport met sterren, wat ging er mis, verwijzing naar notas/oefening). Score: correctheid,
sapverbruik (geheugen) t.o.v. het optimum, snelheid/aantal stappen van de bijen.

Campagne-idee (designer beslist definitief): seizoenen = hoofdstukken. Lente: gewone trie (DNA-alfabet, Figuur 13 →
14, Oef. 17). Zomer: Patricia (snoeien, skip, het BBBB-bedrog, toevoegen met reconstructie, Figuur 15). Herfst:
ternary (grote alfabetten, Figuur 16, Oef. 19/20 als keuze-level: welke boomsoort plant je hier?). Winter: suffixboom
(acacacgt_, Figuur 18/19, vragen van de inspecteur, veralgemeende suffixboom "DNA-spoor"). Finale: Ukkonen (optioneel,
enkel als het 100 % correct volgens de notas kan). Plus een vrije tuin / endless-modus met highscore.
Oefeningen uit de notas (17, 19, 27, 28, 29 …) als herkenbare levels, zoals Hash & Dash dat deed met Oef. 4/5.

## Techniek
- **Godot 4.7.2**, GDScript, 2D, renderer *GL Compatibility*, viewport 1920×1080, stretch `canvas_items`/`expand`
  (zelfde `project.godot` als Hash & Dash; één Godot-project voor alle games).
- Godot-binary in deze cloud-container: `G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64`.
  - importeren: `$G --headless --path . --import`
  - tests: `$G --headless --path . --script res://games/trietuin/tests/run_tests.gd` (script `extends SceneTree`, `quit(code)`)
  - scène draaien + frames opnemen (screenshots/animatie bekijken, werkt via virtuele display):
    `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --write-movie <map>/f.png
    --fixed-fps 30 --quit-after <frames> res://games/trietuin/scenes/X.tscn` → PNG per frame, bekijk met de Read-tool.
    Scripted input/bots voor QA: zie `tools/drag_test.gd` en `tests/bot.gd` van Hash & Dash.
  - Controleer altijd de uitvoer op `SCRIPT ERROR` / `ERROR:` / `Parse Error` — Godot faalt vaak stil.
- Henri speelt op **Windows** (dubbelklik op een `.bat` die de Godot-editor-exe met `--path` start). Alles moet daar
  ook werken: geen Linux-specifieke paden in de game.
- **Mappen voor deze game (alles onder `games/trietuin/`):** `design/` (documenten), `scripts/core/` (pure logica,
  geen nodes), `scripts/game/` (gameplay/UI), `scenes/`, `assets/{art,sfx,music}/`, `tests/`. Gedeelde fonts:
  `res://assets/fonts/` (Fredoka, JetBrains Mono) mag je hergebruiken.
- **`class_name` is globaal in Godot**: Hash & Dash gebruikt al o.a. `Scoring`, `SaveData`, `DaySpec`, `Days`,
  `DayDirector`, `EventLog`, `Parcel`, `Bucket`, `Pal`, `UiKit`, `HashUtil`, `ExtHashModel`. **Prefix al jouw
  class_names met `Tt`** (bv. `TtTrie`, `TtScoring`, `TtSave`). Geen nieuwe autoloads tenzij nodig; als het moet:
  prefix `Tt` en vermeld het in STATUS. Je mag de bestaande autoloads `Sfx`, `Juice`, `Transition` gebruiken
  (lees ze eerst), maar niet wijzigen. Opslag: `user://trietuin_save.json`.
- **Bouw scènes bij voorkeur in code** (nodes aanmaken in `_ready`); houd `.tscn`-bestanden minimaal.
- Geen betaalde/niet-vrije assets: enkel CC0 (bv. Kenney.nl, al deels in `assets/`) of zelf gegenereerd (code,
  shaders, procedureel, Python-scripts zoals `assets/_gen/`). Bronnen + licentie in `games/trietuin/assets/CREDITS.md`.
  Netwerk werkt via een proxy; GitHub-downloads lukken, andere sites mogelijk niet.
- **Hub:** de lead maakt `scenes/hub.tscn` (gedeeld startscherm). Trietuin start via
  `res://games/trietuin/scenes/title.tscn`; Esc/"terug" op het titelscherm gaat naar `res://scenes/hub.tscn`.

## Team en volgorde
1. **Game designer** → `games/trietuin/design/GDD.md` (volledig spelontwerp, levels exact uitgewerkt met woorden en
   verwachte eindbomen, scoring/balans, UI/UX, juice-lijst, interface-contract core ↔ front-end).
   **Art & audio director** (parallel) → `games/trietuin/design/ART.md` + assets + `scenes/art_preview.tscn`.
2. **Core engineer** (modellen trie/Patricia/ternary/suffixboom(+Ukkonen), orakel "juiste volgende zet", levels,
   scoring, opslag, uitgebreide tests incl. tests tegen de figuren/oefeningen uit de notas) ∥ **Gameplay/front-end
   engineer** (scènes, input, animaties, UI, juice, rapport).
3. **QA-playtester** speelt via frame-opnames en scripted bots, rapporteert in `design/QA.md`; engineers fixen.
Communiceer via de bestanden in `games/trietuin/design/` (vooral `STATUS.md`: formaat
`- [x]/[ ] DD/MM HH:MM <rol>: <wat>`; een opvolger moet uit STATUS + git log kunnen verderwerken).
Schrijf niet in andermans bestanden zonder dat je opdracht het zegt.
**Git:** werk op branch `claude/vibrant-turing-mfec2j`. Commit je eigen bestanden regelmatig met een duidelijke
boodschap (prefix `trietuin <rol>:`), `git pull --rebase` vóór je pusht, push met `git push -u origin
claude/vibrant-turing-mfec2j`. Voeg nooit `lesnotas_AD3_2026.pdf`-afgeleiden (tekstextracten, paginarenders) toe
aan de repo.
