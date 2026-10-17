# Trietuin — QA leerpad (nieuwe speler + fixer)

Tester: frisse agent die tries/Patricia/ternary/suffixbomen/Ukkonen "niet kent". Gespeeld via frame-opnames
(`--shots=<dir> --shot_every=1.5 --quit_at=N`, scène `garden.tscn` met `--reset_learning --lesson=<deel>
--autoplay --lesson_demo --speed=2`; Check via `season_map.tscn --check=<level> --auto_answer`). Eerst zelf de
voorspelvraag beantwoord op het frame vóór het antwoord, daarna pas de feedback bekeken.

Opmerking over de werkwijze: `games/trietuin/design/LEARNING_PATH.md` bestond niet (de bouwer werd onderbroken);
de CLI-opties heb ik uit `tt_session.gd`/`tt_lesson_coach.gd` (alleen de argument-namen) gehaald. Na deel 1–4 heb
ik de lesdefinities in `tt_lessons.gd` gezien (om de fixes te maken); voor de latere delen kende ik dus de
regelzin vooraf, niet de uitwerking.

Handige opties (ontbraken in een leerpad-document): `reset_learning`, `lesson=<id>`, `phase=kijk|samen`,
`autoplay` (Kijk speelt zelf af), `auto_answer` (voorspel/check juist beantwoorden), `lesson_demo` (Samen: de Uil
speelt, mét bewuste fouten om de foutuitleg te tonen), `lesson_log` (`LESSON_STEP` op stdout), `speed=<x>`,
`check=<level>` (seizoenkaart: Check-vragen van dat level), `leerpad` (kaart: leerpadpaneel), `no_lessons`.

---

## Deel 1–4 · gewone trie (zoeken, toevoegen, verwijderen, geheugen)

**Wat ik begreep (zonder de game te raadplegen):**
- Interne top = array met één pointer per letter van A = {A,C,G,T,_}; de wortel stelt ∅ voor.
- Opzoeken: op diepte d volg je kind k_{s_d}. NULL → niet gevonden. Blad → vergelijk het héle woord met het label.
- Toevoegen: NULL → hang daar een blad met s. Blad l op diepte d (≠ s): j = min{i ≥ d | l_i ≠ s_i}; het blad
  wordt een interne top, pad tot diepte j, daar twee bladeren (k_{l_j}, k_{s_j}). Nieuwe interne toppen: j − d + 1,
  elk |A| pointers.
- Verwijderen: zoek het blad, knip alles weg na de laatste top met ≥ 2 niet-lege kinderen.

**Examenvraag (nieuw voorbeeld):** voeg ACG_, AGT_, CAT_ toe aan een lege trie, geef het geheugen, verwijder dan ACG_.
- Mijn antwoord: ACG_ → blad aan wortel.A. AGT_ → botst op blad ACG_ op d = 1, j = 1 → 1 nieuwe top "A" met
  C→[ACG_], G→[AGT_]. CAT_ → wortel.C is NULL → blad. Notatie `{A{C[ACG_] G[AGT_]} C[CAT_]}`, 2 interne toppen
  = 10 pointers (4 niet-NULL). Verwijder ACG_: laatste top met 2 kinderen is "A" → knip k_C; resultaat
  `{A{G[AGT_]} C[CAT_]}` (AGT_ blijft op diepte 2 hangen).
- Core (`TtTrie.insert_auto/delete_auto`): identiek, ook na het verwijderen. **Klopt.** Lesnotas p. 27: zelfde
  regel ("verwijder alle toppen op dit pad na de laatste top die ten minste twee niet lege kinderen heeft"), niets
  wordt opgeschoven (de canonieke trie van {AGT_, CAT_} zou `{A[AGT_] C[CAT_]}` zijn — een typische examenval).

**Onduidelijk / fouten in de game:**
- In de verteltekst stond `j = min{i ≥ d | l_i ≠ s_i}` met letterlijke underscores, terwijl de rest echte indices
  toont (s₀, l₃). Ook in de regel van de gids, `σ_j`, `l_t`, `s_{j+1}` … verder in het leerpad.
- Of een vrucht na het knippen "omhoog schuift" werd nergens gezegd; de Kijk toont het wel, maar ik twijfelde.
- HUD: lange leerpad-titels ("Toevoegen: het eerste verschil j") liepen onder het label "wind" en de wind-chips door.

**Verbeterd:**
- `TtLessons.subs()`: zet `x_i`, `x_{..}`, `σ_j` om naar kleine indices; toegepast op de Uil-tekst, de Check-vragen
  /uitleg en de regel in de gids.
- Verwijderen: Kijk-uitleg na het knippen + `idea` zeggen nu expliciet dat de andere vruchten blijven hangen
  (enkel als alleen de wortel overblijft, wordt die een blad ∅).
- HUD: de windrij begint pas na de titel (gemeten breedte).
- Check 1-1/1-3 bekeken: vragen op een nieuw voorbeeld met notas-figuur, uitleg correct (j = 4; 2 toppen × 5 = 10).

---

## Deel 5–7 · Patricia (snoeien + skip, zoeken met Algoritme 1, enten)

**Wat ik begreep:**
- Patricia = trie zonder toppen met één kind. Snoei je een top met één kind en is zijn kind een top, dan
  skip(kind) := skip(kind) + skip(top) + 1; is het kind een vrucht, dan schuift die gewoon op. De game toont naast
  de skip-ring ook "pos" = welke letter die top leest (pos = pos(ouder) + skip + 1).
- Zoeken (Algoritme 1): next = next + skip + 1, lees s[next − 1]; is next + skip > m (m = index laatste letter):
  te kort. Overgeslagen letters controleer je pas in de vrucht (hele woord vergelijken).
- Enten: daal af tot je stopt, kies een vrucht onder die plek, j = eerste verschil vanaf positie 0; op diepte j
  komt een nieuwe top (of, als een top al positie j leest, enkel een nieuwe vrucht).

**Examenvraag:** maak de Patricia van {ACGA_, ACGT_, ACGTT_, AT_, CAT_}, zoek ACCT_, voeg dan ACCT_ toe.
- Mijn antwoord: trie `{A{C{G{A[ACGA_] T{T[ACGTT_] _[ACGT_]}}} T[AT_]} C[CAT_]}`; top "AC" heeft
  één kind → weg, top "ACG" krijgt skip 0 + 0 + 1 = 1. Patricia `{0|A{0|C{1|A[ACGA_] T{0|T[ACGTT_] _[ACGT_]}} T[AT_]} C[CAT_]}`.
  Zoek ACCT_: leest s0, s1, s3, s4 → vrucht ACGT_ ≠ ACCT_ → niet gevonden. Enten: j = 2; tussen top "A" (pos 1)
  en de top met pos 3 → nieuwe top skip 2 − 1 − 1 = 0, de top eronder skip 3 − 2 − 1 = 0.
- Core (`TtReference.patricia_of`, `zoek_patricia`): `{0|A{0|C{0|C[ACCT_] G{0|A[ACGA_] T{…}}} T[AT_]} C[CAT_]}`,
  reads [0,1,3,4]. **Klopt.** Lesnotas p. 28–29 (Algoritme 1, skip-regel): idem.

**Onduidelijk:**
- Bij het enten zei de Uil enkel "de skips worden herrekend". Op het examen moet je de nieuwe skips tekenen; welke
  getallen dat worden, moest ik zelf uit de ringen in het frame afleiden (en het geval "een top leest al positie j"
  werd niet benoemd).
- De Check van enten vroeg alleen j, nooit de nieuwe skip.

**Verbeterd:**
- `TtLessons.graft_info()` + verteltekst: "Nieuwe top op diepte j = 2: skip = j − pos(ouder) − 1 = 2 − 0 − 1 = 1;
  de top eronder (pos 3) krijgt skip = 3 − 2 − 1 = 0", of "Top GGC leest al positie j = 3: de vrucht komt aan zijn
  lege knop A, geen nieuwe top (skips blijven)". Getest in de Kijk (frames).
- Extra Check-variant bij enten: "Welke skip krijgt de nieuwe top?" (met uitleg); `t_lessons` bevestigt het antwoord
  naïef (diepste vertakkende trie-top boven diepte j).
- Check 2-1 (Algoritme 1-posities) en 2-3 (j) bekeken: juist en leesbaar.

---

## Deel 8–9 · ternary trie (rankknopen, toevoegen)

**Wat ik begreep:**
- Elke trie-top wordt een klein zoekboompje van letterbollen (enkel gebruikte letters). Per bol: s_d kleiner →
  links, groter → rechts (zelfde top, d blijft), gelijk → midden naar het kind en d + 1. Elke bol = 3 pointers.
- Toevoegen: zoek zoals opzoeken; eindigt het bij een lege rank, dan groeit daar een bol met de vrucht. Botst het
  op een vrucht l: j = eerste verschil; tot diepte j rankknopen met één bol, op diepte j eerst l_j, dan s_j.
- Wie eerst geplant wordt (eerst toegevoegd), staat bovenaan in het zoekboompje.

**Examenvraag:** voeg mol_, mus_, maan_, das_ (in die volgorde) toe aan een lege ternary trie; hoeveel vergelijkingen
kost het opzoeken van maan_?
- Mijn antwoord: bol m (vrucht mol_); mus_ botst op mol_ bij d = 1, j = 1 → rankknoop op diepte 1 met bol o
  (mol_) en rechts daarvan u (mus_); maan_: m gelijk, a < o → links nieuwe bol a (maan_); das_: d < m → links van m
  nieuwe bol d. 5 bollen = 15 pointers. Opzoeken maan_: m, o, a = 3 vergelijkingen.
- Core (`TtReference.ternary_of` / `ternary_comparisons`): `(m (d . [das_] .) (o (a . [maan_] .) [mol_] (u . [mus_] .)) .)`,
  3. **Klopt.** Lesnotas p. 30–31: idem (pointerboom per top, niet geherbalanceerd bij toevoegen).

**Onduidelijk / bugs:**
- Kijk "rankknopen" (trie → ternary omzetten): de Uil plantte eerst G ("nog te planten: C G T") met als reden
  "deze volgorde geeft de minste vergelijkingen", maar zei niet waarom G. Ik kon de keuze niet nadoen.
- Bug (visueel): tijdens het omzetten werden de nog niet verbonden rankknopen/vruchten op de wortel getekend: de
  vrucht TCCA_ lag over de wortelbol en verborg zijn letter.
- Bug (figuur in Check/gids): in de notas-figuur van een ternary trie kon een lo-bol onder een andere bol vallen
  (A over G, CGAGAG_ over CGGA_): de breedte hield geen rekening met het centreren van de eq-kolom. De titel met de
  woordvolgorde liep ook buiten de kader.

**Verbeterd:**
- Verteltekst bij het planten toont nu "Vruchten per letter: C 2 · G 1 · T 2" en de keuzeregel (letter die
  vruchten × vergelijkingen het kleinst maakt, meestal de middelste; bij gelijke stand die van het eerst toegevoegde
  woord). `TtTernary.cursor()` geeft daarvoor `weights` mee (nieuw veld, niets gewijzigd).
- `TtTreeView`: losse (nog niet verbonden) ternary-toppen worden niet getekend; `TtViewLayout`: echte wortel = laagste
  id, bolbreedte symmetrisch rond de eq-kolom (geen overlap meer, ook niet in de tuin).
- `TtNotesView`: titel krimpt of breekt in 2 regels. Opnieuw bekeken: Kijk (omzetten) en Check 3-1/3-2 zijn juist en
  leesbaar.

---

## Deel 10–13 · suffixboom (alle suffixen, (b,e)-labels, zoeken/tellen/positie, veralgemeend)

**Wat ik begreep:**
- Suffixboom van t (afgesloten met _): bevat alle suffixen σ_j, geen toppen met één kind, strings aan de bogen.
  σ_j toevoegen: volg het vanaf de wortel tot waar het afwijkt; op een top → nieuwe tak, midden in een boog → boog
  splitsen in een nieuwe top met twee kinderen.
- (b,e)-labels: nieuwe bladboog vanuit diepte l voor σ_j: b = j + l, e = n (laatste index).
- Zoeken: volg z (O(m)); aantal = vruchten onder het eindpunt; positie = b − l_t (boog met het laatste teken van z,
  l_t = diepte van de top erboven); alle posities = de nummers van de vruchten eronder.
- Veralgemeend: teksten achter elkaar met eigen afsluittekens; de eigenaars van de vruchten onder z.

**Examenvraag:** teken de suffixboom van abab_ met (b,e)-labels (posities vanaf 0); waar staat ab?
- Mijn antwoord: σ0 → (0,4). σ1 → (1,4). σ2 = ab_ wijkt af na ab (l = 2) midden in (0,4): split in (0,1) + (2,4),
  nieuw blad (4,4). σ3 = b_ wijkt af na b in (1,4): (1,1) + (2,4), nieuw blad (4,4). σ4 = _ → (4,4) uit de wortel.
  `{(0,1){(2,4)#0 (4,4)#2} (1,1){(2,4)#1 (4,4)#3} (4,4)#4}`. ab: eindigt op de top "ab" → vruchten #0, #2 →
  posities 0 en 2 (aantal 2).
- Core (`TtReference.suffix_naive`, `occurrences`): identiek, [0, 2]. **Klopt.** Lesnotas p. 32–34, 48–49: idem.

**Onduidelijk:**
- Bij het splitsen van een boog zei de game enkel "die wordt gesplitst"; wat er met het (b,e)-label van die boog
  gebeurt (bovenste deel (b, b+k−1), onderste (b+k, e)) moest ik zelf bedenken — precies wat je op het examen tekent.
- De Kijk "alle suffixen" stopte na σ5 van acacacgt_: de getoonde boom had 6 bladeren, geen volledige suffixboom.
- Veralgemeend: de Kijk vertrekt van een kant-en-klare boom; hoe je hem bouwt stond niet in de les.

**Verbeterd:**
- Split-uitleg toont nu het label: "Boog (0,3) wordt (0,1) naar de nieuwe top en (2,3) eronder" (of met strings:
  "Boog acacacgt_ wordt acac + acgt_"). Getest in de Kijk van deel 11.
- Kijk deel 10 hecht nu alle 9 suffixen aan (volledige boom van Figuur 18).
- Idee van deel 13: bouwen = gewone suffixboom van t₁1t₂2; suffixen met een afsluitteken in het midden zitten vanaf
  dat teken in één bladboog (Oef. 30).
- Check 4-1/4-2/4-3/4-5 bekeken: juist (σ4 = tc_ → "t"; (3,6); ca 1×; gt → Merel) en leesbaar.
