# imapfilter

Dieses Verzeichnis enthält ein separates imapfilter-Setup für IMAP-Filterregeln mit konfigurierbaren Whitelist- und Suspicious-Patterns.

## Projektstruktur

- `src/lua/` enthält die Lua-Quellen
- `src/config-template/` enthält die Template-Dateien, die beim Start in `/etc/imapfilter` kopiert werden, falls dort noch keine Dateien existieren
- `config/` bleibt lokal und wird nicht in Git verfolgt
- `data/` enthält die Laufzeitdaten des Containers

## Übernommene Regeln

- Whitelist: alle Adressen mit `@example.com` werden ignoriert.
- Blacklist: Adressen mit Muster `vorname_nachname12345@example.com|example.net|example.org` gelten als verdächtig.
- Betroffene Mailboxen: `INBOX` und `Security`.
- Zielordner: `Spamverdacht`.

## Einrichtung

1. Lege unter `config/accounts.csv` die IMAP-Accounts an.
2. Setze nur noch das Intervall in `.env` oder direkt im Compose-Environment.
3. Starten Sie den Container:

```bash
docker compose up -d --build
```

4. Logs ansehen:

```bash
docker compose logs -f
```

## CSV-Format für Accounts

Die IMAP-Accounts werden aus `/etc/imapfilter/accounts.csv` gelesen. Für eine einfachere Lua-Logik ist es klarer, pro Ordner eine Zeile zu definieren:

```csv
name,host,port,username,password,ssl,mailbox,spam_folder
Example User,imap.example.com,993,vorname.nachname@example.com,REPLACE_ME,true,INBOX,Spamverdacht
Example User,imap.example.com,993,vorname.nachname@example.com,REPLACE_ME,true,Security,Spamverdacht
My Example,imap.example.com,993,me@example.com,REPLACE_ME,true,INBOX,Spam
```

Die Datei wird über das Compose-Volume auf `/etc/imapfilter/accounts.csv` eingebunden. Wenn das Volume noch leer ist, initialisiert der Entrypoint die Dateien aus `src/config-template/` automatisch.

Die Konfiguration akzeptiert auch noch das ältere Format mit `mailboxes` als CSV-Liste, aber der Eintrag pro Ordner ist deutlich einfacher und robuster.

## Hinweise

- Das Poll-Interval bleibt in der Umgebung, z. B. `IMAPFILTER_INTERVAL=300`.
- Die Filterlogik ist bewusst konservativ: sie verschiebt nur eindeutige Bot-Sender-Muster und lässt `@example.com` auf jeden Fall frei.
- Die IMAP- und Mailbox-Einstellungen müssen auf die jeweilige Ziel-Umgebung angepasst werden.
- Für die Produktion sollte der IMAP-Filter auf eine echte IMAP-Umgebung mit passender Benutzer- und Spam-Ordner-Konfiguration angepasst werden.
