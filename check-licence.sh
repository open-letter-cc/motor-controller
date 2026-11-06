#!/usr/bin/env bash
# Copyright 2026 Open Letter, Inc.
# SPDX-License-Identifier: LicenseRef-OpenLetter-Tools
#
# Licence boundary check for this module. Fails if any file in the tree
# carries MPL text, or if a source file lacks this module's own licence
# header. Run from anywhere: it checks the directory it lives in.
#
# Third-party code vendored under its own licence (an ipc-channel copy, say)
# lives under a directory listed in THIRD_PARTY below; those files keep their
# upstream notices and are exempt from the header rule, but still must not
# carry MPL text, because nothing MPL-licensed is ever vendored here.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$dir"

THIRD_PARTY=("third_party")
status=0

is_third_party() {
  for p in "${THIRD_PARTY[@]}"; do
    case "$1" in ./"$p"/*) return 0 ;; esac
  done
  return 1
}

while IFS= read -r f; do
  # This script names the pattern it looks for; skip itself.
  [ "$f" = "./check-licence.sh" ] && continue
  if grep -qiE 'mozilla public license|MPL-2\.0|mozilla\.org/MPL' "$f"; then
    echo "::error::MPL text in $f; nothing MPL-licensed belongs in this module"
    status=1
  fi
  is_third_party "$f" && continue
  case "$f" in
    ./LICENSES/*|./Cargo.lock|./.gitignore) continue ;;
    *.rs|*.toml|*.md|*.sh|*.yml|*.yaml|*.c|*.h)
      if ! grep -q 'SPDX-License-Identifier: LicenseRef-OpenLetter-Tools' "$f"; then
        echo "::error::$f lacks the LicenseRef-OpenLetter-Tools header"
        status=1
      fi ;;
  esac
done < <(find . -type f -not -path './.git/*' -not -path './target/*')

if [ "$status" -eq 0 ]; then
  echo "licence boundary clean: no MPL text, headers present"
fi
exit "$status"
