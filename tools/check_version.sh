#!/usr/bin/env bash
# Prueft, dass die Version ueberall gleich ist: beide TOCs, BananaLootRaider.VERSION und eine
# CHANGELOG-Ueberschrift "## v<Version>". Bei JEDER Aenderung die Version erhoehen.
# Nutzung:  bash tools/check_version.sh
set -u
cd "$(dirname "$0")/.."
a="$(grep '^## Version:' BananaLootRaider.toc | sed 's/## Version: *//' | tr -d '\r')"
b="$(grep '^## Version:' BananaLoot-Raider.toc | sed 's/## Version: *//' | tr -d '\r')"
c="$(grep -m1 '^BananaLootRaider.VERSION' BananaLootRaider.lua | sed 's/.*"\(.*\)".*/\1/')"
fail=0
if [ "$a" != "$b" ] || [ "$a" != "$c" ]; then
  echo "FEHLER Version: BananaLootRaider.toc=$a, BananaLoot-Raider.toc=$b, BananaLootRaider.VERSION=$c"; fail=1
else
  echo "ok    Version $a"
fi
if ! grep -q "^## v$a" CHANGELOG.md; then
  echo "FEHLER Version: CHANGELOG.md hat keine Ueberschrift '## v$a'"; fail=1
else
  echo "ok    CHANGELOG-Eintrag fuer v$a"
fi
exit $fail
