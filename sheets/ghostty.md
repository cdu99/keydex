# Ghostty

apps: com.mitchellh.ghostty
command: sh ./ghostty.sh

Ghostty handles most of its keybindings itself, so they are in no menu: line editing keys sent
to the shell, prompt jumps, scrolling, selection… This sheet asks the running Ghostty for them
(`ghostty +list-keybinds`, see `ghostty.sh`), so it always follows your configuration.
