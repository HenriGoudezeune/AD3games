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
Volgende stap: suffixboom (T22–T26), dan Ukkonen, levels/director/bloom/scoring/save.
- [x] 13/10 core: mijlpaal 3 — `TtTernary` (extends `TtTrie`): rankknopen (PACK) met letterbollen (BALL), zetten
  go/split/same/answer, omzetten met `place` (BST-plaatsing automatisch; orakel = optimale plantvolgorde per
  rankknoop, gelijke kost → letter van het eerst geplante woord uit `word_order`, zo komt Figuur 16 er exact uit),
  `comparisons()`, `optimal_comparisons()`, `bst_warnings()`. Tests T17–T21 groen.
- [x] 13/10 core: mijlpaal 2 — `TtPatricia` (extends `TtTrie`): Algoritme 1 (`zoek`), hoplint-zetten read/short,
  enten met reconstructie (pick_leaf, split → ent volgens GDD §3.2), snoeien (prune/prune_done), wesp steelt.
  Tests T10–T16 groen, incl. 500 willekeurige sets (Patricia-invoegen == snoei(gewone trie)).
- [x] 13/10 core: mijlpaal 1 — `TtCodes`, `TtAlphabet`, `TtNode`, `TtNotation`, `TtCard`, `TtEventLog` (coachzinnen +
  notasverwijzingen), `TtTreeModel` (apply/orakel/snapshot/restore/signalen), `TtTrie` (opzoeken, toevoegen met j,
  verwijderen met knip, foutpaden), `TtReference` (trie/patricia/ternary/suffix naïef). Tests T01–T09 groen
  (`--script res://games/trietuin/tests/run_tests.gd`, filter: `-- trie`).
- [ ] core: `scripts/core/` volgens GDD §8 + tests T01–T36 (`tests/run_tests.gd`). Volgorde: §10 "Bouwvolgorde"

## Gameplay / front-end engineer
- [ ] front-end: titel → seizoenkaart → tuin → Bloei → terugblik, P0-levels (GDD §10)

## QA-playtester
- [ ] QA: `design/QA.md` (frame-opnames, bots met foutmodi, controle leerstof tegen GDD §5/§9)

## API-afwijkingen (core → front-end)
Afwijkingen/aanvullingen t.o.v. GDD §8 (core is bron van waarheid; vragen → zet ze hieronder bij front-end):
- **Na `card_finished`** is `model.card == null` en `model.phase == IDLE`. `phase_changed(phase, cursor)` komt na
  **elke** uitgevoerde zet (niet enkel bij een fasewissel): gebruik het om cursor/markeringen te verversen.
- **Sap op** (`split`/groei met te weinig sap): `ok=false`, `reason "no_sap"`, maar de kaart eindigt (`done=true`,
  `outcome.result == "no_sap"`, `card.state == "expired"`): het zaadje waait weg. De staat van de boom blijft gelijk.
- Extra bump-redenen: `"wrong_phase"` (zet hoort niet bij deze fase), `"unknown_act"`, `"no_card"`, `"bad_target"`
  (letter niet in het alfabet / ongeldig doel).
- `card_finished`-outcome: `{all_ok, verdicts, result, …}`. `result` voor tries: SEED `planted|same|blown|no_sap`;
  BEE `found|missed|not_found|rejected|wrong_honey|stolen|wasp_caught`; PRUNE `cut|not_found`. Extra velden:
  `leaf` (nieuwe vrucht), `found`/`truth` (bestelling), `fallen`/`dead` (knip).
- Logentry heeft extra velden `ok` (false = klonk) en `card` (kaart-id); `data.affects` = woorden waarvan de vrucht
  door dit event verloren/verdwaald is (voor `cause_of_word` en de oorzaakketens). `data.move` = de gespeelde zet.
- `render_nodes()` (trie): extra veld `path` (string die de top voorstelt).
- Extra: `TtAlphabet.abc_lower()` (a b c _ voor `abacabc_`/`aabbabc_`), `TtAlphabet.for_text(t)`,
  `alphabet.with_cost(256)` en `by_name("dna@256")` (ASCII-storm), `alphabet.sorted(keys)`, `display_word(w)`.
- Extra in elk model: `wrong_moves()` (plausibele foute zetten, voor bots/QA) en `impossible_moves()` (klonk-tests),
  `children(id)`, `subtree(id)`, `path_to(id)`, `leaves_under(id)`. TtTrie: `path_string(id)`, `inner_count()`,
  `correct_cut(leaf)`, `first_diff(l, s, d)`.
- `TtCodes.Phase.BED` (extra fase voor 3-4) en `TtCodes.verdict_name()/phase_name()/card_kind_of()`.
- Patricia: `read` met `pos < next` → klonk `"before_d"` (de bij hopt niet terug); een te late j waarvan de knop
  al bezet is → klonk `"occupied"`. `prune_done` eindigt de PATRICIFY-kaart (result `"pruned"`). Cursor heeft extra
  `unary` (PRUNING) en `label` (COMPARE). Fx `graft` komt vóór `hang`. `path_string(id)` = eerste pos(t) tekens van
  een vrucht eronder.
- Ternary: in een **lege wortel-rankknoop** groeit de eerste bol automatisch bij `begin()` (SEED: kaart meteen af
  met `planted`; BEE: `not_found`). Een split emit `grow {nodes}` (nieuwe PACKs + BALLs), dan één `ball`-fx per nieuwe
  bol (`dir` "root"/"lo"/"hi"), dan `rehang`, `hang`. TERNARIFY-kaart: `load_trie(notation)` maakt lege rankknopen en
  losse vruchten; tijdens het omzetten zijn nog niet geplante rankknopen/vruchten niet verbonden (`parent == -1`);
  `cursor()` geeft `placing_node`, `remaining`, `kids` (letter → id van de rankknoop/vrucht die aan die bol komt).
  Zet `model.word_order = spec.bloom_present` (TtLevels doet dit) voor het plantorakel. Outcome van TERNARIFY:
  `{result:"converted", comparisons, optimum}`. `model.source_trie` = de gewone trie (geestboom).
- **Class-naam `TtBot` is van de core** (`games/trietuin/tests/tt_bot.gd`): speelt een level via `TtDirector` +
  orakel, met foutmodi. Front-end: maak geen tweede `TtBot`, gebruik deze (komt bij de director-mijlpaal).
