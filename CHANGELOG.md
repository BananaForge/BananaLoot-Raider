# Changelog

## v1.19

- Neu: **Raids ohne BananaLoot.** Beim Betreten einer Gruppe fragt Raider per `HQ` nach BananaLoot (Antwort nach ca. 8 s ausgewertet). Findet sich keines, werden **"SR einreichen" und "SR+ Liste" ausgegraut** (sichtbar, aber nicht klickbar; Hinweis im Tooltip und unten im Hauptfenster). Sobald doch BananaLoot-Nachrichten aus der Gruppe kommen, sind sie wieder aktiv.
- Neu: **RollFor-Unterstuetzung** (https://github.com/sica42/RollFor), ohne dass RollFor installiert sein muss. Raider liest die Addon-Nachrichten des RollFor-Loot-Masters mit (Praefix `RollFor`: START_ROLL, ROLL, TIE, FINISH, CANCEL_ROLL, AWARDED, auch in Teilen) und zeigt MS/OS/TM-Wuerfe, Gewinner und Countdown im bekannten **Sync-Fenster**. Die Beute-Ansage von RollFor im Raidchat (`1. [Item] (HR)` / `2. [Item] (SR by Name [2 rolls] (+3), ...)`) wird gelesen und ergaenzt die Tooltips (SR/SR+/HR je Item).
- Neu: Dieselbe Raid-ID: erhaelt Raider denselben Raid (gleiche ID, z.B. nach einem Discord-Import durch einen Vertreter) von einem anderen Sender, gilt der **neuere** Stand; ein aelterer ersetzt keinen neueren.

## v1.18

- Fix: **"Aktiv" (Stern) in der SR+ Liste** gilt nur noch fuer Uebersichten, die hoechstens 15 Minuten alt sind und deren Sender in der eigenen Gruppe ist. Vorher blieb ein alter Raid bis zu 30 Tage "aktiv" und verdraengte neuere Raids im Tooltip.
- Fix: **Quelle**: Im Raid/in der Gruppe werden Uebersichten nur vom Loot-Master angenommen; bei der Auswahl hat der Loot-Master Vorrang.
- Fix: Gilde und Raid werden beim Empfang getrennt zusammengesetzt (keine doppelten Eintraege mehr, wenn beide Sendungen gleichzeitig ankommen).
- Neu: Beim Betreten eines Raids/einer Gruppe bzw. nach dem Einloggen fragt der Raider die Uebersicht automatisch an.

## v1.17

- Neu: **SR+ Liste** (Knopf "SR+ Liste" im Hauptfenster, `/blr srlist`). Zeigt die vom Loot-Master per BananaLoot synchronisierten Raids (mit < > blaettern, aktiver Raid zuerst): alle Items **alphabetisch**, daneben wer das Item auf SR hat und wie viel SR+ jeder hat. Mit der Maus ueber einem Item erscheinen die Item-Daten und die komplette Liste. "Neu anfragen" fordert die Uebersicht beim Loot-Master an.
- Neu: **Tooltip in der SR-Auswahlliste** (Fenster "SR einreichen"): unter den Item-Daten steht, wer das Item schon reserviert hat und mit wie viel SR+.
- Neu: **Item-Link im Raidchat anklicken**: das Item-Fenster zeigt zusaetzlich die SR+ Liste dieses Items (nur fuer Items, die zuletzt im Raidchat gepostet wurden; im Raid-Chat-Fall gilt nur der Raidchat, in einer 5er-Gruppe der Gruppenchat; im Testlauf bei jedem Item).
- Die Daten kommen ohne Einstellung bei jedem an (Raid/Gruppe und Gilde); die letzten 14 Raids werden gespeichert.

## v1.16

- Aenderung: Das 3D-Modell im Boss-Fenster ist entfernt (Kalibrierung, Animation, Modell-Liste, Option). An seiner Stelle steht ein ruhiges **Bild**: das Symbol eines besonderen Drops des Bosses (aus der Beute-Tabelle, bevorzugt ein bosstypisches Item hoher Qualitaet); Bosse ohne Beutedaten zeigen ein Totenkopf-Symbol. Die Bilder kommen aus dem Spiel selbst - es werden keine Bilddateien mitgeliefert.

## v1.15

- Neu: **Werte von Hand eintippen.** Unter dem Modell stehen jetzt Eingabefelder fuer S (Groesse), T (Tiefe), H (links/rechts), V (hoch/runter), D (Drehung) und C (Kamera-Abstand); Wert eintippen, Enter druecken. Die Knoepfe aendern die Werte weiter schrittweise; alles wird pro Boss gespeichert (`/blr modeltune`).
- Neu: **Animation.** Der Client spielt Modell-Animationen nicht von selbst ab; das Fenster schaltet jetzt die Zeit der Stehen-Animation selbst weiter, damit sich das Modell bewegt.

## v1.14

- Fix: Das Raider-Symbol (Minimap-Button, Fenster-Titel, Optionen-Logo) fehlte, wenn der Addon-Ordner "BananaLoot-Raider" heisst (so heisst der Download von GitHub) statt "BananaLootRaider": der Bildpfad war fest verdrahtet. Der Ordnername wird jetzt automatisch erkannt. Ausserdem lief die Start-Initialisierung (ADDON_LOADED) nur beim Ordnernamen "BananaLootRaider" - jetzt auch bei "BananaLoot-Raider".

## v1.13

- Aenderung: Modell-Kalibrierung im Boss-Fenster. Die Position/Groesse der Pfad-Modelle liess sich nicht zuverlaessig raten, deshalb gibt es jetzt unter dem Modell zwei Reihen Knoepfe: S-/S+ (Groesse), T-/T+ (Tiefe), < > (drehen), ^ v (hoch/runter), L R (links/rechts), K (Kamera-Modus: K1 = Portrait-Kamera, K2 = Standardkamera), ~ (Dauerdrehung), 0 (zuruecksetzen) und eine Anzeige der aktuellen Werte. Alles wird pro Boss gespeichert; `/blr modeltune` gibt die Werte zum Weitergeben aus. Standard ist K1 (Portrait-Kamera, Modell immer im Bild).

## v1.12

- Fix: Boss-Modelle waren im Boss-Test komplett weiss und zu nah herangezoomt. Ueber einen Dateipfad laedt das Spiel Modelle **ohne Texturen** - das laesst sich mit der 1.12-Schnittstelle nicht aendern. Deshalb werden Pfad-Modelle jetzt ueber das Modell-Licht **thematisch eingefaerbt** (Feuer orange, Frost blau, Gift gruen, Untote violett, Sand gelblich ...), und der Start-Zoom richtet sich nach der Modellgroesse (Groessenklasse aus den Client-Tabellen). Zusaetzliche Knoepfe `^`/`v` verschieben das Modell hoch/runter; `+`/`-` zoomen, `<`/`>` drehen. Im echten Kampf (anvisiertes Ziel) bleiben die echten Farben mit der Portrait-Kamera des Spiels.

## v1.11

- Neu: Modell-Liste fuer das Boss-Fenster/den Boss-Test aus den Client-Tabellen (CreatureDisplayInfo/CreatureModelData des Turtle-Clients) und der Classic-Datenbank erzeugt: **65 Bosse** haben jetzt ein 3D-Modell (vorher 9). Humanoide Bosse (Trolle, Menschen, Orcs) und die Turtle-Custom-Bosse fehlen weiterhin; im echten Kampf zeigt das Fenster aber immer das Modell des anvisierten Ziels. Bosse, die sich ein Modell teilen, zeigen ueber den Pfad das Standard-Aussehen.

## v1.10

- Neu: **3D-Modell im Boss-Fenster.** Links neben dem Text erscheint das animierte Spielmodell des Bosses (Fenster wird breiter). Im echten Kampf zeigt es das **anvisierte Ziel** (funktioniert fuer jeden Boss, auch Turtle-Bosse); im Boss-Test und ohne Ziel kommt das Modell aus einer Pfad-Liste (`BananaLootRaiderBossModels.lua`, Pfade aus dem Community-Listfile) - aktuell fuer Ragnaros, Onyxia, Nefarian, Hakkar, Kel'Thuzad, Taerar, Lethon, Anubisath Defender, Echo of Medivh. Bosse ohne Eintrag zeigen im Test kein Modell. Mit +/- zoomen, mit < > drehen, ~ = Dauerdrehung; die Einstellung wird pro Boss gespeichert (`/blr modeltune` gibt sie aus). Ein/aus: Raider-Optionen "3D-Modell des Bosses im Boss-Fenster zeigen" (Standard: an). Im Boss-Test sind Bosse mit Modell mit [3D] markiert.

## v1.9

- Neu: **Rolle und Klasse hervorgehoben.** Das Boss-Info-Fenster prueft zuerst, wer du bist (Klasse, Talentbaum, Rolle Tank/DD/Heiler), teilt jeden Boss-Text satzweise ein und zeigt oben **"FUER DICH"** (gelb hervorgehoben, mit ">") - alles, was deine Rolle oder deine Klasse betrifft (z.B. Taunt/Tankwechsel fuer Tanks, Tranquilizing Shot fuer Jaeger, Decursen fuer Druide/Magier, Fear Ward fuer Priester, Tremor Totem fuer Schamanen). Darunter "Fuer alle", ganz unten gedaempft, was nur andere Rollen/Klassen betrifft. Knopf "Nur fuer mich" blendet den letzten Teil aus. Die Kopfzeile nennt Rolle, Klasse und Talentbaum.
- Neu: **Boss-Test** (nur im BananaLoot-Testlauf, ueber BananaLoot > Optionen > Verwaltung "Raider-Boss-Test" oder `/blr bosstest`): aufklappbare Uebersicht aller Raids mit ihren Bossen. Ein Klick auf einen Boss zeigt das Info-Fenster wie fuer einen echten Raider. Rolle und Klasse lassen sich vortaeuschen (Tank/DD/Heiler, alle neun Klassen), um jede Ansicht zu pruefen.

## v1.8

- Aenderung: Boss-Texte ueberarbeitet (nach Recherche): Onyxia, Ebonroc, Baron Geddon, Lord Kazzak, Rend & Gyth, Bloodlord Mandokir, Ragnaros korrigiert; der Fuellsatz "Keine Fluche zu cleansen" ist aus allen Texten entfernt.
- Fix: Hat ein Text keinen eigenen Abschnitt fuer die Rolle, aber einen allgemeinen Teil, erscheint nicht mehr der Hinweis "kein eigener Hinweis".

## v1.7

- Fix: Lua-Fehler `attempt to call method 'SetVerticalScroll' (a nil value)` im Raid-Code-Fenster auf neueren Clients (nach dem OctoWow-Update, ohne pfUI). Der eigene Handler der Scrollleiste wird jetzt vor dem Setzen der Werte eingebaut.

## v1.6

- Neu: **Boss-Hilfen als Fenster.** Vor einem Boss erscheint ein kleines Fenster mit der Erklaerung - nur fuer DEINE Rolle (Tank / DD / Heiler; "Alle"-Hinweise immer dabei). Die Rolle wird ueber die Talente erkannt oder in den Optionen festgelegt; ein Knopf zeigt bei Bedarf alle Rollen. Ausloeser: die Ansage des Raidleiters (BananaLoot ab v3.51), sonst - als Fallback - das Anvisieren des Bosses (nach 3 Sekunden, nur in Gruppe/Raid). Das Fenster schliesst sich per X oder bei Kampfbeginn.
- Neu: Haken "Fuer diesen Boss nicht mehr anzeigen" im Fenster und Haken "Boss-Hilfen als Fenster anzeigen" in den Optionen (Standard: an) fuer erfahrene Spieler; Rollenwahl Auto/Tank/DD/Heiler in den Optionen.
- Neu: Die Standardtexte (112 Bosse) liegen als Kopie in `BananaLootRaiderBossData.lua` (`tools/sync_boss_data.sh` aktualisiert sie aus BananaLoot). Vom Raidleiter in BananaLoot geaenderte Texte kommen per Addon-Nachricht und werden gespeichert.
- Neu: `/blr boss <Name>` zeigt die Vorschau eines Bosses, `/blr boss reset` blendet ausgeblendete Bosse wieder ein.

## v1.5

- Neu: Kleine Sprach-Buttons "DE" / "EN" rechts oben neben dem Schliessen-Kreuz der Loot-Historie; ein Klick schaltet sofort um (aktive Sprache golden).
- Neu: Gleichnamige Mobs, die nacheinander getoetet und gelootet werden, erscheinen als getrennte Gruppen (BananaLoot ab v3.48 sendet eine Kill-Nummer mit). Die Kopfzeile zeigt zusaetzlich die Uhrzeit der ersten Vergabe.

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
