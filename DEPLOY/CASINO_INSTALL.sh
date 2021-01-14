#!/bin/bash

# Voraussetzung sollte ein Debian 9 / 10 Server sein, keine zusätzlichen Check dafür im Skript

# TODOS /IDEEN:
# - Alles, was der Skript nicht erledigen kann, dokumentieren in den Installationshinweisen (plus Voraussetzungen / Anleitung Skript)
# - Apache Directives / Security Settings
# - Virtualenv fixen, sodass die manuellen Fixes (s. unten) nicht mehr nötig sind
# - Dynamische Konfiguration des Mail-Users (mail.cfg)
# - Automatische Installation des Webhooks (nötig?)
# - Funktionen verwenden (Code kürzen)
# - >/dev/null statt >/dev/null 2>&1 verwenden, wo es Sinn macht
# - seperater sudo nutzer (...)
# - alte Nutzer löschen

# Variables
SERVERIP=$(curl -s ipinfo.io/ip);
GITURL="https://github.com/Lartsch/casinoapp-deploy-test.git"
# Use the following lines to define the subfolder in the repo where the CasinoApp / Config files lives
# Ex. GITCASINOSUBFOLDER="CasinoApp/" (notice slash at the end!)
GITCASINOSUBFOLDER="CasinoApp/"
GITCCONFIGSUBFOLDER=""

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
read -p "Fortfahren? (Y/N) " runyn
if [[ ! "$runyn" == [yY1]* ]]; then
    exit -1
fi
echo ""

# Führe apt update aus, da sonst manche benötigte Pakete nicht gefunden werden (und upgrade)
echo ""
echo "${yellow}Führe apt update und apt upgrade aus...${reset}"
apt-get -qq update >/dev/null 2>&1;
apt-get -qq upgrade >/dev/null 2>&1;
echo "${green}Fertig.${reset}"
echo ""

#WEBSTUFF
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

#FTP SERVER
# Frage Benutzernamen für Installation ab
read -p "${yellow}Benutzername für den FTP-User der WebApp: ${reset}" FTPUSER
# Falls leer oder kürzer als 3 Zeichen, breche ab (ALTERNATIV: LOOP)
if [ -z "$FTPUSER" ] || [ ${#FTPUSER} -lt 3 ]; then
        # Abbruch
        echo "${red}Benutzername leer oder weniger als 3 Zeichen. Abbruch.${reset}"
        exit -1
fi
# Falls User bereits existiert, breche ab
if grep "${FTPUSER}" /etc/passwd >/dev/null 2>&1; then
        # Abbruch
        echo "${red}Benutzer existiert bereits. Abbruch.${reset}"
        exit -1
fi
# Frage Passwort ab (und Bestätigung dafür)
read -s -p "${yellow}Passwort für den FTP-User der WebApp: ${reset}" FTPUSERPW; echo
# Falls leer oder kürzer als 9 Zeichen, breche ab (ALTERNATIV: LOOP)
if [ -z "$FTPUSERPW" ] || [ ${#FTPUSERPW} -lt 9 ]; then
        # Abbruch
        echo "${red}Passwort leer oder weniger als 9 Zeichen. Abbruch.${reset}"
        exit -1
fi
read -s -p "${yellow}Passwort bestätigen: ${reset}" FTPUSERCONFIRMPW; echo
# Prüfe Übereinstimmung
if [[ "$FTPUSERPW" != "$FTPUSERCONFIRMPW" ]]; then
        # Abbruch
        echo ""
        echo "${red}Passwörter stimmen nicht überein. Abbruch.${reset}"
        exit -1
fi

#DBUSER
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

#PHPUSER
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
        exit -1;
fi
read -s -p "${yellow}Passwort bestätigen: ${reset}" PHPUSERCONFIRMPW; echo
# Prüfe Übereinstimmung
if [[ "$PHPUSERPW" != "$PHPUSERCONFIRMPW" ]]; then
        # Abbruch
        echo "";
        echo "${red}Passwörter stimmen nicht überein. Abbruch.${reset}";
        exit -1;
fi
echo "${green}Benutzerdaten OK, fahre fort...${reset}";
echo "";

echo ""
echo "${red}Möchten Sie für die App SSL aktivieren? Dazu benötigen Sie eine gültige Domain und E-Mail-Adresse.";
echo "Der A-Record der Domain muss bereits auf die öffentliche IP dieses Servers verweisen, damit die Einrichtung funktioniert.";
echo "Falls sie die Seite ohne SSL installieren, wird sie nur unter der öffentlichen IP des Servers erreichbar sein.${reset}";
read -p "SSL aktivieren? (Y/N) " sslyn
if [[ "$sslyn" == [yY1]* ]]; then
    echo ""
    # Frage Domain ab
    read -p "${yellow}Ihre Domain (ohne \"www\", zum Beispiel test.de): ${reset}" DOMAINNAME
    DOMAINCHECKED=$(echo "$DOMAINNAME" | grep -P '(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$)');
    if [ -z "$DOMAINCHECKED" ]; then
        # Abbruch
        echo "${red}Domain leer oder fehlerhaft. Abbruch.${reset}";
        exit -1;
    fi
    read -p "${yellow}Ihre E-Mail-Adresse: ${reset}" EMAILADDRESS
    EMAILCHECKED=$(echo "$EMAILADDRESS" | grep -P "^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+");
    if [ -z "$EMAILCHECKED" ]; then
        # Abbruch
        echo "${red}E-Mail-Adresse leer oder fehlerhaft. Abbruch.${reset}";
        exit -1;
    fi
    echo "${green}OK, fahre fort mit SSL-Installation...${reset}";
else
    echo "${green}OK, fahre fort ohne SSL-Installation...${reset}";
fi
echo ""


# Erstellung des Nutzers, Festlegen des Passworts
echo "${yellow}Beginne Nutzererstellung...${reset}"
adduser --disabled-password --gecos "" $APPUSER >/dev/null 2>&1;
echo -e "$APPUSERPW\n$APPUSERPW" | passwd $APPUSER >/dev/null 2>&1;
adduser --disabled-password --gecos "" $FTPUSER --group ftpuser --shell /bin/false >/dev/null 2>&1;
echo -e "$FTPUSERPW\n$FTPUSERPW" | passwd $FTPUSER >/dev/null 2>&1;
echo "${green}Fertig.${reset}"
echo ""

# Diverse Programme / Ordner /Datenbanken zurücksetzen
echo "${yellow}Setze Programme und Ordner zurück...${reset}"
rm -rf /var/lib/mysql/* >/dev/null 2>&1;
rm -rf /var/www/html >/dev/null 2>&1;
rm -rf /var/lib/phpmyadmin >/dev/null 2>&1;
rm -rf /usr/share/phpmyadmin >/dev/null 2>&1;
rm -rf /etc/apache2 >/dev/null 2>&1;
rm -rf /etc/mysql >/dev/null 2>&1;
rm -rf /etc/letsencrypt >/dev/null 2>&1;
rm -rf /etc/proftpd >/dev/null 2>&1;
apt-get -qq purge ufw certbot python3-certbot-apache apache2 libapache2-mod-php7.3 libsodium23 php php-common php7.3 php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline psmisc php7.3-mbstring php7.3-zip php7.3-gd php7.3-xml php7.3-curl php7.3-mysql mariadb-server mariadb-client mysql-common curl python3.7 python3-dev python3-pip python3-venv python3.7-venv libapache2-mod-wsgi-py3 libapache2-mod-security2 libmariadb-dev-compat libmariadb-dev proftpd-basic >/dev/null 2>&1;
echo "${green}Fertig.${reset}"
echo ""

# Alle notwendigen Systempakete installieren
echo "${yellow}Installiere alle nötigen Systempakete...${reset}";
apt-get -qq install sudo git ufw openssh-server apache2 libapache2-mod-php7.3 libsodium23 php php-common php7.3 php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline psmisc php7.3-mbstring php7.3-zip php7.3-gd php7.3-xml php7.3-curl php7.3-mysql mariadb-server mariadb-client mysql-common curl python3.7 python3-dev python3-pip python3-venv python3.7-venv libapache2-mod-wsgi-py3 libapache2-mod-security2 libmariadb-dev-compat libmariadb-dev proftpd-basic >/dev/null 2>&1;
if [[ "$sslyn" == [yY1]* ]]; then
    apt-get -qq install certbot python3-certbot-apache >/dev/null 2>&1;
fi
echo "${green}Fertig.${reset}";
echo ""

# Beginne mit UFW-Setup
echo "${yellow}Richte Firewall ein...${reset}";
echo 'y' | ufw reset >/dev/null;
ufw default deny incoming >/dev/null;
ufw default allow outgoing >/dev/null;
ufw allow 60000:65535/tcp >/dev/null;
ufw allow 20/tcp >/dev/null;
ufw allow OpenSSH >/dev/null;
ufw allow 'WWW Full' >/dev/null;
echo 'y' | ufw enable >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

# Lade Setup-Dateien herunter
echo "${yellow}Bereite App-Dateien vor...${reset}";
mkdir /home/$APPUSER/casinoapp-download;
git clone -q $GITURL /home/$APPUSER/casinoapp-download >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Setze Benutzergruppen...${reset}";
usermod -aG www-data $APPUSER >/dev/null;
usermod -aG sudo $APPUSER >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

# Beginne Apache-Setup
echo "${yellow}Konfiguriere Apache...${reset}";
echo "${yellow}Setze Rechte...${reset}";
chown $APPUSER:www-data -R /var/www;
chmod 750 -R /var/www;
echo "${yellow}De/Aktiviere alle relevanten Module...${reset}";
ENAPACHEMODULES="access_compat authz_user dir negotiation php7.3 reqtimeout status mpm_prefork alias autoindex env rewrite wsgi filter setenvif auth_basic cgid headers authn_core proxy socache_shmcb authn_file deflate mime ssl authz_core proxy_http authz_host";
DISAPACHEMODULES="mpm_event";
for VALDIS in $DISAPACHEMODULES; do
        a2dismod -q $VALDIS >/dev/null;
done
for VALEN in $ENAPACHEMODULES; do
        a2enmod -q $VALEN >/dev/null;
done
echo "${yellow}Bereite .conf-Dateien vor...${reset}";
cp /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}phpmyadmin.conf /etc/apache2/conf-available;
cp /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}Casino.base.conf /etc/apache2/sites-available/Casino.conf;
if [[ "$sslyn" == [yY1]* ]]; then
    cat /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}Casino.https.conf >> /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerName SERVERNAME/ServerName $DOMAINCHECKED/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerAlias SERVERALIAS/ServerAlias *.$DOMAINCHECKED/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/Redirect permanent \/ https:\/\/SERVERNAME/Redirect permanent \/ https:\/\/$DOMAINCHECKED/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerAlias WWWSERVERNAME/ServerAlias *.$DOMAINCHECKED/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/Alias \/ftp \/home\/FTPUSER\//Alias \/ftp/home\/$FTPUSER/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/<Directory \/home\/FTPUSER\/>/<Directory \/home\/$FTPUSER\/>/g" /etc/apache2/sites-available/Casino.conf;
else
    cat /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}Casino.http.conf >> /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerName SERVERNAME/ServerName $SERVERIP/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/Alias \/ftp \/home\/FTPUSER\//Alias \/ftp/home\/$FTPUSER/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/<Directory \/home\/FTPUSER\/>/<Directory \/home\/$FTPUSER\/>/g" /etc/apache2/sites-available/Casino.conf;
fi
echo "${yellow}Bereite Webdateien vor...${reset}";
rm /var/www/html/index.html;
mv /home/$APPUSER/casinoapp-download/${GITCASINOSUBFOLDER} /var/www/html;
echo "${yellow}De/Aktiviere .conf-Dateien...${reset}";
a2enconf -q phpmyadmin >/dev/null;
a2ensite -q Casino >/dev/null;
a2dissite -q 000-default >/dev/null;
if [[ "$sslyn" == [yY1]* ]]; then
    certbot --apache --quiet --non-interactive --agree-tos -m "$EMAILCHECKED" -d "$DOMAINCHECKED" -d "www.$DOMAINCHECKED";
fi
echo "${green}Fertig.${reset}";
echo "";

# Beginne FTP-Setup
echo "${yellow}Konfiguriere FTP...${reset}";
echo "${yellow}Setze Rechte...${reset}";
chown -R $FTPUSER:www-data /home/$FTPUSER/;
echo "${yellow}Bereite .conf-Dateien vor...${reset}";
cp /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}custom.conf /etc/proftpd/conf.d/;
rm /etc/proftpd/proftpd.conf;
cp /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}proftpd.conf >> /etc/proftpd/proftpd.conf;
echo "${yellow}Starte FTP neu...${reset}";
systemctl restart proftpd;
echo "${green}Fertig.${reset}";
echo "";

# Beginne MariaDB / phpMyAdmin Setup
echo "${yellow}Richte Datenbanken und phpMyAdmin ein...${reset}";
echo "${yellow}Bereite Dateien für phpMyAdmin vor...${reset}";
wget -q -P /home/$APPUSER/casinoapp-download https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz;
mkdir -p /usr/share/phpmyadmin;
tar xvf /home/$APPUSER/casinoapp-download/phpMyAdmin-latest-all-languages.tar.gz --strip-components=1 -C /usr/share/phpmyadmin >/dev/null 2>&1;
cp /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}config.inc.php /usr/share/phpmyadmin;
cp /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}app-db.sql /usr/share/phpmyadmin/sql;
mkdir -p /var/lib/phpmyadmin/tmp;
echo "${yellow}Bearbeite Konfiguration für phpMyAdmin...${reset}";
sed -i "s/PHPUSERPW/$PHPUSERPW/g" /usr/share/phpmyadmin/config.inc.php;
echo "${yellow}Setze Rechte...${reset}";
chown -R $APPUSER:www-data /var/lib/phpmyadmin;
chown -R $APPUSER:www-data /usr/share/phpmyadmin;
chmod -R 750 /var/lib/phpmyadmin;
chmod -R 750 /usr/share/phpmyadmin;
echo "${yellow}Erstelle Datenbank für phpMyAdmin...${reset}";
mariadb < /usr/share/phpmyadmin/sql/create_tables.sql;
echo "${yellow}Erstelle Datenbank für CasinoApp...${reset}";
mariadb < /usr/share/phpmyadmin/sql/app-db.sql;
echo "${yellow}Erstelle alle Datenbanknutzer...${reset}";
DBUSER="${APPUSER}-appdb";
mariadb -e "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '$PHPUSERPW';";
mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '$APPUSER'@'localhost' IDENTIFIED BY '$APPUSERPW' WITH GRANT OPTION;";
mariadb -e "GRANT SELECT, INSERT, UPDATE, DELETE ON casinoapp.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBUSERPW';";
CASINOUSER="${APPUSER}-app";
CASINOUSERPW=$(echo -n $DBUSERPW | md5sum | awk '{print $1}')
mariadb -e "USE casinoapp; INSERT INTO user VALUES (NULL, '$CASINOUSER', '', '$CASINOUSERPW', 0, 20, 0, 1, 1, NULL, NULL, 0, NULL);";
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Lege Zugangsdaten-Datei an...${reset}";
cp /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}creds.txt /home/$APPUSER;
sed -i "s/Nutzername: APPUSER/Nutzername: $APPUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: APPUSERPW/Passwort: $APPUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Nutzername: DBUSER/Nutzername: $DBUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: DBUSERPW/Passwort: $DBUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: PHPUSERPW/Passwort: $PHPUSERPW/g" /home/$APPUSER/creds.txt;
if [[ "$sslyn" == [yY1]* ]]; then
    sed -i "s/SERVERIP/$DOMAINCHECKED/g" /home/$APPUSER/creds.txt;
else
    sed -i "s/SERVERIP/$SERVERIP/g" /home/$APPUSER/creds.txt;
fi
sed -i "s/Passwort: CASINOUSERPW/Passwort: $DBUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Benutzername: CASINOUSER/Benutzername: $CASINOUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Nutzername: FTPUSER/Nutzername: $FTPUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: FTPUSERPW/Passwort: $FTPUSERPW/g" /home/$APPUSER/creds.txt;
chown ${APPUSER}:${APPUSER} /home/$APPUSER/creds.txt;
chmod 750 /home/$APPUSER/creds.txt;
echo "${green}Fertig.${reset}";
echo "";

# Beginne mit App-Installation
echo "${yellow}Installiere die virtuelle Umgebung...${reset}";
# Next line is needed as fix for opencv build failing. pip needs to be upgraded manually after initial installation
python3 -m pip install -qq --upgrade pip wheel setuptools;
python3 -m venv /var/www/html/CasinoApp/venv;
source /var/www/html/CasinoApp/venv/bin/activate;
# Next line needs to be installed seperately, build errors otherwise when installing requirements at oce
python3 -m pip install -qq pip wheel setuptools;
python3 -m pip install -qq -r /home/$APPUSER/casinoapp-download/${GITCONFIGFOLDER}requirements.txt;
deactivate;
echo "${yellow}Entferne temporäre Dateien...${reset}";
rm -r /home/$APPUSER/casinoapp-download;
echo "${yellow}Bearbeite Konfigurationen...${reset}";
sed -i "s/'DBUSER'/'$DBUSER'/g" /var/www/html/CasinoApp/db.cfg;
sed -i "s/'DBUSERPW'/'$DBUSERPW'/g" /var/www/html/CasinoApp/db.cfg;
if [[ "$sslyn" == [yY1]* ]]; then
    sed -i "s/APPDOMAIN = 'https:\/\/casino.reshade.io'/APPDOMAIN = 'https:\/\/$DOMAINCHECKED'/g" /var/www/html/CasinoApp/__init__.py;
else
    sed -i "s/APPDOMAIN = 'https:\/\/casino.reshade.io'/APPDOMAIN = '$SERVERIP'/g" /var/www/html/CasinoApp/__init__.py;
fi
echo "${yellow}Setze Berechtigungen...${reset}";
chown -R $APPUSER:www-data /var/www/html/CasinoApp;
chmod -R 750 /var/www/html/CasinoApp;
chmod -R 770 /var/www/html/CasinoApp/static/upload/profileimg;
echo "${yellow}Starte Apache-Webserver neu...${reset}";
systemctl restart apache2;
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