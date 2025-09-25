#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function download_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  set -o errexit
  cd -- "$SELFPATH"
  local URL= SITE=
  exec < <(sed -nre '/<!-- versions table sites -->/,/<!--/'$(
    )'{s~^\s+~~;s~\)$~~p}' -- README.md)
  while IFS= read -r URL; do
    SITE="$URL"
    SITE="${SITE#*://}"
    SITE="${SITE#www.}"
    SITE="${SITE%%.*}"
    [ -s tmp."$SITE".html ] || wget -O tmp."$SITE".html -- "$URL"
    case "$SITE" in
      getsafety ) "$SITE"_like_site "$URL";;
      * ) aikido_like_site "$URL";;
    esac
  done

  grep --no-filename --fixed-strings --regexp=$'\tn:' -- tmp.*.pkg |
    sort --version-sort --unique | tee -- tmp.versions.grep |
    sed -re 's~\tv:.*~\t~' | uniq >tmp.names.grep
  wc --lines -- tmp.versions.grep
}


function aikido_like_site () {
  <tmp."$SITE".html aikido_simplify_html | aikido_pkgtbl_extract |
    aikido_pkgtbl_html2tsv | tee -- tmp."$SITE".tsv |
    aikido_split_versions | tee -- tmp."$SITE".pkg |
    aikido_check_found_anything
}


function aikido_check_found_anything () {
  # ATTN: Don't use --quiet in grep, or it will terminate early and
  #   break its input pipe!
  grep -Fe $'\tn:' >/dev/null || return 4$(
    echo E: "Failed to find any package table entry in site $SITE!" >&2)
}


function aikido_simplify_html () {
  tr -s '\r\n \t' ' ' |
    sed -re 's~<h[1-6]\b[^<>]*>([^<>]*)</h[1-6]>~\n<hl>\1</hl>\n~g' |
    sed -re 's~<(/?)(table|p|tr)\b[^<>]*>~\n<\1\2>~g'
}


function aikido_pkgtbl_extract () {
  sed -re 's~^<hl>(Affected|Impacted) Packages<\/hl>$~<attn>~i' |
    sed -nre '/^<attn>$/,/<\/table>/p'
}


function aikido_pkgtbl_html2tsv () {
  sed -rf <(echo '
    /^<tr>/!d
    /<td\b/!d
    s~^<tr>~~
    s~\s*</td>~~g
    s~\s*<td\b[^<>]*>~\t~g
    s~^\t[0-9]+\t~~
    s~^\t+~~
    ')
}


function aikido_split_versions () {
  local PKG= VER=
  while IFS= read -r PKG; do
    VER="${PKG#*$'\t'}"
    PKG="${PKG%%$'\t'*}"
    VER="${VER//,/ }"
    for VER in $VER; do
      printf '%s\t' '' "n:$PKG" "v:$VER"
      echo
    done
  done
}


function getsafety_like_site () {
  <tmp."$SITE".html aikido_simplify_html | grep -xvFe '</p>' |
    sed -re 's~^<p>The affected packages and versions are:~<attn>~i' |
    sed -nre '/^<attn>/{n;s~^<p>~~;s~<br ?/?>~\n~g;p}' |
    sed -re 's~ - ~\t~' | tee -- tmp."$SITE".tsv |
    aikido_split_versions | tee -- tmp."$SITE".pkg |
    aikido_check_found_anything
}










download_cli_init "$@"; exit $?
