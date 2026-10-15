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
