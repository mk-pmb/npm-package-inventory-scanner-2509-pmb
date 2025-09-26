#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function pkgvertree_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local TMP_BFN="tmp.npm-pkgvers-tree.$(printf '%(%y%m%d)T' -1)"
  local TASK="${1:-scan}"; shift
  pkgvertree_"$TASK" "$@" || return $?$(
    echo E: "Task '$TASK' failed, rv=$?" >&2)
}


function pkgvertree_scan () {
  local NPM_LS_CD=
  case "$1" in
    . | /* | ./* | ../* ) NPM_LS_CD="$1"; shift;;
  esac
  [ "$#" == 0 ] || return 4$(
    echo E: "scan: Unexpected unsupported CLI argument: '$1'" >&2)

  pkgvertree_ensure_tree_file || return $?
  sed -rf <(echo '
    s~^ +"([^"]+)": \{ "version": "([^"]+)"(,| \},?$)~\tp:\1\tv:\2\n\r\3~
    /version/s~^~#??\t~
    ') -- "$TMP_BFN.tree.json" | sed -nre '/^\r/d; /\t/s~$~\t~p' |
    LANG=C sort --version-sort --uniq >"$TMP_BFN.versions.tsv"
  wc --lines -- "$TMP_BFN.versions.tsv"
  echo D: 'All done.'
}


function pkgvertree_ensure_tree_file () {
  local TREE_JSON="$TMP_BFN.tree.json"
  local TREE_ERR="$TMP_BFN.tree.err"
  if [ -s "$TREE_JSON" ]; then
    echo D: "Reusing existing tree file '$TREE_JSON'. (Delete it if outdated.)"
    return 0
  fi
  echo D: 'Tree scan start!'
  local SCAN_DURA="$SECONDS"
  ( cd -- "${NPM_LS_CD:-.}" && npm ls --all --json
  ) 2> >(pkgvertree_denoise_npm_ls | tee -- "$TREE_ERR" >&2) |
    pkgvertree_denoise_npm_ls | pkgvertree_compactify_json >"$TMP_BFN.tree.json"
  sleep 0.5s
  (( SCAN_DURA -= SECONDS ))
  (( SCAN_DURA *= -1 ))
  echo D: "Tree scan ended, took ≈ $SCAN_DURA seconds." \
    'Waitin for remaining processes to quit.'
  wait || return $?$(
    echo E: "Failed to wait for subproceeses: rv=$?" >&2)
  if [ -s "$TREE_ERR" ]; then
    nl -ba -- "$TREE_ERR" | tail --lines=20 | cut --bytes=1-200 >&2
    echo E: "There were some errors. Error log file: $TREE_ERR" >&2
    return 4
  else
    rm -- "$TREE_ERR"
  fi
}


function pkgvertree_denoise_npm_ls () {
  sed -rf <(echo '
    /^$/d
    /^npm ERR! A complete log of this run can be found in:/{N;d}
    /^npm ERR! code ELSPROBLEMS$/d
    /^npm ERR! extraneous: /d
    /^npm ERR! invalid: /d
    /^npm ERR! missing: /d

    /^\{$/N
    s~^\{\n  "~{ "~

    /^\{ "problems": \[$/s~ ~\n  ~
    /^\{ +"error": \{/{N; s~\n +("code": ")~ \1~}
    ') |
    sed -rf <(echo '
      /^ +"extraneous": true,/d
      /^ +"problems": \[$/,/^ +\],?$/d
      /^\{ "error": \{ "code": "ELSPROBLEMS",/,/^ *\}/{
        /^ +"summary": "/d
        /^ +"detail": "",?$/d
      }
    ') |
    sed -re '/^\{ "error": \{ "code": "[^"]+",/{N;s~,\n +\}~ }~}' |
    sed -re '/^\{ "error": \{ "code": "[^"]+" \}/N; s~\n\}~ }~' |
    sed -re '/^\{ "error": \{ "code": "ELSPROBLEMS" \} \}$/d' |
    cat # <- Allows to insert more steps above with less diff flickering.
}


function pkgvertree_compactify_json () {
  tr '\n}' '\r\n' |
    sed -re 's~,([\r ]+)$~\1~' |
    sed -re 's~\{[ \r]*("version": "[^" \r\n\t]+")(\r +|) $~{ \1 ~g' |
    sed -re 's~\{\r *("version": "|$)~{ \1~g' |
    sed -re 's~,\r *("resolved": ")~, \1~g' |
    sed -re 's~"\r *$~ ~g' |
    # sed -re 's~^~<<~;s~$~>>~' |
    tr '\r\n' '\n}' |
    sed -re '/^ +"\.[a-z]+": \{ *\},?$/d' |
    cat # <- Allows to insert more steps above with less diff flickering.
}










pkgvertree_cli_init "$@"; exit $?
