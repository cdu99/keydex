# Obsidian

apps: md.obsidian
command: sh ./obsidian.sh

Obsidian lists only a few of its hotkeys in its menus: most of them (editing, tabs, files,
plugins…) live in Settings → Hotkeys. This sheet asks the running Obsidian for them through
its command line (`obsidian hotkeys`, see `obsidian.sh`), so it follows your custom hotkeys
and the plugins you enable, in the current vault.

It needs the command line interface: Settings → General → Command line interface.
