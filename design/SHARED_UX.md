# AD3 Speelhal — gedeelde UX-afspraken (navigatie, tutorial, theorie)

Feedback van Henri na het spelen: (1) terug naar het startscherm kost te veel stappen; (2) vaak is niet duidelijk
wat je moet doen en welke handelingen mogelijk zijn; (3) hij wil een korte tutorial en (4) een iets meer theoretische
uitleg over de datastructuur. Dit geldt voor álle games (Hash & Dash, Trietuin, TELEX, Kortschrift).

## 1. Navigatie (gedeeld, één implementatie)
- Autoload **`HubNav`** (`scripts/shared/hub_nav.gd`, CanvasLayer, hoge layer): toont op elke scène behalve de hub een
  klein, altijd zichtbaar **huisje-knopje linksboven** ("⌂ Speelhal") + sneltoets **Ctrl+H**.
  - Buiten een level: meteen terug naar `HubRegistry.HUB_SCENE`.
  - Tijdens een level: klein bevestigingsvenster "Level verlaten? Je voortgang in dit level gaat verloren"
    [Naar speelhal] [Naar levelkeuze] [Verder spelen]. Een scène meldt zich als level via `HubNav.set_context({...})`.
  - Pauzeert het spel (`get_tree().paused`) zolang het venster open is; `process_mode = ALWAYS`.
- Elk pauzemenu krijgt ook de knoppen **"Naar levelkeuze"** en **"Naar speelhal"**.
- **Esc** is overal consistent: sluit eerst een open paneel; in een level opent Esc het pauzemenu; op een menu-scherm
  gaat Esc één niveau terug (level-kaart → titel → speelhal).

## 2. "Hoe speel je dit?" (tutorial + handelingen)
- Gedeeld paneel **`GuideOverlay`** (`scripts/shared/guide_overlay.gd`): een rustig, leesbaar paneel met tabbladen
  **Doel · Handelingen · Theorie**, bladeren met pijltjes, sluiten met Esc/klik. Elke game levert de inhoud als data
  (een Dictionary of JSON) en mag het paneel visueel in eigen stijl kleuren (kleuren/fonts als parameters).
- **Eerste keer** dat een speler een nieuwe mechaniek/werktuig/machine tegenkomt, opent het paneel automatisch met
  een korte tutorial (max. 3–5 kaartjes: wat zie je, wat is het doel, welke handelingen, één mini-voorbeeld). Daarna
  nooit meer automatisch (onthouden in de save van die game), maar altijd opnieuw te openen via een zichtbare
  **"?"-knop** in de HUD + sneltoets **F1**.
- Tab **Handelingen**: altijd een lijst van wat je *nu* kunt doen in dit level, met muis- én toetsenbordbediening
  ("Klik op een knop met de letter → tak groeit", "Sleep een pakje naar een luik", ...). Kort, concreet.
- Tijdens het spelen: als de speler ~8 s niets doet, een discrete hint-rand rond het element waarmee hij iets kan doen
  (geen oplossing verklappen).

## 3. Theorie
- Tab **Theorie** (in hetzelfde paneel, ook bereikbaar vanuit titel/kaart via knop "Theorie"): per datastructuur /
  algoritme één tot drie pagina's met
  - de definitie zoals in de lesnotas (met notatie van de notas),
  - hoe de operaties werken (stappen, korte pseudocode of schema),
  - complexiteit / geheugen en waarom (zoals de notas het zeggen),
  - een klein uitgewerkt voorbeeld (bij voorkeur het voorbeeld/de figuur uit de notas),
  - verwijzing "lesnotas §x.y, p. N".
- Strikt correct volgens de lesnotas (`/tmp/claude-0/lesnotas_layout.txt` en `lesnotas_AD3_2026.pdf`); geen extra
  theorie die niet in de notas staat. Nederlands, kort, helder; liever een schema dan een lap tekst.

## Techniek
- Godot 4.7.2: `G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64`. Autoloads registreren in `project.godot`.
- Gedeelde code in `scripts/shared/` (class_names prefix `Hub`), geen afhankelijkheid van game-specifieke klassen.
- Alle bestaande tests moeten groen blijven (4 suites: `res://tests/run_tests.gd`,
  `res://games/{trietuin,telex,scriptorium}/tests/run_tests.gd`).

## API voor de games (fase 1, gebouwd)

### `HubNav` (autoload, `scripts/shared/hub_nav.gd`)
Huisje "Speelhal" linksboven (CanvasLayer 95, onder `Transition` 100) op elke scène behalve de hub; **Ctrl+H** doet hetzelfde.
De context hoort bij de huidige scène en vervalt vanzelf bij een scènewissel. Zonder context = menu-scherm (meteen naar de hub).
```gdscript
# in _ready() van een level-scène:
HubNav.set_context({
    "in_level": true,                              # vraagt bevestiging: [Naar speelhal] [Naar levelkeuze] [Verder spelen]
    "level_select_scene": "res://games/x/scenes/map.tscn",   # weglaten = geen knop "Naar levelkeuze"
    "on_leave": func(): _stop_sounds(),            # optioneel, vlak voor het verlaten
    "corner_offset": Vector2(0, 80),               # optioneel: huisje verschuiven (t.o.v. (16, 16)) als het over je HUD valt
    "hidden": false,                               # optioneel: huisje verbergen op deze scène
})
HubNav.clear_context()
# knoppen in je pauzemenu:
HubNav.go_level_select()   # "Naar levelkeuze" (zonder vragen; valt terug op de hub)
HubNav.go_hub()            # "Naar speelhal"   (zonder vragen)
HubNav.request_home()      # zoals een klik op het huisje (in een level: bevestigingsvenster)
HubNav.in_level() -> bool; HubNav.button_rect() -> Rect2
```
- Het venster pauzeert de boom (`get_tree().paused`) en zet de vorige toestand terug bij "Verder spelen"/Esc.
  Bij vertrekken: `on_leave`, unpause, `Engine.time_scale = 1`, overgang via `/root/Transition.goto()` als die bestaat.
- Huisje ≈ 142×40 px. Waar het op de huidige scènes van Trietuin/TELEX/Kortschrift over HUD viel, staat een
  standaardpositie in `HubNav.SCENE_OFFSETS` (per scènepad); `corner_offset` in je eigen `set_context` gaat voor.
- `-- --no-hubnav` verbergt het huisje (vergelijkende schermopnames).

### `HubGuide` (`scripts/shared/guide_overlay.gd`)
```gdscript
var g := HubGuide.open(self, {
    "title": "Trietuin · hoe speel je?",
    "tabs": {"doel": [page, ...], "handelingen": [...], "theorie": [...]},  # lege/ontbrekende tabs vallen weg
    "tab": "theorie", "page": 0,                                            # optionele startpositie
}, style)
# tutorial zonder tabbladen (laatste knop = "Aan de slag!"):
HubGuide.open(self, {"title": "Nieuw: de schaar", "pages": [page, page, page], "tutorial": true}, style)
g.closed.connect(func(): ...)          # bv. tutorial als gezien markeren in je save
# page = {"title": String (BBCode), "text": String (BBCode, RichTextLabel),
#         "schema": Texture2D  óf  Callable(ci: Control, size: Vector2) die tekent,
#         "schema_node": Callable() -> Control (wordt ingebed, bv. je eigen figuurweergave),
#         "schema_width": float = 520}
# style (alles optioneel): bg, panel, border, text, text_dim, accent, accent_text, tab (Color);
#   font, font_bold, font_mono (Font); size (Vector2, standaard 1320×780); font_size (24);
#   layer (CanvasLayer, standaard 90); pause (bool, standaard true: pauzeert de boom zolang open)
```
- Opent in een eigen CanvasLayer onder `parent` (schermvullend, los van camera's), `process_mode = ALWAYS`.
- Bediening: ←/→ (PageUp/PageDown) bladeren, Tab volgend tabblad, Esc of F1 of klik naast het paneel sluit.
  Het paneel slikt alle toetsen (behalve Ctrl+…) zodat het spel niets ontvangt; zet in je spel F1 = openen.
- BBCode-tip: een letterlijke `[` schrijf je als `[lb]` (anders wordt `p[i]` cursief). Fredoka mist o.a. `→ ← ≥ ⌊ ★`;
  zet zulke tekens in `[code]…[/code]` (JetBrains Mono heeft ze, behalve ★).

### Zo zit het in Hash & Dash (voorbeeld)
- `scripts/game/hd_guide.gd` (`HDGuide`): inhoud Doel/Handelingen (per dag, uit de `DaySpec`) + Theorie (§2.1.1, p. 5–9,
  figuren 2–5 via `NotasView`) + tutorials per mechaniek; "gezien" in `SaveData` settings `tutorials_seen`.
- Depot: `HubNav.set_context({in_level, level_select_scene, corner_offset})`, "?"-knop in de HUD + F1, tutorial bij de
  eerste keer (`-- --no-tutorial` of `--bot` slaat over); pauzemenu: Uitleg & theorie · Naar levelkeuze · Naar speelhal.
- Titel en dagenkaart: knop "Theorie" (+ F1) opent de gids op het tabblad Theorie.
