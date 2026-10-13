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
Volgende stap: wensen van front-end/QA verwerken (zet ze hier). De API van TtPal/TtDraw/TtUi/TtFx blijft
achterwaarts compatibel: nieuwe parameters komen altijd achteraan, met een default.
- [x] 13/10 15:50 art: `design/ART.md` (stijl "betoverde boomgaard", palet + seizoenstabel, typografie, vormtaal,
  specificatie van elk element met de bijbehorende `TtDraw`-functie, juice-timings, partikels, leesbaarheid en
  audio direction), `assets/MANIFEST.md` (event → bestand, per GDD-#) en `assets/CREDITS.md`.
- [x] 13/10 15:50 art: code `scripts/game/tt_pal.gd` (**TtPal**: palet, `SEASONS`, letterchips, `SUSPECTS`, fonts,
  `word()`/`rich_line()`), `tt_draw.gd` (**TtDraw**: wortel, tak + `branch_curve(arch)`, knoppenkrans, letterchip,
  vrucht + label (rot/doel/gevonden/eigenaar), spooktak/-vrucht, zaadzakje, sapbuis (ghost/opt/loss), Patricia
  (jaarring `skip_ring`, entwikkel, spookknoppen, schaar), ternary (`rank_knot`, `tendril`), slinger + (b,e)-bordjes +
  letterparels + telbadges, bij/wesp (`wasp` 0..1), korf + koningin, Uil, Egel, hond, vuurvliegje, linten
  (`ribbon`, `compare_ribbon` met hops/cursor/j), windrij-kaartjes, potten, sterbloemen, stempel, compost, pillen),
  `tt_ui.gd` (**TtUi**: thema, knoppen PRIMARY/SECONDARY/SAP/GHOST/DANGER, icoonknop, panelen) en `tt_fx.gd`
  (**TtFx**: sfeerdeeltjes per seizoen, bursts groei/rijpen/snoei/sap/gevonden/poof/seizoensgolf).
- [x] 13/10 15:50 art: assets (± 13 MB, alles procedureel en CC0, generators in `assets/_gen/`): 4 achtergronden +
  grasranden + wolken, 11 partikeltexturen, mist-shader, 49 SFX (alle events uit GDD §7.2), 4 sfeerlussen,
  muziek met basis + bloeilaag per seizoen (synchroon, naadloos), titel, finale en 3 rapport-jingles. De loop-vlaggen
  staan in de `.import`-bestanden.
- [x] 13/10 15:50 art: `scenes/art_preview.tscn` (3 pagina's × 4 seizoenen; `-- season=0..3 page=0..2`, toetsen
  1–4/Tab), screenshots in `design/screens/` (+ `.gdignore`). Gecontroleerd met xvfb-frames: geen SCRIPT ERROR.
  Enkel de engine-melding "resources still in use at exit" (spelende OGG-streams bij `--quit-after`; Hash & Dash
  geeft dezelfde melding).
- Let op (front-end): `TtPal.MONO*` zijn MSDF-fonts (scherp bij camerazoom). Fredoka kan geen MSDF (artefacten),
  dus zet Fredoka-tekst in de UI-laag. Takken naar vruchten met `branch_curve(..., arch = true)`, zodat het label vrij
  onder de vrucht hangt. Muziek en geluid via `TtSnd` (jouw bestand), met de namen uit MANIFEST.

## Core engineer
Volgende stap: wensen/vragen van front-end en QA verwerken (zet ze in deze sectie of onder API-afwijkingen).
- [x] 13/10 core: mijlpaal 6 — property-tests (`t_properties.gd`): 1200 woordsets trie == referentie, Patricia-zoek ==
  Algoritme 1-referentie, 1000 sets ternary-zoeken == trie-zoeken (+ omzetten met orakel = optimum), verwijderen,
  willekeurig spel (p = 0.4, 3 seeds × 20 levels) breekt nooit invariants en elk level eindigt, scoring monotoon
  (perfect ≥ 28 foutmodi × 20 levels in sterren én honing), layout op willekeurige bomen; `t_meta.gd` (core puur,
  prefix Tt). Totaal **1229 asserts groen** (~30 s): `$G --headless --path . --script res://games/trietuin/tests/run_tests.gd`
  (filter: `-- t_trie` of `-- t_trie,t_levels`).
- Robuustheid na fouten: Patricia-split waarvan de ent-knop bezet is (vrucht uit een verkeerde tak na een foute
  leespositie) → orakel = "Zit er al" (zaadje waait weg, de fout staat al bij READ); suffixkaart waarvan σ_j na een
  verkeerde b al volledig als pad bestaat → kaart meteen af met result `"present"` (Bloei faalt voor dat suffix).
- Aanvullingen/afwijkingen t.o.v. de GDD (notas gaan voor): (1) "te ondiep op hetzelfde pad" aanhechten (§3.4 fouten)
  kan niet: het volgende teken is dan gelijk → Definitie 3 → klonk `duplicate_first`; enkel een punt op een ander pad
  of dieper is een WRONG_POINT. (2) Patricia-ent met een te late j maakt de boom fout maar niet altijd een woord
  onvindbaar (Algoritme 1 slaat letters over); test controleert "geen correcte Patricia meer". (3) 3-3: de GDD legde de
  eindboom niet vast; `expect_end` = de boom van het optimale orakel (49 vergelijkingen, gelijke kost → eerste woord).
  (4) 4-4: eerste vraag is "Waar komt `cat` het **eerst** voor?" (q `first`, beslissing lead 10), 4-4 is CALM met
  geduld 25 s/vraag. (5) Bijen in de vrije tuin en 1-4 hebben `card.expect`; een bij voor een gestolen/ontbrekend
  woord dat er had moeten zijn (2-2) telt als mislukt, ook al vloog ze correct.
- [x] 13/10 core: mijlpaal 5 — `TtLevelSpec`/`TtLevels` (alle 20 levels + vrije tuin, exacte data uit §5; P0/P1/P2),
  `TtDirector` (CALM/SWARM, windrij, geduld, 4e zaadje waait weg, hint, terugspoelen, Bloei, rapport, vrije tuin met
  generator/sapaangroei/3 missers), `TtBloom`, `TtScoring` (honing §6.3, combo, sterren, rapport), `TtSave`,
  `TtLayout`, `TtWordGen`, `TtBeds` (3-4). Bot: `games/trietuin/tests/tt_bot.gd` (**class `TtLevelBot`**).
  Tests T32–T36 groen: elke level met de perfecte bot = 3 sterren, sap == optimum, eindboom == expect_end, Bloei
  100 %, snapshot-roundtrip na elke zet; in elke fase worden alle foute zetten met verdict ≠ OK aanvaard en alle
  onmogelijke zetten geweigerd zonder staatswijziging.
- [x] 13/10 core: mijlpaal 4 — `TtSuffixTree` (aanhechten met afwijkpunt + b kiezen, labels (b,e) volgens §3.4.3,
  inspecteur: locate/absent/where/count/pick/owner, veralgemeend met eigenaars, naïeve opbouw) en `TtUkkonen`
  (stapsgewijs: hop/rule/link/follow, open bladbogen "it", trace, active, sigmas, run_all). Tests T22–T31 groen:
  Figuur 18/19, Figuur 19 zoals getekend (pos −1), mist, veralgemeend, abacabc_ (alle (p̄,x̄)-pijlen en links),
  Oef. 27, acacacgt_-cascade, alle 254 {a,c}-teksten Ukkonen == naïef, Oef. 28a (b − l_t == eerste voorkomen).
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
- [x] 13/10 core: `scripts/core/` volgens GDD §8 + tests T01–T36 (`tests/run_tests.gd`) — klaar.

## Gameplay / front-end engineer
Volgende stap: Patricia/ternary/suffix/Ukkonen-levels doorspelen met de bot (frames bekijken), daarna polish + P1.
QA-opties (na `--`): `level=1-2` (start meteen dat level), `bot=perfect|errors|random`, `speed=2`, `intro=0`,
`unlock=1` (kaart: alles open), `shots=<map> shot_every=2 quit_at=60` (snelle PNG-schermafdrukken zonder
--write-movie), `notes=1` (rapport opent notas-weergave), `sheet=1`, `fps=1`. Bv.:
`xvfb-run -a $G --path . --rendering-driver opengl3 res://games/trietuin/scenes/garden.tscn -- level=1-3 bot=errors`.
- [x] 13/10 16:45 front-end: mijlpaal 1 — scènes `title.tscn` (boompje groeit, vruchten spellen TRIETUIN, bijen,
  Spelen/Vrije tuin/Instellingen/← Alle games, Esc → hub), `season_map.tscn` (jaarwiel, potten met sterren, hover =
  notasverwijzing, ontgrendeling via `TtLevels.is_unlocked`, korf = vrije tuin), `garden.tscn` (één scène voor alle
  levels). Tuin: `TtTreeView` (boom uit `render_nodes()` + eigen `TtViewLayout` met de getekende maten; groei-,
  plop-, val- en verwelkanimaties; klikzones), fx-afspeler voor alle `changed(fx)`-types, HUD (windrij, sapbuis,
  honing, combo), werkbank (lint met leeshulp, vergelijkingslint, hoplint, vraagkaart, contextknoppen), Uil (hint F1),
  spookhand, inspecteur Egel + hond, slinger/σ-rij, intro-kaart, pauze, instellingen, notas-spiekbriefje,
  ASCII-storm, Bloei (bloesemgolf + zwerm), terugblik (sterren, honing, sap, Bloeirij, tijdlijn met herbeleving in een
  tweede model, coachzin, notas-weergave), opslag via `TtSave`. Lente 1-1/1-2 met bot perfect en errors doorgespeeld.
- Wensen voor core: geen blokkerende. (De front-end gebruikt eigen `TtViewLayout` i.p.v. `TtLayout` omdat die de
  getekende knoestbreedtes/labelbreedtes kent; `TtLayout` blijft de referentie voor tests.)

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
- Suffixboom: `setup(alpha, text, pos_base, labels, owners)` met `owners` = **per positie** de tekstindex (1..k);
  `model.owner_names` = namen voor de coachzin. Posities in zetten (`where.pos`, `label.b`) zijn **intern 0-gebaseerd**;
  toon ze met `display_pos(p)` (= p + pos_base). Getallen in `data` van WHERE/LABEL-logentries staan al in de
  weergavebasis (voor de coachzinnen). `pick.leaves` = **ids** van vruchten; `owner.texts` = tekstindexen.
  LABEL-fase enkel als `labels == "pointers"` (4-2); bij "strings" (4-1) is de kaart af na `attach`.
  `locate_auto(z)` geeft ook `starts` (beginposities, gesorteerd) en `owners`; `leaves` = ids.
  Extra klonk-redenen: `label` met een b waarvan het eerste teken al een broer-boog heeft → `"duplicate_first"`;
  een punt op een vrucht (off 0) → `"bad_target"`; off > booglengte → `"past_end"`.
  Ukkonen: weigeringen hebben `reason` `"short_edge"|"wrong_edge"|"not_canonical"` (hop, WRONG_HOP),
  `"already_there"|"missing"` (rule, WRONG_RULE), `"bad_target"` (link → WRONG_LINK, follow → WRONG_FOLLOW).
  `TtUkkonen.setup_text(alpha, text, pos_base, owners)`; begin een `ukkonen`-kaart; `active()` geeft ook
  `link_target` (in U_LINK), `edge` (kind-id van de boog onder het vuurvliegje), `finished`. Na de laatste iteratie
  worden alle open bladeinden gesloten (fx `label` met e = n) en is de kaart af (`result "built"`).
  `render_nodes()` (suffix): extra `edge` (booglabel als string), `string` (padstring), `e_now` (huidige eindpositie,
  ook voor "it"), `path_ok` (vrucht klopt met haar suffix), `depth` = stringdiepte.
- **Bot**: de front-end heeft al `TtBot` (`scripts/game/tt_bot.gd`); de core-bot heet daarom **`TtLevelBot`**
  (`games/trietuin/tests/tt_bot.gd`): `TtLevelBot.new(mode, seed).play(spec)` → rapport, of `run(director)` /
  `step(director, dt)` voor één actie per frame. Modi: `""` perfect, `first`, `every`, `random` (p), `act:<act>`,
  `bump`, `hint`, `rewind`, `idle`, `pluck_wasp`. Elk model heeft `wrong_moves()`/`impossible_moves()` voor bots.
- **Director** (`TtDirector`): `start(spec, seed)`, `tick(dt)` elke frame (ook in CALM: tijd + geduld),
  `next_card()` (CALM: volgende kaart; SWARM: oudste wachtende), `take(id)` (SWARM), `model.apply(move)` voor zetten,
  `all_done()` → `run_bloom()` → `finish()` (rapport). `hint()`, `rewind()` (CALM; misstappen in teruggespoelde
  kaarten vervallen: logentries krijgen `rewound: true`), `mistakes()`, `letter_hint()` (leeshulp voor de actieve
  kaart), `dispose()` (verbreek signalen bij het verlaten van de scène). Extra signalen: `card_arrived`,
  `card_done(card, outcome)`, `timeline_event(ev)` (1-2 stempel "Figuur 14 ✓", 3-1 `ascii_storm`, 4-4 `badges`),
  `budget_changed` (vrije tuin). `peak_sap`, `misses`, `cards`, `waiting()`, `queue()`.
  Opslaan doet de front-end: `TtSave.set_stars(id, report.n_stars)`, `TtSave.set_best(id, report.honey)`,
  `TtSave.add_highscore(score, naam, datum)` (vrije tuin). Ontgrendeling: `TtSave.is_unlocked(id, beschikbare_ids)`
  of `TtLevels.is_unlocked(id, sterren, beschikbaar)`; `TtLevels.next_id(id)`.
- **Rapport** (`finish()` / `level_finished`): naast §8.9 ook `n_stars`, `sap_peak`, `bloom_ratio`, `end`,
  `expect_end`, `asks_ok`, `asks`, `missed`, `max_combo`, `level`, `title`, `notes_ref`, `extra` (levelweetjes:
  `report`, `did_you_know`, `figure`, `rule`, `oef28a`, …). `mistakes` = logentries (met `before`, `hint`; coachzin
  via `model.log.coach_line(e)` en `notes_ref(e)`); herbeleving: `TtLevels.make_model(spec).restore(e.before)`.
- **LevelSpec**: extra velden `start_format` (`"trie"` = gewone trie laden voor snoeien/omzetten, `"built"` = 4-5
  suffixboom opbouwen, `"beds"` = 3-4), `hint_full_cards` (3-2), `endless`, `extra`. Kaart `{"kind":"ask","z":…,
  "q":…}`; q kan ook **`"first"`** zijn (4-4, beslissing lead 10: "Waar komt het **eerst** voor?"; antwoord via
  `where`). 4-4 is CALM met `patience` 25 s per vraag (geduld loopt vanaf de start van de kaart), niet SWARM.
  `TtCard.expect` (BEE: 1 = hoort in de boom) wordt door de director gezet; `TtScoring.bee_success(card)`.
- **3-4 (Oef. 20)**: model `TtBeds` (kind TRIE, fase `BED`): zet `{"act":"bed","bed":i,"choice":"array"|"ternary"}`
  (opnieuw kiezen = herplanten), `bed_model(i)` = het geplante model om te tekenen, `beds[i]` met `array_sap`,
  `ternary_sap`, `best`, `planted`, `blown`.
- **Layout**: `TtLayout.compute(render_nodes, kind, rect, root_bottom, letters)` (5e parameter optioneel:
  `model.alphabet.letters`); resultaat bevat ook `"_meta"` ({cols, levels, dx, dy}). Ternary: een PACK krijgt de plaats
  van zijn wortelbol. Losse deelbomen (tijdens omzetten) komen naast de hoofdboom.
