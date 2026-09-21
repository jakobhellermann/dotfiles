---
name: jj-restore-descendants
description: "Löst eine Teil-Änderung aus einem bestehenden, bereits beschriebenen Commit in einen eigenen Commit darüber auf (User nennt das sq-restore-descendants): im Working Copy die Teil-Änderung entfernen, dann jj restore --from @ --into <target> --restore-descendants — ein vorab als leeres Kind erstellter Commit absorbiert die Delta als seinen Diff. Use when the user wants to split a change out of an existing commit into its own commit, e.g. nach einem Review (splitte X aus dem Commit raus, doppel das in einen eigenen Commit, mach Mobile-Support zum eigenen Commit)."
argument-hint: "<target-commit> <was raus soll>"
---

# jj restore --restore-descendants: Teil-Änderung in eigenen Commit extrahieren

Situation: Commit **A** (beschrieben, evtl. nach Review bearbeitet) enthält eine
Teil-Änderung **X**, die als eigener Commit **B** auf A gehören soll. Statt X im
Diff herauszupicken: X aus A *entfernen* und einen vorab geparkten leeren Commit
die Differenz aufsaugen lassen. Kein diffedit, kein manuelles Re-Anwenden.

## Rezept (A ist Stack-Tip, @ ist leeres Working-Copy-Kind von A)

```
1. jj new <A> --no-edit -m "<message für X>"   # leeres Kind B von A, @ bleibt @
2. im Working Copy X entfernen (edit + build + test)
3. jj restore --from @ --into <A> --restore-descendants
```

Warum jedes Step so:

- **B muss VOR dem Restore entstehen** (solange A den vollen Stand hat). B's Baum
  ist der Anker: beim Restore wird B „preserving their content" gerebased, sein
  Baum bleibt voll → sein Diff ist danach exakt X.
- **Der Working Copy (Kind von A) ist das Editing-Ground**: nach Schritt 2 ist
  der WC-Baum „A ohne X" — genau dieser Stand wird der neue A. Hier testen/builden,
  dann ist der reduzierte Baum schon validiert.
- **Restore**: A bekommt den reduzierten Stand. Descendants (B und @) behalten
  ihre Bäume: B absorbiert X als Diff, @'s Baum == neuer A → @ ist wieder leer.

## Semantik des Flags

`--restore-descendants` existiert nur auf `jj restore` ("Preserve the content
(not the diff) when rebasing descendants") und `jj abandon` ("Do not modify the
content of the children") — NICHT auf squash/split (Stand: getestete jj-Version).

- **Ohne Flag** behalten Descendants ihre *Diffs*: das leere Kind B bleibt leer,
  X landet in keinem Commit mehr (nur via `jj op log` rekonstruierbar).
  Scratch-verifiziert.
- **Mit Flag** behalten Descendants ihre *Bäume*: B wird durch die inverse Delta
  zum X-Commit. Genau der Unterschied, der den Split macht.

## Sonderfall: A in der Mitte des Stacks

Hat A echte Kinder (A → D → …), braucht es keinen geparkten B: Editing-Ground
ist dann `jj new <A>` (ohne --no-edit, @ wird das neue Kind von A), X entfernen,
restore wie oben. Die Delta landet im **direkten Kind D** — dessen Diff wächst um
X (zusätzlich zu seiner eigenen Änderung), alle höheren Descendants behalten
ihre Diffs, D's Message ggf. anpassen. Scratch-verifiziert.

## Verifikation nach dem Restore

- `jj diff -r <B>` — darf ausschließlich X enthalten (Kontrolle: Non-X-Zeilen
  der +/- Lines greppen → muss leer sein).
- `jj diff -r <A>` — darf X nicht mehr enthalten.
- `jj status` — @ wieder leer.
- Beide Bäume sind einzeln getestet: der reduzierte (A) lief als WC in Schritt 2,
  B's Baum ist der alte, bereits getestete Stand von A.

## Stolperfallen

- B nach dem Restore anlegen ist zu spät: es erbt den reduzierten Stand und
  bleibt leer → X ist verloren.
- `jj new` ohne `--no-edit` wandert @ auf B → das Editing-Ground-Layout kaputt.
- B ist danach Sibling von @; zum Weiterarbeiten auf B: `jj new <B>`.
- Revsets: Change-ID-Prefixes benutzen (`jj new mz --no-edit` …), keine
  `description()`-Funktion — die resolved je nach jj-Version stille leer.
- Entfernt man eine API, die (ggf. gitignored) lokale Files benutzen, kompiliert
  der reduzierte Baum lokal nicht mehr — die getrackten Commits bleiben
  konsistent; beim lokalen Build nur die unveränderten Module bauen.
