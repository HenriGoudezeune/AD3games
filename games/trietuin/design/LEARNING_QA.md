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
