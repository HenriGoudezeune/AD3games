# Trietuin — status (elke agent werkt dit bij na elke mijlpaal)

Formaat: `- [x]/[ ] DD/MM HH:MM <rol>: <wat>`. Zet open punten en de volgende stap bovenaan je sectie.
Wordt een agent onderbroken, dan moet een opvolger uit dit bestand en `git log` kunnen verderwerken.
Lees eerst `TEAM.md` (briefing) en `GDD.md` (ontwerp, interface-contract §8, tests §9, scope §10, open vragen §11).

## Lead
- [x] 13/10 lead: open vragen GDD §11 beantwoord — **deze beslissingen zijn bindend** (gaan voor op GDD):
  1. Fig. 19: akkoord. De core gebruikt de Ukkonen-labels (2,3); Fig. 19 met (0,1) wordt aanvaard als geldige boom
     (notas p. 33: "In principe kunnen de indices naar arbitraire posities in de tekst refereren"). "Wist je dat" in 4-2/5-3:
     neutraal formuleren ("de figuur kiest een ander voorkomen van `ac`; Ukkonen kiest altijd de positie direct na s_t,
     daarom werkt b − l_t"), niet zeggen dat de notas fout zijn.
  2. Positiebasis per level met zichtbaar plaatje: akkoord (volgt telkens de figuur/oefening uit de notas).
  3. Ternary: `_` achteraan (zoals de knoppenrij A C G T _), eerst l_j dan s_j planten: akkoord. Toon in de Notas-weergave
     van herfst één regel "volgorde-afspraak van deze game".
  4. Figuren exact laden zoals getekend: akkoord.
  5. Sapmodel: akkoord.
  6. Verwijderen tot lege wortel niet implementeren: akkoord.
  7. Oef. 20: akkoord (array: 5 pointers vs. ternary: 2 × 3 pointers; terugblik legt ook snelheid uit).
  8. Patricia-invoegen met "eender welk blad onder de top": akkoord.
  9. Onechte veralgemeende suffixboom: akkoord.
  10. Oef. 28a: ja, als ontdekking in 4-4 ("Waar komt het **eerst** voor?"). Bewijs (lead): elke b komt van het blad
      dat in fase i bij extensie j werd aangemaakt (regel 2 ⇒ s[j..i] kwam vóór i niet voor ⇒ j is het eerste voorkomen);
      splitsen behoudt b − l_t; elk voorkomen van een langere string op die boog is ook een voorkomen van s[j..i].
      De terugblik mag dit als antwoord op Oef. 28a tonen.
  11. Ukkonen-fouten weigeren (met lokale wereld-uitleg, telt als misstap): akkoord.
  12. Patricia-wortel met skip > 0 in 2-2: akkoord (Algoritme 1 behandelt de wortel als elke top).
  13. Volgorde regel → link: akkoord; de terugblik vermeldt dat de notas het blad pas na de link tekenen.

## Game designer
- [x] 13/10 14:57 designer: `design/GDD.md` v1 (pitch/pijlers, mapping per structuur met speler/automatisch/fouten, bediening + schermen + HUD, campagne 20 levels + vrije tuin exact uitgewerkt, scoring/sap/sterren/terugblik + coachzinnen, juice/audio, interface-contract `Tt*`, testgevallen T01–T36, scope P0/P1/P2, 13 open vragen)
- Alle leveldata zijn nagerekend met een Python-referentiesimulator (staat niet in de repo). Twijfels staan in GDD §11.

## Art & audio director
- [ ] art: `design/ART.md`, `assets/`, `scenes/art_preview.tscn`

## Core engineer
- [ ] core: `scripts/core/` volgens GDD §8 + tests T01–T36 (`tests/run_tests.gd`). Volgorde: §10 "Bouwvolgorde"

## Gameplay / front-end engineer
- [ ] front-end: titel → seizoenkaart → tuin → Bloei → terugblik, P0-levels (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
(nog niets; core noteert hier elke afwijking van GDD §8)
