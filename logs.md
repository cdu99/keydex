# Keydex — journal de bord

Ce fichier suit le plan et l'avancement. Il est mis à jour à chaque étape, dans le même commit que le code.

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
Keydex/                       App : composition root (AppContainer), présentation SwiftUI/AppKit
Packages/KeydexCore/
  Sources/KeydexDomain/       Modèle et règles métier purs (Foundation seulement), protocoles
  Sources/KeydexInfrastructure/  Adaptateurs macOS (Accessibilité, NSWorkspace, NSEvent…)
  Tests/                      Tests unitaires (Swift Testing)
```
Les dépendances vont vers le domaine : l'infrastructure implémente ses protocoles, et l'app assemble le tout dans `AppContainer`.

### Étapes
| # | Étape | Statut |
|---|-------|--------|
| 0 | Squelette : app de barre de menus, package, Makefile | ✅ |
| 1 | Cœur : lecture des raccourcis de l'app active (Accessibilité) | ✅ |
| 2 | Panneau (Liquid Glass, groupes par menu, colonnes adaptatives) | ⏳ |
| 3 | Geste ⌘ maintenu (coup d'œil) | ⏳ |
| 4 | Performance : cache, préchargement, rafraîchissement asynchrone | ⏳ |
| 5 | Mode recherche : double ⌘, filtre, navigation, déclenchement | ⏳ |
| 6 | Réglages, lancement au démarrage, accueil des permissions | ⏳ |
| 7 | (après v1) Fiches perso par app et fiche système, rechargées à chaud | ⏳ |

### Limites macOS connues
- **Focus en mode recherche** : pour taper, le panneau doit recevoir le clavier. Il est non activant : l'app reste active (sa barre de menus reste affichée) et retrouve le clavier à la fermeture.
- **Raccourcis grisés** : certaines apps ne recalculent l'état d'un item qu'à l'ouverture du menu, donc l'état lu peut être périmé.
- **Menus construits à la volée** (certaines apps Electron ou Java) : ils peuvent être incomplets.
- **Signature** : avec une signature ad hoc, macOS révoque la permission Accessibilité à chaque rebuild. Voir « Prérequis ».
- **Secure Input** (champs mot de passe) : macOS masque le clavier aux autres apps, donc pas de panneau.

- **Touche fn / 🌐** : les modificateurs exposés par l'API Accessibilité (format Carbon) n'ont pas de bit pour fn. Les raccourcis de placement des fenêtres (fn ⌃ ←) risquent de s'afficher « ⌃← ». À vérifier avec le diagnostic (étape 1).

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
