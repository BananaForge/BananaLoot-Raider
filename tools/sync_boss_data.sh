#!/bin/bash
# Kopiert die Boss-Standardtexte aus dem BananaLoot-Repo (Pfad als Argument, Standard ../BananaLoot).
SRC="${1:-../BananaLoot}/BananaLootBossData.lua"
DST="$(dirname "$0")/../BananaLootRaiderBossData.lua"
{
  echo "-- BananaLootRaiderBossData.lua"
  echo "-- Kopie der Boss-Standardtexte aus BananaLoot (BananaLootBossData.lua), erzeugt mit tools/sync_boss_data.sh"
  echo "--"
  sed 's/BananaLoot_RaidData/BananaLootRaider_RaidData/g' "$SRC"
} > "$DST"
echo "ok: $DST"
