#!/bin/bash

# Voraussetzung sollte ein Debian 9 / 10 Server sein, keine zusätzlichen Check dafür im Skript

# IMPLEMENTIERT:
# - Benutzerdateneingabe
# - User-Setup mit sudo
# - root / sudo Checks
# - Automatischer Purge aller relevanten Pakete
# - Automatische Installation aller relevanten Pakete
# - Automatisches Aufsetzen der Firewall
# - Automatisches Aufsetzen und Konfigurieren von MariaDB und phpMyAdmin aus dessen Quellcode
# - Automatisches Datenbanksetup mit verschiedenen Usern
# - Automatisches Anpassen der relevanten configs
# - Automatisches De/Aktivieren aller relevanten Apache Module
# - Automatische Konfiuration der Apache Virtual Hosts und WSGI
# - Automatisches Aufsetzen der virtuellen Umgebung
# - Automatisches Setzen aller Berechtigungen
# - Automatische Installation der CasinoApp

# TODOS:
# - Alles, was der Skript nicht erledigen kann, dokumentieren in den Installationshinweisen (plus Voraussetzungen / Anleitung Skript)
# - FTP Server automatisch einrichten
# - Apache Directives / Security Settings
# - SSL Setup (allerdings wäre das eher was für die Installationshinweise, denn das dynamisch im Skript zu implementieren suckt)
# - Skript so ändern, dass die App von einem nicht-sudo ausgeführt wird
# - Ausführung des Skripts mit sudo -H -u ersetzen durch runuser oder direkt per root und dann Rechte/Besitzer/Gruppe ändern
# - Virtualenv fixen, sodass die manuellen Fixes (s. unten) nicht mehr nötig sind
# - Dynamische Konfiguration des Mail-Users (mail.cfg)
# - Am Ende des Skripts 1x alle Nutzerdaten ausgeben (mit PWs)
# - Automatische Installation des Webhooks (nötig?)
# - Funktionen verwenden (Code kürzen)
# - >/dev/null statt >/dev/null 2>&1 verwenden, wo es Sinn macht
# - separater Update-Script

# Definiere Farbcodes
red=`tput setaf 1`;
yellow=`tput setaf 3`;
green=`tput setaf 2`;
reset=`tput setaf 7`;

# Skript muss als root oder mit sudo ausgeführt werden
if [[ $EUID > 0 ]]; then
        # Abbruch
        echo "${red}Bitte als ROOT ausführen!${reset}"
        exit -1
fi

echo ""
echo "${red}Achtung: Dieses Programm entfernt alle vorhandenen Datenbanken und Websites, deinstalliert und installiert Systempakete!";
echo "Die Installation sollte nur auf einem frisch eingerichteten Debian 10 Server gestartet werden.${reset}";
read -p "Fortfahren? (Y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit -1
fi

# Führe apt update aus, da sonst manche benötigte Pakete nicht gefunden werden (und upgrade)
echo ""
echo "${yellow}Führe apt update und apt upgrade aus...${reset}"
apt-get -qq update >/dev/null 2>&1;
apt-get -qq upgrade >/dev/null 2>&1;
echo "${green}Fertig.${reset}"
echo ""

# Frage Benutzernamen für Installation ab
read -p "${yellow}Benutzername für den Linux-User der WebApp: ${reset}" APPUSER
# Falls leer oder kürzer als 3 Zeichen, breche ab (ALTERNATIV: LOOP)
if [ -z "$APPUSER" ] || [ ${#APPUSER} -lt 3 ]; then
        # Abbruch
        echo "${red}Benutzername leer oder weniger als 3 Zeichen. Abbruch.${reset}"
        exit -1
fi
# Falls User bereits existiert, breche ab
if grep "${APPUSER}" /etc/passwd >/dev/null 2>&1; then
        # Abbruch
        echo "${red}Benutzer existiert bereits. Abbruch.${reset}"
        exit -1
fi
# Frage Passwort ab (und Bestätigung dafür)
read -s -p "${yellow}Passwort für den Linux-User der WebApp: ${reset}" APPUSERPW; echo
# Falls leer oder kürzer als 9 Zeichen, breche ab (ALTERNATIV: LOOP)
if [ -z "$APPUSERPW" ] || [ ${#APPUSERPW} -lt 9 ]; then
        # Abbruch
        echo "${red}Passwort leer oder weniger als 9 Zeichen. Abbruch.${reset}"
        exit -1
fi
read -s -p "${yellow}Passwort bestätigen: ${reset}" APPUSERCONFIRMPW; echo
# Prüfe Übereinstimmung
if [[ "$APPUSERPW" != "$APPUSERCONFIRMPW" ]]; then
        # Abbruch
        echo ""
        echo "${red}Passwörter stimmen nicht überein. Abbruch.${reset}"
        exit -1
fi
# Frage Passwort für eingeschränkten Datenbanknutzer ab (und Bestätigung dafür)
read -s -p "${yellow}Passwort für den eingeschränkten Datenbanknutzer der App: ${reset}" DBUSERPW; echo
# Falls leer oder kürzer als 9 Zeichen, breche ab (ALTERNATIV: LOOP)
if [ -z "$DBUSERPW" ] || [ ${#DBUSERPW} -lt 9 ]; then
        # Abbruch
        echo "${red}Passwort leer oder weniger als 9 Zeichen. Abbruch.${reset}"
        exit -1
fi
# Prüfe ob gleich wie vorherige Passwörter
if [[ "$DBUSERPW" == "$APPUSERPW" ]]; then
        # Abbruch
        echo "${red}Passwort bereits verwendet. Abbruch.${reset}";
        exit -1
fi
read -s -p "${yellow}Passwort bestätigen: ${reset}" DBUSERCONFIRMPW; echo
# Prüfe Übereinstimmung
if [[ "$DBUSERPW" != "$DBUSERCONFIRMPW" ]]; then
        # Abbruch
        echo ""
        echo "${red}Passwörter stimmen nicht überein. Abbruch.${reset}"
        exit -1
fi

# Frage Passwort für eingeschränkten phpMyAdmin-User ab (und Bestätigung dafür)
read -s -p "${yellow}Passwort für den eingeschränkten phpMyAdmin-User: ${reset}" PHPUSERPW; echo
# Falls leer oder kürzer als 9 Zeichen, breche ab (ALTERNATIV: LOOP)
if [ -z "$PHPUSERPW" ] || [ ${#PHPUSERPW} -lt 9 ]; then
        # Abbruch
        echo "${red}Passwort leer oder weniger als 9 Zeichen. Abbruch.${reset}"
        exit -1
fi
# Prüfe ob gleich wie vorherige Passwörter
if [[ "$PHPUSERPW" == "$APPUSERPW" ]] | [[ "$PHPUSERPW" == "$DBUSERPW" ]]; then
        # Abbruch
        echo "${red}Passwort bereits verwendet. Abbruch.${reset}";
        exit -1
fi
read -s -p "${yellow}Passwort bestätigen: ${reset}" PHPUSERCONFIRMPW; echo
# Prüfe Übereinstimmung
if [[ "$PHPUSERPW" != "$PHPUSERCONFIRMPW" ]]; then
        # Abbruch
        echo ""
        echo "${red}Passwörter stimmen nicht überein. Abbruch.${reset}"
        exit -1
fi

echo "${green}Benutzerdaten OK, fahre fort...${reset}"
echo ""

# Prüfe Vorhandensein von sudo und installiere es falls nicht
echo "${yellow}Prüfe Verfügbarkeit von sudo...${reset}"
if ! type "sudo" > /dev/null; then
        # Nicht vorhandne, installiere sudo
        apt-get -qq install sudo >/dev/null 2>&1;
        echo "${green}sudo wurde installiert, fahre fort...${reset}";
        echo ""
else
        # Bereits vorhanden, nichts zu tun
        echo "${green}sudo ist vorhanden, fahre fort...${reset}";
        echo ""
fi

# Erstellung des Nutzers, Festlegen des Passworts, Hinzufügen zur sudo-Gruppe
echo "${yellow}Beginne Nutzererstellung...${reset}"
adduser --disabled-password --gecos "" $APPUSER >/dev/null;
echo -e "$APPUSERPW\n$APPUSERPW" | passwd $APPUSER >/dev/null 2>&1;
echo "${yellow}Füge zur sudo-Gruppe hinzu...${reset}"
usermod -aG sudo $APPUSER >/dev/null;
echo "${green}Fertig.${reset}"
echo ""
echo "${green}Rest der Installation wird als Nutzer \"${yellow}$APPUSER${green}\" ausgeführt.${reset}"
echo ""

# Passwort für sudo vorweg ausfüllen
sudo -H -u "$APPUSER" bash -c "(echo '$APPUSERPW' | sudo -Si >/dev/null 2>&1);"

# Diverse Programme / Ordner /Datenbanken zurücksetzen
echo "${yellow}Setze Programme zurück...${reset}"
sudo -H -u "$APPUSER" bash -c "sudo rm -rf /var/lib/mysql/* >/dev/null 2>&1";
sudo -H -u "$APPUSER" bash -c "sudo rm -rf /var/www/html >/dev/null 2>&1";
sudo -H -u "$APPUSER" bash -c "sudo rm -rf /var/lib/phpmyadmin >/dev/null 2>&1";
sudo -H -u "$APPUSER" bash -c "sudo rm -rf /usr/share/phpmyadmin >/dev/null 2>&1";
sudo -H -u "$APPUSER" bash -c "sudo rm -rf /etc/apache2 >/dev/null 2>&1";
sudo -H -u "$APPUSER" bash -c "sudo rm -rf /etc/mysql >/dev/null 2>&1";
sudo -H -u "$APPUSER" bash -c "sudo apt-get -qq purge ufw apache2 libapache2-mod-php7.3 libsodium23 php php-common php7.3 php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline psmisc php7.3-mbstring php7.3-zip php7.3-gd php7.3-xml php7.3-curl php7.3-mysql mariadb-server mariadb-client mysql-common curl python3.7 python3-dev python3-pip python3-venv python3.7-venv libapache2-mod-wsgi-py3 libapache2-mod-security2 libmariadb-dev-compat libmariadb-dev >/dev/null 2>&1";
echo "${green}Fertig.${reset}"
echo ""

# Alle notwendigen Systempakete installieren
echo "${yellow}Installiere alle nötigen Systempakete...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo apt-get -qq install git ufw openssh-server apache2 libapache2-mod-php7.3 libsodium23 php php-common php7.3 php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline psmisc php7.3-mbstring php7.3-zip php7.3-gd php7.3-xml php7.3-curl php7.3-mysql mariadb-server mariadb-client mysql-common curl python3.7 python3-dev python3-pip python3-venv python3.7-venv libapache2-mod-wsgi-py3 libapache2-mod-security2 libmariadb-dev-compat libmariadb-dev >/dev/null 2>&1";
echo "${green}Fertig.${reset}";
echo ""

# Beginne mit UFW-Setup
echo "${yellow}Richte Firewall ein...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo ufw default deny incoming >/dev/null";
sudo -H -u "$APPUSER" bash -c "sudo ufw default allow outgoing >/dev/null";
sudo -H -u "$APPUSER" bash -c "sudo ufw allow OpenSSH >/dev/null";
sudo -H -u "$APPUSER" bash -c "sudo ufw allow 'WWW Full' >/dev/null";
sudo -H -u "$APPUSER" bash -c "echo 'y' | sudo ufw enable >/dev/null";
echo "${green}Fertig.${reset}";
echo "";

# Lade Setup-Dateien herunter
echo "${yellow}Bereite App-Dateien vor...${reset}";
sudo -H -u "$APPUSER" bash -c "mkdir /home/$APPUSER/casinoapp-download";
sudo -H -u "$APPUSER" bash -c "sudo git clone -q https://github.com/Lartsch/casinoapp-deploy-test.git /home/$APPUSER/casinoapp-download >/dev/null";
echo "${green}Fertig.${reset}";
echo "";

# Beginne Apache-Setup
echo "${yellow}Konfiguriere Apache...${reset}";
echo "${yellow}Setze Rechte...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo usermod -aG www-data $APPUSER";
sudo -H -u "$APPUSER" bash -c "sudo chown www-data:www-data -R /var/www";
sudo -H -u "$APPUSER" bash -c "sudo chmod 755 -R /var/www";
echo "${yellow}Bereite .conf-Dateien vor...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo cp /home/$APPUSER/casinoapp-download/phpmyadmin.conf /etc/apache2/conf-available";
sudo -H -u "$APPUSER" bash -c "sudo cp /home/$APPUSER/casinoapp-download/Casino.conf /etc/apache2/sites-available";
echo "${yellow}De/Aktiviere .conf-Dateien...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo a2enconf -q phpmyadmin >/dev/null";
sudo -H -u "$APPUSER" bash -c "sudo a2ensite -q Casino >/dev/null";
sudo -H -u "$APPUSER" bash -c "sudo a2dissite -q 000-default >/dev/null";
echo "${yellow}Bereite Webdateien vor...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo rm /var/www/html/index.html";
sudo -H -u "$APPUSER" bash -c "sudo mv /home/$APPUSER/casinoapp-download/CasinoApp /var/www/html";
echo "${yellow}De/Aktiviere alle relevanten Module...${reset}";
ENAPACHEMODULES="access_compat authz_user dir negotiation php7.3 reqtimeout status mpm_prefork alias autoindex env rewrite wsgi filter setenvif auth_basic cgid headers authn_core proxy socache_shmcb authn_file deflate mime ssl authz_core proxy_http authz_host";
DISAPACHEMODULES="mpm_event";
for VALDIS in $DISAPACHEMODULES; do
        sudo -H -u "$APPUSER" bash -c "sudo a2dismod -q $VALDIS >/dev/null";
done
for VALEN in $ENAPACHEMODULES; do
        sudo -H -u "$APPUSER" bash -c "sudo a2enmod -q $VALEN >/dev/null";
done
echo "${green}Fertig.${reset}";
echo "";

# Beginne MariaDB / phpMyAdmin Setup
echo "${yellow}Richte Datenbanken und phpMyAdmin ein...${reset}";
echo "${yellow}Bereite Dateien für phpMyAdmin vor...${reset}";
sudo -H -u "$APPUSER" bash -c "wget -q -P /home/$APPUSER/casinoapp-download https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz";
sudo -H -u "$APPUSER" bash -c "sudo mkdir -p /usr/share/phpmyadmin";
sudo -H -u "$APPUSER" bash -c "sudo tar xvf /home/$APPUSER/casinoapp-download/phpMyAdmin-latest-all-languages.tar.gz --strip-components=1 -C /usr/share/phpmyadmin >/dev/null 2>&1";
sudo -H -u "$APPUSER" bash -c "sudo cp /home/$APPUSER/casinoapp-download/config.inc.php /usr/share/phpmyadmin";
sudo -H -u "$APPUSER" bash -c "sudo cp /home/$APPUSER/casinoapp-download/app-db.sql /usr/share/phpmyadmin/sql";
sudo -H -u "$APPUSER" bash -c "sudo mkdir -p /var/lib/phpmyadmin/tmp";
echo "${yellow}Bearbeite Konfiguration für phpMyAdmin...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/PHPUSERPW/$PHPUSERPW/g\" /usr/share/phpmyadmin/config.inc.php"
echo "${yellow}Setze Rechte...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo chown -R www-data:www-data /var/lib/phpmyadmin";
sudo -H -u "$APPUSER" bash -c "sudo chown -R www-data:www-data /usr/share/phpmyadmin";
sudo -H -u "$APPUSER" bash -c "sudo chmod -R 755 /var/lib/phpmyadmin";
sudo -H -u "$APPUSER" bash -c "sudo chmod -R 755 /usr/share/phpmyadmin";
echo "${yellow}Erstelle Datenbank für phpMyAdmin...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo mariadb < /usr/share/phpmyadmin/sql/create_tables.sql";
echo "${yellow}Erstelle Datenbank für CasinoApp...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo mariadb < /usr/share/phpmyadmin/sql/app-db.sql";
echo "${yellow}Erstelle alle Datenbanknutzer...${reset}";
DBUSER="${APPUSER}-appdb";
sudo -H -u "$APPUSER" bash -c "sudo mariadb -e \"GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '$PHPUSERPW';\"";
sudo -H -u "$APPUSER" bash -c "sudo mariadb -e \"GRANT ALL PRIVILEGES ON *.* TO '$APPUSER'@'localhost' IDENTIFIED BY '$APPUSERPW' WITH GRANT OPTION;\"";
sudo -H -u "$APPUSER" bash -c "sudo mariadb -e \"GRANT SELECT, INSERT, UPDATE, DELETE ON casinoapp.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBUSERPW';\"";
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Lege Zugangsdaten-Datei an...${reset}";
SERVERIP=$(curl -s ipinfo.io/ip);
sudo -H -u "$APPUSER" bash -c "sudo cp /home/$APPUSER/casinoapp-download/creds.txt /home/$APPUSER";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/Nutzername: APPUSER/Nutzername: $APPUSER/g\" /home/$APPUSER/creds.txt";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/Passwort: APPUSERPW/Passwort: $APPUSERPW/g\" /home/$APPUSER/creds.txt";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/Nutzername: DBUSER/Nutzername: $DBUSER/g\" /home/$APPUSER/creds.txt";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/Passwort: DBUSERPW/Passwort: $DBUSERPW/g\" /home/$APPUSER/creds.txt";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/Nutzername: PHPUSER/Nutzername: $PHPUSER/g\" /home/$APPUSER/creds.txt";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/Passwort: PHPUSERPW/Passwort: $PHPUSERPW/g\" /home/$APPUSER/creds.txt";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/SERVERIP/$SERVERIP/g\" /home/$APPUSER/creds.txt";
echo "${green}Fertig.${reset}";
echo "";

# Beginne mit App-Installation
echo "${yellow}Installiere die virtuelle Umgebung...${reset}";
# Next line is needed as fix for opencv build failing. pip needs to be upgraded manually after initial installation
python3 -m pip install -qq --upgrade pip wheel setuptools
# sudo not working here (permissions problem?) - SWITCH TO RUNSER GENERALLY OR ROOT-THEN-PERMISSIONS
python3 -m venv /var/www/html/CasinoApp/venv;
source /var/www/html/CasinoApp/venv/bin/activate;
# Next two lines need to be installed seperately, build errors otherwise when installing requirements at oce
python3 -m pip install -qq pip wheel setuptools;
python3 -m pip install -qq -r /home/$APPUSER/casinoapp-download/requirements.txt;
deactivate;
echo "${yellow}Bearbeite Konfigurationen...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo rm -r /home/$APPUSER/casinoapp-download";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/'DBUSER'/'$DBUSER'/g\" /var/www/html/CasinoApp/db.cfg";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/'DBUSERPW'/'$DBUSERPW'/g\" /var/www/html/CasinoApp/db.cfg";
sudo -H -u "$APPUSER" bash -c "sudo sed -i \"s/APPDOMAIN = 'APPDOMAIN'/APPDOMAIN = '$SERVERIP'/g\" /var/www/html/CasinoApp/__init__.py";
echo "${yellow}Setze Berechtigungen...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo chown -R www-data:www-data /var/www/html/CasinoApp";
sudo -H -u "$APPUSER" bash -c "sudo chmod -R 750 /var/www/html/CasinoApp";
sudo -H -u "$APPUSER" bash -c "sudo chmod -R 770 /var/www/html/CasinoApp/static/upload/profileimg";
echo "${yellow}Starte Apache-Webserver neu...${reset}";
sudo -H -u "$APPUSER" bash -c "sudo systemctl restart apache2";
echo "${green}Fertig.${reset}";
echo "";

# Endanweisungen
echo ""
echo ""
echo "${green}Installation abgeschlossen.";
echo "Wechsle zum Benutzer \"${yellow}$APPUSER${green}\".";
echo "Zugangsdaten gespeichert unter /home/$APPUSER/creds.txt ${red}- Bitte woanders sichern und dann löschen!"
echo "Bitte Neustart durchführen mit ${yellow}sudo reboot${reset}";
echo ""

# Letzer Schritt, wechsle zum APPUSER
su "$APPUSER";