# Changelog

## v1.4

- Neu: Loot-Historie nach Boss/Mob gruppiert. Jede bekaempfte Quelle erscheint als Kopfzeile (mit Anzahl); Anklicken klappt den Loot auf/zu. Die Quelle kommt von BananaLoot ab v3.47 (aeltere Versionen: "Unbekannte Quelle").
- Fix: Scrollen in der Loot-Historie funktioniert (Mausrad und Scrollleiste).
- Texte in den Kaestchen sind jetzt in jeder Spalte zentriert.

Alle nennenswerten Änderungen an BananaLoot Raider werden hier
festgehalten.

## v1.3

- Neu: Loot-Historie lesbarer. Kleiner Rahmen um die Liste, hoehere Zeilen mit mehr Abstand (zweizeilige Itemnamen werden nicht mehr gequetscht) und ein Gitternetz mit Zeilenrahmen und Spaltentrennern (Zeit | Item | Gewinner | Pool).

## v1.2

- Neu: Die Versionsnummer steht im Titel des Hauptfensters ("Loot-Historie v1.2") und in der Ladezeile; `/blr version` zeigt sie an. In einer Gruppe antwortet BananaLoot Raider auf `/bl version` von BananaLoot mit seiner Version, so sieht der Loot-Master, wer welche Version hat. Regel: jede Aenderung erhoeht die Version (beide TOCs + `BananaLootRaider.VERSION` + Ueberschrift hier); `tools/check_version.sh` prueft das.

- Neu: Jedes Item hat Informationen. `BananaLootRaiderItemInfoExtra.lua` ergaenzt Name,
  Qualitaet und Icon fuer ca. 1500 Items aus AtlasLoot, die der Item-Datenbank fehlten;
  kennt der Client keinen Tooltip, baut das Addon ihn lokal aus der Datenbank.
- Geaendert: Das Item-Vorladen merkt sich Anfragen 3 Tage lang und laeuft nicht doppelt,
  wenn BananaLoot installiert ist (dessen Vorladen uebernimmt).
- Neu: Automatische Raid-Erkennung. In einer Gruppe/einem Raid fragt der Raider im
  Hintergrund, welcher BananaLoot-Raid dort laeuft, und verbindet sich mit dessen
  Raid-Code selbst (nur ueber Raid-/Gruppenchat, nie ueber die Gilde). Ein von
  Hand eingegebener Code bleibt bestehen.
- Neu: Button "SR einreichen" neben "Optionen" im Hauptfenster (oeffnet dasselbe
  Fenster wie `/blr code`). Das bisherige Whisper-Fenster heisst jetzt "Whisper-SR".
- Neu: Bankreserve-Items des Raids sind im SR-Fenster gesperrt.
- Fix: Der "?"-Button im Hauptfenster haengte an einem erst spaeter erzeugten Button
  und sass am Fensterrand; die obere Buttonzeile ist jetzt sauber verkettet.
- Geaendert: Alle Fenster haben jetzt einen dunklen, fast deckenden Hintergrund
  (besser lesbar, keine durchscheinenden Texte anderer Fenster) und werden beim
  Anklicken/Oeffnen komplett nach oben geholt. Ebenen vereinheitlicht: Roll-Sync-
  Popup und Loot-Historie auf HIGH, alle weiteren Fenster auf DIALOG
  (`BananaLootRaiderTheme.lua`).
- Neu: Raid-Code. Der Loot-Master von BananaLoot nennt einen Raid-Code (z.B.
  `MC-7K3Q`). Mit `/blr code [Code]` verbindet man sich, waehlt seine SR-Items
  aus der Beute des Raids (Icon, Tooltip, Suche, Qualitaetsfilter Weiss/Gruen/
  Blau/Episch/Orange, Hard-Reserve- und Raid-Roll-Items sind gesperrt) und sendet
  sie per Addon-Nachricht in den Raid-Chat (ohne Raid: Gruppe, sonst Gilde).
  Loot-Master und Stellvertreter nehmen die SR an und bestaetigen sie; der
  Status (SR offen/geschlossen, max. SR) wird live angezeigt. Erneut senden
  ersetzt die alte SR. Daten: `BananaLootRaiderRaidLoot.lua` (aus AtlasLoot
  Turtle WoW Edition, mit Erlaubnis des Entwicklers).
- Fix: Item-Icon im Roll-Sync-Popup blieb bei manchen Items ein Fragezeichen.
  Das Icon wird jetzt unabhaengig von der Position im `GetItemInfo`-Ergebnis
  gelesen (1.12: 9. Wert), und unbekannte Items werden aktiv beim Server
  angefragt, statt nur zu warten.
- Neu: Faehrt man mit der Maus ueber ein Fragezeichen-Icon im Popup, wird das
  Item erneut beim Server angefragt und das Icon einige Sekunden lang neu
  geladen.
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
