# zsh

apps: Ghostty, Terminal, iTerm2, WezTerm, Alacritty, kitty

Line editing shortcuts of zsh in its default (emacs) mode. They belong to the shell, not to
the terminal, so they appear in no menu.

Shortcuts with ⌥ need the terminal to send ⌥ as Meta (Alt): in Ghostty set
`macos-option-as-alt = true`, in Terminal tick "Use Option as Meta key", in iTerm2 set the
Option key to "Esc+".

## Déplacement
- `⌃A` Début de ligne
- `⌃E` Fin de ligne
- `⌥B` Mot précédent (⌥ = Meta)
- `⌥F` Mot suivant (⌥ = Meta)
- `⌃B` Caractère précédent
- `⌃F` Caractère suivant

## Effacement
- `⌃W` Effacer le mot précédent
- `⌥⌫` Effacer le mot précédent (⌥ = Meta)
- `⌥D` Effacer le mot suivant (⌥ = Meta)
- `⌃U` Effacer toute la ligne
- `⌃K` Effacer jusqu'à la fin de la ligne
- `⌃D` Effacer le caractère suivant (ou quitter si la ligne est vide)
- `⌃Y` Recoller le dernier texte effacé
- `⌃_` Annuler

## Mots
- `⌥T` Échanger les deux mots (⌥ = Meta)
- `⌃T` Échanger les deux caractères
- `⌥U` Mot en majuscules (⌥ = Meta)
- `⌥L` Mot en minuscules (⌥ = Meta)
- `⌥C` Mot avec une majuscule (⌥ = Meta)

## Historique et sélection
- `⌃R` Chercher dans l'historique
- `⌃P` Commande précédente
- `⌃N` Commande suivante
- `⌥.` Insérer le dernier argument de la commande précédente (⌥ = Meta)
- `⌃Space` Poser une marque (début de sélection)
- `⌃L` Effacer l'écran
- `⌃C` Interrompre la commande
