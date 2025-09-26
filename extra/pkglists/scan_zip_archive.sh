#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
set -o errexit -o pipefail
unzip -l -- "$1" | sed -nre 's~/package\.json$~~p' |
  sed -re 's~^[^:]+:[0-9]{2}+ +~~' | LANG=C sort --version-sort
