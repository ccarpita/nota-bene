# Overview

Nota Bene is a simple shell-based note-taking application providing Evernote-like functionality.

Why use a fancy thick client application to take notes when you're already in the terminal?  Ain't nobody got time for that!

NB uses a simple convention: notes are stored in flat namespace, and the filename of the note is the label.  Using the power of the shell, you can list, search, and even encrypt notes (TBD).  By symlinking your note directory into a sync service folder (such as Dropbox) you can get all the benefit of free cloud storage and mobile access.

# Install

Available as a [bpkg](http://www.bpkg.io/)
```sh
bpkg install ccarpita/nota-bene
```

# Usage

Edit or start a new note

```sh
nb note-label
# Uses EDITOR (default: vim) for note taking
```

List your notes
```sh
nb --list <optional-filter-search>
```

Search your notes
```sh
nb --search <query>
```

Setup command-line completion and the aliases `nbs` (search) and `nbl` (list)
```sh
NB_DIR=~/Dropbox/my-notes
source `which nb`
```

# Environmental Variables

------------------------------------------
| Variable | Default Value | Description |
| -------- | ------------- | ----------- |
| `EDITOR` | `vim` | Default note editor to use |
| `NB_DIR` | `$HOME/notes` | The directory where your notes will be stored.  Pro tip: symlink this into your Dropbox for cloud sync |
| `NB_DEFAULT_EXT` | `md`  | The default extension given to your notes.  Markdown is the preferred, but you can use `txt` if you prefer |
------------------------------------------

# TODO

* Setup GH issues
* Support encryption
* Automated testing

