# Dotfiles

This directory is reserved for explicitly live-editable configuration sources.

Home Manager owns the symlink into `$HOME`; this repository owns the source
file under `dotfiles/`. A rebuild is needed when adding, removing, or changing a
Home Manager link declaration. Edits to an already-linked file are read live by
the application when it reloads or rereads the file.

Explicitly managed live files are forced during activation. Existing files at
those target paths are replaced by the repository-owned version, so do not keep
unique machine-local edits only in `$HOME`.

Do not store secrets, generated application state, caches, or files rewritten
unpredictably by applications here.
