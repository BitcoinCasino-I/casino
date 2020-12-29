### Aktueller Stand:

- VPS bei Digital Ocean:
  - 159.89.3.149
  - SSH: dummy@159.89.3.149 mit Passwort mcjwillbeatu4ever
- Apache2-Server mit WSGI und Flask als Framework konfiguriert:
  - Apache Configs unter /etc/apache2
  - Logs unter /var/log/apache2
  - Domain casino.reshade.io
  - phpMyAdmin unter /phpmyadmin (noch zu ändern)
  - MySQL-Datenbank mit den Usern
    - root|mcjWillBeatU4Ever (Vollzugriff) und
    - dummy|mcjwillbeatu4ever ( wird auch von der Webapp verwendet und hat nur SELECT, UPDATE, DELETE, INSERT)
- Webapp
  - https://casino.reshade.io
  - liegt in /var/www/html/CasinoApp/CasinoApp
  - Python-VirtualEnvironment
    - im Webapp-Ordner &quot;source Casino\_vEnv/bin/activate&quot; um zu wechseln
    - nur hier per pip3 nötige Module installieren / entfernen
    - dann mit &quot;deactivate&quot; wieder wechseln
  - Komplette Logik in \_\_init\_\_.py
  - Statische Inhalte in /static
  - jinja2-Templates in /templates (umgewandelt von Template auf Basis von Bootstrap)
  - Mail-Config in mail.cfg
  - DB-Config in db.cfg
  - Implementierte Features
    - Registrierung mit E-Mail-Validierung
    - Login / Logout
    - Banning
    - Passwort vergessen
    - My Account-Seite
      - Nutzerdaten
      - Passwort ändern
      - Profilbild hochladen / ändern / entfernen
      - Credits &quot;kaufen&quot;
      - Account löschen
    - Send Credits (an andere User)
    - Slotmachine (bisher nur clientseitig)
    - Admin Panel
      - Show Users (mit Profilbild-, Edit- und Delete-Shortlinks)
      - Edit user
      - Delete user
      - Add user
    - Weitere Anwendungslogig und alles, was sonst halt so dazugehört (siehe CODE)

### Wichtige Hinweise:

- Falls weitere py-Skripte angelegt werden, immer Shebang benutzen
- Alle Files und Ordner auf dem Webserver (ausgenommen \_\_pycache\_\_ und Casino\_vEnv) sollten dummy als owner, www-data als groupowner und 750 als Rechte haben (außer, wenn wir für manche Sicherheitslücken für bestimmte Ordner etwas anderes brauchen)
- Bitte keinen root-User für Änderungen auf dem Server verwenden, soweit möglich
- Wenn Änderungen an der Anwendungslogik / Templates nicht direkt funktionieren, apache2 neustarten (sudo systemctl restart apache2) und evtl. Browsercache leeren (ggf. sollten wir das Caching noch weiter anpassen)

### Weitere ToDos (nur TECHNISCH):

- Weitere Features implementieren und finalisieren:
  - Input/Output-Validierung (soweit gewollt)
  - Startseite finalisieren
  - Slot Machine umschreiben (damit sie mit dem Server kommuniziert)
  - Besser sichtbare Formularantworten
  - Show Users Änderung: Mehr-Seiten-Ansicht (da sonst zu viele User auf einmal ausgegeben werden könnten)
  - Menuitems werden manchmal nicht richtig hinterlegt (fixen)
  - Buy Credits besser machen
- VPS &amp; Apache vollständig konfigurieren (Sicherheitsdirektiven etc.)
- Authentifizierungsmethoden, Benutzer und Benutzerrollen finalisieren (für VPS, MySQL, Anwendung)
- Datei- bzw. Ordnerberechtigungen finalisieren (soweit gewollt)
- Template vollständig modularisieren / dynamisch machen
- Github-Webhooks, um Änderungen im main-branch automatisch auf der Server zu pushen
- Skript, der die Anwendung komplett wiederherstellen kann
- Code-Reviews
