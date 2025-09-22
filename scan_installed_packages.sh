#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function sinp_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  # cd -- "$SELFPATH" || return $?

  local -A NM_ABS_SCANNED=()
  local GLOBAL_NMDIRS=()
  sinp_find_global_nmdirs || return $?
  local FLAG_NO_GLOBAL=
  if [ "$1" == --no-global ]; then
    FLAG_NO_GLOBAL=+
    shift
  fi

  local TASK="${1:-scan}"; shift
  sinp_"$TASK" "$@" || return $?$(echo E: "Task '$TASK' failed! rv=$?" >&2)
}


function sinp_find_global_nmdirs () {
  local LIST=(
    "$HOME"/{,.}node_modules
    /{usr/,var/,}lib/{local/,site/,}node_modules
    )
  local ITEM= RESO=
  for ITEM in "${LIST[@]}"; do
    [ -d "$ITEM" ] || continue
    GLOBAL_NMDIRS+=( "$ITEM" )
    RESO="$(readlink -m -- "$ITEM")"
    [ "$RESO" == "$ITEM" ] || GLOBAL_NMDIRS+=( "$RESO" )
  done
}


function sinp_scan () {
  if tty --silent <&1 && tty --silent <&2; then
    if [ /dev/stdout -ef /dev/stderr ]; then
      echo E: 'Please redirect stdout in order to not miss warnings.' >&2
      return 4
    fi
  fi
  local NM_DIRS=()
  local ITEM= # pre-declare so the assignment can preserve the return value.
  ITEM="$(sinp_find_nm_basedirs "$@")" || return $?$(
    echo E: "Failed to scan node_modules basedirs! rv=$?" >&2)
  readarray -t NM_DIRS < <(echo "$ITEM") || return $?
  for ITEM in "${NM_DIRS[@]}"; do
    sinp_print_named_cols b "$ITEM"
    SCAN_DEPTH=0 NM_BASEDIR="$ITEM" sinp_scan_one_nm "$ITEM" || return $?
  done
}


function sinp_print_named_cols () {
  printf -- '%s:%s\t' '' '' "$@"
  echo :
}


function sinp_find_nm_basedirs () {
  # Scan cwd and parent directories, branch for any symlinks.

  local TODO=() FOUND=()
  local -A CHECKED=()
  local ITEM= MAYBE= FAIL= RESO=

  if [ -n "$FLAG_NO_GLOBAL" ]; then
    for ITEM in "${GLOBAL_NMDIRS[@]}"; do CHECKED["$ITEM"]=+; done
  else
    TODO+=( "${GLOBAL_NMDIRS[@]}" )
  fi
  [ "$#" -ge 1 ] || TODO+=( . )
  TODO+=( "$@" )

  while [ "${#TODO[@]}" -ge 1 ]; do
    ITEM="${TODO[0]}"; TODO=( "${TODO[@]:1}" )
    case "$ITEM" in
      '' ) FAIL='Enpty';;
      . ) ITEM="$PWD";;
      / ) FAIL='Cannot use root directory as';;
      */ ) FAIL='Unexpected trailing slash in';;
      /* ) ;;
      * ) FAIL='Expectead an absolute path as';;
    esac
    [ -z "$FAIL" ] || return 4$(echo E: $FUNCNAME: >&2 \
      "$FAIL candidate directory: '$ITEM'")

    [ -z "${CHECKED["$ITEM"]}" ] || continue
    [ -d "$ITEM" ] || continue

    RESO="$(readlink -m -- "$ITEM")"
    if [ "$RESO" != "$ITEM" ]; then
      # echo D: $FUNCNAME: "add sym: $RESO <- $ITEM"
      TODO+=( "$RESO" )
    fi

    MAYBE="${ITEM%/*}"
    if [ -n "$MAYBE" ]; then
      # echo D: $FUNCNAME: "add up: $MAYBE"
      TODO+=( "$MAYBE" )
    fi

    MAYBE="$ITEM"/node_modules
    if [ -d "$MAYBE" ]; then
      # echo D: $FUNCNAME: "add nm: $MAYBE"
      FOUND+=( "$MAYBE" )
    fi

    CHECKED["$ITEM"]=+
  done

  # Now we deduplicate potential symlinks in FOUND:
  readlink -m -- "${FOUND[@]}" | sort --version-sort --unique
}


function sinp_scan_one_nm () {
  local NM_DIR="$1"; shift
  [ -z "${NM_ABS_SCANNED["$NM_DIR"]}" ] || return 0
  NM_ABS_SCANNED["$NM_DIR"]=+

  # echo D: $FUNCNAME: "'$NM_DIR'"

  [ "$SCAN_DEPTH" -lt 20 ] || return 8$(
    echo E: $FUNCNAME: "Reached scan depth limit $SCAN_DEPTH at $NM_DIR" >&2)
  local SUB_DEPTH=$(( SCAN_DEPTH + 1 ))

  local ITEM= PKJS= NMSUB= RESO=
  if [ -n "$FLAG_NO_GLOBAL" ]; then
    for ITEM in "${GLOBAL_NMDIRS[@]}"; do
      case "$NM_DIR" in
        "$ITEM" | "$ITEM"/* ) return 0;;
      esac
    done
  fi

  for ITEM in "$NM_DIR"/{@[A-Za-z0-9_]*/,}[A-Za-z0-9_]*/; do
    ITEM="${ITEM%/}"
    [ -d "$ITEM" ] || continue

    PKJS="$ITEM"/package.json
    if [ -f "$PKJS" ]; then
      sinp_report_one_pkg "$ITEM" || return $?
    fi

    NMSUB="$(readlink -m -- "$ITEM"/node_modules)"
    if [ -d "$NMSUB" ]; then
      SCAN_DEPTH="$SUB_DEPTH" sinp_scan_one_nm "$NMSUB" || return $?
    fi
  done
}


function sinp_report_one_pkg () {
  local NM_DIR="$1"
  local MANIF_NAME="$(<"$NM_DIR"/package.json jq --raw-output \
    '.name + "\t" + .version')"
  local MANIF_VERS="${MANIF_NAME##*$'\t'}"
  MANIF_NAME="${MANIF_NAME%$'\t'*}"
  [ -n "$MANIF_NAME" ] || return 0$(echo W: >&2 \
    "Cannot find package name for in '$NM_DIR'")
  local PATH_COL='p'
  local NM_SUB="$NM_DIR"
  case "$NM_SUB" in
    "$NM_BASEDIR"/* )
      NM_SUB="${NM_SUB#"$NM_BASEDIR"/}"
      PATH_COL='s';;
  esac
  sinp_print_named_cols "$PATH_COL" "$NM_SUB" n "$MANIF_NAME" v "$MANIF_VERS"
  [[ "$NM_DIR" == */"$MANIF_NAME" ]] || echo W: >&2 \
    "Package name doesn't match path: '$MANIF_NAME' in '$NM_DIR'"
}










sinp_cli_init "$@"; exit $?
