# Changelog

Alle nennenswerten Änderungen an BananaLoot Raider werden hier
festgehalten.

## Unreleased

- Neu: Item-Vorladen pro Instanz. Beim Betreten eines Dungeons/Raids
  fragt das Addon alle dort droppenden Items, die der Client noch nicht
  kennt, gedrosselt (4 pro Sekunde) per unsichtbarem Tooltip beim Server
  ab. Dadurch zeigt das Blizzard-Wuerfelfenster beim Looten Icon und
  Tooltip statt eines Fragezeichens. Daten: `BananaLootRaiderZoneLoot.lua`
  (aus AtlasLoot Turtle WoW Edition, mit Erlaubnis des Entwicklers,
  erzeugt mit `tools/gen_zone_loot.py`). Befehle: `/blr prefetch`
  (manuell fuer die aktuelle Zone), `/blr prefetch on|off`.
- README auf Englisch umgestellt und an Struktur/Branding von
  [BananaLoot](https://github.com/BaregBananenrepublik/BananaLoot)
  angeglichen (Banner, "Part of BananaForge", Credits-Abschnitt mit
  Bananaforge-Luminar-Hinweis, Repository-Layout, Limitations-Abschnitt).
- Bild-Ordner von `.github/` nach `assets/` umbenannt (Konvention von
  BananaLoot: "Images for this README only, not shipped").

## v1.1

- Item-Datenbank auf den aktuellen BananaLoot-Stand aktualisiert (ca.
  14.230 Einträge statt ca. 3.600, jetzt inkl. Icon-Feld – Items zeigen
  dadurch häufiger ein echtes Icon statt des Fragezeichen-Platzhalters).
- Trade-Tracking grundlegend überarbeitet: statt empfangene
  `TT`-Nachrichten nur weiterzuleiten, erkennt BananaLoot Raider
  Weitergaben jetzt wie der Lootmaster selbst im eigenen Handelsfenster
  (inkl. Chat-Hinweis bei erkannter Weitergabe). Standard jetzt: an
  (vorher aus).
- Roll-Sync-Popup zeigt jetzt Round-Robin-Stufen an (RR-Tag je
  MS-Wurf, nicht gewertete Würfe ausgegraut mit Legende), wenn der
  Lootmaster Round-Robin-Hauptspec nutzt.
- `RL`-Nachrichten (neues Raidlead-Feature des Lootmasters) werden sauber
  ignoriert.
- Repo-Struktur für git-basierte Addon-Installation über den OctoLauncher
  vorbereitet (siehe README), inkl. zweiter `.toc`-Datei unter dem
  Repo-Namen als Fallback und `.gitattributes` zum Schutz der
  TGA-Icons.

## v1.0

- Erste Version: Roll-Sync-Empfangs-Popup, geteilte Loot-Historie,
  SR/unSR-Sende-Fenster, optionales Trade-Tracking, Minimap-Button,
  Optionen (Sprache/Sound/Skalierung).
