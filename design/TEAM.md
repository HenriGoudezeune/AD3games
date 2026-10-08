# Hash & Dash — teambriefing (lees dit eerst)

## Wat we maken
Een **echte game** (geen quiz, geen website) waarmee Henri, bachelorstudent informatica (UGent), **extendible
hashing** (lesnotas AD3, sectie 2.1.1, prof. Brinkmann) leert door het te *spelen*. Henri's harde eis: het moet
echt leuk zijn om te spelen, met **topanimaties en -feel** ("juice"), niet een quiz in een spelletjesjasje.

**Kernprincipe:** de spelregels ZIJN het algoritme. Fouten worden niet met "❌ fout" afgestraft maar hebben
gevolgen in de spelwereld (pakje kwijt, klant boos, verspilde ruimte, dure magazijnritten). Je leert de
regels omdat je anders verliest.

## Concept (goedgekeurd door Henri: "je idee is leuk")
Management-arcade à la *Overcooked* / *Mini Metro*: jij runt een pakjesdepot.

| in het spel | leerstof (notas 2.1.1) |
|---|---|
| pakje met bitlabel, bv. `10110` | record met hashwaarde h(r) |
| sorteermuur met 2^a luiken (`00`,`01`,…) | pointerarray (directory), index = h(r)\|a (eerste a bits) |
| rekken met plaats voor g pakjes, bordje *ab* | emmers met capaciteit g, lokale diepte ab |
| meerdere luiken → hetzelfde rek (gekleurde buizen) | 2^(a−ab) pointers naar één emmer |
| rek uit/naar magazijn halen kost tijd | lees-/schrijfoperaties op schijf (1 lezen + 2 schrijven per splitsing) |

Spelerhandelingen: pakjes van de band naar het juiste luik slepen (zelf de eerste a bits lezen); bij een vol rek
zelf kiezen **"rek bijbouwen"** (splitsen, kan enkel als ab < a, daarna zelf pakjes verdelen op bit ab+1) of
**"muur verbreden"** (pointerarray verdubbelen, als ab = a). Foute keuzes worden niet geblokkeerd maar hebben
gevolgen. Klanten komen pakjes ophalen ("`01101`!") → juiste rek aanklikken; na een foute verdeling ligt het er niet.
Score: tevreden klanten, weinig magazijnritten, weinig verspilde ruimte.

Campagne (één idee per dag): 1 basis (a=0) · 2 eerste verdubbeling · 3 splitsen zonder verdubbeling · 4 klanten
ophalen · 5 "11110-storm" (na splitsen blijft een rek leeg, opnieuw verdubbelen — voorbeeld uit de notas) ·
6 Oefening 5 (sleutels 3,7,12,45,44,1) · 7 "De Klonen" (identieke hashwaarden → algoritme faalt, Oef. 4) ·
∞ endless mode met highscore. Verwijderen zit NIET in de notas → niet in de game.
Open keuzes (designer beslist, met motivatie): realtime vs. rustiger in de eerste dagen; bits markeren in het
begin en geleidelijk afbouwen.

## Techniek
- **Godot 4.7.2**, GDScript, 2D, renderer *GL Compatibility*. Viewport 1920×1080, stretch `canvas_items`/`expand`.
- Godot-binaries: `C:\Users\henri\tools\godot\Godot_v4.7.2-stable_win64_console.exe` (console, voor CLI/tests) en
  `...\Godot_v4.7.2-stable_win64.exe` (editor/GUI).
- Project: `C:\Users\henri\OneDrive - UGent\26-27\AD3\hash-and-dash\` (`project.godot` bestaat al;
  `scenes/smoke.*` is een wegwerp-rooktest).
- Mappen: `design/` (documenten), `scripts/core/` (pure spellogica, geen nodes), `scripts/game/` (gameplay/UI),
  `scenes/`, `assets/{art,sfx,music,fonts}/`, `tests/`, `tools/`.
- **Bouw scènes bij voorkeur in code** (nodes aanmaken in `_ready`) of houd `.tscn`-bestanden minimaal: handgeschreven
  .tscn met veel subresources breekt snel.
- Handige CLI:
  - importeren: `"$G" --headless --path . --import`
  - script/test draaien: `"$G" --headless --path . --script res://tests/run_tests.gd` (script `extends SceneTree`, `quit(code)`)
  - scène draaien + frames opnemen (screenshots/animatie bekijken):
    `"$G" --path . --write-movie <map>\f.png --fixed-fps 30 --quit-after <frames> res://scenes/X.tscn`
    → PNG per frame, bekijk ze met de Read-tool. Gebruik de scratchpad
    `C:\Users\henri\AppData\Local\Temp\claude\C--Users-henri\12b9c9e3-36c6-4fdf-9e96-d42161901667\scratchpad\`.
  - Controleer altijd de console-uitvoer op `SCRIPT ERROR` / `ERROR:` — Godot faalt vaak stil.
- Geen betaalde of niet-vrije assets. Enkel CC0 (bv. Kenney.nl) of zelf gegenereerd (code, shaders, procedureel).
  Houd bronnen + licentie bij in `assets/CREDITS.md`.

## Bron van de leerstof
Lesnotas als tekst: `C:\Users\henri\OneDrive - UGent\26-27\AD3\ad3-quest\_bron\lesnotas.txt`, regels ~150–480
(gedrukte p. 4–10). PDF met figuren: `C:\Users\henri\OneDrive - UGent\26-27\AD3\lesnotas_AD3_2026.pdf`.
Een bestaande, geteste JS-referentie-implementatie (pure functies bovenaan, incl. het 11110-voorbeeld en Oef. 5):
`C:\Users\henri\OneDrive - UGent\26-27\AD3\ad3-quest\levels\2-1-1-extendible-hashing.js`. De notas gaan altijd voor.
Belangrijke details: index = **eerste (meest significante)** a bits; bij splitsen blijven records met bit ab+1 = 0
in de oude emmer, die met 1 gaan naar de nieuwe; na splitsen kan één emmer leeg blijven en moet je opnieuw
verdubbelen; meer dan g identieke hashwaarden → algoritme faalt.

## Team en volgorde
1. **Game designer** → `design/GDD.md` (spelontwerp, balans, levels, UI/UX, juice-lijst, interface-contract).
   **Art & audio director** → `design/ART.md` + assets (parallel).
2. **Core/back-end engineer** (model, levels, scoring, opslag, tests) ∥ **Gameplay/front-end engineer**
   (scènes, input, animaties, UI, effecten).
3. **QA-playtester** speelt via frame-opnames en scripted bots, rapporteert; engineers fixen.
Communiceer via de bestanden in `design/`. Schrijf niet in andermans bestanden zonder dat je opdracht het zegt.
Taal in de game: Nederlands.
