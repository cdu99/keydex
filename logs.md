# Keydex — journal de bord

Ce fichier suit le plan et l'avancement. Il est mis à jour à la fin de chaque étape, dans un commit `docs(logs)`.

Commits : petits, atomiques, au format [Conventional Commits](https://www.conventionalcommits.org/) (`feat(scope): …`, `fix: …`, `test: …`, `docs: …`…). Les étapes 0 à 3 ont été commitées en blocs plus gros, avant cette règle.

## Plan

### Objectif
Une app de barre de menus qui affiche les raccourcis de l'app au premier plan :
- **⌘ maintenu** → coup d'œil (le panneau disparaît au relâchement) ;
- **double ⌘ + maintien** → mode recherche (le panneau reste ouvert, filtrage, déclenchement de l'action, Échap pour fermer).

### Stack
- Swift 6 (concurrence stricte), SwiftUI + AppKit, macOS 26 (Liquid Glass). Aucune dépendance externe.
- API Accessibilité (AXUIElement) : lecture des menus de l'app et déclenchement des actions (`AXPress`).
- NSEvent global monitors pour détecter ⌘. Une seule permission : Accessibilité.
- `NSPanel` non activant : le panneau ne vole pas le focus de l'app.
- XcodeGen (`project.yml` → `Keydex.xcodeproj`, généré et non versionné), `Makefile` pour les commandes.
- Pas de sandbox (incompatible avec l'API Accessibilité), donc pas de Mac App Store. Aucun code réseau.

### Architecture (Clean)
```
Keydex/                       App : composition root (AppContainer), barre de menus, NSPanel
Packages/KeydexCore/
  Sources/KeydexDomain/       Modèle et règles métier purs (Foundation seulement), protocoles
  Sources/KeydexInfrastructure/  Adaptateurs macOS (Accessibilité, NSWorkspace, NSEvent…)
  Sources/KeydexPresentation/ View models, mise en page (pure, testée), vues SwiftUI
  Sources/KeydexDump/         Outil dev : `swift run keydex-dump <app> [--raw] [--runs N]`
  Tests/                      Tests unitaires (Swift Testing)
```
Les dépendances vont vers le domaine : l'infrastructure implémente ses protocoles, et l'app assemble le tout dans `AppContainer`.

### Étapes
| # | Étape | Statut |
|---|-------|--------|
| 0 | Squelette : app de barre de menus, package, Makefile | ✅ |
| 1 | Cœur : lecture des raccourcis de l'app active (Accessibilité) | ✅ |
| 2 | Panneau (Liquid Glass, groupes par menu, colonnes adaptatives) | ✅ |
| 3 | Geste ⌘ maintenu (coup d'œil) + double appui | ✅ |
| 4 | Performance : cache, préchargement, rafraîchissement asynchrone | ✅ |
| 5 | Mode recherche : double ⌘, filtre, navigation, déclenchement | ✅ |
| 6 | Réglages, lancement au démarrage, accueil des permissions | ⏳ |
| 7 | (après v1) Fiches perso par app et fiche système, rechargées à chaud | ⏳ |

### Limites macOS connues
- **Focus en mode recherche** : pour taper, le panneau doit recevoir le clavier. Il est non activant : l'app reste active (sa barre de menus reste affichée) et retrouve le clavier à la fermeture.
- **Raccourcis grisés** : certaines apps ne recalculent l'état d'un item qu'à l'ouverture du menu, donc l'état lu peut être périmé.
- **Menus construits à la volée** (certaines apps Electron ou Java) : ils peuvent être incomplets.
- **Signature** : avec une signature ad hoc, macOS révoque la permission Accessibilité à chaque rebuild. Voir « Prérequis ».
- **Secure Input** (champs mot de passe) : macOS masque le clavier aux autres apps, donc pas de panneau.

- **Touche fn / 🌐** : ✅ résolu. macOS l'expose via un bit non documenté (1 << 4) des modificateurs AX.
- **Items grisés** : constaté sur Ghostty, où beaucoup d'items sont grisés alors qu'ils sont utilisables. L'état n'est mis à jour qu'à l'ouverture du menu. Finder et IntelliJ semblent fiables.

### Prérequis
- Xcode (le `Makefile` force `DEVELOPER_DIR`, donc `xcode-select` n'a pas besoin d'être changé) et XcodeGen (`brew install xcodegen`).
- Recommandé : ajouter ton Apple ID dans Xcode > Réglages > Comptes, puis créer `Config/Signing.local.xcconfig` (non versionné) avec :
  ```
  DEVELOPMENT_TEAM = <ton Team ID>
  CODE_SIGN_IDENTITY = Apple Development
  ```
  La permission Accessibilité survit alors aux rebuilds.

## Avancement

### Étape 0 — Squelette ✅ (2026-11-25)
**Fait**
- `project.yml` (XcodeGen) : cible macOS 26, `LSUIElement` (pas d'icône dans le Dock), hardened runtime, pas de sandbox.
- Package local `KeydexCore` avec deux modules : `KeydexDomain` (`AppInfo`, protocole `ActiveAppProviding`) et `KeydexInfrastructure` (`WorkspaceActiveAppTracker`, qui suit l'app au premier plan en ignorant Keydex).
- App SwiftUI `MenuBarExtra`, composition root `AppContainer`.
- `Makefile` : `make run`, `make build`, `make test`, `make clean`.
- Signature configurable via `Config/Signing.xcconfig` et un `Signing.local.xcconfig` optionnel, non versionné.

**Décisions**
- Le `.xcodeproj` n'est pas versionné : `make project` le régénère.
- Interface en français, code et commentaires en anglais.

**À tester**
1. `make run`
2. Une icône ⌘ apparaît dans la barre de menus, et aucune icône dans le Dock.
3. Passe sur une autre app (Safari, Finder…), puis clique sur l'icône : « App active : Safari ». Le nom ne devient jamais « Keydex ».
4. « Quitter Keydex » (ou ⌘Q quand le menu est ouvert) ferme l'app.

**Commit** : voir `git log` (« Step 0: … »).

### Étape 1 — Cœur : lecture des raccourcis ✅ (2026-11-25)
**Fait**
- **Domaine** (`KeydexDomain`) :
  - `ModifierSet`, `Key`/`SpecialKey`, `KeyCombo` : notation Mac, modificateurs toujours dans l'ordre fn ⌃ ⌥ ⇧ ⌘, symboles ↩ ⌫ ⌦ ⎋ ⇥ ← → ↑ ↓ ⇞ ⇟ F1…F20.
  - `Shortcut`, `ShortcutGroup` (un par menu, dans l'ordre de la barre de menus), `ShortcutCatalog`, `MenuPath` (chemin index + titre, pour retrouver l'item à déclencher plus tard).
  - Ports `ShortcutSource` et `AccessibilityPermissionProviding`, use case `LoadShortcutCatalog` (exécuté hors du main thread via `@concurrent`).
- **Infrastructure** (`KeydexInfrastructure`) :
  - `AXMenuBarReader` : parcours de la barre de menus, toutes les valeurs d'un item en un seul aller-retour IPC, timeout de 1 s, profondeur limitée.
  - `AXKeyDecoder` : glyphes Carbon, caractères de contrôle et touches de fonction AppKit, codes virtuels en secours.
  - `MenuShortcutMapper` : groupes, sous-menus aplatis, séparateurs ignorés, doublons retirés, items désactivés conservés.
  - `AXPermissionService` : statut de la permission, invite système, lien vers Réglages.
  - `MenuBarDiagnostics` : vidage brut des valeurs AX.
- **App** :
  - Menu de la barre : « Raccourcis de <app> », ou « Autoriser l'accès… » si la permission manque.
  - Fenêtre de liste brute (temporaire, remplacée par le panneau à l'étape 2) : groupes, sous-menus, items grisés, nombre de raccourcis, **temps de lecture**, boutons « Recharger » et « Copier le diagnostic ».
- **Tests** : 18 tests (Swift Testing) : ordre des modificateurs, symboles, décodage des flags, glyphes, caractères et codes virtuels, construction des groupes. `make test`.

**Décisions**
- La lecture brute (`MenuItemSnapshot`) est séparée de son interprétation, qui reste testable sans app réelle.
- Le code virtuel ne sert que pour les touches non imprimables, car certaines apps renvoient 0 (= touche A) pour « aucun raccourci ».
- Pour l'instant, seuls les items avec raccourci sont affichés.

**À tester**
1. `make run`, puis clic sur l'icône ⌘ de la barre de menus → « Autoriser l'accès… ». Active Keydex dans Réglages › Confidentialité et sécurité › Accessibilité. L'icône se met à jour en une seconde environ, sans relancer l'app.
   - ⚠️ Avec la signature ad hoc, après chaque `make run`, la case peut rester cochée sans effet : retire Keydex de la liste (−) puis réautorise. Pour éviter ça, configure `Signing.local.xcconfig` (voir Prérequis).
2. Va dans Finder, puis clic sur l'icône → « Raccourcis de Finder » : la fenêtre liste les raccourcis groupés par menu (Apple, Finder, Fichier, Édition, Présentation, Aller, Fenêtre, Aide), avec les touches au format Mac.
3. Recommence avec Safari, Ghostty, IntelliJ. Note le temps de lecture affiché en haut (surtout pour IntelliJ).
4. Vérifie qu'un item grisé dans le vrai menu (ex. Édition › Copier sans sélection) l'est aussi dans la liste.
5. **fn** : dans une app native, ouvre Fenêtre › Déplacer et redimensionner, puis compare avec la liste (« fn ⌃ ← » attendu). Clique « Copier le diagnostic » et colle-moi la partie « Fenêtre » pour que je voie ce que macOS expose.

**Commit** : voir `git log` (« Step 1: … »).

### Correctif fn + outil `keydex-dump` (2026-11-26)
- Le bit 1 << 4 des modificateurs AX correspond à fn. Window › Fill renvoie 28 = fn + sans ⌘ + ⌃. Les raccourcis de placement des fenêtres s'affichent maintenant correctement (fn ⌃ ←, fn ⌃ F…).
- `keydex-dump` lit une app depuis le terminal (le terminal doit avoir l'accès Accessibilité).
- **Mesures** (à froid / ensuite) : Finder 104 / 14 ms, Safari 158 / 19 ms, Ghostty 26 / 9 ms, **IntelliJ 181 / 32 ms** (188 raccourcis).

### Étape 2 — Panneau ✅ (2026-11-26)
**Fait**
- Nouveau module `KeydexPresentation` :
  - `ColumnPlanner` (pur) : répartit les menus en colonnes **dans l'ordre** (de haut en bas, puis de gauche à droite), avec le moins de colonnes possible pour tenir en hauteur, équilibrées. Si même le maximum de colonnes ne suffit pas, le contenu défile.
  - `PanelMetrics` / `PanelLayout` : hauteurs de lignes fixes, donc la taille du panneau est connue avant rendu, sans mesure en deux passes.
  - `ShortcutPanelViewModel` : modes `glance` / `sticky`, états chargement, chargé, aucun raccourci, erreur, permission manquante.
  - Vues : en-tête (icône, nom, nombre de raccourcis, ✕ en mode sticky), menus en colonnes, touches alignées comme dans un menu macOS (modificateurs puis touche), items grisés à 40 %. Fond **Liquid Glass** (`glassEffect`), remplacé par un fond opaque si « Réduire la transparence » est activé.
- App :
  - `ShortcutPanel` : `NSPanel` sans bord, **non activant** (ne vole pas le focus), au-dessus des apps plein écran, présent sur tous les bureaux, sans animation.
  - `ShortcutPanelController` : centré sur l'écran de la souris, limité à 92 % × 86 % de l'écran, fermé par un clic en dehors.
- La fenêtre provisoire de l'étape 1 est supprimée (remplacée par `keydex-dump` pour le diagnostic).
- Tests : 34 au total (+16 : colonnes, mise en page, view model avec des faux).

**Vérifié**
- Le panneau s'ouvre pour Finder (1174 × 817, 4 colonnes) et **Finder reste l'app active**.

**À tester**
1. `make run`. Va dans une app, puis icône ⌘ → « Afficher les raccourcis de <app> ».
2. Vérifie :
   - le rendu Liquid Glass en mode clair et en mode sombre ;
   - la lisibilité ;
   - l'ordre des menus (Apple, App, Fichier, Édition…) ;
   - que les items grisés sont visibles mais estompés.
3. Clique ailleurs : le panneau se ferme. Le bouton ✕ le ferme aussi.
4. L'app d'origine garde le focus : sa barre de menus reste affichée et la frappe va toujours dans l'app.
5. Réglages › Accessibilité › Affichage › **Réduire la transparence** : le fond devient opaque.
6. Essaie IntelliJ (beaucoup de menus) et un petit écran : tout doit tenir sans défiler dans la plupart des cas.

### Étape 3 — Geste ⌘ ✅ (2026-11-26)
**Fait**
- **Domaine** :
  - `CommandGestureRecognizer`, une machine à états **pure** (sans horloge ni AppKit) qui reçoit des `InputEvent` et renvoie des effets (`startTimer`, `cancelTimer`, `showGlance`, `hideGlance`, `showSticky`).
  - `GestureTiming` : délai du coup d'œil 0,5 s, intervalle du double appui 0,3 s, maintien du 2ᵉ appui 0,15 s. Ces valeurs seront réglables à l'étape 6.
  - Port `InputEventMonitoring`.
- **Règles** :
  - Seul ⌘ maintenu **seul** déclenche le panneau.
  - Une touche, un clic, un scroll ou un autre modificateur annule le geste **jusqu'au relâchement de toutes les touches**. ⌘C, ⌘Tab, ⇧⌘…, ⌘-clic ne montrent donc jamais le panneau.
  - Une touche tapée pendant le coup d'œil le cache et le raccourci passe normalement.
  - Un double appui suivi d'un maintien ouvre le panneau **sticky**, qui reste après le relâchement.
  - Un coup d'œil ne remplace jamais un panneau sticky ouvert.
- **Infrastructure** : `NSEventInputMonitor` (monitors globaux et locaux, **en lecture seule** : les événements ne sont jamais interceptés).
- **App** : `CommandGestureCoordinator` exécute le minuteur et applique les effets au panneau. Il réinstalle les monitors quand la permission change.
- **Tests** : 52 au total. Le simulateur de chronologie couvre 16 scénarios : ⌘ maintenu, ⌘C, ⌘Tab, touche tardive, ⌘-clic, ⇧⌘ / ⌥⌘ / ⌃⌘ / fn⌘, ⇧ puis ⌘, double appui (réussi, trop lent, 1ᵉʳ appui trop long, relâché trop tôt), ⌘C puis ⌘V, minuteur périmé.

**Vérifié en réel** (événements simulés via `CGEvent`) : 9 scénarios OK, dont le coup d'œil, ⌘+touche, la touche tardive, le double appui et le sticky qui survit à un coup d'œil.

**Limite constatée** : pendant que le menu de Keydex lui-même est ouvert, le minuteur ne se déclenche pas. Sans impact en usage normal.

**À tester**
1. `make run`, puis dans n'importe quelle app :
   - **maintiens ⌘** : le panneau apparaît après ½ s ;
   - **relâche** : il disparaît.
2. Fais tes raccourcis habituels (⌘C, ⌘V, ⌘Tab maintenu, ⌘⇧T, ⌘-clic) : le panneau ne doit **jamais** apparaître.
3. Maintiens ⌘ jusqu'au panneau, puis tape une touche (ex. ⌘W) : le panneau disparaît et le raccourci fonctionne.
4. **Double appui ⌘ puis maintien** : le panneau reste après le relâchement, avec le ✕. Ferme-le avec ✕ ou un clic ailleurs (Échap arrive à l'étape 5).
5. Dis-moi si ½ s te paraît trop long ou trop court (réglable à l'étape 6).

### Ajustements du panneau après captures d'écran (2026-11-26)
Une capture de Finder sur l'écran 14" montrait des menus **coupés en bas**. Un coup d'œil ne pouvant pas défiler, les raccourcis cachés étaient perdus.
- `feat(panel)` : **colonnes adaptatives**. Largeurs essayées 268 → 236 → 212 pt ; la plus large qui tient sans défiler est retenue.
- `feat(panel)` : **flux entre colonnes**.
  - Un long menu continue en haut de la colonne suivante, avec la mention « FICHIER (suite) ».
  - Jamais moins de 2 lignes de part et d'autre d'une coupure.
  - Les colonnes sont équilibrées par recherche binaire.
- **Vérifié par capture** : Finder (118 raccourcis) tient en 4 colonnes et IntelliJ (161) en 5, sans défilement, sur l'écran 14".
- **À améliorer plus tard** : en colonnes étroites, les titres préfixés d'un sous-menu sont tronqués au milieu (« Code Compl…rent Statement »). Il faudrait privilégier le nom de l'action.

### Étape 4 — Performance ✅ (2026-11-26)
**Constats (mesurés)**
- IntelliJ ne répond vite (32 ms) que s'il a été interrogé il y a moins de ~300 ms. Sinon, une lecture coûte **~140 ms**, exécutés sur **son** fil principal. On ne peut donc pas relire à chaque appui sur ⌘ (⌘C, ⌘S…) sans risquer de ralentir IntelliJ.
- Avant cette étape, un coup d'œil apparaissait **640 à 880 ms** après l'appui sur ⌘, pour un délai réglé à 500 ms. Les causes : la lecture AX, le premier rendu du contenu (70 à 150 ms) et un minuteur retardé par macOS (jusqu'à 90 ms, App Nap et regroupement des minuteurs).

**Fait** (commits atomiques)
- `feat(domain)` : `ShortcutCatalogStore` (actor), un cache par app (LRU, 12 apps). Les lectures simultanées d'une même app sont fusionnées, les échecs ne sont pas mis en cache, et un PID réutilisé par une autre app est ignoré.
- `feat(panel)` : le panneau affiche **immédiatement** le contenu du cache, puis le rafraîchit en arrière-plan (menus ou états grisés modifiés) et se redimensionne si besoin.
- `refactor(domain)` : suppression de `LoadShortcutCatalog`, remplacé par le cache.
- `feat(presentation)` + `feat(app)` : `ActiveAppPrefetcher` lit l'app sur laquelle tu **restes** ~1 s. Les apps traversées avec ⌘Tab ne sont pas lues.
- `fix(gesture)` : tolérance de 5 ms sur le minuteur du geste.
- `perf(panel)` : **pré-rendu** du panneau (transparent, sans clic, 250 ms) juste après le préchargement. Côté Keydex, le coup d'œil passe de 148 ms à environ 15 ms.
- `feat(dump)` : option `--pause` pour observer le cache côté app.

**Résultat** : apparition **~580 à 600 ms** après l'appui sur ⌘, dont 500 ms de délai volontaire, contre 640 à 880 ms avant. Le reste vient de l'arrivée de l'événement (~12 ms) et de la composition par le serveur de fenêtres, que la mesure elle-même ralentit.
**Légèreté** : 0 % CPU au repos, ~120 Mo de mémoire (build Debug).
**Tests** : 65 au total (cache, fusion des lectures, LRU, préchargement, affichage du cache puis rafraîchissement).

**À tester**
1. `make run`. Passe sur IntelliJ, attends 1 s, puis maintiens ⌘ : le panneau apparaît dès la fin du délai, sans latence visible.
2. Sur une app jamais ouverte depuis le lancement de Keydex, ⌘ tout de suite : le panneau apparaît après la première lecture (un peu plus lent, c'est normal).
3. Dans une app, sélectionne du texte ou non, puis maintiens ⌘ : l'état grisé de Copier/Couper se met à jour (après un court instant si le cache était périmé).
4. ⌘Tab rapide entre plusieurs apps : rien ne doit ralentir.

### Étape 5 — Mode recherche ✅ (2026-11-26)
**Fait** (commits atomiques)
- `feat(domain)` : `ShortcutQuery` cherche **par nom ou par touches**.
  - Insensible à la casse et aux accents.
  - Tous les termes doivent correspondre ; les menus et sous-menus comptent aussi.
  - Modificateurs collés ou non : « ⌘⇧F », « cmd shift f », « Cmd+Shift+F ».
  - Mots Windows/Linux et français acceptés : « ctrl », « alt », « maj ».
  - Noms de touches : « esc », « échap », « f5 », « gauche », « ← ».
  - Avec des modificateurs, une lettre seule désigne la touche ; sans, elle cherche le début des mots.
- `feat(infra)` : `AXMenuActionPerformer` déclenche l'item via `AXPress`. `MenuPathResolver` (pur, testé) suit les positions et vérifie les titres. Si l'item a bougé, il le retrouve par son titre ; s'il a disparu, **il n'appuie sur rien** plutôt que sur un autre item.
- `feat(dump)` : `--perform TITLE` pour tester depuis le terminal.
- `refactor(infra)` : utilitaires AX partagés.
- `feat(panel)` (view model) : requête, résultats affichés **dans la taille actuelle du panneau** (la fenêtre ne saute pas pendant la frappe), sélection ↑↓ circulaire, exécution de l'action (fermeture, puis 80 ms, puis `AXPress`).
- `feat(panel)` (UI) :
  - champ de recherche dans l'en-tête, nombre de résultats ;
  - ligne sélectionnée en surbrillance (comme un item de menu) ;
  - **↑ ↓ ↩ Échap** ;
  - survol = sélection, clic = exécution ;
  - « Aucun raccourci ne correspond… » quand rien ne correspond.
  - Le panneau sticky **prend le clavier sans activer Keydex**.
- `feat(panel)` : le panneau se ferme quand on change d'app (⌘Tab, Dock).
- Tests : 87 au total (+22 : recherche, résolveur de menus, recherche et navigation dans le view model).

**Vérifié en réel** (TextEdit, événements simulés) :
- Double ⌘, puis « select all » : 1 résultat, sélectionné. Pendant la recherche, TextEdit ne reçoit rien et reste l'app active.
- ↩ : le texte de TextEdit est sélectionné en moins de 100 ms, et la frappe suivante va bien dans TextEdit (le clavier est rendu).
- Échap ferme et rend le clavier ; ⌘A et ⌘V fonctionnent dans le champ de recherche.
- Les 9 scénarios du geste passent toujours.

**Limites constatées**
- Si une bulle de **correction automatique** est ouverte dans l'app (ex. TextEdit qui propose « Hello »), la première action déclenchée peut être absorbée par la fermeture de la bulle. C'est le même comportement qu'un clic dans le menu.
- Les actions grisées (état peut-être périmé) restent déclenchables : l'app décide. Si l'action est réellement indisponible, rien ne se passe.

**À tester**
1. `make run`. Dans une app, **double appui ⌘ puis maintien** : le champ de recherche a le focus.
2. Tape « copier » ou « copy », puis « ⌘⇧F », puis « fn ctrl left », puis « f5 » : les résultats se filtrent.
3. ↑ ↓ pour choisir, **↩** pour exécuter : le panneau se ferme et l'action se fait dans ton app.
4. **Échap** ou **✕** : retour exact dans ton app, la frappe y va directement.
5. Clic sur une ligne : l'action est exécutée. ⌘Tab : le panneau se ferme.
