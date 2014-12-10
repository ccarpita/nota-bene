#!/bin/bash

VERSION=0.0.1

usage () {
  echo "nb [-hV] [-e] [-sl] [name|query]"
  echo
  echo "Options:"
  echo "  -h|--help               Print this help dialogue and exit"
  echo "  -V|--version            Print the current version and exit"
  echo "  -l|--ls|--list [query]  List notes.  Optional query arg will filter list"
  echo "  -s|--search <query>     Search notes using query argument"
  echo "  -m|--move|-r|--rename  <name> <newname>  Rename note"
  echo "  -p|--publish <name>     Publish note."
}

nb_move () {
  local ext="$1"
  local from="${2%.*}"
  local to="${3%.*}"
  local notefile="$dir/$from.$ext"
  local destfile="$dir/$to.$ext"
  if [[ -e "$destfile" ]]; then
    echo "Error: destination note already exists, will not overwrite: $destname"
    return 1
  fi
  mv "$notefile" "$destfile"
  echo "Moved: $rootname -> $destname"
}

nb_pub () {
  local filename="$1"
  local dir="${NB_DIR:-$HOME/notes}"
  if [ ! -f "$dir/$filename" ]; then
    echo "Error: File not found: $filename" >&2
    return 1
  fi
  local pubdir="${NB_PUB_DIR:-$HOME/pub}"
  if [ ! -d "$pubdir" ]; then
    mkdir -p "$pubdir"
  fi
  cd "$pubdir"
  if [ ! -d ".git" ]; then
    if ! git init; then
      echo "Error: could not initialize git repo" >&2
      return 1
    fi
  fi
  local branch="${NB_PUB_BRANCH:-public}"
  if ! git checkout "$branch"; then
    if ! git checkout -b "$branch"; then
      echo "Error: could not create branch: $branch" >&2
      return 1
    fi
  fi
  cp "$dir/$filename" "$pubdir/$filename"
  git add "$filename"
  git commit -m "Publish Update: $filename"
  if ! git push origin public; then
    echo "Error: could not push to origin.  Please check your remote settings" >&2
    return 1
  fi
  return 0
}

nb () {
  local dir="${NB_DIR:-$HOME/notes}"
  if ! mkdir -p "$dir"; then
    echo "Setup error: cannot mkdir -p $dir" >&2
    return 1
  fi

  declare -i local search=0
  declare -i local list=0
  declare -i local encrypt=0
  declare -i local move=0
  declare -i local pub=0
  local text=""
  local query=""
  local name=""
  local grep_opt=""

  local num_args=$#
  for arg in "${@}"; do
    case "$arg" in
      -V|--version)
        echo "$VERSION"
        return 0
        ;;
      -h|--help)
        usage
        return 0
        ;;
      --list|--ls|-l)
        list=1
        ;;
      --search|-s)
        search=1
        ;;
      -w)
        grep_opt="$grep_opt -w"
        ;;
      --encrypt|-e)
        echo "warning: encryption not yet supported" >&2
        encrypt=1
        ;;
      --move|-m|--rename|-r)
        move=1
        ;;
      --publish|-p|--pub)
        pub=1
        ;;
      -*)
        echo "Error: flag not recognized: $arg" >&2
        return 1
        ;;
      *)
        if [[ -z "$name" ]]; then
          name="$arg"
        elif [[ -z "$text" ]]; then
          text="$arg"
        else
          text="$text $arg"
        fi
        ;;
    esac
  done
  if (( num_args == 0 )); then
    usage
    return 1
  fi

  local notefile=""
  local rootname=${name%.*}
  local ext=${NOTE_EXT:-md}
  if [[ "$rootname" != "$name" ]]; then
    ext=${name##*.}
  fi
  if [[ -n "$rootname" ]]; then
    for test_ext in 'txt' 'md'; do
      if [[ "$ext" != "$test_ext" ]] && [[ -f "$dir/$rootname.$test_ext" ]]; then
        ext="$test_ext"
        break
      fi
    done
    notefile="$dir/$rootname.$ext"
  fi

  if (( move == 1 )); then
    nb_move "$ext" "$query" "$text"
    return $?
  elif (( pub == 1 )); then
    nb_pub "$rootname.$ext"
    return $?
  elif (( search == 1 )); then
    query="$name"
    if [[ -z "$query" ]]; then
      echo "--search requires a query" >&2
      usage
      return 1
    fi
    grep $grep_opt -i -R -C 1 "$query" "$dir"
  elif (( list == 1 )); then
    query="${name:-.}"
    for fname in $(ls -c "$dir" | grep "$query"); do
      echo "${fname%.*}"
    done
  elif [[ -n "$text" ]]; then
    if [[ -z "$notefile" ]]; then
      echo "no notefile specified for append" >&2
      note_usage
      return 1
    fi
    echo "$text" >> "$notefile"
    echo "Appended text to end of $notefile:"
    tail -n 5 "$notefile"
  else
    if [[ -z "$notefile" ]]; then
      echo "no notefile specified for editing" >&2
      note_usage
      return 1
    fi
    ${EDITOR:-vim} "$notefile"
  fi
}

nbgrep () {
  nb --search "$@"
}

nbls () {
  nb --list "$@"
}

nbmove () {
  nb --move "$@"
}

nbcat () {
  EDITOR=cat nb "$@"
}

__nb_complete () {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $( compgen -W "$(nb --list)" -- $cur ) )
  return 0
}

setup () {
  complete -o default -o nospace -F __note_complete nb
  complete -o default -o nospace -F __note_complete nbls
  complete -o default -o nospace -F __note_complete nbgrep
  complete -o default -o nospace -F __note_complete nbcat
  complete -o default -o nospace -F __note_complete nbmove
  export -f nb
  export -f nbls
  export -f nbgrep
  export -f nbmove
  export -f nbcat
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  setup
else
  nb "${@}"
  exit 0
fi
