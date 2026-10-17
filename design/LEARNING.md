# AD3 Speelhal — leren door te spelen (didactische afspraken)

**Doel (Henri):** iemand die het algoritme/de datastructuur NIET kent, moet het door de game te spelen echt leren:
na afloop kan hij het algoritme met pen en papier uitvoeren op een nieuw voorbeeld (zoals op het examen) en
uitleggen waarom het werkt. Spelen zonder te begrijpen mag niet "toevallig" lukken.

## Methode per nieuw deel (concept, mechaniek, algoritmestap)
Elke game splitst de leerstof in kleine **delen** (één nieuw idee per deel, bv. "opzoeken in een trie",
"splitsen van een emmer", "KMP-verschuivingstabel", "Huffman: twee lichtste samenbinden"). Voor elk deel doorloopt
de speler **vier fasen** in de spelwereld (geen losse quiz; in de stijl en wereld van de game):

1. **Kijk (voorbeeld, ±30–60 s).** Een personage uit de game (chef, uil, broeder, ...) voert het deel voor op een
   klein voorbeeld (bij voorkeur het voorbeeld/de figuur uit de lesnotas). Stap voor stap, trage animatie, bij elke
   stap één korte zin *wat* er gebeurt en *waarom* (de regel). Speler klikt "Volgende stap" (of laat afspelen).
   Technisch: speel de **bot/het orakel** (`correct_move()`) van de game af met vertraging + verteltekst per stap.
   Altijd overslaanbaar, en later herbekijkbaar via de gids.
2. **Samen (begeleid oefenen).** De speler doet zelf de stappen op een tweede klein voorbeeld. Vóór elke stap
   mag hij een **hint** vragen (licht het juiste element op + zegt de regel). Bij een fout: niet meteen de gevolgen,
   maar een korte uitleg *waarom* dat niet klopt + opnieuw proberen. Begeleiding vermindert: eerst bij elke stap
   een tip, daarna enkel op vraag (fading).
3. **Zelf (gewoon level).** Het bestaande level met de echte gevolgen in de wereld, zonder hulp (hint blijft
   beschikbaar maar kost sterren/punten).
4. **Check (voorspellen/terughalen).** Korte in-world **voorspelvragen** op sleutelmomenten ("Waar komt dit pakje
   terecht?", "Hoeveel schuift het sjabloon op?", "Welke twee bundels bind je nu?") vóór de game het toont — met
   meteen feedback en uitleg. En in de terugblik 1–2 vragen over het deel op een *nieuw* klein voorbeeld.
   Resultaat telt mee voor een "begrepen"-badge per deel (zichtbaar op de levelkaart).

Regels:
- **Volgorde = opbouw:** een level vraagt nooit iets dat nog niet in een Kijk-fase getoond is.
- **Notatie van de notas** in alle uitleg (en paginaverwijzing in de gids), zodat de speler de notas herkent.
- **Kort en concreet:** max. 2 zinnen per stap; liever tonen dan vertellen.
- **Fouten = leerkans:** in Samen/Check uitleg + herkansing; in Zelf de bestaande gevolgen + terugblik.
- **Herbekijken:** in de gids (F1) staat per deel "Bekijk de demo opnieuw" en "Oefen dit opnieuw".
- **Eerste keer verplicht, daarna overslaanbaar** (onthouden in de save). In bot-modus wordt alles overgeslagen.

## Werkwijze per game (team, game per game, niet parallel)
1. **Leerontwerper + bouwer** (één agent): maakt een *leerpad* in `games/<x>/design/LEARNING_PATH.md` (of
   `design/LEARNING_PATH_hashdash.md` voor Hash & Dash): lijst van delen in volgorde, per deel het voorbeeld, de
   verteltekst per stap (Kijk), het oefenvoorbeeld (Samen), de voorspelvragen (Check) met juiste antwoorden
   (nagerekend met de core/bot) en welk bestaand level de Zelf-fase is. Bouwt het daarna in.
2. **Nieuwe speler (tester) + fixer** (andere agent, frisse blik): speelt de game als iemand die het algoritme
   niet kent — leest enkel wat de game toont (frame-opnames + teksten), geen GDD/code/notas vooraf. Na elk deel
   beantwoordt hij zelf een examenachtige vraag op een *nieuw* voorbeeld en controleert zijn antwoord daarna tegen
   de core. Waar hij het niet kon leren uit de game: verbeteren en opnieuw testen. Rapport in
   `games/<x>/design/LEARNING_QA.md`.

## Techniek
- Hergebruik per game de bestaande **bot/orakel** (Kijk: afspelen met verteltekst; Samen: `correct_move()` voor
  hints en foutcontrole), de **event-log/coachzinnen** en `HubGuide` (gedeeld) voor tekstpanelen.
- Geen breaking changes aan de core; alle testsuites groen houden. Commit + push na elk afgerond stuk.
