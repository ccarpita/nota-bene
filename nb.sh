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

}

nb () {
  local dir="${NOTE_DIR:-$HOME/notes}"
  if ! mkdir -p "$dir"; then
    echo "Setup error: cannot mkdir -p $dir" >&2
    return 1
  fi

  declare -i local search=0
  declare -i local list=0
  declare -i local encrypt=0
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
  if (( search == 1 )) && (( list == 1 )); then
    echo "--search and --list are mutually exclusive options" >&2
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

  if (( search == 1 )); then
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

  ## your code here
}

nbs () {
  nb --search "$@"
}

nbl () {
  nb --list "$@"
}

__nb_complete () {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $( compgen -W "$(nb --list)" -- $cur ) )
  return 0
}

setup () {
  complete -o default -o nospace -F __note_complete nb
  complete -o default -o nospace -F __note_complete nbl
  export -f nb
  export -f nbs
  export -f nbl
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  setup
else
  nb "${@}"
  exit 0
fi
